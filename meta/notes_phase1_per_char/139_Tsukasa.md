# 139 Tsukasa [典] / 典 — structural notes

Author-variant directory: `139 Tsukasa [典]/典/`. Char ID = **139**. The other variant `典（机翻更新版）/` is a community machine-translated update.

Tsukasa is **by the same author as Hatate (042) — すし**, so its file taxonomy and many helper-function patterns are shared. The new structural ground covered here is:

1. **Default-argument syntax** in label headers.
2. **Wetness / clothing-transparency state machine**.
3. **Multi-choice prompt (`ASK_M`) with per-option weights**.
4. **Per-character lover-mode nickname stored in CSTR**.
5. **Tightly state-machined "specific-event" library** with explicit external CFLAG hooks per event.

## File set

| File | Role |
|------|------|
| `M_KOJO_K139_イベント.ERB` (399 KB) | events |
| `M_KOJO_K139_日常系コマンド.ERB` (547 KB) | daily COMs |
| `M_KOJO_K139_性交系コマンド.ERB` (203 KB) | sex COMs |
| `M_KOJO_K139_セクハラコマンド.ERB` (127 KB) | sexual-harassment COMs |
| `M_KOJO_K139_愛撫系コマンド.ERB` (59 KB) | foreplay COMs |
| `M_KOJO_K139_派生コマンド.ERB` (68 KB) | SCOMs |
| `M_KOJO_K139_カウンター.ERB` (59 KB) | counters |
| `M_KOJO_K139_依頼.ERB` (53 KB) | quests |
| `M_KOJO_K139_絶頂.ERB` (47 KB) | orgasm |
| `M_KOJO_K139_奉仕系コマンド.ERB` (47 KB) | service COMs |
| `M_KOJO_K139_典特殊イベント.ERB` (38 KB) | **char-private special events** |
| `M_KOJO_K139_コマンド.ERB` (25 KB) | misc COMs |
| `M_KOJO_K139_弾幕勝負.ERB` (22 KB) | danmaku |
| `M_KOJO_K139_道具系コマンド.ERB` (13 KB) | toy COMs |
| `M_KOJO_K139_育児イベント.ERB` (12 KB) | child rearing |
| `M_KOJO_K139_ハードなコマンド.ERB` (10 KB) | hard COMs |
| `M_KOJO_K139_加虐系コマンド.ERB` (12 KB) | SM COMs |
| `M_KOJO_K139_日記（簡易版）.ERB` (9 KB) | "diary (simple version)" |
| `K139_固有カウンター1.ERB` (1.7 KB) | char-unique counter (tail-touch) |
| `M_KOJO_K139_関数ライブラリ.ERB` (16 KB) | char-private function library |
| `M_KOJO_K139_刻印取得.ERB` (3 KB) | mark hook |
| `自分用メモ/` (subdir) | author memos |
| `readme.txt`, `フラグ管理メモ.txt`, `衣装メモ.txt`, `ライセンス.txt` | author docs |

