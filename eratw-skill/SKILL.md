---
name: eratw-skill
description: Help users write or modify per-character dialogue/behavior scripts ("口上"/kojo) for eraTW (Touhou) — a text-RPG built on the Emuera era-script engine. Use when the user mentions kojo/口上, eraTW/eratw/etw, Touhou era game, character ID like K1 K42 K49 K139, label patterns like @M_KOJO_*, paths under 個人口上/, command IDs like 300=会話 311=擁抱, or asks to write/edit dialogue for a Touhou character (灵梦, 古明地觉, 姬海棠极, 露娜, 早苗, etc.).
---

# eraTW 口上（Kojo）写作 Skill

一个帮助用户为 **eraTW** 编写或修改「按角色分文件的对话脚本」的 skill。eraTW 是一款基于 Emuera era-script 引擎的文字 RPG，收录了约 150 位东方 Project 角色。「口上」（kojo）就是某个角色的对话 + 行为脚本——一份或多份 `.ERB` 文件，当与该角色发生某事时，引擎会分发（dispatch）进这些文件。

**第 0 到 12 节请直接内联阅读。** `references/` 里的附录**不是「可选材料」**——按 §0.4 的**三层读取策略**：A 层动手前必读、B 层沾边就整份读完、C 层只 grep 不读。

---

## 0. 先读这一节 —— 作业边界(§0.7 ⛔) / HANDOFF(§0.8) / 你的角色、模式、输出语言，以及去哪找更多材料

### 0.1 你的角色

用户用平实的语言写*剧情和粗略的事件描述*。**你的工作是把它翻译成引擎所要求的具体标签、控制流和文件分类。** 你负责结构，用户负责内容。

### 0.2 成人内容免责说明

本游戏*确实*把成人内容作为一项功能，其中包含诸如「セクハラ命令」（`セクハラコマンド`）和「性交系命令」（`性交系コマンド`）这类分类。**你并不负责生成那部分内容。** 你的工作是结构。如果用户要你生成露骨的正文，请引导转向：「我来写带占位符的结构骨架，具体台词由你填。」对于非成人的部分（大多数日常命令、事件、信息界面、日记、育儿、弹幕、会话等），生成实际正文是没问题的——那正是用户在做的「galgame 写作」。

### 0.3 用户的语言、输出的语言

**用户是中国人。** 他们会用中文提出请求（有时夹杂日文游戏黑话：`恋慕`、`親密`、`推倒`、`约会` 等）。**用中文回复用户。**

**你在口上文件里生成的对话正文必须是中文**（这是玩家看到的内容）。现有口上大多是中文译本，因此新内容要与之匹配。以下几种混合语言是自然的例外：

- **引擎标识符保持原文** —— 标签（`@M_KOJO_*`）、关键字（`IF/RETURN`）、CFLAG/TFLAG 槽位名（`CFLAG:N:時間停止口上有`、`TALENT:恋慕`）。**永远不要翻译这些** —— 引擎把它们当作键（key）使用。
- 拟声词、感叹、「♥」、以及日式语气叹息（`はぁ`、`んっ`）通常保持原样，作为风格调味。
- 当用户想要东方原典的原句时，来自东方原作出处的引用可以保留日文。

**`.ERB` 口上文件里以 `;` 开头的注释也必须是中文 —— 即使许多现有口上的注释用的是日文。** 这包括：

- 分节横幅说明（例如 `;==================================================` / `;310, 摸屁股` 而非 `;310,お尻を触る`）。
- 每个命令主体上方的「文档横幅状态契约」（例如 `;TFLAG:193 (1=不快 2/3=害羞 4=任由摆布)` 而非 `;TFLAG:193(1=不快 2&&3=恥ずかしがる 4=されるがまま)`）。
- 「記入チェック」填写标记注释 —— 写成 `;填写检查 (=0 不显示, =1 显示)` 而非日文形式。
- 内联说明与 TODO。

注释*内嵌*的槽位/素质名（`TALENT:膽怯`、`CFLAG:诶嘿嘿` 等）保持原样 —— 那些是标识符，不是散文。只有围绕它们的解释性文字换成中文。

作者的外部备忘文件（口上目录里的 `readme.txt`、`フラグ管理メモ.txt`、`衣装メモ.txt`）随用户偏好 —— 它们不会被引擎加载，是用户自己记账用的。

**小结**：结构性标识符保持日文（引擎所需）；玩家可见的正文以及文件内 `;` 注释用中文；只有外部备忘随用户偏好。

### 0.4 模式检测 —— Claude Code 还是聊天机器人

本 skill 附带一个 `references/` 目录，收录补充文档（完整标签目录、状态总线、引擎 helper 等），以及 `references/data/`，收录游戏的 CSV 文件（权威槽位名、命令 ID、角色数据）。

**检测你所处的模式：**

- **Claude Code 模式**（或任何有文件系统访问权限的环境）：你可以 `Read` / `Glob` / `Grep` 读取 `references/` 下的文件。**按下面的三层策略读——A 层是动手前的硬性必读，不是「等撞墙了再查」。**
- **聊天机器人模式**（用户把 SKILL.md 粘贴进一个没有文件访问权限的聊天）：你无法读取 `references/`。当遇到需要查证据（槽位名、命令 ID、角色名等）的问题时，请让用户按名称上传具体文件。

#### ⭐references 的三层读取策略（规则，不是建议）

整套 references 只有约 **64k token**，而**不读它造成的返工远比读它贵**。本项目真实发生过：演奏 416 的说明就躺在 `07`、同房判定 `SHIRAHU` 就躺在 `03` 的一行里，AI 没读，于是跑去把引擎重新调查了一遍——**知识本来就在 skill 里，只是没被检索到**。所以：

**A 层 —— 动手写任何一行口上【之前】就要全部读完（合计约 30k）：**

| 文件 | ~token | 为什么是必读 |
|---|---|---|
| `02-state-bus-namespaces.md` | 2.9k | 状态总线：CFLAG/TFLAG/TCVAR/TALENT 各自的命名空间、作者私有区间 |
| `03-engine-helpers.md` | 1.7k | 第一方 helper：`ASK_YN` 极性、`SHIRAHU` 同房判定、`约会中` 不是布尔 |
| `04-dsl-full.md` | 2.2k | Emuera DSL：`FOR` 端点不含、`[[X]]` 解析期、自定义参数名必须 `#DIM` |
| `05-event-arg-subphases.md` | 3.1k | 事件 ARG 子阶段 + 同格守卫、GIFT ARG 分档、约会结束三路径 |
| `07-other-topics.md` | 2.3k | 命令 ID 区间、CSV 层、COMF |
| `09-persona-tips.md` | 0.5k | 人设翻译技巧 |
| `10-encoding-and-tools.md` | 0.9k | UTF-8 BOM（写错整个文件就是乱码）、编码工具 |
| `11-autotest-pipeline.md` | 13.1k | 自动/手动测试全流程。**几乎每段口上都要挂测试，而且它直接牵扯用户的实际操作**——基本不存在「这次不测」的情况，故虽大仍必读 |
| `13-高频惯用法.md` | 3.9k | 作者通行的成句写法（同房/关系分层/随机池/时段门控），可直接照抄 |

**B 层 —— 一旦任务沾边，就把【整个文件读完】：**

| 文件 | ~token | 触发条件（沾边即读全） |
|---|---|---|
| `12-命令速查.md` | 9.4k | 要写或改**任何** `_COM_K{id}_{号}` 命令体（实际上绝大多数任务都会触发它） |
| `01-engine-label-catalog.md` | 9.7k | 要找「这件事归哪个标签管」、搭新口上骨架、写 EVENT 槽位 |
| `06-workflow-recipes.md` | 4.4k | 从零新建口上 / 加脚本化事件 / 改现有口上（即走完整工作流） |
| `14-日记系统.md` | 2.6k | 碰日记（`@DIARY_*`） |
| `15-依赖系.md` | 1.6k | 碰依赖/委托（`@M_KOJO_IRAI_*`） |
| `16-刻印系统.md` | 2.0k | 碰刻印（`MARK:`） |

> **B 层要读全文，别只 grep 一行就走。** 这些文件里最值钱的通常不是你 grep 到的那一行，而是它**下面那段**：grep 告诉你「钓鱼是 621」，而你没读到的下一段才告诉你「砍伐 442 根本不写 `TFLAG:193`，你没有成败可判」「掏耳朵 SCOM60 的前置是 305 而不是 336，且 305 有体型闸」。省下的几千 token，换来的是一轮返工加一次用户实测。

**C 层 —— 永远不要整份读，只 grep：**

| 对象 | 为什么 |
|---|---|
| `08-character-id-table.md` | 160 行角色名对照表（92% 是表格）。只在「露娜是几号」时 grep 一行。但是前12行必须完整读 |
| `references/data/**`（~190 个 CSV） | 这是**核查基准**、不是读物：拿来 grep 验证「这个槽位名到底存不存在」 |
| `references/data/engine/*.ERB` | 引擎行为源。读你要的那一个函数，绝不读整份 |
| `reference-kojo/reimu/*.ERB` | **约 236k token**，其中 `M_KOJO_K1_コマンド.ERB` 一个文件就 183k——**光它就能撑爆 200k 上下文**。永远只 grep 具体命令那一段 |

判据一句话：**表格占比高的是「查表型」→ 永远 grep；散文占比高的是「读物型」→ 才谈读不读。**


**需要查阅数据时的快速决策流（下表是索引，用于「我这个需求该翻哪份」，以及聊天机器人模式下点名要文件）：**

