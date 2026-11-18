#!/usr/bin/env bash
# gate.sh — 工程方法论的唯一机器判据
#
# 用法：
#   bash gate.sh <项目目录>                       # 查全部八件套
#   bash gate.sh <项目目录> --steps 4             # 只查范畴表（层一·划界）
#   bash gate.sh <项目目录> --steps 0,1           # 只查立项书 + 切片表
#
#   --steps 的数字 = 位置序号（不是「第几步」，是「哪一块」）：
#     0 层一·域  1 层一·切片表  2 层一·策划  3 层一·三定
#     4 层一·划界  5 层二·集成面  6 门4·验收  7 反合理化
#   bash gate.sh <项目目录> --done                # 额外跑验收.sh
#   bash gate.sh <项目目录> --arch                # 额外跑 arch-check.sh（分类与落位）
#   bash gate.sh <项目目录> --spiral              # 额外查螺旋：每轮必须有新增事实
#   bash gate.sh <项目目录> --charter             # 额外查立项：表被填满 / 文档存在 / 边界 / 未知 / 无补丁
#   bash gate.sh <项目目录> --board               # 额外查切片：表被填满 / 有反证 / 有依赖 / 无占位
#
#   --charter / --board 只查结构，不查词汇。
#   理由：域 = 范畴 =「要让这件事成立必须存在的一类东西」，数量与名字由这个功能推出，
#   每个项目都不同。把某个项目的域清单写成判据，就等于只对一个项目有效。
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
DOMAINS=""
STEPS="0,1,2,3,4,5,6,7"

while [ $# -gt 0 ]; do
  case "$1" in
    --done)    MODE="--done"; shift ;;
    --arch)    ARCH="1"; shift ;;
    --spiral)  SPIRAL="1"; shift ;;
    --charter) CHARTER="1"; shift ;;
    --board)   BOARD="1"; shift ;;
    --domains) DOMAINS="1"; shift ;;
    --steps)   STEPS="${2:-}"; shift 2 ;;
    *)         DIR="${1:-}"; shift ;;
  esac
done

