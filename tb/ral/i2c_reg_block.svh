`ifndef I2C_REG_BLOCK_SVH
  `define I2C_REG_BLOCK_SVH

  class i2c_reg_block extends uvm_reg_block;
    
    `uvm_object_utils(i2c_reg_block)
    
    rand i2c_reg_pre    PRE;
    rand i2c_reg_ctr    CTR;
    rand i2c_reg_tx     TX;
    rand i2c_reg_rx     RX;
    rand i2c_reg_cmd    CMD;
    rand i2c_reg_status STATUS;
    
    function new(string name="i2c_reg_block");
      super.new(name, UVM_NO_COVERAGE);
    endfunction
    
    virtual function void build();
      default_map = create_map(
        .name("i2c_map"),
        .base_addr('h000),
        .n_bytes(4),
        .endian(UVM_LITTLE_ENDIAN),
        .byte_addressing(1)
      );
      
      default_map.set_check_on_read(1);
      
      PRE = i2c_reg_pre::type_id::create(.name("PRE"), .parent(null), .contxt(get_full_name()));
      CTR = i2c_reg_ctr::type_id::create(.name("CTR"), .parent(null), .contxt(get_full_name()));
      TX = i2c_reg_tx::type_id::create(.name("TX"), .parent(null), .contxt(get_full_name()));
      RX = i2c_reg_rx::type_id::create(.name("RX"), .parent(null), .contxt(get_full_name()));
      CMD = i2c_reg_cmd::type_id::create(.name("CMD"), .parent(null), .contxt(get_full_name()));
      STATUS = i2c_reg_status::type_id::create(.name("STATUS"), .parent(null), .contxt(get_full_name()));
      
      PRE.configure(.blk_parent(this));
      CTR.configure(.blk_parent(this));
      TX.configure(.blk_parent(this));
      RX.configure(.blk_parent(this));
      CMD.configure(.blk_parent(this));
      STATUS.configure(.blk_parent(this));
      
      PRE.build();
      CTR.build();
      TX.build();
      RX.build();
      CMD.build();
      STATUS.build();
      
      default_map.add_reg(.rg(PRE),    .offset('h00), .rights("RW"));
      default_map.add_reg(.rg(CTR),    .offset('h04), .rights("RW"));
      default_map.add_reg(.rg(RX),     .offset('h08), .rights("RO"));
      default_map.add_reg(.rg(STATUS), .offset('h0C), .rights("RO"));
      default_map.add_reg(.rg(TX),     .offset('h10), .rights("RW"));
      default_map.add_reg(.rg(CMD),    .offset('h14), .rights("RW"));
      
    endfunction
  endclass

`endif