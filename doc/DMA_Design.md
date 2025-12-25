# DMA Controller Module Design Document

## 概述 (Overview)

本文档描述了为 E203 RISC-V SoC 设计的 DMA（Direct Memory Access）控制器模块。DMA 控制器允许在不占用 CPU 的情况下进行内存到内存的数据传输，提高系统性能。

This document describes the DMA (Direct Memory Access) controller module designed for the E203 RISC-V SoC. The DMA controller enables memory-to-memory data transfers without CPU intervention, improving system performance.

## 模块位置 (Module Location)

- **DMA Controller**: `rtl/e203/perips/e203_dma_ctrl.v`
- **Testbench**: `tb/tb_dma_test.v`

## 功能特性 (Features)

1. **ICB 从接口** - 用于 CPU 配置寄存器
   - ICB Slave Interface - for CPU configuration registers
   
2. **ICB 主接口** - 用于内存访问
   - ICB Master Interface - for memory access
   
3. **内存到内存传输** - 支持 32 位字传输
   - Memory-to-memory transfers - supports 32-bit word transfers
   
4. **中断生成** - 传输完成时产生中断信号
   - Interrupt generation - generates interrupt on transfer completion
   
5. **状态监控** - 提供忙碌、完成和错误标志
   - Status monitoring - provides busy, done, and error flags

## 寄存器映射 (Register Map)

| 地址 (Address) | 寄存器名称 (Register Name) | 描述 (Description) |
|----------------|---------------------------|-------------------|
| 0x00 | 控制/状态寄存器 (CSR) | [0] START: 写 1 启动传输<br>[1] DONE: 读 1 表示完成（写 1 清除）<br>[2] BUSY: 读 1 表示 DMA 忙碌<br>[3] ERROR: 读 1 表示发生错误 |
| 0x04 | 源地址寄存器 (SRC) | 源内存地址（字对齐） |
| 0x08 | 目标地址寄存器 (DST) | 目标内存地址（字对齐） |
| 0x0C | 传输计数寄存器 (CNT) | 传输字数（32位字） |

### 控制/状态寄存器位定义 (CSR Bit Definitions)

```
Bit 0 (START):  写 1 启动 DMA 传输（仅当 BUSY=0 时有效）
                Write 1 to start DMA transfer (only valid when BUSY=0)
                
Bit 1 (DONE):   读 1 表示传输完成，写 1 清除此标志
                Read 1 when transfer complete, write 1 to clear
                
Bit 2 (BUSY):   只读，1 表示 DMA 正在工作
                Read-only, 1 indicates DMA is busy
                
Bit 3 (ERROR):  读 1 表示传输过程中发生错误
                Read 1 if error occurred during transfer
```

## 工作流程 (Operation Flow)

### 1. 配置 DMA (Configure DMA)
```c
// 配置源地址 (Configure source address)
DMA_SRC = 0x80000000;

// 配置目标地址 (Configure destination address)  
DMA_DST = 0x80001000;

// 配置传输计数 (Configure transfer count)
DMA_CNT = 256;  // 传输 256 个字 (Transfer 256 words)
```

### 2. 启动传输 (Start Transfer)
```c
// 启动 DMA (Start DMA)
DMA_CSR = 0x1;  // 设置 START 位 (Set START bit)
```

### 3. 等待完成 (Wait for Completion)
```c
// 轮询状态 (Poll status)
while (!(DMA_CSR & 0x2)) {
    // 等待 DONE 标志 (Wait for DONE flag)
}

// 或者使用中断 (Or use interrupt)
// 当 dma_irq 信号拉高时，传输完成
// When dma_irq signal is asserted, transfer is complete
```

### 4. 清除完成标志 (Clear Done Flag)
```c
// 清除 DONE 和 ERROR 标志 (Clear DONE and ERROR flags)
DMA_CSR = 0x2;  // 写 1 到 DONE 位 (Write 1 to DONE bit)
```

## 状态机 (State Machine)

DMA 控制器使用以下状态机实现数据传输：

1. **IDLE** - 空闲状态，等待启动信号
   - Idle state, waiting for start signal
   
2. **READ** - 从源地址读取数据
   - Reading data from source address
   
3. **READ_RSP** - 等待读响应
   - Waiting for read response
   
4. **WRITE** - 向目标地址写入数据
   - Writing data to destination address
   
5. **WRITE_RSP** - 等待写响应
   - Waiting for write response
   
6. **DONE** - 传输完成
   - Transfer complete

状态转换图：
```
IDLE -> READ -> READ_RSP -> WRITE -> WRITE_RSP -> 
         ^                                  |
         |                                  v
         +-----------(continue)------- (check count)
                                           |
                                           v
                                        DONE -> IDLE
```

## 接口信号 (Interface Signals)

### ICB 从接口 (ICB Slave Interface)
- **cfg_icb_cmd_valid/ready**: 命令握手信号
- **cfg_icb_cmd_addr**: 寄存器地址
- **cfg_icb_cmd_read**: 读/写指示
- **cfg_icb_cmd_wdata**: 写数据
- **cfg_icb_rsp_valid/ready**: 响应握手信号
- **cfg_icb_rsp_rdata**: 读数据

### ICB 主接口 (ICB Master Interface)
- **mem_icb_cmd_valid/ready**: 内存命令握手
- **mem_icb_cmd_addr**: 内存地址
- **mem_icb_cmd_read**: 读/写指示
- **mem_icb_cmd_wdata**: 写数据
- **mem_icb_rsp_valid/ready**: 内存响应握手
- **mem_icb_rsp_rdata**: 读数据

