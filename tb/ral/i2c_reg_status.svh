`ifndef I2C_REG_STATUS_SVH
  `define I2C_REG_STATUS_SVH

  class i2c_reg_status extends uvm_reg;
    `uvm_object_utils(i2c_reg_status)
    
    rand uvm_reg_field RXACK;
    rand uvm_reg_field BUSY;
    rand uvm_reg_field AL;
    rand uvm_reg_field TIP;
    rand uvm_reg_field IF_FLAG;
    
    function new(string name = "i2c_reg_status");
      super.new(.name(name), .n_bits(8), .has_coverage(UVM_NO_COVERAGE));
    endfunction
    
    virtual function void build();
      RXACK   = uvm_reg_field::type_id::create(.name("RXACK"), .parent(null), .contxt(get_full_name));
      BUSY    = uvm_reg_field::type_id::create(.name("BUSY"), .parent(null), .contxt(get_full_name));
      AL      = uvm_reg_field::type_id::create(.name("AL"), .parent(null), .contxt(get_full_name));
      TIP     = uvm_reg_field::type_id::create(.name("TIP"), .parent(null), .contxt(get_full_name));
      IF_FLAG = uvm_reg_field::type_id::create(.name("IF_FLAG"), .parent(null), .contxt(get_full_name));
      
      RXACK.configure(
        .parent(this),
        .size(1),
        .lsb_pos(7),
        .access("RO"),
        .volatile(1),
        .reset(1'b0),
        .has_reset(1),
        .is_rand(1),
        .individually_accessible(0)
      );
      
      BUSY.configure(
        .parent(this),
        .size(1),
        .lsb_pos(6),
        .access("RO"),
        .volatile(1),
        .reset(1'b0),
        .has_reset(1),
        .is_rand(1),
        .individually_accessible(0)
      );
      
      AL.configure(
        .parent(this),
        .size(1),
        .lsb_pos(5),
        .access("RO"),
        .volatile(1),
        .reset(1'b0),
        .has_reset(1),
        .is_rand(1),
        .individually_accessible(0)
      );
      
      TIP.configure(
        .parent(this),
        .size(1),
        .lsb_pos(1),
        .access("RO"),
        .volatile(1),
        .reset(1'b0),
        .has_reset(1),
        .is_rand(1),
        .individually_accessible(0)
      );
      
      IF_FLAG.configure(
        .parent(this),
        .size(1),
        .lsb_pos(0),
        .access("RO"),
        .volatile(1),
        .reset(1'b0),
        .has_reset(1),
        .is_rand(1),
        .individually_accessible(0)
      );
    endfunction
    
  endclass

`endif