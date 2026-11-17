#!/usr/bin/env bash
# gate.sh — 工程方法论的唯一机器判据
#
# 用法：
#   bash gate.sh <项目目录>                       # 查全部八件套
#   bash gate.sh <项目目录> --steps 5             # 只查范畴表（范畴入口）
#   bash gate.sh <项目目录> --steps 0,1           # 只查立项书 + 规划
#   bash gate.sh <项目目录> --done                # 额外跑验收.sh
#   bash gate.sh <项目目录> --arch                # 额外跑 arch-check.sh（分类与落位）
#   bash gate.sh <项目目录> --spiral              # 额外查螺旋：每轮必须有新增事实
#
# 退出码：0 = PASS，1 = BLOCK，2 = 用法错误
#
# 设计原则：只读、只判、只拒绝，绝不修改任何文件。
# 依据：AI 的注意力是概率性的，所以判据必须是代码，不是提示词。

set -uo pipefail

DIR=""
MODE=""
ARCH=""
SPIRAL=""
STEPS="0,1,2,3,4,5,6,7"

while [ $# -gt 0 ]; do
  case "$1" in
    --done)   MODE="--done"; shift ;;
    --arch)   ARCH="1"; shift ;;
    --spiral) SPIRAL="1"; shift ;;
    --steps)  STEPS="${2:-}"; shift 2 ;;
    *)        DIR="${1:-}"; shift ;;
  esac
done

if [ -z "$DIR" ] || [ ! -d "$DIR" ]; then
  echo "用法: bash gate.sh <项目目录> [--steps 0,1,2,3,4,5,6,7] [--done] [--arch] [--spiral]" >&2
  exit 2
fi

FAIL=0
say()   { printf '%s\n' "$*"; }
block() { printf 'BLOCK  %s\n' "$*"; FAIL=1; }
pass()  { printf 'ok     %s\n' "$*"; }

has() { case ",$STEPS," in *",$1,"*) return 0 ;; *) return 1 ;; esac; }

# ---------- G1 各步产物 ----------
declare -A F=(
  [0]="立项书.md"
  [1]="规划.md"
  [2]="策划.md"
  [3]="设计.md"
  [4]="范畴表.md"
  [5]="集成面.md"
  [6]="验收.sh"
  [7]="反合理化表.md"
)
for s in 0 1 2 3 4 5 6 7; do
  if has "$s"; then
    f="${F[$s]}"
    if [ -s "$DIR/$f" ]; then pass "G1 步$s $f"; else block "G1 缺步$s产物或为空: $f"; fi
  fi
done

# ---------- G4 设计必须签收（步 3 的核心 gate）----------
if has 3; then
  if [ -s "$DIR/.runs/signoff-system-design.md" ]; then
    pass "G4 系统设计已签收"
  else
    block "G4 系统设计未签收（缺 .runs/signoff-system-design.md）—— 不许开程序设计段"
  fi
fi

