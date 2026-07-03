# 梅露兰 (K21) 口上创作 —— eratw-skill 验证日志

- 日期/小时：2026-06-13 / 05（文件名时间戳 `20260613-05`）
- 角色：东方 Project 021 Merlin [メルラン]（游戏内编号 21）
- 目的：**这不是为了产出口上本身，而是验证 `eratw-skill` 是否准确、全面、可靠**。
- 约束遵守情况：
  - ✅ 全程**只读取 `eratw-skill` 目录内的内容**（SKILL.md + references/ + references/data/ + reference-kojo/），未查看游戏本体任何文件，未联网。
  - ✅ 只写了梅露兰口上文件与本 md，未写其它任何文件。
  - ✅ 角色性格使用模型内置知识把握（task 3.1 允许），未外查设定。
- 本 session 对话存储地址：`C:\Users\lzh\.claude\projects\d--Game-TouHou-Yoiyami-Dreamer-datas-eraTW\`

---

## 0. 产出清单（11 个 .ERB，全部 UTF-8 BOM + CRLF）

路径：`ERB\口上・メッセージ関連\個人口上\021 Merlin [メルラン]\メルラン\`

| 文件 | 主要测试的 skill 功能 |
|---|---|
| `M_KOJO_K21_イベント.ERB` | 存在判定 / FLAGSETTING（启用各静默钩子）/ COLOR / UPDATE / ENCOUNTER / BEFORETRAIN(静默状态机) / SPEVENT 1-3 + MESSAGECHECK 对 / EVENT_1(**同格守卫**+ARG子相位+姐妹同格 flavor) / EVENT_2/3(同格守卫) / EVENT_21(陥落取得) / EVENT_26+26_1(返回契约) / GRAVITY(**静默·只写引力点**) / LOST_VIRGIN_STOP(返回契约) / PERMISSION_1/2(返回契约) / GIFT(**5参 #DIM/#DIMS**) / SPECIALDAY + 作者私有一次性事件(CFLAG 1101 + ASK_YN + SOURCE) / RUN_INTO / CHARA_INFO |
| `M_KOJO_K21_日常系コマンド.ERB` | 300(完整 10 层 cascade，关系分支**内嵌**天气 flavor，§9.4) / 301(4 层简易 cascade) / 302 / 309 / 311(FIRSTTIME + 初次子开关 §8) / 312(ADD_KISS + AddEXP) / 332(BASE:酒気 醉态分支) / TEXTR 单行随机 / `_00` 兜底静默 / LOCAL=0 stub |
| `M_KOJO_K21_カウンター.ERB` | COUNTER + EVENT_COUNTER_MESSAGE + **SOURCE 账本** / 固有 UNIQUE_COUNTER1 四件套(ABLE/FREQUENCY/MESSAGE/SOURCE) |
| `M_KOJO_K21_弾幕勝負.ERB` | DANMAKU(ARGS, ARG)，ARGS 场景字符串分支 |
| `M_KOJO_K21_刻印取得.ERB` | MARKCNG + **强制 TFLAG 守卫**(§1#7) + MARK_MESSAGE |
| `M_KOJO_K21_絶頂.ERB` | PALAMCNG_B 按 NOWEX 各绝顶分支 + A2 stub |
| `M_KOJO_K21_日記.ERB` | DIARY_EXIST / BEFORE_CHECK(DIARY:N:M 状态) / **DIARY_TEXT #DIM/#DIMS**(§1#1 最关键) / 406 命令 |
| `M_KOJO_K21_セクハラコマンド.ERB` | 310(非露骨调侃实写) + MESSAGECHECK / 353(R18 仅骨架占位，遵守 §0.2) |
| `M_KOJO_K21_性交系コマンド.ERB` | R18 骨架 + 中间守卫(破瓜/勃起/TFLAG:193) + stub |
| `M_KOJO_K21_関数ライブラリ.ERB` | `#FUNCTION`(K21_FIND_SISTER) / `#FUNCTIONS`(K21_C_NAME 带**自定义参数 TYPE 的 #DIM** / K21_GREETING) / RETURNF |
| `of_new_kojo_api.ERB` | 新 API：CUSTOM_TALENT_SET / COM_NAME/ABLE/COM_0 / 命令 270 体 / VERSION，整体 `[SKIPSTART]/[SKIPEND]` 包裹(§0.6) |

