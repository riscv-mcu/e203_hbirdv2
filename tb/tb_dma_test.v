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
// Description:
//  Simple testbench for DMA controller verification
//  Tests basic memory-to-memory DMA transfer functionality
//
// ====================================================================

`timescale 1ns/1ps

module tb_dma_test();

  // Clock and reset
  reg clk;
  reg rst_n;

  // ICB Slave Interface signals - CPU configuration
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

  // Simple memory model
  reg [31:0] memory [0:1023];
  integer i;

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
          mem_icb_rsp_rdata <= memory[mem_icb_cmd_addr[11:2]];
        end else begin
          // Write to memory
          memory[mem_icb_cmd_addr[11:2]] <= mem_icb_cmd_wdata;
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

  // Test stimulus
  reg [31:0] read_data;
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

    // Initialize source memory with test pattern
    for (i = 0; i < 1024; i = i + 1) begin
      memory[i] = 32'h0;
    end
    // Source data at address 0x000 - 0x03C (16 words)
    for (i = 0; i < 16; i = i + 1) begin
      memory[i] = 32'hA000_0000 + i;
    end

    // Reset
    #100;
    rst_n = 1;
    #50;

    $display("==============================================");
    $display("DMA Test Starting...");
    $display("==============================================");

    // Configure DMA
    $display("[%0t] Writing DMA source address: 0x00000000", $time);
    write_dma_reg(32'h04, 32'h0000_0000);  // Source address
    
    $display("[%0t] Writing DMA destination address: 0x00000100", $time);
    write_dma_reg(32'h08, 32'h0000_0100);  // Destination address (word 64)
    
    $display("[%0t] Writing DMA transfer count: 16 words", $time);
    write_dma_reg(32'h0C, 32'h0000_0010);  // Transfer 16 words

    // Start DMA
    $display("[%0t] Starting DMA transfer...", $time);
    write_dma_reg(32'h00, 32'h0000_0001);  // Start DMA

    // Wait for completion
    read_data = 32'h0;
    while ((read_data & 32'h0000_0002) == 0) begin
      #100;
      read_dma_reg(32'h00, read_data);  // Read status
    end
    
    $display("[%0t] DMA transfer completed! Status: 0x%08h", $time, read_data);

    // Verify data
    $display("\n==============================================");
    $display("Verifying transferred data...");
    $display("==============================================");
    for (i = 0; i < 16; i = i + 1) begin
      if (memory[i] != memory[64+i]) begin
        $display("ERROR: Data mismatch at index %0d: src=0x%08h dst=0x%08h", 
                 i, memory[i], memory[64+i]);
      end else begin
        $display("PASS: Index %0d: 0x%08h", i, memory[64+i]);
      end
    end

    $display("\n==============================================");
    $display("DMA Test Complete!");
    $display("==============================================");
    
    #1000;
    $finish;
  end

  // Waveform dump
  initial begin
    $dumpfile("tb_dma_test.vcd");
    $dumpvars(0, tb_dma_test);
  end

  // Timeout watchdog
  initial begin
    #100000;
    $display("ERROR: Test timeout!");
    $finish;
  end

endmodule
