# Lyrica K20 kōjō — Post-Test Bug Fixes & Guide-Improvement Notes

This document logs every fix made to the Lyrica (K20) kōjō after the first-pass
file generation was tested in the Emuera engine. It is intended as feedback
for improving `eraTW_kojo_writing_guide.md` so that future first-pass
generations are correct on first run.

For each fix:
- **Symptom** — what the user / engine reported
- **Root cause** — what was actually wrong
- **Diff** — the code change
- **Guide gap** — what the original guide should have said but didn't (or said
  ambiguously)

---

## Top-level guide gaps (summary, before the per-fix details)

These cross-cut multiple fixes:

1. **`@label(ARG, ...)` parameter naming is restricted.** Custom names like
   `TYPE = 0` or `相手残機` produce `Lv2` warnings:
   `参数错误:变量"X"未在此函数中定义`. The guide §3.1 shows
   `@MY_HELPER(ARG, TYPE = 0)` as a valid example — but in this engine build,
   parameter slots **must be named `ARG` / `ARG:N` / `ARGS` / `ARGS:N`**
   (positional). Defaults work (`ARG:1 = 0`), but custom identifiers don't.
   The guide should rewrite the §3.1 default-args example to use `ARG:1 = 0`,
   and add a note: "do not name parameters with arbitrary identifiers; use
   the positional slots."

2. **`[[<name>]]` only resolves names that appear in `CSV/STR.csv`.** Many
   character names (アリス, ルナサ, メルラン, 幽々子, ライコ, …) are NOT in
   `STR.csv` even though they exist as `CSV/Chara/Chara<N> <name>.csv`. The
   guide §3.7 says "parse-time char-id lookup (e.g. `[[極]]` → 42). Requires
   the name to exist in `STR.csv`." — but doesn't tell the LLM how to
   *verify* a name is there, and the guide's recommendation in §16-pt-8 says
   "char ID = the directory's leading number" — which means the LLM should
   prefer **numeric IDs with comments** over `[[]]` syntax for inter-character
   references.

3. **`MASTER` is a built-in numeric pseudo-constant, NOT a name.** Writing
   `[[MASTER]]` produces a warning. The guide should explicitly list
   `MASTER`, `TARGET`, `ASSI`, `PLAYER` as built-in identifiers that should
   be referenced bare (no `[[]]`).

4. **`@M_KOJO_EVENT_K{id}_1(ARG, ARG:1)` is dispatched many times per
   in-room visit, with `ARG` selecting the sub-phase.** The guide §2.2 says
   "1 = room encounter" but does not enumerate the standard ARG values for
   slot 1. Without ARG branching, the body fires for every sub-phase causing
   the line to be repeated 3-5 times per visit. From Reimu's reference kōjō
   (which the guide should cite), the canonical ARG values for EVENT_K_1 are:

   | ARG | Sub-phase                                            |
   |-----|------------------------------------------------------|
   | 1   | MASTER walks in, char already in room                |
   | 2   | char walks in, MASTER already in room                |
   | 3   | char enters bathroom while MASTER is bathing — joins |
   | 4   | char enters bathroom, exits politely                 |
   | 5   | char enters bathroom, MASTER kicks them out          |

   And the body should `RETURN 0` per branch (not `RETURN 1`), with `ELSE`
   fall-through also returning 0.

5. **EVENT_K_1, EVENT_K_2, EVENT_K_3 ALL fire whenever the char is on
   the same world map as MASTER, not just the same room/cell.** Worse:
   `EVENT_K_1` also fires once **per cell transition** as the char's NPC
   AI walks around — so a char moving bedroom→corridor→dining→kitchen
   prints 3 dialogue lines while MASTER is still asleep elsewhere. The
   guide MUST instruct: gate every EVENT_K_X body's first line with
   `SIF CFLAG:{id}:現在位置 != CFLAG:MASTER:現在位置 / RETURN 0`,
   no exceptions.

5b. **`EVENT_K_GRAVITY` is a silent NPC-AI movement attractor, NOT a
    message label.** It fires per movement tick (many times per turn).
    Its body MUST set `TCVAR:N:引力点 = <location-code>` and MUST NOT
    print anything. The guide §2.2 calls it "gravity event" which is
    catastrophically misleading. See Fix 11. The guide must split events
    into "prints text" vs "silent control-flow" columns; otherwise every
    first-pass author will treat GRAVITY as a flavor event.

6. **`@M_KOJO_MESSAGE_COM_K{id}_00` is a CATCH-ALL that fires on every
   undefined command, not "rare fallback".** If you write rich body text in
   `_00`, the player sees that line on every R18 cmd they tried with no
   defined kōjō. The guide §2.2 calls it "Catch-all fallback for any cmd
   this char handles" — should clarify that it should mostly be a `LOCAL = 0`
   silent stub (or very short flavor) UNLESS the kōjō author wants every
   undefined cmd to print one identical body.

7. **`@M_KOJO_MESSAGE_MARKCNG_K{id}` fires every time SOURCE adjusts marks,
   even when no actual mark transition occurred.** Body must guard with
   `IF TFLAG:21 || TFLAG:22 || TFLAG:23 || TFLAG:24 || TFLAG:時姦刻印取得`
   and `RETURN 0` silently for the no-mark case. The guide §2.2 only
   mentions the label, not this guard.

8. **Symbol names are simplified-Chinese in this fork's CSVs.** Reimu's
   kōjō uses `CFLAG:TARGET:约会中` (simplified). My initial pass wrote
   `約会中` (Japanese-form 約) which fails to resolve. The guide should
   instruct: when writing flag names, **read the actual CSV file**
   (`CFLAG.csv`, etc.) for canonical spelling — don't transliterate.

9. **`[[X]]` syntax silently compiles to `0` when X is unresolved.**
   This is dangerous — `CASE [[X]]` becomes `CASE 0` and matches ARG=0.
   The guide should warn: always verify [[]] resolution by checking
   `CSV/STR.csv` first, and prefer numeric IDs for reliability.

10. **Display name vs. file/dir name vs. CSV name can disagree.** The
    Chara20 CSV had `名前,莉莉喀` (with `喀`) while the directory was
    "020 Lyrica [リリカ]" and we used "莉莉卡" (with `卡`) throughout the
    kōjō. The engine prints `%CALLNAME:20%` from the CSV, producing
    "莉莉喀" in default narration sandwiched between our "莉莉卡" lines.
    The guide should add: **before writing kōjō text, read
    `CSV/Chara/Chara<N> <name>.csv` and confirm the canonical display
    name** (`名前` and `呼び名` rows). If the user wants a different
    display name, edit the CSV to match.

11. **TFLAG slot name `逢瀬時間` does not exist in this fork's
    `CSV/TFLAG.csv`.** The guide §5.6 lists `TIME_PROGRESS(TFLAG:<key>)`
    as a helper but does not tell the LLM that the `<key>` must be a
    real row in `TFLAG.csv`. The LLM should grep `TFLAG.csv` first.

12. **File encoding: UTF-8 *with BOM* is REQUIRED; CRLF is preferred but
    LF appears tolerated.** Empirically:
    - Without BOM, the engine fails to parse Chinese characters in some
      string contexts (silent breakage).
    - LF-only files were accepted by the engine in our testing — engine
      did not warn about line endings.
    - The reference Reimu kōjō uses BOM+CRLF as the project convention.
    - Claude's `Write` and `Edit` tools default to LF (no BOM). After
      writing/editing, prepend BOM:
      `printf '\xef\xbb\xbf' > tmp && cat file >> tmp && mv tmp file`
      and optionally `unix2dos file`. The Edit tool on subsequent edits
      preserves BOM but reverts CRLF → LF.

13. **The standard branching cascade as written in §8 omits `ELSEIF
    CFLAG:睡眠`, `ELSEIF FLAG:扮演` from the day-1 examples in §11.** All
    real kōjō should keep these guards even when their respective口上有
    flags are 1 — for many sub-phases, the engine still expects the body
    to suppress on these states. Worth re-emphasizing.

---

## Per-fix details

### Fix 1 — `M_KOJO_K20_関数ライブラリ.ERB` : `@K20_C_NAME` parameter & `[[]]` fixes

