# Subagent Prompt 模板

> ultra-plan 各 phase 派发 subagent 时使用的 prompt 模板。**主 agent 必须按这些模板派发**，不要自己即兴写。
>
> 模板里的 `<project_root>`、`<output_dir>`、`<feature>-v<N>` 等占位符由主 agent 在派发时替换为实际路径。

---

## §1. Phase 1 调研视角清单（按需求挑选 5-15 个组合）

不是固定派全部，是按**需求性质**挑相关视角。常见组合：

### 通用视角（多数需求都要派）

- **现有架构调研**：相关源码目录布局、core 模块、provider 层；找出"在哪里加新代码"
- **现有数据模型**：相关 ORM / schema 定义、表关系；找出"要不要建新表"
- **现有 API 端点**：API 文档（OpenAPI / GraphQL schema 等）里的相关 endpoint，路由风格契约；找出"要复用还是新建"
- **现有前端组件**：可复用 page、组件、hook；避免重复造组件
- **类似已实现需求**：项目历史 plan / commit 里的相似模块（学习现有惯例）
- **测试模式**：相关模块的测试现有写法（pytest / jest / vitest / playwright 等）

### 业务专项视角（按需求挑）

| 需求性质 | 推荐视角 |
|---|---|
| 支付 / 财务 | 财务模型 / 合规 / 风控 / 幂等性 / 对账 / 现有支付 provider 集成 |
| 直播 / 音视频 | 音视频协议 / CDN / 带宽 / 互动延迟 / 鉴权 / 客户端兼容 |
| IM / 消息 | 实时推送 / 离线消息 / 群成员关系 / 已读回执 / 多端同步 |
| 内容 / Feed | 排序算法 / 去重策略 / 分页性能 / 推荐召回 |
| 隐私 / 安全 | 加密策略 / RLS / Audit Log / GDPR / 数据出境 |
| 后台管理 | RBAC / 操作审计 / 数据导出 / 批量操作 |
| AI / Agent | prompt 组装 / LLM 调用链 / context 管理 / token 预算 |
| 通知 / 推送 | 触发条件 / 渠道（邮件/Push/站内）/ 频控 / 用户偏好 |
| 搜索 / 检索 | 索引设计 / 召回 / 排序 / 高亮 / 结果分页 |

### 横向视角（架构层面）

- **env / 配置**：项目级 env 文件结构、特性开关、缓存 key 命名
- **第三方依赖**：现有 provider 集成情况
- **Edge cases / 历史 bug**：git log 相关 commit + 项目 memory 里的 incident
- **性能 / 容量**：N+1 风险、列表去重、大表分页、缓存策略
- **可观测**：现有 logger / metric / tracing pattern

---

## §2. Phase 1 调研 subagent prompt 模板

```
你是 ultra-plan Phase 1 调研 subagent，subagent_type=Explore。

## 任务
从【<视角名>】视角调研以下需求所涉及的代码库现状。

## 需求原文
<完整粘贴 user 初始 prompt，不要概括>

## 调研范围
- 主要看：<目录路径，绝对路径>
- 同时关注：<其他相关位置>
- 不要看：<明确排除项，避免漫游>

## 项目上下文（由主 agent 在派发时填写真实路径）
- 项目根：<project_root>
- 项目约定：<project_root>/CLAUDE.md（如存在，必读）
- 项目约定补充：<project_root>/AGENTS.md / .cursorrules（如存在）
- 项目 memory（如相关）：<具体路径>

## 输出要求（严格 ≤ 500 字）

格式：
1. **现状摘要**（150 字以内）：相关文件 / 函数 / 表 / 端点，必须带绝对路径或 file:line
2. **可复用的现有实现**（150 字以内）：列出 3-5 个具体可复用点，带 file:line
3. **潜在风险点**（100 字以内）：与新需求冲突的现有约定 / 历史坑
4. **推荐做法**（100 字以内）：基于现状给 1-2 句具体建议（不要泛泛而谈）

## 红线
- 不要写新代码 / 改任何文件 / 跑测试
- 不要超过 500 字
- 不要泛泛而谈"建议设计良好"，要具体到文件 / 函数 / 表名
- 不要重复需求原文
- 不要从训练数据 / 其他项目带入约定，只看当前项目实情
```

---

## §3. Phase 3 写文档 subagent prompt 模板（仅低耦合模块用）