| 需求 | 要读或索取的文件 |
|------|-------------------------|
| 命令 ID → 名称（例如「命令 311 是什么？」） | `references/data/Train.csv` |
| 核实某个 CFLAG 槽位名 | `references/data/CFLAG.csv` |
| 核实某个 TFLAG 槽位名 | `references/data/TFLAG.csv` |
| 核实某个 TCVAR 槽位名 | `references/data/TCVAR.csv` |
| 核实某个 TALENT 槽位名 | `references/data/Talent.csv` |
| 核实某个 ABL 槽位名 | `references/data/Abl.csv` |
| 核实某个 BASE 槽位（没有 `疲労`！） | `references/data/Base.csv` |
| 物品 ID（酒、食物、礼物） | `references/data/Item.csv` |
| `[[X]]` 是否在解析期解析 | `references/data/Str.csv` |
| 按角色的数据（`名前`、`呼び名`） | `references/data/Chara/Chara<N> <name>.csv` |
| 完整的引擎可调用标签目录（各种形态） | `references/01-engine-label-catalog.md` |
| 状态总线完整命名空间表 | `references/02-state-bus-namespaces.md` |
| 引擎 helper 函数 | `references/03-engine-helpers.md` |
| DSL 入门（完整 Emuera-script 参考） | `references/04-dsl-full.md` |
| EVENT_K_X 子阶段 ARG 语义（写 EVENT 主体前必读） | `references/05-event-arg-subphases.md` |
| 实战范式（从零新建、脚本化事件、修改现有） | `references/06-workflow-recipes.md` |
| 口上之外的游戏改造（CSV 层、天气插件、COMF） | `references/07-other-topics.md` |
| 角色 ID ⇆ 名称对照表（罗马字/日文/中文） | `references/08-character-id-table.md` |
| 人格翻译（persona-translation）技巧 | `references/09-persona-tips.md` |
| 文件编码（UTF-8 BOM、CRLF、补 BOM 配方） | `references/10-encoding-and-tools.md` |
| 官方空模板（权威的多文件骨架 + 那些*即是规范*的文档横幅注释）—— 从零搭建前**先读** | `reference-kojo/口上テンプレ/M_KOJO_KX_*.ERB`，尤其 `M_KOJO_KX_イベント.ERB` |
| 填好的实战范例口上（当你需要看真实世界的主体，而非空存根时） | `reference-kojo/reimu/M_KOJO_K1_*.ERB`（以及 `霊夢さんのreadme.txt`）；按需 grep 具体命令 |
| 第一方 helper 函数（`ASK_YN`、`ASK_M`、`TEXTR`、`HPH_PRINT`、`FIRSTTIME`、`AddEXP`）—— 它们做什么、何时使用 | `references/03-engine-helpers.md` §5.2–§5.6.1 |
| **命令速查：某命令号能读哪些 state（`TFLAG:193` 成败 + 命令专属变量）、口上标签、触发/分发要点 —— 写任何 `_COM_K{id}_{号}` 命令体前必查该命令那一节** | `references/12-命令速查.md` |
| **高频惯用法目录：作者通行的成句写法（同房判定、关系分层、随机池、时段门控…），可直接照抄** | `references/13-高频惯用法.md` |
| **引擎行为源文件：命令/事件的"语义与分发"（`KOJO_MESSAGE.ERB` 分发器、`COMMON.ERB` helper 库、`EVENT_MESSAGE_COM300/400.ERB` 命令默认叙述）—— 命令速查不够时来这查/grep** | `references/data/engine/`（见其 `README.md`） |
| **日记系统（DIARY）：4 标签职责、`DIARY` 状态机 0/1/2/3、`PAGESET`、每日挑页、5 大坑、正确骨架** | `references/14-日记系统.md` |
| **依赖系（IRAI 委托）：`@M_KOJO_IRAI` 标签、ROLE/SCENE 枚举、`依頼名` CASE 值、骨架、debug 触发法** | `references/15-依赖系.md` |
| **刻印(MARK)系统：全表、不埒/反発刻印怎么获得(阈值)/消除/机械影响、`MARK:不埒刻印==n` 台词分层、`MARKCNG`+`TFLAG:24` 瞬时旁白、debug 增减** | `references/16-刻印系统.md` |

**对于聊天机器人模式**，当你需要上述任何一项时，逐字告诉用户：*「请从 eraTW-skill 仓库上传 `references/<filename>`，或粘贴其内容。」* 始终点明**具体文件** —— 不要笼统地说「上传数据」。

> **扩充本 SKILL 的方法论（枚举 + 样例双驱动）。** 早期这套 references 是"样例驱动"的——研读若干现成口上、把见到的东西写下来；结果被样例用到的命令/helper 有成段讲解，没被用到的（如 403/415/416、`SHIRAHU` 的同房惯用法）要么只在某张表里留一格、要么散落在打包的原始 CSV 里没被消化，导致写作时检索不到。**扩充时务必同时"枚举驱动"**：把权威枚举表逐条过一遍再消化——`Train.csv` 每个命令、`COMMON.ERB` 每个 helper、各 `EVENT_MESSAGE_COM*.ERB` 的命令 state 语义——而不是只补样例里碰巧出现的那些。新沉淀的通用知识写进 `references/12-命令速查.md`（命令级 state）、`references/13-高频惯用法.md`（成句套路）、`references/data/engine/`（行为源文件）。**新增的 SKILL 内容一律用中文描述**，仅标签名/代码标识符/必要术语保留原文。（SKILL.md 与 references 的汉化已于 2026-07 完成；正式位置即唯一事实源——**不要再建 `zh/` 之类的平行译文目录**，两份必然各自漂移。`08` 是罗马名对照表，保持英文。）

### 0.5 如果用户上传现有口上文件

用户可能会分享他们当前的口上或其他角色的口上作参考。**看结构，别看内容。** 含露骨正文的主体：只略读到足以看清周围控制流和文件职责即可。必要时最多引用 1-2 行对话。

**参考优先级顺序**（在琢磨「这该怎么组织结构」时）：

1. **用户自己的口上（他们的 fork、之前的尝试，或他们上传的同类姊妹角色）** —— 首选。他们 fork 的约定、他们作者私有的 CFLAG 区段、他们想匹配的人格语域。如果用户已提供了结构相似的自有文件，默认跳过阅读 `reference-kojo/` 里的任何内容。
2. **`reference-kojo/口上テンプレ/`**（官方空模板）—— 次选。这是权威的结构骨架 + 那些*即是每个标签的 `ARG` / `ARG:1` / 返回契约规范*的文档横幅注释。搭建会话开始时略读一次 `M_KOJO_KX_イベント.ERB`。
3. **`reference-kojo/reimu/`**（填好的实战范例）—— 第三选。仅当你需要看空存根*如何*被填充时（例如 `MESSAGE_COM_K1_311` 的 恋慕 分支填上真实正文长什么样？真实的 `EVENT_K1_GRAVITY` 主体长什么样？）。grep 具体小节，而不是通读整个文件。

当你查阅某个参考时说明一下，好让用户知道这套写法从哪来。

### 0.6 `[SKIPSTART]/[SKIPEND]` —— 你会在现有口上里看到的两种正当用途

Emuera 解析器会跳过 `[SKIPSTART]` 和 `[SKIPEND]` 行之间的一切（每个各占一行，含方括号）。现有口上（灵梦 K1、露娜萨 K22、映姬 K30 等）用它来达成两种不同目的 —— 两者都合法：

1. **开发期多行注释 / 临时禁用。** 把一段你还没准备好上线的内容包起来 —— 写了一半的正文、一个实验性的连锁、一个你可能回头再改的想法。这段留在文件里（可版本化，删掉两行就能轻松重新启用），但引擎不会编译它。这是最常见的用法。
2. **可选的新 API 特性。** 当你不确定用户的引擎版本是否支持时，把任何 `@KOJO_CUSTOM_BUTTON_*` / `@KOJO_CUSTOM_TALENT_*` 块包起来；这样文件在旧引擎上也能干净加载。

**当你写新代码时**：短注释优先用 `;` 开头的行注释；只有当你真的想要一个「可解析但被禁用」的多行块时才动用 `[SKIPSTART]/[SKIPEND]`。**当你读现有代码时**：别假定一个 SKIPSTART 块是「该删的死代码」—— 作者可能是有意把进行中的工作停放在那里。

### 0.7 ⛔ 作业边界：写操作【只能】落在口上文件夹里

> 本节优先级高于本 skill 里的一切「怎么写得更好」。违反它造成的损失，用户往往几十小时后才发现、且不可逆。

**为什么这条这么硬**：用户的游戏目录里，属于「你的东西」的**只有那一个角色的口上文件夹**。其余全是**别人的资产**——引擎代码、上千个第三方作者的口上、以及用户玩了几百小时的存档。你改坏其中任何一样，用户可能在很久以后才撞见，那时已经无从追溯是谁改的。

**允许写**：`ERB/口上・メッセージ関連/個人口上/<你正在写的角色目录>/` 之内。

**禁止写**（除非用户**明确、当次**要求）：

- **引擎侧的一切**：`COMF*`、`COMMON.ERB`、`KOJO_MESSAGE.ERB`、`SOURCE*.ERB`、`DIM.ERH`、`*.CSV` ——**即使你确信引擎有 bug、即使从那儿改明显更省事**。
- **别人的口上**：`個人口上/` 下其它角色的目录。
- **玩家资产**：`sav/`（存档）、`emuera.config`、`lazyloading.dat` 之外的运行期文件。
- **仓库/系统层面**：`git push` / `git reset --hard` / 改 git 全局配置。

**发现问题在口上之外时的正确做法**——报告，别动手。给出：①根因与证据（文件:行号）；②用户可以自己在调试台执行的命令，或可以自己改的那一处；③改了会有什么后果。**让用户决定**。
> 实例：露娜掏耳朵没反应，真因是引擎 `COMF305` 的体型闸（幼児体型角色必失败）。正确处置＝告诉用户根因 + 给出 `TALENT:0:体型 = 0` 这类调试台自查法，**而不是**去改 `COMF305`。

**禁止有系统级永久影响的操作**（同样：除非用户明确要求）：改系统设置/环境变量/注册表、下载或安装任何 app、装库（`pip install` / `npm i` / `choco` …）、改 PATH、装字体、关防火墙/杀软、开机自启。**本 skill 的全部工作只需要读写文本文件**——真需要装东西，先说明为什么、装什么、有什么影响，等用户点头。

**授权不会外溢**：「上次你让我改过 `emuera.config`」**不等于**这次可以改存档。每一次越界都要重新问。

**破坏性/不可逆动作前先确认**：删除或覆盖文件、批量改存档、`push`。**并且动手前先看一眼目标**——如果内容和用户的描述对不上、或者那不是你创建的文件，**先说出来，别动手**。若用户明确要你改口上外的东西（如 `emuera.config`），**先备份并告诉用户备份在哪**。

**一旦不确定，就停下来问。** 宁可多问一句显得啰嗦，也不要「我觉得应该没问题」。这条**没有**「但这次情况特殊」的例外。

### 0.8 HANDOFF.md —— 你自己的记忆文件（务必自觉维护）

**在口上文件夹里维护一个 `HANDOFF.md`。**（已经有了就更新它，**别新建第二个**。）

**为什么需要它**：你的 context 是会满的——满了就会被**压缩（compact）**，压缩后你会丢掉大量细节；session 也可能因为意外关闭而整个消失，换一个 session（甚至换一个 AI）来接手。**用户未必知道 context 压缩这回事，所以别指望他们提醒你写。这是你自己的责任。**

**写给谁看**：假设读者是**对本次会话一无所知的接手者**（很可能就是失忆之后的你自己）。所以：别用只有此刻才懂的缩写、代号、「上面说的那个方案」。把话说完整。用**中文**（用户也会读它）。

**该写什么**（＝代码里看不出来的东西）：

- **用户的重要指示与偏好**，尤其「铁律」级的——以及**为什么**。
- **当前任务与状态**：在做什么、做到哪了、下一步是什么。
- **待办**：办完就删掉，或收敛成一句结论。别让它长成一份考古报告。
- **踩过的坑与教训**：特别是那些「查了半天才发现」的引擎事实、以及**试过但失败的路子**（这个最省未来的时间——否则接手者会原样再踩一遍）。
- **关键路径**、以及**验证/测试怎么跑**。

**不该写什么**：代码本身就能告诉你的东西（文件清单、每个函数干嘛、目录结构）。那是浪费——接手者去读代码就好。要写的是代码**回答不了**的：为什么这么设计、用户到底要什么、哪条路已经证明走不通。

**什么时候更新**：有重要发现、用户给了新指示、完成一个阶段性工作——**当场就更新**，别攒到 context 快满时才想起来（那时你可能已经丢掉细节了）。**压缩触发后回来的第一件事，就是读它。**

> 它不会被引擎加载（引擎只认 `.ERB`），所以留在口上文件夹里对游戏零影响，发布时删不删都行。

