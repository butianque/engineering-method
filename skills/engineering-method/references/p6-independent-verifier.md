# P6 — 独立证伪者

> 本阶段的存在理由：**P5 的结论不能由做这件事的人自己下。**
> 完成（completion）与通过（pass/fail）是**两件事**；作者的自评不算验证，
> 报告本身只是"未验证的主张"。本阶段把"谁来判、按什么判、判不出来怎么办"写死。

本阶段由三部分拼成：① superpowers 的**审验者硬规则**（§1–§4）；
② **判据私有**的评估台机制（§5）；③ 配套的**独立证伪者 agent `falsifier`**（§6）。

---

## 1. superpowers `task-reviewer-prompt` 的三条硬规则

**来源**：`_research/dev-skill-refs/superpowers/skills__subagent-driven-development__task-reviewer-prompt.md`
（配套 `...__skills__subagent-driven-development__SKILL.md`）

### 规则 A — 报告 = 未验证的主张（Do Not Trust the Report）

> Treat the implementer's report as unverified claims about the code. It may be incomplete, inaccurate, or optimistic. Verify the claims against the diff. Design rationales in the report are claims too: "left it per YAGNI," "kept it simple deliberately," or any other justification is the implementer grading their own work. Judge the code on its merits — a stated rationale never downgrades a finding's severity.

**要点**：实现者的报告只是**关于代码的、未经验证的主张**；报告里的设计理由**同样是主张**，
不能因为它说了理由就降低发现（finding）的严重度。

### 规则 B — 作者不得自评（The plan's authorship does not grade its own work）

原文（同文件，Calibration 节）：

> If the plan or brief explicitly mandates something this rubric calls a defect (a test that asserts nothing, verbatim duplication of a logic block), that IS a finding — report it as Important, labeled plan-mandated. The plan's authorship does not grade its own work; the human decides.

配套原文（SKILL.md）：

> Never skip the task review, and never accept a report missing either verdict — spec compliance AND task quality are both required. Implementer self-review never replaces the task review; both are needed.

**要点**：即便"计划本身要求了这个缺陷"，**那也是 finding**（报为 Important，标注 `plan-mandated`）。
**计划 / 报告的作者没有给作品打分的资格，由人来裁定。**

### 规则 C — 审验者不得预判，也不得再派生审验者

**不得预判**（原文 `SKILL.md`）：

> Do not pre-judge findings for the reviewer — never instruct a reviewer to ignore or not flag a specific issue. ... If the prompt you are writing contains "do not flag," "don't treat X as a defect," "at most Minor," or "the plan chose" — stop: you are pre-judging, usually to spare yourself a review loop.

**不得再派生审验者**（原文 `task-reviewer-prompt.md`，`## You Do Not Dispatch Subagents`）：

> Do all of this review yourself. Never spawn a subagent to review part of the diff, and never spawn another reviewer for a second opinion. This process already provides every review seat the work gets; a reviewer you spawn duplicates one of them at full cost, and its verdict counts for nothing.

**要点**：① 对审验者说"别标这条" / "这条最多算 Minor" / "计划就是这么定的" = **预判，违规**；
② 审验者自己再派一个审验者 = 重复评审席位，**其 verdict 无效**。这两条删除
了"把审查做成表演"的两个出口。

**审验者必须交的产物**（原文）：

> **Reviewer returns:** Spec Compliance verdict (✅/❌/⚠️), Strengths, Issues (Critical/Important/Minor), Task quality verdict

其中质量量尺为 **Critical (Must Fix) / Important (Should Fix) / Minor (Nice to Have)**；原文对 Important 的定义：

> Important means this task cannot be trusted until it is fixed: incorrect or fragile behavior, a missed requirement, or maintainability damage you would block a merge over — verbatim duplication of a logic block, swallowed errors, tests that assert nothing.

---

## 2. `adversarial-reviewer` 的三个敌对 persona

**来源**：`_fanout/dev-skill-research/s2-rigorous-methods.md` §2.4 实例 C（引用仓库
`alirezarezvani/claude-skills`，`engineering-team/skills/adversarial-reviewer/SKILL.md`；
URL 见文末）。

