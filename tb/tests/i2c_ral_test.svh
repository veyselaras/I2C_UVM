`ifndef I2C_RAL_TEST_SVH
  `define I2C_RAL_TEST_SVH

  class i2c_ral_test extends i2c_base_test;
    `uvm_component_utils(i2c_ral_test)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      #100ns;

      // PRE register — RW, volatile=0, check edilecek
      begin
        apb_base_sequence seq = apb_base_sequence::type_id::create("seq");
        void'(seq.randomize() with { addr == 12'h000; wdata == 32'h0010; dir == APB_WRITE; delay == 0; });
        seq.start(env.agent_apb.sequencer);
      end

      begin
        apb_base_sequence seq = apb_base_sequence::type_id::create("seq");
        void'(seq.randomize() with { addr == 12'h000; dir == APB_READ; delay == 0; });
        seq.start(env.agent_apb.sequencer);
      end

      // CTR register — RW, volatile=0, check edilecek
      begin
        apb_base_sequence seq = apb_base_sequence::type_id::create("seq");
        void'(seq.randomize() with { addr == 12'h004; wdata == 32'h0080; dir == APB_WRITE; delay == 0; });
        seq.start(env.agent_apb.sequencer);
      end

      begin
        apb_base_sequence seq = apb_base_sequence::type_id::create("seq");
        void'(seq.randomize() with { addr == 12'h004; dir == APB_READ; delay == 0; });
        seq.start(env.agent_apb.sequencer);
      end

      // TX register — RW, volatile=0, check edilecek
      begin
        apb_base_sequence seq = apb_base_sequence::type_id::create("seq");
        void'(seq.randomize() with { addr == 12'h010; wdata == 32'h00AB; dir == APB_WRITE; delay == 0; });
        seq.start(env.agent_apb.sequencer);
      end

      begin
        apb_base_sequence seq = apb_base_sequence::type_id::create("seq");
        void'(seq.randomize() with { addr == 12'h010; dir == APB_READ; delay == 0; });
        seq.start(env.agent_apb.sequencer);
      end

      #100ns;
      `uvm_info("RAL_TEST", "end of test", UVM_LOW)
      phase.drop_objection(this);
    endtask
  endclass

`endif