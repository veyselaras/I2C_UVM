`ifndef I2C_PKG_SVH
  `define I2C_PKG_SVH

  `include "uvm_macros.svh"
  `include "i2c_if.svh"

  package i2c_pkg;
    import uvm_pkg::*;

    `include "i2c_types.svh"
    `include "i2c_seq_item.svh"
    `include "i2c_transaction.svh"
    `include "i2c_agent_config.svh"
    `include "i2c_sequencer.svh"
    `include "i2c_forever_sequence.svh"
    `include "i2c_driver.svh"
    `include "i2c_monitor.svh"
	`include "i2c_coverage.svh"
    `include "i2c_agent.svh"
  endpackage
`endif