// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

module spi_master_tx
(
    input  logic        clk,
    input  logic        rstn,
    input  logic        en,
    input  logic        tx_edge,
    output logic        tx_done,
    output logic        sdo0,
    output logic        sdo1,
    output logic        sdo2,
    output logic        sdo3,
    input  logic        en_quad_in,
    input  logic [15:0] counter_in,
    input  logic        counter_in_upd,
    input  logic [31:0] data,
    input  logic        data_valid,
    output logic        data_ready,
    output logic        clk_en_o
);

  logic [31:0] data_int;
  logic [31:0] data_int_next;
  logic [15:0] counter;
  logic [15:0] counter_trgt;
  logic [15:0] counter_next;
  logic [15:0] counter_trgt_next;
  logic        done;
  logic        reg_done;

  enum logic [0:0] { IDLE, TRANSMIT } tx_CS, tx_NS;

  assign sdo0 = (en_quad_in) ? data_int[28] : data_int[31];
  assign sdo1 = data_int[29];
  assign sdo2 = data_int[30];
  assign sdo3 = data_int[31];

  assign tx_done = done;

  assign reg_done  = (!en_quad_in && (counter[4:0] == 5'b11111)) || (en_quad_in && (counter[2:0] == 3'b111));

  always_comb
  begin
    if (counter_in_upd)
      counter_trgt_next = (en_quad_in) ? {2'b00,counter_in[15:2]} : counter_in;
    else
      counter_trgt_next = counter_trgt;
  end

  assign done = (counter == counter_trgt-1) && tx_edge;

  always_comb
  begin
    tx_NS         = tx_CS;
    clk_en_o      = 1'b0;
    data_int_next = data_int;
    data_ready    = 1'b0;
    counter_next  = counter;

    case (tx_CS)
      IDLE: begin
        clk_en_o = 1'b0;

        if (en && data_valid) begin
          data_int_next = data;
          data_ready    = 1'b1;
          tx_NS         = TRANSMIT;
        end
      end

      TRANSMIT: begin
        clk_en_o = 1'b1;

        if (tx_edge) begin
          counter_next = counter + 1;
          data_int_next = (en_quad_in) ? {data_int[27:0],4'b0000} : {data_int[30:0],1'b0};

          if (tx_done) begin
            counter_next = 0;

            if (en && data_valid) begin
              data_int_next = data;
              data_ready    = 1'b1;
              tx_NS         = TRANSMIT;
            end else begin
              clk_en_o = 1'b0;
              tx_NS    = IDLE;
            end
          end else if (reg_done) begin
            if (data_valid) begin
              data_int_next = data;
              data_ready    = 1'b1;
            end else begin
              clk_en_o = 1'b0;
              tx_NS    = IDLE;
            end
          end
        end
      end
    endcase
  end

  always_ff @(posedge clk, negedge rstn)
  begin
    if (~rstn)
    begin
      counter      <= 0;
      counter_trgt <= 'h8;
      data_int     <= 'h0;
      tx_CS        <= IDLE;
    end
    else
    begin
      counter      <= counter_next;
      counter_trgt <= counter_trgt_next;
      data_int     <= data_int_next;
      tx_CS        <= tx_NS;
    end
  end
endmodule
