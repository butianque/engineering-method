# P0 先验冻结表（Pre-registration）

> 用法：拷进项目（例如 `docs/proof/<task>.prereg.md`），**在跑任何实验 / 改任何代码之前**填满并冻结。
> 规则：**五元组缺一栏即冻结失败，不许进入下一阶段**；冻结之后先验预测与成功标准不得回改（改判据须走 P5 的 `REFORMULATE`）。
> 机制依据：`../references/p0-preregistration.md`。

---

## 冻结元信息

| 字段 | 值 |
| --- | --- |
| 任务 / 需求标题 | |
| 冻结时间戳（ISO 8601） | |
| 冻结时的 git commit（SHA） | |
| 分支 / worktree | |
| 执行者 | |
| 签名（执行者） | |
| 签名（复核者，独立） | |

> ⚠️ 时间戳 + git commit 的作用：让"先验早于结果"可被审计。冻结时的 commit 必须**早于**任何实验 commit。

---

## 一、激活闸门（双条件）

> 原文依据：`falsify__SKILL.md` L19-20「Automatic activation: require BOTH meaningful formulation uncertainty AND non-trivial intervention cost or risk. Neither alone is enough.」

| 条件 | 本任务的判定 | 满足？ |
| --- | --- | --- |
| meaningful formulation uncertainty（问题定义存在实质不确定性） | | ☐ 是 / ☐ 否 |
| non-trivial intervention cost or risk（干预成本/风险不低） | | ☐ 是 / ☐ 否 |
| **两条件同时满足？** | | ☐ 是（进入本协议）/ ☐ 否（`BYPASS`：把原任务交回宿主，不硬造报告） |

> 免启动清单（任一命中即通常不启动）：verified diagnosis、obvious syntax/compilation error、typo、translation、formatting、mechanical transformation、deterministic local edit、very cheap reversible intervention。（`falsify__SKILL.md` L24-26）
> 提醒：`Mere logical possibility of another explanation is insufficient.`（L27）

---

## 二、五对象分离

> 原文依据：`falsify__SKILL.md` L37-45「Observation != Interpretation != Causal Hypothesis != Problem Formulation != Solution.」

| 对象 | 内容 | 来源 / 说明 |
| --- | --- | --- |
| Observation（观测） | | provenance：____ |
| Interpretation（解读） | | |
| Causal Hypothesis（因果假设） | | |
| **Current Problem Formulation（当前问题定义）** | | ☐ stated / ☐ inferred（若由方案反推，勾 inferred） |
| Solution（方案） | | |

> 主张强度勾选（L66-68）：☐ possible contributor / ☐ primary explanation / ☐ exclusive explanation

---

## 三、provenance（来源）登记

> 原文依据：`falsify__SKILL.md` L49-53；标签可选：`tool-observed` / `user-reported` / `document-reported` / `experimentally observed` / `measurement-derived`。

| # | 观测内容 | provenance 标签 | 必附信息（文件/命令/文档名/实验条件/输入与采样限制） |
| --- | --- | --- | --- |
| 1 | | | |
| 2 | | | |
| 3 | | | |

> ⚠️ **禁止把 `user-reported` 升格为已证实事实；不许编造观测或执行记录。**（L58-60）

---

## 四、必填五元组（缺一不可）

> 原文依据：`falsify__SKILL.md` L103、L106-110、L143；superpowers `skills__verification-before-completion__SKILL.md` L27、L40-42。

### 1. Question（待答问题，一句话）

> 禁用"应该 / 可能 / 似乎"。可证伪、可判定。

```text
<填写>
```

### 2. Prior prediction（先验预测：方向 + 量级）

> 必须能区分候选，且量级有依据（不得凭空编数值阈值）。

| 项 | 内容 |
| --- | --- |
| 方向（增 / 减 / 无变化） | |
| 量级（数值 + 单位；或定性判据及理由） | |
| 该预测区分了哪些候选 | |

### 3. Success criterion（成功标准：跑哪条命令、看到什么才算过）

> 必须是**外置可复算的命令 + 可判定输出**；"上一轮结果""应该会过"不算。

| 项 | 内容 |
| --- | --- |
| 证明用的命令 | |
| 判定通过的输出 |（例：`0 failures`、`exit 0`、具体断言） |
| 判定不通过的情形 | |

### 4. Failure prediction（证伪条件：什么观测直接推翻假设）

> 什么可靠观测会直接杀死当前假设（`contrary evidence`）。
> ⚠️ 缺失证据 ≠ 相反证据；只有覆盖度与检测能力足以让该信号本应出现时，缺失才能否定候选（L207-208）。

```text
<填写>
```

### 5. Confounds（混淆项）

> 可能污染结论的因素（覆盖度 / 新鲜度 / 可比性 / 缺失数据），以及"在什么条件下它才会改变结论"。

| # | 混淆项 | 何时才会改变结论 |
| --- | --- | --- |
| 1 | | |
| 2 | | |

---

## 五、Gate Function 五步自检（声明任何状态之前）

> 原文依据：`skills__verification-before-completion__SKILL.md` L25-35、L17、L12。

- [ ] **IDENTIFY**：写下能证明该主张的命令
- [ ] **RUN**：执行**完整**命令（新鲜、完整）
- [ ] **READ**：读完整输出，检查 exit code，数失败数
- [ ] **VERIFY**：输出是否支持该主张？（NO → 带证据说实况；YES → 带证据下结论）
- [ ] **ONLY THEN**：才作声明

> 判决句：**`Skip any step = lying, not verifying`**
> Iron Law：`NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE`
> `Violating the letter of this rule is violating the spirit of this rule.`

---

## 六、冻结签字

```
五元组全部填满？  ☐ 是   ☐ 否（否 → 冻结失败，Start over）
先验预测 / 成功标准已写死、不得回改？  ☐ 是
冻结时间戳：____________________    git commit：____________________
执行者签名：____________________    复核者签名：____________________
```

> 处置句：**`Can't check all boxes? You skipped the protocol. Start over.`**
