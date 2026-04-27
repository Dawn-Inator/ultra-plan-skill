---
name: ultra-plan
description: Use when user describes a large-scale architecture or multi-module feature that needs deep planning across many parts of a codebase. Triggers on phrases like "ultra-plan", "/ultra-plan", "large architecture", "整套架构", "整个系统", "全套", or any request that visibly spans 5+ modules / crosses frontend+backend / requires multiple AI sessions. Skip for single-file fixes, single-module features, bug fixes, or routine refactors that fit normal planning.
---

# Ultra-Plan: 大型架构需求的多 md 拆解 skill

## 这个 skill 解决什么问题

普通 Plan Mode 输出**一个** plan，对单功能足够。但当用户输入「整套管理端」「全套支付系统」「跨前后端的 IM 富媒体」这种**5+ 模块、跨前后端、需要多 AI session 分头执行**的需求时，单个 plan 颗粒度不够，开发者会在执行时迷失。

ultra-plan 把需求**拆成一组结构化 md**：1 个 `00_总体规划.md`（全局视图 + 模块依赖图 + 派发指令）+ N 个模块 md（每个模块独立的 8 节实现指引）。开发者可以拿着 00_总体规划.md 喂给一个新 AI session，让它按图索骥派 subagent 执行各模块。

**项目无关**：本 skill 不内嵌任何项目特定约定。项目自身的约定（API 风格、env 路径、测试标准、目录布局等）由 ultra-plan 在 Phase 0 自动**读取项目级配置文件**（`AGENTS.md` / `CLAUDE.md` / `.claude/CLAUDE.md` / `.cursorrules` 等）后注入到生成的 md 中。若同一项目同时存在 `AGENTS.md` 与 `CLAUDE.md`，Codex 优先遵循 `AGENTS.md`。

## 何时用

✅ 用：
- 5+ 模块的需求
- 跨前后端 / 跨 service 的整套交付
- 用户说 "ultra-plan" / "整套" / "全套架构" / "/ultra-plan"
- 用户暗示要长时间执行（"开个新窗口让 AI 跑"、"我下班前定好让 AI 慢慢做"）

❌ 不用：
- 单文件改动 → 直接做
- 单模块功能 → 用普通 Plan Mode
- bug 修复 → 用 `superpowers:systematic-debugging`
- 重构 / 重命名 → 用普通 Plan Mode
- 小于 5 个模块 → 用普通 Plan Mode

## Hard rules（不可违反）

1. **NEVER** 跳过 Phase 0.0 执行模式输入确认（用 `request_user_input`）—— 这是**整个 ultra-plan 第一个动作**，必须在任何探测、调研、写作之前完成。禁止与 Phase 0.2 合并、禁止延后到 Phase 4。豁免唯一条件见 0.0。
2. **NEVER** 在 Phase 1 派 subagent 写代码（subagent 只能调研、读、报告）
3. **NEVER** 在 Phase 5 派多个并行 subagent 写**同一个模块**（会冲突）
4. **NEVER** 自己造 CTO / PM / Marketing 这种"角色化"subagent —— 用视角 prompt 注入，不要预设人设
5. **NEVER** 在 skill 自身或生成的 md 里写死项目特定约定 —— 项目约定必须从项目级配置文件抽取
6. **ALWAYS** 在 subagent prompt 里列绝对路径并要求复述（≤150 字回执）
7. **ALWAYS** Phase 4 按 Phase 0.0 执行模式答案直接流转 —— **不再二次弹窗确认**。Phase 4 的职责退化为「列文档清单 + 按 0.0 答案分支」
8. **ALWAYS** 主 agent 串行写 `00_总体规划.md`，不能派 subagent 写它（要保证全局术语一致）
9. **ALWAYS** Phase 0 之前先读项目级配置文件（见 [references/项目适配指南.md](references/项目适配指南.md)）

## Workflow

### Phase 0: 启动三件套（必须按 0.0 → 0.1 → 0.2 顺序）

#### 0.0 执行模式输入确认（无条件必弹，第一动作）

**收到大型需求后，主 agent 的第一个动作就是这个 `request_user_input`**，禁止与 0.2 合并、禁止延后到 Phase 4。

| Header | Question | Options |
|---|---|---|
| 执行模式 | 写完所有 md 后怎么办？| (A) 推荐：停下，开新 Codex 窗口让它读 `00_总体规划.md` 执行（避免主 session 上下文爆）(B) 直接接着派 subagent 跑 (C) 写完先停，我自己看了再决定 |

**唯一豁免**：用户初始 prompt 里**逐字明说**了执行态度（"直接执行" / "立即执行" / "auto execute" / "自动跑" / "写完新窗口跑" / "写完停"）。豁免时主 agent 必须在文字回复中**复述用户原话**作为凭据。

