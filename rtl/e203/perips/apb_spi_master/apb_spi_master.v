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


`define log2(VALUE) ((VALUE) < ( 1 ) ? 0 : (VALUE) < ( 2 ) ? 1 : (VALUE) < ( 4 ) ? 2 : (VALUE) < ( 8 ) ? 3 : (VALUE) < ( 16 )  ? 4 : (VALUE) < ( 32 )  ? 5 : (VALUE) < ( 64 )  ? 6 : (VALUE) < ( 128 ) ? 7 : (VALUE) < ( 256 ) ? 8 : (VALUE) < ( 512 ) ? 9 : (VALUE) < ( 1024 ) ? 10 : (VALUE) < ( 2048 ) ? 11 : (VALUE) < ( 4096 ) ? 12 : (VALUE) < ( 8192 ) ? 13 : (VALUE) < ( 16384 ) ? 14 : (VALUE) < ( 32768 ) ? 15 : (VALUE) < ( 65536 ) ? 16 : (VALUE) < ( 131072 ) ? 17 : (VALUE) < ( 262144 ) ? 18 : (VALUE) < ( 524288 ) ? 19 : (VALUE) < ( 1048576 ) ? 20 : (VALUE) < ( 1048576 * 2 ) ? 21 : (VALUE) < ( 1048576 * 4 ) ? 22 : (VALUE) < ( 1048576 * 8 ) ? 23 : (VALUE) < ( 1048576 * 16 ) ? 24 : 25)

`define SPI_STD     2'b00
`define SPI_QUAD_TX 2'b01
`define SPI_QUAD_RX 2'b10

