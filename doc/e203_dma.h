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
 * @file e203_dma.h
 * @brief DMA Controller Driver Header for E203 SoC
 * 
 * This header provides register definitions and API functions
 * for the E203 DMA controller module.
 */

#ifndef __E203_DMA_H__
#define __E203_DMA_H__

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ===================================================================
 * DMA Register Definitions
 * =================================================================== */

/* DMA Base Address - modify this based on actual address mapping */
#ifndef DMA_BASE_ADDR
#define DMA_BASE_ADDR           0x10002000UL
#endif

/* DMA Register Offsets */
#define DMA_CSR_OFFSET          0x00    /**< Control/Status Register */
#define DMA_SRC_OFFSET          0x04    /**< Source Address Register */
#define DMA_DST_OFFSET          0x08    /**< Destination Address Register */
#define DMA_CNT_OFFSET          0x0C    /**< Transfer Count Register */

/* DMA Register Addresses */
#define DMA_CSR                 (*(volatile uint32_t*)(DMA_BASE_ADDR + DMA_CSR_OFFSET))
#define DMA_SRC                 (*(volatile uint32_t*)(DMA_BASE_ADDR + DMA_SRC_OFFSET))
#define DMA_DST                 (*(volatile uint32_t*)(DMA_BASE_ADDR + DMA_DST_OFFSET))
#define DMA_CNT                 (*(volatile uint32_t*)(DMA_BASE_ADDR + DMA_CNT_OFFSET))

/* DMA Control/Status Register Bit Definitions */
#define DMA_CSR_START           (1U << 0)   /**< Start DMA transfer */
#define DMA_CSR_DONE            (1U << 1)   /**< Transfer done flag */
#define DMA_CSR_BUSY            (1U << 2)   /**< DMA busy flag (read-only) */
#define DMA_CSR_ERROR           (1U << 3)   /**< Error flag */

/* ===================================================================
 * DMA Status Codes
 * =================================================================== */

typedef enum {
    DMA_OK = 0,                 /**< Operation successful */
    DMA_ERR_BUSY = -1,          /**< DMA is busy */
    DMA_ERR_INVALID = -2,       /**< Invalid parameter */
    DMA_ERR_TIMEOUT = -3,       /**< Operation timeout */
    DMA_ERR_TRANSFER = -4       /**< Transfer error occurred */
} dma_status_t;

/* ===================================================================
 * DMA Configuration Structure
 * =================================================================== */

/**
 * @brief DMA transfer configuration
 */
typedef struct {
    uint32_t src_addr;          /**< Source address (word-aligned) */
    uint32_t dst_addr;          /**< Destination address (word-aligned) */
    uint32_t count;             /**< Number of 32-bit words to transfer */
} dma_config_t;

/* ===================================================================
 * DMA API Functions
 * =================================================================== */

/**
 * @brief Initialize DMA controller
 * 
 * This function initializes the DMA controller by clearing any
 * pending status flags.
 */
static inline void dma_init(void)
{
    /* Clear done and error flags */
    DMA_CSR = DMA_CSR_DONE | DMA_CSR_ERROR;
}

/**
 * @brief Check if DMA is busy
 * 
 * @return 1 if DMA is busy, 0 otherwise
 */
static inline int dma_is_busy(void)
{
    return (DMA_CSR & DMA_CSR_BUSY) ? 1 : 0;
}

/**
 * @brief Check if DMA transfer is done
 * 
 * @return 1 if transfer is complete, 0 otherwise
 */
static inline int dma_is_done(void)
{
    return (DMA_CSR & DMA_CSR_DONE) ? 1 : 0;
}

/**
 * @brief Check if DMA error occurred
 * 
 * @return 1 if error occurred, 0 otherwise
 */
static inline int dma_has_error(void)
{
    return (DMA_CSR & DMA_CSR_ERROR) ? 1 : 0;
}

/**
 * @brief Clear DMA done flag
 */
static inline void dma_clear_done(void)
{
    DMA_CSR = DMA_CSR_DONE;
}

/**
 * @brief Clear DMA error flag
 */
static inline void dma_clear_error(void)
{
    DMA_CSR = DMA_CSR_ERROR;
}

/**
 * @brief Configure DMA transfer
 * 
 * @param config Pointer to DMA configuration structure
 * @return DMA_OK on success, error code otherwise
 */
static inline dma_status_t dma_config(const dma_config_t *config)
{
    if (config == NULL) {
        return DMA_ERR_INVALID;
    }
    
    /* Check if DMA is busy */
    if (dma_is_busy()) {
        return DMA_ERR_BUSY;
    }
    
    /* Check alignment (word-aligned) */
    if ((config->src_addr & 0x3) || (config->dst_addr & 0x3)) {
        return DMA_ERR_INVALID;
    }
    
    /* Configure DMA registers */
    DMA_SRC = config->src_addr;
    DMA_DST = config->dst_addr;
    DMA_CNT = config->count;
    
    return DMA_OK;
}

