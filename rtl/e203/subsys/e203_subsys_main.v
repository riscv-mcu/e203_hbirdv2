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
//  The Subsystem-TOP module to implement CPU and some closely coupled devices
//
// ====================================================================


`include "e203_defines.v"


module e203_subsys_main(
  output core_csr_clk,

  output hfxoscen,// The signal to enable the crystal pad generated clock

  output inspect_pc_29b       ,
  output inspect_dbg_irq      ,

  input  inspect_mode, 
  input  inspect_por_rst, 
  input  inspect_32k_clk, 
  input  inspect_jtag_clk,

  input  [`E203_PC_SIZE-1:0] pc_rtvec,
  ///////////////////////////////////////
  // With the interface to debug module 
  //
    // The interface with commit stage
  output  [`E203_PC_SIZE-1:0] cmt_dpc,
  output  cmt_dpc_ena,

  output  [3-1:0] cmt_dcause,
  output  cmt_dcause_ena,

  input   dbg_irq_a,
  output  dbg_irq_r,

    // The interface with CSR control 
  output  wr_dcsr_ena    ,
  output  wr_dpc_ena     ,
  output  wr_dscratch_ena,



  output  [32-1:0] wr_csr_nxt    ,

  input  [32-1:0] dcsr_r    ,
  input  [`E203_PC_SIZE-1:0] dpc_r     ,
  input  [32-1:0] dscratch_r,

  input  dbg_mode,
  input  dbg_halt_r,
  input  dbg_step_r,
  input  dbg_ebreakm_r,
  input  dbg_stopcycle,


  ///////////////////////////////////////
  input  [`E203_HART_ID_W-1:0] core_mhartid,  
    
  input  aon_wdg_irq_a,
  input  aon_rtc_irq_a,
  input  aon_rtcToggle_a,

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

      //////////////////////////////////////////////////////////
  output                         dm_icb_cmd_valid,
  input                          dm_icb_cmd_ready,
  output [`E203_ADDR_SIZE-1:0]   dm_icb_cmd_addr, 
  output                         dm_icb_cmd_read, 
  output [`E203_XLEN-1:0]        dm_icb_cmd_wdata,
  //
  input                          dm_icb_rsp_valid,
  output                         dm_icb_rsp_ready,
  input  [`E203_XLEN-1:0]        dm_icb_rsp_rdata,

  input  [32-1:0] io_pads_gpioA_i_ival,
  output [32-1:0] io_pads_gpioA_o_oval,
  output [32-1:0] io_pads_gpioA_o_oe,

  input  [32-1:0] io_pads_gpioB_i_ival,
  output [32-1:0] io_pads_gpioB_o_oval,
  output [32-1:0] io_pads_gpioB_o_oe,  

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

  `ifdef E203_HAS_ITCM_EXTITF //{
  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // External-agent ICB to ITCM
  //    * Bus cmd channel
  input                          ext2itcm_icb_cmd_valid,
  output                         ext2itcm_icb_cmd_ready,
  input  [`E203_ITCM_ADDR_WIDTH-1:0]   ext2itcm_icb_cmd_addr, 
  input                          ext2itcm_icb_cmd_read, 
  input  [`E203_XLEN-1:0]        ext2itcm_icb_cmd_wdata,
  input  [`E203_XLEN/8-1:0]      ext2itcm_icb_cmd_wmask,
  //
  //    * Bus RSP channel
  output                         ext2itcm_icb_rsp_valid,
  input                          ext2itcm_icb_rsp_ready,
  output                         ext2itcm_icb_rsp_err  ,
  output [`E203_XLEN-1:0]        ext2itcm_icb_rsp_rdata,
  `endif//}

  `ifdef E203_HAS_DTCM_EXTITF //{
  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // External-agent ICB to DTCM
  //    * Bus cmd channel
  input                          ext2dtcm_icb_cmd_valid,
  output                         ext2dtcm_icb_cmd_ready,
  input  [`E203_DTCM_ADDR_WIDTH-1:0]   ext2dtcm_icb_cmd_addr, 
  input                          ext2dtcm_icb_cmd_read, 
  input  [`E203_XLEN-1:0]        ext2dtcm_icb_cmd_wdata,
  input  [`E203_XLEN/8-1:0]      ext2dtcm_icb_cmd_wmask,
  //
  //    * Bus RSP channel
  output                         ext2dtcm_icb_rsp_valid,
  input                          ext2dtcm_icb_rsp_ready,
  output                         ext2dtcm_icb_rsp_err  ,
  output [`E203_XLEN-1:0]        ext2dtcm_icb_rsp_rdata,
  `endif//}

  
  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The ICB Interface to Private Peripheral Interface
  //
  //    * Bus cmd channel
  output                         sysper_icb_cmd_valid,
  input                          sysper_icb_cmd_ready,
  output [`E203_ADDR_SIZE-1:0]   sysper_icb_cmd_addr, 
  output                         sysper_icb_cmd_read, 
  output [`E203_XLEN-1:0]        sysper_icb_cmd_wdata,
  output [`E203_XLEN/8-1:0]      sysper_icb_cmd_wmask,
  //
  //    * Bus RSP channel
  input                          sysper_icb_rsp_valid,
  output                         sysper_icb_rsp_ready,
  input                          sysper_icb_rsp_err  ,
  input  [`E203_XLEN-1:0]        sysper_icb_rsp_rdata,

  `ifdef E203_HAS_FIO //{
  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The ICB Interface to Fast I/O
  //
  //    * Bus cmd channel
  output                         sysfio_icb_cmd_valid,
  input                          sysfio_icb_cmd_ready,
  output [`E203_ADDR_SIZE-1:0]   sysfio_icb_cmd_addr, 
  output                         sysfio_icb_cmd_read, 
  output [`E203_XLEN-1:0]        sysfio_icb_cmd_wdata,
  output [`E203_XLEN/8-1:0]      sysfio_icb_cmd_wmask,
  //
  //    * Bus RSP channel
  input                          sysfio_icb_rsp_valid,
  output                         sysfio_icb_rsp_ready,
  input                          sysfio_icb_rsp_err  ,
  input  [`E203_XLEN-1:0]        sysfio_icb_rsp_rdata,
  `endif//}

  `ifdef E203_HAS_MEM_ITF //{
  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The ICB Interface from Ifetch 
  //
  //    * Bus cmd channel
  output                         sysmem_icb_cmd_valid,
  input                          sysmem_icb_cmd_ready,
  output [`E203_ADDR_SIZE-1:0]   sysmem_icb_cmd_addr, 
  output                         sysmem_icb_cmd_read, 
  output [`E203_XLEN-1:0]        sysmem_icb_cmd_wdata,
  output [`E203_XLEN/8-1:0]      sysmem_icb_cmd_wmask,
  //
  //    * Bus RSP channel
  input                          sysmem_icb_rsp_valid,
  output                         sysmem_icb_rsp_ready,
  input                          sysmem_icb_rsp_err  ,
  input  [`E203_XLEN-1:0]        sysmem_icb_rsp_rdata,
  `endif//}

  input  test_mode,

  input  ls_clk,

  input  corerst, // The original async reset
  input  hfclkrst, // The original async reset
  input  hfextclk,// The original clock from crystal
  output hfclk // The generated clock by HCLKGEN

  );

 wire [31:0] inspect_pc;
 wire inspect_mem_cmd_valid;
 wire inspect_mem_cmd_ready;
 wire inspect_mem_rsp_valid;
 wire inspect_mem_rsp_ready;
 wire inspect_core_clk;
 wire inspect_pll_clk;
 wire inspect_16m_clk;

 assign inspect_pc_29b = inspect_pc[29];

 wire  [32-1:0] gpioA_o_oval ;
 wire  [32-1:0] gpioA_o_oe   ;


  // The GPIO are reused for inspect mode, in which the GPIO
  //   is forced to be an output
 assign  io_pads_gpioA_o_oe[0]      = inspect_mode ? 1'b1          : gpioA_o_oe[0];
 assign  io_pads_gpioA_o_oe[1]      = inspect_mode ? 1'b1          : gpioA_o_oe[1];
 assign  io_pads_gpioA_o_oe[2]      = inspect_mode ? 1'b1          : gpioA_o_oe[2];
 assign  io_pads_gpioA_o_oe[3]      = inspect_mode ? 1'b1          : gpioA_o_oe[3];
 assign  io_pads_gpioA_o_oe[4]      = inspect_mode ? 1'b1          : gpioA_o_oe[4];
 assign  io_pads_gpioA_o_oe[5]      = inspect_mode ? 1'b1          : gpioA_o_oe[5];
 assign  io_pads_gpioA_o_oe[6]      = inspect_mode ? 1'b1          : gpioA_o_oe[6];
 assign  io_pads_gpioA_o_oe[7]      = inspect_mode ? 1'b1          : gpioA_o_oe[7];
 assign  io_pads_gpioA_o_oe[8]      = inspect_mode ? 1'b1          : gpioA_o_oe[8];
 assign  io_pads_gpioA_o_oe[9]      = inspect_mode ? 1'b1          : gpioA_o_oe[9];
 assign  io_pads_gpioA_o_oe[10]     = inspect_mode ? 1'b1          : gpioA_o_oe[10];
 assign  io_pads_gpioA_o_oe[11]     = inspect_mode ? 1'b1          : gpioA_o_oe[11];
 assign  io_pads_gpioA_o_oe[12]     = inspect_mode ? 1'b1          : gpioA_o_oe[12];
 assign  io_pads_gpioA_o_oe[13]     = inspect_mode ? 1'b1          : gpioA_o_oe[13];
 assign  io_pads_gpioA_o_oe[14]     = inspect_mode ? 1'b1          : gpioA_o_oe[14];
 assign  io_pads_gpioA_o_oe[15]     = inspect_mode ? 1'b1          : gpioA_o_oe[15];
 assign  io_pads_gpioA_o_oe[16]     = inspect_mode ? 1'b1          : gpioA_o_oe[16];
 assign  io_pads_gpioA_o_oe[17]     = inspect_mode ? 1'b1          : gpioA_o_oe[17];
 assign  io_pads_gpioA_o_oe[18]     = inspect_mode ? 1'b1          : gpioA_o_oe[18];
 assign  io_pads_gpioA_o_oe[19]     = inspect_mode ? 1'b1          : gpioA_o_oe[19];
 assign  io_pads_gpioA_o_oe[20]     = inspect_mode ? 1'b1          : gpioA_o_oe[20];
 assign  io_pads_gpioA_o_oe[21]     = inspect_mode ? 1'b1          : gpioA_o_oe[21];
 assign  io_pads_gpioA_o_oe[22]     = inspect_mode ? 1'b1          : gpioA_o_oe[22];
 assign  io_pads_gpioA_o_oe[23]     = inspect_mode ? 1'b1          : gpioA_o_oe[23];
 assign  io_pads_gpioA_o_oe[24]     = inspect_mode ? 1'b1          : gpioA_o_oe[24];
 assign  io_pads_gpioA_o_oe[25]     = inspect_mode ? 1'b1          : gpioA_o_oe[25];
 assign  io_pads_gpioA_o_oe[26]     = inspect_mode ? 1'b1          : gpioA_o_oe[26];
 assign  io_pads_gpioA_o_oe[27]     = inspect_mode ? 1'b1          : gpioA_o_oe[27];
 assign  io_pads_gpioA_o_oe[28]     = inspect_mode ? 1'b1          : gpioA_o_oe[28];
 assign  io_pads_gpioA_o_oe[29]     = inspect_mode ? 1'b1          : gpioA_o_oe[29];
 assign  io_pads_gpioA_o_oe[30]     = inspect_mode ? 1'b1          : gpioA_o_oe[30];
 assign  io_pads_gpioA_o_oe[31]     = inspect_mode ? 1'b1          : gpioA_o_oe[31];
 
  
 assign  io_pads_gpioA_o_oval[0]    = inspect_mode ? inspect_pc[0]         : gpioA_o_oval[0];
 assign  io_pads_gpioA_o_oval[1]    = inspect_mode ? inspect_pc[1]         : gpioA_o_oval[1];
 assign  io_pads_gpioA_o_oval[2]    = inspect_mode ? inspect_pc[2]         : gpioA_o_oval[2];
 assign  io_pads_gpioA_o_oval[3]    = inspect_mode ? inspect_pc[3]         : gpioA_o_oval[3];
 assign  io_pads_gpioA_o_oval[4]    = inspect_mode ? inspect_pc[4]         : gpioA_o_oval[4];
 assign  io_pads_gpioA_o_oval[5]    = inspect_mode ? inspect_pc[5]         : gpioA_o_oval[5];
 assign  io_pads_gpioA_o_oval[6]    = inspect_mode ? inspect_pc[6]         : gpioA_o_oval[6];
 assign  io_pads_gpioA_o_oval[7]    = inspect_mode ? inspect_pc[7]         : gpioA_o_oval[7];
 assign  io_pads_gpioA_o_oval[8]    = inspect_mode ? inspect_pc[8]         : gpioA_o_oval[8];
 assign  io_pads_gpioA_o_oval[9]    = inspect_mode ? inspect_pc[9]         : gpioA_o_oval[9];
 assign  io_pads_gpioA_o_oval[10]   = inspect_mode ? inspect_pc[10]        : gpioA_o_oval[10];
 assign  io_pads_gpioA_o_oval[11]   = inspect_mode ? inspect_pc[11]        : gpioA_o_oval[11];
 assign  io_pads_gpioA_o_oval[12]   = inspect_mode ? inspect_pc[12]        : gpioA_o_oval[12];
 assign  io_pads_gpioA_o_oval[13]   = inspect_mode ? inspect_pc[13]        : gpioA_o_oval[13];
 assign  io_pads_gpioA_o_oval[14]   = inspect_mode ? inspect_pc[14]        : gpioA_o_oval[14];
 assign  io_pads_gpioA_o_oval[15]   = inspect_mode ? inspect_pc[15]        : gpioA_o_oval[15];
 assign  io_pads_gpioA_o_oval[16]   = inspect_mode ? inspect_pc[16]        : gpioA_o_oval[16];
 assign  io_pads_gpioA_o_oval[17]   = inspect_mode ? inspect_pc[17]        : gpioA_o_oval[17];
 assign  io_pads_gpioA_o_oval[18]   = inspect_mode ? inspect_pc[18]        : gpioA_o_oval[18];
 assign  io_pads_gpioA_o_oval[19]   = inspect_mode ? inspect_pc[19]        : gpioA_o_oval[19];
 assign  io_pads_gpioA_o_oval[20]   = inspect_mode ? inspect_pc[20]        : gpioA_o_oval[20];
 assign  io_pads_gpioA_o_oval[21]   = inspect_mode ? inspect_pc[21]        : gpioA_o_oval[21];
 assign  io_pads_gpioA_o_oval[22]   = inspect_mode ? inspect_mem_cmd_valid : gpioA_o_oval[22];
 assign  io_pads_gpioA_o_oval[23]   = inspect_mode ? inspect_mem_cmd_ready : gpioA_o_oval[23];
 assign  io_pads_gpioA_o_oval[24]   = inspect_mode ? inspect_mem_rsp_valid : gpioA_o_oval[24];
 assign  io_pads_gpioA_o_oval[25]   = inspect_mode ? inspect_mem_rsp_ready : gpioA_o_oval[25];
 assign  io_pads_gpioA_o_oval[26]   = inspect_mode ? inspect_jtag_clk      : gpioA_o_oval[26];
 assign  io_pads_gpioA_o_oval[27]   = inspect_mode ? inspect_core_clk      : gpioA_o_oval[27];
 assign  io_pads_gpioA_o_oval[28]   = inspect_mode ? inspect_por_rst       : gpioA_o_oval[28];
 assign  io_pads_gpioA_o_oval[29]   = inspect_mode ? inspect_32k_clk       : gpioA_o_oval[29];
 assign  io_pads_gpioA_o_oval[30]   = inspect_mode ? inspect_16m_clk       : gpioA_o_oval[30];
 assign  io_pads_gpioA_o_oval[31]   = inspect_mode ? inspect_pll_clk       : gpioA_o_oval[31];

  
  //This is to reset the main domain
  wire main_rst;
 sirv_ResetCatchAndSync_2 u_main_ResetCatchAndSync_2_1 (
    .test_mode(test_mode),
    .clock(hfclk),
    .reset(corerst),
    .io_sync_reset(main_rst)
  );

  wire main_rst_n = ~main_rst;

  wire pllbypass ;
  wire pll_RESET ;
  wire pll_ASLEEP ;
  wire [1:0]  pll_OD;
  wire [7:0]  pll_M;
  wire [4:0]  pll_N;
  wire plloutdivby1;
  wire [5:0] plloutdiv;

  e203_subsys_hclkgen u_e203_subsys_hclkgen(
    .test_mode   (test_mode),
    .hfclkrst    (hfclkrst ),
    .hfextclk    (hfextclk    ),
                 
    .pllbypass   (pllbypass   ),
    .pll_RESET   (pll_RESET   ),
    .pll_ASLEEP  (pll_ASLEEP   ),
    .pll_OD      (pll_OD),
    .pll_M       (pll_M ),
    .pll_N       (pll_N ),
    .plloutdivby1(plloutdivby1),
    .plloutdiv   (plloutdiv   ), 

    .inspect_pll_clk(inspect_pll_clk),
    .inspect_16m_clk(inspect_16m_clk),
                
    .hfclk       (hfclk       ) // The generated clock by this module
  );


  wire  tcm_ds = 1'b0;// Currently we dont support it
  wire  tcm_sd = 1'b0;// Currently we dont support it