module apb_spi_master
#(
    parameter BUFFER_DEPTH   = 10,
    parameter APB_ADDR_WIDTH = 12  //APB slaves are 4KB by default
)
(
    input  wire                        HCLK,
    input  wire                        HRESETn,
    input  wire [APB_ADDR_WIDTH - 1:0] PADDR,
    input  wire [31:0]                 PWDATA,
    input  wire                        PWRITE,
    input  wire                        PSEL,
    input  wire                        PENABLE,
    output wire [31:0]                 PRDATA,
    output wire                        PREADY,
    output wire                        PSLVERR,

    output wire                        events_o,
    
    output wire                        spi_clk,
    output wire                        spi_csn0,
    output wire                        spi_csn1,
    output wire                        spi_csn2,
    output wire                        spi_csn3,
    output wire                        spi_sdo0,
    output wire                        spi_sdo1,
    output wire                        spi_sdo2,
    output wire                        spi_sdo3,
    output reg                         spi_oe0,
    output reg                         spi_oe1,
    output reg                         spi_oe2,
    output reg                         spi_oe3,
    input  wire                        spi_sdi0,
    input  wire                        spi_sdi1,
    input  wire                        spi_sdi2,
    input  wire                        spi_sdi3
);

    localparam LOG_BUFFER_DEPTH = `log2(BUFFER_DEPTH);

    wire [7:0]  spi_clk_div;
    wire        spi_clk_div_valid;
    wire [31:0] spi_status;
    wire [31:0] spi_addr;
    wire [5:0]  spi_addr_len;
    wire [31:0] spi_cmd;
    wire [5:0]  spi_cmd_len;
    wire [15:0] spi_data_len;
    wire [15:0] spi_dummy_rd;
    wire [15:0] spi_dummy_wr;
    wire        spi_swrst;
    wire        spi_rd;
    wire        spi_wr;
    wire        spi_qrd;
    wire        spi_qwr;
    wire [3:0]  spi_csreg;
    wire [31:0] spi_data_tx;
    wire        spi_data_tx_valid;
    wire        spi_data_tx_ready;
    wire [31:0] spi_data_rx;
    wire        spi_data_rx_valid;
    wire        spi_data_rx_ready;
    wire [6:0]  spi_ctrl_status;
    wire [31:0] spi_ctrl_data_tx;
    wire        spi_ctrl_data_tx_valid;
    wire        spi_ctrl_data_tx_ready;
    wire [31:0] spi_ctrl_data_rx;
    wire        spi_ctrl_data_rx_valid;
    wire        spi_ctrl_data_rx_ready;

    wire [1:0]  spi_mode;

    wire        s_eot;

    wire [LOG_BUFFER_DEPTH:0] elements_tx;
    wire [LOG_BUFFER_DEPTH:0] elements_rx;

    wire [LOG_BUFFER_DEPTH:0] s_th_tx;
    wire [LOG_BUFFER_DEPTH:0] s_th_rx;

    wire                      s_rise_int_tx;
    wire                      s_rise_int_rx;
    wire                      s_int_tx;
    wire                      s_int_rx;
    wire                      s_int_en;
    wire [31:0]               s_int_status;


    localparam FILL_BITS = 7 - LOG_BUFFER_DEPTH;

    assign spi_status = {{FILL_BITS {1'b0}}, elements_tx, {FILL_BITS {1'b0}}, elements_rx, 9'h000, spi_ctrl_status};

    assign s_rise_int_tx = s_int_en & (elements_tx < s_th_tx);
    assign s_rise_int_rx = s_int_en & (elements_rx > s_th_rx);
    
    assign events_o = s_rise_int_tx | s_rise_int_rx;
    assign s_int_status = {s_rise_int_rx, s_rise_int_tx};
    
    always @(*) begin
        spi_oe0 = 1'b0;
        spi_oe1 = 1'b0;
        spi_oe2 = 1'b0;
        spi_oe3 = 1'b0;

        case (spi_mode)
            `SPI_STD: begin
                spi_oe0 = 1'b1;
                spi_oe1 = 1'b0;
                spi_oe2 = 1'b0;
                spi_oe3 = 1'b0;
            end
            `SPI_QUAD_TX: begin
                spi_oe0 = 1'b1;
                spi_oe1 = 1'b1;
                spi_oe2 = 1'b1;
                spi_oe3 = 1'b1;
            end
            `SPI_QUAD_RX: begin
                spi_oe0 = 1'b0;
                spi_oe1 = 1'b0;
                spi_oe2 = 1'b0;
                spi_oe3 = 1'b0;
            end
        endcase
    end

    spi_master_apb_if
    #(
        .BUFFER_DEPTH   ( BUFFER_DEPTH   ),
        .APB_ADDR_WIDTH ( APB_ADDR_WIDTH )
    )
    u_axiregs
    (
        .HCLK              ( HCLK              ),
        .HRESETn           ( HRESETn           ),
        .PADDR             ( PADDR             ),
        .PWDATA            ( PWDATA            ),
        .PWRITE            ( PWRITE            ),
        .PSEL              ( PSEL              ),
        .PENABLE           ( PENABLE           ),
        .PRDATA            ( PRDATA            ),
        .PREADY            ( PREADY            ),
        .PSLVERR           ( PSLVERR           ),

        .spi_clk_div       ( spi_clk_div       ),
        .spi_clk_div_valid ( spi_clk_div_valid ),
        .spi_status        ( spi_status        ),
        .spi_addr          ( spi_addr          ),
        .spi_addr_len      ( spi_addr_len      ),
        .spi_cmd           ( spi_cmd           ),
        .spi_cmd_len       ( spi_cmd_len       ),
        .spi_data_len      ( spi_data_len      ),
        .spi_dummy_rd      ( spi_dummy_rd      ),
        .spi_dummy_wr      ( spi_dummy_wr      ),
        .spi_swrst         ( spi_swrst         ),
        .spi_rd            ( spi_rd            ),
        .spi_wr            ( spi_wr            ),
        .spi_qrd           ( spi_qrd           ),
        .spi_qwr           ( spi_qwr           ),
        .spi_csreg         ( spi_csreg         ),
        .spi_int_th_rx     ( s_th_rx           ),
        .spi_int_th_tx     ( s_th_tx           ),
        .spi_int_en        ( s_int_en          ),
        .spi_int_status    ( s_int_status      ),
        .spi_data_tx       ( spi_data_tx       ),
        .spi_data_tx_valid ( spi_data_tx_valid ),
        .spi_data_tx_ready ( spi_data_tx_ready ), //FIXME not used inside thhis module
        .spi_data_rx       ( spi_data_rx       ),
        .spi_data_rx_valid ( spi_data_rx_valid ),
        .spi_data_rx_ready ( spi_data_rx_ready )
    );

    spi_master_fifo
    #(
        .DATA_WIDTH   ( 32           ),
        .BUFFER_DEPTH ( BUFFER_DEPTH )
    )
    u_txfifo
    (
        .clk_i      ( HCLK                   ),
        .rst_ni     ( HRESETn                ),
        .clr_i      ( spi_swrst              ),

        .elements_o ( elements_tx            ),

        .data_o     ( spi_ctrl_data_tx       ),
        .valid_o    ( spi_ctrl_data_tx_valid ),
        .ready_i    ( spi_ctrl_data_tx_ready ),

        .valid_i    ( spi_data_tx_valid      ),
        .data_i     ( spi_data_tx            ),
        .ready_o    ( spi_data_tx_ready      )
    );

    spi_master_fifo
    #(
        .DATA_WIDTH   ( 32           ),
        .BUFFER_DEPTH ( BUFFER_DEPTH )
    )
    u_rxfifo
    (
        .clk_i      ( HCLK                   ),
        .rst_ni     ( HRESETn                ),
        .clr_i      ( spi_swrst              ),

        .elements_o ( elements_rx            ),

        .data_o     ( spi_data_rx            ),
        .valid_o    ( spi_data_rx_valid      ),
        .ready_i    ( spi_data_rx_ready      ),

        .valid_i    ( spi_ctrl_data_rx_valid ),
        .data_i     ( spi_ctrl_data_rx       ),
        .ready_o    ( spi_ctrl_data_rx_ready )
    );

    spi_master_controller u_spictrl
    (
        .clk                    ( HCLK                   ),
        .rstn                   ( HRESETn                ),
        .eot                    ( s_eot                  ),
        .spi_clk_div            ( spi_clk_div            ),
        .spi_clk_div_valid      ( spi_clk_div_valid      ),
        .spi_status             ( spi_ctrl_status        ),
        .spi_addr               ( spi_addr               ),
        .spi_addr_len           ( spi_addr_len           ),
        .spi_cmd                ( spi_cmd                ),
        .spi_cmd_len            ( spi_cmd_len            ),
        .spi_data_len           ( spi_data_len           ),
        .spi_dummy_rd           ( spi_dummy_rd           ),
        .spi_dummy_wr           ( spi_dummy_wr           ),
        .spi_swrst              ( spi_swrst              ),
        .spi_rd                 ( spi_rd                 ),
        .spi_wr                 ( spi_wr                 ),
        .spi_qrd                ( spi_qrd                ),
        .spi_qwr                ( spi_qwr                ),
        .spi_csreg              ( spi_csreg              ),
        .spi_ctrl_data_tx       ( spi_ctrl_data_tx       ),
        .spi_ctrl_data_tx_valid ( spi_ctrl_data_tx_valid ),
        .spi_ctrl_data_tx_ready ( spi_ctrl_data_tx_ready ),
        .spi_ctrl_data_rx       ( spi_ctrl_data_rx       ),
        .spi_ctrl_data_rx_valid ( spi_ctrl_data_rx_valid ),
        .spi_ctrl_data_rx_ready ( spi_ctrl_data_rx_ready ),
        .spi_clk                ( spi_clk                ),
        .spi_csn0               ( spi_csn0               ),
        .spi_csn1               ( spi_csn1               ),
        .spi_csn2               ( spi_csn2               ),
        .spi_csn3               ( spi_csn3               ),
        .spi_mode               ( spi_mode               ),
        .spi_sdo0               ( spi_sdo0               ),
        .spi_sdo1               ( spi_sdo1               ),
        .spi_sdo2               ( spi_sdo2               ),
        .spi_sdo3               ( spi_sdo3               ),
        .spi_sdi0               ( spi_sdi0               ),
        .spi_sdi1               ( spi_sdi1               ),
        .spi_sdi2               ( spi_sdi2               ),
        .spi_sdi3               ( spi_sdi3               )
    );

endmodule
