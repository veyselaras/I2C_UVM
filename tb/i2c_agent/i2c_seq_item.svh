`ifndef I2C_SEQ_ITEM_SVH
  `define I2C_SEQ_ITEM_SVH

  class i2c_seq_item extends uvm_sequence_item;
    
    `uvm_object_utils(i2c_seq_item)
    
    rand i2c_ack_e ack;
    rand bit [7:0] data;
    i2c_dir_e dir;
    
    function new(string name="i2c_seq_item");
      super.new(name);
    endfunction
    
    virtual function string convert2string();
      return $sformatf("dir=%s data=0x%02h ack=%s", dir.name(), data, ack.name());
    endfunction
    
  endclass

`endif