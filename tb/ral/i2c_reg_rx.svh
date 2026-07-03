`ifndef I2C_REG_RX_SVH
  `define I2C_REG_RX_SVH

  class i2c_reg_rx extends uvm_reg;
    `uvm_object_utils(i2c_reg_rx)
    
    rand uvm_reg_field RX_DATA;
    
    function new(string name = "i2c_reg_rx");
      super.new(.name(name), .n_bits(8), .has_coverage(UVM_NO_COVERAGE));
    endfunction
    
    virtual function void build();
      RX_DATA = uvm_reg_field::type_id::create(.name("RX_DATA"), .parent(null), .contxt(get_full_name));
      
      RX_DATA.configure(
        .parent(this),
        .size(8),
        .lsb_pos(0),
        .access("RO"),
        .volatile(1),
        .reset(8'h00),
        .has_reset(0),
        .is_rand(1),
        .individually_accessible(0)
      );
    endfunction
    
  endclass

`endif