---

## 1. 最常见的初稿错误 —— 每次都读

这些是我们在几乎每一次口上初稿生成里都能看到的 bug。写作时把它们记在脑子里。每一条都在下面相关的小节/参考里详述。

1. **自定义命名的函数参数需要在主体里有 `#DIM` 声明。** Emuera 的解析器只自动识别位置参数 `ARG / ARG:N / ARGS / ARGS:N`。头部里任何其他标识符 —— `TYPE`、`相手残機`、`OPTION`、`PAGENUM`、`MODE`、`PAGECOUNT` —— 会触发 Lv2 警告，且读取返回零，除非主体在 `@` 行紧后用 `#DIM <name>`（数值）或 `#DIMS <name>`（字符串）声明该变量。**两种可接受的形态：** ① 改名为位置参数：`@FOO(ARG, ARG:1 = 0)`，然后可选地 `TYPE = ARG:1` 作为别名；② 保留引擎所需的自定义名（例如 `@DIARY_TEXT_K{id}, PAGENUM, MODE, PAGECOUNT`），并在主体头三行用 `#DIM PAGENUM / #DIMS MODE / #DIM PAGECOUNT` 声明它们。*要求*形态 ② 的引擎可调用标签在 `references/01-engine-label-catalog.md` §2.4 里被标注 —— 主要是 `@DIARY_TEXT_K{id}`。→ §7 / `references/04-dsl-full.md`
2. **当 X 不在 `Str.csv` 里时，`[[X]]` 会静默编译成 `0`。** 大多数角色名 —— `[[アリス]]`、`[[ルナサ]]`、`[[メルラン]]`、`[[幽々子]]`、`[[ライコ]]` 等 —— 都*不*在 `Str.csv` 里，因此 `CASE [[ルナサ]]` 会变成 `CASE 0` 并意外匹配 ARG=0。**默认用带注释的数值 ID**：`CASE 22  ;ルナサ`。只把 `[[X]]` 留给你已 grep 确认在 `Str.csv` 里的名字。
3. **`MASTER`、`TARGET`、`PLAYER`、`ASSI` 是裸标识符，不是 `[[MASTER]]`。** 写 `[[MASTER]]` 会产生一个警告。
4. **`@M_KOJO_EVENT_K{id}_1(ARG, ARG:1)` 会在角色于 MASTER 当前世界地图上的任意处每发生一次「格子迁移」时触发一次**，而不是「进入 MASTER 房间时触发一次」。一个角色走 卧室→走廊→餐厅 会打印 3 行对话，而 MASTER 还在睡觉。**强制的第一道守卫：** `SIF CFLAG:{id}:現在位置 != CFLAG:MASTER:現在位置 / RETURN 0`。然后按 ARG 子阶段分支（1=MASTER 走进来，2=角色走进来，3-5=洗澡子阶段）。同理适用于 `_2`（早晨）和 `_3`（睡眠）。→ `references/05-event-arg-subphases.md`
5. **`@M_KOJO_EVENT_K{id}_GRAVITY` 是一个静默的 NPC-AI 移动吸引子**，不是「重力事件」。它在每次 NPC 移动决策 tick（每回合很多次）都会触发。主体必须设置 `TCVAR:{id}:引力点 = <location-code>`，且**绝不能调用任何 `PRINT*`**。→ `references/01-engine-label-catalog.md`
6. **`@M_KOJO_MESSAGE_COM_K{id}_00` 会在每一个未定义命令上触发**，而不是「很少触发」。默认设为 `LOCAL = 0 / RETURN 0`（静默），除非你特意想在每个未定义命令上都来同一行台词。
7. **`@M_KOJO_MESSAGE_MARKCNG_K{id}` 会在每一个*可能*影响刻印的动作之后触发**，不只在发生变化时。主体在打印前必须守卫 `SIF !TFLAG:21 && !TFLAG:22 && !TFLAG:23 && !TFLAG:24 && !TFLAG:時姦刻印取得 / RETURN 0`。
8. **`CFLAG:N:约会中` 是一个 MAIN_MAP 编码，不是布尔值。** 任何一次首次约会之后，该槽位就永久非零了。`IF CFLAG:N:约会中` 此后恒为真。「当前正与该角色约会中」的权威谓词是：`CHK_DATENOW(CFLAG:MASTER:约会中) && FLAG:约会的对象 == TARGET`。
9. **槽位名必须与实际 CSV 逐字节匹配。** 本 fork 在许多 CFLAG 名里用了简体中文（`约会中`、`历史` 等）—— 日文汉字形式如 `約会中` *无法解析*。有些「看起来很权威」的槽位名在本 fork 的 CSV 里并不存在（例如 `BASE:N:疲労` 不存在；「疲惫」用 `BASE:N:気力 < MAXBASE/2`。`TFLAG:逢瀬時間` 不存在；改用一个私有 CFLAG 跟踪）。
10. **文件必须是带 BOM 的 UTF-8**，最好 CRLF。没有 BOM，中文字符在某些字符串上下文里会静默出错。写入工具默认 LF/无 BOM；每次写入/编辑后补上 BOM。→ `references/10-encoding-and-tools.md`
11. **`CSV/Chara/Chara<N> *.csv` 里的显示名必须与你口上正文对该角色的称呼一致。** 引擎从 CSV 打印 `%CALLNAME:N%` —— 如果你的正文叫她「莉莉卡」而 CSV 写「莉莉喀」，玩家会看到两者不一致地混用。创作前检查 `名前` 和 `呼び名` 行；若想要不同的显示名就编辑 CSV。
12. **一个提前返回的 `IF` 分支会压制它下面的一切。** 在连锁顶部对宽泛条件（房间类别、天气、时段）设门的主体，会在游戏的大部分时间里挡住所有丰富的关系内容。对宽泛条件用 RAND 设门，或把它们作为调味的子条件移进关系分支内部，而不是作为提前返回的拦截器。
13. **写任何命令处理体前，先查该命令能读哪些 state —— 别凭记忆猜变量名。** 顺序（拉取变推送）：
    1. **先查 `references/12-命令速查.md` 里该命令那一节**，拿到它的口上标签、`TFLAG:193` 成败、以及命令专属状态变量（如演奏 416 的 `TFLAG:使用楽器`、劝酒 332 的 `BASE:酒気`、午睡 417 的 `CFLAG:陪睡中`）及各取值含义。
    2. **速查里没有 / 资料不足**：`grep "^{号}," references/data/Train.csv` 确认命令名 → grep 现存口上里该命令顶部的 banner 注释（`grep -rn "_COM_K.*_{号}" 個人口上/` 看多个作者的 banner，去重收敛）→ grep 引擎命令语义（`references/data/engine/EVENT_MESSAGE_COM{3,4}00.ERB`，或游戏里 `ERB\コマンド関連\COMF\COMF{号}*.ERB` 的命令主体）。
    3. **仍不清楚**：派一个 Explore agent 去游戏文件夹（`ERB\` 全树）检索该命令/变量——这是补资料的正道，不要凭"这个命令应该有个 XX 变量"臆测。查到的新事实若属通用知识，回填进 `references/12` 与 `references/data/engine/`。

---

## 2. 校验流程 —— 宣布完成前先跑

搭好一个新口上后、交回给用户前，校验：

```bash
# 按用户的安装路径调整
DIR="<kojo variant dir, e.g. ERB/口上・メッセージ関連/個人口上/100 Rei'sen [レイセン]/myvar>"
CSVDIR="<game root>/CSV"

cd "$DIR"

echo "=== [[ ]] symbols not in Str.csv (will silently become 0) ==="
grep -hoE "\[\[[^]]+\]\]" *.ERB | sort -u | while read s; do
    name="${s:2:-2}"
    grep -qE ",${name}\b" "$CSVDIR/Str.csv" || echo "MISSING: $s"
done

echo "=== Custom-named function parameters (must be ARG/ARG:N/ARGS/ARGS:N only) ==="
grep -nE "^@.*\([A-Za-z_][A-Za-z0-9_]*\s*=" *.ERB | \
    grep -vE "ARG(:[0-9]+)?\s*=" | grep -vE "ARGS(:[0-9]+)?\s*="

echo "=== Unverified CFLAG/TFLAG/TCVAR slot names (must exist in CSV) ==="
grep -hoE "(CFLAG|TFLAG|TCVAR):([A-Z]+:)?[^a-z0-9 :,()<>=&|!*+\r\n_-]+\b" *.ERB | \
    sed -E 's/^(CFLAG|TFLAG|TCVAR):([A-Z]+:)?//' | sort -u | while read slot; do
    grep -qF ",${slot}" "$CSVDIR"/{CFLAG,TFLAG,TCVAR}.csv || echo "MISSING: $slot"
done

echo "=== Files missing UTF-8 BOM ==="
for f in *.ERB; do
    head -c 3 "$f" | xxd -p | grep -q "efbbbf" || echo "$f"
done

echo "=== EVENT_K_X bodies missing the same-cell guard ==="
grep -l "@M_KOJO_EVENT_K[0-9]\+_[123](" *.ERB | while read f; do
    grep -qE "現在位置.*!=.*MASTER:現在位置" "$f" || echo "$f: missing 現在位置 != MASTER:現在位置 guard"
done

echo "=== IF / ENDIF balance per file ==="
# Invariant: one ENDIF per block-opening IF. ELSEIF (starts 'E') and SIF (starts 'S')
# are NOT block openers and are naturally excluded by anchoring on '^\s*IF\b'.
# (Do NOT compute (IF+ELSEIF)-SIF — that only balances when ELSEIF count == SIF count,
#  so a body full of SIF-guarded [[MT]] markers throws false positives.)
for f in *.ERB; do
    ifs=$(grep -cE "^[[:space:]]*IF\b" "$f")
    ends=$(grep -cE "^[[:space:]]*ENDIF\b" "$f")
    [ "$ends" -eq "$ifs" ] || echo "$f: IF (block openers)=$ifs, ENDIF=$ends"
done

echo "=== SELECTCASE / ENDSELECT balance per file ==="
for f in *.ERB; do
    s=$(grep -cE "^[[:space:]]*SELECTCASE\b" "$f")
    e=$(grep -cE "^[[:space:]]*ENDSELECT\b" "$f")
    [ "$s" -eq "$e" ] || echo "$f: SELECTCASE=$s, ENDSELECT=$e"
done

echo "=== [SKIPSTART] / [SKIPEND] balance per file ==="
for f in *.ERB; do
    s=$(grep -cF "[SKIPSTART]" "$f")
    e=$(grep -cF "[SKIPEND]"   "$f")
    [ "$s" -eq "$e" ] || echo "$f: [SKIPSTART]=$s, [SKIPEND]=$e"
done

echo "=== Duplicate @label across all files (will hide later definition) ==="
grep -hE "^@[A-Za-z_][A-Za-z0-9_]*" *.ERB | awk '{print $1}' | sort | uniq -d

echo "=== RAND:0 (would crash at runtime) ==="
grep -nE "RAND:0\b" *.ERB

