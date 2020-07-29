// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

module input_stage #(
    parameter EXTSIG_NUM = 32
) (
    input  logic                clk_i,
    input  logic                rstn_i,

    input  logic                ctrl_active_i,
    input  logic                ctrl_update_i,

    input  logic                ctrl_arm_i,

    input  logic                cnt_end_i,

    input  logic          [7:0] cfg_sel_i,
    input  logic                cfg_sel_clk_i,
    input  logic          [2:0] cfg_mode_i,

    input  logic                ls_clk_i,
    input  logic  [EXTSIG_NUM-1:0] signal_i,
    output logic                event_o

);

    logic s_rise;
    logic s_rise_ls_clk;
    logic s_fall;
    logic s_int_evnt;
    logic s_event;

    logic                r_active;
    logic                r_event;
    logic                r_oldval;
    logic                s_int_sig;
    logic          [7:0] r_sel; 
    logic          [2:0] r_mode;
    logic                r_armed;
    logic          [2:0] r_ls_clk_sync;


    assign s_rise = ~r_oldval &  s_int_sig;
    assign s_fall =  r_oldval & ~s_int_sig;
    assign s_rise_ls_clk = ~r_ls_clk_sync[2] & r_ls_clk_sync[1];

    always_ff @(posedge clk_i or negedge rstn_i) begin : proc_r_ls_clk_sync
        if(~rstn_i) begin
            r_ls_clk_sync <= 'h0;
        end else begin
            r_ls_clk_sync <= {r_ls_clk_sync[1:0],ls_clk_i};
        end
    end

    always_ff @(posedge clk_i or negedge rstn_i) begin : proc_r_mode
        if(~rstn_i) begin
            r_mode    <= 0;
            r_sel     <= 0;
        end else begin
            if (ctrl_update_i)
            begin
                r_mode    <= cfg_mode_i;
                r_sel     <= cfg_sel_i; 
            end
        end
    end

    always_comb begin : proc_event_o
        if(cfg_sel_clk_i)
            event_o = s_int_evnt & s_rise_ls_clk;
        else
            event_o = s_int_evnt;
    end

    always_comb begin : proc_s_int_evnt
        case (r_mode)
            3'b000:
                s_int_evnt = 1'b1;          
            3'b001:
                s_int_evnt = ~s_int_sig;
            3'b010:
                s_int_evnt = s_int_sig;
            3'b011:
                s_int_evnt = s_rise;
            3'b100:
                s_int_evnt = s_fall;
            3'b101:
                s_int_evnt = s_rise | s_fall;
            3'b110:
            begin
                if(r_armed)
                    s_int_evnt = s_rise ? 1'b1 : r_event;
                else
                    s_int_evnt = 1'b0;
            end
            3'b111:
            begin
                if(r_armed)
                    s_int_evnt = s_fall ? 1'b1 : r_event;
                else
                    s_int_evnt = 1'b0;
            end
        endcase // cfg_mode_i
    end


    always_comb begin : proc_int_sig
        s_int_sig = 0;
        for (int i=0;i<EXTSIG_NUM;i++)
        begin
            if (r_sel == i)
                s_int_sig = signal_i[i];
        end
    end

    always_ff @(posedge clk_i or negedge rstn_i) begin : proc_r_event
        if(~rstn_i) begin
            r_event <= 1'b0;
            r_armed <= 1'b0;
        end else begin
            if (r_armed)
                r_event <= s_int_evnt;
            else if(cnt_end_i)
                r_event <= 1'b0;
            if (ctrl_arm_i)
                r_armed <= 1'b1;
            else if(cnt_end_i)
                r_armed <= 1'b0;
        end
    end

    always_ff @(posedge clk_i or negedge rstn_i) begin : proc_r_sync
        if(~rstn_i) begin
            r_oldval <= 0;
        end else begin
            if (ctrl_active_i)
            begin
                if (!cfg_sel_clk_i || (cfg_sel_clk_i && s_rise_ls_clk))
                    r_oldval <= s_int_sig;
            end
        end
    end



endmodule // input_stage