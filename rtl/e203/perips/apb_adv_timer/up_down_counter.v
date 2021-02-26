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

module up_down_counter #(
    parameter NUM_BITS = 16
)
(
    input  wire                  clk_i,
    input  wire                  rstn_i,

    input  wire                  cfg_sawtooth_i,
    input  wire [NUM_BITS - 1:0] cfg_start_i,
    input  wire [NUM_BITS - 1:0] cfg_end_i,

    input  wire                  ctrl_update_i,
    input  wire                  ctrl_rst_i,
    input  wire                  ctrl_active_i,

    input  wire                  counter_event_i,

    output wire                  counter_end_o,
    output wire                  counter_saw_o,
    output wire                  counter_evt_o,
    output wire [NUM_BITS - 1:0] counter_o
);

    reg [NUM_BITS - 1:0] r_counter;
    reg [NUM_BITS - 1:0] r_start;
    reg [NUM_BITS - 1:0] r_end;

    reg [NUM_BITS - 1:0] s_counter;
    reg [NUM_BITS - 1:0] s_start;
    reg [NUM_BITS - 1:0] s_end;

    reg                  r_direction;    //0 = count up | 1 = count down
    reg                  r_sawtooth;
    reg                  r_event;

    reg                  s_direction;    //0 = count up | 1 = count down
    reg                  s_sawtooth;

    wire                 s_is_update;
    reg                  s_do_update;
    reg                  s_pending_update;
    reg                  r_pending_update;


    assign counter_o     = r_counter;
    assign counter_saw_o = r_sawtooth;
    assign counter_evt_o = ctrl_active_i & r_event;
    assign counter_end_o = (ctrl_active_i & r_event) & s_is_update;

    assign s_is_update   = r_sawtooth ? (r_counter == r_end) : (r_direction && (r_counter == (r_start - 1)));

    always @(posedge clk_i or negedge rstn_i) begin : proc_r_event
        if (~rstn_i) begin
            r_event          <= 0;
            r_pending_update <= 0;
	end else begin
            r_pending_update <= s_pending_update;
            if (ctrl_active_i)
                r_event <= counter_event_i;
        end
    end


    always @(*) begin : proc_s_do_update
        s_pending_update = r_pending_update;
        s_do_update      = 0;

        if (ctrl_update_i || r_pending_update) begin
            if (ctrl_update_i && !ctrl_active_i) begin
                s_pending_update = 0;
                s_do_update      = 1;
	    end else if (s_is_update) begin
                s_pending_update = 0;
                s_do_update      = counter_event_i;
	    end else begin
                s_pending_update = 1;
                s_do_update      = 0;
            end
	end else if (ctrl_rst_i) begin
            s_pending_update = 0;
            s_do_update      = 1;
        end
    end


    always @(*) begin : proc_s_counter
        s_counter   = r_counter;
        s_start     = r_start;
        s_sawtooth  = r_sawtooth;
        s_end       = r_end;
        s_direction = r_direction;

        if (s_do_update) begin
            s_counter   = cfg_start_i;
            s_start     = cfg_start_i;
            s_sawtooth  = cfg_sawtooth_i;
            s_end       = cfg_end_i;
            s_direction = 1'b0;
        end else if (counter_event_i && ctrl_active_i) begin
            if (!r_direction && (r_counter == r_end)) begin
                if (r_sawtooth) begin
                    s_counter   = r_start;
                    s_direction = 1'b0;
		end else begin
                    s_counter   = r_counter - 1;
                    s_direction = 1'b1;
                end
	    end else if (r_direction && (r_counter == r_start)) begin
                s_counter   = r_counter + 1;
                s_direction = 1'b0;
	    end else if (r_direction) begin
                s_counter = r_counter - 1;
	    end else begin
                s_counter = r_counter + 1;
	    end
	end
    end


    always @(posedge clk_i or negedge rstn_i) begin : proc_r_counter
        if (~rstn_i) begin
            r_counter   <= 0;
            r_start     <= 0;
            r_end       <= 0;
            r_direction <= 0;
            r_sawtooth  <= 1'b1;
	end else begin
            if (s_do_update || (counter_event_i && ctrl_active_i)) begin
                r_counter   <= s_counter;
                r_direction <= s_direction;
            end

            if (s_do_update) begin
                r_start    <= s_start;
                r_end      <= s_end;
                r_sawtooth <= s_sawtooth;
            end
        end
    end


endmodule
