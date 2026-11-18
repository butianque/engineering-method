# Changelog

Every entry says **why the change exists**, not only what changed. The version
rule is the one used by the skill itself: `x` for a restructure, `y` for a new
step or gate, `z` for content added inside an existing step.

The skill started as two separate skills inside a private workspace:

```
engineering-method   how to think   (立核 → 范畴 → 递归 → 检索 → 规划 → 冻结 → 验证 → 落盘)
system-project-init  how to refuse  (five artefacts + integration surface + acceptance + gate)
```

They were merged because their trigger conditions overlapped (both claimed
"规划"), because the order they enforce was always one chain, and because a user
wants a chain, not a methodology plus a door. Everything below is post-merge.

---

## 0.9.2 — 2026-11-19

**用户问的那个口子，确实要开一道门：**

> 现在层一有 5 个子步，但只有门 1、门 2、门 3 管它 ——「逐域文档」没有单独的门，它混在门 2 的「设计签收」里。

**判断：要开。** 因为那个项目的真实成本就在「每个域各自写完一份」，
而它**最容易被吞进「三定」** —— 于是出现「三定写完了，域文档只有一半」却没人发现。

### Added — 门 2 `--domains`：域文档齐

```
D1 声明的文档都存在且非空        → 抓「域表点了名，文件没建」
D2 每份不是空壳                  → 有 ≥1 张填满的数据行表，或 ≥3 个二/三级标题
D3 清单每一行都有落点            → 抓「有域没文档」
```

**D3 必须按表判**：同一份立项文件里还有「不做」「未知项」等表，它们本来就没有 `.md` 列；
跨表混判会把它们全误报成「域没落点」。这个坑我当场踩了一次，实测抓出来的。

**「三件套是否真的齐」仍是人判**（H 类）—— 机器只保证「不是空的」。

### 门序改为五道

```
门1 立项可判  →  门2 域文档齐  →  门3 设计可开工  →  门4 切片可派  →  门5 一片可收
--steps 0 --charter   --steps 0 --domains   --steps 3   --steps 5 --board   --done
```

层一正文里 ② 后面直接写明：**过门 2 才算写完**。主干图、门表、命令表、三档约束全部同步。

### Added — `verify.sh` 第 12b 节

门必须两头都能动：

```
补一份缺的文档、把空壳写成有结构  →  必须转 PASS（否则它是墙，不是门）
```

### Fixed — 两个真 bug（都是我这一轮自己写出来的）

**① `gate.sh` 里两处外层引号没闭合**

```
STATS="$(awk '...' "$CH")      ← 少了收尾的 "
EMPTYCOLS="$(awk '...' "$CH")  ← 同上
```

后果不是语法错（`bash -n` 照样 PASS），而是**运行时把后面 20 多行当成一个字符串**，
报出一句完全误导的 `TROWS: unbound variable`。这正是本 skill 说的
「判据跑绿了不等于判据是对的」——`bash -n` 是语法层，抓不到引号跨度错误。

**② G13 里我用了「域表」这个项目词汇**

新加的检查一上手就写成 `G13 域表里有行没写入口文档`。第二节的形态无关性检查当场把它抓出来
（`gate.sh contains no project-specific vocabulary` FAIL）。改成结构词「清单」后通过。

**⇒ 这两条合起来说明一件事：判据自己也要被同一个判据检查。**
`consistency.sh` + `verify.sh` 第 11 节的组合，这次真的拦住了一个回归。

### 自测

```
consistency.sh                     → PASS
三域合成项目                        → PASS
未填模板                            → BLOCK
门2：缺文档 / 空壳 / 无落点         → BLOCK，补全后转 PASS
DSJY 真实 docs                      → 23 份域文档全在、全有结构、清单每行有落点
verify.sh                           → PASS（含 12b）
SKILL.md 19,984 B < 20000
```

---

## 0.9.0 — 2026-11-18

**用户问了两个问题，第二个是重点：**

> 可以，但是目前这个skill不会冲突吗？
> 而且这个流程得搞对。

**冲突确实存在。** 我用 `grep` 把整个 skill 审了一遍，找到 **8 处「一个东西两套说法」**
——而 `C12 / D3`「一个概念只许一处定义」正是本 skill 拿来要求别人的第一条纪律。

### 审计出的 8 处冲突