echo "=== 测试覆盖启发式：有台词(PRINTFORM)却一个 ;@AT 标签都没有的文件 —— 多半整份漏标测试 ==="
# 这一条抓的是最严重的疏漏：整个口上文件写满台词，却没给任何 region 打测试标签。
# （更细的「某个分支漏标」难以纯 grep，靠 §2.1 的规则 + 交付前逐 handler 自查。）
for f in *.ERB; do
    p=$(grep -cE "^[[:space:]]*PRINTFORM" "$f")
    t=$(grep -cE "^[[:space:]]*;@AT\b" "$f")
    [ "$p" -gt 0 ] && [ "$t" -eq 0 ] && echo "$f: 有 $p 处台词、却 0 个 ;@AT 标签 —— 整份漏标测试！"
done
```

若有任何检查失败，修复后重跑。**每一遍 Edit 后都重跑**，因为工具有时会在重写时剥掉 BOM。

### 2.1 测试覆盖是【硬要求】，不是可选项

**每一个会出声（含 `PRINT*` 台词）的口上 region，交付前都必须挂上测试——自动测试或手动测试之一，一个都不许漏。** 这是初稿反复翻车的地方：AI 只写了台词、没写任何测试标签，于是整份口上没法被验证，bug 只能等玩家实机撞见。「写完台词」不等于「写完」——没挂测试的 region 视为未完成。

**做法（先【完整读】 `references/11-autotest-pipeline.md` 全文，按它的规范做，别只扫这一段）**：§11 是自动/手动测试的权威规范，它在 §0.4 的 A 层必读清单里——动手写口上之前就该读完，而不是交付时才补。下面是它的要点，细节以 §11 为准：

1. **每个会出声的 region 必须有一条 `;@AT <状态> <TID>` 标签**（状态见 §11.7：初稿一般是 `待自动测试` 或 `待手动测试`；`TID` 形如 `K{id}_410_旁观`，全局唯一、`K{角色号}_` 开头）。**没有任何一个 region 可以完全不带标签。**
   - **例外（可豁免）**：被别的 handler 调用的 **helper / 子程序**（如函数库里的工具函数）——它们的台词覆盖体现在**调用方** handler 的 `;@AT` 上，helper 文件本身可以没有标签。上面校验脚本若报到函数库这类文件，按此判断（属可接受的提示、非缺陷）。**但命令 / 事件 / 派生等引擎会直接分发进来的 handler 不在此列——它们必须逐分支标。**
   - **静默桩不算会出声**：`LOCAL = 0` 的占位 body（无 `PRINT*` 触发）不需要标签。
2. **能靠状态注入自动测试的，当场就接进 AUTOTEST 测试套件**（§11.13 的 ⭐原则）：凡分支只依赖可注入状态（`TFLAG:193` 成败、`TALENT:*` 关系、`CFLAG:*:好感度`、`BASE:*:酒気`、`Activity_Type:*`、或直接 `CALL` 事件/派生/日记 body），就标 `待自动测试` 并在**同一轮**给测试套件加 `[[TID BEGIN]]…[[TID OK]]` 块。别图省事把能自动测的丢给手动测试——手动测试极耗用户时间。
3. **真正只能手动测的**（交互菜单 `ASK_YN`/`ASK_M`、真实事件/约会时序、难注入的房间/在场角色），标 `待手动测试`，并加**两行**标记：守卫行 `SIF K{id}_MT_ON()` 紧接其下 `PRINTL [[MT <TID>]]`（§11.8）。测试通过后 `manual_scan.ps1 -Apply` 会自动把 `;@AT` 翻成 `测试通过` 并删掉这两行——你不用手动清理。
4. **原则上无法测的**（纯 `RAND` 的文本变体、只能靠多轮累积覆盖的分支等），**仍要标注并写明原因**（例如标 `待手动测试` 再加一句注释「纯 RAND 文本、靠多轮游玩累积」）。**「没标签」和「标了、并说明不可测」是两回事**：前者是缺陷（分不清是漏了还是不能测），后者是已知、可交付。**不允许静默遗漏。**

**交付前自查**：逐个 `@M_KOJO_*` 会出声的 handler 过一遍，确认它名下每个会 `PRINT*` 的分支都有对应 `;@AT`。上面校验脚本的「有台词却 0 标签」那条只能抓住整份漏标的极端情况；**「某个分支漏标」得靠你自己逐 handler 核**。§11.13 的「承诺集↔已接入套件」交叉核对是在这之上的**第二道**（它假设你已经打好了标签，只查 `待自动测试` 的有没有真的接进套件）——它**不**替你发现「压根没打标签」的 region。

---

## 3. 与用户一起调试

校验流程（§2）能抓到静态问题。但很多 bug 只在运行时才暴露 —— 某行打印太多次、某个谓词不触发、某个 CFLAG 槽位静默地是错误类型。本节是**迭代循环**，当口上改完后行为不对时，你*与用户一起*运行它。

### 3.1 如何把游戏日志导出来

游戏在 **「文件」** 菜单下有两个相关动作：

- **「保存日志」** —— 把当前会话日志保存为游戏目录里的一个文件。
- **「将日志复制到剪切板」** —— 把会话日志复制到剪贴板，方便用户粘贴进聊天。

**用户把相关日志片段粘进对话；你来读。** 让用户只粘相关片段，因为整份日志可能很长，含大量无关内容。

此外，游戏会在游戏根目录写入 `emuera.log` 和 `<YYYYMMDD-HHMMSS>.log`（每会话一份）。但前者可能不会实时更新。后者由 **「保存日志」** 生成。

### 3.2 编译错误 —— 必须先修好，其他一切之前

编译错误不会阻止游戏加载，但它们可能随时让游戏崩溃。它们在游戏启动时出现。

**一次健康的启动大约显示四行：**

```
如果出現了錯誤、請根據目錄下的報錯指導文件進行報錯
1702 files were found in the lazy loading table
Loading complete. Took 2.19 seconds.
Press Enter or click to proceed.
```

**第二行与第三行之间的行很可能是编译错误。** 例：

```
如果出現了錯誤、請根據目錄下的報錯指導文件進行報錯
1702 files were found in the lazy loading table
警告Lv2:口上・メッセージ関連\個人口上\020 Lyrica [リリカ]\リリカ\M_KOJO_K20_日記.ERB:第40行:函数"@DIARY_TEXT_K20"的参数错误:变量"PAGENUM"未在此函数中定义
@DIARY_TEXT_K20, PAGENUM, MODE, PAGECOUNT
警告Lv2:口上・メッセージ関連\個人口上\020 Lyrica [リリカ]\リリカ\M_KOJO_K20_日記.ERB:第41行:变量"PAGENUM"未在此函数中定义
SELECTCASE PAGENUM
Loading complete. Took 2.19 seconds.
Press Enter or click to proceed.
```

每一行 `警告Lv2:` 告诉你：
- **文件路径**（相对游戏根目录，例如 `口上・メッセージ関連\個人口上\020 Lyrica [リリカ]\リリカ\M_KOJO_K20_日記.ERB`）。
- **行号**（例如 `第40行` = 第 40 行）。
- **受影响的函数名**（例如 `@DIARY_TEXT_K20`）。
- **实际原因**（例如 `参数错误:变量"PAGENUM"未在此函数中定义` —— 「参数错误：变量 PAGENUM 未在此函数中定义」—— 见坑 #1：自定义参数名不生效；用 `ARG/ARG:1/ARGS/ARGS:1`）。

**当用户粘贴一个编译错误时的工作流：**

1. 告诉用户：**«请把游戏启动时出现的所有 `警告Lv2:` 行都贴给我。** 一次健康的启动只显示你看到的前 2 行和后 2 行 —— 中间的任何内容都是需要修复的错误。»
2. 把每个警告映射到某条 §1 坑（大多数警告都能对上那里列的 12 条之一）或映射到 §2 的校验检查。
3. 修补文件。展示一个 diff。
4. **与用户确认**：«请重新启动游戏，看看 `警告Lv2:` 行有没有消失。» 重复直到干净。

**在启动干净之前，别进入运行时测试。** 一个启动时带编译错误的游戏可能*看起来*能跑，但受影响的标签会静默失效。

**⚠️ 新加的标签在游戏里没反应，但*没有*编译错误？先怀疑 `lazyloading.dat` —— 在动代码之前。** 在 `USELAZYLOADING:YES`（玩家默认）下，你刚加的一个**全新**标签不在陈旧的符号缓存里，因此引擎会当它不存在，回退到通用叙述（你看到命令的默认横幅，但没有你的口上台词）。对*现有*标签的主体编辑通常*会*显示 —— 这种不对称正是令人困惑之处。删掉游戏根目录里的 `lazyloading.dat` 再重启（引擎会重建它）。autotest 启动器会自动做这件事；手动 exe 启动不会。完整细节：`references/11-autotest-pipeline.md` §11.6。

### 3.3 运行时问题 —— 主动的调试打印工作流

每次非平凡的口上编辑后，**主动询问用户**：

> «改完了。请在游戏里测试一下：[列出受影响的 cmd / 事件 / 触发条件]。如果有任何不对的地方（例如台词重复、不该触发的时候触发、对话乱序等），请告诉我并贴出 `「文件」→「将日志复制到剪切板」` 的内容。»

若用户报告一个问题：

1. **确定哪个主体标签触发了**（或本应触发却没触发）。读用户的描述；映射到一个标签。
2. **加临时调试打印**到那个主体，捕捉相关 state（配方见下方 §3.4）。
3. **交回给用户**：«我加了一些临时的诊断打印。请重新触发刚才的操作 (e.g. 走进莉莉卡的房间)，然后用 `「文件」→「将日志复制到剪切板」` 把日志贴给我。»
4. **从捕捉到的 state 诊断**。常见模式：
   - 某谓词求值错误，因为一个 CFLAG 非布尔（见坑 #8 —— `约会中` 是地图 id）。
   - 某标签触发次数多于预期（见坑 #4 —— `EVENT_K_1` 每次格子迁移都触发）。
   - 某槽位是零，因为 `[[X]]` 没解析成功（见坑 #2）。
   - 某函数参数在主体内不可读（见坑 #1）。
5. **在同一次编辑里修补并移除调试打印**。告诉用户：«已修复。**注意我把诊断打印行删掉了**，这样以后正式玩的时候不会有 `[DBG]` 噪音。»

### 3.4 调试打印配方

要在主体的任意点检查 state，加入这样的行：

```erb
;[DBG] — 临时；宣布完成前移除
PRINTFORML [DBG] DAY={DAY:0} MAIN_MAP={MAIN_MAP} TIME:5={TIME:5} TIME:2={TIME:2}
PRINTFORML [DBG] ARG={ARG} ARG:1={ARG:1} SELECTCOM={SELECTCOM} TFLAG:50={TFLAG:50}
PRINTFORML [DBG] CFLAG:20:現在位置={CFLAG:20:現在位置} CFLAG:MASTER:現在位置={CFLAG:MASTER:現在位置}
PRINTFORML [DBG] CFLAG:20:约会中={CFLAG:20:约会中} FLAG:约会的对象={FLAG:约会的对象}
PRINTFORML [DBG] TALENT:恋慕={TALENT:恋慕} TALENT:恋人={TALENT:恋人} ABL:20:親密={ABL:20:親密}
```

关于语法的说明：

- **任何 `PRINTFORM*` 命令里的 `{<expr>}`** 会在打印时求值并替换成该表达式的值。数字打印为数位；字符串打印为文本。
- **`PRINT VARDUMP(<arr>)`** 会转储整个数组的内容。
- **始终以 `[DBG]` 前缀** 好让用户能在正常叙述中认出你的调试行。在粘贴的日志里搜 `[DBG]` 就能只拿到诊断输出。
- **对于静默分支的谓词**（不打印就返回），在*每个分支内部*放一个带唯一标记的调试打印，让日志揭示走了哪条路径：
  ```erb
  IF CHK_DATENOW(CFLAG:MASTER:约会中) && FLAG:约会的对象 == TARGET
      PRINTFORML [DBG-A] dating-with-this-char branch taken
      ...
  ELSEIF TALENT:恋人
      PRINTFORML [DBG-B] lover branch taken
      ...
  ELSE
      PRINTFORML [DBG-C] fall-through branch taken
      ...
  ENDIF
  ```
- **移除所有调试行** 再宣布口上完成。在文件里 grep `[DBG]` 并逐一删除。§2 的校验流程应能抓到任何残留。

### 3.5 用户的 bug 报告消息长什么样

你应该预期（并温和地引导）用户说出类似这样的话：

> «我刚刚走进莉莉卡的房间，但她的台词出现了 3 次。日志如下: [paste]»

或在一个编译错误之后：

> «游戏启动时报错: [paste 警告Lv2: block]»

快速回复：

1. **把相关日志行引用回去** 让用户知道你读了它。
2. **一句话说明原因**（"这是 §1 pitfall #4 — `EVENT_K_1` 每次角色走进新格子都会触发，body 缺少同格守卫。"）。
3. **以 diff 展示修复。**
4. **告诉用户下一步**：«请重新启动游戏看看是否还有报错。» / «请再触发一次该动作并粘贴新的日志。»

迭代周期往往每次 30-60 秒（游戏重启 + 复现 + 粘贴）。保持简洁 —— 别过度解释。

---

## 4. 全景图 —— 什么在哪

```
eraTW/
├── ERB/                                  ; 全部游戏逻辑（Emuera 脚本）
│   ├── 口上・メッセージ関連/
│   │   ├── KOJO_MESSAGE.ERB              ; 分发器（引擎 —— 永不修改）
│   │   ├── COMMON_KOJO.ERB               ; 库 helper
│   │   ├── EVENT_MESSAGE*.ERB            ; 引擎默认叙述
│   │   └── 個人口上/                      ; 你的领域：按角色的口上
│   │       ├── 001 Reimu [霊夢]/
│   │       │   └── <variant>/
│   │       │       ├── M_KOJO_K1_イベント.ERB
│   │       │       ├── M_KOJO_K1_日常系コマンド.ERB
│   │       │       └── … ~10-25 个文件
│   │       ├── 002 Ruukoto [る～こと]/
│   │       └── … 153 个角色目录
│   ├── COMMON.ERB, BATTLE.ERB            ; 引擎代码
│   ├── 天候*.ERB                          ; 天气子系统（一个「系统插件」示例）
│   ├── コマンド関連/                      ; 命令系统（COMF/、SCOMF/、COMABLE/）
│   └── …                                 ; 许多其他引擎子目录
├── CSV/                                  ; 静态数据表
│   ├── CFLAG.csv, TFLAG.csv, TCVAR.csv   ; 标志槽位字典
│   ├── Talent.csv, Abl.csv, Mark.csv     ; 按角色的特性字典
│   ├── Item.csv, Equip.csv, Train.csv    ; 物品 / 装备 / 命令
│   ├── Base.csv, Palam.csv               ; 生理基础值 / 参数
│   ├── Str.csv                           ; 字符串表 —— 决定 [[X]] 的解析
│   └── Chara/                            ; 按角色的数据 CSV（每角色一份）
├── 原版+前人整合等各种readme/             ; 社区教程与模板（见 §12）
│   ├── 改造とかしてみたい人のためのあれこれ/  ; 改造教程（口上教程、helper 函数参考…）
│   └── 資料/                               ; 参考表（CFLAG/TFLAG/TCVAR ID、地图…）
├── Emuera*.exe                           ; 引擎二进制（多个变体）
├── emuera.config, README*                ; 引擎配置
└── sav/, dat/, resources/, font/         ; 存档、立绘、字体
```

**关键洞察**：没有插件清单。引擎在加载时递归扫描 `ERB/`；*加一个新文件就是全部安装过程*。把一个变体目录丢进 `個人口上/<id> <name>/`，就完成了。

`原版+前人整合等各种readme/` 是原始日文社区的教程语料库 —— **本 skill 里的大部分结构性知识都源自那里。** 它不会被引擎加载；它存在于安装里供人参考。§12 说明里面有什么、何时直接查阅。

---

## 5. 心智模型 —— 引擎代码 vs 口上代码

本游戏里有两种代码；把它们分开：

1. **引擎代码** —— `KOJO_MESSAGE.ERB`、`EVENT_MESSAGE*.ERB` 等。**你从不编写或修改这些。** 它们随游戏而来，实现了分发循环。
2. **口上代码** —— `個人口上/<id> <name>/<variant>/M_KOJO_K<id>_*.ERB` 下的文件。**这才是你写的。** 引擎会伸进这些文件里寻找**特定的标签名**，并调用它找到的那些。

两者之间的契约仅仅是一份**标签名清单**。引擎声明：*「如果你定义了 `@M_KOJO_MESSAGE_COM_K1_300`，那么每当玩家对角色 1（灵梦）使用命令 300 时，我就会调用它。」* 你定义你关心的标签；引擎忽略其余的。

所以**作为口上作者你不写 `TRYCALLFORM ...`** —— 那行在引擎内部，不是你的事。你只写 `@LABEL_NAME` 定义。引擎读那份约定俗成的标签名清单并调用它们。完整标签目录在 `references/01-engine-label-catalog.md`。

### 5.1 分发流程，逐步

当玩家对角色 ID 1（灵梦）使用命令 300（会話）时会发生什么，具体走一遍：

1. 引擎处理玩家输入，判定「这是一个对 TARGET=1、命令 id=300 的 COMMAND」。
2. 引擎调用其内部函数 `@KOJO_MESSAGE_SEND("COMMAND", 300, 1, ...)`。
3. 在那个函数内部（在 `KOJO_MESSAGE.ERB` 里），引擎**从一个模板构造出一个标签名**并尝试调用它：
   ```
   TRYCALLFORM M_KOJO%RESULTS%_MESSAGE_COM_K{NO:TARGET}_{ARG:1}
                       ↓                 ↓             ↓
                       (选择器,          K1            300       → 标签解析为：
                        通常为空)                                 @M_KOJO_MESSAGE_COM_K1_300
   ```
   `TRYCALLFORM` 是引擎的「试着调用这个标签，但如果它没定义就保持静默」。
4. 如果你在口上文件里定义了 `@M_KOJO_MESSAGE_COM_K1_300`，引擎就运行你的主体。如果没有，引擎静默地转向一个回退（`_00` 兜底，然后是引擎默认叙述）。

这就是全部的魔法。引擎用几条构建规则（每种分发类型一条）来命名标签；你提供你想填充的那些标签。

### 5.2 ARG、ARG:1、ARG:3 等是什么意思（位置参数）

当引擎构造一个标签名时，一些输入进入*名字*；另一些作为**位置参数传给主体**：

```
TRYCALLFORM M_KOJO_EVENT_K1_5(ARG:3, ARG:4)
                          ↓   ↓     ↓
                          K=1 然后 ARG:3 和 ARG:4 作为位置参数传入
                          event=5
