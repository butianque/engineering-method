# P7 · 模式 A：形式化证明分支

> 适用：需求能被写成**命题**（不变量 / 协议安全性 / 算法正确性 / 数据一致性），
> 且「测试通过」**不足以**证明它。
> 判据物：**证明** 或 **反例**。不是命令输出，也不是模型自评。
>
> 本文件是 `dev-proof-protocol` 的**模式 A 分册**。主干 P0–P6 与铁律 L1–L5 照旧适用；
> 模式 A 只做一件事：把 P4/P5 的「证据」换成「证明 / 反例」。

---

## 0. 一句话

**模式 A = 先冻结一条命题，再建模，再用工具证明它、或用反例否证它，最后落判决。**

它不放松任何铁律：

- **L1**：命题就是"预先冻结的成功标准"，必须在动手前定死；
- **L4**：判定由**工具内核**做（Lean 的 kernel、TLC 的穷举、SMT 求解器），不由 AI 自评；
- **L5**：谁写证明，谁不自证——交独立者做 **statement audit**。

> `Violating the letter of this protocol is violating the spirit of it.`

---

## 1. 何时切到形式化模式

判据分两组。**第 1 组里有 ≥1 条成立**、且**第 2 组里有 ≥1 条成立**，才切模式 A。

### 1.1 命题化判据（需求能不能写成命题）

| # | 命题形态 | 典型例子 |
|---|---|---|
| A1 | **不变量 invariant** | 队列长度 ≤ 容量；引用计数非负；锁不会被双重释放；索引恒在界内 |
| A2 | **协议安全性 / 活性 safety / liveness** | 并发交错下不丢唤醒、不双重释放、不乱序；`close` 一定会完成 |
| A3 | **算法正确性 correctness** | 排序对**所有**输入有序；二分查找「返回 none ⇒ 元素确实不存在」 |
| A4 | **数据一致性 consistency** | 编解码往返无损；`slot = item mod window` 的边界恒成立 |

### 1.2 "测试不足"判据（为什么非得证明，不能靠跑）

| # | 判据 |
|---|---|
| B1 | 输入空间 / 并发交错空间组合爆炸，穷举测试不可行 |
| B2 | 故障只在**特定并发时序**或**特定尺寸**出现，测试样例覆盖不到 |
| B3 | 需要的是"对任意尺寸 / 任意交错成立"，而不是"我跑过的那几个样例通过" |
| B4 | 失败成本高（数据损坏、安全、死锁），宁可先证明也不愿事后踩雷 |

### 1.3 不切（仍走模式 B）

- 需求本身**写不成一句可判真假的命题**（模糊、"更健壮一点"）→ 回 P1/P2；
- 输入有限且可穷举，直接跑测试就能判定；
- 机械改动且诊断已验证。

### 1.4 命题类型 → 首选工具 → 判据物

| 命题类型 | 首选工具 | 判据物 |
|---|---|---|
| 并发 / 分布式协议的交错与活性 | **TLA+ + TLC** | 小实例穷举无违例 / 出现反例 trace |
| 顺序算法、算术、边界，要求对所有尺寸成立 | **Lean 4** | kernel 检验通过的证明 |
| 有界输入 / 有界循环的 Rust 函数 | **Kani**（见 §4，`agent-formal-verify` 附带） | 界内每个输入无违例 |
| 结构 / 关系型设计约束（数据模型、权限、拓扑） | **Alloy** | 小 scope 内找到/找不到反例 |
| 顺序命令式代码的前后置条件、循环不变量、终止性 | **Dafny** | SMT 验证器通过 |
| 可判定的算术 / 位向量 / 数组 / 未解释函数的判定问题 | **Z3 / SMT** | `unsat`（证明）或 `sat` 模型（反例） |

> 关键判据：**「测试通过」证明的是"我试的那几个"，不是"全部"。**
> 只要需求需要"全部"，或者"全部"无法穷举，就进模式 A。

---

## 2. 工具选型对照表

