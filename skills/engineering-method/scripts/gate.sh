#!/usr/bin/env bash
# gate.sh — 工程方法论的唯一机器判据
#
# 用法：
#   bash gate.sh <项目目录>                       # 查全部八件套
#   bash gate.sh <项目目录> --steps 4             # 只查范畴表（范畴入口）
#   bash gate.sh <项目目录> --steps 0,1           # 只查立项书 + 规划
#   bash gate.sh <项目目录> --done                # 额外跑验收.sh
#   bash gate.sh <项目目录> --arch                # 额外跑 arch-check.sh（分类与落位）
#   bash gate.sh <项目目录> --spiral              # 额外查螺旋：每轮必须有新增事实
#   bash gate.sh <项目目录> --charter             # 额外查立项：七段 / 九域 / 宪法 / 裁决点 / 状态表
#   bash gate.sh <项目目录> --board               # 额外查切片表：四列 / 反证 / 顺序行 / 无待定
#
#   --charter / --board 认文件名关键词，不要求固定文件名：
#     立项书 → 立项书.md，或名字含「立项书」的 .md（如 00-立项书-0.0.3.md）
#     宪法   → 文档宪法.md，或名字含「宪法」/「纪律」的 .md
#     切片   → 切片表.md，或名字含「切片」的 .md（如 15-实施切片.md）
#   理由：真实项目几乎都带编号前缀，要求改名等于要求重写索引。
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
CHARTER=""
BOARD=""
STEPS="0,1,2,3,4,5,6,7"

while [ $# -gt 0 ]; do
  case "$1" in
    --done)    MODE="--done"; shift ;;
    --arch)    ARCH="1"; shift ;;
    --spiral)  SPIRAL="1"; shift ;;
    --charter) CHARTER="1"; shift ;;
    --board)   BOARD="1"; shift ;;
    --steps)   STEPS="${2:-}"; shift 2 ;;
    *)         DIR="${1:-}"; shift ;;
  esac
done

if [ -z "$DIR" ] || [ ! -d "$DIR" ]; then
  echo "用法: bash gate.sh <项目目录> [--steps 0,1,2,3,4,5,6,7] [--done] [--arch] [--spiral] [--charter] [--board]" >&2
  exit 2
fi

FAIL=0
say()   { printf '%s\n' "$*"; }
block() { printf 'BLOCK  %s\n' "$*"; FAIL=1; }
pass()  { printf 'ok     %s\n' "$*"; }

has() { case ",$STEPS," in *",$1,"*) return 0 ;; *) return 1 ;; esac; }

# 文件解析：先认固定名，再认「名字里含关键词」的第一个 .md
# 理由：真实项目都带编号前缀（00-立项书-0.0.3.md / 15-实施切片.md），要求改名等于要求重写索引。
resolve() {
  local dir="$1" exact="$2" key="$3" f
  if [ -s "$dir/$exact" ]; then printf '%s' "$dir/$exact"; return 0; fi
  [ -n "$key" ] || { printf ''; return 1; }
  # 由浅到深：顶层优先，再一层，再两层（真实项目的文档按域分目录）
  for f in "$dir"/*.md "$dir"/*/*.md "$dir"/*/*/*.md; do
    [ -s "$f" ] || continue
    case "$(basename "$f")" in *"$key"*) printf '%s' "$f"; return 0 ;; esac
  done
  printf ''
  return 1
}

# ---------- G1 各步产物 ----------
declare -A F=(
  [0]="立项书.md" [1]="规划.md" [2]="策划.md" [3]="设计.md"
  [4]="范畴表.md" [5]="集成面.md" [6]="验收.sh" [7]="反合理化表.md"
)
# 关键词：空 = 只认固定名（.sh 与表类文件名自带语义，不该被前缀猜中）
declare -A K=(
  [0]="立项书" [1]="规划" [2]="策划" [3]="设计"
  [4]="范畴"   [5]="集成面" [6]="" [7]="反合理化"
)
for s in 0 1 2 3 4 5 6 7; do
  if has "$s"; then
    f="${F[$s]}"
    hit="$(resolve "$DIR" "$f" "${K[$s]}")"
    if [ -n "$hit" ]; then
      if [ "$(basename "$hit")" = "$f" ]; then pass "G1 步$s $f"
      else pass "G1 步$s $f（认作 $(basename "$hit")）"; fi
    else
      block "G1 缺步$s产物或为空: $f"
    fi
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

