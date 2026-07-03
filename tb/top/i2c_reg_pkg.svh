`ifndef I2C_REG_PKG_SV
  `define I2C_REG_PKG_SV

  package i2c_reg_pkg;
    import uvm_pkg::*;

    `include "i2c_reg_pre.svh"
    `include "i2c_reg_ctr.svh"
    `include "i2c_reg_tx.svh"
    `include "i2c_reg_rx.svh"
    `include "i2c_reg_cmd.svh"
    `include "i2c_reg_status.svh"
	`include "i2c_reg_block.svh"

  endpackage

`endif