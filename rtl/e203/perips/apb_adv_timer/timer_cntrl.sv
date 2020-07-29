// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

module timer_cntrl (
	input  logic       clk_i,
	input  logic       rstn_i,

	input  logic       cfg_start_i,
	input  logic       cfg_stop_i,
	input  logic       cfg_rst_i,
	input  logic       cfg_update_i,
	input  logic       cfg_arm_i,

	output logic       ctrl_cnt_upd_o,
	output logic       ctrl_all_upd_o,
	output logic       ctrl_active_o,
	output logic       ctrl_rst_o,
	output logic       ctrl_arm_o,

	input  logic       cnt_update_i,

	output logic [7:0] status_o
);

	logic r_active;
	logic r_pending;

	assign ctrl_arm_o = cfg_arm_i;

	assign status_o = {6'h0,r_pending};

	assign ctrl_active_o = r_active;

	always_comb begin : proc_sm
		if (cfg_start_i && !r_active)
		begin
			ctrl_rst_o     = 1'b1;
			ctrl_cnt_upd_o = 1'b1;
			ctrl_all_upd_o = 1'b1;
		end
		else
		begin
			ctrl_rst_o     = cfg_rst_i;
			ctrl_cnt_upd_o = cfg_update_i;
			ctrl_all_upd_o = cnt_update_i;			
		end
	
	end

	always_ff @(posedge clk_i or negedge rstn_i) begin : proc_r_active
		if(~rstn_i) begin
			r_active <= 0;
			r_pending <= 0;
		end else begin
			if (cfg_start_i)
				r_active <= 1;
			else if (cfg_stop_i)
				r_active <= 0;
			if (cnt_update_i && !cfg_update_i)
			begin
				r_pending <= 0;
			end
			else if(cfg_update_i)
			begin
				r_pending <= 1;
			end
		end
	end
endmodule