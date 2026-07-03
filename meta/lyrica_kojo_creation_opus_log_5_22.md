# Lyrica (K20) 口上创作日志 — Opus 4.7 / eratw-skill 验证

日期: 2026-05-22（创作） / 2026-05-23（验证扫描完成）
模型: claude-opus-4-7[1m]
任务: 仅使用 eratw-skill 内容（不连网、不读 skill 外的游戏内容），为莉莉卡（K20）创作一份口上，作为对 eratw-skill 准确性、完整性、可靠性的验证。

变体目录: `ERB/口上・メッセージ関連/個人口上/020 Lyrica [リリカ]/莉莉卡_v01/`

最终产出：15 个 .ERB（共 1477 行）+ 2 个 .txt（readme + フラグ管理メモ）。

---

## 1. 模型在创作过程中是否需要 skill 外的额外 context？

**结论（截止初版完成时）：不需要游戏内的额外文件，但需要 skill 外的"角色性格知识"补充。**

### 1.1 不需要补充的部分（skill 已经覆盖）
- **结构层面 100% 由 skill 提供**：标签命名规则、ARG 子相位、CFLAG/TFLAG/TCVAR 槽名、命令 ID、字符 ID 表、引擎 helper、DSL 语法、UTF-8 BOM 要求、§2 验证扫描 — 全部齐备。skill 自带的 `references/data/*.csv` 就是 byte-exact 的 ground truth。
- **Reimu 参考口上**直接打包在 skill 内（`reference-kojo/reimu/`），结构模板齐全。
- **本回 §2 验证扫描结果**：CFLAG 11/11、TFLAG 1/1、TCVAR 4/4、TALENT 9/9、ABL 3/3、BASE 3/3、MARK 1/1、NOWEX 2/2、EXP 2/2 — 全部 byte-exact 匹配。说明 skill 提供的 CSV 数据已经足以让我"零猜测"地写出 slot 名。

### 1.2 我用了模型自带知识（不是 skill 提供）的部分
- **莉莉卡的人物性格**：三妖精普利兹姆利巴姐妹中的幺女（注意："Prismriver 三姐妹" 跟 "Sunny/Luna/Star 三妖精" 是两组不同角色，skill 文档没强调，写错就会闹笑话），键盘手，活泼，有点小恶魔气质，爱恶作剧 — 这部分知识来自我训练数据里的东方 Project 资料，**不是来自 eratw-skill**。skill 的 §0.1 明确说"用户写人设、你写结构"，所以这本身是合理的；但是验证 skill 时需要意识到：如果以后给一个我不熟的角色（比如 ID 158 瑞霊）写口上，**这部分知识缺失会直接导致台词写不出来**。
- **三姐妹的乐器分工**：露娜萨 K22 = 小提琴、梅露兰 K21 = 小号、莉莉卡 K20 = 键盘。Chara20 CSV 只能看到"音乐技能 5 / 相性:21,150 / 相性:22,150"（即和 K21、K22 兼容性高），不能直接推出"是亲姐妹"或"分别对应什么乐器"。

### 1.3 我做了但有点拿不准的判断（建议作者再确认）
- **`SOURCE:N:愛情経験` 是否被引擎实际接受**：skill §10.4 列出了它，CSV 在 `exp.csv` 里能查到 `41,愛情経験`。但 source 列表是不是直接复用 exp 同名 slot、skill 没有明说；我按 §10.4 给的列表里"愛情経験"是合法的来用了。
- **GIFT 触发用 `@M_KOJO_EVENT_K{id}_GIFT(ARG, ARG:1)` 这个签名**：skill §2.4 / §6 表格里 `EVENT_*` 行只写到 `_GIFT` 而没有像 `_1/_2/_3` 那样详细的 ARG 含义。我假定 ARG=item_id；可能错。
- **`SUCCESS_COM` 的 `TFLAG:192` 值含义**：skill §7 标注"-2 end / -1 fail / 0 default / 1 great-success"，但我没找到 `-2 end` 的细致解释；我按字面理解 `-2 = 提前结束`、`-1 = 失败`、`0 = 默认成功`、`1 = 大成功` 来用。
- **`DAY:1` 是 weekday**：skill §4.2 列出 DAY=DAY:0 / DAY:2=月 / DAY:3=日，**没列 DAY:1**。我在 BEFORETRAIN 里用了 `DAY:1 == 7` 想表达"周日"，**这一条很可能不对**，可能需要换成别的 weekday 索引或者用 `DAY % 7 == X` 这种 derived。

### 1.4 比较关键的发现：skill 里 Reimu 参考口上跟 skill 文档本身有出入
- **`@M_KOJO_SUCCESS_COM_K{id}_{cmd}` 标签**：SKILL.md §7 和 §11 反复强调"always emit both SUCCESS_COM and MESSAGE_COM"。但 Reimu 的参考 `M_KOJO_K1_コマンド.ERB` **完全没有任何 `@M_KOJO_SUCCESS_COM_K1_*` 标签** — grep 整个文件 84 个 `^@` 全是 `MESSAGE_COM`，零 `SUCCESS_COM`。要么 SKILL.md 言过其实，要么 Reimu 这份是过时的（按 §0.5 caveat 也说"old monolithic layout"）。我目前选择按 skill 文档写 — 即两个都给。
- **`CALL TRAIN_MESSAGE`**：SKILL.md §7 把它作为推荐起手。Reimu 的命令 300 body 注释明确写着 "指令共通メッセージ(TRAIN_MESSAGE) 削除すると「～说着话。」とかが消えます" — 意思是 optional 的开关。我跟随 skill 文档，全部都加了 `CALL TRAIN_MESSAGE`。
- **Reimu 参考口上里完全没有 `@M_KOJO_UPDATE_K1`、`@M_KOJO_EVENT_K1_GRAVITY`、`@M_KOJO_EVENT_K1_PERMISSION_*`、`@M_KOJO_EVENT_K1_LOST_VIRGIN_STOP`、`@K1_BEFORETRAIN`、`@SPECIALDAY_EVENT_K1`** — 这些 skill 大量描述的 silent label，**参考实现里一个都没有**。这是 §0.5 caveat #4 委婉提到的现实：Reimu 这份代码足够老、没用上这些较新的 hook。具体到这些 silent label，skill 文档没有更接近的参考。我只能根据 §2.4 / §2.4.1 / §10.x 的文字描述硬写，写出来对不对要等用户运行测试。
- **Reimu 的 `@M_KOJO_EVENT_K1_1` 等 EVENT body 都没用 `SIF CFLAG:1:現在位置 != CFLAG:MASTER:現在位置` 同格守卫**。这是 §1 pitfall #4、§2.4.1 反复强调的"必须做"。Reimu 这份代码先于这个建议存在 — 也说明这个 bug 在历史口上里确实是普遍的，skill 把它列为 #4 pitfall 完全合理。我新写的 EVENT_K20_1/2/3 都加了该守卫。