覆盖了 §6 dispatch 表中绝大多数种类（print / 静默 / RESULTS-only 除外——RESULTS-only 的 MUSHI_BATTLE/SUIKA 未实现，见建议）。

---

## 1. 是否需要 eratw-skill 以外的 context？

**结论：不需要。** SKILL.md + `references/` + `references/data/` 的 CSV + `reference-kojo/` 模板，足以独立完成一份覆盖面很广的口上，且能逐字节核对槽位名。没有任何一处让我"无法保证准确性而被迫停下"（task 5 未触发）。

几处**差点**想要外部 context、但最终用 skill 内资源解决的地方：

1. **角色性格**：梅露兰的"开朗/爱出风头/不知羞耻/狂气/骚灵/三姐妹中负责小号"等，用的是模型内置东方知识 + `Chara21 メルラン.csv` 的素质行（倒錯的/狂気/幽霊=2 骚灵/兩面通吃/巨乳/Ｖ敏感/音楽技能5/絶対音感）。task 3.1 明确允许用模型把握性格，所以这不算违规外部 context。**而且 `06-workflow-recipes.md` §11.1 恰好就用梅露兰 K21 做范例**，连 COLOR、ENCOUNTER、命令 body 都给了，极大降低了对外部设定的依赖。
2. **姐妹称呼/编号**：`Chara21` 的"相性"行直接给了 莉莉喀(20)/露娜薩(22)，无需外查。
3. **命令 ID**：`Train.csv` 完整覆盖（300=会話…311=擁抱 312=接吻 406=日記本 等），无需外部命令表。
4. **地点码**（GRAVITY 的引力点、廃洋館=330）：`Chara21` 的"自宅位置,330"直接可用；未深入到需要 `現在位置一覧.txt`。

唯一**轻微**遗憾：`references/data/` 没有"位置 ID 一览"（MAP/現在位置 枚举）。我用到的 330 来自 Chara CSV，够用；但如果要写更复杂的地点分支，会需要 §12 提到但未整合进 skill 的 `資料/変数一覧/現在位置一覧.txt`。这属于 skill 已知的"未整合"项，不算缺陷，但见建议第 4 条。

---

## 2. eratw-skill 优点

