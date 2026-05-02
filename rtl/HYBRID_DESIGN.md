# E203 × CV32E40P 深度融合处理器（含 AI 加速器）设计报告

> **目标定位**：以蜂鸟 E203 为基础骨架，融合 CV32E40P（RI5CY）的四级流水架构、动态分支预测与 APU 浮点接口，并内嵌可重配置 AI 加速器，形成一颗在有限面积/功耗下兼具控制效率与神经网络推理算力的 RV32IMC(F) 核，目标为 RISC-V 比赛。
>
> **代号建议**：`HBird-X`（Hybrid Bird with X-tensions）
>
> **相关文档**：[ICB-X 总线改造报告](ICB-X.md)（已完成）

---

## 目录

1. [可行性总评估](#1-可行性总评估)
2. [目标处理器顶层架构](#2-目标处理器顶层架构)
3. [Phase 1：流水线骨架重构（2 级 → 4 级）](#3-phase-1流水线骨架重构2-级--4-级)
4. [Phase 2：动态分支预测器升级](#4-phase-2动态分支预测器升级)
5. [Phase 3：L1 I-Cache 与 D-Cache](#5-phase-3l1-i-cache-与-d-cache)
6. [Phase 4：APU/FPU 外挂接口移植](#6-phase-4apufpu-外挂接口移植)
7. [Phase 5：AI 加速器（HBird-NPU）](#7-phase-5ai-加速器hbird-npu)
8. [Phase 6：集成验证与基准测试](#8-phase-6集成验证与基准测试)
9. [AI 加速器创新点](#9-ai-加速器创新点)
10. [风险、备选与里程碑](#10-风险备选与里程碑)

---

## 1. 可行性总评估

### 1.1 总体结论

**可行**。但属于**重度改造**而非简单融合，工作量约相当于一个准全新的核（保留 E203 IFU 取指接口、CSR/异常框架、ICB-X 总线、NICE 接口，改写 EXU 流水线）。各项需求拆解后的可行性如下：

| # | 需求 | 可行性 | 主要难点 |
|:---:|:---|:---:|:---|
| 1 | 保留 ICB-X 总线 | ★★★★★ | 已完成；缓存 refill/wb 的 burst 编码已就绪 |
| 2 | CV32E40P 4 级流水 | ★★★★ | E203 EXU 一体化，须切成 ID/EX/WB 三级；OITF 需重定位 |
| 3 | 动态分支预测 | ★★★★★ | 算法成熟（gshare + BTB + RAS）；难在 mispredict flush 时序 |
| 4 | L1 Cache | ★★★ | I/D 双 Cache + MSHR + 替换策略；与 TCM 共存的地址解码需小心 |
| 5 | FPU 外挂（APU） | ★★★★★ | 直接复用 CV32E40P 的 apu_disp，APU 完成走 OITF |
| 6 | E203 为基础 | ★★★★★ | 顶层层级、SoC 子系统、外设、调试模块全部继承 |
| 7 | AI 加速器 | ★★★★ | 内部架构自由度大；难在数据通路与精度选择上做出比赛亮点 |

**总评**：6 大可行（≥4★），1 大需要谨慎（L1 Cache 3★）。在 6–9 个月小团队周期内可达竞赛流片/上 FPGA 演示水平。

### 1.2 风险矩阵

| 风险 | 严重度 | 概率 | 缓解措施 |
|:---|:---:|:---:|:---|
| **流水线切分破坏 OITF 语义** | 高 | 中 | Phase 1 完成后必须跑通 riscv-tests 全集再继续 |
| **D-Cache 与 DTCM 混合地址映射 bug** | 高 | 中 | 严格按地址 region 解码，保留 TCM 区段；先 I-Cache 后 D-Cache 分两步落地 |
| **BPU 误预测恢复信号过深路径** | 中 | 高 | mispredict 信号专用线网，避免穿过 OITF |
| **AI 加速器 timing closure** | 中 | 中 | PE 阵列规模 ≤ 8×8，对外异步 handshake，与主核解耦 |
| **APU + OITF 协同时寄存器堆写口竞争** | 中 | 中 | 写口仲裁优先级：FPU < LSU < ALU；冲突时 stall ID |
| **总验证工作爆炸** | 高 | 高 | 每 Phase 强制回归门禁；CI 自动化 ISA 测试 |

### 1.3 时间估算（按 2–3 人小团队、每周 ~20 工时）

| 阶段 | 工作量 | 累计 |
|:---|:---:|:---:|
| Phase 0：环境准备 + 基线回归 | 2 周 | 2 |
| Phase 1：流水线骨架重构 | 6 周 | 8 |
| Phase 2：动态分支预测 | 3 周 | 11 |
| Phase 3：L1 I-Cache + D-Cache | 6 周 | 17 |
| Phase 4：APU/FPU 移植 | 3 周 | 20 |
| Phase 5：AI 加速器 | 8 周 | 28 |
| Phase 6：集成验证 + 性能调优 | 持续 4 周 | 32 |

**合计 ≈ 32 周 ≈ 7.5 个月**。如比赛周期紧张，可取消 Phase 4（FPU），把 NPU 作为唯一亮点深耕。

### 1.4 边界明确

**做**：
- 4 级顺序流水线 + 完整前递/停顿 + 动态 BPU
- 双 L1 Cache（写回、写分配、单 MSHR）
- ICB-X 全程贯通到加速器与 Cache
- INT8/INT4 可重配 NPU + 稀疏性跳过 + NICE 指令调度
- M-mode 全套 + ECLIC + JTAG 调试

**不做**（出比赛规模）：
- 多核/多 hart
- 乱序发射/超标量
- MMU/虚拟内存/U-mode 完整 PMP
- L2 Cache、Coherence 协议
- Vector 扩展（V）

---

## 2. 目标处理器顶层架构

### 2.1 流水线视图

```
       ┌─────┐    ┌─────┐    ┌─────┐    ┌─────┐
       │ IF  │───▶│ ID  │───▶│ EX  │───▶│ WB  │
       └─────┘    └─────┘    └─────┘    └─────┘
          │          │          │          │
   ┌──────┴──┐  ┌────┴────┐  ┌──┴──┐   ┌───┴────┐
   │ I-Cache │  │ Decode  │  │ ALU │   │ Regfile│
   │ Aligner │  │ RegRead │  │ AGU │   │ Write  │
   │ Comp.Dec│  │ Hazard  │  │BJP  │   │  Mux   │
   │ BPU/BTB │  │ Forward │  │MULDIV│  └───┬────┘
   │  RAS    │  │  Issue  │  │ APU │      │
   └────┬────┘  └────┬────┘  │ NPU │   ┌──┴────────┐
        │            │       │ LSU │   │   OITF    │
        └────────────┼───────┴──┬──┘   │ longp_wbck│
                     │          │       └─────▲────┘
                     ▼          ▼             │
                 [Hazard]   [D-Cache]─────────┘
```

**关键设计点**：
- **OITF 保留**：横跨 EX/WB 的"长流水线池"，跟踪 LSU/MULDIV/APU/NPU 的多周期完成；配合 longp_wbck 与 ALU 单周期写回仲裁。
- **ID 是新增级**：从 E203 一体化 EXU 中拆出"解码 + 寄存器读 + 冒险/前递"逻辑，靠 ID/EX 流水寄存器分隔。
- **WB 是新增级**：原 E203 EXU 的 commit + wbck 仲裁向后挪一级，与 LSU 响应天然汇合。
- **BPU 在 IF**：反馈来自 EX（实际跳转结果），更新延迟 2 拍。
- **Cache 透明插入**：I-Cache 在 IFU 与 BIU 之间，D-Cache 在 LSU 与 BIU 之间；TCM 走旁路。

### 2.2 模块层级

```
e203_soc_top.v                 ← 不动
└── e203_subsys_top.v          ← 不动
    └── e203_subsys_main.v     ← 不动（ICB-X 已贯通）
        └── e203_cpu_top.v     ← 不动
            └── e203_cpu.v     ← 微调（接 BPU 信号、APU、NPU）
                └── e203_core.v  ← 内部子模块替换
                    ├── e203_ifu.v
                    │   ├── e203_ifu_ifetch.v        [改]增加 BPU 接入
                    │   ├── e203_ifu_bpu.v           [新]替换原 litebpu
                    │   ├── e203_ifu_btb.v           [新]
                    │   ├── e203_ifu_ras.v           [新]
                    │   ├── e203_ifu_aligner.v       [新]从 cv32e40p 移植
                    │   ├── e203_ifu_compdec.v       [改]扩展为完整压缩解码器
                    │   ├── e203_l1icache.v          [新]
                    │   └── e203_ifu_ift2icb.v       [改]Cache miss 走 ICB-X burst
                    ├── e203_idu.v                   [新]ID 级（原 EXU 解码部分）
                    │   ├── e203_idu_decode.v        [改自 e203_exu_decode]
                    │   ├── e203_idu_regfile.v       [改自 e203_exu_regfile + 加读口]
                    │   ├── e203_idu_hazard.v        [新]冒险检测 + 前递选择
                    │   └── e203_idu_disp.v          [改自 e203_exu_disp]
                    ├── e203_exu.v                   [大改]仅保留 EX 级计算
                    │   ├── e203_exu_alu_dpath.v     [保留]
                    │   ├── e203_exu_alu_bjp.v       [改]上报实际跳转给 BPU
                    │   ├── e203_exu_alu_lsuagu.v    [保留]
                    │   ├── e203_exu_alu_muldiv.v   [保留]
                    │   ├── e203_exu_alu_csrctrl.v  [保留]
                    │   ├── e203_exu_apu_disp.v     [新]从 cv32e40p_apu_disp 移植
                    │   ├── e203_exu_npu_disp.v     [新]NICE 风格的 NPU 接口
                    │   ├── e203_exu_oitf.v         [改]位宽扩展到容纳 APU/NPU
                    │   └── e203_exu_branchslv.v    [保留]
                    ├── e203_wbu.v                   [新]WB 级（原 wbck/commit）
                    │   ├── e203_wbu_arbt.v          [改自 e203_exu_wbck]
                    │   ├── e203_wbu_longp.v         [改自 e203_exu_longpwbck]
                    │   └── e203_wbu_commit.v        [改自 e203_exu_commit]
                    ├── e203_lsu.v
                    │   ├── e203_lsu_ctrl.v          [改]接 D-Cache
                    │   └── e203_l1dcache.v          [新]
                    ├── e203_npu_top.v               [新]AI 加速器顶层
                    │   ├── e203_npu_pe_array.v
                    │   ├── e203_npu_wbuf.v
                    │   ├── e203_npu_abuf.v
                    │   ├── e203_npu_seq.v
                    │   └── e203_npu_dma.v
                    └── e203_biu.v                   [不动]
```

### 2.3 总线/存储拓扑

```
            ┌─────────────────────────────┐
            │         e203_core           │
            │  ┌──────┐         ┌──────┐  │
            │  │ IFU  │────┬────│LSU/  │  │
            │  │+I$   │    │    │ +D$  │  │
            │  └──────┘    │    └──────┘  │
            │              ▼              │
            │         ┌────────┐          │
            │         │ NPU    │←─NICE──  │
            │         │ (DMA)  │          │
            │         └───┬────┘          │
            │             ▼               │
            │     ICB-X (id/len/burst)   │
            └─────────────│───────────────┘
                          ▼
                    ┌──────────┐
                    │   BIU    │ ← 已 ICB-X 化
                    └─┬─┬─┬─┬─┬┘
                      ▼ ▼ ▼ ▼ ▼
                   ITCM PPI CLINT PLIC SysMem
                   DTCM
```

**地址 region 分配建议**（保持 E203 风格）：
- `0x0000_0000–0x07FF_FFFF`：DTCM（旁路 D-Cache）
- `0x0800_0000–0x0FFF_FFFF`：ITCM（旁路 I-Cache）
- `0x1000_0000–0x1FFF_FFFF`：PPI（不缓存）
- `0x2000_0000–0x3FFF_FFFF`：FIO（不缓存）
- `0x8000_0000–`：SysMem（**经 D-Cache / I-Cache**）
- `0xE000_0000–`：CLINT/PLIC（不缓存）
- `0xF000_0000–`：NPU MMIO + AI 模型权重区（cacheable，可选 DMA 直通）

---

## 3. Phase 1：流水线骨架重构（2 级 → 4 级）

### 3.1 目标

把 E203 的 IFU + 一体化 EXU 改造为 IF / ID / EX / WB 四级流水。ID 与 WB 是新引入的级，EX 是原 EXU 计算部分的精简版。**OITF 保留**（依然在 EX 末尾入队、WB 出队），不替换为 ROB。

### 3.2 涉及文件

新增：
- `e203_idu.v`（ID 级顶层）
- `e203_idu_hazard.v`（冒险检测 + 前递选择）
- `e203_wbu.v`（WB 级顶层）

修改：
- `e203_core.v`（重新连线 + 新增流水寄存器）
- `e203_exu.v`（去掉 decode/disp/regfile，只剩 EX 计算）
- `e203_exu_decode.v` → 移到 `e203_idu_decode.v`（拆分点）
- `e203_exu_disp.v` → 移到 `e203_idu_disp.v`
- `e203_exu_regfile.v` → 移到 `e203_idu_regfile.v`，加 1 读口（4 级流水里 EX 转发回 ID 仍需读最新值）
- `e203_exu_wbck.v` → 移到 `e203_wbu_arbt.v`
- `e203_exu_longpwbck.v` → 移到 `e203_wbu_longp.v`
- `e203_exu_commit.v` → 移到 `e203_wbu_commit.v`
- `e203_exu_oitf.v`：itag 仍由 disp 分配（在 ID 级），但 ret_ena 来自 WB 级

### 3.3 流水寄存器定义（最小集合）

| 寄存器 | 字段 |
|:---|:---|
| `IF/ID` | `if2id_pc[31:0]`, `if2id_instr[31:0]`, `if2id_pred_taken`, `if2id_pred_target[31:0]`, `if2id_btb_hit`, `if2id_excp_buserr` |
| `ID/EX` | `id2ex_uop`（解码后微操作枚举）, `id2ex_rs1_data`, `id2ex_rs2_data`, `id2ex_imm`, `id2ex_rd_idx`, `id2ex_itag`, `id2ex_pc`, `id2ex_pred_*`, `id2ex_csr_idx`, `id2ex_excp` |
| `EX/WB` | `ex2wb_alu_result`, `ex2wb_rd_idx`, `ex2wb_itag`, `ex2wb_pc`, `ex2wb_excp`, `ex2wb_lsu_pending`, `ex2wb_op_type` |

每级 valid/ready 握手：上游 valid + 下游 ready ⇒ 流水推进；下游不 ready ⇒ 上游 stall。

### 3.4 冒险与前递

**4 级流水的核心痛点**：ID 级要读寄存器，但 EX 和 WB 里可能有刚写完还没回写的值。对策：

```verilog
// e203_idu_hazard.v 内核心逻辑
wire fwd_from_ex = (id_rs1_idx == ex2wb_rd_idx) & ex2wb_rd_we & ex2wb_alu_single;
wire fwd_from_wb = (id_rs1_idx == wb_rd_idx)    & wb_rd_we;
assign id_rs1_data_fwd = fwd_from_ex ? ex2wb_alu_result :
                          fwd_from_wb ? wb_data        :
                          regfile_rs1_data;
```

**load-use 冒险**：load 指令在 EX 阶段只发出 D-Cache 请求，结果在 WB 阶段才到。如果 ID 级紧跟着用这个寄存器，必须 stall 1 拍：

```verilog
wire load_use_haz = id_uses_rs1 & (id_rs1_idx == ex_load_rd_idx) & ex_is_load;
// stall ID, 插入 EX 气泡
```

**多周期冒险**（MULDIV/LSU/APU/NPU）：通过 OITF 跟踪——dispatch 时检查 rs1/rs2 是否在 OITF 中（写后读 RAW），有则 stall ID 直到 OITF 弹出对应表项。这一逻辑沿用 E203 原有 disp 模块的依赖检测，无需改动。

### 3.5 OITF 在 4 级流水中的语义重定义

**原 E203（2 级）**：OITF 入队时刻 = dispatch；出队时刻 = longp_wbck 写回。
**新 4 级**：OITF 入队时刻 = ID 级 dispatch（与原相同）；出队时刻 = **WB 级**仲裁通过。

`oitf_ret_ena` 信号的源从 `exu_oitfwbck` 改为 `wbu_longp_arbt`，注意控制依赖路径不能跨级反馈，否则会形成组合环。

### 3.6 实施步骤（建议子里程碑）

1. **Step 1.1**（2 周）：拆 EXU。把 decode/regfile/disp 物理上挪到 `e203_idu.v` 中，但**不**插入流水寄存器，先确认 RTL 仍能跑通原 e203 testbench（行为等效）。
2. **Step 1.2**（1 周）：插入 IF/ID 流水寄存器 + ID 级 valid/ready 握手 + 简单 bubble 注入。
3. **Step 1.3**（1.5 周）：插入 ID/EX 流水寄存器 + 实现前递逻辑（hazard.v）。
4. **Step 1.4**（1 周）：插入 EX/WB 流水寄存器 + 把 wbck/longpwbck/commit 挪到 WB 级。
5. **Step 1.5**（0.5 周）：调通 OITF 跨级 ret_ena 反馈。

### 3.7 验收

- [ ] 全套 riscv-tests（rv32ui-p-*, rv32um-p-*, rv32uc-p-*）100% 通过
- [ ] coremark / dhrystone 跑通（首次性能基线 baseline，记录 IPC）
- [ ] 等效性：同一 ELF 输入下 retire 序列与原 E203 一致

---

## 4. Phase 2：动态分支预测器升级

### 4.1 目标

替换 E203 的 LiteBPU（静态前 NT 后 T + JALR 阻塞）为：**gshare 方向预测 + 64 项 BTB + 8 项 RAS**。预期把整数控制流密集 benchmark 的 IPC 提升 ≥15%。

### 4.2 涉及文件

新增：
- `e203_ifu_bpu.v`（顶层封装）
- `e203_ifu_btb.v`（Branch Target Buffer，64 项 4 路组关联）
- `e203_ifu_pht.v`（Pattern History Table，2-bit saturating counter × 256 项）
- `e203_ifu_ras.v`（Return Address Stack，8 项）
- `e203_ifu_bhr.v`（全局历史寄存器，8 位）

修改：
- `e203_ifu_ifetch.v`：取指 PC 由 BPU 预测决定
- `e203_exu_alu_bjp.v`：在分支解决时回送 actual_taken/actual_target/mispredict 到 BPU
- `e203_idu_decode.v`：标记当前指令是 call/return（识别 JAL/JALR rd=x1/x5 即 call，JALR rs1=x1/x5 即 return），传给 RAS 控制

### 4.3 BPU 算法概要

**预测路径（IF 级 1 拍内完成）**：
```
1. 取指 PC → BTB 查表
2. 若 BTB 命中且类型为 conditional_branch:
     PHT_index = (PC[9:2] ^ BHR[7:0])
     prediction = PHT[PHT_index][1]   // MSB 决定 T/NT
3. 若 BTB 命中且类型为 JAL: 直接预测 taken + 已知 target
4. 若 BTB 命中且类型为 JALR-return: 预测 taken + RAS_top
5. 若 BTB 命中且类型为 JALR-call: 预测 taken + BTB_target；同时 RAS_push(PC+4)
6. 否则: 预测 NT (顺序 PC+4)
```

**更新路径（EX 级反馈）**：
```
mispredict = (actual_taken != predicted_taken) | (actual_target != predicted_target)
若 mispredict:
  - 刷新 IF/ID 流水（一拍泡）
  - PC 强制跳到 actual_target
  - PHT[index] 按 actual_taken 饱和更新
  - BTB 写入 (PC, actual_target, type)
  - BHR <<= 1 | actual_taken
```

### 4.4 关键时序

- **预测**：BTB/PHT/RAS 必须在 IF 级 1 拍内并行查到，预算 ≤ 4 ns（FPGA 100 MHz）。
- **mispredict flush**：从 EX 反馈到 IFU 重定向 PC 不应跨 2 个组合层级，否则关键路径爆。建议 flush 信号专线到 IFU 寄存器使能。

### 4.5 实施步骤

1. **Step 2.1**（0.5 周）：写 PHT + 2-bit 计数器更新 + 简单 testbench。
2. **Step 2.2**（1 周）：写 BTB（4 路、LRU 替换） + IFU 集成。
3. **Step 2.3**（0.5 周）：写 RAS + 调通 call/return 识别。
4. **Step 2.4**（1 周）：连接 EX 反馈 + flush 路径 + 性能调优。

### 4.6 验收

- [ ] 所有 ISA 测试在开启 BPU 下仍通过
- [ ] coremark 比 Phase 1 baseline IPC 提升 ≥ 15%
- [ ] mispredict 率（自带 perf counter）≤ 10%

---

## 5. Phase 3：L1 I-Cache 与 D-Cache

### 5.1 目标

**I-Cache**：4 KB，2 路组关联，32 B 行，64 项；**D-Cache**：4 KB，2 路组关联，32 B 行，写回 + 写分配，1 项 MSHR。

### 5.2 涉及文件

新增：
- `e203_l1icache.v`（I-Cache 主体）
- `e203_l1dcache.v`（D-Cache 主体）
- `e203_cache_pkg.v`（地址解码、参数）
- `e203_cache_axi_refill.v`（用 ICB-X burst 实现 refill）

修改：
- `e203_ifu.v`：在 ift2icb 之前插入 I-Cache
- `e203_lsu.v`：在 LSU ctrl 之前插入 D-Cache
- `e203_lsu_ctrl.v`：地址解码增加 cacheable region 判断
- `e203_defines.v`：增加 `E203_HAS_L1_ICACHE` / `E203_HAS_L1_DCACHE` 宏

### 5.3 Cache 内部结构

```
I-Cache (4 KB, 2-way, 32B line)
  index 位宽: 6  (64 set)
  offset 位宽: 5
  tag 位宽: 32 - 6 - 5 = 21

  组件:
    - tag_array (BRAM, 64×2×21)
    - data_array (BRAM, 64×2×256)
    - valid_array (FF, 64×2)
    - lru_bit (FF, 64)
    - refill_fsm: IDLE → MISS → REFILL_BURST → DONE

D-Cache (4 KB, 2-way, 32B line, WB+WA)
  额外:
    - dirty_array (FF, 64×2)
    - mshr (1 项, 记录 miss 中的请求)
    - wb_buffer (32B + 地址)
    - 状态机: IDLE → MISS_RD → REFILL → CHECK_DIRTY → WB_BURST → IDLE
```

### 5.4 与 ICB-X 协同

**Refill burst 编码**（line size 32 B，AXI4 INCR 4 拍 64-bit 或 8 拍 32-bit）：
```
cmd_id    = 2'd1     // 给 cache 分配的固定 ID（区分非 cache 请求）
cmd_len   = 8'd7     // 8 拍 32-bit；如果用 64-bit 总线则为 8'd3
cmd_burst = 2'b01    // INCR
cmd_last  = 拍 7 时为 1
```

**Writeback burst** 同理。

### 5.5 地址解码（cacheable vs bypass）

```verilog
// e203_cache_pkg.v
wire is_itcm    = (addr[31:28] == 4'h8);         // 旧 ITCM 区
wire is_dtcm    = (addr[31:28] == 4'h0);         // 假设 0x0
wire is_periph  = (addr[31:28] >= 4'hE);         // CLINT/PLIC/PPI
wire is_cacheable = (addr[31] == 1'b1) & ~is_periph;
```

I-Cache 仅在 `is_cacheable & ~is_itcm` 时启用；D-Cache 仅在 `is_cacheable & ~is_dtcm & ~is_periph` 时启用。其他地址走原 BIU 直通路径（保留 E203 的 ITCM/DTCM 确定性低延迟）。

### 5.6 实施步骤

1. **Step 3.1**（2 周）：实现 I-Cache（只读，简单），先关闭 D-Cache。
2. **Step 3.2**（0.5 周）：I-Cache 接入 IFU + 地址解码。
3. **Step 3.3**（2.5 周）：实现 D-Cache（含 dirty/MSHR/wb），先单端口仿真。
4. **Step 3.4**（1 周）：D-Cache 接入 LSU + 多 outstanding 测试。

### 5.7 验收

- [ ] 全 riscv-tests 通过（启用 cache）
- [ ] 矩阵乘法（1KB × 1KB）相比无 cache 加速 ≥ 3×
- [ ] cache miss rate 通过 perf counter 暴露
- [ ] ITCM/DTCM 路径延迟保持 1 拍（不被 cache 影响）

---

## 6. Phase 4：APU/FPU 外挂接口移植

### 6.1 目标

把 CV32E40P 的 APU 接口移植到 EX 级，作为外挂 FPU 的标准接口。FPU 本身不集成（用 cv-fpu/FPnew 作为可选挂件）。

### 6.2 涉及文件

新增：
- `e203_exu_apu_disp.v`（直接复用 cv32e40p_apu_disp.sv，做 Verilog 转译）
- `e203_apu_pkg.v`（APU 操作码、标志位定义）

修改：
- `e203_idu_decode.v`：识别 RV32F 指令族，输出 apu_op + apu_operands
- `e203_exu.v`：实例化 apu_disp，输出 apu_req/apu_operands 到 core 边界
- `e203_exu_oitf.v`：加 1 比特标记 "is_apu"
- `e203_wbu_longp.v`：apu_rvalid 通过 longp_wbck 通道汇入仲裁
- `e203_exu_csr.v`：增加 fcsr (0x003), frm (0x002), fflags (0x001)；mstatus.FS 字段维护
- `e203_cpu.v`、`e203_core.v`、`e203_cpu_top.v`、`e203_subsys_main.v`、`e203_subsys_top.v`、`e203_soc_top.v`：全部加 APU 端口透传（与 ICB-X 透传一样的工作）

### 6.3 接口契约

```verilog
output                      apu_req_o,
input                       apu_gnt_i,
output [APU_NARGS-1:0][31:0] apu_operands_o,
output [APU_WOP-1:0]        apu_op_o,
output [APU_NDSFLAGS-1:0]   apu_flags_o,

input                       apu_rvalid_i,
input  [31:0]               apu_result_i,
input  [APU_NUSFLAGS-1:0]   apu_flags_i,
```

### 6.4 实施步骤

1. **Step 4.1**（1 周）：APU 接口端口贯通 + tie-off（不接 FPU 也能编译）。
2. **Step 4.2**（1 周）：FPU 指令解码 + apu_disp 集成 + OITF 挂载。
3. **Step 4.3**（1 周）：CSR 集成 + fp register file（如选 ZFINX 则共用 GPR）+ rv32uf 测试。

### 6.5 验收

- [ ] APU 端口悬空时全部回归通过
- [ ] 接入 FPnew 后，rv32uf-p-* 测试 100% 通过

---

## 7. Phase 5：AI 加速器（HBird-NPU）

### 7.1 设计哲学

**"轻量、可重配、与主核紧耦合"**。不追求 TPU 级吞吐，而是在 ≤ 50K LUT（或等效 ASIC 面积）内做出可执行 MNIST/Speech-Yes-No 这类 8-bit/4-bit 量化模型的端侧推理。

### 7.2 顶层架构

```
   ┌────────────────────────────────────────────┐
   │             HBird-NPU                      │
   │                                            │
   │   ┌────────┐    ┌──────────────┐          │
   │   │NICE Cmd│───▶│   Sequencer  │          │
   │   └────────┘    │  (FSM + CSR) │          │
   │                  └──┬──────┬────┘          │
   │                     │      │               │
   │   ┌─────────────┐  │      │  ┌─────────┐ │
   │   │ Weight Buf  │◀─┘      └─▶│ Act Buf │ │
   │   │  (DTCM-Lite │            │ (Ping-  │ │
   │   │   2 KB)     │            │  Pong   │ │
   │   └──────┬──────┘            │  1 KB×2)│ │
   │          │                   └─────┬───┘ │
   │          ▼                         ▼     │
   │   ┌──────────────────────────────────┐  │
   │   │   PE Array  4×4 (默认 INT8)      │  │
   │   │   每个 PE = MAC + 累加器         │  │
   │   │   可配置: 4×4×INT8 | 8×4×INT4 | │  │
   │   │            16×4×INT2             │  │
   │   └──────────┬───────────────────────┘  │
   │              ▼                           │
   │   ┌──────────────┐                      │
   │   │ Postprocess │  ← ReLU/Quant/Pool   │
   │   └──────┬───────┘                      │
   │          ▼                               │
   │       回主机或下一层                     │
   │                                          │
   │   ┌─────────┐  ┌──────────────┐         │
   │   │ DMA Eng │──│  ICB-X 主端口 │ ───▶  到 BIU
   │   └─────────┘  └──────────────┘         │
   └────────────────────────────────────────────┘
```

### 7.3 涉及文件

新增（全部位于 `rtl/e203/core/npu/`）：
- `e203_npu_top.v` —— 顶层
- `e203_npu_seq.v` —— 控制 FSM + CSR/MMIO
- `e203_npu_wbuf.v` —— 权重缓冲（双端口 SRAM 2KB）
- `e203_npu_abuf.v` —— 激活缓冲（ping-pong）
- `e203_npu_pe.v` —— 单个 PE（可配置精度的 MAC）
- `e203_npu_pe_array.v` —— 4×4 systolic 阵列
- `e203_npu_post.v` —— ReLU + requant + pooling
- `e203_npu_dma.v` —— ICB-X 主端口 DMA
- `e203_npu_pkg.v` —— 操作码、CSR 索引

修改：
- `e203_exu_npu_disp.v`（仿照 nice 接口的 NPU 派遣器）
- `e203_idu_decode.v`：识别自定义 NPU 指令（OPCODE_CUSTOM_0 = 7'b000_1011）
- `e203_exu_oitf.v`：itag 容纳 NPU 长延迟事务
- `e203_core.v`：实例化 npu_top + DMA 接 LSU 或独立 BIU 端口
- `e203_biu.v`：在仲裁器输入端增加 NPU DMA 主端口

### 7.4 自定义指令 ISA

NPU 通过 RV32 自定义 opcode `0001011`（custom-0）暴露：

| 指令 | 编码（funct7+rs2+rs1+funct3+rd+op） | 功能 |
|:---|:---|:---|
| `npu.cfg rd, rs1, rs2` | funct3=000 | rs1=cfg_addr, rs2=cfg_data，写 NPU CSR |
| `npu.load_w rs1, rs2` | funct3=001 | rs1=src_addr (mem), rs2=size，DMA 加载权重 |
| `npu.load_a rs1, rs2` | funct3=010 | DMA 加载 activation |
| `npu.compute rs1` | funct3=011 | rs1=层类型（matmul/conv/elem），启动计算 |
| `npu.store_o rs1, rs2` | funct3=100 | DMA 写回输出 |
| `npu.wait rd` | funct3=101 | 阻塞等 NPU 完成，rd 返回状态码 |

通过 NICE 接口送入 `e203_exu_npu_disp.v`，NPU 完成后通过 longp_wbck 写回 rd（仅 wait 指令需要）。

### 7.5 PE 阵列设计

**默认配置**：4×4 weight-stationary systolic array，每个 PE 一个 INT8×INT8 → INT32 MAC（每周期 1 MAC，时钟 100 MHz 时峰值 1.6 GOPS）。

**可重配精度**（创新点 1）：每个 PE 内部数据通路按 32-bit 拼接重用：
- 配置为 INT8：1 MAC × 16 PE = 16 MAC/cycle
- 配置为 INT4：2 MAC × 16 PE = 32 MAC/cycle（2× 吞吐）
- 配置为 INT2：4 MAC × 16 PE = 64 MAC/cycle（4× 吞吐）

切换通过 `npu.cfg precision_mode` 实现，硬件代价仅为多路选择器与累加器位宽参数化。

### 7.6 创新点设计（详见第 9 节）

1. 可重配精度 PE
2. 稀疏权重跳过
3. TCM 融合权重缓冲
4. NICE 紧耦合调度

### 7.7 实施步骤

1. **Step 5.1**（1 周）：定义 ISA + 实现 npu_seq + 自定义指令解码贯通。
2. **Step 5.2**（2 周）：实现单精度 INT8 PE + 4×4 阵列 + 简单 matmul testbench。
3. **Step 5.3**（1 周）：buffers + DMA + ICB-X master 端口接入 BIU。
4. **Step 5.4**（1.5 周）：可重配精度逻辑 + 创新点验证。
5. **Step 5.5**（1 周）：稀疏跳过单元。
6. **Step 5.6**（1.5 周）：post-processing（ReLU/quant/pooling）+ end-to-end MNIST 跑通。

### 7.8 验收

- [ ] 自定义指令在 spike + RTL co-sim 下行为一致
- [ ] 4×4 INT8 matmul 性能 ≥ 软件实现的 30×
- [ ] 跑通 MNIST（LeNet-5 量化版）端到端推理，准确率与浮点参考偏差 ≤ 1%
- [ ] 稀疏度 50% 时实测加速 ≥ 1.5×
- [ ] NPU 计算期间主核可继续执行其他指令（OITF 验证）

---

## 8. Phase 6：集成验证与基准测试

### 8.1 验证策略

**三层金字塔**：

1. **单元测试**：每个新模块（BPU/Cache/NPU PE）独立 cocotb/SystemVerilog testbench，覆盖率 ≥ 80% 行覆盖。
2. **核心级回归**：riscv-tests + riscv-arch-test 全部通过；coremark/dhrystone/embench 跑分。
3. **系统级**：FPGA 上电 + Linux-free RT bare-metal demo + MNIST/Speech 推理 demo。

### 8.2 性能基准

| 指标 | E203 baseline | HBird-X 目标 |
|:---|:---:|:---:|
| Coremark/MHz | 2.5 | ≥ 3.5 |
| Dhrystone DMIPS/MHz | 1.4 | ≥ 1.9 |
| MNIST 推理时延 (28×28 INT8) | N/A | ≤ 5 ms @100 MHz |
| 关键词识别 (3-class, 10ms 帧) | N/A | 实时 |
| 面积 (LUT eq) | ~5K | ≤ 50K（含 NPU） |
| 主频 (FPGA Artix-7) | 100 MHz | ≥ 80 MHz |

### 8.3 持续集成

在 `vsim/` 目录下增加：
- `regression.mk`：自动跑 riscv-tests + coremark
- `npu_demo.mk`：编译 MNIST 二进制 + 运行
- 每次 PR 必须跑通才能合入

---

## 9. AI 加速器创新点（竞赛卖点）

### 9.1 创新点 1：精度-吞吐弹性 PE

**问题**：固定精度 PE 在不同模型/层上利用率不均（FC 层倾向 INT8，浅层 conv 容忍 INT4）。

**方案**：每个 PE 物理是 32-bit MAC 数据通路，通过控制 mux 重新解释为：
- 1 路 INT16×INT16
- 2 路 INT8×INT8
- 4 路 INT4×INT4
- 8 路 INT2×INT2

切换以"层粒度"通过 `npu.cfg` 在线完成，**单层内**精度统一。硬件增量约 8% 面积。

### 9.2 创新点 2：基于权重稀疏度的零跳过 + 索引压缩

**问题**：训练后剪枝模型权重稀疏度往往 50%–90%，但稠密 PE 阵列照常做 0×x 计算。

**方案**：
- 权重缓冲存储格式：CSR-lite（每 8 个权重压缩为 4-bit 非零位掩码 + 实际非零值序列）
- PE 输入侧增加 1-cycle 选择器：依据掩码，从激活缓冲选取对应位置的激活
- 全 0 行整体跳过（PE 时钟门控）

预期 50% 稀疏度时实测加速 1.5–1.8×（受激活流速限制）。

### 9.3 创新点 3：TCM-融合权重缓冲

**问题**：传统 NPU 权重缓冲是私有 SRAM，CPU 无法直接访问，每次更新必须 DMA。

**方案**：将权重缓冲（2 KB）映射到 DTCM 地址空间的高 2 KB（比如 `0x07FF_F800`–`0x07FF_FFFF`）：
- CPU 可直接通过 `sw` 写权重，避免 DMA setup 开销
- NPU 通过双端口 SRAM 的另一端读，完全不冲突
- 模型更新与推理可流水重叠：CPU 写下一层权重，NPU 处理上一层

这是 E203 TCM 哲学与 NPU 的天然融合，**比赛叙事性强**。

### 9.4 创新点 4：NICE 指令级调度（vs MMIO 轮询）

**问题**：传统 NPU 通过 MMIO 寄存器启动/查询，CPU 必须轮询或中断，调度开销大。

**方案**：通过 NICE 自定义指令直接调度 NPU。`npu.compute` 一发即返回（OITF 跟踪），CPU 可继续做无关计算；只有 `npu.wait` 才阻塞等待。**调度延迟从数十周期降到 1 周期**。

### 9.5 创新点 5（可选 stretch）：在 FPU APU 接口上"借道"NPU

如果 Phase 4 完成而 FPU 暂未接入，APU 接口可以临时给 NPU 复用——把 NPU 包装成"APU 设备"接入。这不是性能优化，而是接口复用的设计美感，便于评委理解。

---

## 10. 风险、备选与里程碑

### 10.1 主里程碑（M0–M6）

| 里程碑 | 时间 | 交付 |
|:---:|:---|:---|
| M0 | T+2w | Phase 0 完成；E203 baseline 在 FPGA 跑 riscv-tests |
| M1 | T+8w | 4 级流水跑通 riscv-tests，IPC 与 baseline 持平 |
| M2 | T+11w | BPU 上线，coremark 提升 ≥ 15% |
| M3 | T+17w | I/D Cache 上线，矩阵乘加速 ≥ 3× |
| M4 | T+20w | APU 接口贯通（含或不含 FPU） |
| M5 | T+28w | NPU 上线，MNIST demo 跑通 |
| M6 | T+32w | 全功能上 FPGA + 比赛报告 + 演示视频 |

### 10.2 资源紧张时的可砍优先级

如时间或人手不足，按**反向优先级**砍：
1. **首先放弃**：Phase 4（APU/FPU）—— 软件可仿真浮点
2. 其次：Phase 3 D-Cache（保留 I-Cache）
3. 不能砍：Phase 1（流水线）、Phase 2（BPU）、Phase 5（NPU 是亮点）

### 10.3 兜底方案

如 Phase 1（流水线重构）出现重大风险（OITF 语义破坏），退而求其次：
- 保留 E203 原 2 级流水
- 在 IFU 加 BPU（Phase 2 仍可独立完成）
- 在 EXU 之后挂 NPU（Phase 5 不依赖流水线深度）
- 砍 Cache 或仅做 I-Cache

这样退化方案仍能形成"E203 + 动态分支预测 + AI 加速"的完整作品，竞赛叙事不破。

### 10.4 关键决策检查清单

| 决策点 | 选项 | 默认建议 |
|:---|:---|:---|
| 寄存器堆实现 | FF / Latch / SRAM | FF（与 E203 一致） |
| Cache 关联度 | 1/2/4 路 | 2 路 |
| Cache 大小 | 4 KB / 8 KB | 4 KB（FPGA 友好） |
| BTB 大小 | 32/64/128 项 | 64 项 |
| BPU 算法 | bimodal / gshare / TAGE | gshare（性价比最高） |
| NPU PE 阵列 | 4×4 / 8×8 | 4×4（先做小，能跑再扩） |
| NPU 数据格式 | weight-stationary / output-stationary | weight-stationary |
| 默认精度 | INT8 / INT16 | INT8 |
| FPU | FPnew / 不接 | 不接（接口贯通即可） |
| 多核 | 否 | 否 |

---

## 附录 A：建议的 git 分支策略

```
master                    ← 当前 ICB-X 完成态
└── dev/hybrid            ← 主集成分支
    ├── feat/p1-pipeline  ← Phase 1
    ├── feat/p2-bpu       ← Phase 2
    ├── feat/p3-cache     ← Phase 3
    ├── feat/p4-apu       ← Phase 4
    ├── feat/p5-npu       ← Phase 5
    └── ci/regression     ← 回归基础设施
```

每个 feat 分支必须跑通 riscv-tests 才能合入 dev/hybrid。

## 附录 B：建议的目录新增

```
rtl/e203/core/
├── idu/                   ← 新增 ID 级
├── wbu/                   ← 新增 WB 级
├── npu/                   ← 新增 NPU
└── cache/                 ← 新增 Cache
tb/
├── unit/                  ← 单元测试
└── benchmark/             ← coremark/MNIST/dhrystone
doc/
├── HYBRID_DESIGN.md       ← 本文
├── ICB-X.md               ← 已有
└── NPU_ISA.md             ← 待补 NPU 指令集详细 spec
```

---

*本报告生成日期：2026 年 5 月 1 日*
*项目：HBird-X — E203 与 CV32E40P 深度融合 RISC-V 处理器*
