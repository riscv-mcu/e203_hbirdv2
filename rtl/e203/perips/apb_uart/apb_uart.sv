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

module apb_uart_sv
#(
    parameter APB_ADDR_WIDTH = 12  //APB slaves are 4KB by default
)
(
    input  logic                      CLK,
    input  logic                      RSTN,
    /* verilator lint_off UNUSED */
    input  logic [APB_ADDR_WIDTH-1:0] PADDR,
    /* lint_on */
    input  logic               [31:0] PWDATA,
    input  logic                      PWRITE,
    input  logic                      PSEL,
    input  logic                      PENABLE,
    output logic               [31:0] PRDATA,
    output logic                      PREADY,
    output logic                      PSLVERR,

    input  logic                      rx_i,      // Receiver input
    output logic                      tx_o,      // Transmitter output

    output logic                      event_o    // interrupt/event output
);
    // register addresses
    parameter RBR = 3'h0, THR = 3'h0, DLL = 3'h0, IER = 3'h1, DLM = 3'h1, IIR = 3'h2,
              FCR = 3'h2, LCR = 3'h3, MCR = 3'h4, LSR = 3'h5, MSR = 3'h6, SCR = 3'h7;

    parameter TX_FIFO_DEPTH = 16; // in bytes
    parameter RX_FIFO_DEPTH = 16; // in bytes

    logic [2:0]       register_adr;
    logic [9:0][7:0]  regs_q, regs_n;
    logic [1:0]       trigger_level_n, trigger_level_q;

    // receive buffer register, read only
    logic [7:0]       rx_data;
    // parity error
    logic             parity_error;
    logic [3:0]       IIR_o;
    logic [3:0]       clr_int;

    /* verilator lint_off UNOPTFLAT */
    // tx flow control
    logic             tx_ready;
    /* lint_on */

    // rx flow control
    logic             apb_rx_ready;
    logic             rx_valid;

    logic             tx_fifo_clr_n, tx_fifo_clr_q;
    logic             rx_fifo_clr_n, rx_fifo_clr_q;

    logic             fifo_tx_valid;
    logic             tx_valid;
    logic             fifo_rx_valid;
    logic             fifo_rx_ready;
    logic             rx_ready;

    logic             [7:0] fifo_tx_data;
    logic             [8:0] fifo_rx_data;

    logic             [7:0] tx_data;
    logic             [$clog2(TX_FIFO_DEPTH):0] tx_elements;
    logic             [$clog2(RX_FIFO_DEPTH):0] rx_elements;

    // TODO: check that stop bits are really not necessary here
    uart_rx uart_rx_i
    (
        .clk_i              ( CLK                           ),
        .rstn_i             ( RSTN                          ),
        .rx_i               ( rx_i                          ),
        .cfg_en_i           ( 1'b1                          ),
        .cfg_div_i          ( {regs_q[DLM + 'd8], regs_q[DLL + 'd8]}    ),
        .cfg_parity_en_i    ( regs_q[LCR][3]                ),
        .cfg_bits_i         ( regs_q[LCR][1:0]              ),
        // .cfg_stop_bits_i    ( regs_q[LCR][2]                ),
        /* verilator lint_off PINCONNECTEMPTY */
        .busy_o             (                               ),
        /* lint_on */
        .err_o              ( parity_error                  ),
        .err_clr_i          ( 1'b1                          ),
        .rx_data_o          ( rx_data                       ),
        .rx_valid_o         ( rx_valid                      ),
        .rx_ready_i         ( rx_ready                      )
    );

    uart_tx uart_tx_i
    (
        .clk_i              ( CLK                           ),
        .rstn_i             ( RSTN                          ),
        .tx_o               ( tx_o                          ),
        /* verilator lint_off PINCONNECTEMPTY */
        .busy_o             (                               ),
        /* lint_on */
        .cfg_en_i           ( 1'b1                          ),
        .cfg_div_i          ( {regs_q[DLM + 'd8], regs_q[DLL + 'd8]}    ),
        .cfg_parity_en_i    ( regs_q[LCR][3]                ),
        .cfg_bits_i         ( regs_q[LCR][1:0]              ),
        .cfg_stop_bits_i    ( regs_q[LCR][2]                ),

        .tx_data_i          ( tx_data                       ),
        .tx_valid_i         ( tx_valid                      ),
        .tx_ready_o         ( tx_ready                      )
    );

    io_generic_fifo
    #(
        .DATA_WIDTH         ( 9                             ),
        .BUFFER_DEPTH       ( RX_FIFO_DEPTH                 )
    )
    uart_rx_fifo_i
    (
        .clk_i              ( CLK                           ),
        .rstn_i             ( RSTN                          ),

        .clr_i              ( rx_fifo_clr_q                 ),

        .elements_o         ( rx_elements                   ),

        .data_o             ( fifo_rx_data                  ),
        .valid_o            ( fifo_rx_valid                 ),
        .ready_i            ( fifo_rx_ready                 ),

        .valid_i            ( rx_valid                      ),
        .data_i             ( { parity_error, rx_data }     ),
        .ready_o            ( rx_ready                      )
    );

    io_generic_fifo
    #(
        .DATA_WIDTH         ( 8                             ),
        .BUFFER_DEPTH       ( TX_FIFO_DEPTH                 )
    )
    uart_tx_fifo_i
    (
        .clk_i              ( CLK                           ),
        .rstn_i             ( RSTN                          ),

        .clr_i              ( tx_fifo_clr_q                 ),

        .elements_o         ( tx_elements                   ),

        .data_o             ( tx_data                       ),
        .valid_o            ( tx_valid                      ),
        .ready_i            ( tx_ready                      ),

        .valid_i            ( fifo_tx_valid                 ),
        .data_i             ( fifo_tx_data                  ),
        // not needed since we are getting the status via the fifo population
        .ready_o            (                               )
    );

    uart_interrupt
    #(
        .TX_FIFO_DEPTH (TX_FIFO_DEPTH),
        .RX_FIFO_DEPTH (RX_FIFO_DEPTH)
    )
    uart_interrupt_i
    (
        .clk_i              ( CLK                           ),
        .rstn_i             ( RSTN                          ),


        .IER_i              ( regs_q[IER][2:0]              ), // interrupt enable register
        .RDA_i              ( regs_n[LSR][5]                ), // receiver data available
        .CTI_i              ( 1'b0                          ), // character timeout indication


        .error_i            ( regs_n[LSR][2]                ),
        .rx_elements_i      ( rx_elements                   ),
        .tx_elements_i      ( tx_elements                   ),
        .trigger_level_i    ( trigger_level_q               ),

        .clr_int_i          ( clr_int                       ), // one hot

        .interrupt_o        ( event_o                       ),
        .IIR_o              ( IIR_o                         )

    );

    // UART Registers

    // register write and update logic
    always_comb
    begin
        regs_n          = regs_q;
        trigger_level_n = trigger_level_q;

        fifo_tx_valid   = 1'b0;
        tx_fifo_clr_n   = 1'b0; // self clearing
        rx_fifo_clr_n   = 1'b0; // self clearing

        // rx status
        regs_n[LSR][0] = fifo_rx_valid; // fifo is empty

        // parity error on receiving part has occured
        regs_n[LSR][2] = fifo_rx_data[8]; // parity error is detected when element is retrieved

        // tx status register
        regs_n[LSR][5] = ~ (|tx_elements); // fifo is empty
        regs_n[LSR][6] = tx_ready & ~ (|tx_elements); // shift register and fifo are empty

        if (PSEL && PENABLE && PWRITE)
        begin
            case (register_adr)

                THR: // either THR or DLL
                begin
                    if (regs_q[LCR][7]) // Divisor Latch Access Bit (DLAB)
                    begin
                        regs_n[DLL + 'd8] = PWDATA[7:0];
                    end
                    else
                    begin
                        fifo_tx_data = PWDATA[7:0];
                        fifo_tx_valid = 1'b1;
                    end
                end

                IER: // either IER or DLM
                begin
                    if (regs_q[LCR][7]) // Divisor Latch Access Bit (DLAB)
                        regs_n[DLM + 'd8] = PWDATA[7:0];
                    else
                        regs_n[IER] = PWDATA[7:0];
                end

                LCR:
                    regs_n[LCR] = PWDATA[7:0];

                FCR: // write only register, fifo control register
                begin
                    rx_fifo_clr_n   = PWDATA[1];
                    tx_fifo_clr_n   = PWDATA[2];
                    trigger_level_n = PWDATA[7:6];
                end

                default: ;
            endcase

        end

    end

    // register read logic
    always_comb
    begin
        PRDATA = 'b0;
        apb_rx_ready = 1'b0;
        fifo_rx_ready = 1'b0;
        clr_int      = 4'b0;

        if (PSEL && PENABLE && !PWRITE)
        begin
            case (register_adr)
                RBR: // either RBR or DLL
                begin
                    if (regs_q[LCR][7]) // Divisor Latch Access Bit (DLAB)
                        PRDATA = {24'b0, regs_q[DLL + 'd8]};
                    else
                    begin

                        fifo_rx_ready = 1'b1;

                        PRDATA = {24'b0, fifo_rx_data[7:0]};

                        clr_int = 4'b1000; // clear Received Data Available interrupt
                    end
                end

                LSR: // Line Status Register
                begin
                    PRDATA = {24'b0, regs_q[LSR]};
                    clr_int = 4'b1100; // clear parrity interrupt error
                end

                LCR: // Line Control Register
                    PRDATA = {24'b0, regs_q[LCR]};

                IER: // either IER or DLM
                begin
                    if (regs_q[LCR][7]) // Divisor Latch Access Bit (DLAB)
                        PRDATA = {24'b0, regs_q[DLM + 'd8]};
                    else
                        PRDATA = {24'b0, regs_q[IER]};
                end

                IIR: // interrupt identification register read only
                begin
                    PRDATA = {24'b0, 1'b1, 1'b1, 2'b0, IIR_o};
                    clr_int = 4'b0100; // clear Transmitter Holding Register Empty
                end

                default: ;
            endcase
        end
    end

    // synchronouse part
    always_ff @(posedge CLK, negedge RSTN)
    begin
        if(~RSTN)
        begin

            regs_q[IER]       <= 8'h0;
            regs_q[IIR]       <= 8'h1;
            regs_q[LCR]       <= 8'h0;
            regs_q[MCR]       <= 8'h0;
            regs_q[LSR]       <= 8'h60;
            regs_q[MSR]       <= 8'h0;
            regs_q[SCR]       <= 8'h0;
            regs_q[DLM + 'd8] <= 8'h0;
            regs_q[DLL + 'd8] <= 8'h0;

            trigger_level_q <= 2'b00;
            tx_fifo_clr_q   <= 1'b0;
            rx_fifo_clr_q   <= 1'b0;

        end
        else
        begin
            regs_q <= regs_n;

            trigger_level_q <= trigger_level_n;
            tx_fifo_clr_q   <= tx_fifo_clr_n;
            rx_fifo_clr_q   <= rx_fifo_clr_n;

        end
    end

    assign register_adr = {PADDR[4:2]};
    // APB logic: we are always ready to capture the data into our regs
    // not supporting transfare failure
    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;
endmodule
