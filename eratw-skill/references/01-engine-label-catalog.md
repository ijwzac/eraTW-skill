# 引擎可调用标签总目录（完整参考）

本文件收录引擎知道如何派发进入的每一个标签的完整清单，包括口上选择器（kojo-selector）机制、MESSAGECHECK / EXTRASOURCE / 自定义 API 扩展，以及作者扩展惯用法。

标签前缀里**方括号包住的 `[%RESULTS%_]` 槽位**含义是：「若设置了口上选择器，引擎会把它插到这里」。大多数角色把它留空。

### 2.4 引擎可调用标签 —— 完整清单

你只需记住这些。不在本清单里的一切都是作者私有的（可以定义，但引擎不会直接调用它）。

**每角色生命周期**（各一个，可选）：
| 标签 | 何时运行 |
|---|---|
| `@M_KOJO_K{id}(ARG)` | 存在性检查。必须 `RETURN 1`。设置 `RESULTS = "_<NAME>"` 以声明一个选择器（罕见）。 |
| `@M_KOJO[%RESULTS%_]FLAGSETTING_K{id}` | 每回合。初始化 `CFLAG:N:<flag>` 并跑每回合的状态机 tick。 |
| `@M_KOJO[%RESULTS%_]COLOR_K{id}` | 每行。为角色嗓音 `SETCOLOR`。 |
| `@M_KOJO[%RESULTS%_]UPDATE_K{id}` | 每次载入某游戏版本一次。权限类 UI（授予素质、选昵称）。 |

**初遇 / 一次性剧情**：
| 标签 | 何时运行 |
|---|---|
| `@M_KOJO[%RESULTS%_]ENCOUNTER_K{id}` | MASTER 首次遇见该角色。 |
| `@M_KOJO[%RESULTS%_]SPEVENT_K{id}_{ev}(ARG, ARG:1)` | 脚本化特殊事件 `ev`。ARG 选择子状态（0 = 提议, 1 = 接受, 2 = 拒绝, 等）。body 通常以 `CALL SPEVENT_MESSAGE_{ev}(ARG, ARG:1)` 开头以打印引擎默认旁白。 |

**通用事件**（这些会 PRINT 出消息文本）：

| 标签 | 参数 | ARG 的含义 |
|---|---|---|
| `@M_KOJO[%RESULTS%_]EVENT_K{id}_{ev}(ARG, ARG:1)` | `ev` = 引擎事件槽 1..34（完整 ARG 映射：§2.4.2；cell 守卫的理由：§2.4.1） | **`ev=1` 是房间/cell 遭遇 —— 每当该角色在同一世界地图上做一次 cell 切换就会触发一次，即使 MASTER 身处不同 cell 也会触发。务必先用 `SIF CFLAG:{id}:現在位置 != CFLAG:MASTER:現在位置 / RETURN 0` 守卫 body，再按 ARG 子阶段分支。** |
| `@M_KOJO[%RESULTS%_]EVENT_K{id}_GIFT(ARG, GIFT_ID, 評価点, GIFT_NAME, SENSE)` | 5 参数 | 礼物事件。body 必须在前四行 `#DIM GIFT_ID / #DIM 評価点 / #DIMS GIFT_NAME / #DIMS SENSE`。**ARG 取值**：1 = 约会归来赠礼（701-999 分，需亲密度 5+），2 = 日终「宝物」（≥700），3 = 「最爱」（≥700 且最高分），4 = 「收藏起来」（400-699），5 = 「偷偷典当」（<400）。用 `STRCOUNT(SENSE, "<token>/")` 测试礼物属性标签。`GET_GIFTDATA(GIFT_ID, "<key>")` 可取出 回数 / 得点 / 日付 / 場所 / 形容詞 / 本体。 |
| `@M_KOJO[%RESULTS%_]DAILY_EVENT_K{id}_{n}(ARG, ARG:1, ARG:2, ARG:3, ARG:4, ARGS:1, ARGS:2)` | 7 参数 | 带完整状态向量的每日事件。已知槽位：`_2` = 夢精（梦遗 —— 当 MASTER 具 濃厚精液 素质时发生），`_4` = 物思い（沉思 —— 在拜访角色亲密度 ≥5 时自动触发），`_12` = 特訓（战斗训练 —— 居住角色信賴 ≥100 时；`ARG:1` 是子步骤 1=请求/2=拒绝/3=攻击/4=闪避/5=闪避失败）。与 `@M_KOJO_DAILY_EVENT_MESSAGECHECK_K{id}_{n}` 配对以在覆盖时抑制引擎旁白。 |
| `@M_KOJO[%RESULTS%_]EVENT_K{id}_ONABARE_1(ARG)` | 1 参数 | 可选覆盖：替换引擎默认的「MASTER 撞见 TARGET 自慰」旁白。`ARG = 1` 表示走后门，否则走正门。不使用时用 `[SKIPSTART]/[SKIPEND]` 包住（模板默认）。 |
| `@M_KOJO[%RESULTS%_]EVENT_K{id}_ONABARE_2(ARG)` | 1 参数 | 可选覆盖：替换引擎的「TARGET 仍继续下去」旁白。ARG 语义同 `_1`。 |
| `@M_KOJO[%RESULTS%_]EVENT_K{id}_ONABARE_3(前戯１, 本番はどっちか, 回数, 注入量)` | 4 参数 | 可选覆盖：替换引擎的「MASTER 加入」4 步旁白。自定义参数名；body 必须在前四行 `#DIM 前戯１ / #DIM 本番はどっちか / #DIM 回数 / #DIM 注入量`（依 §1 陷阱 #1）。`前戯１`：1=C/2=B/3=M 的反应度。`本番はどっちか`：0=正门, 1=后门。 |
| `@M_KOJO[%RESULTS%_]EVENT_K{id}_26_1(ARGS)` | 1 参数字符串 | 对 `EVENT_K{id}_26`（オナバレ 被撞见自慰）动作选择的预判定。`ARGS` 是玩家所选动作（`"どうぞそのまま"` / `"二人で"` / ...）。**返回契约**：`RETURN -1` 强制失败该动作，`RETURN 1` 强制成功，`RETURN 0` 使用引擎的常规判定。 |

