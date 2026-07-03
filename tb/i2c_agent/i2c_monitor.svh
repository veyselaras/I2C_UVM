`ifndef I2C_MONITOR_SVH
  `define I2C_MONITOR_SVH

  class i2c_monitor extends uvm_monitor;
    `uvm_component_utils(i2c_monitor)
    
    i2c_vif vif;
    
    uvm_analysis_port #(i2c_transaction) ap;
    uvm_analysis_port #(i2c_transaction) request_aport;
    
    function new(string name="i2c_monitor", uvm_component parent);
      super.new(name, parent);
      
      ap = new("ap", this);
      request_aport = new("request_aport", this);
    endfunction
    
    virtual task collect_transaction();
      i2c_transaction transaction = i2c_transaction::type_id::create("transaction");
      
      bit [7:0] last_data;
      bit sda_prev;
      forever begin
        @(vif.monitor_cb);
        if(sda_prev == 1 && vif.monitor_cb.sda_line == 0 && vif.monitor_cb.scl_line == 1)
          break;
        sda_prev = vif.monitor_cb.sda_line;
      end
      
      `uvm_info("I2C_MON", "START condition detected", UVM_HIGH)
      
      for(int i = 0; i < 7; i++) begin
        @(posedge vif.monitor_cb.scl_line);
        transaction.slave_addr = {transaction.slave_addr[5:0], vif.monitor_cb.sda_line};
      end
      
      @(posedge vif.monitor_cb.scl_line);
      transaction.dir = i2c_dir_e'(vif.monitor_cb.sda_line);
      
      request_aport.write(transaction);
      `uvm_info("I2C_MON", $sformatf("Request: %s", transaction.convert2string()), UVM_MEDIUM)
      
      @(posedge vif.monitor_cb.scl_line);
      transaction.ack = i2c_ack_e'(vif.monitor_cb.sda_line);
      
      if(transaction.ack == I2C_NACK) begin
        `uvm_info("I2C_MON", $sformatf("NACK - transfer ended: %s", transaction.convert2string()), UVM_MEDIUM)
        ap.write(transaction);
        return;
      end
      

      
      fork
        begin : stop_watch
          bit sda_prev_stop;
          forever begin
            @(vif.monitor_cb);
            if(sda_prev_stop == 0 && vif.monitor_cb.sda_line == 1 && vif.monitor_cb.scl_line == 1)
              break;
            sda_prev_stop = vif.monitor_cb.sda_line;
          end
        end

        begin : data_collect
          forever begin
            for(int i = 0; i < 8; i++) begin
              @(posedge vif.monitor_cb.scl_line);
              transaction.data = {transaction.data[6:0], vif.monitor_cb.sda_line};
            end
            
            last_data = transaction.data;
			request_aport.write(transaction);
            
            @(posedge vif.monitor_cb.scl_line);
            transaction.ack = i2c_ack_e'(vif.monitor_cb.sda_line);

            if(transaction.ack == I2C_NACK) break;
          end
        end
      join_any
      disable fork;
        
      transaction.data = last_data;
      `uvm_info("I2C_MON", $sformatf("Complete: %s", transaction.convert2string()), UVM_MEDIUM)
      ap.write(transaction);
    endtask
    
    virtual task collect_transactions();
      forever begin
        collect_transaction();
      end
    endtask
    
    virtual task run_phase(uvm_phase phase);
      super.run_phase(phase);
      collect_transactions();
    endtask
    
  endclass

`endif