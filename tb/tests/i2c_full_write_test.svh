`ifndef I2C_FULL_WRITE_TEST_SVH
  `define I2C_FULL_WRITE_TEST_SVH

  class i2c_full_write_test extends i2c_base_test;
    
    `uvm_component_utils(i2c_full_write_test)
    
    function new(string name = "i2c_full_write_test", uvm_component parent);
      super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
      phase.raise_objection(this, "TEST_DONE");
      
        fork
          begin
            i2c_forever_sequence i2c_seq = i2c_forever_sequence::type_id::create("i2c_seq");
            i2c_seq.start(env.agent_i2c.sequencer);
          end
        join_none
      
      #(100ns);
      
      begin
        apb_base_sequence seq;
        
//         1     PRE      0x000   0x0400  Prescaler (SCL hızı)
        seq = apb_base_sequence::type_id::create("seq");
      
        if (!seq.randomize() with { addr == 12'h000; wdata == 32'h0010; dir == APB_WRITE; }) begin
          `uvm_error("RAND_FAIL_TEST", "apb_item randomization failed due to constraint conflict!")
        end
        
        seq.start(env.agent_apb.sequencer);
      
        `uvm_info("TEST_DEBUG", $sformatf("item: %0s", seq.req.convert2string()), UVM_LOW)
//         2     CTR      0x004   0x0080  EN=1 (core enable)
        seq = apb_base_sequence::type_id::create("seq");
      
        if (!seq.randomize() with { addr == 12'h004; wdata == 32'h0080; dir == APB_WRITE; }) begin
          `uvm_error("RAND_FAIL_TEST", "apb_item randomization failed due to constraint conflict!")
        end
        
        seq.start(env.agent_apb.sequencer);
      
        `uvm_info("TEST_DEBUG", $sformatf("item: %0s", seq.req.convert2string()), UVM_LOW)
        
//         3     TX       0x010   0x00    slave_addr + W bit (sen belirle)
        seq = apb_base_sequence::type_id::create("seq");
      
        if (!seq.randomize() with { addr == 12'h010; wdata == 32'h00FE; dir == APB_WRITE; }) begin
          `uvm_error("RAND_FAIL_TEST", "apb_item randomization failed due to constraint conflict!")
        end
        
        seq.start(env.agent_apb.sequencer);
      
        `uvm_info("TEST_DEBUG", $sformatf("item: %0s", seq.req.convert2string()), UVM_LOW)
        
//         4     CMD      0x014   0x0090  STA=1, WR=1 (START + write)
        seq = apb_base_sequence::type_id::create("seq");
      
        if (!seq.randomize() with { addr == 12'h014; wdata == 32'h0090; dir == APB_WRITE; }) begin
          `uvm_error("RAND_FAIL_TEST", "apb_item randomization failed due to constraint conflict!")
        end
        
        seq.start(env.agent_apb.sequencer);
      
        `uvm_info("TEST_DEBUG", $sformatf("item: %0s", seq.req.convert2string()), UVM_LOW)
        
//         5     SR       0x00C   poll    TIP(bit1)=0 olana kadar READ
        env.agent_apb.driver.set_report_verbosity_level(UVM_NONE);
        env.agent_apb.monitor.set_report_verbosity_level(UVM_NONE);
        do begin
          seq = apb_base_sequence::type_id::create("seq");
          if (!seq.randomize() with { addr == 12'h00C; dir == APB_READ; delay == 0; }) begin
            `uvm_error("RAND_FAIL_TEST", "apb_item randomization failed due to constraint conflict!")
          end
          seq.start(env.agent_apb.sequencer);
        end while(seq.req.rdata[1] == 1);  // TIP hâlâ 1 → tekrar oku
        env.agent_apb.driver.set_report_verbosity_level(UVM_MEDIUM);
        env.agent_apb.monitor.set_report_verbosity_level(UVM_MEDIUM);
//         6     SR       0x00C   kontrol RxACK(bit7)=0 ise ACK gelmiş
        if(seq.req.rdata[7] == 1) `uvm_error("I2C_NACK", "Slave did not acknowledge the address")
        else `uvm_info("TEST_DEBUG", "Slave ACK received", UVM_LOW)
        
//         7     TX       0x010   0xAB    data byte
        seq = apb_base_sequence::type_id::create("seq");
      
        if (!seq.randomize() with { addr == 12'h010; wdata == 32'h00AB; dir == APB_WRITE; }) begin
          `uvm_error("RAND_FAIL_TEST", "apb_item randomization failed due to constraint conflict!")
        end
        
        seq.start(env.agent_apb.sequencer);
      
        `uvm_info("TEST_DEBUG", $sformatf("item: %0s", seq.req.convert2string()), UVM_LOW)
        
//         8     CMD      0x014   0x0010  WR=1 (data gönder)
        seq = apb_base_sequence::type_id::create("seq");
      
        if (!seq.randomize() with { addr == 12'h014; wdata == 32'h0010; dir == APB_WRITE; }) begin
          `uvm_error("RAND_FAIL_TEST", "apb_item randomization failed due to constraint conflict!")
        end
        
        seq.start(env.agent_apb.sequencer);
      
        `uvm_info("TEST_DEBUG", $sformatf("item: %0s", seq.req.convert2string()), UVM_LOW)
        
//         9     SR       0x00C   poll    TIP=0 bekle
        env.agent_apb.driver.set_report_verbosity_level(UVM_NONE);
        env.agent_apb.monitor.set_report_verbosity_level(UVM_NONE);
        do begin
          seq = apb_base_sequence::type_id::create("seq");
          if (!seq.randomize() with { addr == 12'h00C; dir == APB_READ; delay == 0; delay == 0; }) begin
            `uvm_error("RAND_FAIL_TEST", "apb_item randomization failed due to constraint conflict!")
          end
          seq.start(env.agent_apb.sequencer);
        end while(seq.req.rdata[1] == 1);  // TIP hâlâ 1 → tekrar oku
        env.agent_apb.driver.set_report_verbosity_level(UVM_MEDIUM);
        env.agent_apb.monitor.set_report_verbosity_level(UVM_MEDIUM);
        // Adım 9 polling sonrası
        if(seq.req.rdata[7] == 1)
          `uvm_error("I2C_NACK", "Slave did not acknowledge the data byte")
        else
          `uvm_info("TEST_DEBUG", "Data byte ACK received", UVM_LOW)
        
//         10    CMD      0x014   0x0040  STO=1 (STOP gönder)
        seq = apb_base_sequence::type_id::create("seq");
      
        if (!seq.randomize() with { addr == 12'h014; wdata == 32'h0040; dir == APB_WRITE; delay == 0; }) begin
          `uvm_error("RAND_FAIL_TEST", "apb_item randomization failed due to constraint conflict!")
        end
        
        seq.start(env.agent_apb.sequencer);
      
        `uvm_info("TEST_DEBUG", $sformatf("item: %0s", seq.req.convert2string()), UVM_LOW)
        #(5us);
        
      end
      #(100ns);
      `uvm_info("TEST_DEBUG", "this is the end of the test", UVM_LOW)
      
      phase.drop_objection(this, "TEST_DONE");
    endtask
  endclass

`endif