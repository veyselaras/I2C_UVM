`ifndef APB_IF_SVH
  `define APB_IF_SVH

  `ifndef CFS_APB_MAX_DATA_WIDTH
  	`define CFS_APB_MAX_DATA_WIDTH 32
  `endif

  `ifndef CFS_APB_MAX_ADDR_WIDTH
  	`define CFS_APB_MAX_ADDR_WIDTH 12
  `endif

interface apb_if #(
  parameter ADDR_WIDTH = 12
)(
  input logic pclk,
  input logic preset_n
);

  logic [ADDR_WIDTH-1:0] paddr;
  logic [`CFS_APB_MAX_DATA_WIDTH-1:0]           pwdata;
  logic                  pwrite;
  logic                  psel;
  logic                  penable;
  logic [`CFS_APB_MAX_DATA_WIDTH-1:0]           prdata;
  logic                  pready;
  logic                  pslverr;
  logic                  interrupt_o;

  // Master drives these signals
  clocking master_cb @(posedge pclk);
    default input #1 output #1;
    output paddr, pwdata, pwrite, psel, penable;
    input  prdata, pready, pslverr, interrupt_o;
  endclocking

  // Monitor samples all signals
  clocking monitor_cb @(posedge pclk);
    default input #1;
    input paddr, pwdata, pwrite, psel, penable;
    input prdata, pready, pslverr, interrupt_o;
  endclocking

  modport master  (clocking master_cb,  input pclk, input preset_n);
  modport monitor (clocking monitor_cb, input pclk, input preset_n);
    
    // =========================================================================
    // GROUP 1: Unknown (X/Z) checks
    // Ensures no signal carries unknown values during active operation
    // =========================================================================

    // PSEL must be known at all times after reset
    sequence S_APB_PSEL_NO_X;
      $isunknown(psel) == 0;
    endsequence
    
    property P_APB_PSEL_NO_X;
      @(posedge pclk)
      disable iff(!preset_n)
      S_APB_PSEL_NO_X;
    endproperty
    
    A_APB_PSEL_NO_X: assert property(P_APB_PSEL_NO_X) else
      $error("PSEL must not be X/Z after reset");


    // PENABLE must be known at all times after reset
    sequence S_APB_PENABLE_NO_X;
      $isunknown(penable) == 0;
    endsequence
    
    property P_APB_PENABLE_NO_X;
      @(posedge pclk)
      disable iff(!preset_n)
      S_APB_PENABLE_NO_X;
    endproperty
    
    A_APB_PENABLE_NO_X: assert property(P_APB_PENABLE_NO_X) else
      $error("PENABLE must not be X/Z after reset");


    // PADDR must be known whenever a slave is selected
    property P_APB_PADDR_NO_X_WHEN_SELECTED;
      @(posedge pclk)
      disable iff(!preset_n)
      psel |-> ($isunknown(paddr) == 0);
    endproperty
    
    A_APB_PADDR_NO_X_WHEN_SELECTED: assert property(P_APB_PADDR_NO_X_WHEN_SELECTED) else
      $error("PADDR must not be X/Z when PSEL is asserted");


    // PWDATA must be known during a write transfer
    sequence S_APB_PWDATA_NO_X_WHEN_WRITE;
      psel && pwrite;
    endsequence
      
    property P_APB_PWDATA_NO_X_WHEN_WRITE;
      @(posedge pclk)
      disable iff(!preset_n)
      S_APB_PWDATA_NO_X_WHEN_WRITE |-> ($isunknown(pwdata) == 0);
    endproperty
      
    A_APB_PWDATA_NO_X_WHEN_WRITE: assert property(P_APB_PWDATA_NO_X_WHEN_WRITE) else
      $error("PWDATA must not be X/Z during write transfer");


    // PWRITE must be known whenever a slave is selected
    property P_APB_PWRITE_NO_X_WHEN_SELECTED;
      @(posedge pclk)
      disable iff(!preset_n)
      psel |-> ($isunknown(pwrite) == 0);
    endproperty
    
    A_APB_PWRITE_NO_X_WHEN_SELECTED: assert property(P_APB_PWRITE_NO_X_WHEN_SELECTED) else
      $error("PWRITE must not be X/Z when PSEL is asserted");


    // PREADY must be known during access phase
    property P_APB_PREADY_NO_X_WHEN_ACCESS;
      @(posedge pclk)
      disable iff(!preset_n)
      penable |-> ($isunknown(pready) == 0);
    endproperty
    
    A_APB_PREADY_NO_X_WHEN_ACCESS: assert property(P_APB_PREADY_NO_X_WHEN_ACCESS) else
      $error("PREADY must not be X/Z during access phase");


    // PRDATA must be known when a read transfer completes
    sequence S_APB_PRDATA_NO_X_WHEN_READ_COMPLETE;
      (pwrite == 0) && psel && penable && pready;
    endsequence
    
    property P_APB_PRDATA_NO_X_WHEN_READ_COMPLETE;
      @(posedge pclk)
      disable iff(!preset_n)
      S_APB_PRDATA_NO_X_WHEN_READ_COMPLETE |-> ($isunknown(prdata) == 0);
    endproperty
    
    A_APB_PRDATA_NO_X_WHEN_READ_COMPLETE: assert property(P_APB_PRDATA_NO_X_WHEN_READ_COMPLETE) else
      $error("PRDATA must not be X/Z when read transfer completes");


    // =========================================================================
    // GROUP 2: State transition rules
    // Ensures correct SETUP -> ACCESS -> IDLE state machine behavior
    // =========================================================================

    // Setup phase must transition to access phase in exactly one cycle
    property P_APB_PENABLE_FOLLOWS_PSEL;
      @(posedge pclk)
      disable iff(!preset_n)
      (psel && !penable) |-> ##1 penable;
    endproperty
      
    A_APB_PENABLE_FOLLOWS_PSEL: assert property(P_APB_PENABLE_FOLLOWS_PSEL) else
      $error("PENABLE must be asserted one cycle after PSEL is asserted");


    // PENABLE cannot be asserted without PSEL — no orphan access phase
    property P_APB_NO_PENABLE_WITHOUT_PSEL;
      @(posedge pclk)
      disable iff(!preset_n)
      penable |-> psel;
    endproperty
      
    A_APB_NO_PENABLE_WITHOUT_PSEL: assert property(P_APB_NO_PENABLE_WITHOUT_PSEL) else
      $error("PENABLE must not be asserted without PSEL");


    // PENABLE must deassert after a completed transfer (PREADY=1)
    sequence S_APB_PENABLE_DEASSERT_AFTER_TRANSFER;
      psel && penable && pready;
    endsequence

    property P_APB_PENABLE_DEASSERT_AFTER_TRANSFER;
      @(posedge pclk)
      disable iff(!preset_n)
      S_APB_PENABLE_DEASSERT_AFTER_TRANSFER |-> ##1 $fell(penable);
    endproperty
      
    A_APB_PENABLE_DEASSERT_AFTER_TRANSFER: assert property(P_APB_PENABLE_DEASSERT_AFTER_TRANSFER) else
      $error("PENABLE must be deasserted after transfer completes (PENABLE=1 and PREADY=1)");


    // =========================================================================
    // GROUP 3: Signal stability during access phase
    // ARM spec requires control and data signals remain stable until transfer ends
    // =========================================================================

    // PADDR must not change while PENABLE is asserted
    property P_APB_PADDR_STABLE_DURING_ACCESS;
      @(posedge pclk)
      disable iff(!preset_n)
      penable |-> $stable(paddr);
    endproperty
      
    A_APB_PADDR_STABLE_DURING_ACCESS: assert property(P_APB_PADDR_STABLE_DURING_ACCESS) else
      $error("PADDR must remain stable during access phase");


    // PWRITE must not change while PENABLE is asserted
    property P_APB_PWRITE_STABLE_DURING_ACCESS;
      @(posedge pclk)
      disable iff(!preset_n)
      penable |-> $stable(pwrite);
    endproperty
      
    A_APB_PWRITE_STABLE_DURING_ACCESS: assert property(P_APB_PWRITE_STABLE_DURING_ACCESS) else
      $error("PWRITE must remain stable during access phase");


    // PSEL must not change while PENABLE is asserted
    property P_APB_PSEL_STABLE_DURING_ACCESS;
      @(posedge pclk)
      disable iff(!preset_n)
      penable |-> $stable(psel);
    endproperty
      
    A_APB_PSEL_STABLE_DURING_ACCESS: assert property(P_APB_PSEL_STABLE_DURING_ACCESS) else
      $error("PSEL must remain stable during access phase");


    // PWDATA must not change during a write access phase
    sequence S_APB_PWDATA_STABLE_DURING_WRITE;
      penable && pwrite;
    endsequence
      
    property P_APB_PWDATA_STABLE_DURING_WRITE;
      @(posedge pclk)
      disable iff(!preset_n)
      S_APB_PWDATA_STABLE_DURING_WRITE |-> $stable(pwdata);
    endproperty
      
    A_APB_PWDATA_STABLE_DURING_WRITE: assert property(P_APB_PWDATA_STABLE_DURING_WRITE) else
      $error("PWDATA must remain stable during write access phase");


    // =========================================================================
    // GROUP 4: PSLVERR rules
    // Error signal is only meaningful at the point of transfer completion
    // =========================================================================

    // PSLVERR may only be asserted when a transfer is completing
    sequence S_APB_PSLVERR_VALID_ONLY_ON_COMPLETION;
      psel && penable && pready;
    endsequence
      
    property P_APB_PSLVERR_VALID_ONLY_ON_COMPLETION;
      @(posedge pclk)
      disable iff(!preset_n)
      pslverr |-> S_APB_PSLVERR_VALID_ONLY_ON_COMPLETION;
    endproperty
      
    A_APB_PSLVERR_VALID_ONLY_ON_COMPLETION: assert property(P_APB_PSLVERR_VALID_ONLY_ON_COMPLETION) else
      $error("PSLVERR is only valid when PSEL, PENABLE and PREADY are all HIGH");


    // PSLVERR should be driven low when no transfer is completing (recommended)
    property P_APB_PSLVERR_LOW_WHEN_NOT_SAMPLED;
      @(posedge pclk)
      disable iff(!preset_n)
      !(psel && penable && pready) |-> (pslverr == 0);
    endproperty
      
    A_APB_PSLVERR_LOW_WHEN_NOT_SAMPLED: assert property(P_APB_PSLVERR_LOW_WHEN_NOT_SAMPLED) else
      $error("PSLVERR should be driven LOW when not being sampled");
endinterface
    
`endif