```

引擎内部有一个 `ARG`/`ARG:1`/`ARG:2`/... 命名空间。构造标签时，它把一部分放进*名字字符串*（用于标签分发），把其余转发为位置参数。**你不定义 `ARG:3`/`ARG:4`；引擎来填。** 你的工作是在你的标签头里**接收并读取**它们：

```erb
@M_KOJO_EVENT_K1_5(ARG, ARG:1)
;       ^                  ^
;       灵梦               你接收 ARG（引擎的 ARG:3）和 ARG:1（引擎的 ARG:4）

;主体 —— 读 ARG 以判断我们处在 event 5 的哪个子状态：
IF ARG == 0
    PRINTFORML 「<ARG=0 的台词 —— 例如 求婚>」
ELSEIF ARG == 1
    PRINTFORML 「<ARG=1 的台词 —— 例如 接受>」
ENDIF
RETURN 1
```

每个位置 `ARG` 的含义**取决于分发类型**：对 SPEVENT，`ARG` 通常是一个子状态（0=求婚，1=接受，2=拒绝）；对 EVENT，`ARG` 按槽位有文档记载（见 `references/05-event-arg-subphases.md`）；对育儿 `(ARGS, ARG, ARG:1)`，`ARGS` 是人生阶段字符串。完整的按标签 arg 语义在 `references/01-engine-label-catalog.md`。

---

## 6. 分发类型 —— 快速参考

引擎的 `ARGS` 键（完整标签目录 → `references/01-engine-label-catalog.md`）：

| ARGS | 何时触发 | 它构建的标签族 |
|---|---|---|
| `"ENCOUNTER"` | 初次相遇过场。 | `@M_KOJO_ENCOUNTER_K{id}` |
| `"SP_EVENT"` | 一次性脚本事件（接吻、告白）。 | `@M_KOJO_SPEVENT_K{id}_{ev}(ARG, ARG:1)` |
| `"EVENT"` | 通用事件（进房、早晨、睡眠）。 | `@M_KOJO_EVENT_K{id}_{ev}(ARG, ARG:1)` |
| `"COMMAND"` | 玩家选了一个命令。 | `@M_KOJO_MESSAGE_COM_K{id}_{cmd}`（+ `_SUCCESS_COM_*`、`_MESSAGE_SCOM_*`） |
| `"COUNTER"` | 自动 / 空闲反应。 | `@M_KOJO_MESSAGE_COUNTER_K{id}_{n}` |
| `"PALAM"` | 动作后的数值变化（含高潮）。 | `@M_KOJO_MESSAGE_PALAMCNG_A/A2/B/B2/F_K{id}` |
| `"MARK"` | 刻印被获得。 | `@M_KOJO_MESSAGE_MARKCNG_K{id}` |
| `"DANMAKU"` | 弹幕对决。 | `@M_KOJO_MESSAGE_COM_K{id}_DANMAKU(ARGS, ARG)` |
| `"IRAI"` | 委托对话。 | `@M_KOJO_IRAI_K{id}(ROLE, SCENE, IRAI_ID)` |
| `"DAILY"` | 日常事件。 | `@M_KOJO_DAILY_EVENT_K{id}_{n}(ARG..., ARGS:1, ARGS:2)` —— 已知 n：2 (夢精), 4 (物思い), 12 (特訓) |
| `"DIARY"` | 日记阅读。 | `@DIARY_K{id}_*`、`@M_KOJO_MESSAGE_COM_K{id}_406` |
| `"CHILD"` | 育儿事件。 | `@M_KOJO_EVENT_K{id}_CHILD_RAISING_*` |
| `"GRAVITY"` | NPC AI 移动决策（静默！）。 | `@M_KOJO_EVENT_K{id}_GRAVITY(ARG)` ← **静默**，设 `TCVAR:N:引力点`，从不打印 |
| `"BEFORETRAIN"` | 调教前静默钩子。 | `@K{id}_BEFORETRAIN` ← **静默** |
| `"PERMISSION"` | 推送式同意（静默 helper）。 | `@M_KOJO_EVENT_K{id}_PERMISSION_<n>(ARG)` |
| `"LOST_VIRGIN_STOP"` | 初次时的中断判定（静默）。 | `@M_KOJO_EVENT_K{id}_LOST_VIRGIN_STOP(ARG)` |
| `"GIFT"` | 礼物 收到/送出。 | `@M_KOJO_EVENT_K{id}_GIFT(ARG, GIFT_ID, 評価点, GIFT_NAME, SENSE)`（5 参数，自定义名 —— 主体需 `#DIM`/`#DIMS`） |
| `"ONABARE"` | 自慰被撞见时的爆发。 | `@M_KOJO_EVENT_K{id}_26(ARG, ARG:1)`（主对话）+ `_26_1(ARGS)`（动作前判定）+ 可选 `_ONABARE_1/2/3`（叙述覆盖） |
| `"MUSHI_BATTLE"` | 虫战对话。 | `@M_KOJO_MESSAGE_COM_K{id}_MUSHI_BATTLE(ARGS, ARG)` ← **写 `RESULTS = "..."`，不是 `PRINT*`** |
| `"SUIKA"` | 切西瓜方向提示。 | `@M_KOJO_MESSAGE_COM_K{id}_SUIKA(ARGS, ARG)` ← **写 `RESULTS = "..."`，不是 `PRINT*`** |
| `"RUN_INTO"` | 地图上随机遭遇。 | `@RUN_INTO_K{id}(MAP_ID)` |
| `"SEX_FRIEND"` | 「炮友」契约场景。 | `@KOJO_SF_CONTRACT_EVENT_K{id}(ARGS)`（"導入" / "補正" / "成功" / "失敗"） |
| `"IRAI_BLOCKED"` | 抑制该角色的特定委托。 | `@M_KOJO_CHECK_K{id}_IRAI_BLOCKED(ARGS, ARG, ARG:1)` ← 返回 1 表示屏蔽 |
| `"ODEKAKE"`, `"DIRECT"`, `"SUCCESS"`, `"ENDING"` | 杂项 / 小众。 | （见 references/01） |

