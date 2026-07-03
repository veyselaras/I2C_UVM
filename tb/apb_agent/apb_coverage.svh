`ifndef APB_COVERAGE_SVH
  `define APB_COVERAGE_SVH

  class apb_coverage extends uvm_subscriber#(apb_seq_item);
    
    `uvm_component_utils(apb_coverage)
    
    bit [11:0]  addr;
    bit [31:0]  wdata;
    apb_dir_e   dir;
    
    // DUT will assert these signals so, we can't implement it as a rand
    apb_err_e        slverr;
    
    covergroup apb_cvg;
      option.per_instance = 1;
      option.name = "apb_coverage";
      
      wr_cp: coverpoint dir{
        bins write_op = {APB_WRITE};
        bins read_op = {APB_READ};
      }
      
      err_cp: coverpoint slverr{
        bins error = {APB_ERR};
        bins done = {APB_DONE};
      }
      
      wdata_cp: coverpoint wdata{
        bins all_zeros = {32'h0000_0000};
        bins low_vals  = {[32'h0000_0001 : 32'h0000_FFFF]};
        bins mid_vals  = {[32'h0001_0000 : 32'hFFFE_FFFF]};
        bins high_vals = {[32'hFFFF_0000 : 32'hFFFF_FFFE]};
        bins all_ones  = {32'hFFFF_FFFF};
      }
      
      addr_cp: coverpoint addr {
        bins prescaler = {12'h000};
        bins control   = {12'h004};
        bins rx_data   = {12'h008};
        bins status    = {12'h00c};
        bins tx_data   = {12'h010};
        bins command   = {12'h014};
      }
      
      dir_x_addr: cross wr_cp, addr_cp;
    endgroup
    
    function new(string name="apb_coverage", uvm_component parent);
      super.new(name, parent);
      
      apb_cvg = new();
    endfunction
    
    virtual function void write(apb_seq_item t);
      addr = t.addr;
      wdata = t.wdata;
      dir = t.dir;
      slverr = t.slverr;
      
      apb_cvg.sample();
    endfunction
    
    function void report_phase(uvm_phase phase);
      real total_cov, addr_cov, dir_cov, wdata_cov, err_cov, cross_cov;
      super.report_phase(phase);

      total_cov = apb_cvg.get_inst_coverage();
      addr_cov  = apb_cvg.addr_cp.get_coverage();
      dir_cov   = apb_cvg.wr_cp.get_coverage();
      wdata_cov = apb_cvg.wdata_cp.get_coverage();
      err_cov   = apb_cvg.err_cp.get_coverage();
      cross_cov = apb_cvg.dir_x_addr.get_coverage();

      `uvm_info("APB_COV", $sformatf({
        "\n========================================",
        "\n        APB COVERAGE REPORT",
        "\n========================================",
        "\n  Address           : %6.2f%%",
        "\n  Direction         : %6.2f%%",
        "\n  Write Data        : %6.2f%%",
        "\n  Error Response    : %6.2f%%",
        "\n  Direction x Addr  : %6.2f%%",
        "\n----------------------------------------",
        "\n  TOTAL             : %6.2f%%",
        "\n========================================"
      }, addr_cov, dir_cov, wdata_cov, err_cov, cross_cov, total_cov), UVM_LOW)
    endfunction
    
  endclass

`endif