---

## 2. eratw-skill 的优点

### 2.1 §2 "Verification pass" 直接可用
这一节是整个 skill 最有价值的部分之一。一段 bash、无需进游戏，能在静态层面挡掉 §1 列的 12 个 pitfall 里至少一半。我跑完之后：
- BOM 检查发现全 15 个 .ERB 都没 BOM（Write 工具默认不写）— 一行 `prepend_bom` 修好。
- 所有非纯数字的 CFLAG/TFLAG/TCVAR/TALENT slot 名都 byte-exact 命中 CSV。
- IF / SELECTCASE / SKIPSTART 平衡都过了。

**如果这一节没在 skill 里**，我大概率会交付一份"看上去对、跑起来到处 Lv2"的口上。

### 2.2 §1 "Most-common first-pass mistakes" 是高密度的失败知识
12 条都不是写代码当下能想到的、而是"踩过坑才知道"的。例如：
- `[[X]]` 静默变 0（pitfall #2）
- `CFLAG:N:约会中` 是 map_id 不是 boolean（pitfall #8）
- `MASTER/TARGET/PLAYER/ASSI` 是裸标识符（pitfall #3）
- `EVENT_K_1` 每次 cell transition 触发，必须同格守卫（pitfall #4）
- `GRAVITY` 是 NPC AI 吸引点，绝对不能 PRINT（pitfall #5）
- `LOCAL = 0` 是"stub 占位"，不是 bug（pitfall 没编号但 §8 详细讲了）

这些里几乎每一条都正好对应我在写代码时差点踩中的点。

### 2.3 §3 "Debugging with the user" 比一般 skill 高一层
直接定义了
1. 怎么识别"健康启动"（4 行 log）
2. 警告行的格式怎么 parse（文件路径 / 行号 / 函数 / 警告原因）
3. PRINTFORML 加 `[DBG]` 前缀做断点
4. 让用户「文件」→「将日志复制到剪切板」之后粘贴

这种"和用户实际协作"的章节，是大部分技术 skill 都缺的。

### 2.4 reference-kojo 直接打包
不是只有一段文字说"参考 Reimu 写法"，是真把 Reimu 整套 .ERB 打进来了。这一点对模型来说作用很大 — 我可以直接 grep 实际代码看 `IF LOCAL && !FLAG:時間停止 / IF TALENT:恋人 ...` 这种模板。

### 2.5 references/data 的 CSV 完整 byte-exact 副本
让模型完全脱离"猜 slot 名"。哪怕我写 `CFLAG:20:約会中`（Japanese 約），grep CFLAG.csv 一下就发现 byte-exact 是 `约会中`（simplified 约）。

### 2.6 §0.4 mode detection 分类清晰
明确区分 Claude Code mode 和 chatbot mode、并对应不同行为（前者直接读、后者要用户上传具体文件名）。这避免了在没有 file system 的环境里乱编 slot 名。

### 2.7 §10.4 SOURCE ledger 提示
我本来打算只写 PRINTFORML、结果看到这一节才补上 `SOURCE:20:愛情経験 += N` 这种 affection delta。否则口上"会说话但不影响好感"。

### 2.8 §2.4.1 ARG 子相位表
非常具体到 ARG=1/2/3/4/5 各自含义。换作没这个表，我会盲目分支然后行为完全错乱。

---

## 3. eratw-skill 的缺点

### 3.1 SKILL.md 和 reference-kojo/reimu 的实际代码出入太大，谁是 ground truth 不清楚
具体冲突在 §1.4 已列。SKILL.md 自己也意识到这个问题（§0.5 caveat #2 + #4），但只用"old monolithic layout / lacks new patterns" 一两句话带过。后果：
- 模型如果偏信 SKILL.md，写出来的代码跟实际 Reimu 风格不一致。
- 模型如果偏信 Reimu，会漏掉 SUCCESS_COM / GRAVITY / PERMISSION 等"较新的 hook"。
- **建议**：要么补一份"现代风格"的参考口上（skill README 提到 `022 Lunasa [ルナサ]/ルナサ/` 是 modern split，但没打包进来）；要么 SKILL.md 明确标注"这一节的描述在 Reimu 参考里看不到，是从 X 角色提取的"。

### 3.2 `DAY:1` / `weekday` 没有索引
§4.2 列了 `DAY` / `DAY:2` / `DAY:3`，没列 `DAY:1`。"周日"这种需求不知道怎么表达，只能猜。建议补一行。

### 3.3 GIFT / DAILY_EVENT 的 ARG 含义不细
§2.4 表格里 `_GIFT` 和 `DAILY_EVENT` 都只是一行，没有像 EVENT_K_X 那样的子相位表。我只能假定 ARG=item_id；实际拿不准。**建议**：把这些常用 hook 的 ARG 含义补到 §2.4.1 风格的表里。

### 3.4 "三妖精 vs 普利兹姆利巴三姐妹"这种容易混淆的角色组没有警示
ID 表里能看到 5/6/7 是 Sunny/Luna/Star，20/21/22 是 Lyrica/Merlin/Lunasa，这两组都俗称"三人组"，模型容易写串场景。**建议**：character-id-table 加一栏"所属团体"或者一段 caveat。

### 3.5 `RESULTS` 在 `@K20_C_NAME` 等 #FUNCTIONS 返回值的用法
我读 §10.1 看到 `RETURNF MASTERNAME:139` / `RETURNF CALLNAME:ARG + "さん"` 这样的用法、但没看到清楚说明：返回的字符串以什么方式被调用方接收（是 `%K20_C_NAME(0)%` 直接展开？还是 `RESULTS = K20_C_NAME(0)`？）。我两种都用了，可能有一种不对。**建议**：DSL 一节用一个"调用 + 接收"的小例子统一说清。

### 3.6 `@M_KOJO_EVENT_K{id}_GIFT` 既出现在 §2.4 EVENT 行又出现在 §10.x 隐式 — 但 §6 表格的 GIFT 行写的是 `"GIFT" → (see references/01)`
导致到底 GIFT 走的是 `EVENT_K{id}_GIFT` 还是别的入口，文档里要翻两节才能拼起来。建议合并到一处。