**不打印的通用事件**（静默控制流 / 状态机；在它们 body 里打印会导致每 tick 刷屏玩家）：

| 标签 | 参数 | 作用 |
|---|---|---|
| `@M_KOJO[%RESULTS%_]EVENT_K{id}_GRAVITY(ARG)` | 1 参数 | **静默的 NPC-AI 移动引力吸引点 —— 尽管名字叫 gravity，它并不是风味「重力」事件。** 引擎在每个 NPC 移动决策 tick（一回合内多次）都会触发它。body 必须设置 `TCVAR:{id}:引力点 = <location-code>` 来影响 AI 的目的地，且**绝不能**调用任何 `PRINT*`。默认 `TCVAR:{id}:引力点 = 0`。规范范式见 K30 映姬的 `EVENT_K30_GRAVITY`。 |
| `@M_KOJO[%RESULTS%_]EVENT_K{id}_LOST_VIRGIN_STOP(ARG)` | 1 参数 | 静默。**前置条件**：必须在 `FLAGSETTING_K{id}` 里设置 `CFLAG:{id}:破瓜中止口上有 = 1`，否则该标签永不被派发。**body 返回契约**：`RETURN 1` 中止破瓜流程，`RETURN 0`（或直接落穿）则正常进行。（引擎在派发后经 `TRACHECK_LOST_VIRGIN.ERB:392-399` 读 `RESULT == 1`。不存在 `TFLAG:中止破瓜` 槽。） |
| `@M_KOJO[%RESULTS%_]EVENT_K{id}_PERMISSION_<n>(ARG)` | 1 参数 | 静默。两个槽位：`PERMISSION_1` = 初次押し倒し（推倒）尝试，`PERMISSION_2` = 两情相悦的押し倒し。**前置条件**：`_1` 需 `CFLAG:{id}:口上内抱き寄せ判定_初回 = 1`，`_2` 需 `CFLAG:{id}:口上内抱き寄せ判定_通常 = 1` —— 必须在 `FLAGSETTING_K{id}` 里设置，否则 body 永不被派发。**body 返回契约**：`RETURN -1` = 拒绝（强制中止），`RETURN 0` = 使用引擎常规判定，`RETURN 1` = 无条件成功（强制允许）。记录这些的规范注释块见 `007 Star [スター]/スターサファイア/M_KOJO_K7_イベント.erb:4658-4677`。 |
| `@K{id}_BEFORETRAIN` | 无 | 静默。每角色的日初状态机初始化。读 `BASE/CFLAG/TCVAR`，写其他 body 会分支判断的 `CFLAG/TCVAR` 标志。 |

**玩家命令**：
| 标签 | 何时运行 |
|---|---|
| `@M_KOJO[%RESULTS%_]SUCCESS_COM_K{id}_{cmd}` | 可选。设置 `TFLAG:192` 以覆盖（-2 结束 / -1 失败 / 0 默认 / 1 大成功）。否则就 `TFLAG:192 = 0`。 |
| `@M_KOJO[%RESULTS%_]MESSAGE_COM_K{id}_{cmd}` | 每命令的话语。**惯例**：以 `CALL TRAIN_MESSAGE`（引擎默认旁白）开头，再 `CALL <body_label>` 调到一个 `_<cmd>_1` body 标签。 |
| `@M_KOJO[%RESULTS%_]MESSAGE_COM_K{id}_00` | **对每个未定义 cmd 都会触发的兜底**，不是「罕见」回退。若你在这里写丰富的 body 文本，玩家在每个 R18 / 未实现命令后都会看到它。默认应 `LOCAL = 0 / RETURN 0`（静默落穿到引擎旁白），除非你确实想在每个未定义 cmd 上都出同一句相同的台词。 |
| `@M_KOJO[%RESULTS%_]MESSAGE_SCOM_K{id}_{cmd}` | 子命令（由 TFLAG:50 驱动）。对多人 SCOM：`_<cmd>_1` 是第一个参与者，`_<cmd>_2` 是第二个；引擎会交换 TARGET。 |

**自动反击 / 待机反应**：
| 标签 | 备注 |
|---|---|
| `@M_KOJO[%RESULTS%_]MESSAGE_COUNTER_K{id}_{n}` | `n` = counter ID（1-100 多）。先 `CALL EVENT_COUNTER_MESSAGE` 再 body。 |
| `@UNIQUE_COUNTER<n>_ABLE_K{id}` | 角色专属 counter 的资格。`RETURN 0/1`。 |
| `@UNIQUE_COUNTER<n>_FREQUENCY_K{id}` | 设置 `RESULTS = "<type>"`（取值之一：`ソフト/ベリーソフト/コミュ/着衣/脱衣愛撫/脱衣強要/抱き着き/性交/責め/おねだり`）。`RETURN <freq>`（基准 + 10 = 引擎基线）。 |
| `@UNIQUE_COUNTER<n>_MESSAGE_K{id}` | 打印 body。 |
| `@UNIQUE_COUNTER<n>_SOURCE_K{id}` | 副作用：`SOURCE:N:<slot> += N`、`CALL TOUCH_SET(...)`、`CALL DATUI_BOTTOM(...)` 等。 |

