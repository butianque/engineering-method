# Why this skill is shaped the way it is

> The README says what it does. This file says why, and where the reasoning
> stops being reliable. Read it before changing `SKILL.md`, because most of the
> rules exist to prevent a specific failure that already happened.

---

## 1. The problem is not capability

An agent can write the function. It cannot see the rest of the system, and it
does not know it is missing.

```
Tests can only assert the behaviour of code that exists.
Something that does not exist produces no red.
⇒ "all tests green" does not imply "the system works".
```

Three failure modes follow:

| # | Failure | Survives review because |
|---|---|---|
| **F1** | The missing thing is absent — no code, no test, no red | there is nothing to look at |
| **F2** | The checker is written by the thing being checked | self-certification reads like diligence |
| **F3** | Every piece is locally correct; the chain is not connected | per-file reasoning has no edges |

A single real example, because abstractions here are worthless without one:

```
A session bug that needed 9 changes across 2 repositories.
Change 1 of 9 applied  →  go test ./internal/api/handlers/management/  →  ok  20.3s
The user                →  still logged out
```

The test was not wrong. It covered one total order. The dependency edge it
missed ("the panel consumes the reason field the backend produces") lived in
another repository and in no total order at all.

---

## 2. Why the artefacts, and why these eight

Each artefact exists because leaving it out produced a specific, repeatable
failure. None of them are ceremony; the test for keeping one is *"which failure
comes back if this is a blank page?"*

| Artefact | The failure it prevents |
|---|---|
| `立项书.md` | "What should it look like" collapses into a feature list, so the shape is never decided |
| `规划.md` | Stages with no exit criterion, so nobody can tell whether stage 2 finished |
| `策划.md` | Only one option, which means the decision was made before it was written down |
| `设计.md` | System design and program design written at once, so every function is correct under an assumption that was never checked |
| `范畴表.md` | Two words for one thing, so every later argument is about vocabulary |
| `集成面.md` | The seven things a working chain needs, of which the agent builds one |
| `验收.sh` | "It passes" means unit tests, which cannot see middleware, auth, or the other repository |
| `反合理化表.md` | Under time pressure, every rule without a named consequence gets renegotiated |

### The 7-line integration surface

This is the only genuinely new artefact, and the fixed row count is the point:

```
1 入口        2 业务函数      3 谁调用它    4 数据从哪来/存哪
5 失败路径    6 配置/权限/并发  7 可观测/可回滚
```

**If the model may add and remove rows, a row it did not think of gets deleted,
and the report comes back green.** That is the same failure as "the tests pass",
one level up. So the骨架 is fixed, and only the status column is editable:

```
存在  /  本次新建  /  不存在
```

`不存在` is the output that matters. It is a to-do list the model cannot
quietly empty.

### Every probe is a command

```
写不出探针  ⇒  状态标 不存在
```

Writing a probe means stating, in a form a machine can check, what "this exists"
would look like. If that cannot be done, the honest state is *absent*, not
*probably fine*.

---

## 3. Time and space, stated so they can be checked

This is the part most likely to be dismissed as philosophy. It is not; both are
standard mathematics, and both name a concrete symptom.

### Time = dependency partial order ⊆ execution total order

```
⊑   dependency order: A must be produced before B is consumed.
                    X and Y are unordered.
≤   execution order: everything has a position; code runs one line at a time.

Correct  ⟺  ≤ is a linear extension of ⊑, i.e. ⊑ ⊆ ≤
Violation: (a,b) ∈ ⊑ but (b,a) ∈ ≤      ← "executed before produced"
```

Four violation shapes, each with the symptom it explains:

| Shape | Symptom | Why a test misses it |
|---|---|---|
| executed before produced | uses state that is not initialised yet | the test happens to run in the right order |
| a dependency edge in no total order | the other repository, process, or browser | the test runs one total order |
| a cycle in the partial order | deadlock / circular dependency | a unit test never reaches the combination |
| satisfied by several total orders with no mutual exclusion | data race | unit tests are serial |

**And the corollary that justifies the whole skill:**

```
A test is ONE linear extension of ⊑.
Completion is ALL of ⊑ being covered.
⊑ has many linear extensions; a suite pins down one.
⇒ tests passing does NOT imply the partial order is closed.
```

The practical form is a table whose **last column is the entire point**:

| produce | consume | what | which boundary | **which total order covers it** |
|---|---|---|---|---|

A row with an empty last column is an edge nobody verifies. That is the
difference between "we thought about it" and "we check it".

### Space = artifacts → declared coordinates, and the coordinate graph is a DAG

Two layers, and the second is the one usually missed:

| Layer | Question | Check |
|---|---|---|
| placement | where does this *kind* of thing go | the file maps to a row in the placement table |
| architecture position | who may this module depend on | the dependency graph is a DAG, direction matches layering |

The agent's failure at layer 1 is a **nearest-neighbour rule**: put the new file
next to the last file that looked related. Ten of those and one kind of file
lives in ten places. Its failure at layer 2 is not seeing a graph at all.

### Style must carry numbers

```
❌ "keep it clean"        ✅ nesting depth ≤ 3
❌ "comment appropriately" ✅ comment ratio 10–30 %, explaining WHY
❌ "functions not too long" ✅ over 50 lines must state its responsibility
```

