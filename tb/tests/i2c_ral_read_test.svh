`ifndef I2C_RAL_READ_TEST_SVH
  `define I2C_RAL_READ_TEST_SVH

  class i2c_ral_read_test extends i2c_base_test;
    `uvm_component_utils(i2c_ral_read_test)
    
    function new(string name = "i2c_ral_read_test", uvm_component parent);
      super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
      uvm_status_e   status;
      uvm_reg_data_t rdata;
      
      phase.raise_objection(this, "TEST_DONE");
      
      uvm_config_db#(bit[7:0])::set(this, "*", "read_data", 8'h55);
      
      // Forever sequence'ı paralel başlat
      fork
        begin
          i2c_forever_sequence i2c_seq = i2c_forever_sequence::type_id::create("i2c_seq");
          i2c_seq.start(env.agent_i2c.sequencer);
        end
      join_none
      
      #100ns;
      
      // 1. PRE prescaler
      env.model.reg_block.PRE.write(status, 16'h0010);
      
      // 2. CTR enable
      env.model.reg_block.CTR.write(status, 8'h80);
      
      // 3. TX = 0xFF (slave addr 0x7F + R bit)
      env.model.reg_block.TX.write(status, 8'hFF);
      
      // 4. CMD = 0x90 (START + WRITE, adres göndermek için hâlâ WRITE)
      env.model.reg_block.CMD.write(status, 8'h90);
      
      // 5. Poll TIP=0
      env.agent_apb.driver.set_report_verbosity_level(UVM_NONE);
      env.agent_apb.monitor.set_report_verbosity_level(UVM_NONE);
      do begin
        env.model.reg_block.STATUS.read(status, rdata);
      end while(rdata[1] == 1);
      env.agent_apb.driver.set_report_verbosity_level(UVM_MEDIUM);
      env.agent_apb.monitor.set_report_verbosity_level(UVM_MEDIUM);
      
      // 6. Check RxACK
      if(rdata[7] == 1)
        `uvm_error("I2C_NACK", "Slave did not acknowledge the address")
      else
        `uvm_info("RAL_TEST", "Slave ACK received", UVM_LOW)
      
      // 7. CMD = 0x20 (RD - data oku)
      env.model.reg_block.CMD.write(status, 8'h20);
      
      // 8. Poll TIP=0
      env.agent_apb.driver.set_report_verbosity_level(UVM_NONE);
      env.agent_apb.monitor.set_report_verbosity_level(UVM_NONE);
      do begin
        env.model.reg_block.STATUS.read(status, rdata);
      end while(rdata[1] == 1);
      env.agent_apb.driver.set_report_verbosity_level(UVM_MEDIUM);
      env.agent_apb.monitor.set_report_verbosity_level(UVM_MEDIUM);
      
      if(rdata[7] == 1)
        `uvm_error("I2C_NACK", "Slave did not acknowledge the data byte")
      else
        `uvm_info("RAL_TEST", "Data byte ACK received", UVM_LOW)
      
      // 9. RX register oku
      env.model.reg_block.RX.read(status, rdata);
      `uvm_info("READ_TEST", $sformatf("RX read: 0x%02h", rdata[7:0]), UVM_LOW)
      
      // 10. CMD = 0x40 (STOP)
      env.model.reg_block.CMD.write(status, 8'h40);
      
      #5us;
      `uvm_info("READ_TEST", "end of test", UVM_LOW)
      
      phase.drop_objection(this, "TEST_DONE");
    endtask
  endclass

`endif