**战斗 / 委托 / 刻印**：
| 标签 | 备注 |
|---|---|
| `@M_KOJO[%RESULTS%_]MESSAGE_COM_K{id}_DANMAKU(ARGS, ARG)` | 单一标签。**用 `ARG` 作第二参数名，不要用自定义的 `相手残機`** —— Emuera 编译器拒绝自定义参数名；只有 `ARG/ARG:N/ARGS/ARGS:N` 合法。用注释标注用途：`;ARG = 相手残機 (对手剩余残机)`。某些既有口上（K5/K6/K7）用 `(ARGS, 相手残機)` + 紧随其后的 `#DIM 相手残機` 绕过它 —— 那种写法能用，但在载入时会产生 Lv2 警告；新口上首选简单的 `(ARGS, ARG)` 形式。由 `ARGS` 字符串选择场景：`"戦闘前"`、`"ハンデ"`、`"被弾"`、`"残忍酷薄"`、`"乾坤一擲"`、`"怪力乱神"`、`"戦闘後"`。 |
| `@M_KOJO[%RESULTS%_]IRAI_K{id}(ROLE, SCENE, IRAI_ID)` | 委托（quest）。`ROLE` ∈ `"CLIENT"/"TARGET"/"NO_REPORT"`。`SCENE` ∈ `"依頼提示時"/...・/"成功報告時"/"失敗報告時"`。 |
| `@M_KOJO[%RESULTS%_]MESSAGE_MARKCNG_K{id}` | **在每个*可能*影响刻印的动作后都会触发**，而非仅在刻印实际发生迁移时。body 必须在打印任何内容前用 `SIF !TFLAG:21 && !TFLAG:22 && !TFLAG:23 && !TFLAG:24 && !TFLAG:時姦刻印取得 / RETURN 0` 守卫，否则会在大多数动作后刷一句通用台词。 |

**日记**：
| 标签 | 备注 |
|---|---|
| `@DIARY_K{id}_EXIST` | 返回 1 以声明支持日记。 |
| `@DIARY_BEFORE_CHECK_K{id}` | 根据游戏状态更新 `DIARY:N:M` 槽位状态。 |
| `@DIARY_TEXT_K{id}, PAGENUM, MODE, PAGECOUNT` | body。`MODE` ∈ `"デイリー"`（自动日终）/ `"指令"`（命令 406）。**body 必须在 `@` 头行之后的前三行用 `#DIM PAGENUM` / `#DIMS MODE` / `#DIM PAGECOUNT` 声明这些自定义命名参数**，否则 Emuera 在载入时抛 警告Lv2（「本函数内变量未定义」），且读取这些变量会失败。这与 §1 陷阱 #1 是同一条 Emuera 规则 —— 规范范式另见随 skill 附带的 `reference-kojo/luna-K6/M_KOJO_K6_日記.ERB`（`@DIARY_TEXT_K6` 的头三行声明）。 |
| `@DIARY_AFTER_CHECK_K{id}` | 每日清理。 |
| `@M_KOJO_MESSAGE_COM_K{id}_406` | 「读日记」命令 body。 |

**高潮 / 绝顶**：
| 标签 | 备注 |
|---|---|
| `@M_KOJO[%RESULTS%_]MESSAGE_PALAMCNG_A_K{id}` | A 级（动作后）。 |
| `@M_KOJO[%RESULTS%_]MESSAGE_PALAMCNG_A2_K{id}` | A 级次级。 |
| `@M_KOJO[%RESULTS%_]MESSAGE_PALAMCNG_B_K{id}` | B 级（高潮）。按 `NOWEX:Ｃ絶頂/Ｖ絶頂/Ｂ絶頂/Ａ絶頂/Ｍ絶頂/射精/噴乳/放尿/TotalEX`、`SYNCED_ORGASM(N)`、`TEQUIP:Ｖ接触部位` 分支。 |
| `@M_KOJO[%RESULTS%_]MESSAGE_PALAMCNG_B2_K{id}` | B 级次级。 |
| `@M_KOJO[%RESULTS%_]MESSAGE_PALAMCNG_F_K{id}` | F 级回退。 |

**育儿**：
| 标签 | 备注 |
|---|---|
| `@M_KOJO_EVENT_K{id}_CHILD_RAISING_<key>` | 生命阶段里程碑。`<key>` ∈ `回復/離乳/玩具/つかまり立ち/よちよち/会話寸前/喋る/語彙/しつけ/就学/自立前/自立`。 |
| `@M_KOJO_EVENT_K{id}_CHILD_RAISING_<activity>(ARGS, ARG, ARG:1)` | 各生命阶段的每日活动。`<activity>` ∈ `登下校/吃飯/BATH/SLEEPING/OYASUMI/TOY/OTHER`。`ARGS` = `"幼児期" / "幼少期" / "授乳" / "離乳食" / ...`。 |
| `@M_KOJO_EVENT_K{id}_CHILD_DIARY_口上手紙(ARG)` / `_共通手紙(ARG, ARGS)` / `_寺子屋(ARGS, ARG, ARG:1)` | 书信 / 学堂事件。 |

**信息界面**：
| 标签 | 备注 |
|---|---|
| `@CHARA_INFO_KOJO_K{id}()` | 覆盖 角色介绍（「character info」）标签页。body 打印描述；可按游戏状态分支。 |

