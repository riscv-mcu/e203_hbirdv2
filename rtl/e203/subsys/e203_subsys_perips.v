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
// Designer   : Jayden Hu
//
// Description:
//  The peirpheral bus and the connected devices 
//
// ====================================================================

`include "e203_defines.v"


module e203_subsys_perips(
  input                          ppi_icb_cmd_valid,
  output                         ppi_icb_cmd_ready,
  input  [`E203_ADDR_SIZE-1:0]   ppi_icb_cmd_addr, 
  input                          ppi_icb_cmd_read, 
  input  [`E203_XLEN-1:0]        ppi_icb_cmd_wdata,
  input  [`E203_XLEN/8-1:0]      ppi_icb_cmd_wmask,
  //
  output                         ppi_icb_rsp_valid,
  input                          ppi_icb_rsp_ready,
  output                         ppi_icb_rsp_err,
  output [`E203_XLEN-1:0]        ppi_icb_rsp_rdata,
  
  //////////////////////////////////////////////////////////
  output                         sysper_icb_cmd_valid,
  input                          sysper_icb_cmd_ready,
  output [`E203_ADDR_SIZE-1:0]   sysper_icb_cmd_addr, 
  output                         sysper_icb_cmd_read, 
  output [`E203_XLEN-1:0]        sysper_icb_cmd_wdata,
  output [`E203_XLEN/8-1:0]      sysper_icb_cmd_wmask,
  //
  input                          sysper_icb_rsp_valid,
  output                         sysper_icb_rsp_ready,
  input                          sysper_icb_rsp_err,
  input  [`E203_XLEN-1:0]        sysper_icb_rsp_rdata,

  //////////////////////////////////////////////////////////
  output                         aon_icb_cmd_valid,
  input                          aon_icb_cmd_ready,
  output [`E203_ADDR_SIZE-1:0]   aon_icb_cmd_addr, 
  output                         aon_icb_cmd_read, 
  output [`E203_XLEN-1:0]        aon_icb_cmd_wdata,
  //
  input                          aon_icb_rsp_valid,
  output                         aon_icb_rsp_ready,
  input                          aon_icb_rsp_err,
  input  [`E203_XLEN-1:0]        aon_icb_rsp_rdata,

  input                      qspi0_ro_icb_cmd_valid,
  output                     qspi0_ro_icb_cmd_ready,
  input  [32-1:0]            qspi0_ro_icb_cmd_addr, 
  input                      qspi0_ro_icb_cmd_read, 
  input  [32-1:0]            qspi0_ro_icb_cmd_wdata,
  
  output                     qspi0_ro_icb_rsp_valid,
  input                      qspi0_ro_icb_rsp_ready,
  output [32-1:0]            qspi0_ro_icb_rsp_rdata,

  input  [32-1:0]            io_pads_gpioA_i_ival,
  output [32-1:0]            io_pads_gpioA_o_oval,
  output [32-1:0]            io_pads_gpioA_o_oe,

  input  [32-1:0]            io_pads_gpioB_i_ival,
  output [32-1:0]            io_pads_gpioB_o_oval,
  output [32-1:0]            io_pads_gpioB_o_oe,

  input   io_pads_qspi0_sck_i_ival,
  output  io_pads_qspi0_sck_o_oval,
  output  io_pads_qspi0_sck_o_oe,
  input   io_pads_qspi0_dq_0_i_ival,
  output  io_pads_qspi0_dq_0_o_oval,
  output  io_pads_qspi0_dq_0_o_oe,
  input   io_pads_qspi0_dq_1_i_ival,
  output  io_pads_qspi0_dq_1_o_oval,
  output  io_pads_qspi0_dq_1_o_oe,
  input   io_pads_qspi0_dq_2_i_ival,
  output  io_pads_qspi0_dq_2_o_oval,
  output  io_pads_qspi0_dq_2_o_oe,
  input   io_pads_qspi0_dq_3_i_ival,
  output  io_pads_qspi0_dq_3_o_oval,
  output  io_pads_qspi0_dq_3_o_oe,
  input   io_pads_qspi0_cs_0_i_ival,
  output  io_pads_qspi0_cs_0_o_oval,
  output  io_pads_qspi0_cs_0_o_oe,

  output qspi0_irq, 
  output qspi1_irq,
  output qspi2_irq,

  output pwm_irq_0,
  output pwm_irq_1,
  output pwm_irq_2,
  output pwm_irq_3,

  output i2c0_mst_irq,
  output i2c1_mst_irq,

  output gpioA_irq,
  output gpioB_irq,
 
  output uart0_irq,                
  output uart1_irq,                
  output uart2_irq,                

  output pllbypass ,
  output pll_RESET ,
  output pll_ASLEEP ,
  output [1:0]  pll_OD,
  output [7:0]  pll_M,
  output [4:0]  pll_N,
  output plloutdivby1,
  output [5:0] plloutdiv,

  output hfxoscen,

  input  ls_clk,
  input  clk,
  input  bus_rst_n,
  input  rst_n
  );

  
  wire                         i_aon_icb_cmd_valid;
  wire                         i_aon_icb_cmd_ready;
  wire [`E203_ADDR_SIZE-1:0]   i_aon_icb_cmd_addr; 
  wire                         i_aon_icb_cmd_read; 
  wire [`E203_XLEN-1:0]        i_aon_icb_cmd_wdata;

  wire                         i_aon_icb_rsp_valid;
  wire                         i_aon_icb_rsp_ready;
  wire                         i_aon_icb_rsp_err;
  wire [`E203_XLEN-1:0]        i_aon_icb_rsp_rdata;


  wire qspi0_sck;
  wire qspi0_dq_0_i;
  wire qspi0_dq_0_o;
  wire qspi0_dq_0_oe;
  wire qspi0_dq_1_i;
  wire qspi0_dq_1_o;
  wire qspi0_dq_1_oe;
  wire qspi0_dq_2_i;
  wire qspi0_dq_2_o;
  wire qspi0_dq_2_oe;
  wire qspi0_dq_3_i;
  wire qspi0_dq_3_o;
  wire qspi0_dq_3_oe;
  wire qspi0_cs_0;


  wire                     qspi0_icb_cmd_valid;
  wire                     qspi0_icb_cmd_ready;
  wire [32-1:0]            qspi0_icb_cmd_addr; 
  wire                     qspi0_icb_cmd_read; 
  wire [32-1:0]            qspi0_icb_cmd_wdata;
  
  wire                     qspi0_icb_rsp_valid;
  wire                     qspi0_icb_rsp_ready;
  wire [32-1:0]            qspi0_icb_rsp_rdata;

  wire                     uart0_apb_icb_cmd_valid;
  wire                     uart0_apb_icb_cmd_ready;
  wire [32-1:0]            uart0_apb_icb_cmd_addr; 
  wire                     uart0_apb_icb_cmd_read; 
  wire [32-1:0]            uart0_apb_icb_cmd_wdata;
  wire [4 -1:0]            uart0_apb_icb_cmd_wmask;
  
  wire                     uart0_apb_icb_rsp_valid;
  wire                     uart0_apb_icb_rsp_ready;
  wire [32-1:0]            uart0_apb_icb_rsp_rdata;
  wire                     uart0_apb_icb_rsp_err;

  wire                     uart1_apb_icb_cmd_valid;
  wire                     uart1_apb_icb_cmd_ready;
  wire [32-1:0]            uart1_apb_icb_cmd_addr; 
  wire                     uart1_apb_icb_cmd_read; 
  wire [32-1:0]            uart1_apb_icb_cmd_wdata;
  wire [4 -1:0]            uart1_apb_icb_cmd_wmask;
  
  wire                     uart1_apb_icb_rsp_valid;
  wire                     uart1_apb_icb_rsp_ready;
  wire [32-1:0]            uart1_apb_icb_rsp_rdata;
  wire                     uart1_apb_icb_rsp_err; 

  wire                     uart2_apb_icb_cmd_valid;
  wire                     uart2_apb_icb_cmd_ready;
  wire [32-1:0]            uart2_apb_icb_cmd_addr; 
  wire                     uart2_apb_icb_cmd_read; 
  wire [32-1:0]            uart2_apb_icb_cmd_wdata;
  wire [4 -1:0]            uart2_apb_icb_cmd_wmask;
  
  wire                     uart2_apb_icb_rsp_valid;
  wire                     uart2_apb_icb_rsp_ready;
  wire [32-1:0]            uart2_apb_icb_rsp_rdata;
  wire                     uart2_apb_icb_rsp_err;  

  wire                     spi1_apb_icb_cmd_valid;
  wire                     spi1_apb_icb_cmd_ready;
  wire [32-1:0]            spi1_apb_icb_cmd_addr; 
  wire                     spi1_apb_icb_cmd_read; 
  wire [32-1:0]            spi1_apb_icb_cmd_wdata;
  wire [4 -1:0]            spi1_apb_icb_cmd_wmask;
  
  wire                     spi1_apb_icb_rsp_valid;
  wire                     spi1_apb_icb_rsp_ready;
  wire [32-1:0]            spi1_apb_icb_rsp_rdata;
  wire                     spi1_apb_icb_rsp_err;

  wire                     spi2_apb_icb_cmd_valid;
  wire                     spi2_apb_icb_cmd_ready;
  wire [32-1:0]            spi2_apb_icb_cmd_addr; 
  wire                     spi2_apb_icb_cmd_read; 
  wire [32-1:0]            spi2_apb_icb_cmd_wdata;
  wire [4 -1:0]            spi2_apb_icb_cmd_wmask;
  
  wire                     spi2_apb_icb_rsp_valid;
  wire                     spi2_apb_icb_rsp_ready;
  wire [32-1:0]            spi2_apb_icb_rsp_rdata;
  wire                     spi2_apb_icb_rsp_err;  

  wire                     expl_axi_icb_cmd_valid;
  wire                     expl_axi_icb_cmd_ready;
  wire [32-1:0]            expl_axi_icb_cmd_addr; 
  wire                     expl_axi_icb_cmd_read; 
  wire [32-1:0]            expl_axi_icb_cmd_wdata;
  wire [4 -1:0]            expl_axi_icb_cmd_wmask;
  
  wire                     expl_axi_icb_rsp_valid;
  wire                     expl_axi_icb_rsp_ready;
  wire [32-1:0]            expl_axi_icb_rsp_rdata;
  wire                     expl_axi_icb_rsp_err;

  wire                     gpioA_apb_icb_cmd_valid;
  wire                     gpioA_apb_icb_cmd_ready;
  wire [32-1:0]            gpioA_apb_icb_cmd_addr; 
  wire                     gpioA_apb_icb_cmd_read; 
  wire [32-1:0]            gpioA_apb_icb_cmd_wdata;
  wire [4 -1:0]            gpioA_apb_icb_cmd_wmask;
  
  wire                     gpioA_apb_icb_rsp_valid;
  wire                     gpioA_apb_icb_rsp_ready;
  wire [32-1:0]            gpioA_apb_icb_rsp_rdata;
  wire                     gpioA_apb_icb_rsp_err;

  wire                     gpioB_apb_icb_cmd_valid;
  wire                     gpioB_apb_icb_cmd_ready;
  wire [32-1:0]            gpioB_apb_icb_cmd_addr; 
  wire                     gpioB_apb_icb_cmd_read; 
  wire [32-1:0]            gpioB_apb_icb_cmd_wdata;
  wire [4 -1:0]            gpioB_apb_icb_cmd_wmask;
  
  wire                     gpioB_apb_icb_rsp_valid;
  wire                     gpioB_apb_icb_rsp_ready;
  wire [32-1:0]            gpioB_apb_icb_rsp_rdata;
  wire                     gpioB_apb_icb_rsp_err;

  wire                     i2c0_apb_icb_cmd_valid;
  wire                     i2c0_apb_icb_cmd_ready;
  wire [32-1:0]            i2c0_apb_icb_cmd_addr; 
  wire                     i2c0_apb_icb_cmd_read; 
  wire [32-1:0]            i2c0_apb_icb_cmd_wdata;
  wire [4 -1:0]            i2c0_apb_icb_cmd_wmask;
  
  wire                     i2c0_apb_icb_rsp_valid;
  wire                     i2c0_apb_icb_rsp_ready;
  wire [32-1:0]            i2c0_apb_icb_rsp_rdata;
  wire                     i2c0_apb_icb_rsp_err;

  wire                     i2c1_apb_icb_cmd_valid;
  wire                     i2c1_apb_icb_cmd_ready;
  wire [32-1:0]            i2c1_apb_icb_cmd_addr; 
  wire                     i2c1_apb_icb_cmd_read; 
  wire [32-1:0]            i2c1_apb_icb_cmd_wdata;
  wire [4 -1:0]            i2c1_apb_icb_cmd_wmask;
  
  wire                     i2c1_apb_icb_rsp_valid;
  wire                     i2c1_apb_icb_rsp_ready;
  wire [32-1:0]            i2c1_apb_icb_rsp_rdata;
  wire                     i2c1_apb_icb_rsp_err;  

  wire                     pwm_apb_icb_cmd_valid;
  wire                     pwm_apb_icb_cmd_ready;
  wire [32-1:0]            pwm_apb_icb_cmd_addr; 
  wire                     pwm_apb_icb_cmd_read; 
  wire [32-1:0]            pwm_apb_icb_cmd_wdata;
  wire [4 -1:0]            pwm_apb_icb_cmd_wmask;
  
  wire                     pwm_apb_icb_rsp_valid;
  wire                     pwm_apb_icb_rsp_ready;
  wire [32-1:0]            pwm_apb_icb_rsp_rdata;
  wire                     pwm_apb_icb_rsp_err;

  wire                     hclkgen_icb_cmd_valid;
  wire                     hclkgen_icb_cmd_ready;
  wire [32-1:0]            hclkgen_icb_cmd_addr; 
  wire                     hclkgen_icb_cmd_read; 
  wire [32-1:0]            hclkgen_icb_cmd_wdata;
  wire [4 -1:0]            hclkgen_icb_cmd_wmask;
  
  wire                     hclkgen_icb_rsp_valid;
  wire                     hclkgen_icb_rsp_ready;
  wire [32-1:0]            hclkgen_icb_rsp_rdata;
  wire                     hclkgen_icb_rsp_err;

  // The total address range for the PPI is from/to
  //  **************0x1000 0000 -- 0x1FFF FFFF
  // There are several slaves for PPI bus, including:
  //  * AON       : 0x1000 0000 -- 0x1000 7FFF
  //  * HCLKGEN   : 0x1000 8000 -- 0x1000 8FFF
  //  * GPIOA     : 0x1001 2000 -- 0x1001 2FFF
  //  * UART0     : 0x1001 3000 -- 0x1001 3FFF
  //  * QSPI0     : 0x1001 4000 -- 0x1001 4FFF
  //  * PWM       : 0x1001 5000 -- 0x1001 5FFF
  //  * UART1     : 0x1002 3000 -- 0x1002 3FFF
  //  * QSPI1     : 0x1002 4000 -- 0x1002 4FFF
  //  * I2C0      : 0x1002 5000 -- 0x1002 5FFF
  //  * UART2     : 0x1003 3000 -- 0x1003 3FFF
  //  * QSPI2     : 0x1003 4000 -- 0x1003 4FFF
  //  * I2C1      : 0x1003 5000 -- 0x1003 5FFF
  //  * GPIOB     : 0x1004 0000 -- 0x1004 0FFF
  //  * Example-AXI      : 0x1004 1000 -- 0x1004 1FFF
  //  * Reserved         : 0x1004 2000 -- 0x1004 2FFF
  //  * SysPer    : 0x1100 0000 -- 0x11FF FFFF

  sirv_icb1to16_bus # (
  .ICB_FIFO_DP        (2),// We add a ping-pong buffer here to cut down the timing path
  .ICB_FIFO_CUT_READY (1),// We configure it to cut down the back-pressure ready signal

  .AW                   (32),
  .DW                   (`E203_XLEN),
  .SPLT_FIFO_OUTS_NUM   (1),// The peirpherals only allow 1 oustanding
  .SPLT_FIFO_CUT_READY  (1),// The peirpherals always cut ready
  //  * AON       : 0x1000 0000 -- 0x1000 7FFF
  .O0_BASE_ADDR       (32'h1000_0000),       
  .O0_BASE_REGION_LSB (15),
  //  * HCLKGEN   : 0x1000 8000 -- 0x1000 8FFF
  .O1_BASE_ADDR       (32'h1000_8000),       
  .O1_BASE_REGION_LSB (12),
  //  * GPIOA     : 0x1001 2000 -- 0x1001 2FFF
  .O2_BASE_ADDR       (32'h1001_2000),       
  .O2_BASE_REGION_LSB (12),
  //  * UART0     : 0x1001 3000 -- 0x1001 3FFF
  .O3_BASE_ADDR       (32'h1001_3000),       
  .O3_BASE_REGION_LSB (12),
  //  * QSPI0     : 0x1001 4000 -- 0x1001 4FFF
  .O4_BASE_ADDR       (32'h1001_4000),       
  .O4_BASE_REGION_LSB (12),
  //  * PWM       : 0x1001 5000 -- 0x1001 5FFF
  .O5_BASE_ADDR       (32'h1001_5000),       
  .O5_BASE_REGION_LSB (12),
  //  * UART1     : 0x1002 3000 -- 0x1002 3FFF
  .O6_BASE_ADDR       (32'h1002_3000),       
  .O6_BASE_REGION_LSB (12),
  //  * QSPI1     : 0x1002 4000 -- 0x1002 4FFF
  .O7_BASE_ADDR       (32'h1002_4000),       
  .O7_BASE_REGION_LSB (12),
  //  * I2C0      : 0x1002 5000 -- 0x1002 5FFF
  .O8_BASE_ADDR       (32'h1002_5000),       
  .O8_BASE_REGION_LSB (12),
  //  * UART2     : 0x1003 3000 -- 0x1003 3FFF
  .O9_BASE_ADDR       (32'h1003_3000),       
  .O9_BASE_REGION_LSB (12),
  //  * QSPI2     : 0x1003 4000 -- 0x1003 4FFF
  .O10_BASE_ADDR       (32'h1003_4000),       
  .O10_BASE_REGION_LSB (12),
  //  * I2C1      : 0x1003 5000 -- 0x1003 5FFF
  .O11_BASE_ADDR       (32'h1003_5000),       
  .O11_BASE_REGION_LSB (12),
  //  * SysPer    : 0x1100 0000 -- 0x11FF FFFF
  .O12_BASE_ADDR       (32'h1100_0000),       
  .O12_BASE_REGION_LSB (24),

  // * GPIOB      : 0x1004 0000 -- 0x1004 0FFF
  .O13_BASE_ADDR       (32'h1004_0000),       
  .O13_BASE_REGION_LSB (12),
  
  // * Here is an example AXI Peripheral
  .O14_BASE_ADDR       (32'h1004_1000),       
  .O14_BASE_REGION_LSB (12),
  
  // * Reserved 
  .O15_BASE_ADDR       (32'h1004_2000),       
  .O15_BASE_REGION_LSB (3)

  )u_sirv_ppi_fab(

    .i_icb_cmd_valid  (ppi_icb_cmd_valid),
    .i_icb_cmd_ready  (ppi_icb_cmd_ready),
    .i_icb_cmd_addr   (ppi_icb_cmd_addr ),
    .i_icb_cmd_read   (ppi_icb_cmd_read ),
    .i_icb_cmd_wdata  (ppi_icb_cmd_wdata),
    .i_icb_cmd_wmask  (ppi_icb_cmd_wmask),
    .i_icb_cmd_lock   (1'b0),
    .i_icb_cmd_excl   (1'b0 ),
    .i_icb_cmd_size   (2'b0 ),
    .i_icb_cmd_burst  (2'b0 ),
    .i_icb_cmd_beat   (2'b0 ),
    
    .i_icb_rsp_valid  (ppi_icb_rsp_valid),
    .i_icb_rsp_ready  (ppi_icb_rsp_ready),
    .i_icb_rsp_err    (ppi_icb_rsp_err  ),
    .i_icb_rsp_excl_ok(),
    .i_icb_rsp_rdata  (ppi_icb_rsp_rdata),
    
  //  * AON 
    .o0_icb_enable     (1'b1),

        //
    .o0_icb_cmd_valid  (i_aon_icb_cmd_valid),
    .o0_icb_cmd_ready  (i_aon_icb_cmd_ready),
    .o0_icb_cmd_addr   (i_aon_icb_cmd_addr ),
    .o0_icb_cmd_read   (i_aon_icb_cmd_read ),
    .o0_icb_cmd_wdata  (i_aon_icb_cmd_wdata),
    .o0_icb_cmd_wmask  (),
    .o0_icb_cmd_lock   (),
    .o0_icb_cmd_excl   (),
    .o0_icb_cmd_size   (),
    .o0_icb_cmd_burst  (),
    .o0_icb_cmd_beat   (),
    
    .o0_icb_rsp_valid  (i_aon_icb_rsp_valid),
    .o0_icb_rsp_ready  (i_aon_icb_rsp_ready),
    .o0_icb_rsp_err    (i_aon_icb_rsp_err),
    .o0_icb_rsp_excl_ok(1'b0  ),
    .o0_icb_rsp_rdata  (i_aon_icb_rsp_rdata),

  //  * HCLKGEN      
    .o1_icb_enable     (1'b1),

    .o1_icb_cmd_valid  (hclkgen_icb_cmd_valid),
    .o1_icb_cmd_ready  (hclkgen_icb_cmd_ready),
    .o1_icb_cmd_addr   (hclkgen_icb_cmd_addr ),
    .o1_icb_cmd_read   (hclkgen_icb_cmd_read ),
    .o1_icb_cmd_wdata  (hclkgen_icb_cmd_wdata),
    .o1_icb_cmd_wmask  (),
    .o1_icb_cmd_lock   (),
    .o1_icb_cmd_excl   (),
    .o1_icb_cmd_size   (),
    .o1_icb_cmd_burst  (),
    .o1_icb_cmd_beat   (),
    
    .o1_icb_rsp_valid  (hclkgen_icb_rsp_valid),
    .o1_icb_rsp_ready  (hclkgen_icb_rsp_ready),
    .o1_icb_rsp_err    (1'b0  ),
    .o1_icb_rsp_excl_ok(1'b0  ),
    .o1_icb_rsp_rdata  (hclkgen_icb_rsp_rdata),


  //  * GPIOA      
    .o2_icb_enable     (1'b1),

    .o2_icb_cmd_valid  (gpioA_apb_icb_cmd_valid),
    .o2_icb_cmd_ready  (gpioA_apb_icb_cmd_ready),
    .o2_icb_cmd_addr   (gpioA_apb_icb_cmd_addr ),
    .o2_icb_cmd_read   (gpioA_apb_icb_cmd_read ),
    .o2_icb_cmd_wdata  (gpioA_apb_icb_cmd_wdata),
    .o2_icb_cmd_wmask  (gpioA_apb_icb_cmd_wmask),
    .o2_icb_cmd_lock   (),
    .o2_icb_cmd_excl   (),
    .o2_icb_cmd_size   (),
    .o2_icb_cmd_burst  (),
    .o2_icb_cmd_beat   (),
    
    .o2_icb_rsp_valid  (gpioA_apb_icb_rsp_valid),
    .o2_icb_rsp_ready  (gpioA_apb_icb_rsp_ready),
    .o2_icb_rsp_err    (gpioA_apb_icb_rsp_err),
    .o2_icb_rsp_excl_ok(1'b0  ),
    .o2_icb_rsp_rdata  (gpioA_apb_icb_rsp_rdata),

  //  * UART0     
    .o3_icb_enable     (1'b1),

    .o3_icb_cmd_valid  (uart0_apb_icb_cmd_valid),
    .o3_icb_cmd_ready  (uart0_apb_icb_cmd_ready),
    .o3_icb_cmd_addr   (uart0_apb_icb_cmd_addr ),
    .o3_icb_cmd_read   (uart0_apb_icb_cmd_read ),
    .o3_icb_cmd_wdata  (uart0_apb_icb_cmd_wdata),
    .o3_icb_cmd_wmask  (uart0_apb_icb_cmd_wmask),
    .o3_icb_cmd_lock   (),
    .o3_icb_cmd_excl   (),
    .o3_icb_cmd_size   (),
    .o3_icb_cmd_burst  (),
    .o3_icb_cmd_beat   (),
    
    .o3_icb_rsp_valid  (uart0_apb_icb_rsp_valid),
    .o3_icb_rsp_ready  (uart0_apb_icb_rsp_ready),
    .o3_icb_rsp_err    (uart0_apb_icb_rsp_err  ),
    .o3_icb_rsp_excl_ok(1'b0  ),
    .o3_icb_rsp_rdata  (uart0_apb_icb_rsp_rdata),

  //  * QSPI0     
    .o4_icb_enable     (1'b1),

    .o4_icb_cmd_valid  (qspi0_icb_cmd_valid),
    .o4_icb_cmd_ready  (qspi0_icb_cmd_ready),
    .o4_icb_cmd_addr   (qspi0_icb_cmd_addr ),
    .o4_icb_cmd_read   (qspi0_icb_cmd_read ),
    .o4_icb_cmd_wdata  (qspi0_icb_cmd_wdata),
    .o4_icb_cmd_wmask  (),
    .o4_icb_cmd_lock   (),
    .o4_icb_cmd_excl   (),
    .o4_icb_cmd_size   (),
    .o4_icb_cmd_burst  (),
    .o4_icb_cmd_beat   (),
    
    .o4_icb_rsp_valid  (qspi0_icb_rsp_valid),
    .o4_icb_rsp_ready  (qspi0_icb_rsp_ready),
    .o4_icb_rsp_err    (1'b0  ),
    .o4_icb_rsp_excl_ok(1'b0  ),
    .o4_icb_rsp_rdata  (qspi0_icb_rsp_rdata),


  //  * PWM      
    .o5_icb_enable     (1'b1),

    .o5_icb_cmd_valid  (pwm_apb_icb_cmd_valid),
    .o5_icb_cmd_ready  (pwm_apb_icb_cmd_ready),
    .o5_icb_cmd_addr   (pwm_apb_icb_cmd_addr ),
    .o5_icb_cmd_read   (pwm_apb_icb_cmd_read ),
    .o5_icb_cmd_wdata  (pwm_apb_icb_cmd_wdata),
    .o5_icb_cmd_wmask  (pwm_apb_icb_cmd_wmask),
    .o5_icb_cmd_lock   (),
    .o5_icb_cmd_excl   (),
    .o5_icb_cmd_size   (),
    .o5_icb_cmd_burst  (),
    .o5_icb_cmd_beat   (),
    
    .o5_icb_rsp_valid  (pwm_apb_icb_rsp_valid),
    .o5_icb_rsp_ready  (pwm_apb_icb_rsp_ready),
    .o5_icb_rsp_err    (pwm_apb_icb_rsp_err  ),
    .o5_icb_rsp_excl_ok(1'b0  ),
    .o5_icb_rsp_rdata  (pwm_apb_icb_rsp_rdata),

  //  * UART1     
    .o6_icb_enable     (1'b1),

    .o6_icb_cmd_valid  (uart1_apb_icb_cmd_valid),
    .o6_icb_cmd_ready  (uart1_apb_icb_cmd_ready),
    .o6_icb_cmd_addr   (uart1_apb_icb_cmd_addr ),
    .o6_icb_cmd_read   (uart1_apb_icb_cmd_read ),
    .o6_icb_cmd_wdata  (uart1_apb_icb_cmd_wdata),
    .o6_icb_cmd_wmask  (uart1_apb_icb_cmd_wmask),
    .o6_icb_cmd_lock   (),
    .o6_icb_cmd_excl   (),
    .o6_icb_cmd_size   (),
    .o6_icb_cmd_burst  (),
    .o6_icb_cmd_beat   (),
    
    .o6_icb_rsp_valid  (uart1_apb_icb_rsp_valid),
    .o6_icb_rsp_ready  (uart1_apb_icb_rsp_ready),
    .o6_icb_rsp_err    (uart1_apb_icb_rsp_err  ),
    .o6_icb_rsp_excl_ok(1'b0  ),
    .o6_icb_rsp_rdata  (uart1_apb_icb_rsp_rdata),

  //  * QSPI1     
    .o7_icb_enable     (1'b1),

    .o7_icb_cmd_valid  (spi1_apb_icb_cmd_valid),
    .o7_icb_cmd_ready  (spi1_apb_icb_cmd_ready),
    .o7_icb_cmd_addr   (spi1_apb_icb_cmd_addr ),
    .o7_icb_cmd_read   (spi1_apb_icb_cmd_read ),
    .o7_icb_cmd_wdata  (spi1_apb_icb_cmd_wdata),
    .o7_icb_cmd_wmask  (spi1_apb_icb_cmd_wmask),
    .o7_icb_cmd_lock   (),
    .o7_icb_cmd_excl   (),
    .o7_icb_cmd_size   (),
    .o7_icb_cmd_burst  (),
    .o7_icb_cmd_beat   (),
    
    .o7_icb_rsp_valid  (spi1_apb_icb_rsp_valid),
    .o7_icb_rsp_ready  (spi1_apb_icb_rsp_ready),
    .o7_icb_rsp_err    (spi1_apb_icb_rsp_err  ),
    .o7_icb_rsp_excl_ok(1'b0  ),
    .o7_icb_rsp_rdata  (spi1_apb_icb_rsp_rdata),

  //  * I2C0      
    .o8_icb_enable     (1'b1),

    .o8_icb_cmd_valid  (i2c0_apb_icb_cmd_valid),
    .o8_icb_cmd_ready  (i2c0_apb_icb_cmd_ready),
    .o8_icb_cmd_addr   (i2c0_apb_icb_cmd_addr ),
    .o8_icb_cmd_read   (i2c0_apb_icb_cmd_read ),
    .o8_icb_cmd_wdata  (i2c0_apb_icb_cmd_wdata),
    .o8_icb_cmd_wmask  (i2c0_apb_icb_cmd_wmask),
    .o8_icb_cmd_lock   (),
    .o8_icb_cmd_excl   (),
    .o8_icb_cmd_size   (),
    .o8_icb_cmd_burst  (),
    .o8_icb_cmd_beat   (),
    
    .o8_icb_rsp_valid  (i2c0_apb_icb_rsp_valid),
    .o8_icb_rsp_ready  (i2c0_apb_icb_rsp_ready),
    .o8_icb_rsp_err    (i2c0_apb_icb_rsp_err),
    .o8_icb_rsp_excl_ok(1'b0  ),
    .o8_icb_rsp_rdata  (i2c0_apb_icb_rsp_rdata),

  //  * UART2     
    .o9_icb_enable     (1'b1),

    .o9_icb_cmd_valid  (uart2_apb_icb_cmd_valid),
    .o9_icb_cmd_ready  (uart2_apb_icb_cmd_ready),
    .o9_icb_cmd_addr   (uart2_apb_icb_cmd_addr ),
    .o9_icb_cmd_read   (uart2_apb_icb_cmd_read ),
    .o9_icb_cmd_wdata  (uart2_apb_icb_cmd_wdata),
    .o9_icb_cmd_wmask  (uart2_apb_icb_cmd_wmask),
    .o9_icb_cmd_lock   (),
    .o9_icb_cmd_excl   (),
    .o9_icb_cmd_size   (),
    .o9_icb_cmd_burst  (),
    .o9_icb_cmd_beat   (),
    
    .o9_icb_rsp_valid  (uart2_apb_icb_rsp_valid),
    .o9_icb_rsp_ready  (uart2_apb_icb_rsp_ready),
    .o9_icb_rsp_err    (uart2_apb_icb_rsp_err  ),
    .o9_icb_rsp_excl_ok(1'b0  ),
    .o9_icb_rsp_rdata  (uart2_apb_icb_rsp_rdata),

  //  * QSPI2     
    .o10_icb_enable     (1'b1),

    .o10_icb_cmd_valid  (spi2_apb_icb_cmd_valid),
    .o10_icb_cmd_ready  (spi2_apb_icb_cmd_ready),
    .o10_icb_cmd_addr   (spi2_apb_icb_cmd_addr ),
    .o10_icb_cmd_read   (spi2_apb_icb_cmd_read ),
    .o10_icb_cmd_wdata  (spi2_apb_icb_cmd_wdata),
    .o10_icb_cmd_wmask  (spi2_apb_icb_cmd_wmask),
    .o10_icb_cmd_lock   (),
    .o10_icb_cmd_excl   (),
    .o10_icb_cmd_size   (),
    .o10_icb_cmd_burst  (),
    .o10_icb_cmd_beat   (),
    
    .o10_icb_rsp_valid  (spi2_apb_icb_rsp_valid),
    .o10_icb_rsp_ready  (spi2_apb_icb_rsp_ready),
    .o10_icb_rsp_err    (spi2_apb_icb_rsp_err  ),
    .o10_icb_rsp_excl_ok(1'b0  ),
    .o10_icb_rsp_rdata  (spi2_apb_icb_rsp_rdata),

  //  * I2C1  
    .o11_icb_enable     (1'b1),

    .o11_icb_cmd_valid  (i2c1_apb_icb_cmd_valid),
    .o11_icb_cmd_ready  (i2c1_apb_icb_cmd_ready),
    .o11_icb_cmd_addr   (i2c1_apb_icb_cmd_addr ),
    .o11_icb_cmd_read   (i2c1_apb_icb_cmd_read ),
    .o11_icb_cmd_wdata  (i2c1_apb_icb_cmd_wdata),
    .o11_icb_cmd_wmask  (i2c1_apb_icb_cmd_wmask),
    .o11_icb_cmd_lock   (),
    .o11_icb_cmd_excl   (),
    .o11_icb_cmd_size   (),
    .o11_icb_cmd_burst  (),
    .o11_icb_cmd_beat   (),
    
    .o11_icb_rsp_valid  (i2c1_apb_icb_rsp_valid),
    .o11_icb_rsp_ready  (i2c1_apb_icb_rsp_ready),
    .o11_icb_rsp_err    (i2c1_apb_icb_rsp_err),
    .o11_icb_rsp_excl_ok(1'b0  ),
    .o11_icb_rsp_rdata  (i2c1_apb_icb_rsp_rdata),     

  //  * SysPer    
    .o12_icb_enable     (1'b1),

    .o12_icb_cmd_valid  (sysper_icb_cmd_valid),
    .o12_icb_cmd_ready  (sysper_icb_cmd_ready),
    .o12_icb_cmd_addr   (sysper_icb_cmd_addr ),
    .o12_icb_cmd_read   (sysper_icb_cmd_read ),
    .o12_icb_cmd_wdata  (sysper_icb_cmd_wdata),
    .o12_icb_cmd_wmask  (sysper_icb_cmd_wmask),
    .o12_icb_cmd_lock   (),
    .o12_icb_cmd_excl   (),
    .o12_icb_cmd_size   (),
    .o12_icb_cmd_burst  (),
    .o12_icb_cmd_beat   (),
    
    .o12_icb_rsp_valid  (sysper_icb_rsp_valid),
    .o12_icb_rsp_ready  (sysper_icb_rsp_ready),
    .o12_icb_rsp_err    (sysper_icb_rsp_err),
    .o12_icb_rsp_excl_ok(1'b0  ),
    .o12_icb_rsp_rdata  (sysper_icb_rsp_rdata),

  //  * GPIOB      
    .o13_icb_enable     (1'b1),

    .o13_icb_cmd_valid  (gpioB_apb_icb_cmd_valid),
    .o13_icb_cmd_ready  (gpioB_apb_icb_cmd_ready),
    .o13_icb_cmd_addr   (gpioB_apb_icb_cmd_addr ),
    .o13_icb_cmd_read   (gpioB_apb_icb_cmd_read ),
    .o13_icb_cmd_wdata  (gpioB_apb_icb_cmd_wdata),
    .o13_icb_cmd_wmask  (gpioB_apb_icb_cmd_wmask),
    .o13_icb_cmd_lock   (),
    .o13_icb_cmd_excl   (),
    .o13_icb_cmd_size   (),
    .o13_icb_cmd_burst  (),
    .o13_icb_cmd_beat   (),
    
    .o13_icb_rsp_valid  (gpioB_apb_icb_rsp_valid),
    .o13_icb_rsp_ready  (gpioB_apb_icb_rsp_ready),
    .o13_icb_rsp_err    (gpioB_apb_icb_rsp_err),
    .o13_icb_rsp_excl_ok(1'b0  ),
    .o13_icb_rsp_rdata  (gpioB_apb_icb_rsp_rdata),

   //  * Example AXI    
    .o14_icb_enable     (1'b1),

    .o14_icb_cmd_valid  (expl_axi_icb_cmd_valid),
    .o14_icb_cmd_ready  (expl_axi_icb_cmd_ready),
    .o14_icb_cmd_addr   (expl_axi_icb_cmd_addr ),
    .o14_icb_cmd_read   (expl_axi_icb_cmd_read ),
    .o14_icb_cmd_wdata  (expl_axi_icb_cmd_wdata),
    .o14_icb_cmd_wmask  (expl_axi_icb_cmd_wmask),
    .o14_icb_cmd_lock   (),
    .o14_icb_cmd_excl   (),
    .o14_icb_cmd_size   (),
    .o14_icb_cmd_burst  (),
    .o14_icb_cmd_beat   (),
    
    .o14_icb_rsp_valid  (expl_axi_icb_rsp_valid),
    .o14_icb_rsp_ready  (expl_axi_icb_rsp_ready),
    .o14_icb_rsp_err    (1'b0 ),
    .o14_icb_rsp_excl_ok(1'b0  ),
    .o14_icb_rsp_rdata  (expl_axi_icb_rsp_rdata),


   //  *      
    .o15_icb_enable     (1'b0),

    .o15_icb_cmd_valid  (),
    .o15_icb_cmd_ready  (1'b0),
    .o15_icb_cmd_addr   (),
    .o15_icb_cmd_read   (),
    .o15_icb_cmd_wdata  (),
    .o15_icb_cmd_wmask  (),
    .o15_icb_cmd_lock   (),
    .o15_icb_cmd_excl   (),
    .o15_icb_cmd_size   (),
    .o15_icb_cmd_burst  (),
    .o15_icb_cmd_beat   (),
    
    .o15_icb_rsp_valid  (1'b0),
    .o15_icb_rsp_ready  (),
    .o15_icb_rsp_err    (1'b0),
    .o15_icb_rsp_excl_ok(1'b0),
    .o15_icb_rsp_rdata  (32'b0),

    .clk           (clk  ),
    .rst_n         (bus_rst_n) 
  );


  //  * QSPI0     
sirv_flash_qspi_top u_sirv_qspi0_top(
    .clk           (clk  ),
    .rst_n         (rst_n),

    .i_icb_cmd_valid (qspi0_icb_cmd_valid),
    .i_icb_cmd_ready (qspi0_icb_cmd_ready),
    .i_icb_cmd_addr  (qspi0_icb_cmd_addr ),
    .i_icb_cmd_read  (qspi0_icb_cmd_read ),
    .i_icb_cmd_wdata (qspi0_icb_cmd_wdata),
    
    .i_icb_rsp_valid (qspi0_icb_rsp_valid),
    .i_icb_rsp_ready (qspi0_icb_rsp_ready),
    .i_icb_rsp_rdata (qspi0_icb_rsp_rdata), 

    .f_icb_cmd_valid (qspi0_ro_icb_cmd_valid),
    .f_icb_cmd_ready (qspi0_ro_icb_cmd_ready),
    .f_icb_cmd_addr  (qspi0_ro_icb_cmd_addr ),
    .f_icb_cmd_read  (qspi0_ro_icb_cmd_read ),
    .f_icb_cmd_wdata (qspi0_ro_icb_cmd_wdata),
    
    .f_icb_rsp_valid (qspi0_ro_icb_rsp_valid),
    .f_icb_rsp_ready (qspi0_ro_icb_rsp_ready),
    .f_icb_rsp_rdata (qspi0_ro_icb_rsp_rdata), 

    .io_port_sck     (qspi0_sck    ), 
    .io_port_dq_0_i  (qspi0_dq_0_i ),
    .io_port_dq_0_o  (qspi0_dq_0_o ),
    .io_port_dq_0_oe (qspi0_dq_0_oe),
    .io_port_dq_1_i  (qspi0_dq_1_i ),
    .io_port_dq_1_o  (qspi0_dq_1_o ),
    .io_port_dq_1_oe (qspi0_dq_1_oe),
    .io_port_dq_2_i  (qspi0_dq_2_i ),
    .io_port_dq_2_o  (qspi0_dq_2_o ),
    .io_port_dq_2_oe (qspi0_dq_2_oe),
    .io_port_dq_3_i  (qspi0_dq_3_i ),
    .io_port_dq_3_o  (qspi0_dq_3_o ),
    .io_port_dq_3_oe (qspi0_dq_3_oe),
    .io_port_cs_0    (qspi0_cs_0   ),
    .io_tl_i_0_0     (qspi0_irq    ) 
);

  assign qspi0_dq_0_i              = io_pads_qspi0_dq_0_i_ival;
  assign qspi0_dq_1_i              = io_pads_qspi0_dq_1_i_ival;
  assign qspi0_dq_2_i              = io_pads_qspi0_dq_2_i_ival;
  assign qspi0_dq_3_i              = io_pads_qspi0_dq_3_i_ival;

  assign io_pads_qspi0_sck_o_oval  = qspi0_sck;
  assign io_pads_qspi0_sck_o_oe    = 1'h1;
  assign io_pads_qspi0_cs_0_o_oval = qspi0_cs_0;
  assign io_pads_qspi0_cs_0_o_oe   = 1'h1;
  assign io_pads_qspi0_dq_0_o_oval = qspi0_dq_0_o;
  assign io_pads_qspi0_dq_0_o_oe   = qspi0_dq_0_oe;
  assign io_pads_qspi0_dq_1_o_oval = qspi0_dq_1_o;
  assign io_pads_qspi0_dq_1_o_oe   = qspi0_dq_1_oe;
  assign io_pads_qspi0_dq_2_o_oval = qspi0_dq_2_o;
  assign io_pads_qspi0_dq_2_o_oe   = qspi0_dq_2_oe;
  assign io_pads_qspi0_dq_3_o_oval = qspi0_dq_3_o;
  assign io_pads_qspi0_dq_3_o_oe   = qspi0_dq_3_oe;


  localparam CMD_PACK_W = 65;
  localparam RSP_PACK_W = 33;

  wire [CMD_PACK_W-1:0] i_aon_icb_cmd_pack;
  wire [RSP_PACK_W-1:0] i_aon_icb_rsp_pack;
  wire [CMD_PACK_W-1:0] aon_icb_cmd_pack;
  wire [RSP_PACK_W-1:0] aon_icb_rsp_pack;
  
  assign i_aon_icb_cmd_pack = {
          i_aon_icb_cmd_addr, 
          i_aon_icb_cmd_read, 
          i_aon_icb_cmd_wdata};

  assign {aon_icb_cmd_addr, 
          aon_icb_cmd_read, 
          aon_icb_cmd_wdata} = aon_icb_cmd_pack;

  sirv_gnrl_cdc_tx   
   # (
     .DW      (CMD_PACK_W),
     .SYNC_DP (`E203_ASYNC_FF_LEVELS) 
   ) u_aon_icb_cdc_tx (
     .o_vld  (aon_icb_cmd_valid ), 
     .o_rdy_a(aon_icb_cmd_ready ), 
     .o_dat  (aon_icb_cmd_pack ),
     .i_vld  (i_aon_icb_cmd_valid ),
     .i_rdy  (i_aon_icb_cmd_ready ),
     .i_dat  (i_aon_icb_cmd_pack ),
   
     .clk    (clk),
     .rst_n  (rst_n)
   );
     

  assign aon_icb_rsp_pack = {
          aon_icb_rsp_err, 
          aon_icb_rsp_rdata};

  assign {i_aon_icb_rsp_err, 
          i_aon_icb_rsp_rdata} = i_aon_icb_rsp_pack;

   sirv_gnrl_cdc_rx   
      # (
     .DW      (RSP_PACK_W),
     .SYNC_DP (`E203_ASYNC_FF_LEVELS) 
   ) u_aon_icb_cdc_rx (
     .i_vld_a(aon_icb_rsp_valid), 
     .i_rdy  (aon_icb_rsp_ready), 
     .i_dat  (aon_icb_rsp_pack),
     .o_vld  (i_aon_icb_rsp_valid),
     .o_rdy  (i_aon_icb_rsp_ready),
     .o_dat  (i_aon_icb_rsp_pack),
   
     .clk    (clk),
     .rst_n  (rst_n)
   );



  // * APB Peripheral:  GPIO A
  wire [`E203_ADDR_SIZE-1:0] gpioA_apb_paddr;
  wire gpioA_apb_pwrite;
  wire gpioA_apb_pselx;
  wire gpioA_apb_penable;
  wire [`E203_XLEN-1:0] gpioA_apb_pwdata;
  wire [`E203_XLEN-1:0] gpioA_apb_prdata;

  wire [32-1:0] gpioA_i_ival;
  wire [32-1:0] gpioA_o_oval;
  wire [32-1:0] gpioA_o_oe;
  wire [32-1:0] gpioA_in_sync;
  wire [32-1:0] gpioA_iof;
   
sirv_gnrl_icb2apb # (
  .AW   (32),
  .DW   (`E203_XLEN) 
) u_gpioA_apb_icb2apb(
    .i_icb_cmd_valid (gpioA_apb_icb_cmd_valid),
    .i_icb_cmd_ready (gpioA_apb_icb_cmd_ready),
    .i_icb_cmd_addr  (gpioA_apb_icb_cmd_addr ),
    .i_icb_cmd_read  (gpioA_apb_icb_cmd_read ),
    .i_icb_cmd_wdata (gpioA_apb_icb_cmd_wdata),
    .i_icb_cmd_wmask (gpioA_apb_icb_cmd_wmask),
    .i_icb_cmd_size  (),
    
    .i_icb_rsp_valid (gpioA_apb_icb_rsp_valid),
    .i_icb_rsp_ready (gpioA_apb_icb_rsp_ready),
    .i_icb_rsp_rdata (gpioA_apb_icb_rsp_rdata),
    .i_icb_rsp_err   (gpioA_apb_icb_rsp_err),

    .apb_paddr     (gpioA_apb_paddr  ),
    .apb_pwrite    (gpioA_apb_pwrite ),
    .apb_pselx     (gpioA_apb_pselx  ),
    .apb_penable   (gpioA_apb_penable), 
    .apb_pwdata    (gpioA_apb_pwdata ),
    .apb_prdata    (gpioA_apb_prdata ),

    .clk           (clk  ),
    .rst_n         (bus_rst_n) 
  );


apb_gpio # (
  .APB_ADDR_WIDTH (32)
) u_perips_apb_gpioA (
    .HCLK           (clk),
    .HRESETn        (rst_n),
    .PADDR          (gpioA_apb_paddr),
    .PWDATA         (gpioA_apb_pwdata),
    .PWRITE         (gpioA_apb_pwrite),
    .PSEL           (gpioA_apb_pselx),
    .PENABLE        (gpioA_apb_penable),
    .PRDATA         (gpioA_apb_prdata),
    .PREADY         (),
    .PSLVERR        (),

    .gpio_in        (gpioA_i_ival),
    .gpio_in_sync   (gpioA_in_sync),
    .gpio_out       (gpioA_o_oval),
    .gpio_dir       (gpioA_o_oe),
    .gpio_padcfg    (),
    .gpio_iof       (gpioA_iof),
    .interrupt      (gpioA_irq)
);


  // * APB Peripheral:  GPIO B
  wire [`E203_ADDR_SIZE-1:0] gpioB_apb_paddr;
  wire gpioB_apb_pwrite;
  wire gpioB_apb_pselx;
  wire gpioB_apb_penable;
  wire [`E203_XLEN-1:0] gpioB_apb_pwdata;
  wire [`E203_XLEN-1:0] gpioB_apb_prdata;

  wire [32-1:0] gpioB_i_ival;
  wire [32-1:0] gpioB_o_oval;
  wire [32-1:0] gpioB_o_oe;
  wire [32-1:0] gpioB_in_sync;
  wire [32-1:0] gpioB_iof;
   
sirv_gnrl_icb2apb # (
  .AW   (32),
  .DW   (`E203_XLEN) 
) u_gpioB_apb_icb2apb(
    .i_icb_cmd_valid (gpioB_apb_icb_cmd_valid),
    .i_icb_cmd_ready (gpioB_apb_icb_cmd_ready),
    .i_icb_cmd_addr  (gpioB_apb_icb_cmd_addr ),
    .i_icb_cmd_read  (gpioB_apb_icb_cmd_read ),
    .i_icb_cmd_wdata (gpioB_apb_icb_cmd_wdata),
    .i_icb_cmd_wmask (gpioB_apb_icb_cmd_wmask),
    .i_icb_cmd_size  (),
    
    .i_icb_rsp_valid (gpioB_apb_icb_rsp_valid),
    .i_icb_rsp_ready (gpioB_apb_icb_rsp_ready),
    .i_icb_rsp_rdata (gpioB_apb_icb_rsp_rdata),
    .i_icb_rsp_err   (gpioB_apb_icb_rsp_err),

    .apb_paddr     (gpioB_apb_paddr  ),
    .apb_pwrite    (gpioB_apb_pwrite ),
    .apb_pselx     (gpioB_apb_pselx  ),
    .apb_penable   (gpioB_apb_penable), 
    .apb_pwdata    (gpioB_apb_pwdata ),
    .apb_prdata    (gpioB_apb_prdata ),

    .clk           (clk  ),
    .rst_n         (bus_rst_n) 
  );


apb_gpio # (
  .APB_ADDR_WIDTH (32)
) u_perips_apb_gpioB (
    .HCLK           (clk),
    .HRESETn        (rst_n),
    .PADDR          (gpioB_apb_paddr),
    .PWDATA         (gpioB_apb_pwdata),
    .PWRITE         (gpioB_apb_pwrite),
    .PSEL           (gpioB_apb_pselx),
    .PENABLE        (gpioB_apb_penable),
    .PRDATA         (gpioB_apb_prdata),
    .PREADY         (),
    .PSLVERR        (),

    .gpio_in        (gpioB_i_ival),
    .gpio_in_sync   (gpioB_in_sync),
    .gpio_out       (gpioB_o_oval),
    .gpio_dir       (gpioB_o_oe),
    .gpio_padcfg    (),
    .gpio_iof       (gpioB_iof),
    .interrupt      (gpioB_irq)
);


  // * APB Peripheral:  UART0
  wire [`E203_ADDR_SIZE-1:0] uart0_apb_paddr;
  wire uart0_apb_pwrite;
  wire uart0_apb_pselx;
  wire uart0_apb_penable;
  wire [`E203_XLEN-1:0] uart0_apb_pwdata;
  wire [`E203_XLEN-1:0] uart0_apb_prdata;

  wire  uart0_txd;
  wire  uart0_rxd;
   
sirv_gnrl_icb2apb # (
  .AW   (32),
  .DW   (`E203_XLEN) 
) u_uart0_apb_icb2apb(
    .i_icb_cmd_valid (uart0_apb_icb_cmd_valid),
    .i_icb_cmd_ready (uart0_apb_icb_cmd_ready),
    .i_icb_cmd_addr  (uart0_apb_icb_cmd_addr ),
    .i_icb_cmd_read  (uart0_apb_icb_cmd_read ),
    .i_icb_cmd_wdata (uart0_apb_icb_cmd_wdata),
    .i_icb_cmd_wmask (uart0_apb_icb_cmd_wmask),
    .i_icb_cmd_size  (),
    
    .i_icb_rsp_valid (uart0_apb_icb_rsp_valid),
    .i_icb_rsp_ready (uart0_apb_icb_rsp_ready),
    .i_icb_rsp_rdata (uart0_apb_icb_rsp_rdata),
    .i_icb_rsp_err   (uart0_apb_icb_rsp_err),

    .apb_paddr     (uart0_apb_paddr  ),
    .apb_pwrite    (uart0_apb_pwrite ),
    .apb_pselx     (uart0_apb_pselx  ),
    .apb_penable   (uart0_apb_penable), 
    .apb_pwdata    (uart0_apb_pwdata ),
    .apb_prdata    (uart0_apb_prdata ),

    .clk           (clk  ),
    .rst_n         (bus_rst_n) 
  );


apb_uart_sv # (
  .APB_ADDR_WIDTH (32) 
) u_perips_apb_uart0 (
    .CLK            (clk),
    .RSTN           (rst_n),
    .PADDR          (uart0_apb_paddr  ),
    .PWDATA         (uart0_apb_pwdata ),
    .PWRITE         (uart0_apb_pwrite ),
    .PSEL           (uart0_apb_pselx  ),
    .PENABLE        (uart0_apb_penable),
    .PRDATA         (uart0_apb_prdata ),
    .PREADY         (),
    .PSLVERR        (),

    .rx_i           (uart0_rxd),     
    .tx_o           (uart0_txd),      

    .event_o        (uart0_irq)
);

  wire io_pads_uart0_rxd_i_ival;
  wire io_pads_uart0_rxd_o_oval;
  wire io_pads_uart0_rxd_o_oe;
  wire io_pads_uart0_txd_i_ival;
  wire io_pads_uart0_txd_o_oval;
  wire io_pads_uart0_txd_o_oe;

  assign uart0_rxd                = io_pads_uart0_rxd_i_ival;
  assign io_pads_uart0_rxd_o_oval = 1'h0;
  assign io_pads_uart0_rxd_o_oe   = 1'h0;

  assign io_pads_uart0_txd_o_oval = uart0_txd;
  assign io_pads_uart0_txd_o_oe   = 1'h1;

  // * APB Peripheral:  UART1
  wire [`E203_ADDR_SIZE-1:0] uart1_apb_paddr;
  wire uart1_apb_pwrite;
  wire uart1_apb_pselx;
  wire uart1_apb_penable;
  wire [`E203_XLEN-1:0] uart1_apb_pwdata;
  wire [`E203_XLEN-1:0] uart1_apb_prdata;

  wire  uart1_txd;
  wire  uart1_rxd;
   
sirv_gnrl_icb2apb # (
  .AW   (32),
  .DW   (`E203_XLEN) 
) u_uart1_apb_icb2apb(
    .i_icb_cmd_valid (uart1_apb_icb_cmd_valid),
    .i_icb_cmd_ready (uart1_apb_icb_cmd_ready),
    .i_icb_cmd_addr  (uart1_apb_icb_cmd_addr ),
    .i_icb_cmd_read  (uart1_apb_icb_cmd_read ),
    .i_icb_cmd_wdata (uart1_apb_icb_cmd_wdata),
    .i_icb_cmd_wmask (uart1_apb_icb_cmd_wmask),
    .i_icb_cmd_size  (),
    
    .i_icb_rsp_valid (uart1_apb_icb_rsp_valid),
    .i_icb_rsp_ready (uart1_apb_icb_rsp_ready),
    .i_icb_rsp_rdata (uart1_apb_icb_rsp_rdata),
    .i_icb_rsp_err   (uart1_apb_icb_rsp_err),

    .apb_paddr     (uart1_apb_paddr  ),
    .apb_pwrite    (uart1_apb_pwrite ),
    .apb_pselx     (uart1_apb_pselx  ),
    .apb_penable   (uart1_apb_penable), 
    .apb_pwdata    (uart1_apb_pwdata ),
    .apb_prdata    (uart1_apb_prdata ),

    .clk           (clk  ),
    .rst_n         (bus_rst_n) 
  );


apb_uart_sv # (
  .APB_ADDR_WIDTH (32) 
) u_perips_apb_uart1 (
    .CLK            (clk),
    .RSTN           (rst_n),
    .PADDR          (uart1_apb_paddr  ),
    .PWDATA         (uart1_apb_pwdata ),
    .PWRITE         (uart1_apb_pwrite ),
    .PSEL           (uart1_apb_pselx  ),
    .PENABLE        (uart1_apb_penable),
    .PRDATA         (uart1_apb_prdata ),
    .PREADY         (),
    .PSLVERR        (),

    .rx_i           (uart1_rxd),     
    .tx_o           (uart1_txd),      

    .event_o        (uart1_irq)
);

  wire io_pads_uart1_rxd_i_ival;
  wire io_pads_uart1_rxd_o_oval;
  wire io_pads_uart1_rxd_o_oe;
  wire io_pads_uart1_txd_i_ival;
  wire io_pads_uart1_txd_o_oval;
  wire io_pads_uart1_txd_o_oe;

  assign uart1_rxd                = io_pads_uart1_rxd_i_ival;
  assign io_pads_uart1_rxd_o_oval = 1'h0;
  assign io_pads_uart1_rxd_o_oe   = 1'h0;

  assign io_pads_uart1_txd_o_oval = uart1_txd;
  assign io_pads_uart1_txd_o_oe   = 1'h1;


  // * APB Peripheral:  UART2
  wire [`E203_ADDR_SIZE-1:0] uart2_apb_paddr;
  wire uart2_apb_pwrite;
  wire uart2_apb_pselx;
  wire uart2_apb_penable;
  wire [`E203_XLEN-1:0] uart2_apb_pwdata;
  wire [`E203_XLEN-1:0] uart2_apb_prdata;

  wire  uart2_txd;
  wire  uart2_rxd;
   
sirv_gnrl_icb2apb # (
  .AW   (32),
  .DW   (`E203_XLEN) 
) u_uart2_apb_icb2apb(
    .i_icb_cmd_valid (uart2_apb_icb_cmd_valid),
    .i_icb_cmd_ready (uart2_apb_icb_cmd_ready),
    .i_icb_cmd_addr  (uart2_apb_icb_cmd_addr ),
    .i_icb_cmd_read  (uart2_apb_icb_cmd_read ),
    .i_icb_cmd_wdata (uart2_apb_icb_cmd_wdata),
    .i_icb_cmd_wmask (uart2_apb_icb_cmd_wmask),
    .i_icb_cmd_size  (),
    
    .i_icb_rsp_valid (uart2_apb_icb_rsp_valid),
    .i_icb_rsp_ready (uart2_apb_icb_rsp_ready),
    .i_icb_rsp_rdata (uart2_apb_icb_rsp_rdata),
    .i_icb_rsp_err   (uart2_apb_icb_rsp_err),

    .apb_paddr     (uart2_apb_paddr  ),
    .apb_pwrite    (uart2_apb_pwrite ),
    .apb_pselx     (uart2_apb_pselx  ),
    .apb_penable   (uart2_apb_penable), 
    .apb_pwdata    (uart2_apb_pwdata ),
    .apb_prdata    (uart2_apb_prdata ),

    .clk           (clk  ),
    .rst_n         (bus_rst_n) 
  );


apb_uart_sv # (
  .APB_ADDR_WIDTH (32) 
) u_perips_apb_uart2 (
    .CLK            (clk),
    .RSTN           (rst_n),
    .PADDR          (uart2_apb_paddr  ),
    .PWDATA         (uart2_apb_pwdata ),
    .PWRITE         (uart2_apb_pwrite ),
    .PSEL           (uart2_apb_pselx  ),
    .PENABLE        (uart2_apb_penable),
    .PRDATA         (uart2_apb_prdata ),
    .PREADY         (),
    .PSLVERR        (),

    .rx_i           (uart2_rxd),     
    .tx_o           (uart2_txd),      

    .event_o        (uart2_irq)
);

  wire io_pads_uart2_rxd_i_ival;
  wire io_pads_uart2_rxd_o_oval;
  wire io_pads_uart2_rxd_o_oe;
  wire io_pads_uart2_txd_i_ival;
  wire io_pads_uart2_txd_o_oval;
  wire io_pads_uart2_txd_o_oe;

  assign uart2_rxd                = io_pads_uart2_rxd_i_ival;
  assign io_pads_uart2_rxd_o_oval = 1'h0;
  assign io_pads_uart2_rxd_o_oe   = 1'h0;

  assign io_pads_uart2_txd_o_oval = uart2_txd;
  assign io_pads_uart2_txd_o_oe   = 1'h1;


  // * APB Peripheral:  (Q)SPI1
  wire [`E203_ADDR_SIZE-1:0] spi1_apb_paddr;
  wire spi1_apb_pwrite;
  wire spi1_apb_pselx;
  wire spi1_apb_penable;
  wire [`E203_XLEN-1:0] spi1_apb_pwdata;
  wire [`E203_XLEN-1:0] spi1_apb_prdata;
  
  wire qspi1_sck ;
  wire qspi1_cs_0;
  wire qspi1_dq_0_o;
  wire qspi1_dq_1_o;
  wire qspi1_dq_2_o;
  wire qspi1_dq_3_o;
  wire qspi1_dq_0_oe;
  wire qspi1_dq_1_oe;
  wire qspi1_dq_2_oe;
  wire qspi1_dq_3_oe;
  wire qspi1_dq_0_i;
  wire qspi1_dq_1_i;
  wire qspi1_dq_2_i;
  wire qspi1_dq_3_i;


sirv_gnrl_icb2apb # (
  .AW   (32),
  .DW   (`E203_XLEN) 
) u_spi1_apb_icb2apb(
    .i_icb_cmd_valid (spi1_apb_icb_cmd_valid),
    .i_icb_cmd_ready (spi1_apb_icb_cmd_ready),
    .i_icb_cmd_addr  (spi1_apb_icb_cmd_addr ),
    .i_icb_cmd_read  (spi1_apb_icb_cmd_read ),
    .i_icb_cmd_wdata (spi1_apb_icb_cmd_wdata),
    .i_icb_cmd_wmask (spi1_apb_icb_cmd_wmask),
    .i_icb_cmd_size  (),
    
    .i_icb_rsp_valid (spi1_apb_icb_rsp_valid),
    .i_icb_rsp_ready (spi1_apb_icb_rsp_ready),
    .i_icb_rsp_rdata (spi1_apb_icb_rsp_rdata),
    .i_icb_rsp_err   (spi1_apb_icb_rsp_err),

    .apb_paddr     (spi1_apb_paddr  ),
    .apb_pwrite    (spi1_apb_pwrite ),
    .apb_pselx     (spi1_apb_pselx  ),
    .apb_penable   (spi1_apb_penable), 
    .apb_pwdata    (spi1_apb_pwdata ),
    .apb_prdata    (spi1_apb_prdata ),

    .clk           (clk  ),
    .rst_n         (bus_rst_n) 
  );


apb_spi_master #(
  .APB_ADDR_WIDTH (32)
) u_perips_apb_spi1 (
    .HCLK          (clk),
    .HRESETn       (rst_n),
    .PADDR         (spi1_apb_paddr),
    .PWDATA        (spi1_apb_pwdata),
    .PWRITE        (spi1_apb_pwrite),
    .PSEL          (spi1_apb_pselx),
    .PENABLE       (spi1_apb_penable),
    .PRDATA        (spi1_apb_prdata),
    .PREADY        (),
    .PSLVERR       (),

    .events_o      (qspi1_irq),

    .spi_clk       (qspi1_sck),
    .spi_csn0      (qspi1_cs_0),
    .spi_csn1      (),
    .spi_csn2      (),
    .spi_csn3      (),
    .spi_sdo0      (qspi1_dq_0_o),
    .spi_sdo1      (qspi1_dq_1_o),
    .spi_sdo2      (qspi1_dq_2_o),
    .spi_sdo3      (qspi1_dq_3_o),
    .spi_oe0       (qspi1_dq_0_oe),
    .spi_oe1       (qspi1_dq_1_oe),
    .spi_oe2       (qspi1_dq_2_oe),
    .spi_oe3       (qspi1_dq_3_oe),
    .spi_sdi0      (qspi1_dq_0_i),
    .spi_sdi1      (qspi1_dq_1_i),
    .spi_sdi2      (qspi1_dq_2_i),
    .spi_sdi3      (qspi1_dq_3_i)
);


  wire io_pads_qspi1_sck_i_ival ;
  wire io_pads_qspi1_sck_o_oval ;
  wire io_pads_qspi1_sck_o_oe   ;
  wire io_pads_qspi1_cs_0_i_ival;
  wire io_pads_qspi1_cs_0_o_oval; 
  wire io_pads_qspi1_cs_0_o_oe  ;
  wire io_pads_qspi1_dq_0_i_ival;
  wire io_pads_qspi1_dq_0_o_oval;
  wire io_pads_qspi1_dq_0_o_oe  ;
  wire io_pads_qspi1_dq_1_i_ival;
  wire io_pads_qspi1_dq_1_o_oval;
  wire io_pads_qspi1_dq_1_o_oe  ;
  wire io_pads_qspi1_dq_2_i_ival;
  wire io_pads_qspi1_dq_2_o_oval;
  wire io_pads_qspi1_dq_2_o_oe  ;
  wire io_pads_qspi1_dq_3_i_ival;
  wire io_pads_qspi1_dq_3_o_oval;
  wire io_pads_qspi1_dq_3_o_oe  ;


  assign qspi1_dq_0_i              = io_pads_qspi1_dq_0_i_ival;
  assign qspi1_dq_1_i              = io_pads_qspi1_dq_1_i_ival;
  assign qspi1_dq_2_i              = io_pads_qspi1_dq_2_i_ival;
  assign qspi1_dq_3_i              = io_pads_qspi1_dq_3_i_ival;

  assign io_pads_qspi1_sck_o_oval  = qspi1_sck;
  assign io_pads_qspi1_sck_o_oe    = 1'h1;
  assign io_pads_qspi1_cs_0_o_oval = qspi1_cs_0;
  assign io_pads_qspi1_cs_0_o_oe   = 1'h1;
  assign io_pads_qspi1_dq_0_o_oval = qspi1_dq_0_o;
  assign io_pads_qspi1_dq_0_o_oe   = qspi1_dq_0_oe;
  assign io_pads_qspi1_dq_1_o_oval = qspi1_dq_1_o;
  assign io_pads_qspi1_dq_1_o_oe   = qspi1_dq_1_oe;
  assign io_pads_qspi1_dq_2_o_oval = qspi1_dq_2_o;
  assign io_pads_qspi1_dq_2_o_oe   = qspi1_dq_2_oe;
  assign io_pads_qspi1_dq_3_o_oval = qspi1_dq_3_o;
  assign io_pads_qspi1_dq_3_o_oe   = qspi1_dq_3_oe;


  // * APB Peripheral:  (Q)SPI2
  wire [`E203_ADDR_SIZE-1:0] spi2_apb_paddr;
  wire spi2_apb_pwrite;
  wire spi2_apb_pselx;
  wire spi2_apb_penable;
  wire [`E203_XLEN-1:0] spi2_apb_pwdata;
  wire [`E203_XLEN-1:0] spi2_apb_prdata;
  
  wire qspi2_sck ;
  wire qspi2_cs_0;
  wire qspi2_dq_0_o;
  wire qspi2_dq_1_o;
  wire qspi2_dq_2_o;
  wire qspi2_dq_3_o;
  wire qspi2_dq_0_oe;
  wire qspi2_dq_1_oe;
  wire qspi2_dq_2_oe;
  wire qspi2_dq_3_oe;
  wire qspi2_dq_0_i;
  wire qspi2_dq_1_i;
  wire qspi2_dq_2_i;
  wire qspi2_dq_3_i;


sirv_gnrl_icb2apb # (
  .AW   (32),
  .DW   (`E203_XLEN) 
) u_spi2_apb_icb2apb(
    .i_icb_cmd_valid (spi2_apb_icb_cmd_valid),
    .i_icb_cmd_ready (spi2_apb_icb_cmd_ready),
    .i_icb_cmd_addr  (spi2_apb_icb_cmd_addr ),
    .i_icb_cmd_read  (spi2_apb_icb_cmd_read ),
    .i_icb_cmd_wdata (spi2_apb_icb_cmd_wdata),
    .i_icb_cmd_wmask (spi2_apb_icb_cmd_wmask),
    .i_icb_cmd_size  (),
    
    .i_icb_rsp_valid (spi2_apb_icb_rsp_valid),
    .i_icb_rsp_ready (spi2_apb_icb_rsp_ready),
    .i_icb_rsp_rdata (spi2_apb_icb_rsp_rdata),
    .i_icb_rsp_err   (spi2_apb_icb_rsp_err),

    .apb_paddr     (spi2_apb_paddr  ),
    .apb_pwrite    (spi2_apb_pwrite ),
    .apb_pselx     (spi2_apb_pselx  ),
    .apb_penable   (spi2_apb_penable), 
    .apb_pwdata    (spi2_apb_pwdata ),
    .apb_prdata    (spi2_apb_prdata ),

    .clk           (clk  ),
    .rst_n         (bus_rst_n) 
  );


apb_spi_master #(
  .APB_ADDR_WIDTH (32)
) u_perips_apb_spi2 (
    .HCLK          (clk),
    .HRESETn       (rst_n),
    .PADDR         (spi2_apb_paddr),
    .PWDATA        (spi2_apb_pwdata),
    .PWRITE        (spi2_apb_pwrite),
    .PSEL          (spi2_apb_pselx),
    .PENABLE       (spi2_apb_penable),
    .PRDATA        (spi2_apb_prdata),
    .PREADY        (),
    .PSLVERR       (),

    .events_o      (qspi2_irq),

    .spi_clk       (qspi2_sck),
    .spi_csn0      (qspi2_cs_0),
    .spi_csn1      (),
    .spi_csn2      (),
    .spi_csn3      (),
    .spi_sdo0      (qspi2_dq_0_o),
    .spi_sdo1      (qspi2_dq_1_o),
    .spi_sdo2      (qspi2_dq_2_o),
    .spi_sdo3      (qspi2_dq_3_o),
    .spi_oe0       (qspi2_dq_0_oe),
    .spi_oe1       (qspi2_dq_1_oe),
    .spi_oe2       (qspi2_dq_2_oe),
    .spi_oe3       (qspi2_dq_3_oe),
    .spi_sdi0      (qspi2_dq_0_i),
    .spi_sdi1      (qspi2_dq_1_i),
    .spi_sdi2      (qspi2_dq_2_i),
    .spi_sdi3      (qspi2_dq_3_i)
);


  wire io_pads_qspi2_sck_i_ival ;
  wire io_pads_qspi2_sck_o_oval ;
  wire io_pads_qspi2_sck_o_oe   ;
  wire io_pads_qspi2_cs_0_i_ival;
  wire io_pads_qspi2_cs_0_o_oval; 
  wire io_pads_qspi2_cs_0_o_oe  ;
  wire io_pads_qspi2_dq_0_i_ival;
  wire io_pads_qspi2_dq_0_o_oval;
  wire io_pads_qspi2_dq_0_o_oe  ;
  wire io_pads_qspi2_dq_1_i_ival;
  wire io_pads_qspi2_dq_1_o_oval;
  wire io_pads_qspi2_dq_1_o_oe  ;
  wire io_pads_qspi2_dq_2_i_ival;
  wire io_pads_qspi2_dq_2_o_oval;
  wire io_pads_qspi2_dq_2_o_oe  ;
  wire io_pads_qspi2_dq_3_i_ival;
  wire io_pads_qspi2_dq_3_o_oval;
  wire io_pads_qspi2_dq_3_o_oe  ;


  assign qspi2_dq_0_i              = io_pads_qspi2_dq_0_i_ival;
  assign qspi2_dq_1_i              = io_pads_qspi2_dq_1_i_ival;
  assign qspi2_dq_2_i              = io_pads_qspi2_dq_2_i_ival;
  assign qspi2_dq_3_i              = io_pads_qspi2_dq_3_i_ival;

  assign io_pads_qspi2_sck_o_oval  = qspi2_sck;
  assign io_pads_qspi2_sck_o_oe    = 1'h1;
  assign io_pads_qspi2_cs_0_o_oval = qspi2_cs_0;
  assign io_pads_qspi2_cs_0_o_oe   = 1'h1;
  assign io_pads_qspi2_dq_0_o_oval = qspi2_dq_0_o;
  assign io_pads_qspi2_dq_0_o_oe   = qspi2_dq_0_oe;
  assign io_pads_qspi2_dq_1_o_oval = qspi2_dq_1_o;
  assign io_pads_qspi2_dq_1_o_oe   = qspi2_dq_1_oe;
  assign io_pads_qspi2_dq_2_o_oval = qspi2_dq_2_o;
  assign io_pads_qspi2_dq_2_o_oe   = qspi2_dq_2_oe;
  assign io_pads_qspi2_dq_3_o_oval = qspi2_dq_3_o;
  assign io_pads_qspi2_dq_3_o_oe   = qspi2_dq_3_oe;

  // * APB Peripheral:  I2C0
  wire [`E203_ADDR_SIZE-1:0] i2c0_apb_paddr;
  wire i2c0_apb_pwrite;
  wire i2c0_apb_pselx;
  wire i2c0_apb_penable;
  wire [`E203_XLEN-1:0] i2c0_apb_pwdata;
  wire [`E203_XLEN-1:0] i2c0_apb_prdata;
   
sirv_gnrl_icb2apb # (
  .AW   (32),
  .DW   (`E203_XLEN) 
) u_i2c0_apb_icb2apb(
    .i_icb_cmd_valid (i2c0_apb_icb_cmd_valid),
    .i_icb_cmd_ready (i2c0_apb_icb_cmd_ready),
    .i_icb_cmd_addr  (i2c0_apb_icb_cmd_addr ),
    .i_icb_cmd_read  (i2c0_apb_icb_cmd_read ),
    .i_icb_cmd_wdata (i2c0_apb_icb_cmd_wdata),
    .i_icb_cmd_wmask (i2c0_apb_icb_cmd_wmask),
    .i_icb_cmd_size  (),
    
    .i_icb_rsp_valid (i2c0_apb_icb_rsp_valid),
    .i_icb_rsp_ready (i2c0_apb_icb_rsp_ready),
    .i_icb_rsp_rdata (i2c0_apb_icb_rsp_rdata),
    .i_icb_rsp_err   (i2c0_apb_icb_rsp_err),

    .apb_paddr     (i2c0_apb_paddr  ),
    .apb_pwrite    (i2c0_apb_pwrite ),
    .apb_pselx     (i2c0_apb_pselx  ),
    .apb_penable   (i2c0_apb_penable), 
    .apb_pwdata    (i2c0_apb_pwdata ),
    .apb_prdata    (i2c0_apb_prdata ),

    .clk           (clk  ),
    .rst_n         (bus_rst_n) 
  );

  wire io_pads_i2c0_scl_o_oen ;
  wire io_pads_i2c0_sda_o_oen ;
  wire io_pads_i2c0_sda_o_oval;
  wire io_pads_i2c0_scl_o_oval;
  wire io_pads_i2c0_scl_i_ival;
  wire io_pads_i2c0_sda_i_ival;

apb_i2c #(
  .APB_ADDR_WIDTH (32) 
) u_perips_apb_i2c0 (
    .HCLK          (clk),
    .HRESETn       (rst_n),
    .PADDR         (i2c0_apb_paddr),
    .PWDATA        (i2c0_apb_pwdata),
    .PWRITE        (i2c0_apb_pwrite),
    .PSEL          (i2c0_apb_pselx),
    .PENABLE       (i2c0_apb_penable),
    .PRDATA        (i2c0_apb_prdata),
    .PREADY        (),
    .PSLVERR       (),

    .interrupt_o   (i2c0_mst_irq),
    .scl_pad_i     (io_pads_i2c0_scl_i_ival),
    .scl_pad_o     (io_pads_i2c0_scl_o_oval),
    .scl_padoen_o  (io_pads_i2c0_scl_o_oen),
    .sda_pad_i     (io_pads_i2c0_sda_i_ival),
    .sda_pad_o     (io_pads_i2c0_sda_o_oval),
    .sda_padoen_o  (io_pads_i2c0_sda_o_oen)
);


  // * APB Peripheral:  I2C1
  wire [`E203_ADDR_SIZE-1:0] i2c1_apb_paddr;
  wire i2c1_apb_pwrite;
  wire i2c1_apb_pselx;
  wire i2c1_apb_penable;
  wire [`E203_XLEN-1:0] i2c1_apb_pwdata;
  wire [`E203_XLEN-1:0] i2c1_apb_prdata;
   
sirv_gnrl_icb2apb # (
  .AW   (32),
  .DW   (`E203_XLEN) 
) u_i2c1_apb_icb2apb(
    .i_icb_cmd_valid (i2c1_apb_icb_cmd_valid),
    .i_icb_cmd_ready (i2c1_apb_icb_cmd_ready),
    .i_icb_cmd_addr  (i2c1_apb_icb_cmd_addr ),
    .i_icb_cmd_read  (i2c1_apb_icb_cmd_read ),
    .i_icb_cmd_wdata (i2c1_apb_icb_cmd_wdata),
    .i_icb_cmd_wmask (i2c1_apb_icb_cmd_wmask),
    .i_icb_cmd_size  (),
    
    .i_icb_rsp_valid (i2c1_apb_icb_rsp_valid),
    .i_icb_rsp_ready (i2c1_apb_icb_rsp_ready),
    .i_icb_rsp_rdata (i2c1_apb_icb_rsp_rdata),
    .i_icb_rsp_err   (i2c1_apb_icb_rsp_err),

    .apb_paddr     (i2c1_apb_paddr  ),
    .apb_pwrite    (i2c1_apb_pwrite ),
    .apb_pselx     (i2c1_apb_pselx  ),
    .apb_penable   (i2c1_apb_penable), 
    .apb_pwdata    (i2c1_apb_pwdata ),
    .apb_prdata    (i2c1_apb_prdata ),

    .clk           (clk  ),
    .rst_n         (bus_rst_n) 
  );

  wire io_pads_i2c1_scl_o_oen ;
  wire io_pads_i2c1_sda_o_oen ;
  wire io_pads_i2c1_sda_o_oval;
  wire io_pads_i2c1_scl_o_oval;
  wire io_pads_i2c1_scl_i_ival;
  wire io_pads_i2c1_sda_i_ival;

apb_i2c #(
  .APB_ADDR_WIDTH (32) 
) u_perips_apb_i2c1 (
    .HCLK          (clk),
    .HRESETn       (rst_n),
    .PADDR         (i2c1_apb_paddr),
    .PWDATA        (i2c1_apb_pwdata),
    .PWRITE        (i2c1_apb_pwrite),
    .PSEL          (i2c1_apb_pselx),
    .PENABLE       (i2c1_apb_penable),
    .PRDATA        (i2c1_apb_prdata),
    .PREADY        (),
    .PSLVERR       (),

    .interrupt_o   (i2c1_mst_irq),
    .scl_pad_i     (io_pads_i2c1_scl_i_ival),
    .scl_pad_o     (io_pads_i2c1_scl_o_oval),
    .scl_padoen_o  (io_pads_i2c1_scl_o_oen),
    .sda_pad_i     (io_pads_i2c1_sda_i_ival),
    .sda_pad_o     (io_pads_i2c1_sda_o_oval),
    .sda_padoen_o  (io_pads_i2c1_sda_o_oen)
);


  // * APB Peripheral:  PWM 
  wire [`E203_ADDR_SIZE-1:0] pwm_apb_paddr;
  wire pwm_apb_pwrite;
  wire pwm_apb_pselx;
  wire pwm_apb_penable;
  wire [`E203_XLEN-1:0] pwm_apb_pwdata;
  wire [`E203_XLEN-1:0] pwm_apb_prdata;


  wire [3:0] pwm_timer0_o;
  wire [3:0] pwm_timer1_o;
  wire [3:0] pwm_timer2_o;
  wire [3:0] pwm_timer3_o;
   
sirv_gnrl_icb2apb # (
  .AW   (32),
  .DW   (`E203_XLEN) 
) u_pwm_apb_icb2apb(
    .i_icb_cmd_valid (pwm_apb_icb_cmd_valid),
    .i_icb_cmd_ready (pwm_apb_icb_cmd_ready),
    .i_icb_cmd_addr  (pwm_apb_icb_cmd_addr ),
    .i_icb_cmd_read  (pwm_apb_icb_cmd_read ),
    .i_icb_cmd_wdata (pwm_apb_icb_cmd_wdata),
    .i_icb_cmd_wmask (pwm_apb_icb_cmd_wmask),
    .i_icb_cmd_size  (),
    
    .i_icb_rsp_valid (pwm_apb_icb_rsp_valid),
    .i_icb_rsp_ready (pwm_apb_icb_rsp_ready),
    .i_icb_rsp_rdata (pwm_apb_icb_rsp_rdata),
    .i_icb_rsp_err   (pwm_apb_icb_rsp_err),

    .apb_paddr     (pwm_apb_paddr  ),
    .apb_pwrite    (pwm_apb_pwrite ),
    .apb_pselx     (pwm_apb_pselx  ),
    .apb_penable   (pwm_apb_penable), 
    .apb_pwdata    (pwm_apb_pwdata ),
    .apb_prdata    (pwm_apb_prdata ),

    .clk           (clk  ),
    .rst_n         (bus_rst_n) 
  );



apb_adv_timer #(
  .APB_ADDR_WIDTH (32)
) u_perips_apb_pwm (
    .HCLK          (clk),
    .HRESETn       (rst_n),
    .PADDR         (pwm_apb_paddr),
    .PWDATA        (pwm_apb_pwdata),
    .PWRITE        (pwm_apb_pwrite),
    .PSEL          (pwm_apb_pselx),
    .PENABLE       (pwm_apb_penable),
    .PRDATA        (pwm_apb_prdata),
    .PREADY        (),
    .PSLVERR       (),

    .dft_cg_enable_i (1'b0),
    .low_speed_clk_i (ls_clk),
    .ext_sig_i       (gpioA_in_sync),
    
    .events_o        ({pwm_irq_3,pwm_irq_2,pwm_irq_1,pwm_irq_0}),	
   
    .ch_0_o          (pwm_timer0_o),	
    .ch_1_o          (pwm_timer1_o),	
    .ch_2_o          (pwm_timer2_o),	
    .ch_3_o          (pwm_timer3_o)
);


  wire io_pads_pwm0_ch0_i_ival;
  wire io_pads_pwm0_ch0_o_oval;
  wire io_pads_pwm0_ch0_o_oe  ;
  wire io_pads_pwm0_ch1_i_ival;
  wire io_pads_pwm0_ch1_o_oval;
  wire io_pads_pwm0_ch1_o_oe  ;
  wire io_pads_pwm0_ch2_i_ival;
  wire io_pads_pwm0_ch2_o_oval;
  wire io_pads_pwm0_ch2_o_oe  ;
  wire io_pads_pwm0_ch3_i_ival;
  wire io_pads_pwm0_ch3_o_oval;
  wire io_pads_pwm0_ch3_o_oe  ;

  wire io_pads_pwm1_ch0_i_ival;
  wire io_pads_pwm1_ch0_o_oval;
  wire io_pads_pwm1_ch0_o_oe  ;
  wire io_pads_pwm1_ch1_i_ival;
  wire io_pads_pwm1_ch1_o_oval;
  wire io_pads_pwm1_ch1_o_oe  ;
  wire io_pads_pwm1_ch2_i_ival;
  wire io_pads_pwm1_ch2_o_oval;
  wire io_pads_pwm1_ch2_o_oe  ;
  wire io_pads_pwm1_ch3_i_ival;
  wire io_pads_pwm1_ch3_o_oval;
  wire io_pads_pwm1_ch3_o_oe  ;

  wire io_pads_pwm2_ch0_i_ival;
  wire io_pads_pwm2_ch0_o_oval;
  wire io_pads_pwm2_ch0_o_oe  ;
  wire io_pads_pwm2_ch1_i_ival;
  wire io_pads_pwm2_ch1_o_oval;
  wire io_pads_pwm2_ch1_o_oe  ;
  wire io_pads_pwm2_ch2_i_ival;
  wire io_pads_pwm2_ch2_o_oval;
  wire io_pads_pwm2_ch2_o_oe  ;
  wire io_pads_pwm2_ch3_i_ival;
  wire io_pads_pwm2_ch3_o_oval;
  wire io_pads_pwm2_ch3_o_oe  ;

  wire io_pads_pwm3_ch0_i_ival;
  wire io_pads_pwm3_ch0_o_oval;
  wire io_pads_pwm3_ch0_o_oe  ;
  wire io_pads_pwm3_ch1_i_ival;
  wire io_pads_pwm3_ch1_o_oval;
  wire io_pads_pwm3_ch1_o_oe  ;
  wire io_pads_pwm3_ch2_i_ival;
  wire io_pads_pwm3_ch2_o_oval;
  wire io_pads_pwm3_ch2_o_oe  ;
  wire io_pads_pwm3_ch3_i_ival;
  wire io_pads_pwm3_ch3_o_oval;
  wire io_pads_pwm3_ch3_o_oe  ;


  assign io_pads_pwm0_ch0_o_oe   = 1'h1;
  assign io_pads_pwm0_ch1_o_oe   = 1'h1;
  assign io_pads_pwm0_ch2_o_oe   = 1'h1;
  assign io_pads_pwm0_ch3_o_oe   = 1'h1;

  assign io_pads_pwm0_ch0_o_oval = pwm_timer0_o[0];
  assign io_pads_pwm0_ch1_o_oval = pwm_timer0_o[1];
  assign io_pads_pwm0_ch2_o_oval = pwm_timer0_o[2];
  assign io_pads_pwm0_ch3_o_oval = pwm_timer0_o[3];

  assign io_pads_pwm1_ch0_o_oe   = 1'h1;
  assign io_pads_pwm1_ch1_o_oe   = 1'h1;
  assign io_pads_pwm1_ch2_o_oe   = 1'h1;
  assign io_pads_pwm1_ch3_o_oe   = 1'h1;

  assign io_pads_pwm1_ch0_o_oval = pwm_timer1_o[0];
  assign io_pads_pwm1_ch1_o_oval = pwm_timer1_o[1];
  assign io_pads_pwm1_ch2_o_oval = pwm_timer1_o[2];
  assign io_pads_pwm1_ch3_o_oval = pwm_timer1_o[3];

  assign io_pads_pwm2_ch0_o_oe   = 1'h1;
  assign io_pads_pwm2_ch1_o_oe   = 1'h1;
  assign io_pads_pwm2_ch2_o_oe   = 1'h1;
  assign io_pads_pwm2_ch3_o_oe   = 1'h1;

  assign io_pads_pwm2_ch0_o_oval = pwm_timer2_o[0];
  assign io_pads_pwm2_ch1_o_oval = pwm_timer2_o[1];
  assign io_pads_pwm2_ch2_o_oval = pwm_timer2_o[2];
  assign io_pads_pwm2_ch3_o_oval = pwm_timer2_o[3];

  assign io_pads_pwm3_ch0_o_oe   = 1'h1;
  assign io_pads_pwm3_ch1_o_oe   = 1'h1;
  assign io_pads_pwm3_ch2_o_oe   = 1'h1;
  assign io_pads_pwm3_ch3_o_oe   = 1'h1;

  assign io_pads_pwm3_ch0_o_oval = pwm_timer3_o[0];
  assign io_pads_pwm3_ch1_o_oval = pwm_timer3_o[1];
  assign io_pads_pwm3_ch2_o_oval = pwm_timer3_o[2];
  assign io_pads_pwm3_ch3_o_oval = pwm_timer3_o[3];



  // * Here is an example AXI Peripheral
  wire expl_axi_arvalid;
  wire expl_axi_arready;
  wire [`E203_ADDR_SIZE-1:0] expl_axi_araddr;
  wire [3:0] expl_axi_arcache;
  wire [2:0] expl_axi_arprot;
  wire [1:0] expl_axi_arlock;
  wire [1:0] expl_axi_arburst;
  wire [3:0] expl_axi_arlen;
  wire [2:0] expl_axi_arsize;

  wire expl_axi_awvalid;
  wire expl_axi_awready;
  wire [`E203_ADDR_SIZE-1:0] expl_axi_awaddr;
  wire [3:0] expl_axi_awcache;
  wire [2:0] expl_axi_awprot;
  wire [1:0] expl_axi_awlock;
  wire [1:0] expl_axi_awburst;
  wire [3:0] expl_axi_awlen;
  wire [2:0] expl_axi_awsize;

  wire expl_axi_rvalid;
  wire expl_axi_rready;
  wire [`E203_XLEN-1:0] expl_axi_rdata;
  wire [1:0] expl_axi_rresp;
  wire expl_axi_rlast;

  wire expl_axi_wvalid;
  wire expl_axi_wready;
  wire [`E203_XLEN-1:0] expl_axi_wdata;
  wire [(`E203_XLEN/8)-1:0] expl_axi_wstrb;
  wire expl_axi_wlast;

  wire expl_axi_bvalid;
  wire expl_axi_bready;
  wire [1:0] expl_axi_bresp;
   
sirv_gnrl_icb2axi # (
  .AXI_FIFO_DP (2), // We just add ping-pong buffer here to avoid any potential timing loops
                    //   User can change it to 0 if dont care
  .AXI_FIFO_CUT_READY (1), // This is to cut the back-pressure signal if you set as 1
  .AW   (32),
  .FIFO_OUTS_NUM (1),// We only allow 1 oustandings at most for peripheral, user can configure it to any value
  .FIFO_CUT_READY(1),
  .DW   (`E203_XLEN) 
) u_expl_axi_icb2axi(
    .i_icb_cmd_valid (expl_axi_icb_cmd_valid),
    .i_icb_cmd_ready (expl_axi_icb_cmd_ready),
    .i_icb_cmd_addr  (expl_axi_icb_cmd_addr ),
    .i_icb_cmd_read  (expl_axi_icb_cmd_read ),
    .i_icb_cmd_wdata (expl_axi_icb_cmd_wdata),
    .i_icb_cmd_wmask (expl_axi_icb_cmd_wmask),
    .i_icb_cmd_size  (),
    
    .i_icb_rsp_valid (expl_axi_icb_rsp_valid),
    .i_icb_rsp_ready (expl_axi_icb_rsp_ready),
    .i_icb_rsp_rdata (expl_axi_icb_rsp_rdata),
    .i_icb_rsp_err   (expl_axi_icb_rsp_err),

    .o_axi_arvalid   (expl_axi_arvalid),
    .o_axi_arready   (expl_axi_arready),
    .o_axi_araddr    (expl_axi_araddr ),
    .o_axi_arcache   (expl_axi_arcache),
    .o_axi_arprot    (expl_axi_arprot ),
    .o_axi_arlock    (expl_axi_arlock ),
    .o_axi_arburst   (expl_axi_arburst),
    .o_axi_arlen     (expl_axi_arlen  ),
    .o_axi_arsize    (expl_axi_arsize ),
                      
    .o_axi_awvalid   (expl_axi_awvalid),
    .o_axi_awready   (expl_axi_awready),
    .o_axi_awaddr    (expl_axi_awaddr ),
    .o_axi_awcache   (expl_axi_awcache),
    .o_axi_awprot    (expl_axi_awprot ),
    .o_axi_awlock    (expl_axi_awlock ),
    .o_axi_awburst   (expl_axi_awburst),
    .o_axi_awlen     (expl_axi_awlen  ),
    .o_axi_awsize    (expl_axi_awsize ),
                     
    .o_axi_rvalid    (expl_axi_rvalid ),
    .o_axi_rready    (expl_axi_rready ),
    .o_axi_rdata     (expl_axi_rdata  ),
    .o_axi_rresp     (expl_axi_rresp  ),
    .o_axi_rlast     (expl_axi_rlast  ),
                    
    .o_axi_wvalid    (expl_axi_wvalid ),
    .o_axi_wready    (expl_axi_wready ),
    .o_axi_wdata     (expl_axi_wdata  ),
    .o_axi_wstrb     (expl_axi_wstrb  ),
    .o_axi_wlast     (expl_axi_wlast  ),
                   
    .o_axi_bvalid    (expl_axi_bvalid ),
    .o_axi_bready    (expl_axi_bready ),
    .o_axi_bresp     (expl_axi_bresp  ),

    .clk           (clk  ),
    .rst_n         (bus_rst_n) 
  );

sirv_expl_axi_slv # (
  .AW   (32),
  .DW   (`E203_XLEN) 
) u_perips_expl_axi_slv (
    .axi_arvalid   (expl_axi_arvalid),
    .axi_arready   (expl_axi_arready),
    .axi_araddr    (expl_axi_araddr ),
    .axi_arcache   (expl_axi_arcache),
    .axi_arprot    (expl_axi_arprot ),
    .axi_arlock    (expl_axi_arlock ),
    .axi_arburst   (expl_axi_arburst),
    .axi_arlen     (expl_axi_arlen  ),
    .axi_arsize    (expl_axi_arsize ),
     
    .axi_awvalid   (expl_axi_awvalid),
    .axi_awready   (expl_axi_awready),
    .axi_awaddr    (expl_axi_awaddr ),
    .axi_awcache   (expl_axi_awcache),
    .axi_awprot    (expl_axi_awprot ),
    .axi_awlock    (expl_axi_awlock ),
    .axi_awburst   (expl_axi_awburst),
    .axi_awlen     (expl_axi_awlen  ),
    .axi_awsize    (expl_axi_awsize ),
    
    .axi_rvalid    (expl_axi_rvalid ),
    .axi_rready    (expl_axi_rready ),
    .axi_rdata     (expl_axi_rdata  ),
    .axi_rresp     (expl_axi_rresp  ),
    .axi_rlast     (expl_axi_rlast  ),
   
    .axi_wvalid    (expl_axi_wvalid ),
    .axi_wready    (expl_axi_wready ),
    .axi_wdata     (expl_axi_wdata  ),
    .axi_wstrb     (expl_axi_wstrb  ),
    .axi_wlast     (expl_axi_wlast  ),
  
    .axi_bvalid    (expl_axi_bvalid ),
    .axi_bready    (expl_axi_bready ),
    .axi_bresp     (expl_axi_bresp  ),

    .clk           (clk  ),
    .rst_n         (rst_n) 
  );



  sirv_hclkgen_regs u_sirv_hclkgen_regs(
    .clk  (clk),
    .rst_n(rst_n),

    .pllbypass   (pllbypass   ),
    .pll_RESET(pll_RESET),
    .pll_ASLEEP(pll_ASLEEP),
    .pll_OD(pll_OD),
    .pll_M (pll_M ),
    .pll_N (pll_N ),
    .plloutdivby1(plloutdivby1),
    .plloutdiv   (plloutdiv   ),
                              
    .hfxoscen    (hfxoscen    ),


    .i_icb_cmd_valid(hclkgen_icb_cmd_valid),
    .i_icb_cmd_ready(hclkgen_icb_cmd_ready),
    .i_icb_cmd_addr (hclkgen_icb_cmd_addr[11:0]), 
    .i_icb_cmd_read (hclkgen_icb_cmd_read ), 
    .i_icb_cmd_wdata(hclkgen_icb_cmd_wdata),
                     
    .i_icb_rsp_valid(hclkgen_icb_rsp_valid),
    .i_icb_rsp_ready(hclkgen_icb_rsp_ready),
    .i_icb_rsp_rdata(hclkgen_icb_rsp_rdata)
  );


  // The GPIOA IOF SET 
 assign  io_pads_gpioA_o_oe[0]      =  gpioA_iof[0]    ? io_pads_pwm0_ch0_o_oe          : gpioA_o_oe[0];
 assign  io_pads_gpioA_o_oe[1]      =  gpioA_iof[1]    ? io_pads_pwm0_ch1_o_oe          : gpioA_o_oe[1];
 assign  io_pads_gpioA_o_oe[2]      =  gpioA_iof[2]    ? io_pads_pwm0_ch2_o_oe          : gpioA_o_oe[2];
 assign  io_pads_gpioA_o_oe[3]      =  gpioA_iof[3]    ? io_pads_pwm0_ch3_o_oe          : gpioA_o_oe[3];
 assign  io_pads_gpioA_o_oe[4]      =  gpioA_iof[4]    ? io_pads_pwm1_ch0_o_oe          : gpioA_o_oe[4];
 assign  io_pads_gpioA_o_oe[5]      =  gpioA_iof[5]    ? io_pads_pwm1_ch1_o_oe          : gpioA_o_oe[5];
 assign  io_pads_gpioA_o_oe[6]      =  gpioA_iof[6]    ? io_pads_pwm1_ch2_o_oe          : gpioA_o_oe[6];
 assign  io_pads_gpioA_o_oe[7]      =  gpioA_iof[7]    ? io_pads_pwm1_ch3_o_oe          : gpioA_o_oe[7];
 assign  io_pads_gpioA_o_oe[8]      =  gpioA_iof[8]    ? io_pads_qspi1_sck_o_oe         : gpioA_o_oe[8];
 assign  io_pads_gpioA_o_oe[9]      =  gpioA_iof[9]    ? io_pads_qspi1_cs_0_o_oe        : gpioA_o_oe[9];
 assign  io_pads_gpioA_o_oe[10]     =  gpioA_iof[10]   ? io_pads_qspi1_dq_0_o_oe        : gpioA_o_oe[10];
 assign  io_pads_gpioA_o_oe[11]     =  gpioA_iof[11]   ? io_pads_qspi1_dq_1_o_oe        : gpioA_o_oe[11];
 assign  io_pads_gpioA_o_oe[12]     =  gpioA_iof[12]   ? io_pads_qspi1_dq_2_o_oe        : gpioA_o_oe[12];
 assign  io_pads_gpioA_o_oe[13]     =  gpioA_iof[13]   ? io_pads_qspi1_dq_3_o_oe        : gpioA_o_oe[13];
 assign  io_pads_gpioA_o_oe[14]     =  gpioA_iof[14]   ? (~io_pads_i2c0_scl_o_oen)      : gpioA_o_oe[14];
 assign  io_pads_gpioA_o_oe[15]     =  gpioA_iof[15]   ? (~io_pads_i2c0_sda_o_oen)      : gpioA_o_oe[15];
 assign  io_pads_gpioA_o_oe[16]     =  gpioA_iof[16]   ? io_pads_uart0_rxd_o_oe         : gpioA_o_oe[16];
 assign  io_pads_gpioA_o_oe[17]     =  gpioA_iof[17]   ? io_pads_uart0_txd_o_oe         : gpioA_o_oe[17];
 assign  io_pads_gpioA_o_oe[18]     =  gpioA_iof[18]   ? io_pads_uart2_rxd_o_oe         : gpioA_o_oe[18];
 assign  io_pads_gpioA_o_oe[19]     =  gpioA_iof[19]   ? io_pads_uart2_txd_o_oe         : gpioA_o_oe[19];
 assign  io_pads_gpioA_o_oe[20]     =  gpioA_o_oe[20];
 assign  io_pads_gpioA_o_oe[21]     =  gpioA_o_oe[21];
 assign  io_pads_gpioA_o_oe[22]     =  gpioA_o_oe[22];
 assign  io_pads_gpioA_o_oe[23]     =  gpioA_o_oe[23];
 assign  io_pads_gpioA_o_oe[24]     =  gpioA_o_oe[24];
 assign  io_pads_gpioA_o_oe[25]     =  gpioA_o_oe[25];
 assign  io_pads_gpioA_o_oe[26]     =  gpioA_o_oe[26];
 assign  io_pads_gpioA_o_oe[27]     =  gpioA_o_oe[27];
 assign  io_pads_gpioA_o_oe[28]     =  gpioA_o_oe[28];
 assign  io_pads_gpioA_o_oe[29]     =  gpioA_o_oe[29];
 assign  io_pads_gpioA_o_oe[30]     =  gpioA_o_oe[30];
 assign  io_pads_gpioA_o_oe[31]     =  gpioA_o_oe[31];
 
 assign  io_pads_gpioA_o_oval[0]    =  gpioA_iof[0]    ? io_pads_pwm0_ch0_o_oval        : gpioA_o_oval[0];
 assign  io_pads_gpioA_o_oval[1]    =  gpioA_iof[1]    ? io_pads_pwm0_ch1_o_oval        : gpioA_o_oval[1];
 assign  io_pads_gpioA_o_oval[2]    =  gpioA_iof[2]    ? io_pads_pwm0_ch2_o_oval        : gpioA_o_oval[2];
 assign  io_pads_gpioA_o_oval[3]    =  gpioA_iof[3]    ? io_pads_pwm0_ch3_o_oval        : gpioA_o_oval[3];
 assign  io_pads_gpioA_o_oval[4]    =  gpioA_iof[4]    ? io_pads_pwm1_ch0_o_oval        : gpioA_o_oval[4];
 assign  io_pads_gpioA_o_oval[5]    =  gpioA_iof[5]    ? io_pads_pwm1_ch1_o_oval        : gpioA_o_oval[5];
 assign  io_pads_gpioA_o_oval[6]    =  gpioA_iof[6]    ? io_pads_pwm1_ch2_o_oval        : gpioA_o_oval[6];
 assign  io_pads_gpioA_o_oval[7]    =  gpioA_iof[7]    ? io_pads_pwm1_ch3_o_oval        : gpioA_o_oval[7];
 assign  io_pads_gpioA_o_oval[8]    =  gpioA_iof[8]    ? io_pads_qspi1_sck_o_oval       : gpioA_o_oval[8];
 assign  io_pads_gpioA_o_oval[9]    =  gpioA_iof[9]    ? io_pads_qspi1_cs_0_o_oval      : gpioA_o_oval[9];
 assign  io_pads_gpioA_o_oval[10]   =  gpioA_iof[10]   ? io_pads_qspi1_dq_0_o_oval      : gpioA_o_oval[10];
 assign  io_pads_gpioA_o_oval[11]   =  gpioA_iof[11]   ? io_pads_qspi1_dq_1_o_oval      : gpioA_o_oval[11];
 assign  io_pads_gpioA_o_oval[12]   =  gpioA_iof[12]   ? io_pads_qspi1_dq_2_o_oval      : gpioA_o_oval[12];
 assign  io_pads_gpioA_o_oval[13]   =  gpioA_iof[13]   ? io_pads_qspi1_dq_3_o_oval      : gpioA_o_oval[13];
 assign  io_pads_gpioA_o_oval[14]   =  gpioA_iof[14]   ? io_pads_i2c0_scl_o_oval        : gpioA_o_oval[14];
 assign  io_pads_gpioA_o_oval[15]   =  gpioA_iof[15]   ? io_pads_i2c0_sda_o_oval        : gpioA_o_oval[15];
 assign  io_pads_gpioA_o_oval[16]   =  gpioA_iof[16]   ? io_pads_uart0_rxd_o_oval       : gpioA_o_oval[16];
 assign  io_pads_gpioA_o_oval[17]   =  gpioA_iof[17]   ? io_pads_uart0_txd_o_oval       : gpioA_o_oval[17];
 assign  io_pads_gpioA_o_oval[18]   =  gpioA_iof[18]   ? io_pads_uart2_rxd_o_oval       : gpioA_o_oval[18];
 assign  io_pads_gpioA_o_oval[19]   =  gpioA_iof[19]   ? io_pads_uart2_txd_o_oval       : gpioA_o_oval[19];
 assign  io_pads_gpioA_o_oval[20]   =  gpioA_o_oval[20];
 assign  io_pads_gpioA_o_oval[21]   =  gpioA_o_oval[21];
 assign  io_pads_gpioA_o_oval[22]   =  gpioA_o_oval[22];
 assign  io_pads_gpioA_o_oval[23]   =  gpioA_o_oval[23];
 assign  io_pads_gpioA_o_oval[24]   =  gpioA_o_oval[24];
 assign  io_pads_gpioA_o_oval[25]   =  gpioA_o_oval[25];
 assign  io_pads_gpioA_o_oval[26]   =  gpioA_o_oval[26];
 assign  io_pads_gpioA_o_oval[27]   =  gpioA_o_oval[27];
 assign  io_pads_gpioA_o_oval[28]   =  gpioA_o_oval[28];
 assign  io_pads_gpioA_o_oval[29]   =  gpioA_o_oval[29];
 assign  io_pads_gpioA_o_oval[30]   =  gpioA_o_oval[30];
 assign  io_pads_gpioA_o_oval[31]   =  gpioA_o_oval[31];

 assign  gpioA_i_ival               =  io_pads_gpioA_i_ival;
 assign  io_pads_pwm0_ch0_i_ival    =  gpioA_in_sync[0];
 assign  io_pads_pwm0_ch1_i_ival    =  gpioA_in_sync[1];
 assign  io_pads_pwm0_ch2_i_ival    =  gpioA_in_sync[2];
 assign  io_pads_pwm0_ch3_i_ival    =  gpioA_in_sync[3];
 assign  io_pads_pwm1_ch0_i_ival    =  gpioA_in_sync[4];
 assign  io_pads_pwm1_ch1_i_ival    =  gpioA_in_sync[5];
 assign  io_pads_pwm1_ch2_i_ival    =  gpioA_in_sync[6];
 assign  io_pads_pwm1_ch3_i_ival    =  gpioA_in_sync[7];
 assign  io_pads_qspi1_sck_i_ival   =  gpioA_in_sync[8];
 assign  io_pads_qspi1_cs_0_i_ival  =  gpioA_in_sync[9];
 assign  io_pads_qspi1_dq_0_i_ival  =  gpioA_in_sync[10];
 assign  io_pads_qspi1_dq_1_i_ival  =  gpioA_in_sync[11];
 assign  io_pads_qspi1_dq_2_i_ival  =  gpioA_in_sync[12];
 assign  io_pads_qspi1_dq_3_i_ival  =  gpioA_in_sync[13];
 assign  io_pads_i2c0_scl_i_ival    =  gpioA_in_sync[14];
 assign  io_pads_i2c0_sda_i_ival    =  gpioA_in_sync[15];
 assign  io_pads_uart0_rxd_i_ival   =  gpioA_in_sync[16];
 assign  io_pads_uart0_txd_i_ival   =  gpioA_in_sync[17];
 assign  io_pads_uart2_rxd_i_ival   =  gpioA_in_sync[18];
 assign  io_pads_uart2_txd_i_ival   =  gpioA_in_sync[19];


  // The GPIOB IOF SET 
 assign  io_pads_gpioB_o_oe[0]      =  gpioB_iof[0]    ? io_pads_pwm2_ch0_o_oe          : gpioB_o_oe[0];
 assign  io_pads_gpioB_o_oe[1]      =  gpioB_iof[1]    ? io_pads_pwm2_ch1_o_oe          : gpioB_o_oe[1];
 assign  io_pads_gpioB_o_oe[2]      =  gpioB_iof[2]    ? io_pads_pwm2_ch2_o_oe          : gpioB_o_oe[2];
 assign  io_pads_gpioB_o_oe[3]      =  gpioB_iof[3]    ? io_pads_pwm2_ch3_o_oe          : gpioB_o_oe[3];
 assign  io_pads_gpioB_o_oe[4]      =  gpioB_iof[4]    ? io_pads_pwm3_ch0_o_oe          : gpioB_o_oe[4];
 assign  io_pads_gpioB_o_oe[5]      =  gpioB_iof[5]    ? io_pads_pwm3_ch1_o_oe          : gpioB_o_oe[5];
 assign  io_pads_gpioB_o_oe[6]      =  gpioB_iof[6]    ? io_pads_pwm3_ch2_o_oe          : gpioB_o_oe[6];
 assign  io_pads_gpioB_o_oe[7]      =  gpioB_iof[7]    ? io_pads_pwm3_ch3_o_oe          : gpioB_o_oe[7];
 assign  io_pads_gpioB_o_oe[8]      =  gpioB_iof[8]    ? io_pads_qspi2_sck_o_oe         : gpioB_o_oe[8];
 assign  io_pads_gpioB_o_oe[9]      =  gpioB_iof[9]    ? io_pads_qspi2_cs_0_o_oe        : gpioB_o_oe[9];
 assign  io_pads_gpioB_o_oe[10]     =  gpioB_iof[10]   ? io_pads_qspi2_dq_0_o_oe        : gpioB_o_oe[10];
 assign  io_pads_gpioB_o_oe[11]     =  gpioB_iof[11]   ? io_pads_qspi2_dq_1_o_oe        : gpioB_o_oe[11];
 assign  io_pads_gpioB_o_oe[12]     =  gpioB_iof[12]   ? io_pads_qspi2_dq_2_o_oe        : gpioB_o_oe[12];
 assign  io_pads_gpioB_o_oe[13]     =  gpioB_iof[13]   ? io_pads_qspi2_dq_3_o_oe        : gpioB_o_oe[13];
 assign  io_pads_gpioB_o_oe[14]     =  gpioB_iof[14]   ? (~io_pads_i2c1_scl_o_oen)      : gpioB_o_oe[14];
 assign  io_pads_gpioB_o_oe[15]     =  gpioB_iof[15]   ? (~io_pads_i2c1_sda_o_oen)      : gpioB_o_oe[15];
 assign  io_pads_gpioB_o_oe[16]     =  gpioB_iof[16]   ? io_pads_uart1_rxd_o_oe         : gpioB_o_oe[16];
 assign  io_pads_gpioB_o_oe[17]     =  gpioB_iof[17]   ? io_pads_uart1_txd_o_oe         : gpioB_o_oe[17];
 assign  io_pads_gpioB_o_oe[18]     =  gpioB_o_oe[18];
 assign  io_pads_gpioB_o_oe[19]     =  gpioB_o_oe[19];
 assign  io_pads_gpioB_o_oe[20]     =  gpioB_o_oe[20];
 assign  io_pads_gpioB_o_oe[21]     =  gpioB_o_oe[21];
 assign  io_pads_gpioB_o_oe[22]     =  gpioB_o_oe[22];
 assign  io_pads_gpioB_o_oe[23]     =  gpioB_o_oe[23];
 assign  io_pads_gpioB_o_oe[24]     =  gpioB_o_oe[24];
 assign  io_pads_gpioB_o_oe[25]     =  gpioB_o_oe[25];
 assign  io_pads_gpioB_o_oe[26]     =  gpioB_o_oe[26];
 assign  io_pads_gpioB_o_oe[27]     =  gpioB_o_oe[27];
 assign  io_pads_gpioB_o_oe[28]     =  gpioB_o_oe[28];
 assign  io_pads_gpioB_o_oe[29]     =  gpioB_o_oe[29];
 assign  io_pads_gpioB_o_oe[30]     =  gpioB_o_oe[30];
 assign  io_pads_gpioB_o_oe[31]     =  gpioB_o_oe[31];
 
 assign  io_pads_gpioB_o_oval[0]    =  gpioB_iof[0]    ? io_pads_pwm2_ch0_o_oval        : gpioB_o_oval[0];
 assign  io_pads_gpioB_o_oval[1]    =  gpioB_iof[1]    ? io_pads_pwm2_ch1_o_oval        : gpioB_o_oval[1];
 assign  io_pads_gpioB_o_oval[2]    =  gpioB_iof[2]    ? io_pads_pwm2_ch2_o_oval        : gpioB_o_oval[2];
 assign  io_pads_gpioB_o_oval[3]    =  gpioB_iof[3]    ? io_pads_pwm2_ch3_o_oval        : gpioB_o_oval[3];
 assign  io_pads_gpioB_o_oval[4]    =  gpioB_iof[4]    ? io_pads_pwm3_ch0_o_oval        : gpioB_o_oval[4];
 assign  io_pads_gpioB_o_oval[5]    =  gpioB_iof[5]    ? io_pads_pwm3_ch1_o_oval        : gpioB_o_oval[5];
 assign  io_pads_gpioB_o_oval[6]    =  gpioB_iof[6]    ? io_pads_pwm3_ch2_o_oval        : gpioB_o_oval[6];
 assign  io_pads_gpioB_o_oval[7]    =  gpioB_iof[7]    ? io_pads_pwm3_ch3_o_oval        : gpioB_o_oval[7];
 assign  io_pads_gpioB_o_oval[8]    =  gpioB_iof[8]    ? io_pads_qspi2_sck_o_oval       : gpioB_o_oval[8];
 assign  io_pads_gpioB_o_oval[9]    =  gpioB_iof[9]    ? io_pads_qspi2_cs_0_o_oval      : gpioB_o_oval[9];
 assign  io_pads_gpioB_o_oval[10]   =  gpioB_iof[10]   ? io_pads_qspi2_dq_0_o_oval      : gpioB_o_oval[10];
 assign  io_pads_gpioB_o_oval[11]   =  gpioB_iof[11]   ? io_pads_qspi2_dq_1_o_oval      : gpioB_o_oval[11];
 assign  io_pads_gpioB_o_oval[12]   =  gpioB_iof[12]   ? io_pads_qspi2_dq_2_o_oval      : gpioB_o_oval[12];
 assign  io_pads_gpioB_o_oval[13]   =  gpioB_iof[13]   ? io_pads_qspi2_dq_3_o_oval      : gpioB_o_oval[13];
 assign  io_pads_gpioB_o_oval[14]   =  gpioB_iof[14]   ? io_pads_i2c1_scl_o_oval        : gpioB_o_oval[14];
 assign  io_pads_gpioB_o_oval[15]   =  gpioB_iof[15]   ? io_pads_i2c1_sda_o_oval        : gpioB_o_oval[15];
 assign  io_pads_gpioB_o_oval[16]   =  gpioB_iof[16]   ? io_pads_uart1_rxd_o_oval       : gpioB_o_oval[16];
 assign  io_pads_gpioB_o_oval[17]   =  gpioB_iof[17]   ? io_pads_uart1_txd_o_oval       : gpioB_o_oval[17];
 assign  io_pads_gpioB_o_oval[18]   =  gpioB_o_oval[18];
 assign  io_pads_gpioB_o_oval[19]   =  gpioB_o_oval[19];
 assign  io_pads_gpioB_o_oval[20]   =  gpioB_o_oval[20];
 assign  io_pads_gpioB_o_oval[21]   =  gpioB_o_oval[21];
 assign  io_pads_gpioB_o_oval[22]   =  gpioB_o_oval[22];
 assign  io_pads_gpioB_o_oval[23]   =  gpioB_o_oval[23];
 assign  io_pads_gpioB_o_oval[24]   =  gpioB_o_oval[24];
 assign  io_pads_gpioB_o_oval[25]   =  gpioB_o_oval[25];
 assign  io_pads_gpioB_o_oval[26]   =  gpioB_o_oval[26];
 assign  io_pads_gpioB_o_oval[27]   =  gpioB_o_oval[27];
 assign  io_pads_gpioB_o_oval[28]   =  gpioB_o_oval[28];
 assign  io_pads_gpioB_o_oval[29]   =  gpioB_o_oval[29];
 assign  io_pads_gpioB_o_oval[30]   =  gpioB_o_oval[30];
 assign  io_pads_gpioB_o_oval[31]   =  gpioB_o_oval[31];

 assign  gpioB_i_ival               =  io_pads_gpioB_i_ival;
 assign  io_pads_pwm2_ch0_i_ival    =  gpioB_in_sync[0];
 assign  io_pads_pwm2_ch1_i_ival    =  gpioB_in_sync[1];
 assign  io_pads_pwm2_ch2_i_ival    =  gpioB_in_sync[2];
 assign  io_pads_pwm2_ch3_i_ival    =  gpioB_in_sync[3];
 assign  io_pads_pwm3_ch0_i_ival    =  gpioB_in_sync[4];
 assign  io_pads_pwm3_ch1_i_ival    =  gpioB_in_sync[5];
 assign  io_pads_pwm3_ch2_i_ival    =  gpioB_in_sync[6];
 assign  io_pads_pwm3_ch3_i_ival    =  gpioB_in_sync[7];
 assign  io_pads_qspi2_sck_i_ival   =  gpioB_in_sync[8];
 assign  io_pads_qspi2_cs_0_i_ival  =  gpioB_in_sync[9];
 assign  io_pads_qspi2_dq_0_i_ival  =  gpioB_in_sync[10];
 assign  io_pads_qspi2_dq_1_i_ival  =  gpioB_in_sync[11];
 assign  io_pads_qspi2_dq_2_i_ival  =  gpioB_in_sync[12];
 assign  io_pads_qspi2_dq_3_i_ival  =  gpioB_in_sync[13];
 assign  io_pads_i2c1_scl_i_ival    =  gpioB_in_sync[14];
 assign  io_pads_i2c1_sda_i_ival    =  gpioB_in_sync[15];
 assign  io_pads_uart1_rxd_i_ival   =  gpioB_in_sync[16];
 assign  io_pads_uart1_txd_i_ival   =  gpioB_in_sync[17];

endmodule
