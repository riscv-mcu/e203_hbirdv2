// Copyright 2018 ETH Zurich and University of Bologna.
// -- Adaptable modifications made for hbirdv2 SoC. -- 
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

`define OP_SET    3'b000
`define OP_TOGRST 3'b001
`define OP_SETRST 3'b010
`define OP_TOG    3'b011
`define OP_RST    3'b100
`define OP_TOGSET 3'b101
`define OP_RSTSET 3'b110


module comparator #(
	parameter NUM_BITS = 16
) (
    input  wire                  clk_i,
    input  wire                  rstn_i,
    input  wire                  ctrl_active_i,
    input  wire                  ctrl_update_i,
    input  wire                  ctrl_rst_i,
    input  wire [NUM_BITS - 1:0] cfg_comp_i,
    input  wire [2:0]            cfg_comp_op_i,
    input  wire                  timer_end_i,
    input  wire                  timer_valid_i,
    input  wire                  timer_sawtooth_i,
    input  wire [NUM_BITS - 1:0] timer_count_i,
    output wire                  result_o
);

    reg [NUM_BITS - 1:0] r_comp;
    reg [2:0]            r_comp_op;
    
    reg                  r_value;
    wire                 r_active;
    reg                  r_is_2nd_event;

    wire                 s_match;
    wire                 s_2nd_event;

    assign s_match     = timer_valid_i & (r_comp == timer_count_i);
    assign s_2nd_event = timer_sawtooth_i ? timer_end_i : s_match;
    assign result_o    = r_value;

    always @(posedge clk_i or negedge rstn_i) begin : proc_r_comp
        if (~rstn_i) begin
            r_comp    <= 0;
            r_comp_op <= 0;
	end else if (ctrl_update_i) begin   //if first enable or explicit update is iven
            r_comp    <= cfg_comp_i;
            r_comp_op <= cfg_comp_op_i;
        end
    end

    always @(posedge clk_i or negedge rstn_i) begin : proc_r_value
        if (~rstn_i) begin
            r_value        <= 0;
            r_is_2nd_event <= 1'b0;
	end else if (ctrl_rst_i) begin
            r_value        <= 1'b0;
            r_is_2nd_event <= 1'b0;
        end else if (timer_valid_i && ctrl_active_i) begin
	    case(r_comp_op)
	        `OP_SET:
	            r_value <= s_match ? 1'b1 : r_value;
	        `OP_TOGRST:
	        begin
		    if(timer_sawtooth_i) begin
	                if(s_match)
	                    r_value <= ~r_value;
	                else if(s_2nd_event)
	                    r_value <= 1'b0;
	            end else begin
			if(s_match && !r_is_2nd_event) begin
	            	    r_value        <= ~r_value;
	            	    r_is_2nd_event <= 1'b1;
			end else if(s_match && r_is_2nd_event) begin
	            	    r_value        <= 1'b0;
	            	    r_is_2nd_event <= 1'b0;
	            	end
	            end
	        end
	        `OP_SETRST:
	        begin
		    if(timer_sawtooth_i) begin
	                if(s_match)
	                    r_value <= 1'b1;
	                else if(s_2nd_event)
	                    r_value <= 1'b0;
	            end else begin
		        if(s_match && !r_is_2nd_event) begin
	                    r_value        <= 1'b1;
	                    r_is_2nd_event <= 1'b1;
		        end else if(s_match && r_is_2nd_event) begin
	                    r_value        <= 1'b0;
	                    r_is_2nd_event <= 1'b0;
	                end
	            end
	        end
	        `OP_TOG:
	             r_value <= s_match ? ~r_value : r_value;
	        `OP_RST:
	             r_value <= s_match ? 1'b0 : r_value;
	        `OP_TOGSET:
	        begin
		    if(timer_sawtooth_i) begin
	                if(s_match)
	               	    r_value <= ~r_value;
	                else if(s_2nd_event)
	               	    r_value <= 1'b1;
		    end else begin
		        if(s_match && !r_is_2nd_event) begin
	                    r_value        <= ~r_value;
	                    r_is_2nd_event <= 1'b1;
		        end else if(s_match && r_is_2nd_event) begin
	                    r_value        <= 1'b1;
	                    r_is_2nd_event <= 1'b0;
	                end
	            end
	        end
	        `OP_RSTSET:
	        begin
	            if(timer_sawtooth_i) begin
	                if(s_match)
	                    r_value <= 1'b0;
	                else if(s_2nd_event)
	                    r_value <= 1'b1;
	            end else begin
		        if(s_match && !r_is_2nd_event) begin
	            	    r_value <= 1'b0;
	            	    r_is_2nd_event <= 1'b1;
		        end else if(s_match && r_is_2nd_event) begin
	            	    r_value <= 1'b1;
	            	    r_is_2nd_event <= 1'b0;
	            	end
	            end
	        end
	        default:
	        begin
	            r_value        <= r_value;
	            r_is_2nd_event <= 1'b0;
	        end
	    endcase // r_comp_op
	end
    end
endmodule