以下每一条都来自工具官方来源（引用块为原文句子）。**不要凭印象选工具。**

| 工具 | 它是什么 | 适合 | 不适合 |
|---|---|---|---|
| **Lean 4** | 交互式定理证明器 + 函数式编程语言 | 数学定理；需要**归纳 / 任意尺寸**的命题；算术、边界、顺序状态转移；代码级不变量 | 用来自动穷举并发交错（不擅长大规模状态搜索）；想"零成本"自动化——需要人工写证明，成本高 |
| **TLA+ + TLC** | 建模语言 + 模型检查器（另有 TLAPS 证明系统） | 并发 / 分布式系统的**设计级**建模；不变量（安全性）；公平性假设下的活性 | 需要"对所有尺寸/任意整数"的算术证明（用常数抽象）；直接验证整段程序代码；状态爆炸的大配置 |
| **Alloy** | 关系逻辑 + SAT 有界模型查找器（引擎 Kodkod） | **结构性 / 关系型**设计约束；找反例（"小 scope 假设"）；权限、数据模型、拓扑类设计缺陷 | 无界证明（不做归纳）；顺序算法的逐步不变量证明；大 scope 会爆炸 |
| **Dafny** | 验证感知的命令式编程语言，自带静态验证器 | 顺序命令式代码；前置/后置条件、循环不变量、终止性；可编译到 C#/Java/JS/Go/Python | 并发协议的建模与活性；必须靠人工归纳、SMT 自动机搞不定的重数学；SMT 超时会让证明"脆" |
| **Z3 / SMT** | SMT 求解器（判定过程集合） | 线性算术、位向量、数组、未解释函数的判定问题；**位精确**检查；作为 Dafny/Alloy 的后端；给出 `sat` 反例 | 对无界结构做归纳；高阶 / 不可判定片段（会返回 `unknown`）；单独拿它当"系统建模语言"——它只是一段可满足性引擎 |

官方原文（择要）：

> **Lean**：an open-source programming language and proof assistant that enables correct, maintainable, and formally verified code
> … Lean's minimal trusted kernel guarantees absolute correctness in mathematical proof, software and hardware verification
> （lean-lang.org，2026 抓取）

> **TLA+**：a high-level language for modeling programs and systems--especially concurrent and distributed ones … useful for eliminating fundamental design errors, which are hard to find and expensive to correct in code
> … The primary ones are the TLC model checker and the TLAPS proof system
> （Leslie Lamport，TLA+ Home Page，Last modified 13 October 2025）

> **Alloy**：Alloy is an open source language and analyzer for software modeling … from finding holes in security mechanisms to designing telephone switching networks … on top of Kodkod, its model finding engine
> … Alloy 6 … adds mutable state, a temporal logic and accompanying solvers
> （alloytools.org，2026 抓取）

> **Dafny**：**Dafny** is a verification-aware programming language that has native support for recording specifications and is equipped with a static program verifier.
> … pre- and post-conditions, termination conditions, loop invariants, and read/write specifications
> （dafny.org，2026 抓取）

> **Z3**：Z3 is a theorem prover from Microsoft Research. … Default input format is SMTLIB2
> （github.com/Z3Prover/z3 README，2026 抓取）

### 2.1 现成工具给出的"哪个问题用哪个工具"对照

`michael-denyer/agent-formal-verify` 的 `skills/formal-verify/SKILL.md` 直接给了这张表，
是本文件推荐落地的现成判据（原文照录）：

> | What can go wrong | Tool | Why |
> | --- | --- | --- |
> | Thread interleavings that lose wakeups, free resources twice, deliver items twice or out of order, block close, or report errors on the wrong thread | TLA+ with TLC | TLC explores the states of a small instance and reports counter-examples |
> | Overflow, out-of-bounds access, panics and broken invariants in a Rust function with bounded loops | Kani | Kani checks the real code for every input within the stated bounds |
> | Arithmetic or sequential transitions that break bounds, invariants or encoder round trips, or reach states the code assumes impossible | Lean 4 | Evaluate bounded instances, then prove the property for every size |

