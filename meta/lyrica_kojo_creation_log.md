# Lyrica 口上创作过程日志

> **Token usage 记录:** 本次创作开始时 current session token usage = **50%**(用户报告于阶段 3 末尾)。结束时再记录一次。

---

## TL;DR — 给 skill 维护者的一页摘要

**实验目标**:让一个 LLM 仅凭 `eratw-skill` 为 K20 莉莉卡从零写出能跑的口上(~100 处对话)。

**实验结论**:**当前 skill 版本下,做不到"仅凭 skill"。** 见 §4.4,14 项操作中 6 项必须读其他口上或引擎源码。

**已发现 3 个 skill bug + 7 个 skill gap**(详见 §5.2 / §5.5;skill 修订位置清单见 §5.2 表)。

**未确认仍有多少 bug**:这 3 个是 Emuera *加载阶段* 报错或与现存口上对照才发现的。**runtime / play-through 测试零次**(见 §4.6),真实 bug 数大概率 > 3。

**给下一个改 skill 的 Claude 的最高优先级动作**:
1. 编辑 `references/01-engine-label-catalog.md` §2.4 — 修 `LOST_VIRGIN_STOP` / `PERMISSION_<n>` / `DIARY_TEXT_K{id}` 三处
2. 编辑 `SKILL.md` §1#1 — 把"自定义参数名规则"扩展为"包括 DIARY_TEXT 也要 #DIM"
3. 编辑 `references/06-workflow-recipes.md` §11.1 — 加"先读至少一份现存口上骨架"作为第 1 步
4. 编辑 `SKILL.md` §2 验证 pass — 加 IF/ENDIF / SELECTCASE / SKIPSTART / duplicate label 平衡检查

**应保留不动**(见 §5.1):
- §1 12 条痛点列表(命中率高,救命设计)
- §6 标准 body 模板 / §8 cascade 顺序
- §0.4 mode detection / references/ lazy-load 设计
- §0.2 不生成成人内容指引

---

本文件记录一个 LLM(Claude Opus 4.7,通过 Claude Code)在仅有 `eratw-skill` 作为指南的前提下,**为 020 莉莉卡·普莉兹姆利巴从零创作完整口上**的全过程。最终目标:让未来一个仅装载该 skill 的 LLM 能复现这个工作流并产出可工作的口上。

凡是 skill **没有显式涵盖** / **超出 skill 范围**而我必须用其他手段补足的环节,都会标记为 **`[SKILL-GAP]`**,并写明:遇到的具体问题、用了什么手段、为什么 skill 单独不够。

凡是 skill 已经覆盖、我直接照做即可的,标记 **`[SKILL-OK]`**。

---

## 阶段 0:任务启动

### 0.1 用户给出的目标
- 为 020 Lyrica 创作 ~100 处不同对话,功能丰富,但**重点不是文学性而是覆盖 skill 中提到的各种功能**(测试 skill 是否完整有效)
- 同步维护本日志

### 0.2 获取人物设定
- 用户先要求访问 `https://thwiki.cc/...`
- 我使用 `WebFetch` 工具,**两次都 socket 异常关闭**;`en.touhouwiki.net` 返回 HTTP 418
- **`[SKILL-GAP]`**:skill 自身不假设网络访问,所以这一步本来就是用户要补的素材;但如果未来 LLM 看不到这条记录,可能会反复无效尝试 WebFetch。建议 skill 在 §0.4 之外加一句"对于角色背景,优先要求用户上传 wiki PDF/文本,而不是尝试 WebFetch"
- 用户在 `learning/meta/` 放了 PDF;PDF 自带的 layout 把双栏文本打乱了,**`[SKILL-GAP]` `pdftotext` 不带 `-layout` 参数效果更好**(skill 对外部素材读取没有指引,这是 skill 范围外的)
- 命令:`pdftotext -enc UTF-8 <pdf> <txt>`(`/mingw64/bin/pdftotext`)

### 0.3 提取的 Lyrica 关键设定(用于人物语气)
- 种族:骚灵(Poltergeist)。"骚灵并不是幽灵,但没有适合的分类就归在这里"
- **三女**(最年幼);姐姐:Lunasa(长女,小提琴,优等生,坦率易骗,喜欢独奏);Merlin(次女,小号,从容开朗,有点狂躁病苗头)
- 自身:键盘 + 打击乐;**狡猾,平时教唆姐姐们而自己不去战斗**;只想用最小气力获得最大利益;精神又聪明,行为算到三步以后
- 三姐妹中身高最矮、体格最小,**但身体却是最有体力的**
- 演奏"幻想之音":现实不存在的音声,无需用手就能演奏
- 危险度低、人类友好度高、活动场所:祭典会场、雾之湖附近的废洋馆
- **沿街拉琴的幽灵宣传家** —"被叫去通过演奏来使气氛高涨";三姐妹一起行动,独奏的时候多半在搞阴谋诡计或刚和姐姐吵了架
- 外貌:深棕色及肩短发,红色圆锥形帽顶端有绿色星形装饰;白衬衫 + 红马甲 + 红裙子;白色短袜;红皮鞋;领口"L.P."缩写
- 出处:东方妖妖梦 4 面 BOSS、东方花映塚自/敌机
- 主题曲:幽灵乐团 ~ Phantom Ensemble
- ZUN 评论:"想着把骚灵设计为独立的幽灵角色...给她们分配了乐器,但应该加一些打击乐器进去"
- 魔理沙的魔法书提到 Lyrica 的演奏"无趣",符卡生成的弹幕"简单至极",因为"乐器中没有灵魂"——这是个有趣的反差点

---

## 阶段 1:摸清 eraTW 的环境

### 1.1 确认 Lyrica 在游戏里的状态 **`[SKILL-OK]`**
- skill §3 给出文件结构,据此查 `ERB/口上・メッセージ関連/個人口上/`
- Lyrica 目录:`020 Lyrica [リリカ]/`,**只含 1 个文件 `HOGE`**(38 字节,内容是 GIT 合并占位"「GITマージ用ファイル」")—— 这是真正的"从零开始"
- 同样姐妹 Merlin(021)也只有 HOGE
- **Lunasa(022)有完整口上目录 `ルナサ/`**,十二个 ERB 文件 —— 完美的姐妹角色参考骨架
- Chara CSV:`CSV/Chara/Chara20 リリカ.csv` 已存在

