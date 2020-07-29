// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

`define SPI_STD     2'b00
`define SPI_QUAD_TX 2'b01
`define SPI_QUAD_RX 2'b10

module spi_master_controller
(
    input  logic                          clk,
    input  logic                          rstn,
    output logic                          eot,
    input  logic                    [7:0] spi_clk_div,
    input  logic                          spi_clk_div_valid,
    output logic                    [6:0] spi_status,
    input  logic                   [31:0] spi_addr,
    input  logic                    [5:0] spi_addr_len,
    input  logic                   [31:0] spi_cmd,
    input  logic                    [5:0] spi_cmd_len,
    input  logic                   [15:0] spi_data_len,
    input  logic                   [15:0] spi_dummy_rd,
    input  logic                   [15:0] spi_dummy_wr,
    input  logic                    [3:0] spi_csreg,
    input  logic                          spi_swrst, //FIXME Not used at all
    input  logic                          spi_rd,
    input  logic                          spi_wr,
    input  logic                          spi_qrd,
    input  logic                          spi_qwr,
    input  logic                   [31:0] spi_ctrl_data_tx,
    input  logic                          spi_ctrl_data_tx_valid,
    output logic                          spi_ctrl_data_tx_ready,
    output logic                   [31:0] spi_ctrl_data_rx,
    output logic                          spi_ctrl_data_rx_valid,
    input  logic                          spi_ctrl_data_rx_ready,
    output logic                          spi_clk,
    output logic                          spi_csn0,
    output logic                          spi_csn1,
    output logic                          spi_csn2,
    output logic                          spi_csn3,
    output logic                    [1:0] spi_mode,
    output logic                          spi_sdo0,
    output logic                          spi_sdo1,
    output logic                          spi_sdo2,
    output logic                          spi_sdo3,
    input  logic                          spi_sdi0,
    input  logic                          spi_sdi1,
    input  logic                          spi_sdi2,
    input  logic                          spi_sdi3
);

  logic spi_rise;
  logic spi_fall;

  logic spi_clock_en;

  logic spi_en_tx;
  logic spi_en_rx;

  logic [15:0] counter_tx;
  logic        counter_tx_valid;
  logic [15:0] counter_rx;
  logic        counter_rx_valid;

  logic [31:0] data_to_tx;
  logic        data_to_tx_valid;
  logic        data_to_tx_ready;

  logic en_quad;
  logic en_quad_int;
  logic do_tx; //FIXME NOT USED at all!!
  logic do_rx;

  logic tx_done;
  logic rx_done;

  logic [1:0] s_spi_mode;

  logic ctrl_data_valid;

  logic spi_cs;

  logic tx_clk_en;
  logic rx_clk_en;

  enum logic [2:0] {DATA_NULL,DATA_EMPTY,DATA_CMD,DATA_ADDR,DATA_FIFO} ctrl_data_mux;

  enum logic [4:0] {IDLE,CMD,ADDR,MODE,DUMMY,DATA_TX,DATA_RX,WAIT_EDGE} state,state_next;

  assign en_quad = spi_qrd | spi_qwr | en_quad_int;

  spi_master_clkgen u_clkgen
  (
    .clk           ( clk               ),
    .rstn          ( rstn              ),
    .en            ( spi_clock_en      ),
    .clk_div       ( spi_clk_div       ),
    .clk_div_valid ( spi_clk_div_valid ),
    .spi_clk       ( spi_clk           ),
    .spi_fall      ( spi_fall          ),
    .spi_rise      ( spi_rise          )
  );

  spi_master_tx u_txreg
  (
    .clk            ( clk              ),
    .rstn           ( rstn             ),
    .en             ( spi_en_tx        ),
    .tx_edge        ( spi_fall         ),
    .tx_done        ( tx_done          ),
    .sdo0           ( spi_sdo0         ),
    .sdo1           ( spi_sdo1         ),
    .sdo2           ( spi_sdo2         ),
    .sdo3           ( spi_sdo3         ),
    .en_quad_in     ( en_quad          ),
    .counter_in     ( counter_tx       ),
    .counter_in_upd ( counter_tx_valid ),
    .data           ( data_to_tx       ),
    .data_valid     ( data_to_tx_valid ),
    .data_ready     ( data_to_tx_ready ),
    .clk_en_o       ( tx_clk_en        )
  );

  spi_master_rx u_rxreg
  (
    .clk            ( clk                    ),
    .rstn           ( rstn                   ),
    .en             ( spi_en_rx              ),
    .rx_edge        ( spi_rise               ),
    .rx_done        ( rx_done                ),
    .sdi0           ( spi_sdi0               ),
    .sdi1           ( spi_sdi1               ),
    .sdi2           ( spi_sdi2               ),
    .sdi3           ( spi_sdi3               ),
    .en_quad_in     ( en_quad                ),
    .counter_in     ( counter_rx             ),
    .counter_in_upd ( counter_rx_valid       ),
    .data           ( spi_ctrl_data_rx       ),
    .data_valid     ( spi_ctrl_data_rx_valid ),
    .data_ready     ( spi_ctrl_data_rx_ready ),
    .clk_en_o       ( rx_clk_en              )
  );

  always_comb
  begin
      data_to_tx       =  'h0;
      data_to_tx_valid = 1'b0;
      spi_ctrl_data_tx_ready = 1'b0;

      case(ctrl_data_mux)
          DATA_NULL:
          begin
              data_to_tx       =  '0;
              data_to_tx_valid = 1'b0;
              spi_ctrl_data_tx_ready = 1'b0;
          end

          DATA_EMPTY:
          begin
              data_to_tx       =  '0;
              data_to_tx_valid = 1'b1;
          end

          DATA_CMD:
          begin
              data_to_tx       = spi_cmd;
              data_to_tx_valid = ctrl_data_valid;
              spi_ctrl_data_tx_ready = 1'b0;
          end

          DATA_ADDR:
          begin
              data_to_tx       = spi_addr;
              data_to_tx_valid = ctrl_data_valid;
              spi_ctrl_data_tx_ready = 1'b0;
          end

          DATA_FIFO:
          begin
              data_to_tx       = spi_ctrl_data_tx;
              data_to_tx_valid = spi_ctrl_data_tx_valid;
              spi_ctrl_data_tx_ready = data_to_tx_ready;
          end
      endcase
  end

  always_comb
  begin
    spi_cs           = 1'b1;
    spi_clock_en     = 1'b0;
    counter_tx       =  '0;
    counter_tx_valid = 1'b0;
    counter_rx       =  '0;
    counter_rx_valid = 1'b0;
    state_next       = state;
    ctrl_data_mux    = DATA_NULL;
    ctrl_data_valid  = 1'b0;
    spi_en_rx        = 1'b0;
    spi_en_tx        = 1'b0;
    spi_status       =  '0;
    s_spi_mode       = `SPI_QUAD_RX;
    eot              = 1'b0;
    case(state)
      IDLE:
      begin
        spi_status[0] = 1'b1;
        s_spi_mode = `SPI_QUAD_RX;
        if (spi_rd || spi_wr || spi_qrd || spi_qwr)
        begin
          spi_cs       = 1'b0;
          spi_clock_en = 1'b1;

          if (spi_cmd_len != 0)
          begin
            s_spi_mode = (spi_qrd | spi_qwr) ? `SPI_QUAD_TX : `SPI_STD;
            counter_tx       = {8'h0,spi_cmd_len};
            counter_tx_valid = 1'b1;
            ctrl_data_mux    = DATA_CMD;
            ctrl_data_valid  = 1'b1;
            spi_en_tx        = 1'b1;
            state_next       = CMD;
          end
          else if (spi_addr_len != 0)
          begin
            s_spi_mode = (spi_qrd | spi_qwr) ? `SPI_QUAD_TX : `SPI_STD;
            counter_tx       = {8'h0,spi_addr_len};
            counter_tx_valid = 1'b1;
            ctrl_data_mux    = DATA_ADDR;
            ctrl_data_valid  = 1'b1;
            spi_en_tx        = 1'b1;
            state_next       = ADDR;
          end
          else if (spi_data_len != 0)
          begin
            if (spi_rd || spi_qrd)
            begin
              s_spi_mode = (spi_qrd) ? `SPI_QUAD_RX : `SPI_STD;
              if(spi_dummy_rd != 0)
              begin
                counter_tx       = en_quad ? {spi_dummy_rd[13:0],2'b00} : spi_dummy_rd;
                counter_tx_valid = 1'b1;
                spi_en_tx        = 1'b1;
                ctrl_data_mux    = DATA_EMPTY;
                state_next       = DUMMY;
              end
              else
              begin
                counter_rx       = spi_data_len;
                counter_rx_valid = 1'b1;
                spi_en_rx        = 1'b1;
                state_next       = DATA_RX;
              end
            end
            else
            begin
              s_spi_mode = (spi_qwr) ? `SPI_QUAD_TX : `SPI_STD;
              if(spi_dummy_wr != 0)
              begin
                counter_tx       = en_quad ? {spi_dummy_wr[13:0],2'b00} : spi_dummy_wr;
                counter_tx_valid = 1'b1;
                ctrl_data_mux    = DATA_EMPTY;
                spi_en_tx        = 1'b1;
                state_next       = DUMMY;
              end
              else
              begin
                counter_tx       = spi_data_len;
                counter_tx_valid = 1'b1;
                ctrl_data_mux    = DATA_FIFO;
                ctrl_data_valid  = 1'b0;
                spi_en_tx        = 1'b1;
                state_next       = DATA_TX;
              end
            end
          end
        end
        else
        begin
          spi_cs = 1'b1;
          state_next = IDLE;
        end
      end

      CMD:
      begin
        spi_status[1] = 1'b1;
        spi_cs = 1'b0;
        spi_clock_en = 1'b1;
        s_spi_mode = (en_quad) ? `SPI_QUAD_TX : `SPI_STD;
        if (tx_done)
        begin
          if (spi_addr_len != 0)
          begin
            s_spi_mode = (en_quad) ? `SPI_QUAD_TX : `SPI_STD;
            counter_tx       = {8'h0,spi_addr_len};
            counter_tx_valid = 1'b1;
            ctrl_data_mux    = DATA_ADDR;
            ctrl_data_valid  = 1'b1;
            spi_en_tx        = 1'b1;
            state_next       = ADDR;
          end
          else if (spi_data_len != 0)
          begin
            if (do_rx)
            begin
              s_spi_mode = (en_quad) ? `SPI_QUAD_RX : `SPI_STD;
              if(spi_dummy_rd != 0)
              begin
                counter_tx       = en_quad ? {spi_dummy_rd[13:0],2'b00} : spi_dummy_rd;
                counter_tx_valid = 1'b1;
                spi_en_tx        = 1'b1;
                ctrl_data_mux    = DATA_EMPTY;
                state_next       = DUMMY;
              end
              else
              begin
                counter_rx       = spi_data_len;
                counter_rx_valid = 1'b1;
                spi_en_rx        = 1'b1;
                state_next       = DATA_RX;
              end
            end
            else
            begin
              s_spi_mode = (en_quad) ? `SPI_QUAD_TX : `SPI_STD;
              if(spi_dummy_wr != 0)
              begin
                counter_tx       = en_quad ? {spi_dummy_wr[13:0],2'b00} : spi_dummy_wr;
                counter_tx_valid = 1'b1;
                ctrl_data_mux    = DATA_EMPTY;
                spi_en_tx        = 1'b1;
                state_next       = DUMMY;
              end
              else
              begin
                counter_tx       = spi_data_len;
                counter_tx_valid = 1'b1;
                ctrl_data_mux    = DATA_FIFO;
                ctrl_data_valid  = 1'b1;
                spi_en_tx        = 1'b1;
                state_next       = DATA_TX;
              end
            end
          end
          else
          begin
            state_next = IDLE;
          end
        end
        else
        begin
          spi_en_tx  = 1'b1;
          state_next = CMD;
        end
      end

      ADDR:
      begin
        spi_en_tx     = 1'b1;
        spi_status[2] = 1'b1;
        spi_cs        = 1'b0;
        spi_clock_en  = 1'b1;
        s_spi_mode    = (en_quad) ? `SPI_QUAD_TX : `SPI_STD;

        if (tx_done)
        begin
          if (spi_data_len != 0)
          begin
            if (do_rx)
            begin
              s_spi_mode = (en_quad) ? `SPI_QUAD_RX : `SPI_STD;
              if(spi_dummy_rd != 0)
              begin
                counter_tx       = en_quad ? {spi_dummy_rd[13:0],2'b00} : spi_dummy_rd;
                counter_tx_valid = 1'b1;
                spi_en_tx        = 1'b1;
                ctrl_data_mux    = DATA_EMPTY;
                state_next       = DUMMY;
              end
              else
              begin
                counter_rx       = spi_data_len;
                counter_rx_valid = 1'b1;
                spi_en_rx        = 1'b1;
                state_next       = DATA_RX;
              end
            end
            else
            begin
              s_spi_mode = (en_quad) ? `SPI_QUAD_TX : `SPI_STD;
              spi_en_tx  = 1'b1;

              if(spi_dummy_wr != 0) begin
                counter_tx       = en_quad ? {spi_dummy_wr[13:0],2'b00} : spi_dummy_wr;
                counter_tx_valid = 1'b1;
                ctrl_data_mux    = DATA_EMPTY;
                state_next       = DUMMY;
              end else begin
                counter_tx       = spi_data_len;
                counter_tx_valid = 1'b1;
                ctrl_data_mux    = DATA_FIFO;
                ctrl_data_valid  = 1'b1;
                state_next       = DATA_TX;
              end
            end
          end
          else
          begin
            state_next = IDLE;
          end
        end
      end

      MODE:
      begin
        spi_status[3] = 1'b1;
        spi_cs = 1'b0;
        spi_clock_en = 1'b1;
        spi_en_tx        = 1'b1;
      end

      DUMMY:
      begin
        spi_en_tx     = 1'b1;
        spi_status[4] = 1'b1;
        spi_cs        = 1'b0;
        spi_clock_en  = 1'b1;
        s_spi_mode    = (en_quad) ? `SPI_QUAD_RX : `SPI_STD;

        if (tx_done) begin
          if (spi_data_len != 0) begin
            if (do_rx) begin
              counter_rx       = spi_data_len;
              counter_rx_valid = 1'b1;
              spi_en_rx        = 1'b1;
              state_next       = DATA_RX;
            end else begin
              counter_tx       = spi_data_len;
              counter_tx_valid = 1'b1;
              s_spi_mode       = (en_quad) ? `SPI_QUAD_TX : `SPI_STD;

              spi_clock_en     = tx_clk_en;
              spi_en_tx        = 1'b1;
              state_next       = DATA_TX;
            end
          end
          else
          begin
            eot        = 1'b1;
            state_next = IDLE;
          end
        end
        else
        begin
          ctrl_data_mux = DATA_EMPTY;
          spi_en_tx     = 1'b1;
          state_next    = DUMMY;
        end
      end

      DATA_TX:
      begin
        spi_status[5]    = 1'b1;
        spi_cs           = 1'b0;
        spi_clock_en     = tx_clk_en;
        ctrl_data_mux    = DATA_FIFO;
        ctrl_data_valid  = 1'b1;
        spi_en_tx        = 1'b1;
        s_spi_mode       = (en_quad) ? `SPI_QUAD_TX : `SPI_STD;

        if (tx_done) begin
          eot          = 1'b1;
          state_next   = IDLE;
          spi_clock_en = 1'b0;
        end else begin
          state_next = DATA_TX;
        end
      end

      DATA_RX:
      begin
        spi_status[6] = 1'b1;
        spi_cs        = 1'b0;
        spi_clock_en  = rx_clk_en;
        s_spi_mode    = (en_quad) ? `SPI_QUAD_RX : `SPI_STD;

        if (rx_done) begin
          state_next = WAIT_EDGE;
        end else begin
          spi_en_rx  = 1'b1;
          state_next = DATA_RX;
        end
      end
      WAIT_EDGE:
      begin
        spi_status[6] = 1'b1;
        spi_cs        = 1'b0;
        spi_clock_en  = 1'b0;
        s_spi_mode    = (en_quad) ? `SPI_QUAD_RX : `SPI_STD;

        if (spi_fall) begin
          eot        = 1'b1;
          state_next = IDLE;
        end else begin
          state_next = WAIT_EDGE;
        end
      end
    endcase
  end


  always_ff @(posedge clk, negedge rstn)
  begin
    if (rstn == 1'b0)
    begin
      state       <= IDLE;
      en_quad_int <= 1'b0;
      do_rx       <= 1'b0;
      do_tx       <= 1'b0;
      spi_mode    <= `SPI_QUAD_RX;
    end
    else
    begin
      state <= state_next;
      spi_mode <= s_spi_mode;
      if (spi_qrd || spi_qwr)
        en_quad_int <= 1'b1;
      else if (state_next == IDLE)
        en_quad_int <= 1'b0;

      if (spi_rd || spi_qrd)
      begin
        do_rx <= 1'b1;
        do_tx <= 1'b0;
      end
      else if (spi_wr || spi_qwr)
      begin
        do_rx <= 1'b0;
        do_tx <= 1'b1;
      end
      else if (state_next == IDLE)
      begin
        do_rx <= 1'b0;
        do_tx <= 1'b0;
      end
    end
  end

  assign spi_csn0 = ~spi_csreg[0] | spi_cs;
  assign spi_csn1 = ~spi_csreg[1] | spi_cs;
  assign spi_csn2 = ~spi_csreg[2] | spi_cs;
  assign spi_csn3 = ~spi_csreg[3] | spi_cs;

endmodule
