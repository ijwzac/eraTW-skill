# 引擎行为文件（behavior .ERB）—— 命令/事件的"语义与分发"来源

> `references/data/` 上一层收的是**枚举表（CSV）**——有哪些槽位/命令/道具/角色。
> 本目录收的是**行为源（.ERB）**——命令怎么派发、设哪些 state、helper 函数干什么。
> 二者互补：写口上遇到"这个命令能读哪些变量""这个 helper 什么意思""这个事件何时触发"，来这里查，别猜。

## 收录的文件

| 文件 | 是什么 | 什么时候查它 |
|---|---|---|
| `KOJO_MESSAGE.ERB` | **口上总分发器**。用 `KOJO_MESSAGE_SEND("EVENT"\|"SP_EVENT"\|"COMMAND"\|"COUNTER"…, slot, ARG, sub)` 把引擎事件拼成 `@M_KOJO_..._K{id}_{…}` 标签派发到各角色口上。**每个调用处都带 `;口上名,ARG,描述` 注释**。 | 想知道"某标签何时触发、各 ARG/sub 什么含义"——这里是权威出处（grep 命令号/事件号看调用处注释） |
| `COMMON.ERB` | **helper 函数库**（2600+ 行）。`@SHIRAHU`(在场可交互)、`@FINDCHARA`、`@GET_TARGETNUM`(房间人数)、`@GROUPMATCH`、`@CHK_DATENOW` 等。 | 想用某个 helper 前，来这里看它的签名与返回语义（grep `@函数名`） |
| `EVENT_MESSAGE_COM300.ERB` | **300 段互动命令的引擎默认叙述**（会話/身体接触/礼物/摸头/拥抱/接吻…）。角色没写该命令口上时用它。 | 想知道某 300 命令**能读哪些 state、怎么读**（默认叙述里有现成 SELECTCASE 示例） |
| `EVENT_MESSAGE_COM400.ERB` | **400 段日常命令的引擎默认叙述**（掃除/训练/料理/吃饭/演奏/午睡/浴室/祈願…）。 | 同上。例：`使用楽器` 的 1-5↔乐器映射就在本文件（约 523 行） |

## 未整体收录、但很重要的（去游戏文件夹查）

- **`ERB\コマンド関連\COMF\…\COMF{命令号} *.ERB`** —— 每个日常/训练命令的**主体逻辑**（做什么、设哪些 TFLAG、对谁生效、如何派发）。共 300+ 文件、3.4MB，太大未打包。查法：按命令号 grep 文件名，例如演奏(416)看 `COMF416 演奏する.ERB`。
- 其余 `EVENT_MESSAGE_COM*.ERB`（500/700/80~/セクハラ/道具系…）、`MOVEMENTS\MOVEMENT*.ERB`（位置/帰宅事件）、`イベント関連\*.ERB`（日记/宴会/祭日等事件驱动）—— 需要时按主题去游戏 `ERB\` 下 grep。

## 用法要点

1. **命令能读哪些 state**：先查 `references/12-命令速查.md`（已消化）；不足再 grep 本目录 `EVENT_MESSAGE_COM{3,4}00.ERB` 或游戏里的 `COMF{号}`。
2. **helper 语义**：grep `COMMON.ERB` 里的 `@函数名`。
3. **标签何时触发/ARG 含义**：grep `KOJO_MESSAGE.ERB` 的调用处注释。
4. 这些是某个可用 eraTW 安装的**精确副本**，作为基准真值；与游戏实际版本若有差异，以游戏当前 `ERB\` 为准。
