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

module prescaler (
    input  wire       clk_i,
    input  wire       rstn_i,
    input  wire       ctrl_active_i,
    input  wire       ctrl_update_i,
    input  wire       ctrl_rst_i,
    input  wire [7:0] cfg_presc_i,
    input  wire       event_i,
    output reg        event_o
);

    reg [7:0] r_presc;
    reg [7:0] r_counter;

    always @(posedge clk_i or negedge rstn_i) begin : proc_r_presc
        if (~rstn_i)
            r_presc <= 0;
        else if (ctrl_update_i)    //if first enable or explicit update is iven
            r_presc <= cfg_presc_i;
    end


    always @(posedge clk_i or negedge rstn_i) begin : proc_r_counter
        if (~rstn_i) begin
            r_counter <= 0;
            event_o   <= 0;
	end else if (ctrl_rst_i) begin
            r_counter <= 0;
            event_o   <= 0;
	end else if (ctrl_active_i) begin
            if (event_i) begin
		if (r_presc == 0) begin
                    event_o   <= 1'b1;
		end else if (r_counter == r_presc) begin
                    event_o   <= 1'b1;
                    r_counter <= 0;
		end else begin
                    event_o   <= 1'b0;
                    r_counter <= r_counter + 1;
                end
	    end else begin
                event_o <= 1'b0;
	    end
	end else begin
            r_counter <= 0;
            event_o   <= 0;
        end
    end


endmodule