### 中断信号 (Interrupt Signal)
- **dma_irq**: 传输完成中断（脉冲）

## 集成到 E203 SoC

要将 DMA 控制器集成到 E203 SoC，需要以下步骤：

### 1. 在 subsys_main.v 中添加 DMA 实例

```verilog
// DMA ICB signals
wire                         dma_icb_cmd_valid;
wire                         dma_icb_cmd_ready;
wire [`E203_ADDR_SIZE-1:0]   dma_icb_cmd_addr;
wire                         dma_icb_cmd_read;
wire [`E203_XLEN-1:0]        dma_icb_cmd_wdata;
wire [`E203_XLEN/8-1:0]      dma_icb_cmd_wmask;

wire                         dma_icb_rsp_valid;
wire                         dma_icb_rsp_ready;
wire                         dma_icb_rsp_err;
wire [`E203_XLEN-1:0]        dma_icb_rsp_rdata;

// DMA interrupt
wire                         dma_irq;

// DMA Controller instance
e203_dma_ctrl u_e203_dma_ctrl (
  .cfg_icb_cmd_valid   (dma_icb_cmd_valid),
  .cfg_icb_cmd_ready   (dma_icb_cmd_ready),
  .cfg_icb_cmd_addr    (dma_icb_cmd_addr),
  .cfg_icb_cmd_read    (dma_icb_cmd_read),
  .cfg_icb_cmd_wdata   (dma_icb_cmd_wdata),
  .cfg_icb_cmd_wmask   (dma_icb_cmd_wmask),
  
  .cfg_icb_rsp_valid   (dma_icb_rsp_valid),
  .cfg_icb_rsp_ready   (dma_icb_rsp_ready),
  .cfg_icb_rsp_err     (dma_icb_rsp_err),
  .cfg_icb_rsp_rdata   (dma_icb_rsp_rdata),
  
  .mem_icb_cmd_valid   (/* connect to memory bus */),
  .mem_icb_cmd_ready   (/* connect to memory bus */),
  // ... more memory interface connections
  
  .dma_irq             (dma_irq),
  .clk                 (bus_clk),
  .rst_n               (bus_rst_n)
);
```

### 2. 添加地址解码

在总线分配器中为 DMA 添加地址范围：
```verilog
// 例如分配地址 0x10002000 - 0x10002FFF 给 DMA
localparam DMA_BASE_ADDR = 32'h1000_2000;
```

### 3. 连接到 PLIC（可选）

将 `dma_irq` 连接到 PLIC（Platform-Level Interrupt Controller）以支持中断驱动的操作。

## 测试验证 (Testing and Verification)

### 单独测试 (Standalone Test)

使用提供的测试平台 `tb_dma_test.v` 可以独立验证 DMA 功能：

```bash
# 编译测试
iverilog -g2005-sv -o dma_test.out \
  -I rtl/e203/core \
  tb/tb_dma_test.v \
  rtl/e203/perips/e203_dma_ctrl.v

# 运行测试
vvp dma_test.out

# 查看波形
gtkwave tb_dma_test.vcd
```

测试平台验证以下功能：
1. 寄存器读写
2. 16 个字的内存到内存传输
3. 传输完成状态检测
4. 数据完整性验证

### 集成测试 (Integration Test)

集成到完整 SoC 后，可以编写 C 程序测试：

```c
#include <stdint.h>

#define DMA_BASE 0x10002000
#define DMA_CSR  (*(volatile uint32_t*)(DMA_BASE + 0x00))
#define DMA_SRC  (*(volatile uint32_t*)(DMA_BASE + 0x04))
#define DMA_DST  (*(volatile uint32_t*)(DMA_BASE + 0x08))
#define DMA_CNT  (*(volatile uint32_t*)(DMA_BASE + 0x0C))

void dma_transfer(uint32_t src, uint32_t dst, uint32_t count) {
    DMA_SRC = src;
    DMA_DST = dst;
    DMA_CNT = count;
    DMA_CSR = 0x1;  // Start
    
    // Wait for completion
    while (!(DMA_CSR & 0x2));
    
    // Clear done flag
    DMA_CSR = 0x2;
}
```

## 性能考虑 (Performance Considerations)

1. **传输速度**: 每个字传输需要 2 个总线事务（1 读 + 1 写）
   - Transfer speed: Each word transfer requires 2 bus transactions (1 read + 1 write)

2. **总线占用**: DMA 传输期间会占用总线，可能影响 CPU 性能
   - Bus utilization: DMA transfers occupy the bus, may impact CPU performance

3. **优化建议**: 
   - 对于小数据量（< 16 字），CPU 直接拷贝可能更快
   - 对于大数据量，使用 DMA 可以释放 CPU 处理其他任务
   - Optimization suggestions:
     - For small data (< 16 words), direct CPU copy may be faster
     - For large data, using DMA frees CPU for other tasks

## 未来改进 (Future Improvements)

1. 支持突发传输以提高带宽效率
   - Support burst transfers for better bandwidth efficiency

2. 添加多通道 DMA 支持
   - Add multi-channel DMA support

3. 支持 2D DMA 传输（行/列传输）
   - Support 2D DMA transfers (row/column transfers)

4. 添加 scatter-gather 功能
   - Add scatter-gather capability

5. 支持外设到内存、内存到外设传输
   - Support peripheral-to-memory and memory-to-peripheral transfers

## 参考资料 (References)

1. E203 SoC Architecture Documentation
2. ICB Bus Protocol Specification
3. RISC-V Platform Specification