Compared to Luna and Hatate, **Tsukasa fits its function library directly in the kōjō root** rather than under `Lib/`. Either layout is valid (the engine doesn't care).

## Structurally new patterns

### 1. Default-argument syntax in label headers

```erb
@K139_C_NAME(ARG, TYPE = 0)
#FUNCTIONS
```

`(ARG, TYPE = 0)` declares `TYPE` with a **default value of 0**. Callers can omit it: `K139_C_NAME(0)` or pass it: `K139_C_NAME(36, 1)`. This is the only sane way to add new optional args without breaking call sites.

`#FUNCTIONS` (note the trailing `S`) is the **string-returning function** marker — distinct from `#FUNCTION` (numeric-returning). The body must `RETURNF "...string..."`.

### 2. Wetness / transparency state machine

```erb
@K139_AMANURE
;雨の日に屋外にいるなら服が濡れて透ける。旗袍限定
IF OUTROOF(CFLAG:139:現在位置) && GROUPMATCH(TIME:5, 4, 5, 6, 7)
    SELECTCASE TIME:5
    CASE 5                            ; heavy rain
        TCVAR:355 += 7
    CASEELSE
        TCVAR:355 += 3
    ENDSELECT
ENDIF
```

`TIME:5` is the **weather phase** (4-7 corresponds to rainy weather; this confirms `TIME:5` semantics that wasn't clear from Luna). `TCVAR:355` is Tsukasa's per-target wetness gauge.

```erb
@K139_NURESUKE()
SELECTCASE TCVAR:139:355
CASE 0
    RETURN -1                          ; dry
CASE IS > 100                          ; soaked
    PRINTFORML 衣服紧紧贴在典的躯体上 ...
    IF CFLAG:没穿内裤 == 1
        ...
    ELSE
        PRINTFORML %PANTSNAME(EQUIP:TARGET:下半身内衣２, TARGET)% 透了出来 ...
    ENDIF
CASE IS > 50                           ; partial
    IF EQUIP:上半身内衣１
        PRINTFORML %CLOTHNAME(7, EQUIP:139:7)% 若隐若现 ...
    ELSEIF EQUIP:上半身内衣２
        PRINTFORML %CLOTHNAME(8, EQUIP:139:8)% ...
    ELSE
        PRINTFORML 樱粉色的乳头 ...    ; nothing under the wet outer
    ENDIF
CASE IS > 0                            ; barely
    PRINTFORML 在典的衣服上浸染出两抹绯晕 ...
ENDSELECT
```

Helpers used:
- `OUTROOF(loc)` — outdoors? (engine).
- `EQUIP:slot` and `EQUIP:N:slot` — current equipment slot. Slots have semantic names (`下半身内衣２`, `上半身内衣１`, etc., declared in `Equip.csv`).
- `%CLOTHNAME(slot, equip_id)%` — engine helper: "name of the cloth in slot S with id E for char N's wardrobe".
- `%PANTSNAME(EQUIP:TARGET:下半身内衣２, TARGET)%` — same for underwear.

The pattern shows that **bodies can be expressive about the character's current outfit** — they read the equipment table and resolve names/states.

### 3. The clothing system (from `衣装メモ.txt`)

Slot `下半身内衣２` has 11 well-known IDs (1=緊身内衣, 2/3=贴身长筒袜, 4/5=兔女郎服, 6=死库水, 7=競泳水着, 8=連体泳装, 9=Y字, 10=保暖, 11=鎖帷子). Bodies often check `EQUIP:下半身内衣２ == 22` to gate "kayfabe-undress" branches. The author's memo also documents that **連衣裙 has 裙子属性** (skirt-attribute) for `掀裙子` to function.

The relationship between equipment numbers and clothing names is in `OBJ/CLASS/CLOTHES/`. **For an LLM writing kōjō, treat the clothing IDs as opaque and rely on `%CLOTHNAME(slot, equip)%` / `%PANTSNAME(slot, char)%` interpolation rather than testing IDs by hand** — except for top-tier "is this character naked" checks.

### 4. Per-character "C-NAME" function

```erb
@K139_C_NAME(ARG, TYPE = 0)
#FUNCTIONS
;ARG = char id (or 0 for MASTER)
;TYPE 0 = polite suffix, 1 or 2 = "someone"/"another person" if path-er or self,
;     3 = race/tribe-style appellation
SELECTCASE ARG
    CASE 0
        RETURNF CALLNAME:MASTER + "さん"
    CASEELSE
        RETURNF CALLNAME:ARG + "さん"
ENDSELECT
```

This is a **char-side public API** — it returns "what Tsukasa calls character N." Bodies use `K139_C_NAME(TARGET)` instead of `%CALLNAME:TARGET%` to layer on suffixes. Used heavily in narration like "%K139_C_NAME(LOCAL)%は……".

### 5. Per-character lover-mode nickname (stored in CSTR)

```erb
@K139_SET_C_NAME(ARG)
;ARG=0:通常初回 =1:恋慕 =2:祈願→通常変更 =3:祈願→恋慕変更
...
INPUTS
C_NAM = %RESULTS%
... validation cascade ...
IF MASTERNAME:139 == "" || ARG == 2
    MASTERNAME:139 = %C_NAM%
ELSE
    CSTR:139:80 = %C_NAM%        ; lover-mode private nickname
ENDIF
```

`CSTR:N:slot` is **per-character mutable string storage**. Tsukasa keeps two nicknames:
- `MASTERNAME:139` — the "everyday" name.
- `CSTR:139:80` — the lover-mode private name (e.g. "darling", "honey").

Bodies switch by relationship state:

```erb
\@ TALENT:139:恋人 ? %CSTR:139:80% # %MASTERNAME:139% \@
```

This is the next refinement above Hatate's single `MASTERNAME:N`.

### 6. Multi-choice prompt: `ASK_M`

```erb
CALL ASK_M("想要射出来", 1, "中断support", 1, "已经不需要了", 1)
SELECTCASE RESULT
CASE 0
    ...
CASE 1
    ...
CASE 2
    ...
ENDSELECT
```

`ASK_M(label1, weight1, label2, weight2, ...)` is engine-side and presents N choices. The integer between each label is the option's "weight"/availability flag (1 = enabled, 0 = grey-out). `RESULT` is the chosen 0-based index. Used heavily in choice-driven character bodies.

### 7. The "specific-event" library style (`典特殊イベント.ERB`)

Each event is a standalone `@K139_<NAME>` label with a `;CALL K139_<NAME>` comment above documenting its caller convention. Examples:

- `@K139_ONASAPO` — "self-pleasure supporter Tsukasa" event. Branches on `CFLAG:1008` (event progress: 0 = first encounter, 1 = first session, 4 = ongoing). Each session updates the same CFLAG, advancing the state machine.
- `@K139_PREG_WISH` — "I want a child" event. One-shot, sets `TALENT:妊娠願望 = 1`.
- `@K139_AFFAIR` — "secret affair" event.

Each is **modular**: the author's main kōjō files have `IF <state-trigger> ... CALL K139_<event-name>` to invoke them when conditions ripen. The events use:

- `CALL ASK_YN("yes-text", "no-text")` for binary.
- `CALL ASK_M(...)` for multi-choice.
- `CALL HPH_PRINT, @"text", "L"` for "panting" emphasis.
- `CALL PRINT_FACE, [[典]], "笑顔", "服", "", ""` for face display (note: 6 args, last two empty strings — `expr`, `clothing`, plus padding).
- `\@ <cond> ? <a> # <b> \@` ternaries inside HPH_PRINT strings.

### 8. The flag-management memo style (from `フラグ管理メモ.txt`)

Tsukasa's memo lists all reserved CFLAGs (1000-1999) and TCVARs (350-374). Worth quoting one for the LLM doc since it documents *what the author intends each slot to mean*:

```
;CFLAG:1000 典より先に龍が恋慕         ; "Megumu got 恋慕 before Tsukasa"
;CFLAG:1001 典の後に龍が恋慕           ; "Megumu got 恋慕 after Tsukasa"
;CFLAG:1004 你が龍に好意を持ってるかもしれない？
;CFLAG:1008 自慰サポート初回判定(2=終了, 3=中断)
;CFLAG:1011 ○回目のプロポーズ
;CFLAG:1014 被逆推回数
;CFLAG:1015 幻想郷縁起がバレた
;CFLAG:1019 初めてのＶ挿入
;CFLAG:1998 UPDATE時出産回数フラグ      ; reserved for the engine's UPDATE path
;CFLAG:1999 胸圍・UPDATE管理フラグ      ; reserved for the engine's UPDATE path

;TCVAR:350 心情不快時身体接觸回数
;TCVAR:355 雨濡れ・水濡れ
;TCVAR:357 今日の推倒
;TCVAR:358 今日一日の膣内射精回数
;TCVAR:359 膣内避孕套射精（使用）回数
;TCVAR:360 典がガチ子作りモード
;TCVAR:374 尿意ゲージ
```

The pattern is clear: **CFLAG = persistent across days; TCVAR = transient/per-day.** Authors assign them numeric IDs in the 1000s (CFLAG) and 350s (TCVAR) ranges; engine reserves 1998/1999 for its own purposes.

### 9. CSTR-driven 角色介绍

```erb
@CHARA_INFO_KOJO_K139()
CALL M_KOJO_COLOR_K139
PRINTFORML %CSVCSTR(139, 10)%   ; canonical species/ability summary from CSV row 10
RESETCOLOR
PRINTL 

;Common branches
PRINTFORML 传说中被冠以邪恶之名的管狐
IF TCVAR:発情 ...
IF (TALENT:MASTER:年齢 == -1 || TALENT:MASTER:幼児／幼児退行) ...

;Optional CSTR-driven free-form blocks (commented out by default)
;FOR LOCAL,20,40
;    SIF CSTR:139:(LOCAL) != ""
;        PRINTFORML %CSTR:139:(LOCAL)%
;NEXT
```

The block at the end is a **plug-in for the player to inject custom info-text** by writing into `CSTR:139:20..39`. By keeping it commented, Tsukasa says "this slot exists if you want to extend later." This is a generally-useful pattern: leave CSTR slots free for downstream patches to populate.

### 10. The unique counter is *minimal*

`K139_固有カウンター1.ERB` — Tsukasa's "tail-touch" counter — has the same 4-label shape as Hatate's, but the `_SOURCE_K139` body is **mostly commented out** (calls to `TOUCH_SET`, `DATUI_BOTTOM`, `EVENT_COUNTER_POSE_69` are all `;`-prefixed). The author left the scaffolding in place but wrote only `SOURCE:[[典]]:情愛 += 150`-style ledger updates. **Comment-out is a valid "stub"** for unfinished labels — the file still loads, the label exists, and the engine can call it without crashing.

## Heuristics for the LLM-doc

- Default-argument syntax: `@LABEL(ARG1, ARG2 = N)` for optional numeric, `@LABEL(ARGS, ARGS:1 = "default")` for optional string. Callers omit the trailing args.
- Use `#FUNCTION` for numeric returns (`RETURNF N`), `#FUNCTIONS` for string returns (`RETURNF "..."`).
- For per-character clothing-transparency / wetness behavior, define a helper like `@K<id>_NURESUKE()` that reads the wetness counter and prints based on `EQUIP:` and `TCVAR:` state.
- For lover-vs-everyday name distinction, store the lover-mode private nickname in `CSTR:N:80` (or any unused CSTR slot ≥40 — slots 0-19 are typically engine-reserved).
- For multi-choice scenes, prefer `ASK_M` over `INPUT + SELECTCASE RESULT` because it auto-formats and supports per-option weights.
- For long story arcs that span many turns, structure them as `@K<id>_<NAME>` labels in a "特殊イベント" file with a state-tracking CFLAG; advance the CFLAG inside each call to control the next branch.
- The `自分用メモ/` subdir convention: keep the author's wishlist, costume notes, and version history as `.txt` files alongside the `.ERB`. Engine ignores `.txt`.
