#!/usr/bin/env bash
# consistency.sh — 本 skill 自己的 D3 检查器（一个概念只许一处定义）
#
#   bash consistency.sh <skill 目录>
#
# 退出 0 = 自洽；1 = 有冲突；2 = 用法错。
#
# 为什么需要这个文件：
#   本 skill 要求别人的文档「一个概念只有一处定义」（D3），
#   而它自己在 0.8.x 里长出了三套编号（九步 / 八类入口 / 八件产物）
#   和五处「谁验收」。要求别人做到的事，自己先做到；
#   做不到的部分，就交给机器查，而不是靠「下次注意」。

set -uo pipefail

SK="${1:-}"
[ -n "$SK" ] && [ -d "$SK" ] || { echo "用法: bash consistency.sh <skill 目录>" >&2; exit 2; }

FAIL=0
ok()  { printf 'ok     %s\n' "$*"; }
bad() { printf 'CONFLICT  %s\n' "$*"; FAIL=1; }

md() { ls "$SK"/*.md "$SK"/references/*.md "$SK"/templates/*.md 2>/dev/null; }

# ---------------------------------------------------------------- 1 只有一套编号
# 唯一主干 = 层一/层二 + 门 1–4。旧编号（九步 / 步 0–7 / 八件）一旦回来，
# 读者就会在两套说法之间猜，那正是本 skill 要防的病。
LEGACY=$(grep -nE '九步|步\s*[0-7]\b|八件产物|八个不能省' "$SK"/SKILL.md 2>/dev/null \
         | grep -v 'CLI 序号' || true)
if [ -z "$LEGACY" ]; then
  ok "SKILL.md 只有一套编号（层一/层二 + 门 1–4）"
else
  bad "SKILL.md 出现旧编号，与主干并存："
  printf '%s\n' "$LEGACY" | head -5 | sed 's/^/        /'
fi

for f in $(md); do
  case "$(basename "$f")" in
    SKILL.md|consistency.md) continue ;;
  esac
  HIT=$(grep -nE '步\s*[0-7]\b' "$f" 2>/dev/null | grep -vE 'CLI|序号|--steps' || true)
  if [ -n "$HIT" ]; then
    bad "$(basename "$f") 仍用旧编号「步N」："
    printf '%s\n' "$HIT" | head -3 | sed 's/^/        /'
  fi
done

# ---------------------------------------------------------------- 2 分工只有一处定义
# 定义 = 成段论述（出现「只负责」「不负责验收」这类完整句）。
# 引用 = 一行指针。超过一处成段论述，就是两套说法。
DEF=0
for f in $(md); do
  n=$(grep -cE '子代理只负责|不负责验收' "$f" 2>/dev/null || true)
  [ "${n:-0}" -gt 0 ] && { DEF=$((DEF + n)); echo "        定义处: $(basename "$f") × $n"; }
done
if [ "$DEF" -le 2 ]; then
  ok "分工的成段论述只有一处（r8 §3；含其引用行共 $DEF 行）"
else
  bad "分工在 $DEF 行里被成段论述 —— 定义应只在 r8 §3，其余只能一行引用"
fi

# ---------------------------------------------------------------- 3 三定只有一处定义
# 三定的定义（位置结构 / 依赖序 / 风格 的完整论述）只在 spacetime.md。
TD=$(grep -lE '依赖序图.*谁产生|位置结构（空间）' $(md) 2>/dev/null | xargs -r -n1 basename 2>/dev/null | sort -u)
if [ "$(printf '%s\n' "$TD" | grep -c .)" -le 1 ]; then
  ok "三定的定义只有一处（${TD:-spacetime.md}）"
else
  bad "三定被重复定义：$(printf '%s ' $TD)"
fi

# ---------------------------------------------------------------- 4 立项清单只有一处
# 立项要填哪几节：唯一权威是 templates/立项书.md。
# steps-0-2.md 若再列一遍清单，就又是两套。
Q=$(grep -lE '六项，缺一重做|立项书 6 项|立项书七段|立项书 7 段' $(md) 2>/dev/null || true)
if [ -z "$Q" ]; then
  ok "立项清单只在模板里定义"
else
  bad "立项清单在别处又被定义了一次："
  printf '%s\n' "$Q" | sed 's/^/        /'
fi

# ---------------------------------------------------------------- 5 模板名不许撞车
# gate.sh 按文件名关键词解析；若两个模板共享关键词，
# 「有 A 没有 B」会被判成「B 也在」——这是假通过。
for kw in 立项书 规划 策划 设计 范畴 集成面 反合理化; do
  n=$(ls "$SK"/templates/*"$kw"*.md 2>/dev/null | wc -l | tr -d ' ')
  if [ "${n:-0}" -gt 1 ]; then
    bad "模板关键词「$kw」撞车 $n 个（gate 会互相误认）：$(ls "$SK"/templates/*"$kw"*.md | xargs -n1 basename | tr '\n' ' ')"
  fi
done

# ---------------------------------------------------------------- 6 每个 references 都被 SKILL 指到
# 造出来却没人指的文件 = 写了没人读 = 白写。
# 允许两种指法：字面文件名，或通配（`p0`–`p7-*.md` 这类范围写法）。
covered() {
  local b="$1" prefix="$2"
  grep -q "$b" "$SK/SKILL.md" && return 0
  # 通配范围：p0`–`p7-*.md / r0-r8 / *-*.md 形态
  grep -qE "$prefix[0-9]\`?[–-]\`?$prefix[0-9]|$prefix\\*|$prefix-\\*\\.md" "$SK/SKILL.md" && return 0
  grep -rq "$b" "$SK"/references/*.md 2>/dev/null && return 0
  # 被同一前缀范围覆盖（p1 由 `p0`–`p7-*.md` 覆盖）
  grep -qE "\`$prefix[0-9]\`[–-]\`$prefix[0-9]-\\*\\.md" "$SK/SKILL.md" && return 0
  return 1
}

ORPHAN=0
for f in "$SK"/references/*.md; do
  b=$(basename "$f")
  [ "$b" = "consistency.md" ] && continue
  prefix=$(printf '%s' "$b" | sed -n 's/^\([a-z][a-z]*\)[0-9].*/\1/p')
  [ -n "$prefix" ] || prefix="$(printf '%s' "$b" | cut -c1-1)"
  if ! covered "$b" "$prefix"; then
    bad "references/$b 没有任何入口指向它（写了没人读）"
    ORPHAN=$((ORPHAN + 1))
  fi
done
[ "$ORPHAN" -eq 0 ] && ok "每个 reference 都有入口"

# ---------------------------------------------------------------- 结论
echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "PASS  自洽：一个概念一处定义，一套编号"
  exit 0
else
  echo "CONFLICT  上列每一条都是「两套说法」——本 skill 要求别人做到的，自己先做到"
  exit 1
fi
