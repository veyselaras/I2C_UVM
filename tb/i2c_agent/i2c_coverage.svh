`ifndef I2C_COVERAGE_SVH
  `define I2C_COVERAGE_SVH

  class i2c_coverage extends uvm_subscriber#(i2c_transaction);
    
    `uvm_component_utils(i2c_coverage)
    
    bit [6:0] slave_addr;
    i2c_dir_e dir;
    bit [7:0] data;
    i2c_ack_e ack;
    
    covergroup i2c_cvg;
      option.per_instance = 1;
      option.name = "i2c_coverage";
      
      dir_cp: coverpoint dir {
        bins write_op = {I2C_WRITE};
        bins read_op  = {I2C_READ};
      }
      
      ack_cp: coverpoint ack {
        bins ack_ok  = {I2C_ACK};
        bins nack_op = {I2C_NACK};
      }
      
      addr_cp: coverpoint slave_addr {
        bins low_range  = {[7'h00 : 7'h3F]};
        bins high_range = {[7'h40 : 7'h7F]};
        bins target     = {7'h7F};
      }
      
      data_cp: coverpoint data {
        bins all_zeros = {8'h00};
        bins low_vals  = {[8'h01 : 8'h3F]};
        bins mid_vals  = {[8'h40 : 8'hBF]};
        bins high_vals = {[8'hC0 : 8'hFE]};
        bins all_ones  = {8'hFF};
      }
      
      dir_x_ack: cross dir_cp, ack_cp;
      
    endgroup
    
    function new(string name="i2c_coverage", uvm_component parent);
      super.new(name, parent);
      i2c_cvg = new();
    endfunction
    
    virtual function void write(i2c_transaction t);
      slave_addr = t.slave_addr;
      dir        = t.dir;
      data       = t.data;
      ack        = t.ack;
      
      i2c_cvg.sample();
    endfunction
    
    function void report_phase(uvm_phase phase);
      real total_cov, dir_cov, ack_cov, addr_cov, data_cov, cross_cov;
      super.report_phase(phase);

      total_cov = i2c_cvg.get_inst_coverage();
      dir_cov   = i2c_cvg.dir_cp.get_coverage();
      ack_cov   = i2c_cvg.ack_cp.get_coverage();
      addr_cov  = i2c_cvg.addr_cp.get_coverage();
      data_cov  = i2c_cvg.data_cp.get_coverage();
      cross_cov = i2c_cvg.dir_x_ack.get_coverage();

      `uvm_info("I2C_COV", $sformatf({
        "\n========================================",
        "\n        I2C COVERAGE REPORT",
        "\n========================================",
        "\n  Direction         : %6.2f%%",
        "\n  ACK/NACK          : %6.2f%%",
        "\n  Slave Address     : %6.2f%%",
        "\n  Data Values       : %6.2f%%",
        "\n  Direction x ACK   : %6.2f%%",
        "\n----------------------------------------",
        "\n  TOTAL             : %6.2f%%",
        "\n========================================"
      }, dir_cov, ack_cov, addr_cov, data_cov, cross_cov, total_cov), UVM_LOW)
    endfunction
    
  endclass

`endif