**钩子（较不常用）**：
| 标签 | 备注 |
|---|---|
| `@SPECIALDAY_EVENT_K{id}` | 纪念日 / 节日。按 `DAY:2`（月）和 `DAY:3`（日）分支。**⚠ 引擎不会派发它** —— 引擎的 `KOJO_MESSAGE` 路由器从不构建 `SPECIALDAY` 标签。它是一个你必须自己从真实引擎事件里 `CALL` 的口上内部子例程（惯例：在 `@M_KOJO_EVENT_K{id}_1` 内、经过日期检查后调用 —— 见 こいし K38 的 `M_KOJO_K38_イベント.ERB` 里 `CALL SPECIALDAY_EVENT_K38`）。定义了它却没有匹配的 `CALL` = 死代码（永不触发）。 |
| `@K{id}_BEFORETRAIN`（或 `@M_KOJO[%RESULTS%_]_BEFORETRAIN_K{id}`） | 日初状态机。 |
| `@RUN_INTO_K{id}(MAP_ID)` | 地图上的随机遭遇。 |
| `@KOJO_SF_CONTRACT_EVENT_K{id}(ARGS)` | 「セフレ」（炮友）约定。 |
| `@M_KOJO_CHECK_K{id}_IRAI_BLOCKED(ARGS, ARG, ARG:1)` | 委托阻断谓词。 |
| `@M_KOJO_DIARYSETTING_K{id}(ARG)` | 日记状态设置辅助。 |

### 2.4.1 EVENT_K_X 子阶段参考（各槽的 ARG 取值）

引擎会在一回合内**多次**触发若干 EVENT 槽，用 `ARG` 区分子阶段。**如果你忽略 ARG**，body 会对每个子阶段都触发（每次拜访 3-5 次），台词会重复打印。务必按 ARG 分支，并在每个分支里 `RETURN 0`（以便其他子阶段还能匹配）。

权威 ARG 语义（提取自 001 Reimu / 霊夢 参考）：

**`@M_KOJO_EVENT_K{id}_1(ARG, ARG:1)` —— 房间/cell 遭遇。** 每当该角色**在与 MASTER 同一世界地图上做一次 cell 切换**时触发一次，即使 MASTER 身处不同 cell。**强制的首个守卫：**
```erb
@M_KOJO_EVENT_K{id}_1(ARG, ARG:1)
LOCAL = 1
SIF !LOCAL || FLAG:時間停止
    RETURN 0
;引擎在每次 NPC cell 移动时都触发本标签。不同处一室时拒绝：
SIF CFLAG:{id}:現在位置 != CFLAG:MASTER:現在位置
    RETURN 0
;然后按 ARG 子阶段分支：
SELECTCASE ARG
    CASE 1   ;MASTER 走进来，角色已在房内
        ...
        RETURN 0
    CASE 2   ;角色走进来，MASTER 已在房内
        ...
        RETURN 0
    CASE 3   ;MASTER 洗澡时角色进浴室 —— 一起入浴
        ...
        RETURN 0
    CASE 4   ;角色进浴室，礼貌退出
        ...
        RETURN 0
    CASE 5   ;角色进浴室，被 MASTER 赶出去
        ...
        RETURN 0
ENDSELECT
RETURN 0
```

**`@M_KOJO_EVENT_K{id}_2(ARG, ARG:1)` —— 早晨。** 对与 MASTER 同一世界地图上的每个角色、每天早晨都触发 —— 即使角色身处不同 cell。**需要同样的首个守卫：**
```erb
SIF CFLAG:{id}:現在位置 != CFLAG:MASTER:現在位置
    RETURN 0
```

**`@M_KOJO_EVENT_K{id}_3(ARG, ARG:1)` —— 睡眠相关。** 与 `_2` 相同的「地图 vs cell」区分。需要同样的守卫。
⚠**别把它理解成「在就寝時間触发一次」**——派发源是 `ERB\MOVEMENTS\SLEEP.ERB @CHARA_SLEEP`，它在**该角色的整个睡眠时段内、只要 MASTER 与她同格**就可能每回合派发一次。所以「玩家在她起床時間之前把她吵醒、试图互动」也会走这里（`ARG=2` 困倦），**不要在 `ARG=2` 的台词里写死「都几点了还不睡」这类时刻**——清晨同样会触发。

**为什么从引擎源码看不明显**：`KOJO_MESSAGE.ERB` 里的派发器不按当前 cell 过滤；它只按*地图存在*过滤。cell 检查是口上自己的责任。大多数参考口上都含有这个守卫，但它们没有强调它 —— 必须靠读代码才能观察到。

### 2.4.2 完整 EVENT-槽 ARG 映射（槽 1-34）

依官方模板（`reference-kojo/口上テンプレ/M_KOJO_KX_イベント.ERB`）并与权威的 `口上作者様へ.txt`（槽 1-23）交叉核对。槽 24-34 仅在模板中有记录。

