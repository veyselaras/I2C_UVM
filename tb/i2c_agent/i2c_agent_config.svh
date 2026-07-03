`ifndef I2C_AGENT_CONFIG_SVH
	`define I2C_AGENT_CONFIG_SVH

  class i2c_agent_config extends uvm_component;
    `uvm_component_utils(i2c_agent_config)
    
    local i2c_vif vif;
    
    local uvm_active_passive_enum active_passive;
    
    local bit has_coverage;
    
    local bit [6:0] slave_addr;
    
    function new(string name="i2c_agent_config", uvm_component parent);
      super.new(name, parent);
      
      active_passive = UVM_ACTIVE;
      has_coverage = 1;
      slave_addr = '0;
    endfunction
    
    virtual function void set_vif(i2c_vif value);
      if(vif == null) begin
        vif = value;
      end
      else begin
        `uvm_fatal("ALGORITHM_ISSUE", "Trying to set the I2C virtual interface more than once")
      end
    endfunction
    
    virtual function i2c_vif get_vif();
      return vif;
    endfunction
    
    
    virtual function bit[6:0] get_slave_addr();
      return slave_addr;
    endfunction
    
    virtual function void set_slave_addr(bit[6:0] value);
      slave_addr = value;
    endfunction
    
    
    virtual function uvm_active_passive_enum get_active_passive();
      return active_passive;
    endfunction
    
    virtual function void set_active_passive(uvm_active_passive_enum value);
      active_passive = value;
    endfunction
    
    
    virtual function void set_has_coverage(bit value);
      has_coverage = value;
    endfunction
    
    virtual function bit get_has_coverage();
      return has_coverage;
    endfunction
    
    
    virtual function void start_of_simulation_phase(uvm_phase phase);
      if(get_vif() == null) begin
        `uvm_fatal("ALGORITHM_ISSUE", "The I2C virtual interface is not configured at \"Start of Simulation\" phase")
      end
      else begin
        `uvm_info("I2C_CONFIG", "The I2C virtual interface is configured at \"Start of Simulation\" phase", UVM_LOW)
      end
    endfunction
    
  endclass

`endif