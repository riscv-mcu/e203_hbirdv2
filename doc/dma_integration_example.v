/*                                                                      
Copyright 2018-2020 Nuclei System Technology, Inc.                

Licensed under the Apache License, Version 2.0 (the "License");         
you may not use this file except in compliance with the License.        
You may obtain a copy of the License at                                 
                                                                        
    http://www.apache.org/licenses/LICENSE-2.0                          
                                                                        
 Unless required by applicable law or agreed to in writing, software    
distributed under the License is distributed on an "AS IS" BASIS,       
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and     
limitations under the License.                                          
*/                                                                      

//=====================================================================
//
// Description:
//  DMA Integration Example for E203 Subsystem
//  
//  This file demonstrates how to integrate the DMA controller
//  into the E203 subsystem with proper bus connections.
//
// ====================================================================

`include "e203_defines.v"

module e203_subsys_dma_example(
  // ... existing subsys_main ports ...
  
  // DMA interrupt output (connect to PLIC)
  output  dma_irq,
  
  // ... other ports ...
  input   bus_clk,
  input   bus_rst_n
);

  // =====================================================================
  // DMA ICB Interface Signals
  // =====================================================================
  
  // DMA Configuration ICB (Slave) - connects to peripheral bus
  wire                         dma_cfg_icb_cmd_valid;
  wire                         dma_cfg_icb_cmd_ready;
  wire [`E203_ADDR_SIZE-1:0]   dma_cfg_icb_cmd_addr;
  wire                         dma_cfg_icb_cmd_read;
  wire [`E203_XLEN-1:0]        dma_cfg_icb_cmd_wdata;
  wire [`E203_XLEN/8-1:0]      dma_cfg_icb_cmd_wmask;
  
  wire                         dma_cfg_icb_rsp_valid;
  wire                         dma_cfg_icb_rsp_ready;
  wire                         dma_cfg_icb_rsp_err;
  wire [`E203_XLEN-1:0]        dma_cfg_icb_rsp_rdata;

  // DMA Memory ICB (Master) - connects to memory bus
  wire                         dma_mem_icb_cmd_valid;
  wire                         dma_mem_icb_cmd_ready;
  wire [`E203_ADDR_SIZE-1:0]   dma_mem_icb_cmd_addr;
  wire                         dma_mem_icb_cmd_read;
  wire [`E203_XLEN-1:0]        dma_mem_icb_cmd_wdata;
  wire [`E203_XLEN/8-1:0]      dma_mem_icb_cmd_wmask;
  wire                         dma_mem_icb_cmd_lock;
  wire                         dma_mem_icb_cmd_excl;
  wire [1:0]                   dma_mem_icb_cmd_size;
  
  wire                         dma_mem_icb_rsp_valid;
  wire                         dma_mem_icb_rsp_ready;
  wire                         dma_mem_icb_rsp_err;
  wire                         dma_mem_icb_rsp_excl_ok;
  wire [`E203_XLEN-1:0]        dma_mem_icb_rsp_rdata;

  // =====================================================================
  // DMA Controller Instance
  // =====================================================================
  
  e203_dma_ctrl #(
    .AW(`E203_ADDR_SIZE),
    .DW(`E203_XLEN)
  ) u_e203_dma_ctrl (
    // Configuration interface (slave)
    .cfg_icb_cmd_valid   (dma_cfg_icb_cmd_valid),
    .cfg_icb_cmd_ready   (dma_cfg_icb_cmd_ready),
    .cfg_icb_cmd_addr    (dma_cfg_icb_cmd_addr),
    .cfg_icb_cmd_read    (dma_cfg_icb_cmd_read),
    .cfg_icb_cmd_wdata   (dma_cfg_icb_cmd_wdata),
    .cfg_icb_cmd_wmask   (dma_cfg_icb_cmd_wmask),
    
    .cfg_icb_rsp_valid   (dma_cfg_icb_rsp_valid),
    .cfg_icb_rsp_ready   (dma_cfg_icb_rsp_ready),
    .cfg_icb_rsp_err     (dma_cfg_icb_rsp_err),
    .cfg_icb_rsp_rdata   (dma_cfg_icb_rsp_rdata),
    
    // Memory interface (master)
    .mem_icb_cmd_valid   (dma_mem_icb_cmd_valid),
    .mem_icb_cmd_ready   (dma_mem_icb_cmd_ready),
    .mem_icb_cmd_addr    (dma_mem_icb_cmd_addr),
    .mem_icb_cmd_read    (dma_mem_icb_cmd_read),
    .mem_icb_cmd_wdata   (dma_mem_icb_cmd_wdata),
    .mem_icb_cmd_wmask   (dma_mem_icb_cmd_wmask),
    .mem_icb_cmd_lock    (dma_mem_icb_cmd_lock),
    .mem_icb_cmd_excl    (dma_mem_icb_cmd_excl),
    .mem_icb_cmd_size    (dma_mem_icb_cmd_size),
    
    .mem_icb_rsp_valid   (dma_mem_icb_rsp_valid),
    .mem_icb_rsp_ready   (dma_mem_icb_rsp_ready),
    .mem_icb_rsp_err     (dma_mem_icb_rsp_err),
    .mem_icb_rsp_excl_ok (dma_mem_icb_rsp_excl_ok),
    .mem_icb_rsp_rdata   (dma_mem_icb_rsp_rdata),
    
    // Interrupt
    .dma_irq             (dma_irq),
    
    // Clock and reset
    .clk                 (bus_clk),
    .rst_n               (bus_rst_n)
  );

  // =====================================================================
  // Bus Connection Example
  // =====================================================================
  
  // OPTION 1: Connect DMA config interface to peripheral bus
  // This requires modifying the peripheral bus fabric (e.g., sirv_icb1to8_bus)
  // to add DMA as one of the slave devices with address range 0x10002000-0x10002FFF
  
  /*
  sirv_icb1to8_bus #(
    // ... existing parameters ...
    // Add DMA address range
    .O7_BASE_ADDR      (32'h1000_2000),
    .O7_BASE_REGION_LSB(12)
  ) u_perips_bus (
    // ... existing connections ...
    
    // Connect DMA configuration interface as output 7
    .o7_icb_cmd_valid  (dma_cfg_icb_cmd_valid),
    .o7_icb_cmd_ready  (dma_cfg_icb_cmd_ready),
    .o7_icb_cmd_addr   (dma_cfg_icb_cmd_addr),
    .o7_icb_cmd_read   (dma_cfg_icb_cmd_read),
    .o7_icb_cmd_wdata  (dma_cfg_icb_cmd_wdata),
    .o7_icb_cmd_wmask  (dma_cfg_icb_cmd_wmask),
    
    .o7_icb_rsp_valid  (dma_cfg_icb_rsp_valid),
    .o7_icb_rsp_ready  (dma_cfg_icb_rsp_ready),
    .o7_icb_rsp_err    (dma_cfg_icb_rsp_err),
    .o7_icb_rsp_rdata  (dma_cfg_icb_rsp_rdata),
    
    // ... other connections ...
  );
  */
  
  // OPTION 2: Connect DMA memory interface to system memory bus
  // This requires an arbiter to share bus between CPU and DMA
  
  /*
  sirv_gnrl_icb_arbt #(
    .AW           (`E203_ADDR_SIZE),
    .DW           (`E203_XLEN),
    .USR_W        (1),
    .ARBT_NUM     (2),  // CPU + DMA
    .ARBT_SCHEME  (0)   // Priority based: CPU has higher priority
  ) u_mem_bus_arbt (
    // Output to memory
    .o_icb_cmd_valid   (mem_icb_cmd_valid),
    .o_icb_cmd_ready   (mem_icb_cmd_ready),
    .o_icb_cmd_addr    (mem_icb_cmd_addr),
    .o_icb_cmd_read    (mem_icb_cmd_read),
    .o_icb_cmd_wdata   (mem_icb_cmd_wdata),
    .o_icb_cmd_wmask   (mem_icb_cmd_wmask),
    // ... other output signals ...
    
    .o_icb_rsp_valid   (mem_icb_rsp_valid),
    .o_icb_rsp_ready   (mem_icb_rsp_ready),
    .o_icb_rsp_rdata   (mem_icb_rsp_rdata),
    .o_icb_rsp_err     (mem_icb_rsp_err),
    // ... other response signals ...
    
    // Input 0: CPU
    .i_bus_icb_cmd_valid({cpu_mem_icb_cmd_valid, dma_mem_icb_cmd_valid}),
    .i_bus_icb_cmd_ready({cpu_mem_icb_cmd_ready, dma_mem_icb_cmd_ready}),
    // ... CPU connections ...
    
    // Input 1: DMA
    // ... DMA memory interface connections ...
    
    .clk   (bus_clk),
    .rst_n (bus_rst_n)
  );
  */

  // =====================================================================
  // Address Map Notes
  // =====================================================================
  //
  // Recommended DMA register address: 0x10002000 - 0x10002FFF
  //
  // This address range should be added to the peripheral bus decoder.
  // Ensure it doesn't conflict with existing peripherals:
  //   - GPIO:  0x10012000
  //   - UART:  0x10013000
  //   - QSPI:  0x10014000
  //   - PWM:   0x10015000
  //   - I2C:   0x10016000
  //   - DMA:   0x10002000 (proposed)
  //
  // =====================================================================

endmodule

// =====================================================================
// Integration Steps Summary
// =====================================================================
//
// 1. Add DMA module files to compilation:
//    - rtl/e203/perips/e203_dma_ctrl.v
//
// 2. Modify e203_subsys_main.v:
//    - Add DMA instance
//    - Declare DMA ICB signals
//    - Add dma_irq output port
//
// 3. Modify peripheral bus fabric:
//    - Expand sirv_icb1to8_bus to sirv_icb1to16_bus if needed
//    - Add DMA configuration interface as a slave
//    - Set base address to 0x10002000
//
// 4. Modify memory bus:
//    - Add arbiter if not present
//    - Connect DMA memory interface as additional master
//    - Set CPU priority higher than DMA
//
// 5. Connect to PLIC (optional):
//    - Add dma_irq to PLIC interrupt sources
//    - Assign interrupt number (e.g., IRQ #16)
//
// 6. Update software:
//    - Add DMA driver code
//    - Define DMA register addresses
//    - Add interrupt handler if using interrupts
//
// =====================================================================
