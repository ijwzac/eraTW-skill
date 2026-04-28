# 042 Hatate [はたて] / はたて — structural notes

Author-variant directory: `042 Hatate [はたて]/はたて/`. Char ID = **42**. The other variant `试做型姬海棠 自制别人/` is a separate user fork with different file count/layout — covered briefly at the end. The "primary" directory is the focus.

The author's persona (from `readme.txt`): *坦率* (frank), *大胃王* (big eater), normal libido, cellphone gimmick. Significant feature: **she is a paparazzi rival of Aya (29)** and reacts to other-character state across the cast.

This is a **near-maximal, professional-grade** authoring; almost every feature the engine supports is in use. Roughly **3.7 MB** of ERB.

## File set

| File | Role |
|------|------|
| `M_KOJO_K42_イベント.ERB` (596 KB) | All event-class labels: existence, flag-setting, color, UPDATE, ENCOUNTER, SPEVENT, EVENT, special CHARA_INFO override |
| `M_KOJO_K42_日常系コマンド.ERB` (1.1 MB) | COM 300–4xx |
| `M_KOJO_K42_性交系コマンド.ERB` (293 KB) | COM 60–7x |
| `M_KOJO_K42_セクハラコマンド.ERB` (200 KB) | COM 310–330 |
| `M_KOJO_K42_愛撫系コマンド.ERB` (165 KB) | foreplay COMs |
| `M_KOJO_K42_奉仕系コマンド.ERB` (162 KB) | sub-led service COMs |
| `M_KOJO_K42_カウンター.ERB` (160 KB) | COUNTER 1–9x + 100s |
| `M_KOJO_K42_派生コマンド.ERB` (162 KB) | SCOM 1–N |
| `M_KOJO_K42_絶頂.ERB` (124 KB) | **Orgasm hook** (`PALAMCNG_B`) — Luna lacks this entirely |
| `M_KOJO_K42_育児イベント.ERB` (73 KB) | child rearing |
| `M_KOJO_K42_カウンター.ERB` (160 KB) | counters |
| `M_KOJO_K42_コマンド.ERB` (48 KB) | misc COMs |
| `M_KOJO_K42_依頼.ERB` (34 KB) | quests |
| `M_KOJO_K42_弾幕勝負.ERB` (28 KB) | danmaku |
| `M_KOJO_K42_道具系コマンド.ERB` (16 KB) | toy COMs (40s, 100s) |
| `M_KOJO_K42_加虐系コマンド.ERB` (11 KB) | SM COMs |
| `M_KOJO_K42_ハードなコマンド.ERB` (12 KB) | "hard" COMs |
| `M_KOJO_K42_日記.ERB` (39 KB) | diary |
| `M_KOJO_K42_刻印取得.ERB` (1.6 KB) | mark hook |
| `K42_固有カウンター1_おちんぽ撮影.ERB` (1.5 KB) | **char-unique counter** (taking photos of MASTER's penis) |
| `K42_固有カウンター2_膣内撮影.ERB` (3.8 KB) | char-unique counter (inner-shot photos) |
| `Lib/K42C_はたて用DIM.ERH` (1.5 KB) | constant declarations |
| `Lib/M_KOJO_K42_関数ライブラリ.ERB` (94 KB) | character-private function library |
| `Lib/M_KOJO_K42_はたて特殊イベント.ERB` (147 KB) | character-private special events |
| `readme.txt`, `readme通常版.txt`, `CFLAG一覧.txt`, `供養.txt`, `ライセンステンプレ.txt` | author docs/memos (not loaded by engine) |

The `Lib/` directory is loaded — Emuera scans recursively for `.ERB`/`.ERH` files. The naming convention `K42C_*` (with the `C` suffix) is the author's hint that these are constants. Files in `Lib/` define **author-specific** symbols and helpers that the rest of this character's kōjō uses.

## What's structurally new vs. Luna

### 1. Author-defined constants (header file)

`Lib/K42C_はたて用DIM.ERH`:

```erb
;[CFLAG名]
#DIM CONST K42C_椛交流値              = 1010
#DIM CONST K42C_ちんぽ初見せ          = 1002
#DIM CONST K42C_约会回数              = 1021
#DIM CONST K42C_結婚                  = 1100
#DIM CONST K42C_極オナホ              = 1108
#DIM CONST K42C_極のアトリエ          = 1401
#DIM CONST K42C_極と通販              = 1403
...
```

`#DIM CONST <name> = <value>` declares a compile-time constant. After the header is loaded, body code can write `CFLAG:42:K42C_結婚` instead of `CFLAG:42:1100` (this matters because `1100`'s meaning is unrecoverable from context, while `K42C_結婚` is self-documenting). The engine resolves these at parse-time.

`.ERH` files are header-only — they declare DIMs. They never contain `@LABEL` definitions.

### 2. Author-defined helper functions (function library)

`Lib/M_KOJO_K42_関数ライブラリ.ERB` is **a `#FUNCTION` library** the author rolled themselves, partly borrowed from other characters' kōjō (as the comments document explicitly):

```erb
@K42_FIND_LOVER()
#FUNCTION                            ; declares this is a value-returning function
SIF TALENT:MASTER:恋人 == 0
    RETURNF 0
SIF TALENT:恋人
    RETURNF -1
LOCAL = TALENT:MASTER:恋人
SIF CFLAG:LOCAL:現在位置 == CFLAG:MASTER:現在位置
    RETURNF 2
RETURNF 1
```

Use site: `IF K42_FIND_LOVER() == 2 …` — the function is callable in expressions.

```erb
@K42_FIND_AROUND()
#FUNCTION
#DIM 知り合い, 6 = 29, 65, 51, 49, 38, 1   ; literal-init array of "acquaintances"
#DIM 総人数
#DIM 抽選
#LOCALSIZE 200                      ; expand local array size
...
```

Notable: `#DIM <name>, <size> = <a>, <b>, <c>` performs **inline array initialization** — `知り合い:0 = 29` and so on.

Other Hatate-private functions (use cases obvious from names):
- `@K42_DRUNK()` returns `0..3` based on `BASE:42:酒気`.
- `@K42_BOKKI()` — caller-passed `CHARA` arg returns 0..3 erection level.
- `@K42_AENAI` — "days since last met" line if not seen in a while.
- `@K42_KOUSAI` — anniversary printer (every 124 days = 1 year).
- `@CHARA_INFO_KOJO_K42()` — overrides the **角色介绍** screen content.
- `@K42_COOKING_REACTION` — `SELECTCASE DISHNAME` over the engine's dish names.
- `@NAME_SET_K42` — interactive nickname-setting routine; runs an `INPUTS` loop, sanitizes the input, rejects look-alike names like `姫海棠 極`/`犬走 椛`/`お兄様` based on `STRCOUNT(LOCALS, "<regex>")`, stores into `MASTERNAME:42`.

### 3. Special-event labels (author-private major events)

`Lib/M_KOJO_K42_はたて特殊イベント.ERB` contains author-private `@K42_<name>` labels — major one-shot story events triggered from elsewhere (e.g., from a daily-event hook):

```erb
@K42_4KANO                           ; "the 4 tengus love MASTER" event
@K42_PREGNANCY_DESIRE                ; "I want a child" event — sets TALENT:妊娠願望 = 1
@K42_HEALTH                          ; energy-drink prank event — randomizes BASE:MASTER:体力
... etc
```

These are **not engine-dispatched**. They are called from within other kōjō labels (e.g., a daily event sets a CFLAG, an event-hook sees the CFLAG, and `CALL K42_PREGNANCY_DESIRE` is invoked). Authors use them to *modularize* a long story arc.

### 4. Char-unique counters (`K42_固有カウンター*_<name>.ERB`)

Each numbered file declares **four** labels (the engine looks for these by suffix `1`, `2`, …):

```erb
@UNIQUE_COUNTER<N>_ABLE_K42        ; eligibility — RETURN 0/1
@UNIQUE_COUNTER<N>_FREQUENCY_K42   ; RESULTS = "type" + RETURN = base-10 frequency
@UNIQUE_COUNTER<N>_MESSAGE_K42     ; print body
@UNIQUE_COUNTER<N>_SOURCE_K42      ; side-effects (SOURCE updates, pose set, etc.)
```

`RESULTS` for `_FREQUENCY` must be one of: `ソフト / ベリーソフト / コミュ / 着衣 / 脱衣愛撫 / 脱衣強要 / 抱き着き / 性交 / 責め / おねだり`. The engine uses this to **pick the right scene-state context** (e.g., `脱衣愛撫` requires the partner be partially undressed). Numeric return is added to the engine's base counter rate.

`@UNIQUE_COUNTER1_SOURCE_K42` body shows the typical SOURCE-update / pose-set / equipment-undress side effects:

```erb
CALL TOUCH_SET(SET_FROM_YUBI, 1, [[極]])
TFLAG:MASTERのＣ使用中 ++
IF TEQUIP:PLAYER:0
    IF TEQUIP:PLAYER:0 & 1
        CALL DATUI_BOTTOM([[極]], 1)
    ELSEIF TEQUIP:PLAYER:0 & 8
        CALL DATUI_BOTTOM([[極]], 2)
    ENDIF
ENDIF
SOURCE:[[極]]:性行動 += 150
SOURCE:[[極]]:侮辱 += 500
SOURCE:[[極]]:加虐 += 100
SOURCE:[[極]]:征服 += 100
TCVAR:[[極]]:嗜虐フラグ = 1
CALL EVENT_COUNTER_POSE_69([[極]], 2)
```

### 5. The orgasm hook

`@M_KOJO_MESSAGE_PALAMCNG_B_K42` is engine-dispatched at the end of any command that produces a climax. It branches on:

- `NOWEX:噴乳` (lactation), `NOWEX:射精` (ejaculation: 0..3 = none/normal/large/extreme), `NOWEX:放尿` (urination), `NOWEX:Ｃ絶頂` / `Ｖ絶頂` / `Ｂ絶頂` / `Ａ絶頂` / `Ｍ絶頂` (per-zone climax intensity), `NOWEX:TotalEX` (sum, 1..15), `SYNCED_ORGASM(TARGET)` (synced).
- Equipment-routing: `TEQUIP:Ｖ接触部位 == 1/3/4` for "what made contact" (penis/finger/tongue), `TEQUIP:振動棒` / `TEQUIP:陰蒂夾` etc. for toy-driven climax.
- `SELECTCOM == N` to gate the "first-time using this toy" CFLAG bumps.

Use side-effects to flip first-time CFLAGs:

```erb
SIF SELECTCOM == 40 && CFLAG:K42C_極と通販 != 2
    CFLAG:K42C_極と通販 = 1   ; was 0 → now 1 (advanced one tier)
```

Luna's directory has *no* orgasm file. This is one of the most missing-but-impactful slots.

### 6. The 角色介绍 (info-screen) override

`@CHARA_INFO_KOJO_K42()` overrides the per-character info tab. Body uses `PRINTFORML` with rich state-driven branching:

- `IF CFLAG:K42C_結婚 >= 1`: print married-state intro.
- `IF EXP:42:愛情経験 >= 200`: print "love-experience-saturated" intro variant.
- `IF EXP:42:約會経験 >= 100`: print "date count" milestone.
- Branches on `CFLAG:42:1413` (time-stop-acceptance), `CFLAG:42:1414` (suspicion of MASTER), etc., to print plot-state.

So the info screen *is* a kōjō slot — author owns it.

## Special interpolation forms

- `%TEXTR("a/b/c/d")%` — random-pick one of the slash-separated alternatives.
- `%MASTERNAME:42%` — the per-character nickname for MASTER (mutable). Each character maintains their own `MASTERNAME:N`. Set during `@NAME_SET_K42` via an `INPUTS` loop with regex-based reject filters.
- `%CALLNAME:N%` — character display name.
- `%PANTS_DESCRIPTION(EQUIP:TARGET:下半身内衣２, TARGET)%` — engine-side description function — built-in.
- `%SHOW_BOTTOM(TARGET)%`, `%OPPAI_DESCRIPTION(N, 1)%` — body-description functions (in `COMMON_KOJO.ERB`).
- `%CSVCSTR(N, slot)%` — CSV-string lookup.
- `%CALLNAME:N%`-style nested lookup chain with `[[NAME]]`: `[[極]]` resolves to char ID 42 at parse time (see `STR.csv` resolution table).
- `%"text",72,LEFT%` — fixed-width padded text.

## Engine helpers used (additions to Luna's set)

- **Yes/no**: `CALL ASK_YN("yes-text", "no-text")` — sets `RESULT` to 0 (yes) / 1 (no — confusingly the negated form, see code).
- **Multi-target**: `GET_TARGETNUM()`, `TARGET:N` (N-th in TARGET array, `TARGET:0` is current).
- **Co-presence**: `K42_FIND_AROUND()` (author's helper) iterates `知り合い:N`, then `TARGET:N`.
- **String ops**: `STRCOUNT(s, "regex")`, `STRLENS(s)`, `REPLACE s, "from", "to"`, `INPUTS`.
- **UI**: `PRINTBUTTON @"label", @"return-value"`, `CLEARLINE 1`, `REUSELASTLINE <text>`.
- **Range check**: `INRANGE(RESULT, 0, 3)`.
- **Math**: `MAX(a, b)`, `MAXBASE:N:slot`.
- **Pose / state**: `TOUCH_SET(SET_FROM_YUBI, 1, [[N]])`, `EVENT_COUNTER_POSE_69([[N]], M)`, `DATUI_BOTTOM([[N]], M)` (M=1: pull down; M=2: full strip).
- **Game state**: `MAIN_MAP` (current world map ID), `ESTRUS_CYCLE(N)`, `SYNCED_ORGASM(N)`, `OUTROOF(loc?)`, `BATHROOM(loc?)`.
- **Image**: `CALL 画像セット(@"顔絵_<state>_<expr>_{[[N]]}", x, y, w, h, _, _, "default")` — set image. `CALL 画像一斉表示("左", 0, 1)` — display all set images.
- **Multi-char dispatch**: `CALL HPH_PRINT, @"...", "L"` — the "panting print" decorator (visible string formatter).

## SOURCE: post-action affection ledger

The single most important pattern Hatate uses that Luna doesn't:

```erb
SOURCE:[[極]]:露出       += 1500
SOURCE:[[極]]:逸脱       += 500
SOURCE:[[極]]:与快Ｃ     += 50
SOURCE:[[極]]:性行動     += 150
SOURCE:[[極]]:誘惑       += 1000
SOURCE:[[極]]:侮辱       += 500
SOURCE:[[極]]:挑発       += 1000
SOURCE:[[極]]:加虐       += 100
SOURCE:[[極]]:征服       += 100
```

These accumulate in a transient ledger that the engine reads at end-of-turn (in `ステータス計算関連/`), then applies as deltas to `ABL/EXP/CFLAG:好感度`/etc. **All counter and unique-counter handlers should update SOURCE.** Without it, the kōjō prints text but doesn't shift affection.

## Persona-specific behavior (Hatate)

- **Conditional update prompt** (in `@M_KOJO_UPDATE_K42`): asks for permission to grant `坦率`+`大胃王` talents. If denied, sets `CFLAG:42:1001 = -1` (negative, distinct from "not asked yet"). On accept, mutates `TALENT:42:態度 = -1` and `TALENT:42:大胃王 = 1`.
- **Conditional name-input** (also in update): if encountered but `MASTERNAME:42 == ""`, calls `@NAME_SET_K42` to capture player's preferred form-of-address.
- **Conditional rich animation toggle**: also in update, four-way `INPUT` for animation-display preference, stored in `CFLAG:42:1501` (which the body then reads to choose "use animation" vs "use static"); a body would read `IF CFLAG:42:1501 == 0` etc.
- **Push-down policy** is computed dynamically:
  ```
  IF TALENT:42:恋慕 || TALENT:42:恋人 || TALENT:42:炮友 || TALENT:42:愛欲
      CFLAG:42:推倒禁止 = 0
  ELSEIF (TALENT:MASTER:幼女 && +扶她 && +魅力系) AND
         ((CFLAG:积攒度 >= 750 && PALAM:欲情 >= PALAMLV:5) || TCVAR:発情)
      CFLAG:42:推倒禁止 = 0
  ELSE
      CFLAG:42:推倒禁止 = 1
  ENDIF
  ```
  Fine-grained — push-down (Hatate jumping MASTER) only allowed when relationship state and player physical state match.
- **Encounter** branches on `MAIN_MAP == 8` (Tengu mountain), and within that on `CFLAG:MASTER:初期位置` to recognize 11+ co-living locations (Aya/Momiji/cabin/Yasaka/Suwako/Sanae/Tenshi/private rooms etc.).
- **Sex-talent branching cascade**: `IF TALENT:恋慕 || TALENT:恋人` (most affectionate) → `ELSEIF TALENT:愛欲 || TALENT:炮友` (lustful but not romantic) → `ELSEIF TALENT:思慕` (admiring) → `ELSE` (neutral). These four tiers are the canonical relationship-state buckets.

## What changes in `试做型姬海棠 自制别人/`

The other variant has only:
- `M_KOJO_K42_イベント.ERB` (218 KB)
- `M_KOJO_K42_コマンド.ERB` (138 KB)
- `M_KOJO_K42_COUNTER.ERB` (54 KB)
- `口上说明.txt`, `更新情报.txt`

This is a **minimalist port** that combines all command-style files into one big `_コマンド.ERB`. Engine-side it's the same labels (`@M_KOJO_MESSAGE_COM_K42_<n>`); just stored differently. Demonstrates that **the file-per-category split is a convention, not a rule**.

## Heuristics for the LLM-doc

- The full feature surface seen here is what a "high-end" character looks like. Most characters use a subset.
- **Always update SOURCE** in counter/unique-counter handlers — text without ledger is a one-shot prop.
- Use `Lib/` for anything reusable: constants, helper functions, special events. Reference them from the regular kōjō.
- The orgasm hook is `@M_KOJO_MESSAGE_PALAMCNG_B_K<id>`. Branches on `NOWEX:*絶頂`, `NOWEX:射精`, `NOWEX:TotalEX`.
- The info-screen hook is `@CHARA_INFO_KOJO_K<id>()`. The body is rendered when the player opens the character's info tab.
- For dynamic narrative branches that don't fit a command/event slot, define a `@K<id>_<name>` author-private label and `CALL` it from a daily-event hook with appropriate guards.
- Strings that need to *vary* but can't be done with `RAND:N` (e.g. random epithets within one printed line) use `%TEXTR("a/b/c")%` instead.
- `MASTERNAME:N` is per-character mutable — set it during a name-input dialog after first encounter, then use it everywhere instead of `%CALLNAME:MASTER%`.
