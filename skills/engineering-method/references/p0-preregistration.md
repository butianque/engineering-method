# P0 立题与先验冻结

> 阶段目标：**在不知道"什么叫对"的时候，不许动手改代码。** P0 的产出是一张冻结的《先验登记表》（模板见 `../templates/preregistration.md`），冻结之后才允许进入 P1。

本阶段的机制来自两处原文：

- **`falsify-the-problem`**（本地 `_research/dev-skill-refs/r3/falsify__SKILL.md`）：双条件激活闸门、五对象分离、来源保真（provenance）标签。
- **superpowers `verification-before-completion`**（本地 `_research/dev-skill-refs/superpowers/skills__verification-before-completion__SKILL.md`）：Gate Function 五步与判决句。

---

## 一、双条件激活闸门（何时才该启动）

不是所有请求都要走这套协议。启动需要**同时**满足两个条件，缺一不可。

> "Automatic activation: require BOTH meaningful formulation uncertainty AND non-trivial intervention cost or risk. Neither alone is enough."
> — `falsify__SKILL.md` L19-20

**不要太早启动**（原文列举的免启动清单）：

> "Usually do not auto-activate for a verified diagnosis, obvious syntax or compilation error, typo, translation, formatting, mechanical transformation, deterministic local edit, or very cheap reversible intervention."
> — `falsify__SKILL.md` L24-26

> "Mere logical possibility of another explanation is insufficient."
> — `falsify__SKILL.md` L27

**"跳过闸门"也是一种决定，不是证据判决**：

> "`BYPASS` is an activation decision, never an evidence verdict. When bypassing, leave the original task with the host; do not manufacture an adversarial report. If explicitly invoked on a supported diagnosis, use `KEEP`, not `BYPASS`."
> — `falsify__SKILL.md` L29-31

> ⚠️ 关键纪律：`BYPASS` 是**"要不要启用"的激活决定**，**不是**证据判决，更不是 P5 的第六个判决词（见 `p5-verdict.md`）。跳过时必须把原任务交回宿主，**不许硬造一份对抗性报告来交差**。被显式调用时，即使诊断已经成立也应给 `KEEP` 而非 `BYPASS`。

**我们语境下的两个条件如何落地（假设标注）**：

| 条件 | 本工作区的判定（本 skill 的落地假设） |
| --- | --- |
| meaningful formulation uncertainty（问题定义存在实质不确定性） | 需求含"应该/可能/似乎/improve/优化"这类不可证伪措辞；同一现象有 ≥2 个说得通的解释；改动会触碰既有结构而现有行为尚未读清 |
| non-trivial intervention cost or risk（干预成本/风险不低） | 涉及生产机、部署、删除、迁移、重启、对外接口、跨多文件结构改动（对应 `AGENTS.md` 的"重启须提前告知""删除铁律"） |

> 假设：以上"成本/风险阈值"是本工作区自行拟定，`falsify` 原文只提出"non-trivial cost or risk"，未给具体数值。落地时应由使用者按项目调整。

---

## 二、五对象分离表

用户常把五件事塞进一句话里。**必须先拆开再处理。**

> "Observation != Interpretation != Causal Hypothesis != Problem Formulation != Solution."
> — `falsify__SKILL.md` L45

| 对象 | 含义 | 示例（原文表 L37-43） |
| --- | --- | --- |
| **Observation**（观测） | 被观察到、测量到、或被报告的事实 | User reports P99 rose from 300 ms to 2.8 s |
| **Interpretation**（解读） | 给观测赋予的意义 | The database is slow |
| **Causal Hypothesis**（因果假设） | 一个具体的、用来解释它的机制 | Lock contention delays requests |
| **Problem Formulation**（问题定义） | 到底在解哪一类问题 | Database service time dominates the slow tail |
| **Solution**（方案） | 提出的干预手段 | Add Redis |

**登记规则**：

