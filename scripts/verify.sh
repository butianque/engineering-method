#!/usr/bin/env bash
# verify.sh — the repository's own gate. CI runs exactly this; run it locally too.
#
#   bash scripts/verify.sh
#
# Exit 0 = the repo is publishable. Exit 1 = something is wrong, and the failing
# check prints the file and line it is about.
#
# This file exists because the repo ships a skill that demands a machine gate.
# A repo that argues for gates and has none of its own is a joke. Every check
# here is something that has actually broken during development:
#
#   * SKILL.md grew past the host's truncation threshold (content silently lost)
#   * frontmatter `name` drifted from the directory name (skill never loads)
#   * a reference was renamed and SKILL.md still pointed at the old path
#   * shell scripts carried CRLF (bash: $'\r': command not found)
#   * VERSION, SKILL.md metadata.version and plugin.json disagreed

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_DIR="$ROOT/skills/engineering-method"
SKILL_MD="$SKILL_DIR/SKILL.md"

FAIL=0
say()   { printf '%s\n' "$*"; }
ok()    { printf 'ok    %s\n' "$*"; }
bad()   { printf 'FAIL  %s\n' "$*"; FAIL=1; }
head2() { printf '\n== %s ==\n' "$*"; }

# ---------------------------------------------------------------- 1 frontmatter
head2 "1 frontmatter"

if [ ! -s "$SKILL_MD" ]; then
  bad "missing $SKILL_MD"
else
  name="$(sed -n 's/^name:[[:space:]]*//p' "$SKILL_MD" | head -1 | tr -d '\r')"
  desc="$(sed -n '/^description:/,/^[a-z_]*:/p' "$SKILL_MD" | head -20 | wc -l)"
  ver="$(sed -n 's/^[[:space:]]*version:[[:space:]]*"\{0,1\}\([^"]*\)"\{0,1\}[[:space:]]*$/\1/p' "$SKILL_MD" | head -1)"

  if [ "$name" = "engineering-method" ]; then ok "name = engineering-method"
  else bad "frontmatter name is '$name', want 'engineering-method' (must match the directory)"; fi

  if [ "$desc" -gt 1 ]; then ok "description present ($desc lines)"
  else bad "description missing or empty"; fi

  if [ -n "$ver" ]; then ok "metadata.version = $ver"
  else bad "metadata.version missing"; fi

  # license and category are required by this repo's own convention
  grep -q '^license:' "$SKILL_MD" && ok "license field present" || bad "license field missing"
fi

# ---------------------------------------------------------------- 2 size limits
head2 "2 size limits"

BYTES=$(wc -c <"$SKILL_MD" | tr -d ' ')
LINES=$(wc -l <"$SKILL_MD" | tr -d ' ')
if [ "$BYTES" -lt 20000 ]; then ok "SKILL.md $BYTES bytes (< 20000)"
else bad "SKILL.md $BYTES bytes — over 20000, the host truncates and the tail is lost"; fi

if [ "$LINES" -lt 500 ]; then ok "SKILL.md $LINES lines (< 500)"
else bad "SKILL.md $LINES lines — over 500"; fi

# references must stay one level deep: references/*.md, never references/*/*.md
deep=$(find "$SKILL_DIR/references" -mindepth 2 -type f 2>/dev/null | head -5)
if [ -z "$deep" ]; then ok "references are one level deep"
else bad "nested files under references/:"; printf '%s\n' "$deep" | sed 's/^/        /'; fi

# ---------------------------------------------------------------- 3 references
head2 "3 every referenced file exists"

MISSING=""
# only look at backtick-free plain mentions like references/foo.md and templates/bar.md
while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  case "$rel" in *'*'*) continue ;; esac          # glob, not a literal path
  [ -e "$SKILL_DIR/$rel" ] || MISSING="$MISSING $rel"
done <<EOF
$(grep -oE '(references|templates|scripts)/[A-Za-z0-9._-]+\.[A-Za-z0-9]+' "$SKILL_MD" 2>/dev/null | sort -u)
EOF

if [ -z "${MISSING// /}" ]; then ok "all referenced paths exist under skills/engineering-method/"
else bad "SKILL.md points at paths that do not exist:"; printf '%s\n' $MISSING | sed 's/^/        /'; fi

# ---------------------------------------------------------------- 4 shell syntax
head2 "4 shell syntax + line endings"

check_sh() {
  local f="$1"
  [ -f "$f" ] || { bad "missing $f"; return; }
  # Only .sh files are parsed by bash. install.ps1 is PowerShell: running
  # `bash -n` on it reports a syntax error that is not one, which is exactly the
  # kind of false red this repo exists to avoid.
  case "$f" in
    *.sh) if bash -n "$f" 2>/dev/null; then ok "syntax: ${f#"$ROOT"/}"
          else bad "syntax error: ${f#"$ROOT"/}"; bash -n "$f" 2>&1 | sed 's/^/        /'; fi ;;
    *.ps1) ok "skipped bash parse (PowerShell): ${f#"$ROOT"/}" ;;
  esac
  # A BOM breaks every user who pipes the installer, on every platform.
  if head -c 3 "$f" | od -An -tx1 | grep -q 'ef bb bf'; then
    bad "UTF-8 BOM in ${f#"$ROOT"/} — remove it"
  fi
  # CRLF is fatal for bash and harmless for PowerShell, so the check is
  # per-language. Applying it to .ps1 was a false red: .gitattributes asks git
  # for CRLF on that file, and the verifier then complained about what git did.
  case "$f" in
    *.sh) if grep -qU $'\r' "$f" 2>/dev/null; then
            bad "CRLF in ${f#"$ROOT"/} — must be LF (bash: \$'\\r': command not found)"
          fi ;;
    *.ps1) ok "CRLF allowed (PowerShell): ${f#"$ROOT"/}" ;;
  esac
}