| # | 冲突 | 具体 |
|---:|---|---|
| 1 | **三套编号并存** | 「九步 0–7」/「八类入口」/「八件产物」——同一件事三种数法 |
| 2 | **八类只有六行** | 表头写「八类入口」，表里 6 行（规划/策划/设计合并了），说 8 给 6 |
| 3 | **分工五处成段论述** | r8 §3 / r7 §4 / 任务书 / SKILL / excuse-table 各写一遍「谁验收」 |
| 4 | **三定两处定义** | SKILL 列了三定表，`spacetime.md` 又定义一遍 |
| 5 | **立项清单两套** | `steps-0-2.md` 教「六项」，`templates/立项书.md` 已经 8 节 |
| 6 | **判据 6 条 vs 实现 4 条半** | r6 §7 列 6 条，`--charter` 只实跑 4 条（空列、删掉会怎么坏都没查） |
| 7 | **gate 用两套标签** | 输出说「G1 步3」，SKILL 说「层一·三定」 |
| 8 | **6 个 reference 没人指** | p1/p2/p4/p6/p7/design-planning 写了没入口（路由表用 `p0`–`p7-*.md` 通配，检查器看不见） |

### 修法一：一条主干，一套编号

```
【层一·定向】一次：域 → 三定 → 切片表
【层二·施工】每片：九个动作
【收口】版本级：对账 + 状态表 + 红线

四道门：1 立项可判 · 2 设计可开工 · 3 切片可派 · 4 一片可收
```

**「步 0–7」全部退休**，换成位置名：`层一·域 / 层一·切片表 / 层一·策划 / 层一·三定 / 层一·划界 / 层二 / 门 4`。
`gate.sh --steps` 的数字保留为 **CLI 序号**（并写明「不是第几步，是哪一块」），输出改用位置名（`G1 层一·域 立项书.md`）。

**为什么不是「保留九步、只加别名」**：两套名字并存，读者永远要在两套之间猜——那就是「各自解释」。

### 修法二：唯一权威表进 SKILL 正文

新增一节，把「哪个概念只在哪一处定义」列成表（主干 / 域 / 引导兜底 / 纪律 / 认知链 / 切片 / 任务书 / 分工 / 九动作 / 日志 / 三定 / gate）。
**判据：任何一条规则在 `grep` 下只能有一个定义处；其余必须是引用或一句话摘要。**

据此把 r7 §4 从「成段复述」改成 **一行 + 指向 r8 §3**；把 SKILL 的三定表改成 **一行 + 指向 spacetime.md**；
把 `steps-0-2.md` §0.2 的「六项」改成 **「清单不在这里定义，唯一权威是 templates/立项书.md」**。

### 修法三：新增 `scripts/consistency.sh` —— 本 skill 自己的 D3 检查器

```
1 只有一套编号（旧编号「步N」「九步」「八件」一旦回来就红）
2 分工只许一处成段论述（其余只能一行引用）
3 三定只许一处定义
4 立项清单只许在模板里定义
5 模板关键词不许撞车（撞了 gate 会互相误认 = 假通过）
6 每个 reference 都必须有入口（写了没人读 = 白写）
```

**它第一次跑就抓出 8 条**，包括我自己在 0.8.3 里刚写下的 bug。

**⇒ 这是本轮最重要的一件事：把「不冲突」从承诺变成 `exit 1`。**

### 修法四：判据与实现对齐（按 D-11）

r6 §7 重写成两半，对齐 `--charter`：

```
7.1 机器判 8 条（M1–M8）：表够大 / 行填满 / 空格率 / 无空列 / 路径存在 / 有边界 / 未知+怎么验 / 无补丁段
7.2 只能人判 4 条（H1–H4）：域数量对不对 / 「删掉会怎么坏」成不成立 / 边界真排除东西没 / 引导记录属不实
7.3 反例：不许写成判据的形态（九域 / 域表 / 串并汇 / D1–D6 编号）
```

**M4「无空列」是这一版新加的真实检查**：`awk` **按表**统计（同一文件多张表，跨表混算会把空列算成满列），
某列有 ≥2 行却一格没填 ⇒ 判「装饰列」。( 修这个时踩了一次坑：第一版跨表混算，实测被抓出来。)

### Added — `templates/开工单.md`

用户问「这个流程得搞对」，而 r8 的九个动作在此之前**只存在于对话里**。
开工单把它变成一片一张的账：定规范 / 冻契约 / lead 探针 + 基线 / 派活 / 双注入红点 / 两流实测 / 收口 + 债。

**它不是规格的第二份**（那会撞 D3）：语义在任务书、动作在 r8、判据在切片表，**开工单只做账**。

### verify.sh 新增第 13 节

```
consistency.sh 必须 PASS
consistency.sh 必须拒绝一个「九步 + 步0–7」的假 skill（否则这个检查是表演）
```

### 自测（三条方向）

