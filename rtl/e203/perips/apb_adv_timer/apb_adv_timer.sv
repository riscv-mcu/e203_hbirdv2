// Copyright 2018 ETH Zurich and University of Bologna.
// -- Adaptable modifications made for hbirdv2 SoC. -- 
// Copyright 2020 Nuclei System Technology, Inc.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

module apb_adv_timer #(
	parameter APB_ADDR_WIDTH = 12,
	parameter EXTSIG_NUM     = 32,
	parameter TIMER_NBITS    = 16
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

	input  logic                      dft_cg_enable_i,
	input  logic                      low_speed_clk_i,
	input  logic     [EXTSIG_NUM-1:0] ext_sig_i,

	output logic                [3:0] events_o,	

	output logic                [3:0] ch_0_o,	
	output logic                [3:0] ch_1_o,	
	output logic                [3:0] ch_2_o,	
	output logic                [3:0] ch_3_o
);

	localparam N_TIMEREXTSIG = EXTSIG_NUM+16;

    logic                      s_timer0_apb_start;
    logic                      s_timer0_apb_stop;
	logic                      s_timer0_apb_arm;
	logic                      s_timer0_apb_update;
	logic                      s_timer0_apb_rst;
	logic                      s_timer0_apb_saw;
	logic                [7:0] s_timer0_apb_in_sel;
	logic                [2:0] s_timer0_apb_in_mode;
	logic                [7:0] s_timer0_apb_presc;
	logic               [15:0] s_timer0_apb_th_hi;
	logic               [15:0] s_timer0_apb_th_low;
	logic                [2:0] s_timer0_apb_ch0_mode;
	logic                [1:0] s_timer0_apb_ch0_flt;
	logic               [15:0] s_timer0_apb_ch0_th;
	logic               [15:0] s_timer0_apb_ch0_lut;
	logic                [2:0] s_timer0_apb_ch1_mode;
	logic                [1:0] s_timer0_apb_ch1_flt;
	logic               [15:0] s_timer0_apb_ch1_th;
	logic               [15:0] s_timer0_apb_ch1_lut;
	logic                [2:0] s_timer0_apb_ch2_mode;
	logic                [1:0] s_timer0_apb_ch2_flt;
	logic               [15:0] s_timer0_apb_ch2_th;
	logic               [15:0] s_timer0_apb_ch2_lut;
	logic                [2:0] s_timer0_apb_ch3_mode;
	logic                [1:0] s_timer0_apb_ch3_flt;
	logic               [15:0] s_timer0_apb_ch3_th;
	logic               [15:0] s_timer0_apb_ch3_lut;

    logic                      s_timer1_apb_start;
    logic                      s_timer1_apb_stop;
	logic                      s_timer1_apb_arm;
	logic                      s_timer1_apb_update;
	logic                      s_timer1_apb_rst;
	logic                      s_timer1_apb_saw;
	logic                [7:0] s_timer1_apb_in_sel;
	logic                [2:0] s_timer1_apb_in_mode;
	logic                [7:0] s_timer1_apb_presc;
	logic               [15:0] s_timer1_apb_th_hi;
	logic               [15:0] s_timer1_apb_th_low;
	logic                [2:0] s_timer1_apb_ch0_mode;
	logic                [1:0] s_timer1_apb_ch0_flt;
	logic               [15:0] s_timer1_apb_ch0_th;
	logic               [15:0] s_timer1_apb_ch0_lut;
	logic                [2:0] s_timer1_apb_ch1_mode;
	logic                [1:0] s_timer1_apb_ch1_flt;
	logic               [15:0] s_timer1_apb_ch1_th;
	logic               [15:0] s_timer1_apb_ch1_lut;
	logic                [2:0] s_timer1_apb_ch2_mode;
	logic                [1:0] s_timer1_apb_ch2_flt;
	logic               [15:0] s_timer1_apb_ch2_th;
	logic               [15:0] s_timer1_apb_ch2_lut;
	logic                [2:0] s_timer1_apb_ch3_mode;
	logic                [1:0] s_timer1_apb_ch3_flt;
	logic               [15:0] s_timer1_apb_ch3_th;
	logic               [15:0] s_timer1_apb_ch3_lut;

    logic                      s_timer2_apb_start;
    logic                      s_timer2_apb_stop;
	logic                      s_timer2_apb_arm;
	logic                      s_timer2_apb_update;
	logic                      s_timer2_apb_rst;
	logic                      s_timer2_apb_saw;
	logic                [7:0] s_timer2_apb_in_sel;
	logic                [2:0] s_timer2_apb_in_mode;
	logic                [7:0] s_timer2_apb_presc;
	logic               [15:0] s_timer2_apb_th_hi;
	logic               [15:0] s_timer2_apb_th_low;
	logic                [2:0] s_timer2_apb_ch0_mode;
	logic                [1:0] s_timer2_apb_ch0_flt;
	logic               [15:0] s_timer2_apb_ch0_th;
	logic               [15:0] s_timer2_apb_ch0_lut;
	logic                [2:0] s_timer2_apb_ch1_mode;
	logic                [1:0] s_timer2_apb_ch1_flt;
	logic               [15:0] s_timer2_apb_ch1_th;
	logic               [15:0] s_timer2_apb_ch1_lut;
	logic                [2:0] s_timer2_apb_ch2_mode;
	logic                [1:0] s_timer2_apb_ch2_flt;
	logic               [15:0] s_timer2_apb_ch2_th;
	logic               [15:0] s_timer2_apb_ch2_lut;
	logic                [2:0] s_timer2_apb_ch3_mode;
	logic                [1:0] s_timer2_apb_ch3_flt;
	logic               [15:0] s_timer2_apb_ch3_th;
	logic               [15:0] s_timer2_apb_ch3_lut;

    logic                      s_timer3_apb_start;
    logic                      s_timer3_apb_stop;
	logic                      s_timer3_apb_arm;
	logic                      s_timer3_apb_update;
	logic                      s_timer3_apb_rst;
	logic                      s_timer3_apb_saw;
	logic                [7:0] s_timer3_apb_in_sel;
	logic                [2:0] s_timer3_apb_in_mode;
	logic                [7:0] s_timer3_apb_presc;
	logic               [15:0] s_timer3_apb_th_hi;
	logic               [15:0] s_timer3_apb_th_low;
	logic                [2:0] s_timer3_apb_ch0_mode;
	logic                [1:0] s_timer3_apb_ch0_flt;
	logic               [15:0] s_timer3_apb_ch0_th;
	logic               [15:0] s_timer3_apb_ch0_lut;
	logic                [2:0] s_timer3_apb_ch1_mode;
	logic                [1:0] s_timer3_apb_ch1_flt;
	logic               [15:0] s_timer3_apb_ch1_th;
	logic               [15:0] s_timer3_apb_ch1_lut;
	logic                [2:0] s_timer3_apb_ch2_mode;
	logic                [1:0] s_timer3_apb_ch2_flt;
	logic               [15:0] s_timer3_apb_ch2_th;
	logic               [15:0] s_timer3_apb_ch2_lut;
	logic                [2:0] s_timer3_apb_ch3_mode;
	logic                [1:0] s_timer3_apb_ch3_flt;
	logic               [15:0] s_timer3_apb_ch3_th;
	logic               [15:0] s_timer3_apb_ch3_lut;

	logic             [3:0] s_event_en;
	logic             [3:0] s_event_sel_0;
	logic             [3:0] s_event_sel_1;
	logic             [3:0] s_event_sel_2;
	logic             [3:0] s_event_sel_3;
	logic        s_timer0_apb_in_clk;
	logic        s_timer1_apb_in_clk;
	logic        s_timer2_apb_in_clk;
	logic        s_timer3_apb_in_clk;

	logic [15:0] s_timer0_counter;
	logic [15:0] s_timer1_counter;
	logic [15:0] s_timer2_counter;
	logic [15:0] s_timer3_counter;


    logic        s_timer0_clk_en;
    logic        s_timer1_clk_en;
    logic        s_timer2_clk_en;
    logic        s_timer3_clk_en;

    logic        s_clk_timer0;
    logic        s_clk_timer1;
    logic        s_clk_timer2;
    logic        s_clk_timer3;


	adv_timer_apb_if #(
      	.APB_ADDR_WIDTH   ( APB_ADDR_WIDTH         )
   	) u_apb_if (
    	.HCLK                    ( HCLK                 ),
    	.HRESETn                 ( HRESETn              ),
    	.PADDR                   ( PADDR                ),
    	.PWDATA                  ( PWDATA               ),
    	.PWRITE                  ( PWRITE               ),
    	.PSEL                    ( PSEL                 ),
    	.PENABLE                 ( PENABLE              ),
    	.PRDATA                  ( PRDATA               ),
    	.PREADY                  ( PREADY               ),
    	.PSLVERR                 ( PSLVERR              ),

    	.events_en_o             ( s_event_en           ),
    	.events_sel_0_o          ( s_event_sel_0        ),
    	.events_sel_1_o          ( s_event_sel_1        ),
    	.events_sel_2_o          ( s_event_sel_2        ),
    	.events_sel_3_o          ( s_event_sel_3        ),

    	.timer0_start_o          ( s_timer0_apb_start    ),
    	.timer0_stop_o           ( s_timer0_apb_stop     ),
		.timer0_arm_o            ( s_timer0_apb_arm      ),
		.timer0_update_o         ( s_timer0_apb_update   ),
		.timer0_rst_o            ( s_timer0_apb_rst      ),
		.timer0_saw_o            ( s_timer0_apb_saw      ),
		.timer0_in_sel_o         ( s_timer0_apb_in_sel   ),
		.timer0_in_clk_o         ( s_timer0_apb_in_clk   ),
		.timer0_in_mode_o        ( s_timer0_apb_in_mode  ),
		.timer0_presc_o          ( s_timer0_apb_presc    ),
		.timer0_th_hi_o          ( s_timer0_apb_th_hi    ),
		.timer0_th_low_o         ( s_timer0_apb_th_low   ),
		.timer0_ch0_mode_o       ( s_timer0_apb_ch0_mode ),
		.timer0_ch0_flt_o        ( s_timer0_apb_ch0_flt  ),
		.timer0_ch0_th_o         ( s_timer0_apb_ch0_th   ),
		.timer0_ch0_lut_o        ( s_timer0_apb_ch0_lut  ),
		.timer0_ch1_mode_o       ( s_timer0_apb_ch1_mode ),
		.timer0_ch1_flt_o        ( s_timer0_apb_ch1_flt  ),
		.timer0_ch1_th_o         ( s_timer0_apb_ch1_th   ),
		.timer0_ch1_lut_o        ( s_timer0_apb_ch1_lut  ),
		.timer0_ch2_mode_o       ( s_timer0_apb_ch2_mode ),
		.timer0_ch2_flt_o        ( s_timer0_apb_ch2_flt  ),
		.timer0_ch2_th_o         ( s_timer0_apb_ch2_th   ),
		.timer0_ch2_lut_o        ( s_timer0_apb_ch2_lut  ),
		.timer0_ch3_mode_o       ( s_timer0_apb_ch3_mode ),
		.timer0_ch3_flt_o        ( s_timer0_apb_ch3_flt  ),
		.timer0_ch3_th_o         ( s_timer0_apb_ch3_th   ),
		.timer0_ch3_lut_o        ( s_timer0_apb_ch3_lut  ),
		.timer0_counter_i        ( s_timer0_counter      ),

    	.timer1_start_o          ( s_timer1_apb_start    ),
    	.timer1_stop_o           ( s_timer1_apb_stop     ),
		.timer1_arm_o            ( s_timer1_apb_arm      ),
		.timer1_update_o         ( s_timer1_apb_update   ),
		.timer1_rst_o            ( s_timer1_apb_rst      ),
		.timer1_saw_o            ( s_timer1_apb_saw      ),
		.timer1_in_sel_o         ( s_timer1_apb_in_sel   ),
		.timer1_in_clk_o         ( s_timer1_apb_in_clk   ),
		.timer1_in_mode_o        ( s_timer1_apb_in_mode  ),
		.timer1_presc_o          ( s_timer1_apb_presc    ),
		.timer1_th_hi_o          ( s_timer1_apb_th_hi    ),
		.timer1_th_low_o         ( s_timer1_apb_th_low   ),
		.timer1_ch0_mode_o       ( s_timer1_apb_ch0_mode ),
		.timer1_ch0_flt_o        ( s_timer1_apb_ch0_flt  ),
		.timer1_ch0_th_o         ( s_timer1_apb_ch0_th   ),
		.timer1_ch0_lut_o        ( s_timer1_apb_ch0_lut  ),
		.timer1_ch1_mode_o       ( s_timer1_apb_ch1_mode ),
		.timer1_ch1_flt_o        ( s_timer1_apb_ch1_flt  ),
		.timer1_ch1_th_o         ( s_timer1_apb_ch1_th   ),
		.timer1_ch1_lut_o        ( s_timer1_apb_ch1_lut  ),
		.timer1_ch2_mode_o       ( s_timer1_apb_ch2_mode ),
		.timer1_ch2_flt_o        ( s_timer1_apb_ch2_flt  ),
		.timer1_ch2_th_o         ( s_timer1_apb_ch2_th   ),
		.timer1_ch2_lut_o        ( s_timer1_apb_ch2_lut  ),
		.timer1_ch3_mode_o       ( s_timer1_apb_ch3_mode ),
		.timer1_ch3_flt_o        ( s_timer1_apb_ch3_flt  ),
		.timer1_ch3_th_o         ( s_timer1_apb_ch3_th   ),
		.timer1_ch3_lut_o        ( s_timer1_apb_ch3_lut  ),
		.timer1_counter_i        ( s_timer1_counter      ),

    	.timer2_start_o          ( s_timer2_apb_start    ),
    	.timer2_stop_o           ( s_timer2_apb_stop     ),
		.timer2_arm_o            ( s_timer2_apb_arm      ),
		.timer2_update_o         ( s_timer2_apb_update   ),
		.timer2_rst_o            ( s_timer2_apb_rst      ),
		.timer2_saw_o            ( s_timer2_apb_saw      ),
		.timer2_in_sel_o         ( s_timer2_apb_in_sel   ),
		.timer2_in_clk_o         ( s_timer2_apb_in_clk   ),
		.timer2_in_mode_o        ( s_timer2_apb_in_mode  ),
		.timer2_presc_o          ( s_timer2_apb_presc    ),
		.timer2_th_hi_o          ( s_timer2_apb_th_hi    ),
		.timer2_th_low_o         ( s_timer2_apb_th_low   ),
		.timer2_ch0_mode_o       ( s_timer2_apb_ch0_mode ),
		.timer2_ch0_flt_o        ( s_timer2_apb_ch0_flt  ),
		.timer2_ch0_th_o         ( s_timer2_apb_ch0_th   ),
		.timer2_ch0_lut_o        ( s_timer2_apb_ch0_lut  ),
		.timer2_ch1_mode_o       ( s_timer2_apb_ch1_mode ),
		.timer2_ch1_flt_o        ( s_timer2_apb_ch1_flt  ),
		.timer2_ch1_th_o         ( s_timer2_apb_ch1_th   ),
		.timer2_ch1_lut_o        ( s_timer2_apb_ch1_lut  ),
		.timer2_ch2_mode_o       ( s_timer2_apb_ch2_mode ),
		.timer2_ch2_flt_o        ( s_timer2_apb_ch2_flt  ),
		.timer2_ch2_th_o         ( s_timer2_apb_ch2_th   ),
		.timer2_ch2_lut_o        ( s_timer2_apb_ch2_lut  ),
		.timer2_ch3_mode_o       ( s_timer2_apb_ch3_mode ),
		.timer2_ch3_flt_o        ( s_timer2_apb_ch3_flt  ),
		.timer2_ch3_th_o         ( s_timer2_apb_ch3_th   ),
		.timer2_ch3_lut_o        ( s_timer2_apb_ch3_lut  ),
		.timer2_counter_i        ( s_timer2_counter      ),

    	.timer3_start_o          ( s_timer3_apb_start    ),
    	.timer3_stop_o           ( s_timer3_apb_stop     ),
		.timer3_arm_o            ( s_timer3_apb_arm      ),
		.timer3_update_o         ( s_timer3_apb_update   ),
		.timer3_rst_o            ( s_timer3_apb_rst      ),
		.timer3_saw_o            ( s_timer3_apb_saw      ),
		.timer3_in_sel_o         ( s_timer3_apb_in_sel   ),
		.timer3_in_clk_o         ( s_timer3_apb_in_clk   ),
		.timer3_in_mode_o        ( s_timer3_apb_in_mode  ),
		.timer3_presc_o          ( s_timer3_apb_presc    ),
		.timer3_th_hi_o          ( s_timer3_apb_th_hi    ),
		.timer3_th_low_o         ( s_timer3_apb_th_low   ),
		.timer3_ch0_mode_o       ( s_timer3_apb_ch0_mode ),
		.timer3_ch0_flt_o        ( s_timer3_apb_ch0_flt  ),
		.timer3_ch0_th_o         ( s_timer3_apb_ch0_th   ),
		.timer3_ch0_lut_o        ( s_timer3_apb_ch0_lut  ),
		.timer3_ch1_mode_o       ( s_timer3_apb_ch1_mode ),
		.timer3_ch1_flt_o        ( s_timer3_apb_ch1_flt  ),
		.timer3_ch1_th_o         ( s_timer3_apb_ch1_th   ),
		.timer3_ch1_lut_o        ( s_timer3_apb_ch1_lut  ),
		.timer3_ch2_mode_o       ( s_timer3_apb_ch2_mode ),
		.timer3_ch2_flt_o        ( s_timer3_apb_ch2_flt  ),
		.timer3_ch2_th_o         ( s_timer3_apb_ch2_th   ),
		.timer3_ch2_lut_o        ( s_timer3_apb_ch2_lut  ),
		.timer3_ch3_mode_o       ( s_timer3_apb_ch3_mode ),
		.timer3_ch3_flt_o        ( s_timer3_apb_ch3_flt  ),
		.timer3_ch3_th_o         ( s_timer3_apb_ch3_th   ),
		.timer3_ch3_lut_o        ( s_timer3_apb_ch3_lut  ),
		.timer3_counter_i        ( s_timer3_counter      ),
		
		.timer0_clk_en_o         ( s_timer0_clk_en       ),
		.timer1_clk_en_o         ( s_timer1_clk_en       ),
		.timer2_clk_en_o         ( s_timer2_clk_en       ),
		.timer3_clk_en_o         ( s_timer3_clk_en       )
	);

