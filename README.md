# 💻 Custom 9-Bit Multi-Cycle Microprocessor (RTL Design)

![SystemVerilog](https://img.shields.io/badge/Language-SystemVerilog-blue.svg)
![Architecture](https://img.shields.io/badge/Architecture-9--bit-success.svg)
![Design Pattern](https://img.shields.io/badge/Design-Multi--Cycle-orange.svg)

## 📌 Project Overview
This repository contains the complete RTL (Register-Transfer Level) implementation of a custom **9-bit multi-cycle microprocessor** written in **SystemVerilog**. Designed from the ground up, this project demonstrates core concepts of computer architecture, including Finite State Machine (FSM) control, custom Instruction Set Architecture (ISA), von Neumann memory organization, and Memory-Mapped I/O.

The processor features an 8-register datapath, a dedicated Arithmetic Logic Unit (ALU), a multi-cycle execution pipeline, and hardware peripherals (9-bit LED array) controlled via specific memory addresses.

---

## 📑 Table of Contents
1. [System Architecture](#-system-architecture)
2.[Instruction Cycle & FSM](#-instruction-cycle--fsm)
3. [Datapath & ALU](#-datapath--alu)
4. [Instruction Set Architecture (ISA)](#-instruction-set-architecture-isa)
5. [Memory Map & I/O](#-memory-map--io)
6.[RTL Schematics](#-rtl-schematics)
7. [Simulation & Waveforms](#-simulation--waveforms)
8. [Module Hierarchy](#-module-hierarchy)
9. [How to Run / Synthesize](#-how-to-run--synthesize)

---

## 🏛️ System Architecture

The top-level system (`mcu_system`) acts as the motherboard, bridging the CPU core, Main Memory (RAM), and External Peripherals (LEDs). 

![Top Level System Architecture](docs/images/top_level_architecture.png)
> *<!-- 📸 ADD IMAGE HERE: A block diagram showing the mcu_system, CPU, RAM, and LED outputs interacting via the 9-bit address and data buses. -->*

### Key Specifications:
* **Data Bus Width:** 9 bits
* **Address Bus Width:** 9 bits
* **Registers:** 8 General-Purpose Registers (`R0` - `R7`). *Note: `R7` is hardware-mapped to act as the Program Counter (PC).*
* **Memory:** 128-word internal RAM (von Neumann architecture)

---

## 🔄 Instruction Cycle & FSM

The control unit is governed by a multi-state Finite State Machine (FSM) that orchestrates the strict **Fetch - Decode - Execute - Store** pipeline. Because this is a multi-cycle processor, each instruction takes multiple clock cycles to complete, allowing for stable memory read/write operations and reusing hardware components (like the ALU).

![FSM State Diagram](docs/images/fsm_state_diagram.png)
> *<!-- 📸 ADD IMAGE HERE: A state machine diagram showing T0 -> T0_Wait -> T1 -> T2 -> T3 -> T4 transitions based on the instruction type. -->*

### Execution States:
1. **Fetch (`T0`, `T0_Wait`):** The PC (`R7`) is loaded onto the address bus. The system waits for RAM to output the instruction, which is then latched into the Instruction Register (IR). PC is incremented.
2. **Decode (`T1`):** The 3-bit Opcode is decoded. Operands are prepared (e.g., moving register values to internal ALU buses). Address buses are configured for memory operations.
3. **Execute (`T2`, `T2_Wait`):** The ALU performs arithmetic (`add`, `sub`), or the system waits for data to be loaded from RAM (`ld`, `movi`).
4. **Write-Back / Store (`T3`):** ALU results are routed back to the destination register, or data is permanently written to RAM/Peripherals (`st`).
5. **Next Cycle (`T4`):** The `Done` signal is asserted, the next instruction address is fetched, and the cycle resets to `T0`.

---

## 🛤️ Datapath & ALU

The datapath relies on a central bus multiplexer that routes data between the registers, the ALU, and external memory. 

![CPU Datapath](docs/images/cpu_datapath.png)
> *<!-- 📸 ADD IMAGE HERE: A schematic showing the Register File, A & G registers, the ALU, and the large bus multiplexer. -->*

* **ALU Design:** Constructed using custom full-adder blocks. It supports addition and 2's complement subtraction.
* **Zero Flag Logic:** A combinational NOR-gate array detects when the ALU output is exactly zero, latching into the `ALUz` flip-flop. This is used by the `mvnz` instruction for conditional branching (e.g., `while` loops).

---

## 📜 Instruction Set Architecture (ISA)

The CPU uses a custom 9-bit instruction format. The 9 bits of the Instruction Register (`IR[8:0]`) are divided as follows:
* **`IR[8:6]`**: 3-bit Opcode (Operation type)
* **`IR[5:3]`**: 3-bit Register X index (`Rx` - Destination/Operand 1)
* **`IR[2:0]`**: 3-bit Register Y index (`Ry` - Operand 2)

| Opcode | Mnemonic | Operation Description | RTL Logic |
| :---: | :--- | :--- | :--- |
| `000` | **`mv Rx, Ry`** | Move Register to Register | `Rx ← Ry` |
| `001` | **`movi Rx`**| Move Immediate (Next byte in Mem) | `Rx ← Memory[PC]; PC ← PC + 1` |
| `010` | **`add Rx, Ry`** | Add | `Rx ← Rx + Ry` |
| `011` | **`sub Rx, Ry`** | Subtract | `Rx ← Rx - Ry` |
| `100` | **`ld Rx, Ry`** | Load from Memory Address in Ry | `Rx ← Memory[Ry]` |
| `101` | **`st Rx, Ry`** | Store Rx into Memory Address in Ry | `Memory[Ry] ← Rx` |
| `110` | **`mvnz Rx, Ry`**| Move if Not Zero (Branching) | `If (Z == 0) then Rx ← Ry` |

---

## 🗺️ Memory Map & I/O

Hardware address decoding logic is built directly into the top module (`mcu_system`) to separate physical RAM from I/O devices using **Memory-Mapped I/O**.

| Address Range (Binary) | Address (Decimal) | Target Peripheral | Description |
| :--- | :--- | :--- | :--- |
| `00xxxxxxx` | `0` - `127` | **RAM** | 128-word Main Memory (Data & Instructions) |
| `100000000` | `256` | **LED Output** | Memory-mapped 9-bit LED register |

**Hardware Peripheral Control:** To output data to the physical LEDs, the programmer simply loads `256` into a register and uses the `st` (store) instruction. The top-level module intercepts the `W_Main` signal and routes the data to the `ledreg9bit` module instead of RAM.

---

## 🔌 RTL Schematics

Below are the Register-Transfer Level schematics generated during synthesis, verifying the hardware logic mapping.

![Top Level RTL Viewer](docs/images/rtl_viewer_top.png)
> *<!-- 📸 ADD IMAGE HERE: Screenshot of the top-level RTL schematic from Quartus/Vivado. -->*

![Control Unit RTL Viewer](docs/images/rtl_viewer_fsm.png)
> *<!-- 📸 ADD IMAGE HERE: Screenshot of the Control Unit FSM RTL mapping. -->*

---

## 📈 Simulation & Waveforms

The design was verified using a testbench to simulate clock cycles, instruction fetching, and ALU operations. 

![Simulation Waveforms](docs/images/simulation_waveform.png)
> *<!-- 📸 ADD IMAGE HERE: Screenshot from ModelSim / QuestaSim / Vivado Simulator. -->*

**Waveform Highlights:**
* Notice the `Clock` and `Resetn` initialization.
* Observe `Tstep_Q` transitioning through the FSM states (`T0` -> `T1` -> `T2` -> `T3` -> `T4`).
* The `Done` signal successfully pulses high at `T4`, indicating the instruction has finished executing and `PC` is updated.
* `BusWires` reflects the accurate routing of data between registers and memory.

---

## 📂 Module Hierarchy

* `mcu_system` *(Top Module)*
  * `processor` *(CPU Core)*
    * `control_unit` *(FSM, Instruction Decoder)*
    * `alu` *(Combinational arithmetic logic built with full adders)*
    * `pc_logic` *(Program Counter multiplexing)*
    * `register` *(D-Flip-Flop arrays for R0-R7, A, G, IR, PC)*
    * `bus_multiplexer` *(Data routing)*
  * `RAM` *(Memory block)*
  * `ledreg9bit` *(Memory-mapped output register)*

---
