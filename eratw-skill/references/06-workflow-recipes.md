# Workflow recipes (full)

Detailed walk-throughs for the three common kojo authoring tasks. SKILL.md §9 has the abridged versions.

## 11. Workflow recipes

> **About these three recipes**: they're ordered by *scope*, not just topic.
>
> - **11.1** is the heaviest — building a brand-new kojo from an empty directory. You generate dozens of files and many labels. Use this when the target character has no kojo yet (e.g. a 賑やかし stub or an entirely empty dir).
> - **11.2** is medium — adding a *new feature* (a major one-shot scripted event with its own progression flags) to an *already-working* kojo. You touch existing files but the additions are substantial: a new label, a state-progress CFLAG, a trigger hook in another file.
> - **11.3** is the lightest — a *small content tweak* to a single existing label body. One file, one branch added, no new labels or flags.
>
> If a user request is ambiguous, ask which scope they mean before scaffolding.

### 11.1 New character variant from scratch

用户请求示例:「我想为 021 Merlin (中文名梅露兰) 写一份口上。她是三妖精之一，性格大方爽朗，喜欢音乐和恶作剧，对%CALLNAME:MASTER%有姐姐式的关怀感。」

(Confirmed: `021 Merlin [メルラン]/` is currently an empty `HOGE` placeholder, so we're building from scratch.)

**Step 1 — 搭建目录骨架.**

推荐的初始文件集（之后可以扩展）:

```
個人口上/021 Merlin [メルラン]/<你的variant名>/
├── M_KOJO_K21_イベント.ERB          ; existence + FLAGSETTING + COLOR + UPDATE + ENCOUNTER + ~5 EVENT slots
├── M_KOJO_K21_日常系コマンド.ERB    ; ~10 daily commands at minimum
├── M_KOJO_K21_セクハラコマンド.ERB  ; can be all LOCAL=0 stubs
├── M_KOJO_K21_性交系コマンド.ERB    ; can be all LOCAL=0 stubs
├── M_KOJO_K21_愛撫系コマンド.ERB    ; stubs ok
├── M_KOJO_K21_加虐系コマンド.ERB    ; stubs ok
├── M_KOJO_K21_道具系コマンド.ERB    ; stubs ok
├── M_KOJO_K21_派生コマンド.ERB      ; stubs ok
├── M_KOJO_K21_カウンター.ERB        ; ~5-10 counters
├── M_KOJO_K21_弾幕勝負.ERB          ; one DANMAKU label
├── M_KOJO_K21_刻印取得.ERB          ; one MARKCNG label
├── readme.txt                         ; persona / version / license
└── ライセンステンプレ.txt              ; license template
```

**Step 2 — 写出 existence + FLAGSETTING + COLOR + UPDATE + ENCOUNTER 标签骨架.**

```erb
;### 口上存在判定 ###################################
@M_KOJO_K21(ARG)
RETURN 1

;### 口上基本フラグ設定 #############################
@M_KOJO_FLAGSETTING_K21
;optional flips:
;CFLAG:21:時間停止口上有 = 0
;CFLAG:21:眠姦口上有 = 0
;CFLAG:21:扮演口上有 = 0
;CFLAG:21:推倒禁止 = 1                ; default deny

;### 口上色判定 ###################################
@M_KOJO_COLOR_K21
SETCOLOR 0xC8E6F0                       ; pale-blue, fits Merlin's spectral wing color

;※※※※※※※※※※※※※※※※※※※※※※※※※※
;"UPDATE判定"
;※※※※※※※※※※※※※※※※※※※※※※※※※※
@M_KOJO_UPDATE_K21
;optional: ask permission to change talents on first load

;※※※※※※※※※※※※※※※※※※※※※※※※※※
;"ENCOUNTER"系イベント
;※※※※※※※※※※※※※※※※※※※※※※※※※※
@M_KOJO_ENCOUNTER_K21
PRINTFORML 「啊啦、是新面孔呢」
PRINTFORML （描述：梅露兰一边轻摆着喇叭、一边好奇地打量着 %CALLNAME:MASTER%。）
PRINTFORMW 「我是梅露兰·普利兹姆利巴。喜欢音乐吗？」
RETURN 1
```

**Step 3 — 日常系指令 (300–4xx 范围).**

为每个用得上的命令 N (300=会話, 301=泡茶, 302=身体接觸, …) 生成 body。按关系层级(§8)分支。用人设(「大方爽朗 + 音乐 + 姐姐式关怀」)给台词上色:

```erb
;==================================================
;300,会話
;TFLAG:193(1=大成功 0=成功 -1=失敗 -2=大失敗(TARGETがMASTERより教養が4以上高い))
;TCVAR:302(0=会話可能 1>=非恋慕時会話不能)
;==================================================
@M_KOJO_SUCCESS_COM_K21_300
TFLAG:192 = 0

@M_KOJO_MESSAGE_COM_K21_300
CALL TRAIN_MESSAGE
CALL M_KOJO_MESSAGE_COM_K21_300_1
RETURN RESULT

@M_KOJO_MESSAGE_COM_K21_300_1
LOCAL = 1
IF LOCAL
    IF FLAG:時間停止
    ELSEIF TALENT:恋慕
        SELECTCASE RAND:3
            CASE 1
                PRINTFORML 「呐%CALLNAME:MASTER%、上次教你的那段旋律、记得吗？」
                PRINTFORMW 梅露兰一边把玩着喇叭、一边眯起眼睛笑着
            CASE 0
                PRINTFORML 「呵呵、和%CALLNAME:MASTER%在一起的时候、不知不觉就想哼歌呢」
                PRINTFORMW 梅露兰用喇叭轻轻顶了顶%CALLNAME:MASTER%的肩膀
            CASEELSE
                PRINTFORML 「今天也、来听听姐姐我演奏吧？」
                PRINTFORMW 梅露兰得意地举起喇叭
        ENDSELECT
    ELSEIF TALENT:思慕
        SELECTCASE RAND:3
            CASE 1
                PRINTFORML 「%CALLNAME:MASTER%好像挺喜欢和我们玩呢」
                PRINTFORMW 梅露兰随手吹出了一段简单的旋律
            CASE 0
                PRINTFORML 「妹妹（露娜）有没有给你添麻烦？她有时候有点笨呢」
                PRINTFORMW 梅露兰一脸宠溺地说着
            CASEELSE
                PRINTFORML 「无聊的时候、来找姐姐聊聊吧」
                PRINTFORMW 
        ENDSELECT
    ELSE
        SELECTCASE RAND:3
            CASE 1
                PRINTFORML 「呵、人类小孩很有趣呢」
                PRINTFORMW 梅露兰用喇叭挠了挠脸颊
            CASE 0
                PRINTFORML 「想知道什么、就问吧。我心情好的时候会回答的」
                PRINTFORMW 梅露兰戏谑地笑着
            CASEELSE
                PRINTFORML 「不过别想着捉弄我哟、捉弄人是我们的工作」
                PRINTFORMW 
        ENDSELECT
    ENDIF
ENDIF
RETURN 1

;==================================================
;301,泡茶
;...其余命令同样的 IF FLAG:時間停止 / ELSEIF TALENT:恋慕 / ... cascade
```

**Step 4 — 其余命令.**

人设不合的命令直接留 `LOCAL = 0` —— 引擎会回退到默认旁白。

例如「捉弄人」是梅露兰本职, 所以 309 摸頭 不应该让她讨厌, 而是顺手回敬恶作剧:

```erb
@M_KOJO_MESSAGE_COM_K21_309_1
LOCAL = 1
IF LOCAL
    IF FLAG:時間停止
    ELSEIF TALENT:恋人
        PRINTFORML 「呵、原来%CALLNAME:MASTER%还是个爱撒娇的孩子呢」
        PRINTFORMW 梅露兰反过来揉乱了%CALLNAME:MASTER%的头发
    ELSE
        PRINTFORML 「啊啦啊啦、想被姐姐摸头呢？」
        PRINTFORMW 梅露兰一脸促狭地伸手过来反摸了%CALLNAME:MASTER%
    ENDIF
ENDIF
RETURN 1
```

提示用户: 等他们对照试玩感觉 OK 后, 再让你扩充其余命令的 body。一次性生成所有 ~50 条命令的 body 是不必要的, 也容易让用户疲劳审稿。

### 11.2 Adding a one-shot scripted event

用户请求示例:「请在博丽神社新年那天 (1 月 1 日)、当 %CALLNAME:MASTER% 来到神社、亲密度 ≥ 6 时, 触发一段灵梦给 %CALLNAME:MASTER% 准备甘酒迎新的限定剧情。整个事件只发生一次。」

(Compare with §11.3 below: this is a *new feature* (multi-line cinematic with its own progress flag), not a small line tweak. We're adding a brand-new label `@K1_NEW_YEAR_AMAZAKE`, a new CFLAG slot for "已经体验过", and a hook in `@SPECIALDAY_EVENT_K1`. The existing kojo is otherwise unchanged.)

**Step 1 — 决定触发位置.**

此事件适合 `@SPECIALDAY_EVENT_K1` (节日/纪念日 hook), 因为它有明确的日期条件。如果灵梦的现有口上已经定义了这个 label, 就在末尾追加; 没有就新建。Trigger condition: `DAY:2 == 1 && DAY:3 == 1 && CFLAG:MASTER:現在位置 == <博丽神社地点 ID> && ABL:1:親密 >= 6 && CFLAG:1:1101 == 0`.

**Step 2 — 预留 state-progress flag.**

在 `フラグ管理メモ.txt` 自己的备忘里加一行:
```
;CFLAG:1:1101 - 灵梦给MASTER准备过甘酒(0=未发生 1=已发生)
```
作者私有 CFLAG 范围是 1000-1999, 选 1101 (1100+ 留给作者扩展)。

**Step 3 — 写事件 body.** 通常放在 `M_KOJO_K1_イベント.ERB` 末尾, 或者拆出独立的 `M_KOJO_K1_霊夢特殊イベント.ERB`:

```erb
;CALL K1_NEW_YEAR_AMAZAKE
;==========================================================================================
;新年甘酒
;==========================================================================================
@K1_NEW_YEAR_AMAZAKE
;一次性事件, 体验过就跳过
SIF CFLAG:1:1101 != 0
    RETURN 0

PRINTFORML 来到博丽神社的%CALLNAME:MASTER%、看到了正在炉边忙活的灵梦
PRINTFORMW 神乐铃挂在屋檐下、风一吹就发出清脆的响声
PRINTFORML 「啊、%CALLNAME:MASTER%。新年快乐」
PRINTFORML 灵梦端着两个木杯朝这边走过来
PRINTFORMW 「难得碰到、来一杯吗？姐姐酿的甘酒哦」

CALL ASK_YN("接受这份心意", "礼貌地推辞")
IF !RESULT
    ;accepted
    PRINTFORML 「来、小心烫」
    PRINTFORML 灵梦把温热的木杯递了过来
    PRINTFORMW 略带米香的甘酒、暖意从喉咙一直传到肚子里…
    PRINTFORML 「呵、表情那么满足、是有那么好喝吗？」
    PRINTFORML 灵梦带着难得的柔和神情看着%CALLNAME:MASTER%
    PRINTFORML 「…新年的话、我也想稍微温柔一点呢」
    PRINTFORMW 「这一年也、请多关照啊、%CALLNAME:MASTER%」
    CFLAG:1:1101 = 1
    ;affection ledger
    SOURCE:1:愛情経験 += 800
    SOURCE:1:情愛 += 500
ELSE
    PRINTFORML 「啊啦、很可惜呢」
    PRINTFORMW 灵梦稍显遗憾地笑了笑、把木杯放回了桌上
    CFLAG:1:1101 = 1                  ; 同样标记为已发生, 不让用户反复看到这个分支
ENDIF
RETURN 1
```

**Step 4 — 挂钩.** 在 `M_KOJO_K1_イベント.ERB` 的 `@SPECIALDAY_EVENT_K1` 中追加触发条件。如果这个 label 之前没定义, 现在新建; 否则在现有内容末尾加分支:

```erb
@SPECIALDAY_EVENT_K1
;-- 既有 SPECIALDAY 分支 (如有) --
;...

;-- 新增: 新年甘酒事件 --
SIF DAY:2 == 1 && DAY:3 == 1 && CFLAG:MASTER:現在位置 == 51 && ABL:1:親密 >= 6 && CFLAG:1:1101 == 0
    CALL K1_NEW_YEAR_AMAZAKE
```

(地点 ID 51 = 博麗神社 — 来自 `CSV/` 的位置 ID。如果用户用的版本编号不同, 让他们查一下 `CSV/Chara/Chara1 霊夢.csv` 或者 `CSV/Base.csv`。)

向用户说明:
- 修改了/新增了 1 个文件 (`M_KOJO_K1_イベント.ERB` 末尾的 `@K1_NEW_YEAR_AMAZAKE` 和 `@SPECIALDAY_EVENT_K1` 分支)。
- 占用了 1 个作者私有 CFLAG (`CFLAG:1:1101`)。
- 事件触发后会写入 `SOURCE:1:愛情経験 += 800`, 让灵梦对玩家的好感度永久 +800。
- 这次只生成结构和占位台词, 用户可以再调整对白细节、增加随机分支等。

### 11.3 Modifying an existing kojo

用户请求示例:「灵梦的会話命令 (300) 在下雨天的台词太普通, 我想让她下雨天讲点更有特色的话。」

(Compare with §11.2: this is just adding *one extra branch* to one existing body. No new labels, no new flags, no progress state. The patch is small enough that you can show it as a diff.)

**Step 1 — 找到目标文件.** 灵梦 (id=1) 的会話命令在 `001 Reimu [霊夢]/<active variant>/M_KOJO_K1_日常系コマンド.ERB`。会話 = 命令 300。

**Step 2 — 找到 body**: 用 grep 搜索 `@M_KOJO_MESSAGE_COM_K1_300_1` (如果该 variant 用了 selector, 是 `@M_KOJO_<selector>_MESSAGE_COM_K1_300_1`)。

**Step 3 — 在现有分支*之前*加雨天分支** (这样雨天会优先于关系层级触发):

```erb
@M_KOJO_MESSAGE_COM_K1_300_1
LOCAL = 1
IF LOCAL
    IF FLAG:時間停止
    ;-- NEW BRANCH: rainy day, 优先级高于 TALENT 分支 --
    ELSEIF GROUPMATCH(TIME:5, 4, 5, 6, 7) && OUTROOF(CFLAG:1:現在位置)
        SELECTCASE RAND:3
            CASE 0
                PRINTFORML 「真讨厌啊、又下雨了…香油钱箱都要进水了」
                PRINTFORMW 灵梦看着屋檐下的雨帘叹了口气
            CASE 1
                PRINTFORML 「神社的屋顶又要漏水了…谁来修一下啊」
                PRINTFORMW 灵梦白了%CALLNAME:MASTER%一眼
            CASEELSE
                PRINTFORML 「下雨天的话、连参拜的人都没有呢」
                PRINTFORMW 灵梦给%CALLNAME:MASTER%递上一杯温热的茶
        ENDSELECT
    ELSEIF TALENT:恋人
        ; existing branches unchanged below
        ...
    ELSE
        ...
    ENDIF
ENDIF
RETURN 1
```

`TIME:5` ∈ {4..7} = 雨天的几个 weather phase; `OUTROOF(loc)` = 在屋外/无屋顶。如果用户想让她在屋内也能听见雨声, 把 `&& OUTROOF(...)` 去掉。

向用户说明:
- 只动了 1 个文件的 1 个 body, 只新增了 1 个 `ELSEIF` 分支。
- 没有引入新的 label / CFLAG / SOURCE。
- 因为新分支放在所有 `TALENT` 分支之前, 所以雨天会无视关系层级直接触发; 如果用户想让雨天分支只在「非恋人」时触发, 把 `ELSEIF GROUPMATCH(...)` 移到 `ELSEIF TALENT:恋人` 之后即可。

### 11.4 Diagnosing "my kojo isn't firing"

| Symptom | Likely cause | Check |
|---|---|---|
| Engine prints default narration only | Existence check returning 0 or missing | `@M_KOJO_K{id}(ARG)` exists & `RETURN 1`? |
| Wrong character voice | RESULTS selector mismatch | Does the body's label prefix match the existence check's `RESULTS`? |
| Specific command silent | Body has `LOCAL = 0` | Set `LOCAL = 1` if you want output. |
| Time-stop scene silent | `CFLAG:N:時間停止口上有` not set | Set `CFLAG:N:時間停止口上有 = 1` in FLAGSETTING. |
| Sleep scene silent | `CFLAG:N:眠姦口上有` not set | Set `CFLAG:N:眠姦口上有 = 1`. |
| Push-down rejected even on consent | `CFLAG:N:推倒禁止 = 1` | Set to 0 in FLAGSETTING (gate by relationship if desired). |
| Two-version conflict | Two variant directories both active | Delete or `[SKIPSTART]/[SKIPEND]` the unwanted variant's existence check. |
| Custom command not appearing | `@KOJO_COM_ABLE_K{id}_{Y}` returning 0 | Trace the predicate. |
| Diary not readable | DIARY:N:M not transitioning to 1/2/3 | Check `@DIARY_BEFORE_CHECK_K{id}`. |

---

