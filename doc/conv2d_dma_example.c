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
 * @file conv2d_dma_example.c
 * @brief 2D Convolution with DMA Transfer Example
 * 
 * This program demonstrates:
 * - CPU performing 2D convolution computation
 * - DMA controller moving results to output buffer
 * 
 * Data Specifications:
 * - Feature map: 16×16×3 (Height × Width × Channels)
 * - Kernel: 3×3×3
 * - Stride: 1
 * - Padding: None (valid convolution)
 * - Output: 14×14×3
 * - Element width: 32-bit
 */

#include <stdint.h>

/* ===================================================================
 * DMA Register Definitions
 * =================================================================== */

#define DMA_BASE_ADDR           0x10002000UL
#define DMA_CSR                 (*(volatile uint32_t*)(DMA_BASE_ADDR + 0x00))
#define DMA_SRC                 (*(volatile uint32_t*)(DMA_BASE_ADDR + 0x04))
#define DMA_DST                 (*(volatile uint32_t*)(DMA_BASE_ADDR + 0x08))
#define DMA_CNT                 (*(volatile uint32_t*)(DMA_BASE_ADDR + 0x0C))

#define DMA_CSR_START           (1U << 0)
#define DMA_CSR_DONE            (1U << 1)
#define DMA_CSR_BUSY            (1U << 2)
#define DMA_CSR_ERROR           (1U << 3)

/* ===================================================================
 * Memory Layout in SRAM_1
 * =================================================================== */

#define SRAM1_BASE              0x80000000UL

// Input feature maps: 16×16×3 = 768 words
#define FEATURE_BASE            (SRAM1_BASE + 0x0000)
#define FEATURE_SIZE            (16 * 16 * 3)

// Convolution kernels: 3×3×3 = 27 words per channel
#define KERNEL_BASE             (SRAM1_BASE + 0x0C00)  // 768 words offset
#define KERNEL_SIZE             (3 * 3 * 3)

// Temporary computation buffer: 14×14 = 196 words per channel
#define TEMP_BUFFER_BASE        (SRAM1_BASE + 0x1000)  // 4KB offset
#define TEMP_BUFFER_SIZE        (14 * 14)

// Final output: 14×14×3 = 588 words
#define OUTPUT_BASE             (SRAM1_BASE + 0x2000)  // 8KB offset
#define OUTPUT_SIZE             (14 * 14 * 3)

/* ===================================================================
 * Convolution Parameters
 * =================================================================== */

#define FEATURE_HEIGHT          16
#define FEATURE_WIDTH           16
#define FEATURE_CHANNELS        3

#define KERNEL_HEIGHT           3
#define KERNEL_WIDTH            3

#define OUTPUT_HEIGHT           14  // (16 - 3 + 1) = 14
#define OUTPUT_WIDTH            14
#define OUTPUT_CHANNELS         3

#define STRIDE                  1

/* ===================================================================
 * Helper Functions
 * =================================================================== */

/**
 * @brief Initialize DMA controller
 */
static inline void dma_init(void)
{
    DMA_CSR = DMA_CSR_DONE | DMA_CSR_ERROR;
}

/**
 * @brief Check if DMA is done
 */
static inline int dma_is_done(void)
{
    return (DMA_CSR & DMA_CSR_DONE) ? 1 : 0;
}

/**
 * @brief Perform DMA transfer
 * 
 * @param src Source address
 * @param dst Destination address
 * @param count Number of 32-bit words
 * @return 0 on success, -1 on error
 */
int dma_transfer(uint32_t src, uint32_t dst, uint32_t count)
{
    // Check if DMA is busy
    if (DMA_CSR & DMA_CSR_BUSY) {
        return -1;
    }
    
    // Configure DMA
    DMA_SRC = src;
    DMA_DST = dst;
    DMA_CNT = count;
    
    // Start transfer
    DMA_CSR = DMA_CSR_START;
    
    // Wait for completion
    while (!dma_is_done()) {
        // Busy wait
    }
    
    // Check for errors
    if (DMA_CSR & DMA_CSR_ERROR) {
        return -1;
    }
    
    // Clear done flag
    DMA_CSR = DMA_CSR_DONE;
    
    return 0;
}

/* ===================================================================
 * Convolution Functions
 * =================================================================== */

