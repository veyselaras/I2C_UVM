`ifndef I2C_REG_PRE_SVH
  `define I2C_REG_PRE_SVH

  class i2c_reg_pre extends uvm_reg;
    `uvm_object_utils(i2c_reg_pre)
    
    rand uvm_reg_field PRESCALER;
    
    function new(string name = "i2c_reg_pre");
      super.new(.name(name), .n_bits(16), .has_coverage(UVM_NO_COVERAGE));
    endfunction
    
    virtual function void build();
      PRESCALER = uvm_reg_field::type_id::create(.name("PRESCALER"), .parent(null), .contxt(get_full_name));
      
      PRESCALER.configure(
        .parent(this),
        .size(16),
        .lsb_pos(0),
        .access("RW"),
        .volatile(0),
        .reset(16'h0000),
        .has_reset(1),
        .is_rand(1),
        .individually_accessible(0)
      );
    endfunction
    
  endclass

`endif