# ---------- G9 立项是基准（--charter）----------
# 依据：立项书不是介绍，是基准。下游每篇都要能被它逐行判「是/否」。
# 缺七段 = 目标不可判、边界无限；缺九域 = 那类问题没有词汇，永远看不见。
if [ "$CHARTER" = "1" ]; then
  CH="$(resolve "$DIR" 立项书.md 立项书)"
  if [ -z "$CH" ] || [ ! -s "$CH" ]; then
    block "G9 缺 立项书（立项书.md，或名字含「立项书」的 .md）"
  else
    pass "G9 找到立项书: $(basename "$CH")"
    # 七段关键词：缺哪段报哪段（同义词算过 —— 概念是「域表」，标题叫「九个域」也行）
    grep -qE '域表|九域|九个域|总揽' "$CH" && pass "G9 段域表" || block "G9 立项书缺「域表」段"
    for kw in 依赖顺序 落位表 不做 裁决; do
      grep -q "$kw" "$CH" && pass "G9 段$kw" || block "G9 立项书缺「$kw」段"
    done

    # 九域：每域至少被点名一次（少一域 ⇒ 那类问题没词汇）
    MISS=""
    for d in 范畴 架构 形式化 工程 框架 细则 数据流 消费者 判据; do
      grep -q "$d" "$CH" || MISS="$MISS $d"
    done
    if [ -n "$MISS" ]; then
      block "G9 九域不全，缺:$MISS"
    else
      pass "G9 九域齐"
    fi

    # 依赖顺序必须写串/并/汇，否则只是罗列
    if grep -qE '串|并|汇' "$CH"; then pass "G9 依赖顺序写了串/并/汇"
    else block "G9 依赖顺序没写串/并/汇 —— 只是罗列，不是顺序"; fi

    # 状态表：草案/定稿/作废 三值
    if grep -q '定稿' "$CH" && grep -qE '草案|作废' "$CH"; then pass "G9 状态表三值齐"
    else block "G9 缺状态表三值（草案/定稿/作废）—— 已完成会被重读"; fi

    # 文档宪法：独立文件（名字含「宪法」或「纪律」），或立项书内写明 D1 与 D6
    CT="$(resolve "$DIR" 文档宪法.md 宪法)"
    [ -n "$CT" ] || CT="$(resolve "$DIR" 文档宪法.md 纪律)"
    if [ -n "$CT" ]; then pass "G9 文档宪法存在: $(basename "$CT")"
    elif grep -q 'D1' "$CH" && grep -q 'D6' "$CH"; then pass "G9 立项书内含宪法 D1/D6"
    else block "G9 缺文档宪法（文档宪法.md / 名字含「宪法」或「纪律」的 .md，或立项书里的 D1–D6）—— 两份文档会各说一套"; fi

    # 裁决点：未定项必须写「它决定哪些下游文档」
    if grep -q '决定' "$CH"; then pass "G9 裁决点写明了下游影响"
    else block "G9 裁决点没写「它决定哪些下游文档」—— 未定项会被忘掉"; fi

    # G10 补丁段：只抓确凿的补丁句式（裸「修订」误伤太大）
    PATCH=$(grep -nE '原写.{0,30}现改为|补记|修订记录|变更日志' "$CH" 2>/dev/null || true)
    if [ -n "$PATCH" ]; then
      block "G10 立项书里有补丁段（D1 禁止：只写当前真相）:"
      printf '%s\n' "$PATCH" | head -5 | sed 's/^/        /'
    else
      pass "G10 无补丁段"
    fi
  fi
fi

# ---------- G11 切片可派（--board）----------
# 依据：一片 = 一条能从输入走到行、再从行走回语义的功能。
# 四列缺一列，就会有人问「这片算完了吗」；没有反证的判据不算判据。
if [ "$BOARD" = "1" ]; then
  BD="$(resolve "$DIR" 切片表.md 切片)"
  if [ -s "$BD" ]; then
    pass "G11 找到切片表: $(basename "$BD")"
    HDR=""
    for kw in 数据流 信息流 依赖; do
      grep -qE "^\|.*$kw" "$BD" || HDR="$HDR $kw"
    done
    if [ -n "$HDR" ]; then
      block "G11 切片表缺列:$HDR（表头必须是 片/功能/数据流出口/信息流出口/依赖）"
    else
      pass "G11 四列齐"
    fi

    if grep -q '反证' "$BD"; then pass "G11 有反证列/段"
    else block "G11 切片表没有反证 —— 每条判据必须能测出红"; fi

    if grep -qE '→|->' "$BD"; then pass "G11 顺序写成一行"
    else block "G11 没有顺序行（F1 → (F2 ∥ F3) → …）—— 依赖序只能靠记忆"; fi

    TBD=$(grep -nE '待定|待补|TODO|TBD' "$BD" 2>/dev/null || true)
    if [ -n "$TBD" ]; then
      block "G11 切片表还有待定/待补（写「不知道」也得写清了什么不知道）:"
      printf '%s\n' "$TBD" | head -5 | sed 's/^/        /'
    else
      pass "G11 无待定"
    fi
  else
    block "G11 缺 切片表（切片表.md，或名字含「切片」的 .md）—— 不许一边切一边想"
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
