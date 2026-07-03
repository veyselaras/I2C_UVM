`ifndef I2C_REG_ADAPTER_SVH
  `define I2C_REG_ADAPTER_SVH

  class i2c_reg_adapter extends uvm_reg_adapter;
    
    `uvm_object_utils(i2c_reg_adapter)
    
    function new(string name = "i2c_reg_adapter");
      super.new(name);  
    endfunction
    
    virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
      apb_seq_item seq_item;
      
      if($cast(seq_item, bus_item)) begin
        rw.kind = seq_item.dir == APB_READ? UVM_READ : UVM_WRITE;
        rw.addr = seq_item.addr;
        rw.data = (seq_item.dir == APB_WRITE) ? seq_item.wdata : seq_item.rdata;
        rw.status = (seq_item.slverr == APB_ERR) ? UVM_NOT_OK : UVM_IS_OK;
      end
      else begin
        `uvm_fatal("ALGORITHM_ISSUE", $sformatf("Class not supported: %0s", bus_item.get_type_name()))
      end
    endfunction
    
    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
      apb_seq_item seq_item = apb_seq_item::type_id::create("seq_item");

      seq_item.addr  = rw.addr;
      seq_item.dir   = (rw.kind == UVM_WRITE) ? APB_WRITE : APB_READ;
      seq_item.wdata = rw.data;
      seq_item.delay = 0;

      return seq_item;
    endfunction

  endclass

`endif