```
consistency.sh          → PASS（第一次跑抓出 8 条，全部修完）
三域合成项目            → PASS
未填模板                → BLOCK
DSJY 真实 docs          → G9 表 9 行全满 / 无空列 / 23 文档在 / 有边界
                          G11 301 行、253 片填满 / 有反证 / 有依赖 / 无占位
                          BLOCK：一条未知项都没有（真缺）
verify.sh               → PASS
SKILL.md 18,592 B < 20000
```

---

## 0.8.3 — 2026-11-18

**一条没有余地的规则，加上它在施工里的位置。**

用户的原话，只有三行：

> 子代理只负责主代理给与的相关任务，不负责验收，
> 验收和规划由任务发出者验收，如有问题子代理也可如实上报。
> 就是这样。

**「就是这样」= 没有例外条款。** 我上一版留了一个口子（「纯搬运也许可以交给子代理自验」），
这版把它堵掉，并且给出了为什么连搬运都不能放：

```
搬运最容易悄悄改掉字节 —— 错误文案、常量内容、指纹输出。
它们不影响编译、不影响逻辑，只影响调用方看到的字节。
→ 所以搬运片的通过凭证是 lead 的逐字节快照，不是子代理的「没改逻辑」。
```

### Changed — `references/r8-slice-rhythm.md` §3 重写为「只执行，不验收」

| 谁 | 干什么 | 不许干什么 |
|---|---|---|
| **任务发出者（lead）** | 规划这一片 / 冻契约 / 写独立探针 / **判定过不过** | 不许把判定外包 |
| **子代理** | 写域内执行 + 如实上报 | **不许自判「这一片通过」**，不许改判据让它通过 |

**新增 §3.1「上报不等于验收」** —— 这条是用户那句「如有问题子代理也可如实上报」的落地：

```
✅ 报事实：「S4 的上界按冻结语义只有 2 条，与任务书的 3 条冲突，我按语义做了，请裁决」
✅ 报事实：「源码 0 处要改」+ 结构性理由 + 注入红点
✅ 报事实：「我够不到 store 的写域，这个洞我复现了但没修」
✗ 报结论：「这一片通过」「测试全绿，可以合了」
```

**判据：报告里凡是「通过 / 完成 / 可以合了」，一律当「它的观点」，判定由 lead 下。**

### Changed — `references/r7-slice-board.md` §4 改名并加硬

「lead 的三件事（不许全交出去）」→ **「分工：规划与验收归任务发出者，子代理只执行」**，
开头就是那三行原话，并明确「不存在某类片可以交给子代理自验」。

### Changed — `templates/任务书.md` 开头先说死角色

任务书第一段现在就是：

```
你只执行这一份任务；规划与验收归任务发出者。
有问题、有冲突、有做不到的，照实上报 —— 但不要下「通过 / 完成」这类结论。
```

§9 加了「报告里不许下的三句结论」与「要报告的三类事实」；§10 机器字段加 `role: execute-only`。

### 规则 — C16 / G12

```
C16 规划与验收归任务发出者；子代理只执行 + 如实上报，不许自判通过。
G12 子代理的自验不算验收；lead 没写独立探针，不许判过。
```

同时把 C13 改准（**域先认来源**：他给了就用他的，没给才推）、C15 改准（**引导与兜底同轨**），
并把 G9 从「立项缺七段 / 九域」改成结构判据 —— 旧写法正是 0.8.1 要拆掉的形态依赖。

### verify.sh 新增第 12 节：分工不许被软化

```
r8 里必须仍有「不负责验收」
「纯搬运」这条无例外声明必须同时存在于 r7 与 r8
任务书必须仍带 role: execute-only
```

这三条是回归闸门：任何后代把这条规则改成「某类任务可以自验」，CI 当场红。

---

## 0.8.2 — 2026-11-18

**这一版不修洞，是「把用户已经在跑的那套做法，原样写进 skill」。**

用户给的是两句话，第二句是一整段施工记录：

> 没有边界，或者说边界是自我触发式的，引导过程中就要找兜底方案去对应。
>
> （以及一整段 8 功能片 + 7 重构片、294 条测试、20 份开发日志的实录）
> 这一整段对话和处理问题的方式，就是整个skills该有的方式。

### 病灶一：我把「引导 → 兜底」写成了先后两步

0.8.1 的 §4 引导、§5 兜底是两节，读起来就是「先问完，再决定要不要查行业」。用户否掉了：

```
没有边界 —— 不存在「问到第几个问题就转行业」这条线
边界是自我触发式的 —— 他一旦不判，兜底当场就得上，不能留空
引导过程中就要找兜底方案去对应 —— 问与兜底是同一个动作的两面
```

**改成 §4「引导 ⇄ 兜底：同一条轨道」**，核心是**一问三备**：