### 1.2 创建 meta 日志
- 已创建本文件
- **决定**:命名 `lyrica_kojo_creation_log.md`(沿用 `learning/meta/` 下现有命名风格 `notes_phase1_*.md` 等)

---

## 阶段 2:references / CSV 调研

### 2.1 已读的 references **`[SKILL-OK]`**(skill §0.4 显式给出 lazy-load 表)
- `references/01-engine-label-catalog.md` — 全部派遣 label 形态 + EVENT subphase + MESSAGECHECK 家族 + EXTRASOURCE 家族 + 新 custom API + selector 机制
- `references/02-state-bus-namespaces.md` — CFLAG/TFLAG/TCVAR 等命名空间
- `references/06-workflow-recipes.md` — 三种工作流的完整范例(尤其 11.1 从零建)
- skill SKILL.md 已 inline 包含 §1-§10

### 2.2 必读的本仓库素材 **`[SKILL-GAP]`**

skill 没指明"对于一个具体角色,该读哪些参考素材",我自己摸索:

1. **Lyrica 的角色 CSV `CSV/Chara/Chara20 リリカ.csv`** — 这一份是 *人设的硬数据*,skill 提示"check 名前/呼び名 before authoring",但实际有更多关键信息:
   - 名前 `莉莉卡·普莉兹姆利巴` / 呼び名 `莉莉卡` (这是 `%CALLNAME:20%` 的展开)
   - 体型 `-1;矮小体型`、貧乳、Ｃ感度 1
   - 性格素质:`傲慢/好奇心/喜歡引人注目/学習快/小悪魔`
   - 音楽技能 5(满)/教養 1/戦闘能力 3
   - 自宅:`廃洋館 (loc 330)`、初期位置 `342;EX`、相性:21=150 22=150(三姐妹)
   - 弾幕特能:130(具体含义未确定;skill 没给弾幕特能字段对照表 — `[SKILL-GAP-2]`)
   - 口調:2

2. **CSV/Str.csv**`[[X]]` 字符串校验:**确认 `[[リリカ]]` / `[[莉莉卡]]` / `[[ルナサ]]` / `[[露娜薩]]` / `[[メルラン]]` / `[[梅露蘭]]` 都不在 Str.csv 里**,符合 skill §1 痛点 #2 警告 → **对自己/姐妹的引用全部用数字 ID + 注释**(`CFLAG:20:現在位置  ;Lyrica`)。`[[MASTER]]/[[TARGET]]` 是 bare 关键字也不能加方括号。
   - 顺带发现:Lunasa 的现有口上里多处用 `[[露娜薩]]` 也不在 Str.csv,**这意味着 022 既存口上有静默 bug**(编译为 0 即 MASTER 槽位)。我会在 meta 备注,但不修。

3. **CSV/Train.csv** — 命令 ID 完整表(340 行)。挑出 Lyrica 会写的命令清单:
   - 日常:300=会話 / 301=泡茶 / 302=身体接觸 / 303=道歉 / 305=膝枕 / 309=摸頭 / 310=摸屁股 / 311=擁抱 / 312=接吻
   - 行动:400=移動 / 402=就寝 / 403=休憩 / 405=外出 / 406=日記本 / 416=演奏(★人设核心)
   - 工作:411=戦闘訓練 / 412=学习 / 413=製作料理 / 414=吃飯
   - 派生:603=牽手 / 604=散步

4. **`ERB/口上・メッセージ関連/個人口上/022 Lunasa [ルナサ]/ルナサ/M_KOJO_K22_*.ERB`** — 姐姐 Lunasa 的现成口上(完整 12 文件)。**作为骨架参考**,而不是抄。学到的点:
   - 文件命名约定(`M_KOJO_K22_イベント.ERB / 日常系コマンド.ERB / カウンター.ERB / セクハラコマンド.ERB / 性交系コマンド.ERB / 愛撫系コマンド.ERB / 奉仕系コマンド.ERB / 派生コマンド.ERB / 絶頂.ERB`)
   - 顶部用 `;**** FlagManagement *****` 注释段记私有 CFLAG/TCVAR
   - 用 `[SKIPSTART]/[SKIPEND]` 包住实验性/不想编译的段(skill 在新 custom API 里提到这语法,但 Lunasa 用得更广,用作"暂屏蔽"工具)
   - Lunasa 的 SPEVENT 标签前会成对放 `@M_KOJO_SPEVENT_MESSAGECHECK_K22_<n> RETURN 1` —— skill §2.5 提到 MESSAGECHECK 但默认值 1 意味着"只显示 kojo,隐藏 engine 默认旁白";Lunasa 默认就这么设,值得我学这个习惯

### 2.3 本阶段新发现的 skill 缺口

- **`[SKILL-GAP-3]` skill 没指引"如何挑选要写的命令"**(应该写 50 个还是 5 个?用户测试覆盖时怎么取舍?)。我决定:挑出与 Lyrica 人设最契合的 ~17 个命令完整写,其余留空 stub
- **`[SKILL-GAP-4]` skill 没说一个文件最大行数应是多少**;Lunasa 的 日常系コマンド.ERB 一个文件 1900+ 行,显然没硬限。OK
- **`[SKILL-GAP-5]` skill 没说 `[SKIPSTART]/[SKIPEND]` 可以做"开发期注释"用** —— 它在 §10.6/10.7 只提及 "if uncertain wrap in SKIPSTART";但实际现存口上把这个语法**广泛用作多行注释/暂屏蔽**

---

## 阶段 3:Lyrica 口上设计

### 3.1 人物语气(基于 wiki + Chara CSV 综合)

- 三姐妹中**最矮**、**最小**(loli 体型)、但**最有体力**(矛盾点:外表小 vs 实际皮)
- 性格:**狡猾/小悪魔/教唆姐姐/算到三步以后**;**好奇心 + 喜欢引人注目**;**懒**(用最小气力换最大利益)
- 演奏:键盘 + 打击乐;"幻想之音"——别人没法听见或现实不存在的声音(可以化用为"嘿嘿嘿,这个曲子只有我能听见的部分哦")
- 与姐姐互动:Lunasa(优等生型)= 严肃唠叨, Lyrica 称呼"大姐"/"露娜",会撒娇骗她;Merlin(狂躁开朗型)= "二姐"/"梅露",有时一起恶搞
- **梗**:魔理沙之书评她"乐器中没灵魂、弹幕单调"——可以化用为自嘲式幽默
- 别名候选:外面读者称她"叮咚屋小姐"(咲夜评论)
- 出处梗:被西行寺家叫去演奏赏花会(与白玉楼/西行寺幽幽子有交集)

