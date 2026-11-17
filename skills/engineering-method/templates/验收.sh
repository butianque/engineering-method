#!/usr/bin/env bash
# 验收.sh — 三级验收，退出码 0 才算过
#
# 用法：
#   bash 验收.sh              # 跑全部
#   bash 验收.sh --case restart   # 只跑某一例
#
# 铁律：L3 必须从真实入口打进去，必须断言期望结果，不许只断言"没报错"。

set -uo pipefail
cd "$(dirname "$0")" || exit 1
CASE="${2:-all}"
FAIL=0

# .runs 用来留证据；gate.sh 会把它的输出写进 .runs/acceptance.log
mkdir -p .runs

step()  { printf '\n==== %s ====\n' "$*"; }
ok()    { printf 'ok    %s\n' "$*"; }
bad()   { printf 'FAIL  %s\n' "$*"; FAIL=1; }

# ---------- 按需改这一段：填真实命令 ----------
BASE="${BASE:-http://127.0.0.1:8080}"   # 外部入口
# -------------------------------------------

# ================= L1 语法 =================
if [ "$CASE" = "all" ] || [ "$CASE" = "syntax" ]; then
  step "L1 语法 / 类型"
  # 改成你的实际命令。下面三种留一个。
  # go build ./...            && ok "go build"           || bad "go build"
  # bun run type-check        && ok "type-check"         || bad "type-check"
  # python -m compileall -q . && ok "compileall"         || bad "compileall"
  true
fi

# ================= L2 单测 =================
if [ "$CASE" = "all" ] || [ "$CASE" = "unit" ]; then
  step "L2 单测"
  # go test ./... -count=1      && ok "go test"     || bad "go test"
  # bun test                    && ok "bun test"    || bad "bun test"
  true
fi

# ================= L3 端到端 =================
# 三条硬要求：
#   E1 从真实入口（HTTP / CLI / UI），不直接调函数
#   E2 断言期望结果，不只是没报错
#   E3 端点清单里每一个都要打一次
if [ "$CASE" = "all" ] || [ "$CASE" = "e2e" ]; then
  step "L3 端到端（外部入口）"

  # --- 例 1：健康检查 ---
  code=$(curl -s -o /dev/null -w '%{http_code}' "$BASE/health" || echo 000)
  [ "$code" = "200" ] && ok "GET /health → 200" || bad "GET /health → $code"

  # --- 例 2：断言响应体，不只是状态码 ---
  body=$(curl -s "$BASE/api/example" || true)
  printf '%s' "$body" | grep -q '"ok":true' \
    && ok "GET /api/example 含 ok:true" \
    || bad "GET /api/example 响应不符：$(printf '%s' "$body" | head -c 200)"

  # --- 例 3：失败路径（故意传错，期望被拒） ---
  code=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$BASE/api/example" -d '{}' || echo 000)
  [ "$code" = "400" ] && ok "空 body → 400" || bad "空 body → $code（期望 400）"
fi

# ================= 专项：重启后数据还在 =================
if [ "$CASE" = "restart" ]; then
  step "L3 专项：重启持久化"
  # 改成：写入 → 重启 → 读回。这里只给骨架。
  # curl -sf -X POST "$BASE/api/x" -d '{"v":1}' >/dev/null || bad "写入失败"
  # <restart command>                                     || bad "重启失败"
  # got=$(curl -s "$BASE/api/x")
  # printf '%s' "$got" | grep -q '"v":1' && ok "重启后仍在" || bad "重启后丢了：$got"
  true
fi

# ================= 结论 =================
printf '\n'
if [ "$FAIL" -eq 0 ]; then
  printf 'ACCEPT 全部通过\n'
  exit 0
else
  printf 'REJECT 有失败项\n'
  exit 1
fi
