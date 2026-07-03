`ifndef APB_DRIVER_SVH
  `define APB_DRIVER_SVH

  class apb_driver extends uvm_driver#(.REQ(apb_seq_item));
    `uvm_component_utils(apb_driver)
    
    apb_vif vif;
    
    function new(string name="apb_driver", uvm_component parent);
      super.new(name, parent);
    endfunction
    
    protected task drive_transaction();
      apb_seq_item tr;
      seq_item_port.get_next_item(tr);
      
      `uvm_info("APB_DRV", $sformatf("Driving: %s", tr.convert2string()), UVM_MEDIUM)
      
      @(vif.master_cb);
      
      for(int i = 0; i < tr.delay; i++) begin
        @(vif.master_cb);
      end
      
      
      vif.master_cb.psel <= 1;
      vif.master_cb.pwrite <= bit'(tr.dir);
      vif.master_cb.paddr <= tr.addr;
      
      if(tr.dir == APB_WRITE) begin
        vif.master_cb.pwdata <= tr.wdata;
      end
      
      @(vif.master_cb);
      
      vif.master_cb.penable <= 1;
      @(vif.master_cb);
      
      while(vif.master_cb.pready !== 1) begin
        @(vif.master_cb);
      end
      
      if(tr.dir == APB_READ)
        tr.rdata = vif.master_cb.prdata;
      tr.slverr = vif.master_cb.pslverr;
      
      
      vif.master_cb.psel    <= 0;
      vif.master_cb.penable <= 0;
      vif.master_cb.pwrite  <= 0;
      vif.master_cb.paddr   <= 0;
      vif.master_cb.pwdata  <= 0;
      
      
      seq_item_port.item_done();
    endtask
    
    protected task drive_transactions();
        vif.master_cb.psel    <= 0;
        vif.master_cb.penable <= 0;
        vif.master_cb.pwrite  <= 0;
        vif.master_cb.paddr   <= 0;
        vif.master_cb.pwdata  <= 0;
      forever begin
        drive_transaction();
      end
    endtask
    
    virtual task run_phase(uvm_phase phase);
      super.run_phase(phase);
      drive_transactions();
    endtask
    
  endclass


`endif