> Prefer Kani when the function is Rust and its inputs and loops can be bounded, because it checks the production function directly. Use Lean when the property must hold for every size or the code is not Rust.

> A thread protocol that depends on arithmetic such as `slot = item mod window` needs both tools. Use TLA+ for the interleavings with the arithmetic as a constant, and Lean for the arithmetic.

---

## 3. 流程：statement → 建模 → 证明/反例 → 判决

```
S0 命题化：把需求写成可判真假的 statement（进 §3 的表）
S1 冻结 statement：★ 必须人工确认后才冻结
S2 建模：把源码/设计映射成模型，记录假设与边界
S3 证明或找反例：跑工具；并用 mutation 证明"检查器真的会失败"
S4 判决：PROVED / COUNTEREXAMPLE / UNKNOWN / OUTSIDE_FRAME
```

### S0 命题化（对应 P1：分解）

把大命题拆成**引理 / 子目标**（P1 的分解树在模式 A 里的形态）。每条 statement 一行：

| 字段 | 含义 |
|---|---|
| `stmt_id` | 命题编号（如 `T.1`） |
| `nl_source` | 需求中文原文（**不可改写**） |
| `natural_statement` | 待证明命题的自然语言陈述 |
| `formal_statement` | 工具的正式声明（Lean `theorem` / TLA+ 不变量 / SMT 公式） |
| `bindings` | 绑定的源码落点（`file:symbol` / 行范围）——对应 P2 |
| `assumptions` | 假设、边界、scope、整数宽度 |
| `target` | 用哪个工具、跑什么命令 |
| `status` | `PROPOSED / FROZEN / PROVED / COUNTEREXAMPLE / UNKNOWN` |

### S1 冻结 statement —— 人工确认后才冻结

**这是模式 A 的 P0（L1）。statement 没冻结，不许开始证明。**

- 必须**先给完整声明**（不是摘要、不是 Markdown 契约），由人确认后才冻结。
  现成 skill 的原文照着做：

  > Show me the complete proposed Lean declaration before freezing it.
  > … obtain independent statement audits, and show me the exact declarations for approval before freezing them

  （`scottnarmstrong/LeanAutoformalizationSkills` README）

- 冻结把**类型与定义体**钉住，允许证明体暂缺：

  > Use `--freeze` before the file names to record statement types and definition bodies in each model's `.statements` file before proving it. Freezing permits `sorry` and reports FROZEN, not a proof PASS.

  （`agent-formal-verify` `skills/formal-verify/SKILL.md`）

- 冻结后**不许原地改**命题：

  > A wrong declaration requires an author-approved versioned successor and invalidation of dependent graph/audit evidence; never repair it in place.

  （`LeanAutoformalizationSkills` `skills/lean-statement-audit/SKILL.md`）

> 注意：`sorry` / 未完成的证明**不是通过**。Draft 只能报 `FROZEN`，永远不能报 proof PASS。

### S2 建模

- **如实建模**：模型必须跟着源码走，记录它跟随的 `file:line` 与所有假设、bound、整数宽度。
  `agent-formal-verify` 要求：*Read the whole source file for each target so the model follows the code.*
- TLA+/Lean 模型是**手写**的，不是自动抽取的（见 §6 诚实边界）。
- `tlaplus/AgentSkills` 的 `tlaplus-from-source` 提供了从 C/C++/Rust 生成 TLA+ 高层模型的流程：
  Analyze → Abstract → Specify → Propose（产出 `TypeOk`、`Init`/`Next`、安全性与活性建议），
  但**改完必须跑 TLC 复检**。

### S3 证明 / 找反例

- **证明**：Lean kernel / TLAPS / Dafny / SMT 通过。
- **反例**：TLC 给出 trace，Alloy 给出模型，SMT 给出 `sat`。反例要**读回源码**：
  映射到代码事件与行号，并判定可达性（`reproduced` / `reachable at shipped settings` / `model-only`）。
