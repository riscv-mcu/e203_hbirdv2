.. _core:

Hummingbirdv2 E203 Core
=======================

Hummingbirdv2 E203 RISC-V processor is mainly used for embedded application with low power and area consumption.

Features
########

The features of Hummingbirdv2 E203 core are as follows.

- RISC-V RV32IMAC or RV32EMAC ISA supported
- 2-Stage Pipeline
- Machine Mode only
- Configurable
- "RISC-V External Debug Support Version 0.11nov12" supported
- NICE(Nuclei Instruction Co-unit Extension) supported

Hierarchy
#########

The hierarchy of Hummingbirdv2 E203 core implementation is shown in the diagram below, and the function of each modules is listed in the table below.

.. _figure_core_1:

.. figure:: /asserts/medias/core_fig1.jpg
   :width: 600
   :alt: core_fig1

   Hierarchy of Hummingbirdv2 E203 core implementation


.. _table_core_1:

.. table:: Function of each modules

  +-------------------+-------------------------------------------------------------------+
  | e203_cpu_top      |  Top module                                                       |
  +-------------------+-------------------------------------------------------------------+
  | e203_cpu          |  Logic top module of core                                         |
  +-------------------+-------------------------------------------------------------------+
  | e203_clk_ctrl     |  Clock control module                                             |
  +-------------------+-------------------------------------------------------------------+
  | e203_reset_ctrl   |  Reset control module                                             |
  +-------------------+-------------------------------------------------------------------+
  | e203_irq_sync     |  Asynchronous interrupt signal sync module                        |
  +-------------------+-------------------------------------------------------------------+
  | e203_itcm_ctrl    |  ITCM control module                                              |
  +-------------------+-------------------------------------------------------------------+
  | e203_dtcm_ctrl    |  DTCM control module                                              |
  +-------------------+-------------------------------------------------------------------+
  | e203_core         |  Main logic top module of core                                    |
  +-------------------+-------------------------------------------------------------------+
  | e203_ifu          |  Top module of fetch unit                                         |
  +-------------------+-------------------------------------------------------------------+
  | e203_exu          |  Top module of execution unit                                     |
  +-------------------+-------------------------------------------------------------------+
  | e203_lsu          |  Top module of load & store unit                                  |
  +-------------------+-------------------------------------------------------------------+
  | e203_biu          |  Bus interface unit module                                        |
  +-------------------+-------------------------------------------------------------------+
  | e203_srams        |  SRAM top module of core                                          |
  +-------------------+-------------------------------------------------------------------+
  | e203_itcm_ram     |  ITCM SRAM module                                                 |
  +-------------------+-------------------------------------------------------------------+
  | e203_dtcm_ram     |  DTCM SRAM module                                                 |
  +-------------------+-------------------------------------------------------------------+


Configurable
############

Hummingbirdv2 E203 core is configurable, and user can achieve different implementation by modifying the config.v file (in e203_hbirdv2/rtl/e203/core directory). Detailed config informations can be found in the table below.

.. _table_core_2:

.. table:: Function of each modules

  +----------------------------------+-----------------------------------------------------------------+---------------------------+
  | Config Macro                     | Description                                                     | Default Value             |
  +----------------------------------+-----------------------------------------------------------------+---------------------------+
  | E203_CFG_DEBUG_HAS_JTAG          | If defined, E203 core has JTAG debug interface                  | defined                   |
  +----------------------------------+-----------------------------------------------------------------+---------------------------+
  | E203_CFG_ADDR_SIZE_IS_16         | Choose one of three, set bus address width of processor         | 32                        |
  +                                  +                                                                 +                           +
  | E203_CFG_ADDR_SIZE_IS_24         |                                                                 |                           |
  +                                  +                                                                 +                           +
  | E203_CFG_ADDR_SIZE_IS_32         |                                                                 |                           |
  +----------------------------------+-----------------------------------------------------------------+---------------------------+
  | E203_CFG_SUPPORT_MCYCLE_MINSTRET | If defined, E203 core has MCYCLE and MINSTRET CSR register      | defined                   |
  +----------------------------------+-----------------------------------------------------------------+---------------------------+
  | E203_CFG_REGNUM_IS_32            | Choose one of two, set number of general register               | 32                        |
  +                                  +                                                                 +                           +
  | E203_CFG_REGNUM_IS_16            |                                                                 |                           |
  +----------------------------------+-----------------------------------------------------------------+---------------------------+
  | E203_CFG_HAS_ITCM                | If defined, E203 core has ITCM                                  | defined                   |
  +----------------------------------+-----------------------------------------------------------------+---------------------------+
  | E203_CFG_ITCM_ADDR_BASE          | Set base address of ITCM                                        | 0x8000_0000               |
  +----------------------------------+-----------------------------------------------------------------+---------------------------+
  | E203_CFG_ITCM_ADDR_WIDTH         | Set size of ITCM                                                | 16(64KB)                  |
  +----------------------------------+-----------------------------------------------------------------+---------------------------+
  | E203_CFG_HAS_DTCM                | If defined, E203 core has DTCM                                  | defined                   |
  +----------------------------------+-----------------------------------------------------------------+---------------------------+
  | E203_CFG_DTCM_ADDR_BASE          | Set base address of DTCM                                        | 0x9000_0000               |
  +----------------------------------+-----------------------------------------------------------------+---------------------------+
  | E203_CFG_DTCM_ADDR_WIDTH         | Set size of DTCM                                                | 16(64KB)                  |
  +----------------------------------+-----------------------------------------------------------------+---------------------------+
  | E203_CFG_REGFILE_LATCH_BASED     | If defined, using latch as register                             | Not defined               |
  +----------------------------------+-----------------------------------------------------------------+---------------------------+
  | E203_CFG_PPI_ADDR_BASE           | Set base address of peripheral interface                        | 0x1000_0000               |
  +----------------------------------+-----------------------------------------------------------------+---------------------------+
  | E203_CFG_PPI_BASE_REGION         | Set address region of peripheral interface                      | 31:28                     |
  +                                  +                                                                 +                           +
  |                                  |                                                                 | (0x1000_0000~0x1FFF_FFFF) |
  +----------------------------------+-----------------------------------------------------------------+---------------------------+
  | E203_CFG_FIO_ADDR_BASE           | Set base address of fast IO interface                           | 0xf000_0000               |
  +----------------------------------+-----------------------------------------------------------------+---------------------------+
  | E203_CFG_FIO_BASE_REGION         | Set address region of fast IO interface                         | 31:28                     |
  +                                  +                                                                 +                           +
  |                                  |                                                                 | (0xF000_0000~0xFFFF_FFFF) |
  +----------------------------------+-----------------------------------------------------------------+---------------------------+
  | E203_CFG_CLINT_ADDR_BASE         | Set base address of CLINT                                       | 0x0200_0000               |
  +----------------------------------+-----------------------------------------------------------------+---------------------------+
  | E203_CFG_CLINT_BASE_REGION       | Set address region of CLINT                                     | 31:16                     |
  +                                  +                                                                 +                           +
  |                                  |                                                                 | (0x0200_0000~0x0200_FFFF) |
  +----------------------------------+-----------------------------------------------------------------+---------------------------+
  | E203_CFG_PLIC_ADDR_BASE          | Set base address of PLIC                                        | 0x0C00_0000               |
  +----------------------------------+-----------------------------------------------------------------+---------------------------+
  | E203_CFG_PLIC_BASE_REGION        | Set address region of PLIC                                      | 31:24                     |
  +                                  +                                                                 +                           +
  |                                  |                                                                 | (0x0C00_0000~0x0CFF_FFFF) |
  +----------------------------------+-----------------------------------------------------------------+---------------------------+
  | E203_CFG_HAS_ECC                 | If defined, E203 core has ECC module                            | defined                   |
  +                                  +                                                                 +                           +
  |                                  | **Note: Currently, ECC module isn't included in HBirdv2 E203,** |                           |
  +                                  +                                                                 +                           +
  |                                  | **so this config macro is meaningless**                         |                           |
  +----------------------------------+-----------------------------------------------------------------+---------------------------+
  | E203_CFG_HAS_NICE                | If defined, E203 core has NICE interface                        | defined                   |
  +----------------------------------+-----------------------------------------------------------------+---------------------------+
  | E203_CFG_SUPPORT_SHARE_MULDIV    | If defined, E203 core has multi-cycle multiplier and            | defined                   |
  +                                  +                                                                 +                           +
  |                                  | divider unit                                                    |                           |
  +----------------------------------+-----------------------------------------------------------------+---------------------------+
  | E203_CFG_SUPPORT_AMO             | If defined, E203 core support RISC-V "A" standard Extension     | defined                   |
  +----------------------------------+-----------------------------------------------------------------+---------------------------+