### 3.2 文件清单和 ~100 处对话分布

| 文件 | 内容 | dialog 数 |
|---|---|---:|
| `M_KOJO_K20_イベント.ERB` | 存在判定 / FLAGSETTING / COLOR / UPDATE / ENCOUNTER / EVENT_K20_1(房间)/2(早晨)/3(就寝) / EVENT_GRAVITY(silent) / EVENT_PERMISSION_1(silent) / EVENT_LOST_VIRGIN_STOP(silent) / SPECIALDAY_EVENT / @K20_BEFORETRAIN(silent) | 18 |
| `M_KOJO_K20_日常系コマンド.ERB` | 300,301,302,303,305,309,310,311,312,400,402,403,405,416,411,412 + 标准 cascade | 50 |
| `M_KOJO_K20_派生コマンド.ERB` | SCOM(派生)1-2 个 + 603=牽手 | 5 |
| `M_KOJO_K20_カウンター.ERB` | COUNTER 通用 ~3 + UNIQUE_COUNTER1 完整(ABLE/FREQUENCY/MESSAGE/SOURCE) | 8 |
| `M_KOJO_K20_弾幕勝負.ERB` | DANMAKU(ARGS, ARG) 7 场景全覆盖 | 7 |
| `M_KOJO_K20_刻印取得.ERB` | MARKCNG with TFLAG guard | 4 |
| `M_KOJO_K20_絶頂.ERB` | PALAMCNG_A / B / B2 / F | 5 |
| `M_KOJO_K20_莉莉卡特殊イベント.ERB` | `@K20_CONCERT_INVITE`(节日触发的演奏会邀请,带 ASK_YN + SOURCE) + 1-2 SPEVENT | 6 |
| `M_KOJO_K20_日記.ERB` | DIARY_K20_EXIST/BEFORE_CHECK/TEXT/AFTER_CHECK + COM_406 | 3 |
| `M_KOJO_K20_カスタム.ERB` | CUSTOM_BUTTON_CONDITION/_BUTTON + CUSTOM_TALENT_SET | 5(按钮 1 个 + talent 2 个 + 体验响应) |
| `M_KOJO_K20_セクハラコマンド.ERB` | 几个 stub LOCAL=0(展示空仓位) + 1 完整 | 3 |
| `M_KOJO_K20_性交系コマンド.ERB` | 全部 stub LOCAL=0(skill §0.2:不生成情色文字,只放结构) | 0 |
| `M_KOJO_K20_愛撫系コマンド.ERB` | 全部 stub | 0 |
| `M_KOJO_K20_道具系コマンド.ERB` | 全部 stub | 0 |
| `M_KOJO_K20_自慰系コマンド.ERB` | stub | 0 |
| `M_KOJO_K20_関数ライブラリ.ERB` | `@K20_FIND_SISTER(ARG)` / `@K20_C_NAME(ARG)` 私有函数 | 0 |
| `readme.txt` | 元信息 / 许可 | - |
| `フラグ管理メモ.txt` | 私有 CFLAG 1000-1099 / TCVAR 350-359 列表 | - |

**预计 dialogue 总数:~115 处**(略超 100,留余量)。

### 3.3 功能点覆盖清单(测试 skill 是否完整) — 我会逐项打勾

