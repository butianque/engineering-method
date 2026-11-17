# P3 判别实验与执行规范

> 阶段目标：把 P1 分解树上的"未决"逐轮打成"有证据"。每轮**恰好一个**主判别检验；跑**之前**先写下 outcome map；全程只动一个变量；偏离规范即作废。连续 3 轮同问题失败即熔断。

素材来源：

- **`falsify-the-problem`**（本地 `_research/dev-skill-refs/r3/falsify__SKILL.md`）：每轮一个 Primary Discriminating Test、outcome map、候选更新词表、停止条件。
- **superpowers `systematic-debugging`**（本地 `_research/dev-skill-refs/superpowers/skills__systematic-debugging__SKILL.md`）：只改一个变量、3 轮熔断。

---

## 一、每轮恰好一个 Primary Discriminating Test

> "When beginning an investigation round under unresolved uncertainty, choose **exactly ONE Primary Discriminating Test**. This is one per round, not one forever. Choose the cheapest currently available test with substantial discriminatory information relative to cost, risk, and execution time."
> — `falsify__SKILL.md` L125-128

**关键区分**：这是**"每轮一个"**，不是**"永远一个"**。一轮结束后，带着更新过的候选集开下一轮、换下一个检验。

判别力的自问标准：

> "Ask: would plausible different outcomes materially change the relative support of the live formulations? If not, choose a better test."
> — `falsify__SKILL.md` L130-131

**一个检验可以包含多个取材/计算步骤**，但必须服务**同一个预先声明的对比与 outcome map**，不得把多路独立探查捆成"一个"检验：

> "One test can require several retrieval or computation steps if they serve one predeclared comparison and outcome map. It cannot hide independent investigations inside a bundle such as "check logs, metrics, configuration, and tests.""
> — `falsify__SKILL.md` L146-148

> ⚠️ **禁止把它叫"决定性检验"**，也不得暗示每个结果都必须终结问题：
> "Do not call it a "Decisive Test" or imply that every result must settle the issue."
> — `falsify__SKILL.md` L152

> 落地假设：本 skill 把"一轮"绑定到 agent 的**一次工具回合**（一轮 = 一个 Primary Test 从声明到出结果）。原文只说"one per round"，未定义"一轮"的粒度边界；不绑死会让"每轮一个"变成空话。

---

## 二、跑之前先写 outcome map

**在跑检验之前**，先把"若出现 X → 谁被加强 / 削弱 / 杀死"写在纸面上。

> "Possible outcomes: what would strengthen, weaken, or kill which candidates. Include inconclusive or mixed outcomes where plausible."
> — `falsify__SKILL.md` L142-143

完整要声明四件事：

> - "**Test:** one bounded comparison or observation, its source, and its scope."
> - "**Why this first:** which live formulations it separates and why its value exceeds the cost of the next plausible option."
> - "**Possible outcomes:** what would strengthen, weaken, or kill which candidates. Include inconclusive or mixed outcomes where plausible."
> - "**Remaining uncertainty:** what this test cannot establish."
> — `falsify__SKILL.md` L139-144

**候选更新词表（5 个，注意：这是"候选更新"，不是总体判决）**：

> | Candidate update | Meaning |
> | STRENGTHEN | New evidence raises support, without proving the candidate |
> | WEAKEN | New evidence reduces support; the candidate remains live |
> | KILL | Reliable evidence contradicts a necessary assumption at the stated scope |
> | UNRESOLVED | Evidence does not discriminate enough or is unavailable |
> | MERGE | Combine with a named candidate because the distinction is redundant |
> — `falsify__SKILL.md` L199-205

> ⚠️ **两套词不许混用**：候选更新 5 词（`STRENGTHEN / WEAKEN / KILL / UNRESOLVED / MERGE`）**≠** 总体判决 5 词（`KEEP / WEAKEN / KILL / REFORMULATE / INSUFFICIENT EVIDENCE`，见 `p5-verdict.md`）。原文：
> "Candidate updates and the overall verdict have different meanings and scopes."
> — `falsify__SKILL.md` L211
> 把两者混用会导致"没有结论（UNRESOLVED）"被误当成"否决（KILL）"。

**必须预留"无结论 / 混合"这一档**（见上 L143）。**缺失证据 ≠ 相反证据**：

> "Missing evidence is not contrary evidence. An absent signal kills a candidate only when coverage and detection were sufficient for that signal to be expected."
> — `falsify__SKILL.md` L207-208

**可回滚**：标签是"可修订的结论"，不是永久状态；旧 kill 被推翻要显式 reopen：

> "If new evidence undermines a prior kill, explicitly reopen the candidate and give the reason; labels are revisable conclusions, not permanent states."
> — `falsify__SKILL.md` L209-210

---

## 三、只改一个变量、一次只动一处

实验执行时，**最小改动 + 单一变量**是硬规则。

> "2. **Test Minimally**"
> "   - Make the SMALLEST possible change to test hypothesis"
> "   - One variable at a time"
> "   - Don't fix multiple things at once"
> — `skills__systematic-debugging__SKILL.md` L152-155

> "3. **Verify Before Continuing**"
> "   - Did it work? Yes → Phase 4"
> "   - Didn't work? Form NEW hypothesis"
> "   - DON'T add more fixes on top"
> — `skills__systematic-debugging__SKILL.md` L157-160

实现时同样：

> "2. **Implement Single Fix**"
> "   - Address the root cause identified"
> "   - ONE change at a time"
> "   - No "while I'm here" improvements"
> "   - No bundled refactoring"
> — `skills__systematic-debugging__SKILL.md` L179-183