check_sh "$ROOT/install.sh"
check_sh "$ROOT/install.ps1"
check_sh "$ROOT/scripts/verify.sh"
check_sh "$SKILL_DIR/scripts/gate.sh"
check_sh "$SKILL_DIR/scripts/arch-check.sh"

# install.ps1 and verify.sh are not bash, so `bash -n` above is a weak check for
# them; they still must not carry CRLF or a BOM. That the bash check passes on
# non-bash text means nothing, which is why the CRLF/BOM checks are separate.

# ---------------------------------------------------------------- 5 executables
head2 "5 scripts are executable"

for f in "$SKILL_DIR/scripts/gate.sh" "$SKILL_DIR/scripts/arch-check.sh" "$ROOT/install.sh" "$ROOT/scripts/verify.sh"; do
  if [ -x "$f" ]; then ok "executable: ${f#"$ROOT"/}"
  else bad "not executable: ${f#"$ROOT"/} (chmod +x)"; fi
done

# ---------------------------------------------------------------- 6 artefacts
head2 "6 templates and gates"

for t in 立项书.md 规划.md 策划.md 设计.md 范畴表.md 集成面.md 验收.sh 反合理化表.md 文档宪法.md 切片表.md 任务书.md; do
  if [ -s "$SKILL_DIR/templates/$t" ]; then ok "template: $t"
  else bad "missing template: templates/$t"; fi
done

# The two new modes exist because 立项 and 切片 are the two places where a
# project silently stops being verifiable. A mode that is documented but absent
# is a promise the gate cannot keep.
for m in --charter --board; do
  if grep -q -- "$m" "$SKILL_DIR/scripts/gate.sh"; then ok "gate.sh supports $m"
  else bad "gate.sh lacks $m (documented in SKILL.md but not implemented)"; fi
done

# references added in 0.8.0: the cognition chain, the charter, the slice board
for r in r5-axiom-chain.md r6-project-charter.md r7-slice-board.md; do
  if [ -s "$SKILL_DIR/references/$r" ]; then ok "reference: $r"
  else bad "missing reference: references/$r"; fi
done

# gate.sh must still refuse; a gate that always passes is worse than no gate
if bash "$SKILL_DIR/scripts/gate.sh" >/dev/null 2>&1; then
  bad "gate.sh exits 0 with no arguments — it must exit 2 on a usage error"
elif [ $? -eq 2 ]; then ok "gate.sh refuses a usage error with exit 2"
else ok "gate.sh refuses a usage error (non-zero)"; fi

# ---------------------------------------------------------------- 7 version sync
head2 "7 version is consistent"

VFILE="$(tr -d '\r\n' <"$ROOT/VERSION" 2>/dev/null)"
SMVER="$(sed -n 's/^[[:space:]]*version:[[:space:]]*"\{0,1\}\([^"]*\)"\{0,1\}[[:space:]]*$/\1/p' "$SKILL_MD" | head -1)"
PJVER="$(grep -oE '"version"[[:space:]]*:[[:space:]]*"[^"]+"' "$ROOT/.claude-plugin/plugin.json" 2>/dev/null | head -1 | sed 's/.*"\([^"]*\)"$/\1/')"
MKVER="$(grep -oE '"version"[[:space:]]*:[[:space:]]*"[^"]+"' "$ROOT/.claude-plugin/marketplace.json" 2>/dev/null | head -1 | sed 's/.*"\([^"]*\)"$/\1/')"

say "VERSION=$VFILE  SKILL.md=$SMVER  plugin.json=$PJVER  marketplace.json=$MKVER"
if [ "$VFILE" = "$SMVER" ] && [ "$VFILE" = "$PJVER" ] && [ "$VFILE" = "$MKVER" ]; then
  ok "all four agree on $VFILE"
