// Copyright 2017 ETH Zurich and University of Bologna.
// -- Adaptable modifications made for hbirdv2 SoC. -- 
// Copyright 2020 Nuclei System Technology, Inc.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

module uart_rx (
    input  wire        clk_i,
    input  wire        rstn_i,
    input  wire        rx_i,
    input  wire [15:0] cfg_div_i,
    input  wire        cfg_en_i,
    input  wire        cfg_parity_en_i,
    input  wire [1:0]  cfg_parity_sel_i,
    input  wire [1:0]  cfg_bits_i,
    // input  wire        cfg_stop_bits_i,
    output wire        busy_o,
    output reg         err_o,
    input  wire        err_clr_i,
    output wire [7:0]  rx_data_o,
    output reg         rx_valid_o,
    input  wire        rx_ready_i
);

    localparam [2:0] IDLE      = 0;
    localparam [2:0] START_BIT = 1;
    localparam [2:0] DATA      = 2;
    localparam [2:0] SAVE_DATA = 3;
    localparam [2:0] PARITY    = 4;
    localparam [2:0] STOP_BIT  = 5;

    reg [2:0]  CS, NS;

    reg [7:0]  reg_data;
    reg [7:0]  reg_data_next;
    reg [2:0]  reg_rx_sync;
    reg [2:0]  reg_bit_count;
    reg [2:0]  reg_bit_count_next;

    reg [2:0]  s_target_bits;

    reg        parity_bit;
    reg        parity_bit_next;

    reg        sampleData;

    reg [15:0] baud_cnt;
    reg        baudgen_en;
    reg        bit_done;

    reg        start_bit;
    reg        set_error;
    wire       s_rx_fall;

    assign busy_o = (CS != IDLE);

    always @(*) begin
        case (cfg_bits_i)
            2'b00: s_target_bits = 3'h4;
            2'b01: s_target_bits = 3'h5;
            2'b10: s_target_bits = 3'h6;
            2'b11: s_target_bits = 3'h7;
        endcase
    end


    always @(*) begin
        NS = CS;
        sampleData = 1'b0;
        reg_bit_count_next = reg_bit_count;
        reg_data_next = reg_data;
        rx_valid_o = 1'b0;
        baudgen_en = 1'b0;
        start_bit = 1'b0;
        parity_bit_next = parity_bit;
        set_error = 1'b0;

        case (CS)
	    IDLE: begin
                if (s_rx_fall) begin
                    NS         = START_BIT;
                    baudgen_en = 1'b1;
                    start_bit  = 1'b1;
                end
	    end
            START_BIT: begin
                parity_bit_next = 1'b0;
                baudgen_en      = 1'b1;
                start_bit       = 1'b1;
                if (bit_done) NS = DATA;
            end
            DATA: begin
                baudgen_en      = 1'b1;
                parity_bit_next = parity_bit ^ reg_rx_sync[2];

                case (cfg_bits_i)
                    2'b00: reg_data_next = {3'b0, reg_rx_sync[2], reg_data[4:1]};
                    2'b01: reg_data_next = {2'b0, reg_rx_sync[2], reg_data[5:1]};
                    2'b10: reg_data_next = {1'b0, reg_rx_sync[2], reg_data[6:1]};
                    2'b11: reg_data_next = {reg_rx_sync[2], reg_data[7:1]};
                endcase

                if (bit_done) begin
                    sampleData = 1'b1;
                    if (reg_bit_count == s_target_bits) begin
                    	reg_bit_count_next = 'h0;
                    	NS = SAVE_DATA;
	            end else begin
                    	reg_bit_count_next = reg_bit_count + 1;
		    end
                end
            end
            SAVE_DATA: begin
                baudgen_en = 1'b1;
                rx_valid_o = 1'b1;
		if (rx_ready_i) begin
                    if (cfg_parity_en_i) NS = PARITY;
                    else NS = STOP_BIT;
	        end
            end
            PARITY: begin
                baudgen_en = 1'b1;
                if (bit_done) begin
                    case (cfg_parity_sel_i)
                        2'b00:
                            if (reg_rx_sync[2] != ~parity_bit) set_error = 1'b1;
                        2'b01:
                            if (reg_rx_sync[2] != parity_bit) set_error = 1'b1;
                        2'b10:
                            if (reg_rx_sync[2] != 1'b0) set_error = 1'b1;
                        2'b11:
                            if (reg_rx_sync[2] != 1'b1) set_error = 1'b1;
                    endcase
                    NS = STOP_BIT;
                end
            end
            STOP_BIT: begin
                baudgen_en = 1'b1;
                if (bit_done) NS = IDLE;
            end
            default: NS = IDLE;
        endcase
    end


    always @(posedge clk_i or negedge rstn_i) begin
        if (rstn_i == 1'b0) begin
            CS            <= IDLE;
            reg_data      <= 8'hff;
            reg_bit_count <= 'h0;
            parity_bit    <= 1'b0;
	end else begin
            if (bit_done)
                parity_bit <= parity_bit_next;
            if (sampleData)
                reg_data <= reg_data_next;

            reg_bit_count <= reg_bit_count_next;

            if (cfg_en_i)
                CS <= NS;
            else
                CS <= IDLE;
        end
    end

    assign s_rx_fall = ~reg_rx_sync[1] & reg_rx_sync[2];

    always @(posedge clk_i or negedge rstn_i) begin
        if (rstn_i == 1'b0)
            reg_rx_sync <= 3'b111;
        else if (cfg_en_i)
            reg_rx_sync <= {reg_rx_sync[1:0], rx_i};
        else
            reg_rx_sync <= 3'b111;
    end

    always @(posedge clk_i or negedge rstn_i) begin
        if (rstn_i == 1'b0) begin
            baud_cnt <= 'h0;
            bit_done <= 1'b0;
	end else if (baudgen_en) begin
            if (!start_bit && (baud_cnt == cfg_div_i)) begin
                baud_cnt <= 'h0;
                bit_done <= 1'b1;
	    end else if (start_bit && (baud_cnt == {1'b0, cfg_div_i[15:1]})) begin
                baud_cnt <= 'h0;
                bit_done <= 1'b1;
	    end else begin
                baud_cnt <= baud_cnt + 1;
                bit_done <= 1'b0;
            end
	end else begin
            baud_cnt <= 'h0;
            bit_done <= 1'b0;
        end
    end


    always @(posedge clk_i or negedge rstn_i)
        if (rstn_i == 1'b0)
            err_o <= 1'b0;
        else if (err_clr_i)
       	    err_o <= 1'b0;
        else if (set_error)
       	    err_o <= 1'b1;

    assign rx_data_o = reg_data;

endmodule
