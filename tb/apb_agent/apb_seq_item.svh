`ifndef APB_SEQ_ITEM_SVH
  `define APB_SEQ_ITEM_SVH

  class apb_seq_item extends uvm_sequence_item;
    `uvm_object_utils(apb_seq_item)
    
    rand bit [11:0]  addr;
    rand bit [31:0]  wdata;
    rand apb_dir_e   dir;
    
    // Delay for blocking back to back transaction
    rand int unsigned delay;
    
	// DUT will assert these signals so, we can't implement it as a rand
    bit [31:0]       rdata;
    apb_err_e        slverr;
    
    constraint addr_range{
      soft addr inside {
        12'h000,
        12'h004,
        12'h008,
        12'h00c,
        12'h010,
        12'h014
      };
    }
    
    constraint delay_range{
      soft delay <= 10;
    }
    
    function new(string name="apb_seq_item");
      super.new(name);
    endfunction
    
    function string convert2string();
      return $sformatf("dir=%s addr=0x%03h wdata=0x%08h rdata=0x%08h slverr=%0b delay=%0d",
                   dir.name(), addr, wdata, rdata, slverr, delay);
    endfunction
    
  endclass


`endif