`ifndef I2C_SCOREBOARD_SVH
  `define I2C_SCOREBOARD_SVH

`uvm_analysis_imp_decl(_apb)
`uvm_analysis_imp_decl(_i2c)

  class i2c_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(i2c_scoreboard)
    
    uvm_analysis_imp_apb #(apb_seq_item,       i2c_scoreboard) apb_export;
    uvm_analysis_imp_i2c #(i2c_transaction,    i2c_scoreboard) i2c_export;
    
    bit [7:0] expected_data[$];
    bit [7:0] expected_rx[$];

    int matches_cnt;
    int mismatches_cnt;
    
    bit [7:0] pending_tx;
    bit pending_tx_valid = 0;
    
    bit [7:0] pending_rx;
    bit       pending_rx_valid = 0;
    
    function new(string name="i2c_scoreboard", uvm_component parent);
      super.new(name, parent);
      apb_export = new("apb_export", this);
      i2c_export = new("i2c_export", this);
    endfunction
    
    virtual function void write_apb(apb_seq_item item);
      bit [7:0] exp_byte;

      // RX register read yakala (read yönü)
      if(item.addr == 12'h008 && item.dir == APB_READ) begin
        if(expected_rx.size() == 0) begin
          // I2C tarafı henüz gelmedi, RX'i pending'e koy
          pending_rx = item.rdata[7:0];
          pending_rx_valid = 1;
          `uvm_info("SCB", $sformatf("RX read 0x%02h pending, waiting for I2C", pending_rx), UVM_HIGH)
          return;
        end

        // I2C tarafı önce geldi, direkt karşılaştır
        exp_byte = expected_rx.pop_front();

        if(exp_byte == item.rdata[7:0]) begin
          matches_cnt++;
          `uvm_info("SCB", $sformatf("READ MATCH: expected=0x%02h actual=0x%02h", exp_byte, item.rdata[7:0]), UVM_LOW)
        end
        else begin
          mismatches_cnt++;
          `uvm_error("SCB", $sformatf("READ MISMATCH: expected=0x%02h actual=0x%02h", exp_byte, item.rdata[7:0]))
        end
        return;
      end

      if(item.dir != APB_WRITE) return;

      case(item.addr)
        12'h010: begin  // TX register
          pending_tx = item.wdata[7:0];
          pending_tx_valid = 1;
          `uvm_info("SCB", $sformatf("TX pending: 0x%02h", pending_tx), UVM_HIGH)
        end

        12'h014: begin  // CMD register
          if(!pending_tx_valid) return;

          if(item.wdata[7]) begin
            `uvm_info("SCB", $sformatf("Address byte 0x%02h - skipped", pending_tx), UVM_HIGH)
            pending_tx_valid = 0;
          end
          else if(item.wdata[4]) begin
            expected_data.push_back(pending_tx);
            `uvm_info("SCB", $sformatf("Data byte 0x%02h -> expected queue", pending_tx), UVM_LOW)
            pending_tx_valid = 0;
          end
        end
      endcase
    endfunction


    virtual function void write_i2c(i2c_transaction txn);
      case(txn.dir)
        I2C_WRITE: begin
          bit [7:0] exp_byte;

          if(expected_data.size() == 0) begin
            `uvm_error("SCB", $sformatf("Received I2C data 0x%02h but expected queue is empty", txn.data))
            return;
          end

          exp_byte = expected_data.pop_front();

          if(exp_byte == txn.data) begin
            matches_cnt++;
            `uvm_info("SCB", $sformatf("WRITE MATCH: expected=0x%02h actual=0x%02h", exp_byte, txn.data), UVM_LOW)
          end
          else begin
            mismatches_cnt++;
            `uvm_error("SCB", $sformatf("WRITE MISMATCH: expected=0x%02h actual=0x%02h", exp_byte, txn.data))
          end
        end

        I2C_READ: begin
          if(pending_rx_valid) begin
            // APB RX read zaten geldi, direkt karşılaştır
            if(pending_rx == txn.data) begin
              matches_cnt++;
              `uvm_info("SCB", $sformatf("READ MATCH: I2C=0x%02h RX=0x%02h", txn.data, pending_rx), UVM_LOW)
            end
            else begin
              mismatches_cnt++;
              `uvm_error("SCB", $sformatf("READ MISMATCH: I2C=0x%02h RX=0x%02h", txn.data, pending_rx))
            end
            pending_rx_valid = 0;
          end
          else begin
            // APB RX read henüz gelmedi, I2C data'yı bekletmeye al
            expected_rx.push_back(txn.data);
            `uvm_info("SCB", $sformatf("I2C read data 0x%02h -> expected_rx queue", txn.data), UVM_LOW)
          end
        end
      endcase
    endfunction
    
    function void report_phase(uvm_phase phase);
      super.report_phase(phase);

      `uvm_info("SCB", $sformatf({
        "\n========================================",
        "\n        SCOREBOARD REPORT",
        "\n========================================",
        "\n  Matches            : %0d",
        "\n  Mismatches         : %0d",
        "\n  Leftover write exp : %0d",
        "\n  Leftover read exp  : %0d",
        "\n========================================"
      }, matches_cnt, mismatches_cnt, expected_data.size(), expected_rx.size()), UVM_LOW)

      if(expected_data.size() > 0 || expected_rx.size() > 0)
        `uvm_warning("SCB", "Expected queues have leftover items at end of test")
    endfunction
    
  endclass

`endif