Three requirements, and they are what makes a style contract checkable:

```
F1  a number, or a citation to an external standard ("follow <language> convention")
F2  no 恰当 / 良好 / 合理 / 清晰 / 简洁 — unmeasurable words
F3  each line verifiable by lint, grep, or one human scan
```

`gate.sh` rejects a style section containing an unmeasurable word. Not because
the word is wrong, but because a contract you cannot violate is not a contract.

---

## 4. Why the constraints are shaped like formulas

This section exists because the format is unusual and will otherwise be
"simplified" by someone well-meaning.

### The real difference is addressability, not precision

| | prose | formula |
|---|---|---|
| stored as | a sentence | a **symbol** |
| referencable elsewhere | only by re-copying it | `[11.Body_Act]` |
| cost per reference | O(sentence) | **O(1)** |
| conflict resolution | human reading | denominator / precedence |

One symbol, referenced twenty times, carries its full definition every time. A
sentence cannot do that, because **sentences have no pointers**.

### Three shapes that do the work

**Denominator — violations go in the denominator, not a minus term**

```
质量 = 分子 / (违规1 + 违规2 + 1)
```

An additive penalty can be drowned by enough correctness. A denominator goes to
zero. The `+1` keeps zero violations from scaling the result.

**Multiplication — forces simultaneity**

```
❌ "ensure A, B and C"    → checked one at a time, C gets forgotten
✅ A × B × C              → any one at zero makes the whole zero
```

**A named exit condition**

```
❌ "check carefully before finishing"
✅ "[EA] 未清零前禁止输出最终代码"
```

A process with no named exit lets the model invent one.

### Budget, and what to do when you exceed it

```
symbols ≤ 20    formulas ≤ 40    lines per formula ≤ 3
```

**When you exceed it, split the file and add a routing table. Do not compress.**
Compression is lossy and the loss is exactly the criteria. This repo walked that
path: `SKILL.md` went from 17,607 B to 9,276 B by *moving* content into
`references/`, and the total content **grew** by 14 KB.

```
SKILL.md 会被整体塞进上下文  ⇒ 它必须小
reference 不会（只 read 局部）⇒ 它可以任意大
```

**And the reverse conclusion, which matters more than the rest of this section:**

> **Anything a script can check should be a script, not a formula.**

A formula depends on attention, which is probabilistic. `gate.sh` returns 0 or 1.
Formulas are for the semantic judgements a machine cannot make; everything else
belongs in the gate.

---

## 5. Why a second agent, and why only sometimes

The rule is not "more agents is better". It is:

```
多叫一个 AI，只有「它的任务框架与已有的不同」时才增值。
```

And there is measured evidence for the limit. Recursive self-critique without
external input decays: informational content fell from 0.193 to 0.087 (−55 %)
across three providers, and a single injection of external verification produced
a +28 % rebound. Source: [arXiv:2510.21861](https://arxiv.org/abs/2510.21861).

So the requirement is not "ask again", it is:

```
AI 问 AI 有效 ⟺ 第二个 AI 带回了「新信息」（读文件 / 跑命令 / 查资料）
AI 问 AI 无效 ⟺ 只是「重新推理一遍」—— 哪怕换模型、换 provider
```

Hence the hard requirement on the reviewer's output:

```
{ 结论, 依据（文件:行号 | 命令输出）, 不确定项 }
依据为空 ⇒ 回答无效
```

And the rule that protects the checker from the checked (G5): when a probe turns
red, the agent may not edit the probe. Ask first, bring back evidence, then
change it. Otherwise the shortest path to green is to weaken the check.

---

## 6. Where the reasoning stops

**This skill covers missing things that break.** That is a real subset, not all
of it.

| Class | Why it is out of scope | What is needed |
|---|---|---|
| missing and silently wrong | nothing goes red | an oracle: person, reference implementation, formal spec |
| missing and you do not know it is wrong | the concept is not in your vocabulary | hitting reality / a person telling you / someone else's failure taxonomy |

The second row is a hard limit, not an engineering gap. Someone who has never
built a distributed system does not ask about split-brain — not because they are
careless, but because the word is not in their vocabulary. No amount of
table-walking produces it.

**And the skill is stateless.** It cannot remember where last week's scratch
script went. That needs a host with cross-session state. The fallback is a
placement table: replace memory with a file.

```
能做的：要求有落位表 / 检查新文件落在已声明位置 / 检查 TTL / 检查越界 / 检查三定
做不到：发现"这里需要新类" / 命名 / 跨会话记住上次在哪 / 主动清理 / 实时提醒
```

**Said plainly: this skill makes a class of failure visible and cheap to reject.
It does not make an agent competent.**

---

## 7. What would falsify it

Worth writing down so the claims can be attacked:

1. **The gate is not better than a careful human.** Test: hand the same change
   to a careful reviewer and to the gate; count missed cross-boundary edges.
2. **The fixed 7 rows are the wrong 7.** Test: collect real missing-item reports
   from finished projects and see what fraction fit outside the seven.
3. **The formula style is not better than prose.** Test: the same constraint as
   prose and as a formula, same model, count violations.
4. **The 20-symbol budget is wrong.** Test: raise it and measure whether
   identifier confusion rises.

Numbers 1 and 3 are the ones that would hurt most, and neither has been run.
