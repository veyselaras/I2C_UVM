`ifndef I2C_REG_CTR_SVH
  `define I2C_REG_CTR_SVH

  class i2c_reg_ctr extends uvm_reg;
    `uvm_object_utils(i2c_reg_ctr)
    
    rand uvm_reg_field EN;
    rand uvm_reg_field IEN;
    
    function new(string name = "i2c_reg_ctr");
      super.new(.name(name), .n_bits(8), .has_coverage(UVM_NO_COVERAGE));
    endfunction
    
    virtual function void build();
      EN = uvm_reg_field::type_id::create(.name("EN"), .parent(null), .contxt(get_full_name));
      IEN = uvm_reg_field::type_id::create(.name("IEN"), .parent(null), .contxt(get_full_name));
      
      EN.configure(
        .parent(this),
        .size(1),
        .lsb_pos(7),
        .access("RW"),
        .volatile(0),
        .reset(1'b0),
        .has_reset(1),
        .is_rand(1),
        .individually_accessible(0)
      );
      
      IEN.configure(
        .parent(this),
        .size(1),
        .lsb_pos(6),
        .access("RW"),
        .volatile(0),
        .reset(1'b0),
        .has_reset(1),
        .is_rand(1),
        .individually_accessible(0)
      );
    endfunction
    
  endclass

`endif