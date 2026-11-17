# Changelog

Every entry says **why the change exists**, not only what changed. The version
rule is the one used by the skill itself: `x` for a restructure, `y` for a new
step or gate, `z` for content added inside an existing step.

The skill started as two separate skills inside a private workspace:

```
engineering-method   how to think   (立核 → 范畴 → 递归 → 检索 → 规划 → 冻结 → 验证 → 落盘)
system-project-init  how to refuse  (five artefacts + integration surface + acceptance + gate)
```

They were merged because their trigger conditions overlapped (both claimed
"规划"), because the order they enforce was always one chain, and because a user
wants a chain, not a methodology plus a door. Everything below is post-merge.

---

## 0.7.1 — 2026-11-17

**Trigger vocabulary: six kinds of talk → eight.**

The first six (认知 / 范畴 / 立项 / 规划 / 策划 / 设计) are all *thinking* talk.
There was not a single *doing* trigger. The consequence was exact and bad:

```
"加个接口"        → no match → skill does not load → code written directly
"重构一下"        → no match
"报错了"          → no match
"测试过了，上线吧"  → no match
```

**The two categories most likely to skip the process were the two that could not
trigger it.** Added:

* **工程** — 工程 / 架构 / 模块 / 分层 / 耦合 / 依赖 / 重构 / 技术债 / 跨仓库 / 部署顺序.
  Enters at **step 3 三定 → 5**. Structure talk must land in the three
  definitions, or "we should decouple" is a sentence with no consequence.
* **代码** — 写代码 / 加个接口 / 改一下 / 报错了 / 测试过了 / 好像没问题.
  Enters at **step 3 三定 → 5 → 6**. Action talk must be preceded by 三定 and
  followed by end-to-end.

Also: the 「时间与空间」and「分类与统筹」sections were collapsed into one two-row
"what it can / cannot check" table. Detail already lives in `references/`, so the
only thing removed was the duplication inside `SKILL.md`. 16,711 B → 16,184 B.

**Repository packaging** (same version): this repo. Layout `skills/<name>/`,
two idempotent installers (`install.sh`, `install.ps1`) covering seven agents
plus a generic fallback, `[CC]` marketplace manifest, `scripts/verify.sh` as the
repo's own gate, and CI on three platforms.

The instruction that produced it was 「具备一键安装的能力，放入任何 agent 内」. The
two decisions worth recording:

* **Auto-detect on the parent directory, not the skills directory.** A missing
  `skills/` is the normal state of a fresh install; testing for it would skip
  every agent that has never had a skill.
* **`~/.agents/skills/` is always added.** It costs one directory and it is the
  only target that keeps working for an agent this repo has never heard of.

## 0.7.0 — 2026-11-15

**Time and space, stated as two lines you can check.**

```
时间 = 依赖偏序 ⊑ 执行全序
      AI writes the total order (line by line) and never checks the partial
      order (what must be produced before what is consumed).

空间 = 人造物 → 已声明坐标，且坐标图是 DAG
      AI sees files. It does not see a node's position in a graph.
```

This turned two vague complaints into definitions, and proved the thing that
motivated the whole skill:

```
A test is ONE linear extension of the dependency partial order.
Completion is the WHOLE partial order being covered.
⇒ tests passing does NOT imply the partial order is closed.
```

Added:

* Rules `C7` (范畴 ⊏ 完成), `C8` (tests ≠ completion), `C9` (the method is
  `f(state)`, not a constant — a more specific plan has a shorter shelf life).
* Rule `G7` and a gate: **立项后三定** — placement, dependency order, style.
  Missing any one blocks business code.
* `设计.md §1.5` dependency-order table, whose last column is the whole point:
  *which total order covers this cross-boundary edge*. A row with an empty last
  column is an edge nobody verifies.
* `设计.md §2.2` module dependency direction (read it as a graph; it must be a DAG).
* `设计.md §2.6` style contract, which **must carry numbers** (nesting ≤ 3,
  comment ratio 10–30 %). "Keep it clean" is not a contract.
* **Spiral** and `gate.sh --spiral`: every round must record one fact it did not
  know before. Without that, a spiral degrades into iteration — the same
  self-critique loop whose informational content decays ~55 %.

## 0.6.0 — 2026-11-14

**Classification and coordination: AI has no spatial memory.**

The trigger was a concrete one: writing a throwaway test endpoint required
reading half the repository to work out where it could live, and then it was
dumped wherever looked closest and never removed.

Root cause is not capability but carrier: an agent has the current context and
nothing else. So it applies a **nearest-neighbour rule** — put the new thing
beside the last thing that looked related. Ten of those and the same kind of file
lives in ten places.

The fix is not to make it smarter; it is to give it a **table it can look up**
instead of a location it must infer. Added:

* `templates/设计.md §2.5` placement table (what kind of thing → which directory
  → naming → lifetime), with four rules, the fourth being *a missing row means
  the table is incomplete: fill the table, do not dump the file*.
* `scripts/arch-check.sh` — A1 table exists, A2 every row has a location and a
  TTL, A3 every code file maps to some row.
* `gate.sh --arch` (G6).
* An explicit, non-hedged limit: the skill can require the table and check the
  result; it cannot invent a new category, name it, remember last week's
  location, or clean up after itself. Those need a host with cross-session state.

## 0.5.0 — 2026-11-13

**One file → a dispatch layer plus discrete references.**

The entry file had reached 17,607 B of a 20,000 B hard limit. Compressing it
would have cost exactly the thing worth keeping — the criteria and the
counter-examples — so nothing was compressed. Content was **moved**:

```
before   SKILL.md 17,607 B (88 %) + references 23 + templates 8    ≈ 190 KB
after    SKILL.md  9,276 B (46 %) + references 25 + templates 13   ≈ 204 KB
```

**Half the entry file, fourteen kilobytes more total content.** `SKILL.md` was
reduced to three jobs: decide whether to enter, decide which step, point at the
one reference needed. Everything else loads on demand.

Also renumbered the steps 0–7 plus one loop, because 「认知补给」had been
numbered as a linear stop when it is actually the loop between design and
category: design exposes a gap → go learn → settle it as a category → come back
and change the design.

## 0.4.0 — 2026-11-13

**Two skills merged into one.**

Trigger overlap was the forcing reason: both descriptions claimed "规划", so the
host could not tell which to load. But the deeper reason is that the order they
enforce was always a single chain — think first, then start; integration surface
before business code.

The nine steps are the merge:

```
0 应然形态 → 1 规划 → 2 策划 → 3 设计 → ↻ 认知补给 ⇄ 4 范畴 → 5 集成面 → 6 验收 → 7 反合理化
```

`system-project-init` was archived, not deleted, so the merge is auditable.

## 0.3.0 and earlier — pre-merge

Two skills, five artefacts each, and a gate that only checked three of them.
Building the gate against a real cross-repository bug is what produced the
7-line integration surface and the "every probe is a command" rule: the first
version of the table let the model add and remove rows, which meant a row it
had not thought of could simply be deleted, and the report came back green —
exactly the same failure as "the tests pass".