- 先显式写出 **Current Problem Formulation**；若它是由某个方案反推出来的，必须标注"推断"，**不得**算作用户明确表达的信念。
  > "State the **Current Problem Formulation** explicitly. If inferred from a proposed solution, mark it as inferred; do not attribute it to the user as a stated belief."
  > — `falsify__SKILL.md` L62-63
- 保留主张强度：contributor / primary explanation / exclusive explanation 是三种不同的主张，不得混同。
  > "Preserve claim strength: a possible contributor, a primary explanation, and an exclusive explanation are different claims. Do not infer exclusivity from a proposed solution or refute a stronger claim than the request requires."
  > — `falsify__SKILL.md` L66-68

### provenance（来源）标签

每条**关键观测**都必须带来源标签：

> "`tool-observed`: name the file, command, trace, or other inspected artifact." / "`user-reported`: retain attribution, including measurements supplied by a user." / "`document-reported`: identify the document and its claim." / "`experimentally observed`: identify the experiment and conditions." / "`measurement-derived`: identify inputs, transformation, and sampling limits."
> — `falsify__SKILL.md` L49-53

| provenance 标签 | 含义 | 必须附带的信息 |
| --- | --- | --- |
| `tool-observed` | 用工具直接看到的 | 文件名 / 命令 / trace / 被检视的产物 |
| `user-reported` | 用户报告的 | 保留归属；用户提供的测量值也算这一类 |
| `document-reported` | 某份文档声称的 | 文档名 + 它的主张 |
| `experimentally observed` | 实验观测到的 | 实验本身 + 条件 |
| `measurement-derived` | 由测量推导的 | 输入 / 变换 / 采样限制 |

> "Never upgrade user reports into independently verified facts. Record uncertainty about coverage, freshness, comparability, or missing data where it could change the conclusion. Do not fabricate observations or execution."
> — `falsify__SKILL.md` L58-60

> ⚠️ **禁止把用户报告升格为已证实事实。** "用工具读了一份报告"只证明"报告这么说了"，不证明报告的内容为真；本地模拟 fixture 只对该 fixture 有效，不构成对真实事件的独立验证。**不许编造观测或执行记录。**

---

## 三、必填五元组（先验冻结的核心）

P0 的产出就是这五项，**缺一栏就冻结不了**。每项的原文依据如下。

### 1. Question（问题）

把要回答的那**一句话**写死，禁用"应该 / 可能 / 似乎"这类不可证伪措辞。

依据：falsify 要求显式写出 Current Problem Formulation（L62），且预测必须能区分候选，"not restate their names"：
> "A prediction must distinguish live formulations, not restate their names."
> — `falsify__SKILL.md` L106

### 2. Prior prediction（先验预测：方向 + 量级）

必须给出**方向与量级**，且量级要有依据，不许凭空编数值阈值。

> "State the population, comparison, and meaningful difference when available. Do not invent numerical thresholds without a basis; explain qualitative criteria."
> — `falsify__SKILL.md` L109-110

预测必须**能区分活着的候选**，而不是复述候选的名字：

> `Formulation -> load-bearing assumption -> observable prediction -> contrary evidence`
> — `falsify__SKILL.md` L103

> "a service-time framing predicts elevated service spans in slow requests; a capacity framing predicts rising pre-service wait with concurrency; a measurement framing predicts disagreement between raw samples and reported aggregation."
> — `falsify__SKILL.md` L107-108

### 3. Success criterion（跑哪条命令、看到什么才算过）

成功标准必须是**外置可复算的命令 + 可判定的输出**，不能是"我觉得好了"。

依据：superpowers Gate Function 第 1 步就要求"哪条命令能证明这个主张"：

> "1. IDENTIFY: What command proves this claim?"
> — `skills__verification-before-completion__SKILL.md` L27

以及"通过"的判据是命令输出本身（不是上一轮结果、不是"应该会过"）：