```
对一个待定的域 / 值，同时准备三条出路：
  ① 两个具体选项，各带代价      → 他判了，用他的（原话权威）
  ② 行业默认值，让他否决        → 他不判，落默认并标明「要改就说」
  ③ 反推「不做会怎样」          → 他两个都不接受，从后果定边界
```

**触发条件不是「第几个问题」，是「他有没有判」。**
**结局只有三种：他判了 / 落了行业默认 / 进了未知项。第四种（问过、没结论、没记录）非法。**

### 病灶二：我把「域」写成了「AI 推出来的」

真实的立项不是这样。用户是**自己把域给了**：

```
要写立项书作为总索引总揽：数学\认知范畴 | 架构 | 形式化证明 | 工程\架构 | 框架 |
工程片段细则 | 数据流\API | 消费者\信息流 | 工程判据
我认为这样的架构涵盖了很大一片了。
```

```
0.8.1（错）：一律「推」—— 会把他拍板的东西降级成我的提案
0.8.2（对）：先认来源
             ① 他给了清单 → 照他的建表，我只补「管什么/不管什么/怎么算过」
             ② 他没给     → 才推（功能 → 困境 → 必须同时存在哪几类）
             ③ 推时发现少一类 → 说清「少了它会怎么坏」，让他决定加还是不做
```

**三种来源的交付形态不许混**：他给的写「对齐」，我推的写「推导」，行业的写 `assumption`。

### Added — `references/r8-slice-rhythm.md`：一片怎么才算跑完

这是用户那段实录抽象出来的。**九个动作，顺序不许换**：

```
① 定规范（先改文档，再改代码）→ ② 冻契约（子代理只填函数体）
→ ③ lead 自己写独立探针 → ④ 派活（跨 crate 依赖串行 A→B，不并行）
→ ⑤ 自己复跑（不信「全绿」）→ ⑥ 双注入（子代理一次 + lead 一次，红点不同）
→ ⑦ 看两流（直接查库 / 直接读回）→ ⑧ 开发日志六节 → ⑨ 只改状态表一行
```

**十二条硬纪律，每条都带翻车记录**，其中四条最贵：

| # | 纪律 | 实录里的代价 |
|---:|---|---|
| D-1 | 派活前跑一次基线，把真实数字抄进任务书 | 连续 **8 次**把基线写错（217/238、272/276、276/282…） |
| D-5 | 注入没红，先怀疑夹具覆盖不到 | 注入 `find_edge` 恒 None 没红 —— 只有反面方向用它 |
| D-7 | 零覆盖检测：把主路径那一行注释掉，看有几条红 | `commit()` 从未被执行，291 条测试全绿 |
| D-8 | 重构要三类判据：快照 + wired + 计数 | 原语抄回调用方，8/8 快照全绿，只有计数抓得住 |

还有 D-10（重构片测试条数改前改后必须相等）、D-11（判据与实现不一致只许「改实现」或「承认违反」，不许改判据迁就实现）、D-12（文档失真最难发现的是「当时为真的计划」，只有双向对账能抓）。

### Added — `templates/开发日志.md`

六节固定：改了什么 / 得出什么数字 / 架构长什么样 / 加了哪些文件 / 做到了什么 / 坑。
**第二节与第六节是这份日志存在的理由**；其余只是索引。文件名用**开工**时间。

### Added — 子代理的正确用法（反直觉的四条）

```
1 它会替你兜住你写错的规范（把冲突原文上报，而不是硬套）——这才是要的交付
2 「源码 0 处要改」可以是有效交付，前提：结构性理由 + 注入能红的测试
3 它会越界做临时注入：允许，但要事前说明 + SHA256 核对 + 交付无痕迹
4 它会留中间产物：任务书要写「交付时清掉，只留可复现命令」
```

### Changed — 失败清单加第 ⑩ 条

**⑩ 凭记忆写基线数字**：任务书里的数没重跑 ⇒ 子代理拿错起点，报告对不上。

### verify.sh 新增三条

```
template: 开发日志.md 存在
references/r8-slice-rhythm.md 存在
r6 里仍有「一问三备」——删掉它就等于退回「先问完再查行业」的两步式
```

---

## 0.8.1 — 2026-11-18

**0.8.0 修对了三个洞，但把「一个项目的形态」当成了「所有项目的规范」。这一版只做一件事：把形态降级成例证，把判据改成形态无关。**

用户的判断，一句话：

> 这是做这个项目的方法，不是做所有项目的方法，你的诊断与改动可能不正确，
> 你要认知到的是背后的逻辑与方法论，而不是别的。

### 病灶：抄了结论，没抄前提 —— 这次犯在我自己身上

