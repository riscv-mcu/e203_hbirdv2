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
// Designer   : Bob Hu
//
// Description:
//  The wrapper with some glue logics for PLIC 
//
// ====================================================================


`include "e203_defines.v"


module e203_subsys_plic(
  input                          plic_icb_cmd_valid,
  output                         plic_icb_cmd_ready,
  input  [`E203_ADDR_SIZE-1:0]   plic_icb_cmd_addr, 
  input                          plic_icb_cmd_read, 
  input  [`E203_XLEN-1:0]        plic_icb_cmd_wdata,
  input  [`E203_XLEN/8-1:0]      plic_icb_cmd_wmask,
  //
  output                         plic_icb_rsp_valid,
  input                          plic_icb_rsp_ready,
  output                         plic_icb_rsp_err,
  output [`E203_XLEN-1:0]        plic_icb_rsp_rdata,

  output plic_ext_irq,

  input  wdg_irq_a,
  input  rtc_irq_a,

  input  qspi0_irq, 
  input  qspi1_irq,
  input  qspi2_irq,

  input  uart0_irq,                
  input  uart1_irq,                
  input  uart2_irq,                

  input  pwm_irq_0,
  input  pwm_irq_1,
  input  pwm_irq_2,
  input  pwm_irq_3,

  input  i2c0_mst_irq,
  input  i2c1_mst_irq,

  input  gpioA_irq,
  input  gpioB_irq,

  input  clk,
  input  rst_n
  );

  assign plic_icb_rsp_err     = 1'b0;

  wire  wdg_irq_r;
  wire  rtc_irq_r;

  sirv_gnrl_sync # (
  .DP(`E203_ASYNC_FF_LEVELS),
  .DW(1)
  ) u_rtc_irq_sync(
      .din_a    (rtc_irq_a),
      .dout     (rtc_irq_r),
      .clk      (clk  ),
      .rst_n    (rst_n) 
  );

  sirv_gnrl_sync # (
  .DP(`E203_ASYNC_FF_LEVELS),
  .DW(1)
  ) u_wdg_irq_sync(
      .din_a    (wdg_irq_a),
      .dout     (wdg_irq_r),
      .clk      (clk  ),
      .rst_n    (rst_n) 
  );

  wire plic_irq_i_0  = wdg_irq_r;
  wire plic_irq_i_1  = rtc_irq_r;
  wire plic_irq_i_2  = uart0_irq;
  wire plic_irq_i_3  = uart1_irq;
  wire plic_irq_i_4  = uart2_irq;
  wire plic_irq_i_5  = qspi0_irq;
  wire plic_irq_i_6  = qspi1_irq;   
  wire plic_irq_i_7  = qspi2_irq;
  wire plic_irq_i_8  = pwm_irq_0;
  wire plic_irq_i_9  = pwm_irq_1;
  wire plic_irq_i_10 = pwm_irq_2;
  wire plic_irq_i_11 = pwm_irq_3;
  wire plic_irq_i_12 = i2c0_mst_irq;
  wire plic_irq_i_13 = i2c1_mst_irq;
  wire plic_irq_i_14 = gpioA_irq;
  wire plic_irq_i_15 = gpioB_irq; 

  sirv_plic_top u_sirv_plic_top(
    .clk             (clk   ),
    .rst_n           (rst_n ),
  
    .i_icb_cmd_valid (plic_icb_cmd_valid),
    .i_icb_cmd_ready (plic_icb_cmd_ready),
    .i_icb_cmd_addr  (plic_icb_cmd_addr ),
    .i_icb_cmd_read  (plic_icb_cmd_read ),
    .i_icb_cmd_wdata (plic_icb_cmd_wdata),
    
    .i_icb_rsp_valid (plic_icb_rsp_valid),
    .i_icb_rsp_ready (plic_icb_rsp_ready),
    .i_icb_rsp_rdata (plic_icb_rsp_rdata),
  
    .io_devices_0_0  (plic_irq_i_0 ),
    .io_devices_0_1  (plic_irq_i_1 ),
    .io_devices_0_2  (plic_irq_i_2 ),
    .io_devices_0_3  (plic_irq_i_3 ),
    .io_devices_0_4  (plic_irq_i_4 ),
    .io_devices_0_5  (plic_irq_i_5 ),
    .io_devices_0_6  (plic_irq_i_6 ),
    .io_devices_0_7  (plic_irq_i_7 ),
    .io_devices_0_8  (plic_irq_i_8 ),
    .io_devices_0_9  (plic_irq_i_9 ),
    .io_devices_0_10 (plic_irq_i_10),
    .io_devices_0_11 (plic_irq_i_11),
    .io_devices_0_12 (plic_irq_i_12),
    .io_devices_0_13 (plic_irq_i_13),
    .io_devices_0_14 (plic_irq_i_14),
    .io_devices_0_15 (plic_irq_i_15),

    .io_harts_0_0    (plic_ext_irq ) 
  );

  endmodule

