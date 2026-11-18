# engineering-method

> **一个拒绝把「测试通过」当成「能用」的 agent skill。**

[![CI](https://github.com/butianque/engineering-method/actions/workflows/ci.yml/badge.svg)](https://github.com/butianque/engineering-method/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-black.svg)](LICENSE)
[![Skill version](https://img.shields.io/badge/skill-0.7.1-informational)](CHANGELOG.md)

**English → [README.md](README.md)**

---

## 它解决什么

AI 交付一个改动。能编译，测试全绿，它说**完成了**。

然后你一用，发现这个功能只是整条链上的一小块，其余部分从来没被建过。

**这不是能力问题，是「什么被检查了」的问题：**

```
测试只能断言「已经写出来的代码」的行为。
不存在的东西不产生红色。
⇒ 「测试全绿」不蕴含「系统可用」。
```

由此有三个失效模式，靠「仔细点」一个都修不好：

| # | 失效 | 为什么审查看不出来 |
|---|---|---|
| **F1** | 缺的东西是**缺席**，没代码、没测试、没红色 | 没有东西可看 |
| **F2** | 检查器由被检查的东西自己写 | 自证 |
| **F3** | 每一块局部都对，链没接上 | 逐文件推理看不见边 |

## 它做什么

把上面三条变成**机器可判的产物**，然后对产物设门禁。

```
拿到一个请求，先回答：它应该长什么样，我才能完成它？
答不出来，后面全是瞎写。
```

八个入口，一条链：

```
0 应然形态 → 1 规划 → 2 策划 → 3 设计(三定) → ↻ 认知补给 ⇄ 4 范畴
                                                    ↓
                                      5 集成面 → 6 验收 → 7 反合理化
```

产物是八个文件，`gate.sh` 不齐不放行：

| 产物 | 它证明什么 |
|---|---|
| `立项书.md` | 请求被还原成**形态**，不是功能清单 |
| `规划.md` | 每阶段都有能跑的退出判据 |
| `策划.md` | 至少两个方案，每个都写「什么情况下它是错的」 |
| `设计.md` | **三定**：依赖序 / 模块依赖方向 / 风格契约 |
| `范畴表.md` | 术语、不变量、归属边界 |
| `集成面.md` | 7 行骨架，每行都由一条**命令**支撑 |
| `验收.sh` | L1 语法 → L2 单测 → **L3 从真实入口端到端** |
| `反合理化表.md` | 借口→现实，每条都有具名后果 |

配套三份（0.8.0 起，`--charter` / `--board` 查）：`文档宪法.md`（改法·编号·唯一权威）、`切片表.md`（一片一条端到端）、`任务书.md`（派给子代理的九段）。

## 三个值得抄走的判断

### 1. 域是推出来的，不是列出来的

```
域 = 范畴 =「要让这件事成立，必须存在的一类东西」
数量与名字由这个功能推出，不由模板给出
判据：删掉它，系统会以什么方式坏？说不出 ⇒ 它是细节，不是域
```

推导顺序不许换：**推（功能→困境→必须有哪几类东西）→ 划界（管什么/不管什么/怎么算过）→ 引导（把要求从用户嘴里提出来）→ 兜底（他说不清就问行业：谁这么做/为什么/代价）→ 落实（不打补丁）**。

推的过程中**用户通常只说一半**，所以「引导」是立项的一部分，不是沟通技巧：
只问可判的选择、给行业默认让他否决、反推不做会怎样、一次只问一个并立刻落条文。
**判据：每个问题都要能答成一句可判的话；答不成 ⇒ 问法错了，不是用户不清。**

这条也约束判据本身：**`--charter` 只查结构（表填满没 / 路径通不通 / 有边界没 / 有未知项没），不查「是不是九个域」。** 把某个项目的词汇写进判据，判据就只对一个项目有效 —— `scripts/verify.sh` 第 11 节专门盯这一条。


### 2. 测试通过，只是依赖偏序的一条线性扩展

```
时间 = 依赖偏序 ⊑ 执行全序
      AI 只写全序（一行一行往下），从不校验偏序（谁先产生、谁后消费）。

空间 = 人造物 → 已声明坐标，且坐标图是 DAG
      AI 只看见「文件」，不看见「节点在图里的位置」。
```

测试是依赖偏序的**一条**线性扩展；完成是**整个**偏序被覆盖。
这就是为什么「测试全绿」和「系统坏着」能同时成立，也是为什么解药是：
**把每一条跨界的边写下来，给每条边配一条覆盖它的命令。**

### 3. 你没法告诉 AI 它缺什么，但可以让它看见天塌了

```
你没法告诉 AI 它缺什么。
但你可以让它看见：拆掉这个，天塌了。
```

缺席的东西是看不见的，**断裂**不是。`gate.sh` 把「我觉得做完了」变成 `exit 1`。

## 安装

一条命令。自动探测你已装的 agent，逐个装进去。

**macOS / Linux / WSL / Git Bash**

```bash
curl -fsSL https://raw.githubusercontent.com/butianque/engineering-method/main/install.sh | bash
```

**Windows（PowerShell 5.1+ / 7+）**

```powershell
irm https://raw.githubusercontent.com/butianque/engineering-method/main/install.ps1 | iex
```

**从 clone 装**

```bash
git clone https://github.com/butianque/engineering-method.git
cd engineering-method
bash install.sh            # 或  pwsh -File install.ps1
```

### 参数

| 参数（bash / pwsh） | 作用 |
|---|---|
| `--agent <list>` / `-Agent` | `claude,dsh,opencode,cursor,codex,gemini,agents`，默认自动探测 |
| `--all` / `-All` | 所有支持的 agent（即使没探测到） |
| `--project` / `-Project` | 装到 `./.claude/skills` 等，而不是 `$HOME` |
| `--dir <p>` / `-Dir` | 精确装到 `<p>`（装完 `<p>` 里就是 `SKILL.md`） |
| `--skills-dir <p>` / `-SkillsDir` | 装到 `<p>/engineering-method` |
| `--force` / `-Force` | 已是最新也重装 |
| `--dry-run` / `-DryRun` | 只打印计划，不动文件 |
| `--uninstall` / `-Uninstall` | 从同样的目标里删掉 |
| `--no-generic` / `-NoGeneric` | 跳过 `~/.agents/skills` 这个通用兜底 |

两个安装器都是**幂等**的（树哈希相同就跳过），而且**跨平台一致**（bash 装的，PowerShell 认作最新）。

**手动安装** —— 把 `skills/engineering-method/` 复制进你的 agent skills 目录。完整路径表见 [docs/agent-directories.md](docs/agent-directories.md)。

**如果 `raw.githubusercontent.com` 被墙**（常见于 `github.com` 还能通、raw CDN 被重置的网络），上面那条一行命令根本跑不起来。三条不碰该域名的路子见 [docs/install.md](docs/install.md#when-rawgithubusercontentcom-is-unreachable)。

## 怎么用

不用主动调用。它在**八类话语**上触发，中英都行：

| | 触发短语 | 入口 |
|---|---|---|
| 认知 | 「认知不对」「没有这层认知」「做出来四不像」 | ↻ 补给 → 公理链 |
| 范畴 | 「定个范畴」「术语不统一」「边界在哪」 | 步 4 |
| 立项 | 「立项」「要不要做」「从哪开始」「立项即标准」 | 步 0 |
| 规划 | 「规划」「分几步」「里程碑」 | 步 1 |
| 策划 | 「策划」「方案」「怎么落地」 | 步 2 |
| 设计 | 「设计」「它应该长什么样」「部件怎么接」 | 步 3 |
| **工程** | 「工程」「架构」「模块」「分层」「耦合」「依赖」「重构」「技术债」「跨仓库」 | **步 3 三定 → 5** |
| **代码** | 「写代码」「加个接口」「改一下」「报错了」「测试过了」「好像没问题」 | **步 3 三定 → 5 → 6** |

**最后两类才是重点**：最容易跳过流程的话，正好被接到最硬的关卡上。

## 机器判据

提示词那一半只提高概率，`scripts/gate.sh` 保下限。

```bash
SK=~/.dsh/skills/engineering-method        # 或 ~/.claude/skills/… 、~/.config/opencode/skills/…

bash $SK/scripts/gate.sh <项目>                # 八件齐 + G7 三定
bash $SK/scripts/gate.sh <项目> --steps 3      # 只查设计（G4 签收 + G7 三定）
bash $SK/scripts/gate.sh <项目> --arch         # 加 分类与落位（G6）
bash $SK/scripts/gate.sh <项目> --done         # 加 验收必须退出码 0（G3）
bash $SK/scripts/gate.sh <项目> --spiral       # 加 每轮必须有新事实（G8）
bash $SK/scripts/gate.sh <项目> --charter      # 加 立项是基准（G9 / G10）
bash $SK/scripts/gate.sh <项目> --board        # 加 切片可派（G11）
```

退出码：`0` 通过 · `1` 拦住 · `2` 用法错。**只读，绝不改任何文件。**

| Gate | 拦什么 |
|---|---|
| G1 | 任一产物缺失或为空 |
| G2 | `集成面.md` 还有「不存在」，或探针列为空 |
| G3 | `验收.sh` 退出码非 0 |
| G4 | 系统设计未签收 |
| G5 | （纪律）探针红了却想改探针 —— 先问第二个 AI |
| G6 | 有文件映射不到任何已声明位置 |
| **G7** | **三定不齐：没有依赖序表 / 没有模块依赖方向 / 风格里有不可测词** |
| **G8** | **某一轮螺旋没有产出新事实；或某条判据没有反证** |
| **G9** | **立项不可判：表没填满 / 声明的文档不存在 / 没有边界 / 没有未知项或没写怎么验** |
| **G10** | **文档里出现补丁段（「原写…现改为…」「补记」）—— D1 禁止** |
| **G11** | **切片率不清：表没填满 / 没有反证 / 没有依赖 / 还有占位** |

## 目录

```
engineering-method/
├── skills/engineering-method/       skill 本体
│   ├── SKILL.md                     20 KB 入口：C/G 铁律、8 个入口、9 步、路由表
│   ├── references/                  30 份，按需加载
│   ├── templates/                   16 份：立项书 / 规划 / 策划 / 设计 / 范畴表 / 集成面 /
│   │                                            验收.sh / 反合理化表 / 文档宪法 / 切片表 / 任务书
│   └── scripts/
│       ├── gate.sh                  机器判据
│       └── arch-check.sh            落位与边界检查
├── install.sh  install.ps1          一键安装
├── .claude-plugin/                  Claude Code 插件与市集清单
├── docs/                            安装 / 各 agent 路径 / 为什么
└── scripts/verify.sh                CI 跑的东西
```

`SKILL.md` 是**分发层**，不是手册：它判「要不要进门」「进哪一步」，然后指向你需要的那一份。其余按需加载，所以入口文件能稳定在 16 KB，不会被截断。

## 诚实边界

这个 skill 覆盖**会断裂的缺失**。它不覆盖：

| 类 | 为什么 | 需要什么 |
|---|---|---|
| 不报错但结果错（200 但数据错） | 什么都不红 | oracle：人 / 参考实现 / 形式规范 |
| 连「错了」都不知道 | 不在你的词表里 | 撞现实 / 人说 / 读别人的失败分类 |

而且 skill 是**无状态**的。它记不住你上周那个临时脚本放在哪 —— 那需要宿主有跨会话状态。降级方案是**落位表**：用文件代替记忆。

```
能做的：要求有落位表 / 检查新文件落在已声明位置 / 检查 TTL / 检查越界 / 检查三定
做不到：发现"这里需要新类" / 命名 / 跨会话记住上次在哪 / 主动清理 / 实时提醒
```

## 它真的有用吗

这道门是对着真实故障建的，不是假设。一个例子：

```
一次会话修复，跨 2 个仓库、9 处。
只改第 1 处  →  go test ./internal/api/handlers/management/  →  ok  20.3s
用户实际体验  →  仍然被踢下线
```

`gate.sh` 报的是：

```
BLOCK  G2 集成面里还有 7 处「不存在」—— 这些就是待做的
       14:| 5 | 失败路径 | ... | 不存在 |
       18:| 9 | 下游改动（面板） | ... | 不存在 |
```

Go 测试看不见面板那个仓库。门禁能看见，因为那条依赖边被写下来了。

## 文档

| | |
|---|---|
| [docs/install.md](docs/install.md) | 全部安装路径、验证、卸载 |
| [docs/agent-directories.md](docs/agent-directories.md) | 各 agent 的 skill 目录表 + 手动安装 |
| [docs/why.md](docs/why.md) | 为什么公式形状的约束比散文强，以及边界在哪 |
| [docs/flow-observed.md](docs/flow-observed.md) | 一次真实会话（71 轮）里跑出来的流程，以及 0.8.0 三处改动是从哪条故障长出来的 |
| [CHANGELOG.md](CHANGELOG.md) | 改了什么，以及每个改动为什么存在 |

## 许可

MIT —— 见 [LICENSE](LICENSE)。
