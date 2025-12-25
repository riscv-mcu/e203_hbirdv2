# 2D 卷积 DMA 示例 - 快速参考

## 文件位置

```
e203_hbirdv2/
├── doc/
│   ├── conv2d_dma_example.c       # C 语言实现（参考）
│   ├── CONV2D_DMA_README.md        # 详细说明文档
│   └── CONV2D_VERIFICATION.md      # 验证和运行指南
├── tb/
│   └── tb_conv2d_dma.v             # Verilog 仿真测试平台
├── rtl/e203/perips/
│   └── e203_dma_ctrl.v             # DMA 控制器模块
└── run_conv2d_sim.sh               # 一键运行脚本
```

## 快速开始

### 1. 安装工具（如果还没有）

```bash
# Ubuntu/Debian
sudo apt-get install iverilog gtkwave
```

### 2. 运行仿真

```bash
cd /home/runner/work/e203_hbirdv2/e203_hbirdv2
chmod +x run_conv2d_sim.sh
./run_conv2d_sim.sh
```

或手动运行：

```bash
mkdir -p sim_conv2d && cd sim_conv2d

# 编译
iverilog -g2005-sv -o conv2d_sim.out \
  -I ../rtl/e203/core \
  -I ../rtl/e203/perips \
  ../tb/tb_conv2d_dma.v \
  ../rtl/e203/perips/e203_dma_ctrl.v

# 运行
vvp conv2d_sim.out

# 查看波形
gtkwave tb_conv2d_dma.vcd
```

## 实验内容

### 数据规格
- **输入特征图**: 16×16×3
- **卷积核**: 3×3×3  
- **输出**: 14×14×3
- **步长**: 1
- **填充**: 无 (Valid 卷积)

### 工作流程

```
对于每个通道 (共3个):
  1. CPU 计算卷积 → 临时缓冲区 (0x80001000)
     • 14×14 = 196 个输出值
     • 每个值是 3×3=9 个乘加运算的结果
  
  2. DMA 传输数据 → 输出区域 (0x80002000 + offset)
     • 配置 SRC = 0x80001000
     • 配置 DST = 0x80002000 + channel*196*4
     • 配置 CNT = 196 words
     • 启动传输并等待完成
```

### 内存映射

```
地址              | 内容           | 大小
------------------|----------------|--------
0x80000000        | 特征图数据     | 3KB
0x80000C00        | 卷积核数据     | 108B
0x80001000        | 临时缓冲区     | 784B
0x80002000        | 输出结果       | 2.3KB
0x10002000        | DMA 寄存器     | 16B
```

## 预期结果

```
=======================================================
2D Convolution with DMA Test
=======================================================
Feature map: 16x16x3
Kernel: 3x3x3
Output: 14x14x3
=======================================================

Processing Channel 0...
  CPU computing convolution...
  CPU computation done.
  DMA transferring results...
[xxx] DMA Transfer completed. Status: 0x00000002

Processing Channel 1...
  [similar output]

Processing Channel 2...
  [similar output]

=======================================================
PASS: All data transferred correctly!
=======================================================
```

## 关键代码片段

### C 语言版（doc/conv2d_dma_example.c）

```c
// 单通道卷积计算
void conv2d_single_channel(
    const int32_t *feature,  // 16×16
    const int32_t *kernel,   // 3×3
    int32_t *output          // 14×14
) {
    for (int out_row = 0; out_row < 14; out_row++) {
        for (int out_col = 0; out_col < 14; out_col++) {
            int32_t sum = 0;
            for (int kr = 0; kr < 3; kr++) {
                for (int kc = 0; kc < 3; kc++) {
                    sum += feature[(out_row+kr)*16 + (out_col+kc)] 
                         * kernel[kr*3 + kc];
                }
            }
            output[out_row*14 + out_col] = sum;
        }
    }
}

// CPU-DMA 协作
for (int ch = 0; ch < 3; ch++) {
    // CPU: 计算
    conv2d_single_channel(..., temp_buffer);
    
    // DMA: 传输
    dma_transfer(temp_buffer, output + ch*196, 196);
}
```

### Verilog 版（tb/tb_conv2d_dma.v）

测试平台自动：
1. 初始化随机数据到 SRAM
2. 用 Verilog function 模拟 CPU 卷积计算
3. 调用 DMA 执行数据传输
4. 验证传输的数据完整性

## 性能分析

### DMA 传输性能
- 每个字传输: ~4 个时钟周期
- 每个通道: 196 words × 4 = 784 cycles
- 总共 3 个通道: 2352 cycles
- 假设 100MHz: 约 23.5μs

### 对比纯 CPU 方式
- CPU 逐个写入: 每个字 3-6 cycles (load + store + overhead)
- DMA 批量传输: 每个字 4 cycles (但 CPU 不参与)
- **关键优势**: CPU 可以继续计算下一个通道

## 验证点

测试平台自动验证：

✅ DMA 寄存器配置正确
✅ 数据传输完整无误（588 words）
✅ DONE 标志正确设置
✅ 多次传输均成功
✅ 内存数据一致性

## 波形查看要点

使用 GTKWave 查看 `tb_conv2d_dma.vcd`：

**重要信号**:
- `u_dma_ctrl.state` - DMA 状态机
- `mem_icb_cmd_addr` - 内存访问地址
- `mem_icb_cmd_read` - 读/写指示
- `u_dma_ctrl.current_cnt` - 传输计数

**查看 DMA 传输过程**:
1. 找到 `cfg_icb_cmd_valid` 上升沿（配置阶段）
2. 观察 `state` 变化：IDLE → READ → WRITE → ...
3. 查看 `mem_icb_cmd_addr` 地址递增
4. 确认传输完成时 `state` 回到 IDLE

## 实验目标

本示例成功展示：

✅ **熟悉 SoC 工作模式**
- 理解内存系统
- 掌握总线访问机制
- 了解 CPU-DMA 协作

✅ **使用 DMA 控制器**
- 配置寄存器
- 启动和监控传输
- 处理完成事件

✅ **优化设计策略**
- CPU 专注计算
- DMA 处理数据搬运
- 流水线式协作

✅ **实际应用场景**
- 神经网络卷积
- 大规模数据处理
- 性能优化技巧

## 故障排查

### 问题：iverilog 未安装
```bash
sudo apt-get install iverilog
```

### 问题：编译错误
检查路径和 include 目录设置

### 问题：仿真卡住
查看波形，检查 DMA 配置和内存响应

### 问题：数据不匹配
验证卷积计算和 DMA 地址配置

## 更多信息

详细文档请查看：
- `doc/CONV2D_DMA_README.md` - 完整说明
- `doc/CONV2D_VERIFICATION.md` - 验证指南
- `doc/DMA_Design.md` - DMA 设计文档

---

**提示**: 如果没有 iverilog，文档中包含完整的 C 实现代码和详细的算法说明，可以用于理解工作原理。
