# P4 — 证伪工具（四张可复用判据表）

> 本阶段的存在理由：**P3 决定"跑什么实验"，P4 决定"实验结果怎么算数"。**
> 没有工具化判据时，人会退化成"我觉得这个改动是对的"。本阶段把"算不算通过"写成
> **可逐条对照的表格 + 封闭判决词**，判定就不再依赖语气。
>
> 四张表**改编自 `trailofbits/skills` 的四个技能**（原文已落盘于本工作区，逐句可核；
> 路径见每节标题下的「来源」）。原文全是英文，本文保留关键机制的原句（引用块 `>`），
> 中文为译注与改造。用法：为每一轮判别实验挂上**一张**与改动类型匹配的表；
> **表里没有的元素不写进判据**（与 P2「先表后码」同构）。

## 0. 选表指引

| 你要回答的问题 | 用哪张表 | 封闭判决词 |
|---|---|---|
| 这真的算一个 bug / 漏洞吗 | §1 fp-check 六道 gate | `TRUE POSITIVE` / `FALSE POSITIVE` |
| 测试真的覆盖了这段代码吗 | §2 mutation-testing | `equivalent` / testing gap / `unresolved` |
| 补丁真的把这个问题修好了吗 | §3 post-patch-validation | `complete` / `incomplete` + `PPV_REACHED` |
| 这次改动把别的功能改坏了吗 | §4 regression-hunt 9-check 矩阵 | 6 个封闭结果词 |

> 四表共有的形式：**"通过条件"与"失败条件"分列**，且判定是**合取（`与`）**——
> 全部通过条件满足才判"通过"，任一失败条件命中即判"失败"；不确定**不等于**通过。

---

## 1. fp-check — 六道 gate

**来源**：`_research/dev-skill-refs/trailofbits/fp-check__skills__fp-check__references__gate-reviews.md`
（配套 `fp-check__skills__fp-check__SKILL.md`、`...__references__false-positive-patterns.md`、
`...__references__standard-verification.md`、`...__references__deep-verification.md`）

原文开场（`gate-reviews.md`）：

> Before reporting ANY bug as a vulnerability, all six gate reviews must pass.

**判定形式 = `Pass 条件 | Fail 条件` 两列 + 六道 gate 全过**
（`与`关系：`All gate reviews pass → TRUE POSITIVE`；`Any gate review fails → FALSE POSITIVE`）。

| # | Gate | 判据（Criterion） | Pass 条件 | Fail 条件 |
|---|---|---|---|---|
| 1 | **Process** | 所有阶段都完成且有留档证据 | 每个阶段都有证据 | 阶段缺少具体证据 |
| 2 | **Reachability** | 攻击者能到达并控制漏洞处的数据 | 有攻击者可控路径的明确证据，且 PoC 确认 | 无法证明攻击者可控或可到达 |
| 3 | **Real Impact** | 利用后导致 RCE、提权或信息泄露 | 有具体场景的直接影响 | 只是运行稳健性问题 |
| 4 | **PoC Validation** | PoC（伪代码 / 可执行 / 单测）展示攻击路径 | 展示出攻击者控制、触发与影响 | PoC 未能展示攻击路径或影响 |
| 5 | **Math Bounds** | 数学分析确认漏洞条件可能成立 | 代数证明该条件可能成立 | 数学证明校验会阻止它 |
| 6 | **Environment** | 没有环境防护能完全阻止利用 | 防护不能消除漏洞 | 环境防护完全阻断利用 |

**判决格式（封闭）**：

- `TRUE POSITIVE`：六 gate 全过 → `BUG #N TRUE POSITIVE — [brief vulnerability description]`
- `FALSE POSITIVE`：任一 gate 失败 → `BUG #N FALSE POSITIVE — [brief reason for rejection]`

原文示例（说明"失败要指出是哪一道 gate"）：

> ```
> BUG #3 FALSE POSITIVE — Integer underflow in packet_handler.c:142
>   Gate 5 (Math Bounds) FAIL: validation at line 98 ensures packet_size >= 16,
>   making (packet_size - header_size) >= 8. Underflow is mathematically impossible.
> ```

**配套的 13 项 FP 检查清单**（原文 `false-positive-patterns.md`：`Apply ALL items in this checklist to EACH potential bug`）——
逐条对**每个**候选 bug 应用，缺一即不完整：1 Trace Full Validation Chain（含 1a Map Complete Conditional Logic Flow）、
2 Identify Defensive Programming Patterns、3 Confirm Exploitable Data Paths、4 Understand Data Source Context、
5 Analyze Bounds Validation Logic、6 Verify TOCTOU Claims、7 Understand API Contract and Trust Boundaries、
8 Distinguish Internal Storage from External Input、9 Don't Confuse Pattern Recognition with Vulnerability Analysis、
10 Verify Concurrent Access is Actually Possible、11 Assess Real vs Theoretical Security Impact、
12 Understand Defense-in-Depth vs Primary Controls、13 Apply the Checklist Rigorously, Not Superficially。