Pipeline Structure
##################

The pipeline structure of E203 core is shown in the diagram below.

.. _figure_core_2:

.. figure:: /asserts/medias/core_fig2.jpg
   :width: 600
   :alt: core_fig2

   Pipeline structure of Hummingbirdv2 E203 core

- First stage: Fetch(IFU)
- Second stage: Decode(EXU), Execute(EXU), Write Back(WB)
- Other stage: Memory Access(LSU)

.. note::
   In fact, the number of E203 core's pipeline stage is variable. As the main structure of E203 core is "Fectch" in first stage and "Decode", "Execute", "Write Back" in second stage, so we just called E203 core as 2-stage pipeline RISC-V processor.



NICE
####

Introduction
------------

E203 core supports configurable NICE(Nuclei Instruction Co-unit Extension) which could be used to create user-defined instructions. NICE enables the integration of custom hardware co-units that improve domain-specific performance while reducing power consumption.

Co-unit connected by the NICE interface protocol (Hereinafter referred to as NICE-Core) is an independent module outside the Master E203 Core.

NICE Instruction Format
-----------------------

In order to facilitate user to extend custom instructions, RISC-V ISA predefines 4 groups of custom instruction types in 32-bit instructions (Custom-0, Custom-1, Custom-2, Custom-3), each with its own opcode, as shown in the table below.

.. _table_core_3:

.. table:: 32-bit instruction opcode of RISC-V (inst[1:0]=11)

  +-----------+--------+----------+------------+----------+--------+----------------+------------------+-------+
  | inst[4:2] | 000    | 001      | 010        | 011      | 100    | 101            | 110              | 111   |
  +-----------+        +          +            +          +        +                +                  +       +
  | inst[6:5] |        |          |            |          |        |                |                  | (>32) |
  +-----------+--------+----------+------------+----------+--------+----------------+------------------+-------+
  | 00        | LOAD   | LOAD-FP  | *Custom-0* | MISC-MEM | OP_IMM | AUIPC          | OP-IMM-32        | 48b   |
  +-----------+--------+----------+------------+----------+--------+----------------+------------------+-------+
  | 01        | STORE  | STORE-FP | *Custom-1* | AMO      | OP     | LUI            | OP-32            | 64b   |
  +-----------+--------+----------+------------+----------+--------+----------------+------------------+       +
  | 10        | MADD   | MSUB     | NMSUB      | NMADD    | OP-FP  | reserved       | *Custom-2/rv128* | 48b   |
  +-----------+--------+----------+------------+----------+--------+----------------+------------------+-------+
  | 11        | BRANCH | JALR     | reserved   | JAL      | SYSTEM | reserved       | *Custom-3/rv128* | >=80b |
  +-----------+--------+----------+------------+----------+--------+----------------+------------------+-------+

In E203 Core, user can use these 4 custom instruction groups (Custom-0, Custom-1, Custom-2, Custom-3) for NICE extensions, the following diagram shows the detail of NICE instruction format, and the detailed description of each field in NICE instruction is shown in the table below.

.. _figure_core_3:

.. figure:: /asserts/medias/core_fig3.jpg
   :width: 800
   :alt: core_fig3

   NICE instruction format


.. _table_core_4:

