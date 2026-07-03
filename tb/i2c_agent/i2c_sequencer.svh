`ifndef I2C_SEQUENCER_SVH
  `define I2C_SEQUENCER_SVH

  class i2c_sequencer extends uvm_sequencer#(i2c_seq_item);
    `uvm_component_utils(i2c_sequencer)
    
    uvm_analysis_export#(i2c_transaction) request_export;
    uvm_tlm_analysis_fifo#(i2c_transaction) request_fifo;
    
    function new(string name="i2c_sequencer", uvm_component parent);
      super.new(name, parent);
      request_export = new("request_export", this);
      request_fifo = new("request_fifo", this);
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      
      request_export.connect(request_fifo.analysis_export);
    endfunction
    
  endclass

`endif