**区分 print / 静默 / 仅-RESULTS 分发至关重要**：
- **静默标签**（GRAVITY, BEFORETRAIN, PERMISSION, LOST_VIRGIN_STOP）：在里面放 `PRINTFORML` 会每个 tick 都刷屏 → §1 坑 #5
- **仅-RESULTS 标签**（MUSHI_BATTLE, SUIKA）：用 `RESULTS = "<line>"` 然后 `RETURN 1` —— 引擎会自己带自动格式打印它。此处用 `PRINTFORML` 会破坏显示。见 `references/01-engine-label-catalog.md` §2.4.3。

---

## 7. 标准主体形态（最常复用的模板）

每个命令主体都遵循这个模式。把它当作你的默认脚手架。下面展示的 10 层连锁是*最大*形态；官方空模板（`reference-kojo/口上テンプレ/`）用的是更简单的 4 层连锁 —— 见 §9 说明各自适用于何时。

```erb
;==================================================
;<cmd-id>,<命令名>
;TFLAG:193(1=心情上升 0=中立 -1=心情下降)
;CFLAG:诶嘿嘿==2&&TCVAR:20(<情境子状态>)
;PREVCOM(<影响本命令的前一命令号>)
;==================================================
@M_KOJO_SUCCESS_COM_K<id>_<cmd>
;成否判定
TFLAG:192 = 0                         ; -2 结束, -1 失败, 0 默认, 1 大成功

@M_KOJO_MESSAGE_COM_K<id>_<cmd>
CALL TRAIN_MESSAGE                    ; 引擎默认叙述（若想完全自定义则省略）
CALL M_KOJO_MESSAGE_COM_K<id>_<cmd>_1  ; 分发到主体
RETURN RESULT

@M_KOJO_MESSAGE_COM_K<id>_<cmd>_1
;-------------------------------------------------
;填写检查（=0, 不显示、1, 显示）
LOCAL = 1                              ; 1 = 已填写, 0 = 存根跳过
;-------------------------------------------------
IF LOCAL
    IF FLAG:時間停止                   ; 時間停止：除非设了 時間停止口上有 否则静默
    ELSEIF CFLAG:睡眠                  ; 睡眠中：除非设了 眠姦口上有 否则静默
    ELSEIF TALENT:恋人                 ; 第 5 层 —— 伴侣
        SELECTCASE RAND:3
            CASE 1
                PRINTFORML 「<lover-line-A>」
                PRINTFORMW <lover-narr-A>
            CASE 0
                PRINTFORML 「<lover-line-B>」
                PRINTFORMW <lover-narr-B>
            CASEELSE
                PRINTFORML 「<lover-line-C>」
                PRINTFORMW <lover-narr-C>
        ENDSELECT
    ELSEIF TALENT:愛欲 || TALENT:炮友  ; 第 4 层 —— 情欲
        ...
    ELSEIF TALENT:恋慕                 ; 第 3 层 —— 恋慕（陷入爱恋）
        ...
    ELSEIF TALENT:思慕                 ; 第 2 层 —— 思慕（爱慕）
        ...
    ELSE                                ; 第 1/0 层 —— 中立或敌对
        ...
    ENDIF
ENDIF
RETURN 1
```

要记住的契约要点：

- 对本角色处理的任何命令，始终同时输出 `@M_KOJO_SUCCESS_COM_K<id>_<cmd>` 和 `@M_KOJO_MESSAGE_COM_K<id>_<cmd>`。SUCCESS 可以是单行 `TFLAG:192 = 0`。
- 拆分 `MESSAGE_COM_<cmd> → MESSAGE_COM_<cmd>_1` 是约定；让主体标签能被独立地重新 CALL。
- 主体的 `RETURN 1` 标记「我处理了」；引擎不会回退到默认。
- `RETURN 0` 或不返回：引擎回退到 `_00` 兜底，然后回退到引擎默认。
- 主体最后一个 `PRINTFORML` 通常应是 `PRINTFORMW`，好让玩家推进。
- 用 `%CALLNAME:MASTER%`，而非 "你"/"主人公"/等 —— 名字是用户可配置的。
- 随机变化：`SELECTCASE RAND:N / CASE 0 / … / CASEELSE`（默认 = 概率最高）。
- 单行随机：在 `PRINTFORML` 里用 `%TEXTR("a/b/c")%`。

---

## 8. `LOCAL = 0/1` 「填写与否」惯用法

主体以 `LOCAL = 1`（已填）或 `LOCAL = 0`（存根）开头。`LOCAL = 0` 会让主体静默地回退穿过。**不要「修好」`LOCAL = 0` 的主体** —— 它们是有意的存根。

子分支用 `LOCAL:1 = 1/0` 作子开关：

```erb
LOCAL = 1
IF LOCAL
    ;-------------------------------------------------
    ;初めて
    LOCAL:1 = 1
    ;-------------------------------------------------
    IF LOCAL:1 && FIRSTTIME(SELECTCOM)
        ; 仅初次的分支
    ENDIF
    ;基本セット
    IF FLAG:70
    ELSEIF TALENT:恋慕
        ...
    ELSE
        ...
    ENDIF
ENDIF
RETURN 1
```

这让作者能选择性地启用/禁用各部分。

---

## 9. 标准分支连锁

两种连锁很常见；挑符合该角色复杂度的那个。

### 9.1 最大（10 层）连锁 —— 用于功能齐全、每层调味丰富的口上

| 次序 | 守卫 | 注释 |
|---|---|---|
| 1 | `IF FLAG:時間停止`（`= FLAG:70`） | 時間停止 生效中；通常静默，除非在 FLAGSETTING 里设了 `CFLAG:N:時間停止口上有 = 1`。 |
| 2 | `ELSEIF CFLAG:睡眠` | 睡眠中；静默，除非 `CFLAG:N:眠姦口上有 = 1`。 |
| 3 | `ELSEIF FLAG:扮演` | 扮演；静默，除非 `CFLAG:N:扮演口上有 = 1`。可按 `CFLAG:(FLAG:扮演):出禁` 分支。 |
| 4 | `ELSEIF CFLAG:318 == 1` | 「极度冷淡 / 不友好」—— 许多角色都有这个。 |
| 5 | `ELSEIF CFLAG:诶嘿嘿 == 2` | 「醉后嬉闹的『诶嘿嘿』情绪」—— 再按 `TCVAR:20` 分子动作。 |
| 6 | `ELSEIF TALENT:恋人` | 第 5 层 —— 伴侣。 |
| 7 | `ELSEIF TALENT:愛欲 \|\| TALENT:炮友` | 第 4 层 —— 无承诺的情欲。 |
| 8 | `ELSEIF TALENT:恋慕` | 第 3 层 —— 恋慕。 |
| 9 | `ELSEIF TALENT:思慕` | 第 2 层 —— 思慕。 |
| 10 | `ELSE` | 第 1/0 层 —— 中立或敌对。 |

有些作者把它收拢进一个 helper `陥落状態()`，返回 0..5；主体便用 `IF 陥落状態() >= 4 ...` 代替直接测试 TALENT。

### 9.2 官方模板（4 层）连锁 —— 用于较简单或部分填充的口上

这是官方空模板（`reference-kojo/口上テンプレ/`）默认使用的连锁：

```erb
IF LOCAL:1 && FIRSTTIME(SELECTCOM)   ; 初次台词（可选的开场）
    PRINTFORMW <first-time-line>
    RETURN 1
ENDIF
;基本セット
IF FLAG:70                            ; 時姦中（時間停止）
    PRINTFORMW <time-stop-line>
    RETURN 1
ELSEIF TALENT:恋慕                    ; 恋慕
    PRINTFORMW <love-line>
    RETURN 1
ELSEIF MARK:不埒刻印 == 3             ; lv3 不埒刻印
    PRINTFORMW <submission-line>
    RETURN 1
ELSE                                  ; 其他一切
    PRINTFORMW <default-line>
    RETURN 1
ENDIF
```

**用 4 层**：当用户的人格/角色简单、当他们不在意每层细微差别、或当他们只想填充最常见的少数情形而让其余一切回退穿过时。**用 10 层**：当用户明确想要丰富的、逐层不同的调味（例如 思慕 vs 恋慕 vs 愛欲 vs 恋人 各有不同台词），或当人格需要按 扮演/CFLAG:318 等设门时。

两者都有效，也都能对上安装里已发布的口上。别把 10 层硬塞进一个 4 行就够的主体。

### 9.3 性交系命令的中间守卫

对性交系命令（60-77、95，外加逆アナル 90-95），加中间守卫，判定 `BASE:MASTER:勃起`、`TCVAR:破瓜`、`TFLAG:193`（成功等级）、`TFLAG:194`（SELECTCOM 记录）等 —— 参照模板里每个命令上方的文档横幅状态契约，以及 `references/02-state-bus-namespaces.md`。

### 9.4 提前返回警告

TALENT 连锁之上的每一个提前返回条件都会*压制它下面所有的关系内容*。对于宽泛条件（房间类别、天气、时段），优先用 RAND 设门，或把该条件作为调味子条件移进关系分支内部，而不是作为提前返回的拦截器。