**禁止**：
- 禁止把这一确认与 0.2 合并问
- 禁止用"feature 名/输出位置已知就跳过整个 Phase 0"为理由省略
- 禁止延后到 Phase 4 才问

#### 0.1 项目探测（主 agent 必做）

按 [references/项目适配指南.md](references/项目适配指南.md) 检查工作目录里的项目级配置：

- `AGENTS.md`（Codex / 通用 agent 指令，存在时优先）
- `CLAUDE.md` / `.claude/CLAUDE.md`（Claude Code 项目指令，作为补充）
- `.cursorrules` / `.cursor/rules/`（Cursor 风格规范）
- `README.md` 顶部的"约定"段
- `package.json` / `pyproject.toml` 等读出技术栈

**目标**：抽取出能注入"派发前必须强调"段的红线（API 风格、env 管理、响应格式、测试标准、目录布局、截图位置等）。

如果项目没有任何配置文件 → 跳过项目特定红线段，只用通用模板。

#### 0.2 范围澄清确认（必做，3 题）

立即用 `request_user_input` 问 3 件事（**已不含执行模式 —— 那个在 0.0 已经定了**）：

| Header | Question | Options |
|---|---|---|
| feature 命名 | 这次需求的 feature 名是？（决定目录名）| 主 agent 提议 2-3 个候选；Codex 客户端会自动提供 Other |
| 输出位置 | 文档放在哪里？| (A) `<project_root>/.todolist/<feature>-v<N>/`（推荐，gitignore 友好）(B) `docs/plans/<feature>-v<N>/` (C) Other 让用户敲 |
| 调研深度 | Phase 1 派几个调研 subagent？| (A) 你自己判断（推荐）(B) 标准 5-8 个 (C) 深度 10-15 个 |

**跳过 0.2 的唯一情况**：用户初始 prompt 里逐字明说了 feature 名 + 输出位置 + 深度。任何一项缺失都要弹。

### Phase 1: 调研（并行 5-15 subagent）

主 agent 综合需求 + Phase 0 答案后，**用 `spawn_agent` 并行派 5-15 个 `explorer` subagent 调研**。如果当前 Codex 会话未获得明确的 ultra-plan / subagent 授权，先在 Phase 0 让用户确认该模式。

视角清单见 [references/subagent-prompt模板.md](references/subagent-prompt模板.md) §1。**不是固定派全部**，是按需求性质挑相关视角组合。例：
- 支付需求 → 财务模型 / 合规 / 风控 / 幂等性 / 对账 / 现有 provider 集成 / 测试 / 边界
- 直播需求 → 音视频协议 / CDN / 带宽成本 / 互动延迟 / 鉴权 / 数据流 / 客户端兼容 / 测试

**派发要求**：
- 每个 subagent prompt **必须 ≤ 500 字**输出限制（防止主 session 上下文爆）
- prompt 模板见 [references/subagent-prompt模板.md](references/subagent-prompt模板.md) §2
- subagent 只调研、不写代码、不改文件
- subagent 数量根据 Phase 0 答案：标准 5-8 / 深度 10-15 / 自动判断按需求复杂度

### Phase 2: 拆解（主 agent 综合）

主 agent 收到所有 subagent 调研报告后：

1. **列模块清单**：把需求拆成 N 个模块（典型 5-15 个），每个模块独立可交付
2. **标耦合度**：每个模块标 `高耦合` / `中耦合` / `低耦合`，判定标准见 [references/耦合度判定.md](references/耦合度判定.md)
3. **画依赖图**：模块之间的前后置依赖（哪个先做、哪个并行）
4. **划波次**：第 1 波（基础）→ 第 2 波（依赖第 1 波）→ ...

**输出**：内部草稿（不写文件），用于 Phase 3。

### Phase 3: 写文档（混合策略）

#### 3.1 主 agent **串行**必写

- `00_总体规划.md` —— 全局上下文，模板见 [templates/00_总体规划.md.template](templates/00_总体规划.md.template)
- 任何标"高耦合"的模块 md（涉及跨模块共享 schema / API 契约 / 术语）
- 跨模块的契约 md（如有，命名 `99_跨模块契约.md`）

#### 3.2 低耦合模块可派 subagent **并行**写

**只对低耦合模块**用 `spawn_agent` 派 `worker` subagent 并行写：
- 每个 subagent 负责 1-2 个模块 md
- prompt 必须包含已写好的 `00_总体规划.md` 全文 + 模板路径 + 该模块在依赖图里的位置
- prompt 见 [references/subagent-prompt模板.md](references/subagent-prompt模板.md) §3

**判定阈值**：模块清单里 ≥30% 模块标"高耦合" → **全部主 agent 串行写**，不派并行。

#### 3.3 模块 md 标准结构