if [ -z "$DIR" ] || [ ! -d "$DIR" ]; then
  echo "用法: bash gate.sh <项目目录> [--steps 0,1,2,3,4,5,6,7] [--done] [--arch] [--spiral] [--charter] [--board] [--domains]" >&2
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
# 位置名（与 SKILL.md 的「三层四门」同一套词；数字只是 CLI 序号）
declare -A P=(
  [0]="层一·域" [1]="层一·切片表" [2]="层一·策划" [3]="层一·三定"
  [4]="层一·划界" [5]="层二·集成面" [6]="门4·验收" [7]="反合理化"
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
      if [ "$(basename "$hit")" = "$f" ]; then pass "G1 ${P[$s]} $f"
      else pass "G1 ${P[$s]} $f（认作 $(basename "$hit")）"; fi
    else
      block "G1 缺 ${P[$s]} 产物或为空: $f"
    fi
  fi
done

# ---------- G4 设计必须签收（层一·三定的核心 gate）----------
if has 3; then
  if [ -s "$DIR/.runs/signoff-system-design.md" ]; then
    pass "G4 系统设计已签收"
  else
    block "G4 系统设计未签收（缺 .runs/signoff-system-design.md）—— 不许开程序设计段"
  fi
fi

# ---------- G7 三定（位置结构 / 依赖序 / 风格）----------
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

# ---------- G2 集成面（层二·集成面）----------
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

# ---------- G3 验收（门4，仅 --done）----------
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
# 依据：立项文档不是介绍，是基准。下游每篇都要能被它逐行判「是/否」。
#
# 这里只查结构，不查词汇。理由：域 = 范畴 =「要让这件事成立必须存在的一类东西」，
# 数量与名字由这个功能推出，每个项目都不同。把某个项目的域清单写成判据，
# 就等于只对一个项目有效。可查的结构是：
#   ① 有表，且至少一行被填满（一个域被说清了）
#   ② 声明的文档路径真实存在（域必须落到一份真实文档）
#   ③ 有边界（不做 / 不管 / 不在范围）
#   ④ 有未知项，且写了「怎么验」
#   ⑤ 无补丁段（G10）
if [ "$CHARTER" = "1" ]; then
  CH="$(resolve "$DIR" 立项书.md 立项)"
  [ -n "$CH" ] || CH="$(resolve "$DIR" "" charter)"
  [ -n "$CH" ] || CH="$(resolve "$DIR" "" 提案)"
  if [ -z "$CH" ] || [ ! -s "$CH" ]; then
    block "G9 缺立项文档（立项书.md / 名字含「立项」「charter」「提案」的 .md）"
  else
    pass "G9 找到立项文档: $(basename "$CH")"

    # ① 表格：数据行数 / 单元总数 / 空格 / 被填满的数据行数（表头不算）
    #   遇到分隔行 ⇒ 上一行是表头，撤掉它的计数。否则「表头填满」会被当成「一个域填满了」。
    STATS="$(awk '
      /^\|/ {
        line=$0
        sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line)
        if (line ~ /^\|[-:| ]+\|$/) {
          if (prevrow) { rows--; total-=pcells; empty-=pempty; if (pfull) full-- }
          prevrow=1; pcells=0; pempty=0; pfull=0
          next
        }
        n=split(line, a, "|")
        rows++; filled=0; cells=0
        for (i=2; i<n; i++) {
          c=a[i]; sub(/^[ \t]+/, "", c); sub(/[ \t]+$/, "", c)
          cells++; total++
          if (c=="") { empty++ } else { filled++ }
        }
        pfull = (cells>=4 && filled==cells) ? 1 : 0
        if (pfull) full++
        prevrow=1; pcells=cells; pempty=cells-filled
      }
      END { printf "%d %d %d %d\n", rows+0, total+0, empty+0, full+0 }
    ' "$CH")"
    TROWS=$(printf '%s' "$STATS" | cut -d' ' -f1)
    TCELLS=$(printf '%s' "$STATS" | cut -d' ' -f2)
    TEMPTY=$(printf '%s' "$STATS" | cut -d' ' -f3)
    TFULL=$(printf '%s' "$STATS" | cut -d' ' -f4)

    if [ "${TROWS:-0}" -lt 3 ] || [ "${TCELLS:-0}" -lt 6 ]; then
      block "G9 立项里没有可用的表（≥3 行 ≥2 列）—— 域要被列出来，不能被写成一团散文"
    elif [ "${TFULL:-0}" -lt 1 ]; then
      block "G9 没有一行被填满：一个域都没说清（每格都要有内容；写「不知道」也算内容）"
    else
      pass "G9 表 $TROWS 行，$TFULL 行填满，空格 $TEMPTY/$TCELLS"
    fi

    if [ "${TCELLS:-0}" -gt 0 ] && [ $(( TEMPTY * 100 / TCELLS )) -gt 60 ]; then
      block "G9 表格空格率 $(( TEMPTY * 100 / TCELLS ))%（>60%）—— 模板抄了没填，等于没立项"
    fi

    # ①b 整列为空的列 = 装饰列（结构性，不依赖列名）
    #     典型：写了「删掉它会怎么坏」这一列，一格都没填 —— 那一列等于不存在。
    #     必须**按表**统计：同一个文件里有多张表，跨表混算会把空列算成满列。
    EMPTYCOLS="$(awk '
      function flush(   j) {
        if (datrows > 0)
          for (j = 1; j <= maxc; j++)
            if (cnt[j] > 1 && fill[j] + 0 == 0) printf "表%d列%d ", blkno, j
        delete cnt; delete fill; datrows = 0; maxc = 0; seensep = 0
      }
      /^\|/ {
        line = $0; sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line)
        if (line ~ /^\|[-:| ]+\|$/) { if (!seensep) { seensep = 1; blkno++ } next }
        n = split(line, a, "|")
        if (!seensep) next
        datrows++
        if (n - 2 > maxc) maxc = n - 2
        for (i = 2; i < n; i++) {
          v = a[i]; sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
          cnt[i-1]++; if (v != "") fill[i-1]++
        }
        next
      }
      { flush() }
      END { flush() }
    ' "$CH")"
    if [ -n "$EMPTYCOLS" ]; then
      block "G9 有整列没填（$EMPTYCOLS）—— 占位列等于没写：删掉那一列，或填满"
    else
      pass "G9 无空列"
    fi

    # ② 域必须落到真实文档（skill 自身的 references/ templates/ 不算项目文档）
    #    正则里只放 ASCII 分隔符：把中文标点写进 [^…] 会让 grep 按字节切，切出乱码路径。
    PATHS=$(grep -oE '[^ |`()<>,]+\.md' "$CH" 2>/dev/null \
            | sed -e 's/^[^A-Za-z0-9_./-]*//' -e 's/[^A-Za-z0-9_./-]*$//' \
            | grep -vE '^(references|templates)/' | grep -v '^\.md$' | sort -u || true)
    if [ -z "$PATHS" ]; then
      block "G9 一个文档路径都没声明 —— 域没有入口文档，就等于没有位置"
    else
      BAD=""
      while IFS= read -r p; do
        [ -n "$p" ] || continue
        [ -e "$DIR/$p" ] && continue
        b="$(basename "$p")"
        if [ -z "$(find "$DIR" -name "$b" -print -quit 2>/dev/null)" ]; then BAD="$BAD $p"; fi
      done <<EOF
