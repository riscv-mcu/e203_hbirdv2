/*                                                                      
Copyright 2018-2020 Nuclei System Technology, Inc.                

Licensed under the Apache License, Version 2.0 (the "License");         
you may not use this file except in compliance with the License.        
You may obtain a copy of the License at                                 
                                                                        
    http://www.apache.org/licenses/LICENSE-2.0                          
                                                                        
 Unless required by applicable law or agreed to in writing, software    
distributed under the License is distributed on an "AS IS" BASIS,       
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and     
limitations under the License.                                          
*/                                                                      

//=====================================================================
//
// Designer   : Generated for E203 integration
//
// Description:
//  Simple DMA Controller Module
//  - ICB slave interface for CPU configuration
//  - ICB master interface for memory transfers
//  - Supports memory-to-memory DMA transfers
//  - Interrupt generation on transfer completion
//
// Register Map:
//  0x00: Control/Status Register (CSR)
//        [0] - START: Write 1 to start DMA transfer
//        [1] - DONE: Read 1 when transfer complete (write 1 to clear)
//        [2] - BUSY: Read 1 when DMA is busy
//        [3] - ERROR: Read 1 if error occurred
//  0x04: Source Address Register
//  0x08: Destination Address Register
//  0x0C: Transfer Count Register (number of 32-bit words)
//
// ====================================================================