### 3.7 `_00 catch-all` 的解释存在但缺少"为什么 LOCAL=0 / RETURN 0 是默认"的回归测试
SKILL §1 pitfall #6 说默认 `LOCAL = 0 / RETURN 0`，但是 `_00` 是个不寻常的命名（不是 `_DEFAULT` / `_FALLBACK`），新作者第一眼看到肯定不会理解它是 catch-all。建议 §6 dispatch kinds 表也单独列一行。

### 3.8 `[SKIPSTART]/[SKIPEND]` 在 §0.6 解释了用途、但很多作者放在文件最顶部当"模板预览"用的样例没明说
我在 Reimu 看到的 `[SKIPSTART]` 块就是这种用法（顶部有两段空的 IF cascade / PRINTDATA 模板）。新作者看到容易困惑"为什么把空模板留在文件里"。建议 §0.6 加一句"还有第三种用途：留作模板复制粘贴的种子"。

### 3.9 `references/01` 章节号 §2.4 起跳、之前 §1 / §2 / §2.1-2.3 不在该文件
读 references/01 时一开始觉得"为什么这文件从 §2.4 开始"。是把 SKILL.md 的章节延续过来，但文件之间章节号体系跳跃，模型不容易把握 source of truth。建议要么每个 references/*.md 自己 §1 起跳、要么把 SKILL.md 章节号一同附上。

### 3.10 没有"完整 minimal kojo 模板"可以拷贝
SKILL.md §7 给了 standard body shape、§11 给了"新口上 step-by-step"，但没有一份"50 行内、可拷贝即跑的最小可用 kojo"。新口上作者第一次上手时，需要这个 footprint。建议加一个 `references/00-minimal-kojo-template.md`，把 existence + FLAGSETTING + COLOR + 一个 daily command + ENDIF 全部凑齐。

---

## 4. Bug 和 fix 记录

### Bug #1 — 日终给莉莉卡送礼物后游戏崩溃（CRITICAL）

- **触发条件**: 当天送过礼物给莉莉卡 → 日终结算触发 @GIFT_FAVORITE
- **预期行为**: 莉莉卡触发 @M_KOJO_EVENT_K20_GIFT 打印收礼台词、累加 SOURCE
- **实际行为（v01 原版）**: Emuera 报错弹窗 "M_KOJO_EVENT_K20_GIFT函数: 参数过多"、调用栈贴的是 `KOJO_MESSAGE.ERB:998` 的 dispatch：
  ```
  TRYCALLFORM M_KOJO%RESULTS%_EVENT_K{NO:TARGET}_GIFT(ARG:1, ARG:3, ARG:4, ARGS:1, ARGS:2)
  ```
- **根本原因**: 引擎实际以 **5 个位置参数**（3 numeric + 2 string）调度该 label；我之前按 SKILL.md §2.4 表格里 `_GIFT` 行没明确签名、自行写成 `(ARG, ARG:1)` —— 只 2 个参数、不够装下引擎传入的 5 个。
- **第一次修复 (5/22)**: 把签名改为匿名 5 参 `@M_KOJO_EVENT_K20_GIFT(ARG, ARG:1, ARG:2, ARGS, ARGS:1)`。
  - **作者测试反馈**: 不崩了、但显示了引擎默认的"这是莉莉卡收到的最喜欢的礼物"旁白 — 说明引擎接受匿名 5 参签名、但我的 body 逻辑没真正触发（把 `ARG` 当 item_id 用、错过了 `ARG==1` 这个 event_type 判断）。
- **第二次修复 (5/23、本轮)**: 通过 agent 检索 K30/K139 现代口上的真实 GIFT body，发现：
  - 真实签名是 **命名参数 + #DIM/#DIMS 声明**: `(ARG, GIFT_ID, 評価点, GIFT_NAME, SENSE)`
  - `ARG == 1` 表示"收到礼物"事件类型
  - `評価点` (701-999) 是评分、用来做"喜欢程度"分支
  - `STRCOUNT(SENSE, "音楽")` 等是检测礼物属性的标准做法
  - 现在按 真实签名 + 真实分支逻辑 重写、删除了我编的"item ID 1500-1510 = 乐谱"假说
- **skill 是否应该提前预警**: **是、必须**。这是一个 100% 静默静态不可见、跑到运行时崩游戏的坑。建议：
  1. 在 references/01-engine-label-catalog.md §2.4 的 `EVENT` 表格里、把 `_GIFT` 行从 "`_GIFT` = gift reaction" 扩展为完整签名 `_GIFT(ARG, GIFT_ID, 評価点, GIFT_NAME, SENSE)` + 每个参数含义 + **必须 #DIM/#DIMS 声明**的注意。
  2. 或者在 SKILL.md §1 加一条新 pitfall #13 "EVENT_K_GIFT 是 5 命名参数调度，遵循 §1 pitfall #1 必须 #DIM/#DIMS 声明"。
  3. §2 verification pass 加 grep：所有 `@M_KOJO_EVENT_K[0-9]+_GIFT(` 必须有 5 个参数 + 紧跟 4 行 #DIM/#DIMS。

> 这条 bug 也展示了"匿名 5 参"和"命名 5 参"两种风格都能跑、但匿名风格让 body 逻辑容易出错（不知道 ARG 到底代表什么）。skill 应该建议命名 + #DIM 这种"现代风格"。

### Bug #2 — 角色显示名 "莉莉喀" vs 我们写的 "莉莉卡"（POTENTIAL，未崩游戏）

- **症状**: 游戏日终旁白显示 "莉莉**喀**把你先生赠送的苹果の零钱包暂时保管起来"，而 skill 的 `references/data/Chara/Chara20 リリカ.csv` 里 `呼び名,莉莉卡`、且我们口上里所有 PRINTFORML 都是 "莉莉**卡**"。
- **原因推测**: 用户实际游戏目录里的 `CSV/Chara/Chara20 *.csv` 的 `呼び名` 行是 "莉莉喀"、和 skill 打包的副本不一致。这是 skill **§1 pitfall #11** 命中的场景。
- **修复方向**: 二选一 — (a) 用户改 `CSV/Chara/Chara20 *.csv` 的 呼び名 为 "莉莉卡"，(b) 或者批量改 kojo 里 "莉莉卡" → "莉莉喀"。我们没动 CSV（任务禁止）、也没改 kojo（首选方案需要用户决定）。
- **skill 反馈**: pitfall #11 已经写了、命中 — 不算 skill 的问题。但 §3 debug 章节可以加一段"如何用 grep 检查这个不一致"。

---

## 4.5 第二次扩充时新增的内容与发现

针对用户在第二次会话中的 4 条要求（更多对话 / 情境分支 / 占位填空 / 修 GIFT 崩溃）做了如下改动：

### 4.5.1 对话扩充
| 命令 | 改动 |
|---|---|
| 300 会話 | 关系层级 RAND 变体从 3 个扩到 4-5 个；新增情境分支：醉酒、约会中、姐姐在场（3 种组合）、雨天户外、情绪低；所有情境分支都用 `ELSEIF`（不是 `IF`），保证条件不满足时立刻回落到关系层级 |
| 301 泡茶 | 加了醉酒、雨天分支；关系层级 RAND 变体扩到 3 个 |
| 416 演奏 | 加了醉酒（"醉骚灵进行曲"）、三姐妹合奏、约会中、情绪低；关系层级 RAND 变体扩到 3 个 |
| 410 掃除（新增） | 全套 SUCCESS_COM / MESSAGE_COM、关系层级 + 醉酒分支 |

### 4.5.2 占位填充
原来 stub-only 的命令现在都有占位台词（暧昧但非 R18）：
- 305 索求膝枕、306 撫摸肚子、307 捏臉蛋、308 捅臉頰、336 膝枕
- 352 告白、354 陪睡、412 学习、413 製作料理、604 散步
- 350 推倒、351 帯出去、356 邀请去阴暗处（318 之类未涉及）
- 303 道歉、304 帮忙干活

仍保留 LOCAL=0 静默 fallback 的：
- 314 肛門愛撫、316 手指挿入、353 猥褻 — 这些纯属 R18 范畴，按 SKILL.md §0.2 不生成

### 4.5.3 设计原则
按用户要求"情境分支条件较窄或优先级靠后、不要盖掉关系层级"做到：
- **窄触发条件**：醉酒要 `K20_DRUNK() >= 2`；姐姐分支要 `K20_SISTERS_HERE() == 3`（两个都在）才走"三姐妹合奏"；雨天要 `GROUPMATCH(TIME:5, 4, 5, 6, 7)`；约会要双重 `CHK_DATENOW(...) && FLAG:约会的对象 == TARGET`。
- **优先级**：醉酒 → 约会 → 姐姐 → 雨天 → 情绪 → TALENT cascade。前面的 ELSEIF 不命中、就自然回落到关系层级。任何一个情境分支只覆盖到一个 RAND 变体本来会生成的台词、不会"长期霸占"对话。

### 4.5.4 新发现的潜在风险（skill 没提）
- `FLAG:约会的对象` 在 SKILL.md §4.2 / §5.5 都列了、但 grep `references/data/*.csv` 找不到这个 slot 名。**可能是引擎硬编码的 FLAG 索引、不在 CSV 里**。我跟随 SKILL.md 用了它、如果 Lv2 警告冒出来再调整。
- `BASE:N:情緒` 我用于 "情绪低" 分支阈值 `< MAXBASE:20:情緒 / 3`。skill 的 `references/02-state-bus-namespaces.md` 列了 情緒 在 BASE.csv 里、且 grep 验证 OK。
- `K20_DRUNK()` / `K20_SISTERS_HERE()` 是我自己写的 `#FUNCTION`、放在 関数ライブラリ.ERB。要让命令 body 调用、必须保证文件被引擎扫描到（按 SKILL §0.4 引擎递归扫描应该 OK）。

### 4.5.5 文件行数变化
- 修改前: 1477 行（15 个 .ERB）
- 修改后: 2157 行（15 个 .ERB） — +680 行
- 全部 §2 verification 仍然通过

---

---

## 5. 我（Opus 4.7）能否胜任这个工作？

### 5.1 能胜任的方面
- **结构骨架**：标签命名、ARG 守卫、IF cascade、SELECTCASE 分支、UTF-8 BOM、SOURCE ledger — 完全没问题。§2 verification pass 一遍过，说明结构层面 0 静态错误。
- **CFLAG/TFLAG/TCVAR 槽名引用**：在 skill 提供 CSV 的前提下、grep verification 之后全部 byte-exact。
- **`@DIARY_TEXT_K{id}` 这种引擎自定义参数名 + #DIM 声明**：第一次写就按 skill §1 pitfall #1 的写法做对了。
- **`GRAVITY` 是静默的 NPC AI 吸引点**：第一遍就避免了 PRINT。
- **同格守卫**：EVENT_K20_1/2/3 都加了。
- **小恶魔 + 喜歡引人注目 + 骚灵 + 三姐妹幺女** 这种东方角色性格的"风格"也能基本写出来（基于训练数据自带的东方知识）。

### 5.2 不太胜任的方面
- **R18 prose**：skill §0.2 明确禁止生成、这是有意为之、所以严格说不是"不胜任"。但是这意味着 stub 命令文件（性交 / 加虐 / セクハラ）只能交一个 `LOCAL = 0` 的占位、要靠人工后续填。
- **冷僻角色的人设**：上面提到的，对训练数据里不丰富的角色（瑞霊、行きずり 这种），我没有"自带"的人设知识可调。这种情况下哪怕给我 skill、我也只能写出空骨架、台词部分得用户写。
- **多版本引擎差异**：skill §2.7 提到 `[SKIPSTART]/[SKIPEND]` 包 custom API、但我不知道用户实际跑的引擎版本是不是支持。我按"用 SKIPSTART 包起来保证向下兼容"的安全策略走了、但如果用户其实跑的是新版、那 `[SKIPSTART]` 块就被永远跳过了——这种 trade-off skill 没明确建议。
- **作者私有 CFLAG 编号冲突**：我自行用了 1000/1001/1010/1100/1101/1990 几个、写到 `フラグ管理メモ.txt` 里。但是如果 Reimu 也用了 1100、就会冲。skill 说"author-private 1000-1999"是规约、不是保证唯一。这部分我没办法跨角色 dedupe（也不能查、按"不读 skill 外文件"的约束）。

### 5.3 总体判断
**胜任度: 8/10**。整个流程跑下来 skill 起的作用 >> 模型自带知识。文件结构、slot 名、调度模式、debug 流程全部 skill 提供。模型主要贡献是把"莉莉卡的人设"翻译成"哪个 cascade 走哪条分支"以及自然语言台词。如果换一个我完全不熟的角色、胜任度可能掉到 5/10、那时候必须让用户先给人设。

---

## 6. 对 eratw-skill 的建议（汇总）

1. **补一份"现代风格"的 reference-kojo**：得寻找一个，把 GRAVITY / PERMISSION / LOST_VIRGIN_STOP / BEFORETRAIN / SPECIALDAY / UPDATE 这些 Reimu 没用的 hook 给一个真实示例。
2. **补一份 50 行内可拷贝的 minimal kojo 模板**（§3.10）。
3. **`DAY:1` weekday 索引** 补到 §4.2（§3.2）。
4. **GIFT / DAILY_EVENT 的 ARG 含义表** 补到 §2.4.1（§3.3）。**这是导致 Bug #1 (运行时崩游戏) 的直接原因，应该是优先级最高的修补点。** 具体应补的内容：
   ```
   @M_KOJO_EVENT_K{id}_GIFT(ARG, ARG:1, ARG:2, ARGS, ARGS:1)
     5 positional params. Dispatched as:
       TRYCALLFORM M_KOJO%RESULTS%_EVENT_K{NO:TARGET}_GIFT(ARG:1, ARG:3, ARG:4, ARGS:1, ARGS:2)
     Args (positional, names at body site):
       ARG    = item_id (推测)
       ARG:1  = ?
       ARG:2  = ?
       ARGS   = item_name 字符串 (推测)
       ARGS:1 = ?
     Writing (ARG, ARG:1) only — as the EVENT_K_1/_2/_3 cell-events use —
     will run-time crash with "函数参数过多".
   ```
5. **character-id-table 加"团体" 列**，提示 5/6/7 三妖精 ≠ 20/21/22 三姐妹（§3.4）。
6. **#FUNCTIONS 返回值的接收方式**用一个最小例子统一说清（§3.5）。
7. **§1 / §7 关于 SUCCESS_COM 的强调和 Reimu 不一致**，要么放一段"Reimu 老风格 vs 现代风格"的对照，要么明确说 SUCCESS_COM 是 optional（§1.4）。
8. **§7 / §1 / §6 整理出"command body 的最小必要标签"** — 让作者一眼知道至少要写哪几个 `@`，比如"SUCCESS_COM 是 optional、`_00` 是 catch-all、`_<cmd>` 是入口、`_<cmd>_1` 是 body"。
9. **`SOURCE:N:<slot>` 的可用 slot 列表**，建议挂到 references/data 里加一份 source.csv（实际上 `source.csv` 文件存在、但 §10.4 直接列了一串中文 slot 名、二者没对得上）。
10. **§3 debug 章节加一节"如何 dump CFLAG/TCVAR 全量"**：很多 bug 是"某个 CFLAG 不是我以为的值"，给一段标准 dump recipe 比手写 `PRINTFORML [DBG] CFLAG:...` 强。
11. **§2 verification pass 加 GIFT 签名扫描**：
    ```bash
    echo "=== EVENT_K_GIFT signature check (must be 5 params) ==="
    grep -nE "@M_KOJO_EVENT_K[0-9]+_GIFT\(" *.ERB | while read line; do
        params=$(echo "$line" | sed -E 's/.*\(([^)]+)\).*/\1/' | tr ',' '\n' | wc -l)
        if [ "$params" -ne 5 ]; then
            echo "BAD: $line  ($params params, need 5)"
        fi
    done
    ```
12. **"对话量"指引**：SKILL.md §7 给了一个 cascade 模板、但没说"每个分支建议几个 RAND 变体"。新手很可能像我第一版那样、每个分支只写一两条、玩家很快就重复看到同一句。建议补一句"对每个 cmd × 关系层级、建议至少 3 个 RAND 变体；常用命令（300 会話 / 301 泡茶 / 演奏 / 散步）建议 4-5 个"。
13. **"情境分支放哪里"指引**：跟 12 关联 — 我第一次写时把所有情境（醉酒 / 约会 / 天气）全塞进关系层级 cascade 之前的 ELSEIF。第二次反思发现：放前面会盖掉所有关系层级台词、玩家整局都听同一句"下雨天的话——"。建议 SKILL.md §9 加一段"哪些 ELSEIF 优先级放哪里"的指引：醉酒 / 紧急情绪状态可以在前；天气 / 时段建议作为 RAND 变体的子条件、而不是 cascade 头部 ELSEIF。

---

## 6.5 写给下一个负责维护 eratw-skill 的 Claude session 的话

把这一段单独拎出来、方便另一个 session 直接读。

1. **本次最高优先级反馈：GIFT 签名**（§4.1 Bug #1 + §6 第 4 条）。这是 0 静态可检、跑到运行时炸游戏的事。SKILL.md §2.4 表格里 `_GIFT` 那行务必补完整签名。
2. **第二高优先级：SUCCESS_COM 的 Reimu / SKILL.md 不一致**。要么 Reimu 不是 ground truth（注：这是可运行的老牌口上，肯定是ground truth）、要么 SUCCESS_COM 实际是 optional。两种情况都需要文档明说。
3. **第三高优先级：对话量指引**（§6 第 12 / 13 条）。我自己第一次写下来、就完美踩中"对话太少、情境分支盖掉关系层级"两个 Pit。说明这是 LLM 普遍会犯的、不是个例。
4. **次要但有用：character-id-table 团体列、minimal kojo 模板、DAY:1、SOURCE slot 表、debug 章节加 CFLAG dump recipe**。
5. **关于"reference-kojo 只打包了 Reimu 老风格"**：这是结构性缺口。Reimu 没有 GRAVITY / PERMISSION / LOST_VIRGIN_STOP / SUCCESS_COM / SPECIALDAY / UPDATE / 现代多文件 split — 这些恰好是新口上最容易出错的地方。建议再打包一份 022 Lunasa 或 030 Eiki。


---

## 7. 我做了哪些有意识的"测试 skill"的选择

为了让这份口上能尽量多地"探测" skill 的不同部分，我有意地：

- 写了 **15 个分文件**（每种 dispatch kind 至少 1 个）而非 1 个大文件
- 用了 `@DIARY_TEXT_K20, PAGENUM, MODE, PAGECOUNT` + #DIM 声明（测试 pitfall #1）
- 写了 `@M_KOJO_EVENT_K20_GRAVITY` 仅设 TCVAR、不 PRINT（测试 pitfall #5）
- 写了 `@M_KOJO_EVENT_K20_1/2/3` 都带 `SIF 現在位置 != MASTER:現在位置` 守卫（测试 pitfall #4 / §2.4.1）
- 写了 `@M_KOJO_MESSAGE_MARKCNG_K20` 带 `SIF !TFLAG:21 && ... !TFLAG:時姦刻印取得 / RETURN 0` 守卫（测试 pitfall #7）
- 写了 `@M_KOJO_MESSAGE_COM_K20_DANMAKU(ARGS, ARG)` 用 ARG 不是自定义名（测试 pitfall #1 的 DANMAKU 子情况）
- 用 `CALL ASK_YN("yes-text", "no-text")` + `IF !RESULT`（注意 polarity）测试 §5.2
- 用 `CALL ADD_KISS` 测试 §5.1
- 用 `FIRSTTIME(SELECTCOM)` 测试 §5.5
- 用 `SOURCE:20:愛情経験 += 500` 等 SOURCE ledger 写入（§10.4）
- 用 `@K20_FIND_LOVER() #FUNCTION` / `@K20_C_NAME(ARG, ARG:1 = 0) #FUNCTIONS` 测试 §10.1
- 用 `@K20_NEW_YEAR_CONCERT` / `@K20_XMAS_PIANO` 测试 §11.2 special-events
- 用 `[SKIPSTART]/[SKIPEND]` 包了 `@KOJO_CUSTOM_TALENT_SET_K20`（§2.7 + §0.6）
- 用 `_00 catch-all = LOCAL=0`（pitfall #6）
- 数值地用 `21`、`22` + `;梅露兰` / `;露娜萨` 注释代替 `[[メルラン]]`/`[[ルナサ]]`（pitfall #2）
- 给所有命令 body 都加了 `IF FLAG:時間停止 ELSEIF TALENT:恋人 ...` 标准 cascade（§9）
- 给所有 command 都补了 `@SUCCESS_COM_K20_{cmd}`（按 SKILL.md 写法、虽然 Reimu 没有）