> ⚠️ **gate 数只有"六道"，不要数错。** 13 项 FP 清单与 Standard 路径的两处升级检查点、
> Deep 路径的 7/13 问，**都不是 gate**，别把它们算进 gate 数量。

**升级检查点（2 个，原文 `standard-verification.md`）**：Standard 路径本是一条线性清单，
出现下列复杂度即升级到 Deep：

> 1. **After Step 1 (Data Flow)**: Escalate if 3+ trust boundaries, callbacks/async control flow, or ambiguous validation chain
> 2. **After Step 5 (Devil's Advocate)**: Escalate if any question produces genuine uncertainty you cannot resolve

---

## 2. mutation-testing — mutant 4 个 tier + 等价 mutant 5 步判定

**来源**：`_research/dev-skill-refs/trailofbits/mutation-testing__skills__mutation-testing__references__severity-classification.md`、
`...__references__equivalent-mutants.md`、`...__workflows__analyzing-results.md`、`...__SKILL.md`

总判据（原文 `severity-classification.md`）：

> Severity depends on the impact type of the mutated code, not the mutation operator used. ... Always classify based on what the code does, not how it was mutated.
> The tiers prioritize testing gaps. They do not establish that the original code contains a vulnerability.

### 2.1 mutant 严重度 4 个 tier

| Tier | 名称 | 判定该代码属于本 tier 的准则（原文 Decision Criteria 归纳） |
|---|---|---|
| **Tier 1** | Critical — Security-Sensitive | 强制"谁能调用"（访问控制 / 授权）；验证身份或凭据（认证、签名校验）；防重入或并发攻击；校验系统边界上的外部输入；做密码学操作（哈希 / 签名 / 验证）；守住提权路径（管理员函数、升级） |
| **Tier 2** | High — Financial/State Integrity | 转移代币或原生币；计算费用 / 份额 / 汇率 / 利息；管理余额或账本；强制状态机迁移顺序；用 oracle 相关价格计算；强制滑点 / 截止时间保护；处理清算或抵押阈值 |
| **Tier 3** | Medium — Business Logic | 校验配置或参数（非安全边界）；管理数据结构（数组 / 映射 / 队列）；实现协议工作流逻辑（治理 / 投票 / 质押奖励）；处理与外部合约的集成点（回调 / 返回值）；非安全路径的错误处理或 revert 条件 |
| **Tier 4** | Low — Observability | 发出事件或日志；仅供展示的 view/pure/getter 返回值；错误消息字符串（非 revert 条件本身）；NatSpec 或文档映射的常量；监控 / 调试输出 |

Tier 2↔Tier 3 边界判据（原文）：

> ask: if this code were wrong in production, would it result in loss of funds or incorrect accounting? If yes, Tier 2. If it would cause incorrect behavior without direct financial impact, Tier 3.

（还给出边界覆盖：影响安全的配置参数按 **Tier 1**；承载价值的外部调用出错按 **Tier 2**；
被状态变更逻辑消费的 getter 按 **Tier 2**；下游消费者依赖的事件发射按 **Tier 3**。）

### 2.2 等价 mutant 判定程序（5 步，缺一不可）

原文 `equivalent-mutants.md`：

> Before classifying a mutant as equivalent, complete all five checks:

| 步 | 检查 | 通过的含义（判"等价"方向） | 存疑时的处置（判"非等价 / 待定"方向） |
|---|---|---|---|
| 1 | **Type context** | 确定参与变异的全部变量类型；无符号整数 / 布尔 / 枚举各有其等价模式 | 类型未定 → 不能判等价 |
| 2 | **Reachability** | 变异代码在执行中确实可达 | 死代码里的变异平凡等价；但"当前测试没覆盖"**不等于**不可达 |
| 3 | **Downstream consumption** | 变异后的值从未被后续逻辑读取 / 使用 | 若该值被消费，则变异有可观察效果 → 非等价 |
| 4 | **Semantic comparison** | 在类型约束内的所有输入上，原码与变异码行为一致 | 出现任一不同结果 → 非等价 |
| 5 | **Distinguishing test attempt** | 尝试构造一个能区分原码 / 变异码的具体输入；查过边界值、类型极值、领域边界后仍构造不出 | 找到区分输入 → 非等价，并把该输入记为建议测试用例 |

保守原则（原文）：

> A mutant is equivalent only when the analysis establishes identical observable behavior. If a check is uncertain, retain it as unresolved and explain what evidence is missing. Uncertainty alone does not establish a testing gap.

**"看起来等价、其实不是"的反面清单**（原文，本身即为判据；不得判为 false positive）：
Boundary Value Changes（`>` ↔ `>=`，除非边界值可证不可达）、Off-by-One in Loop Bounds、
Removed Event Emission（应判 **Tier 4**，不是等价）、Swapped Non-Commutative Operations、
Undefined Behavior Introduction（C/C++）。

**正面等价模式**（可判等价的寥寥几种）：Unsigned Comparison Equivalence（无符号 `x > 0` ≡ `x != 0`）、
Boolean Double-Negation、Tautological Bound Checks（无符号 `x >= 0` ≡ `true`）、Dead Code Mutations、
Redundant Assignment Mutations、Commutative Operation Reordering。

### 2.3 mutant 状态词（原文 `SKILL.md` "What Results Mean"）

| 状态 | 含义 |
|---|---|
| `Caught` / `TestFail` | 测试检出了该变异（好） |
| `Uncaught` | 测试没检出——需查源码区分"测试缺口"还是"等价变异" |
| `Timeout` | 测试超时——**不确定**，不是覆盖的证据 |
| `Skipped` | 同一行更严重的变异未被捕获，较轻的被跳过 |

---

## 3. post-patch-validation — 7 类 check + `PPV_REACHED`

**来源**：`_research/dev-skill-refs/trailofbits/post-patch-validation__skills__post-patch-validation__SKILL.md`
（配套 `...__references__evidence-model.md`、`...__workflows__validate-patch.js`）

原文 `## Evidence Contract`：

> The runner rejects incomplete plans. Supply at least one check of every kind:

**判定形式 = 7 类 check 每类至少 1 个（`与`关系：缺任一类，runner 直接拒绝整份 plan）。**

| Kind | Required observation（这类 check 要观测到什么） |
|---|---|
| `control` | 良性的 harness 在 base 与 patch 上**都**成功 |
| `exploit` | 原始安全断言在 base **失败**、在 patch **成功** |
| `variant` | 一个不同的同根因变体在 base **失败**、在 patch **成功** |
| `behavior` | 不受影响的行为成功，且选定输出**逐字节一致** |
| `regression` | 针对性的非安全回归检查在**两个** revision 上都成功 |
| `security` | 相邻 / 新引入漏洞的检查在 base 与 patch 上都成功 |
| `suite` | 既有项目测试套件 / sanitizer / 确定性 fuzz campaign 在 patch 上成功 |

### 3.1 必须证明"真的跑到了"——`PPV_REACHED`

原文：

> A nonzero exit does not mean the vulnerability reproduced. An import error, a failed build, a missing dependency, and a failed safety assertion all exit nonzero and are indistinguishable to the runner. Every `exploit` and `variant` check must print and flush `PPV_REACHED` immediately before it evaluates its assertion, on both revisions:

> The token is also in the environment as `PPV_REACHED_MARKER`. It must land on **stdout, as a line of its own**. ... A run without it leaves a `marker_missing` gap.

**要点**：非零退出 ≠ 漏洞复现（import 错误、构建失败、缺依赖、断言失败，四者都非零，runner 无法区分）。
所以 `exploit` / `variant` 两类 check 必须在**评估断言之前**、在**两个 revision 上**都打印并 flush `PPV_REACHED`，
且必须落在 **stdout 的独立一行**（stderr 不扫描——Python `SyntaxError` 会回显源码，否则会误满足）。
缺它 → 留下 `marker_missing` gap。

**side-blind 防作弊**（原文）：

> These checks also run **side-blind**. `{side}` is not expanded for them, `PPV_SIDE` is absent ... An assertion that can see which revision it is on can assert on *that* instead of on the code.

### 3.2 assessment 与退出码（原文）

`result.json` schema 2.0 的 `assessment` 含 `status` / `findings` / `gaps` / `human_review_required`：

> Status is `complete` when all required checks produced usable evidence, even if some checks found failures. Status is `incomplete` when any gap remains.

> The runner exits 0 for complete checks with no findings, 1 for complete checks with findings, 10 for incomplete validation, and 64 for invalid inputs.

**证据层级 3 档**：`source`（仅源码 / patch 不变量）、`build`（编译或分析，但未执行所述行为）、
`runtime`（执行所述行为及其安全断言）。

**workflow 判决 4 态**（原文）：`NEEDS_REPAIR`、`BLOCKED`、`READY_FOR_HUMAN_REVIEW`、`REVIEW_REQUIRED`。
`NEEDS_REPAIR` 即便其它 check 留了 gap 也返回受支持的失败；`BLOCKED` 表示证据不完整且无受支持失败。

> 关键：**"supplied checks 全过"也要人复核**（`Passing supplied checks still requires human review before acceptance.`）。

---

## 4. regression-hunt — 9-check 判决矩阵 + 6 个封闭结果词

**来源**：`_research/dev-skill-refs/trailofbits/regression-hunt__references__evidence.md`、
`...__docs__regression-definition.md`、`...__docs__report-definitions.md`、`...__skills__regression-hunt__SKILL.md`

### 4.1 回归定义（原文）

> **A regression is a new defect introduced by the selected change that breaks previously correct, supported behavior on a reachable user or attacker path.**

> Before confirming a regression, establish that the expected behavior is supported, the failure is reachable, the behavior worked before the patch, it fails afterward, and the patch introduced the defect.

4 类回归（按优先级）：Security / Functional / Performance / Build-test。

### 4.2 9-check 判决矩阵（判定的核心形式）

原文 `references/evidence.md`：

> For confirmation also provide ... `checks` for each: `supported_behavior`, `reachability`, `introduced_defect`, `incomplete_fix`, `latent_bug`, `preexisting_bug`, `intentional_change`, `unsupported_expectation`, `security_scope`. Each check is `{"conclusion":"SUPPORTED", "reason":"explanation", "evidence":["file/path"]}`.
> **Confirmation requires SUPPORTED for the first three checks, REFUTED for the five exclusion checks, and SUPPORTED for security scope (NOT_APPLICABLE for other categories). UNKNOWN prevents confirmation.**

**"确认回归"= 3 项必须 SUPPORTED ∧ 5 项排除必须 REFUTED ∧ security_scope 必须 SUPPORTED 或 N/A**
（`与`关系；任一项 `UNKNOWN` 即阻止确认）：

| # | check | 必须的结论 | 含义 |
|---|---|---|---|
| 1 | `supported_behavior` | **SUPPORTED** | 期望行为是"受支持的"（含正确拒绝非法输入） |
| 2 | `reachability` | **SUPPORTED** | 该失败在用户或攻击者路径上可达 |
| 3 | `introduced_defect` | **SUPPORTED** | 缺陷确由本次改动引入（patch 前正常、patch 后失败） |
| 4 | `incomplete_fix` | **REFUTED** | 排除"修复漏了输入源 / 调用方 / 使用路径" |
| 5 | `latent_bug` | **REFUTED** | 排除"本次变更暴露了既有缺陷" |
| 6 | `preexisting_bug` | **REFUTED** | 排除"失败在改动前就可达" |
| 7 | `intentional_change` | **REFUTED** | 排除"这是有意变更的行为" |
| 8 | `unsupported_expectation` | **REFUTED** | 排除"期望本身不被支持（行为契约外）" |
| 9 | `security_scope` | **SUPPORTED** 或 **N/A** | 该候选确在安全范围内；其它 category 填 `NOT_APPLICABLE` |

> `UNKNOWN prevents confirmation.` —— 证据缺失**不等于**已排除；它阻止确认，理由必须带引用证据。

### 4.3 6 个封闭结果词（原文 `docs/report-definitions.md`）

| 结果词 | 含义 |
|---|---|
| `REPRODUCED_REGRESSION` | 在实机 S0/S1 上证明的新缺陷，经独立 replay 与 adjudicate |
| `INCOMPLETE_FIX` | 预期修复漏掉了某个输入源、调用方或使用路径 |
| `LATENT_BUG` | 本次变更**暴露**了一个既有缺陷 |
| `PREEXISTING_BUG` | 失败在本次变更**之前**就已可达 |
| `REJECTED` | 引用证据推翻了某个必需的回归要件 |
| `UNRESOLVED` | 所需证据、执行或评审缺失 / 相互矛盾 |

> `Only REPRODUCED_REGRESSION contributes to confirmed totals.` —— 只有 `REPRODUCED_REGRESSION` 计入"已确认"总数。
> `Missing proof is unresolved, not rejected.` —— 缺证据记 `UNRESOLVED`，不是 `REJECTED`。

其它标签：S0/S1 = 变更前 / 后（`S0 and S1 mean before and after the complete selected change, not severity.`）；
category 为 `VULNERABILITY` / `FUNCTIONAL_BUG` / `PERFORMANCE` / `BUILD_TEST`；
severity 4 档（Low/Medium/High/Critical）、likelihood 3 档（Low/Medium/High），
verification level 为 `isolated`（host 记录：确认 fresh context + 私有环境）/ `shared-host`（agent 记录：独立 agent 但共享机）。

---

## 5. 四表共用公约数（写判据时照此检查）

1. **证据对象必须结构化**（固定列 / JSON 字段），不是散文。
2. **假阳性必须逐条排除并引用证据**（fp-check 13 项、regression-hunt 5 个 REFUTED check、mutation 反面清单）。
3. **不确定 ≠ 通过**：`retain as unresolved` / `UNKNOWN prevents confirmation` / `Missing proof is unresolved, not rejected`。
4. **产物落文件优先于聊天输出**（result.json / report.md / 证据文件）。
5. **判决词封闭枚举**，不许自造；判决必须能追到"哪一条 check / 哪一道 gate"。
