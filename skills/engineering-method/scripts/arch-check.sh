#!/usr/bin/env bash
# arch-check.sh — 分类与落位的机器判据
#
# 用法：
#   bash arch-check.sh <项目目录>
#   bash arch-check.sh <项目目录> --changed     # 只查 git 新增/修改的文件
#
# 检查三件事（对应 references/placement.md 的 S1–S4）：
#   A1  设计.md 里有落位表，且"放哪"列全非空
#   A2  临时类都有 TTL（生命周期列非空）
#   A3  代码文件能映射到落位表某一行（不能裸放）
#
# 退出码：0 = PASS，1 = BLOCK，2 = 用法错误
#
# 设计原则：只读、只判、只拒绝。绝不修改任何文件。
# 依据：AI 只有"就近原则"，没有空间记忆 ⇒ 必须用表代替记忆，用命令代替自觉。

set -uo pipefail

DIR="${1:-}"
MODE="${2:-}"

if [ -z "$DIR" ] || [ ! -d "$DIR" ]; then
  echo "用法: bash arch-check.sh <项目目录> [--changed]" >&2
  exit 2
fi

FAIL=0
say()   { printf '%s\n' "$*"; }
block() { printf 'BLOCK  %s\n' "$*"; FAIL=1; }
pass()  { printf 'ok     %s\n' "$*"; }

# ---------- 找设计文档 ----------
DESIGN=""
for c in "$DIR/设计.md" "$DIR/docs/设计.md" "$DIR/DESIGN.md"; do
  [ -s "$c" ] && DESIGN="$c" && break
done

if [ -z "$DESIGN" ]; then
  block "找不到 设计.md —— 没有设计就没有落位表，不许继续"
  say ""
  say "BLOCK 不许继续"
  exit 1
fi

# ---------- A1 落位表存在 ----------
# 落位表 = 含"落位表"标题，或表头含"放在哪"/"放哪"
# 判据：必须有一个真正的表格表头含「放在哪」或「放哪」列
# （只出现"落位表"三个字不算 —— 像"没有落位表"这种否定句会误判）
if grep -qE '^\|[^|]*放在哪[^|]*\||^\|[^|]*放哪[^|]*\||\|\s*放(在)?哪.*\|' "$DESIGN"; then
  pass "A1 落位表存在（有含「放哪」列的表头）"
else
  block "A1 设计.md 里没有落位表，或缺「放在哪」列"
  say "        → 加一节「2.5 落位表」，模板见 templates/设计.md"
  say "        → 表头必须是：| 这类东西 | 放在哪（目录/包） | 命名规范 | 生命周期 |"
fi

# ---------- A2 每行「放哪」非空 + 临时类有 TTL ----------
if grep -qE '放在哪|放哪' "$DESIGN"; then
  # 提取落位表区块（从"落位表"或"放在哪"起，到下一个 ## 或空行块结束）
  BLOCK_TXT=$(awk '
    /落位表|放在哪|放哪/ { inf=1 }
    inf && /^## / && !/落位表|放在哪|放哪/ { inf=0 }
    inf { print }
  ' "$DESIGN")

  # 表格数据行：以 | 开头，第 2 列（这类东西）非空且不是表头/分隔
  EMPTY_POS=$(printf '%s\n' "$BLOCK_TXT" | awk -F'|' '
    /^\|/ && NF>=5 {
      c1=$2; c2=$3; c4=$5;
      gsub(/^[ \t]+|[ \t]+$/,"",c1);
      gsub(/^[ \t]+|[ \t]+$/,"",c2);
      gsub(/^[ \t]+|[ \t]+$/,"",c4);
      if (c1 ~ /^$/) next;
      if (c1 ~ /^[-: ]+$/) next;
      if (c1 == "这类东西") next;
      if (c2 == "") print "缺位置: " c1;
      if (c4 == "" || c4 == "生命周期" ) print "缺TTL: " c1;
    }')

  if [ -n "$EMPTY_POS" ]; then
    block "A2 落位表有行不完整："
    printf '%s\n' "$EMPTY_POS" | sed 's/^/        /'
  else
    pass "A2 落位表每行有位置；临时类有生命周期"
  fi
fi

# ---------- A3 新文件能映射到落位表 ----------
# 只检查代码文件；从落位表里抽出所有路径前缀
PREFIXES=$(printf '%s\n' "${BLOCK_TXT:-}" | awk -F'|' '
  /^\|/ && NF>=5 {
    c2=$3;
    gsub(/^[ \t]+|[ \t]+$/,"",c2);
    gsub(/`/,"",c2);
    if (c2 ~ /^$/) next;
    if (c2 ~ /^[-: ]+$/) next;
    if (c2 == "放在哪（目录/包）" || c2 ~ /放在哪/) next;
    # 去掉说明性括注
    sub(/（.*$/,"",c2);
    sub(/\(.*$/,"",c2);
    gsub(/[ \t]+$/,"",c2);
    print c2;
  }')

if [ -z "$PREFIXES" ]; then
  block "A3 落位表里抽不出任何路径前缀 —— 表头格式不对，或「放哪」列不是路径"
else
  # 收集要检查的文件
  FILES=""
  if [ "$MODE" = "--changed" ] && [ -d "$DIR/.git" ]; then
    FILES=$(cd "$DIR" && git status --porcelain 2>/dev/null | awk '$1 ~ /^\?\?|^A|^M/ {print $2}' | grep -E '\.(go|ts|tsx|js|py|rs|java|kt)$' || true)
  else
    FILES=$(cd "$DIR" && find . -type f \( -name '*.go' -o -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.py' -o -name '*.rs' \) \
      -not -path './node_modules/*' -not -path './.git/*' -not -path './dist/*' 2>/dev/null | sed 's|^\./||')
  fi

  ORPHAN=""
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    matched=0
    while IFS= read -r p; do
      [ -z "$p" ] && continue
      case "$f" in
        "$p"*|*"$p"*) matched=1; break ;;
      esac
    done <<EOF
$PREFIXES
EOF
    [ "$matched" -eq 0 ] && ORPHAN="$ORPHAN$f"$'\n'
  done <<EOF
$FILES
EOF

  if [ -n "${ORPHAN//[$'\n']/}" ]; then
    CNT=$(printf '%s' "$ORPHAN" | grep -c . || true)
    block "A3 有 $CNT 个文件映射不到落位表任何一行（裸放）"
    printf '%s' "$ORPHAN" | head -20 | sed 's/^/        /'
    say "        → 要么挪到已声明位置，要么补一行落位表（R4：查不到就补表）"
  else
    pass "A3 所有文件都能映射到落位表"
  fi
fi

# ---------- 结论 ----------
say ""
if [ "$FAIL" -eq 0 ]; then
  say "PASS  分类与落位无缺口"
  say ""
  say "⚠️ 以下三条本脚本做不到，必须等 pangu 工作台："
  say "   · 自动发现「这里需要一个新类」（语义判断）"
  say "   · 跨会话记住「上次那个在哪」（skill 无状态）"
  say "   · 主动清理过期临时物（需要后台进程）"
  exit 0
else
  say "BLOCK 不许继续 —— 上列每一项都要清掉"
  exit 1
fi
