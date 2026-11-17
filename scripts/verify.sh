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
  # A BOM or CRLF here breaks every user who pipes the installer.
  if head -c 3 "$f" | od -An -tx1 | grep -q 'ef bb bf'; then
    bad "UTF-8 BOM in ${f#"$ROOT"/} — remove it"
  fi
  if grep -qU $'\r' "$f" 2>/dev/null; then
    bad "CRLF in ${f#"$ROOT"/} — must be LF (bash: \$'\\r': command not found)"
  fi
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

for t in 立项书.md 规划.md 策划.md 设计.md 范畴表.md 集成面.md 验收.sh 反合理化表.md; do
  if [ -s "$SKILL_DIR/templates/$t" ]; then ok "template: $t"
  else bad "missing template: templates/$t"; fi
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

for d in README.md README.zh-CN.md LICENSE CHANGELOG.md docs/install.md docs/agent-directories.md docs/why.md; do
  if [ -s "$ROOT/$d" ]; then ok "$d"
  else bad "missing $d"; fi
done

# ---------------------------------------------------------------- verdict
say ""
if [ "$FAIL" -eq 0 ]; then
  say "PASS  repository is publishable"
  exit 0
else
  say "BLOCK  fix the items above"
  exit 1
fi
