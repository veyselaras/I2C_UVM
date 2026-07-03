`ifndef I2C_REG_CMD_SVH
  `define I2C_REG_CMD_SVH

  class i2c_reg_cmd extends uvm_reg;
    `uvm_object_utils(i2c_reg_cmd)
    
    rand uvm_reg_field STA;
    rand uvm_reg_field STO;
    rand uvm_reg_field RD;
    rand uvm_reg_field WR;
    rand uvm_reg_field ACK;
    rand uvm_reg_field IACK;
    
    function new(string name = "i2c_reg_cmd");
      super.new(.name(name), .n_bits(8), .has_coverage(UVM_NO_COVERAGE));
    endfunction
    
    virtual function void build();
      STA  = uvm_reg_field::type_id::create(.name("STA"), .parent(null), .contxt(get_full_name));
      STO  = uvm_reg_field::type_id::create(.name("STO"), .parent(null), .contxt(get_full_name));
      RD   = uvm_reg_field::type_id::create(.name("RD"), .parent(null), .contxt(get_full_name));
      WR   = uvm_reg_field::type_id::create(.name("WR"), .parent(null), .contxt(get_full_name));
      ACK  = uvm_reg_field::type_id::create(.name("ACK"), .parent(null), .contxt(get_full_name));
      IACK = uvm_reg_field::type_id::create(.name("IACK"), .parent(null), .contxt(get_full_name));
      
      STA.configure(
        .parent(this),
        .size(1),
        .lsb_pos(7),
        .access("RW"),
        .volatile(1),
        .reset(1'b0),
        .has_reset(1),
        .is_rand(1),
        .individually_accessible(0)
      );
      
      STO.configure(
        .parent(this),
        .size(1),
        .lsb_pos(6),
        .access("RW"),
        .volatile(1),
        .reset(1'b0),
        .has_reset(1),
        .is_rand(1),
        .individually_accessible(0)
      );
      
      RD.configure(
        .parent(this),
        .size(1),
        .lsb_pos(5),
        .access("RW"),
        .volatile(1),
        .reset(1'b0),
        .has_reset(1),
        .is_rand(1),
        .individually_accessible(0)
      );
      
      WR.configure(
        .parent(this),
        .size(1),
        .lsb_pos(4),
        .access("RW"),
        .volatile(1),
        .reset(1'b0),
        .has_reset(1),
        .is_rand(1),
        .individually_accessible(0)
      );
      
      ACK.configure(
        .parent(this),
        .size(1),
        .lsb_pos(3),
        .access("RW"),
        .volatile(1),
        .reset(1'b0),
        .has_reset(1),
        .is_rand(1),
        .individually_accessible(0)
      );
      
      IACK.configure(
        .parent(this),
        .size(1),
        .lsb_pos(0),
        .access("RW"),
        .volatile(1),
        .reset(1'b0),
        .has_reset(1),
        .is_rand(1),
        .individually_accessible(0)
      );
    endfunction
    
  endclass

`endif