`ifndef I2C_REG_ACCESS_SVH
  `define I2C_REG_ACCESS_SVH

  class i2c_reg_access_test extends i2c_base_test;
    
    `uvm_component_utils(i2c_reg_access_test)
    
    function new(string name = "i2c_reg_access_test", uvm_component parent);
      super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
      phase.raise_objection(this, "TEST_DONE");
      
      #100ns;
      
      `uvm_info("DEBUG", "this is the end of the test", UVM_LOW)
      
      phase.drop_objection(this, "TEST_DONE");
    endtask
    
  endclass

`endif