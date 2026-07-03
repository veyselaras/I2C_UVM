`ifndef APB_BASE_SEQUENCE_SVH
  `define APB_BASE_SEQUENCE_SVH

  class apb_base_sequence extends uvm_sequence#(apb_seq_item);
    `uvm_object_utils(apb_base_sequence)
    `uvm_declare_p_sequencer(apb_sequencer)

    rand bit [11:0]  addr;
    rand bit [31:0]  wdata;
    rand apb_dir_e   dir;
    rand int unsigned delay;
    
    constraint delay_default {
      soft delay <= 10;
    }

    constraint addr_range {
      soft addr inside {12'h000, 12'h004, 12'h008,
                        12'h00c, 12'h010, 12'h014};
    }

    function new(string name="apb_base_sequence");
      super.new(name);
    endfunction

    virtual task body();
      req = apb_seq_item::type_id::create("req");

      start_item(req);

      if (!req.randomize() with {
        addr  == local::addr;
        wdata == local::wdata;
        dir   == local::dir;
        delay == local::delay;
      }) begin
        `uvm_error("RAND_FAIL_SEQUENCE", "req randomization failed!")
      end

      finish_item(req);
    endtask

  endclass

`endif