/////////////////////////////////////////////////////////////////////
//
//         TIMER0
//
/////////////////////////////////////////////////////////////////////
	logic [7:0] s_timer0_status;
	logic [N_TIMEREXTSIG-1:0] s_timer0_signal;
	assign s_timer0_signal = {ch_3_o,ch_2_o,ch_1_o,ch_0_o,ext_sig_i};

    e203_clkgate i_clk_gate_timer0
    (
        .clk_in(HCLK),
        .clock_en(s_timer0_clk_en),
        .test_mode(dft_cg_enable_i),
        .clk_out(s_clk_timer0)
    );

	timer_module #(
		.NUM_BITS(TIMER_NBITS),
		.N_EXTSIG(N_TIMEREXTSIG)
	) u_tim0 (
		.clk_i            ( s_clk_timer0          ),
		.rstn_i           ( HRESETn               ),

		.cfg_start_i      ( s_timer0_apb_start    ),
		.cfg_stop_i       ( s_timer0_apb_stop     ),
		.cfg_rst_i        ( s_timer0_apb_rst      ),
		.cfg_update_i     ( s_timer0_apb_update   ),
		.cfg_arm_i        ( s_timer0_apb_arm      ),

		.cfg_sel_i        ( s_timer0_apb_in_sel   ),
		.cfg_sel_clk_i    ( s_timer0_apb_in_clk   ),
		.cfg_mode_i       ( s_timer0_apb_in_mode  ),

		.cfg_presc_i      ( s_timer0_apb_presc    ),

		.cfg_sawtooth_i   ( s_timer0_apb_saw      ),
		.cfg_cnt_start_i  ( s_timer0_apb_th_low   ),
		.cfg_cnt_end_i    ( s_timer0_apb_th_hi    ),

		.cfg_comp_ch0_i   ( s_timer0_apb_ch0_th   ),
		.cfg_comp_op_ch0_i( s_timer0_apb_ch0_mode ),
		.cfg_comp_ch1_i   ( s_timer0_apb_ch1_th   ),
		.cfg_comp_op_ch1_i( s_timer0_apb_ch1_mode ),
		.cfg_comp_ch2_i   ( s_timer0_apb_ch2_th   ),
		.cfg_comp_op_ch2_i( s_timer0_apb_ch2_mode ),
		.cfg_comp_ch3_i   ( s_timer0_apb_ch3_th   ),
		.cfg_comp_op_ch3_i( s_timer0_apb_ch3_mode ),

		.ls_clk_i         ( low_speed_clk_i       ),
		.signal_i         ( s_timer0_signal       ),

		.counter_o        ( s_timer0_counter      ),

		.pwm_o            ( ch_0_o                ),
		.status_o         ( s_timer0_status       )
	);

