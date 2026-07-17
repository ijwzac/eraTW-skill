# 口上之外 —— 更广的游戏改造主题

## 12. 口上之外 —— 更广的游戏改造主题

### 12.1 CSV 层

`CSV/` 存放静态数据表。它们是枚举文件 —— 槽位 id → 名称的映射：

| 文件 | 映射内容 |
|---|---|
| `CFLAG.csv` | 角色标志(character-flag)槽位 ID 到人类可读名称。**对理解口上至关重要**：当你看到 `CFLAG:6:1001` 时，去查 CFLAG.csv 的第 1001 行，就能知道该作者的意图。 |
| `TFLAG.csv` | 回合标志(turn-flag)槽位 ID。 |
| `TCVAR.csv` | 逐目标变量(per-target var)槽位。 |
| `Talent.csv` | 素质，如 `恋慕`、`処女`、`兒童`。 |
| `Abl.csv` | 能力(ability)槽位。 |
| `CSTR.csv` | 逐角色字符串槽位。 |
| `Mark.csv` | 刻印(imprint)槽位。 |
| `Item.csv` | 道具定义。 |
| `Equip.csv`、`Tequip.csv` | 装备。 |
| `Train.csv` | 训练命令 ID。 |
| `Palam.csv` | 参数(parameter)槽位。 |
| `Juel.csv` | 玉(juel)货币。 |
| `Stain.csv` | 体液污渍(stain)槽位。 |
| `Str.csv` | UI 字符串。 |
| `Source.csv`、`ex.csv`、`exp.csv` | 经验曲线(EXP curves)。 |
| `Base.csv`、`GameBase.csv` | 游戏元数据。 |
| `Chara/` | 逐角色静态数据 CSV。每个角色一份。 |

**添加一个新的作者私有 CFLAG 槽位**：编辑 `CFLAG.csv` 加一行（例如 `1234,my_new_flag`）。然后在你的口上里，`CFLAG:N:my_new_flag` 就能用了（`CFLAG:N:1234` 也一样能用）。

### 12.2 其他 ERB 子目录

| 子目录/文件 | 作用 |
|---|---|
| `初期設定.ERB`、`SYSTEM.ERB`、`TITLE.ERB`、`NEWGAME/` | 游戏启动、标题画面、新游戏流程。 |
| `DIM.ERH` | 变量 schema 声明。 |
| `COMMON.ERB` (83 KB) | 引擎通用子程序。 |
| `BATTLE.ERB`、`CASINO/`、`NOUMIN.ERB`、`YASAI.ERB` | 小系统（战斗、赌场、务农、蔬菜）。 |
| `天候*` | 天候子系统（`ERH` 为头文件，`ERB` 为逻辑）。 |
| `時間停止解除.ERB` | 时间停止解除。 |
| `潜伏モード関連/` | 潜伏/潜行模式。 |
| `衣服/` | 服装。 |
| `グラフィック表示ライブラリ/` | 图像显示库。 |
| `ステータス計算関連/` (子目录) | 状态计算：`ABL/`、`ATTITUDE.ERB`、`STAIN.ERB`、`TRACHECK*.ERB`。**回合结束时的好感度台账就在这里。** |
| `ステータス表示関連/` (子目录) | UI：立绘、颜色、BAR、IMAGE、INFO、look。 |
| `キャラデータ/` (子目录) | `Chara_data_<N>_<name>.ERB` —— 运行时加载的角色设置。 |
| `カラム機能/` (子目录) | Column / 面板 UI。 |
| `イベント関連/` (子目录) | 约会事件、祭典、礼物、嫉妒/外遇、怀孕。 |
| `コマンド関連/` (子目录) | 命令系统：`COMABLE/`、`COMF/`、`SCOMF/`、`COMORDER.ERB`。 |
| `SHOP関連/` (子目录) | 商店。 |
| `ALTER/`、`MOVEMENTS/`、`OBJ/`、`COLOREDMAPS/`、`DLC/`、`NEWCHARACTERリソース作成/` | 杂项：换皮、地点、地图、DLC、资源生成。 |
| `method_from_anon/`、`method_from_eratohoЯeverse/` | 来自匿名贡献者的库子程序。 |
| `魔改内容/` | Mod 专属内容。 |

### 12.3 命令系统（`コマンド関連/`）

这是口上所*挂接*的对象。分工如下：

- **`COMF/`**：逐命令的实现文件。文件名内嵌命令 ID：`COMF1 クンニ.ERB`、`COMF12 胸揉み.ERB`、`COMF184 野外プレイ.ERB`。**这些定义命令在机制上做什么**；口上文件提供逐角色的台词。
- **`SCOMF/`**：子命令实现（SCOM 家族）。
- **`COMABLE/`**（`COMABLE.ERB`、`COMABLE_300.ERB`、`_400`、`_500`、`_600`、`_700`、`_80`）：「这条命令当前是否可用？」的门控。数字后缀对应命令 ID 区间。
- **`COMORDER.ERB`**：命令的排序/串联。
- **`USERCOM.ERB`** + **`USERCOM_*`**：用户自定义命令。