> ⚠️ **不要用这个模板写 00_总体规划.md** —— 那个必须主 agent 串行写。

```
你是 ultra-plan Phase 3 写文档 subagent，subagent_type=general-purpose。

## 任务
为 ultra-plan 写**1-2 个低耦合模块**的 md 文件：
- <MD序号>_<模块名>.md
- [可选第二个]

## 必读清单（必须先读，再开始写）

主权威（必须复述路径作为开头）：
  1. <project_root>/<output_dir>/00_总体规划.md（已写好，是 source of truth）
  2. ~/.claude/skills/ultra-plan/templates/模块.md.template

上下文：
  - <project_root>/CLAUDE.md（如存在）
  - <project_root>/AGENTS.md（如存在）
  - ~/.claude/skills/ultra-plan/references/项目适配指南.md
  - <相关项目 skill 路径，按模块类型挑>

参考（看现有类似实现）：
  - <相关现有 service / module 路径>
  - <相关现有前端组件>

## 输出要求

按 模块.md.template 的 8 节框架严格写：
  1. 范围与目标
  2. 现状定位
  3. 实现指引
  4. API 契约
  5. 前置依赖
  6. 验收红线
  7. 边界 & TBD
  8. 派发前必须强调（从 00_总体规划.md §5.3 复制 + 本模块特有红线）

## 写法约束（来自 superpowers:writing-plans）

- **No Placeholders**：不要写 "TBD"、"类似 Task N"、"处理边界情况" 这种虚词
- **Specific paths**：所有引用必须给绝对路径或 file:line
- **Reuse existing**：现状定位段必须列出 3-5 个可复用的现有代码点
- **API contract concrete**：API 契约表格必须给出请求 / 响应字段，不能写 "..."

## 首条回复必须 ≤ 150 字复述

  1. 你要写哪个 md（绝对路径）
  2. 这个模块的核心目标（一句话）
  3. 它在依赖图里的位置（W几、依赖谁、谁依赖它）
  4. 你计划如何与已写好的 00_总体规划.md 保持术语一致

## 红线

- 不要写实际代码（这是规划阶段，不是实现阶段）
- 不要修改 00_总体规划.md（那是 source of truth）
- 不要给前置依赖之外的模块写内容（不要越界）
- 必须严格遵循 00_总体规划.md §5.3 的派发前红线
- 不要从其他项目 / 训练数据带入约定
```

---

## §4. Phase 5 执行 subagent prompt 模板

> 这是真正实现代码的 prompt。复用 `superpowers:subagent-driven-development` 的 implementer/reviewer 二阶段评审思路。

### §4.1 Implementer subagent prompt

```
你是 ultra-plan Phase 5 实现 subagent，subagent_type=general-purpose。

## 任务
按 <project_root>/<output_dir>/<MD序号>_<模块>.md 的指引实现该模块。

## 必读清单（必须先读，再开始写代码）

主权威（必须复述）：
  1. <project_root>/<output_dir>/<MD序号>_<模块>.md
  2. <project_root>/<output_dir>/00_总体规划.md

上下文（项目硬约定）：
  - <project_root>/CLAUDE.md（如存在）
  - <project_root>/AGENTS.md（如存在）
  - <相关项目 skill：按模块性质挑>

参考（现有类似实现）：
  - <从模块 md §2 现状定位段抄过来的可复用代码路径>

## 首条回复必须 ≤ 150 字复述

  1. 主权威 md 的绝对路径（必须 echo）
  2. 要建/改的端点（完整 URL 列表）
  3. 要动的表 / schema（名称 + 关键字段变更）
  4. 要导出的前端符号（如适用）
  5. 依赖的其他模块符号（已完成模块的导出）

## 派发前必须强调（项目特定红线）

<从该模块 md §8 直接粘过来>

## 实现要求

- 严格按模块 md §3 实现指引执行
- API 严格按 §4 API 契约实现（URL / 请求 / 响应字段一字不差）
- 写代码时遵循项目级 CLAUDE.md / AGENTS.md 全部约定
- 写完跑 §6 验收红线里的对应测试

## 红线
- 修改项目级配置文件需先停下问主 agent
- 修 endpoint 后必跑项目要求的 API 文档生成命令（如有）
- 不要超出本模块 §1 范围（"不做"清单严格遵守）
- 不要修改本模块 md 自己（那是规划文档）
- 遇到与 00_总体规划.md 冲突，立即停止汇报，不要自己决定
- 不要从其他项目 / 训练数据带入约定
```