.. table:: Description of each field in NICE instruction

  +--------+------------------------------------------------------------------------------------------+
  | Field  | Description                                                                              |
  +--------+------------------------------------------------------------------------------------------+
  | opcode | Choose one of 4 custom instruction groups (Custom-0, Custom-1, Custom-2, Custom-3)       |
  +--------+------------------------------------------------------------------------------------------+
  | rd     | Destination register index                                                               |
  +--------+------------------------------------------------------------------------------------------+
  | xs2    | If this bit is set, source register 2 will be read                                       |
  +--------+------------------------------------------------------------------------------------------+
  | xs1    | If this bit is set, source register 1 will be read                                       |
  +--------+------------------------------------------------------------------------------------------+
  | xd     | If this bit is set, destination register will be written                                 |
  +--------+------------------------------------------------------------------------------------------+
  | rs1    | Source register 1 index                                                                  |
  +--------+------------------------------------------------------------------------------------------+
  | rs2    | Source register 2 index                                                                  |
  +--------+------------------------------------------------------------------------------------------+
  | funct7 | Encode different custom instructions                                                     |
  +--------+------------------------------------------------------------------------------------------+

NICE Interface
--------------

NICE interface has 4 channels, request channel, response channel, memory request channel and memory response channel. The detailed description of each channels are shown in the table below.

.. _table_core_5:

.. table:: Description of NICE interface
 
  +----------+-----------+-------+--------------------+----------------------------------------------------------------------------+
  | Channel  | Direction | Width | Signal Name        | Description                                                                |
  +----------+-----------+-------+--------------------+----------------------------------------------------------------------------+
  | Request  | Output    | 1     | nice_req_valid     | This signal indicates that E203 core sends a nice request                  |
  +          +-----------+-------+--------------------+----------------------------------------------------------------------------+
  | Channel  | Input     | 1     | nice_req_ready     | This signal indicates that NICE-Core can receive a nice request            |
  |          +-----------+-------+--------------------+----------------------------------------------------------------------------+
  |          | Output    | 32    | nice_req_instr     | Custom instruction                                                         |
  |          +-----------+-------+--------------------+----------------------------------------------------------------------------+
  |          | Output    | 32    | nice_req_rs1       | Value of source register 1                                                 |
  |          +-----------+-------+--------------------+----------------------------------------------------------------------------+
  |          | Output    | 32    | nice_req_rs2       | Value of source register 2                                                 |
  +----------+-----------+-------+--------------------+----------------------------------------------------------------------------+
  | Response | Input     | 1     | nice_rsp_valid     | This signal indicates that NICE-Core sends a nice response                 |
  +          +-----------+-------+--------------------+----------------------------------------------------------------------------+
  | Channel  | Output    | 1     | nice_rsp_ready     | This signal indicates that E203 core can receive a nice response           |
  |          +-----------+-------+--------------------+----------------------------------------------------------------------------+
  |          | Input     | 32    | nice_rsp_data      | The result from NICE-Core                                                  |
  |          +-----------+-------+--------------------+----------------------------------------------------------------------------+
  |          | Input     | 1     | nice_rsp_err       | This signal indicates that an error is detected in NICE-Core executing     |
  +----------+-----------+-------+--------------------+----------------------------------------------------------------------------+
  | Memory   | Input     | 1     | nice_icb_cmd_valid | This signal indicates that NICE-Core sends a memory access request         |
  +          +-----------+-------+--------------------+----------------------------------------------------------------------------+
  | Request  | Output    | 1     | nice_icb_cmd_ready | This signal indicates that E203 core can receive memory access request     |
  +          +-----------+-------+--------------------+----------------------------------------------------------------------------+
  | Channel  | Input     | 32    | nice_icb_cmd_addr  | Address of memory access request                                           |
  |          +-----------+-------+--------------------+----------------------------------------------------------------------------+
  |          | Input     | 1     | nice_icb_cmd_read  | Write or Read of memory access request                                     |
  |          |           |       |                    |                                                                            |
  |          |           |       |                    | 0: write                                                                   |
  |          |           |       |                    |                                                                            |
  |          |           |       |                    | 1: read                                                                    |
  |          +-----------+-------+--------------------+----------------------------------------------------------------------------+
  |          | Input     | 32    | nice_icb_cmd_wdata | Write data of memory write request                                         |
  |          +-----------+-------+--------------------+----------------------------------------------------------------------------+
  |          | Input     | 2     | nice_icb_cmd_size  | The size of memory access request                                          |
  |          |           |       |                    |                                                                            |
  |          |           |       |                    | 2’b00: byte                                                                |
  |          |           |       |                    |                                                                            |
  |          |           |       |                    | 2'b01: half-word                                                           |
  |          |           |       |                    |                                                                            |
  |          |           |       |                    | 2'b10: word                                                                |
  |          |           |       |                    |                                                                            |
  |          |           |       |                    | 2'b11: reserved                                                            |
  |          +-----------+-------+--------------------+----------------------------------------------------------------------------+
  |          | Input     | 1     | nice_mem_holdup    | This signal indicates NICE-Core occupy LSU pipe of E203 core for           |
  |          |           |       |                    |                                                                            |
  |          |           |       |                    | stalling next load and store instruction                                   |
  +----------+-----------+-------+--------------------+----------------------------------------------------------------------------+
  | Memory   | Output    | 1     | nice_icb_rsp_valid | This signal indicates E203 core sends a memory access response             |
  +          +-----------+-------+--------------------+----------------------------------------------------------------------------+
  | Response | Input     | 1     | nice_icb_rsp_ready | This signal indicates NICE-Core can receive memory                         |
  +          +-----------+-------+--------------------+----------------------------------------------------------------------------+
  | Channel  | Output    | 32    | nice_icb_rsp_rdata | Read data of memory access                                                 |
  |          +-----------+-------+--------------------+----------------------------------------------------------------------------+
  |          | Output    | 1     | nice_icb_rsp_err   | This signal indicates that an error is detected during memory access       |
  +----------+-----------+-------+--------------------+----------------------------------------------------------------------------+


