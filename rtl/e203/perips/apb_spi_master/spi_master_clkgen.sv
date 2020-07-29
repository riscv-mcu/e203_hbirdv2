// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

module spi_master_clkgen
(
    input  logic                        clk,
    input  logic                        rstn,
    input  logic                        en,
    input  logic          [7:0]         clk_div,
    input  logic                        clk_div_valid,
    output logic                        spi_clk,
    output logic                        spi_fall,
    output logic                        spi_rise
);

    logic [7:0] counter_trgt;
    logic [7:0] counter_trgt_next;
    logic [7:0] counter;
    logic [7:0] counter_next;

    logic       spi_clk_next;
    logic       running;

    always_comb
    begin
            spi_rise = 1'b0;
            spi_fall = 1'b0;
            if (clk_div_valid)
                counter_trgt_next = clk_div;
            else
                counter_trgt_next = counter_trgt;

            if (counter == counter_trgt)
            begin
                counter_next = 0;
                spi_clk_next = ~spi_clk;
                if(spi_clk == 1'b0)
                    spi_rise = running;
                else
                    spi_fall = running;
            end
            else
            begin
                counter_next = counter + 1;
                spi_clk_next = spi_clk;
            end
    end

    always_ff @(posedge clk, negedge rstn)
    begin
        if (rstn == 1'b0)
        begin
            counter_trgt <= 'h0;
            counter      <= 'h0;
            spi_clk      <= 1'b0;
            running      <= 1'b0;
        end
        else
        begin
            counter_trgt <= counter_trgt_next;
            if ( !((spi_clk==1'b0)&&(~en)) )
            begin
                running <= 1'b1;
                spi_clk <= spi_clk_next;
                counter <= counter_next;
            end
            else
                running <= 1'b0;
        end
    end



endmodule
