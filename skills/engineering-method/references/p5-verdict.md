# P5 判决与结构变更

> 阶段目标：把 P3 累积的证据收敛成**恰好一个**总体判决，并据此决定"能不能进入实现"。判决词是**封闭词表**，一个都不许自造。

素材来源：**`falsify-the-problem`**（本地 `_research/dev-skill-refs/r3/falsify__SKILL.md`）：五值判决、单值有序裁决、`OUTSIDE CURRENT FRAME`。

---

## 一、五值判决表

> "Use exactly one overall verdict about the original Current Problem Formulation:"
> — `falsify__SKILL.md` L230

| 总体判决 | 含义 | 是否允许进入实现 handoff |
| --- | --- | --- |
| **KEEP** | Current framing remains best-supported and sufficiently validated for the pending decision | **允许**（ALLOWED for that framing; release to the downstream solver） |
| **WEAKEN** | Current framing remains live but has materially lost support; no replacement is sufficiently established | **暂不允许**（NOT YET；继续有效调查，或交接那份具体的不确定性） |
| **KILL** | Current framing is no longer viable, with no sufficiently supported replacement | **被阻断**（BLOCKED for the killed premise；若值得，去调查另一个 framing） |
| **REFORMULATE** | A materially different framing is sufficiently better supported to replace the original | **暂不允许**（NOT YET；把"重构后的问题"交回下游流程；旧方案不予放行） |
| **INSUFFICIENT EVIDENCE** | Available evidence cannot discriminate enough to support a stronger verdict | **暂不允许**（NOT YET；若值得继续调查，否则说明最少还缺什么证据） |
> — 表 L232-238（Meaning / Solutioning-handoff 两列逐字引自原文）

**只有 `KEEP` 放行进入实现。** 其余四个都是"不放行"（`NOT YET` 或 `BLOCKED`）。

### `REFORMULATE` 强制携带具名替代

> "For REFORMULATE, always output **Reformulated Problem:** with the replacement and its supporting evidence. KILL does not assert a replacement; REFORMULATE does."
> — `falsify__SKILL.md` L240-241

> ⚠️ 区分：`KILL` **不**断言替代品；只有 `REFORMULATE` 才带具名替代。

---

## 二、有序裁决规则

当多个判决看似都成立时，按固定顺序 tie-break，取**最有信息量**的那个：

> "If several descriptions fit, choose the most informative supported verdict: an established replacement takes REFORMULATE over KILL or WEAKEN; absent one, contradicted necessary assumptions justify KILL, reduced support justifies WEAKEN, and non-discrimination justifies INSUFFICIENT EVIDENCE."
> — `falsify__SKILL.md` L242-245

等价的可判定写法：

```text
已确立的替代？         -> REFORMULATE   （优先于 KILL / WEAKEN）
必要假设被推翻？        -> KILL
支持度实质性下降？      -> WEAKEN
无法区分？             -> INSUFFICIENT EVIDENCE
（其余，充分验证）      -> KEEP
```

> 依据：`falsify__SKILL.md` L242-245；等价裁决顺序亦见 `r3-extract.md` §1.4。

---

## 三、判决词是封闭词表（不许自造第六个词）

**判决词就是这 5 个：`KEEP / WEAKEN / KILL / REFORMULATE / INSUFFICIENT EVIDENCE`。**

> ⚠️ **不许自造第六个判决词。** `BYPASS` 之类**不是**判决词。

原文定性：

> "`BYPASS` is an activation decision, never an evidence verdict."
> — `falsify__SKILL.md` L29

`BYPASS` 属于 P0 的"要不要启用"决定（见 `p0-preregistration.md` 第一节），与总体判决是**两个不同层面的东西**。同样，候选更新 5 词（`STRENGTHEN / WEAKEN / KILL / UNRESOLVED / MERGE`，见 `p3-experiment-protocol.md`）也**不是**判决词。

