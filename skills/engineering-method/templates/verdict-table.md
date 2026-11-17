# P5 判决表模板（Verdict Table）

> 用法：拷进项目，在每个实验轮次结束后逐行登记，最后收敛成**恰好一个**总体判决。
> 机制依据：`../references/p5-verdict.md`。

---

## 判决登记表

| 观测 | 相对先验预测 | 对假设的作用 | 判决 | 下一步 |
| --- | --- | --- | --- | --- |
| | | | | |
| | | | | |
| | | | | |

**列说明**：

- **观测**：本轮实际跑出的结果，**必须带 provenance**（`tool-observed` / `user-reported` / `document-reported` / `experimentally observed` / `measurement-derived`）。
- **相对先验预测**：与 P0 冻结的 Prior prediction 比对——方向、量级是否如预测？（对照 `../templates/preregistration.md`）
- **对假设的作用**：候选更新，用 5 词之一：`STRENGTHEN / WEAKEN / KILL / UNRESOLVED / MERGE`。（`falsify__SKILL.md` L199-205）
- **判决**：**总体判决**，用 5 值之一（见下）。注意与上一列的候选更新**不是一回事**。
- **下一步**：继续 / 换检验 / 交接 / 改结构。

> ⚠️ 两套词不许混用：候选更新 5 词 ≠ 总体判决 5 词。
> "Candidate updates and the overall verdict have different meanings and scopes." — `falsify__SKILL.md` L211

---

## 总体判决 5 值说明（封闭词表）

> "Use exactly one overall verdict about the original Current Problem Formulation:" — `falsify__SKILL.md` L230

| 判决 | 含义 | 能否进入实现 handoff |
| --- | --- | --- |
| `KEEP` | 当前定义获最多支持，且已充分验证 | **允许** |
| `WEAKEN` | 当前定义仍活着，但已实质失去支持；无足够替代 | 暂不允许（NOT YET） |
| `KILL` | 当前定义已不可成立，且无足够支持的替代 | 被阻断（BLOCKED） |
| `REFORMULATE` | 有实质不同的替代已获足够支持，可替换原定义 | 暂不允许（NOT YET；须附 `Reformulated Problem:`） |
| `INSUFFICIENT EVIDENCE` | 现有证据不足以区分 | 暂不允许（NOT YET） |

> ⚠️ **判决词是封闭词表——不许自造第六个词。** `BYPASS` 是激活决定，不是判决词（`falsify__SKILL.md` L29）；候选更新 5 词也不是判决词。
> ⚠️ `OUTSIDE CURRENT FRAME` 是**证据诊断，不是第六判决**：保留残差，不许塞给最近的候选（`falsify__SKILL.md` L188-192）。
> ⚠️ `KILL ⇒ 改结构，不许改判据`（见 `../references/p5-verdict.md` 第五节）。

**有序裁决（多个判决看似都成立时）**：

```text
已确立的替代？  -> REFORMULATE
必要假设被推翻？ -> KILL
支持度实质性下降？-> WEAKEN
无法区分？      -> INSUFFICIENT EVIDENCE
（其余，充分验证）-> KEEP
```
> 依据：`falsify__SKILL.md` L242-245。

---

## 不合格写法举例（一出现即判该判决无效）

| ❌ 不合格写法 | 为什么不合格 |
| --- | --- |
| `判决：BYPASS` | `BYPASS` 是激活决定，不是判决词（L29） |
| `判决：PASS / FAIL / OK / DONE` | 非封闭词表内的词，属自造第六词 |
| `判决：OUTSIDE CURRENT FRAME` | 那是证据诊断，不是第六判决（L188-192） |
| `判决：KEEP`，但成功标准是跑完后才改的 | 判据被污染，先验失效（须走 `REFORMULATE`） |
| `判决：KEEP`，理由是"测试都用完了 / 没时间了" | `Running out of tests, access, time, or alternatives is not itself evidence for KEEP.`（L227） |
| `判决：KILL`，但没有可靠证据与必要假设矛盾 | KILL 的定义是 `Reliable evidence contradicts a necessary assumption at the stated scope`（L203） |
| `判决：REFORMULATE`，却没写 `Reformulated Problem:` | “For REFORMULATE, always output **Reformulated Problem:** with the replacement and its supporting evidence.”（L240-241） |
| "候选 KILL 了，所以总体也 KILL" | 候选更新 ≠ 总体判决（L211），须重走有序裁决 |
| 把框架外结果塞给最近的候选 | `Preserve the unexplained residual; do not award it to the closest candidate.`（L190-191） |
| `判决：WEAKEN`，却同时声称"已确立替代" | 有序裁决：有已确立替代时优先 `REFORMULATE`（L242-243） |

---

## 收尾签字

```
本轮唯一总体判决（5 选 1）：____________________
是否为 KEEP？  ☐ 是（放行实现）/ ☐ 否（不放行）
若 REFORMULATE，是否已附 Reformulated Problem:  ☐ 是 / ☐ 不适用
git commit：____________________   时间戳：____________________
```
