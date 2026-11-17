#!/usr/bin/env bash
# engineering-method — one-shot installer for macOS / Linux / WSL / Git Bash
#
#   curl -fsSL https://raw.githubusercontent.com/butianque/engineering-method/main/install.sh | bash
#
# Options:
#   --agent <list>   claude,dsh,opencode,cursor,codex,gemini,agents   (default: auto-detect)
#   --all            install into every supported agent (even ones not detected)
#   --project        install into ./.claude/skills, ./.agents/skills, etc. instead of $HOME
#   --dir <path>     install into exactly this directory (it will contain SKILL.md)
#   --skills-dir <p> install into <p>/engineering-method (a skills parent dir)
#   --force          reinstall even when the installed copy already matches
#   --dry-run        print what would happen, change nothing
#   --no-generic     skip the generic ~/.agents/skills fallback
#   --uninstall      remove the skill from the same targets
#   -h | --help      this text
#
# Exit codes: 0 ok, 1 failure, 2 usage error.
#
# Design note: this script must behave identically whether it runs from a clone
# (`bash install.sh`) or from a pipe (`curl … | bash`). A piped run has no
# $0 path and no sibling files, so the skill is fetched as a tarball instead of
# copied. Both paths end in the same "copy one directory into place" step.

set -uo pipefail

REPO="butianque/engineering-method"
SKILL="engineering-method"
BRANCH="${EM_BRANCH:-main}"

AGENTS=""
ALL=0
PROJECT=0
EXPLICIT_DIR=""
SKILLS_PARENT=""
FORCE=0
DRY=0
GENERIC=1
UNINSTALL=0

say()   { printf '%s\n' "$*"; }
ok()    { printf '  ok    %s\n' "$*"; }
warn()  { printf '  warn  %s\n' "$*"; }
fail()  { printf '  FAIL  %s\n' "$*" >&2; }
die()       { fail "$*"; exit 1; }
die_usage() { fail "$*"; exit 2; }

usage() {
  sed -n '2,24p' "$0" 2>/dev/null | sed 's/^# \{0,1\}//' || cat <<'USAGE'
engineering-method installer
  --agent <list>  claude,dsh,opencode,cursor,codex,gemini,agents
  --all  --project  --dir <path>  --force  --dry-run  --no-generic  --uninstall
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --agent)      AGENTS="${2:-}"; shift 2 ;;
    --all)        ALL=1; shift ;;
    --project)    PROJECT=1; shift ;;
    --dir)        EXPLICIT_DIR="${2:-}"; shift 2 ;;
    --skills-dir) SKILLS_PARENT="${2:-}"; shift 2 ;;
    --force)      FORCE=1; shift ;;
    --dry-run)    DRY=1; shift ;;
    --no-generic) GENERIC=0; shift ;;
    --uninstall)  UNINSTALL=1; shift ;;
    -h|--help)    usage; exit 0 ;;
    *)            fail "unknown option: $1"; usage; exit 2 ;;
  esac
done

# ---------------------------------------------------------------- target table
# $HOME-level defaults. A target is "detected" when its PARENT directory exists,
# i.e. the agent itself is installed — not merely that its skills dir exists.
agent_base() {
  if [ "$PROJECT" = "1" ]; then printf '.'; else printf '%s' "$HOME"; fi
}

target_dir() {
  local agent="$1" base; base="$(agent_base)"
  case "$agent" in
    claude)   printf '%s/.claude/skills' "$base" ;;
    dsh)      printf '%s/.dsh/skills' "$base" ;;
    opencode) printf '%s/.config/opencode/skills' "$base" ;;
    cursor)   printf '%s/.cursor/skills' "$base" ;;
    codex)    printf '%s/.codex/skills' "$base" ;;
    gemini)   printf '%s/.gemini/skills' "$base" ;;
    agents)   printf '%s/.agents/skills' "$base" ;;
    *)        return 1 ;;
  esac
}

agent_parent() {
  local agent="$1" base; base="$(agent_base)"
  case "$agent" in
    claude)   printf '%s/.claude' "$base" ;;
    dsh)      printf '%s/.dsh' "$base" ;;
    opencode) printf '%s/.config/opencode' "$base" ;;
    cursor)   printf '%s/.cursor' "$base" ;;
    codex)    printf '%s/.codex' "$base" ;;
    gemini)   printf '%s/.gemini' "$base" ;;
    agents)   printf '%s/.agents' "$base" ;;
    *)        return 1 ;;
  esac
}

ALL_AGENTS="claude dsh opencode cursor codex gemini agents"

# ---------------------------------------------------------------- resolve list
SELECTED=""
if [ -n "$EXPLICIT_DIR" ]; then
  SELECTED="__explicit_dir__"
elif [ -n "$SKILLS_PARENT" ]; then
  SELECTED="__explicit_parent__"
elif [ -n "$AGENTS" ]; then
  IFS=',' read -r -a _req <<<"$AGENTS"
  for a in "${_req[@]}"; do
    a="$(printf '%s' "$a" | tr -d ' ')"
    valid=0
    for k in $ALL_AGENTS; do [ "$a" = "$k" ] && valid=1; done
    [ "$a" = "all" ] && { ALL=1; continue; }
    [ "$valid" = "1" ] || die_usage "unknown agent '$a' (valid: $ALL_AGENTS)"
    SELECTED="$SELECTED $a"
  done
elif [ "$ALL" = "1" ]; then
  SELECTED="$ALL_AGENTS"