/////////////////////////////////////////////////////////////////////
//
//         TIMER0
//
/////////////////////////////////////////////////////////////////////
	logic [7:0] s_timer1_status;
	logic [N_TIMEREXTSIG-1:0] s_timer1_signal;
	assign s_timer1_signal = {ch_3_o,ch_2_o,ch_1_o,ch_0_o,ext_sig_i};

    e203_clkgate i_clk_gate_timer1
    (
        .clk_in(HCLK),
        .clock_en(s_timer1_clk_en),
        .test_mode(dft_cg_enable_i),
        .clk_out(s_clk_timer1)
    );
	
	timer_module #(
		.NUM_BITS(TIMER_NBITS),
		.N_EXTSIG(N_TIMEREXTSIG)
	) u_tim1 (
		.clk_i            ( s_clk_timer1          ),
		.rstn_i           ( HRESETn               ),

		.cfg_start_i      ( s_timer1_apb_start    ),
		.cfg_stop_i       ( s_timer1_apb_stop     ),
		.cfg_rst_i        ( s_timer1_apb_rst      ),
		.cfg_update_i     ( s_timer1_apb_update   ),
		.cfg_arm_i        ( s_timer1_apb_arm      ),

		.cfg_sel_i        ( s_timer1_apb_in_sel   ),
		.cfg_sel_clk_i    ( s_timer1_apb_in_clk   ),
		.cfg_mode_i       ( s_timer1_apb_in_mode  ),

		.cfg_presc_i      ( s_timer1_apb_presc    ),

		.cfg_sawtooth_i   ( s_timer1_apb_saw      ),
		.cfg_cnt_start_i  ( s_timer1_apb_th_low   ),
		.cfg_cnt_end_i    ( s_timer1_apb_th_hi    ),

		.cfg_comp_ch0_i   ( s_timer1_apb_ch0_th   ),
		.cfg_comp_op_ch0_i( s_timer1_apb_ch0_mode ),
		.cfg_comp_ch1_i   ( s_timer1_apb_ch1_th   ),
		.cfg_comp_op_ch1_i( s_timer1_apb_ch1_mode ),
		.cfg_comp_ch2_i   ( s_timer1_apb_ch2_th   ),
		.cfg_comp_op_ch2_i( s_timer1_apb_ch2_mode ),
		.cfg_comp_ch3_i   ( s_timer1_apb_ch3_th   ),
		.cfg_comp_op_ch3_i( s_timer1_apb_ch3_mode ),

		.ls_clk_i         ( low_speed_clk_i       ),
		.signal_i         ( s_timer1_signal       ),

		.counter_o        ( s_timer1_counter      ),

		.pwm_o            ( ch_1_o                ),
		.status_o         ( s_timer1_status       )
	);

