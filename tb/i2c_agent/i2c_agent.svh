`ifndef I2C_AGENT_SVH
	`define I2C_AGENT_SVH

  class i2c_agent extends uvm_agent;
    `uvm_component_utils(i2c_agent)
    
    i2c_agent_config agent_config;
    
    i2c_sequencer sequencer;
    
    i2c_driver driver;
    
    i2c_monitor monitor;
    
    i2c_coverage coverage;
    
    i2c_vif vif;
    
    function new(string name="agent_i2c", uvm_component parent);
      super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      
      if (!uvm_config_db#(i2c_agent_config)::get(this, "", "i2c_config", agent_config))
        `uvm_fatal(get_type_name(), "i2c_agent_config could not be retrieved")
        
      if(uvm_config_db#(i2c_vif)::get(this, "", "i2c_vif", vif)) begin
        agent_config.set_vif(vif);
      end 
      else begin
        `uvm_fatal("I2C_NO_VIF", "Could not get from the database the I2C virtual interface")
      end
      
      if(agent_config.get_active_passive() == UVM_ACTIVE) begin
        sequencer = i2c_sequencer::type_id::create("sequencer", this);
        driver = i2c_driver::type_id::create("driver", this);
      end
      
      monitor = i2c_monitor::type_id::create("monitor", this);
      
      if(agent_config.get_has_coverage()) begin
        coverage = i2c_coverage::type_id::create("coverage", this);
      end
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      
      monitor.vif = agent_config.get_vif();
      
      if(agent_config.get_active_passive() == UVM_ACTIVE) begin
        driver.seq_item_port.connect(sequencer.seq_item_export);
        driver.vif = agent_config.get_vif();
        
        monitor.request_aport.connect(sequencer.request_export);
      end
      
      if(agent_config.get_has_coverage()) begin
        monitor.ap.connect(coverage.analysis_export);
      end
    endfunction
    
  endclass

`endif