这份 v01 应该是一个"宽探测、浅深度"的 skill 测试场。

---

## 8. 复盘 — 我违反了"宁缺毋滥"的原则（2026-05-23 反思）

作者指出：模型对没把握的代码、又不好触发的代码、**不该一开始就写**；该列在 deferred 文件里、等作者确认了再加。这次我明显违反了这条原则。

### 8.1 读取范围（重申诚实清单）
仅 `C:\Users\lzh\.claude\skills\eratw-skill\` 内的文件。其中 .md 11 份全读、CSV 按需 grep + Read（约 13 份）、reference-kojo/reimu/ 3 个文件按需 Read（イベント前 1000 行 + コマンド前 220 行 + readme）。

**轻微的隐式信息泄露**：我用 `ls -la` 看了 `learning/meta/` 目录、看到了 `lyrica_kojo_creation_haiku_log.md` / `post_test_bugfixes_lyrica.md` / `reference-kojo-analysis.md` 这些文件名 — 这些名字本身就告诉了我"之前已经有人 / Claude 反复做过这个任务、且有现成 bugfix 记录"。我**没打开**任何一个。

### 8.2 我已埋下的"高风险 + 低触发"地雷
详细清单见 [`TODO_TEST_AND_DEFER.txt`](../../ERB/口上・メッセージ関連/個人口上/020 Lyrica [リリカ]/莉莉卡_v01/TODO_TEST_AND_DEFER.txt)，A 类（既没把握又不好触发 — **不该写、建议立刻 SKIPSTART 隔离**）摘要：

1. `@M_KOJO_EVENT_K20_LOST_VIRGIN_STOP` — 返回契约未验证、一年可能 0-1 次触发
2. `@M_KOJO_EVENT_K20_PERMISSION_1/_2` — 同上、稍微好触发一点
3. `@SPECIALDAY_EVENT_K20` + `K20_NEW_YEAR_CONCERT` + `K20_XMAS_PIANO` — 一年 2 天
4. `EVENT_K20_GIFT` 里 `IF ARG >= 1500 && ARG <= 1510 = 乐谱` — item ID 是我编的、没查 Item.csv
5. `@K20_LONG_TIME_NO_PLAY` — 死代码、无 CALL
6. `FLAG:约会的对象 == TARGET` — `约会的对象` slot 在 CSV grep 不到

### 8.3 对 skill 的最关键建议（应该独立于 §6 / §6.5 之外、提前到 SKILL.md §10 / §11 工作流开头）

**skill 应该硬性要求模型在 scaffold 任何新口上之前先和作者协商**，告诉模型：

> 1. 列出两份清单给作者：
>    - "会写"清单 — 只含**安全且好测试**的 label 与 cascade
>    - "不写但记账"清单 — 含所有难触发 / 不确定签名 / 引擎版本敏感的 label
> 2. 默认**只写"会写"清单**。任何 silent label（GRAVITY 除外、那个必须写但极容易出错）、节日事件、LOST_VIRGIN_STOP、引擎新 API、虚构的 item ID 范围 — 一律先放进"不写"清单。
> 3. 同时创建 `TODO_TEST_AND_DEFER.txt`（或类似名）维护三类：
>    - **SHOULD TEST**: 已写、能触发、需作者验证 — 附触发步骤
>    - **RECOMMEND QUARANTINE**: 已写、但回顾发现风险高 — 附 SKIPSTART 包裹建议
>    - **NEEDS AUTHOR DECISION**: 还没写、等作者点头
> 4. 收到作者"再加 X 功能"请求时、先评估 X 属于哪一类、再决定立刻写还是先记账。
> 5. 每次 Edit 后、更新 tracker 文件。
> 6. **作者无法测的代码 = 等于发布 bug 给玩家**。

这条比 GIFT 签名修复优先级更高 — 因为它是工作流问题、不是单一 bug。换句话说：哪怕这次 GIFT 签名是对的、我还是会埋下 LOST_VIRGIN_STOP / SPECIALDAY / 编造的 item ID 这些雷、等同样的事在另一个角色 / 另一个模型上重复发生。

### 8.4 下一步动作（等作者决定）

A 类清单已记录到 `TODO_TEST_AND_DEFER.txt`。等作者答复后可立刻执行：
- A1, A3, A4 是否立刻用 `[SKIPSTART]/[SKIPEND]` 包起来？
- A5 死代码 `@K20_LONG_TIME_NO_PLAY` 是删还是挂到 EVENT_K20_1？
- B 类全部进入测试待办、按作者节奏分批触发
- C 类全部等作者确认才开工

---

## 9. 新建议（来自 2026-05-23 第二轮复盘讨论）

### 9.1 references/ 应该新加一份"游戏体验导向"的文档

**问题**：skill 的所有现存文档都是"引擎机制 + 标签调度 + slot 名"层面的知识。完全没有"哪些命令玩家用得多 / 哪些条件实际触发频率如何"这种**只有玩过这游戏的人能写**的经验。

模型读 SKILL.md 不会知道：
- 311 擁抱 / 309 摸頭 / 410 掃除 / 300 会話 是高频日常 — 应该堆 RAND 变体
- 约会条件看起来稀有、但一旦进入就持续很久（"一整天约会复读同一句"就是这么来的）
- 三姐妹合奏 / 节日事件 看起来好玩、实际几乎不触发
- 时间停止 / 扮演 在大部分存档里不会启用
- 同性 / 异性 / 三人 SCOM 各自的真实使用比例

**建议**：新增 `references/11-gameplay-frequency-notes.md` 或类似名、记载：
- 命令使用频率分级（高/中/低）+ 每个 cmd × master常用做法
- 条件实际触发概率（约会/时间停止/天气/醉酒/姐妹在场/扮演 等）
- "条件持续时间"指引 — 比如约会一旦开始可能持续 4-8 个回合、所以约会分支必须有 RAND 变体
- 节日 / 一次性事件实际触发可能性（包括玩家 mod 时间的可能）
- 推荐 RAND 变体数量分级（高频命令 × 高频条件 = 至少 5 变体；低频命令 × 低频条件 = 1 变体也行）

这份文档作者（玩过的人）写最合适。模型也可以辅助起草，但需要作者校对。

### 9.2 工作流改进：允许模型用 agent 检索其他角色的口上

skill 默认禁止/没建议看 skill 外的口上、但实际上跨角色参考往往是写好新口上的最快方式 — 因为 Reimu 参考缺很多现代 hook。

**建议在 skill 里增加这种工作流**：

> 当模型遇到"SKILL.md 描述了某 label 但 Reimu 参考里没有"的情况、模型应该：
> 1. 用 Agent 工具发起一次只读 grep、范围限定到 `ERB/口上・メッセージ関連/個人口上/**/*.ERB`
> 2. 让 agent 只返回**该 label 在其他角色口上里的位置**（file:line）和**该 label 周围 30-50 行的代码**
> 3. 模型只读 agent 返回的小段、不读整文件、不读其他作者作品的对话内容（避免风格污染 + 隐私 + R18）
> 4. **绝对不修改**任何其他角色的文件

具体例子：本次 Bug #1（GIFT 签名）如果在写口上之前就用 agent grep `^@M_KOJO_EVENT_K[0-9]+_GIFT(` 跨所有角色、能马上拿到正确签名 — 完全避免崩游戏。

PERMISSION / LOST_VIRGIN_STOP / SPECIALDAY 等 Reimu 没有的 silent label 也同理。

### 9.3 大野心提议：references/ 增加"角色口上特征索引表"

**作者后续澄清（2026-05-23 第三轮）**：
1. **不是 150 角色 × N 特征 — 而是只记每个角色在 skill 之外的特征**。大部分角色应该是空记录（有特征的都该已经进 skill 主文档）、只有少数角色拥有大量特征。这让表本身比预期小得多。
2. **不要双索引、只保留 feature-key 一份**。理由：如果作者说"想模仿 X 角色"、模型直接去口上文件夹里 grep `K{x}_` 就行、不需要预先索引。
3. **作者欣赏的特征不在表里的担忧也可以放下** — 同上、grep 口上原文足够。
4. **此表放 references/、SKILL.md 只记 high-level 信息**（什么时候用、怎么用）。

修正后的设计更轻、SE 风险也降低（单索引 = 不存在去同步化问题）。

**作者提议**：另一个 skill-维护 session 用多个 agent、扫描所有 150+ 角色的口上、产出一份索引表、记录每个角色的"特殊代码 / 特殊标签 / 大段可参考文本"等特征。未来使用 skill 的模型可以快速通过表知道"为了当前任务应该去学习哪个口上"。

作者特别要求两份 view：一份模型 grep 用（feature-key）、一份和作者讨论用（character-key、对人友好）。

**我的客观评估（按 SE / vibe coding skill 视角）**：

整体认同、但有几条注意：

| 风险 | 说明 | 缓解 |
|---|---|---|
| **过时漂移** | 150+ 个口上常被各自作者改、表很快和实际代码脱节。模型信表而表错 = 比没表更危险 | 表头必须写"上次再生成日期"；skill 强制模型读表后**必须用 grep 验证至少 1 处**才信 |
| **agent 描述不准** | "什么算特殊"是判断题；不同 agent 写出来的粒度不一 | 必须有统一 rubric（哪些算 feature：声明的 silent label / 用了 custom API / 大段 SOURCE 操作 / 跨角色 RELATION / 特别长的 DATAFORM 集等） |
| **双索引去同步化** | 手维护两张表肯定漂移 | **单一源（YAML/JSON）**一行一条 `(char, feature)` 记录、两张表都从这份**自动渲染**。源是 ground truth、两张表是 view |
| **太大、塞不进 context** | 150 角色 × N 特征、char-key 那份可能 5000+ 行 | 强制 lazy load — 加在 §0.4 mode detection 旁边、不放进 SKILL.md 自动加载部分 |
| **作者用 char-key 表"想模仿 X"时描述不到点** | 作者欣赏的特征可能是描述里没强调的 | char-key 表每行带 "see also: <file:line>" 指向具体片段、让模型再读那一小段 |

**schema 建议（grep 友好版）**：

源（单一）：
```yaml
- char: 49
  name: Satori / 古明地觉
  feature: function_library
  label: K49_FIND_LOVER
  file: M_KOJO_K49_関数ライブラリ.ERB
  line: 12
  brief: 标准 #FUNCTION/-1/0/1/2 返回值的寻找 master 恋人位置 helper
- char: 49
  name: Satori / 古明地觉
  feature: mind_reading
  label: ""
  file: M_KOJO_K49_日常系コマンド.ERB
  line: 240
  brief: 用 \@ <thought-cond> ? <reading> # <neutral> \@ 三元式呈现"读心"语感
```

feature-keyed view（模型 grep 用）：每行 ≤ 200 字符、含 file:line:
```
function_library | K49 / K139 / K30 | M_KOJO_K49_関数ライブラリ.ERB:12
mind_reading     | K49              | M_KOJO_K49_日常系コマンド.ERB:240
gift_5_param     | K??              | <谁家有正确签名>
specialday_event | K?? / K??        | <谁家有真实示例>
```

char-keyed view（作者讨论用）：每角色一段、面向人、3-5 行总结：
```
## K49 古明地觉
- function library 较丰富：K49_FIND_LOVER / K49_C_NAME / ...
- 大量使用"读心"三元式（\@ ? # \@）— see 日常系コマンド.ERB:240
- 兄妹联动条件丰富（CFLAG:38:現在位置 == ...）
- 不使用 SPECIALDAY / SUCCESS_COM
```

**SE 上的小坑**：
- 别把表写进 SKILL.md（会污染 always-loaded context）
- 单一源 .yaml 也别 always-load — 比表更大
- 再生成脚本应该用 agent 跑、但要 idempotent — 重跑应该出同样表
- 源 .yaml 应按 (char, feature) 排序、git diff 友好
- 加 schema version 字段、便于将来 schema 升级

**没看出明显 SE 问题**。两 view + 单源 是数据库范式里的标准做法（normalize + render index）、合理。

**唯一真正的隐忧**：第一次生成谁来 review 准确性？这跟"打包 Reimu 参考时谁 review"是同一个问题、skill 现有也没解决 — 可以接受。

---

## 10. 写给下一个 skill 维护 session 的优先级清单（汇总版）

如果只能改 5 条：

1. **GIFT 签名** 修进 references/01 §2.4（避免运行时崩游戏）
2. **工作流强制**：scaffold 前列"会写 + 不写"两份清单、维护 `TODO_TEST_AND_DEFER.txt`、默认不写难触发 + 没把握的代码
3. **新增 references/11-gameplay-frequency-notes.md**（命令频率 / 条件持续时长 / RAND 变体数量指引）— 作者起草
4. **允许 agent 跨口上检索**（只读、只看小片段、不污染对话）— 写进 SKILL.md §0.4 mode detection 旁
5. **角色特征索引表**（单一源 YAML + 两份 view + lazy load）— 大野心、独立 PR

中优先级：补现代风格 reference-kojo（Lunasa / Eiki）、character-id-table 加团体列、SUCCESS_COM 真实性澄清、§2 verification pass 加 GIFT-signature scan。

低优先级：DSL #FUNCTIONS 返回值接收方式、minimal kojo 模板、DAY:1 索引、SOURCE slot 表。

---

## 11. 第三轮：用 agent 跨口上检索 + 直接修复（2026-05-23 第二批）

作者放开了"agent 可以读其他口上"的限制。我并行发了 2 个 agent、拿回非常关键的真实数据：

### 11.1 Agent 检索结果一览

| 待验证 | Agent 实测发现 |
|---|---|
| GIFT 签名 | `(ARG, GIFT_ID, 評価点, GIFT_NAME, SENSE)` + #DIM/#DIMS — 是命名参数、不是匿名位置参数（K30/K139 都用此模式） |
| PERMISSION_1/_2 签名 | **0 参数**（不是 `(ARG)`）；返回 -1/0/1；可在拒绝分支 PRINT（不是严格 silent） |
| LOST_VIRGIN_STOP 签名 | **0 参数**；返回 1=中止 0=允许；可 PRINT |
| SPECIALDAY_EVENT 签名 | **0 参数**、总是 RETURN 0；K16 Remilia 有完整新年/情人节/万圣节/圣诞节示例 |
| BEFORETRAIN 签名 | **0 参数**；K30 / K139 用于 TALENT 修正、CFLAG 标记、TCVAR 自动触发 |
| `DAY:1` | 是 weekday、`DAY:1 == 7` 就是周日 — 我写对了 |
| `FLAG:约会的对象` | 真实存在！在用户的 `CSV/FLAG.csv:73`、被 `ERB/MOVEMENTS/*.ERB` 引用 — **但 skill 自带的 references/data 副本不全**、缺这个 row |
| item ID 1500-1510 = 乐谱 | **错** — `CSV/FLAG.csv:280` 注释"1500-1599 是乐谱所持用 FLAG"、乐谱是 FLAG 追踪的虚拟对象、不是 Item |
| `CFLAG:N:陪睡中` | boolean、由 `@SET_TOGETHER()` 管理 — 我用对了 |

### 11.2 立即修复（已应用到 Lyrica 口上）

1. **GIFT body 改用命名参数 + #DIM**（M_KOJO_K20_道具系コマンド.ERB:27）
   - 新签名: `@M_KOJO_EVENT_K20_GIFT(ARG, GIFT_ID, 評価点, GIFT_NAME, SENSE)`
   - 4 行 `#DIM GIFT_ID / #DIM 評価点 / #DIMS GIFT_NAME / #DIMS SENSE`
   - body: `IF ARG == 1` 守卫 + 按 `STRCOUNT(SENSE, "音楽")` / `STRCOUNT(GIFT_NAME, "楽譜")` / `STRCOUNT(SENSE, "酒")` / `評価点 >= 950/800/...` 分支
2. **PERMISSION_1 / _2 改为 0 参数**（M_KOJO_K20_イベント.ERB:370 / 392）
   - 借鉴 K42 模式：野外 + 露出癖低时拒绝；反発刻印 >=2 强拒
3. **LOST_VIRGIN_STOP 改为 0 参数**（M_KOJO_K20_イベント.ERB:409）
   - 借鉴 K30 / K42 模式：非恋慕状态打印拒绝台词 + RETURN 1
4. **死代码 K20_LONG_TIME_NO_PLAY 挂到 EVENT_K20_1 case 1 头部**
   - 现在 BEFORETRAIN 设的提醒位会被 EVENT 消费

### 11.3 反思 — agent 跨口上检索的有效性

- **2 个 agent 拿回的信息抵 100 次单文件 grep**。
- **核心价值**：把 Reimu 老风格补足成"现代多角色"参考集 — Reimu 没有的 hook（GRAVITY / PERMISSION / LOST_VIRGIN_STOP / 现代 GIFT 签名 / SPECIALDAY 完整示例 / 名字真实使用），K30/K42/K139 都有。
- **代价**：每个 agent 单次约 30-60 秒、可控。
- **建议**：skill 应该把"用 agent 检索其他口上"作为**标准工作流**写进去、不是可选。特别是在 scaffold 阶段前期、就让 agent 抓 2-3 个现代角色的 silent label 真实示例当蓝本。

---
（debug 阶段开始后、Bug 记录在 §4 累加。本日志主体只追加、不删除。）