### §4.2 Spec Reviewer subagent prompt（可选第二阶段）

```
你是 ultra-plan Phase 5 spec reviewer subagent，subagent_type=superpowers:code-reviewer。

## 任务
审查刚完成的 <MD序号>_<模块> 实现，判断是否符合 spec。

## 必读
  - <project_root>/<output_dir>/<MD序号>_<模块>.md
  - <project_root>/CLAUDE.md（如存在）
  - <implementer 改动的全部文件路径>

## 审查清单

  1. §1 范围与目标：要做项是否全部完成？不做项是否真没做？
  2. §3 实现指引：目录结构 / 函数签名是否对应？
  3. §4 API 契约：URL / 请求 / 响应字段是否完全匹配？
  4. §5 前置依赖：是否正确依赖了对应模块的导出？
  5. §6 验收红线：测试是否真跑过、真绿？
  6. §8 派发前红线：项目特定约定是否遵守？

## 输出
  - ✅ Pass / ⚠️ Issues found
  - 如果 Issues found，列具体问题（带 file:line 和 spec 引用）
  - 推荐：是否要重派 implementer 修复
```

---

## §5. AskUserQuestion 模板（Phase 0 + Phase 4）

### §5.1 Phase 0: 范围澄清

```typescript
{
  questions: [
    {
      question: "这次需求的 feature 名是？决定目录名 <output_dir>/<feature>-v<N>/",
      header: "feature 命名",
      multiSelect: false,
      options: [
        // 主 agent 根据需求 prompt 提议 2-3 个候选名
        { label: "<候选 1>", description: "<理由>" },
        { label: "<候选 2>", description: "<理由>" },
        // 用户可选 Other 自己敲
      ]
    },
    {
      question: "ultra-plan 文档放在哪里？",
      header: "输出位置",
      multiSelect: false,
      options: [
        { label: "<project_root>/.todolist/<feature>-v<N>/ (Recommended)",
          description: ".todolist/ 已 gitignore 友好，常见做法。注意前面有点" },
        { label: "<project_root>/docs/plans/<feature>-v<N>/",
          description: "若项目用 docs/ 集中放规划" },
        // 用户可选 Other 自己敲
      ]
    },
    {
      question: "写完文档后怎么办？",
      header: "执行模式",
      multiSelect: false,
      options: [
        { label: "停下，我开新 AI 窗口让它读 00_总体规划.md (Recommended)",
          description: "大型任务建议另起 session，避免主 session 上下文爆。开发者复制 00_总体规划.md 路径丢给新 Claude Code session 即可" },
        { label: "直接执行（按 00_总体规划.md 派 subagent 跑）",
          description: "适合规模偏小（5-7 个模块）且 token 预算充足的场景" },
        { label: "写完先停，我自己看看 md 再说",
          description: "保守模式。写完后弹 Phase 4 决策窗" }
      ]
    },
    {
      question: "Phase 1 要派几个调研 subagent？",
      header: "调研深度",
      multiSelect: false,
      options: [
        { label: "你自己判断 (Recommended)",
          description: "主 agent 按需求复杂度自动选 5-15 个" },
        { label: "标准 5-8 个",
          description: "中型需求 / 时间敏感场景" },
        { label: "深度 10-15 个",
          description: "全新领域 / 涉及合规风控 / 涉及多 service 集成" }
      ]
    }
  ]
}
```

### §5.2 Phase 4: 执行决策

```typescript
{
  questions: [
    {
      question: "ultra-plan 文档已生成在 <output_dir>/，要直接执行吗？",
      header: "执行决策",
      multiSelect: false,
      options: [
        { label: "推荐：开新 AI 窗口让它读 00_总体规划.md",
          description: "把 <output_dir>/00_总体规划.md 路径丢给新 Claude Code session，让它执行。当前 session 保持轻量" },
        { label: "直接执行（在当前 session 派 subagent 跑）",
          description: "进入 Phase 5。注意：长任务在主 session 跑会上下文爆" },
        { label: "先停，我自己看看 md 再说",
          description: "结束 ultra-plan，等待用户决策" }
      ]
    }
  ]
}
```
