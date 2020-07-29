// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

`define log2(VALUE) ((VALUE) < ( 1 ) ? 0 : (VALUE) < ( 2 ) ? 1 : (VALUE) < ( 4 ) ? 2 : (VALUE) < ( 8 ) ? 3 : (VALUE) < ( 16 )  ? 4 : (VALUE) < ( 32 )  ? 5 : (VALUE) < ( 64 )  ? 6 : (VALUE) < ( 128 ) ? 7 : (VALUE) < ( 256 ) ? 8 : (VALUE) < ( 512 ) ? 9 : (VALUE) < ( 1024 ) ? 10 : (VALUE) < ( 2048 ) ? 11 : (VALUE) < ( 4096 ) ? 12 : (VALUE) < ( 8192 ) ? 13 : (VALUE) < ( 16384 ) ? 14 : (VALUE) < ( 32768 ) ? 15 : (VALUE) < ( 65536 ) ? 16 : (VALUE) < ( 131072 ) ? 17 : (VALUE) < ( 262144 ) ? 18 : (VALUE) < ( 524288 ) ? 19 : (VALUE) < ( 1048576 ) ? 20 : (VALUE) < ( 1048576 * 2 ) ? 21 : (VALUE) < ( 1048576 * 4 ) ? 22 : (VALUE) < ( 1048576 * 8 ) ? 23 : (VALUE) < ( 1048576 * 16 ) ? 24 : 25)

module spi_master_fifo
#(
    parameter DATA_WIDTH = 32,
    parameter BUFFER_DEPTH = 2,
    parameter LOG_BUFFER_DEPTH = `log2(BUFFER_DEPTH)
)
(
    input  logic                    clk_i,
    input  logic                    rst_ni,

    input  logic                    clr_i,

    output logic [LOG_BUFFER_DEPTH:0] elements_o,

    output logic [DATA_WIDTH-1 : 0] data_o,
    output logic                    valid_o,
    input  logic                    ready_i,

    input  logic                    valid_i,
    input  logic [DATA_WIDTH-1 : 0] data_i,
    output logic                    ready_o
);

    // Internal data structures
    logic [LOG_BUFFER_DEPTH-1:0]       pointer_in;  // location to which we last wrote
    logic [LOG_BUFFER_DEPTH-1:0]       pointer_out; // location from which we last sent
    logic [LOG_BUFFER_DEPTH:0]         elements;    // number of elements in the buffer
    logic [DATA_WIDTH-1:0]             buffer [BUFFER_DEPTH - 1 : 0];

    wire                             full;

    integer                             loop1;

    assign full = (elements == BUFFER_DEPTH);
    assign elements_o = elements;

    always_ff @(posedge clk_i, negedge rst_ni)
    begin: elements_sequential
        if (rst_ni == 1'b0)
            elements <= 0;
        else
        begin
            if (clr_i)
                elements <= 0;
            else 
            begin
                // ------------------
                // Are we filling up?
                // ------------------
                // One out, none in
                if (ready_i && valid_o && (!valid_i || full))
                    elements <= elements - 1;
                // None out, one in
                else if ((!valid_o || !ready_i) && valid_i && !full)
                    elements <= elements + 1;
                // Else, either one out and one in, or none out and none in - stays unchanged
            end
        end
    end

    always_ff @(posedge clk_i, negedge rst_ni)
    begin: buffers_sequential
        if (rst_ni == 1'b0)
        begin
            for (loop1 = 0 ; loop1 < BUFFER_DEPTH ; loop1 = loop1 + 1)
                buffer[loop1] <= 0;
        end
        else
        begin
            // Update the memory
            if (valid_i && !full)
                buffer[pointer_in] <= data_i;
        end
    end

    always_ff @(posedge clk_i, negedge rst_ni)
    begin: sequential
        if (rst_ni == 1'b0)
        begin
            pointer_out <= 0;
            pointer_in  <= 0;
        end
        else
        begin
            if(clr_i)
            begin
                pointer_out <= 0;
                pointer_in  <= 0;
            end
            else
            begin
                // ------------------------------------
                // Check what to do with the input side
                // ------------------------------------
                // We have some input, increase by 1 the input pointer
                if (valid_i && !full)
                begin
                    if (pointer_in == $unsigned(BUFFER_DEPTH - 1))
                        pointer_in <= 0;
                    else
                        pointer_in <= pointer_in + 1;
                end
                // Else we don't have any input, the input pointer stays the same

                // -------------------------------------
                // Check what to do with the output side
                // -------------------------------------
                // We had pushed one flit out, we can try to go for the next one
                if (ready_i && valid_o)
                begin
                    if (pointer_out == $unsigned(BUFFER_DEPTH - 1))
                        pointer_out <= 0;
                    else
                        pointer_out <= pointer_out + 1;
                end
                // Else stay on the same output location
            end
        end
    end

    // Update output ports
    assign data_o  = buffer[pointer_out];
    assign valid_o = (elements != 0);

    assign ready_o = ~full;

endmodule
