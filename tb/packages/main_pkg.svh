`ifndef MAIN_PKG_SVH
  `define MAIN_PKG_SVH

  `include "uvm_macros.svh"
  `include "i2c_pkg.svh"
  `include "apb_pkg.svh"
  `include "i2c_reg_pkg.svh"

  package main_pkg;
    import uvm_pkg::*;
    import i2c_pkg::*;
    import apb_pkg::*;
	import i2c_reg_pkg::*;

	`include "i2c_reg_adapter.svh"
	`include "i2c_model.svh"
	`include "i2c_scoreboard.svh"
    `include "i2c_env.svh"
  endpackage
`endif