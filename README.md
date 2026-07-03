# UVM Verification Testbench — APB I2C Master Controller

A complete UVM-based verification environment for the [PULP Platform APB I2C Master Controller](https://github.com/pulp-platform/apb_i2c). The testbench verifies an I2C master core programmed through an APB slave register interface, using two coordinated UVM agents, a full RAL model, protocol assertions, functional coverage on both bus domains, and a self-checking scoreboard.

> **Tools:** Cadence Xcelium 25.03 · UVM CDNS-1.2 · EDA Playground
> **Reference:** Verilab — *"Reactive Slaves in UVM"* (Litterick)

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [DUT and Register Map](#dut-and-register-map)
- [APB Agent](#apb-agent)
- [I2C Reactive Agent](#i2c-reactive-agent)
- [Register Abstraction Layer (RAL)](#register-abstraction-layer-ral)
- [SVA Assertions](#sva-assertions)
- [Functional Coverage](#functional-coverage)
- [Scoreboard](#scoreboard)
- [Tests](#tests)
- [File Structure](#file-structure)
- [How to Run](#how-to-run)
- [Lessons Learned](#lessons-learned)
- [Next Steps](#next-steps)

---

## Overview

This testbench verifies an I2C master IP by combining two UVM agents. An **active APB master agent** programs the DUT registers, and a **reactive I2C slave agent** responds to whatever the DUT drives on the I2C bus. On top of that, a **RAL model** tracks register state, **SVA assertions** verify protocol compliance, **functional coverage** is collected on both bus domains, and a **scoreboard** automatically compares data across them.

### What was built

- Active APB master agent driving AMBA APB3 transactions
- Reactive I2C slave agent following the Verilab methodology
- Register Abstraction Layer (RAL) with predictor-based mirror tracking
- 16 APB and 3 I2C SystemVerilog assertions
- Functional coverage models for both APB and I2C sides
- Self-checking scoreboard comparing APB and I2C data both ways
- End-to-end tests for both I2C write and read transfers

---

## Architecture

Two agents run in parallel. The APB agent drives register writes to trigger I2C transfers. The I2C agent watches the bus and reacts to what the DUT master does — sending ACK, NACK, or data bytes as needed.

```
+--------------------------------------------------------------------+
|  Test (i2c_ral_write_test, i2c_ral_read_test, ...)                 |
|    raise_objection -> fork forever_seq -> RAL calls -> drop        |
+-------------------------------+------------------------------------+
                                |
+-------------------------------v------------------------------------+
|  i2c_env                                                           |
|                                                                    |
|  +--------------------+   +----------+   +----------------------+  |
|  |  APB Agent          |   |   DUT    |   |  I2C Agent           | |
|  |  (Active Master)    |   |          |   |  (Reactive Slave)    | |
|  |                     |   | apb_i2c  |   |                      | |
|  |  Sequencer          |   |          |   |  Monitor --> FIFO    | |
|  |      v              |   |Registers |   |              v       | |
|  |  Driver <-APB Bus-->|   |    v     |   |  Forever Sequence    | |
|  |      ^              |   |byte_ctrl |   |              v       | |
|  |  Monitor -> Coverage|   |    v     |   |  Driver <-I2C Bus--> | |
|  |                     |   | bit_ctrl |   |      ^               | |
|  |  16 SVA Assertions  |   |          |   |  Monitor -> Coverage | |
|  +----------+----------+   +----------+   |  3 SVA Assertions    | |
|             |                             +----------+-----------+ |
|             |              +-------------+            |            |
|             +------------->| Scoreboard  |<-----------+            |
|                            +-------------+                         |
|                                                                    |
|  +-------------------------------------------------+               |
|  |  RAL Model                                       |              |
|  |  reg_block (PRE, CTR, TX, RX, CMD, STATUS)      |               |
|  |       ^                                          |              |
|  |  Predictor <- Adapter <- APB Monitor            |               |
|  +-------------------------------------------------+               |
+--------------------------------------------------------------------+
```

### UVM Hierarchy

```
uvm_test_top
 |
 +- env (i2c_env)
      |
      +- agent_apb (apb_agent)
      |    |- sequencer, driver, monitor
      |    +- coverage, agent_config
      |
      +- agent_i2c (i2c_agent)
      |    |- sequencer (+ request_fifo)
      |    |- driver, monitor
      |    +- coverage, agent_config
      |
      +- model (i2c_model)
      |    +- reg_block (PRE, CTR, TX, RX, CMD, STATUS)
      |
      +- predictor (uvm_reg_predictor)
      |
      +- scoreboard (i2c_scoreboard)
```

---

## DUT and Register Map

The DUT is a three-module hierarchy from the PULP Platform:

| Module | Role |
|--------|------|
| `apb_i2c` | Top level — APB register interface and byte controller instantiation |
| `i2c_master_byte_ctrl` | Byte-level protocol — orchestrates 8-bit transfers |
| `i2c_master_bit_ctrl` | Bit-level control — generates SCL/SDA waveforms |

The I2C interface uses an **open-drain bus model** with wired-AND logic. Both master and slave can pull lines LOW but cannot drive HIGH. A line reads HIGH only when all parties release it.

```systemverilog
wire scl_line = (scl_padoen_o ? 1'b1 : scl_pad_o) & slave_scl_o;
wire sda_line = (sda_padoen_o ? 1'b1 : sda_pad_o) & slave_sda_o;
```

### Register Map

Six registers exposed through the APB interface:

| Address | Name | Width | Access | Description |
|---------|------|-------|--------|-------------|
| `0x00` | PRE | 16-bit | RW | Clock prescaler |
| `0x04` | CTR | 8-bit | RW | `[7]` EN, `[6]` IEN |
| `0x08` | RX | 8-bit | RO | Received data from slave |
| `0x0C` | SR | 8-bit | RO | `[7]` RxACK, `[6]` Busy, `[5]` AL, `[1]` TIP, `[0]` IF |
| `0x10` | TX | 8-bit | RW | Data to transmit to slave |
| `0x14` | CMD | 8-bit | RW | `[7]` STA, `[6]` STO, `[5]` RD, `[4]` WR, `[3]` ACK, `[0]` IACK |

Two status bits used heavily in tests:
- **TIP** (bit 1) — Transfer In Progress. `1` means the I2C core is busy, `0` means done.
- **RxACK** (bit 7) — `0` means the slave acknowledged the last byte, `1` means NACK.

---

## APB Agent

Active UVM agent driving AMBA APB3 transactions. Uses clocking blocks in the interface to prevent race conditions.

### Protocol Handshake

```
        SETUP        ACCESS (wait)     ACCESS (done)    IDLE
      +--------+   +-----------+   +------------+   +------+
PCLK   _|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-
PSEL   _|                                       |________
PENABLE ___|                                    |________
PREADY ___________________________|_______|_____________
```

The driver walks through three phases:
1. **SETUP** — Assert PSEL, drive PADDR/PWDATA/PWRITE (1 cycle)
2. **ACCESS** — Assert PENABLE, wait for PREADY = 1
3. **CLEANUP** — Deassert all signals, call `item_done()`

### Layered Sequence Pattern

The sequence architecture uses `local::` for constraint forwarding. The test constrains the sequence, which forwards those constraints to the sequence item:

```systemverilog
// Test layer — decide what to do
seq.randomize() with { addr == 12'h004; wdata == 32'h0080; dir == APB_WRITE; };

// Sequence layer — forward to item
req.randomize() with { addr == local::addr; wdata == local::wdata; };

// Item layer — enforce protocol constraints
constraint addr_range { soft addr inside {12'h000, 12'h004, ...}; }
```

Each layer stays independently reusable.

---

## I2C Reactive Agent

The I2C agent is a reactive slave. Unlike a normal agent where the test pushes stimulus, this agent watches the DUT master and responds within I2C timing constraints.

### The Reactive Chain

```
DUT drives START + address on the I2C bus
         |
         v
  +-----------------+
  |   I2C Monitor    |  Collects 7-bit address + R/W bit
  |                  |  Publishes BEFORE the ACK time slot
  +--------+--------+
           | request_aport.write(transaction)
           v
  +-----------------+
  |  request_fifo    |  uvm_tlm_analysis_fifo inside sequencer
  |  (in Sequencer)  |
  +--------+--------+
           | fifo.get() — forever sequence unblocks
           v
  +-----------------+
  | Forever Sequence |  Checks slave address match
  |                  |  Creates ACK or NACK response item
  +--------+--------+
           | start_item / finish_item
           v
  +-----------------+
  |   I2C Driver     |  Pulls SDA LOW (ACK) or leaves HIGH (NACK)
  |                  |  at the 9th SCL falling edge
  +-----------------+
```

**Why timing matters:** The monitor must publish the request *before* the ACK clock pulse arrives. The entire chain (FIFO -> sequence -> driver) must complete within the SCL clock period. A prescaler of `0x0010` gives enough time.

### Two Different Item Types

| Type | Created by | Purpose |
|------|-----------|---------|
| `i2c_transaction` | Monitor | Bus observation record (addr, dir, data, ack) — no `rand` fields |
| `i2c_seq_item` | Sequence | Slave response (ack, data) — `rand` fields for constrained random |

They are different types because they serve different purposes.

### Monitor with Dual Analysis Ports

| Port | Fires when | Purpose |
|------|-----------|---------|
| `request_aport` | After 8 bits (addr + R/W), before ACK slot | Triggers the reactive chain |
| `ap` | After STOP or NACK | Full transaction for scoreboard and coverage |

The monitor uses `fork/join_any` for parallel STOP detection during data collection. A `last_data` variable preserves the correct data value when STOP interrupts the collection loop.

### Driver Timing

The driver modifies SDA only during SCL LOW (safe window):
- **ACK:** Pull SDA LOW on SCL negedge, release after next negedge
- **NACK:** Leave SDA HIGH (released)
- **Write transfer:** After address ACK, wait 8 SCL pulses for data, then drive data ACK
- **Read transfer:** Shift out 8 data bits MSB-first on SCL falling edges

---

## Register Abstraction Layer (RAL)

RAL decouples the test from raw bus transactions. Instead of writing `0x80` to address `0x004`, the test says `reg_block.CTR.write(status, 8'h80)`. The RAL also maintains a mirror of each register's expected value and reports mismatches automatically.

The RAL is split across two packages. Register class definitions live in a dedicated `i2c_reg_pkg`, while the adapter, model, and predictor wiring stay in `main_pkg`. This lets the register model be reused independently of the environment.

### Components

| Component | Role |
|-----------|------|
| Register classes (6 files) | One `uvm_reg` per register with field definitions |
| `i2c_reg_block` | Container class — builds all registers and adds them to a memory map |
| `i2c_reg_adapter` | Translates between generic RAL operations and APB sequence items |
| `i2c_model` | Wrapper component holding the reg block, supports reset handling |
| `uvm_reg_predictor` | Subscribes to APB monitor and updates the mirror automatically |

### Adapter Functions

Two conversions in two directions:

**`bus2reg`** — Monitor to Mirror. Called by the predictor when the APB monitor publishes an observed transaction. Direction-dependent data selection is critical:

```systemverilog
rw.kind   = (seq_item.dir == APB_WRITE) ? UVM_WRITE : UVM_READ;
rw.addr   = seq_item.addr;
rw.data   = (seq_item.dir == APB_WRITE) ? seq_item.wdata : seq_item.rdata;
rw.status = (seq_item.slverr == APB_ERR) ? UVM_NOT_OK : UVM_IS_OK;
```

**`reg2bus`** — RAL to Bus. Called when the test invokes `reg_block.PRE.write()` or `.read()`. Creates an `apb_seq_item` and routes it through the APB sequencer:

```systemverilog
seq_item.addr  = rw.addr;
seq_item.dir   = (rw.kind == UVM_WRITE) ? APB_WRITE : APB_READ;
seq_item.wdata = rw.data;
```

### Mirror Concept — Three Values

For each register, RAL tracks three values:

| Value | What it represents |
|-------|--------------------|
| DUT value | Actual register content inside the hardware |
| Mirrored value | RAL's prediction of what the DUT currently contains |
| Desired value | Target value for later `update()`, set by `set()` |

### Common RAL API

| Method | What it does |
|--------|--------------|
| `write(status, value)` | Bus write; updates desired, mirror, and DUT |
| `read(status, value)` | Bus read; compares against mirror if `set_check_on_read(1)` |
| `set(value)` | Only sets the desired value; no bus activity |
| `update(status)` | If desired != mirror, sends a bus write to sync them |
| `predict(value)` | Manually updates the mirror; used to test the check mechanism |
| `reset(kind)` | Sets the mirror to the register's reset value |

### Volatile Fields

Fields that can change without software intervention are marked `volatile(1)`. On read, mirror comparison is skipped. STATUS bits (`TIP`, `RxACK`, `BUSY`), RX register, and CMD self-clearing bits are all volatile.

---

## SVA Assertions

19 assertions total: 16 for APB in `apb_if.svh` and 3 for I2C in `i2c_if.svh`. All are disabled during reset.

### APB — 16 Assertions

| Group | Count | Coverage |
|-------|-------|----------|
| Unknown value | 7 | PSEL, PENABLE, PADDR, PWDATA, PWRITE, PREADY, PRDATA must not be X/Z |
| State transitions | 3 | PENABLE follows PSEL, no orphan PENABLE, PENABLE deassertion timing |
| Signal stability | 4 | PADDR, PWRITE, PSEL, PWDATA stable during access phase |
| Error response | 2 | PSLVERR validity timing and idle state behavior |

### I2C — 3 Assertions

| Assertion | Rule |
|-----------|------|
| `BUS_IDLE_AT_RESET` | Both SCL and SDA must be HIGH during reset |
| `SCL_NO_X` | SCL must not be X/Z after reset |
| `SDA_NO_X` | SDA must not be X/Z after reset |

---

## Functional Coverage

Coverage is collected on both bus domains. Each agent has its own `uvm_subscriber` connected to the monitor's analysis port. Every captured transaction is sampled automatically.

### APB Coverage

| Coverpoint | Bins |
|------------|------|
| `addr_cp` | 6 named bins for each register address |
| `wr_cp` | `write_op`, `read_op` |
| `wdata_cp` | `all_zeros`, `low_vals`, `mid_vals`, `high_vals`, `all_ones` |
| `err_cp` | `error`, `done` |
| `dir_x_addr` | Cross: 2 x 6 = 12 bins |

### I2C Coverage

| Coverpoint | Bins |
|------------|------|
| `dir_cp` | `write_op` (I2C_WRITE), `read_op` (I2C_READ) |
| `ack_cp` | `ack_ok` (I2C_ACK), `nack_op` (I2C_NACK) |
| `addr_cp` | `low_range` (0x00-0x3F), `high_range` (0x40-0x7F), `target` (0x7F) |
| `data_cp` | `all_zeros`, `low_vals`, `mid_vals`, `high_vals`, `all_ones` |
| `dir_x_ack` | Cross: 2 x 2 = 4 bins |

### Coverage Results

| Test | APB Total | I2C Total | Notes |
|------|-----------|-----------|-------|
| `i2c_ral_write_test` | 63% | ~46% | Write direction only, address matches target |
| `i2c_ral_read_test` | 68% | ~46% | Read direction only, address matches target |

Coverage grows as more test scenarios are added (NACK responses, different addresses, varied data patterns).

---

## Scoreboard

The scoreboard receives transactions from both monitors and confirms that data flows correctly across the APB-to-I2C bridge. It handles both directions of transfer.

```
APB Monitor ------+
                  +---> i2c_scoreboard
I2C Monitor ------+
```

### Write Direction (APB TX -> I2C bus)

```
1. Test writes TX register    -> scoreboard remembers the byte as pending
2. Test writes CMD register   -> scoreboard decides what the previous TX was
   - CMD = STA + WR (0x90)    -> previous TX was an address byte, skip it
   - CMD = WR only  (0x10)    -> previous TX was a data byte, push to queue
3. I2C monitor reports Complete -> pop from queue, compare, report result
```

The address-vs-data distinction is needed because the I2C monitor exposes the address in `slave_addr` and only the data byte in `data`. Pushing the address byte into the expected queue would create false mismatches.

### Read Direction (I2C bus -> APB RX)

```
1. I2C monitor reports Complete (read)   -> push data to expected_rx queue
2. Test reads RX register                -> pop from queue, compare
```

### Timing Corner — TIP vs STOP

There is a subtle timing issue in the read direction. The DUT signals TIP=0 (transfer done) as soon as the data byte is fully received on the bus. The test then reads RX register right away — while the I2C bus is still finishing up (STOP condition has not happened yet).

But the I2C monitor's `Complete` transaction is only published when it detects STOP. So the APB RX read arrives at the scoreboard *before* the I2C data does.

To handle this, the scoreboard uses a two-sided pending mechanism. Whichever side arrives first is stored, and the comparison happens when the second one shows up:

```
If APB RX read comes first:
   -> Store in pending_rx, wait for I2C

If I2C data comes first:
   -> Push to expected_rx queue, wait for APB RX read

Whichever comes second -> do the comparison
```

Same idea in both directions — no side has to happen first.

---

## Tests

### `i2c_ral_write_test`

End-to-end I2C write transfer using the RAL API. Ten register operations from prescaler setup to STOP command:

| Step | Register | Method | Value | Purpose |
|------|----------|--------|-------|---------|
| 1 | PRE | write | `0x0010` | Set SCL prescaler |
| 2 | CTR | write | `0x80` | Enable I2C core |
| 3 | TX | write | `0xFE` | Load slave address 0x7F + write bit |
| 4 | CMD | write | `0x90` | Issue START + WRITE |
| 5 | STATUS | read | poll TIP=0 | Wait for address phase |
| 6 | STATUS | check | RxACK bit | Verify slave ACK |
| 7 | TX | write | `0xAB` | Load data byte |
| 8 | CMD | write | `0x10` | Issue WRITE (data byte) |
| 9 | STATUS | read | poll TIP=0 | Wait for data phase |
| 10 | CMD | write | `0x40` | Issue STOP |

### TIP Polling Explained

Steps 5 and 9 both poll the STATUS register until TIP becomes 0:

```systemverilog
do begin
  env.model.reg_block.STATUS.read(status, rdata);
end while(rdata[1] == 1);
```

TIP (bit 1) indicates that the I2C core is still transmitting. Reading STATUS blindly right after a CMD write would return TIP=1 because the transfer just started. The loop keeps reading until TIP drops to 0, meaning the transfer finished.

During polling, verbosity is temporarily suppressed so the log does not flood with dozens of poll transactions:

```systemverilog
env.agent_apb.driver.set_report_verbosity_level(UVM_NONE);
env.agent_apb.monitor.set_report_verbosity_level(UVM_NONE);
do begin
  env.model.reg_block.STATUS.read(status, rdata);
end while(rdata[1] == 1);
env.agent_apb.driver.set_report_verbosity_level(UVM_MEDIUM);
env.agent_apb.monitor.set_report_verbosity_level(UVM_MEDIUM);
```

### `i2c_ral_read_test`

Same idea as the write test but with the read direction. The slave's response data is set up through the config DB before the test runs:

```systemverilog
uvm_config_db#(bit[7:0])::set(this, "*", "read_data", 8'h55);
```

The forever sequence reads this value at start and uses it as the data byte during I2C read transactions:

```systemverilog
if (!item.randomize() with { data == local::read_data; ack == I2C_ACK; }) begin
  `uvm_error("RAND_FAIL", "randomization failed")
end
```

After the I2C transfer, the test reads the RX register and confirms the same value. The scoreboard also confirms the data matches across both domains.

### `i2c_ral_test` (Mirror Corruption)

A negative test that validates the RAL check mechanism. The test writes a known value, then manually corrupts the mirror using `predict()`, then reads the register:

```systemverilog
env.model.reg_block.PRE.write(status, 16'h0010);   // DUT and mirror = 0x0010
env.model.reg_block.PRE.predict(16'hDEAD);          // Mirror = 0xDEAD, DUT untouched
env.model.reg_block.PRE.read(status, rdata);       // DUT returns 0x0010, mirror = 0xDEAD -> UVM_ERROR
```

This confirms that `set_check_on_read(1)` and the mismatch reporting work as intended.

### Additional Test Files

The repository also contains earlier development tests that predate the RAL:

- `i2c_full_write_test` — Same 10-step write flow but using raw APB sequences instead of the RAL API. Kept as a reference for the pre-RAL style.
- `i2c_single_write_test` — Minimal single APB register write, used during initial APB agent bring-up.
- `i2c_reg_access_test` — Placeholder register access test.

### Results Summary

| Test | UVM_ERROR | Sim Time | Notes |
|------|-----------|----------|-------|
| `i2c_ral_write_test` | 0 | ~23,000 NS | Full write, scoreboard match |
| `i2c_ral_read_test` | 0 | ~23,000 NS | Full read, scoreboard match |
| `i2c_ral_test` | 1 (expected) | ~500 NS | Confirms RAL check mechanism |

---

## File Structure

```
rtl/
  apb_i2c.sv
  i2c_master_bit_ctrl.sv
  i2c_master_byte_ctrl.sv
  i2c_master_defines.sv
  src_files.yml

tb/
  top/
    testbench.sv                # Clock, reset, DUT instantiation (only .sv file)
    i2c_reg_pkg.svh             # Package for register class definitions

  interfaces/
    apb_if.svh                  # APB bus + 16 SVA assertions
    i2c_if.svh                  # Open-drain model + 3 SVA assertions

  apb_agent/
    apb_types.svh
    apb_seq_item.svh
    apb_base_sequence.svh
    apb_sequencer.svh
    apb_driver.svh
    apb_monitor.svh
    apb_coverage.svh
    apb_agent_config.svh
    apb_agent.svh
    apb_pkg.svh

  i2c_agent/
    i2c_types.svh
    i2c_seq_item.svh
    i2c_transaction.svh
    i2c_sequencer.svh           # + request_fifo
    i2c_forever_sequence.svh    # Reactive: fifo.get() -> ACK/NACK
    i2c_driver.svh
    i2c_monitor.svh             # Dual analysis ports
    i2c_coverage.svh
    i2c_agent_config.svh
    i2c_agent.svh
    i2c_pkg.svh

  ral/
    i2c_reg_pre.svh
    i2c_reg_ctr.svh
    i2c_reg_tx.svh
    i2c_reg_rx.svh
    i2c_reg_cmd.svh
    i2c_reg_status.svh
    i2c_reg_block.svh
    i2c_reg_adapter.svh
    i2c_model.svh

  env/
    i2c_env.svh                 # Agents, RAL, predictor, scoreboard wiring
    i2c_scoreboard.svh          # Two-way self-checking

  tests/
    i2c_base_test.svh
    i2c_ral_write_test.svh
    i2c_ral_read_test.svh
    i2c_ral_test.svh            # Mirror corruption / negative test
    i2c_full_write_test.svh     # Pre-RAL write test using raw APB sequences
    i2c_single_write_test.svh   # Minimal APB write test
    i2c_reg_access_test.svh     # Placeholder register access test

  packages/
    main_pkg.svh                # RAL adapter, model, scoreboard, env
    test_pkg.svh                # All tests
```

### Package Layout

- **`apb_pkg`** — APB agent files (interface, types, sequences, driver, monitor, coverage, agent)
- **`i2c_pkg`** — I2C agent files (interface, types, transaction, sequences, driver, monitor, coverage, agent)
- **`i2c_reg_pkg`** — All six register classes plus the register block
- **`main_pkg`** — Imports the three above; adds adapter, model, scoreboard, and env
- **`test_pkg`** — Imports `main_pkg`; adds all test classes

---

## How to Run

### EDA Playground

1. Go to [edaplayground.com](https://www.edaplayground.com)
2. Select **Cadence Xcelium 25.03** as the simulator
3. Upload all files from `rtl/` into the design panel
4. Upload all files from `tb/` into the testbench panel
5. Set run options:
   ```
   +UVM_TESTNAME=i2c_ral_write_test +UVM_MAX_QUIT_COUNT=1
   ```
6. Click **Run**

### Command Line (Xcelium)

```bash
xrun -timescale 1ns/1ns -sysv -coverage functional -access +rw \
     +UVM_TESTNAME=i2c_ral_write_test +UVM_MAX_QUIT_COUNT=1 \
     -uvmhome $UVM_HOME \
     $UVM_HOME/src/uvm_macros.svh \
     rtl/*.sv tb/**/*.svh tb/top/testbench.sv
```

### Available Test Names

- `i2c_ral_write_test` — Full write transfer with scoreboard checks (RAL API)
- `i2c_ral_read_test` — Full read transfer with scoreboard checks (RAL API)
- `i2c_ral_test` — Negative test that validates the RAL check mechanism
- `i2c_full_write_test` — Same as `i2c_ral_write_test` but using raw APB sequences
- `i2c_single_write_test` — Minimal single APB register write
- `i2c_reg_access_test` — Placeholder register access test

---

## Lessons Learned

A few things worth remembering from this project:

- **Reactive timing is tight.** The whole chain (monitor -> FIFO -> sequence -> driver) has to complete within one SCL period. Small prescalers break the chain and the slave misses the ACK slot.
- **Interfaces carry more than signals.** Assertions and clocking blocks are the reason the driver stays clean and race-free.
- **Volatile fields matter in RAL.** Marking status bits volatile prevents false mismatches when the DUT changes their value between reads.
- **Scoreboard timing is bidirectional.** Data does not always arrive from both sides in the same order. Using pending buffers on both ends makes the comparison robust.
- **Log noise kills debug.** Polling loops can dump thousands of lines. Suppressing verbosity around the loop keeps the log readable.
- **RAL API is worth the setup.** Once the adapter and predictor are in place, tests read like specifications rather than bus programs.

---

## Next Steps

- **Interrupt test** — verify `interrupt_o` behavior with IEN enabled
- **Arbitration lost test** — simulate bus contention scenario
- **Error injection sequence** — random NACK responses for negative testing
- **Multi-byte transfers** — read/write more than one data byte per transaction
- **More coverage bins** — corner values, address diversity, ACK/NACK patterns

---

## References

- ARM, *AMBA APB Protocol Specification*, ARM IHI 0024E
- Litterick, M., *"Reactive Slaves in UVM — Bidirectional Agent Architectures"*, Verilab
- Accellera, *UVM 1.2 Class Reference*, Section 5 — Register Layer
- PULP Platform, *apb_i2c RTL*, github.com/pulp-platform/apb_i2c
- NXP Semiconductors, *I2C-Bus Specification and User Manual*, Rev. 6
