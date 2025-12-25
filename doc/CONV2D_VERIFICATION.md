# 2D 卷积与 DMA 仿真验证指南

## 快速开始

本示例提供了完整的 2D 卷积运算与 DMA 数据传输的仿真验证。

## 前置要求

### 安装 Icarus Verilog

#### Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install iverilog gtkwave
```

#### CentOS/RHEL:
```bash
sudo yum install iverilog gtkwave
```

#### macOS:
```bash
brew install icarus-verilog gtkwave
```

## 运行仿真

### 方式 1: 使用自动化脚本（推荐）

```bash
cd /home/runner/work/e203_hbirdv2/e203_hbirdv2
chmod +x run_conv2d_sim.sh
./run_conv2d_sim.sh
```

脚本会自动完成：
1. 创建工作目录 `sim_conv2d/`
2. 编译所有必要的 Verilog 文件
3. 运行仿真
4. 显示测试结果

### 方式 2: 手动执行命令

```bash
# 1. 创建工作目录
mkdir -p sim_conv2d
cd sim_conv2d

# 2. 编译设计
iverilog -g2005-sv \
    -o conv2d_dma_sim.out \
    -I ../rtl/e203/core \
    -I ../rtl/e203/perips \
    ../tb/tb_conv2d_dma.v \
    ../rtl/e203/perips/e203_dma_ctrl.v

# 3. 运行仿真
vvp conv2d_dma_sim.out

# 4. 查看波形（可选）
gtkwave tb_conv2d_dma.vcd
```

## 仿真输出解读

### 成功的仿真输出示例

```
=======================================================
2D Convolution with DMA Test
=======================================================
Feature map: 16x16x3
Kernel: 3x3x3
Output: 14x14x3
=======================================================

Initializing feature maps...
Initializing kernels...

--- Starting Convolution with DMA ---

Processing Channel 0...
  CPU computing convolution...
  CPU computation done.
  DMA transferring results...
[time] DMA Transfer: src=0x80001000, dst=0x80002000, count=196 words
[time] DMA Transfer completed. Status: 0x00000002

Processing Channel 1...
  CPU computing convolution...
  CPU computation done.
  DMA transferring results...
[time] DMA Transfer: src=0x80001000, dst=0x80002310, count=196 words
[time] DMA Transfer completed. Status: 0x00000002

Processing Channel 2...
  CPU computing convolution...
  CPU computation done.
  DMA transferring results...
[time] DMA Transfer: src=0x80001000, dst=0x80002620, count=196 words
[time] DMA Transfer completed. Status: 0x00000002

=======================================================
Convolution with DMA Test Complete!
=======================================================
PASS: All data transferred correctly!

Sample Output (Channel 0, first 5x5):
  00000168 000001a4 000001e0 0000021c 00000258 
  000001a4 000001e0 0000021c 00000258 00000294 
  000001e0 0000021c 00000258 00000294 000002d0 
  0000021c 00000258 00000294 000002d0 0000030c 
  00000258 00000294 000002d0 0000030c 00000348 