/////////////////////////////////////////////////////////////////////
//
//         TIMER2
//
/////////////////////////////////////////////////////////////////////
	logic [7:0] s_timer2_status;
	logic [N_TIMEREXTSIG-1:0] s_timer2_signal;
	assign s_timer2_signal = {ch_3_o,ch_2_o,ch_1_o,ch_0_o,ext_sig_i};

    e203_clkgate i_clk_gate_timer2
    (
        .clk_in(HCLK),
        .clock_en(s_timer2_clk_en),
        .test_mode(dft_cg_enable_i),
        .clk_out(s_clk_timer2)
    );


	timer_module #(
		.NUM_BITS(TIMER_NBITS),
		.N_EXTSIG(N_TIMEREXTSIG)
	) u_tim2 (
		.clk_i            ( s_clk_timer2          ),
		.rstn_i           ( HRESETn               ),

		.cfg_start_i      ( s_timer2_apb_start    ),
		.cfg_stop_i       ( s_timer2_apb_stop     ),
		.cfg_rst_i        ( s_timer2_apb_rst      ),
		.cfg_update_i     ( s_timer2_apb_update   ),
		.cfg_arm_i        ( s_timer2_apb_arm      ),

		.cfg_sel_i        ( s_timer2_apb_in_sel   ),
		.cfg_sel_clk_i    ( s_timer2_apb_in_clk   ),
		.cfg_mode_i       ( s_timer2_apb_in_mode  ),

		.cfg_presc_i      ( s_timer2_apb_presc    ),

		.cfg_sawtooth_i   ( s_timer2_apb_saw      ),
		.cfg_cnt_start_i  ( s_timer2_apb_th_low   ),
		.cfg_cnt_end_i    ( s_timer2_apb_th_hi    ),

		.cfg_comp_ch0_i   ( s_timer2_apb_ch0_th   ),
		.cfg_comp_op_ch0_i( s_timer2_apb_ch0_mode ),
		.cfg_comp_ch1_i   ( s_timer2_apb_ch1_th   ),
		.cfg_comp_op_ch1_i( s_timer2_apb_ch1_mode ),
		.cfg_comp_ch2_i   ( s_timer2_apb_ch2_th   ),
		.cfg_comp_op_ch2_i( s_timer2_apb_ch2_mode ),
		.cfg_comp_ch3_i   ( s_timer2_apb_ch3_th   ),
		.cfg_comp_op_ch3_i( s_timer2_apb_ch3_mode ),

		.ls_clk_i         ( low_speed_clk_i       ),
		.signal_i         ( s_timer2_signal       ),

		.counter_o        ( s_timer2_counter      ),

		.pwm_o            ( ch_2_o                ),
		.status_o         ( s_timer2_status       )
	);

