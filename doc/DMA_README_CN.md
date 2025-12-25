# E203 DMA 模块使用指南

## 概述

本项目为 E203 HBird RISC-V SoC 添加了一个 DMA（Direct Memory Access，直接内存访问）控制器模块。DMA 允许在不占用 CPU 的情况下进行内存到内存的数据传输，可以显著提高系统性能，特别是在处理大量数据传输时。

## 已完成的工作

### 1. DMA 控制器模块 (`rtl/e203/perips/e203_dma_ctrl.v`)

这是核心 DMA 控制器 Verilog 模块，具有以下特性：

- **ICB 从接口**: 用于 CPU 配置 DMA 寄存器
- **ICB 主接口**: 用于执行内存访问操作
- **4 个配置寄存器**:
  - `0x00`: 控制/状态寄存器 (CSR)
  - `0x04`: 源地址寄存器
  - `0x08`: 目标地址寄存器
  - `0x0C`: 传输字数计数寄存器
- **状态机**: 实现读-写循环的 DMA 传输
- **中断支持**: 传输完成时产生中断信号

### 2. 测试平台 (`tb/tb_dma_test.v`)

独立的 Verilog 测试平台，用于验证 DMA 功能：

- 简单的内存模型
- 测试 16 个字的内存到内存传输
- 验证数据完整性
- 可以独立运行，不需要完整的 SoC 环境

### 3. 设计文档 (`doc/DMA_Design.md`)

详细的设计文档，包含：

- 模块功能说明（中英文对照）
- 寄存器映射和位定义
- 工作流程和使用示例
- 状态机描述
- 集成步骤说明
- 性能考虑和未来改进建议

### 4. 集成示例 (`doc/dma_integration_example.v`)

展示如何将 DMA 模块集成到 E203 子系统：

- 完整的信号声明
- DMA 实例化示例
- 总线连接方法
- 地址映射建议

### 5. C 驱动头文件 (`doc/e203_dma.h`)

软件开发所需的 C 头文件：

- 寄存器地址定义
- 状态码定义
- API 函数接口
- 使用示例代码

## 如何运行 DMA 测试

### 方法 1: 使用 Icarus Verilog（如果已安装）

```bash
# 编译测试平台
iverilog -g2005-sv -o dma_test.out \
  -I rtl/e203/core \
  tb/tb_dma_test.v \
  rtl/e203/perips/e203_dma_ctrl.v

# 运行仿真
vvp dma_test.out

# 查看波形（如果已安装 GTKWave）
gtkwave tb_dma_test.vcd
```

### 方法 2: 使用其他仿真器

测试平台是标准的 Verilog 代码，应该可以在任何 Verilog 仿真器上运行：

- **Synopsys VCS**: 使用项目现有的仿真流程
- **Mentor ModelSim/Questa**: 标准 Verilog 编译和仿真
- **Cadence Xcelium**: 标准流程

## 如何集成 DMA 到完整 SoC

DMA 模块已经准备好集成，但为了保持对现有代码的最小修改，我们提供了集成指南而不是直接修改核心文件。

### 集成步骤：

1. **修改 `rtl/e203/subsys/e203_subsys_main.v`**:
   - 添加 DMA 信号声明（参考 `doc/dma_integration_example.v`）
   - 实例化 `e203_dma_ctrl` 模块
   - 添加 `dma_irq` 输出端口

2. **修改外设总线**:
   - 在 `e203_subsys_perips.v` 中添加 DMA 作为从设备
   - 分配地址范围：`0x10002000 - 0x10002FFF`
   - 连接 DMA 配置接口

3. **修改内存总线**（可选，如果需要更好的性能）:
   - 添加总线仲裁器，允许 CPU 和 DMA 共享内存访问
   - 设置 CPU 优先级高于 DMA

4. **连接到 PLIC**（可选，用于中断支持）:
   - 将 `dma_irq` 连接到 PLIC 的中断源
   - 分配中断号（例如 IRQ #16）

详细的集成代码示例请参考 `doc/dma_integration_example.v`。

## 软件使用示例

### 基本使用