```
DSJY 分了九个域    → 我把「九域」写成规范
DSJY 用七段立项    → 我把「七段」写成模板
DSJY 派活用九段    → 我把「九段」写成任务书
gate 里 grep 九域 / 域表 / 串并汇 / 定稿 → 把那次项目的词汇写成了必填字段
```

后果是硬的：一个英文文档的项目、一个前端组件、一个爬虫，**永远过不了 0.8.0 的 `--charter`**。
这不是「不够通用」，是**把偶然形态冒充成判据** —— 正好是 0.8.0 自己写进去的那条错。

### 域的重新定义（这一版的全部理由）

用户的原话：

> 域其实指的就是范畴，也就是说用户要开发的这个功能，立项后具备几个域，需要几个东西才能解决，
> 逐步去推，去明确边界的同时，引导用户将要求说出来，如果用户不明确就得清楚知道行业是怎么做的，
> 不打补丁的方式去落实文档，这样才能把整个项目做好。

```
0.8.0（错）：domains = ["认知范畴","架构","形式化",…]     // 九个固定
0.8.1（对）：domains = derive(feature)                    // 推出来，数量由问题决定
             判据：删掉它，系统会以什么方式坏？说不出 ⇒ 它是细节，不是域
```

### Changed — `references/r6-project-charter.md` 整篇重写

从「七段 + 九域清单」改成**五步推导**：

```
① 推   功能 → 什么困境消失 → 要成立必须同时有什么
② 划界 每域：管什么（带反例）/ 不管什么 / 怎么算过
③ 引导 把要求从用户嘴里提出来（六种问法，按有效度排）
④ 兜底 用户不知道 ⇒ 问行业（谁这么做 / 为什么 / 代价）
⑤ 落实 不打补丁地写进文档（六条纪律）
```

新增两节此前完全没有的内容：

* **§4 引导**：六种问法 —— 「两个选项各带代价」优先于开放题 · 「给行业默认让他否决」·
  「反推不做会怎样」·「对齐他的原话」·「要一个可判判据」·「一次只问一个且立刻落条文」。
  判据是**怪自己**的那一条：每个问题都要能答成一句可判的话；答不成 ⇒ 问法错了，不是用户不清。
* **§5 兜底**：用户不明确时，权威临时从「用户」转到「行业」。但必须说得出
  **谁这么做 / 为什么 / 代价**，不许写「一般来说」；进来时标 assumption，并保留他的否决权。

### Changed — `templates/立项书.md` 从 11 段固定表格改成推导工作表

- §1 功能与困境（问「什么困境消失了」，不是重复功能名）
- §2 **推域表**：一行一个域，列是「管什么（带反例）/ 不管什么 / 删掉它会怎么坏 / 入口文档」，行数自定
- §3 域之间的关系（串 / 并 / 汇）
- §4 **引导记录 + 兜底记录**（我问的 / 他答的 / 哪条是猜的、按谁的做法、代价、他能否决）
- §5 不做 · §6 未知项（必须写「怎么验」）· §7 六条纪律 · §8 状态表

### Changed — `gate.sh --charter` / `--board` 只查结构

| 0.8.0（形态） | 0.8.1（结构） |
|---|---|
| `grep 九域` | 表格**空格率 ≤60%**，且**至少一行被填满**（表头不算） |
| `grep 域表` | 声明了 `.md` 路径，且**这些路径真实存在** |
| `grepE '串\|并\|汇'` | 删掉 |
| `grep 定稿` | 有边界（不做/不管/不在范围）+ 有未知项 + 未知项写了「怎么验」 |
| `grep D1 && D6` | 无补丁段（原写…现改为… / 补记 / 修订记录） |

`--board` 同理：表填满 ≥2 片 / 有反证 / 有依赖 / 无占位。**四列、九段这些词从 gate 里消失。**

两处真修（都是自己先踩到了）：

* **表头不算「填满的行」**：遇到分隔行要撤掉上一行的计数，否则「表头填满」会被当成「一个域填满了」。
* **纪律行不算补丁段**：`D1 … 禁止「原写…现改为…」` 里的引内容是**引用禁令**，必须排除，
  否则纪律本身会被判违规。

### Added — 规则 C13–C15，失败 ⑨

```
C13 域是推出来的，不是列出来的。说不出「删掉它会怎么坏」的不是域。
C14 判据里不许出现某个项目的词汇；写进去，它就只对一个项目有效。
C15 用户说不清 ⇒ 先改问法；还说不清 ⇒ 查行业（谁这么做 / 为什么 / 代价）。

⑨ 抄某个项目的形态当规范：九个域、七段、四列 —— 换个项目全废，还会逼着人硬凑。
```

