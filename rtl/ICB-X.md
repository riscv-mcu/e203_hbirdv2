# E203 ICB-X 总线增强改造完整报告

## 目录

1. [项目概述](#1-项目概述)
2. [ICB-X 协议定义](#2-icb-x-协议定义)
3. [Phase 1 — 配置宏与全局定义](#3-phase-1--配置宏与全局定义)
4. [Phase 2 — 通用 ICB 基础设施模块升级](#4-phase-2--通用-icb-基础设施模块升级)
5. [Phase 3 — BIU 总线接口单元升级](#5-phase-3--biu-总线接口单元升级)
6. [Phase 4 — ICB2AXI 桥接模块升级](#6-phase-4--icb2axi-桥接模块升级)
7. [Phase 5 — LSU/IFU 接口与核心层级布线](#7-phase-5--lsuifu-接口与核心层级布线)
8. [Phase 6 — SoC 顶层层级与外设端点布线](#8-phase-6--soc-顶层层级与外设端点布线)
9. [完整信号通路总图](#9-完整信号通路总图)
10. [设计决策与注意事项](#10-设计决策与注意事项)

---

## 1. 项目概述

### 1.1 改造目标

原始蜂鸟 E203 RISC-V 处理器采用 **ICB（Internal Chip Bus）** 总线协议，这是一种轻量级的 valid/ready 握手协议，仅支持**单拍（single-beat）事务**。为满足以下需求：

- **L1 Cache 支持**：Cache line fill/writeback 需要多拍突发（burst）传输
- **AI 加速器集成**：需要事务 ID 标记以支持乱序返回和多 outstanding 事务
- **AXI4 桥接兼容**：突发类型编码需与 AXI4 一致以简化桥接逻辑

本次改造在原始 ICB 基础上扩展为 **ICB-X（ICB eXtended）** 协议。

### 1.2 设计原则

1. **条件编译**：所有 ICB-X 新增信号均包裹在 `` `ifdef E203_HAS_ICBX `` 条件编译块中，不定义该宏时 RTL 完全退化为原始 ICB，**零面积开销**
2. **向后兼容**：默认值 `id=0, len=0, last=1` 等效于原始单拍行为
3. **层级穿透**：ICB-X 信号从最底层（IFU/LSU）到最顶层（SoC 边界）完整传播，为未来扩展预留接口

### 1.3 修改文件总览

| 阶段 | 修改文件 | 涉及内容 |
|:---:|:---|:---|
| Phase 1 | `config.v`, `e203_defines.v` | 配置参数与全局宏定义 |
| Phase 2 | `sirv_gnrl_icbs.v`（arbt/buffer/n2w/splt） | 4 个通用 ICB 基础设施模块 |
| Phase 3 | `e203_biu.v` | 总线接口单元 |
| Phase 4 | `sirv_gnrl_icbs.v`（icb2axi） | ICB-to-AXI 桥接模块 |
| Phase 5 | `e203_lsu_ctrl.v`, `e203_ifu_ift2icb.v`, `e203_lsu.v`, `e203_ifu.v`, `e203_core.v`, `e203_cpu.v` | LSU/IFU 信号源 + 核心层级 |
| Phase 6 | `e203_cpu_top.v`, `e203_subsys_main.v`, `e203_subsys_perips.v`, `e203_subsys_clint.v`, `e203_subsys_plic.v`, `e203_subsys_mems.v`, `e203_subsys_top.v`, `e203_soc_top.v` | SoC 顶层层级 + 外设端点 |

---

## 2. ICB-X 协议定义

### 2.1 新增信号一览

**CMD 通道（命令方向）新增信号：**

| 信号名 | 位宽 | 方向 | 描述 |
|:---|:---:|:---:|:---|
| `cmd_id` | 2 bit | Master → Slave | 事务 ID，标识不同的 outstanding 事务，支持乱序返回 |
| `cmd_len` | 8 bit | Master → Slave | 突发长度，表示一次突发事务中的拍数（0 = 单拍，N = N+1 拍），与 AXI4 的 `ARLEN`/`AWLEN` 编码一致 |
| `cmd_burst` | 2 bit | Master → Slave | 突发类型编码：`2'b00`=FIXED, `2'b01`=INCR, `2'b10`=WRAP |
| `cmd_last` | 1 bit | Master → Slave | 突发事务的最后一拍标志，单拍事务时恒为 1 |

**RSP 通道（响应方向）新增信号：**

| 信号名 | 位宽 | 方向 | 描述 |
|:---|:---:|:---:|:---|
| `rsp_id` | 2 bit | Slave → Master | 响应的事务 ID，与对应 CMD 的 `cmd_id` 匹配 |
| `rsp_last` | 1 bit | Slave → Master | 响应突发的最后一拍标志，单拍响应时恒为 1 |

### 2.2 突发类型编码

| 编码 | 名称 | 典型用途 |
|:---:|:---|:---|
| `2'b00` | FIXED | 固定地址突发：FIFO 访问、状态轮询 |
| `2'b01` | INCR | 递增地址突发：Cache line fill/writeback |
| `2'b10` | WRAP | 回绕地址突发：Critical-word-first 取指 |

### 2.3 信号打包格式

ICB-X 在通用模块内部使用扩展总线进行信号打包：

```
CMD 扩展总线 [E203_ICBX_CMD_EXT_W-1:0] = {cmd_last, cmd_burst[1:0], cmd_len[7:0], cmd_id[1:0]}
                                          // 共 1+2+8+2 = 13 bit

RSP 扩展总线 [E203_ICBX_RSP_EXT_W-1:0] = {rsp_last, rsp_id[1:0]}
                                          // 共 1+2 = 3 bit
```

---

## 3. Phase 1 — 配置宏与全局定义

### 3.1 文件：`config.v`

**修改位置**：文件末尾（DTCM 配置之后）

**新增内容**：

```verilog
`define E203_CFG_HAS_ICBX            // ICB-X 总开关
`define E203_CFG_ICBX_ID_WIDTH   2   // 事务 ID 位宽
`define E203_CFG_ICBX_LEN_WIDTH  8   // 突发长度位宽
`define E203_CFG_ICBX_OUTS_NUM   4   // 最大 outstanding 事务数
```

**目的**：在用户可配置的顶层文件中提供 ICB-X 的总开关和参数，用户可通过注释/取消注释 `E203_CFG_HAS_ICBX` 来启用/禁用整个 ICB-X 特性。

### 3.2 文件：`e203_defines.v`

**修改位置**：文件末尾（BIU 相关宏定义之后），在 `ifdef E203_CFG_HAS_ICBX` 条件块内。

**新增内容（启用 ICB-X 时）**：

| 宏名 | 值 | 用途 |
|:---|:---|:---|
| `E203_HAS_ICBX` | （定义） | 下游 RTL 统一使用此宏判断 ICB-X 是否启用 |
| `E203_ICBX_ID_W` | 2 | 事务 ID 位宽，派生自 `E203_CFG_ICBX_ID_WIDTH` |
| `E203_ICBX_LEN_W` | 8 | 突发长度位宽，派生自 `E203_CFG_ICBX_LEN_WIDTH` |
| `E203_ICBX_BURST_W` | 2 | 突发类型位宽（固定 2 bit） |
| `E203_ICBX_BURST_FIXED` | `2'b00` | 固定地址突发编码 |
| `E203_ICBX_BURST_INCR` | `2'b01` | 递增地址突发编码 |
| `E203_ICBX_BURST_WRAP` | `2'b10` | 回绕地址突发编码 |
| `E203_ICBX_OUTS_NUM` | 4 | 最大 outstanding 数 |
| `E203_ICBX_OUTS_CNT_W` | 3 | outstanding 计数器位宽 = clog2(4+1) |
| `E203_ICBX_CMD_EXT_W` | 13 | CMD 扩展字段总宽 = 2+8+2+1 |
| `E203_ICBX_CMD_ID_LSB/MSB` | 0/1 | CMD 扩展总线中 ID 字段位域 |
| `E203_ICBX_CMD_LEN_LSB/MSB` | 2/9 | CMD 扩展总线中 LEN 字段位域 |
| `E203_ICBX_CMD_BURST_LSB/MSB` | 10/11 | CMD 扩展总线中 BURST 字段位域 |
| `E203_ICBX_CMD_LAST_LSB/MSB` | 12/12 | CMD 扩展总线中 LAST 字段位域 |
| `E203_ICBX_RSP_EXT_W` | 3 | RSP 扩展字段总宽 = 2+1 |
| `E203_ICBX_RSP_ID_LSB/MSB` | 0/1 | RSP 扩展总线中 ID 字段位域 |
| `E203_ICBX_RSP_LAST_LSB/MSB` | 2/2 | RSP 扩展总线中 LAST 字段位域 |

**BIU 参数覆盖**：当 ICB-X 启用时，BIU 的 outstanding 参数被覆盖：

```verilog
`undef  E203_BIU_OUTS_NUM
`define E203_BIU_OUTS_NUM     `E203_ICBX_OUTS_NUM     // 4（原为 1）
`undef  E203_BIU_OUTS_NUM_IS_1                         // 取消"仅 1 outstanding"标志
`undef  E203_BIU_OUTS_CNT_W
`define E203_BIU_OUTS_CNT_W   `E203_ICBX_OUTS_CNT_W   // 3（原为 1）
`undef  E203_BIU_CMD_DP
`define E203_BIU_CMD_DP  2                              // CMD 流水深度 = 2（ping-pong）
`undef  E203_BIU_RSP_DP_RAW
`define E203_BIU_RSP_DP_RAW  2                          // RSP 流水深度 = 2
```

**目的**：提升 BIU 流水线深度以匹配 ICB-X 的多 outstanding 能力。

**新增内容（未启用 ICB-X 时）**：

```verilog
`define E203_ICBX_ID_W       0
`define E203_ICBX_LEN_W      0
`define E203_ICBX_BURST_W    0
`define E203_ICBX_CMD_EXT_W  0
`define E203_ICBX_RSP_EXT_W  0
```

**目的**：提供零宽度占位宏，使下游 RTL 在未启用 ICB-X 时仍可引用这些宏（用于 generate-if 或三元表达式），避免编译错误。

### 3.3 信号通路

Phase 1 不涉及具体信号线，仅建立宏定义基础设施。所有后续阶段的 `ifdef E203_HAS_ICBX` 条件编译均依赖此处定义。

---

## 4. Phase 2 — 通用 ICB 基础设施模块升级

### 修改文件：`sirv_gnrl_icbs.v`

本阶段升级了 4 个位于 `sirv_gnrl_icbs.v` 中的通用 ICB 基础设施模块，它们是整个 SoC 中被广泛复用的总线构建块。

---

### 4.1 模块：`sirv_gnrl_icb_arbt`（ICB 仲裁器）

**功能**：多主单从仲裁，从 N 个输入主设备中选择一个授权访问输出从设备。

**修改内容**：

| 修改项 | 新增信号 | 说明 |
|:---|:---|:---|
| **输入总线端口** | `i_bus_icb_cmd_id [ARBT_NUM*ID_W-1:0]` | N 个主设备的 CMD ID 拼接总线 |
| | `i_bus_icb_cmd_len [ARBT_NUM*LEN_W-1:0]` | N 个主设备的 CMD LEN 拼接总线 |
| | `i_bus_icb_cmd_last [ARBT_NUM*1-1:0]` | N 个主设备的 CMD LAST 拼接总线 |
| | `i_bus_icb_rsp_id [ARBT_NUM*ID_W-1:0]` | N 个主设备的 RSP ID 拼接总线 |
| | `i_bus_icb_rsp_last [ARBT_NUM*1-1:0]` | N 个主设备的 RSP LAST 拼接总线 |
| **输出端口** | `o_icb_cmd_id [ID_W-1:0]` | 仲裁后 CMD ID |
| | `o_icb_cmd_len [LEN_W-1:0]` | 仲裁后 CMD LEN |
| | `o_icb_cmd_last` | 仲裁后 CMD LAST |
| | `o_icb_rsp_id [ID_W-1:0]` | RSP ID（回传给消息源主设备） |
| | `o_icb_rsp_last` | RSP LAST（回传给消息源主设备） |
| **内部逻辑** | `i_icb_cmd_{id,len,last}[0..N-1]` | 内部 wire 数组，分解拼接总线 |
| | `o_icb_cmd_{id,len,last}` 赋值 | 基于仲裁选择 MUX |
| | `i_bus_icb_rsp_{id,last}` 赋值 | 将 RSP 复制到所有主设备总线 |

**信号通路**：

```
主设备 0 ──cmd_id/len/last──┐
主设备 1 ──cmd_id/len/last──┤  ─→ [仲裁 MUX] ─→ o_icb_cmd_id/len/last ─→ 从设备
...                         ┘
从设备 ──rsp_id/last──→ [广播] ─→ i_bus_icb_rsp_id/last ─→ 所有主设备
```

---

### 4.2 模块：`sirv_gnrl_icb_buffer`（ICB 缓冲/流水级）

**功能**：在 ICB 通道中插入 FIFO 缓冲级，用于切断组合逻辑路径和流水线时序优化。

**修改内容**：

| 修改项 | 新增信号 | 说明 |
|:---|:---|:---|
| **输入端口** | `i_icb_cmd_id`, `i_icb_cmd_len`, `i_icb_cmd_last` | CMD 通道 ICB-X 输入 |
| | `i_icb_rsp_id`, `i_icb_rsp_last` | RSP 通道 ICB-X 输出（回传方向） |
| **输出端口** | `o_icb_cmd_id`, `o_icb_cmd_len`, `o_icb_cmd_last` | CMD 通道 ICB-X 输出 |
| | `o_icb_rsp_id`, `o_icb_rsp_last` | RSP 通道 ICB-X 输入（回传方向） |
| **内部打包** | CMD FIFO 数据宽度扩展 | ICB-X 信号与原始 ICB 载荷合并打包进 FIFO |

**信号打包格式**：

```
CMD_PACK = {cmd_last, cmd_len, cmd_id, cmd_usr, ..., cmd_read}
            ↑ ICB-X 新增部分 ↑         ↑ 原始 ICB 部分 ↑
```

ICB-X 信号被追加到 CMD FIFO 的数据字段末尾，与原始信号一起通过 FIFO 传输。RSP 通道为直通（FIFO 仅切断 CMD 方向）。

**信号通路**：

```
上游 ──cmd_{id,len,last}──→ [CMD FIFO 打包] ──→ [FIFO] ──→ [CMD FIFO 解包] ──→ 下游
下游 ──rsp_{id,last}──→ [直通] ──→ 上游
```

---

### 4.3 模块：`sirv_gnrl_icb_n2w`（ICB 窄到宽位宽转换器）

**功能**：将窄位宽 ICB（如 32-bit）转换为宽位宽 ICB（如 64-bit），用于 SysMem 路径。

**修改内容**：

| 修改项 | 新增信号 | 说明 |
|:---|:---|:---|
| **输入端口（窄侧）** | `i_icb_cmd_id`, `i_icb_cmd_len`, `i_icb_cmd_last` | 32-bit 侧 CMD |
| | `i_icb_rsp_id`, `i_icb_rsp_last` | 32-bit 侧 RSP |
| **输出端口（宽侧）** | `o_icb_cmd_id`, `o_icb_cmd_len`, `o_icb_cmd_last` | 64-bit 侧 CMD |
| | `o_icb_rsp_id`, `o_icb_rsp_last` | 64-bit 侧 RSP |

**关键特征**：ICB-X 信号直接穿透（passthrough），不参与位宽转换。位宽转换仅影响 `wdata`/`wmask`/`rdata`，ICB-X 的 `id`/`len`/`last` 在窄侧和宽侧保持完全一致。

**信号通路**：

```
32-bit 侧 ──cmd_id/len/last──→ [直通] ──→ 64-bit 侧
64-bit 侧 ──rsp_id/last──→ [直通] ──→ 32-bit 侧
```

---

### 4.4 模块：`sirv_gnrl_icb_splt`（ICB 分路器/解复用器）

**功能**：1 对 N 地址解码分路，根据地址将 CMD 路由到 N 个下游从设备之一，并将选中从设备的 RSP 路由回上游。

**修改内容**：

| 修改项 | 新增信号 | 说明 |
|:---|:---|:---|
| **输入端口** | `i_icb_cmd_id`, `i_icb_cmd_len`, `i_icb_cmd_last` | 上游 CMD ICB-X |
| | `i_icb_rsp_id`, `i_icb_rsp_last` | 上游 RSP ICB-X（输出方向） |
| **输出总线端口** | `o_bus_icb_cmd_id [N*ID_W-1:0]` | N 个下游从设备的 CMD ID 拼接 |
| | `o_bus_icb_cmd_len [N*LEN_W-1:0]` | N 个下游从设备的 CMD LEN 拼接 |
| | `o_bus_icb_cmd_last [N*1-1:0]` | N 个下游从设备的 CMD LAST 拼接 |
| | `o_bus_icb_rsp_id [N*ID_W-1:0]` | N 个下游从设备的 RSP ID 拼接 |
| | `o_bus_icb_rsp_last [N*1-1:0]` | N 个下游从设备的 RSP LAST 拼接 |
| **CMD 分发逻辑** | `o_icb_cmd_id[i]` | ICB-X 复制到所有下游端口（有效掩码控制） |
| **RSP 汇聚逻辑** | `sel_i_icb_rsp_id`, `sel_i_icb_rsp_last` | OR-MUX：基于 port_id 从 N 个 RSP 中选择一个 |

**CMD 分发方式**：分为两种模式（由参数控制）：
- **直接复制**：`o_icb_cmd_id[i] = i_icb_cmd_id`（所有端口都收到相同的 ICB-X 信号）
- **有效掩码复制**：`o_icb_cmd_id[i] = {ID_W{valid[i]}} & i_icb_cmd_id`（仅选中端口有效）

**RSP 汇聚方式**：
- **1-hot 模式**：通过 `for` 循环 OR-MUX 逐位合并
- **索引模式**：直接通过 `port_id` 索引选择

**信号通路**：

```
上游 ──cmd_id/len/last──→ [分发复制] ──→ 从设备 0 的 cmd_id/len/last
                                    ──→ 从设备 1 的 cmd_id/len/last
                                    ──→ ...
                                    ──→ 从设备 N-1 的 cmd_id/len/last

从设备 0 ──rsp_id/last──┐
从设备 1 ──rsp_id/last──┤  ─→ [OR-MUX 基于 port_id] ─→ i_icb_rsp_id/last ─→ 上游
...                     ┘
```

---

## 5. Phase 3 — BIU 总线接口单元升级

### 修改文件：`e203_biu.v`

BIU（Bus Interface Unit）是 E203 核心与外部总线系统的唯一出口，负责将 IFU（取指单元）和 LSU（存取单元）的访问请求汇聚、仲裁，然后按地址解码分发到不同的外设通道。

---

### 5.1 模块端口声明

**新增 ICB-X 端口列表**：

| 通道 | CMD 方向（输入） | RSP 方向（输出） |
|:---|:---|:---|
| **LSU→BIU** | `lsu2biu_icb_cmd_id/len/last` | `lsu2biu_icb_rsp_id/last` |
| **IFU→BIU**（`E203_HAS_MEM_ITF`） | `ifu2biu_icb_cmd_id/len/last` | `ifu2biu_icb_rsp_id/last` |
| **PPI**（输出） | `ppi_icb_cmd_id/len/last` | `ppi_icb_rsp_id/last`（输入） |
| **CLINT**（输出） | `clint_icb_cmd_id/len/last` | `clint_icb_rsp_id/last`（输入） |
| **PLIC**（输出） | `plic_icb_cmd_id/len/last` | `plic_icb_rsp_id/last`（输入） |
| **FIO**（输出，`E203_HAS_FIO`） | `fio_icb_cmd_id/len/last` | `fio_icb_rsp_id/last`（输入） |
| **MEM**（输出，`E203_HAS_MEM_ITF`） | `mem_icb_cmd_id/len/last` | `mem_icb_rsp_id/last`（输入） |

**共新增 38 个 `ifdef E203_HAS_ICBX` 块。**

### 5.2 内部 Wire 声明

新增以下内部线网用于 ICB-X 信号传递：

```
ifuerr_icb_cmd_id/len/last, ifuerr_icb_rsp_id/last   // IFU 错误回退通道
arbt_icb_cmd_id/len/last, arbt_icb_rsp_id/last       // 仲裁输出
arbt_bus_icb_cmd_id/len/last                          // 仲裁输入总线（拼接）
arbt_bus_icb_rsp_id/last                              // 仲裁 RSP 总线（拼接）
buf_icb_cmd_id/len/last, buf_icb_rsp_id/last          // Buffer 输出
splt_bus_icb_cmd_id/len/last                          // Splt 输出总线（拼接）
splt_bus_icb_rsp_id/last                              // Splt RSP 总线（拼接）
```

### 5.3 仲裁器连接（arbt 实例）

**CMD 总线拼接**：

```verilog
assign arbt_bus_icb_cmd_id = {
    `ifdef E203_HAS_MEM_ITF
      ifu2biu_icb_cmd_id,       // IFU 的 cmd_id（高位，高优先级）
    `endif
      lsu2biu_icb_cmd_id        // LSU 的 cmd_id（低位）
};
// cmd_len, cmd_last 同理
```

**RSP 总线解包**：

```verilog
assign {
    `ifdef E203_HAS_MEM_ITF
      ifu2biu_icb_rsp_id,
    `endif
      lsu2biu_icb_rsp_id
} = arbt_bus_icb_rsp_id;
// rsp_last 同理
```

**arbt 实例端口连接**：

```verilog
.o_icb_cmd_id   (arbt_icb_cmd_id),    // 仲裁输出 CMD ID
.o_icb_cmd_len  (arbt_icb_cmd_len),   // 仲裁输出 CMD LEN
.o_icb_cmd_last (arbt_icb_cmd_last),  // 仲裁输出 CMD LAST
.o_icb_rsp_id   (arbt_icb_rsp_id),    // 仲裁 RSP ID
.o_icb_rsp_last (arbt_icb_rsp_last),  // 仲裁 RSP LAST
.i_bus_icb_cmd_id   (arbt_bus_icb_cmd_id),
.i_bus_icb_cmd_len  (arbt_bus_icb_cmd_len),
.i_bus_icb_cmd_last (arbt_bus_icb_cmd_last),
.i_bus_icb_rsp_id   (arbt_bus_icb_rsp_id),
.i_bus_icb_rsp_last (arbt_bus_icb_rsp_last),
```

### 5.4 Buffer 连接

Buffer 在 arbt 和 splt 之间，ICB-X 信号完整穿透：

```
arbt_icb_cmd_id/len/last ──→ [buffer.i_icb_cmd_*] ──→ [buffer.o_icb_cmd_*] ──→ buf_icb_cmd_id/len/last
buf_icb_rsp_id/last ──→ [buffer.o_icb_rsp_*] ──→ [buffer.i_icb_rsp_*] ──→ arbt_icb_rsp_id/last
```

### 5.5 Splt 连接与 CMD 分发

Splt 将 buf 输出按地址解码分发到 6 个下游通道：`ifuerr`, `ppi`, `clint`, `plic`, `fio`, `mem`。

**CMD 解包**：

```verilog
assign {ifuerr_icb_cmd_id, ppi_icb_cmd_id, clint_icb_cmd_id,
        plic_icb_cmd_id, fio_icb_cmd_id, mem_icb_cmd_id
       } = splt_bus_icb_cmd_id;
// cmd_len, cmd_last 同理
```

**RSP 打包**：

```verilog
assign splt_bus_icb_rsp_id = {ifuerr_icb_rsp_id, ppi_icb_rsp_id, clint_icb_rsp_id,
                               plic_icb_rsp_id, fio_icb_rsp_id, mem_icb_rsp_id};
// rsp_last 同理
```

### 5.6 IFU 错误通道处理

当 IFU 访问外设区域时，BIU 产生一个错误响应：

```verilog
`ifdef E203_HAS_ICBX
  assign ifuerr_icb_rsp_id   = ifuerr_icb_cmd_id;  // ID 直接回环
  assign ifuerr_icb_rsp_last = 1'b1;                // 错误响应始终是单拍
`endif
```

### 5.7 BIU 内部完整信号通路

```
    IFU ──cmd_id/len/last──┐
                           ├─→ [arbt_bus 拼接] ─→ [arbt] ─→ [buffer] ─→ [splt 地址解码]
    LSU ──cmd_id/len/last──┘                                              │
                                                                    ┌─────┼─────┬─────┬─────┬─────┐
                                                                    ↓     ↓     ↓     ↓     ↓     ↓
                                                                 ifuerr  ppi  clint  plic   fio   mem
                                                                    │     │     │     │     │     │
                                                                    └─────┼─────┴─────┴─────┴─────┘
                                                                          ↓
                                                               [splt RSP 汇聚] ─→ [buffer] ─→ [arbt RSP]
                                                                                                │
                                                                    ┌───────────────────────────┘
                                                                    ↓
    IFU ←─rsp_id/last──┐
                        ├←─ [arbt_bus RSP 解包]
    LSU ←─rsp_id/last──┘
```

---

## 6. Phase 4 — ICB2AXI 桥接模块升级

### 修改文件：`sirv_gnrl_icbs.v`（`sirv_gnrl_icb2axi` 模块）

ICB2AXI 桥是**唯一涉及协议转换逻辑**的模块，也是 ICB-X 改造中最复杂的部分。它将 ICB(-X) 事务转换为标准 AXI 事务。

---

### 6.1 新增端口

| 端口 | 方向 | 说明 |
|:---|:---:|:---|
| `i_icb_cmd_id [ID_W-1:0]` | 输入 | ICB-X 事务 ID |
| `i_icb_cmd_len [LEN_W-1:0]` | 输入 | ICB-X 突发长度 |
| `i_icb_cmd_burst [1:0]` | 输入 | ICB-X 突发类型（FIXED/INCR/WRAP） |
| `i_icb_cmd_last` | 输入 | ICB-X CMD 最后一拍标志 |
| `i_icb_rsp_id [ID_W-1:0]` | 输出 | ICB-X RSP 事务 ID |
| `i_icb_rsp_last` | 输出 | ICB-X RSP 最后一拍标志 |

### 6.2 突发追踪状态机

新增两个状态寄存器跟踪多拍突发的进行状态：

```verilog
reg burst_wr_active;   // 写突发进行中标志
reg burst_rd_active;   // 读突发进行中标志
```

**状态转换逻辑**：

| 条件 | 转换 | 说明 |
|:---|:---|:---|
| `cmd_fire & ~read & ~burst_wr_active & |len & ~last` | `burst_wr_active ← 1` | 写突发第一拍（非 last） |
| `cmd_fire & ~read & last` | `burst_wr_active ← 0` | 写突发最后一拍 |
| `cmd_fire & read & ~burst_rd_active & |len & ~last` | `burst_rd_active ← 1` | 读突发第一拍 |
| `cmd_fire & read & last` | `burst_rd_active ← 0` | 读突发最后一拍 |

### 6.3 AXI 通道控制逻辑修改

**原始逻辑（单拍）**：每次 CMD 都同时发出 AR 或 AW+W。

**ICB-X 突发逻辑**：

| AXI 通道 | 控制条件 | 说明 |
|:---|:---|:---|
| **AR**（读地址） | `valid & read & ~burst_rd_active & ~fifo_full` | 仅在读突发第一拍发出 AR |
| **AW**（写地址） | `valid & ~read & ~burst_wr_active & wready & ~fifo_full` | 仅在写突发第一拍发出 AW |
| **W**（写数据） | `valid & ~read & (burst_active ? ~fifo_full : awready & ~fifo_full)` | 每一拍都发出 W |
| **CMD ready** | `read ? (burst_rd ? 1'b1 : arready) : (burst_wr ? wready : awready & wready)` | 后续拍不需要等待 AR/AW ready |

### 6.4 ICB-X 到 AXI 信号映射

```verilog
assign i_axi_arburst = i_icb_cmd_burst;     // ICB-X burst → AXI AR burst
assign i_axi_awburst = i_icb_cmd_burst;     // ICB-X burst → AXI AW burst
assign i_axi_arlen   = i_icb_cmd_len[3:0];  // ICB-X len[3:0] → AXI3 len (4-bit)
assign i_axi_awlen   = i_icb_cmd_len[3:0];  // ICB-X len[3:0] → AXI3 len (4-bit)
assign i_axi_wlast   = i_icb_cmd_last;      // ICB-X last → AXI W last
```

> 注意：AXI3 的 len 字段为 4-bit（max 16 beats），故此处仅取 `len[3:0]`。AXI4 扩展到 8-bit 可在此处直接修改。

### 6.5 RW FIFO 扩展

**原始 FIFO**：宽度 1 bit（仅存储 read/write 标志）

**ICB-X FIFO**：宽度 = `E203_ICBX_ID_W + 2`（存储 `{cmd_id, rsp_type[1:0]}`）

**rsp_type 编码**：

| 编码 | 名称 | 含义 | AXI 响应来源 |
|:---:|:---|:---|:---|
| `2'b10` | read | 读事务 | AXI R 通道 |
| `2'b01` | write burst mid | 写突发中间拍 | 无（立即响应） |
| `2'b00` | write single/last | 写单拍或写突发最后一拍 | AXI B 通道 |

**`is_wr_burst_nolast` 判定逻辑**：

```verilog
wire is_wr_burst_nolast = (~i_icb_cmd_read) &
     ((~burst_wr_active & (|i_icb_cmd_len) & (~i_icb_cmd_last))   // 突发第一拍（非 last）
     |( burst_wr_active & (~i_icb_cmd_last)));                     // 突发中间拍（非 last）
```

### 6.6 RSP 响应生成

```verilog
assign i_icb_rsp_id   = rw_fifo_o_dat[RW_FIFO_W-1:2];  // 从 FIFO 中取出 cmd_id
assign i_icb_rsp_last = i_icb_rsp_read    ? i_axi_rlast :   // 读：来自 AXI rlast
                         i_icb_rsp_wr_immed ? 1'b0 :          // 写中间拍：0
                                              1'b1;            // 写 last/单拍：1
```

### 6.7 ICB2AXI 信号通路

```
ICB-X CMD ──→ [burst FSM 判定] ──→ AXI AR (首拍读) / AW (首拍写) / W (每拍写)
         │
         └──→ [RW FIFO 入队: {cmd_id, rsp_type}]
                                      │
AXI R resp ──→ [rsp_type=read] ──→   ├──→ [rsp_id = FIFO.cmd_id]
AXI B resp ──→ [rsp_type=wr_last] ──→│    [rsp_last = rlast / 0 / 1]
(immediate) ──→ [rsp_type=wr_mid] ──→┘
                                      │
                                      └──→ ICB-X RSP
```

---

## 7. Phase 5 — LSU/IFU 接口与核心层级布线

### 本阶段修改 6 个文件，将 ICB-X 信号从**最底层信号源**（IFU/LSU）通过核心层级向上传播到 CPU 模块边界。

---

### 7.1 文件：`e203_ifu_ift2icb.v`（IFU 取指→ICB 适配器）

**角色**：将 IFU 的取指请求转换为 ICB 事务并发送到 BIU。

**新增端口**：

| 端口 | 方向 | 说明 |
|:---|:---:|:---|
| `ifu2biu_icb_cmd_id` | output | IFU 发出的事务 ID |
| `ifu2biu_icb_cmd_len` | output | IFU 发出的突发长度 |
| `ifu2biu_icb_cmd_last` | output | IFU 发出的最后一拍标志 |
| `ifu2biu_icb_rsp_id` | input | 返回的响应事务 ID |
| `ifu2biu_icb_rsp_last` | input | 返回的响应最后一拍标志 |

**默认值赋值**：

```verilog
assign ifu2biu_icb_cmd_id   = {`E203_ICBX_ID_W{1'b0}};   // ID = 0
assign ifu2biu_icb_cmd_len  = {`E203_ICBX_LEN_W{1'b0}};  // LEN = 0（单拍）
assign ifu2biu_icb_cmd_last = 1'b1;                        // LAST = 1（每拍都是最后一拍）
```

**设计说明**：当前 IFU 仅支持单拍取指（每次取 32-bit 指令字），因此 ICB-X 信号使用单拍默认值。未来若支持 Cache line fetch，可修改此处。

---

### 7.2 文件：`e203_lsu_ctrl.v`（LSU 控制器）

**角色**：管理 LSU 的仲裁（AGU + NICE 多源）和 BIU 接口。

**新增端口**：

| 端口 | 方向 | 说明 |
|:---|:---:|:---|
| `biu_icb_cmd_id/len/last` | output | LSU→BIU 的 CMD ICB-X |
| `biu_icb_rsp_id/last` | input | BIU→LSU 的 RSP ICB-X |

**新增内部线网**：

```verilog
// 仲裁输出线
wire arbt_icb_cmd_id, arbt_icb_cmd_len, arbt_icb_cmd_last;
wire arbt_icb_rsp_id, arbt_icb_rsp_last;

// 仲裁输入总线（拼接 AGU + NICE 等多源）
wire [LSU_ARBT_I_NUM*ID_W-1:0]  arbt_bus_icb_cmd_id;
wire [LSU_ARBT_I_NUM*LEN_W-1:0] arbt_bus_icb_cmd_len;
wire [LSU_ARBT_I_NUM*1-1:0]     arbt_bus_icb_cmd_last;
wire [LSU_ARBT_I_NUM*ID_W-1:0]  arbt_bus_icb_rsp_id;
wire [LSU_ARBT_I_NUM*1-1:0]     arbt_bus_icb_rsp_last;
```

**arbt 实例连接**：与 BIU 中 arbt 连接方式相同，ICB-X 信号通过拼接总线进出仲裁器。

**BIU CMD 输出赋值**：

```verilog
assign biu_icb_cmd_id   = arbt_icb_cmd_id;
assign biu_icb_cmd_len  = arbt_icb_cmd_len;
assign biu_icb_cmd_last = arbt_icb_cmd_last;
```

**信号通路**：

```
AGU ──cmd_id/len/last──┐
                       ├─→ [LSU arbt] ─→ biu_icb_cmd_id/len/last ─→ BIU
NICE ──cmd_id/len/last─┘

BIU ──rsp_id/last──→ [LSU arbt RSP] ─→ AGU/NICE
```

---

### 7.3 文件：`e203_lsu.v`（LSU 顶层封装）

**角色**：LSU 的顶层模块封装。

**修改**：纯传递，新增 ICB-X 端口声明后直接连接到内部 `e203_lsu_ctrl` 实例。

---

### 7.4 文件：`e203_ifu.v`（IFU 顶层封装）

**角色**：IFU 的顶层模块封装。

**修改**：纯传递，新增 ICB-X 端口声明后直接连接到内部 `e203_ifu_ift2icb` 实例。

---

### 7.5 文件：`e203_core.v`（处理器核心）

**角色**：E203 核心顶层，实例化 IFU、EXU（含 LSU）、BIU 等子模块并互联。

**新增端口**（5 个外设通道）：

| 通道 | CMD 方向（输出） | RSP 方向（输入） |
|:---|:---|:---|
| `ppi_icb_*` | `cmd_id/len/last` | `rsp_id/last` |
| `clint_icb_*` | `cmd_id/len/last` | `rsp_id/last` |
| `plic_icb_*` | `cmd_id/len/last` | `rsp_id/last` |
| `fio_icb_*`（`E203_HAS_FIO`） | `cmd_id/len/last` | `rsp_id/last` |
| `mem_icb_*`（`E203_HAS_MEM_ITF`） | `cmd_id/len/last` | `rsp_id/last` |

**内部线网声明**：为 IFU、LSU 到 BIU 的中间连接声明 ICB-X wire。

**子模块实例连接**：

```
IFU 实例 ──ifu2biu_icb_cmd_id/len/last──┐
                                        ├──→ BIU 实例 ──→ 5 个通道 cmd_id/len/last ──→ core 输出端口
LSU 实例 ──lsu2biu_icb_cmd_id/len/last──┘

core 输入 rsp_id/last ──→ BIU 实例 ──→ IFU/LSU 实例 rsp_id/last
```

---

### 7.6 文件：`e203_cpu.v`（CPU 顶层）

**角色**：CPU 模块封装，包含 core + 时钟控制 + 中断同步。

**修改**：新增 5 个通道的 ICB-X 端口声明，直接传递到/从 `e203_core` 实例。

**信号通路**：纯传递层，无逻辑。

```
cpu.ppi_icb_cmd_id ←→ core.ppi_icb_cmd_id
cpu.ppi_icb_rsp_id ←→ core.ppi_icb_rsp_id
// ... 其余通道同理
```

---

## 8. Phase 6 — SoC 顶层层级与外设端点布线

### 本阶段修改 8 个文件，将 ICB-X 信号从 CPU 边界一路传播到 SoC 最外层边界以及各外设端点模块。

---

### 8.1 文件：`e203_cpu_top.v`（CPU 顶层封装）

**角色**：CPU + SRAM 封装层。

**修改**：新增 5 个通道（ppi/clint/plic/fio/mem）的 ICB-X 模块端口声明，以及 `e203_cpu` 实例端口连接。共 20 个 `ifdef` 块。

**信号通路**：纯传递层。

```
cpu_top.ppi_icb_cmd_id ←→ cpu.ppi_icb_cmd_id
// ... 所有 5 通道同理
```

---

### 8.2 文件：`e203_subsys_main.v`（子系统主枢纽）

**角色**：子系统核心枢纽，连接 cpu_top 到所有外设子模块和外部通道。这是 Phase 6 中**最复杂的文件**。

**修改概要**：共 32 个 `ifdef` 块。

#### 8.2.1 模块端口（外部通道）

新增 3 个外部系统通道的 ICB-X 端口：

| 通道 | CMD 方向（输出） | RSP 方向（输入） |
|:---|:---|:---|
| `sysper_icb_*` | `cmd_id/len/last` | `rsp_id/last` |
| `sysfio_icb_*` | `cmd_id/len/last` | `rsp_id/last` |
| `sysmem_icb_*` | `cmd_id/len/last` | `rsp_id/last` |

#### 8.2.2 内部线网

新增 5 个内部通道的 ICB-X wire 声明：

```verilog
wire [`E203_ICBX_ID_W-1:0]  ppi_icb_cmd_id;     // PPI 通道
wire [`E203_ICBX_LEN_W-1:0] ppi_icb_cmd_len;
wire                         ppi_icb_cmd_last;
// ... clint, plic, fio, mem 同理
```

#### 8.2.3 cpu_top 实例连接

将 cpu_top 的 5 个外设通道 ICB-X 端口连接到内部 wire：

```
cpu_top.ppi_icb_cmd_id ──→ ppi_icb_cmd_id (wire) ──→ perips 实例
cpu_top.clint_icb_cmd_id ──→ clint_icb_cmd_id (wire) ──→ clint 实例
cpu_top.plic_icb_cmd_id ──→ plic_icb_cmd_id (wire) ──→ plic 实例
cpu_top.fio_icb_cmd_id ──→ fio_icb_cmd_id (wire) ──→ sysfio 端口（直连）
cpu_top.mem_icb_cmd_id ──→ mem_icb_cmd_id (wire) ──→ mems 实例
```

#### 8.2.4 FIO 直连

FIO 通道不经过子模块，直接通过 `assign` 连接到外部端口：

```verilog
`ifdef E203_HAS_ICBX
  assign sysfio_icb_cmd_id   = fio_icb_cmd_id;
  assign sysfio_icb_cmd_len  = fio_icb_cmd_len;
  assign sysfio_icb_cmd_last = fio_icb_cmd_last;
  assign fio_icb_rsp_id      = sysfio_icb_rsp_id;
  assign fio_icb_rsp_last    = sysfio_icb_rsp_last;
`endif
```

---

### 8.3 文件：`e203_subsys_plic.v`（PLIC 平台级中断控制器）

**修改**：3 个 `ifdef` 块。

**新增端口**：

| 端口 | 方向 | 说明 |
|:---|:---:|:---|
| `plic_icb_cmd_id/len/last` | input | PLIC 接收的 CMD ICB-X |
| `plic_icb_rsp_id` | output | PLIC 返回的 RSP ID |
| `plic_icb_rsp_last` | output | PLIC 返回的 RSP LAST |

**Tie-off 值**（PLIC 为简单外设，不支持突发）：

```verilog
assign plic_icb_rsp_id   = {`E203_ICBX_ID_W{1'b0}};  // ID = 0
assign plic_icb_rsp_last = 1'b1;                       // 始终单拍响应
```

---

### 8.4 文件：`e203_subsys_clint.v`（CLINT 定时器/软中断控制器）

**修改**：3 个 `ifdef` 块。与 PLIC 结构相同。

**Tie-off 值**：

```verilog
assign clint_icb_rsp_id   = {`E203_ICBX_ID_W{1'b0}};
assign clint_icb_rsp_last = 1'b1;
```

---

### 8.5 文件：`e203_subsys_perips.v`（PPI 外设总线）

**修改**：5 个 `ifdef` 块。

**新增端口**：

| 端口 | 方向 | 说明 |
|:---|:---:|:---|
| `ppi_icb_cmd_id/len/last` | input | 来自 CPU 的 PPI CMD ICB-X |
| `ppi_icb_rsp_id/last` | output | 返回 CPU 的 PPI RSP ICB-X |
| `sysper_icb_cmd_id/len/last` | output | 向外输出的 SysPer CMD ICB-X |
| `sysper_icb_rsp_id/last` | input | 外部返回的 SysPer RSP ICB-X |

**Tie-off 值**：

```verilog
// PPI RSP 默认值（内部外设不支持突发）
assign ppi_icb_rsp_id   = {`E203_ICBX_ID_W{1'b0}};
assign ppi_icb_rsp_last = 1'b1;

// SysPer CMD 默认值（当前不生成突发请求给外部外设）
assign sysper_icb_cmd_id   = {`E203_ICBX_ID_W{1'b0}};
assign sysper_icb_cmd_len  = {`E203_ICBX_LEN_W{1'b0}};
assign sysper_icb_cmd_last = 1'b1;
```

---

### 8.6 文件：`e203_subsys_mems.v`（内存总线）

**修改**：5 个 `ifdef` 块。

**新增端口**：

| 端口 | 方向 | 说明 |
|:---|:---:|:---|
| `mem_icb_cmd_id/len/last` | input | 来自 CPU 的 MEM CMD ICB-X |
| `mem_icb_rsp_id/last` | output | 返回 CPU 的 MEM RSP ICB-X |
| `sysmem_icb_cmd_id/len/last` | output | 向外输出的 SysMem CMD ICB-X |
| `sysmem_icb_rsp_id/last` | input | 外部返回的 SysMem RSP ICB-X |

**Tie-off 值**：

```verilog
// MEM RSP 默认值（内部 MROM/DM 不支持突发）
assign mem_icb_rsp_id   = {`E203_ICBX_ID_W{1'b0}};
assign mem_icb_rsp_last = 1'b1;

// SysMem CMD 默认值
assign sysmem_icb_cmd_id   = {`E203_ICBX_ID_W{1'b0}};
assign sysmem_icb_cmd_len  = {`E203_ICBX_LEN_W{1'b0}};
assign sysmem_icb_cmd_last = 1'b1;
```

---

### 8.7 文件：`e203_subsys_top.v`（子系统顶层封装）

**修改**：12 个 `ifdef` 块。

**新增端口**：3 个外部通道（sysper/sysfio/sysmem）的 ICB-X 模块端口和 subsys_main 实例连接。

**信号通路**：纯传递层。

```
subsys_top.sysper_icb_cmd_id ←→ subsys_main.sysper_icb_cmd_id
subsys_top.sysfio_icb_cmd_id ←→ subsys_main.sysfio_icb_cmd_id
subsys_top.sysmem_icb_cmd_id ←→ subsys_main.sysmem_icb_cmd_id
```

---

### 8.8 文件：`e203_soc_top.v`（SoC 最顶层）

**修改**：6 个 `ifdef` 块。

**角色**：SoC 最外层封装，在本项目中通过环回 tie-off 终止外部通道（实际 SoC 集成时替换为真实外部设备连接）。

**Tie-off 方式**：

```verilog
// CMD 输出悬空（SoC 顶层不连接外部主设备）
.sysper_icb_cmd_id   (),
.sysper_icb_cmd_len  (),
.sysper_icb_cmd_last (),

// RSP 输入使用默认值
.sysper_icb_rsp_id   ({`E203_ICBX_ID_W{1'b0}}),
.sysper_icb_rsp_last (1'b1),

// sysfio, sysmem 同理
```

---

## 9. 完整信号通路总图

### 9.1 CMD 方向（Master → Slave）

```
┌────────────────────────── E203 SoC 核心 ──────────────────────────┐
│                                                                    │
│  ┌─────────┐   cmd_id    ┌─────────┐   cmd_id    ┌───────────┐   │
│  │  IFU    │──len/last──→│  BIU    │──(5通道)──→ │ e203_core │   │
│  │ift2icb  │  (默认值)   │  arbt   │             │  5 端口   │   │
│  └─────────┘             │  ↓      │             └─────┬─────┘   │
│  ┌─────────┐   cmd_id    │ buffer  │                   │          │
│  │  LSU    │──len/last──→│  ↓      │                   │          │
│  │ ctrl    │  (仲裁后)   │  splt   │                   │          │
│  └─────────┘             └─────────┘                   │          │
│                                                        ↓          │
│                                              ┌─────────────────┐  │
│                                              │   e203_cpu.v    │  │
│                                              │   (纯传递)      │  │
│                                              └────────┬────────┘  │
│                                                       ↓           │
│                                              ┌─────────────────┐  │
│                                              │ e203_cpu_top.v  │  │
│                                              │   (纯传递)      │  │
│                                              └────────┬────────┘  │
│                                                       ↓           │
│                                              ┌─────────────────┐  │
│                                              │ subsys_main.v   │  │
│                                              │   (路由枢纽)    │  │
│                                              └──┬──┬──┬──┬──┬──┘  │
│                                                 │  │  │  │  │     │
│                           ┌─────────────────────┘  │  │  │  └───────────────────┐
│                           ↓                        │  ↓  │        │             ↓
│                    ┌──────────────┐    ┌───────────┐│ FIO │  ┌──────────┐  ┌──────────┐
│                    │subsys_perips │    │subsys_clint││直连 │  │subsys_   │  │subsys_   │
│                    │  ppi 端口    │    │  clint端口 ││     │  │plic      │  │mems      │
│                    └──────┬───────┘    └───────────┘│     │  └──────────┘  └──────┬───┘
│                           │                         │     │                       │     │
│                           ↓                         ↓     │                       ↓     │
│                      sysper_icb               sysfio_icb  │                  sysmem_icb │
│                      cmd_id/len/last          cmd_id/...  │                  cmd_id/... │
└───────────────────────────┬──────────────────────┬────────┘──────────────────────┬──────┘
                            ↓                      ↓                               ↓
                    ┌─────────────┐        ┌─────────────┐                 ┌─────────────┐
                    │subsys_top.v │        │subsys_top.v │                 │subsys_top.v │
                    │  (传递)     │        │  (传递)     │                 │  (传递)     │
                    └──────┬──────┘        └──────┬──────┘                 └──────┬──────┘
                           ↓                      ↓                               ↓
                    ┌─────────────┐        ┌─────────────┐                 ┌─────────────┐
                    │ soc_top.v   │        │ soc_top.v   │                 │ soc_top.v   │
                    │ (tie-off)   │        │ (tie-off)   │                 │ (tie-off)   │
                    └─────────────┘        └─────────────┘                 └─────────────┘
```

### 9.2 RSP 方向（Slave → Master）

RSP 方向与 CMD 完全反向，`rsp_id` 和 `rsp_last` 沿上图路径**反向**传递：

- **soc_top** → tie-off 默认值 `rsp_id=0, rsp_last=1`
- **subsys_top** → 传递
- **subsys_main** → 路由到对应通道
- **endpoint 外设**（plic/clint/perips/mems） → tie-off 默认值 `rsp_id=0, rsp_last=1`
- **cpu_top** → 传递
- **cpu** → 传递
- **core** → 传递
- **BIU splt** → RSP OR-MUX 选择 → **BIU buffer** → **BIU arbt** RSP 解包
- **IFU/LSU** ← `rsp_id/rsp_last`

---

## 10. 设计决策与注意事项

### 10.1 关键设计决策

| 决策 | 原因 |
|:---|:---|
| 全部包裹在 `ifdef E203_HAS_ICBX` | 确保零面积回退功能，不影响原始 E203 用户 |
| 默认值 `id=0, len=0, last=1` | 与原始单拍行为完全等价，确保向后兼容 |
| 突发编码与 AXI4 一致 | 简化 ICB2AXI 桥逻辑，可直接映射 |
| BIU outstanding 参数覆盖 | ICB-X 需要多 outstanding 支持，BIU 深度必须匹配 |
| ICB-X 传播到所有通道（含 PPI/CLINT 等） | 为未来扩展预留接口，即使当前不使用突发 |
| 端点外设使用 tie-off 默认值 | 简单外设无需修改内部逻辑 |
| ICB2AXI 使用 3-type FIFO | 精确区分读/写中间拍/写最后拍，正确生成 rsp_last |

### 10.2 后续扩展点

1. **L1 Cache 接入**：修改 `e203_lsu_ctrl.v` 的 CMD 输出，将 `cmd_len` 设为 Cache line 长度，`cmd_burst` 设为 INCR
2. **AI 加速器接入**：在 LSU arbt 增加一个输入端口，接入加速器的 ICB-X 主设备接口
3. **SysMem 实际对接**：替换 `e203_soc_top.v` 的 tie-off 为真实的外部 DDR 控制器 ICB-X 从设备
4. **AXI4 全位宽**：修改 `sirv_gnrl_icb2axi` 的 `arlen`/`awlen` 映射为完整 8-bit

### 10.3 修改统计

| 阶段 | 文件数 | `ifdef` 块数 | 新增信号类型 |
|:---:|:---:|:---:|:---|
| Phase 1 | 2 | 2 | 宏定义 |
| Phase 2 | 1 (4 模块) | ~30 | 端口、内部线网、打包/解包 |
| Phase 3 | 1 | 38 | 端口、线网、实例连接、拼接/解包 |
| Phase 4 | 1 (1 模块) | ~15 | 端口、FSM、AXI 映射、FIFO |
| Phase 5 | 6 | 74 | 端口、线网、实例连接 |
| Phase 6 | 8 | 86 | 端口、线网、实例连接、tie-off |
| **合计** | **19 files** | **~245** | — |

---

*本报告生成日期：2026年4月8日*
*项目：蜂鸟 E203 RISC-V 处理器 ICB-X 总线增强改造*