NICE Instruction Handling
-------------------------

Before instruction sent to NICE-Core through the NICE interface, it is decoded by E203 processor core and marked as a NICE instruction, at the same time rs1 and rs2 registers are read for the NICE interface if needed. 

In case there is a dependency between NICE instruction and previous unfinished instruction, the pipeline would be stalled until the dependency being eliminated. With this mechanism, NICE instruction behaves just like a general instruction from E203 processor core.

NICE request channel confirms a transfer by ``nice_req_valid`` and ``nice_req_ready`` handshaking. ``nice_req_valid`` and other request information should keep stable until ``nice_req_ready`` signal is HIGH. 

After NICE-Core completes processing, it sends the responese to E203 processor core through NICE response channel.

.. note::
   When a NICE instruction is processing in NICE-Core, ``nice_req_ready`` signal is cleared to LOW, so new NICE request will be stalled until current NICE instruction completed.


NICE Memory Access
------------------

NICE-Core could access memory through the NICE interface which contains memory request channel and memory response channel.

In memory request channel, NICE-Core sends ICB request including ``nice_icb_cmd_valid``, ``nice_icb_cmd_addr``, ``nice_icb_cmd_size``, ``nice_icb_cmd_read`` and ``nice_icb_cmd_wdata`` (if it's a write operation), then these signals are waiting for ``nice_icb_cmd_ready`` from E203 processor core. Once valid-ready handshakes successfully, E203 processor core processes the memory access operation with its LSU pipe. 

In memory response channel, E203 processor core sends ``nice_icb_rsp_valid`` and ``nice_icb_rsp_rdata`` (if it is a read operation) to NICE-Core and waits for ``nice_icb_rsp_ready``. 

While the NICE-Core is going to access memory, ``nice_mem_holdup`` signal should be set to HIGH and keep HIGH until NICE-Core finishes all nice memory accesses. This mechanism blocks the following load and store instruction, which can avoid some deadlock scenarios. With the help of nice_mem_holdup, NICE-Core can kick off one or several memory accesses at any time before the NICE instruction is finished.


Typical NICE Operation Examples
-------------------------------

.. _figure_core_4:

.. figure:: /asserts/medias/core_fig4.png
   :width: 600
   :alt: core_fig4

   NICE-Core multi-cycle processing

.. _figure_core_5:

.. figure:: /asserts/medias/core_fig5.png
   :width: 600
   :alt: core_fig5

   NICE-Core access memory

.. _figure_core_6:

.. figure:: /asserts/medias/core_fig6.png
   :width: 600
   :alt: core_fig6

   Illegal NICE instruction