**强制"每个角色必须找出问题"**（原文）：

> Each persona MUST find at least one issue — no "LGTM" escapes.
> **IMPORTANT:** Do not soften findings. Do not hedge. ...

**三个结构性反例角色**（原文）：

> - **Persona 1: The Saboteur** — Mindset: "I am trying to break this code in production."
> - **Persona 2: The New Hire** — Mindset: "I just joined this team. I need to understand and modify this code in 6 months with zero context …"
> - **Persona 3: The Security Auditor** — Mindset: "This code will be attacked. My job is to find the vulnerability before an attacker does."

**要点**：三个角色对应三种**互不重叠的失败模式**——破坏者查"能不能弄坏"，
新人查"六个月后无上下文能不能读懂 / 改对"，安全审计员查"攻击者会先发现什么"。
"每个角色至少一条 finding、不许 LGTM"封死了"看起来没问题就放行"。

---

## 3. 交叉升格规则（Promotion rule）

**来源**：同 §2（原文）：

> **Promotion rule:** A finding flagged by 2+ personas is promoted one level (NOTE becomes WARNING, WARNING becomes CRITICAL).

**要点**：一个 finding 若被 **2 个及以上 persona 独立命中**，严重度升一级
（NOTE → WARNING，WARNING → CRITICAL）。多角色交叉命中 = 该问题不在单一视角的盲区里，
严重度必须反映这一点。

---

## 4. verdict 定义（BLOCK / CONCERNS / CLEAN）

**来源**：同 §2（原文，可操作判据）：

> - **BLOCK** — 1+ CRITICAL findings. Do not merge until resolved.
> - **CONCERNS** — No criticals but 2+ warnings.
> - **CLEAN** — Only notes. Safe to merge.

| verdict | 触发条件 | 处置 |
|---|---|---|
| `BLOCK` | 有 ≥1 个 CRITICAL | 解决前不得合并 |
| `CONCERNS` | 无 CRITICAL，但有 ≥2 个 WARNING | 须处理 |
| `CLEAN` | 只有 NOTE | 可安全合并 |

---

## 5. 判据私有（criteria private）— 防"面向考点优化"

**来源**：`_fanout/dev-skill-research/s2-rigorous-methods.md` §2.4 实例 E，引用 `superpowers-evals / Quorum`
（URL：https://github.com/prime-radiant-inc/superpowers-evals ）。

原文：

> New scenarios use a user-like conversation followed by a fresh evidence-based assessment against private criteria plus deterministic post-checks.
> … Quorum keeps the criteria private and starts a fresh assessor role after capture and independent checks. A delivered answer or refusal completes the conversation, even when it is wrong. The later assessment and checks determine the grade, so **completion and pass/fail are separate facts** …

> quorum produces a three-valued verdict:
> - `pass` - Gauntlet-Agent passed and every post-check passed.
> - `fail` - Gauntlet-Agent failed, or a post-check failed.
> - `indeterminate` - setup/pre-check/capture/quorum failure, Gauntlet `investigate`, or empty trace when trace checks are present.

**要点**：

1. **判据对被验者保密**（`criteria private`）——被验者不知道考点，就无法面向考点优化；
2. 交付答案或拒绝**都算对话结束**（`A delivered answer or refusal completes the conversation, even when it is wrong.`），
   评分在**事后**由**全新**的评估者角色 + 确定性 post-check 决定；
3. 因此 **完成（completion）与通过（pass/fail）是两个独立事实**——这正是 P5/P6 的分界：
   P5 只产出"完成"的事实，**通过与否交给独立的 P6 判**。

> 与 P0 的先验预测天然配套：**预测写下来（冻结），判据不告诉被验者。**

---

## 6. 配套 agent `falsifier`（本 skill 自建）

P6 需要一个**专职证伪者**，它不是"再来一个审验者"，而是**任务是找出反例**的独立 agent。

### 6.1 职责

