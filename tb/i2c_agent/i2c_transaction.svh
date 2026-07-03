`ifndef I2C_TRANSACTION_SVH
  `define I2C_TRANSACTION_SVH

  class i2c_transaction extends uvm_sequence_item;
    
    `uvm_object_utils(i2c_transaction)
    
    bit [6:0] slave_addr;
    i2c_dir_e dir;
    bit [7:0] data;
    i2c_ack_e ack;
    
    function new(string name="i2c_transaction");
      super.new(name);
    endfunction
    
    virtual function string convert2string();
      return $sformatf("dir=%s addr=0x%02h data=0x%02h ack=%s",
                        dir.name(), slave_addr, data, ack.name());
    endfunction
    
  endclass

`endif