| 槽 | 名称 | ARG | ARG:1 | 备注 |
|---:|---|---|---|---|
| 1 | 部屋で遭遇（房间/cell 遭遇） | 1=MASTER入室時 char居 / 2=char入室時 MASTER居 / 3=char入浴, 一緒に入る / 4=char入浴, 出ていく / 5=char入浴, 追い出される / 6=外出先で遭遇 / 7=他キャラとデート中 / 8=MAIN_MAP初挨拶 / 9=外出先初挨拶 | 仅 7：デート相手 / 仅 9：デート相手(0=独り) | **强制 cell 守卫**（§2.4.1） |
| 2 | おはよう（早晨） | 1=通常起床 | — | **强制 cell 守卫** |
| 3 | おやすみ（**睡眠相关，不只是就寝那一刻**） | 1=自室に帰って寝る（`ARG:1` 0=普通 / 1=约会中に帰って寝る）/ **2=眠そう＝困倦（被吵醒、`CFLAG:延迟`、或被赶出寝室后）** / 3=睡眠中 / 5=衰弱して寝る / 6=（`ARG:1` 0/1）/ 7=（`ARG:1` 0=そのまま寝た / 2=中止与他角色的Ｈ后睡）/ 8=被留下「稍微休息一下」/ 9=在寝室当场败给睡魔 / 10=拠点外角色在自宅前回去睡 | — | **强制 cell 守卫** |
| 4 | 移動すれ違い（擦身而过） | 1=立ち止まる / 2=軽く会釈 / 3=無視 | — | |
| 5 | 他者介入ムード変化 | char id | 介入者id | |
| 6 | 情事目撃 | char id | 情事の相手 id | ARG:2: 1=低 / 2=高(参加) / 3=立ち去り |
| 7 | 情事見られた | char id | 目撃した相手 id | ARG:2: 同上 |
| 8 | 情事問い詰め | char id | 問い詰め者 id | ARG:2: 1=MASTER説教 / 2=二人説教 |
| 9 | 弱み握られ | char id | 1=同居場で / 2=遠距離移動中 | 仅初回 |
| 10 | 押し倒され | char id | 1=押し倒した / 2=なだめた | 触发反击 |
| 11 | 浴場遭遇 | char id | 1=追い出された / 2=目が合った | 仅 MASTER 入浴时 |
| 12 | 忍び込み時 | char id | 1=侵入時 / 2=怒り中 | ARG:2: 1=通常 / 2=恋慕 / 3=恋慕衰弱 / 4=追出 / 5=追出衰弱 |
| 13 | 仕事中 | char id | 1=開始 / 2=業務中 / 3=終了 | ARG:2: 業務中时为残量(3>2>1), 終了时为 MASTER 劳动量 |
| 14 | 食事系 | char id | -1=食べられた | 持有食物时遭遇 |
| 15 | 押し倒し | char id | 1= / 2=終了 | MASTER 侧 |
| 16 | 添い寝 | char id | 2=終了 | 抽身时 |
| 17 | 時止め終了 | char id | 1=謎の快感 / 2=絶頂 / 3=パンツ強奪 / 4=【無自覚口内射精】 / 5=【無自覚顔面射精】 / 6=【無自覚手淫射精】 / 7=【無自覚アナル射精】 / 8=【無自覚処女喪失】 / 9=【無自覚膣内射精】 | ARG:2 视情况 | 参照模板 |
| 18 | ナマでやらせろ | char id | 1=避妊要求 / 2=断った / 3=粘られて切れた / 4=危険日以外許可 / 5=危険日許可 | |
| 19 | 神社暮らし承認 | char id | 1=住み込み決定後 / 2=お断り時 | |
| 20 | 非住み込み帰宅 | char id | 1=通常帰宅 / 2=デート中帰宅 | 归宅地の文之前 |
| 21 | 陥落素質取得 | char id | 1=恋慕 / 2=思慕 / 3=愛欲 / 4=愛人 / 5=セフレ | 就寝后 |
| 22 | 就寝時自慰 | char id | 1=自慰 | 就寝后 |
| 23 | 浴場連れ出し | char id | 1=入浴拒否 / 2=入浴許可 | 连出中 → 移动到浴室时 |
| 24 | 懐妊（怀孕） | 1=恋慕 / 2=思慕 / 3=陥落素質無し / 4=無自覚 | — | |
| 25 | 出産（分娩） | 同上 | 第几个孩子 | |
| 26 | オナバレ（被撞见） | 0=見られた瞬間 / 1=何もしない / 2=そのまま続行 / 3=追い出し / 4=やっちゃう / 5=事後 / 6=事後お泊り | — | 与 `EVENT_K{id}_26_1(ARGS)` 配对做动作选择预判定（见上文 §2.4）。 |
| 27 | 相手からデート誘い | 0=誘い文句 / 1=受けた / 2=断った / 3=部屋に誘われた / 4=受けた / 5=断った | 目的地 | |
| 28 | 脱衣 | 0=全裸 / 1=下着 / 2=半脱ぎ / 3=パンツちょうだい | 仅 ARG=3: 0=交換 / 1=OK嬉々 / 2=OK渋々 / 3=嫌 | |
| 29 | 怒り | 1=怒らせた / 2=泣かせた(臆病) | TARGET 的度胸 | |
| 30 | 押し倒し解除（相手側） | 1=疲れた / 2=満足解放 / 3=満足→押し倒された / 4=壊れるまで | — | TARGET 主导 |
| 31 | 一日終了時 | 会ってない日数 | — | 无面识则不被调用。用 `CALL EVENTEND_TSUBUYAKI` 在口上前呼出发生文。 |
| 32 | 自由行動中 | 0=考え事 / 1=遊ぶ / 2=食事 / 3=つまみ食い / 4=掃除 / 5=運動 / 6=読書 / 7=料理 / 8=演奏 / 9=採集 / 10=釣り / 11=実験 / 12=のんびり / 13=晩酌 / 14=買い物 / 15=説教 / 16=落とし穴 / 17=雪だるま / 18=炬燵 | 0=行動中 / 1=完了時 | 技能系仅在技能Lv≥1时 |
| 33 | ハッピーニューイヤー | — | — | 跨年瞬间同室 |
| 34 | 技能レベルアップ | 1=戦闘 / 2=話術 / 3=清掃 / 4=教養 / 5=料理 / 6=採集 / 7=音楽 / 8=釣り / 9=調合 / 10=伐採 / 11=指 / 12=舌 / 13=胸 / 14=腰 / 15=膣 / 16=アナル | 一部在取得素质时为 1+(0=技能, 1=素質) | 升级后的值 |

### 2.4.3 特殊的「用 RESULTS 而非 PRINT」标签

