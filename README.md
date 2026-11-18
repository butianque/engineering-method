# engineering-method

> **An agent skill that refuses to let "tests pass" mean "it works".**

[![CI](https://github.com/butianque/engineering-method/actions/workflows/ci.yml/badge.svg)](https://github.com/butianque/engineering-method/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-black.svg)](LICENSE)
[![Skill version](https://img.shields.io/badge/skill-0.7.1-informational)](CHANGELOG.md)

**中文版 → [README.zh-CN.md](README.zh-CN.md)**

---

## The problem

An agent hands you a change. It compiles. The tests are green. It says **done**.

Then you use it, and the feature is one small piece; the rest of the system was never built.

This is not a capability gap. It is a **gap in what gets checked**:

```
Tests can only assert the behaviour of code that exists.
Something that does not exist produces no red.
⇒ "all tests green" does not imply "the system works".
```

Three failure modes follow, and no amount of "be careful" fixes them:

| # | Failure | Why it survives review |
|---|---|---|
| **F1** | The missing thing is absent — no code, no test, no red | Nothing to look at |
| **F2** | The checker is written by the thing being checked | Self-certification |
| **F3** | Each piece is locally correct; the chain is not connected | Per-file reasoning hides the edges |

## What this skill does

It converts those three into **machine-checkable artefacts**, then gates on them.

```
拿到一个请求，先回答：它应该长什么样，我才能完成它？
答不出来，后面全是瞎写。
```

Eight entry points, one pipeline:

```
0 应然形态 → 1 规划 → 2 策划 → 3 设计(三定) → ↻ 认知补给 ⇄ 4 范畴
                                                    ↓
                                    5 集成面 → 6 验收 → 7 反合理化
```

The outputs are eight files, and `gate.sh` refuses to pass until they are real:

| Artefact | What it proves |
|---|---|
| `立项书.md` | The request was restated as a **shape**, not a feature list |
| `规划.md` | Each stage has an exit criterion you can run |
| `策划.md` | At least two options, each with "when this is wrong" |
| `设计.md` | **三定**: dependency order, module dependency direction, style contract |
| `范畴表.md` | Terms, invariants, ownership boundaries |
| `集成面.md` | The 7-line integration surface, every line backed by a **command** |
| `验收.sh` | L1 syntax → L2 unit → **L3 end-to-end from the real entry** |
| `反合理化表.md` | Excuses → reality, with named consequences |

Four more since 0.8.x: `文档宪法.md` (how docs may change · numbering · single authority), `切片表.md` (one slice = one end-to-end function), `任务书.md` (the task sheet for a subagent), `开发日志.md` (one log per slice, six sections).

## Three ideas worth stealing

### 1. Domains are derived, not listed

```
domain = category = "one class of thing that must exist for this to hold"
How many, and what they are called, is derived from the problem — not from a template.
Test: if you delete it, how does the system break? No answer ⇒ it is a detail, not a domain.
```

Order: **derive (feature → which suffering disappears → what must co-exist) → bound (what it owns / what it does not / how it is judged) → elicit (pull the requirement out of the user) → fall back (if he cannot say, ask the industry: who does this / why / at what cost) → write it down without patches.**

The user usually says **half**. So elicitation is part of charting, not a communication skill:
ask judgeable choices, offer the industry default for him to veto, reverse-derive from "what if we skip it", one question at a time, written down immediately.
**Criterion: every question must be answerable as one judgeable sentence; if not, the question is wrong — not the user.**

That also constrains the gate: **`--charter` checks structure (tables filled / paths exist / a boundary / an unknown with how-to-verify), never "are there nine domains".** A criterion that names one project's vocabulary only works on that project — `scripts/verify.sh` section 11 exists to hold that line.

### 2. Test passing is one linear extension of the dependency partial order

```
时间 = 依赖偏序 ⊑ 执行全序
      An agent writes the total order (line by line) and never checks the partial order
      (what must be produced before what is consumed).

空间 = 人造物 → 已声明坐标，且坐标图是 DAG
      An agent sees files. It does not see a node's position in a graph.
```

A test is **one** linear extension of the partial order. Completion is the **whole** partial order being covered.
That is why a green suite can coexist with a broken system — and why the fix is to write down every **cross-boundary edge** and give each one a command that covers it.

### 3. You cannot tell an agent what is missing; you can let it watch something break

```
你没法告诉 AI 它缺什么。
但你可以让它看见：拆掉这个，天塌了。
```

A missing item is invisible; a **break** is not. `gate.sh` turns "I think it's complete" into `exit 1`.

## Install

One command. It detects the agents you already have and installs into each.

**macOS / Linux / WSL / Git Bash**

```bash
curl -fsSL https://raw.githubusercontent.com/butianque/engineering-method/main/install.sh | bash
```

**Windows (PowerShell 5.1+ / 7+)**

```powershell
irm https://raw.githubusercontent.com/butianque/engineering-method/main/install.ps1 | iex
```

**From a clone**

```bash
git clone https://github.com/butianque/engineering-method.git
cd engineering-method
bash install.sh            # or:  pwsh -File install.ps1
```

### Options

| Flag (bash / pwsh) | Effect |
|---|---|
| `--agent <list>` / `-Agent` | `claude,dsh,opencode,cursor,codex,gemini,agents` — default: auto-detect |
| `--all` / `-All` | Every supported agent, even ones not detected |
| `--project` / `-Project` | `./.claude/skills` etc. instead of `$HOME` |
| `--dir <p>` / `-Dir` | Install into exactly `<p>` (it will contain `SKILL.md`) |
| `--skills-dir <p>` / `-SkillsDir` | Install into `<p>/engineering-method` |
| `--force` / `-Force` | Reinstall even when the installed copy matches |
| `--dry-run` / `-DryRun` | Print the plan, change nothing |
| `--uninstall` / `-Uninstall` | Remove from the same targets |
| `--no-generic` / `-NoGeneric` | Skip the `~/.agents/skills` fallback |

Both installers are **idempotent** (same tree hash ⇒ skip) and **cross-platform consistent** (a tree installed by `install.sh` is recognised as up-to-date by `install.ps1`).

**Manual install** — copy `skills/engineering-method/` into your agent's skills directory. See [docs/agent-directories.md](docs/agent-directories.md) for the full path table.

**If `raw.githubusercontent.com` is blocked** — common on networks where plain `github.com` still answers but the raw CDN resets the connection, so the one-liner above cannot even start — three routes that avoid that host are in [docs/install.md](docs/install.md#when-rawgithubusercontentcom-is-unreachable).

## Use

Nothing to invoke. The skill triggers on **eight kinds of talk**, in Chinese or English:

| | Triggers on | Enters at |
|---|---|---|
| 认知 | "认知不对" "没有这层认知" "做出来四不像" | ↻ 补给 → premise chain |
| 范畴 | "定个范畴" "术语不统一" "边界在哪" | step 4 |
| 立项 | "立项" "要不要做" "从哪开始" "立项即标准" | step 0 |
| 规划 | "规划" "分几步" "里程碑" | step 1 |
| 策划 | "策划" "方案" "怎么落地" | step 2 |
| 设计 | "设计" "它应该长什么样" "部件怎么接" | step 3 |
| **工程** | "工程" "架构" "模块" "分层" "耦合" "依赖" "重构" "技术债" "跨仓库" | **step 3 三定 → 5** |
| **代码** | "写代码" "加个接口" "改一下" "报错了" "测试过了" "好像没问题" | **step 3 三定 → 5 → 6** |

The last two are the point: **the kinds of talk most likely to skip the process are exactly the ones wired to the hardest gate.**

## The machine gate

The prose half raises the probability of doing it right. `scripts/gate.sh` sets the floor.

```bash
SK=~/.dsh/skills/engineering-method        # or ~/.claude/skills/… , ~/.config/opencode/skills/… etc.

bash $SK/scripts/gate.sh <project>                # all eight artefacts + G7 三定
bash $SK/scripts/gate.sh <project> --steps 3      # design only (G4 sign-off + G7 三定)
bash $SK/scripts/gate.sh <project> --arch         # + placement (G6)
bash $SK/scripts/gate.sh <project> --done         # + acceptance must exit 0 (G3)
bash $SK/scripts/gate.sh <project> --spiral       # + every round recorded a new fact (G8)
bash $SK/scripts/gate.sh <project> --charter      # + the charter is a standard (G9 / G10)
bash $SK/scripts/gate.sh <project> --board        # + every slice is dispatchable (G11)
```

Exit codes: `0` pass · `1` blocked · `2` usage error. It only reads. It never edits anything.

| Gate | Blocks on |
|---|---|
| G1 | Any required artefact missing or empty |
| G2 | `集成面.md` still contains 「不存在」, or a probe cell is empty |
| G3 | `验收.sh` exits non-zero |
| G4 | System design not signed off |
| G5 | (policy) probe turned red and you want to edit the probe — ask a second agent first |
| G6 | A file that maps to no declared placement |
| **G7** | **三定 incomplete: no dependency-order table / no module dependency direction / vague style** |
| **G8** | **A spiral round with no new fact; or a criterion with no falsification** |
| **G9** | **The charter cannot be judged: tables not filled / declared docs missing / no boundary / no unknown-or-how-to-verify** |
| **G10** | **A patch segment in a document ("原写…现改为…", "补记") — D1 forbids it** |
| **G11** | **The slice board cannot be dispatched: table not filled / no falsification / no dependency / still placeholders** |

## Layout

```
engineering-method/
├── skills/engineering-method/       the skill itself
│   ├── SKILL.md                     20 KB entry: C/G rules, 8 entries, 9 steps, routing table
│   ├── references/                  31 files, loaded on demand
│   ├── templates/                   17 files: 立项书 / 规划 / 策划 / 设计 / 范畴表 / 集成面 /
│   │                                           验收.sh / 反合理化表 / 文档宪法 / 切片表 / 任务书
│   └── scripts/
│       ├── gate.sh                  the machine gate
│       └── arch-check.sh            placement + boundary check
├── install.sh  install.ps1          one-shot installers
├── .claude-plugin/                  Claude Code plugin + marketplace manifest
├── docs/                            install / agents / why
└── scripts/verify.sh                what CI runs
```

`SKILL.md` is a **dispatch layer**, not a manual: it decides *whether* to enter and *which step*, then points at the one reference you need. Everything else loads on demand, so the entry file stays at 16 KB and nothing is lost to truncation.

## Honest limits

This skill covers **missing things that break**. It does not cover:

| Class | Why not | What is needed |
|---|---|---|
| Missing but silently wrong (200 with wrong data) | Nothing goes red | An oracle: a person, a reference implementation, a formal spec |
| Missing and you don't even know it's wrong | Not in your vocabulary | Hitting reality / a human telling you / reading someone else's failure taxonomy |

And the skill is stateless. It cannot remember where you put last week's scratch script — that needs a host with cross-session state. The fallback is a **placement table**: replace memory with a file.

```
能做的：要求有落位表 / 检查新文件落在已声明位置 / 检查 TTL / 检查越界 / 检查三定
做不到：发现"这里需要新类" / 命名 / 跨会话记住上次在哪 / 主动清理 / 实时提醒
```

## Does it work?

The gate was built against real failures, not hypotheticals. One example:

```
A session fix that touched 9 places across 2 repositories.
Fix 1 of 9 applied  →  go test ./internal/api/handlers/management/  →  ok  20.3s
User experience     →  still logged out
```

`gate.sh` reports it as:

```
BLOCK  G2 集成面里还有 7 处「不存在」—— 这些就是待做的
       14:| 5 | 失败路径 | ... | 不存在 |
       18:| 9 | 下游改动（面板） | ... | 不存在 |
```

The Go test cannot see the panel repository. The gate can, because the dependency edge was written down.

## Docs

| | |
|---|---|
| [docs/install.md](docs/install.md) | Every install path, verification, uninstall |
| [docs/agent-directories.md](docs/agent-directories.md) | Per-agent skill directory table + manual install |
| [docs/why.md](docs/why.md) | Why formula-shaped constraints beat prose, and where the limits are |
| [docs/flow-observed.md](docs/flow-observed.md) | The flow an actual 71-turn session produced, and which failure each 0.8.0 change grew out of (Chinese) |
| [CHANGELOG.md](CHANGELOG.md) | What changed, and why each change exists |

## License

MIT — see [LICENSE](LICENSE).
