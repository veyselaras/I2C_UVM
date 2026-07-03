`include "test_pkg.svh"

module testbench();
  
  import uvm_pkg::*;
  import test_pkg::*;

  reg clk;
  logic reset_n;
  
  initial begin
    clk = 0;
    forever clk = #5ns ~clk;
  end
  
  // Reset
  initial begin
    reset_n = 1;
    #4;
    reset_n = 0;
    #20;
    reset_n = 1;
  end
  
  // Interfaces
  apb_if  inst_apb_if(.pclk(clk), .preset_n(reset_n));
  i2c_if  inst_i2c_if(.clk(clk), .reset_n(reset_n));

  apb_i2c dut (
    .HCLK         (clk),
    .HRESETn      (reset_n),

    // APB
    .PADDR        (inst_apb_if.paddr),
    .PWDATA       (inst_apb_if.pwdata),
    .PWRITE       (inst_apb_if.pwrite),
    .PSEL         (inst_apb_if.psel),
    .PENABLE      (inst_apb_if.penable),
    .PRDATA       (inst_apb_if.prdata),
    .PREADY       (inst_apb_if.pready),
    .PSLVERR      (inst_apb_if.pslverr),
    .interrupt_o  (inst_apb_if.interrupt_o),

    // I2C
    .scl_pad_i    (inst_i2c_if.scl_pad_i),
    .scl_pad_o    (inst_i2c_if.scl_pad_o),
    .scl_padoen_o (inst_i2c_if.scl_padoen_o),
    .sda_pad_i    (inst_i2c_if.sda_pad_i),
    .sda_pad_o    (inst_i2c_if.sda_pad_o),
    .sda_padoen_o (inst_i2c_if.sda_padoen_o)
  );
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
    
    uvm_config_db#(virtual apb_if)::set(null, "*", "apb_vif", inst_apb_if);
    uvm_config_db#(virtual i2c_if)::set(null, "*", "i2c_vif", inst_i2c_if);
    run_test();
  end
  
endmodule