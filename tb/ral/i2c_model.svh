`ifndef I2C_MODEL_SVH
  `define I2C_MODEL_SVH

  class i2c_model extends uvm_component;
    
    `uvm_component_utils(i2c_model)
    
    i2c_reg_block reg_block;
    
    function new(string name = "i2c_model", uvm_component parent);
      super.new(name, parent);  
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      
      if(reg_block == null) begin
        reg_block = i2c_reg_block::type_id::create("reg_block", this);
        
        reg_block.build();
        
        reg_block.lock_model();
      end
    endfunction
    
    virtual function void handle_reset(uvm_phase phase);
      reg_block.reset("HARD");
    endfunction
    
  endclass

`endif