- **必须用 mutation 证明"检查器会失败"**（对应 P4）：
  > it requires mutations that demonstrate the properties detect relevant bugs.

  （`agent-formal-verify` `docs/reference.md`）
  没有 mutation 的"通过"，无法区分"命题真的成立"和"检查器根本没在查"。

### S4 判决（对应 P5）

| 模式 A 判决 | 含义 | 映射到 P5 词表 |
|---|---|---|
| `PROVED` | 命题在**列明的假设与边界内**被工具内核接受 | `SUPPORTED` |
| `COUNTEREXAMPLE` | 找到反例（附 trace / 模型 / 可达性标签） | `REFUTED` |
| `UNKNOWN` | 工具超时 / `unknown` / `UNAVAILABLE` / 有 `sorry` | `UNRESOLVED` |
| `OUTSIDE_FRAME` | 反例需要 shipped 配置不会用的配置或调用者 | `OUTSIDE_FRAME` |

> `UNKNOWN` **不是**通过。工具没跑成（缺依赖）要报"未检查"，不是 pass。

### 3.1 写证明者不得自证 —— 独立 statement audit（对应 P6 / L5）

模式 A 里最危险的一步是 **statement 写错**：一个能编译、能通过 kernel 的证明，
可能证明的**不是**你要的命题。所以冻结前必须有一条与作者独立的路：

> The source reviewer must be independent of the declaration author.

（`LeanAutoformalizationSkills` `skills/lean-statement-audit/SKILL.md`）

> the agent that wrote a proof does not certify it alone.

（`LeanAutoformalizationSkills` README）

现成 skill 把它做成**两道独立 seal**（照录原文）：

> The workflow has two independent review gates:
> 1. **Statement seal.** Pin the mathematical source and any author rulings. Elaborate the complete proposed Lean declaration. An independent reviewer checks every binder, implicit argument, carrier, definition, constant dependency, and conclusion against the source. The author approves the complete command, which is frozen in a one-declaration file and manifest.
> 2. **Proof seal.** Prove the exact frozen statement using independently checked prerequisites. Integrate its proof without changing the approved statement, compile it, inspect its axioms and dependencies, and obtain a fresh source and semantics audit. Completion requires evidence from both the prover and an independent auditor.

本协议的等价动作：**用自己的 `falsifier` / `verifier` 角色做 statement audit**——
判据（statement 表）私有，作者不得自评，审计者要**逐条**核 binder / 假设 / 结论。

---

## 4. 可借的现成 skill（均已用 `gh api` 核实）

核实方式：`gh api repos/<owner>/<repo>` 取元信息 + `gh api repos/<owner>/<repo>/... -H "Accept: application/vnd.github.raw"` 取 README / SKILL.md 原文。
（本机 `raw.githubusercontent.com` 被阻断，故一律走 `gh api`；**四个仓库全部抓取成功，无失败项**。）
star / 日期为 2026-11-07 抓取值，四个仓库均为 **public**、默认分支 **main**。

| 仓库 | ★ | License | pushed_at | 支持宿主（来源见下） |
|---|---|---|---|---|
| `leanprover/skills` | 82 | Apache-2.0 | 2026-02-25 | Claude Code / Gemini CLI / Codex CLI；README 另写 "Other tools" 可指向 `skills/`。**OpenCode 未在 README 列出 → 未确认** |
| `tlaplus/AgentSkills` | 47 | MIT | 2026-02-04 | README 明确声明**不绑定任何具体 agent 基础设施**（host-agnostic） |
| `michael-denyer/agent-formal-verify` | 38 | GPL-3.0-only | 2026-11-05 | Claude Code / Codex / Pi / **OpenCode（明确支持，README + reference.md 双处声明）** |
| `scottnarmstrong/LeanAutoformalizationSkills` | 66 | CC-BY-4.0 | 2026-10-25 | README 写 "for Codex or Claude Code"。**OpenCode 未提及 → 未确认** |

### 4.1 `leanprover/skills`（Lean 官方）

> Official Agent Skills for developing with Lean 4.

