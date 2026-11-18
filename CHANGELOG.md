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

## 0.8.0 — 2026-11-18

**Three holes, all found in one real project (a high-order hypergraph memory
store, 71 turns, 30 task sheets, 1,026 tool calls).**

The session's own words are the evidence:

```
用户：不要写这种东西，有个屁用。
用户：你不要去对代码，对旧的，和新的设计稿，总稿，立项书等等。以我当前的话为基准，
      将矛盾的原话全部拉出来逐行比对。
用户：我认为这样的架构涵盖了很大一片了。
用户：最小可跑是跨步处理……而不是用 cli 测试所谓的通过算通过。
```

Three failures sat in those four lines, and the skill could not see any of them:

1. **认知** — the agent had the conclusions, not the premises. It implemented
   "去重" because the user wrote "超边=节点"; the user's point was that dedup is
   *unnecessary* once that identity is structural. The output was 四不像: every
   rule defensible, none derivable.
2. **立项** — there was no place for the charter to be a *standard*. Documents
   were produced per domain, then each explained itself instead of explaining
   the next one. Contradictions surfaced as prose, not as `exit 1`.
3. **交付** — "tests pass" was repeatedly treated as delivery, and by the end
   the user had to write the rule himself: 不是 cli 通过算通过，是代码和功能要通过.

Three references, three templates, two gate modes, five rules.

### Added — `references/r5-axiom-chain.md` (认知)

**The premise chain**: 锚（原话逐字+出处）→ 拆（A = B / 只有 N 种）→ 推（一步一条
「因此」）→ 落（条文 + 一条可复算判据）. Plus the four rulers every word and
every classification must pass: 反例列 / 穷举 / 同形词分离 / 不需要清单, and the
rule that "不要写这种东西，有个屁用" is a rejection of *form*, not content.

**Why it exists**: a rule that cannot name the sentence it came from is a
component without a system. Nothing in the old skill could detect that.

### Added — `references/r6-project-charter.md` (立项)

**The charter as a standard, not a document.** Seven sections (一句话 / 目标带证据 /
域表 / 依赖顺序串并汇 / 落位表 / 不做 / 裁决点), the nine domains, and the
document constitution: D1 只写当前真相 · D2 插入/替换/删除 · D3 一个概念一处 ·
D4 文件数只减不增 · D5 编号不复用 · D6 完成改状态不重读, with a prefix table, a
single-authority table, and NR1–NR9 all grep-able.

**Why it exists**: 各自解释 ≠ 互相解释. Without D3 the same concept gets two
definitions and the next reader cannot tell which one is live; without D6 every
new agent re-reads finished work.

### Added — `references/r7-slice-board.md` (切片与派活)

**One slice = one function that walks from input to rows and back to meaning.**
Four-column slice table, the four questions each slice must answer, the
anti-shelling probe (delete the cause, the reading must break), the nine-section
task sheet, the falsification requirement (inject → must go red → restore), and
the three things the lead may not delegate: freeze the skeleton, write the
acceptance probes, verify line by line.

**Why it exists**: 30 task sheets were written in that session by hand, each
carrying 写域 / 冻结契约 / 语义编号 / 反证 — and each time they worked, it was
because someone remembered all nine parts.

### Added — `templates/立项书.md` rewritten, `文档宪法.md`, `切片表.md`, `任务书.md`

The old 立项书 template stopped at six items: core question, consumers, criteria,
not-doing, evidence level, unknowns. That is a good **shape**, and it is not a
**standard**: it cannot decide whether a downstream document is lying. §7–§11
were added (域表 / 依赖顺序 / 落位表 / 裁决点 / 状态表) and §0 gained the
one-sentence-with-the-strongest-constraint test.

### Added — `gate.sh --charter` and `gate.sh --board`

Two modes, because these are the two places where a project stops being
verifiable *silently*:

* `--charter` (G9/G10): seven sections present, nine domains named, 串/并/汇
  written, state table has all three values, constitution exists, ruling points
  name their downstream effect, no patch segments (D1).
* `--board` (G11): four columns present, falsification section exists, order
  written on one line, no 待定/待补.

Both are opt-in: a project that predates 0.8.0 keeps passing.

### Rules — C10–C12, G9–G11

```
C10 每条规则都要能指回一句话。指不回 = 四不像的零件。
C11 用户的原话是唯一权威。改写 = 换掉了权威，只剩你的理解。
C12 一个概念只许一处定义；第二处定义 = 下一次必然不同步。

G9  立项书缺域表 / 依赖顺序 / 落位表 / 裁决点，不许开工。
G10 文档里出现补丁段（「原写…现改为…」「补记」），该文档按未完成处理。
G11 派活时写域没写清（哪些能改、哪些不许改），不许发任务。
```

**G8 was also reworded**: 没有反证的判据不算判据（测不出红 = 永远为真）. The old
wording covered the spiral only; falsification is a property of every criterion.

### Changed — 五种最常见的失败 → 八种

Added ⑥ 抄结论代替抄前提 · ⑦ 文档数代替唯一权威 · ⑧ 子代理报告代替验收.
All three produced green tests in the source session.

### Changed — the gate resolves file names instead of demanding them

The source project has `00-立项书-0.0.3.md`, `90-文档纪律与编号规则.md`,
`15-实施切片.md`, `10-范畴表.md` (in subdirectories). A gate that only accepts
`立项书.md` would have reported "does not exist" for documents that exist — the
same false red this repo forbids elsewhere.

`gate.sh` now resolves by keyword, shallow-first (`--charter`, `--board`, and G1):

```
立项书 → 立项书.md，或名字含「立项书」的 .md
宪法   → 文档宪法.md，或名字含「宪法」/「纪律」的 .md
切片   → 切片表.md，或名字含「切片」的 .md
范围   → 顶层 → 一层 → 两层（真实项目的文档按域分目录）
```

And the 域表 check accepts `九域 / 九个域 / 总揽`, because the concept is "the
domain table", not the heading text. Checked against the real project: it passes
G9/G10/G11 and honestly blocks on the five artefacts it never produced
(规划 / 策划 / 集成面 / 验收 / 反合理化).

### Added — `docs/flow-observed.md`

The session read as a flow: six phases, six facts that recur, the exact paragraph
the user re-typed twelve times (his hand-written slice protocol), and the three
things worth building next (`矛盾裁决表` + `--conflicts`; a pre-flight probe
before dispatching a subagent, because four background subagents failed with no
closing message; re-read the authority table after a model switch, because three
switches happened and each time the vocabulary drifted).

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
