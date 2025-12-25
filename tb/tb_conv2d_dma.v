/*
 * Copyright 2018-2020 Nuclei System Technology, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * @file tb_conv2d_dma.v
 * @brief Testbench for 2D Convolution with DMA
 * 
 * This testbench demonstrates:
 * - CPU performing 2D convolution
 * - DMA transferring results
 * - Complete memory system simulation
 */

`timescale 1ns/1ps

module tb_conv2d_dma();

  // Clock and reset
  reg clk;
  reg rst_n;

  // Memory parameters
  parameter SRAM_SIZE = 65536;  // 64KB = 16K words

  // ICB Slave Interface signals - CPU/testbench configuration
  reg                      cfg_icb_cmd_valid;
  wire                     cfg_icb_cmd_ready;
  reg  [31:0]              cfg_icb_cmd_addr;
  reg                      cfg_icb_cmd_read;
  reg  [31:0]              cfg_icb_cmd_wdata;
  reg  [3:0]               cfg_icb_cmd_wmask;
  
  wire                     cfg_icb_rsp_valid;
  reg                      cfg_icb_rsp_ready;
  wire                     cfg_icb_rsp_err;
  wire [31:0]              cfg_icb_rsp_rdata;

  // ICB Master Interface signals - memory access
  wire                     mem_icb_cmd_valid;
  reg                      mem_icb_cmd_ready;
  wire [31:0]              mem_icb_cmd_addr;
  wire                     mem_icb_cmd_read;
  wire [31:0]              mem_icb_cmd_wdata;
  wire [3:0]               mem_icb_cmd_wmask;
  wire                     mem_icb_cmd_lock;
  wire                     mem_icb_cmd_excl;
  wire [1:0]               mem_icb_cmd_size;
  
  reg                      mem_icb_rsp_valid;
  wire                     mem_icb_rsp_ready;
  reg                      mem_icb_rsp_err;
  reg                      mem_icb_rsp_excl_ok;
  reg  [31:0]              mem_icb_rsp_rdata;

  // Interrupt
  wire                     dma_irq;

  // SRAM memory model
  reg [31:0] sram [0:SRAM_SIZE-1];
  integer i, j, k;

  // Convolution parameters
  parameter FEATURE_H = 16;
  parameter FEATURE_W = 16;
  parameter FEATURE_C = 3;
  parameter KERNEL_H = 3;
  parameter KERNEL_W = 3;
  parameter OUTPUT_H = 14;
  parameter OUTPUT_W = 14;
  parameter OUTPUT_C = 3;

  // Memory addresses (word-aligned)
  parameter FEATURE_BASE = 32'h80000000;
  parameter KERNEL_BASE  = 32'h80000C00;
  parameter TEMP_BASE    = 32'h80001000;
  parameter OUTPUT_BASE  = 32'h80002000;
  parameter DONE_SIGNAL  = 32'h80010000;

  // DMA base address
  parameter DMA_BASE = 32'h10002000;

  // DMA Controller instance
  e203_dma_ctrl #(
    .AW(32),
    .DW(32)
  ) u_dma_ctrl (
    .cfg_icb_cmd_valid   (cfg_icb_cmd_valid),
    .cfg_icb_cmd_ready   (cfg_icb_cmd_ready),
    .cfg_icb_cmd_addr    (cfg_icb_cmd_addr),
    .cfg_icb_cmd_read    (cfg_icb_cmd_read),
    .cfg_icb_cmd_wdata   (cfg_icb_cmd_wdata),
    .cfg_icb_cmd_wmask   (cfg_icb_cmd_wmask),
    .cfg_icb_rsp_valid   (cfg_icb_rsp_valid),
    .cfg_icb_rsp_ready   (cfg_icb_rsp_ready),
    .cfg_icb_rsp_err     (cfg_icb_rsp_err),
    .cfg_icb_rsp_rdata   (cfg_icb_rsp_rdata),
    
    .mem_icb_cmd_valid   (mem_icb_cmd_valid),
    .mem_icb_cmd_ready   (mem_icb_cmd_ready),
    .mem_icb_cmd_addr    (mem_icb_cmd_addr),
    .mem_icb_cmd_read    (mem_icb_cmd_read),
    .mem_icb_cmd_wdata   (mem_icb_cmd_wdata),
    .mem_icb_cmd_wmask   (mem_icb_cmd_wmask),
    .mem_icb_cmd_lock    (mem_icb_cmd_lock),
    .mem_icb_cmd_excl    (mem_icb_cmd_excl),
    .mem_icb_cmd_size    (mem_icb_cmd_size),
    .mem_icb_rsp_valid   (mem_icb_rsp_valid),
    .mem_icb_rsp_ready   (mem_icb_rsp_ready),
    .mem_icb_rsp_err     (mem_icb_rsp_err),
    .mem_icb_rsp_excl_ok (mem_icb_rsp_excl_ok),
    .mem_icb_rsp_rdata   (mem_icb_rsp_rdata),
    
    .dma_irq             (dma_irq),
    .clk                 (clk),
    .rst_n               (rst_n)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 100MHz clock
  end

  // Memory model - responds to DMA requests
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mem_icb_rsp_valid <= 1'b0;
      mem_icb_rsp_rdata <= 32'h0;
      mem_icb_rsp_err <= 1'b0;
      mem_icb_rsp_excl_ok <= 1'b0;
    end else begin
      if (mem_icb_cmd_valid & mem_icb_cmd_ready) begin
        mem_icb_rsp_valid <= 1'b1;
        mem_icb_rsp_err <= 1'b0;
        if (mem_icb_cmd_read) begin
          // Read from memory
          mem_icb_rsp_rdata <= sram[mem_icb_cmd_addr[17:2]];
        end else begin
          // Write to memory
          if (mem_icb_cmd_wmask[0]) sram[mem_icb_cmd_addr[17:2]][7:0]   <= mem_icb_cmd_wdata[7:0];
          if (mem_icb_cmd_wmask[1]) sram[mem_icb_cmd_addr[17:2]][15:8]  <= mem_icb_cmd_wdata[15:8];
          if (mem_icb_cmd_wmask[2]) sram[mem_icb_cmd_addr[17:2]][23:16] <= mem_icb_cmd_wdata[23:16];
          if (mem_icb_cmd_wmask[3]) sram[mem_icb_cmd_addr[17:2]][31:24] <= mem_icb_cmd_wdata[31:24];
          mem_icb_rsp_rdata <= 32'h0;
        end
      end else if (mem_icb_rsp_ready) begin
        mem_icb_rsp_valid <= 1'b0;
      end
    end
  end

  // Tasks for DMA configuration
  task write_dma_reg;
    input [31:0] addr;
    input [31:0] data;
    begin
      @(posedge clk);
      cfg_icb_cmd_valid <= 1'b1;
      cfg_icb_cmd_read <= 1'b0;
      cfg_icb_cmd_addr <= addr;
      cfg_icb_cmd_wdata <= data;
      cfg_icb_cmd_wmask <= 4'b1111;
      cfg_icb_rsp_ready <= 1'b1;
      @(posedge clk);
      while (!cfg_icb_cmd_ready) @(posedge clk);
      cfg_icb_cmd_valid <= 1'b0;
      @(posedge clk);
      while (!cfg_icb_rsp_valid) @(posedge clk);
      @(posedge clk);
      cfg_icb_rsp_ready <= 1'b0;
    end
  endtask

  task read_dma_reg;
    input  [31:0] addr;
    output [31:0] data;
    begin
      @(posedge clk);
      cfg_icb_cmd_valid <= 1'b1;
      cfg_icb_cmd_read <= 1'b1;
      cfg_icb_cmd_addr <= addr;
      cfg_icb_rsp_ready <= 1'b1;
      @(posedge clk);
      while (!cfg_icb_cmd_ready) @(posedge clk);
      cfg_icb_cmd_valid <= 1'b0;
      @(posedge clk);
      while (!cfg_icb_rsp_valid) @(posedge clk);
      data = cfg_icb_rsp_rdata;
      @(posedge clk);
      cfg_icb_rsp_ready <= 1'b0;
    end
  endtask

  // Task to perform DMA transfer
  task dma_transfer;
    input [31:0] src;
    input [31:0] dst;
    input [31:0] count;
    reg [31:0] status;
    reg [31:0] start_time;
    reg [31:0] end_time;
    begin
      start_time = $time;
      $display("[%0t] === DMA Transfer Starting ===", $time);
      $display("           Source:      0x%08h", src);
      $display("           Destination: 0x%08h", dst);
      $display("           Count:       %0d words (%0d bytes)", count, count*4);
      
      $display("           Configuring DMA registers...");
      write_dma_reg(DMA_BASE + 32'h04, src);
      write_dma_reg(DMA_BASE + 32'h08, dst);
      write_dma_reg(DMA_BASE + 32'h0C, count);
      $display("           Starting DMA transfer...");
      write_dma_reg(DMA_BASE + 32'h00, 32'h00000001);  // Start
      
      // Wait for completion
      status = 32'h0;
      while ((status & 32'h00000002) == 0) begin
        #100;
        read_dma_reg(DMA_BASE + 32'h00, status);
      end
      
      end_time = $time;
      $display("[%0t] === DMA Transfer Complete ===", $time);
      $display("           Status: 0x%08h (DONE=%0d, BUSY=%0d, ERROR=%0d)", 
               status, (status>>1)&1, (status>>2)&1, (status>>3)&1);
      $display("           Duration: %0d ns (%0d cycles @ 100MHz)", 
               (end_time - start_time)/1000, (end_time - start_time)/10000);
      $display("           Throughput: ~%.2f cycles/word\n", 
               real'(end_time - start_time) / real'(count) / 10000.0);
      
      // Clear done flag
      write_dma_reg(DMA_BASE + 32'h00, 32'h00000002);
    end
  endtask

  // Function to compute single convolution
  function integer conv_compute;
    input integer feature_base;
    input integer kernel_base;
    input integer out_row;
    input integer out_col;
    integer kr, kc, fr, fc, f_idx, k_idx;
    integer sum;
    begin
      sum = 0;
      for (kr = 0; kr < KERNEL_H; kr = kr + 1) begin
        for (kc = 0; kc < KERNEL_W; kc = kc + 1) begin
          fr = out_row + kr;
          fc = out_col + kc;
          f_idx = feature_base + fr * FEATURE_W + fc;
          k_idx = kernel_base + kr * KERNEL_W + kc;
          sum = sum + (sram[f_idx] * sram[k_idx]);
        end
      end
      conv_compute = sum;
    end
  endfunction

  // Test stimulus
  reg [31:0] read_data;
  integer channel, out_row, out_col;
  integer feature_offset, kernel_offset, temp_idx, output_offset;
  integer conv_result;
  integer error_count;
  integer rand_val;
  
  initial begin
    // Initialize signals
    rst_n = 0;
    cfg_icb_cmd_valid = 0;
    cfg_icb_cmd_read = 0;
    cfg_icb_cmd_addr = 0;
    cfg_icb_cmd_wdata = 0;
    cfg_icb_cmd_wmask = 0;
    cfg_icb_rsp_ready = 0;
    mem_icb_cmd_ready = 1;  // Memory always ready

    // Initialize memory to zero
    for (i = 0; i < SRAM_SIZE; i = i + 1) begin
      sram[i] = 32'h0;
    end

    $display("=======================================================");
    $display("2D Convolution with DMA Test");
    $display("=======================================================");
    $display("Feature map: %0dx%0dx%0d", FEATURE_H, FEATURE_W, FEATURE_C);
    $display("Kernel: %0dx%0dx%0d", KERNEL_H, KERNEL_W, FEATURE_C);
    $display("Output: %0dx%0dx%0d", OUTPUT_H, OUTPUT_W, OUTPUT_C);
    $display("=======================================================");
    $display("\nMemory Layout:");
    $display("  Feature maps: 0x%08h - 0x%08h (%0d words)", FEATURE_BASE, FEATURE_BASE + FEATURE_H*FEATURE_W*FEATURE_C*4 - 4, FEATURE_H*FEATURE_W*FEATURE_C);
    $display("  Kernels:      0x%08h - 0x%08h (%0d words)", KERNEL_BASE, KERNEL_BASE + KERNEL_H*KERNEL_W*FEATURE_C*4 - 4, KERNEL_H*KERNEL_W*FEATURE_C);
    $display("  Temp buffer:  0x%08h - 0x%08h (%0d words)", TEMP_BASE, TEMP_BASE + OUTPUT_H*OUTPUT_W*4 - 4, OUTPUT_H*OUTPUT_W);
    $display("  Output:       0x%08h - 0x%08h (%0d words)", OUTPUT_BASE, OUTPUT_BASE + OUTPUT_H*OUTPUT_W*OUTPUT_C*4 - 4, OUTPUT_H*OUTPUT_W*OUTPUT_C);
    $display("  DMA regs:     0x%08h - 0x%08h", DMA_BASE, DMA_BASE + 32'h0F);
    $display("=======================================================\n");

    // Initialize feature maps with random data (small values for easier debugging)
    $display("Initializing feature maps...");
    for (i = 0; i < FEATURE_H * FEATURE_W * FEATURE_C; i = i + 1) begin
      rand_val = $random;
      if (rand_val < 0) rand_val = -rand_val;
      sram[(FEATURE_BASE >> 2) + i] = (rand_val % 10);  // Values 0-9
    end
    
    // Display sample input feature maps
    $display("\nSample Input Feature Map (Channel 0, top-left 4x4):");
    for (i = 0; i < 4; i = i + 1) begin
      $write("  ");
      for (j = 0; j < 4; j = j + 1) begin
        $write("%2d ", sram[(FEATURE_BASE >> 2) + i * FEATURE_W + j]);
      end
      $write("\n");
    end
    
    // Debug: show a few raw values
    $display("\nDebug - First 10 feature values:");
    for (i = 0; i < 10; i = i + 1) begin
      $display("  sram[%0d] = 0x%08h = %0d", (FEATURE_BASE >> 2) + i, 
               sram[(FEATURE_BASE >> 2) + i], sram[(FEATURE_BASE >> 2) + i]);
    end

    // Initialize kernels with small values
    $display("\nInitializing kernels...");
    for (i = 0; i < KERNEL_H * KERNEL_W * FEATURE_C; i = i + 1) begin
      rand_val = $random;
      if (rand_val < 0) rand_val = -rand_val;
      sram[(KERNEL_BASE >> 2) + i] = (rand_val % 5);  // Values 0-4
    end
    
    // Display sample kernels
    $display("\nSample Kernel (Channel 0, 3x3):");
    for (i = 0; i < 3; i = i + 1) begin
      $write("  ");
      for (j = 0; j < 3; j = j + 1) begin
        $write("%2d ", sram[(KERNEL_BASE >> 2) + i * KERNEL_W + j]);
      end
      $write("\n");
    end

    // Reset
    #100;
    rst_n = 1;
    #50;

    $display("\n--- Starting Convolution with DMA ---\n");

    // Initialize DMA
    write_dma_reg(DMA_BASE + 32'h00, 32'h00000006);  // Clear done and error

    error_count = 0;

    // Process each channel
    for (channel = 0; channel < FEATURE_C; channel = channel + 1) begin
      $display("\n=======================================================");
      $display("Processing Channel %0d", channel);
      $display("=======================================================");
      
      feature_offset = (FEATURE_BASE >> 2) + channel * (FEATURE_H * FEATURE_W);
      kernel_offset = (KERNEL_BASE >> 2) + channel * (KERNEL_H * KERNEL_W);
      output_offset = (OUTPUT_BASE >> 2) + channel * (OUTPUT_H * OUTPUT_W);

      // CPU: Compute convolution for this channel
      $display("\n[CPU Phase] Computing convolution...");
      $display("  Feature map offset: 0x%08h", feature_offset << 2);
      $display("  Kernel offset:      0x%08h", kernel_offset << 2);
      $display("  Temp buffer:        0x%08h", TEMP_BASE);
      
      for (out_row = 0; out_row < OUTPUT_H; out_row = out_row + 1) begin
        for (out_col = 0; out_col < OUTPUT_W; out_col = out_col + 1) begin
          conv_result = conv_compute(feature_offset, kernel_offset, out_row, out_col);
          temp_idx = (TEMP_BASE >> 2) + out_row * OUTPUT_W + out_col;
          sram[temp_idx] = conv_result;
          
          // Show first few computation results
          if (out_row == 0 && out_col < 3) begin
            $display("  Conv[%0d][%0d] = %0d", out_row, out_col, conv_result);
          end
        end
      end
      $display("  Computed %0d output values", OUTPUT_H * OUTPUT_W);
      
      // Show sample computed values in temp buffer
      $display("\n  Sample Temp Buffer (first 3x3):");
      for (i = 0; i < 3; i = i + 1) begin
        $write("    ");
        for (j = 0; j < 3; j = j + 1) begin
          $write("%6d ", sram[(TEMP_BASE >> 2) + i * OUTPUT_W + j]);
        end
        $write("\n");
      end

      // DMA: Transfer results to output
      $display("\n[DMA Phase] Transferring results to output memory...");
      dma_transfer(TEMP_BASE, OUTPUT_BASE + (channel * OUTPUT_H * OUTPUT_W * 4), 
                   OUTPUT_H * OUTPUT_W);
      
      // Verify transfer
      $display("  Verifying data integrity...");
      for (i = 0; i < OUTPUT_H * OUTPUT_W; i = i + 1) begin
        if (sram[(TEMP_BASE >> 2) + i] !== sram[output_offset + i]) begin
          $display("  ERROR: Mismatch at channel %0d, index %0d", channel, i);
          error_count = error_count + 1;
        end
      end
      if (error_count == 0) begin
        $display("  ✓ All %0d words transferred correctly!", OUTPUT_H * OUTPUT_W);
      end
    end

    $display("\n=======================================================");
    $display("Convolution with DMA Test Complete!");
    $display("=======================================================");
    
    if (error_count == 0) begin
      $display("PASS: All data transferred correctly!");
    end else begin
      $display("FAIL: %0d errors detected", error_count);
    end

    // Display sample results
    $display("\n=======================================================");
    $display("Final Output Results");
    $display("=======================================================\n");
    
    for (channel = 0; channel < FEATURE_C; channel = channel + 1) begin
      $display("Channel %0d Output (first 5x5, showing decimal values):", channel);
      output_offset = (OUTPUT_BASE >> 2) + channel * (OUTPUT_H * OUTPUT_W);
      for (i = 0; i < 5; i = i + 1) begin
        $write("  ");
        for (j = 0; j < 5; j = j + 1) begin
          $write("%6d ", sram[output_offset + i * OUTPUT_W + j]);
        end
        $write("\n");
      end
      $display("");
    end
    
    // Display statistics
    $display("=======================================================");
    $display("Statistics:");
    $display("  Total operations: %0d convolutions", OUTPUT_H * OUTPUT_W * FEATURE_C);
    $display("  Each convolution: %0d multiply-accumulate operations", KERNEL_H * KERNEL_W);
    $display("  Total MAC ops:    %0d", OUTPUT_H * OUTPUT_W * FEATURE_C * KERNEL_H * KERNEL_W);
    $display("  DMA transfers:    %0d (one per channel)", FEATURE_C);
    $display("  Data transferred: %0d words (%0d KB)", OUTPUT_H * OUTPUT_W * FEATURE_C, (OUTPUT_H * OUTPUT_W * FEATURE_C * 4) / 1024);
    $display("=======================================================\n");
    
    #1000;
    $finish;
  end

  // Waveform dump
  initial begin
    $dumpfile("tb_conv2d_dma.vcd");
    $dumpvars(0, tb_conv2d_dma);
  end

  // Timeout watchdog
  initial begin
    #5000000;  // 5ms timeout
    $display("ERROR: Test timeout!");
    $finish;
  end

endmodule
