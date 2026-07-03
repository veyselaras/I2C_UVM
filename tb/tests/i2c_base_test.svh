`ifndef I2C_BASE_TEST_SVH
  `define I2C_BASE_TEST_SVH

  class i2c_base_test extends uvm_test;
    
    `uvm_component_utils(i2c_base_test)
    
    i2c_env env;
    
    i2c_agent_config i2c_config;
    
    apb_agent_config apb_config;
    
    function new(string name = "i2c_env", uvm_component parent);
      super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      
      i2c_config = i2c_agent_config::type_id::create("i2c_config", this);
      i2c_config.set_active_passive(UVM_ACTIVE);
      
      apb_config = apb_agent_config::type_id::create("apb_config", this);
      apb_config.set_active_passive(UVM_ACTIVE);
      
      uvm_config_db#(i2c_agent_config)::set(this, "env.agent_i2c", "i2c_config", i2c_config);
      uvm_config_db#(apb_agent_config)::set(this, "env.agent_apb", "apb_config", apb_config);
      
      env = i2c_env::type_id::create("env", this);
      
//       uvm_config_db#(uvm_object_wrapper)::set(
//         this,
//         "env.agent_i2c.sequencer.main_phase",
//         "default_sequence",
//         i2c_forever_sequence::type_id::get()
//       );
    endfunction
  endclass

`endif