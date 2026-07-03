`ifndef I2C_ENV_SVH
  `define I2C_ENV_SVH

  class i2c_env extends uvm_env;
    
    `uvm_component_utils(i2c_env)
    
    i2c_agent agent_i2c;
    
    apb_agent agent_apb;
    
    i2c_model model;
    
    uvm_reg_predictor#(apb_seq_item) predictor;
    
    i2c_scoreboard scoreboard;
    
    function new(string name = "i2c_env", uvm_component parent);
      super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      
      agent_i2c = i2c_agent::type_id::create("agent_i2c", this);
      agent_apb = apb_agent::type_id::create("agent_apb", this);
      
      model = i2c_model::type_id::create("model", this);
      
      predictor = uvm_reg_predictor#(apb_seq_item)::type_id::create("predictor", this);
      
      scoreboard = i2c_scoreboard::type_id::create("scoreboard", this);
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
      i2c_reg_adapter adapter = i2c_reg_adapter::type_id::create("adapter", this);
      
      super.connect_phase(phase);
      
      predictor.map = model.reg_block.default_map;
      predictor.adapter = adapter;
      
      agent_apb.monitor.ap.connect(predictor.bus_in);
      
      model.reg_block.default_map.set_sequencer(agent_apb.sequencer, adapter);
      
      agent_apb.monitor.ap.connect(scoreboard.apb_export);
      agent_i2c.monitor.ap.connect(scoreboard.i2c_export);
    endfunction
    
    
    
  endclass

`endif