这些标签**不**使用 `PRINT*` —— 引擎在 body 返回后从 `RESULTS` 读一个字符串，自行渲染它（带自动格式化与换行）。在里面放 `PRINTFORML` 会破坏显示。

| 标签 | 参数 | body 契约 |
|---|---|---|
| `@M_KOJO[%RESULTS%_]MESSAGE_COM_K{id}_MUSHI_BATTLE(ARGS, ARG)` | (字符串 scene, 整数) | 虫斗对话。`ARGS` 选择场景：`"試合前"` / `"戦場に出した"` / `"攻撃時"` / `"倒れた時"` / `"敗退時"` / `"タイマン：勝ち"` / `"タイマン：負け"` / `"バトルロイヤル：優勝"` / `"バトルロイヤル：２位以下"` / `"チーム戦：勝ち"` / `"チーム戦：負け"`。`ARG` = 剩余虫数或名次。**写 `RESULTS = "<line>"` 然后 `RETURN 1`。** 行长上限：`試合前` 50 字，其余 40 字。`%MUSHI_NAME%` 在字符串内可用。 |
| `@M_KOJO[%RESULTS%_]MESSAGE_COM_K{id}_SUIKA(ARGS, ARG)` | (字符串 cue, 整数) | 西瓜割（suikawari）方向指令喊话。`ARGS`：`"衝突"` / `"そこだ！"` / `"近い"` / `"遠い"` / `"かなり遠い"` / `"前"` / `"少し前"` / `"後ろ"` / `"少し後ろ"` / `"右"` / `"少し右"` / `"左"` / `"少し左"` / `"結果"`。**写 `RESULTS = "<line>"`。** `RESULTS = %TEXTR("A/B/C/")%` 在里面可用（随机选取）。多数 cue 有 26 字上限；`衝突` 和 `結果` 无上限（并自动上色）。`結果` 分支按 `TFLAG:193`（-1 失败 / 0 成功 / 1 大成功 / 2 木刀加成）和 `ARG`（0=正直 / 1=ウソつき）判断。 |

### 2.5 MESSAGECHECK 家族 —— 强大却极易被忽略的派发钩子

在调用任何 `*MESSAGE*` body 之前，引擎会*先*查找一个平行的 `*MESSAGECHECK*` 标签。**大多数口上作者不用它**，所以在日常搭架子的工作里不必提及 —— 但当用户要一个*有电影感*的事件（「我想让她的台词完全替换掉引擎默认旁白」）时，这就是那个机制。该标签返回一个**位域**：
- `bit 0` = 1：抑制引擎默认旁白（即「情景文本」—— 也就是 `TRAIN_MESSAGE` / `EVENT_COUNTER_MESSAGE` / `MARK_MESSAGE` / `SPEVENT_MESSAGE_<n>` 前置旁白）。
- `bit 1` = 1：抑制口上自身的消息 body。

所以：
- `RETURN 0` → 两者都显示。
- `RETURN 1` → 只显示口上（隐藏引擎旁白）。
- `RETURN 2` → 只显示引擎旁白（隐藏口上）。
- `RETURN 3` → 两者都隐藏（静默）。

你**也可以在 MESSAGECHECK body 内部打印自定义旁白**，再返回合适的位以抑制重复。

完整的 MESSAGECHECK 家族（如有需要，把每个 message 标签与之配对）：

| 配对标签 | 位置 |
|---|---|
| `@M_KOJO[%RESULTS%_]MESSAGE_MESSAGECHECK_COM_K{id}_{cmd}` | 与 `MESSAGE_COM_K{id}_{cmd}` 配对。 |
| `@M_KOJO[%RESULTS%_]MESSAGE_MESSAGECHECK_SCOM_K{id}_{cmd}` | 与 `MESSAGE_SCOM_K{id}_{cmd}` 配对。 |
| `@M_KOJO[%RESULTS%_]SPEVENT_MESSAGECHECK_K{id}_{ev}` | 与 `SPEVENT_K{id}_{ev}` 配对。 |
| `@M_KOJO[%RESULTS%_]EVENT_MESSAGECHECK_K{id}_{ev}` | 与 `EVENT_K{id}_{ev}` 配对。 |
| `@M_KOJO[%RESULTS%_]MESSAGE_COUNTER_MESSAGECHECK_K{id}_{n}` | 与 `COUNTER_K{id}_{n}` 配对。 |
| `@M_KOJO[%RESULTS%_]MESSAGE_MARKCNG_MESSAGECHECK_K{id}` | 与 `MARKCNG_K{id}` 配对。 |
| `@M_KOJO[%RESULTS%_]DAILY_EVENT_MESSAGECHECK_K{id}_{n}` | 与 `DAILY_EVENT_K{id}_{n}` 配对。 |
| `@M_KOJO[%RESULTS%_]MESSAGE_PALAMCNG_MESSAGECHECK_A_K{id}_{n}` | 与 `PALAMCNG_A_K{id}` 配对。 |
| `@M_KOJO[%RESULTS%_]MESSAGE_PALAMCNG_MESSAGECHECK_A2_K{id}_{n}` | 与 `PALAMCNG_A2_K{id}` 配对。 |
| `@M_KOJO[%RESULTS%_]MESSAGE_PALAMCNG_MESSAGECHECK_B_K{id}_{n}` | 与 `PALAMCNG_B_K{id}` 配对。 |

这些是可选的。当你想在某一行上抑制引擎默认的「X 说着话。」表头时使用 —— 电影感过场里常见。

### 2.6 EXTRASOURCE 家族

在一个消息 body 运行之后，引擎会查找 EXTRASOURCE 标签以施加额外的 `SOURCE:N:<slot>` 账本更新：