```c
#include "e203_dma.h"

void copy_data(void)
{
    uint32_t src_buffer[256];
    uint32_t dst_buffer[256];
    
    // 初始化 DMA
    dma_init();
    
    // 执行传输（256 个字）
    dma_status_t status = dma_transfer(
        (uint32_t)src_buffer,
        (uint32_t)dst_buffer,
        256,
        10000  // 超时
    );
    
    if (status == DMA_OK) {
        // 传输成功
    }
}
```

### 使用中断

```c
volatile int dma_done = 0;

void dma_interrupt_handler(void)
{
    if (dma_is_done()) {
        dma_done = 1;
        dma_clear_done();
    }
}

void async_copy(void)
{
    dma_config_t config;
    
    // 配置传输
    config.src_addr = 0x80000000;
    config.dst_addr = 0x80001000;
    config.count = 1024;
    
    // 启动传输
    dma_config(&config);
    dma_start();
    
    // CPU 可以做其他工作...
    
    // 等待完成
    while (!dma_done);
}
```

## 模块特点

### 优点

1. **简单易用**: 只需配置 4 个寄存器即可开始传输
2. **标准接口**: 使用 E203 的 ICB 总线接口
3. **可扩展**: 易于添加新功能（突发传输、多通道等）
4. **低资源占用**: 简单的状态机，资源消耗小
5. **完整文档**: 提供详细的中英文文档和示例

### 局限性

1. **单通道**: 一次只能执行一个传输
2. **字传输**: 仅支持 32 位字对齐的传输
3. **简单模式**: 不支持突发传输或 scatter-gather
4. **阻塞式**: 传输期间会占用总线

### 适用场景

- 大块内存拷贝（> 64 字节）
- 内存清零/填充
- 数据缓冲区管理
- 图像/音频数据传输

## 性能分析

### 传输速度

- 每个字传输需要：
  - 1 个时钟周期：读请求
  - 1 个时钟周期：读响应
  - 1 个时钟周期：写请求
  - 1 个时钟周期：写响应
- **总计**: ~4 个时钟周期/字

### 与 CPU 拷贝对比

CPU 直接拷贝（假设每个字需要 3 条指令：load + store + loop）:
- 每个字需要约 3-6 个时钟周期（取决于流水线效率）

**结论**: 
- 小数据量 (< 16 字): CPU 拷贝可能更快（无需配置开销）
- 大数据量 (> 64 字): DMA 传输更有优势（CPU 可以做其他工作）

## 测试结果

运行 `tb_dma_test.v` 应该产生以下输出：

```
==============================================
DMA Test Starting...
==============================================
[xxx] Writing DMA source address: 0x00000000
[xxx] Writing DMA destination address: 0x00000100
[xxx] Writing DMA transfer count: 16 words
[xxx] Starting DMA transfer...
[xxx] DMA transfer completed! Status: 0x00000002

==============================================
Verifying transferred data...
==============================================
PASS: Index 0: 0xA0000000
PASS: Index 1: 0xA0000001
...
PASS: Index 15: 0xA000000F

==============================================
DMA Test Complete!
==============================================
```

## 未来改进方向

1. **突发传输**: 支持 AHB 突发传输以提高带宽效率
2. **多通道**: 支持多个独立的 DMA 通道
3. **链式传输**: 支持描述符链表，实现连续多段传输
4. **2D 传输**: 支持二维数据传输（如图像行）
5. **外设支持**: 支持外设到内存、内存到外设的传输

## 问题排查

### 问题 1: DMA 一直忙碌

**原因**: 可能是状态机卡在某个状态
**解决**: 检查总线响应信号，确保内存正确响应

### 问题 2: 数据传输错误

**原因**: 地址未对齐或传输计数错误
**解决**: 确保源和目标地址都是 4 字节对齐

### 问题 3: 中断不工作

**原因**: 中断信号未连接或 PLIC 未配置
**解决**: 检查中断连接和 PLIC 配置

## 参考资料

1. `doc/DMA_Design.md` - 详细设计文档
2. `doc/dma_integration_example.v` - 集成示例
3. `doc/e203_dma.h` - C 驱动头文件
4. `rtl/e203/perips/e203_dma_ctrl.v` - DMA 控制器源码
5. `tb/tb_dma_test.v` - 测试平台

## 许可证

遵循 E203 HBird 项目的 Apache 2.0 许可证。

## 贡献者

- DMA 模块设计和实现
- 文档编写
- 测试平台开发

如有问题或建议，欢迎提出 Issue 或 Pull Request！