=======================================================
```

### 输出说明

1. **通道处理**：
   - 显示每个通道（0、1、2）的处理过程
   - CPU 计算阶段
   - DMA 传输阶段

2. **DMA 传输信息**：
   - `src`: 源地址（临时缓冲区）
   - `dst`: 目标地址（输出缓冲区）
   - `count`: 传输字数（196 = 14×14）

3. **验证结果**：
   - `PASS`: 所有数据传输正确
   - `FAIL`: 检测到错误

4. **样本输出**：
   - 显示第一个通道的 5×5 样本数据
   - 以十六进制格式显示

## 关键时序点

仿真过程中的关键事件：

1. **t=0-100ns**: 系统复位
2. **t=100-200ns**: 初始化随机数据到 SRAM
3. **t=200ns+**: 开始卷积处理
   - 每个通道约需 50-100μs（取决于时钟频率）
   - DMA 传输约需 2-3μs（196 words × 4 cycles/word）

## 波形查看

使用 GTKWave 查看详细时序：

```bash
gtkwave sim_conv2d/tb_conv2d_dma.vcd
```

### 推荐查看的信号

**顶层信号**：
- `clk` - 系统时钟
- `rst_n` - 复位信号

**DMA 配置接口**：
- `cfg_icb_cmd_valid/ready` - 配置命令握手
- `cfg_icb_cmd_addr` - 寄存器地址
- `cfg_icb_cmd_wdata` - 写入数据

**DMA 内存接口**：
- `mem_icb_cmd_valid/ready` - 内存访问握手
- `mem_icb_cmd_addr` - 内存地址
- `mem_icb_cmd_read` - 读/写指示
- `mem_icb_cmd_wdata` - 写入数据
- `mem_icb_rsp_rdata` - 读取数据

**DMA 内部状态**：
- `u_dma_ctrl.state` - DMA 状态机
- `u_dma_ctrl.current_cnt` - 当前传输计数

## 仿真验证点

测试平台自动验证以下功能：

✅ **DMA 寄存器配置**
- 写入源地址、目标地址、计数
- 启动传输命令

✅ **DMA 数据传输**
- 从临时缓冲区读取数据
- 写入到输出缓冲区
- 传输计数正确递增

✅ **数据完整性**
- 传输的数据与原始数据完全一致
- 所有 196×3 = 588 个字正确传输

✅ **传输完成**
- DONE 标志正确置位
- 中断信号正确产生

✅ **多次传输**
- 连续 3 个通道的传输都正确
- 每次传输后正确清除状态

## 性能统计

仿真会自动统计：

- **总传输数据量**: 588 words = 2352 bytes
- **传输次数**: 3 次（每通道一次）
- **每次传输量**: 196 words = 784 bytes
- **理论传输周期**: 196 words × 4 cycles/word = 784 cycles per channel
- **总周期数**: 784 × 3 = 2352 cycles

## 故障排查

### 问题 1: 编译失败

**错误**: `e203_defines.v: No such file`

**解决**:
```bash
# 确保使用正确的 -I 选项
iverilog -I ../rtl/e203/core ...
```

### 问题 2: 仿真卡住

**现象**: 仿真运行后没有输出

**可能原因**:
1. DMA 未正确配置
2. 内存响应信号不正确
3. 死锁

**调试方法**:
```bash
# 查看波形文件，检查信号变化
gtkwave tb_conv2d_dma.vcd
```

### 问题 3: 数据不匹配

**错误**: `ERROR: Mismatch at channel X, index Y`

**可能原因**:
1. DMA 传输地址错误
2. 卷积计算错误
3. 内存读写冲突

**调试**:
- 检查 `sram` 数组内容
- 验证地址计算
- 查看 DMA 传输日志

## 文件清单

```
e203_hbirdv2/
├── doc/
│   ├── conv2d_dma_example.c      # C 语言参考实现
│   ├── CONV2D_DMA_README.md       # 详细说明文档
│   └── CONV2D_VERIFICATION.md     # 本文件
├── tb/
│   └── tb_conv2d_dma.v            # Verilog 测试平台
├── rtl/e203/perips/
│   └── e203_dma_ctrl.v            # DMA 控制器
└── run_conv2d_sim.sh              # 自动化仿真脚本
```

## 下一步

完成基本仿真后，可以尝试：

1. **修改参数**：
   - 改变特征图大小
   - 使用不同的卷积核尺寸
   - 调整步长

2. **性能优化**：
   - 实现双缓冲
   - 使用 DMA 突发模式
   - CPU-DMA 流水线

3. **功能扩展**：
   - 添加 ReLU 激活函数
   - 实现最大池化
   - 支持批量处理

## 总结

本仿真完整验证了：
- DMA 控制器的功能正确性
- CPU-DMA 协作机制
- 2D 卷积的正确实现
- 数据传输的完整性

通过运行本仿真，您将深入理解：
- SoC 中 DMA 的工作原理
- CPU 和 DMA 如何协作
- 如何优化数据密集型应用
- Verilog 仿真和验证方法