> "Candidate updates and the overall verdict have different meanings and scopes."
> — `falsify__SKILL.md` L211

> 口径提醒（照 `r3-extract.md` §5）：本 skill 的判决词**严格限于**这 5 个；`BYPASS`（激活决定）与候选更新 5 词**都不是**判决词，未新增任何判决词。

**若发现需要一个 5 词之外的结论，那是"证据诊断"（见下节），不是新判决。**

---

## 四、`OUTSIDE CURRENT FRAME`：是证据诊断，不是第六判决

> "If a consequential result fits no live formulation, mark it **OUTSIDE CURRENT FRAME**: the set may be incomplete. This is an evidence diagnostic, not a sixth verdict. Preserve the unexplained residual; do not award it to the closest candidate. Repeat the lightweight coverage check once for this new evidence, adding at most one grounded challenger if warranted. Otherwise leave it unresolved."
> — `falsify__SKILL.md` L188-192

三条纪律：

1. **它不是第六个判决**（原文：`not a sixth verdict`）。出现"框架外"结果时，总体判决仍需从上面 5 词里选一个。
2. **保留残差**：不许把无法解释的结果**塞给最近的候选**（`do not award it to the closest candidate`）。
3. **最多一个**"框架外挑战者"：对这条新证据**只做一次**轻量覆盖检查，必要时最多加**一个**有依据的挑战者；不许为凑数扩集，也不许链式审计：

> "add at most ONE Outside-Frame Challenger. … If none is warranted, proceed without one. Do not chain coverage audits or expand the set merely to satisfy a quota."
> — `falsify__SKILL.md` L117-121

---

## 五、`KILL` ⇒ 改结构，不许改判据

判据（成功标准 / 证伪条件）在 P0 已冻结，是**准入前提**。当判决为 `KILL` 时：

- **允许做的**：改**结构**——换一个 framing、重构架构、换掉那个被杀死的前提。
  > "BLOCKED for the killed premise; investigate another framing if worthwhile."
  > — `falsify__SKILL.md` L236
- **禁止做的**：改**判据**来抢救原来的定义。中途修改成功标准 / 证伪条件会让判据被结果带偏（这也正是本 skill 的反模式："判据在结果出来后才定义""先写代码再补判据"，见 `fused-blueprint.md` §6 L158-159）。

> ⚠️ 一句话：**KILL 是"结构错了"，不是"判据太严"。** 改判据 = 拒绝承认结构错误。

> 依据标注：`KILL ⇒ 改结构不许改判据` 是融合蓝图自创规则（`fused-blueprint.md` L50）；其"不许改判据"半条由反模式表（L158-159）与 superpowers "字面即精神"（`skills__verification-before-completion__SKILL.md` L12）共同支撑。

---

## 六、收尾：判决之后控制权交回宿主

> "Skill STOP != Host Agent STOP. KEEP ends this skill's responsibility."
> — `falsify__SKILL.md` L247

- `KEEP` 只解除**问题定义**的门禁，**不授予新权限**，也不保证所提方案有效：
  > "Validation is not new permission for extra work. KEEP validates the problem framing, not the effectiveness of the proposed solution."
  > — `falsify__SKILL.md` L249-250
- 之后任何诊断或实现都应**标记为宿主/下游继续**，不要让一次"问题定义已通过"悄悄变成"根因工作流"：
  > "Mark any subsequent diagnosis or implementation as host/downstream continuation so a completed framing pass does not silently turn into a root-cause workflow."
  > — `falsify__SKILL.md` L251-252

---

## 引用来源

- `_research/dev-skill-refs/r3/falsify__SKILL.md`（L29、L117-121、L188-192、L211、L230-250）
- `_research/dev-skill-refs/r3-extract.md`（§1.4、§5）
- `_research/dev-skill-refs/superpowers/skills__verification-before-completion__SKILL.md`（L12）
- `_fanout/dev-skill-research/fused-blueprint.md`（L50、§6 L158-159）
