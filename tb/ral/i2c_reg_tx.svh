`ifndef I2C_REG_TX_SVH
  `define I2C_REG_TX_SVH

  class i2c_reg_tx extends uvm_reg;
    `uvm_object_utils(i2c_reg_tx)
    
    rand uvm_reg_field TX_DATA;
    
    function new(string name = "i2c_reg_tx");
      super.new(.name(name), .n_bits(8), .has_coverage(UVM_NO_COVERAGE));
    endfunction
    
    virtual function void build();
      TX_DATA = uvm_reg_field::type_id::create(.name("TX_DATA"), .parent(null), .contxt(get_full_name));
      
      TX_DATA.configure(
        .parent(this),
        .size(8),
        .lsb_pos(0),
        .access("RW"),
        .volatile(0),
        .reset(8'h00),
        .has_reset(1),
        .is_rand(1),
        .individually_accessible(0)
      );
    endfunction
    
  endclass

`endif