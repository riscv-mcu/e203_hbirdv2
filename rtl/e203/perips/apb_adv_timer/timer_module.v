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


module timer_module #(
	parameter NUM_BITS = 16,
	parameter N_EXTSIG = 32
) (
    input  wire                  clk_i,
    input  wire                  rstn_i,

    input  wire                  cfg_start_i,
    input  wire                  cfg_stop_i,
    input  wire                  cfg_rst_i,
    input  wire                  cfg_update_i,
    input  wire                  cfg_arm_i,
    input  wire [7:0]            cfg_sel_i,
    input  wire                  cfg_sel_clk_i,
    input  wire [2:0]            cfg_mode_i,
    input  wire [7:0]            cfg_presc_i,
    input  wire                  cfg_sawtooth_i,
    input  wire [NUM_BITS - 1:0] cfg_cnt_start_i,
    input  wire [NUM_BITS - 1:0] cfg_cnt_end_i,
    input  wire [NUM_BITS - 1:0] cfg_comp_ch0_i,
    input  wire [2:0]            cfg_comp_op_ch0_i,
    input  wire [NUM_BITS - 1:0] cfg_comp_ch1_i,
    input  wire [2:0]            cfg_comp_op_ch1_i,
    input  wire [NUM_BITS - 1:0] cfg_comp_ch2_i,
    input  wire [2:0]            cfg_comp_op_ch2_i,
    input  wire [NUM_BITS - 1:0] cfg_comp_ch3_i,
    input  wire [2:0]            cfg_comp_op_ch3_i,
    
    input  wire                  ls_clk_i,
    input  wire [N_EXTSIG - 1:0] signal_i,
    
    output wire [NUM_BITS - 1:0] counter_o,
    output wire [3:0]            pwm_o,
    output wire [7:0]            status_o
);

    wire                  s_ctrl_update_cnt;
    wire                  s_ctrl_update_all;
    wire                  s_ctrl_active;
    wire                  s_ctrl_rst;
    wire                  s_ctrl_arm;
    wire                  s_cnt_update;    //FIXME ANTONIO CONNECT ME
    wire                  s_in_evt;
    wire                  s_presc_evt;
    wire                  s_cnt_end;
    wire                  s_cnt_saw;
    wire                  s_cnt_evt;
    wire [NUM_BITS - 1:0] s_cnt;

    assign counter_o = s_cnt;

    timer_cntrl u_controller
    (
        .clk_i          ( clk_i             ),
        .rstn_i         ( rstn_i            ),
        
        .cfg_start_i    ( cfg_start_i       ),
        .cfg_stop_i     ( cfg_stop_i        ),
        .cfg_rst_i      ( cfg_rst_i         ),
        .cfg_update_i   ( cfg_update_i      ),
        .cfg_arm_i      ( cfg_arm_i         ),
        
        .ctrl_cnt_upd_o ( s_ctrl_update_cnt ),
        .ctrl_all_upd_o ( s_ctrl_update_all ),
        .ctrl_active_o  ( s_ctrl_active     ),
        .ctrl_rst_o     ( s_ctrl_rst        ),
        .ctrl_arm_o     ( s_ctrl_arm        ),
        
        .cnt_update_i   ( s_cnt_evt         ),
        
        .status_o       ( status_o          )
    
    );
    
    input_stage #(
        .EXTSIG_NUM(N_EXTSIG)
    ) u_in_stage (
        .clk_i         ( clk_i             ),
        .rstn_i        ( rstn_i            ),
        
        .ctrl_update_i ( s_ctrl_update_all ),
        .ctrl_active_i ( s_ctrl_active     ),
        .ctrl_arm_i    ( s_ctrl_arm        ),
        
        .cnt_end_i     ( s_cnt_end 	   ),
        
        .cfg_sel_i     ( cfg_sel_i         ),
        .cfg_sel_clk_i ( cfg_sel_clk_i     ),
        .cfg_mode_i    ( cfg_mode_i        ),
        
        .ls_clk_i      ( ls_clk_i 	   ),
        
        .signal_i      ( signal_i          ),
        .event_o       ( s_in_evt          )
    
    );
    
    prescaler u_prescaler
    (
        .clk_i             ( clk_i             ),
        .rstn_i            ( rstn_i            ),
        
        .ctrl_update_i     ( s_ctrl_update_all ),
        .ctrl_active_i     ( s_ctrl_active     ),
        .ctrl_rst_i        ( s_ctrl_rst        ),
        
        .cfg_presc_i       ( cfg_presc_i       ),
        
        .event_i           ( s_in_evt          ),
        .event_o           ( s_presc_evt       )
    );
    
    up_down_counter u_counter
    (
        .clk_i             ( clk_i             ),
        .rstn_i            ( rstn_i            ),
        
        .ctrl_update_i     ( s_ctrl_update_cnt ),
        .ctrl_rst_i        ( s_ctrl_rst        ),
        .ctrl_active_i     ( s_ctrl_active     ),
        
        .cfg_sawtooth_i    ( cfg_sawtooth_i    ),
        .cfg_start_i       ( cfg_cnt_start_i   ),
        .cfg_end_i         ( cfg_cnt_end_i     ),
        
        .counter_event_i   ( s_presc_evt       ),
        .counter_end_o     ( s_cnt_end         ),
        .counter_saw_o     ( s_cnt_saw         ),
        .counter_evt_o     ( s_cnt_evt         ),
        .counter_o         ( s_cnt             )
    );
    
    comparator u_comp_ch0
    (
        .clk_i             ( clk_i             ),
        .rstn_i            ( rstn_i            ),
        
        .ctrl_update_i     ( s_ctrl_update_all ),
        .ctrl_active_i     ( s_ctrl_active     ),
        .ctrl_rst_i        ( s_ctrl_rst        ),
        
        .timer_end_i       ( s_cnt_end         ),
        .timer_valid_i     ( s_cnt_evt         ),
        .timer_sawtooth_i  ( s_cnt_saw         ),
        .timer_count_i     ( s_cnt             ),
        
        .cfg_comp_op_i     ( cfg_comp_op_ch0_i ),
        .cfg_comp_i        ( cfg_comp_ch0_i    ),
        
        .result_o          ( pwm_o[0]          )
    );
    
    comparator u_comp_ch1
    (
        .clk_i             ( clk_i             ),
        .rstn_i            ( rstn_i            ),
        
        .ctrl_update_i     ( s_ctrl_update_all ),
        .ctrl_active_i     ( s_ctrl_active     ),
        .ctrl_rst_i        ( s_ctrl_rst        ),
        
        .timer_end_i       ( s_cnt_end         ),
        .timer_valid_i     ( s_cnt_evt         ),
        .timer_sawtooth_i  ( s_cnt_saw         ),
        .timer_count_i     ( s_cnt             ),
        
        .cfg_comp_op_i     ( cfg_comp_op_ch1_i ),
        .cfg_comp_i        ( cfg_comp_ch1_i    ),
        
        .result_o          ( pwm_o[1]          )
    );
    
    comparator u_comp_ch2
    (
        .clk_i             ( clk_i             ),
        .rstn_i            ( rstn_i            ),
        
        .ctrl_update_i     ( s_ctrl_update_all ),
        .ctrl_active_i     ( s_ctrl_active     ),
        .ctrl_rst_i        ( s_ctrl_rst        ),
        
        .timer_end_i       ( s_cnt_end         ),
        .timer_valid_i     ( s_cnt_evt         ),
        .timer_sawtooth_i  ( s_cnt_saw         ),
        .timer_count_i     ( s_cnt             ),
        
        .cfg_comp_op_i     ( cfg_comp_op_ch2_i ),
        .cfg_comp_i        ( cfg_comp_ch2_i    ),
        
        .result_o          ( pwm_o[2]          )
    );
    
    comparator u_comp_ch3
    (
        .clk_i             ( clk_i             ),
        .rstn_i            ( rstn_i            ),
        
        .ctrl_update_i     ( s_ctrl_update_all ),
        .ctrl_active_i     ( s_ctrl_active     ),
        .ctrl_rst_i        ( s_ctrl_rst        ),
        
        .timer_end_i       ( s_cnt_end         ),
        .timer_valid_i     ( s_cnt_evt         ),
        .timer_sawtooth_i  ( s_cnt_saw         ),
        .timer_count_i     ( s_cnt             ),
        
        .cfg_comp_op_i     ( cfg_comp_op_ch3_i ),
        .cfg_comp_i        ( cfg_comp_ch3_i    ),
        
        .result_o          ( pwm_o[3]          )
    );


endmodule
