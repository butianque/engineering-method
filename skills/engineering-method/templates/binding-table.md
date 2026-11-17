# 模板 · P2 需求 ↔ 代码绑定表

> 用法：每个 P1 叶子一行。**`UNBOUND` 不许进入实现。** `nl_text` 原样抄，不许改写。

## 绑定表

| req_id | nl_text（原文） | 语义五元组（主体/动作/对象/条件/量） | binding（file:symbol / 字段 / 参数 / 配置键 / DB 列 / 事件） | kind | current_behavior（读出来的） | expected_behavior | dependents | criterion | status |
|---|---|---|---|---|---|---|---|---|---|
| C.1.1 | | | | NEW/MODIFY/REUSE/DELETE | | | | | BOUND/UNBOUND/CONFLICT |

## 联动性检查（`dependents` 触发规则）

- [ ] **D1** 每个改动的 binding，其 `dependents` 已全部列出
- [ ] **D2** 有任何 `dependents` 未确认 → 该行 `status` 必须是 `UNBOUND`
- [ ] **D3** 被 ≥2 条需求共享的 binding 已显式标出，并将合并检验
- [ ] **D4** `kind = DELETE` 的行已列出全部引用点与迁移/删除判据

## 嵌套引用链路（数据与参数互相依赖时填写）

```text
req_id  →  binding  →  依赖的字段/参数  →  由哪条需求设定  →  判据
```

| 起点 | 中间依赖 | 上游需求 | 判据 |
|---|---|---|---|
| | | | |

## CONFLICT 登记

| 冲突双方（req_id） | 冲突点 | 性质（互斥 / 与不变量矛盾 / 量级冲突） | 处置（回需求方 / 在 P1 判 REFUTED） |
|---|---|---|---|
| | | | |

## 不合格写法举例

| 写法 | 为什么不合格 |
|---|---|
| `binding: 后端逻辑` | 不是落点 |
| `current_behavior: 应该是先校验再写库` | "应该"= 没读 |
| 绑了 file 没绑 symbol / 参数 | 粒度不足 |
| `criterion` 空 | 该点不可验证 |
| `dependents` 空但符号有 12 处引用 | 漏算联动 |
