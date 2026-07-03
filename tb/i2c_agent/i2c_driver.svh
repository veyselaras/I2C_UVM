`ifndef I2C_DRIVER_SVH
  `define I2C_DRIVER_SVH

  class i2c_driver extends uvm_driver #(i2c_seq_item);
    `uvm_component_utils(i2c_driver)

    i2c_vif vif;

    function new(string name = "i2c_driver", uvm_component parent);
      super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
      super.run_phase(phase);

      vif.slave_sda_o = 1;
      vif.slave_scl_o = 1;

      forever begin
        i2c_seq_item item;
        seq_item_port.get_next_item(item);
        `uvm_info("I2C_DRV", $sformatf("Driving: %s", item.convert2string()), UVM_MEDIUM)
        drive_item(item);
        seq_item_port.item_done();
      end
    endtask

    virtual task drive_item(i2c_seq_item item);
      
      @(negedge vif.slave_cb.scl_line);

      if(item.ack == I2C_NACK) begin
        vif.slave_sda_o = 1;
        @(negedge vif.slave_cb.scl_line); 
        return;
      end
      else begin
        vif.slave_sda_o = 0;
        @(negedge vif.slave_cb.scl_line); 
        vif.slave_sda_o = 1;
      end

      if(item.dir == I2C_READ) begin
        for(int i = 7; i >= 0; i--) begin
          vif.slave_sda_o = item.data[i];
          @(negedge vif.slave_cb.scl_line);
        end
        vif.slave_sda_o = 1; 
        @(negedge vif.slave_cb.scl_line);
      end

    endtask

  endclass

`endif