else
  for a in $ALL_AGENTS; do
    if [ -d "$(agent_parent "$a")" ]; then SELECTED="$SELECTED $a"; fi
  done
fi

# The generic fallback is on by default: it is the only one that works for an
# agent this script has never heard of, and it costs one directory.
if [ "$GENERIC" = "1" ] && [ -z "$EXPLICIT_DIR" ] && [ -z "$SKILLS_PARENT" ] && [ "$UNINSTALL" = "0" ]; then
  case " $SELECTED " in *" agents "*) ;; *) SELECTED="$SELECTED agents" ;; esac
fi

SELECTED="$(printf '%s' "$SELECTED" | xargs 2>/dev/null || printf '%s' "$SELECTED")"
[ -n "$SELECTED" ] || die_usage "no agent detected. Use --all, --agent <list>, or --dir <path>."

# ---------------------------------------------------------------- fetch source
SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)"
fi

SRC=""
WORK=""
cleanup() { [ -n "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT

if [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR/skills/$SKILL" ]; then
  SRC="$SCRIPT_DIR/skills/$SKILL"
  say "source: local checkout ($SRC)"
else
  command -v curl >/dev/null 2>&1 || die "curl is required for a piped install"
  command -v tar  >/dev/null 2>&1 || die "tar is required for a piped install"
  WORK="$(mktemp -d)"
  URL="https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz"
  say "source: $URL"
  curl -fsSL "$URL" -o "$WORK/src.tar.gz" || die "download failed: $URL"
  tar -xzf "$WORK/src.tar.gz" -C "$WORK" || die "extract failed"
  SRC="$(find "$WORK" -maxdepth 3 -type d -path "*/skills/$SKILL" | head -1)"
  [ -n "$SRC" ] && [ -d "$SRC" ] || die "the archive does not contain skills/$SKILL"
fi

# ---------------------------------------------------------------- fingerprint
tree_hash() {
  local dir="$1"
  ( cd "$dir" && find . -type f | LC_ALL=C sort | while IFS= read -r f; do
      printf '%s ' "${f#./}"
      if command -v sha256sum >/dev/null 2>&1; then sha256sum "$f" | cut -d' ' -f1
      else shasum -a 256 "$f" | cut -d' ' -f1; fi
    done ) | { if command -v sha256sum >/dev/null 2>&1; then sha256sum | cut -d' ' -f1
              else shasum -a 256 | cut -d' ' -f1; fi; }
}

SRC_HASH="$(tree_hash "$SRC")"
VERSION="$(sed -n 's/^  version: *"\{0,1\}\([^"]*\)"\{0,1\}$/\1/p' "$SRC/SKILL.md" | head -1)"
say "skill version: ${VERSION:-unknown}  hash: ${SRC_HASH:0:12}"
say ""

# ---------------------------------------------------------------- install
INSTALLED=0
SKIPPED=0
FAILED=0

do_dir() {
  local dest_parent="$1" dest="$2"
  if [ "$UNINSTALL" = "1" ]; then
    if [ -d "$dest" ]; then
      if [ "$DRY" = "1" ]; then ok "would remove $dest"; else rm -rf "$dest" && ok "removed $dest"; fi
    else
      warn "not installed at $dest"
    fi
    return
  fi

  if [ -d "$dest" ] && [ "$FORCE" = "0" ]; then
    local have; have="$(tree_hash "$dest")"
    if [ "$have" = "$SRC_HASH" ]; then ok "up to date: $dest"; SKIPPED=$((SKIPPED+1)); return; fi
  fi

  if [ "$DRY" = "1" ]; then ok "would install: $dest"; return; fi

  mkdir -p "$(dirname "$dest")" || { fail "cannot create $(dirname "$dest")"; FAILED=$((FAILED+1)); return; }
  rm -rf "$dest" || { fail "cannot clear $dest"; FAILED=$((FAILED+1)); return; }
  cp -R "$SRC" "$dest" || { fail "cannot copy to $dest"; FAILED=$((FAILED+1)); return; }
  chmod +x "$dest/scripts/"*.sh 2>/dev/null
  ok "installed: $dest"
  INSTALLED=$((INSTALLED+1))
}

for a in $SELECTED; do
  if [ "$a" = "__explicit_dir__" ]; then
    say "[explicit dir]"
    do_dir "$(dirname "$EXPLICIT_DIR")" "$EXPLICIT_DIR"
    continue
  fi
  if [ "$a" = "__explicit_parent__" ]; then
    say "[explicit skills dir]"
    do_dir "$SKILLS_PARENT" "$SKILLS_PARENT/$SKILL"
    continue
  fi
  say "[$a]"
  do_dir "$(target_dir "$a")" "$(target_dir "$a")/$SKILL"
done

say ""
if [ "$UNINSTALL" = "1" ]; then
  say "uninstall done."
  exit 0
fi
[ "$FAILED" -eq 0 ] || { say "finished with $FAILED failure(s)"; exit 1; }

cat <<EOF
installed ${INSTALLED}, already current ${SKIPPED}.

next:
  1. Restart the agent (or reload its skill list) so it picks up the new skill.
  2. Ask something like "帮我加个接口" — the skill should load and ask for 三定 first.
  3. Verify the machine gate by hand:
       bash <skills-dir>/$SKILL/scripts/gate.sh <your-project> --steps 3

docs: https://github.com/$REPO#readme
EOF
