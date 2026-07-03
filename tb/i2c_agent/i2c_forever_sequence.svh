`ifndef I2C_FOREVER_SEQUENCE_SVH
  `define I2C_FOREVER_SEQUENCE_SVH

  class i2c_forever_sequence extends uvm_sequence#(i2c_seq_item);
    `uvm_object_utils(i2c_forever_sequence)
    `uvm_declare_p_sequencer(i2c_sequencer)
    
    local bit [7:0] addr = 7'h7F;
    bit [7:0] read_data;
    
    i2c_seq_item item;
    i2c_transaction transaction;
    
    function new(string name="i2c_forever_sequence");
      super.new(name);
    endfunction: new
    
    virtual task body();
      
      if(!uvm_config_db#(bit[7:0])::get(null, get_full_name(), "read_data", read_data)) begin
        `uvm_warning("SEQ", "read_data config not found, using 0x00")
        read_data = 8'h00;
      end
      `uvm_info("SEQ", $sformatf("read_data from config: 0x%02h", read_data), UVM_LOW)
      
      forever begin
        p_sequencer.request_fifo.get(transaction);
        item = i2c_seq_item::type_id::create("item");
        
        if(transaction.slave_addr == addr) begin
          case(transaction.dir)
            I2C_WRITE: begin
              start_item(item);
              item.dir = I2C_WRITE;
              if (!item.randomize() with { ack == I2C_ACK; }) begin
                `uvm_error("RAND_FAIL", "i2c_seq_item randomization failed")
              end
              finish_item(item);
              
                // Data byte ACK
//               item = i2c_seq_item::type_id::create("item");
//               start_item(item);
//               if (!item.randomize() with { ack == I2C_ACK; }) begin
//                 `uvm_error("RAND_FAIL", "randomization failed")
//               end
//               finish_item(item);
            end

            I2C_READ: begin
              start_item(item);
              item.dir = I2C_READ;
              if (!item.randomize() with { data == local::read_data; ack == I2C_ACK; }) begin
                `uvm_error("RAND_FAIL", "i2c_seq_item randomization failed")
              end
              finish_item(item);
            end  
          endcase
        end
        else begin
            start_item(item);
            if (!item.randomize() with {  data == read_data; ack == I2C_NACK; }) begin
              `uvm_error("RAND_FAIL", "i2c_seq_item randomization failed")
            end
            finish_item(item);
        end
      end
    endtask
  endclass
`endif