# ---------- G7 立项后三定（位置结构 / 依赖序 / 风格）----------
# 依据：AI 只写全序不校验偏序、只看见文件不看见坐标（见 references/spacetime.md）
# 缺一不许写业务代码。
if has 3; then
  D="$DIR/设计.md"
  if [ -s "$D" ]; then
    # ① 依赖序图：必须有含「消费方」的表头
    # 注意：这些表头在第 3/4 列，[^|]* 跨不过前面的 |，所以用 .* 而不是 [^|]*
    if grep -qE '^\|.*消费方' "$D"; then
      pass "G7① 依赖序图存在"
      # 每条跨界边必须有「哪条全序覆盖它」一列且非空
      # 6 列：# | 产生方 | 消费方 | 交什么 | 跨的是哪个界 | 哪条全序覆盖它
      # 按 | 切分后：$2=#, $3=产生方, $4=消费方, $5=交什么, $6=跨界, $7=覆盖
      NOCover=$(awk -F'|' '
        /^\|/ && NF>=7 {
          c1=$2; c7=$7;
          gsub(/^[ \t]+|[ \t]+$/, "", c1);
          gsub(/^[ \t]+|[ \t]+$/, "", c7);
          if (c1 ~ /^#?$/ || c1 ~ /^[-: ]+$/ || c1 == "#" || c1 ~ /产生方/) next;
          if (c7 == "") print NR": "c1;
        }' "$D")
      if [ -n "$NOCover" ]; then
        block "G7① 有跨界边没写「哪条全序覆盖它」:"
        printf '%s\n' "$NOCover" | sed 's/^/        /'
      else
        pass "G7① 每条跨界边都有覆盖它的全序"
      fi
    else
      block "G7① 设计.md 缺「依赖序图」（表头须含「消费方」）—— 时间盲"
    fi

    # ② 模块依赖方向：必须有含「绝不能依赖谁」的表头
    if grep -qE '^\|.*绝不能依赖谁' "$D"; then
      pass "G7② 模块依赖方向存在"
    else
      block "G7② 设计.md 缺「模块依赖方向」（表头须含「绝不能依赖谁」）—— 空间盲"
    fi

    # ③ 风格契约：必须有含「维度」的表头，且不许出现不可测词
    if grep -qE '^\|.*维度' "$D"; then
      VAGUE=$(grep -nE '恰当|良好|合理|清晰|简洁|规范一些' "$D" | grep -vE '不许出现|不可测词|F2' || true)
      if [ -n "$VAGUE" ]; then
        block "G7③ 风格契约里出现不可测词（F2 禁止）:"
        printf '%s\n' "$VAGUE" | sed 's/^/        /'
      else
        pass "G7③ 风格契约存在且无不可测词"
      fi
    else
      block "G7③ 设计.md 缺「风格契约」（表头须含「维度」）—— 必须带数字"
    fi
  fi
fi

# ---------- G6 分类与落位（--arch）----------
# 依据：AI 没有空间记忆，只有就近原则 ⇒ 必须用表代替记忆（见 references/placement.md）
if [ "$ARCH" = "1" ]; then
  AC="$(dirname "$0")/arch-check.sh"
  if [ -s "$AC" ]; then
    say "---- 跑 arch-check（分类与落位）----"
    mkdir -p "$DIR/.runs"
    if bash "$AC" "$DIR" >"$DIR/.runs/arch-check.log" 2>&1; then
      pass "G6 分类与落位无缺口"
    else
      block "G6 分类与落位有缺口（见下）"
      tail -25 "$DIR/.runs/arch-check.log" | sed 's/^/        /'
    fi
  else
    block "G6 --arch 指定了，但找不到 arch-check.sh"
  fi
fi

# ---------- G2 集成面（步 5）----------
IS="$DIR/集成面.md"
if has 5 && [ -s "$IS" ]; then
  MISSING=""
  for key in 入口 业务函数 接线 数据 失败路径 配置 可观测; do
    grep -q "$key" "$IS" || MISSING="$MISSING $key"
  done
  if [ -n "$MISSING" ]; then
    block "G2 集成面缺骨架行:$MISSING"
  else
    pass "G2 7 行骨架齐"
  fi

  N=$(grep -c '不存在' "$IS" || true)
  if [ "${N:-0}" -gt 0 ]; then
    block "G2 集成面里还有 $N 处「不存在」—— 这些就是待做的"
    grep -n '不存在' "$IS" | sed 's/^/        /'
  else
    pass "G2 无「不存在」"
  fi

  EMPTY=$(awk -F'|' '
    /^\|/ && NF>=5 {
      c1=$2; c3=$4;
      gsub(/^[ \t]+|[ \t]+$/, "", c1);
      gsub(/^[ \t]+|[ \t]+$/, "", c3);
      if (c1 ~ /^#?$/) next;
      if (c1 ~ /^[-: ]+$/) next;
      if (c1 == "#" || c1 == "ID") next;
      if (c3 == "") print NR": "c1;
    }' "$IS")
  if [ -n "$EMPTY" ]; then
    block "G2 有行缺探针（第 3 列空）:"
    printf '%s\n' "$EMPTY" | sed 's/^/        /'
  else
    pass "G2 探针非空"
  fi
fi

# ---------- G3 验收（步 7，仅 --done）----------
if [ "$MODE" = "--done" ] && has 6; then
  ACC="$DIR/验收.sh"
  if [ ! -s "$ACC" ]; then
    block "G3 缺 验收.sh"
  else
    say "---- 跑验收 ----"
    mkdir -p "$DIR/.runs"
    if bash "$ACC" >"$DIR/.runs/acceptance.log" 2>&1; then
      pass "G3 验收退出码 0"
    else
      block "G3 验收失败（末 20 行见下）"
      tail -20 "$DIR/.runs/acceptance.log" | sed 's/^/        /'
    fi
  fi
fi

# ---------- G8 螺旋（--spiral）----------
# 依据：「每轮必须产出一条新事实」是螺旋的牙齿。没有它，螺旋退化成原地迭代。
# .runs/spiral.md 里每轮一行，格式：- [轮次] 新事实
if [ "$SPIRAL" = "1" ]; then
  mkdir -p "$DIR/.runs"
  SP="$DIR/.runs/spiral.md"
  if [ ! -s "$SP" ]; then
    block "G8 缺 .runs/spiral.md —— 没有螺旋记录，等于没有一轮产出新事实"
    say "        → 每轮写一行：- [轮次] 这一轮拿到的、原来不知道的事实"
  else
    # 有效行 = 以 - 开头，且「新事实」部分不是空/占位
    VALID=$(grep -cE '^-\s*\[[^]]+\]\s*\S' "$SP" || true)
    EMPTY=$(grep -nE '^-\s*\[[^]]+\]\s*$' "$SP" || true)
    if [ "${VALID:-0}" -eq 0 ]; then
      block "G8 spiral.md 里没有一条有效的新事实条目（格式：- [轮次] 事实）"
    elif [ -n "$EMPTY" ]; then
      block "G8 spiral.md 里有空事实条目（写了轮次却没写事实）:"
      printf '%s\n' "$EMPTY" | head -10 | sed 's/^/        /'
    else
      pass "G8 螺旋有 $VALID 轮，每轮都记了新事实"
    fi
  fi
fi

# ---------- 结论 ----------
say ""
if [ "$FAIL" -eq 0 ]; then
  say "PASS  可以继续"
  exit 0
else
  say "BLOCK 不许继续 —— 上列每一项都要清掉"
  exit 1
fi