**Symptom (engine warnings):**
```
警告Lv2: M_KOJO_K20_関数ライブラリ.ERB:第20行:函数"@K20_C_NAME"的参数错误:变量"TYPE"未在此函数中定义
警告Lv2: 第23行:发现词法解析中无法被替换(rename)的符号[[MASTER]]
警告Lv2: 第32行:发现词法解析中无法被替换(rename)的符号[[ルナサ]]
警告Lv2: 第34行:发现词法解析中无法被替换(rename)的符号[[メルラン]]
警告Lv2: 第36行:发现词法解析中无法被替换(rename)的符号[[幽々子]]
警告Lv2: 第47行:发现词法解析中无法被替换(rename)的符号[[アリス]]
警告Lv2: 第49行:发现词法解析中无法被替换(rename)的符号[[ライコ]]
```

**Root cause:**
- `TYPE` is not a valid parameter slot. Emuera in this build requires the
  positional slots `ARG`, `ARG:N`, `ARGS`, `ARGS:N`.
- `[[MASTER]]` is wrong because MASTER is a built-in numeric pseudo-constant.
- `[[ルナサ]]`, `[[メルラン]]`, `[[幽々子]]`, `[[アリス]]`, `[[ライコ]]` are
  not in `CSV/STR.csv` so they don't resolve. (`[[霊夢]]`, `[[魔理沙]]`,
  `[[紫]]` also failed silently — they happen to be in STR.csv but as room
  IDs, not character IDs, so they'd resolve to wrong values.)

**Diff:**
```diff
-@K20_C_NAME(ARG, TYPE = 0)
+@K20_C_NAME(ARG, ARG:1 = 0)
 #FUNCTIONS
 SELECTCASE ARG
-    CASE [[MASTER]]
+    CASE MASTER
         ;莉莉卡对MASTER的称呼随关系深化
         ...
-    CASE [[ルナサ]]
+    CASE 22                              ;露娜萨 Lunasa
         RETURNF "露娜萨姐姐"
-    CASE [[メルラン]]
+    CASE 21                              ;梅露兰 Merlin
         RETURNF "梅露兰姐姐"
-    CASE [[幽々子]]
+    CASE 66                              ;幽々子 Yuyuko
         RETURNF "幽幽子大人"
-    CASE [[妖夢]]
+    CASE 23                              ;妖夢 Youmu
         RETURNF "白玉楼的小妖梦"
-    CASE [[魔理沙]]
+    CASE 11                              ;魔理沙 Marisa
         RETURNF "那个魔法使"
-    CASE [[霊夢]]
+    CASE 1                               ;霊夢 Reimu
         RETURNF "巫女小姐"
-    CASE [[紫]]
+    CASE 26                              ;紫 Yukari
         RETURNF "那位八云大人"
-    CASE [[アリス]]
+    CASE 17                              ;アリス Alice
         RETURNF "做人偶的那位"
-    CASE [[ライコ]]
+    CASE 96                              ;ライコ 雷鼓
         RETURNF "雷鼓队长"
```

**Guide gap:** see top-level points 1, 2, 3, 9.

---

### Fix 2 — `M_KOJO_K20_関数ライブラリ.ERB` : `@K20_AENAI` removed `逢瀬時間`

**Symptom:** `第169行:无法解析的标识符"逢瀬時間"`

**Root cause:** `TFLAG:逢瀬時間` is not a slot in this fork's `CSV/TFLAG.csv`.
The reference TFLAG slot most kōjō use is `TFLAG:膝枕した` etc — the LLM
hallucinated `逢瀬時間` from the guide's example without verifying.

**Diff:** rewrite the function to track "days since last met" via a private
CFLAG slot that we control, instead of an unknown TFLAG slot.

```diff
 @K20_AENAI
-;不返回值，直接打印一段台词
-SELECTCASE TIME_PROGRESS(TFLAG:逢瀬時間)
+;按"上次遇见的天数差"决定问候语。
+;由于本fork的TFLAG.csv不含"逢瀬時間"通用slot，
+;我们自己用 CFLAG:20:1080 = 上次相遇的DAY 来记账。
+LOCAL = DAY - CFLAG:20:1080
+SIF CFLAG:20:1080 == 0
+    LOCAL = 0
+CFLAG:20:1080 = DAY
+SELECTCASE LOCAL
     CASE 0 TO 2
         ;两天内
```

**Guide gap:** see top-level point 11. Add to §5.6 helper section: "every
TFLAG/CFLAG slot name you write must exist in the corresponding CSV — grep
first."

---

### Fix 3 — `M_KOJO_K20_弾幕勝負.ERB` : DANMAKU parameter renaming

**Symptom:**
```
警告Lv2: M_KOJO_K20_弾幕勝負.ERB:第12行:函数"@M_KOJO_MESSAGE_COM_K20_DANMAKU"的参数错误:变量"相手残機"未在此函数中定义
警告Lv2: 第44行:变量"相手残機"未在此函数中定义
```

**Root cause:** Same as Fix 1 — Emuera requires `ARG` / `ARG:N` parameter
naming, custom identifiers like `相手残機` aren't allowed.

**Note:** Some other kōjō (K5, K6, K7) declare `(ARGS, 相手残機)` AND add
`#DIM 相手残機` immediately after as a workaround. We could match that style
for readability. For Lyrica I chose the simpler form: rename to `ARG` and
add a comment.

**Diff:**
```diff
-@M_KOJO_MESSAGE_COM_K20_DANMAKU(ARGS, 相手残機)
+@M_KOJO_MESSAGE_COM_K20_DANMAKU(ARGS, ARG)
+;ARG = 相手残機（对方剩余命数）
 SELECTCASE ARGS
 ...
     CASE "戦闘後"
-        IF 相手残機 > 0
+        IF ARG > 0
             ;莉莉卡输了
```

**Guide gap:** point 1 above. Also, the guide §2.2 documents the DANMAKU
label as `(ARGS, 相手残機)` — that signature is misleading; rewrite it as
`(ARGS, ARG)  ; ARG = 相手残機` so first-pass generation matches engine
expectations.

---

### Fix 4 — `M_KOJO_K20_日常系コマンド.ERB` : `約会中` → `约会中`

**Symptom:** `第34/82/120/166行: 无法解析的标识符"約会中"`

**Root cause:** This fork's `CSV/CFLAG.csv` row is
`12,约会中` (simplified Chinese 约). I wrote `約会中` (Japanese form 約).

**Diff (replace_all in the file):**
```diff
-CFLAG:TARGET:約会中
+CFLAG:TARGET:约会中
```

**Guide gap:** point 8.

---

### Fix 5 — `M_KOJO_K20_イベント.ERB` : `EVENT_K20_1` should branch by ARG

**Symptom:** Every time MASTER enters a room with Lyrica, the same body
prints 3-5 times.

**Root cause:** The engine fires `EVENT_K_1(ARG, ARG:1)` once per sub-phase
of the encounter, with ARG distinguishing them. Without an `IF ARG == N`
guard, the body fires for every phase.

**Diff (paraphrased, full body re-templated):**
```diff
 @M_KOJO_EVENT_K20_1(ARG, ARG:1)
 LOCAL = 1
 IF LOCAL && !FLAG:時間停止
-    IF TALENT:恋人
-        ; ... lines ...
-    ELSEIF TALENT:愛欲 || TALENT:炮友
-        ...
-    ELSE
-        ; "莉莉卡飘在房间正中..."
-    ENDIF
+    ;-------------------------------------------------
+    ;ARG == 1 : MASTER 走进房间，莉莉卡在场
+    ;-------------------------------------------------
+    IF ARG == 1
+        IF TALENT:恋人 ...
+        ...
+        RETURN 0
+    ENDIF
+    ;-------------------------------------------------
+    ;ARG == 2 : 莉莉卡走进 MASTER 的房间
+    ;-------------------------------------------------
+    IF ARG == 2
+        ...
+        RETURN 0
+    ENDIF
+    ;-------------------------------------------------
+    ;ARG == 3..5 : 浴室相关
+    ;-------------------------------------------------
+    IF ARG == 3 ... RETURN 0 ... ENDIF
 ENDIF
-RETURN 1
+RETURN 0
```

**Guide gap:** point 4. The guide should include a sub-table enumerating
the standard `ARG` values for each EVENT_K_X slot, derived from the Reimu
reference kōjō.

---

### Fix 6 — `M_KOJO_K20_イベント.ERB` : `EVENT_K20_2` / `EVENT_K20_3` should require same room