/**
 * @brief Start DMA transfer
 * 
 * @return DMA_OK on success, DMA_ERR_BUSY if DMA is busy
 */
static inline dma_status_t dma_start(void)
{
    if (dma_is_busy()) {
        return DMA_ERR_BUSY;
    }
    
    DMA_CSR = DMA_CSR_START;
    return DMA_OK;
}

/**
 * @brief Wait for DMA transfer to complete (blocking)
 * 
 * @param timeout Maximum iterations to wait (0 = wait forever)
 * @return DMA_OK if completed successfully, error code otherwise
 */
static inline dma_status_t dma_wait_done(uint32_t timeout)
{
    uint32_t count = 0;
    
    while (!dma_is_done()) {
        if (timeout > 0) {
            count++;
            if (count >= timeout) {
                return DMA_ERR_TIMEOUT;
            }
        }
    }
    
    /* Check for errors */
    if (dma_has_error()) {
        return DMA_ERR_TRANSFER;
    }
    
    return DMA_OK;
}

/**
 * @brief Perform DMA transfer (configure + start + wait)
 * 
 * This is a convenience function that performs a complete DMA
 * transfer operation.
 * 
 * @param src_addr Source address (word-aligned)
 * @param dst_addr Destination address (word-aligned)
 * @param count Number of 32-bit words to transfer
 * @param timeout Timeout value for waiting (0 = wait forever)
 * @return DMA_OK on success, error code otherwise
 */
static inline dma_status_t dma_transfer(uint32_t src_addr, 
                                        uint32_t dst_addr,
                                        uint32_t count,
                                        uint32_t timeout)
{
    dma_config_t config;
    dma_status_t status;
    
    /* Configure DMA */
    config.src_addr = src_addr;
    config.dst_addr = dst_addr;
    config.count = count;
    
    status = dma_config(&config);
    if (status != DMA_OK) {
        return status;
    }
    
    /* Start transfer */
    status = dma_start();
    if (status != DMA_OK) {
        return status;
    }
    
    /* Wait for completion */
    status = dma_wait_done(timeout);
    if (status != DMA_OK) {
        return status;
    }
    
    /* Clear done flag */
    dma_clear_done();
    
    return DMA_OK;
}

/* ===================================================================
 * Example Usage
 * =================================================================== */

#if 0
/* Example 1: Simple memory copy */
void example_dma_copy(void)
{
    uint32_t src_buf[256];
    uint32_t dst_buf[256];
    dma_status_t status;
    
    /* Initialize DMA */
    dma_init();
    
    /* Perform DMA transfer (256 words) */
    status = dma_transfer((uint32_t)src_buf, (uint32_t)dst_buf, 256, 10000);
    
    if (status == DMA_OK) {
        /* Transfer completed successfully */
    } else {
        /* Handle error */
    }
}

/* Example 2: Manual control */
void example_dma_manual(void)
{
    dma_config_t config;
    
    /* Initialize DMA */
    dma_init();
    
    /* Configure transfer */
    config.src_addr = 0x80000000;
    config.dst_addr = 0x80001000;
    config.count = 1024;
    
    if (dma_config(&config) == DMA_OK) {
        /* Start transfer */
        dma_start();
        
        /* Do other work while DMA is running... */
        
        /* Check if done */
        if (dma_is_done()) {
            if (!dma_has_error()) {
                /* Success */
                dma_clear_done();
            } else {
                /* Error occurred */
                dma_clear_error();
            }
        }
    }
}

/* Example 3: Using interrupt (requires interrupt handler) */
volatile int dma_done_flag = 0;

void dma_irq_handler(void)
{
    if (dma_is_done()) {
        dma_done_flag = 1;
        dma_clear_done();
    }
}

void example_dma_interrupt(void)
{
    dma_config_t config;
    
    /* Initialize DMA */
    dma_init();
    
    /* Enable DMA interrupt in PLIC (platform-specific) */
    /* plic_enable_interrupt(DMA_IRQ_NUM); */
    
    /* Configure and start transfer */
    config.src_addr = 0x80000000;
    config.dst_addr = 0x80001000;
    config.count = 1024;
    
    if (dma_config(&config) == DMA_OK) {
        dma_start();
        
        /* Wait for interrupt */
        while (!dma_done_flag) {
            /* Sleep or do other work */
        }
        
        dma_done_flag = 0;
    }
}
#endif

#ifdef __cplusplus
}
#endif

#endif /* __E203_DMA_H__ */
