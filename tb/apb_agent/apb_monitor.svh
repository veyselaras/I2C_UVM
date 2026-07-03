`ifndef APB_MONITOR_SVH
  `define APB_MONITOR_SVH

  class apb_monitor extends uvm_monitor;
    `uvm_component_utils(apb_monitor)
    
    apb_vif vif;
    
    uvm_analysis_port #(apb_seq_item) ap;
    
    function new(string name="apb_monitor", uvm_component parent);
      super.new(name, parent);
      
      ap = new("item_collected_port", this);
    endfunction
    
    virtual task collect_transaction();
      apb_seq_item item = apb_seq_item::type_id::create("item");
      
      @(posedge vif.monitor_cb.psel);
      
      item.addr   = vif.monitor_cb.paddr;
      item.dir    = apb_dir_e'(vif.monitor_cb.pwrite);
      
      if (item.dir == APB_WRITE) begin
        item.wdata = vif.monitor_cb.pwdata;
      end
      
      @(posedge vif.monitor_cb.penable);
      
      while(vif.monitor_cb.pready !== 1) begin
        @(vif.monitor_cb);
      end
      
      if (item.dir == APB_READ) begin
        item.rdata = vif.monitor_cb.prdata;
      end
      
      item.slverr = apb_err_e'(vif.monitor_cb.pslverr);
      
      `uvm_info("APB_MON", $sformatf("Captured: %s", item.convert2string()), UVM_MEDIUM)
      
      ap.write(item);
    endtask
    
    virtual task collect_transactions();
      forever begin
        collect_transaction();
      end
    endtask
    
    virtual task run_phase(uvm_phase phase);
      super.run_phase(phase);
      collect_transactions();
    endtask
    
  endclass

`endif