**Symptom:** Even when Lyrica isn't in MASTER's room (only same world map),
her `EVENT_K20_2` (morning) body fires.

**Root cause:** Engine calls EVENT_K20_2 for any character in same map.
Body should additionally check
`CFLAG:20:現在位置 == CFLAG:MASTER:現在位置`.

**Diff:**
```diff
 @M_KOJO_EVENT_K20_2(ARG, ARG:1)
 LOCAL = 1
-IF LOCAL && !FLAG:時間停止
+IF LOCAL && !FLAG:時間停止 && CFLAG:20:現在位置 == CFLAG:MASTER:現在位置
     IF TALENT:恋人
         ...
```

(Same for EVENT_K20_3.)

**Guide gap:** point 5.

---

### Fix 7 — `M_KOJO_K20_刻印取得.ERB` : silent return when no mark fired

**Symptom:** "莉莉卡看了一眼自己身上多出的那个小标记..." prints after
泡茶, after R18 commands, basically after most actions.

**Root cause:** Engine calls `MARKCNG_K20` after **every** action that
*could* affect marks, regardless of whether a mark transition actually
happened. The body's ELSE branch was printing a generic line for the
"no specific mark" case — which fired constantly.

**Diff:**
```diff
 @M_KOJO_MESSAGE_MARKCNG_K20_1
 LOCAL = 1
 IF LOCAL
+    ;If no mark actually transitioned this turn, print nothing.
+    SIF !TFLAG:21 && !TFLAG:22 && !TFLAG:23 && !TFLAG:24 && !TFLAG:時姦刻印取得
+        RETURN 0
     IF TFLAG:時姦刻印取得
         ...
     ELSEIF TFLAG:21
         ...
-    ELSE
-        PRINTFORML 莉莉卡看了一眼自己身上多出的那个小标记。
-        PRINTFORMW 「哦——挺特别的纪念品啦。」
     ENDIF
 ENDIF
 RETURN 1
```

**Guide gap:** point 7.

---

### Fix 8 — `M_KOJO_K20_日常系コマンド.ERB` : `_00` fallback should be silent

**Symptom:** "莉莉卡耸耸肩。「——啊，可以可以。我先看看再说。」" appears
on virtually every undefined cmd, including 吃便当 during a date, and
the moment of confession, etc.

**Root cause:** `MESSAGE_COM_K20_00` is the catch-all fallback for **every
command** that has no defined `MESSAGE_COM_K20_<cmd>` handler. Writing
flavor text there makes that flavor appear everywhere. It should be silent
unless the author specifically wants every-cmd fallback flavor.

**Diff:**
```diff
 @M_KOJO_MESSAGE_COM_K20_00
-LOCAL = 1
-IF LOCAL && !FLAG:時間停止
-    IF K20_MOOD() >= 3
-        PRINTFORMW 莉莉卡偏过头，眯着眼笑。「——哦？这种事情？……算了，反正陪%CALLNAME:MASTER%玩玩也无所谓。」
-    ELSE
-        PRINTFORMW 莉莉卡耸耸肩。「——啊，可以可以。我先看看再说。」
-    ENDIF
-ENDIF
+;Catch-all fallback. Silent by design — letting engine default narration
+;handle commands not specifically authored.
+LOCAL = 0
 RETURN 0
```

**Guide gap:** point 6.

---

### Fix 10 — `M_KOJO_K20_イベント.ERB` : `EVENT_K20_1` must guard with `現在位置 ==`

**Symptom (user-observed):** When MASTER is asleep / in a different cell on
the same map, Lyrica's NPC-AI movement (her bedroom → corridor → dining
room → kitchen) prints her room-encounter dialogue **once per cell
transition** (3 messages). MASTER is never actually in those cells.

