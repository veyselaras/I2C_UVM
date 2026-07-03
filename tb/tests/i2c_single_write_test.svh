`ifndef I2C_SINGLE_WRITE_TEST_SVH
  `define I2C_SINGLE_WRITE_TEST_SVH

  class i2c_single_write_test extends i2c_base_test;
    
    `uvm_component_utils(i2c_single_write_test)
    
    function new(string name = "i2c_single_write_test", uvm_component parent);
      super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
      phase.raise_objection(this, "TEST_DONE");
      
      #(100ns);
      
      begin
        apb_base_sequence seq = apb_base_sequence::type_id::create("apb_base_sequence");
      
        if (!seq.randomize() with { dir == APB_WRITE; }) begin
          `uvm_error("RAND_FAIL_TEST", "apb_item randomization failed due to constraint conflict!")
        end
        
        seq.start(env.agent_apb.sequencer);
      
        `uvm_info("TEST_DEBUG", $sformatf("item: %0s", seq.req.convert2string()), UVM_LOW)
      end
      #(100ns);
      `uvm_info("TEST_DEBUG", "this is the end of the test", UVM_LOW)
      
      phase.drop_objection(this, "TEST_DONE");
    endtask
  endclass

`endif