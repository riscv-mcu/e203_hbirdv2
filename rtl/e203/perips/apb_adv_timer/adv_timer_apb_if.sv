// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

//////////////////////////////////////////////////////////
////
////      TIMER 0 CONFIG
////
//////////////////////////////////////////////////////////
`define REG_TIM0_CMD           8'b00000000 //BASEADDR+0x000
`define REG_TIM0_CFG           8'b00000001 //BASEADDR+0x004

`define REG_TIM0_TH            8'b00000010 //BASEADDR+0x008  

`define REG_TIM0_CH0_TH        8'b00000011 //BASEADDR+0x00C 
`define REG_TIM0_CH1_TH        8'b00000100 //BASEADDR+0x010 
`define REG_TIM0_CH2_TH        8'b00000101 //BASEADDR+0x014 
`define REG_TIM0_CH3_TH        8'b00000110 //BASEADDR+0x018 

`define REG_TIM0_CH0_LUT       8'b00000111 //BASEADDR+0x01C 
`define REG_TIM0_CH1_LUT       8'b00001000 //BASEADDR+0x020 
`define REG_TIM0_CH2_LUT       8'b00001001 //BASEADDR+0x024 
`define REG_TIM0_CH3_LUT       8'b00001010 //BASEADDR+0x028

`define REG_TIM0_COUNTER       8'b00001011 //BASEADDR+0x02C

//////////////////////////////////////////////////////////
////
////      TIMER 1 CONFIG
////
//////////////////////////////////////////////////////////
`define REG_TIM1_CMD           8'b00010000 //BASEADDR+0x040
`define REG_TIM1_CFG           8'b00010001 //BASEADDR+0x044

`define REG_TIM1_TH            8'b00010010 //BASEADDR+0x048  

`define REG_TIM1_CH0_TH        8'b00010011 //BASEADDR+0x04C 
`define REG_TIM1_CH1_TH        8'b00010100 //BASEADDR+0x050 
`define REG_TIM1_CH2_TH        8'b00010101 //BASEADDR+0x054 
`define REG_TIM1_CH3_TH        8'b00010110 //BASEADDR+0x058 

`define REG_TIM1_CH0_LUT       8'b00010111 //BASEADDR+0x05C 
`define REG_TIM1_CH1_LUT       8'b00011000 //BASEADDR+0x060 
`define REG_TIM1_CH2_LUT       8'b00011001 //BASEADDR+0x064 
`define REG_TIM1_CH3_LUT       8'b00011010 //BASEADDR+0x068 

`define REG_TIM1_COUNTER       8'b00011011 //BASEADDR+0x06C

//////////////////////////////////////////////////////////
////
////      TIMER 2 CONFIG
////
//////////////////////////////////////////////////////////
`define REG_TIM2_CMD           8'b00100000 //BASEADDR+0x080
`define REG_TIM2_CFG           8'b00100001 //BASEADDR+0x084

`define REG_TIM2_TH            8'b00100010 //BASEADDR+0x088  

`define REG_TIM2_CH0_TH        8'b00100011 //BASEADDR+0x08C 
`define REG_TIM2_CH1_TH        8'b00100100 //BASEADDR+0x090 
`define REG_TIM2_CH2_TH        8'b00100101 //BASEADDR+0x094 
`define REG_TIM2_CH3_TH        8'b00100110 //BASEADDR+0x098 

`define REG_TIM2_CH0_LUT       8'b00100111 //BASEADDR+0x09C 
`define REG_TIM2_CH1_LUT       8'b00101000 //BASEADDR+0x0A0 
`define REG_TIM2_CH2_LUT       8'b00101001 //BASEADDR+0x0A4 
`define REG_TIM2_CH3_LUT       8'b00101010 //BASEADDR+0x0A8 

`define REG_TIM2_COUNTER       8'b00101011 //BASEADDR+0x0AC

//////////////////////////////////////////////////////////
////
////      TIMER 3 CONFIG
////
//////////////////////////////////////////////////////////
`define REG_TIM3_CMD           8'b00110000 //BASEADDR+0x0C0
`define REG_TIM3_CFG           8'b00110001 //BASEADDR+0x0C4

`define REG_TIM3_TH            8'b00110010 //BASEADDR+0x0C8  

`define REG_TIM3_CH0_TH        8'b00110011 //BASEADDR+0x0CC 
`define REG_TIM3_CH1_TH        8'b00110100 //BASEADDR+0x0D0 
`define REG_TIM3_CH2_TH        8'b00110101 //BASEADDR+0x0D4 
`define REG_TIM3_CH3_TH        8'b00110110 //BASEADDR+0x0D8 

`define REG_TIM3_CH0_LUT       8'b00110111 //BASEADDR+0x0DC 
`define REG_TIM3_CH1_LUT       8'b00111000 //BASEADDR+0x0E0 
`define REG_TIM3_CH2_LUT       8'b00111001 //BASEADDR+0x0E4 
`define REG_TIM3_CH3_LUT       8'b00111010 //BASEADDR+0x0E8 

`define REG_TIM3_COUNTER       8'b00111011 //BASEADDR+0x0EC

`define REG_EVENT_CFG          8'b01000000 //BASEADDR+0x100
`define REG_CH_EN              8'b01000001 //BASEADDR+0x104