/////////////////////////////////////////////////////////////////////
//
//         TIMER3
//
/////////////////////////////////////////////////////////////////////
	logic [7:0] s_timer3_status;
	logic [N_TIMEREXTSIG-1:0] s_timer3_signal;
	assign s_timer3_signal = {ch_3_o,ch_2_o,ch_1_o,ch_0_o,ext_sig_i};

    e203_clkgate i_clk_gate_timer3
    (
        .clk_in(HCLK),
        .clock_en(s_timer3_clk_en),
        .test_mode(dft_cg_enable_i),
        .clk_out(s_clk_timer3)
    );


	timer_module #(
		.NUM_BITS(TIMER_NBITS),
		.N_EXTSIG(N_TIMEREXTSIG)
	) u_tim3 (
		.clk_i            ( s_clk_timer3          ),
		.rstn_i           ( HRESETn               ),

		.cfg_start_i      ( s_timer3_apb_start    ),
		.cfg_stop_i       ( s_timer3_apb_stop     ),
		.cfg_rst_i        ( s_timer3_apb_rst      ),
		.cfg_update_i     ( s_timer3_apb_update   ),
		.cfg_arm_i        ( s_timer3_apb_arm      ),

		.cfg_sel_i        ( s_timer3_apb_in_sel   ),
		.cfg_sel_clk_i    ( s_timer3_apb_in_clk   ),
		.cfg_mode_i       ( s_timer3_apb_in_mode  ),

		.cfg_presc_i      ( s_timer3_apb_presc    ),

		.cfg_sawtooth_i   ( s_timer3_apb_saw      ),
		.cfg_cnt_start_i  ( s_timer3_apb_th_low   ),
		.cfg_cnt_end_i    ( s_timer3_apb_th_hi    ),

		.cfg_comp_ch0_i   ( s_timer3_apb_ch0_th   ),
		.cfg_comp_op_ch0_i( s_timer3_apb_ch0_mode ),
		.cfg_comp_ch1_i   ( s_timer3_apb_ch1_th   ),
		.cfg_comp_op_ch1_i( s_timer3_apb_ch1_mode ),
		.cfg_comp_ch2_i   ( s_timer3_apb_ch2_th   ),
		.cfg_comp_op_ch2_i( s_timer3_apb_ch2_mode ),
		.cfg_comp_ch3_i   ( s_timer3_apb_ch3_th   ),
		.cfg_comp_op_ch3_i( s_timer3_apb_ch3_mode ),

		.ls_clk_i         ( low_speed_clk_i       ),
		.signal_i         ( s_timer3_signal       ),

		.counter_o        ( s_timer3_counter      ),

		.pwm_o            ( ch_3_o                ),
		.status_o         ( s_timer3_status       )
	);

	logic [15:0] s_event_signals;
	logic  [1:0] r_event_sync_0;
	logic  [1:0] r_event_sync_1;
	logic  [1:0] r_event_sync_2;
	logic  [1:0] r_event_sync_3;

	assign s_event_signals = {ch_3_o,ch_2_o,ch_1_o,ch_0_o};

	assign events_o[0] = s_event_en[0] & r_event_sync_0[1] & ~r_event_sync_0[0];
	assign events_o[1] = s_event_en[1] & r_event_sync_1[1] & ~r_event_sync_1[0];
	assign events_o[2] = s_event_en[2] & r_event_sync_2[1] & ~r_event_sync_2[0];
	assign events_o[3] = s_event_en[3] & r_event_sync_3[1] & ~r_event_sync_3[0];

	always_ff @(posedge HCLK or negedge HRESETn) begin : proc_edgedet
		if(~HRESETn) begin
			r_event_sync_0 <= 0;
			r_event_sync_1 <= 0;
			r_event_sync_2 <= 0;
			r_event_sync_3 <= 0;
		end else begin
			if (s_event_en[0])
				r_event_sync_0 <= {s_event_signals[s_event_sel_0],r_event_sync_0[1]};
			if (s_event_en[1])
				r_event_sync_1 <= {s_event_signals[s_event_sel_1],r_event_sync_1[1]};
			if (s_event_en[2])
				r_event_sync_2 <= {s_event_signals[s_event_sel_2],r_event_sync_2[1]};
			if (s_event_en[3])
				r_event_sync_3 <= {s_event_signals[s_event_sel_3],r_event_sync_3[1]};
		end
	end

endmodule // apb_adv_timer