else
  bad "version mismatch — bump VERSION, SKILL.md metadata.version, plugin.json and marketplace.json together"
fi

# ---------------------------------------------------------------- 8 installers
head2 "8 installers are wired"

grep -q 'skills/\$SKILL' "$ROOT/install.sh" && ok "install.sh reads skills/\$SKILL" \
  || bad "install.sh does not read from skills/<name>"
grep -q 'skills\\\$Skill' "$ROOT/install.ps1" && ok "install.ps1 reads skills\<\$Skill>" \
  || bad "install.ps1 does not read from skills\<name>"
grep -q 'agents/skills' "$ROOT/install.sh" && ok "install.sh knows the generic fallback" \
  || bad "install.sh has no ~/.agents/skills fallback"
grep -q '\.agents\\skills' "$ROOT/install.ps1" && ok "install.ps1 knows the generic fallback" \
  || bad "install.ps1 has no ~/.agents\skills fallback"

# both installers must offer --dry-run, because the first thing a stranger does
# with an installer is want to see what it will touch
grep -q -- '--dry-run' "$ROOT/install.sh" && ok "install.sh supports --dry-run" || bad "install.sh lacks --dry-run"
grep -q -- '-DryRun' "$ROOT/install.ps1" && ok "install.ps1 supports -DryRun" || bad "install.ps1 lacks -DryRun"

# ---------------------------------------------------------------- 9 docs
head2 "9 docs exist"

for d in README.md README.zh-CN.md LICENSE CHANGELOG.md docs/install.md docs/agent-directories.md docs/why.md docs/flow-observed.md; do
  if [ -s "$ROOT/$d" ]; then ok "$d"
  else bad "missing $d"; fi
done

# ---------------------------------------------------------------- 10 0.8.0 additions
# The three references carry the three failures 0.8.0 exists to catch (cognition /
# charter / slice board). A pointer in SKILL.md to a file that is not there is the
# exact silent loss check 3 cannot see, because check 3 only greps SKILL.md text.
head2 "10 0.8.0 references"

for r in r5-axiom-chain.md r6-project-charter.md r7-slice-board.md r8-slice-rhythm.md; do
  if [ -s "$SKILL_DIR/references/$r" ]; then ok "references/$r"
  else bad "missing references/$r"; fi
done

# 0.8.2 templates: the six-section dev log is the artifact that turns a slice
# into something a future agent can read instead of re-deriving.
if [ -s "$SKILL_DIR/templates/开发日志.md" ]; then ok "template: 开发日志.md"
else bad "missing template: templates/开发日志.md"; fi

# r6 must keep the "one question, three fallbacks" rule; deleting it silently
# restores the old two-step (ask, then maybe look up the industry) which the
# user explicitly rejected.
if grep -q '一问三备' "$SKILL_DIR/references/r6-project-charter.md"; then
  ok "r6 keeps 一问三备 (guidance and fallback on one track)"
else
  bad "r6 lost 一问三备 — guidance and fallback drifted back into two steps"
fi

# gate.sh must actually implement the modes it advertises
grep -q -- '--charter' "$SKILL_DIR/scripts/gate.sh" && ok "gate.sh has --charter" \
  || bad "gate.sh advertises --charter but does not implement it"
grep -q -- '--board' "$SKILL_DIR/scripts/gate.sh" && ok "gate.sh has --board" \
  || bad "gate.sh advertises --board but does not implement it"

# ...and it must refuse, not pass, a project with no charter at all
EMPTY="$(mktemp -d 2>/dev/null || echo "$ROOT/.verify-empty")"
mkdir -p "$EMPTY"
if bash "$SKILL_DIR/scripts/gate.sh" "$EMPTY" --steps 0 --charter >/dev/null 2>&1; then
  bad "gate.sh --charter passed a project with no charter"
else
  ok "gate.sh --charter refuses a project with no charter"
fi
if bash "$SKILL_DIR/scripts/gate.sh" "$EMPTY" --steps 0 --board >/dev/null 2>&1; then
  bad "gate.sh --board passed a project with no slice board"
else
  ok "gate.sh --board refuses a project with no slice board"
fi
rmdir "$EMPTY" 2>/dev/null || rm -rf "$EMPTY"

# ---------------------------------------------------------------- 11 form-independence
# The failure this check exists for: 0.8.0 shipped a gate that demanded "九个域" and
# "串/并/汇". That gate only worked on the one project it was written from. A
# criterion that names one project's vocabulary is not a criterion.
#
# Two halves:
#   a) the gate must not contain that vocabulary
#   b) a project with a DIFFERENT number of domains must still pass
head2 "11 the gate is form-independent"