module adv_timer_apb_if #(
	parameter APB_ADDR_WIDTH = 12
) (
    input  logic                      HCLK,
    input  logic                      HRESETn,
    input  logic [APB_ADDR_WIDTH-1:0] PADDR,
    input  logic               [31:0] PWDATA,
    input  logic                      PWRITE,
    input  logic                      PSEL,
    input  logic                      PENABLE,
    output logic               [31:0] PRDATA,
    output logic                      PREADY,
    output logic                      PSLVERR,

    output logic               [3:0]  events_en_o,
    output logic               [3:0]  events_sel_0_o,
    output logic               [3:0]  events_sel_1_o,
    output logic               [3:0]  events_sel_2_o,
    output logic               [3:0]  events_sel_3_o,

    input  logic              [15:0]  timer0_counter_i,
    input  logic              [15:0]  timer1_counter_i,
    input  logic              [15:0]  timer2_counter_i,
    input  logic              [15:0]  timer3_counter_i,

    output logic                      timer0_start_o,
    output logic                      timer0_stop_o,
	output logic                      timer0_update_o,
	output logic                      timer0_arm_o,
	output logic                      timer0_rst_o,
	output logic                      timer0_saw_o,
	output logic                [2:0] timer0_in_mode_o,
	output logic                [7:0] timer0_in_sel_o,
	output logic                      timer0_in_clk_o,
	output logic                [7:0] timer0_presc_o,
	output logic               [15:0] timer0_th_hi_o,
	output logic               [15:0] timer0_th_low_o,
	output logic                [2:0] timer0_ch0_mode_o,
	output logic                [1:0] timer0_ch0_flt_o,
	output logic               [15:0] timer0_ch0_th_o,
	output logic               [15:0] timer0_ch0_lut_o,
	output logic                [2:0] timer0_ch1_mode_o,
	output logic                [1:0] timer0_ch1_flt_o,
	output logic               [15:0] timer0_ch1_th_o,
	output logic               [15:0] timer0_ch1_lut_o,
	output logic                [2:0] timer0_ch2_mode_o,
	output logic                [1:0] timer0_ch2_flt_o,
	output logic               [15:0] timer0_ch2_th_o,
	output logic               [15:0] timer0_ch2_lut_o,
	output logic                [2:0] timer0_ch3_mode_o,
	output logic                [1:0] timer0_ch3_flt_o,
	output logic               [15:0] timer0_ch3_th_o,
	output logic               [15:0] timer0_ch3_lut_o,

    output logic                      timer1_start_o,
    output logic                      timer1_stop_o,
	output logic                      timer1_update_o,
	output logic                      timer1_arm_o,
	output logic                      timer1_rst_o,
	output logic                      timer1_saw_o,
	output logic                [2:0] timer1_in_mode_o,
	output logic                [7:0] timer1_in_sel_o,
	output logic                      timer1_in_clk_o,
	output logic                [7:0] timer1_presc_o,
	output logic               [15:0] timer1_th_hi_o,
	output logic               [15:0] timer1_th_low_o,
	output logic                [2:0] timer1_ch0_mode_o,
	output logic                [1:0] timer1_ch0_flt_o,
	output logic               [15:0] timer1_ch0_th_o,
	output logic               [15:0] timer1_ch0_lut_o,
	output logic                [2:0] timer1_ch1_mode_o,
	output logic                [1:0] timer1_ch1_flt_o,
	output logic               [15:0] timer1_ch1_th_o,
	output logic               [15:0] timer1_ch1_lut_o,
	output logic                [2:0] timer1_ch2_mode_o,
	output logic                [1:0] timer1_ch2_flt_o,
	output logic               [15:0] timer1_ch2_th_o,
	output logic               [15:0] timer1_ch2_lut_o,
	output logic                [2:0] timer1_ch3_mode_o,
	output logic                [1:0] timer1_ch3_flt_o,
	output logic               [15:0] timer1_ch3_th_o,
	output logic               [15:0] timer1_ch3_lut_o,

    output logic                      timer2_start_o,
    output logic                      timer2_stop_o,
	output logic                      timer2_update_o,
	output logic                      timer2_arm_o,
	output logic                      timer2_rst_o,
	output logic                      timer2_saw_o,
	output logic                [2:0] timer2_in_mode_o,
	output logic                [7:0] timer2_in_sel_o,
	output logic                      timer2_in_clk_o,
	output logic                [7:0] timer2_presc_o,
	output logic               [15:0] timer2_th_hi_o,
	output logic               [15:0] timer2_th_low_o,
	output logic                [2:0] timer2_ch0_mode_o,
	output logic                [1:0] timer2_ch0_flt_o,
	output logic               [15:0] timer2_ch0_th_o,
	output logic               [15:0] timer2_ch0_lut_o,
	output logic                [2:0] timer2_ch1_mode_o,
	output logic                [1:0] timer2_ch1_flt_o,
	output logic               [15:0] timer2_ch1_th_o,
	output logic               [15:0] timer2_ch1_lut_o,
	output logic                [2:0] timer2_ch2_mode_o,
	output logic                [1:0] timer2_ch2_flt_o,
	output logic               [15:0] timer2_ch2_th_o,
	output logic               [15:0] timer2_ch2_lut_o,
	output logic                [2:0] timer2_ch3_mode_o,
	output logic                [1:0] timer2_ch3_flt_o,
	output logic               [15:0] timer2_ch3_th_o,
	output logic               [15:0] timer2_ch3_lut_o,

    output logic                      timer3_start_o,
    output logic                      timer3_stop_o,
	output logic                      timer3_update_o,
	output logic                      timer3_arm_o,
	output logic                      timer3_rst_o,
	output logic                      timer3_saw_o,
	output logic                [2:0] timer3_in_mode_o,
	output logic                [7:0] timer3_in_sel_o,
	output logic                      timer3_in_clk_o,
	output logic                [7:0] timer3_presc_o,
	output logic               [15:0] timer3_th_hi_o,
	output logic               [15:0] timer3_th_low_o,
	output logic                [2:0] timer3_ch0_mode_o,
	output logic                [1:0] timer3_ch0_flt_o,
	output logic               [15:0] timer3_ch0_th_o,
	output logic               [15:0] timer3_ch0_lut_o,
	output logic                [2:0] timer3_ch1_mode_o,
	output logic                [1:0] timer3_ch1_flt_o,
	output logic               [15:0] timer3_ch1_th_o,
	output logic               [15:0] timer3_ch1_lut_o,
	output logic                [2:0] timer3_ch2_mode_o,
	output logic                [1:0] timer3_ch2_flt_o,
	output logic               [15:0] timer3_ch2_th_o,
	output logic               [15:0] timer3_ch2_lut_o,
	output logic                [2:0] timer3_ch3_mode_o,
	output logic                [1:0] timer3_ch3_flt_o,
	output logic               [15:0] timer3_ch3_th_o,
	output logic               [15:0] timer3_ch3_lut_o,

	output logic                      timer0_clk_en_o,
	output logic                      timer1_clk_en_o,
	output logic                      timer2_clk_en_o,
	output logic                      timer3_clk_en_o
);

    logic s_timer1_apb_in_clk;
    logic s_timer2_apb_in_clk;
    logic s_timer3_apb_in_clk;
    logic s_timer1_apb_start;
    logic s_timer1_apb_stop;
    logic s_timer2_apb_start;
    logic s_timer2_apb_stop;
    logic s_timer3_apb_start;
    logic s_timer3_apb_stop;

	logic [31:0] r_timer0_th;
	logic  [7:0] r_timer0_presc;
	logic  [7:0] r_timer0_in_sel;
	logic        r_timer0_in_clk;
	logic  [2:0] r_timer0_in_mode;
	logic        r_timer0_start;
	logic        r_timer0_stop;
	logic        r_timer0_update;
	logic        r_timer0_arm;
	logic        r_timer0_rst;
	logic        r_timer0_saw;
	logic [15:0] r_timer0_ch0_th;
	logic  [2:0] r_timer0_ch0_mode;
	logic [15:0] r_timer0_ch0_lut;
	logic  [1:0] r_timer0_ch0_flt;
	logic [15:0] r_timer0_ch1_th;
	logic  [2:0] r_timer0_ch1_mode;
	logic [15:0] r_timer0_ch1_lut;
	logic  [1:0] r_timer0_ch1_flt;
	logic [15:0] r_timer0_ch2_th;
	logic  [2:0] r_timer0_ch2_mode;
	logic [15:0] r_timer0_ch2_lut;
	logic  [1:0] r_timer0_ch2_flt;
	logic [15:0] r_timer0_ch3_th;
	logic  [2:0] r_timer0_ch3_mode;
	logic [15:0] r_timer0_ch3_lut;
	logic  [1:0] r_timer0_ch3_flt;

	logic [31:0] r_timer1_th;
	logic  [7:0] r_timer1_presc;
	logic  [7:0] r_timer1_in_sel;
	logic        r_timer1_in_clk;
	logic  [2:0] r_timer1_in_mode;
	logic        r_timer1_start;
	logic        r_timer1_stop;
	logic        r_timer1_update;
	logic        r_timer1_arm;
	logic        r_timer1_rst;
	logic        r_timer1_saw;
	logic [15:0] r_timer1_ch0_th;
	logic  [2:0] r_timer1_ch0_mode;
	logic [15:0] r_timer1_ch0_lut;
	logic  [1:0] r_timer1_ch0_flt;
	logic [15:0] r_timer1_ch1_th;
	logic  [2:0] r_timer1_ch1_mode;
	logic [15:0] r_timer1_ch1_lut;
	logic  [1:0] r_timer1_ch1_flt;
	logic [15:0] r_timer1_ch2_th;
	logic  [2:0] r_timer1_ch2_mode;
	logic [15:0] r_timer1_ch2_lut;
	logic  [1:0] r_timer1_ch2_flt;
	logic [15:0] r_timer1_ch3_th;
	logic  [2:0] r_timer1_ch3_mode;
	logic [15:0] r_timer1_ch3_lut;
	logic  [1:0] r_timer1_ch3_flt;

	logic [31:0] r_timer2_th;
	logic  [7:0] r_timer2_presc;
	logic  [7:0] r_timer2_in_sel;
	logic        r_timer2_in_clk;
	logic  [2:0] r_timer2_in_mode;
	logic        r_timer2_start;
	logic        r_timer2_stop;
	logic        r_timer2_update;
	logic        r_timer2_arm;
	logic        r_timer2_rst;
	logic        r_timer2_saw;
	logic [15:0] r_timer2_ch0_th;
	logic  [2:0] r_timer2_ch0_mode;
	logic [15:0] r_timer2_ch0_lut;
	logic  [1:0] r_timer2_ch0_flt;
	logic [15:0] r_timer2_ch1_th;
	logic  [2:0] r_timer2_ch1_mode;
	logic [15:0] r_timer2_ch1_lut;
	logic  [1:0] r_timer2_ch1_flt;
	logic [15:0] r_timer2_ch2_th;
	logic  [2:0] r_timer2_ch2_mode;
	logic [15:0] r_timer2_ch2_lut;
	logic  [1:0] r_timer2_ch2_flt;
	logic [15:0] r_timer2_ch3_th;
	logic  [2:0] r_timer2_ch3_mode;
	logic [15:0] r_timer2_ch3_lut;
	logic  [1:0] r_timer2_ch3_flt;

	logic [31:0] r_timer3_th;
	logic  [7:0] r_timer3_presc;
	logic  [7:0] r_timer3_in_sel;
	logic        r_timer3_in_clk;
	logic  [2:0] r_timer3_in_mode;
	logic        r_timer3_start;
	logic        r_timer3_stop;
	logic        r_timer3_update;
	logic        r_timer3_arm;
	logic        r_timer3_rst;
	logic        r_timer3_saw;
	logic [15:0] r_timer3_ch0_th;
	logic  [2:0] r_timer3_ch0_mode;
	logic [15:0] r_timer3_ch0_lut;
	logic  [1:0] r_timer3_ch0_flt;
	logic [15:0] r_timer3_ch1_th;
	logic  [2:0] r_timer3_ch1_mode;
	logic [15:0] r_timer3_ch1_lut;
	logic  [1:0] r_timer3_ch1_flt;
	logic [15:0] r_timer3_ch2_th;
	logic  [2:0] r_timer3_ch2_mode;
	logic [15:0] r_timer3_ch2_lut;
	logic  [1:0] r_timer3_ch2_flt;
	logic [15:0] r_timer3_ch3_th;
	logic  [2:0] r_timer3_ch3_mode;
	logic [15:0] r_timer3_ch3_lut;
	logic  [1:0] r_timer3_ch3_flt;

	logic  [3:0] r_event_sel_0; 
	logic  [3:0] r_event_sel_1; 
	logic  [3:0] r_event_sel_2; 
	logic  [3:0] r_event_sel_3; 
	logic  [3:0] r_event_en   ; 

	logic  [3:0] r_clk_en;

    logic  [7:0] s_apb_addr;

    assign events_en_o    = r_event_en;
    assign events_sel_0_o = r_event_sel_0;
    assign events_sel_1_o = r_event_sel_1;
    assign events_sel_2_o = r_event_sel_2;
    assign events_sel_3_o = r_event_sel_3;

    assign timer0_start_o     = r_timer0_start;
    assign timer0_stop_o      = r_timer0_stop;
	assign timer0_update_o    = r_timer0_update;
	assign timer0_rst_o       = r_timer0_rst;
	assign timer0_arm_o       = r_timer0_arm;
	assign timer0_saw_o       = r_timer0_saw;
	assign timer0_in_mode_o   = r_timer0_in_mode;
	assign timer0_in_sel_o    = r_timer0_in_sel;
	assign timer0_in_clk_o    = r_timer0_in_clk;
	assign timer0_presc_o     = r_timer0_presc;
	assign timer0_th_hi_o     = r_timer0_th[31:16];
	assign timer0_th_low_o    = r_timer0_th[15:0];
	assign timer0_ch0_mode_o  = r_timer0_ch0_mode;
	assign timer0_ch0_flt_o   = r_timer0_ch0_flt;
	assign timer0_ch0_th_o    = r_timer0_ch0_th;
	assign timer0_ch0_lut_o   = r_timer0_ch0_lut;
	assign timer0_ch1_mode_o  = r_timer0_ch1_mode;
	assign timer0_ch1_flt_o   = r_timer0_ch1_flt;
	assign timer0_ch1_th_o    = r_timer0_ch1_th;
	assign timer0_ch1_lut_o   = r_timer0_ch1_lut;
	assign timer0_ch2_mode_o  = r_timer0_ch2_mode;
	assign timer0_ch2_flt_o   = r_timer0_ch2_flt;
	assign timer0_ch2_th_o    = r_timer0_ch2_th;
	assign timer0_ch2_lut_o   = r_timer0_ch2_lut;
	assign timer0_ch3_mode_o  = r_timer0_ch3_mode;
	assign timer0_ch3_flt_o   = r_timer0_ch3_flt;
	assign timer0_ch3_th_o    = r_timer0_ch3_th;
	assign timer0_ch3_lut_o   = r_timer0_ch3_lut;

    assign timer1_start_o     = r_timer1_start;
    assign timer1_stop_o      = r_timer1_stop;
	assign timer1_update_o    = r_timer1_update;
	assign timer1_rst_o       = r_timer1_rst;
	assign timer1_arm_o       = r_timer1_arm;
	assign timer1_saw_o       = r_timer1_saw;
	assign timer1_in_mode_o   = r_timer1_in_mode;
	assign timer1_in_sel_o    = r_timer1_in_sel;
	assign timer1_in_clk_o    = r_timer1_in_clk;
	assign timer1_presc_o     = r_timer1_presc;
	assign timer1_th_hi_o     = r_timer1_th[31:16];
	assign timer1_th_low_o    = r_timer1_th[15:0];
	assign timer1_ch0_mode_o  = r_timer1_ch0_mode;
	assign timer1_ch0_flt_o   = r_timer1_ch0_flt;
	assign timer1_ch0_th_o    = r_timer1_ch0_th;
	assign timer1_ch0_lut_o   = r_timer1_ch0_lut;
	assign timer1_ch1_mode_o  = r_timer1_ch1_mode;
	assign timer1_ch1_flt_o   = r_timer1_ch1_flt;
	assign timer1_ch1_th_o    = r_timer1_ch1_th;
	assign timer1_ch1_lut_o   = r_timer1_ch1_lut;
	assign timer1_ch2_mode_o  = r_timer1_ch2_mode;
	assign timer1_ch2_flt_o   = r_timer1_ch2_flt;
	assign timer1_ch2_th_o    = r_timer1_ch2_th;
	assign timer1_ch2_lut_o   = r_timer1_ch2_lut;
	assign timer1_ch3_mode_o  = r_timer1_ch3_mode;
	assign timer1_ch3_flt_o   = r_timer1_ch3_flt;
	assign timer1_ch3_th_o    = r_timer1_ch3_th;
	assign timer1_ch3_lut_o   = r_timer1_ch3_lut;

    assign timer2_start_o     = r_timer2_start;
    assign timer2_stop_o      = r_timer2_stop;
	assign timer2_update_o    = r_timer2_update;
	assign timer2_rst_o       = r_timer2_rst;
	assign timer2_arm_o       = r_timer2_arm;
	assign timer2_saw_o       = r_timer2_saw;
	assign timer2_in_mode_o   = r_timer2_in_mode;
	assign timer2_in_sel_o    = r_timer2_in_sel;
	assign timer2_in_clk_o    = r_timer2_in_clk;
	assign timer2_presc_o     = r_timer2_presc;
	assign timer2_th_hi_o     = r_timer2_th[31:16];
	assign timer2_th_low_o    = r_timer2_th[15:0];
	assign timer2_ch0_mode_o  = r_timer2_ch0_mode;
	assign timer2_ch0_flt_o   = r_timer2_ch0_flt;
	assign timer2_ch0_th_o    = r_timer2_ch0_th;
	assign timer2_ch0_lut_o   = r_timer2_ch0_lut;
	assign timer2_ch1_mode_o  = r_timer2_ch1_mode;
	assign timer2_ch1_flt_o   = r_timer2_ch1_flt;
	assign timer2_ch1_th_o    = r_timer2_ch1_th;
	assign timer2_ch1_lut_o   = r_timer2_ch1_lut;
	assign timer2_ch2_mode_o  = r_timer2_ch2_mode;
	assign timer2_ch2_flt_o   = r_timer2_ch2_flt;
	assign timer2_ch2_th_o    = r_timer2_ch2_th;
	assign timer2_ch2_lut_o   = r_timer2_ch2_lut;
	assign timer2_ch3_mode_o  = r_timer2_ch3_mode;
	assign timer2_ch3_flt_o   = r_timer2_ch3_flt;
	assign timer2_ch3_th_o    = r_timer2_ch3_th;
	assign timer2_ch3_lut_o   = r_timer2_ch3_lut;

    assign timer3_start_o     = r_timer3_start;
    assign timer3_stop_o      = r_timer3_stop;
	assign timer3_update_o    = r_timer3_update;
	assign timer3_rst_o       = r_timer3_rst;
	assign timer3_arm_o       = r_timer3_arm;
	assign timer3_saw_o       = r_timer3_saw;
	assign timer3_in_mode_o   = r_timer3_in_mode;
	assign timer3_in_sel_o    = r_timer3_in_sel;
	assign timer3_in_clk_o    = r_timer3_in_clk;
	assign timer3_presc_o     = r_timer3_presc;
	assign timer3_th_hi_o     = r_timer3_th[31:16];
	assign timer3_th_low_o    = r_timer3_th[15:0];
	assign timer3_ch0_mode_o  = r_timer3_ch0_mode;
	assign timer3_ch0_flt_o   = r_timer3_ch0_flt;
	assign timer3_ch0_th_o    = r_timer3_ch0_th;
	assign timer3_ch0_lut_o   = r_timer3_ch0_lut;
	assign timer3_ch1_mode_o  = r_timer3_ch1_mode;
	assign timer3_ch1_flt_o   = r_timer3_ch1_flt;
	assign timer3_ch1_th_o    = r_timer3_ch1_th;
	assign timer3_ch1_lut_o   = r_timer3_ch1_lut;
	assign timer3_ch2_mode_o  = r_timer3_ch2_mode;
	assign timer3_ch2_flt_o   = r_timer3_ch2_flt;
	assign timer3_ch2_th_o    = r_timer3_ch2_th;
	assign timer3_ch2_lut_o   = r_timer3_ch2_lut;
	assign timer3_ch3_mode_o  = r_timer3_ch3_mode;
	assign timer3_ch3_flt_o   = r_timer3_ch3_flt;
	assign timer3_ch3_th_o    = r_timer3_ch3_th;
	assign timer3_ch3_lut_o   = r_timer3_ch3_lut;

	assign timer0_clk_en_o    = r_clk_en[0];
	assign timer1_clk_en_o    = r_clk_en[1];
	assign timer2_clk_en_o    = r_clk_en[2];
	assign timer3_clk_en_o    = r_clk_en[3];

    assign s_apb_addr = PADDR[9:2];

    always_ff @(posedge HCLK, negedge HRESETn) 
    begin
        if(~HRESETn) 
        begin
            r_timer0_th       <=  'h0;
            r_timer0_in_sel   <=  'h0;
            r_timer0_in_clk   <=  'h0;
            r_timer0_in_mode  <=  'h0;
            r_timer0_presc    <=  'h0;
            r_timer0_start    <= 1'b0;
            r_timer0_stop     <= 1'b0;
            r_timer0_update   <= 1'b0;
            r_timer0_arm      <= 1'b0;
            r_timer0_rst      <= 1'b0;
            r_timer0_saw      <= 1'b1;
			r_timer0_ch0_th   <=  'h0;
			r_timer0_ch0_mode <=  'h0;
			r_timer0_ch0_lut  <=  'h0;
			r_timer0_ch0_flt  <=  'h0;
			r_timer0_ch1_th   <=  'h0;
			r_timer0_ch1_mode <=  'h0;
			r_timer0_ch1_lut  <=  'h0;
			r_timer0_ch1_flt  <=  'h0;
			r_timer0_ch2_th   <=  'h0;
			r_timer0_ch2_mode <=  'h0;
			r_timer0_ch2_lut  <=  'h0;
			r_timer0_ch2_flt  <=  'h0;
			r_timer0_ch3_th   <=  'h0;
			r_timer0_ch3_mode <=  'h0;
			r_timer0_ch3_lut  <=  'h0;
			r_timer0_ch3_flt  <=  'h0;

            r_timer1_th       <=  'h0;
            r_timer1_in_sel   <=  'h0;
            r_timer1_in_clk   <=  'h0;
            r_timer1_in_mode  <=  'h0;
            r_timer1_presc    <=  'h0;
            r_timer1_start    <= 1'b0;
            r_timer1_stop     <= 1'b0;
            r_timer1_update   <= 1'b0;
            r_timer1_rst      <= 1'b0;
            r_timer1_arm      <= 1'b0;
            r_timer1_saw      <= 1'b1;
			r_timer1_ch0_th   <=  'h0;
			r_timer1_ch0_mode <=  'h0;
			r_timer1_ch0_lut  <=  'h0;
			r_timer1_ch0_flt  <=  'h0;
			r_timer1_ch1_th   <=  'h0;
			r_timer1_ch1_mode <=  'h0;
			r_timer1_ch1_lut  <=  'h0;
			r_timer1_ch1_flt  <=  'h0;
			r_timer1_ch2_th   <=  'h0;
			r_timer1_ch2_mode <=  'h0;
			r_timer1_ch2_lut  <=  'h0;
			r_timer1_ch2_flt  <=  'h0;
			r_timer1_ch3_th   <=  'h0;
			r_timer1_ch3_mode <=  'h0;
			r_timer1_ch3_lut  <=  'h0;
			r_timer1_ch3_flt  <=  'h0;

            r_timer2_th       <=  'h0;
            r_timer2_in_sel   <=  'h0;
            r_timer2_in_clk   <=  'h0;
            r_timer2_in_mode  <=  'h0;
            r_timer2_presc    <=  'h0;
            r_timer2_start    <= 1'b0;
            r_timer2_stop     <= 1'b0;
            r_timer2_update   <= 1'b0;
            r_timer2_rst      <= 1'b0;
            r_timer2_arm      <= 1'b0;
            r_timer2_saw      <= 1'b1;
			r_timer2_ch0_th   <=  'h0;
			r_timer2_ch0_mode <=  'h0;
			r_timer2_ch0_lut  <=  'h0;
			r_timer2_ch0_flt  <=  'h0;
			r_timer2_ch1_th   <=  'h0;
			r_timer2_ch1_mode <=  'h0;
			r_timer2_ch1_lut  <=  'h0;
			r_timer2_ch1_flt  <=  'h0;
			r_timer2_ch2_th   <=  'h0;
			r_timer2_ch2_mode <=  'h0;
			r_timer2_ch2_lut  <=  'h0;
			r_timer2_ch2_flt  <=  'h0;
			r_timer2_ch3_th   <=  'h0;
			r_timer2_ch3_mode <=  'h0;
			r_timer2_ch3_lut  <=  'h0;
			r_timer2_ch3_flt  <=  'h0;

            r_timer3_th       <=  'h0;
            r_timer3_in_sel   <=  'h0;
            r_timer3_in_clk   <=  'h0;
            r_timer3_in_mode  <=  'h0;
            r_timer3_presc    <=  'h0;
            r_timer3_start    <= 1'b0;
            r_timer3_stop     <= 1'b0;
            r_timer3_update   <= 1'b0;
            r_timer3_rst      <= 1'b0;
            r_timer3_arm      <= 1'b0;
            r_timer3_saw      <= 1'b1;
			r_timer3_ch0_th   <=  'h0;
			r_timer3_ch0_mode <=  'h0;
			r_timer3_ch0_lut  <=  'h0;
			r_timer3_ch0_flt  <=  'h0;
			r_timer3_ch1_th   <=  'h0;
			r_timer3_ch1_mode <=  'h0;
			r_timer3_ch1_lut  <=  'h0;
			r_timer3_ch1_flt  <=  'h0;
			r_timer3_ch2_th   <=  'h0;
			r_timer3_ch2_mode <=  'h0;
			r_timer3_ch2_lut  <=  'h0;
			r_timer3_ch2_flt  <=  'h0;
			r_timer3_ch3_th   <=  'h0;
			r_timer3_ch3_mode <=  'h0;
			r_timer3_ch3_lut  <=  'h0;
			r_timer3_ch3_flt  <=  'h0;

			r_event_sel_0     <=  'h0; 
			r_event_sel_1     <=  'h0; 
			r_event_sel_2     <=  'h0; 
			r_event_sel_3     <=  'h0; 
			r_event_en        <=  'h0; 

			r_clk_en          <=  'h0;


        end
        else
        begin
            if (PSEL && PENABLE && PWRITE)
            begin
                case (s_apb_addr)
                	`REG_TIM0_TH:
                		r_timer0_th <= PWDATA;
                	`REG_TIM0_CMD:
                	begin
            			r_timer0_start  <= PWDATA[0];
            			r_timer0_stop   <= PWDATA[1];
            			r_timer0_update <= PWDATA[2];
            			r_timer0_rst    <= PWDATA[3];
            			r_timer0_arm    <= PWDATA[4];
                	end
                	`REG_TIM0_CFG:
                	begin
			            r_timer0_in_sel <= PWDATA[7:0];
			            r_timer0_in_mode<= PWDATA[10:8];
            			r_timer0_in_clk <= PWDATA[11];
            			r_timer0_saw    <= PWDATA[12];
            			r_timer0_presc  <= PWDATA[23:16];
                	end
					`REG_TIM0_CH0_TH:
					begin
						r_timer0_ch0_th   <= PWDATA[15:0];
						r_timer0_ch0_mode <= PWDATA[18:16];
					end
					`REG_TIM0_CH0_LUT:
					begin
						r_timer0_ch0_lut  <= PWDATA[15:0];
						r_timer0_ch0_flt  <= PWDATA[17:16];
					end
					`REG_TIM0_CH1_TH:
					begin
						r_timer0_ch1_th   <= PWDATA[15:0];
						r_timer0_ch1_mode <= PWDATA[18:16];
					end
					`REG_TIM0_CH1_LUT:
					begin
						r_timer0_ch1_lut  <= PWDATA[15:0];
						r_timer0_ch1_flt  <= PWDATA[17:16];
					end
					`REG_TIM0_CH2_TH:
					begin
						r_timer0_ch2_th   <= PWDATA[15:0];
						r_timer0_ch2_mode <= PWDATA[18:16];
					end
					`REG_TIM0_CH2_LUT:
					begin
						r_timer0_ch2_lut  <= PWDATA[15:0];
						r_timer0_ch2_flt  <= PWDATA[17:16];
					end
					`REG_TIM0_CH3_TH:
					begin
						r_timer0_ch3_th   <= PWDATA[15:0];
						r_timer0_ch3_mode <= PWDATA[18:16];
					end
					`REG_TIM0_CH3_LUT:
					begin
						r_timer0_ch3_lut  <= PWDATA[15:0];
						r_timer0_ch3_flt  <= PWDATA[17:16];
					end


                	`REG_TIM1_TH:
                		r_timer1_th <= PWDATA;
                	`REG_TIM1_CMD:
                	begin
            			r_timer1_start  <= PWDATA[0];
            			r_timer1_stop   <= PWDATA[1];
            			r_timer1_update <= PWDATA[2];
            			r_timer1_rst    <= PWDATA[3];
            			r_timer1_arm    <= PWDATA[4];
                	end
                	`REG_TIM1_CFG:
                	begin
			            r_timer1_in_sel <= PWDATA[7:0];
			            r_timer1_in_mode<= PWDATA[10:8];
            			r_timer1_in_clk <= PWDATA[11];
            			r_timer1_saw    <= PWDATA[12];
            			r_timer1_presc  <= PWDATA[23:16];
                	end
					`REG_TIM1_CH0_TH:
					begin
						r_timer1_ch0_th   <= PWDATA[15:0];
						r_timer1_ch0_mode <= PWDATA[18:16];
					end
					`REG_TIM1_CH0_LUT:
					begin
						r_timer1_ch0_lut  <= PWDATA[15:0];
						r_timer1_ch0_flt  <= PWDATA[17:16];
					end
					`REG_TIM1_CH1_TH:
					begin
						r_timer1_ch1_th   <= PWDATA[15:0];
						r_timer1_ch1_mode <= PWDATA[18:16];
					end
					`REG_TIM1_CH1_LUT:
					begin
						r_timer1_ch1_lut  <= PWDATA[15:0];
						r_timer1_ch1_flt  <= PWDATA[17:16];
					end
					`REG_TIM1_CH2_TH:
					begin
						r_timer1_ch2_th   <= PWDATA[15:0];
						r_timer1_ch2_mode <= PWDATA[18:16];
					end
					`REG_TIM1_CH2_LUT:
					begin
						r_timer1_ch2_lut  <= PWDATA[15:0];
						r_timer1_ch2_flt  <= PWDATA[17:16];
					end
					`REG_TIM1_CH3_TH:
					begin
						r_timer1_ch3_th   <= PWDATA[15:0];
						r_timer1_ch3_mode <= PWDATA[18:16];
					end
					`REG_TIM1_CH3_LUT:
					begin
						r_timer1_ch3_lut  <= PWDATA[15:0];
						r_timer1_ch3_flt  <= PWDATA[17:16];
					end

                	`REG_TIM2_TH:
                		r_timer2_th <= PWDATA;
                	`REG_TIM2_CMD:
                	begin
            			r_timer2_start  <= PWDATA[0];
            			r_timer2_stop   <= PWDATA[1];
            			r_timer2_update <= PWDATA[2];
            			r_timer2_rst    <= PWDATA[3];
            			r_timer2_arm    <= PWDATA[4];
                	end
                	`REG_TIM2_CFG:
                	begin
			            r_timer2_in_sel <= PWDATA[7:0];
			            r_timer2_in_mode<= PWDATA[10:8];
            			r_timer2_in_clk <= PWDATA[11];
            			r_timer2_saw    <= PWDATA[12];
            			r_timer2_presc  <= PWDATA[23:16];
                	end
					`REG_TIM2_CH0_TH:
					begin
						r_timer2_ch0_th   <= PWDATA[15:0];
						r_timer2_ch0_mode <= PWDATA[18:16];
					end
					`REG_TIM2_CH0_LUT:
					begin
						r_timer2_ch0_lut  <= PWDATA[15:0];
						r_timer2_ch0_flt  <= PWDATA[17:16];
					end
					`REG_TIM2_CH1_TH:
					begin
						r_timer2_ch1_th   <= PWDATA[15:0];
						r_timer2_ch1_mode <= PWDATA[18:16];
					end
					`REG_TIM2_CH1_LUT:
					begin
						r_timer2_ch1_lut  <= PWDATA[15:0];
						r_timer2_ch1_flt  <= PWDATA[17:16];
					end
					`REG_TIM2_CH2_TH:
					begin
						r_timer2_ch2_th   <= PWDATA[15:0];
						r_timer2_ch2_mode <= PWDATA[18:16];
					end
					`REG_TIM2_CH2_LUT:
					begin
						r_timer2_ch2_lut  <= PWDATA[15:0];
						r_timer2_ch2_flt  <= PWDATA[17:16];
					end
					`REG_TIM2_CH3_TH:
					begin
						r_timer2_ch3_th   <= PWDATA[15:0];
						r_timer2_ch3_mode <= PWDATA[18:16];
					end
					`REG_TIM2_CH3_LUT:
					begin
						r_timer2_ch3_lut  <= PWDATA[15:0];
						r_timer2_ch3_flt  <= PWDATA[17:16];
					end

                	`REG_TIM3_TH:
                		r_timer3_th <= PWDATA;
                	`REG_TIM3_CMD:
                	begin
            			r_timer3_start  <= PWDATA[0];
            			r_timer3_stop   <= PWDATA[1];
            			r_timer3_update <= PWDATA[2];
            			r_timer3_rst    <= PWDATA[3];
            			r_timer3_arm    <= PWDATA[4];
                	end
                	`REG_TIM3_CFG:
                	begin
			            r_timer3_in_sel <= PWDATA[7:0];
			            r_timer3_in_mode<= PWDATA[10:8];
            			r_timer3_in_clk <= PWDATA[11];
            			r_timer3_saw    <= PWDATA[12];
            			r_timer3_presc  <= PWDATA[23:16];
                	end
					`REG_TIM3_CH0_TH:
					begin
						r_timer3_ch0_th   <= PWDATA[15:0];
						r_timer3_ch0_mode <= PWDATA[18:16];
					end
					`REG_TIM3_CH0_LUT:
					begin
						r_timer3_ch0_lut  <= PWDATA[15:0];
						r_timer3_ch0_flt  <= PWDATA[17:16];
					end
					`REG_TIM3_CH1_TH:
					begin
						r_timer3_ch1_th   <= PWDATA[15:0];
						r_timer3_ch1_mode <= PWDATA[18:16];
					end
					`REG_TIM3_CH1_LUT:
					begin
						r_timer3_ch1_lut  <= PWDATA[15:0];
						r_timer3_ch1_flt  <= PWDATA[17:16];
					end
					`REG_TIM3_CH2_TH:
					begin
						r_timer3_ch2_th   <= PWDATA[15:0];
						r_timer3_ch2_mode <= PWDATA[18:16];
					end
					`REG_TIM3_CH2_LUT:
					begin
						r_timer3_ch2_lut  <= PWDATA[15:0];
						r_timer3_ch2_flt  <= PWDATA[17:16];
					end
					`REG_TIM3_CH3_TH:
					begin
						r_timer3_ch3_th   <= PWDATA[15:0];
						r_timer3_ch3_mode <= PWDATA[18:16];
					end
					`REG_TIM3_CH3_LUT:
					begin
						r_timer3_ch3_lut  <= PWDATA[15:0];
						r_timer3_ch3_flt  <= PWDATA[17:16];
					end
					`REG_EVENT_CFG:
					begin
						r_event_sel_0 <= PWDATA[3:0];
						r_event_sel_1 <= PWDATA[7:4];
						r_event_sel_2 <= PWDATA[11:8];
						r_event_sel_3 <= PWDATA[15:12];
						r_event_en    <= PWDATA[19:16];
					end
					`REG_CH_EN:
					begin
						r_clk_en <= PWDATA[3:0];
					end
                endcase // s_apb_addr
            end
            else
            begin
            	r_timer0_start  <= 1'b0;
            	r_timer0_stop   <= 1'b0;
            	r_timer0_rst    <= 1'b0;
            	r_timer0_update <= 1'b0;
       			r_timer0_arm    <= 1'b0;
            	r_timer1_start  <= 1'b0;
            	r_timer1_stop   <= 1'b0;
            	r_timer1_rst    <= 1'b0;
            	r_timer1_update <= 1'b0;
       			r_timer1_arm    <= 1'b0;
            	r_timer2_start  <= 1'b0;
            	r_timer2_stop   <= 1'b0;
            	r_timer2_rst    <= 1'b0;
            	r_timer2_update <= 1'b0;
       			r_timer2_arm    <= 1'b0;
            	r_timer3_start  <= 1'b0;
            	r_timer3_stop   <= 1'b0;
            	r_timer3_rst    <= 1'b0;
            	r_timer3_update <= 1'b0;
       			r_timer3_arm    <= 1'b0;
            end
        end
    end




    always_comb
    begin
        case (s_apb_addr)
        `REG_TIM0_TH:
            PRDATA = r_timer0_th;
        `REG_TIM1_TH:
            PRDATA = r_timer1_th;
        `REG_TIM2_TH:
            PRDATA = r_timer2_th;
        `REG_TIM3_TH:
            PRDATA = r_timer3_th;
        `REG_TIM0_CFG:
        	PRDATA = {8'h0,r_timer0_presc,3'h0,r_timer0_saw,r_timer0_in_clk,r_timer0_in_mode,r_timer0_in_sel};
		`REG_TIM0_CH0_TH:
			PRDATA = {13'h0,r_timer0_ch0_mode,r_timer0_ch0_th};
		`REG_TIM0_CH0_LUT:
			PRDATA = {14'h0,r_timer0_ch0_flt,r_timer0_ch0_lut};
		`REG_TIM0_CH1_TH:
			PRDATA = {13'h0,r_timer0_ch1_mode,r_timer0_ch1_th};
		`REG_TIM0_CH1_LUT:
			PRDATA = {14'h0,r_timer0_ch1_flt,r_timer0_ch1_lut};
		`REG_TIM0_CH2_TH:
			PRDATA = {13'h0,r_timer0_ch2_mode,r_timer0_ch2_th};
		`REG_TIM0_CH2_LUT:
			PRDATA = {14'h0,r_timer0_ch2_flt,r_timer0_ch2_lut};
		`REG_TIM0_CH3_TH:
			PRDATA = {13'h0,r_timer0_ch3_mode,r_timer0_ch3_th};
		`REG_TIM0_CH3_LUT:
			PRDATA = {14'h0,r_timer0_ch3_flt,r_timer0_ch3_lut};
        `REG_TIM1_CFG:
        	PRDATA = {8'h0,r_timer1_presc,3'h0,r_timer1_saw,r_timer1_in_clk,r_timer1_in_mode,r_timer1_in_sel};
		`REG_TIM1_CH0_TH:
			PRDATA = {13'h0,r_timer1_ch0_mode,r_timer1_ch0_th};
		`REG_TIM1_CH0_LUT:
			PRDATA = {14'h0,r_timer1_ch0_flt,r_timer1_ch0_lut};
		`REG_TIM1_CH1_TH:
			PRDATA = {13'h0,r_timer1_ch1_mode,r_timer1_ch1_th};
		`REG_TIM1_CH1_LUT:
			PRDATA = {14'h0,r_timer1_ch1_flt,r_timer1_ch1_lut};
		`REG_TIM1_CH2_TH:
			PRDATA = {13'h0,r_timer1_ch2_mode,r_timer1_ch2_th};
		`REG_TIM1_CH2_LUT:
			PRDATA = {14'h0,r_timer1_ch2_flt,r_timer1_ch2_lut};
		`REG_TIM1_CH3_TH:
			PRDATA = {13'h0,r_timer1_ch3_mode,r_timer1_ch3_th};
		`REG_TIM1_CH3_LUT:
			PRDATA = {14'h0,r_timer1_ch3_flt,r_timer1_ch3_lut};
        `REG_TIM2_CFG:
        	PRDATA = {8'h0,r_timer2_presc,3'h0,r_timer2_saw,r_timer2_in_clk,r_timer2_in_mode,r_timer2_in_sel};
		`REG_TIM2_CH0_TH:
			PRDATA = {13'h0,r_timer2_ch0_mode,r_timer2_ch0_th};
		`REG_TIM2_CH0_LUT:
			PRDATA = {14'h0,r_timer2_ch0_flt,r_timer2_ch0_lut};
		`REG_TIM2_CH1_TH:
			PRDATA = {13'h0,r_timer2_ch1_mode,r_timer2_ch1_th};
		`REG_TIM2_CH1_LUT:
			PRDATA = {14'h0,r_timer2_ch1_flt,r_timer2_ch1_lut};
		`REG_TIM2_CH2_TH:
			PRDATA = {13'h0,r_timer2_ch2_mode,r_timer2_ch2_th};
		`REG_TIM2_CH2_LUT:
			PRDATA = {14'h0,r_timer2_ch2_flt,r_timer2_ch2_lut};
		`REG_TIM2_CH3_TH:
			PRDATA = {13'h0,r_timer2_ch3_mode,r_timer2_ch3_th};
		`REG_TIM2_CH3_LUT:
			PRDATA = {14'h0,r_timer2_ch3_flt,r_timer2_ch3_lut};
        `REG_TIM3_CFG:
        	PRDATA = {8'h0,r_timer3_presc,3'h0,r_timer3_saw,r_timer3_in_clk,r_timer3_in_mode,r_timer3_in_sel};
		`REG_TIM3_CH0_TH:
			PRDATA = {13'h0,r_timer3_ch0_mode,r_timer3_ch0_th};
		`REG_TIM3_CH0_LUT:
			PRDATA = {14'h0,r_timer3_ch0_flt,r_timer3_ch0_lut};
		`REG_TIM3_CH1_TH:
			PRDATA = {13'h0,r_timer3_ch1_mode,r_timer3_ch1_th};
		`REG_TIM3_CH1_LUT:
			PRDATA = {14'h0,r_timer3_ch1_flt,r_timer3_ch1_lut};
		`REG_TIM3_CH2_TH:
			PRDATA = {13'h0,r_timer3_ch2_mode,r_timer3_ch2_th};
		`REG_TIM3_CH2_LUT:
			PRDATA = {14'h0,r_timer3_ch2_flt,r_timer3_ch2_lut};
		`REG_TIM3_CH3_TH:
			PRDATA = {13'h0,r_timer3_ch3_mode,r_timer3_ch3_th};
		`REG_TIM3_CH3_LUT:
			PRDATA = {14'h0,r_timer3_ch3_flt,r_timer3_ch3_lut};
		`REG_TIM0_COUNTER:
			PRDATA = {16'h0,timer0_counter_i};
		`REG_TIM1_COUNTER:
			PRDATA = {16'h0,timer1_counter_i};
		`REG_TIM2_COUNTER:
			PRDATA = {16'h0,timer2_counter_i};
		`REG_TIM3_COUNTER:
			PRDATA = {16'h0,timer3_counter_i};
		`REG_EVENT_CFG:
			PRDATA = {12'h0,r_event_en,r_event_sel_3,r_event_sel_2,r_event_sel_1,r_event_sel_0};
		`REG_CH_EN:
			PRDATA = {28'h0,r_clk_en};
        default:
            PRDATA = 'h0;
        endcase
    end

    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;

 endmodule // adv_timer_apb_if