1. **§1 的 12 条高频坑极其精准且高价值**。同格守卫(#4)、GRAVITY 静默(#5)、`约会中` 是 map-id 非 bool(#8)、`BASE:疲労` 不存在(#9)、`[[X]]` 静默变 0(#2)、自定义参数需 `#DIM`(#1)——这些是真正会让新手翻车、且从引擎源码看不出来的点。我写作时几乎每个 label 都至少撞上其中一条，全靠这 12 条规避。
2. **"engine code vs kojo code、契约只是 label 名列表"的心智模型(§5)非常清晰**，让人立刻明白"我只写 `@LABEL` 定义，不写 `TRYCALLFORM`"。
3. **`references/01` 的 label catalog + EVENT 1-34 ARG 全表**是查得到的最完整资料，配合 `05-event-arg-subphases` 的 cell-guard 解释，足以正确写出 EVENT_1。
4. **区分 print / 静默 / RESULTS-only 三类 dispatch**（§6 + §2.4.3）是关键设计，避免了在 GRAVITY/PERMISSION 里 PRINT 刷屏、或在 MUSHI_BATTLE/SUIKA 里误用 PRINT。
5. **data CSV 随 skill 附带**，让"逐字节核对槽位"这条铁律真正可执行（chatbot 模式只能让用户上传，Claude Code 模式可直接 grep）。这是本 skill 可靠性的基石。
6. **lazy-load 设计合理**：SKILL.md 主体 + 按需拉 references，没有一次性灌爆 context。
7. **§3 debug 工作流 + §3.4 `[DBG]` 打印 recipe**对后续与用户联调很实用。
8. **persona-tips(§09) 的"性格 → 结构"映射表**把"爱出风头""有姐妹""易醉"直接翻译成 CFLAG/RELATION/同格判定，写人设分支时省了很多脑筋。

---

## 3. eratw-skill 的缺点 / 发现的不一致与潜在 bug

> 以下是用本 fork 的实际 CSV 逐一核对后发现的、**skill 或其引用模板与本 fork 不符**的地方。严重度按"会不会让作者写出不解析的代码"评估。

### ⚠️ B1（中高）— `SOURCE:愛情経験` 在本 fork **不存在**
- `source.csv` 实际槽位：…情愛(10)/性行動(11)/達成(12)/歓楽(20)/与快Ｃ(40)/誘惑(50)/侮辱/挑発/奉仕/強要/加虐… **没有 `愛情経験`**。
- 但 SKILL.md §10.4 与 §2.4 的 SOURCE 槽位列表都把 `愛情経験` 列为合法 SOURCE 槽，且 **`references/06-workflow-recipes.md` §11.2 的范例直接写了 `SOURCE:1:愛情経験 += 800`**。作者照抄会得到 Lv2 警告 / 静默失效。
- 注：`愛情経験` 确实存在，但是在 **ABL** 和 **EXP** 命名空间里，不是 SOURCE。skill 把三个命名空间的同名槽混淆了。
- 我的规避：全程改用 `SOURCE:21:情愛 / 歓楽 / 誘惑`。

### ⚠️ B2（中）— `TALENT:セフレ` 在本 fork 为 `炮友`
- `Talent.csv`：184=愛欲、185=**炮友**，无 `セフレ`。
- SKILL §6/§7 正文用的是 `炮友`（正确），但 **官方模板 `M_KOJO_KX_イベント.ERB` 的 FLAGSETTING 注释**示例写 `!TALENT:X:セフレ`，且 §2.4.2 EVENT_21 表把 ARG=5 注成"セフレ"。作者若取消该注释直接用会不解析。
- 我的规避：用 `TALENT:21:炮友`；EVENT_21 注释里标注"5=セフレ(本fork为炮友)"。

### ⚠️ B3（中）— `CFLAG:なりきり口上有` 在本 fork 为 `扮演口上有`，且 SKILL 自相矛盾
- `CFLAG.csv`：373=**扮演口上有**，无 `なりきり口上有`。
- SKILL §9.1 cascade 表 row3 正确写 `扮演口上有`，但 **§10.1 step4 的 FLAGSETTING 清单**却让作者设 `なりきり口上有`（不解析）。同一份 SKILL 内两处不一致。
- 我的规避：`CFLAG:21:扮演口上有 = 1`。

### ⚠️ B4（低，注释级）— 模板 `破瓜キャンセル口上有` 与本 fork `破瓜中止口上有`
- `CFLAG.csv`：374=**破瓜中止口上有**。
- 官方模板 FLAGSETTING 注释写 `CFLAG:X:破瓜キャンセル口上有 = 0`（不解析）。**SKILL.md §10.1 step4 这里是对的**（写 `破瓜中止口上有`），是模板注释错。因为模板里是注释掉的，危害有限，但作者取消注释即踩雷。

### ⚠️ B5（低，注释级）— `TCVAR:泥酔` 不存在，本 fork 为 `烂醉`
- `TCVAR.csv`：145=**烂醉**（简体烂），无 `泥酔`。
- 官方模板 `日常系コマンド.ERB` 的 300 banner 注释写 `TCVAR:泥酔(1=通常成功or大失敗)`。属注释，不影响编译，但会误导作者写出 `TCVAR:泥酔` 分支。
- 我的规避：勸酒(332) 改用 `BASE:21:酒気 >= MAXBASE:21:酒気/2` 判醉。

### ⚠️ B6（中，工具级）— **§2 验证脚本自身的 IF/ENDIF 平衡检查有 bug**
- §2 的 bash：`ifs=grep -cE "^(IF|ELSEIF)"`，`expected=ifs - sif`，再比 `ENDIF`。**把 `ELSEIF` 也计入了 IF 数**。任何含 `ELSEIF` 的 cascade（即几乎所有命令 body）都会被误报 IF/ENDIF 不平衡。
- 正确逻辑应为：`count(^IF) == count(^ENDIF)`（`ELSEIF`、`SIF` 都不配对 ENDIF）。
- 我的规避：自己用 `^\s*IF\b`（天然排除 ELSEIF/SIF）重写了平衡检查，11 个文件全部平衡。

### ⚠️ B7（低，平台级）— §2 验证脚本是 bash + grep/xxd/unix2dos，Windows/PowerShell 默认无法直接跑
- 用户环境是 win32 + PowerShell。`references/10` 的 BOM recipe 也是 bash(`head -c 3 | xxd`)。本 skill 假定 *nix 工具链；在本机我把整套验证与 BOM 处理改写成了 PowerShell（`[System.IO.File]::WriteAllText` + `UTF8Encoding($true)`）。建议补一份 PowerShell 版（见建议第 2 条）。
- 另一个 Windows 特有坑（skill 未提，建议补）：路径含 `[メルラン]` 时 PowerShell 的 `Test-Path/Get-ChildItem` 会把 `[...]` 当**通配符字符类**，必须用 `-LiteralPath`，否则误判文件不存在。

### ⚠️ B8（中）— catalog 对"哪些 label 的参数需要 `#DIM`"标注不一致，且 §1#1 缺"内置 ARG/ARGS 严禁声明"的反向规则
- `references/01` 对 `@DIARY_TEXT_K{id}, PAGENUM, MODE, PAGECOUNT` 与 `EVENT_K{id}_GIFT(...)` 明确标了"body 需 `#DIM`"，但对 `@RUN_INTO_K{id}(MAP_ID)`、`@KOJO_COM_NAME` 等同样带自定义参数名的 label **没有标**。作者照抄 `@RUN_INTO_K21(MAP_ID)` 就会触发致命 Lv2（本次 F5 即此）。建议：凡 catalog 里参数名不是 `ARG/ARGS/ARG:N` 的 label，一律加"需 `#DIM/#DIMS`"标记。
- 反向地，§1#1 只说"自定义参数要 `#DIM`"，没说"**内置的 `ARG/ARGS/ARG:N/ARGS:N` 严禁 `#DIM/#DIMS`**"。本次 F4 就是我对 `ARGS` 多声明导致致命停机。建议 §1#1 补一句明确的反向禁令，并在 §2 验证脚本加一条"检测对 ARG/ARGS 的多余 `#DIM` 声明"。

### 小结
- B1/B6/B8 是**会实际坑到作者**的三条（B1 槽名不存在且范例在用、B6 验证脚本误报、B8 catalog 漏标 `#DIM`+§1#1 缺反向禁令），建议优先修。
- B2-B5 多为 skill 正文已对、但**所引用的官方模板/范例注释残留日文原版槽名**导致的不一致——根因是本 fork 做了相当程度的简中本地化，而模板/部分文档未同步。
- 总体：**SKILL.md 正文质量很高，"踩雷点"集中在它引用的外部模板注释、§11 范例代码、§2/§10 的 *nix 工具链假设上。**

---

## 4. 我（作者 LLM）自己写出的 bug & fix 记录

> 这些是我生成初稿时自己犯、并在交付前自查修掉的。记录下来供后续联调对照。

| # | 位置 | bug | fix | 触发的 skill 坑 |
|---|---|---|---|---|
| F1 | イベント EVENT_1 CASE1 | `%CALLNAME:K21_FIND_SISTER()%` 把函数调用直接当 CALLNAME 索引，解析风险 | 先 `LOCAL:1 = K21_FIND_SISTER()` 再 `%CALLNAME:LOCAL:1%` | 一般 DSL 严谨性 |
| F2 | イベント GRAVITY | `CFLAG:(K21_FIND_SISTER()):現在位置` 用函数调用作下标，风险 | 简化：恋慕→MASTER 位置，否则→自宅 330 | — |
| F3 | イベント BEFORETRAIN/EVENT_1 | 用了**具名** `TCVAR:21:今日已朝问候`，该名不在 `TCVAR.csv`，会 Lv2 警告 | 改用作者私有数字槽 `TCVAR:21:350` | §1#9 槽名必须存在 / §11 私有区 350-399 |
| F4 | イベント EVENT_26_1 第312行 | 对内置位置参数 `ARGS` 多余地写了 `#DIMS ARGS` → Lv2「变量名ARGS为Emuera所使用的变量名」**致命停机** | 删除 `#DIMS ARGS`（`ARG/ARGS/ARG:N/ARGS:N` 是内置位置参数，**严禁** `#DIM/#DIMS`） | §1#1 的反面：过度套用导致 |
| F5 | イベント RUN_INTO 第432行 | `@RUN_INTO_K21(MAP_ID)` 的 `MAP_ID` 是自定义参数名却未声明 → Lv2「变量MAP_ID未在此函数中定义」**致命停机** | 在 `@` 行下补 `#DIM MAP_ID` | §1#1（自定义参数需 `#DIM`）—— 但见 B8，catalog 未标注此 label 需要 |

**自查发现率反思**：F1/F2 是"把函数当下标/参数"的过度自信，F3 是"以为可以随手起一个中文具名槽"。这三个恰好都是 §1 想防的类别，说明 §1 有效、但模型在生成时仍会本能地犯，**需要靠 §2 验证 + 逐字节核对兜住**（我正是靠 grep CSV 才发现 F3）。

### 待用户测试 / 可能暴露运行时 bug 的点（供后续轮次）
- EVENT_1 的同格守卫是否真的挡住了跨格重复触发（§1#4）。
- GRAVITY 是否完全静默、`TCVAR:21:引力点` 写入是否生效。
- `%CALLNAME:LOCAL:1%` 这种"变量作 CALLNAME 索引"的写法引擎是否接受。
- DIARY_TEXT 的 `#DIM PAGENUM/#DIMS MODE/#DIM PAGECOUNT` 是否消除了 Lv2 警告。
- GIFT 的 `#DIM 評価点`（中文/和文混合标识符）能否被 `#DIM` 正确声明。
- `of_new_kojo_api.ERB` 在用户引擎版本上是否支持（不支持时 SKIPSTART 是否让其余文件照常加载）。
- SPEVENT/EVENT 的 MESSAGECHECK 返回 0 时地の文与口上是否都正常显示。
- 跨文件函数调用 `K21_FIND_SISTER()`（定义在関数ライブラリ，调用在イベント）是否解析正常。

### 启动报错 / 联调记录（后续追加，尽量只增不删）

**第 1 轮（2026-06-13，首次启动）** — 用户日志：
```
警告Lv2:...M_KOJO_K21_イベント.ERB:第312行:变量名"ARGS"为Emuera所使用的变量名
#DIMS ARGS
警告Lv2:...M_KOJO_K21_イベント.ERB:第432行:函数"@RUN_INTO_K21"的参数错误:变量"MAP_ID"未在此函数中定义
@RUN_INTO_K21(MAP_ID)
由于ERB脚本出现无法解释的行，Emuera停止运行
```
- 诊断：两处均 §1#1 自定义参数相关 → 见 F4 / F5。
- 修复：F4 删除 `#DIMS ARGS`；F5 补 `#DIM MAP_ID`。修后重新补 BOM。
- 关联 skill 发现：见 B8（catalog 未标注 `RUN_INTO(MAP_ID)` 需 `#DIM`），以及"`ARG/ARGS` 不可声明"这条 §1#1 没有显式写出的反面规则。
- **反思**：我初稿同时犯了"该声明的没声明(MAP_ID)"和"不该声明的乱声明(ARGS)"两个相反方向的错，说明 §1#1 只讲了"自定义参数要 #DIM"，没讲"内置 ARG/ARGS 严禁 #DIM"，两面都该明示。§2 静态验证脚本也没覆盖这两类（它只查"非 ARG 的参数头"，但不会发现 `#DIMS ARGS` 这种多余声明，也不会发现 MAP_ID 缺声明）。
- 待用户重启确认这两条 `警告Lv2` 是否消失，并继续测试运行时行为（同格守卫、`%CALLNAME:变量%`、DIARY `#DIM` 等，见上一节清单）。

---

## 5. 模型能力自评（本 model 是否足以胜任）

**总体：足以胜任"结构搭建 + 占位/草稿台词"这一核心职责，这正是 skill 给 LLM 定的角色（§0.1：你负责结构，用户负责内容）。**

胜任的方面：
- 把"自然语言事件描述 → 具体 label / 控制流 / 文件分类"翻译得准确。
- 严格遵守 cascade 顺序、静默 label 不 PRINT、RESULTS-only 契约、返回值契约、`#DIM` 声明等结构规则。
- 用 CSV 逐字节自查槽名，主动发现并规避了 skill/模板的多处不一致。
- 中文台词大致贴合梅露兰人设（task 3.1 只要求"看得出该不该出现在这里"，达标）。

相对吃力 / 需要外部兜底的方面：
1. **第一直觉会犯 §1 同类错误**（见 F1-F3）：模型在"图省事"时会把函数当下标、随手起具名槽。必须靠 §2 验证 + grep CSV 这套机械流程兜住，不能纯靠模型自觉。
2. **运行时行为无法纯靠静态推理确认**：同格守卫是否真挡住重复、`%CALLNAME:变量%` 是否被接受、`#DIM` 是否真消警告——这些只有进游戏跑日志才知道。这是 skill 也承认的（§3 整章在讲联调），不是模型单方面能力不足，而是任务本身需要 runtime 反馈闭环。
3. **台词文学质量**：本 model 能产出"情景正确、人设大致对"的草稿，但要达到口上作者要的润色质量仍需人接手——这与 task 设定一致，不算短板。
4. **极冷门 label 的精确语义**（如 CHILD_RAISING 各 key、PALAMCNG 各 tier 的细分触发条件）我没有全部实测，是基于 catalog 文档推断；高复杂度场景下可能需要 grep reimu 实例或模板对照。

结论：**在"Claude Code 模式 + skill 自带 CSV + §2 验证 + 与用户联调"的组合下，本 model 可靠；脱离任何一环（尤其脱离 CSV 核对或 runtime 反馈）则可靠性下降。**

---

## 6. 对 eratw-skill 的改进建议

1. **修 B1（最优先）**：从 SKILL §10.4 / §2.4 的 SOURCE 槽位列表删除 `愛情経験`，并改 `06-workflow-recipes.md` §11.2 范例为 `SOURCE:1:情愛 += 800`（或 `歓楽`）。同时在 §4 状态总线表里点明"`愛情経験` 属 ABL/EXP，不属 SOURCE"。
2. **修 B6 + 出 PowerShell 版验证（高优先）**：修正 §2 IF/ENDIF 检查（只数 `^IF` 不数 `ELSEIF`）。鉴于本 game 装在 Windows，建议在 `references/10` 增补一套 **PowerShell** 的 BOM 写入 + 验证脚本，并提示"含 `[...]` 的路径要用 `-LiteralPath`"。
3. **同步本地化槽名（修 B2-B5）**：在 §1#9 旁加一张"日文原版槽名 → 本 fork 简中槽名"对照小表（セフレ→炮友、なりきり口上有→扮演口上有、破瓜キャンセル口上有→破瓜中止口上有、泥酔→烂醉、約会中→约会中…），并提醒"官方模板/§11 范例中的注释仍是日文原名，照抄前先 grep CSV"。
4. **补"位置 ID"可查性**：把 §12 提到的 `資料/変数一覧/現在位置一覧.txt`（CFLAG:300 现在位置枚举）整合进 `references/data/` 或做成一张小表。GRAVITY/约会地点/同格分支都需要它，目前只能从各 Chara CSV 的"自宅位置"间接拿。
5. **RESULTS-only 类补一个最小示例文件**：MUSHI_BATTLE / SUIKA 这两类"写 `RESULTS=` 不 PRINT"的 label，在 `reference-kojo` 里给个 10 行可抄骨架，比纯文字描述更不易写错（我这次就略过了它们以免误用 PRINT）。
6. **`#DIM` 混合标识符提示**：GIFT 的 `評価点`、DIARY 的 `PAGENUM` 等需要 `#DIM/#DIMS`，建议在 §1#1 明确"和文/中文标识符同样要 `#DIM`，且声明行紧跟 `@` 头"，并给 GIFT 5 参的完整声明块作范例（catalog 有文字，但给整段代码更稳）。
7. **（可选）存在判定/COLOR 颜色示例的角色化**：§11.1 给梅露兰选了冷蓝 `0xC8E6F0`，但梅露兰=小号通常偏暖粉，建议范例里说明"颜色随角色乐器/形象自定，无定规"，避免被当成硬性值。

---

## 7. 一句话总结

`eratw-skill` 的**正文与方法论质量很高、§1 高频坑与自带 CSV 是它最大的价值**；本次验证未触发任何"必须外部 context 才能继续"的硬阻塞。主要缺陷集中在**它引用的官方模板/范例注释里残留的日文原版槽名（与本简中 fork 不符）**，以及 **§2/§10 的工具链默认 *nix**。按建议 1/2/3 修订后，可靠性会显著提升。
