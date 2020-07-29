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
//  The NICE module 
//
// ====================================================================
`include "e203_defines.v"

`ifdef E203_HAS_NICE//{
module e203_exu_nice(

  input  nice_i_xs_off,
  input  nice_i_valid, // Handshake valid
  output nice_i_ready, // Handshake ready
  input [`E203_XLEN-1:0]   nice_i_instr,
  input [`E203_XLEN-1:0]   nice_i_rs1,
  input [`E203_XLEN-1:0]   nice_i_rs2,
  //input                    nice_i_mmode , // O: current insns' mmode 
  input  [`E203_ITAG_WIDTH-1:0] nice_i_itag,
  output nice_o_longpipe,

  // The nice Commit Interface
  output                        nice_o_valid, // Handshake valid
  input                         nice_o_ready, // Handshake ready

  //////////////////////////////////////////////////////////////
  // The nice write-back Interface
  output                        nice_o_itag_valid, // Handshake valid
  input                         nice_o_itag_ready, // Handshake ready
  output [`E203_ITAG_WIDTH-1:0] nice_o_itag,   

  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The nice Request Interface
  input                          nice_rsp_multicyc_valid , //I: current insn is multi-cycle.
  output                         nice_rsp_multicyc_ready , //O:                             

  output                         nice_req_valid, // Handshake valid
  input                          nice_req_ready, // Handshake ready
  output [`E203_XLEN-1:0]        nice_req_instr,
  output [`E203_XLEN-1:0]        nice_req_rs1,
  output [`E203_XLEN-1:0]        nice_req_rs2,
  //output                         nice_req_mmode , // O: current insns' mmode 


  input  clk,
  input  rst_n
  );

  //assign nice_req_mmode = nice_i_mmode;

  wire  nice_i_hsked = nice_i_valid & nice_i_ready;
  // when there is a valid insn and the cmt is ready, then send out the insn.
  wire   nice_req_valid_pos = nice_i_valid & nice_o_ready;
  assign nice_req_valid = ~nice_i_xs_off &  nice_req_valid_pos;
  // when nice is disable, its req_ready is assumed to 1.
  wire   nice_req_ready_pos = nice_i_xs_off ? 1'b1 : nice_req_ready;
  // nice reports ready to decode when its cmt is ready and the nice core is ready.
  assign nice_i_ready   = nice_req_ready_pos & nice_o_ready  ;
  // the nice isns is about to cmt when it is truly a valid nice insn and the nice core has accepted.
  assign nice_o_valid   = nice_i_valid   & nice_req_ready_pos;

  wire   fifo_o_vld;
  assign nice_rsp_multicyc_ready = nice_o_itag_ready & fifo_o_vld;


  assign nice_req_instr = nice_i_instr;
  assign nice_req_rs1 = nice_i_rs1;
  assign nice_req_rs2 = nice_i_rs2;

  assign nice_o_longpipe = ~nice_i_xs_off;


 wire itag_fifo_wen = nice_o_longpipe & (nice_req_valid & nice_req_ready); 
 wire itag_fifo_ren = nice_rsp_multicyc_valid & nice_rsp_multicyc_ready; 

wire          fifo_i_vld  = itag_fifo_wen;
wire          fifo_i_rdy;
wire [`E203_ITAG_WIDTH-1:0] fifo_i_dat = nice_i_itag;

wire          fifo_o_rdy = itag_fifo_ren;
wire [`E203_ITAG_WIDTH-1:0] fifo_o_dat; 
assign nice_o_itag_valid = fifo_o_vld & nice_rsp_multicyc_valid;
//assign nice_o_itag = {`E203_ITAG_WIDTH{nice_o_itag_valid}} & fifo_o_dat;
//ctrl path must be independent with data path to avoid timing-loop.
assign nice_o_itag = fifo_o_dat;

 sirv_gnrl_fifo # (
       .DP(4),
       .DW(`E203_ITAG_WIDTH),
       .CUT_READY(1) 
  ) u_nice_itag_fifo(
    .i_vld   (fifo_i_vld),
    .i_rdy   (fifo_i_rdy),
    .i_dat   (fifo_i_dat),
    .o_vld   (fifo_o_vld),
    .o_rdy   (fifo_o_rdy),
    .o_dat   (fifo_o_dat),
    .clk     (clk  ),
    .rst_n   (rst_n)
  );
  
endmodule     
`endif//}