/**
 * @brief Perform 2D convolution for one channel
 * 
 * Computes convolution of a single feature map channel with a kernel.
 * 
 * @param feature Pointer to feature map (16×16)
 * @param kernel Pointer to kernel (3×3)
 * @param output Pointer to output buffer (14×14)
 */
void conv2d_single_channel(
    const int32_t *feature,
    const int32_t *kernel,
    int32_t *output
)
{
    int out_row, out_col, kr, kc;
    
    // Iterate over output positions
    for (out_row = 0; out_row < OUTPUT_HEIGHT; out_row++) {
        for (out_col = 0; out_col < OUTPUT_WIDTH; out_col++) {
            int32_t sum = 0;
            
            // Perform convolution at this position
            for (kr = 0; kr < KERNEL_HEIGHT; kr++) {
                for (kc = 0; kc < KERNEL_WIDTH; kc++) {
                    int feature_row = out_row * STRIDE + kr;
                    int feature_col = out_col * STRIDE + kc;
                    
                    int feature_idx = feature_row * FEATURE_WIDTH + feature_col;
                    int kernel_idx = kr * KERNEL_WIDTH + kc;
                    
                    sum += feature[feature_idx] * kernel[kernel_idx];
                }
            }
            
            // Store result
            output[out_row * OUTPUT_WIDTH + out_col] = sum;
        }
    }
}

/**
 * @brief Perform 2D convolution for all channels with DMA optimization
 * 
 * This function demonstrates CPU-DMA cooperation:
 * 1. CPU computes convolution for one channel
 * 2. DMA moves results from temp buffer to final output
 * 3. Repeat for all channels
 * 
 * @return 0 on success, -1 on error
 */
int conv2d_with_dma(void)
{
    int channel;
    int32_t *feature = (int32_t *)FEATURE_BASE;
    int32_t *kernel = (int32_t *)KERNEL_BASE;
    int32_t *temp_buffer = (int32_t *)TEMP_BUFFER_BASE;
    int32_t *output = (int32_t *)OUTPUT_BASE;
    
    // Initialize DMA
    dma_init();
    
    // Process each channel
    for (channel = 0; channel < FEATURE_CHANNELS; channel++) {
        // Calculate channel offsets
        int feature_offset = channel * (FEATURE_HEIGHT * FEATURE_WIDTH);
        int kernel_offset = channel * (KERNEL_HEIGHT * KERNEL_WIDTH);
        int output_offset = channel * (OUTPUT_HEIGHT * OUTPUT_WIDTH);
        
        // CPU: Compute convolution for this channel
        conv2d_single_channel(
            feature + feature_offset,
            kernel + kernel_offset,
            temp_buffer
        );
        
        // DMA: Move computed results to output buffer
        uint32_t src_addr = (uint32_t)temp_buffer;
        uint32_t dst_addr = (uint32_t)(output + output_offset);
        uint32_t count = OUTPUT_HEIGHT * OUTPUT_WIDTH;
        
        if (dma_transfer(src_addr, dst_addr, count) != 0) {
            return -1;  // DMA error
        }
    }
    
    return 0;
}

/* ===================================================================
 * Main Function
 * =================================================================== */

/**
 * @brief Main entry point for convolution with DMA example
 * 
 * Memory is pre-initialized with:
 * - Feature maps at FEATURE_BASE
 * - Kernels at KERNEL_BASE
 * 
 * Results will be stored at OUTPUT_BASE after processing.
 */
int main(void)
{
    int result;
    
    // Perform convolution with DMA optimization
    result = conv2d_with_dma();
    
    // Signal completion to testbench
    // Writing to a specific address can be used as completion marker
    volatile uint32_t *done_signal = (volatile uint32_t *)0x80010000;
    *done_signal = (result == 0) ? 0x12345678 : 0xDEADBEEF;
    
    return result;
}

/* ===================================================================
 * Memory Map Summary
 * =================================================================== */

/*
 * SRAM_1 Memory Layout:
 * 
 * 0x80000000 - 0x80000BFF : Feature maps (16×16×3 = 768 words = 3KB)
 * 0x80000C00 - 0x80000C6B : Kernels (3×3×3 = 27 words = 108 bytes)
 * 0x80001000 - 0x800013DF : Temp buffer (14×14 = 196 words = 784 bytes)
 * 0x80002000 - 0x80002927 : Output (14×14×3 = 588 words = 2352 bytes)
 * 0x80010000           : Done signal
 * 
 * Total memory used: ~12KB
 */