### Added — `verify.sh` 第 11 节：形态无关性回归

这一节是这一版的核心资产：它**用机器判住了「下次还会不会犯同一个错」**。

```
a) gate.sh 里不许出现 九域 / 域表 / 定稿 / 串|并|汇
b) 一个「三个域」的合成项目必须 PASS（判据没有被焊死在一个项目上）
c) 把模板原样抄过去、一格不填，必须 BLOCK（判据不是只查标题）
```

### 结果核对（两个方向都测过）

```
三域合成项目（虚构）      → PASS    ← 换项目形态照样过
未填的立项书模板          → BLOCK   ← 抄模板不填过不去
DSJY 真实 docs（九个域）  → 表 9 行全满 / 23 个文档都在 / 有边界
                            BLOCK：一条未知项都没有（它的立项书确实缺这一节）
```

**最后那条 BLOCK 是这一版最想要的输出**：它不是「形态不对」，是**真缺**——
一份没有未知项的立项书等于声明「我全都知道」，而那句通常就是盲区所在。

---

## 0.8.0 — 2026-11-18

**Three holes, all found in one real project (a high-order hypergraph memory
store, 71 turns, 30 task sheets, 1,026 tool calls).**

The session's own words are the evidence:

```
用户：不要写这种东西，有个屁用。
用户：你不要去对代码，对旧的，和新的设计稿，总稿，立项书等等。以我当前的话为基准，
      将矛盾的原话全部拉出来逐行比对。
用户：我认为这样的架构涵盖了很大一片了。
用户：最小可跑是跨步处理……而不是用 cli 测试所谓的通过算通过。
```

Three failures sat in those four lines, and the skill could not see any of them:

1. **认知** — the agent had the conclusions, not the premises. It implemented
   "去重" because the user wrote "超边=节点"; the user's point was that dedup is
   *unnecessary* once that identity is structural. The output was 四不像: every
   rule defensible, none derivable.
2. **立项** — there was no place for the charter to be a *standard*. Documents
   were produced per domain, then each explained itself instead of explaining
   the next one. Contradictions surfaced as prose, not as `exit 1`.
3. **交付** — "tests pass" was repeatedly treated as delivery, and by the end
   the user had to write the rule himself: 不是 cli 通过算通过，是代码和功能要通过.

Three references, three templates, two gate modes, five rules.

### Added — `references/r5-axiom-chain.md` (认知)

**The premise chain**: 锚（原话逐字+出处）→ 拆（A = B / 只有 N 种）→ 推（一步一条
「因此」）→ 落（条文 + 一条可复算判据）. Plus the four rulers every word and
every classification must pass: 反例列 / 穷举 / 同形词分离 / 不需要清单, and the
rule that "不要写这种东西，有个屁用" is a rejection of *form*, not content.

**Why it exists**: a rule that cannot name the sentence it came from is a
component without a system. Nothing in the old skill could detect that.

### Added — `references/r6-project-charter.md` (立项)

**The charter as a standard, not a document.** Seven sections (一句话 / 目标带证据 /
域表 / 依赖顺序串并汇 / 落位表 / 不做 / 裁决点), the nine domains, and the
document constitution: D1 只写当前真相 · D2 插入/替换/删除 · D3 一个概念一处 ·
D4 文件数只减不增 · D5 编号不复用 · D6 完成改状态不重读, with a prefix table, a
single-authority table, and NR1–NR9 all grep-able.

**Why it exists**: 各自解释 ≠ 互相解释. Without D3 the same concept gets two
definitions and the next reader cannot tell which one is live; without D6 every
new agent re-reads finished work.

### Added — `references/r7-slice-board.md` (切片与派活)

**One slice = one function that walks from input to rows and back to meaning.**
Four-column slice table, the four questions each slice must answer, the
anti-shelling probe (delete the cause, the reading must break), the nine-section
task sheet, the falsification requirement (inject → must go red → restore), and
the three things the lead may not delegate: freeze the skeleton, write the
acceptance probes, verify line by line.

**Why it exists**: 30 task sheets were written in that session by hand, each
carrying 写域 / 冻结契约 / 语义编号 / 反证 — and each time they worked, it was
because someone remembered all nine parts.

### Added — `templates/立项书.md` rewritten, `文档宪法.md`, `切片表.md`, `任务书.md`

The old 立项书 template stopped at six items: core question, consumers, criteria,
not-doing, evidence level, unknowns. That is a good **shape**, and it is not a
**standard**: it cannot decide whether a downstream document is lying. §7–§11
were added (域表 / 依赖顺序 / 落位表 / 裁决点 / 状态表) and §0 gained the
one-sentence-with-the-strongest-constraint test.

