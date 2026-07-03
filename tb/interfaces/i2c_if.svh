`ifndef I2C_IF_SVH
  `define I2C_IF_SVH

interface i2c_if (
  input logic clk,
  input logic reset_n
);

  // -------------------------------------------------------
  // DUT side signals (directly connected to apb_i2c ports)
  // -------------------------------------------------------
  logic scl_pad_i;
  logic scl_pad_o;
  logic scl_padoen_o;   // active low: 0 = driving, 1 = released

  logic sda_pad_i;
  logic sda_pad_o;
  logic sda_padoen_o;   // active low: 0 = driving, 1 = released

  // -------------------------------------------------------
  // Slave side drive signals (testbench reactive agent)
  // -------------------------------------------------------
  logic slave_scl_o;    // slave SCL drive (1 = release, 0 = pull low)
  logic slave_sda_o;    // slave SDA drive (1 = release, 0 = pull low)

  // -------------------------------------------------------
  // Open-drain bus model (wired-AND with pullup)
  //   line = 0 if anyone pulls low, 1 only if all release
  // -------------------------------------------------------
  wire scl_line = (scl_padoen_o ? 1'b1 : scl_pad_o) & slave_scl_o;
  wire sda_line = (sda_padoen_o ? 1'b1 : sda_pad_o) & slave_sda_o;

  // Feed bus line values back to DUT
  assign scl_pad_i = scl_line;
  assign sda_pad_i = sda_line;

  // Default: slave releases both lines
  initial begin
    slave_scl_o = 1'b1;
    slave_sda_o = 1'b1;
  end

  // -------------------------------------------------------
  // Clocking blocks
  // -------------------------------------------------------

  // Reactive slave driver: drives SDA based on SCL edges
  clocking slave_cb @(posedge clk);
    default input #1 output #1;
    input  scl_line, sda_line;
    input  scl_padoen_o, sda_padoen_o;
    output slave_scl_o, slave_sda_o;
  endclocking

  // Monitor: samples the actual bus lines
  clocking monitor_cb @(posedge clk);
    default input #1;
    input scl_line, sda_line;
    input scl_padoen_o, sda_padoen_o;
    input scl_pad_o, sda_pad_o;
  endclocking

  modport slave   (clocking slave_cb,   input clk);
  modport monitor (clocking monitor_cb, input clk);
    
    // =========================================================================
    // GROUP 1: Bus Idle at Reset
    // Ensures the I2C bus is in idle state (both lines HIGH) during reset
    // =========================================================================
    
    // I2C bus must be released (both SCL and SDA HIGH) while reset is asserted
    sequence S_I2C_BUS_IDLE_AT_RESET;
      scl_line & sda_line;
    endsequence
    
    property P_I2C_BUS_IDLE_AT_RESET;
      @(posedge clk) !reset_n |-> S_I2C_BUS_IDLE_AT_RESET;
    endproperty
    
    A_I2C_BUS_IDLE_AT_RESET: assert property(P_I2C_BUS_IDLE_AT_RESET) else
      $error("I2C bus must be idle (SCL=1, SDA=1) during reset");
      
    // =========================================================================
    // GROUP 2: Unknown (X/Z) checks
    // Ensures I2C bus lines carry valid logic values after reset
    // =========================================================================

    // SCL line must be known at all times after reset (no X/Z)
    sequence S_SCL_NO_X;
      !$isunknown(scl_line);
    endsequence
    
    property P_SCL_NO_X;
      @(posedge clk) 
      disable iff(!reset_n)
      S_SCL_NO_X;
    endproperty
    
    A_SCL_NO_X: assert property(P_SCL_NO_X) else
      $error("SCL must not be X/Z after reset");
      
    // SDA line must be known at all times after reset (no X/Z)
    sequence S_SDA_NO_X;
      !$isunknown(sda_line);
    endsequence
    
    property P_SDA_NO_X;
      @(posedge clk) 
      disable iff(!reset_n)
      S_SDA_NO_X;
    endproperty
    
    A_SDA_NO_X: assert property(P_SDA_NO_X) else
      $error("SDA must not be X/Z after reset");


endinterface
    
`endif