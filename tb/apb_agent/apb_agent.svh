`ifndef APB_AGENT_SVH
	`define APB_AGENT_SVH

  class apb_agent extends uvm_agent;
    `uvm_component_utils(apb_agent)
    
    apb_agent_config agent_config;
    
    apb_sequencer sequencer;
    
    apb_driver driver;
    
    apb_monitor monitor;
    
    apb_coverage coverage;
    
    apb_vif vif;
    
    function new(string name="agent_apb", uvm_component parent);
      super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      
      if (!uvm_config_db#(apb_agent_config)::get(this, "", "apb_config", agent_config))
        `uvm_fatal(get_type_name(), "i2c_agent_config could not be retrieved")
      
      if(uvm_config_db#(apb_vif)::get(this, "", "apb_vif", vif)) begin
        agent_config.set_vif(vif);
      end 
      else begin
        `uvm_fatal("APB_NO_VIF", "Could not get fron the database the APB virtual interface")
      end
        
      monitor = apb_monitor::type_id::create("monitor", this);
      
      if(agent_config.get_active_passive() == UVM_ACTIVE) begin
        driver = apb_driver::type_id::create("driver", this);
        sequencer = apb_sequencer::type_id::create("sequencer", this);
      end
      
      if(agent_config.get_has_coverage()) begin
        coverage = apb_coverage::type_id::create("coverage", this);
      end
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
      
      super.connect_phase(phase);
      
      monitor.vif = agent_config.get_vif();
      
      if(agent_config.get_active_passive() == UVM_ACTIVE) begin
        driver.seq_item_port.connect(sequencer.seq_item_export);
        driver.vif = agent_config.get_vif();
      end
      
      if(agent_config.get_has_coverage()) begin
        monitor.ap.connect(coverage.analysis_export);
      end
    endfunction
    
  endclass

`endif