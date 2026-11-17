# Agents and skill directories

A skill is a directory containing `SKILL.md`. Where that directory goes is the
only thing that differs between agents. This file lists the paths this repo's
installers know about, plus how to install by hand anywhere else.

---

## Path table

| Agent | User-level skills directory | Project-level |
|---|---|---|
| [CC] | `~/.claude/skills/` | `<repo>/.claude/skills/` |
| DSH | `~/.dsh/skills/` | `<repo>/.dsh/skills/` |
| opencode | `~/.config/opencode/skills/` | `<repo>/.opencode/skills/` |
| Cursor | `~/.cursor/skills/` | `<repo>/.cursor/skills/` |
| Codex | `~/.codex/skills/` | `<repo>/.codex/skills/` |
| Gemini CLI | `~/.gemini/skills/` | `<repo>/.gemini/skills/` |
| **generic** | `~/.agents/skills/` | `<repo>/.agents/skills/` |

`~` means `$HOME` on POSIX and `%USERPROFILE%` on Windows.

**The generic row is the escape hatch.** Any agent that follows the
"one directory, `SKILL.md` inside" convention can read `~/.agents/skills/`.
That is why the installer adds it by default: it costs one directory and it is
the only row that keeps working for an agent this repo has never heard of.

### Detected or not

The installer treats an agent as installed when the **parent** of its skills
directory exists:

```
~/.claude exists   ⇒  claude is installed  ⇒  create ~/.claude/skills/ and copy in
~/.cursor missing  ⇒  cursor is not installed ⇒  skip
```

Checking the parent rather than the skills directory is deliberate: a skills
directory that does not exist yet is the normal state of a fresh install, so
testing for it would skip every agent that has never had a skill.

---

## Manual install

If your agent is not in the table, or you would rather not run a script:

```bash
git clone https://github.com/butianque/engineering-method.git
cp -R engineering-method/skills/engineering-method <your-skills-dir>/engineering-method
```

Windows:

```powershell
git clone https://github.com/butianque/engineering-method.git
Copy-Item -Recurse engineering-method\skills\engineering-method <your-skills-dir>\engineering-method
```

Two things must hold afterwards:

1. `<your-skills-dir>/engineering-method/SKILL.md` exists.
2. The directory name matches the `name:` field in `SKILL.md` — both are
   `engineering-method`. A mismatch is the most common reason a skill silently
   never loads.

Verify:

```bash
head -3 <your-skills-dir>/engineering-method/SKILL.md
bash <your-skills-dir>/engineering-method/scripts/gate.sh; echo "exit=$?"   # expect 2
```

---

## [CC] plugin marketplace

This repo also ships `.claude-plugin/marketplace.json`, so [CC] can add it as a
marketplace instead of copying directories:

```
/plugin marketplace add butianque/engineering-method
/plugin install engineering-method@engineering-method
```

The plugin source is the repo root, and the skill is discovered at
`skills/engineering-method/`. Pick **either** this route or the installer — not
both, or you will have two copies and two places to update.

---

## Multi-skill repositories

This repo is laid out for growth:

```
engineering-method/
└── skills/
    └── engineering-method/     ← one skill
        └── SKILL.md
```

If another skill is added, it becomes `skills/<name>/SKILL.md` and the installer
keeps working unchanged — it installs `skills/engineering-method` specifically,
so a second skill needs its own line in the installer or its own repo.

The single-skill shape was chosen on purpose: one repository, one version, one
CHANGELOG, and an install command that cannot pick the wrong skill.

---

## Agent-side notes

| Agent | How it decides to load a skill | Practical consequence |
|---|---|---|
| [CC] | Reads the `description` and matches it to the task | Put concrete trigger phrases in `description`, not a summary of the process |
| DSH | Same, plus an explicit skill tool | You can also force it: "use engineering-method" |
| opencode | Same | Project-level install wins for repo-scoped work |
| Cursor | Rules/skills surface, description-matched | Project-level install is the reliable one |
| Codex | `$skill-name` or description match | `$engineering-method` forces it |
| Gemini CLI | Description match | Same caveat as everywhere: name it explicitly when unsure |

**Every one of these is probabilistic.** Loading is a match against a
description, so it can fail on wording. That is precisely why the skill ships
`scripts/gate.sh`: the gate does not depend on being loaded. If the agent never
reads the skill, you can still run the gate by hand and get the same answer.

```
软半（提示词）  只提高概率
硬半（gate.sh） 保下限
```

---

## Uninstall by hand

```bash
rm -rf <your-skills-dir>/engineering-method
```

Nothing else was installed anywhere.
