`ifndef TEST_PKG_SVH
  `define TEST_PKG_SVH

  `include "uvm_macros.svh"
  `include "main_pkg.svh"

  package test_pkg;
    import uvm_pkg::*;
    import main_pkg::*;
    import apb_pkg::*;
    import i2c_pkg::*;

    `include "i2c_base_test.svh"
    `include "i2c_reg_access_test.svh"
    `include "i2c_single_write_test.svh"
    `include "i2c_full_write_test.svh"
	`include "i2c_ral_test.svh"
	`include "i2c_ral_write_test.svh"
	`include "i2c_ral_read_test.svh"
    //`include "i2c_single_read_test.svh"
    //`include "i2c_interrupt_test.svh"
    //`include "i2c_arb_lost_test.svh"
  endpackage

`endif