| 标签 | 何时运行 |
|---|---|
| `@M_KOJO[%RESULTS%_]EXTRASOURCE_COM_K{id}_{cmd}` | 每命令之后。 |
| `@M_KOJO[%RESULTS%_]EXTRASOURCE_COM_K{id}_GENERAL` | 兜底。 |
| `@M_KOJO[%RESULTS%_]EXTRASOURCE_SCOM_K{id}_{cmd}` | 每 SCOM 之后。 |
| `@M_KOJO[%RESULTS%_]EXTRASOURCE_SCOM_K{id}_GENERAL` | 兜底。 |

当你想根据玩家状态施加不同的 SOURCE 增量、又不想把逻辑散落到许多命令 body 里时使用。

### 2.7 新的「custom」API（仅现代引擎）

某些角色附带一个 `カスタム.ERB`（或 `of_new_kojo_api.ERB`）文件，使用一套**面向作者自定义命令与 UI 按钮的扩展派发家族**。这仅被较新的引擎版本支持。若你的口上必须能在旧引擎上运行，用 `[SKIPSTART]/[SKIPEND]` 把文件包住。

| 标签 | 作用 |
|---|---|
| `@KOJO_CUSTOM_BUTTON_CONDITION_K{id}_{Y}` | 返回 1 以显示按钮 `Y`（范围 0-9）。设置 `custom_button_name:{id}:{Y} = "<label>"`。 |
| `@KOJO_CUSTOM_BUTTON_K{id}_{Y}` | 按钮 `Y` 的点击处理器。 |
| `@KOJO_CUSTOM_TALENT_SET_K{id}` | 填充 `CUSTOM_TALENT:{id}:{slot}` + `_NAME` + `_COLOR`（0=普通/1=粉/2=红+粗体）+ `_TYPE`（1=种族/2=性/3=身体/4=精神/5=技术/0=其他）。渲染在 角色介绍 标签页。 |
| `@KOJO_COM_NAME_K{id}_{Y}` | 在 `RESULTS` 里返回命令名字符串。`Y` 是 0..9。 |
| `@KOJO_COM_ABLE_K{id}_{Y}` | 若命令 `Y` 当前可用则返回 1。 |
| `@KOJO_COM_K{id}_{Y}` | body。返回 1 = 执行, 0 = 取消但保留 source, -1 = 取消并跳过 source。 |
| `@KOJO_CAN_COM_K{id}_{Y}` | 可入队谓词。 |
| `@KOJO_VERSION_K{id}` | 返回该角色的口上版本（语义化）。 |
| `@KOJO_VERSION_UPDATE_K{id}` | 存档迁移钩子。 |

自定义命令映射到引擎命令空间的偏移 `270 + Y`（所以自定义 0 = 命令 270）。钩子之后，消息 body 使用标准的 `@M_KOJO_MESSAGE_COM_K{id}_{270+Y}` 形式。

### 2.8 口上选择器（RESULTS 中缀）—— 以及多变体如何运作

一个角色目录可以**同时包含多个作者变体子目录**：

```
個人口上/049 Satori [さとり]/
├── さとり/                          ← 变体 A
├── さとり(24.5.14)/                 ← 变体 B
└── 古明地觉_试制口上v0.053/        ← 变体 C
```

引擎在启动时会**全部载入** —— 每个 `.ERB` 都被解析，每个 `@LABEL` 都存在于内存中。那么问题是：当引擎想为 Satori 派发一句口上时，*它调用哪个变体的标签？* 这正是**口上选择器**的用途。

#### 选择器如何工作

在每个变体的存在性检查标签里，作者设置一个唯一的选择器字符串：

```erb
;在变体 A 的 M_KOJO_K49_イベント.ERB 中：
@M_KOJO_K49(ARG)
RESULTS = _ORTHODOX
RETURN 1

;在变体 B 的 M_KOJO_K49_イベント.ERB 中：
@M_KOJO_K49(ARG)
RESULTS = _2024_05_14
RETURN 1
```

（或者 —— 为了不冲突地共存 —— 每个变体使用不同的带版本存在性标签，如 `@M_KOJO_K49_2(ARG)` / `@M_KOJO_K49_3(ARG)`。引擎两者都检查。）

然后**该变体里其他每个标签都必须加前缀**，与同一选择器一致：

```erb
;在变体 A 中：
@M_KOJO_ORTHODOX_FLAGSETTING_K49           ← 前缀与 RESULTS 匹配
@M_KOJO_ORTHODOX_EVENT_K49_1(ARG, ARG:1)
@M_KOJO_ORTHODOX_MESSAGE_COM_K49_300

;在变体 B 中：
@M_KOJO_2024_05_14_FLAGSETTING_K49         ← 不同的前缀
@M_KOJO_2024_05_14_EVENT_K49_1(ARG, ARG:1)
```

引擎的派发模板在运行时把 `%RESULTS%` 展开为该角色当前激活的选择器，因此最终恰好调用正确变体的标签。

#### 那么哪个变体是「激活」的？

角色 N 当前激活的变体存于 `CFLAG:N:口上セレクタ`（一个小整数）。引擎在每次派发开始时读它：

- 若 `CFLAG:N:口上セレクタ == 0`（默认），引擎调用 `@M_KOJO_K{N}(ARG)` 并使用它所设的任何 `RESULTS`。
- 若 `CFLAG:N:口上セレクタ == V`（某个版本号），引擎改为调用 `@M_KOJO_K{N}_<V>(ARG)`，并使用*那个*版本的 `RESULTS`。

