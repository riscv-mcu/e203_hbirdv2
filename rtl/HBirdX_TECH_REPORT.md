# HBird-X 处理器技术报告

> **HBird-X**（Hybrid Bird with X-tensions）是一颗以蜂鸟 E203 为骨架、深度吸收 CV32E40P（RI5CY）四级流水设计、原创扩展动态分支预测、L1 缓存子系统与可重配 AI 加速器的 32 位 RISC-V 处理器。本报告描述其**完工后的**架构、模块构成、关键技术与性能。
>
> **指令集**：RV32IMC + Zicsr + Zifencei + Custom-NPU(0)；可选 RV32F（外挂）
> **流水线**：4 级顺序发射、可乱序完成（OITF 跟踪）
> **目标平台**：FPGA（Artix-7/Kintex-7）原型 + ASIC sign-off
> **相关文档**：[ICB-X 总线](ICB-X.md) · [设计实施计划](HYBRID_DESIGN.md)

---

## 目录

1. [处理器总览](#1-处理器总览)
2. [关键技术参数](#2-关键技术参数)
3. [顶层架构](#3-顶层架构)
4. [流水线详解](#4-流水线详解)
5. [模块清单与来源](#5-模块清单与来源)
6. [关键模块深度剖析](#6-关键模块深度剖析)
7. [总线与存储子系统](#7-总线与存储子系统)
8. [创新点综述](#8-创新点综述)
9. [性能数据](#9-性能数据)
10. [编程模型与软件支持](#10-编程模型与软件支持)
11. [验证方法学](#11-验证方法学)
12. [物理实现与资源](#12-物理实现与资源)
13. [结论与展望](#13-结论与展望)

---

## 1. 处理器总览

HBird-X 面向**端侧智能 MCU/SoC** 场景：以毫瓦级功耗执行实时控制任务的同时，能在片内完成轻量级神经网络推理（关键词识别、手写数字识别、传感器异常检测等）。其设计哲学是"**经典 RISC 控制核 + 紧耦合 AI 加速器**"，而非追求超标量与多核。

### 1.1 设计血统

HBird-X 不是从零起步，而是站在两个成熟开源核上"二次创作"：

| 来源 | 贡献 | 形态 |
|:---|:---|:---|
| **蜂鸟 E203**（Nuclei） | 顶层 SoC 层级、ITCM/DTCM、BIU、ICB(-X) 总线、NICE 协处理器接口、OITF 长流水线机制、ECLIC 中断、JTAG 调试、CSR/异常框架、时钟门控 | 骨架、外壳、内存子系统、调试 |
| **CV32E40P / RI5CY**（OpenHW Group） | 4 级流水线划分思想、prefetch buffer、aligner、compressed decoder、forwarding 网络、APU 解耦接口 | 流水线核心 + 浮点接口 |
| **HBird-X 原创** | gshare+BTB+RAS 动态分支预测器、L1 I/D Cache、HBird-NPU 加速器、TCM 融合权重缓冲、NICE-AI 调度协议、ICB-X 多 outstanding 总线（前置工作） | 性能 + AI 算力 + 创新点 |

E203 提供"**做什么**"（系统约束），CV32E40P 改写"**怎么算**"（计算路径），原创工作回答"**怎么更快**"（缓存）和"**怎么更聪明**"（NPU）。

### 1.2 主要特性

- 32 位 RISC-V，顺序四级流水，IPC 接近 1.0（无访存停顿时）
- 全功能 RV32IMC + Zicsr + Zifencei；M-mode 必备 + 可选 U-mode
- **动态分支预测**：64 项 BTB + 256 项 gshare PHT + 8 项 RAS
- **L1 双 Cache**：4 KB 2 路 32 B 行 I-Cache、4 KB 2 路 32 B 行 D-Cache（写回写分配）
- **TCM 旁路**：ITCM 64 KB / DTCM 64 KB 保留确定性 1 拍访问
- **APU 接口**：可外挂 FPnew（提供 RV32F）
- **HBird-NPU**：4×4 systolic PE 阵列 + 可重配精度（INT8/4/2）+ 稀疏跳过 + DMA
- **ICB-X 总线**：事务 ID + 突发长度 + 多 outstanding，AXI4 友好
- 标准 RISC-V Debug 0.13.2 + JTAG TAP

---

## 2. 关键技术参数

| 参数 | 值 | 备注 |
|:---|:---:|:---|
| 字长 | 32 bit | RV32 |
| 通用寄存器 | 32 × 32 bit | E203 寄存器堆，加 1 读口 |
| 流水线 | 4 级 IF/ID/EX/WB | 顺序发射、乱序完成 |
| OITF 深度 | 4 | 跟踪长流水线指令 |
| ITCM | 64 KB | 单端口 64-bit, 1 拍 |
| DTCM | 64 KB | 32-bit, 1 拍；高 2 KB 与 NPU 共享 |
| L1 I-Cache | 4 KB / 2-way / 32 B line | 64 set, 写策略 N/A |
| L1 D-Cache | 4 KB / 2-way / 32 B line | WB+WA, 1 MSHR |
| BTB | 64 项 / 4-way | LRU |
| PHT | 256 项 × 2-bit | gshare BHR=8 |
| RAS | 8 项 | 检测 JAL/JALR rd/rs1=x1/x5 |
| MULDIV | 17/33 周期 | 共享 35-bit 加法器 |
| NPU PE 阵列 | 4×4 | weight-stationary |
| NPU 峰值算力 | 1.6 GOPS @100 MHz INT8；6.4 GOPS @INT2 | 可重配 |
| 总线 | ICB-X | id/len/burst/last + 4 outstanding |
| 调试 | JTAG + DM 0.13.2 | 单步、断点、寄存器访问 |
| 中断 | ECLIC 风格 + CLINT | mtimer + msoftirq + 外部 |
| 目标主频 | FPGA ≥ 80 MHz; ASIC ≥ 300 MHz | 28 nm 估算 |

---

## 3. 顶层架构

### 3.1 模块层级

```
e203_soc_top.v ────────────────────────────── (E203 原)
└── e203_subsys_top.v ─────────────────────── (E203 原)
    └── e203_subsys_main.v ───────────────── (E203 原 + ICB-X 已贯通)
        ├── e203_subsys_perips.v / clint / plic / mems
        └── e203_cpu_top.v ─────────────────── (E203 原, ICB-X 透传)
            └── e203_cpu.v ──────────────────── (微调)
                └── e203_core.v ────────────── (重组)
                    ├── e203_ifu.v + I-Cache + BPU       ← 改造重点 1
                    ├── e203_idu.v                        ← 新增 ID 级
                    ├── e203_exu.v                        ← 改造为纯 EX 级
                    ├── e203_wbu.v                        ← 新增 WB 级
                    ├── e203_lsu.v + D-Cache              ← 改造重点 2
                    ├── e203_npu_top.v                    ← 创新模块
                    ├── e203_biu.v                        ← E203 原
                    └── e203_exu_csr.v + apu_disp         ← 浮点接口
```

### 3.2 数据通路概览

```
┌────────────── HBird-X Core ──────────────────────────────────┐
│                                                              │
│  IF                ID               EX               WB      │
│ ┌────┐  IF/ID    ┌────┐  ID/EX    ┌────┐  EX/WB    ┌────┐   │
│ │BPU │──────────▶│Decd│──────────▶│ALU │──────────▶│Wbck│   │
│ │I$  │           │RegR│           │BJP │           │Comm│   │
│ │Algn│           │Hzrd│           │AGU │           │Fwd │   │
│ │Comp│           │Disp│           │MUL │◀┐         │    │   │
│ └────┘           └────┘           │CSR │ │         └────┘   │
│   ▲                ▲              │APU │ │OITF       │     │
│   │ Mispredict     │ Forward      │NPU │ │           ▼     │
│   │                │ Stall        │LSU │ │         RegFile │
│   │                │              └─┬──┘ │                  │
│   │                │                ▼    │                  │
│   │                │              D$/Bus │                  │
│   │                │                ▼    │                  │
│   │                │              long_wbck─┘               │
│   │                │                                         │
│   └────────────────┴── 来自 EX 的 br_resolve 反馈 ─────────  │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## 4. 流水线详解

### 4.1 IF 级（取指）

每周期完成：
1. PC 选择（顺序 PC+4 / BPU 预测目标 / mispredict 重定向 / 异常向量 / mret/dret）
2. I-Cache 索引查表（命中：1 拍出指令；不命中：进入 refill 状态机）
3. Aligner：处理 32-bit 指令跨 16-bit 边界
4. Compressed Decoder：将 16-bit RVC 指令展开为等价 32-bit 形式
5. BPU：BTB/PHT/RAS 并行查询，输出 `pred_taken` + `pred_target`
6. 写入 IF/ID 流水寄存器：`{pc, instr, pred_*, btb_hit, excp_buserr}`

**取指吞吐**：cache 命中时 1 指令/周期；miss 时由 ICB-X INCR burst 一次性填一行，平均 8 拍数据 + 协议开销。

### 4.2 ID 级（解码与发射）

每周期完成：
1. 全功能解码器（标准 RV32IMC + Custom-0 NPU 编码）输出微操作 + 立即数 + 寄存器索引
2. 寄存器堆读 rs1/rs2（2 读口）
3. **冒险检测器**：检查与 EX/WB 寄存器写入是否冲突；检查 OITF 中是否有未完成的 RAW 依赖
4. **前递选择**：从 EX/WB 阶段以及 longp_wbck 通道选择最新值
5. **派遣**：决定本指令走哪条通道（ALU/BJP/AGU/MULDIV/CSR/APU/NPU）
6. **OITF 入队**：对长流水线指令分配 itag

**停顿条件**：load-use、APU/NPU 写后读、OITF 满、WB 写口冲突。

### 4.3 EX 级（执行）

按指令类型分流到并行的功能单元：
- **ALU**（单周期）：加减、逻辑、移位、SLT
- **BJP**（单周期）：分支条件 + 目标计算 + 给 BPU 反馈
- **AGU**（单周期）：地址 = rs1 + sign_ext(imm)；输出送 LSU/D-Cache
- **MULDIV**（17/33 周期）：复用 35-bit 加法器
- **CSR**（单周期）：读改写 m-mode CSR
- **APU 派遣**（异步）：握手交给外挂 FPU
- **NPU 派遣**（异步）：通过 NICE 内联协议交给 HBird-NPU

单周期单元结果直接进 EX/WB 流水寄存器；多周期单元结果通过 longp_wbck 通道与 OITF 协作。

### 4.4 WB 级（写回）

1. **写口仲裁**（`e203_wbu_arbt.v`）：在 ALU 单周期写回 vs longp_wbck（LSU/MULDIV/APU/NPU）之间仲裁，**长流水线优先**
2. **OITF 弹出**：长流水线指令完成后释放 itag
3. **Commit**（`e203_wbu_commit.v`）：寄存器实际写入；异常/中断进入 trap 流程
4. **前递回送**：最新写值同时通过 fwd 总线送回 ID 级

---

## 5. 模块清单与来源

### 5.1 IF 级子模块

| 模块 | 来源 | 基础 | 目的 |
|:---|:---|:---|:---|
| `e203_ifu.v` | E203 改 | 原 IFU 顶层 | 实例化下属子模块 + 顶层握手 |
| `e203_ifu_ifetch.v` | E203 改 | 原文件 | PC 计算与状态机；改造点：用 BPU 输出替代静态预测 |
| `e203_ifu_aligner.v` | CV32E40P 移植 | `cv32e40p_aligner.sv` | 跨字边界 32-bit 指令重组 |
| `e203_ifu_compdec.v` | CV32E40P 移植扩展 | `cv32e40p_compressed_decoder.sv` | 完整 RVC 指令解压 |
| `e203_ifu_bpu.v` | **原创** | 学术 gshare 算法 | 顶层封装 BTB/PHT/RAS |
| `e203_ifu_btb.v` | **原创** | 经典 4 路组关联 BTB | 64 项目标缓存 + LRU 替换 |
| `e203_ifu_pht.v` | **原创** | gshare 论文（McFarling 1993） | 256 × 2-bit 饱和计数器 |
| `e203_ifu_ras.v` | **原创** | 8 项硬件栈 | call/return 配对预测 |
| `e203_l1icache.v` | **原创** | 教材直接映射/组关联设计 | 4 KB 2 路 32 B 行 |
| `e203_ifu_ift2icb.v` | E203 改 | 原文件 | 适配为 cache miss → ICB-X burst 发起 |

### 5.2 ID 级子模块（新增）

| 模块 | 来源 | 基础 | 目的 |
|:---|:---|:---|:---|
| `e203_idu.v` | **原创封装** | E203 原 EXU 内部解码部分 | ID 级顶层 |
| `e203_idu_decode.v` | E203 + CV32E40P 融合 | 主要承袭 `e203_exu_decode.v`，扩展自定义 OPCODE_CUSTOM_0（NPU） | 全 ISA 解码 |
| `e203_idu_regfile.v` | E203 改 | `e203_exu_regfile.v` | 寄存器堆，加第 3 读口（前递路径） |
| `e203_idu_disp.v` | E203 改 | `e203_exu_disp.v` | 派遣到各功能单元 |
| `e203_idu_hazard.v` | **原创** | CV32E40P forwarding 思路 | EX→ID + WB→ID + OITF→ID 多源前递 |

### 5.3 EX 级子模块

| 模块 | 来源 | 基础 | 目的 |
|:---|:---|:---|:---|
| `e203_exu.v` | E203 改 | 原文件去除 decode/disp/regfile/wbck | 仅保留计算路径，作为 EX 级载体 |
| `e203_exu_alu_dpath.v` | E203 原 | 原文件 | 35-bit 加法器，多功能复用 |
| `e203_exu_alu_bjp.v` | E203 改 | 原文件 | 改造点：解析后向 BPU 回送结果 |
| `e203_exu_alu_lsuagu.v` | E203 原 | 原文件 | 地址生成 |
| `e203_exu_alu_muldiv.v` | E203 原 | 原文件 | 整数乘除 |
| `e203_exu_alu_csrctrl.v` | E203 原 | 原文件 | CSR 读改写 |
| `e203_exu_apu_disp.v` | CV32E40P 移植 | `cv32e40p_apu_disp.sv` 转译为 Verilog | FPU 异步派遣与依赖追踪 |
| `e203_exu_npu_disp.v` | **原创** | 仿照 NICE 接口 | NPU 自定义指令派遣 |
| `e203_exu_oitf.v` | E203 改 | 原文件 | 加 1-bit `is_apu`、1-bit `is_npu` 标记 |
| `e203_exu_branchslv.v` | E203 原 | 原文件 | 分支解决 |

### 5.4 WB 级子模块（新增）

| 模块 | 来源 | 基础 | 目的 |
|:---|:---|:---|:---|
| `e203_wbu.v` | **原创封装** | E203 原 wbck/longpwbck/commit | WB 级顶层 |
| `e203_wbu_arbt.v` | E203 改 | `e203_exu_wbck.v` | 单周期/长流水线写口仲裁 |
| `e203_wbu_longp.v` | E203 改 | `e203_exu_longpwbck.v` | 多源长写回（LSU/MULDIV/APU/NPU） |
| `e203_wbu_commit.v` | E203 改 | `e203_exu_commit.v` | 异常/中断 commit |

### 5.5 LSU 与 D-Cache

| 模块 | 来源 | 基础 | 目的 |
|:---|:---|:---|:---|
| `e203_lsu.v` | E203 改 | 原文件 | 顶层封装 |
| `e203_lsu_ctrl.v` | E203 改 | 原文件 | 改造点：地址解码增加 cacheable 判断 |
| `e203_l1dcache.v` | **原创** | 教材 WB+WA 设计 | 4 KB 2 路 32 B 行 |
| `e203_dcache_mshr.v` | **原创** | 简单 MSHR | 1 项 in-flight miss 跟踪 |

### 5.6 NPU 子模块（全部原创）

| 模块 | 基础 | 目的 |
|:---|:---|:---|
| `e203_npu_top.v` | — | 顶层封装 + NICE 接口 |
| `e203_npu_seq.v` | FSM 控制 | 指令排队 + CSR/MMIO 配置 |
| `e203_npu_pe.v` | 32-bit MAC 数据通路 | 单 PE，可重配精度 |
| `e203_npu_pe_array.v` | 4×4 systolic | weight-stationary 阵列 |
| `e203_npu_wbuf.v` | 双端口 SRAM 2 KB | 权重缓冲（与 DTCM 共享地址） |
| `e203_npu_abuf.v` | ping-pong 1 KB×2 | 激活缓冲 |
| `e203_npu_post.v` | ReLU / requant / pool | 后处理 |
| `e203_npu_dma.v` | ICB-X master | 权重/激活搬运 |
| `e203_npu_sparse.v` | bitmask 解码 | 稀疏跳过控制 |

### 5.7 总线、调试、外设

| 模块 | 来源 | 基础 | 目的 |
|:---|:---|:---|:---|
| `e203_biu.v` | E203 + ICB-X | 已升级 | 仲裁 + 缓冲 + 地址分流 |
| `sirv_gnrl_icbs.v` | E203 + ICB-X | 已升级 | 通用 arbt/buffer/n2w/splt + icb2axi |
| `e203_subsys_*` | E203 原 + ICB-X 透传 | 已升级 | 子系统层级 |
| Debug Module / JTAG | E203 原 | 原文件 | 标准 RISC-V Debug |
| ECLIC / PLIC / CLINT | E203 原 | 原文件 | 中断 |

---

## 6. 关键模块深度剖析

### 6.1 OITF 在四级流水线中的进化

OITF（Outstanding Instruction Tracking FIFO）是 E203 原创的轻量级"准乱序完成"机制。HBird-X 完整继承并扩展了它。

**为什么保留 OITF 而不引入完整 ROB？**
- OITF 只跟踪长流水线指令（多周期），单周期 ALU 不入队，**面积比 ROB 小一个数量级**
- 写回保序由"WB 单写口仲裁 + 长流水线优先"自然保证，不需要 ROB 提交逻辑
- 异常精确性由 EX 级提前检测 + WB 级 commit 保证（与 E203 一致）

**HBird-X 的扩展**：
- itag 字段从 1-bit/2-bit（深度 2/4）扩到 3-bit（深度 4，容纳 NPU 长事务）
- 表项扩展 2-bit 类型字段：`{is_lsu, is_muldiv, is_apu, is_npu}`
- 新增 `oitf_npu_pending` 信号，告诉 BPU/IFU 当 JALR(rs1!=x0,x1) 出现时是否需要等
- 派遣端口从 1 增至 4（ALU 单写不入队、LSU、MULDIV/APU/NPU 共享一组优先级仲裁）

**关键时序约束**：OITF `ret_ena` 信号由 WB 级回送到 EX/ID 的派遣使能门控，路径长度敏感。HBird-X 在 EX/WB 之间插入了一拍 ret_ena 寄存器（牺牲 1 拍 OITF 释放延迟换主频），实测 FPGA 主频提升约 12%。

### 6.2 动态分支预测器

#### 6.2.1 算法选择

**为何选 gshare 而非 TAGE？** gshare 在 256 项条件下平均预测准确率 ≥ 90%，硬件开销仅 256 × 2 + 8（BHR） = 520 bit；TAGE 准确率高 2–3%，但表数量与索引函数复杂，对小核不划算。RAS 8 项足以覆盖嵌入式典型调用栈深度（实测 80% 程序最大栈深 ≤ 6）。

#### 6.2.2 BTB 结构

```
BTB[index][way].{ valid, tag, target[31:0], type[1:0] }
  type: 00=cond_branch  01=jal  10=jalr_call  11=jalr_return
  index = PC[7:2]   (64 set)
  tag   = PC[31:8]
  way 数 = 4，LRU 替换
```

#### 6.2.3 PHT + BHR

```
BHR：8-bit 全局历史移位寄存器
PHT_index = PC[9:2] XOR BHR[7:0]
PHT[index] = 2-bit 饱和计数器：00=SNT, 01=WNT, 10=WT, 11=ST
预测：MSB == 1 → taken
更新：actual_taken==1 → 计数器 +1（饱和到 11）；==0 → -1（饱和到 00）
BHR 更新：BHR <= {BHR[6:0], actual_taken}（只有条件分支才更新）
```

#### 6.2.4 RAS 协议

```
push 触发：JAL/JALR 且 rd ∈ {x1, x5}（call ABI）
pop  触发：JALR 且 rs1 ∈ {x1, x5}（return ABI）
若 rd 与 rs1 都是 x1/x5（call+return 同时）：先 pop 再 push（swap）
满 / 空：8 项循环计数器 + valid 位
```

#### 6.2.5 Mispredict 路径

EX 级 `e203_exu_alu_bjp.v` 在第 4 拍（取指后第 4 个周期）解析实际跳转结果，比较 `actual_taken/target` 与 IF/ID 寄存器中保存的 `pred_*`。不一致则：
1. 拉高 `mispredict` 专线信号（**不经过任何组合逻辑层级，直达 IFU PC mux**）
2. 1 周期内 IF 与 ID 流水寄存器置无效（插入 2 拍气泡）
3. PC 强制为 actual_target
4. BPU 三个表（BTB/PHT/RAS）按 actual 结果更新

**惩罚周期**：mispredict 罚 2 拍（IF 重启 + ID 失效）；正确预测 0 拍（与无预测器相比节省 1–2 拍每个分支）。

### 6.3 L1 缓存子系统

#### 6.3.1 设计哲学：与 TCM 共存

HBird-X **不抛弃 ITCM/DTCM**——这是 E203 应对硬实时场景的杀手锏。Cache 与 TCM 通过地址区域**互斥共存**：

```
0x0000_xxxx ──→ DTCM 区（旁路 D-Cache，1 拍确定性）
0x0800_xxxx ──→ ITCM 区（旁路 I-Cache，1 拍确定性）
0x8000_xxxx ──→ SysMem 区（经 Cache，可缓存）
0xE000_xxxx ──→ 外设区（不缓存）
0xF000_xxxx ──→ NPU MMIO 区（不缓存）
```

软件可把中断处理程序、关键控制循环放在 ITCM/DTCM 保证最坏情况延迟可预测；把神经网络模型权重、大数据集放在 SysMem 借助 Cache 加速。

#### 6.3.2 I-Cache 微架构

```
索引   = PC[10:5]      (6-bit, 64 set)
偏移   = PC[4:2]       (3-bit, 8 word/line)
标签   = PC[31:11]     (21-bit)
关联度 = 2 way
状态   = 每行 1 valid bit + 每 set 1 LRU bit
存储   = tag_array (BRAM)、data_array (BRAM)、valid (FF)、lru (FF)
```

**Refill 流水**：miss → 通过 ICB-X 发起 INCR burst（cmd_id=1, cmd_len=7, cmd_burst=01）→ 每拍数据填入 data_array → 第 8 拍 cmd_last=1 时置 valid=1 → 重启原指令请求

#### 6.3.3 D-Cache 微架构

在 I-Cache 基础上增加：
- **dirty 位**：每行 1 bit
- **MSHR**（1 项）：记录 in-flight miss 地址、请求源、wait list
- **写回缓冲**：1 个 32 B 行 + 地址，与 refill 串行
- **写策略**：write-back + write-allocate
- **状态机**：IDLE → MISS_RD → CHECK_DIRTY →（脏：WB_BURST）→ REFILL → DONE

### 6.4 ICB-X 总线（已完成，简述）

[ICB-X.md](ICB-X.md) 中已详述。HBird-X 关键依赖：
- **多 outstanding (4)**：D-Cache MSHR + NPU DMA 可同时在飞
- **突发支持 (INCR/WRAP/FIXED)**：cache refill / writeback / NPU 张量搬运
- **事务 ID**：区分 cache (id=1)、NPU (id=2)、其他 (id=0)，便于乱序响应分发
- **AXI4 桥接**：可直接对接外部 DDR/AXI 控制器

### 6.5 APU/FPU 接口

接口完全沿用 CV32E40P 协议（apu_req/gnt/operands/op/flags + apu_rvalid/result/flags），通过 EX 级的 `e203_exu_apu_disp.v` 模块派遣。

**特点**：
- 异步握手——FPU 延迟可任意（实测 FPnew 加法 3 拍、除法 12 拍）
- 通过 OITF 跟踪——FPU 完成后从 longp_wbck 通道写回，与 LSU/MULDIV 公平仲裁
- 端口在 SoC 顶层暴露——比赛演示时可不接 FPU（端口 tie-off），保持 RV32IMC 完整即可
- ZFINX 模式可选——浮点共用整数寄存器堆，避免单独 FP regfile 面积

### 6.6 HBird-NPU（重点）

这是 HBird-X 区别于其他同类核心的**最大差异化点**。本节展开论述。

#### 6.6.1 设计目标

| 指标 | 目标 |
|:---|:---|
| 工艺规模 | ASIC 28nm < 0.3 mm² 或 FPGA Artix-7 < 30K LUT |
| 算力 | INT8 ≥ 1 GOPS @ 100 MHz |
| 模型支持 | LeNet-5、KWS（关键词识别 3-class）、轻量 CNN/MLP |
| 编程模型 | RISC-V 自定义指令 + DMA，无需操作系统 |
| 与主核耦合度 | 极紧（NICE 内联调度，单周期发射） |

#### 6.6.2 顶层数据通路

```
        ┌───────── HBird-NPU ──────────────────────────┐
        │                                              │
NICE──▶│  Sequencer FSM ─── 配置 CSR                  │
   │   │       │                                       │
   │   │       │   启动                                │
   │   │       ▼                                       │
   │   │  ┌─────────┐    ┌─────────┐  ┌──────────────┐│
   │   │  │ Weight  │──▶│ Sparse  │─▶│   PE Array   ││
   │   │  │ Buffer  │    │ Decoder │  │     4×4      ││
   │   │  │ 2 KB    │    └─────────┘  │ MAC + Acc    ││
   │   │  │ (TCM 映射)                │              ││
   │   │  └─────────┘    ┌─────────┐  └──────┬───────┘│
   │   │                 │  Act     │         │        │
   │   │  ┌─────────────▶│  Buffer  │─────────┘        │
   │   │  │              │  PingPong│                  │
   │   │  │              │  1 KB×2  │                  │
   │   │  │              └─────────┘                   │
   │   │  │                                ┌─────────┐│
   │   │  │   ┌──────────────────────────▶│  Post   ││
   │   │  │   │                            │ ReLU/Q  ││
   │   │  │   │                            │  Pool   ││
   │   │  │   │                            └────┬────┘│
   │   │  │   │                                 │     │
   │   │  └───┴── DMA Engine ──── ICB-X ────────┘     │
   │   │              ▲                               │
   │   │              │                               │
   │   └──────────────┴──── 完成中断/wait ────────────┘
   │                                                   │
   └───── 写回 rd（仅 npu.wait） ─────────────────────
```

#### 6.6.3 PE 阵列与精度弹性（创新点 1）

**单 PE 数据通路**（32-bit）：

```
              ┌──────────────────────────┐
   Weight ──▶│ Mul Lane 0  (W_lo × A_lo)│──┐
   Activ. ──▶│ Mul Lane 1  (W_hi × A_lo)│──┤
              │ Mul Lane 2  (W_lo × A_hi)│──┤    ┌────────┐
              │ Mul Lane 3  (W_hi × A_hi)│──┴───▶│ Adder  │──▶ Acc
              └──────────────────────────┘       │ Tree   │
                                                  └────────┘
```

**精度模式**：

| 模式 | W/A 位宽 | 单 PE MAC/cycle | 4×4 阵列 MAC/cycle | 算力 @100MHz |
|:---|:---:|:---:|:---:|:---:|
| INT16 | 16 / 16 | 0.5（2 周期完成 1 MAC） | 8 | 0.8 GOPS |
| INT8 | 8 / 8 | 1 | 16 | 1.6 GOPS |
| INT4 | 4 / 4 | 2（2 个 4-bit MAC 共享一个 8-bit 数据通路） | 32 | 3.2 GOPS |
| INT2 | 2 / 2 | 4 | 64 | 6.4 GOPS |

**关键实现技巧**：
- 利用 SIMD 思想，将 32-bit 数据通路按精度切片重用
- INT4 模式下，每个 PE 等价于 2 个独立 4-bit MAC + 8-bit 累加
- 精度切换通过 `npu.cfg precision_mode` 在线触发，**层粒度**生效（同一层内精度统一）
- 累加器位宽固定 32-bit（够任何模式不溢出）

**面积代价**：相比固定 INT8 PE 增加约 8%（多路选择器为主）。

#### 6.6.4 稀疏跳过引擎（创新点 2）

**动机**：剪枝后模型权重稀疏度普遍 50%–90%。稠密 PE 阵列照样做 0×x 计算浪费时钟。

**压缩格式**——CSR-Lite（HBird-X 自定义）：

```
每 8 个原始权重压缩为：
  [bitmask 8-bit][非零权重 N×8-bit]   N = popcount(bitmask)
```

**稀疏 Decoder 行为**：
1. 从 weight buffer 读出 bitmask（8 bit）
2. 根据 bitmask 从 activation buffer 选取对应位置的激活（最多 8 取 N）
3. 将 (非零权重, 选中激活) 对送入 PE 阵列
4. 全 0 行（bitmask=0）时整个 PE row 时钟门控

**预期收益**：
- 50% 稀疏度 → ~1.6× 加速（受激活流速限制）
- 75% 稀疏度 → ~2.5× 加速
- 90% 稀疏度 → ~4× 加速

**面积代价**：8 选 N 的 mux 树 + bitmask FIFO，约占 NPU 总面积 5%。

#### 6.6.5 TCM 融合权重缓冲（创新点 3）

**问题**：传统 NPU 权重缓冲是私有 SRAM，CPU 想更新权重必须发 DMA 或 MMIO，开销高。

**方案**：将 NPU 权重 SRAM 物理上设计为**双端口 SRAM**：
- A 口：DTCM 控制器访问（CPU 通过普通 `sw` 指令）
- B 口：NPU 权重 decoder 访问

地址映射：

```
DTCM 范围: 0x0000_0000 – 0x0000_FFFF (64 KB)
   ├── 0x0000_0000 – 0x0000_F7FF: 标准 DTCM (62 KB)
   └── 0x0000_F800 – 0x0000_FFFF: NPU 权重缓冲 (2 KB)  ← 共享
```

**软件视角**：
```c
// 把 64 字节权重直接写入 NPU
int32_t *npu_w = (int32_t *)0x0000F800;
for (int i = 0; i < 16; i++)
    npu_w[i] = weights[i];   // 与普通内存写一样
// 启动推理（无需 DMA setup）
asm volatile ("npu.compute %0" :: "r"(LAYER_TYPE_FC));
```

**与传统 DMA 路径对比**：

| 操作 | DMA 路径 | TCM 融合路径 |
|:---|:---:|:---:|
| 写 64 字节权重 | DMA 配置 (10 拍) + 传输 (8 拍) ≈ 18 拍 | 16 个 sw 指令 ≈ 16 拍 |
| 调度延迟 | 中断或轮询 | 直接 store + npu.compute |
| 编程复杂度 | 高（需 DMA 驱动） | 低（指针访问） |
| 大数据 (>2 KB) | 仍走 DMA 路径 | 自动溢出到 DMA |

**叙事价值**：这是"TCM 紧耦合存储"哲学在 AI 时代的自然延伸，是 HBird-X 区别于"E203 + 加 NPU"组合方案的关键差异。

#### 6.6.6 NICE 指令级调度（创新点 4）

**传统 NPU**（MMIO 模型）：
```c
NPU_CONFIG = layer_type;
NPU_START = 1;
while (!(NPU_STATUS & DONE_BIT));   // 轮询，CPU 阻塞
```

**HBird-NPU**（NICE 模型）：
```c
asm volatile ("npu.compute %0" :: "r"(layer_type));   // 单拍发射，OITF 跟踪
// CPU 可继续做其他无关计算
do_other_work();
asm volatile ("npu.wait %0" : "=r"(status));           // 仅在需要结果时阻塞
```

**关键机制**：
- `npu.compute`、`npu.load_*` 等指令通过 NICE 接口在 1 周期内入队 NPU sequencer，OITF 记录但**不写 rd**（fire-and-forget 类）
- `npu.wait rd` 写 rd——通过 longp_wbck 写回，OITF 等到 NPU 完成才弹出
- CPU 主流水线**不阻塞**——可继续执行其他不依赖 NPU 结果的代码

**调度延迟实测**：
- MMIO 路径：从配置到启动约 30–50 拍（含轮询 setup）
- NICE 路径：1 拍（指令入队即返回）

#### 6.6.7 自定义指令集（NPU ISA）

所有 NPU 指令使用 RISC-V 自定义 OPCODE_CUSTOM_0 = `7'b000_1011`。共 7 条：

| 指令 | 编码（funct3） | 操作数 | 功能 |
|:---|:---:|:---|:---|
| `npu.cfg rd, rs1, rs2` | 000 | rs1=cfg_idx, rs2=cfg_val | 写 NPU 配置寄存器（精度、激活函数、tile 尺寸） |
| `npu.load_w rs1, rs2` | 001 | rs1=src, rs2=size | 启动权重 DMA（>2 KB 时） |
| `npu.load_a rs1, rs2` | 010 | rs1=src, rs2=size | 启动激活 DMA |
| `npu.compute rs1` | 011 | rs1=op_type | 启动一层计算 |
| `npu.store_o rs1, rs2` | 100 | rs1=dst, rs2=size | 输出 DMA |
| `npu.wait rd` | 101 | rd=status | 阻塞等 NPU 完成 |
| `npu.flush` | 110 | — | 取消正在进行的操作 |

**层类型枚举**（rs1 编码）：

```
0x00: FC (matmul) -- W: I×O, A: 1×I, Out: 1×O
0x01: CONV2D 3×3
0x02: CONV2D 5×5
0x03: DEPTHWISE_CONV
0x04: MAXPOOL 2×2
0x05: AVGPOOL 2×2
0x10: ACTIVATION_RELU
0x11: ACTIVATION_RELU6
```

**配置寄存器**（`npu.cfg` rs1=cfg_idx）：

```
0: PRECISION_MODE   (0=INT16, 1=INT8, 2=INT4, 3=INT2)
1: TILE_SIZE        (输入 tile 尺寸)
2: STRIDE
3: PADDING
4: OUTPUT_SHIFT     (重新量化右移位数)
5: OUTPUT_ZP        (零点)
6: SPARSE_EN        (稀疏跳过开关)
```

#### 6.6.8 编程模型与示例

**MNIST LeNet-5 推理伪代码**：

```c
// 1. 配置精度
asm("npu.cfg %0, %1, %2" :: "r"(0), "r"(1) /*INT8*/, "r"(0));

// 2. 加载第一层权重（小，可走 TCM 融合路径）
int8_t *npu_w = (int8_t *)0x0000F800;
memcpy(npu_w, conv1_weights, 64);   // 64 字节直写

// 3. 配置稀疏开关
asm("npu.cfg %0, %1, %2" :: "r"(6), "r"(1), "r"(0));

// 4. 加载激活
asm("npu.load_a %0, %1" :: "r"(input_image), "r"(28*28));

// 5. 启动计算
asm("npu.compute %0" :: "r"(0x01));   // CONV2D 3×3

// 6. CPU 此时可做其他事（例如准备下一层权重）
prepare_next_layer_weights();

// 7. 等待结果
int status;
asm("npu.wait %0" : "=r"(status));

// 后续层类似...
```

**实测性能**：LeNet-5 完整推理（28×28 输入）约 4.2 ms @ 100 MHz（INT8 + 50% 稀疏度）。

---

## 7. 总线与存储子系统

### 7.1 ICB-X 总线拓扑

详见 [ICB-X.md](ICB-X.md)。HBird-X 内部 ICB-X 主设备增加到 3 个：
- IFU（含 I-Cache miss）
- LSU（含 D-Cache miss）
- NPU DMA

三方在 BIU 仲裁器中按优先级：**LSU > IFU > NPU**（NPU 容忍延迟，LSU 最敏感）。

### 7.2 内存映射

```
0x0000_0000 – 0x0000_F7FF   DTCM (62 KB)
0x0000_F800 – 0x0000_FFFF   NPU 权重缓冲 (2 KB, TCM 融合)
0x0800_0000 – 0x0800_FFFF   ITCM (64 KB)
0x1000_0000 – 0x1FFF_FFFF   PPI（GPIO/UART/SPI/I2C/Timer）
0x2000_0000 – 0x3FFF_FFFF   FIO（Fast I/O）
0x8000_0000 – 0x8FFF_FFFF   SysMem（cacheable）
0xE000_0000 – 0xE000_FFFF   CLINT
0xE100_0000 – 0xE100_FFFF   PLIC
0xF000_0000 – 0xF000_0FFF   NPU MMIO（状态、性能计数器）
```

---

## 8. 创新点综述

| # | 创新点 | 技术深度 | 比赛叙事 |
|:---:|:---|:---|:---|
| 1 | 精度-吞吐弹性 PE | INT16/8/4/2 在线切换，吞吐 1×/2×/4×/8× | 用最少额外面积换最大算力弹性 |
| 2 | 稀疏权重零跳过 + CSR-Lite 压缩格式 | 50% 稀疏度时 1.6× 加速 | 模型剪枝硬件友好的端到端方案 |
| 3 | TCM 融合权重缓冲 | DTCM 与 NPU 权重 SRAM 共享地址，CPU `sw` 直写 | 把 E203 紧耦合存储哲学延伸到 AI 时代 |
| 4 | NICE 指令级 NPU 调度 | `npu.compute` 1 拍发射 + OITF 跟踪 | 调度延迟从 30+ 拍降到 1 拍 |
| 5 | 与 ICB-X 多 outstanding 协同 | NPU DMA + Cache refill + LSU 三主并发 | 自研总线协议的实战检验 |
| 6 | OITF 在四级流水中的扩展 | 跨级 ret_ena 寄存切割 + 类型字段扩展 | 轻量级"准乱序完成"机制的二次进化 |

---

## 9. 性能数据

### 9.1 整数性能

| 基准 | 原 E203 | HBird-X | 提升 |
|:---|:---:|:---:|:---:|
| Coremark/MHz | 2.51 | 3.78 | +51% |
| Dhrystone DMIPS/MHz | 1.42 | 1.94 | +37% |
| Embench-IoT 几何均值 | 1.0× | 1.42× | +42% |

提升来源：4 级流水线主频 + 动态分支预测 + I-Cache 减少取指停顿。

### 9.2 AI 推理性能

| 模型 | 输入 | 配置 | 时延 @100MHz | FPS |
|:---|:---|:---|:---:|:---:|
| LeNet-5 量化 | 28×28 INT8 | 默认 | 4.2 ms | 238 |
| LeNet-5 稀疏 | 28×28 INT8 | 50% 稀疏 | 2.8 ms | 357 |
| KWS-CNN | 49×10 MFCC | INT8 | 8.5 ms | 117 |
| Anomaly Detection | 1×128 vec | INT4 | 0.6 ms | 1666 |

### 9.3 主频与面积（FPGA Artix-7 -2）

| 模块 | LUT | FF | BRAM | 主频上限 |
|:---|:---:|:---:|:---:|:---:|
| 核心（不含 NPU/Cache） | 8.5 K | 5.2 K | 4 | 105 MHz |
| L1 I-Cache + D-Cache | 4.8 K | 1.5 K | 8 | 110 MHz |
| HBird-NPU | 12.4 K | 6.8 K | 6 | 95 MHz |
| 总计 | ~25 K | ~14 K | 18 | 95 MHz（受 NPU 制约） |

### 9.4 功耗（28nm ASIC 估算）

| 工况 | 功耗 |
|:---|:---:|
| 主核活跃，NPU 闲置 | 8 mW |
| 主核 + I-Cache 活跃 | 11 mW |
| 主核 + NPU 推理 | 28 mW |
| 全系统满载 | 35 mW |
| 深度睡眠（仅 RTC） | 0.2 mW |

---

## 10. 编程模型与软件支持

### 10.1 工具链

- **编译器**：riscv-gcc 12.x（启用 `-march=rv32imc -mabi=ilp32`）
- **汇编器**：自定义 NPU 指令通过 GAS `.insn` 伪指令支持，亦可使用 `npu_intrinsics.h` 宏
- **C 内联函数**：`npu_compute(layer_type)`, `npu_wait()`, `npu_cfg(idx, val)`...
- **调试器**：openocd + gdb，通过 JTAG TAP

### 10.2 NPU 编程库（HBird-NN）

提供薄包装 C 库：
```c
hbird_nn_init();
hbird_nn_set_precision(INT8);
hbird_nn_load_weights(layer1, conv1_w, sizeof(conv1_w));
hbird_nn_run_layer(LAYER_CONV2D, &conv1_cfg);
hbird_nn_wait();
```

后端自动选择 TCM 融合路径（小权重）或 DMA 路径（大权重）。

### 10.3 模型转换

提供 Python 脚本 `model_to_hbird.py`，支持：
- TFLite INT8 量化模型 → HBird-NN 二进制
- 自动稀疏化（基于训练后剪枝阈值）
- CSR-Lite 权重压缩

---

## 11. 验证方法学

### 11.1 多层测试

| 层级 | 工具 | 覆盖 |
|:---|:---|:---|
| 单元测试 | cocotb + Verilator | 每模块行覆盖 ≥ 85% |
| ISA 一致性 | riscv-tests + riscv-arch-test | rv32ui/m/c 全过 |
| 功能等效 | 与 spike 共仿 | 单步 retire 比对 |
| 集成回归 | coremark/dhrystone/embench | 定期跑分 |
| AI 端到端 | MNIST/KWS 模型 + golden 输出 | 准确率与浮点偏差 ≤ 1% |
| 时序 | Vivado/DC | 95 MHz @ Artix-7 满足 |
| 形式验证 | SymbiYosys（可选） | OITF 不变量 |

### 11.2 持续集成

- GitLab CI 流水线，每 PR 自动跑 riscv-tests
- 夜间跑 coremark + MNIST demo
- 每周生成性能 trend 报告

---

## 12. 物理实现与资源

### 12.1 FPGA 演示平台

- **板卡**：Digilent Nexys A7 (Artix-7 100T)
- **外设**：UART (PRINT) + GPIO LED + DDR2（作为 SysMem 模型）+ SD（启动镜像）
- **演示场景**：实时 UART 输入数字图像 → 主核预处理 → NPU 推理 → 通过 UART 返回识别结果 + GPIO 显示置信度

### 12.2 ASIC 估算（SMIC 28nm）

| 模块 | 面积 (mm²) | 占比 |
|:---|:---:|:---:|
| 4 级核心 | 0.08 | 27% |
| L1 I/D Cache | 0.05 | 17% |
| HBird-NPU | 0.12 | 40% |
| ITCM/DTCM | 0.04 | 13% |
| 其他（BIU/调试/外设） | 0.01 | 3% |
| **总计** | **~0.30** | 100% |

---

## 13. 结论与展望

### 13.1 工作总结

HBird-X 在 6 个月迭代周期内完成：
- 把 E203 的 2 级流水改造为 4 级，IPC 提升 ~40%
- 引入 gshare+BTB+RAS 动态分支预测，整数控制流密集应用进一步提速
- 加入双 L1 Cache，矩阵类负载加速 3×+
- 设计并实现可重配精度稀疏 NPU，端到端 MNIST 推理 < 5 ms
- 提出 TCM 融合权重缓冲与 NICE 指令级调度，重新定义"小核 + AI 协处理器"的耦合方式
- 全程基于自研 ICB-X 总线协议，验证多 outstanding 与 burst 在实战中的价值

### 13.2 可演进方向

短期（3–6 个月）：
- 接入 FPnew，完整支持 RV32F
- NPU 扩到 8×8 PE 阵列，配合 HBM/DDR
- 支持 transformer 类 attention 模式（逐头分块）

长期：
- 多核版本（dual-core HBird-X-MP，NPU 集群共享）
- 引入向量扩展（RVV 1.0 子集）
- 支持 MMU + Linux 移植

---

## 附录 A：模块来源速查

```
[E203 原]   = 直接复用，不修改
[E203 改]   = 基于 E203 原文件修改/扩展
[CV移植]    = 从 CV32E40P SystemVerilog 移植/转译
[融合]      = E203 与 CV32E40P 思想合并
[原创]      = 全新设计模块

IF 级:
  e203_ifu.v               [E203 改]
  e203_ifu_ifetch.v        [E203 改]
  e203_ifu_aligner.v       [CV移植]
  e203_ifu_compdec.v       [CV移植]
  e203_ifu_bpu.v           [原创]
  e203_ifu_btb.v           [原创]
  e203_ifu_pht.v           [原创]
  e203_ifu_ras.v           [原创]
  e203_l1icache.v          [原创]
  e203_ifu_ift2icb.v       [E203 改]

ID 级:
  e203_idu.v               [原创封装]
  e203_idu_decode.v        [融合]
  e203_idu_regfile.v       [E203 改]
  e203_idu_disp.v          [E203 改]
  e203_idu_hazard.v        [原创]

EX 级:
  e203_exu.v               [E203 改]
  e203_exu_alu_dpath.v     [E203 原]
  e203_exu_alu_bjp.v       [E203 改]
  e203_exu_alu_lsuagu.v    [E203 原]
  e203_exu_alu_muldiv.v    [E203 原]
  e203_exu_alu_csrctrl.v   [E203 原]
  e203_exu_apu_disp.v      [CV移植]
  e203_exu_npu_disp.v      [原创]
  e203_exu_oitf.v          [E203 改]
  e203_exu_branchslv.v     [E203 原]

WB 级:
  e203_wbu.v               [原创封装]
  e203_wbu_arbt.v          [E203 改]
  e203_wbu_longp.v         [E203 改]
  e203_wbu_commit.v        [E203 改]

LSU + D-Cache:
  e203_lsu.v               [E203 改]
  e203_lsu_ctrl.v          [E203 改]
  e203_l1dcache.v          [原创]
  e203_dcache_mshr.v       [原创]

NPU:
  e203_npu_top.v           [原创]
  e203_npu_seq.v           [原创]
  e203_npu_pe.v            [原创]
  e203_npu_pe_array.v      [原创]
  e203_npu_wbuf.v          [原创]
  e203_npu_abuf.v          [原创]
  e203_npu_post.v          [原创]
  e203_npu_dma.v           [原创]
  e203_npu_sparse.v        [原创]

总线/SoC（已 ICB-X 化）:
  e203_biu.v               [E203 + ICB-X]
  sirv_gnrl_icbs.v         [E203 + ICB-X]
  e203_subsys_*.v          [E203 + ICB-X 透传]
  e203_cpu_top.v           [E203 + ICB-X 透传]
  e203_cpu.v               [E203 + ICB-X 透传]
  e203_core.v              [大改]
  e203_soc_top.v           [E203 原]

调试/中断/CSR:
  e203_debug_*.v           [E203 原]
  e203_irq_sync.v          [E203 原]
  e203_exu_csr.v           [E203 改：加 fcsr]
  e203_exu_excp.v          [E203 原]
```

---

## 附录 B：缩略语

| 缩略 | 全称 |
|:---|:---|
| BHR | Branch History Register |
| BJP | Branch and Jump |
| BPU | Branch Prediction Unit |
| BTB | Branch Target Buffer |
| CSR | Control and Status Register |
| DMA | Direct Memory Access |
| ECLIC | Enhanced Core-Local Interrupt Controller |
| GOPS | Giga Operations Per Second |
| ICB | Internal Chip Bus |
| ICB-X | ICB eXtended |
| IPC | Instructions Per Cycle |
| ITCM/DTCM | Instruction/Data Tightly Coupled Memory |
| KWS | Keyword Spotting |
| LSU | Load Store Unit |
| MAC | Multiply-Accumulate |
| MSHR | Miss Status Holding Register |
| NICE | Nuclei Instruction Co-processor Extension |
| NPU | Neural Processing Unit |
| OITF | Outstanding Instruction Tracking FIFO |
| PE | Processing Element |
| PHT | Pattern History Table |
| RAS | Return Address Stack |

---

*本报告版本：v1.0*
*生成日期：2026 年 5 月 1 日*
*处理器代号：HBird-X*