每个模块 md 严格遵循 8 节框架（模板见 [templates/模块.md.template](templates/模块.md.template)）：

1. 范围与目标（含"不做"清单）
2. 现状定位（表格：项 / 状态 ❌✅⚠️ / 路径）
3. 实现指引（后端 / 前端分写）
4. API 契约（Method / URL / 请求 / 响应表）
5. 前置依赖（其他模块编号）
6. 验收红线（测试 + 边界 case）
7. 边界 & TBD（产品决策项）
8. 派发前必须强调（从 Phase 0.1 抽取的项目级红线）

#### 3.4 项目特定红线注入

把 Phase 0.1 项目探测时抽取的红线注入到：

- `00_总体规划.md` §5.3 派发前必须强调
- 每个模块 md §8 派发前必须强调

抽取要点见 [references/项目适配指南.md](references/项目适配指南.md)。

### Phase 4: 按 Phase 0.0 答案分支（不再二次弹窗）

写完所有 md 后，主 agent **必须**：

1. 跑 `git status` 自检（不应有意外文件修改，只应有目标输出目录下的新文件）
2. 输出文档清单：列出生成的所有 md 路径
3. **按 Phase 0.0 的答案直接流转，禁止再用 `request_user_input` 问执行模式**：

   - 0.0 = (A) 新窗口 → 输出：「✓ 准备好了。请开新 Codex 窗口，第一句喂它：『读 `<output_dir>/00_总体规划.md` 后按计划执行』」然后停下
   - 0.0 = (B) 直接执行 → 立即进入 Phase 5
   - 0.0 = (C) 写完先停 → 输出文档清单，停下

**禁止在 Phase 4 重新发 `request_user_input` 问执行模式** —— 0.0 已经定了，再问就是流程冗余。

### Phase 5: 执行（可选）

仅当 Phase 4 选 (B) 或用户初始 prompt 明说"直接执行"时进入。

**复用 `superpowers:subagent-driven-development`**，但 prompt 模板按 Phase 0.1 抽取的项目约定调整（见 [references/subagent-prompt模板.md](references/subagent-prompt模板.md) §4）。

执行约束：
- 严格按 00_总体规划.md 的波次图，不跳波次
- 每个模块的执行 subagent 必须先复述必读清单（≤150 字）
- 主 agent 自己**不**实现代码，只派发 + 验收 + 推进波次
- 长任务建议**用户开新 session 执行**（Phase 4 推荐选 A），主 session 上下文有限

## Common mistakes（要避免的红旗）

| 误区 | 现实 |
|---|---|
| "需求看着不大，跳过 Phase 0 直接写" | NO. 用户口里"小需求"经常拆出 8 个模块。先弹 Phase 0 |
| "Phase 1 派 3 个 subagent 就够了" | NO. < 5 个就用普通 Plan Mode，不要用 ultra-plan |
| "subagent 调研报告太短，让它写详细点（>500 字）" | NO. 主 session 上下文有限，多 agent 报告会爆。逼它精炼 |
| "00_总体规划.md 我也派 subagent 写更快" | NO. 必须主 agent 串行写。这是全局术语 source of truth |
| "高耦合模块也派并行 subagent 加速" | NO. 高耦合 = 共享 schema / 共用术语 / 互调 API，并行写必然术语不一致 |
| "Phase 4 弹窗太啰嗦，自动选直接执行" | NO. 执行模式应该在 Phase 0.0 就由用户敲定。Phase 4 不再问，按 0.0 答案分支 |
| "feature 名 / 输出位置 / 深度都问出来了，把 0.0 执行模式合并到 0.2 一起问" | NO. 0.0 必须**单独**弹窗、且是**第一个**弹窗。和 0.2 三题合并 = 必然被主 agent 整体跳过 |
| "用户没指定 feature 名，我自己起一个" | NO. 命名权在用户。Phase 0 必问 |
| "派 CTO / PM / Marketing 角色 subagent 看起来更专业" | NO. 角色化 = 限制思维。用具体视角 prompt（财务 / 合规 / 风控 / 幂等等）|
| "项目没 AGENTS.md / CLAUDE.md，我就用其他项目的约定" | NO. 项目无明确配置 = 不注入项目红线段，纯通用模板。不要从训练数据 / 其他项目带入约定 |

## 引用关系

ultra-plan 不重写、只编排现有 skill：

- **Phase 1 调研**：参考 `superpowers:dispatching-parallel-agents` 的 prompt 模板
- **Phase 5 执行**：参考 `superpowers:subagent-driven-development` 的 implementer/reviewer 二阶段评审
- **写 plan 风格**：参考 `superpowers:writing-plans` 的 No Placeholders 原则（不写 TBD / "类似 Task N" / "处理边界"）
- **本 skill 自身的更新**：参考 `superpowers:writing-skills` 的 CSO 规则