$PATHS
EOF
      if [ -n "$BAD" ]; then
        block "G9 声明的文档不存在:$BAD"
      else
        pass "G9 声明的文档都在（$(printf '%s\n' "$PATHS" | wc -l | tr -d ' ') 个）"
      fi
    fi

    # ③ 边界
    if grep -qE '不做|不管|不在范围|范围外|out of scope|non-goal' "$CH"; then
      pass "G9 有边界（不做的部分）"
    else
      block "G9 没有边界 —— 没有「不做」，任何东西都能被说成「做完了」"
    fi

    # ④ 未知项 + 怎么验
    if grep -qE '不知道|未定|未知|unknown|TBD|待验' "$CH"; then
      if grep -qE '怎么验|如何验|验证方式|怎么解决|how to verify' "$CH"; then
        pass "G9 未知项写了怎么验"
      else
        block "G9 写了未知项却没写「怎么验」—— 未知项会烂在原地"
      fi
    else
      block "G9 一条未知项都没有（通常意味着盲区没写出来）"
    fi

    # ⑤ G10 补丁段
    #    要排除「禁止…原写…现改为…」这种**引用**禁令的行，否则纪律本身会被判违规
    PATCH=$(grep -nE '原写.{0,30}现改为|补记|修订记录|变更日志|以下为追加' "$CH" 2>/dev/null \
            | grep -vE '禁止|不许|不得|forbid|Forbid' || true)
    if [ -n "$PATCH" ]; then
      block "G10 立项里有补丁段（D1 禁止：只写当前真相）:"
      printf '%s\n' "$PATCH" | head -5 | sed 's/^/        /'
    else
      pass "G10 无补丁段"
    fi
  fi
fi

# ---------- G11 切片可派（--board）----------
# 依据：一片 = 一条能从输入走到行、再从行走回语义的功能。
# 同样只查结构：有表、有填满的行、有反证、有依赖、无占位。
if [ "$BOARD" = "1" ]; then
  BD="$(resolve "$DIR" 切片表.md 切片)"
  [ -n "$BD" ] || BD="$(resolve "$DIR" "" 实施)"
  if [ -s "$BD" ]; then
    pass "G11 找到切片文档: $(basename "$BD")"
    BSTATS="$(awk '
      /^\|/ {
        line=$0
        sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line)
        if (line ~ /^\|[-:| ]+\|$/) {
          if (prevrow) { rows--; if (pfull) full-- }
          prevrow=1; pfull=0
          next
        }
        n=split(line, a, "|")
        rows++; filled=0; cells=0
        for (i=2; i<n; i++) {
          c=a[i]; sub(/^[ \t]+/, "", c); sub(/[ \t]+$/, "", c)
          cells++; if (c!="") filled++
        }
        pfull = (cells>=3 && filled==cells) ? 1 : 0
        if (pfull) full++
        prevrow=1
      }
      END { printf "%d %d\n", rows+0, full+0 }
    ' "$BD")"
    BROWS=$(printf '%s' "$BSTATS" | cut -d' ' -f1)
    BFULL=$(printf '%s' "$BSTATS" | cut -d' ' -f2)

    if [ "${BROWS:-0}" -lt 2 ]; then
      block "G11 切片没有可用表（≥2 片）—— 边切边想等于没切"
    elif [ "${BFULL:-0}" -lt 1 ]; then
      block "G11 没有一片被填满（每格都要有内容）"
    else
      pass "G11 切片 $BROWS 行，$BFULL 片填满"
    fi

    if grep -qE '反证|注入|falsif|必须红' "$BD"; then pass "G11 有反证"
    else block "G11 没有反证 —— 每条判据必须能测出红"; fi

    if grep -qE '依赖|顺序|→|->|blocked' "$BD"; then pass "G11 写了依赖/顺序"
    else block "G11 没写依赖顺序 —— 只能靠记忆排"; fi

    TBD=$(grep -nE '待定|待补|TODO|TBD|\?\?\?|XXX' "$BD" 2>/dev/null || true)
    if [ -n "$TBD" ]; then
      block "G11 还有占位（写「不知道」也要写清了什么不知道）:"
      printf '%s\n' "$TBD" | head -5 | sed 's/^/        /'
    else
      pass "G11 无占位"
    fi
  else
    block "G11 缺切片文档（切片表.md / 名字含「切片」「实施」的 .md）"
  fi
fi