这意味着：**每个角色同一时刻只有一个变体在运行**，尽管所有变体都被载入内存。玩家（或安装器）翻动 `CFLAG:N:口上セレクタ` 来选择。反正大多数用户每角色也只装一个变体。

#### 选择器是可选的

如果一个角色只有一个变体，**把选择器留空**（不要在存在性检查里设 `RESULTS`）。引擎便把 `%RESULTS%` 展开为空串，派发 `@M_KOJO_FLAGSETTING_K{id}`、`@M_KOJO_MESSAGE_COM_K{id}_300` 等 —— 标准命名。**约 95% 的情况都是这种。**

仅当你确实想与同一角色的竞品版本并肩发布、又不想标签冲突时，才设置非空选择器。

#### 给你（辅助 LLM）的实操建议

当用户说「我想给灵梦写一个口上」时：

- 默认：不带选择器地写。所有标签都以 `@M_KOJO_<KIND>_K1_<n>` 开头。
- 若用户提到同一角色已有另一位作者的口上（「我想让它与官方版共存」），那就引入一个选择器 —— 用用户名或其版本号命名它（例如 `_USER_NAME` 或 `_v01`）。
- 若用户在编辑一个已经使用了选择器的既有口上文件，**与它保持一致**。不要剥掉选择器也不要另加一个。查看存在性检查以确认里面用的是什么。

---


---

## 作者扩展惯用法

### 10.1 函数库

把 `#FUNCTION` / `#FUNCTIONS` 定义放进 `M_KOJO_K{id}_関数ライブラリ.ERB`（或 `Lib/`）。作者的 `K{id}_*` 函数是私有命名空间；body 通过 `K{id}_FOO()` 和 `%K{id}_BAR()%` 调用它们。

示例（Tsukasa K139 有这些；此范式很常见）：

```erb
@K139_FIND_LOVER()
#FUNCTION
SIF TALENT:MASTER:恋人 == 0
    RETURNF 0
SIF TALENT:139:恋人
    RETURNF -1
LOCAL = TALENT:MASTER:恋人
SIF CFLAG:LOCAL:現在位置 == CFLAG:MASTER:現在位置
    RETURNF 2
RETURNF 1

@K139_C_NAME(ARG, TYPE = 0)
#FUNCTIONS
SELECTCASE ARG
    CASE 0
        ; Tsukasa 如何称呼 MASTER
        SIF TALENT:139:恋人
            RETURNF MASTERNAME:139
        RETURNF MASTERNAME:139 + "桑"
    CASEELSE
        RETURNF CALLNAME:ARG + "さん"
ENDSELECT
```

### 10.2 特殊事件库

`M_KOJO_K{id}_<charname>特殊イベント.ERB` —— 独立的 `@K{id}_<NAME>` 标签：

```erb
;CALL K139_PREG_WISH
;==========================================================================================
;子どもがほしいな
;==========================================================================================
@K139_PREG_WISH
PRINTFORML <event-intro-line>
CALL ASK_YN("yes-text", "no-text")
IF !RESULT
    ; 玩家接受
    PRINTFORMW <success-line>
    TALENT:139:妊娠願望 = 1
ELSE
    PRINTFORML <decline-line>
ENDIF
RETURN 1
```

从别处调用：

```erb
;在某个每日事件 body 里：
SIF <conditions ripe>
    CALL K139_PREG_WISH
```

### 10.3 角色专属 counter

`K{id}_固有カウンター<n>_<name>.ERB`：

```erb
@UNIQUE_COUNTER1_ABLE_K{id}
SIF TFLAG:62
    RETURN 0
SIF ABL:[[<charname>]]:欲望 < 5
    RETURN 0
RETURN 1

@UNIQUE_COUNTER1_FREQUENCY_K{id}
RESULTS = 脱衣愛撫            ; type-key（类型键）
RETURN 10                     ; 基线频率

@UNIQUE_COUNTER1_MESSAGE_K{id}
PRINTFORML <message-body>

@UNIQUE_COUNTER1_SOURCE_K{id}
;副作用：
SOURCE:[[<charname>]]:性行動 += 150
SOURCE:[[<charname>]]:誘惑 += 200
;可选：
;CALL TOUCH_SET(SET_FROM_YUBI, 1, [[<charname>]])
;CALL EVENT_COUNTER_POSE_69([[<charname>]], 2)
```

### 10.4 SOURCE —— 动作后的好感账本

这是最常被漏掉的范式。**每个 counter / unique-counter body 都应该写入 SOURCE。** 否则口上打印了文本却不推动好感。

槽位：`性行動, 露出, 逸脱, 与快Ｃ, 誘惑, 侮辱, 挑発, 加虐, 征服, 情愛, 反感, 歓楽, 達成, 愛情経験`。作者挑相关槽位并加上从小到大的正（或负）增量。

### 10.5 多人 SCOM 派发

```erb
@M_KOJO_MESSAGE_SCOM_K<id>_<n>
    CALL TRAIN_MESSAGE
    CALL M_KOJO_MESSAGE_SCOM_K<id>_<n>_1     ; 第一个参与者 body
    LOCAL = MASTER_POSE(<role>, 1, 1)         ; 解析第二个参与者 id
    LOCAL:1 = RESULT
    LOCAL:2 = TARGET
    TARGET = LOCAL
    TRYCALLFORM M_KOJO_MESSAGE_SCOM_K{TARGET}_<n>_2   ; 他们那版的 _2
    TARGET = LOCAL:2
    RETURN LOCAL:1
```

引擎把 `TARGET` 换成第二个参与者，并派发**进入他们的口上**。所以你的 `_2` body 可能是从另一个角色的 `_1` 里被调用的。body 必须一致地使用 `TARGET`。

---