### Added — `gate.sh --charter` and `gate.sh --board`

Two modes, because these are the two places where a project stops being
verifiable *silently*:

* `--charter` (G9/G10): seven sections present, nine domains named, 串/并/汇
  written, state table has all three values, constitution exists, ruling points
  name their downstream effect, no patch segments (D1).
* `--board` (G11): four columns present, falsification section exists, order
  written on one line, no 待定/待补.

Both are opt-in: a project that predates 0.8.0 keeps passing.

### Rules — C10–C12, G9–G11

```
C10 每条规则都要能指回一句话。指不回 = 四不像的零件。
C11 用户的原话是唯一权威。改写 = 换掉了权威，只剩你的理解。
C12 一个概念只许一处定义；第二处定义 = 下一次必然不同步。

G9  立项书缺域表 / 依赖顺序 / 落位表 / 裁决点，不许开工。
G10 文档里出现补丁段（「原写…现改为…」「补记」），该文档按未完成处理。
G11 派活时写域没写清（哪些能改、哪些不许改），不许发任务。
```

**G8 was also reworded**: 没有反证的判据不算判据（测不出红 = 永远为真）. The old
wording covered the spiral only; falsification is a property of every criterion.

### Changed — 五种最常见的失败 → 八种

Added ⑥ 抄结论代替抄前提 · ⑦ 文档数代替唯一权威 · ⑧ 子代理报告代替验收.
All three produced green tests in the source session.

### Changed — the gate resolves file names instead of demanding them

The source project has `00-立项书-0.0.3.md`, `90-文档纪律与编号规则.md`,
`15-实施切片.md`, `10-范畴表.md` (in subdirectories). A gate that only accepts
`立项书.md` would have reported "does not exist" for documents that exist — the
same false red this repo forbids elsewhere.

`gate.sh` now resolves by keyword, shallow-first (`--charter`, `--board`, and G1):

```
立项书 → 立项书.md，或名字含「立项书」的 .md
宪法   → 文档宪法.md，或名字含「宪法」/「纪律」的 .md
切片   → 切片表.md，或名字含「切片」的 .md
范围   → 顶层 → 一层 → 两层（真实项目的文档按域分目录）
```

And the 域表 check accepts `九域 / 九个域 / 总揽`, because the concept is "the
domain table", not the heading text. Checked against the real project: it passes
G9/G10/G11 and honestly blocks on the five artefacts it never produced
(规划 / 策划 / 集成面 / 验收 / 反合理化).

### Added — `docs/flow-observed.md`

The session read as a flow: six phases, six facts that recur, the exact paragraph
the user re-typed twelve times (his hand-written slice protocol), and the three
things worth building next (`矛盾裁决表` + `--conflicts`; a pre-flight probe
before dispatching a subagent, because four background subagents failed with no
closing message; re-read the authority table after a model switch, because three
switches happened and each time the vocabulary drifted).

---

## 0.7.1 — 2026-11-17

**Trigger vocabulary: six kinds of talk → eight.**

The first six (认知 / 范畴 / 立项 / 规划 / 策划 / 设计) are all *thinking* talk.
There was not a single *doing* trigger. The consequence was exact and bad:

```
"加个接口"        → no match → skill does not load → code written directly
"重构一下"        → no match
"报错了"          → no match
"测试过了，上线吧"  → no match
```

**The two categories most likely to skip the process were the two that could not
trigger it.** Added:

* **工程** — 工程 / 架构 / 模块 / 分层 / 耦合 / 依赖 / 重构 / 技术债 / 跨仓库 / 部署顺序.
  Enters at **step 3 三定 → 5**. Structure talk must land in the three
  definitions, or "we should decouple" is a sentence with no consequence.
* **代码** — 写代码 / 加个接口 / 改一下 / 报错了 / 测试过了 / 好像没问题.
  Enters at **step 3 三定 → 5 → 6**. Action talk must be preceded by 三定 and
  followed by end-to-end.

Also: the 「时间与空间」and「分类与统筹」sections were collapsed into one two-row
"what it can / cannot check" table. Detail already lives in `references/`, so the
only thing removed was the duplication inside `SKILL.md`. 16,711 B → 16,184 B.

**Repository packaging** (same version): this repo. Layout `skills/<name>/`,
two idempotent installers (`install.sh`, `install.ps1`) covering seven agents
plus a generic fallback, `[CC]` marketplace manifest, `scripts/verify.sh` as the
repo's own gate, and CI on three platforms.

The instruction that produced it was 「具备一键安装的能力，放入任何 agent 内」. The
two decisions worth recording:

* **Auto-detect on the parent directory, not the skills directory.** A missing
  `skills/` is the normal state of a fresh install; testing for it would skip
  every agent that has never had a skill.
