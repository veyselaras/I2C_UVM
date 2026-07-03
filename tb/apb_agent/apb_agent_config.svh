`ifndef APB_AGENT_CONFIG_SVH
	`define APB_AGENT_CONFIG_SVH

  class apb_agent_config extends uvm_component;
    `uvm_component_utils(apb_agent_config)
    
    local apb_vif vif;
    
    local uvm_active_passive_enum active_passive;
    
    local bit has_coverage;
    
    function new(string name="apb_agent_config", uvm_component parent);
      super.new(name, parent);
      
      active_passive = UVM_ACTIVE;
      has_coverage = 1;
    endfunction
    
    
    virtual function void set_vif(apb_vif value);
      if(vif == null) begin
        vif = value;
      end
      else begin
        `uvm_fatal("ALGORTIHM_ISSUE", "Trying to set the APB virtual interface more than once")
      end
    endfunction
    
    virtual function apb_vif get_vif();
      return vif;
    endfunction
    
    
    virtual function void set_has_coverage(bit value);
      has_coverage = value;
    endfunction
    
    virtual function bit get_has_coverage();
      return has_coverage;
    endfunction
    

    virtual function uvm_active_passive_enum get_active_passive();
      return active_passive;
    endfunction
    
    virtual function void set_active_passive(uvm_active_passive_enum value);
      active_passive = value;
    endfunction
    
    
    
    
    
    virtual function void start_of_simulation_phase(uvm_phase phase);
      if(get_vif() == null) begin
        `uvm_fatal("ALGORTIHM_ISSUE", "The APB virtual interface is not configured at \"Start of Simulation\" pahse")
      end
      else begin
        `uvm_info("APB_CONFIG", "The APB virtual interface is configured at \"Start of Simulation\" phase", UVM_LOW)
      end
    endfunction
    
  endclass

`endif