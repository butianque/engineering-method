# Install

Three ways in, one verification step, one way out. Nothing here needs Node, Go,
or Python — only `curl`/`tar` on POSIX, or PowerShell on Windows.

---

## One command

### macOS / Linux / WSL / Git Bash

```bash
curl -fsSL https://raw.githubusercontent.com/butianque/engineering-method/main/install.sh | bash
```

### Windows (PowerShell 5.1+ / 7+)

```powershell
irm https://raw.githubusercontent.com/butianque/engineering-method/main/install.ps1 | iex
```

### From a clone (recommended if you want to read it first)

```bash
git clone https://github.com/butianque/engineering-method.git
cd engineering-method
bash install.sh          # POSIX
pwsh -File install.ps1   # Windows
```

The clone path and the piped path do the same thing. The difference is where the
payload comes from:

| Run as | Payload source |
|---|---|
| `bash install.sh` | the sibling `skills/engineering-method/` directory |
| `curl … \| bash` | `https://github.com/…/archive/refs/heads/main.tar.gz`, unpacked into a temp dir |

Both end in one step: copy one directory into place. A piped run has no `$0`
path and no sibling files, which is why the tarball branch exists at all.

---

## What it does on your machine

1. Resolves which agents to install into (see below).
2. Prints the skill version and a fingerprint of the tree.
3. For each target: skip if the installed tree already has the same fingerprint,
   otherwise replace `<target>/engineering-method/` wholesale.
4. Reminds you to restart the agent.

It never touches anything outside `<target>/engineering-method/`. It does not
edit `PATH`, shell profiles, or other skills.

### Target selection

| How | Behaviour |
|---|---|
| _(no flag)_ | Auto-detect: an agent counts as installed when its **parent** directory exists (`~/.claude`, `~/.cursor`, …). `~/.agents/skills` is always added as a generic fallback. |
| `--all` | All seven, detected or not. |
| `--agent claude,codex` | Exactly these. Accepts `all`. |
| `--project` | Uses `./` instead of `$HOME`, so the skill travels with the repository. |
| `--dir /path` | Exactly `/path` — afterwards `/path/SKILL.md` exists. |
| `--skills-dir /path` | `/path/engineering-method`. |
| `--no-generic` | Drop the `~/.agents/skills` fallback. |

The full path table is in [agent-directories.md](agent-directories.md).

### Idempotency

The installer fingerprints the tree (relative path + SHA-256 of every file,
hashed again). If the installed copy matches, it prints `up to date` and writes
nothing. The bash and PowerShell installers produce the **same** fingerprint for
the same tree, so installing from either one and re-running the other is a no-op.

Use `--force` to reinstall anyway, which is the right move after you have edited
a template locally and want the shipped one back.

---

## Verify

```bash
SKILL=~/.dsh/skills/engineering-method      # substitute your agent's path

# 1. the entry file is intact and the version is what you expect
head -20 "$SKILL/SKILL.md"

# 2. the gate runs and refuses a usage error (exit 2)
bash "$SKILL/scripts/gate.sh"; echo "exit=$?"

# 3. it blocks on an empty project — a gate that always passes is worse than none
mkdir -p /tmp/empty-proj && bash "$SKILL/scripts/gate.sh" /tmp/empty-proj; echo "exit=$?"
```

Step 3 must print `BLOCK` and exit `1`. If it prints `PASS`, the copy is wrong.

The last check matters more than it looks: the whole point of this skill is that
a check which always succeeds is indistinguishable from no check.

---

## Uninstall

```bash
# same target selection as install
bash install.sh --uninstall
pwsh -File install.ps1 -Uninstall

# or one agent
bash install.sh --uninstall --agent claude
```

Only `<target>/engineering-method/` is removed. Nothing else is touched.

If you installed by hand, `rm -rf` the directory you copied.

---

## Keeping it current

```bash
# re-run the installer; identical trees are skipped
curl -fsSL https://raw.githubusercontent.com/butianque/engineering-method/main/install.sh | bash

# pin a branch or tag
EM_BRANCH=v0.7.1 curl -fsSL https://raw.githubusercontent.com/butianque/engineering-method/main/install.sh | bash

# preview first
curl -fsSL https://raw.githubusercontent.com/butianque/engineering-method/main/install.sh | bash -s -- --dry-run
```

`EM_BRANCH` is read by both installers.

---

---

## When `raw.githubusercontent.com` is unreachable

This is common on networks where plain `github.com` works but the raw CDN does
not (the connection is reset during TLS, so `curl` reports `(35) Recv failure` or
`(28) Timeout`). The one-liner above will fail there — the installer never runs.

Two routes that do not touch the raw CDN.

### Route 1 — run the installer out of the release tarball

`github.com/<owner>/<repo>/archive/…` is a different host path from
`raw.githubusercontent.com`, so it often works where the CDN does not.

```bash
curl -fsSL https://github.com/butianque/engineering-method/archive/refs/heads/main.tar.gz \
  | tar -xzO --wildcards '*/install.sh' | bash -s -- --all
```

Extract, then run — if you would rather read the script first:

```bash
curl -fL https://github.com/butianque/engineering-method/archive/refs/heads/main.tar.gz -o em.tar.gz
tar -xzf em.tar.gz
sed -n '1,40p' engineering-method-main/install.sh
bash engineering-method-main/install.sh --all
```

### Route 2 — point the installer at a mirror

`EM_SRC_URL` replaces the whole download URL, so any mirror or proxy works:

```bash
EM_SRC_URL="https://my-mirror.example/em/main.tar.gz" \
  bash <(curl -fsSL https://my-mirror.example/em/install.sh) --all
```

The same variable exists in PowerShell (`$env:EM_SRC_URL`), where the payload is
a `.zip` rather than a `.tar.gz`.

`EM_BRANCH` selects a branch or tag; `EM_SRC_URL` overrides it entirely.

### Route 3 — clone over SSH

Pushing already uses `ssh.github.com:443` in some networks; the same path works
for fetching:

```bash
git clone ssh://git@ssh.github.com:443/butianque/engineering-method.git
cd engineering-method && bash install.sh
```

### Whichever route you take

All of them install the **same tree**. The installer fingerprints the result, so
a copy installed one way and re-installed another way is recognised as current:

```
repo skill : d1d2028b9f7f…      ← same hash from every route
piped out  : d1d2028b9f7f…
installed  : d1d2028b9f7f…
```
---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `curl: (22) … 404` | `EM_BRANCH` points at something that does not exist | unset it, or use `main` |
| `bash: $'\r': command not found` | the script was saved with CRLF | use the `curl` one-liner, or `git config core.autocrlf input` and re-clone |
| `no agent detected` | none of `~/.claude`, `~/.dsh`, … exist | use `--all`, `--agent`, or `--dir` |
| Installs, but the agent never loads it | the agent was not restarted | restart it, or reload its skill list |
| Installs, but it never triggers | the agent matched its own description rules first | name it explicitly — "用 engineering-method" |
| `cp: cannot create directory` | parent path did not exist and could not be created | check permissions on the parent |
| Gate says `PASS` on an empty project | you are running an old copy | reinstall with `--force` |

---

## What is installed

```
<target>/engineering-method/
├── SKILL.md          the entry point the agent reads
├── references/       27 files, loaded only when the step needs them
├── templates/        13 files the skill copies into your project
└── scripts/
    ├── gate.sh       the machine gate (only reads, only refuses)
    └── arch-check.sh placement and boundary check
```

The skill writes its templates into **your project**, never into its own
directory. Nothing it produces is global state.