VOCAB="$(grep -nE '九域|域表|定稿|串\|并\|汇' "$SKILL_DIR/scripts/gate.sh" 2>/dev/null | grep -v '^\s*#' || true)"
if [ -z "$VOCAB" ]; then
  ok "gate.sh contains no project-specific vocabulary"
else
  bad "gate.sh embeds one project's vocabulary — that criterion only works for that project:"
  printf '%s\n' "$VOCAB" | head -5 | sed 's/^/        /'
fi

FIX="$(mktemp -d 2>/dev/null || echo "$ROOT/.verify-fixture")"
mkdir -p "$FIX/docs"
: >"$FIX/docs/01-接口.md"; : >"$FIX/docs/02-存储.md"; : >"$FIX/docs/03-判据.md"

cat >"$FIX/立项书.md" <<'FIXTURE'
# 立项

| 项 | 内容 |
|---|---|
| 功能 | 给内部工具加一个上传队列 |
| 困境消失 | 上传不再因为断网丢文件 |

| # | 域 | 管什么 | 不管什么 | 删掉它会怎么坏 | 入口文档 |
|---:|---|---|---|---|---|
| 1 | 接口 | 请求形状与错误码；反例：不是鉴权 | 不管鉴权 | 前端无处可调 | docs/01-接口.md |
| 2 | 存储 | 分片与断点；反例：不是备份 | 不管调度 | 断网即丢 | docs/02-存储.md |
| 3 | 判据 | 怎么算过；反例：不是监控 | 不管告警 | 绿了也不知道真通不通 | docs/03-判据.md |

## 不做

| # | 不做 | 为什么 |
|---:|---|---|
| 1 | 多端同步 | 本版只做单端 |

## 未知项

| # | 不知道什么 | 打算怎么验 | 什么时候必须解决 |
|---|---|---|---|
| 1 | 弱网重试上限 | 抓包跑 20 次弱网 | 切片 3 之前 |
FIXTURE

cat >"$FIX/切片表.md" <<'FIXTURE'
# 切片

| 片 | 功能 | 数据流出口 | 信息流出口 | 依赖 |
|---|---|---|---|---|
| F1 | 单文件上传 | chunks / files 两表 | 返回 fileId 与已完成分片 | — |
| F2 | 断点续传 | 只读 | 返回缺失分片列表 | F1 |

顺序：F1 → F2
反证：删掉 chunks 里一行 ⇒ 续传列表必须多出那个分片
FIXTURE

if bash "$SKILL_DIR/scripts/gate.sh" "$FIX" --steps 0 --charter --board >/dev/null 2>&1; then
  ok "a three-domain project passes (the gate is not welded to one project)"
else
  bad "a three-domain project FAILS — the gate still assumes one project's shape"
  bash "$SKILL_DIR/scripts/gate.sh" "$FIX" --steps 0 --charter --board 2>&1 | grep BLOCK | head -5 | sed 's/^/        /'
fi

# ...and the shipped template, copied but not filled in, must be refused
TMPL="$(mktemp -d 2>/dev/null || echo "$ROOT/.verify-tmpl")"
mkdir -p "$TMPL"
cp "$SKILL_DIR/templates/立项书.md" "$TMPL/立项书.md" 2>/dev/null || true
if bash "$SKILL_DIR/scripts/gate.sh" "$TMPL" --steps 0 --charter >/dev/null 2>&1; then
  bad "an unfilled charter template PASSES — the gate only checks that headings exist"
else
  ok "an unfilled charter template is refused"
fi

rm -rf "$FIX" "$TMPL"

# 0.8.3: the division of labour between the task issuer and a subagent is the
# one rule the user stated without hedging ("就是这样"). If it is ever softened
# — e.g. "pure moves may be self-verified" — that is a regression, not a tweak.
head2 "12 division of labour (issuer verifies, subagent executes)"

if grep -q '不负责验收' "$SKILL_DIR/references/r8-slice-rhythm.md"; then
  ok "r8 states: subagent does not verify"
else
  bad "r8 lost the rule that a subagent does not verify"
fi

if grep -q '纯搬运' "$SKILL_DIR/references/r8-slice-rhythm.md" \
   && grep -q '纯搬运' "$SKILL_DIR/references/r7-slice-board.md"; then
  ok "the no-exception clause (even pure moves) is present in r7 and r8"
else
  bad "the 'even pure moves are not self-verified' clause was dropped — that is the exception the user forbade"
fi

if grep -q 'role: execute-only' "$SKILL_DIR/templates/任务书.md"; then
  ok "task sheet carries role: execute-only"
else
  bad "task sheet dropped role: execute-only"
fi
say ""
if [ "$FAIL" -eq 0 ]; then
  say "PASS  repository is publishable"
  exit 0
else
  say "BLOCK  fix the items above"
  exit 1
fi