### 9.5 内容自查：生成完一段对话后，回头过一遍这四点

写完一条命令/事件的台词后，在交还前**自己审一遍**（这是内容质量检查，不是 §2 的机械校验）：

**① 称呼玩家 & 明显与好感相关的内容，必须随好感度变化——别锁死在生疏关系上。**
一条命令若只有「恋人 / 恋慕 / ELSE」三档，那个 `ELSE` 会同时覆盖**萍水相逢的陌生人**和**好感度 1400 的好朋友**——于是一个亲密玩家做出亲吻、请客、一起玩这类举动时，角色却用陌生人的冷淡语气回应（例：亲吻命令的 `ELSE` 是「你干什么！」+ 后退摔倒；一个 思慕/好朋友 玩家不该吃这个反应）。**修法二选一**：要么按 `CFLAG:{id}:好感度` 或关系 `TALENT` 多加中间档（思慕/熟络/心动），要么直接用 `%CALLNAME:MASTER%`（玩家名）而非「人类」「你这家伙」这类**锁定生疏**的称呼。好感度参考刻度（因作品/角色而异，仅作量级参考）：

| 好感度 | 大致关系 |
|---|---|
| < 250 | 生疏（初识/防备） |
| < 500 | 点头之交 |
| < 1000 | 熟人 |
| < 1500 | 好朋友 |
| < 3000 | 非常要好，常已进入「思慕」（`TALENT:思慕` 门槛之一即 好感度≥1500） |
| ≥ 3000 | 基本是恋慕/恋人 |

**要结合上下文灵活判断，不是见「人类」就改。** 关键区分：
- ❌ **锁定生疏**：「人类说要一起玩」——把玩家当外人陈述，任何好感度听着都像不熟。这种要改。
- ✅ **强调种族 + 傲娇**：「哼，人类也想玩妖精的游戏？那你可得跟上我们的节奏哦」——这是在拿「人类 vs 妖精」的身份调侃/逞强，带傲娇味，**任何好感度都可能这么说**，合理，不必改。
判据：这句话**换成恋人来说**还成立吗？成立（傲娇调侃）就留；不成立（暴露了「不熟」的前提）就按好感度分档或改用玩家名。

**② 克制对角色某个标志性特点的反复描写。**
把角色的招牌设定（能力、口癖、某个动作）**每一个分支都塞一遍**，读着就很「AI 完成命题作文」、不自然（例：露娜的「消音」能力若在会話、摸头、拥抱、接吻、礼物每条里都出现一次，就过量了）。让标志性特点**偶尔**出现、点到为止，其余分支用别的细节撑起人物。可参考 eratw 里其他角色口上的自然疏密度。**此项从简**——它是风格偏好、通常很安全，最终由用户拍板润色，不必花大量精力反复审查。

**③ 会持续很久的状态，它的专属台词要【入候选池】，不要写成排他覆盖。**
「约会中」这类状态**一持续就是几十个回合**，玩家在这期间会反复点「会話」。若写成
`IF 约会中 → 演约会台词 / ELSE → 平时的候选池`，那整场约会就**只剩那一句**翻来覆去，丰富度断崖式下降。
正确做法：把约会台词**按当前关系追加进候选池**，让它和平时的台词一起参与随机——约会味道点到为止，变化照旧：
```erb
IF CHK_DATENOW(CFLAG:MASTER:约会中) && FLAG:约会的对象 == TARGET
    IF TALENT:{id}:恋人
        pool:(LOCAL:1) = 70
    ELSEIF …
    ENDIF
    LOCAL:1 += 1
ENDIF
```
**排他覆盖只留给「压过一切」的短暂状态**：时间停止、睡眠、暴怒(318) 之类——这些状态下别的台词本来就说不通。
判据：问自己「这个状态会持续多久？玩家在这期间会点几次这个按钮？」超过两三次，就该入池。

**④ 增减好感度/信赖度等数值时，把变化打印出来。**
玩家看不到内部变量。悄悄 `CFLAG:{id}:好感度 -= 30` 而不吭声，玩家既不知道被罚了、也学不到「这么做有代价」，行为反馈整个断掉：
```erb
;好感度不足 30 时只会扣到 0，故先算出【实际】扣掉多少再打印，别报一个没真扣满的数
LOCAL = MIN(CFLAG:{id}:好感度, 30)
CFLAG:{id}:好感度 -= LOCAL
PRINTFORMW 【%CALLNAME:{id}%的好感度 -{LOCAL}　信赖度 -20】
```
注意打印的是**实际变化量**：有 clamp（下限 0、上限封顶）时，写死的字面量会撒谎。

---

## 10. 当用户要求做 X 时 —— 快速范式

三种常见工作流。**完整实战范例**（含文件脚手架、精确标签和中文正文模板）在 `references/06-workflow-recipes.md`。

### 10.1 从零新建一个变体（目标：空角色目录）

1. **搭建前，先读官方模板。** `reference-kojo/口上テンプレ/` 是随 skill 附带的权威空骨架。至少略读：
   - `M_KOJO_KX_イベント.ERB` —— 存在标签、FLAGSETTING、COLOR、UPDATE、ENCOUNTER、BEFORETRAIN、SPEVENT 1-3、EVENT 1-34（含完整 ARG 文档横幅）、DAILY_EVENT 2/4/12、ONABARE_1/2/3、LOST_VIRGIN_STOP、PERMISSION_1/2、GIFT、MUSHI_BATTLE、GRAVITY、SUIKA、RUN_INTO、SF_CONTRACT_EVENT、CHECK_IRAI_BLOCKED。
   - `M_KOJO_KX_日常系コマンド.ERB` 和 `M_KOJO_KX_性交系コマンド.ERB` 的 TOC 横幅（grep `^;[0-9]+,` 找命令 id 横幅 —— 别读每个主体）。
   - 若用户想要新的自定义 API 特性，则读 `of_new_kojo_api.ERB`。

   模板里的文档横幅注释*即是规范* —— 它们告诉你哪个 `CFLAG` 为每个标签设门、每个槽位的 `ARG`/`ARG:1` 是什么意思，以及返回值契约（`PERMISSION_1` 主体返回 -1/0/1，`LOST_VIRGIN_STOP` 主体返回 1=中止/0=继续，`EVENT_KX_26_1` 主体返回 -1/0/1，等）。**这是最承重的准备步骤。**

   只在你需要看某个具体主体的*填好*范例时才查阅 `reference-kojo/reimu/` —— grep `reimu/M_KOJO_K1_コマンド.ERB` 找你正在做的命令 id。别通读整个灵梦文件；它们又老又庞杂。

   如果用户的目标角色有一个同风格的姊妹/同类角色已有口上（例如三姊妹之一、同人格类型的两个角色），也 grep 那个；它往往会有正确的 `CFLAG:TARGET:*` 情境分支和语气。

2. 确认角色 ID 和目录名（用 `references/08-character-id-table.md` 或 grep `Chara/`）。

3. **按官方模板搭建现代多文件拆分：**
   - **总是**：`イベント / 日常系コマンド / セクハラコマンド / 愛撫系コマンド / 加虐系コマンド / 道具系コマンド / 性交系コマンド / 派生コマンド / カウンター / 弾幕勝負 / 刻印取得 / 絶頂`。
   - **常见**：`奉仕系コマンド / 道具系 / ハードなコマンド / 依頼 / 育児イベント / 日記 (or 日記（簡易版）)`。
   - **可选**：`自慰系(あなた)コマンド / 固有カウンター / of_new_kojo_api / 関数ライブラリ / INFO / <chara>特殊イベント`。

   文件名是 `M_KOJO_K<id>_<category>.ERB`。逐字节匹配模板的文件名（包括 `自慰系(あなた)コマンド.ERB` 里的全角括号）。灵梦的单一 `コマンド.ERB` 庞杂布局是遗留写法 —— 别照搬。

4. 在 `イベント.ERB` 里写存在标签 `@M_KOJO_K<id>(ARG) RETURN 1`，加上 FLAGSETTING（含你想要的静默 helper 的 CFLAG 启用标志 —— `破瓜キャンセル口上有`、`口上内抱き寄せ判定_初回`、`口上内抱き寄せ判定_通常`、`時間停止口上有`、`眠姦口上有`、`なりきり口上有`）、COLOR、UPDATE、ENCOUNTER 骨架。

5. 用 §7 模板填充约 5-10 个最有用的日常命令（300=会話, 301=泡茶, 302=身體接觸, 309=摸頭, 311=擁抱, 312=接吻, …），按人格复杂度选用 §9.1 最大连锁或 §9.2 4 层连锁。

6. 其余一切留 `LOCAL = 0` 存根 —— 引擎回退到默认叙述。

7. 跑 §2 校验流程。

### 10.2 加一个一次性脚本事件（纪念日、节日等）

1. 决定触发器：基于日期用 `@SPECIALDAY_EVENT_K<id>`，基于状态用作者私有的 `@K<id>_<NAME>`。
2. 预留一个状态进度 CFLAG（区段 1000–1999，在 `フラグ管理メモ.txt` 里记录）。
3. 编写事件主体 —— 通常是一个多步场景，在分支点用 `CALL ASK_YN(...)`，完成时用 `SOURCE:N:<slot> += <delta>`。
4. 从现有 `イベント.ERB` 挂上触发器（在合适的引擎槽位里加一行 `SIF <conditions> / CALL <event>`）。

### 10.3 修改现有口上（小的内容调整）

1. 确定文件（哪个 `M_KOJO_K<id>_<category>.ERB`）。
2. 找到主体标签（`grep '^@'` 找相关的 `_<cmd>` 或 `_<n>`）。
3. 在连锁正确位置加新分支。对于天气/时段条件，优先放在关系分支**内部**（作为调味），而非放在它们**之前**（作为会挡住丰富内容的提前返回）。

---

## 11. 给你（辅助 LLM）的最后提醒

> **这两条压过下面所有内容：**
> - **⛔ 写操作只落在口上文件夹里（§0.7）**，且不做有系统级永久影响的操作——除非用户明确、当次要求。**不确定就停下来问。** 引擎侧的问题：报告根因 + 给用户自查/自改的办法，别自己动手。
> - **自觉维护口上文件夹里的 `HANDOFF.md`（§0.8）**——你的 context 会被压缩、session 可能丢失，而用户不会提醒你。当场更新；压缩后回来第一件事是读它。