> | Claim | Requires | Not Sufficient |
> | Tests pass | Test command output: 0 failures | Previous run, "should pass" |
> — `skills__verification-before-completion__SKILL.md` L40-42

### 4. Failure prediction（什么观测直接推翻假设）

**先写下"什么样的观测会直接杀死这个假设"**，即 falsify 链条里的 `contrary evidence`（L103）。
一个可靠证据与"必要假设"矛盾时即判 `KILL`：

> "KILL | Reliable evidence contradicts a necessary assumption at the stated scope"
> — `falsify__SKILL.md` L203

⚠️ **缺失证据 ≠ 相反证据**：

> "Missing evidence is not contrary evidence. An absent signal kills a candidate only when coverage and detection were sufficient for that signal to be expected."
> — `falsify__SKILL.md` L207-208

### 5. Confounds（混淆项）

写下可能污染结论的因素（覆盖度、新鲜度、可比性、缺失数据等），并声明**在什么情况下它才会改变结论**。

> "Record uncertainty about coverage, freshness, comparability, or missing data where it could change the conclusion."
> — `falsify__SKILL.md` L59-60

outcome map 必须包含"无结论/混合"这一档（预留混淆导致的含糊结局）：

> "Include inconclusive or mixed outcomes where plausible."
> — `falsify__SKILL.md` L143

---

## 四、Gate Function 五步（superpowers 原文）

在**声称任何状态**之前，逐条走完这五步：

> ```
> BEFORE claiming any status or expressing satisfaction:
>
> 1. IDENTIFY: What command proves this claim?
> 2. RUN: Execute the FULL command (fresh, complete)
> 3. READ: Full output, check exit code, count failures
> 4. VERIFY: Does output confirm the claim?
>    - If NO: State actual status with evidence
>    - If YES: State claim WITH evidence
> 5. ONLY THEN: Make the claim
>
> Skip any step = lying, not verifying
> ```
> — `skills__verification-before-completion__SKILL.md` L25-35

配套的两条 Iron Law 句式：

> "NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE"
> — `skills__verification-before-completion__SKILL.md` L17

> "Violating the letter of this rule is violating the spirit of this rule."
> — `skills__verification-before-completion__SKILL.md` L12

> ⚠️ 判决句照抄：**`Skip any step = lying, not verifying`**。跳步不是"简化流程"，是**撒谎**。

---

## 五、闸门：五元组缺一不许进入下一阶段

**P0 是准入闸门，不是建议。**

```
先验登记表五元组（Question / Prior prediction / Success criterion / Failure prediction / Confounds）
  任一栏缺失或含"应该/可能/似乎"
     → 冻结失败 → 不许进入 P1 / P3 / 任何改代码动作。
```

处置句（照抄 superpowers 句式）：

> `Can't check all boxes? You skipped the protocol. Start over.`

> 依据（原文）：`Can't check all boxes? You skipped TDD. Start over.` — `skills__test-driven-development__SKILL.md`（r1 提取表 L40）；本 skill 把 `TDD` 换成 `the protocol`。

- 冻结之后，**先验预测与成功标准不得回改**（改判据属 P5 的 `REFORMULATE` 范畴，须走 `p5-verdict.md`，不允许在实验中途悄悄改判据）。
- 冻结时记录**时间戳 + git commit**（模板 `../templates/preregistration.md` 有对应字段），使"先验早于结果"可被审计。

---

## 引用来源

- `_research/dev-skill-refs/r3/falsify__SKILL.md`（L19-31、L37-45、L49-68、L103-110、L143、L203、L207-208）
- `_research/dev-skill-refs/superpowers/skills__verification-before-completion__SKILL.md`（L12、L17、L25-35、L40-42）
- `_research/dev-skill-refs/superpowers/skills__test-driven-development__SKILL.md`（处置句 `Can't check all boxes? …`，经 `r1-superpowers-extract.md` L40 转引）
- `_fanout/dev-skill-research/fused-blueprint.md`（L26、L45、L34-37）