命令 ID 命名空间的分区：
| 区间 | 家族 |
|---|---|
| 0–99 | 杂项 / 原始基础（`COMF1 クンニ`、`COMF11 乳首吸い`、`COMF15 クリ愛撫`、`COMF80 手を引く`）。 |
| 100s | SM / 调教（`COMF100 スパンキング`、`COMF105 縄`、`COMF107 拘束プレイ`）。 |
| 120s–140s | 涉及助手 / 进阶。 |
| 180s | 辅助道具 / 情境（`COMF180 ローション`、`COMF184 野外プレイ`）。 |
| **300s** | **日常生活**（会話 300、泡茶 301、身体接觸 302、道歉 303、…）。 |
| **400s** | **家务/训练**（掃除 410、戦闘訓練 411、学习 412、料理 413、吃飯 414、演奏 416、午睡 417、祈願 421、浴室 431、等待 440）。 |
| 500s | （战斗/符卡 —— 需核实。） |
| **600s** | **约会**（約会）。 |
| **700s** | **自慰系**（`700 自慰系/`）。 |
| 80s SCOMF | 派生子命令（TFLAG:50）。 |

新增命令时：选一个尚未被占用的 ID（例如 270-279 是新 API 自定义命令空间）。

### 12.4 天候子系统 —— 「系统插件」范例

`天候システム.ERH`（头文件）、`天候予測システム.ERB`、`天候管理拡張.ERB`、`日時天候管理.ERB`（合计约 220 KB）。这是非口上插件的典范例子：一个自包含的子系统。

**系统插件的模式**：
1. 把 `.ERH` 头文件和 `.ERB` 源文件放进 `ERB/`（或其下的某个子目录）。
2. `.ERH` 为插件的命名空间声明 `#DIM`/`#DIMS`/`#DIM CONST`。
3. `.ERB` 文件声明可从引擎其余部分调用的标签（`@MY_PLUGIN_*`）。
4. 引擎递归扫描，在下次启动时拾取新文件。
5. 要把插件「注册」到既有口上或命令上，就在合适的钩子点添加一个 `CALL MY_PLUGIN_*` 调用。

例子：天候影响口上。`天候*` 系统写入 `TIME:5`（全局天候相位）。body 读取 `TIME:5` 并按天候分支。这里没有「注册」步骤 —— 口上只是读那个全局变量。

对于更复杂的插件（一套新经济系统、一个新小游戏），你可能会：
- 添加一个新的 `MAIN_MAP` ID 来承载这个小游戏。
- 添加一个带游戏逻辑的新 ERB 文件。
- 在 `COMF/` 里注册一个玩家侧命令来进入该小游戏。
- （可选）在每个角色的 `M_KOJO_K{id}_イベント.ERB` 里为该小游戏添加逐角色口上反应。

### 12.5 resources/ 目录

立绘/头像图片。`mkResourceXml.py` 是生成资源 XML 的构建脚本。逐角色图片放在 `resources/<charid>_<key>.webp`（或类似命名）下。口上里的图像显示用 `CALL PRINT_FACE, char, expr, clothes, variant` 来查找对应资源。

添加新的角色图片：
1. 把图片文件（`.webp` / `.png`）加到 `resources/`。
2. 更新 `resources/顔.csv` 以声明新的 key。
3. 在你的口上里，用 `CALL PRINT_FACE, <id>, "<你的-key>", ...` 来使用它。

### 12.6 存档兼容性

持久状态存放在 `sav/`。影响存档格式的变量类型：
- `CFLAG`、`TALENT`、`ABL`、`EXP`、`BASE`、`MARK`、`CSTR`、`DIARY`、`MAX_DIARY_PAGE` —— 逐角色保存。
- `CFLAG` 全局槽位、`FLAG`、`TIME`、`DAY`、`MAIN_MAP` —— 作为游戏状态保存。
- `#DIM SAVEDATA <name>` —— 口上定义的逐角色持久化。
- `#DIM SAVEDATA GLOBAL <name>` —— 口上定义的跨存档持久化。

添加一个新的 `SAVEDATA` 不会破坏旧存档（引擎会对缺失项补零）。删除一个*会*破坏 —— 旧存档里仍有该值，但运行时不再关心它。

版本升级时的存档迁移：实现 `@KOJO_VERSION_UPDATE_K{id}`，读取旧值、转换、写入新槽位（仅限自定义 API）。

---