> ⚠️ "顺手再修一处"直接破坏因果归因——`"Multiple fixes at once saves time" | Can't isolate what worked. Causes new bugs.`（`skills__systematic-debugging__SKILL.md` L252）。

---

## 四、偏离规范即作废（out-of-protocol 不计入结论）

**违背执行规范做出来的实施，不进结论。** 这不是"下次注意"，而是**本轮结果作废**。

> "Violating the letter of this rule is violating the spirit of this rule."
> — `skills__verification-before-completion__SKILL.md` L12

> 处置句（照抄）：**`Violating the letter of this protocol is violating the spirit of it.`**（融合蓝图 L35 采用的句式，源于上述 superpowers 句）

典型 out-of-protocol（一出现即不计入结论）：

| 违规动作 | 为什么作废 |
| --- | --- |
| 一次改多个变量 | 无法隔离"是哪个改动起了作用"（见上节 L252） |
| 结果不符预期却"顺手再修一处" | 破坏了 outcome map 与单一变量前提 |
| 跑完后才补写 outcome map | 事后归因会被结果带偏（先验失效） |
| 途中悄悄换了成功标准 / 判据 | 判据被污染；改判据属 `REFORMULATE`（走 `p5-verdict.md`），不许静默改 |

中止一轮时，**保留 partial 结果，但显式标注作废**——不许把作废的一轮当成支持证据。

---

## 五、熔断：同问题失败 ≥3 轮 → 停止改代码、质疑架构

用一个**可数阈值**把"再试一次"强制切到"停下来质疑架构"：

> "4. **If Fix Doesn't Work**"
> "   - STOP"
> "   - Count: How many fixes have you tried?"
> "   - If < 3: Return to Phase 1, re-analyze with new information"
> "   - **If ≥ 3: STOP and question the architecture (step 5 below)**"
> "   - DON'T attempt Fix #4 without architectural discussion"
> — `skills__systematic-debugging__SKILL.md` L191-196

> "This is NOT a failed hypothesis - this is a wrong architecture."
> — `skills__systematic-debugging__SKILL.md` L212

架构问题的征兆（出现即支持熔断）：

> "   - Each fix reveals new shared state/coupling/problem in different place"
> "   - Fixes require "massive refactoring" to implement"
> "   - Each fix creates new symptoms elsewhere"
> — `skills__systematic-debugging__SKILL.md` L201-203

熔断后**必须先和人类讨论**再动下一步：

> "**Discuss with your human partner before attempting more fixes**"
> — `skills__systematic-debugging__SKILL.md` L210

> ⚠️ 熔断触发时，本 skill 的裁决词是 `KILL`（原定义不可成立）或 `REFORMULATE`（换一个更好的定义），**不是**"再试一次"；且 `KILL ⇒ 改结构，不许改判据`（见 `p5-verdict.md`）。

---

## 六、停止条件与"KEEP 也是成功"

满足下列任一条件即可结束本轮对抗：

> - "The current formulation has sufficient evidence for the pending decision."
> - "No meaningful materially different alternative remains, or remaining alternatives are too weak to justify delaying the decision."
> - "Further investigation has poor information gain relative to cost, risk, or time."
> - "Another formulation is sufficiently supported to replace the original."
> - "The original formulation is dead and no useful cheap investigation remains."
> - "Essential discriminating evidence is unavailable and no useful proxy exists; hand off the minimal evidence request rather than stall indefinitely."
> — `falsify__SKILL.md` L217-224

**最重要的一句**：耗尽 ≠ 证据。

> "Sufficiency is proportional to the pending intervention and evidence quality. Running out of tests, access, time, or alternatives is not itself evidence for KEEP. Do not become contrarian for its own sake. KEEP is a normal successful outcome."
> — `falsify__SKILL.md` L226-228

> "`KEEP` is a successful result."
> — `falsify__README.md` L25

> ⚠️ **耗尽测试 / 权限 / 时间 / 备选，本身不构成 KEEP 的理由**（"Running out of tests … is not itself evidence for KEEP"）。`KEEP` 是**正常的成功结局**，不是"没查出问题"的挡箭牌。

**"本 skill 停 ≠ 宿主 agent 停"**：

> "Skill STOP != Host Agent STOP. KEEP ends this skill's responsibility."
> — `falsify__SKILL.md` L247

`KEEP` 只解除**问题定义**的门禁，**不授予新权限**，也不保证所提方案有效（`falsify__SKILL.md` L247-250）。

**后续轮次用 delta 输出**，不重复未变的内容：

> "On later turns, use **delta output**: new evidence/source, what changed, affected candidate updates and scope, a new Primary Test only if useful, then verdict/handoff. Do not repeat unchanged observations, formulations, assumptions, or predictions."
> — `falsify__SKILL.md` L284-286

---

## 引用来源

- `_research/dev-skill-refs/r3/falsify__SKILL.md`（L125-131、L139-148、L152、L199-211、L217-228、L247-250、L284-286）
- `_research/dev-skill-refs/r3/falsify__README.md`（L25）
- `_research/dev-skill-refs/superpowers/skills__systematic-debugging__SKILL.md`（L152-160、L179-183、L191-196、L201-212、L252）
- `_research/dev-skill-refs/superpowers/skills__verification-before-completion__SKILL.md`（L12）
- `_fanout/dev-skill-research/fused-blueprint.md`（L34-37、L48）