* **`~/.agents/skills/` is always added.** It costs one directory and it is the
  only target that keeps working for an agent this repo has never heard of.

## 0.7.0 — 2026-11-15

**Time and space, stated as two lines you can check.**

```
时间 = 依赖偏序 ⊑ 执行全序
      AI writes the total order (line by line) and never checks the partial
      order (what must be produced before what is consumed).

空间 = 人造物 → 已声明坐标，且坐标图是 DAG
      AI sees files. It does not see a node's position in a graph.
```

This turned two vague complaints into definitions, and proved the thing that
motivated the whole skill:

```
A test is ONE linear extension of the dependency partial order.
Completion is the WHOLE partial order being covered.
⇒ tests passing does NOT imply the partial order is closed.
```

Added:

* Rules `C7` (范畴 ⊏ 完成), `C8` (tests ≠ completion), `C9` (the method is
  `f(state)`, not a constant — a more specific plan has a shorter shelf life).
* Rule `G7` and a gate: **立项后三定** — placement, dependency order, style.
  Missing any one blocks business code.
* `设计.md §1.5` dependency-order table, whose last column is the whole point:
  *which total order covers this cross-boundary edge*. A row with an empty last
  column is an edge nobody verifies.
* `设计.md §2.2` module dependency direction (read it as a graph; it must be a DAG).
* `设计.md §2.6` style contract, which **must carry numbers** (nesting ≤ 3,
  comment ratio 10–30 %). "Keep it clean" is not a contract.
* **Spiral** and `gate.sh --spiral`: every round must record one fact it did not
  know before. Without that, a spiral degrades into iteration — the same
  self-critique loop whose informational content decays ~55 %.

## 0.6.0 — 2026-11-14

**Classification and coordination: AI has no spatial memory.**

The trigger was a concrete one: writing a throwaway test endpoint required
reading half the repository to work out where it could live, and then it was
dumped wherever looked closest and never removed.

Root cause is not capability but carrier: an agent has the current context and
nothing else. So it applies a **nearest-neighbour rule** — put the new thing
beside the last thing that looked related. Ten of those and the same kind of file
lives in ten places.

The fix is not to make it smarter; it is to give it a **table it can look up**
instead of a location it must infer. Added:

* `templates/设计.md §2.5` placement table (what kind of thing → which directory
  → naming → lifetime), with four rules, the fourth being *a missing row means
  the table is incomplete: fill the table, do not dump the file*.
* `scripts/arch-check.sh` — A1 table exists, A2 every row has a location and a
  TTL, A3 every code file maps to some row.
* `gate.sh --arch` (G6).
* An explicit, non-hedged limit: the skill can require the table and check the
  result; it cannot invent a new category, name it, remember last week's
  location, or clean up after itself. Those need a host with cross-session state.

## 0.5.0 — 2026-11-13

**One file → a dispatch layer plus discrete references.**

The entry file had reached 17,607 B of a 20,000 B hard limit. Compressing it
would have cost exactly the thing worth keeping — the criteria and the
counter-examples — so nothing was compressed. Content was **moved**:

```
before   SKILL.md 17,607 B (88 %) + references 23 + templates 8    ≈ 190 KB
after    SKILL.md  9,276 B (46 %) + references 25 + templates 13   ≈ 204 KB
```

**Half the entry file, fourteen kilobytes more total content.** `SKILL.md` was
reduced to three jobs: decide whether to enter, decide which step, point at the
one reference needed. Everything else loads on demand.

Also renumbered the steps 0–7 plus one loop, because 「认知补给」had been
numbered as a linear stop when it is actually the loop between design and
category: design exposes a gap → go learn → settle it as a category → come back
and change the design.

## 0.4.0 — 2026-11-13

**Two skills merged into one.**

Trigger overlap was the forcing reason: both descriptions claimed "规划", so the
host could not tell which to load. But the deeper reason is that the order they
enforce was always a single chain — think first, then start; integration surface
before business code.

The nine steps are the merge:

```
0 应然形态 → 1 规划 → 2 策划 → 3 设计 → ↻ 认知补给 ⇄ 4 范畴 → 5 集成面 → 6 验收 → 7 反合理化
```

`system-project-init` was archived, not deleted, so the merge is auditable.

## 0.3.0 and earlier — pre-merge

Two skills, five artefacts each, and a gate that only checked three of them.
Building the gate against a real cross-repository bug is what produced the
7-line integration surface and the "every probe is a command" rule: the first
version of the table let the model add and remove rows, which meant a row it
had not thought of could simply be deleted, and the report came back green —
exactly the same failure as "the tests pass".