- [ ] 存在判定 `@M_KOJO_K20(ARG) RETURN 1`
- [ ] FLAGSETTING 设置 時間停止/眠姦/扮演/推倒禁止
- [ ] COLOR `SETCOLOR`
- [ ] UPDATE
- [ ] ENCOUNTER
- [ ] SPEVENT(_x) 配 MESSAGECHECK
- [ ] EVENT_K20_1 (房间) — 含**同格 guard**(skill §1 痛点 #4)和 ARG 1-5 子相位
- [ ] EVENT_K20_2 / _3
- [ ] EVENT_GRAVITY(silent — 引力点设定)
- [ ] EVENT_PERMISSION_1(silent)
- [ ] EVENT_LOST_VIRGIN_STOP(silent)
- [ ] @K20_BEFORETRAIN(silent)
- [ ] SUCCESS_COM + MESSAGE_COM + _1 body 双标签约定
- [ ] MESSAGE_COM_K20_00 catch-all 设 `LOCAL=0`(skill §1 痛点 #6)
- [ ] 标准分支 cascade: 時間停止 → 睡眠 → 扮演 → CFLAG:318 → 诶嘿嘿 → TALENT 5 阶
- [ ] %CALLNAME:MASTER% 用法
- [ ] SELECTCASE RAND:N
- [ ] %TEXTR("a/b/c")% 单行随机
- [ ] PRINTFORML / PRINTFORMW 区分(W 等待玩家)
- [ ] 数字 ID + 注释(skill §1 痛点 #2)代替 `[[X]]`
- [ ] CHK_DATENOW(CFLAG:MASTER:约会中) 正确写法(skill §1 痛点 #8)
- [ ] COUNTER_K20_n
- [ ] UNIQUE_COUNTER1_ABLE / FREQUENCY / MESSAGE / SOURCE 全套
- [ ] DANMAKU(ARGS, ARG) — 用 ARG 不用自定义参数名(skill §1 痛点 #1)
- [ ] MARKCNG with `TFLAG:21..24 / 時姦刻印取得` guard(skill §1 痛点 #7)
- [ ] PALAMCNG_A / B
- [ ] DIARY_K20_EXIST/BEFORE/TEXT/AFTER + COM_406
- [ ] SPECIALDAY_EVENT 用 DAY:2/DAY:3
- [ ] @K20_<NAME> 私有事件 + ASK_YN + SOURCE 写入
- [ ] CUSTOM_BUTTON / CUSTOM_TALENT_SET(新 API,带 SKIPSTART 包裹兜底)
- [ ] #FUNCTION / #FUNCTIONS 私有函数
- [ ] 私有 CFLAG 1000-1099 写入 フラグ管理メモ.txt
- [ ] EXTRASOURCE_COM_GENERAL
- [ ] MESSAGECHECK 配对(SPEVENT 至少一个)
- [ ] UTF-8 BOM 全部文件(skill §1 痛点 #10) — Write 工具不写 BOM,写完后批量补

---

## 阶段 4:实际实施 — 完成

### 4.1 文件清单(16 个 ERB + 2 个 txt)

```
ERB/口上・メッセージ関連/個人口上/020 Lyrica [リリカ]/リリカ/
├── M_KOJO_K20_イベント.ERB              (13 KB - 存在/FLAGSETTING/COLOR/UPDATE/ENCOUNTER/SPEVENT_1
│                                          /EVENT 1-3/GRAVITY/PERMISSION_1-2/LOST_VIRGIN_STOP
│                                          /BEFORETRAIN/SPECIALDAY)
├── M_KOJO_K20_関数ライブラリ.ERB         ( 3 KB - K20_FIND_SISTER / K20_C_NAME / K20_FONDNESS_TIER)
├── M_KOJO_K20_日常系コマンド.ERB          (19 KB - 16 命令完整 + catch-all _00 + EXTRASOURCE_GENERAL)
├── M_KOJO_K20_派生コマンド.ERB           ( 2 KB - 603=牽手 + 多人 SCOM 示例)
├── M_KOJO_K20_セクハラコマンド.ERB        ( 2 KB - 200 完整 + 4 个 stub)
├── M_KOJO_K20_性交系コマンド.ERB          ( 1 KB - 4 个 stub)
├── M_KOJO_K20_愛撫系コマンド.ERB          ( 1 KB - 4 个 stub)
├── M_KOJO_K20_道具系コマンド.ERB          ( 1 KB - 3 个 stub)
├── M_KOJO_K20_自慰系コマンド.ERB          ( 1 KB - 1 个 stub)
├── M_KOJO_K20_カウンター.ERB             ( 4 KB - COUNTER 1-3 + UNIQUE_COUNTER1 全套)
├── M_KOJO_K20_弾幕勝負.ERB               ( 3 KB - DANMAKU(ARGS, ARG) 7 场景)
├── M_KOJO_K20_刻印取得.ERB               ( 2 KB - MARKCNG with TFLAG guard, 5 mark types)
├── M_KOJO_K20_絶頂.ERB                    ( 2 KB - PALAMCNG_A 完整 + B 部分 + A2/B2/F stub)
├── M_KOJO_K20_莉莉卡特殊イベント.ERB     ( 5 KB - K20_CONCERT_INVITE / NEW_YEAR_HASSLE / BIRTHDAY / TEACH_PIANO)
├── M_KOJO_K20_日記.ERB                    ( 4 KB - DIARY 全套 + 命令 406)
├── M_KOJO_K20_カスタム.ERB               ( 4 KB - CUSTOM_TALENT_SET + 2 个 button + KOJO_VERSION)
├── readme.txt                              (3 KB)
└── フラグ管理メモ.txt                       (1.5 KB)
```

### 4.2 §2 验证 pass — 全部通过

```
=== Custom-named function parameters ===   (none — clean ✓)
=== EVENT_K_X 同格 guard ===                 OK ✓
=== GRAVITY 静默 ===                          OK (no PRINT*)  ✓
=== MARKCNG TFLAG guard ===                  OK ✓
=== BOM ===                                  All 18 files ✓
=== IF/ENDIF balance ===                     All balanced ✓
=== SELECTCASE/ENDSELECT balance ===         All balanced ✓
=== [SKIPSTART]/[SKIPEND] balance ===        All balanced ✓
=== RAND:0 (would crash) ===                 None ✓
=== Duplicate @label ===                     None ✓
=== CFLAG slot names ===                     All in CFLAG.csv ✓
=== TFLAG slot names ===                     All in TFLAG.csv ✓
=== TCVAR slot names ===                     All in TCVAR.csv ✓
=== [[X]] string usage ===                   None (用数字 ID 代替, skill §1#2)  ✓
```

PRINTFORM 总数 = **279 句** ≈ 100+ 处独立对白(超过 ~100 目标)。

### 4.3 创作中发现的真实 bug —— 这是 skill 没充分指导的部分(`[SKILL-GAP]`)

**Bug 1:`TFLAG:中止破瓜` 不存在** 我最初的 `EVENT_K20_LOST_VIRGIN_STOP` 写成了:
   ```erb
   IF ABL:20:親密 <= 0 && !TALENT:20:愛欲
       TFLAG:中止破瓜 = 1                      ;BUG
   ENDIF
   RETURN 0
   ```
   **Skill 01-engine-label-catalog.md §2.4 明确写道**:"Body sets `TFLAG:中止破瓜` or similar to abort the virginity-loss flow"。**这条指引是错误的**。
   实际上 TFLAG.csv 没有 `中止破瓜` 槽位。引擎(`TRACHECK_LOST_VIRGIN.ERB:394-399`)的真实实现是看 `RESULT == 1`:
   ```
   CALL KOJO_MESSAGE_SEND("LOST_VIRGIN_STOP", 0, ARG)
   IF RESULT == 1
       RETURN -1            ;abort
   ```
   正确写法:`SIF <abort condition> / RETURN 1` 或 `RESULT = 1`。
   **建议 skill 修订**:把 §2.4 LOST_VIRGIN_STOP 一行从"Body sets `TFLAG:中止破瓜`"改成"Body returns 1 to abort, 0 to proceed (engine reads via RESULT)"。`[SKILL-BUG-1]`

**Bug 2:`PERMISSION_<n>` RESULT 语义需要从现存口上反推** Skill 01-engine-label-catalog.md §2.4 只说"Body decides push-down / advance consent and writes a result flag",**没说返回什么值代表什么**。我最初写的:
   ```erb
   RESULT = 1   ;許可
   RESULT = 0   ;拒否
   RETURN RESULT
   ```
   通过 grep 现存口上 `K7_PERMISSION_1` 发现实际语义是:
   ```
   ;RETURN -1   = 拒否(强制中止)
   ;RETURN  0   = 通常成功
   ;RETURN  1   = (用途不明、注释掉了)
   ```
   即 0 是 allow,-1 是 refuse —— 我的初稿写反了。**`[SKILL-BUG-2]` 建议 skill 在 §2.4 把 PERMISSION_<n> 的返回值规约写明**:`RETURN -1 = refuse, RETURN 0 = allow`。

### 4.4 创作时使用的 skill 范围外手段汇总(`[SKILL-GAP]` 累计)

> **诚实声明**:这次 Lyrica 口上的产出**不是仅凭 skill 完成的**。下表是真实参考清单 — 凡是不读这些就做不出能跑/能编译的口上。"未来 LLM 仅凭 skill 复现"这个目标,在当前 skill 版本下**做不到**。

| # | 行为 | 用了什么 | 为什么 skill 单独不够 |
|---|---|---|---|
| 1 | 访问 wiki 获取人物设定 | WebFetch(失败)→ pdftotext 提取 PDF | skill 不包含获取角色背景的指引;尝试无意义的 WebFetch 浪费 token |
| 2 | 提取 PDF 双栏文本 | `pdftotext -enc UTF-8`(不带 `-layout`) | skill 没有 PDF 解析建议;layout 模式会打乱中日文双栏 |
| 3 | **读 Lunasa K22 现存口上**(`022 Lunasa/ルナサ/M_KOJO_K22_イベント.ERB` 头 120 行 + `..._日常系コマンド.ERB` 头 200 行) | Read 工具 | 学到:① FlagManagement 注释段格式 ② `@SPEVENT_MESSAGECHECK_K22_1 / RETURN 1` 这种"默认抑制 engine 旁白"的实战用法 ③ `[SKIPSTART]/[SKIPEND]` 用作开发期注释 ④ 命令 body 排版 ⑤ `CFLAG:TARGET:跳蛋挿入 / CFLAG:TARGET:陪睡中` 等真实情境分支 ⑥ `CHK_DATENOW(...)` 真实写法。**这些 skill 都没具体写**,§11.1 范例只是骨架 |
| 4 | 校验 `[[X]]` 字符串 | `grep` Str.csv | skill §1 痛点 #2 提到要校验;skill 没给出 grep 命令模板 |
| 5 | 校验 CFLAG/TFLAG/TCVAR 槽名 | `grep` 三个 CSV | skill 痛点 #9 强调 byte-exact;skill 没给完整命令 |
| 6 | Train.csv 命令 ID 选择 | `grep` 命令 300-630 段 | skill §6 列了几个常见命令但没全表;选哪些写 skill 没指引 |
| 7 | **读引擎源码 `ERB/口上・メッセージ関連/KOJO_MESSAGE.ERB:880-940`** | Read | 看 PERMISSION/LOST_VIRGIN_STOP 派遣机制(`TRYCALLFORM`、`RESET RESULT=0` 然后读返回值)。**没有这个根本不知道 silent label 怎么和 engine 交互** |
| 8 | **读引擎源码 `ERB/ステータス計算関連/TRACHECK_LOST_VIRGIN.ERB:389-399`** | Read | 反推 LOST_VIRGIN_STOP 真实 abort 语义为 `RESULT == 1`。**这条事实直接推翻 skill §2.4 的写法**(skill 说 `TFLAG:中止破瓜=1`,实际不存在该槽位)→ `[SKILL-BUG-1]` |
| 9 | **读 Star K7 现存口上 `007 Star/スターサファイア - backup_5_14_2024/M_KOJO_K7_イベント.erb:4654-4666`** | Grep + Read | 反推 PERMISSION_<n> 返回值规约:`RETURN -1=拒否,0=通常成功,1=未使用`。**skill 完全没写返回值规约** → `[SKILL-BUG-2]` |
| 10 | **读 Sanae K31 现存代码 `031 Sanae/早苗さん別人版/パッチ/COMF350 押し倒す.ERB.変更前:60-68`** | Grep + Read | 验证 PERMISSION 调用方对 RESULT 的处理(`SELECTCASE RESULT / CASE -1 / CASE 0 / CASE 1`),交叉验证项 #9 的结论 |
| 11 | **读 Luna K6 现存口上 `006 Luna/ルナチャイルド/M_KOJO_K6_日記.ERB:340-349`** | Grep + Read | 学到 `@DIARY_TEXT_K{id}, PAGENUM, MODE, PAGECOUNT` 必须配合 body 第一行 `#DIM PAGENUM / #DIMS MODE / #DIM PAGECOUNT` 才能编译。**skill 给的签名直接照抄会触发 Emuera 警告 Lv2 + 变量未定义**,这是 Emuera 实际 load 报错后才发现的 → `[SKILL-BUG-3]` |
| 12 | 给所有 ERB 补 BOM | `printf '\xef\xbb\xbf' \| cat - $f` | skill 痛点 #10 强调要 BOM,但 references/10 我没读完(可能里面有 recipe);Write 工具默认不写 BOM |
| 13 | grep IF/ENDIF 平衡检查 | `grep -cE "^\s*IF"` | skill §2 验证 pass 没含此项 |
| 14 | grep duplicate label 检查 | `sort \| uniq -c` | skill §2 验证 pass 没含此项 |

**关键观察**:行 #3、#7、#8、#9、#10、#11 全部是"读其他口上或引擎源码"。这些信息在 skill **完全没有/写错了**。所以本次创作的真实工作流是:

```
skill 提供骨架与方向
  ↓
读 Lunasa K22 复制风格  ← 行 #3
  ↓
按 skill 写出第一版
  ↓
Emuera 加载 / 用户测试报错
  ↓
读其他角色口上 + 引擎源码 反推真实规约 ← 行 #7-#11
  ↓
回填修正
```

这个工作流意味着 skill **必要但不充分**。要让一个 LLM"仅凭 skill 复现"产出能跑的口上,**skill 至少需要修订 §1#1 自定义参数名规则、§2.4 PERMISSION 返回值规约、§2.4 LOST_VIRGIN_STOP 返回值规约、§2.4 DIARY_TEXT 的 #DIM 配套要求**。

### 4.5 功能点覆盖清单 — 全部 ✓

| 类别 | 项 | 状态 | 文件 |
|---|---|:---:|---|
| Lifecycle | 存在判定 `@M_KOJO_K20(ARG)` | ✓ | イベント |
| Lifecycle | FLAGSETTING(時停/眠姦/扮演/推倒/来訪) | ✓ | イベント |
| Lifecycle | COLOR `SETCOLOR 0xFF6478` | ✓ | イベント |
| Lifecycle | UPDATE | ✓ | イベント |
| One-shot | ENCOUNTER(立 CFLAG:面識) | ✓ | イベント |
| Scripted | SPEVENT_1 配 MESSAGECHECK pair | ✓ | イベント |
| Generic | EVENT_K20_1 ARG 1-5 + **同格 guard** | ✓ | イベント |
| Generic | EVENT_K20_2 / _3 + 同格 guard | ✓ | イベント |
| Silent | EVENT_GRAVITY(`TCVAR:20:引力点`) | ✓ | イベント |
| Silent | EVENT_PERMISSION_1 / _2(返回 -1/0) | ✓ | イベント |
| Silent | EVENT_LOST_VIRGIN_STOP(返回 0/1) | ✓ | イベント |
| Silent | @K20_BEFORETRAIN | ✓ | イベント |
| Hook | SPECIALDAY_EVENT(DAY:2/DAY:3 判定) | ✓ | イベント |
| Command | SUCCESS_COM + MESSAGE_COM + _1 body 双标签 | ✓ | 日常系 |
| Command | MESSAGE_COM_K20_00 catch-all `LOCAL=0` | ✓ | 日常系 |
| Command | 标准 cascade(時停→睡眠→扮演→318→诶嘿嘿→TALENT 5阶) | ✓ | 日常系(300) |
| Command | %CALLNAME:MASTER% | ✓ | 全部 |
| Command | SELECTCASE RAND:N + CASEELSE | ✓ | 多处 |
| Command | %TEXTR("a/b/c")% 单行随机 | ✓ | 日常系 300/400/403 |
| Command | PRINTFORML / PRINTFORMW 区分 | ✓ | 全部 |
| Command | 数字 ID + 注释,不用 `[[X]]` | ✓ | 全部 |
| Command | `CHK_DATENOW(CFLAG:MASTER:约会中)` 正确写法 | ✓ | 日常系 300/カウンター |
| Counter | COUNTER_K20_1/2/3 | ✓ | カウンター |
| Counter | UNIQUE_COUNTER1_ABLE/FREQUENCY/MESSAGE/SOURCE 全套 | ✓ | カウンター |
| Battle | DANMAKU(ARGS, ARG) — `ARG` 不用 `相手残機` | ✓ | 弾幕勝負 |
| Mark | MARKCNG with TFLAG:21..24 guard | ✓ | 刻印取得 |
| Climax | PALAMCNG_A 完整 + 其他 stub | ✓ | 絶頂 |
| Diary | DIARY_EXIST/BEFORE_CHECK/TEXT/AFTER_CHECK + 命令406 | ✓ | 日記 |
| Author | @K20_<NAME> 私有事件 + ASK_YN + SOURCE | ✓ | 莉莉卡特殊 |
| Author | #FUNCTION / #FUNCTIONS 私有函数 | ✓ | 関数ライブラリ |
| Author | EXTRASOURCE_COM_GENERAL | ✓ | 日常系 |
| Author | 私有 CFLAG 1000-1099 + TCVAR 350-359 | ✓ | フラグ管理メモ.txt |
| New API | CUSTOM_TALENT_SET(3 个 talent) | ✓ | カスタム |
| New API | CUSTOM_BUTTON_CONDITION + KOJO_COM_K20_<Y> 2 个 button | ✓ | カスタム |
| New API | KOJO_VERSION + KOJO_VERSION_UPDATE | ✓ | カスタム |
| File | UTF-8 BOM 全部 18 文件 | ✓ | 批量补 |
| Inter-char | 私有 helper 引用姐妹(K22 Lunasa, K21 Merlin) | ✓ | 関数ライブラリ |

**全部 37 项功能点覆盖 ✓**

> ⚠️ **重要警告 — 这里的 ✓ 只表示"结构上写出来了 + 加载阶段 Emuera 不报错"。不代表"runtime 跑通了"。** 见下面 §4.6 的未验证清单。

### 4.6 重要免责:实际**未**经过 runtime 验证的部分

下表 ✓ 项的真实测试深度:

| 验证级别 | 含义 | 本次达到的项 |
|---|---|---|
| **L0:语法编译** | Emuera load 阶段不报错 | 全部 37 项(经过 BUG-3 修复后) |
| **L1:加载日志干净** | 没有警告 Lv2 / Lv1 | 假设 ✓(没看完整日志) |
| **L2:进入游戏** | 角色出现、ENCOUNTER 可触发 | **未测**(用户可能测过 ENCOUNTER 一次) |
| **L3:命令路径** | 每个命令实际跑出预期台词 | **未测** |
| **L4:状态变迁** | TALENT 提升 / SOURCE 累加正确 | **未测** |
| **L5:特殊事件** | SPEVENT / SPECIALDAY / DIARY 实际触发 | **未测** |
| **L6:多角色互动** | SCOM 派遣 / GRAVITY AI / inter-char | **未测** |

**仅用户**已确认 runtime 行为的项:
- ✅ Emuera 加载报 DIARY_TEXT 错(BUG-3) — 已修
- ⚠️ UNIQUE_COUNTER1 触发条件太宽(常规对话后必触发) — **不是 skill bug,是我设的 frequency 12 + 思慕 阈值过低**;用户已知,选择不改

**完全没碰过的功能点**:
- CUSTOM API 的 button(`KOJO_CUSTOM_BUTTON_K20_0/1`)从未被点击过
- CUSTOM TALENT(角色介绍 tab 的 3 个 talent)从未被查看过
- PALAMCNG_A / B / B2 / F 全套 — 未触发观察
- MARKCNG with TFLAG guard — 未触发观察
- DIARY_TEXT body(修复后) — 未读取观察
- SPECIALDAY_EVENT 1/1 / 7/8 分支 — 跨日测试零次
- @K20_CONCERT_INVITE — **写完后初版本没挂任何触发点**(已在本次 review 中通过 EVENT_K20_1 case 1 加 hook 修复 — 这本身证明"无运行时测试就有 bug 漏掉")
- @K20_NEW_YEAR_HASSLE / @K20_BIRTHDAY / @K20_TEACH_PIANO — 路径未走过
- COUNTER_K20_1/2/3 — 自动触发未观察
- SP_EVENT 1(ファーストキス)— ARG 0/1/2 三个 case 未跑过
- 弾幕勝負 7 个 ARGS 场景 — 未触发观察
- @M_KOJO_EVENT_K20_GRAVITY 的引力点设定是否真的影响 NPC 行为 — 未观察

### 4.7 已知 bug 大概率不止 §4.3 列出的 3 个

§4.3 的 3 个 bug 都是在以下两个有限情境被发现的:
1. **加载阶段** Emuera 编译报错(只 BUG-3)
2. **写代码时与现存口上对照**(BUG-1 / BUG-2 — 我恰好为了反推语义读了 K7 / TRACHECK_*.ERB)

**没找过的 bug 类型**:
- runtime 路径上的 RESULT 误用 / SOURCE 累加值不合理
- `CFLAG:N:slot` 中的 slot 名 byte 级错配(我 grep 校验了,但跨 fork 的"看似存在但语义不同"未排查)
- SCOM 多人派遣的 TARGET 切换是否正确
- CUSTOM 按钮 click handler 返回 1/0/-1 的实际效果
- 节日 hook 在跨年时是否被正确派遣
- `RAND:N` 的随机分布在小样本下是否合理
- `%CALLNAME:MASTER%` 在某些 inter-char 上下文下是否变成空字符串
- DAILY_EVENT_K20_<n> 完全没写,但 catch-all 是否会蹦出来未知

**给下一 Claude 的提醒**:**修完 §5.2 表里 3 个 bug 后,真实 bug 数大概率仍 > 0**。skill 改进应当包含"如何系统性 runtime 测试"的指引(目前 skill §2 验证 pass 只覆盖到 L0-L1)。

---

## 阶段 5:总结 —— 给 skill 维护者的反馈

### 5.1 skill 的优点(基于这次实战体验) — **应当保留不动的部分**

下面是命中率高、实战检验过的 skill 部分。**下一 Claude 不要因为重构而把它们改掉**。

| skill 位置 | 内容 | 保留理由 |
|---|---|---|
| `SKILL.md` §1 | **12 条痛点列表整体** | 实战中至少 5 条直接救命(#1 自定义参数名、#2 `[[X]]` 静默零、#4 同格 guard、#5 GRAVITY 静默、#7 MARKCNG guard);整体保留,只在 #1 内容内扩展(见 §5.2 表) |
| `SKILL.md` §6 | 标准 body 模板(SUCCESS_COM + MESSAGE_COM + _1 body 三段) | Lyrica 16 个命令全用这个模板,无问题。**结构对** |
| `SKILL.md` §8 | 标准 cascade 顺序(時停→睡眠→扮演→ブチギレ→诶嘿嘿→TALENT 5 阶) | 实战写 K20_300 完整跑了一遍,顺序合理 |
| `SKILL.md` §0.4 | mode detection + lazy-load reference 表 | Claude Code 模式下读 01/02/06 就够覆盖 80%,设计高效 |
| `SKILL.md` §0.2 | 不生成成人内容指引 | 让我顺利留 stub 而不被推着写;关键安全栏 |
| `references/` | lazy-load 整体设计 | 阻止全量加载浪费上下文 |
| `SKILL.md` §3 | 全局文件结构图 | 找姐妹角色目录靠它 |
| `SKILL.md` §4 | dispatch 流走查(从 player input → engine TRYCALLFORM → kojo label) | 让我理解"我只写 label 不写 dispatch",免去无效尝试 |
| `references/06` §11.1 | 从零建工作流的整体流程 | 大方向对(只是 Step 1 该加"读现存口上") |

### 5.2 skill 的不足 — **下一 Claude 应当修订的位置清单**

**3 个真 bug**(直接影响编译/运行):

| ID | skill 文件 | skill 章节 | 现状描述 | 应改为 | 证据来源 |
|---|---|---|---|---|---|
| **BUG-1** | `references/01-engine-label-catalog.md` | §2.4 表中 `EVENT_K{id}_LOST_VIRGIN_STOP` 行 | "Body sets `TFLAG:中止破瓜` or similar to abort" | "Body returns 1 to abort, 0 to proceed (engine reads via RESULT)" | `ERB/ステータス計算関連/TRACHECK_LOST_VIRGIN.ERB:389-399` |
| **BUG-2** | `references/01-engine-label-catalog.md` | §2.4 表中 `EVENT_K{id}_PERMISSION_<n>` 行 | "Body decides push-down / advance consent and writes a result flag" | "Body RETURN -1 = refuse (force abort), RETURN 0 = allow (proceed normally), RETURN 1 = (use unclear, commented out in existing kojo)" | `007 Star/.../M_KOJO_K7_イベント.erb:4654-4666` + `031 Sanae/.../COMF350 押し倒す.ERB.変更前:60-68` + `KOJO_MESSAGE.ERB:880-915` |
| **BUG-3** | `references/01-engine-label-catalog.md` + `SKILL.md` §1#1 | §2.4 表中 `DIARY_TEXT_K{id}` 行 | 签名 `@DIARY_TEXT_K{id}, PAGENUM, MODE, PAGECOUNT` 直接照抄会触发 Emuera 警告 Lv2 | 加注:"body 第一行必须 `#DIM PAGENUM` / `#DIMS MODE` / `#DIM PAGECOUNT`,否则编译失败" + 把 §1#1 自定义参数名规则推广为通用规则(不仅 `相手残機`,DIARY_TEXT 也是同一类) | `006 Luna/.../M_KOJO_K6_日記.ERB:340-349` |

**7 个 skill gap**(影响易用性、不影响编译):

| ID | skill 位置 | 缺什么 | 建议改动 |
|---|---|---|---|
| **GAP-1** | `SKILL.md` §0.4 / 新增章节 | 没有"获取人物背景"指引 | 加一行:"对于角色背景资料,**优先要求用户上传 wiki PDF/文本**;不要默认 `WebFetch` —— eratw 用户多在中国大陆,thwiki 等站点经常 socket 异常或 HTTP 418" |
| **GAP-2** | `SKILL.md` §9 / `references/06` §11.1 | 没说"挑多少命令" | 加:"用户常先说'写 100 处对话'但实际人设最契合的命令往往只有 10-20 个。建议挑 ~17 个完整写,其余 LOCAL=0 stub。**先确认列表再动手**" |
| **GAP-3** | `SKILL.md` §2 验证 pass | 漏掉 4 类语法平衡检查 | 加 IF/ENDIF balance、SELECTCASE/ENDSELECT balance、`[SKIPSTART]/[SKIPEND]` balance、duplicate `@label` 检查 |
| **GAP-4** | `SKILL.md` 任意位置 | `[SKIPSTART]/[SKIPEND]` 用法描述不全 | 现存口上(K22 Lunasa 等)广泛把它当**开发期多行注释**用。skill 应说明这种用法合法 |
| **GAP-5** | `SKILL.md` §0.4 lazy-load 表 | 几个高价值素材没列入 | 加:① "为新口上挑命令时" → `CSV/Train.csv`;② "silent label 行为不明时" → `ERB/口上・メッセージ関連/KOJO_MESSAGE.ERB` + `ERB/ステータス計算関連/TRACHECK_*.ERB`;③ "看真实 cascade 写法" → 同性格邻近角色 kojo |
| **GAP-6** | `references/06` §11.1 第 1 步 | 没强制读现存口上 | 第 1 步加:"在 scaffold 之前,**通读至少一份性格相近角色的现存 kojo**(姐妹/同性格类型优先);骨架命名约定、`[SKIPSTART]` 用法、`CFLAG:TARGET:陪睡中` 等情境分支 skill 都没全列,只能从现存口上学" |
| **GAP-7** | `SKILL.md` §2 / 新增 §11 | 没有 runtime 测试指引 | 加一节"runtime 验证方法":开 Emuera → ENCOUNTER → 跑每个写过的命令一次 → 记录是否台词正确 → 检查 SOURCE 是否累加。skill 当前只到 L0-L1(见 §4.6 的验证级别表) |

**3 个 bug 的修订紧急度**:全部 **P0**(影响实际编译/运行)。**7 个 gap 的紧急度**:GAP-3 / GAP-6 = P1(直接影响产出质量),其余 = P2。

### 5.3 token usage 记录
- **开始时:current session token usage = 50%**(用户在阶段 3 末尾报告)
- **结束时:current session token usage ≈ 65%**(用户报告;承认估值不精确)
- **本次创作消耗 ≈ 15 个百分点**,产出 16 个 ERB + 2 个 txt + 一份 meta md;含 §2 验证 pass、3 个 skill bug 的发现与修复

### 5.4 给未来"只看 skill 的 LLM"的实操建议(诚实版)

**重要前提:本次创作证明,仅凭 skill 是写不出能跑的口上的。** 见 §4.4 表 — 12/14 项操作要么是引擎源码、要么是其他角色现存口上。所以建议先扩大读取面,不要假装 skill 自足。

1. **第一步永远是 grep CSV**(Str / CFLAG / TFLAG / TCVAR / Train + Chara CSV);不要相信记忆,不要相信 skill 列表的"slot 名候选"
2. **第二步必读至少一份现存口上**。把它当作"骨架模板"通读,而不是只挑一两条引用。skill §11.1 的范例**只是骨架的骨架**,实战写法比它复杂得多
3. **任何 silent label / engine-callable label,在写之前都要 grep `ERB/口上・メッセージ関連/KOJO_MESSAGE.ERB` 找到对应的 `TRYCALLFORM` 段**,看清楚:
   - 引擎传什么 ARG?
   - 调用前 RESULT 设置成什么?
   - 调用后引擎读 RESULT 还是 RETURN 值?
   - 不同返回值对应什么 caller 行为?

   **不要相信 skill 文档对 silent label 返回值规约的描述** — 已确认 PERMISSION 和 LOST_VIRGIN_STOP 两处描述都错了/缺了
4. **任何带"自定义参数名"的签名**(skill 里出现的 `PAGENUM, MODE, PAGECOUNT` / `相手残機` / 其他),在 body 第一行**必须 `#DIM` / `#DIMS` 声明**。Emuera 不会自动接受自定义参数名 — 这是底线规则,违反就编译失败
5. **Write 工具不写 BOM** — 写完批量补:
   ```bash
   for f in *.ERB; do
     bom=$(head -c 3 "$f" | xxd -p)
     [ "$bom" = "efbbbf" ] || (printf '\xef\xbb\xbf' | cat - "$f" > "$f.bom" && mv "$f.bom" "$f")
   done
   ```
6. **数字 ID 永远比 `[[X]]` 安全**,姐妹之间也用数字 ID + 注释。`[[名前]]` 不在 Str.csv 里就静默编译为 0
7. **写完先跑 §2 验证 pass + 额外检查**(IF/ENDIF balance、SELECTCASE/ENDSELECT balance、SKIPSTART/SKIPEND balance、duplicate `@label`、`RAND:0`)。这些 skill §2 没全部含
8. **承认必然要加载 → 报错 → 回填修正这一循环**。第一版几乎不可能干净通过 Emuera 加载;预留修复迭代时间

### 5.5 这个实验的诚实结论

> **目标**:让一个 LLM 仅凭 skill 复现这次创作产出能跑的口上。
> **结论**:**当前 skill 版本下,做不到。**
>
> 必要的额外信息(skill 写错或缺失,但属于编译/运行硬约束):
> - PERMISSION_<n> 返回值规约
> - LOST_VIRGIN_STOP 返回值规约(skill 给的 `TFLAG:中止破瓜` 是不存在的槽位)
> - DIARY_TEXT_K{id} 的 #DIM/#DIMS 配套要求
> - "自定义参数名"规则的精确范围(skill §1#1 不够明确)
>
> 即便补上以上四条,LLM 仍然最好读至少一份现存口上骨架,因为 skill 的范例代码量太少,无法传达"实战中 cascade 到底有多复杂、CFLAG:TARGET:* 有哪些常用情境分支"等隐性知识。
>
> **改进路径(如果想达到"skill 自足")**:
> 1. 修复 3 个已知 bug (§5.2)
> 2. 把 §6 的标准 body 模板从"骨架"扩展为"中度详细的实战范例"(可以从 Lunasa K22 摘改)
> 3. 在 references/ 里加一份 `silent_labels_engine_contract.md`,逐个列每个 silent label 的:派遣源码位置 / RESULT 初值 / caller 期望返回值 / 典型 body 模式
> 4. 把"读至少一份现存口上"显式纳入 §11.1 工作流第一步