- 拿到 P0 冻结的假设 + P4 的判据表，**目标只有一个：找出 ≥1 个能推翻它的反例 / 反证据**。
- 它**不改代码、不修问题、不下最终判决**——只产出一个"证伪尝试判决"（见 6.3）与证据。
- 它必须把**尝试过但失败**的证伪路径也写下来（"我试了 A/B/C 都没推翻"本身是证据；
  只说"没找到问题"不是证据）。

### 6.2 硬限制

| 限制 | 值 | 为什么 |
|---|---|---|
| 文件编辑 | `edit: deny` | 证伪者不得改被验代码（改了就不是独立证据，也无法区分"原样是否成立"） |
| 派生 subagent | `subagent: deny` | 与 §1 规则 C 同构：派生审验者 = 重复席位，verdict 不计；证伪者也**不得**再派生 |
| 最低产出 | 必须找出 ≥1 个反例 | `no "LGTM" escapes` 的证伪版：不给出反例尝试就等于没做 |

### 6.3 falsifier 的四值判决（⚠️ 与 P5 五值**不是同一套**）

falsifier 对**每一次证伪尝试**给出下列**四值之一**（本 skill 自创的证伪专用词表）：

| 四值 | 含义 |
|---|---|
| `REFUTED` | 找到 ≥1 个可复现的反例，命题被推翻 |
| `NOT_REFUTED` | 穷尽合理搜索后**仍未找到**反例（⚠️ 明确**不等于**"已证明"；只是"这次没推翻"） |
| `UNRESOLVED` | 因环境 / 权限 / 证据不足，证伪尝试**未完成**（不允许当作通过） |
| `OUTSIDE_FRAME` | 观察到与命题无关、但值得记录的反常——可能说明当前框架不完整 |

> ⚠️ **三套判决词必须分清，不许混用：**
>
> | 层级 | 归属 | 词表 |
> |---|---|---|
> | 树节点判决（四值） | P1 每级分解节点 | `SUPPORTED` / `REFUTED` / `UNRESOLVED` / `OUTSIDE_FRAME` |
> | 总判决（五值） | **P5** 整体结论 | `KEEP` / `WEAKEN` / `KILL` / `REFORMULATE` / `INSUFFICIENT EVIDENCE` |
> | 证伪尝试判决（四值） | **P6 falsifier** | `REFUTED` / `NOT_REFUTED` / `UNRESOLVED` / `OUTSIDE_FRAME` |
>
> 区别要点：P5 五值是对**整个命题/方案**的最终处置（含 `KEEP` 这种"维持原样也是成功"），
> 且含"换框架"（`REFORMULATE`）；falsifier 四值只描述**这一次证伪尝试的结果**，
> 用 `NOT_REFUTED` 而非 `SUPPORTED`，是为了提醒"我们没能推翻它" ≠ "它被证明了"。

### 6.4 闭环

falsifier 的判决**不能直接当最终结论**（L5：作者 / 单方不得自评）：
它的输出与 P5 的判决一起交给**人类或独立 verifier 复核**；若 falsifier 出 `REFUTED`，
P5 必须走"改结构"（见 `p5-verdict.md` 的 `KILL ⇒ 改结构，不许改判据`）。

---

## 来源清单

| 内容 | 本地原文路径 | 上游 URL |
|---|---|---|
| §1 三条硬规则 | `_research/dev-skill-refs/superpowers/skills__subagent-driven-development__task-reviewer-prompt.md`、`...__subagent-driven-development__SKILL.md` | https://github.com/obra/superpowers/blob/main/skills/subagent-driven-development/task-reviewer-prompt.md |
| §2 `adversarial-reviewer` 三 persona | `_fanout/dev-skill-research/s2-rigorous-methods.md`（§2.4 实例 C） | https://github.com/alirezarezvani/claude-skills/blob/main/engineering-team/skills/adversarial-reviewer/SKILL.md |
| §5 判据私有 | `_fanout/dev-skill-research/s2-rigorous-methods.md`（§2.4 实例 E） | https://github.com/prime-radiant-inc/superpowers-evals |
| §6 `falsifier` | 本 skill 自创（蓝图 §8 决定 3） | — |