`include "e203_defines.v"

module e203_dma_ctrl #(
  parameter AW = 32,
  parameter DW = 32
)(
  // ICB Slave Interface - for CPU configuration
  input                      cfg_icb_cmd_valid,
  output                     cfg_icb_cmd_ready,
  input  [AW-1:0]            cfg_icb_cmd_addr,
  input                      cfg_icb_cmd_read,
  input  [DW-1:0]            cfg_icb_cmd_wdata,
  input  [DW/8-1:0]          cfg_icb_cmd_wmask,
  
  output                     cfg_icb_rsp_valid,
  input                      cfg_icb_rsp_ready,
  output                     cfg_icb_rsp_err,
  output [DW-1:0]            cfg_icb_rsp_rdata,

  // ICB Master Interface - for memory access
  output                     mem_icb_cmd_valid,
  input                      mem_icb_cmd_ready,
  output [AW-1:0]            mem_icb_cmd_addr,
  output                     mem_icb_cmd_read,
  output [DW-1:0]            mem_icb_cmd_wdata,
  output [DW/8-1:0]          mem_icb_cmd_wmask,
  output                     mem_icb_cmd_lock,
  output                     mem_icb_cmd_excl,
  output [1:0]               mem_icb_cmd_size,
  
  input                      mem_icb_rsp_valid,
  output                     mem_icb_rsp_ready,
  input                      mem_icb_rsp_err,
  input                      mem_icb_rsp_excl_ok,
  input  [DW-1:0]            mem_icb_rsp_rdata,

  // Interrupt output
  output                     dma_irq,

  input                      clk,
  input                      rst_n
);

  // Register addresses (word-aligned)
  localparam REG_CSR    = 4'h0;  // Control/Status Register
  localparam REG_SRC    = 4'h4;  // Source Address
  localparam REG_DST    = 4'h8;  // Destination Address
  localparam REG_CNT    = 4'hC;  // Transfer Count

  // DMA State Machine
  localparam STATE_IDLE     = 3'b000;
  localparam STATE_READ     = 3'b001;
  localparam STATE_READ_RSP = 3'b010;
  localparam STATE_WRITE    = 3'b011;
  localparam STATE_WRITE_RSP= 3'b100;
  localparam STATE_DONE     = 3'b101;

  // Registers
  reg [AW-1:0]  src_addr;
  reg [AW-1:0]  dst_addr;
  reg [AW-1:0]  transfer_cnt;
  reg [AW-1:0]  current_cnt;
  reg           start_flag;
  reg           done_flag;
  reg           error_flag;
  reg [2:0]     state;
  reg [DW-1:0]  data_buffer;

  wire busy = (state != STATE_IDLE);
  
  // Configuration Interface - Slave
  wire cfg_wen = cfg_icb_cmd_valid & (~cfg_icb_cmd_read);
  wire cfg_ren = cfg_icb_cmd_valid & cfg_icb_cmd_read;
  wire [3:0] cfg_addr = cfg_icb_cmd_addr[3:0];

  // Configuration write handling
  wire write_csr = cfg_wen & (cfg_addr == REG_CSR);
  wire write_src = cfg_wen & (cfg_addr == REG_SRC);
  wire write_dst = cfg_wen & (cfg_addr == REG_DST);
  wire write_cnt = cfg_wen & (cfg_addr == REG_CNT);

  // Start signal - triggered by writing 1 to CSR[0]
  wire start_req = write_csr & cfg_icb_cmd_wdata[0] & (~busy);
  
  // Done clear - triggered by writing 1 to CSR[1]
  wire done_clear = write_csr & cfg_icb_cmd_wdata[1];

  // Configuration read data
  reg [DW-1:0] cfg_rdata;
  always @(*) begin
    case (cfg_addr)
      REG_CSR: cfg_rdata = {28'h0, error_flag, busy, done_flag, 1'b0};
      REG_SRC: cfg_rdata = src_addr;
      REG_DST: cfg_rdata = dst_addr;
      REG_CNT: cfg_rdata = transfer_cnt;
      default: cfg_rdata = 32'h0;
    endcase
  end

  // Configuration response
  reg cfg_rsp_valid_r;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      cfg_rsp_valid_r <= 1'b0;
    else if (cfg_icb_cmd_valid & cfg_icb_cmd_ready)
      cfg_rsp_valid_r <= 1'b1;
    else if (cfg_icb_rsp_ready)
      cfg_rsp_valid_r <= 1'b0;
  end

  assign cfg_icb_cmd_ready = (~cfg_rsp_valid_r) | cfg_icb_rsp_ready;
  assign cfg_icb_rsp_valid = cfg_rsp_valid_r;
  assign cfg_icb_rsp_rdata = cfg_rdata;
  assign cfg_icb_rsp_err   = 1'b0;

  // Register updates
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      src_addr <= {AW{1'b0}};
    end else if (write_src) begin
      src_addr <= cfg_icb_cmd_wdata[AW-1:0];
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      dst_addr <= {AW{1'b0}};
    end else if (write_dst) begin
      dst_addr <= cfg_icb_cmd_wdata[AW-1:0];
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      transfer_cnt <= {AW{1'b0}};
    end else if (write_cnt) begin
      transfer_cnt <= cfg_icb_cmd_wdata[AW-1:0];
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      done_flag <= 1'b0;
    end else if (done_clear) begin
      done_flag <= 1'b0;
    end else if (state == STATE_DONE) begin
      done_flag <= 1'b1;
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      error_flag <= 1'b0;
    end else if (done_clear) begin
      error_flag <= 1'b0;
    end else if (mem_icb_rsp_valid & mem_icb_rsp_err) begin
      error_flag <= 1'b1;
    end
  end

  // DMA State Machine
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= STATE_IDLE;
      current_cnt <= {AW{1'b0}};
      data_buffer <= {DW{1'b0}};
    end else begin
      case (state)
        STATE_IDLE: begin
          if (start_req) begin
            state <= STATE_READ;
            current_cnt <= {AW{1'b0}};
          end
        end

        STATE_READ: begin
          if (mem_icb_cmd_valid & mem_icb_cmd_ready) begin
            state <= STATE_READ_RSP;
          end
        end

        STATE_READ_RSP: begin
          if (mem_icb_rsp_valid & mem_icb_rsp_ready) begin
            if (mem_icb_rsp_err) begin
              state <= STATE_DONE;  // Error occurred
            end else begin
              data_buffer <= mem_icb_rsp_rdata;
              state <= STATE_WRITE;
            end
          end
        end

        STATE_WRITE: begin
          if (mem_icb_cmd_valid & mem_icb_cmd_ready) begin
            state <= STATE_WRITE_RSP;
          end
        end

        STATE_WRITE_RSP: begin
          if (mem_icb_rsp_valid & mem_icb_rsp_ready) begin
            if (mem_icb_rsp_err) begin
              state <= STATE_DONE;  // Error occurred
            end else begin
              current_cnt <= current_cnt + 1'b1;
              if (current_cnt + 1'b1 >= transfer_cnt) begin
                state <= STATE_DONE;
              end else begin
                state <= STATE_READ;
              end
            end
          end
        end

        STATE_DONE: begin
          state <= STATE_IDLE;
        end

        default: begin
          state <= STATE_IDLE;
        end
      endcase
    end
  end

  // Memory Interface - Master
  assign mem_icb_cmd_valid = (state == STATE_READ) | (state == STATE_WRITE);
  assign mem_icb_cmd_read  = (state == STATE_READ);
  assign mem_icb_cmd_addr  = (state == STATE_READ) ? 
                             (src_addr + (current_cnt << 2)) : 
                             (dst_addr + (current_cnt << 2));
  assign mem_icb_cmd_wdata = data_buffer;
  assign mem_icb_cmd_wmask = 4'b1111;  // Full word write
  assign mem_icb_cmd_lock  = 1'b0;
  assign mem_icb_cmd_excl  = 1'b0;
  assign mem_icb_cmd_size  = 2'b10;    // 32-bit word access
  
  assign mem_icb_rsp_ready = (state == STATE_READ_RSP) | (state == STATE_WRITE_RSP);

  // Interrupt generation - pulse on completion
  reg dma_irq_r;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      dma_irq_r <= 1'b0;
    end else begin
      dma_irq_r <= (state == STATE_DONE);
    end
  end
  assign dma_irq = dma_irq_r;

endmodule