**Root cause (deeper than Fix 5):** `EVENT_K_1` fires not just on
"player walks in / char walks in" — it ALSO fires every time the char
**transitions cells anywhere on the same map**, with `ARG == 2` ("char
walked in"). The engine apparently does not check whether MASTER is
actually in the destination cell before firing the event.

Fix 5 only handled "ARG sub-phase" duplication within a single visit.
Fix 6 only handled EVENT_K_2/K_3 (morning/sleep). EVENT_K_1 still needed
the same `現在位置 ==` guard.

**Diff:**
```diff
 @M_KOJO_EVENT_K20_1(ARG, ARG:1)
 LOCAL = 1
 IF !LOCAL || FLAG:時間停止
     RETURN 0
 ENDIF
+
+;关键守卫：引擎在角色【每次走入新格子】时都调用 EVENT_K_1（哪怕 MASTER
+;不在那个格子）。不挡住会在 NPC AI 的每次移动后都印一段台词。
+SIF CFLAG:20:現在位置 != CFLAG:MASTER:現在位置
+    RETURN 0
```

**Guide gap (extends point 5):** §2.2 says
"`EVENT_K{id}_{ev}(ARG, ARG:1)` ... `ev` = engine event slot 1..30+.
Common patterns: `1` = room encounter ..." — but this severely
understates the firing frequency. The actual semantics of EVENT_K_X
slots in this fork:

| Slot | Fires when                                              | Required guards     |
|------|---------------------------------------------------------|---------------------|
| 1    | char enters/exits any cell on same map; OR MASTER walks in | `現在位置 ==` MASTER's |
| 2    | morning, every char on same map as MASTER                  | `現在位置 ==` MASTER's |
| 3    | sleep, every char on same map as MASTER                    | `現在位置 ==` MASTER's |

The guide should add this column emphatically. **The default behavior is
"fires more often than you'd expect; always guard with same-cell check."**

---

### Fix 11 — `M_KOJO_K20_イベント.ERB` : `EVENT_K20_GRAVITY` is NPC AI movement hook, NOT "gravity event"

**Symptom (user-observed):** After MASTER wakes up, the dialogue
"莉莉卡飘在半空，手里的合成器突然往下一沉……" prints **5+ times in
sequence**, with the engine narration "（少女移動中…）" between each.
Same dialogue also appears after every conversation, between turn-end
and clock-tick.

**Root cause:** `EVENT_K_GRAVITY` is **not** a "rare gravity-anomaly event"
as the guide §2.2 describes ("`_GRAVITY` = gravity event"). Inspection of
the engine dispatcher in `KOJO_MESSAGE.ERB:1116-1124` and Eiki K30's
canonical implementation reveals it is the **per-NPC-movement-tick AI
location-attractor hook**:

```erb
;in KOJO_MESSAGE.ERB:
CASE "GRAVITY"
    LOCAL = TARGET
    TARGET = ARG:2
    RESULT = 0
    IF FLAG:口上文本設定 > 0
        CALL KOJO_ACTIVE_INFO(TARGET)
        TRYCALLFORM M_KOJO%RESULTS%_EVENT_K{NO:TARGET}_GRAVITY(ARG:1)
    ENDIF
```

The engine fires this **every time the NPC scheduler decides where a
character should walk to next** — multiple times per turn. The body's
job is to **set `TCVAR:N:引力点 = <location-code>`** to influence the
AI's next destination. The body must **never PRINT anything** — printing
would be visible per movement tick (which is what the user saw).

Eiki K30's canonical structure:
```erb
@M_KOJO_EVENT_K30_GRAVITY(ARG)
TCVAR:30:引力点 = 0                 ; default: don't pull
SIF !K30_CHECK_HEN_T()
    RETURN
SIF !GROUPMATCH(CFLAG:現在位置 / 100, CFLAG:MASTER:現在位置 / 100, MAIN_MAP)
    RETURN
;... conditional sets to TCVAR:30:引力点 = <location code> ...
RETURN
```

**Diff:**
```diff
-;EVENT_GRAVITY = 重力异变事件（骚灵对重力变化的反应）
+;EVENT_GRAVITY = 引力（NPC AI 移动决策 hook，不是"重力异变"！）
+;
+; 引擎在每一次 NPC 移动 tick 都会调用此 label，询问
+;   "这个角色现在应该被吸引到哪里去？"
+; 期望 body 设置 TCVAR:N:引力点 = <地点编码>，**绝对不能打印任何内容**！
+;
+; 地点编码格式：4位数，前2位 = MAIN_MAP，后2位 = 该地图的格子号
-@M_KOJO_EVENT_K20_GRAVITY(ARG, ARG:1)
-LOCAL = 1
-IF LOCAL
-    PRINTFORML 「——啊？」
-    PRINTFORML 莉莉卡飘在半空，手里的合成器突然往下一沉。
-    ...
-ENDIF
-RETURN 1
+@M_KOJO_EVENT_K20_GRAVITY(ARG)
+TCVAR:20:引力点 = 0                              ;默认：不主动移动
+SIF CFLAG:20:現在位置 / 100 != CFLAG:MASTER:現在位置 / 100
+    RETURN                                       ;不在同一大地图：不引导
+SIF TALENT:20:恋人 || TALENT:20:愛欲 || TALENT:20:炮友
+    TCVAR:20:引力点 = CFLAG:MASTER:現在位置      ;关系到位 → 跑去找 MASTER
+RETURN
```

**Guide gap (CRITICAL — this is the #1 most misleading single line in
the whole guide):**

§2.2 currently lists `_GRAVITY` = "gravity event" in a generic
"miscellaneous events" row. This is **catastrophically misleading**: it
makes any first-pass author think "oh, write some flavor text for when
the gravity-anomaly happens." In reality:

- `EVENT_K_GRAVITY` is a **silent control-flow callback**, not a
  message-output label.
- It fires **per movement tick** (many times per turn), not per
  in-world event.
- The label name is misleading; "引力" here means
  "AI movement attractor", not Newtonian gravity.
- The body must SET `TCVAR:N:引力点`, NOT print.

**Recommended guide rewrite (§2.2):**

> | Label | Notes |
> |---|---|
> | `@M_KOJO[%RESULTS%_]EVENT_K{id}_GRAVITY(ARG)` | **Silent NPC-AI
> movement attractor.** Fires every NPC movement decision tick (many
> per turn). Body MUST set `TCVAR:N:引力点 = <location code>` and
> MUST NOT print anything. Default: `TCVAR:N:引力点 = 0`. See K30
> Eiki's `EVENT_K30_GRAVITY` for canonical pattern. |
> | `@M_KOJO[%RESULTS%_]EVENT_K{id}_SUIKA(ARGS, ARG, ...)` | Watermelon-festival display event. Distinct from above — this DOES print. |

The same warning applies to other "control-flow" labels currently lumped
in the events table — the guide should split events into two columns:
**(a) labels that print message text** vs **(b) labels that perform
silent control-flow / state-machine work**. Mixing them in one table
caused this bug.

Suspected control-flow-only labels (verify per-fork):
- `EVENT_K_GRAVITY` — NPC movement attractor (CONFIRMED)
- `EVENT_K_LOST_VIRGIN_STOP` — sets `TFLAG:中止破瓜` (likely)
- `EVENT_K_PERMISSION` — sets push-down judgment (likely)
- `EVENT_K_BEFORETRAIN` — daily state-machine setup (likely)

---

### Fix 9 — `CSV/Chara/Chara20 リリカ.csv` : 莉莉喀 → 莉莉卡

**Symptom:** Engine narration prints "莉莉喀" while user-authored kōjō
text says "莉莉卡". Inconsistent name throughout play.

**Root cause:** CSV had `名前,莉莉喀 普利茲姆利巴,` and `呼び名,莉莉喀,`.
The character is `%CALLNAME:20%`-rendered from CSV, not from kōjō text.

**Diff:**
```diff
-名前,莉莉喀 普利茲姆利巴,
+名前,莉莉卡·普莉兹姆利巴,
-呼び名,莉莉喀,
+呼び名,莉莉卡,
```

**Guide gap:** point 10.

---

### Fix 5 details — actual ARG branching applied

Implemented branches based on the Reimu reference kōjō for EVENT_K_1:

| ARG | Sub-phase                                              | Body |
|-----|--------------------------------------------------------|------|
| 1   | MASTER walks in, char already in room                  | Full talent cascade, original body kept |
| 2   | char (Lyrica) walks in, MASTER already in room         | Short greeting per talent tier |
| 3   | char enters bathroom, joins MASTER bathing              | Talent-conditional |
| 4   | char enters bathroom, exits politely                    | One-line apology, no talent branch |
| 5   | char enters bathroom, MASTER kicks them out             | One-line reaction |

Each branch ends with `RETURN 0` so multiple branches don't fire in one
visit. Outer fall-through also `RETURN 0`. Removed the original
`RETURN 1` which was wrong — that value never short-circuits engine and
just signals "handled".

---

## Tester checklist — to add to the guide

After scaffolding a new kōjō, before declaring done, run:

1. `grep -nE "\[\[[^]]+\]\]"` over your new files. For every match,
   verify the target name appears in `CSV/STR.csv`. If not, replace with
   numeric ID + comment.
2. `grep -nE "@.*\(ARG.*=\s*[0-9]+\)"` — verify all default-arg signatures
   use `ARG` / `ARG:N` slot names only.
3. `grep -nE "CFLAG:[A-Z]+:[^a-z0-9 \r\n_]+"` — list every CFLAG slot name
   you reference, verify it appears in `CSV/CFLAG.csv` byte-for-byte.
   Same for TFLAG, TCVAR, EXP, ABL, etc. (Beware traditional/simplified
   Chinese variants and Japanese kanji variants — `约/約`, `历/歴`, etc.)
4. Read `CSV/Chara/Chara<N> <name>.csv` rows `名前` and `呼び名` —
   ensure your kōjō's text matches the canonical display name, or update
   the CSV.
5. For every `EVENT_K_X` body, confirm it branches on `ARG` (not just
   on TALENT). Reference the Reimu kōjō for canonical ARG semantics
   per slot.
6. For `MESSAGE_MARKCNG_K_*`, gate the body so it returns silently
   when no mark actually transitioned.
7. For `MESSAGE_COM_K_00`, default to `LOCAL = 0` silent unless you
   intentionally want every-undefined-cmd flavor.
8. Save files as UTF-8 with BOM. CRLF is preferred but LF appears
   tolerated in practice. After `Write`/`Edit`, run a BOM-prepend pass
   (Claude tools default to LF, no BOM).

---

## Final implementation notes (state after all fixes)

- All 17 ERB files in `020 Lyrica [リリカ]/莉莉卡/` are UTF-8 with BOM.
  Line endings drift to LF after each `Edit` call; the engine tolerates
  this. If the user reports any further parser-quirks, run unix2dos to
  re-CRLF.
- `CSV/Chara/Chara20 リリカ.csv` was edited to set
  `名前 = 莉莉卡·普莉兹姆利巴`, `呼び名 = 莉莉卡`. The file remains
  UTF-8 BOM + CRLF.
- The kōjō still has many `;TODO` placeholders for R18 commands — those
  are intentional (per user's instruction to scaffold structure but not
  generate explicit prose). They are inert at runtime: each placeholder
  body is `LOCAL = 1 ... ENDIF / RETURN 1` with empty branches, which
  prints nothing and falls through to engine default narration.
- The `K20_AENAI` function now uses `CFLAG:20:1080` for the
  "days since last met" tracking (since `TFLAG:逢瀬時間` does not exist
  in this fork's CSV). This is a private CFLAG slot — not initialized by
  any existing flow, so it will be `0` on first call (treated as "today")
  and increments organically thereafter.

---

## "Easily testable conditions" — claim vs. reality

When asked to add 10 condition-based dialogue branches "easy to test
(not relationship-grinding)", I picked these conditions and claimed
all were single-action testable:

| Cond | Predicate | Actually how many steps? |
|---|---|---|
| #1 共寝中 | `CFLAG:TARGET:陪睡中` | 2 (sleep cmd) |
| #2 浴室 | `BATHROOM(...)` | 1 (walk to bath) |
| #3 约会中 | `CFLAG:TARGET:约会中` | 2 (date cmd) |
| #4 露娜萨同格 | `CFLAG:22:現在位置 == CFLAG:MASTER:現在位置` | **4-5 (locate via 811, walk, invite via 351, walk back)** |
| #5 梅露兰同格 | `CFLAG:21:...` | **4-5, same as #4** |
| #6 MASTER 醉 | `BASE:MASTER:酒気 * 2 > MAXBASE...` | 1-2 (drink) |
| #7 MASTER 累 | `BASE:MASTER:疲労 * 2 > MAXBASE...` | 2-3 (work) |
| #8 雨天 | `GROUPMATCH(TIME:5, 4..7)` | 1 (wait or debug) |
| #9 深夜 | `TIME:2 >= 23 \|\| <= 3` | 1 (wait) |
| #10 室外 | `OUTROOF(...)` | 1 (walk) |

**Claim violation:** #4/#5 are NOT 1-step testable. They require:
1. `COMF811 居場所察知` — locate the sister
2. `COMF400 移動` — walk to her
3. `COMF351 帯出去` — invite her to follow
4. `COMF400 移動` — walk back to Lyrica
5. `COMF300 会話`

**Root cause of the bad estimate:** I assumed "two characters in the
same cell" was a primitive/cheap predicate. It's actually a multi-cmd
sequence in this engine, because the only deterministic way to make
a non-target char arrive at MASTER's cell is `COMF351`. The guide
gives no indication of test-cost-per-predicate.

**Guide gap suggestion:** when the guide eventually lists CFLAG /
TFLAG slots, annotate each with **"how the player triggers/changes
this in normal play"**. E.g.:
- `CFLAG:N:陪睡中` — set by `COMF354 陪睡` cmd
- `CFLAG:N:約会中` — set by `COMF351/405` cmds
- `CFLAG:N:現在位置` — set by NPC AI (mostly autonomous);
  manually controllable via `COMF351 帯出去` (60-min follow)
- `BASE:酒気` — increased by `COMF332 勸酒`
- `TIME:5` — weather state, varies by day; no direct player control
  (might have debug toggle)

Without this annotation, an LLM (or human author) writing
"condition-based dialogue" will mis-estimate which conditions are
cheap to test.

---

## Fix 12 — `M_KOJO_K20_日常系コマンド.ERB` cmd 300 condition #3 : `CFLAG:N:约会中` is NOT a boolean

**Symptom (user-observed):** After the player goes on ONE date with
Lyrica and ends it (via `COMF351` or other means), the "约会中"
condition-branch in cmd 300 fires **every subsequent conversation,
forever** — overriding all other conditions including drunk/bath etc.

**Root cause:** `CFLAG:N:约会中` is **not a boolean flag**. It stores
**the MAIN_MAP code at which the date started**. After one date, the
slot holds (e.g.) `5` and is never reset to `0` even by ending the
date. So `IF CFLAG:TARGET:约会中` (which I wrote as a boolean check)
is `IF 5` = always true.

The engine's canonical "currently dating" predicate is the helper
`@CHK_DATENOW(ARG)` defined in `MOVEMENTS/物件関連/COMMON2.ERB:7`:

```erb
@CHK_DATENOW(ARG)
#FUNCTION
IF ARG == MAIN_MAP
    RETURNF 0       ; same map as date start = "back home, date over"
ELSE
    RETURNF 1       ; different map = "currently away on a date"
ENDIF
```

So the semantic is "**we are away from the date-start map**", not
"date in progress (boolean)". And it's still ambiguous whether it's
a date with the right partner — for that you also need
`FLAG:约会的对象 == TARGET`.

The full canonical "currently dating with this character" predicate
(used in `MOVEMENT_SUB.ERB:78` etc.):
```erb
CHK_DATENOW(CFLAG:MASTER:约会中) && FLAG:约会的对象 == TARGET
```

**Why Reimu's kōjō doesn't visibly suffer this bug:** Reimu uses
`CFLAG:TARGET:约会中` only inside `PRINTFORM-IF` suffix-narration
chains, where "always true after first date" just changes the wording.
She never uses it as an early-return predicate. My code's bug bit
because I used early-return.

**Diff:**
```diff
-IF CFLAG:TARGET:约会中
+IF CHK_DATENOW(CFLAG:MASTER:约会中) && FLAG:约会的对象 == TARGET
     ...
     RETURN 1
 ENDIF
```

Also added DEBUG insertion comment to demonstrate the pattern for
in-game state inspection:
```erb
;PRINTFORML [DBG] CFLAG:MASTER:约会中={CFLAG:MASTER:约会中} MAIN_MAP={MAIN_MAP} ...
```

**Guide gap (significant):**

§5.5 of the guide does mention `CHK_DATENOW(CFLAG:N:約会中)` —
"date currently underway" — but:
1. The slot name is given as `約会中` (traditional 約) which doesn't
   resolve in this fork; canonical is `约会中` (simplified).
2. **The guide does NOT explain that `CFLAG:N:约会中` itself is a
   map-ID storage, not a boolean.** A reader naturally treats
   `IF CFLAG:N:约会中` as "is dating?" and gets bitten.
3. The guide does not document the `CHK_DATENOW + FLAG:约会的对象`
   conjunction that's actually needed to test "dating with this
   specific character".

**Suggested guide rewrite:** for every CFLAG/TFLAG slot that has
non-boolean semantics (counter, map-id, item-id, time-stamp, etc.),
the guide MUST annotate:
- **Type** (boolean / counter / id / timestamp / ...)
- **Reset semantics** (auto-reset on X / never reset / manually reset
  by Y)
- **Canonical predicate** (which helper function should be used
  instead of `IF <slot>`)

Example annotation format:
```
CFLAG:N:约会中
    Type: integer (MAIN_MAP code at date start)
    Set by: COMF351, COMF405 (sets to MAIN_MAP)
    Reset by: NEVER auto-reset (sticky after first date)
    Canonical predicate: CHK_DATENOW(CFLAG:N:约会中) && FLAG:约会的对象 == TARGET
    Anti-pattern: IF CFLAG:N:约会中    ;always true after first date

CFLAG:N:同行
    Type: integer (minutes remaining, default 60)
    Set by: COMF351 (帯出去)
    Reset by: auto-decrement; manually clear via COMF351 menu
    Canonical predicate: IF CFLAG:N:同行
```

Without this metadata, every author falls into the same trap.

---

## Debug techniques used during this fix (worth adding to guide §13.7)

To diagnose the 约会中 bug, I used:

1. **Source grep**: `grep -rEn "约会中\s*=" ERB/` to find all set sites
   → revealed the slot is set to non-boolean values
2. **Source grep**: `grep -rEnh "CHK_DATENOW" ERB/` to see how
   experienced authors test "dating" → revealed the canonical idiom
3. **Function definition lookup**: `grep -rEnA 10 "^@CHK_DATENOW" ERB/`
   → revealed the actual logic (different MAP, not boolean)

**In-game debug techniques** (none of these are in the guide explicitly
in this consolidated form):
- `PRINTFORML [DBG] {var1}={var1} {var2}={var2}` — temporary inline
  inspection. The `{...}` form interpolates inside curly braces in
  PRINTFORM-family commands.
- `PRINT VARDUMP(var)` — dump entire array/struct
- Run with `DEBUG_MODE.bat` for a live console
- Tail `emuera.log` and `<timestamp>.log` for engine warnings
- For sticky-state bugs (like this one), place a debug PRINTFORML
  inside the predicate's body to confirm what value the slot actually
  holds at trigger time

The guide should have a dedicated "How to debug a misfiring predicate"
section, not just the brief mention in §13.7.

---

## Fix 13 — `M_KOJO_K20_日常系コマンド.ERB` cmd 300 condition #7 : `BASE:N:疲労` slot does not exist in this fork

**Symptom (engine warning):**
```
警告Lv2: 第108行:无法解析的标识符"疲労"
IF BASE:MASTER:疲労 * 2 > MAXBASE:MASTER:疲労
```

**Root cause:** Guide §4.1 lists `疲労` in the canonical `BASE:N:slot`
namespace examples. This fork's `CSV/Base.csv` does NOT contain a
`疲労` row. The actual slots are: `体力, 気力, 射精, 母乳, 尿意, 勃起,
精力, 法力, TSP, 情緒, 理性, 憤怒, 工作量, 深度, 酒気, 潜伏率, 身高,
体重, ...`. No 疲労.

**The canonical "tired" proxy** (used by K30 Eiki and others) is
`気力 < MAXBASE:気力 / X`. Energy-low = tired.

**Diff:**
```diff
-IF BASE:MASTER:疲労 * 2 > MAXBASE:MASTER:疲労
+IF BASE:MASTER:気力 * 2 < MAXBASE:MASTER:気力     ;気力低于一半 = "累了"
```

**Guide gap:** §4.1 lists slot names that don't actually exist. **The
guide's "namespace tables" are aspirational rather than verified.**
Recommended fix: every slot listed in guide §4 must be tagged with
either ✓ (verified in this fork's CSV) or ✗ (does not exist; use
alternative). The alternative for "fatigue" should be noted:
"This fork has no 疲労 slot; use `気力 < MAXBASE:気力 / 2` as proxy."

---

## Fix 14 — `M_KOJO_K20_日常系コマンド.ERB` cmd 300 condition priority — RAND-gating broad conditions

**Symptom (analytical, not a runtime bug):** With 10 condition-priority
branches inserted before the TALENT cascade, several conditions are
**too broad** and would suppress the rich恋人/愛欲/恋慕 dialogue:

| Condition | Trigger frequency | Suppression severity |
|---|---|---|
| 室外 (`OUTROOF`) | most of game world | ⚠⚠ massive |
| 深夜 (`TIME:2 >= 23 \|\| <= 3`) | 5h/day = 21% game time | ⚠ large |
| 雨天 (`TIME:5 in 4..7`) | full rainy day | medium |
| 醉酒/累/姐姐同格/共寝/浴室/约会中 | situational | acceptable (rich content for these contexts doesn't exist) |

The rich content was the point of writing tier-by-relationship
dialogue. Suppressing it because MASTER walked outdoors defeats the
purpose.

**Fix applied:** RAND-gate the three broadest conditions:
```diff
-IF GROUPMATCH(TIME:5, 4, 5, 6, 7)
+IF GROUPMATCH(TIME:5, 4, 5, 6, 7) && RAND:3 == 0    ;1/3
-IF TIME:2 >= 23 || TIME:2 <= 3
+IF (TIME:2 >= 23 || TIME:2 <= 3) && RAND:3 == 0     ;1/3
-IF OUTROOF(CFLAG:MASTER:現在位置)
+IF OUTROOF(CFLAG:MASTER:現在位置) && RAND:4 == 0     ;1/4
```

This preserves testability (player can retry `会話` until the line
fires) while letting rich relationship content play most of the time.

**Guide gap (architectural):** When the guide teaches "condition
branches before TALENT cascade" patterns, it should warn explicitly:
**"each early-return condition is a gate that suppresses all rich
content below it. Use early-return only for situations where the rich
content would be wrong (浴室, 共寝 etc.). For broad conditions
(weather, time-of-day, location-class), use RAND-gating or
relationship-tier-gating, or move them inside the TALENT branches as
flavor sub-branches, instead of as an early-return blocker at the
top."**

The guide §6 "Standard body shape" shows the cascade but doesn't warn
about the priority hazard.

---

## Fix 15 — `M_KOJO_K20_日常系コマンド.ERB` cmd 300 condition #9 : `TIME:2` is NOT the hour bucket

**Symptom (user-observed):** Condition #9 「深夜」 fires at 14:00
(afternoon), 13:00, etc. — clearly not late-night times.

**Root cause:** Guide §4.2 says:
> | `TIME:2` | Hour bucket. |

**This is wrong for this fork.** Inspecting `DEBUG.ERB:1368`, the
canonical engine code for "current time" is:
```erb
PRINTFORML 现在时间是：{TIME/60}时{TIME%60}分
```

So:
- `TIME` = minute-of-day (0-1439)
- `TIME / 60` = **hour (0-23)** ← canonical
- `TIME % 60` = minute
- `TIME:2` = **some 0-7 range "time-phase code"**, not the hour

Other kōjō confirm: K6 Luna uses `TIME:2 == 6` for "夜里"; K18 Lily
uses `TIME:2 == 2` for "早上好哦", `TIME:2 == 3` for "中午好哦".
These are tiny integers, not 0-23 hours.

So my predicate `TIME:2 >= 23 || TIME:2 <= 3`:
- `TIME:2 >= 23` is always false (TIME:2 max ~7)
- `TIME:2 <= 3` matches phases 0/1/2/3 = morning/forenoon/noon/afternoon
  → fires throughout the day, including 14:00

**Diff:**
```diff
-IF (TIME:2 >= 23 || TIME:2 <= 3) && RAND:3 == 0
+IF (TIME / 60 >= 23 || TIME / 60 <= 3) && RAND:3 == 0
```

Also added debug-PRINTFORML for inspection:
```erb
;PRINTFORML [DBG-9] TIME={TIME} TIME/60={TIME/60} TIME%60={TIME%60} TIME:2={TIME:2}
```

**Guide gap (significant):**

§4.2 globals table currently lists `TIME:2 = Hour bucket.` — this is
flatly **wrong** in this fork. Suggested replacement:

| Global | Means |
|---|---|
| `TIME` | Minute of day (0-1439). |
| `TIME / 60` | **Hour (0-23) — canonical for hour-of-day comparisons.** |
| `TIME % 60` | Minute (0-59). |
| `TIME:0` | Same as `TIME` (alias). |
| `TIME:2` | Time-phase code (~0-7); 6 = 夜, 2 = 早上, 3 = 中午, etc. **Do NOT use for hour comparisons; use `TIME / 60` instead.** |
| `TIME:5` | Weather phase (4-7 = rain). |

This bug is structurally similar to Fix 12 (`CFLAG:N:约会中` semantics
mistaken for boolean): the guide names a slot, names a "purpose", but
gets the actual numeric semantics wrong, so a naive predicate misfires.
The lesson generalizes to many slots — **the guide should explicitly
state the value DOMAIN of every named slot** (boolean / counter / map
ID / phase code / minute / item ID / etc.) and provide a CANONICAL
expression to obtain the commonly-needed derived value (hour from
TIME, "currently dating" from CFLAG:约会中, etc.).

A guide rewrite checklist:

- For every slot mentioned in §4.1/§4.2: tag with [BOOLEAN] /
  [COUNTER] / [PHASE-N] / [MAP-ID] / [ITEM-ID] / [TIMESTAMP].
- For every "common derived value" (hour, "is on date", "is tired",
  "is fertile", etc.): provide the canonical expression.
- Cross-reference an authoritative source file (preferably an engine
  helper definition) for each.

---

## Things this LLM session got wrong but did NOT fix yet

These were noticed during the bug-fix pass but left for later:

1. **`PRINTFORM` followed by `IF` block then `PRINTFORMW` is fragile.**
   The 300-会話 body uses this pattern (mirrored from Reimu) — the prefix
   `PRINTFORM 莉莉卡飘到%CALLNAME:MASTER%` runs without newline, then an
   `IF` block prints the suffix with `PRINTFORMW`. If the IF cascade
   doesn't match any branch, the prefix is left dangling without
   suffix-newline. Should add a final `ELSE` or default `PRINTFORMW`.

2. **`@K20_AENAI` is defined but never called** in any actual EVENT or
   COM body. If the user wants久别重逢台词 to fire, they need to add
   `CALL K20_AENAI` somewhere (e.g., in EVENT_K20_1 `ARG == 1` branch
   conditional on a "first visit today" check).

3. **The `K20_KEYBOARD_REACT()` function increments `TCVAR:20:350` but
   the daily reset (`FLAGSETTING_K20`) only resets if `DAY != CFLAG:20:1990`.**
   If the engine doesn't actually call `FLAGSETTING_K20` reliably at
   day-start in this fork, the counter may accumulate across days.
   Recommended: use a more robust reset hook (e.g.,
   `BEFORETRAIN_K20`).

4. **Some labels still produce theoretical issues at runtime that we
   couldn't observe in the user's first test:**
   - `IF LOCAL && !FLAG:時間停止` is a guard that wraps every body. But
     if `FLAG:時間停止` is set, the body prints nothing yet still
     `RETURN 1` — the engine will treat that as "handled" and skip
     fallback narration. Ideally should `RETURN 0` (or the engine has
     a `CFLAG:時間停止口上有` check we should rely on).
   - `MESSAGE_COM_K20_00` is now `LOCAL = 0 / RETURN 0` — engine should
     fall through to default. Untested whether that's correct.

---

## Resources actually used (beyond what the guide promised was sufficient)

The current guide presents itself as the SINGLE artifact an LLM needs to
help a user write a kōjō. In reality, this session pulled from **many
other sources** to get correct output. Below is the full list, in order
of how indispensable each was. The end-goal — "a non-technical user mails
the guide alone to a SOTA chat LLM and gets a working kōjō" — currently
fails because of these gaps.

### Hard requirements (without these, output broken on first run)

0. **Per-system data tables — alcohol example.** When asked to write
   per-alcohol drink-pouring (cmd 332) reactions, the guide alone
   cannot tell the LLM how many alcohols exist, what their item IDs
   are, what TFLAG holds the active alcohol, or how to get the taste
   evaluation. I had to grep three sources:
   - `CSV/Item.csv` rows 51-59 + 560-580 → ~25 alcohol items with IDs
   - `ERB/コマンド関連/COMF/日常系/COMF332 お酒をふるまう.ERB` →
     learns that the served alcohol's item ID is in `TFLAG:194`
   - `ERB/コマンド関連/COMF/日常系/酒関連.ERB` → defines
     `@ALCOHOL_TASTE(ARG)` returning a 0-30+ score, < 10 = disliked,
     >= 15 = liked
   - This pattern (specific game subsystem with item table + TFLAG
     parameter + classifier helper) repeats for: gifts, cooking
     dishes, items in trade, training equipment, weather, festivals,
     etc. The guide should provide an "Appendix D: per-subsystem data
     contracts" with one entry per subsystem, listing:
     `<subsystem>: <TFLAG slot> = <what>; <helper function>; <CSV
     file with item rows>`. Without this, every author has to grep
     blind.

1. **`CSV/Train.csv`** — the canonical command-ID → command-name table.
   Without it I had wrong command IDs (e.g., wrote `311 = 称赞` because
   I assumed semantically; actual is `311 = 擁抱`). Affected nearly every
   command body.
   - **Guide action:** embed Train.csv (the active rows) verbatim in an
     appendix, OR provide explicit instruction "before authoring any
     command, open Train.csv and look up the ID's name."

2. **`CSV/CFLAG.csv`** — to verify slot names are byte-exact. The guide
   uses Japanese-style 約 in flag examples; this fork uses simplified 约.
   Mixing produces the warning `无法解析的标识符"約会中"`.
   - **Guide action:** embed top-50 most-used CFLAG slots with **the
     exact Chinese character form used in this fork's CSV**, NOT the
     Japanese forms scattered through the existing guide.

3. **`CSV/STR.csv`** — to verify what `[[name]]` syntax can resolve.
   Guide §3.7 says "Requires the name to exist in `STR.csv`" but does
   not explain that **most character names are NOT in STR.csv** (they
   live in `CSV/Chara/Chara<N> <name>.csv` instead). Without checking,
   the LLM will write `[[アリス]]` which silently compiles to 0.
   - **Guide action:** strong warning "default to numeric IDs with
     comments; only use `[[X]]` for names you've grep-confirmed in
     STR.csv."

4. **`CSV/TFLAG.csv`** — to verify TFLAG slot names. Guide §5.6 mentions
   `TIME_PROGRESS(TFLAG:<key>)` but invented `<key>` like `逢瀬時間`
   doesn't exist.
   - **Guide action:** list the actually-existing TFLAG slot names in
     this fork.

5. **`CSV/Chara/` directory listing** — to map character IDs to canonical
   in-engine names (霊夢 = 1, 魔理沙 = 11, アリス = 17, リリカ = 20,
   メルラン = 21, ルナサ = 22, …). The guide's "char ID = directory's
   leading number" rule (§16-pt-8) is correct but partial: I needed the
   list itself, not just the rule, to write `K20_C_NAME` switch-case for
   inter-character references.
   - **Guide action:** embed a complete K1-K159 → name table.

6. **`CSV/Chara/Chara20 リリカ.csv`** — to verify the canonical display
   name (`名前` and `呼び名` rows). I assumed "莉莉卡" while the CSV
   said "莉莉喀". `%CALLNAME:20%` renders from CSV, producing inconsistent
   names mid-game.
   - **Guide action:** explicit step "before writing prose for character
     N, open `CSV/Chara/Chara<N> <name>.csv` and confirm the display
     name matches your prose, OR edit the CSV to match."

7. **Reimu's reference kōjō** (`001 Reimu [霊夢]/霊夢/M_KOJO_K1_*.ERB`)
   — I read this for at least 9 distinct things the guide doesn't cover:
   - Actual text style for Chinese dialogue (the guide is mostly English
     with some Japanese particles)
   - PRINTDATA / DATALIST / DATAFORM / ENDLIST nesting (guide §3.4 shows
     PRINTDATA with bare DATAFORMs — but real usage groups them in
     DATALIST blocks)
   - Copyright / license header convention
   - FlagManagement comment block convention
   - Standard CFLAG flag-set in `FLAGSETTING_K1`
   - **The actual ARG-by-ARG semantics of EVENT_K_1** (subphases 1-5
     for room/bath events) — not in the guide
   - PRINTFORM-IF-PRINTFORMW interleaving for context-conditional
     suffix narration
   - The `RETURN 0 / RETURN 1` convention per branch (the guide is
     ambiguous on which to use when)
   - **Engine-defined CFLAG slots that the guide §4.1 list omits.**
     Concrete example: `CFLAG:TARGET:陪睡中` (sleeping-together state)
     is not in guide §4.1's CFLAG enumeration but is used canonically
     in Reimu's command 300 body. Every k20 branch gating "sleeping
     together" came from grepping Reimu, not from the guide. Similarly,
     the simplified-form `约会中` (which actually works) is in Reimu;
     guide §4.1 lists `約会中` (traditional form, doesn't resolve in
     this fork).
   - **Guide action:** include a complete Reimu reference kōjō excerpt
     as appendix, OR explicit cross-reference like "for any pattern not
     covered here, grep the equivalent in `001 Reimu [霊夢]/霊夢/`."
     Add an explicit rule: **"Whenever the guide names a slot/flag/
     symbol, verify it exists in the actual CSV / Reimu kōjō before
     trusting it. The guide's lists are partial and have transliteration
     errors."**

8. **Other characters' kōjō (sampled)** — K5/K6/K7 DANMAKU signatures
   confirmed `(ARGS, 相手残機)` is a common but warning-producing
   pattern; K15/K17 confirmed `ARG:N=value` is the only legal default-
   arg syntax. The guide §3.1 misleadingly shows `TYPE = 0`.

### Soft requirements (the work suffered without these)

9. **The user's bug-log feedback** — many of these bugs only appeared at
   runtime. Without the user telling me "重复了几次" / "在不同房间也问候"
   / "莉莉喀 vs 莉莉卡 不一致", I had no way to know. The guide should
   include a "test-and-iterate" section with a checklist of common
   runtime symptoms and likely causes.

10. **Shell tools (`file`, `xxd`, `unix2dos`, `grep`, PowerShell)** —
    needed to manage encoding (BOM/CRLF) and verify text byte-for-byte.
    Most non-technical users won't have these; even the SOTA LLM session
    needs to be told the LLM has those tools available.
    - **Guide action:** include encoding instructions targeted at LLM
      sessions: "after writing any .ERB file, ensure UTF-8 BOM is
      present (prepend `EF BB BF` if your write tool didn't)."

11. **Direct file system access (`ls`, `Read`, `Edit`, `Write`)** — the
    guide assumes the LLM has tools to inspect / edit files. A
    chat-only LLM (no tools) couldn't follow the workflow at all. The
    guide should distinguish: "if you're a tool-using LLM, do X; if
    you're a chat-only LLM, give the user this script to run."

### Things the guide claimed I had, but didn't really

12. **The guide claimed `[[X]]` parse-time char ID lookup works** —
    only sometimes, only for STR.csv-listed names.
13. **The guide claimed default args `(ARG, TYPE = 0)` work** — they
    don't (positional only).
14. **The guide claimed `MESSAGE_COM_K_00` is a "fallback"** — it's
    actually a "fires-on-every-undefined-cmd" — much more aggressive than
    the word "fallback" suggests.

---

## Guide content audit: what should be deleted, compressed, or reorganized

The guide is ~1400 lines. About 30-40% can be cut without loss; another
20% should be replaced with project-specific tables (CSV embeds, char
ID list, command ID list) which would save the LLM from inventing wrong
values. Concrete recommendations:

### DELETE (low-value content the LLM has from training)

- **§3.8 "Built-in math/string ops" table.** Generic Emuera operators
  (`MAX`, `MIN`, `RAND`, `STRLENS`, etc.) — any SOTA LLM knows these
  from training data. If kept, compress to a single line "see Emuera
  reference for built-ins."
- **§5 second half (UI prompts, image/face/talk, pose/state, predicates,
  quest/gift/diary helpers).** These are reference-manual content that
  takes 200+ lines but is rarely needed in scaffolding. Move to a
  separate appendix or external link.
- **§12 "Beyond kōjō".** CSV layer overview, ERB subdirectories,
  command system internals, weather subsystem, resources/ — almost no
  first-pass kōjō author writes engine plugins. Cut to a 5-line "if you
  need to extend the engine itself, see X."
- **§4.1 namespace tables for TALENT/ABL/EXP** — currently lists 60+
  slot names. The LLM uses ~10-15 in practice. Cut to a "frequently
  used" subset, plus a "to find others, grep the corresponding CSV".
- **§14 persona-translation tips.** A chat-LLM doing creative writing
  doesn't need a translator's handbook; this section is filler. Cut.

### COMPRESS (kept but trimmed)

- **§9 file taxonomy (~80 lines) and §15 cheatsheet (~30 lines)** are
  near-duplicates. Merge into a single 30-line table.
- **§2.2 label list** has redundant rows for similar variants
  (PALAMCNG_A / A2 / B / B2 / F). Compress to a single "PALAMCNG_*"
  entry with branching logic in a sub-bullet.
- **§2.5 custom API tables** — useful but currently ~20 separate label
  rows. Compress to a 5-line "modern engines support a custom-button
  API; see <reference char with カスタム.ERB>".
- **§11.4 "Diagnosing my kōjō isn't firing"** is a 7-row table of
  symptom→cause; compress to 3 most-common rows + "for others, grep
  emuera.log".
- **§13.x quality-of-life conventions (5 sub-sections)** — collapse
  to a 10-line bullet list.

### REPLACE / REORGANIZE (the highest-leverage change)

- **Add an Appendix A: "Engine name dictionaries"** — embed the
  *actual rows* of Train.csv, CFLAG.csv, TFLAG.csv, TCVAR.csv,
  STR.csv (relevant rows only), Chara/ directory list. **This single
  appendix would have prevented ~70% of the bugs we hit.** It is more
  important than half the existing guide.
- **Add an Appendix B: "EVENT_K_X subphase semantics"** — one table
  per slot (1, 2, 3, ...) listing each ARG value's meaning and the
  required guards. Extracted from Reimu reference. Currently §2.2
  hand-waves this.
- **Add an Appendix C: "Reimu kōjō annotated excerpt"** — 200-300
  lines of Reimu's actual file with annotations marking the patterns
  the LLM should mimic. **A worked example beats a list of rules.**
- **Add an Appendix D: "Per-subsystem data contracts + reference
  implementations"** — one row per game subsystem, structured as 5
  columns:

  | Subsystem | Param storage | Classifier helper | Item-list CSV | **Reference kōjō to mirror** |
  |---|---|---|---|---|
  | alcohol | `TFLAG:194` = item ID | `ALCOHOL_TASTE(ARG)` | `Item.csv` 51-59, 560-580 | (TBD: which char's 332 is canonical? maybe Suika K10) |
  | gift | `TFLAG:??` = item ID | `GET_GIFTDATA(item, "得点")` | `Item.csv` ??? | (TBD) |
  | dish | `TFLAG:??` = dish ID | `DISHNAME` / `DISH_TASTE` | ??? | (TBD: maybe Yuyuko K66) |
  | weather | `TIME:5` = phase code | (direct `GROUPMATCH`) | (4-7=rain, 9=snow — should enumerate) | (any char with weather branches) |
  | festival | ?? | ?? | ?? | (TBD) |

  The 5th column ("Reference kōjō to mirror") is the most valuable
  part. Concretely it should answer: **"if I want to write good
  per-X reactions, which existing character's kōjō already did this
  well — and what file should I grep?"** Example entry expansion:

  > **Alcohol — reference: K10 Suika (萃香) `M_KOJO_K10_日常系コマンド.ERB`
  > cmd 332.** Grep `^@M_KOJO_MESSAGE_COM_K10_332` in that file to see
  > a canonical `SELECTCASE TFLAG:194` switch with per-item flavor.
  > Mirror that structure; substitute Suika's voice with your own
  > character's voice.

  Without this column, the LLM has to either skip per-item branching
  (output is generic) or grep blind through 5+ ERB files per
  subsystem. **A "look at this specific working file" pointer is
  worth ~10 abstract rules** — for example, all 8+ things I learned
  from Reimu (see Resource #7 above) could have been a single guide
  line: "for any standard daily/event/COM body, mirror the patterns
  in `001 Reimu [霊夢]/霊夢/M_KOJO_K1_*.ERB`."

  **In short: rules are useful but worked examples are 10× more
  useful per byte. The guide currently has 100% rules, 0% pointers
  to working examples.**

  Concrete alcohol-appendix sketch (verified against game source for
  cmd 332):
  ```
  TFLAG:194    = Item ID of the alcohol being poured
  ITEMNAME:(TFLAG:194)   = display string
  ALCOHOL_TASTE(TFLAG:194)  = taste score for TARGET (0-30+);
      < 10 = TARGET dislikes; 10 = neutral; >= 15 = likes
  Major item IDs (from CSV/Item.csv):
    51 濁酒  52 清酒  53 鬼殺酒  54 紅酒  55 神酒
    56 甜酒  58 蒸留酒  59 薬酒
    560 烧酒  561 蜂蜜酒  562 果酒  563 莓子酒
    564/565/566 白/金/黑朗姆酒
    567/568/569/570 强化/貴腐/陈酿/優質陈酿紅酒
    574 灰持酒  577 にごり酒  578 吟醸酒  579 熟成酒  580 古酒
  Engine-defined alcohol DATA records: ERB/コマンド関連/COMF/日常系/酒関連.ERB
  ```
- **Move §16 "Final reminders" to the TOP** as §0.5 — these are the
  most important rules and they're currently buried at line 1389+.
- **Restructure §0 to be "tools-using LLM" vs "chat-only LLM"
  branches.** A chat-only LLM cannot grep the project; instructions
  must differ.

### Effective reduction

If applied, the guide becomes:
- ~600 lines of prose (down from ~1400)
- + ~400 lines of project-specific appendices (replacing the LLM's
  guesswork with ground truth)
- = ~1000 lines net, 30% smaller AND meaningfully more correct

The cuts are not the point; **the appendices are**. The current guide
is a "what does Emuera DSL look like?" tutorial; what an LLM scaffolding
a kōjō actually needs is "what does THIS project's lookup tables
contain?".

---

## Suggested guide addition: "Verification pass" section

After the LLM scaffolds a kōjō, before declaring done, run this
verification script (Bash) and address all output:

```bash
DIR="path/to/your/<id> <name>/<variant>"
cd "$DIR"
echo "=== [[]] symbols not in STR.csv ==="
grep -hoE "\[\[[^]]+\]\]" *.ERB | sort -u | while read s; do
    name="${s:2:-2}"
    grep -qE "^[0-9]+,${name}\b" "/path/to/CSV/STR.csv" || echo "MISSING: $s"
done

echo "=== Custom-named function parameters ==="
grep -nE "^@.*\([A-Za-z_][A-Za-z0-9_]*\s*=" *.ERB | grep -vE "ARG(:[0-9]+)?\s*=" | grep -vE "ARGS(:[0-9]+)?\s*="

echo "=== CFLAG/TFLAG/TCVAR slot names not in CSVs ==="
grep -hoE "(CFLAG|TFLAG|TCVAR):([A-Z]+:)?[^a-z0-9 :,()<>=&|!*+\r\n_]+\b" *.ERB | \
    sed -E 's/^(CFLAG|TFLAG|TCVAR):([A-Z]+:)?//' | sort -u | while read slot; do
    grep -qF ",${slot}" /path/to/CSV/CFLAG.csv /path/to/CSV/TFLAG.csv /path/to/CSV/TCVAR.csv || \
        echo "MISSING: $slot"
done

echo "=== Files missing BOM ==="
for f in *.ERB; do
    head -c 3 "$f" | xxd -p | grep -q "efbbbf" || echo "$f"
done
```

The guide should include a version of this in §13.7 ("Testing tips").