1. **先结构，后正文。** 总是先搭好文件和标签名，*再*问用户内容。
2. **默认用标准连锁**（§9）。只在用户人格明确需要时才加自定义守卫。
3. **大方地用 `LOCAL = 0` 存根** —— 那些槽位会回退到引擎默认。别逼用户把什么都填满。
4. **对任何命令都始终同时输出 `SUCCESS_COM` 和 `MESSAGE_COM`**。即便 SUCCESS 只是 `TFLAG:192 = 0`。
5. **在 counter / unique-counter 处理器里更新 `SOURCE:N:<slot>`**。不然口上会打印文本却不改变好感。
6. **用 `%CALLNAME:MASTER%`**，而非 你/主人公/等。
7. **别引用现有口上里的 R18 台词。** 展示范例时，把正文涂改成占位符。
8. **ID 查找**：角色 ID = 目录名开头的数字。用 `references/data/Chara/Chara<N> <name>.csv` 确认。
9. **新 API 特性**（`@KOJO_CUSTOM_BUTTON_*` 等）：只在你已确认用户跑的是较新引擎时才用。不确定就用 `[SKIPSTART]/[SKIPEND]` 包起来。
10. **持久存储**：优先用 `CFLAG:N:1000-1999`（作者私有）和 `TCVAR:N:350-399`（作者私有），而非 `SAVEDATA` 修饰符。
11. **角色间互动**：从目录列表读每个角色的 ID。若引擎支持则用 `RELATION:N:M`；否则从 `CFLAG:M:好感度` 组合。
12. **交付前在脑中测试**：标签对得上吗？存在检查返回 1 吗？守卫在连锁里的次序对吗？
13. **宣布完成前始终跑 §2 校验流程**。最常见的 bug 都能机械地检测到。
14. **按 §0.4 的三层策略读 references** —— **A 层**（02/03/04/05/07/09/10/11/13，约 30k）在动手写之前就读完，不是等撞墙再查；**B 层**一旦沾边就读全文（别 grep 一行就走）；**C 层**（`08`、`data/**`、`reference-kojo/reimu`）只 grep、永不整份读。在聊天机器人模式下，点明用户该上传的具体文件。

当用户问「让 X 对 Y 作出反应」时，公式是：
- **哪个槽位？** 确定引擎标签（命令 / 事件 / counter）。
- **哪个守卫？** 确定判别式（TFLAG / CFLAG / TALENT / 时间 / 天气）。
- **什么主体？** 生成反映「所求人格 × 守卫」的 `PRINTFORML` 台词。

然后交付补丁。修改用统一 diff 风格，创建用整文件风格。对用户说中文；引擎标识符保持其原始日文/英文。

祝好运。用户在做一件他们珍视的创意作品；你的工作是那些枯燥的基础设施活儿，好让他们专注于自己的角色。

---

## 12. 社区教程语料库（`原版+前人整合等各种readme/`）

你的 eraTW 安装几乎必然附带一个目录 `原版+前人整合等各种readme/`（字面意思「原版 + 各种前人整合的 readme」）。**这是原始日文社区的教程 + 参考语料库，本 skill 里的大部分结构性知识都源自那里。** 它不会被引擎加载 —— 它存在于安装里供人参考。

你通常不需要读它：skill 已把相关部分提取进了 `reference-kojo/` 和 `references/`。但你应该**知道它存在**，因为 (a) 用户可能引用它（问「`便利な関数.txt` 里有什么？」），(b) 用户手上的语料库可能比本 skill 构建时**更新**，(c) 对本文未覆盖的小众主题，它是权威出处。

### 12.1 `原版+前人整合等各种readme/` 的结构

```
原版+前人整合等各种readme/
├── eraTW_FAQ.txt                       ; 面向玩家的 FAQ（非给改造者）
├── 更新内容・readme.txt                  ; ~400 KB 更新日志
├── 今後の課題・方針・思いつきetc.txt     ; 维护者的路线图 / 笔记
├── 改造とかしてみたい人のためのあれこれ/   ; 改造教程 —— 先读这个
│   ├── 口上関連/                         ; 一切与口上相关的
│   │   ├── worldパッチ制作者による超初心者向け口上の書き方入門.txt
│   │   │                                 ; ★★★ 维护者的口上初学者入门（100 行）
│   │   ├── TW口上作成周辺の注訳.txt
│   │   │                                 ; ★★★ 「以口上形式写就的教程」—— 覆盖 IF/ELSEIF/SIF、&&/||、CFLAG、PRINTDATA
│   │   ├── 口上作者様へ.txt
│   │   │                                 ; ★★★★ 权威的 ENCOUNTER/EVENT 1-23/SP_EVENT 1-3 ARG 语义
│   │   ├── 超初心者向け使用頻度の高い変数の説明.txt
│   │   │                                 ; ★★★ FLAG vs CFLAG vs TFLAG vs TCVAR vs TALENT vs ABL vs BASE 一句话解释
│   │   ├── 口上テンプレ/                  ; ★★★★★ 官方空模板 —— 逐字复制进 reference-kojo/口上テンプレ/
│   │   ├── 別人版用口上テンプレ/          ; 同一模板但用于「别人格」变体
│   │   ├── 口上ファイル以外のキャラ別メッセージ等.txt
│   │   ├── 口上作者様へ.txt              ; （同上 —— 见 ★★★★）
│   │   ├── 日記帳れどめ.txt              ; 日记系统文档
│   │   ├── eraTheWorld proto4.11 イベントまとめ(仮)/     ; 较旧的 EVENT 参考（已被取代）
│   │   ├── txt口上ノート/                ; 纯文本口上规划工作表
│   │   └── TW用私製テンプレ/            ; 某作者的另一种模板风格
│   ├── 便利な関数.txt                    ; ★★★★ 第一方 helper 函数参考（ASK_YN, ASK_M, TEXTR, HPH_PRINT, FIRSTTIME, AddEXP）
│   ├── キャラ追加のススメVer.2.0.txt     ; ★★ 如何加一个新角色（CSV 层 + 角色数据 + CHARAMOVE）
│   ├── キャラ設定向け参考資料.txt        ; 角色数值设定指导
│   ├── 改造関連FAQ.txt                   ; ★★ 别用记事本、用 Sakura Editor 等
│   ├── お手軽！…仕事の追加講座.txt     ; 面向非程序员的简易加工作
│   ├── 下着追加のススメ80%版.txt         ; 内衣系统改造教程
│   ├── eTW用コマンド作成例/              ; 命令创建示例（COMF 系统）
│   ├── eratohoTWサクラエディタ用キーワードヘルプ/    ; Sakura Editor 语法高亮
│   ├── MOB子素材作成のすすめ20180409/    ; mob 角色素材创建
│   ├── NewIraiSystem.txt                 ; 新 IRAI（委托）系统
│   ├── CharaXX テンプレ.csv              ; CSV 模板
│   ├── IRAI_XX 依頼テンプレ.ERB          ; 委托模板
│   ├── ROOMSETTING_XX.ERB                ; 房间设定模板
│   ├── IMAGE_IXX_○○ テンプレ.ERB        ; 按角色的图像模板
│   └── DAIRY_EVテンプレ.ERB              ; 日常事件模板
├── 資料/                                 ; 参考表（Shift-JIS 编码 —— 用 --encoding shift_jis 读）
│   ├── 変数一覧/                         ; 权威的变量 ID 表
│   │   ├── CFLAGS.txt                    ; CFLAG:N ID 表（273 行）
│   │   ├── TFLAGS.txt                    ; TFLAG:N ID 表（111 行）
│   │   ├── TCVAR.txt, EXP.txt, FLAGS.txt, EQUIP.txt, TEQUIP.txt, …
│   │   └── 現在位置一覧.txt              ; CFLAG:300（当前位置）ID 枚举
│   ├── 刻印取得条件.txt, 陥落系素質取得条件.txt   ; 特性获得条件
│   ├── 技能成長条件.txt                  ; 技能成长条件
│   ├── MAP.txt, 月マップ全景&ROOMSETTING一覧.txt, 紅魔館マップ全景.txt, 神社周辺見取り図.txt
│   └── 実装済みお仕事一覧.txt            ; 工作目录
├── パッチ/                               ; 60+ 个版本固定的 bugfix 补丁（历史性，多半无关）
└── (etc —— 较旧的 readme、版本说明)
```

### 12.2 哪些已整合进本 skill，哪些还没

| 源文件 | 它在 skill 里的位置 |
|---|---|
| `口上テンプレ/`（整个目录） | 逐字复制到 `reference-kojo/口上テンプレ/` |
| `口上作者様へ.txt`（EVENT 1-23 ARG 语义） | 整合进 `references/01-engine-label-catalog.md` §2.4.2（据模板扩展到 1-34） |
| `便利な関数.txt`（ASK_YN/ASK_M/TEXTR/HPH_PRINT/FIRSTTIME/AddEXP） | 整合进 `references/03-engine-helpers.md` §5.2 / §5.6.1 |
| `worldパッチ制作者による超初心者向け口上の書き方入門.txt`（PRINT 家族、CALLNAME、SETCOLOR 走查） | 该走查的经验烘焙进了此处的 §5–§8 |
| `TW口上作成周辺の注訳.txt`（IF/SIF/&&/PRINTDATA 教程） | 经验烘焙进 §1、§7、§8 |
| `超初心者向け使用頻度の高い変数の説明.txt`（FLAG vs CFLAG vs TFLAG 一句话） | 烘焙进 §5 + `references/02-state-bus-namespaces.md` |
| `日記帳れどめ.txt`（日记系统 0/1/2/3 状态） | 整合进 `references/01-engine-label-catalog.md` §2.4 DIARY 行 |
| `資料/変数一覧/*.txt`（CFLAG/TFLAG/TCVAR ID 枚举） | **未整合** —— skill 假定你去读 `references/data/CFLAG.csv` 等做按槽位查找。这些日文文本文件覆盖同样的数据，但用 Shift-JIS。若用户问「CFLAG:341 干嘛的？」而你的 CSV 里没有，去查 `資料/変数一覧/CFLAGS.txt`。 |
| `キャラ追加のススメVer.2.0.txt`（新角色 CSV 搭建） | **未整合** —— 超出范围（本 skill 只管口上）。若用户想搭建一个*全新角色*（CSV + CHARAMOVE + 角色数据 + 口上），把他们指向此文件。 |
| `パッチ/`（版本固定的 bugfix 补丁） | **未整合** —— 历史性。 |
| `eTW用コマンド作成例/`（命令创建示例） | **未整合** —— 超出范围。 |
| `下着追加のススメ80%版.txt`（内衣改造） | **未整合** —— 超出范围。 |
| `NewIraiSystem.txt`（新委托系统） | **未整合** —— 仅当用户想加一种新委托类型时相关；委托*对话*已覆盖。 |

### 12.3 skill 版本 vs 安装版本

**本 skill 是针对大约 2024-05 时的语料库构建的（源目录上的文件 `mtime`）。** 用户的安装可能更新。eraTW 更新缓慢，且几乎所有更新都向后兼容现有口上，因此你在此看到的 EVENT 槽位号 / CFLAG ID / 标签命名约定应该仍然有效 —— 但要留意：

- **如果用户的安装在 `原版+前人整合等各种readme/口上関連/口上テンプレ/` 里有更新的文件**（例如一个你不认识的名为 `M_KOJO_KX_<新カテゴリ>.ERB` 的文件），信任他们的副本。直接看那个文件 —— 它的文档横幅注释会告诉你它是做什么的。
- **如果用户报告一个本 skill 未记载的标签的引擎警告**（例如 `@M_KOJO_FOO_K20` 触发了警告），建议他们查安装里对应的 ERB 引擎文件。引擎源码是最终权威；本 skill 是一份经整理的摘录。
- **如果用户引用了上表之外的某个教程或模板文件**，让他们分享 —— 它可能是本 skill 上次更新后新增的。

除非用户明确询问本文未覆盖的某样东西，否则你不需要自己扫描该语料库目录。§12 的要点只是：知道它存在、大致知道里面有什么、知道它在安装里的位置。
