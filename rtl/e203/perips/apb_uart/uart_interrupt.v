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

module uart_interrupt
#(
    parameter TX_FIFO_DEPTH = 32,
    parameter RX_FIFO_DEPTH = 32
)
(
    input  wire                           clk_i,
    input  wire                           rstn_i,

    // registers
    input  wire [2:0]                     IER_i,             // interrupt enable register

    // control logic
    input  wire                           error_i,
    input  wire [$clog2(RX_FIFO_DEPTH):0] rx_elements_i,
    input  wire [$clog2(TX_FIFO_DEPTH):0] tx_elements_i,
    input  wire [1:0]                     trigger_level_i,

    input  wire [3:0]                     clr_int_i,         // one hot

    output wire                           interrupt_o,
    output wire [3:0]                     IIR_o
);

    reg [3:0] iir_n;
    reg [3:0] iir_q;
    reg trigger_level_reached;

    always @(*) begin
        trigger_level_reached = 1'b0;
        case (trigger_level_i)
            2'b00:
                if ($unsigned(rx_elements_i) == 1)
            	    trigger_level_reached = 1'b1;
            2'b01:
                if ($unsigned(rx_elements_i) == 4)
            	    trigger_level_reached = 1'b1;
            2'b10:
                if ($unsigned(rx_elements_i) == 8)
            	    trigger_level_reached = 1'b1;
            2'b11:
                if ($unsigned(rx_elements_i) == 14)
            	    trigger_level_reached = 1'b1;
        endcase
    end


    always @(*) begin
        if (clr_int_i == 4'b0) begin
            // Receive data parity error
            if (IER_i[2] & error_i)
            	iir_n = 4'b1100;
            // Trigger level reached in FIFO mode
            else if (IER_i[0] & trigger_level_reached)
            	iir_n = 4'b1000;
            // Transmitter holding register empty
            else if (IER_i[1] & (tx_elements_i == 0))
            	iir_n = 4'b0100;
            else
            	iir_n = iir_q;
        end else begin
            iir_n = iir_q & ~clr_int_i;
        end
    end


    always @(posedge clk_i or negedge rstn_i) begin
        if (~rstn_i)
       	    iir_q <= 4'b0;
        else
       	    iir_q <= iir_n;
    end

    assign IIR_o = iir_q;
    assign interrupt_o = iir_q[2] | iir_q[3];

endmodule