# ---------- G13 域文档齐（门 2，--domains）----------
# 依据：真实项目的成本在「每个域各自写完一份文档」，而这一步最容易被吞进「三定」里，
# 于是出现「三定写完了，但域文档只有一半」却没人发现。
#
# 只查结构，不查词汇（C14）：
#   ① 清单里每一行都声明了入口文档（那一格不能空）
#   ② 每一份声明的文档真实存在且非空
#   ③ 每份文档不是空壳：有一张填满的数据行表，或 ≥3 个二/三级标题
#
# 「三件套是否真的齐」属人判（H 类），机器只保证「不是空的」。
if [ "$DOMAINS" = "1" ]; then
  CH="$(resolve "$DIR" 立项书.md 立项)"
  [ -n "$CH" ] || CH="$(resolve "$DIR" "" charter)"
  [ -n "$CH" ] || CH="$(resolve "$DIR" "" 提案)"

  if [ -z "$CH" ] || [ ! -s "$CH" ]; then
    block "G13 缺立项文档 —— 清单都没有，无从查域文档"
  else
    # 抓清单里声明的 .md 路径（排除 skill 自身文档）
    DOCS=$(grep -oE '[^ |`()<>,]+\.md' "$CH" 2>/dev/null \
           | sed -e 's/^[^A-Za-z0-9_./-]*//' -e 's/[^A-Za-z0-9_./-]*$//' \
           | grep -vE '^(references|templates)/' | grep -v '^\.md$' | sort -u || true)

    NDM=$(printf '%s\n' "$DOCS" | grep -c . || true)
    if [ "${NDM:-0}" -eq 0 ]; then
      block "G13 清单没声明任何入口文档 —— 域没有落点，等于没建"
    else
      # ③ 逐份：存在 / 非空 / 不是空壳
      HOLLOW=""
      ABSENT=""
      while IFS= read -r d; do
        [ -n "$d" ] || continue
        f=""
        if [ -s "$DIR/$d" ]; then f="$DIR/$d"
        else
          b="$(basename "$d")"
          cand="$(find "$DIR" -name "$b" -print -quit 2>/dev/null)"
          [ -n "$cand" ] && [ -s "$cand" ] && f="$cand"
        fi
        if [ -z "$f" ]; then ABSENT="$ABSENT $d"; continue; fi

        # 结构化内容判定：填满的数据行表 OR ≥3 个二/三级标题
        TABROWS=$(awk '
          /^\|/ {
            line=$0; sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line)
            if (line ~ /^\|[-:| ]+\|$/) next
            n=split(line, a, "|"); cells=0; filled=0
            for (i=2; i<n; i++) {
              v=a[i]; sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
              cells++; if (v!="") filled++
            }
            if (cells>=2 && filled==cells) full++
          }
          END { printf "%d\n", full+0 }' "$f")
        HEADS=$(grep -cE '^#{2,3} ' "$f" || true)

        if [ "${TABROWS:-0}" -lt 1 ] && [ "${HEADS:-0}" -lt 3 ]; then
          HOLLOW="$HOLLOW $d"
        fi
      done <<EOF
$DOCS
EOF

      if [ -n "$ABSENT" ]; then
        block "G13 声明了但文档不存在（或为空）:$ABSENT"
      else
        pass "G13 声明的 $NDM 份域文档都存在且非空"
      fi

      if [ -n "$HOLLOW" ]; then
        block "G13 这些文档是空壳（没有填满的表，也没有 ≥3 个小节）:$HOLLOW"
      else
        pass "G13 每份域文档都有结构（表或小节）"
      fi
    fi

    # ② 清单里的每一行都要有文档（抓「有域没落点」）
    #    必须**按表**判断：同一个文件里还有「不做」「未知项」等表，
    #    它们本来就没有 .md 列 —— 跨表混判会把它们全误报成「域没落点」。
    NODOC=$(awk '
      function flush(   j) {
        if (hasmd) for (j = 1; j <= ndr; j++) if (!rowmd[j]) printf "%s ", first[j]
        delete rowmd; delete first; ndr = 0; hasmd = 0
      }
      /^\|/ {
        line=$0; sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line)
        if (line ~ /^\|[-:| ]+\|$/) { seensep = 1; next }
        if (!seensep) next                     # 表头行
        ndr++
        f = line; gsub(/^\|[ \t]*/, "", f); sub(/[ \t]*\|.*$/, "", f)
        first[ndr] = f
        if (line ~ /\.md/) { rowmd[ndr] = 1; hasmd = 1 } else { rowmd[ndr] = 0 }
        next
      }
      { flush(); seensep = 0 }
      END { flush() }
    ' "$CH")
    if [ -n "$NODOC" ]; then
      block "G13 清单里有行没写入口文档（首列: $NODOC）—— 那个域没有位置"
    else
      pass "G13 清单每行都指到了文档（或本行不是域行）"
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