提供 9 个 skill：`lean-proof`（一步一 tactic、错误优先级、先啃最难分支）、`lean-setup`（elan 工具链）、
`lean-bisect`（二分工具链回归）、`lean-mwe`、`lean-pr`、`mathlib-build`、`mathlib-pr`、`mathlib-review`、`nightly-testing`。

支持宿主（README 原文）：Claude Code（`/plugin marketplace add https://github.com/leanprover/skills.git`）、
Gemini CLI（`gemini skills install https://github.com/leanprover/skills --path skills`）、Codex CLI，
以及"Other tools: Clone this repository and point your tool at the `skills/` directory."

- **用于 OpenCode**：README 未列 OpenCode；但仓库用标准 `skills/<name>/SKILL.md` 布局
  （README 自称 [Agent Skills](https://agentskills.io)），可按 "Other tools" 方式把 `skills/` 指给 OpenCode。
  **此路径未在仓库中确认 → 标"未确认"。**
- **借什么**：Lean 证明的实操纪律（`lean-proof` 的 "Never declare a proof complete while `sorry` placeholders or error diagnostics remain."），
  以及 toolchain setup / bisect 流程。
- 该仓库自带评测习惯（"Every skill should be validated by test cases that demonstrate it actually improves agent performance."），
  verdict 词表为 `satisfactory` / `not_needed` / `needs_improvement`——与本协议 L5 的"独立复核"同构。

### 4.2 `tlaplus/AgentSkills`（TLA+ 官方）

> A collection of agent skills for working with TLA+ specifications. These skills enable the AI assistant to perform common TLA+ modeling tasks with proper structure and conventions.

提供 3 个 skill：`tlaplus-add-variable`（加变量不变语义）、`tlaplus-split-action`（拆分 action）、
`tlaplus-from-source`（从 C/C++/Rust 源码生成 TLA+ 高层模型：Analyze → Abstract → Specify → Propose，
产出 `TypeOk`、`Init`/`Next`、安全性/活性建议）。

支持宿主（README 原文）：

> Note 1: "Agent skills" is meant in a general sense, and is not tied to any specific agent infrastructure (e.g., Claude or Cursor Skills).

- **用于 OpenCode**：仓库**明确声明不绑定任何宿主**，且为标准 `SKILL.md` 布局 → 可直接用。
  （逐条安装命令未在仓库给出，故标"host-agnostic，OpenCode 可用"，非逐字确认。）
- **注意**：README 明确"改完要跑 TLC"（"Run TLC - After modifications, run the TLA+ model checker to verify the specification still works"）；
  另提到 TLA+ 的 VSCode/Cursor 扩展内置 **TLA+ MCP server** 与知识库文章（"also contains TLA+ MCP server with lots of useful tools"）。
- **借什么**：官方 TLA+ 建模工作流 + "from-source" 的建模流程。

### 4.3 `michael-denyer/agent-formal-verify`（已支持 OpenCode）

> TLA+ model checking and Lean proofs for coding agents, with explicit tool setup.

> A skill for Claude Code, Codex, Pi and OpenCode that implements the targeted formal-verification method …

OpenCode 支持（原文）：

> ### OpenCode
> OpenCode 2.2 or later. Run in your terminal:
> `opencode plugin add agent-formal-verify`

（`docs/reference.md`）> In OpenCode, request `setup` or `formal-verify` by name; the agent loads it through the `skill` tool. The plugin's `opencode.mjs` registers the two skills from `skills/` and leaves any existing skill with the same name in place. It adds no tools, commands, agents or MCP servers. It needs OpenCode 2.2 or later; with an older version, use a skills-only installation.

本地 checkout 也可用（`opencode.json` 的 `plugins` 里加绝对路径）。

提供 2 个 skill：`setup`（装工具）与 `formal-verify`（建模/检查）。
覆盖三件工具：**TLA+ + TLC**（线程交错）、**Lean 4**（算术/顺序不变量）、**Kani**（有界 Rust）。
带 **mutation 检查**与 **CI** 重跑。

#### 工具安装前置（这是"能不能跑"的关键）

> Run `setup` once to prepare the shared Java, Python, TLC, elan, Lean, Rust and Kani tools.

- **TLC**：插件**不下载** TLC——
  > The plugin does not download TLC. Save `tla2tools.jar` from the TLA+ release … as `~/.cache/tla/tla2tools-v1.7.4.jar`
  需要 JDK + Python 3 + `sha256sum`/`shasum` 校验 JAR。
- **Lean**：需 elan；检查器要求 **Lean 4.20.0 或更高** pin；`setup.sh lean <project>` 按 `lean-toolchain` 装。
- **Kani**（Rust）：
  > Install Rust and Cargo, then install Kani 0.68.0
  `cargo install --locked kani-verifier --version 0.68.0` + `cargo kani setup`；Kani 支持 Linux/macOS x86_64/aarch64。

#### 边界（它自己写明）

> A passing model establishes its stated properties under its assumptions. Reports must identify omitted code constraints and unfinished proofs.

> These models do not check memory ordering below the mutex. Keep the project's ThreadSanitizer or race-detector checks.

> A passing TLA+ or Lean model establishes its stated properties under its assumptions. It describes the code by hand. … Neither result establishes correctness of the whole program.

### 4.4 `scottnarmstrong/LeanAutoformalizationSkills`

> Portable Lean 4 autoformalization skills for Codex and Claude Code
> （**出处：GitHub 仓库 description 字段，非 README 正文**）

> The central goal is to prove **the theorem the mathematical source actually states**. A successful Lean build checks the formal statement; the audit workflows also check that its hypotheses, definitions, quantifiers, and conclusion match the intended mathematics.

提供 12 个 skill，含 `lean-workflow`、`lean-statement-audit`、`lean-orchestrator`、
`build-proof-dependency-graph`、`lean-proof-patterns`、`lean-search-discovery`、`lean-project-architecture` 等。

支持宿主（README 原文）：**Codex 或 Claude Code**。装法：
`python3 scripts/install_skills.py --agent codex|claude [--project <lean-project>]`，
Codex 用 `~/.agents/skills/`、Claude Code 用 `~/.claude/skills/`；`--dest` 可指定目录。

- **用于 OpenCode**：README **未提及 OpenCode** → **未确认**。
  理论上可用 `--dest` 指到 `~/.config/opencode/skills/`，但这是**推断，仓库未文档化**。
- **前置**：
  > You need Codex or Claude Code. The helper scripts require Python 3.10 or newer … These skills provide instructions and checks; they do not install Lean or a proof-search service.
  也就是说，要真正检查证明，得**自备 Lean/Lake 项目**。
- **借什么（本文件最重要的一块）**：
  - **两道 seal**（statement seal + proof seal，见 §3.1）；
  - **写证明者不得自证**（"the agent that wrote a proof does not certify it alone."）；
  - **冻结前人工确认**（"Show me the complete proposed Lean declaration before freezing it."）；
  - `lean-statement-audit` 的 fail-closed 检查：五桶 binder 判定、定义体/特征化审计、
    `#print axioms`、以及"**EXCESS 假设 = 自动失败**"（把没证明的义务塞进假设里不算证明原命题）。

> 注：该仓库 README 里仍写着 "While the repository is private, cloning requires an account with access."，
> 但 2026-11-07 经 GitHub API 核实该仓库为 **public**（`private=false`）——README 文案滞后，实际可公开克隆。

---

## 5. 与主干的关系

模式 A **不是**另一套协议，只是主干在"可命题化"情形下的一个分叉：

| 主干 | 模式 A 的对应 |
|---|---|
| **P0** 先验冻结（L1） | **S1 冻结 statement**（人工确认后才冻结） |
| **P1** 分解与逐级判定 | 把命题拆成引理/子目标（每个子目标一条 statement 行） |
| **P2** 需求↔代码绑定 | statement 行的 `bindings` / `file:line` |
| **P3** 判别实验 | 建模 + 跑一次判别检查（TLC / Lean / Kani / Alloy / Dafny / SMT） |
| **P4** 证伪工具 | **反例** + **mutation**（证明"检查器真的会失败"） |
| **P5** 判决 | `PROVED / COUNTEREXAMPLE / UNKNOWN / OUTSIDE_FRAME` → 映射到五值词表 |
| **P6** 独立证伪者（L5） | **独立 statement audit**（写证明者不得自证） |

铁律如何落地：

- **L1**：statement 必须先冻结再证明；不许边证边改命题。
- **L4（判据外置）**：判定交给**工具内核**（Lean kernel 的 trusted kernel、TLC 的穷举、SMT 求解器），
  不是 AI 说"我觉得证完了"。`sorry` 这种"AI 说没证完但先放着"的占位符，不算证据。
- **L5（完成 ≠ 通过）**：证明通过 ≠ statement 正确；必须由**独立于作者**的一方做 statement audit，
  两条 seal 都过才算完成。

> **模式 A 只是把 P4/P5 的「证据」从"命令输出/指标"换成"证明/反例"，
> 其余一律照旧——尤其是 L1 的"先冻结"、L4 的"判据外置"、L5 的"独立证伪"。**

---

## 6. 诚实边界

1. **数学形式化 ≠ 需求正确。** 证明只保证"你写下的那条命题为真"，不保证"命题就是用户想要的"。
   > The central goal is to prove **the theorem the mathematical source actually states**.

   statement 写错，则证明**毫无意义**——所以才有独立 statement audit。

2. **证明 `B → A` 不等于证明了源命题 `A`。** 原文：

   > For a theorem, proving B → A is not proving source statement A, even if B is proved elsewhere.

   同理，把没证明的步骤塞进假设里（EXCESS binder）也不算证明原命题。

3. **通过只在"列明的假设、边界、scope 内"成立。** 原文：

   > A passing model establishes its stated properties under its assumptions. Reports must identify omitted code constraints and unfinished proofs.

   TLA+ 的 TLC 只穷举**有限小实例**；Kani 只覆盖**声明的输入与 unwind 界**；Lean 证明也要列出假设与整数宽度。

4. **模型是手写的，不是自动抽取的。** TLA+/Lean 模型"describes the code by hand"，
   模型与真实代码的偏差是**已知风险**，要靠 `file:line` 绑定 + differential testing 缓解。

5. **形式化不覆盖整个程序。** 原文：

   > Neither result establishes correctness of the whole program.

   例如 `agent-formal-verify` 明说它**不检查 mutex 以下的内存序**（仍需 ThreadSanitizer / race detector）。

6. **`UNKNOWN` / 超时 / `UNAVAILABLE` 不是通过。** 工具没跑成要报"未检查"并给补救方法，不能当 pass。

7. **`sorry` 不是证明。** 未完成的证明只能报 `FROZEN_UNPROVED`，永远不能当作 PROVED。

8. **本文件是 Markdown 指引，不构成运行期闸门。** 硬约束靠工具命令真跑 + 独立 statement audit 兜底。

---

## 附：快速自查（模式 A）

- [ ] 需求已写成可判真假的 statement（不是"更健壮"这种模糊话）
- [ ] statement 在证明**之前**已冻结，且有**人工确认**记录
- [ ] 冻结的是**完整正式声明**，不是摘要
- [ ] 每个 statement 行都有 `bindings`（`file:line`）与 `assumptions` / 边界
- [ ] 选工具时对照过 §2，不是凭印象
- [ ] 跑过 **mutation**，证明"检查器真的会失败"
- [ ] **独立于作者**的一方做过 statement audit，且两条 seal（statement + proof）都过
- [ ] 判决落在 `PROVED / COUNTEREXAMPLE / UNKNOWN / OUTSIDE_FRAME`，且 `UNKNOWN ≠ 通过`
- [ ] 报告写明了"边界内成立 + 哪些没覆盖 + 哪些是手写模型"

**Can't check all boxes? You skipped the protocol. Start over.**