`ifndef E203_HAS_LOCKSTEP//{
  wire core_rst_n = main_rst_n;
  wire bus_rst_n  = main_rst_n;
  wire per_rst_n  = main_rst_n;
`endif//}





  wire                         ppi_icb_cmd_valid;
  wire                         ppi_icb_cmd_ready;
  wire [`E203_ADDR_SIZE-1:0]   ppi_icb_cmd_addr; 
  wire                         ppi_icb_cmd_read; 
  wire [`E203_XLEN-1:0]        ppi_icb_cmd_wdata;
  wire [`E203_XLEN/8-1:0]      ppi_icb_cmd_wmask;

  wire                         ppi_icb_rsp_valid;
  wire                         ppi_icb_rsp_ready;
  wire                         ppi_icb_rsp_err  ;
  wire [`E203_XLEN-1:0]        ppi_icb_rsp_rdata;

  
  wire                         clint_icb_cmd_valid;
  wire                         clint_icb_cmd_ready;
  wire [`E203_ADDR_SIZE-1:0]   clint_icb_cmd_addr; 
  wire                         clint_icb_cmd_read; 
  wire [`E203_XLEN-1:0]        clint_icb_cmd_wdata;
  wire [`E203_XLEN/8-1:0]      clint_icb_cmd_wmask;

  wire                         clint_icb_rsp_valid;
  wire                         clint_icb_rsp_ready;
  wire                         clint_icb_rsp_err  ;
  wire [`E203_XLEN-1:0]        clint_icb_rsp_rdata;

  
  wire                         plic_icb_cmd_valid;
  wire                         plic_icb_cmd_ready;
  wire [`E203_ADDR_SIZE-1:0]   plic_icb_cmd_addr; 
  wire                         plic_icb_cmd_read; 
  wire [`E203_XLEN-1:0]        plic_icb_cmd_wdata;
  wire [`E203_XLEN/8-1:0]      plic_icb_cmd_wmask;

  wire                         plic_icb_rsp_valid;
  wire                         plic_icb_rsp_ready;
  wire                         plic_icb_rsp_err  ;
  wire [`E203_XLEN-1:0]        plic_icb_rsp_rdata;

  `ifdef E203_HAS_FIO //{
  wire                         fio_icb_cmd_valid;
  wire                         fio_icb_cmd_ready;
  wire [`E203_ADDR_SIZE-1:0]   fio_icb_cmd_addr; 
  wire                         fio_icb_cmd_read; 
  wire [`E203_XLEN-1:0]        fio_icb_cmd_wdata;
  wire [`E203_XLEN/8-1:0]      fio_icb_cmd_wmask;

  wire                         fio_icb_rsp_valid;
  wire                         fio_icb_rsp_ready;
  wire                         fio_icb_rsp_err  ;
  wire [`E203_XLEN-1:0]        fio_icb_rsp_rdata;

  assign sysfio_icb_cmd_valid = fio_icb_cmd_valid;
  assign fio_icb_cmd_ready    = sysfio_icb_cmd_ready;
  assign sysfio_icb_cmd_addr  = fio_icb_cmd_addr ; 
  assign sysfio_icb_cmd_read  = fio_icb_cmd_read ; 
  assign sysfio_icb_cmd_wdata = fio_icb_cmd_wdata;
  assign sysfio_icb_cmd_wmask = fio_icb_cmd_wmask;
                           
  assign fio_icb_rsp_valid    = sysfio_icb_rsp_valid;
  assign sysfio_icb_rsp_ready = fio_icb_rsp_ready;
  assign fio_icb_rsp_err      = sysfio_icb_rsp_err  ;
  assign fio_icb_rsp_rdata    = sysfio_icb_rsp_rdata;
  `endif//}

  wire                         mem_icb_cmd_valid;
  wire                         mem_icb_cmd_ready;
  wire [`E203_ADDR_SIZE-1:0]   mem_icb_cmd_addr; 
  wire                         mem_icb_cmd_read; 
  wire [`E203_XLEN-1:0]        mem_icb_cmd_wdata;
  wire [`E203_XLEN/8-1:0]      mem_icb_cmd_wmask;
  
  wire                         mem_icb_rsp_valid;
  wire                         mem_icb_rsp_ready;
  wire                         mem_icb_rsp_err  ;
  wire [`E203_XLEN-1:0]        mem_icb_rsp_rdata;

  wire  plic_ext_irq;
  wire  clint_sft_irq;
  wire  clint_tmr_irq;

  wire tm_stop;


  wire core_wfi;



  e203_cpu_top u_e203_cpu_top(

  .inspect_pc               (inspect_pc), 
  .inspect_dbg_irq          (inspect_dbg_irq      ),
  .inspect_mem_cmd_valid    (inspect_mem_cmd_valid), 
  .inspect_mem_cmd_ready    (inspect_mem_cmd_ready), 
  .inspect_mem_rsp_valid    (inspect_mem_rsp_valid),
  .inspect_mem_rsp_ready    (inspect_mem_rsp_ready),
  .inspect_core_clk         (inspect_core_clk),

  .core_csr_clk          (core_csr_clk      ),


        
        

    .tm_stop         (tm_stop),
    .pc_rtvec        (pc_rtvec),

    .tcm_sd          (tcm_sd),
    .tcm_ds          (tcm_ds),
    
    .core_wfi        (core_wfi),

    .dbg_irq_r       (dbg_irq_r      ),

    .cmt_dpc         (cmt_dpc        ),
    .cmt_dpc_ena     (cmt_dpc_ena    ),
    .cmt_dcause      (cmt_dcause     ),
    .cmt_dcause_ena  (cmt_dcause_ena ),

    .wr_dcsr_ena     (wr_dcsr_ena    ),
    .wr_dpc_ena      (wr_dpc_ena     ),
    .wr_dscratch_ena (wr_dscratch_ena),



                                     
    .wr_csr_nxt      (wr_csr_nxt    ),
                                     
    .dcsr_r          (dcsr_r         ),
    .dpc_r           (dpc_r          ),
    .dscratch_r      (dscratch_r     ),

    .dbg_mode        (dbg_mode),
    .dbg_halt_r      (dbg_halt_r),
    .dbg_step_r      (dbg_step_r),
    .dbg_ebreakm_r   (dbg_ebreakm_r),
    .dbg_stopcycle   (dbg_stopcycle),

    .core_mhartid            (core_mhartid),  
    .dbg_irq_a               (dbg_irq_a),
    .ext_irq_a               (plic_ext_irq),
    .sft_irq_a               (clint_sft_irq),
    .tmr_irq_a               (clint_tmr_irq),

  `ifdef E203_HAS_ITCM_EXTITF //{
    .ext2itcm_icb_cmd_valid  (ext2itcm_icb_cmd_valid),
    .ext2itcm_icb_cmd_ready  (ext2itcm_icb_cmd_ready),
    .ext2itcm_icb_cmd_addr   (ext2itcm_icb_cmd_addr ),
    .ext2itcm_icb_cmd_read   (ext2itcm_icb_cmd_read ),
    .ext2itcm_icb_cmd_wdata  (ext2itcm_icb_cmd_wdata),
    .ext2itcm_icb_cmd_wmask  (ext2itcm_icb_cmd_wmask),
    
    .ext2itcm_icb_rsp_valid  (ext2itcm_icb_rsp_valid),
    .ext2itcm_icb_rsp_ready  (ext2itcm_icb_rsp_ready),
    .ext2itcm_icb_rsp_err    (ext2itcm_icb_rsp_err  ),
    .ext2itcm_icb_rsp_rdata  (ext2itcm_icb_rsp_rdata),
  `endif//}

  `ifdef E203_HAS_DTCM_EXTITF //{
    .ext2dtcm_icb_cmd_valid  (ext2dtcm_icb_cmd_valid),
    .ext2dtcm_icb_cmd_ready  (ext2dtcm_icb_cmd_ready),
    .ext2dtcm_icb_cmd_addr   (ext2dtcm_icb_cmd_addr ),
    .ext2dtcm_icb_cmd_read   (ext2dtcm_icb_cmd_read ),
    .ext2dtcm_icb_cmd_wdata  (ext2dtcm_icb_cmd_wdata),
    .ext2dtcm_icb_cmd_wmask  (ext2dtcm_icb_cmd_wmask),
    
    .ext2dtcm_icb_rsp_valid  (ext2dtcm_icb_rsp_valid),
    .ext2dtcm_icb_rsp_ready  (ext2dtcm_icb_rsp_ready),
    .ext2dtcm_icb_rsp_err    (ext2dtcm_icb_rsp_err  ),
    .ext2dtcm_icb_rsp_rdata  (ext2dtcm_icb_rsp_rdata),
  `endif//}


    .ppi_icb_cmd_valid     (ppi_icb_cmd_valid),
    .ppi_icb_cmd_ready     (ppi_icb_cmd_ready),
    .ppi_icb_cmd_addr      (ppi_icb_cmd_addr ),
    .ppi_icb_cmd_read      (ppi_icb_cmd_read ),
    .ppi_icb_cmd_wdata     (ppi_icb_cmd_wdata),
    .ppi_icb_cmd_wmask     (ppi_icb_cmd_wmask),
    
    .ppi_icb_rsp_valid     (ppi_icb_rsp_valid),
    .ppi_icb_rsp_ready     (ppi_icb_rsp_ready),
    .ppi_icb_rsp_err       (ppi_icb_rsp_err  ),
    .ppi_icb_rsp_rdata     (ppi_icb_rsp_rdata),

    .plic_icb_cmd_valid     (plic_icb_cmd_valid),
    .plic_icb_cmd_ready     (plic_icb_cmd_ready),
    .plic_icb_cmd_addr      (plic_icb_cmd_addr ),
    .plic_icb_cmd_read      (plic_icb_cmd_read ),
    .plic_icb_cmd_wdata     (plic_icb_cmd_wdata),
    .plic_icb_cmd_wmask     (plic_icb_cmd_wmask),
    
    .plic_icb_rsp_valid     (plic_icb_rsp_valid),
    .plic_icb_rsp_ready     (plic_icb_rsp_ready),
    .plic_icb_rsp_err       (plic_icb_rsp_err  ),
    .plic_icb_rsp_rdata     (plic_icb_rsp_rdata),

    .clint_icb_cmd_valid     (clint_icb_cmd_valid),
    .clint_icb_cmd_ready     (clint_icb_cmd_ready),
    .clint_icb_cmd_addr      (clint_icb_cmd_addr ),
    .clint_icb_cmd_read      (clint_icb_cmd_read ),
    .clint_icb_cmd_wdata     (clint_icb_cmd_wdata),
    .clint_icb_cmd_wmask     (clint_icb_cmd_wmask),
    
    .clint_icb_rsp_valid     (clint_icb_rsp_valid),
    .clint_icb_rsp_ready     (clint_icb_rsp_ready),
    .clint_icb_rsp_err       (clint_icb_rsp_err  ),
    .clint_icb_rsp_rdata     (clint_icb_rsp_rdata),

    .fio_icb_cmd_valid     (fio_icb_cmd_valid),
    .fio_icb_cmd_ready     (fio_icb_cmd_ready),
    .fio_icb_cmd_addr      (fio_icb_cmd_addr ),
    .fio_icb_cmd_read      (fio_icb_cmd_read ),
    .fio_icb_cmd_wdata     (fio_icb_cmd_wdata),
    .fio_icb_cmd_wmask     (fio_icb_cmd_wmask),
    
    .fio_icb_rsp_valid     (fio_icb_rsp_valid),
    .fio_icb_rsp_ready     (fio_icb_rsp_ready),
    .fio_icb_rsp_err       (fio_icb_rsp_err  ),
    .fio_icb_rsp_rdata     (fio_icb_rsp_rdata),

    .mem_icb_cmd_valid  (mem_icb_cmd_valid),
    .mem_icb_cmd_ready  (mem_icb_cmd_ready),
    .mem_icb_cmd_addr   (mem_icb_cmd_addr ),
    .mem_icb_cmd_read   (mem_icb_cmd_read ),
    .mem_icb_cmd_wdata  (mem_icb_cmd_wdata),
    .mem_icb_cmd_wmask  (mem_icb_cmd_wmask),
    
    .mem_icb_rsp_valid  (mem_icb_rsp_valid),
    .mem_icb_rsp_ready  (mem_icb_rsp_ready),
    .mem_icb_rsp_err    (mem_icb_rsp_err  ),
    .mem_icb_rsp_rdata  (mem_icb_rsp_rdata),

    .test_mode     (test_mode), 
    .clk           (hfclk  ),
    .rst_n         (core_rst_n) 
  );

  wire  qspi0_irq; 
  wire  qspi1_irq;
  wire  qspi2_irq;

  wire  uart0_irq;                
  wire  uart1_irq;                
  wire  uart2_irq;                

  wire  pwm_irq_0;
  wire  pwm_irq_1;
  wire  pwm_irq_2;
  wire  pwm_irq_3;

  wire  i2c0_mst_irq;
  wire  i2c1_mst_irq;

  wire  gpioA_irq;
  wire  gpioB_irq;


 e203_subsys_plic u_e203_subsys_plic(
    .plic_icb_cmd_valid     (plic_icb_cmd_valid),
    .plic_icb_cmd_ready     (plic_icb_cmd_ready),
    .plic_icb_cmd_addr      (plic_icb_cmd_addr ),
    .plic_icb_cmd_read      (plic_icb_cmd_read ),
    .plic_icb_cmd_wdata     (plic_icb_cmd_wdata),
    .plic_icb_cmd_wmask     (plic_icb_cmd_wmask),
    
    .plic_icb_rsp_valid     (plic_icb_rsp_valid),
    .plic_icb_rsp_ready     (plic_icb_rsp_ready),
    .plic_icb_rsp_err       (plic_icb_rsp_err  ),
    .plic_icb_rsp_rdata     (plic_icb_rsp_rdata),

    .plic_ext_irq           (plic_ext_irq),

    .wdg_irq_a              (aon_wdg_irq_a),
    .rtc_irq_a              (aon_rtc_irq_a),

    .qspi0_irq              (qspi0_irq ), 
    .qspi1_irq              (qspi1_irq ),
    .qspi2_irq              (qspi2_irq ),
                                       
    .uart0_irq              (uart0_irq ),                
    .uart1_irq              (uart1_irq ),                
    .uart2_irq              (uart2_irq ),                
                                        
    .pwm_irq_0              (pwm_irq_0 ),
    .pwm_irq_1              (pwm_irq_1 ),
    .pwm_irq_2              (pwm_irq_2 ),
    .pwm_irq_3              (pwm_irq_3 ),
                                        
    .i2c0_mst_irq           (i2c0_mst_irq),
    .i2c1_mst_irq           (i2c1_mst_irq),

    .gpioA_irq              (gpioA_irq ),
    .gpioB_irq              (gpioB_irq ),

    .clk                    (hfclk  ),
    .rst_n                  (per_rst_n) 
  );

e203_subsys_clint u_e203_subsys_clint(
    .tm_stop                 (tm_stop),

    .clint_icb_cmd_valid     (clint_icb_cmd_valid),
    .clint_icb_cmd_ready     (clint_icb_cmd_ready),
    .clint_icb_cmd_addr      (clint_icb_cmd_addr ),
    .clint_icb_cmd_read      (clint_icb_cmd_read ),
    .clint_icb_cmd_wdata     (clint_icb_cmd_wdata),
    .clint_icb_cmd_wmask     (clint_icb_cmd_wmask),
    
    .clint_icb_rsp_valid     (clint_icb_rsp_valid),
    .clint_icb_rsp_ready     (clint_icb_rsp_ready),
    .clint_icb_rsp_err       (clint_icb_rsp_err  ),
    .clint_icb_rsp_rdata     (clint_icb_rsp_rdata),

    .clint_tmr_irq           (clint_tmr_irq),
    .clint_sft_irq           (clint_sft_irq),

    .aon_rtcToggle_a         (aon_rtcToggle_a),

    .clk           (hfclk  ),
    .rst_n         (per_rst_n) 
  );

  
  wire                     qspi0_ro_icb_cmd_valid;
  wire                     qspi0_ro_icb_cmd_ready;
  wire [32-1:0]            qspi0_ro_icb_cmd_addr; 
  wire                     qspi0_ro_icb_cmd_read; 
  wire [32-1:0]            qspi0_ro_icb_cmd_wdata;
  
  wire                     qspi0_ro_icb_rsp_valid;
  wire                     qspi0_ro_icb_rsp_ready;
  wire [32-1:0]            qspi0_ro_icb_rsp_rdata;

  
  e203_subsys_perips u_e203_subsys_perips (
    .pllbypass   (pllbypass   ),
    .pll_RESET   (pll_RESET   ),
    .pll_ASLEEP  (pll_ASLEEP  ),
    .pll_OD(pll_OD),
    .pll_M (pll_M ),
    .pll_N (pll_N ),
    .plloutdivby1(plloutdivby1),
    .plloutdiv   (plloutdiv   ), 

    .hfxoscen    (hfxoscen),
    .ppi_icb_cmd_valid     (ppi_icb_cmd_valid),
    .ppi_icb_cmd_ready     (ppi_icb_cmd_ready),
    .ppi_icb_cmd_addr      (ppi_icb_cmd_addr ),
    .ppi_icb_cmd_read      (ppi_icb_cmd_read ),
    .ppi_icb_cmd_wdata     (ppi_icb_cmd_wdata),
    .ppi_icb_cmd_wmask     (ppi_icb_cmd_wmask),
    
    .ppi_icb_rsp_valid     (ppi_icb_rsp_valid),
    .ppi_icb_rsp_ready     (ppi_icb_rsp_ready),
    .ppi_icb_rsp_err       (ppi_icb_rsp_err  ),
    .ppi_icb_rsp_rdata     (ppi_icb_rsp_rdata),

  
    .sysper_icb_cmd_valid  (sysper_icb_cmd_valid),
    .sysper_icb_cmd_ready  (sysper_icb_cmd_ready),
    .sysper_icb_cmd_addr   (sysper_icb_cmd_addr ), 
    .sysper_icb_cmd_read   (sysper_icb_cmd_read ), 
    .sysper_icb_cmd_wdata  (sysper_icb_cmd_wdata),
    .sysper_icb_cmd_wmask  (sysper_icb_cmd_wmask),
                                                
    .sysper_icb_rsp_valid  (sysper_icb_rsp_valid),
    .sysper_icb_rsp_ready  (sysper_icb_rsp_ready),
    .sysper_icb_rsp_err    (sysper_icb_rsp_err  ),
    .sysper_icb_rsp_rdata  (sysper_icb_rsp_rdata),

    .aon_icb_cmd_valid     (aon_icb_cmd_valid),
    .aon_icb_cmd_ready     (aon_icb_cmd_ready),
    .aon_icb_cmd_addr      (aon_icb_cmd_addr ), 
    .aon_icb_cmd_read      (aon_icb_cmd_read ), 
    .aon_icb_cmd_wdata     (aon_icb_cmd_wdata),
                                             
    .aon_icb_rsp_valid     (aon_icb_rsp_valid),
    .aon_icb_rsp_ready     (aon_icb_rsp_ready),
    .aon_icb_rsp_err       (aon_icb_rsp_err  ),
    .aon_icb_rsp_rdata     (aon_icb_rsp_rdata),

`ifdef FAKE_FLASH_MODEL//{
    .qspi0_ro_icb_cmd_valid  (1'b0), 
    .qspi0_ro_icb_cmd_ready  (),
    .qspi0_ro_icb_cmd_addr   (32'b0 ),
    .qspi0_ro_icb_cmd_read   (1'b0 ),
    .qspi0_ro_icb_cmd_wdata  (32'b0),
                             
    .qspi0_ro_icb_rsp_valid  (),
    .qspi0_ro_icb_rsp_ready  (1'b0),
    .qspi0_ro_icb_rsp_rdata  (),
`else//}{
    .qspi0_ro_icb_cmd_valid  (qspi0_ro_icb_cmd_valid), 
    .qspi0_ro_icb_cmd_ready  (qspi0_ro_icb_cmd_ready),
    .qspi0_ro_icb_cmd_addr   (qspi0_ro_icb_cmd_addr ),
    .qspi0_ro_icb_cmd_read   (qspi0_ro_icb_cmd_read ),
    .qspi0_ro_icb_cmd_wdata  (qspi0_ro_icb_cmd_wdata),
                             
    .qspi0_ro_icb_rsp_valid  (qspi0_ro_icb_rsp_valid),
    .qspi0_ro_icb_rsp_ready  (qspi0_ro_icb_rsp_ready),
    .qspi0_ro_icb_rsp_rdata  (qspi0_ro_icb_rsp_rdata),
`endif//}
                           

    .io_pads_gpioA_i_ival        (io_pads_gpioA_i_ival),
    .io_pads_gpioA_o_oval        (gpioA_o_oval),
    .io_pads_gpioA_o_oe          (gpioA_o_oe),

    .io_pads_gpioB_i_ival        (io_pads_gpioB_i_ival),
    .io_pads_gpioB_o_oval        (io_pads_gpioB_o_oval),
    .io_pads_gpioB_o_oe          (io_pads_gpioB_o_oe),

    .io_pads_qspi0_sck_i_ival    (io_pads_qspi0_sck_i_ival    ),
    .io_pads_qspi0_sck_o_oval    (io_pads_qspi0_sck_o_oval    ),
    .io_pads_qspi0_sck_o_oe      (io_pads_qspi0_sck_o_oe      ),
    .io_pads_qspi0_dq_0_i_ival   (io_pads_qspi0_dq_0_i_ival   ),
    .io_pads_qspi0_dq_0_o_oval   (io_pads_qspi0_dq_0_o_oval   ),
    .io_pads_qspi0_dq_0_o_oe     (io_pads_qspi0_dq_0_o_oe     ),
    .io_pads_qspi0_dq_1_i_ival   (io_pads_qspi0_dq_1_i_ival   ),
    .io_pads_qspi0_dq_1_o_oval   (io_pads_qspi0_dq_1_o_oval   ),
    .io_pads_qspi0_dq_1_o_oe     (io_pads_qspi0_dq_1_o_oe     ),
    .io_pads_qspi0_dq_2_i_ival   (io_pads_qspi0_dq_2_i_ival   ),
    .io_pads_qspi0_dq_2_o_oval   (io_pads_qspi0_dq_2_o_oval   ),
    .io_pads_qspi0_dq_2_o_oe     (io_pads_qspi0_dq_2_o_oe     ),
    .io_pads_qspi0_dq_3_i_ival   (io_pads_qspi0_dq_3_i_ival   ),
    .io_pads_qspi0_dq_3_o_oval   (io_pads_qspi0_dq_3_o_oval   ),
    .io_pads_qspi0_dq_3_o_oe     (io_pads_qspi0_dq_3_o_oe     ),
    .io_pads_qspi0_cs_0_i_ival   (io_pads_qspi0_cs_0_i_ival   ),
    .io_pads_qspi0_cs_0_o_oval   (io_pads_qspi0_cs_0_o_oval   ),
    .io_pads_qspi0_cs_0_o_oe     (io_pads_qspi0_cs_0_o_oe     ),

    .qspi0_irq              (qspi0_irq  ), 
    .qspi1_irq              (qspi1_irq  ),
    .qspi2_irq              (qspi2_irq  ),
                                        
    .uart0_irq              (uart0_irq  ),                
    .uart1_irq              (uart1_irq  ),                
    .uart2_irq              (uart2_irq  ),                
                                        
    .pwm_irq_0              (pwm_irq_0 ),
    .pwm_irq_1              (pwm_irq_1 ),
    .pwm_irq_2              (pwm_irq_2 ),
    .pwm_irq_3              (pwm_irq_3 ),
                                        
    .i2c0_mst_irq           (i2c0_mst_irq),
    .i2c1_mst_irq           (i2c1_mst_irq),

    .gpioA_irq              (gpioA_irq ),
    .gpioB_irq              (gpioB_irq ),

    .ls_clk        (ls_clk  ),
    .clk           (hfclk  ),
    .bus_rst_n     (bus_rst_n), 
    .rst_n         (per_rst_n) 
  );

e203_subsys_mems u_e203_subsys_mems(

    .mem_icb_cmd_valid  (mem_icb_cmd_valid),
    .mem_icb_cmd_ready  (mem_icb_cmd_ready),
    .mem_icb_cmd_addr   (mem_icb_cmd_addr ),
    .mem_icb_cmd_read   (mem_icb_cmd_read ),
    .mem_icb_cmd_wdata  (mem_icb_cmd_wdata),
    .mem_icb_cmd_wmask  (mem_icb_cmd_wmask),
    
    .mem_icb_rsp_valid  (mem_icb_rsp_valid),
    .mem_icb_rsp_ready  (mem_icb_rsp_ready),
    .mem_icb_rsp_err    (mem_icb_rsp_err  ),
    .mem_icb_rsp_rdata  (mem_icb_rsp_rdata),

    .sysmem_icb_cmd_valid  (sysmem_icb_cmd_valid),
    .sysmem_icb_cmd_ready  (sysmem_icb_cmd_ready),
    .sysmem_icb_cmd_addr   (sysmem_icb_cmd_addr ),
    .sysmem_icb_cmd_read   (sysmem_icb_cmd_read ),
    .sysmem_icb_cmd_wdata  (sysmem_icb_cmd_wdata),
    .sysmem_icb_cmd_wmask  (sysmem_icb_cmd_wmask),
    
    .sysmem_icb_rsp_valid  (sysmem_icb_rsp_valid),
    .sysmem_icb_rsp_ready  (sysmem_icb_rsp_ready),
    .sysmem_icb_rsp_err    (sysmem_icb_rsp_err  ),
    .sysmem_icb_rsp_rdata  (sysmem_icb_rsp_rdata),
 
    .qspi0_ro_icb_cmd_valid  (qspi0_ro_icb_cmd_valid), 
    .qspi0_ro_icb_cmd_ready  (qspi0_ro_icb_cmd_ready),
    .qspi0_ro_icb_cmd_addr   (qspi0_ro_icb_cmd_addr ),
    .qspi0_ro_icb_cmd_read   (qspi0_ro_icb_cmd_read ),
    .qspi0_ro_icb_cmd_wdata  (qspi0_ro_icb_cmd_wdata),
                             
    .qspi0_ro_icb_rsp_valid  (qspi0_ro_icb_rsp_valid),
    .qspi0_ro_icb_rsp_ready  (qspi0_ro_icb_rsp_ready),
    .qspi0_ro_icb_rsp_err    (1'b0  ),
    .qspi0_ro_icb_rsp_rdata  (qspi0_ro_icb_rsp_rdata),
                           
    .dm_icb_cmd_valid    (dm_icb_cmd_valid  ),
    .dm_icb_cmd_ready    (dm_icb_cmd_ready  ),
    .dm_icb_cmd_addr     (dm_icb_cmd_addr   ),
    .dm_icb_cmd_read     (dm_icb_cmd_read   ),
    .dm_icb_cmd_wdata    (dm_icb_cmd_wdata  ),
     
    .dm_icb_rsp_valid    (dm_icb_rsp_valid  ),
    .dm_icb_rsp_ready    (dm_icb_rsp_ready  ),
    .dm_icb_rsp_rdata    (dm_icb_rsp_rdata  ),

    .clk           (hfclk  ),
    .bus_rst_n     (bus_rst_n), 
    .rst_n         (per_rst_n) 
  );



`ifdef FAKE_FLASH_MODEL//{
fake_qspi0_model_top u_fake_qspi0_model_top(
    .icb_cmd_valid  (qspi0_ro_icb_cmd_valid), 
    .icb_cmd_ready  (qspi0_ro_icb_cmd_ready),
    .icb_cmd_addr   (qspi0_ro_icb_cmd_addr ),
    .icb_cmd_read   (qspi0_ro_icb_cmd_read ),
    .icb_cmd_wdata  (qspi0_ro_icb_cmd_wdata),
                    
    .icb_rsp_valid  (qspi0_ro_icb_rsp_valid),
    .icb_rsp_ready  (qspi0_ro_icb_rsp_ready),
    .icb_rsp_rdata  (qspi0_ro_icb_rsp_rdata),

    .clk            (hfclk    ),
    .rst_n          (bus_rst_n)  
  );
`endif//}


endmodule
