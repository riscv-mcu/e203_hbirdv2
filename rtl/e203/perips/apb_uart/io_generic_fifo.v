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

module io_generic_fifo 
#(
    parameter DATA_WIDTH = 32,
    parameter BUFFER_DEPTH = 2,
    parameter LOG_BUFFER_DEPTH = $clog2(BUFFER_DEPTH)
)
(
    input  wire                      clk_i,
    input  wire                      rstn_i,
    input  wire                      clr_i,
    output wire [LOG_BUFFER_DEPTH:0] elements_o,
    output wire [DATA_WIDTH - 1:0]   data_o,
    output wire                      valid_o,
    input  wire                      ready_i,
    input  wire                      valid_i,
    input  wire [DATA_WIDTH - 1:0]   data_i,
    output wire                      ready_o
);
    // Internal data structures
    reg [LOG_BUFFER_DEPTH - 1:0] pointer_in;      // location to which we last wrote
    reg [LOG_BUFFER_DEPTH - 1:0] pointer_out;     // location from which we last sent

    reg [LOG_BUFFER_DEPTH:0]     elements;        // number of elements in the buffer
    reg [DATA_WIDTH - 1:0]       buffer [BUFFER_DEPTH - 1:0];
    wire                         full;
   
   
    assign full       = (elements == BUFFER_DEPTH);
    assign elements_o = elements;

    always @(posedge clk_i or negedge rstn_i) begin : elements_sequential
        if (rstn_i == 1'b0)
            elements <= 0;
        else if (clr_i)
            elements <= 0;
        // ------------------
        // Are we filling up?
        // ------------------
        // One out, none in
        else if ((ready_i && valid_o) && (!valid_i || full))
            elements <= elements - 1;
        // None out, one in
        else if (((!valid_o || !ready_i) && valid_i) && !full)
            elements <= elements + 1;
        // Else, either one out and one in, or none out and none in - stays unchanged
    end

    integer loop1;
    always @(posedge clk_i or negedge rstn_i) begin : buffers_sequential
        if (rstn_i == 1'b0) begin
            for (loop1 = 0; loop1 < BUFFER_DEPTH; loop1 = loop1 + 1) begin
                buffer[loop1] <= 0;
            end
        end else if (valid_i && !full) begin
            buffer[pointer_in] <= data_i;     // Update the memory
        end
    end

    always @(posedge clk_i or negedge rstn_i) begin : sequential
        if (rstn_i == 1'b0) begin
            pointer_out <= 0;
            pointer_in  <= 0;
	end else if (clr_i) begin
            pointer_out <= 0;
            pointer_in  <= 0;
	end else begin

            // ------------------------------------
            // Check what to do with the input side
            // ------------------------------------
            // We have some input, increase by 1 the input pointer		
	    if (valid_i && !full) begin
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
	    if (ready_i && valid_o) begin
                if (pointer_out == $unsigned(BUFFER_DEPTH - 1))
                    pointer_out <= 0;
                else
                    pointer_out <= pointer_out + 1;
            end
            // Else stay on the same output location
        end
    end


    // Update output ports
    assign data_o  = buffer[pointer_out];
    assign valid_o = (elements != 0);
    assign ready_o = ~full;

endmodule
