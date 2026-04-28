# Engine-callable label catalog (full reference)

This file contains the complete list of every label the engine knows how to dispatch into, including the kojo-selector mechanism, MESSAGECHECK / EXTRASOURCE / custom-API extensions, and author-extension idioms.

**Bracketed `[%RESULTS%_]` slots** in label prefixes mean: "if a kojo selector is set, the engine inserts it here." Most characters leave it empty.

### 2.4 Engine-callable labels — the complete list

You only need to remember these. Anything not in this list is author-private (fine to define, but the engine won't call it directly).

**Per-character lifecycle** (one each, optional):
| Label | Runs |
|---|---|
| `@M_KOJO_K{id}(ARG)` | Existence check. Must `RETURN 1`. Set `RESULTS = "_<NAME>"` to declare a selector (rare). |
| `@M_KOJO[%RESULTS%_]FLAGSETTING_K{id}` | Every turn. Initialize `CFLAG:N:<flag>` and run per-turn state-machine ticks. |
| `@M_KOJO[%RESULTS%_]COLOR_K{id}` | Every line. `SETCOLOR` for character voice. |
| `@M_KOJO[%RESULTS%_]UPDATE_K{id}` | Once per game-version-load. Permission UIs (grant talents, choose nickname). |

**First meeting / one-shot story**:
| Label | Runs |
|---|---|
| `@M_KOJO[%RESULTS%_]ENCOUNTER_K{id}` | First time MASTER meets this character. |
| `@M_KOJO[%RESULTS%_]SPEVENT_K{id}_{ev}(ARG, ARG:1)` | Scripted special event `ev`. ARG selects sub-state (0 = propose, 1 = accept, 2 = reject, etc). Body usually starts with `CALL SPEVENT_MESSAGE_{ev}(ARG, ARG:1)` to print the engine's default narration. |

**Generic events** (these PRINT message text):

| Label | Args | What ARG means |
|---|---|---|
| `@M_KOJO[%RESULTS%_]EVENT_K{id}_{ev}(ARG, ARG:1)` | `ev` = engine event slot 1..30+ | **`ev=1` is room/cell encounter — fires once per cell transition the char makes on the same world map, even if MASTER is in a different cell. Always guard the body with `SIF CFLAG:{id}:現在位置 != CFLAG:MASTER:現在位置 / RETURN 0` first, then branch on ARG sub-phase.** Common slots: `1` = room/cell encounter (sub-phases 1-5: see §2.4.1), `2` = morning, `3` = bedtime, `_ONABARE_<n>` = outburst, `_GIFT` = gift reaction. |
| `@M_KOJO[%RESULTS%_]DAILY_EVENT_K{id}_{n}(ARG, ARG:1, ARG:2, ARG:3, ARG:4, ARGS:1, ARGS:2)` | 7-arg | Daily event with full state vector. |

**Generic events that DO NOT print** (silent control-flow / state-machine; printing in their bodies will spam the player every tick):

| Label | Args | Role |
|---|---|---|
| `@M_KOJO[%RESULTS%_]EVENT_K{id}_GRAVITY(ARG)` | 1-arg | **Silent NPC-AI movement attractor — NOT a flavor "gravity" event despite the name.** Engine fires this every NPC-movement-decision tick (many times per turn). Body MUST set `TCVAR:{id}:引力点 = <location-code>` to influence the AI's destination, and MUST NOT call any `PRINT*`. Default `TCVAR:{id}:引力点 = 0`. See K30 Eiki's `EVENT_K30_GRAVITY` for canonical pattern. |
| `@M_KOJO[%RESULTS%_]EVENT_K{id}_LOST_VIRGIN_STOP(ARG)` | 1-arg | Silent. Body sets `TFLAG:中止破瓜` or similar to abort the virginity-loss flow. |
| `@M_KOJO[%RESULTS%_]EVENT_K{id}_PERMISSION_<n>(ARG)` | 1-arg | Silent. Body decides push-down / advance consent and writes a result flag. |
| `@K{id}_BEFORETRAIN` | none | Silent. Day-start per-character state-machine setup. Read `BASE/CFLAG/TCVAR`, write `CFLAG/TCVAR` flags that other bodies will branch on. |

**Player commands**:
| Label | Runs |
|---|---|
| `@M_KOJO[%RESULTS%_]SUCCESS_COM_K{id}_{cmd}` | Optional. Set `TFLAG:192` to override (-2 end / -1 fail / 0 default / 1 great-success). Otherwise just `TFLAG:192 = 0`. |
| `@M_KOJO[%RESULTS%_]MESSAGE_COM_K{id}_{cmd}` | Per-command speech. **Convention**: starts with `CALL TRAIN_MESSAGE` (engine default narration) then `CALL <body_label>` to a `_<cmd>_1` body label. |
| `@M_KOJO[%RESULTS%_]MESSAGE_COM_K{id}_00` | **Catch-all that fires on EVERY undefined cmd**, not a "rare" fallback. If you write rich body text here, the player sees it after every R18 / unimplemented command. Default to `LOCAL = 0 / RETURN 0` (silent fall-through to engine narration) UNLESS you specifically want one identical line on every undefined cmd. |
| `@M_KOJO[%RESULTS%_]MESSAGE_SCOM_K{id}_{cmd}` | Sub-command (TFLAG:50-driven). For multi-person SCOM: `_<cmd>_1` is first participant, `_<cmd>_2` is second; engine swaps TARGET. |

**Auto-counter / idle reactions**:
| Label | Notes |
|---|---|
| `@M_KOJO[%RESULTS%_]MESSAGE_COUNTER_K{id}_{n}` | `n` = counter ID (1-100s). `CALL EVENT_COUNTER_MESSAGE` then body. |
| `@UNIQUE_COUNTER<n>_ABLE_K{id}` | Char-unique counter eligibility. `RETURN 0/1`. |
| `@UNIQUE_COUNTER<n>_FREQUENCY_K{id}` | Set `RESULTS = "<type>"` (one of: `ソフト/ベリーソフト/コミュ/着衣/脱衣愛撫/脱衣強要/抱き着き/性交/責め/おねだり`). `RETURN <freq>` (base + 10 = engine baseline). |
| `@UNIQUE_COUNTER<n>_MESSAGE_K{id}` | Print body. |
| `@UNIQUE_COUNTER<n>_SOURCE_K{id}` | Side-effects: `SOURCE:N:<slot> += N`, `CALL TOUCH_SET(...)`, `CALL DATUI_BOTTOM(...)`, etc. |

**Battle / quest / mark**:
| Label | Notes |
|---|---|
| `@M_KOJO[%RESULTS%_]MESSAGE_COM_K{id}_DANMAKU(ARGS, ARG)` | Single label. **Use `ARG` as the second-arg name, not custom `相手残機`** — Emuera's compiler rejects custom param names; only `ARG/ARG:N/ARGS/ARGS:N` are valid. Annotate purpose with a comment: `;ARG = 相手残機 (opponent remaining lives)`. Some existing kojo (K5/K6/K7) bypass this with `(ARGS, 相手残機)` + `#DIM 相手残機` immediately after — that style works but produces a Lv2 warning at load time; the simple `(ARGS, ARG)` form is preferred for new kojo. Scenes selected by `ARGS` string: `"戦闘前"`, `"ハンデ"`, `"被弾"`, `"残忍酷薄"`, `"乾坤一擲"`, `"怪力乱神"`, `"戦闘後"`. |
| `@M_KOJO[%RESULTS%_]IRAI_K{id}(ROLE, SCENE, IRAI_ID)` | Quest. `ROLE` ∈ `"CLIENT"/"TARGET"/"NO_REPORT"`. `SCENE` ∈ `"依頼提示時"/...・/"成功報告時"/"失敗報告時"`. |
| `@M_KOJO[%RESULTS%_]MESSAGE_MARKCNG_K{id}` | **Fires after EVERY action that *could* affect marks**, not only on actual mark transition. Body MUST guard with `SIF !TFLAG:21 && !TFLAG:22 && !TFLAG:23 && !TFLAG:24 && !TFLAG:時姦刻印取得 / RETURN 0` before printing anything, otherwise it spams a generic line after most actions. |

**Diary**:
| Label | Notes |
|---|---|
| `@DIARY_K{id}_EXIST` | Returns 1 to claim diary support. |
| `@DIARY_BEFORE_CHECK_K{id}` | Updates `DIARY:N:M` slot states based on game state. |
| `@DIARY_TEXT_K{id}, PAGENUM, MODE, PAGECOUNT` | Body. `MODE` ∈ `"デイリー"` (auto end-of-day) / `"指令"` (command 406). |
| `@DIARY_AFTER_CHECK_K{id}` | Per-day cleanup. |
| `@M_KOJO_MESSAGE_COM_K{id}_406` | "Read diary" command body. |

**Climax / orgasm**:
| Label | Notes |
|---|---|
| `@M_KOJO[%RESULTS%_]MESSAGE_PALAMCNG_A_K{id}` | A-tier (after-action). |
| `@M_KOJO[%RESULTS%_]MESSAGE_PALAMCNG_A2_K{id}` | A-tier secondary. |
| `@M_KOJO[%RESULTS%_]MESSAGE_PALAMCNG_B_K{id}` | B-tier (climax). Branch on `NOWEX:Ｃ絶頂/Ｖ絶頂/Ｂ絶頂/Ａ絶頂/Ｍ絶頂/射精/噴乳/放尿/TotalEX`, `SYNCED_ORGASM(N)`, `TEQUIP:Ｖ接触部位`. |
| `@M_KOJO[%RESULTS%_]MESSAGE_PALAMCNG_B2_K{id}` | B-tier secondary. |
| `@M_KOJO[%RESULTS%_]MESSAGE_PALAMCNG_F_K{id}` | F-tier fallback. |

**Child-rearing**:
| Label | Notes |
|---|---|
| `@M_KOJO_EVENT_K{id}_CHILD_RAISING_<key>` | Lifecycle milestones. `<key>` ∈ `回復/離乳/玩具/つかまり立ち/よちよち/会話寸前/喋る/語彙/しつけ/就学/自立前/自立`. |
| `@M_KOJO_EVENT_K{id}_CHILD_RAISING_<activity>(ARGS, ARG, ARG:1)` | Per-life-stage daily activities. `<activity>` ∈ `登下校/吃飯/BATH/SLEEPING/OYASUMI/TOY/OTHER`. `ARGS` = `"幼児期" / "幼少期" / "授乳" / "離乳食" / ...`. |
| `@M_KOJO_EVENT_K{id}_CHILD_DIARY_口上手紙(ARG)` / `_共通手紙(ARG, ARGS)` / `_寺子屋(ARGS, ARG, ARG:1)` | Letter / school events. |

**Info screen**:
| Label | Notes |
|---|---|
| `@CHARA_INFO_KOJO_K{id}()` | Override the 角色介绍 ("character info") tab. Body prints the description; can branch on game state. |

**Hooks (less common)**:
| Label | Notes |
|---|---|
| `@SPECIALDAY_EVENT_K{id}` | Anniversary / holiday. Branch on `DAY:2` (month) and `DAY:3` (day). |
| `@K{id}_BEFORETRAIN` (or `@M_KOJO[%RESULTS%_]_BEFORETRAIN_K{id}`) | Day-start state-machine. |
| `@RUN_INTO_K{id}(MAP_ID)` | Random encounter on map. |
| `@KOJO_SF_CONTRACT_EVENT_K{id}(ARGS)` | "Sex friend" agreement. |
| `@M_KOJO_CHECK_K{id}_IRAI_BLOCKED(ARGS, ARG, ARG:1)` | Quest-block predicate. |
| `@M_KOJO_DIARYSETTING_K{id}(ARG)` | Diary state-set helper. |

### 2.4.1 EVENT_K_X subphase reference (ARG values per slot)

The engine fires several EVENT slots **multiple times per turn** with `ARG` distinguishing the sub-phase. **If you ignore ARG**, the body fires for every sub-phase (3-5 times per visit) and the dialogue prints repeatedly. Always branch on ARG, and `RETURN 0` from each branch (so other sub-phases can match).

Authoritative ARG semantics (extracted from 001 Reimu / 霊夢 reference):

**`@M_KOJO_EVENT_K{id}_1(ARG, ARG:1)` — room/cell encounter.** Fires once **per cell transition the character makes on the same world map** as MASTER, even if MASTER is in a different cell. **Mandatory first guard:**
```erb
@M_KOJO_EVENT_K{id}_1(ARG, ARG:1)
LOCAL = 1
SIF !LOCAL || FLAG:時間停止
    RETURN 0
;Engine fires this on every NPC cell-step. Reject when not co-located:
SIF CFLAG:{id}:現在位置 != CFLAG:MASTER:現在位置
    RETURN 0
;Then branch on ARG sub-phase:
SELECTCASE ARG
    CASE 1   ;MASTER walks in, char already in room
        ...
        RETURN 0
    CASE 2   ;char walks in, MASTER already in room
        ...
        RETURN 0
    CASE 3   ;char enters bathroom while MASTER bathing — joins
        ...
        RETURN 0
    CASE 4   ;char enters bathroom, exits politely
        ...
        RETURN 0
    CASE 5   ;char enters bathroom, MASTER kicks them out
        ...
        RETURN 0
ENDSELECT
RETURN 0
```

**`@M_KOJO_EVENT_K{id}_2(ARG, ARG:1)` — morning.** Fires for every char on the same world-map as MASTER, every morning — even if char is in a different cell. **Same first guard required:**
```erb
SIF CFLAG:{id}:現在位置 != CFLAG:MASTER:現在位置
    RETURN 0
```

**`@M_KOJO_EVENT_K{id}_3(ARG, ARG:1)` — bedtime.** Same map-vs-cell distinction as `_2`. Same guard required.

For other EVENT slots (4..30+), check the corresponding body in 001 Reimu's kojo for ARG semantics; the pattern of "guard first, branch ARG, RETURN 0 per branch" applies universally.

**Why this isn't obvious from the engine source**: the dispatcher in `KOJO_MESSAGE.ERB` doesn't filter by current-cell; it filters only by *map presence*. The cell check is the kojo's responsibility. Most reference kojo include this guard but they don't emphasize it — it has to be observed by reading them.

### 2.5 The MESSAGECHECK family — a powerful and easily-overlooked dispatch hook

Before invoking any `*MESSAGE*` body, the engine *first* looks for a parallel `*MESSAGECHECK*` label. **Most kojo authors don't use this**, so don't bring it up in casual scaffolding work — but when a user asks for a *cinematic-feeling* event ("I want her line to replace the engine's default narration entirely"), this is the mechanism. The label returns a **bitfield**:
- `bit 0` = 1: suppress the engine's default narration (the "情景文本" — i.e. the `TRAIN_MESSAGE` / `EVENT_COUNTER_MESSAGE` / `MARK_MESSAGE` / `SPEVENT_MESSAGE_<n>` pre-narration).
- `bit 1` = 1: suppress the kojo's own message body.

So:
- `RETURN 0` → show both.
- `RETURN 1` → show only kojo (hide engine narration).
- `RETURN 2` → show only engine narration (hide kojo).
- `RETURN 3` → hide both (silent).

You can **also print custom narration inside the MESSAGECHECK body itself**, then return suitable bits to suppress duplication.

The complete MESSAGECHECK family (pair every message label with this if needed):

| Pair label | Where |
|---|---|
| `@M_KOJO[%RESULTS%_]MESSAGE_MESSAGECHECK_COM_K{id}_{cmd}` | Pair of `MESSAGE_COM_K{id}_{cmd}`. |
| `@M_KOJO[%RESULTS%_]MESSAGE_MESSAGECHECK_SCOM_K{id}_{cmd}` | Pair of `MESSAGE_SCOM_K{id}_{cmd}`. |
| `@M_KOJO[%RESULTS%_]SPEVENT_MESSAGECHECK_K{id}_{ev}` | Pair of `SPEVENT_K{id}_{ev}`. |
| `@M_KOJO[%RESULTS%_]EVENT_MESSAGECHECK_K{id}_{ev}` | Pair of `EVENT_K{id}_{ev}`. |
| `@M_KOJO[%RESULTS%_]MESSAGE_COUNTER_MESSAGECHECK_K{id}_{n}` | Pair of `COUNTER_K{id}_{n}`. |
| `@M_KOJO[%RESULTS%_]MESSAGE_MARKCNG_MESSAGECHECK_K{id}` | Pair of `MARKCNG_K{id}`. |
| `@M_KOJO[%RESULTS%_]DAILY_EVENT_MESSAGECHECK_K{id}_{n}` | Pair of `DAILY_EVENT_K{id}_{n}`. |
| `@M_KOJO[%RESULTS%_]MESSAGE_PALAMCNG_MESSAGECHECK_A_K{id}_{n}` | Pair of `PALAMCNG_A_K{id}`. |
| `@M_KOJO[%RESULTS%_]MESSAGE_PALAMCNG_MESSAGECHECK_A2_K{id}_{n}` | Pair of `PALAMCNG_A2_K{id}`. |
| `@M_KOJO[%RESULTS%_]MESSAGE_PALAMCNG_MESSAGECHECK_B_K{id}_{n}` | Pair of `PALAMCNG_B_K{id}`. |

These are optional. Use when you want to suppress the engine's default "X 说着话。" header on a particular line — common for cinematic cutscenes.

### 2.6 The EXTRASOURCE family

After a message body runs, the engine looks for an EXTRASOURCE label to apply additional `SOURCE:N:<slot>` ledger updates:

| Label | Runs |
|---|---|
| `@M_KOJO[%RESULTS%_]EXTRASOURCE_COM_K{id}_{cmd}` | After per-command. |
| `@M_KOJO[%RESULTS%_]EXTRASOURCE_COM_K{id}_GENERAL` | Catch-all. |
| `@M_KOJO[%RESULTS%_]EXTRASOURCE_SCOM_K{id}_{cmd}` | After per-SCOM. |
| `@M_KOJO[%RESULTS%_]EXTRASOURCE_SCOM_K{id}_GENERAL` | Catch-all. |

Use when you want to apply different SOURCE deltas based on player state without scattering the logic across many command bodies.

### 2.7 The new "custom" API (modern engines only)

Some characters ship a `カスタム.ERB` (or `of_new_kojo_api.ERB`) file using an **extended dispatch family for author-defined custom commands and UI buttons**. This is supported only by recent engine versions. Wrap your file in `[SKIPSTART]/[SKIPEND]` if your kojo must run on older engines.

| Label | Role |
|---|---|
| `@KOJO_CUSTOM_BUTTON_CONDITION_K{id}_{Y}` | Returns 1 to show button `Y` (range 0-9). Sets `custom_button_name:{id}:{Y} = "<label>"`. |
| `@KOJO_CUSTOM_BUTTON_K{id}_{Y}` | Click handler for button `Y`. |
| `@KOJO_CUSTOM_TALENT_SET_K{id}` | Populates `CUSTOM_TALENT:{id}:{slot}` + `_NAME` + `_COLOR` (0=normal/1=pink/2=red+bold) + `_TYPE` (1=race/2=sexual/3=physical/4=mental/5=technical/0=other). Renders in 角色介绍 tab. |
| `@KOJO_COM_NAME_K{id}_{Y}` | Returns command name string in `RESULTS`. `Y` is 0..9. |
| `@KOJO_COM_ABLE_K{id}_{Y}` | Returns 1 if command `Y` is currently usable. |
| `@KOJO_COM_K{id}_{Y}` | Body. Returns 1 = execute, 0 = cancel-but-keep-source, -1 = cancel-and-skip-source. |
| `@KOJO_CAN_COM_K{id}_{Y}` | Predicate for queue-ability. |
| `@KOJO_VERSION_K{id}` | Returns this character's kojo version (semantic). |
| `@KOJO_VERSION_UPDATE_K{id}` | Save-game migration hook. |

Custom commands map onto engine command space at offset `270 + Y` (so custom 0 = command 270). After hook, the message body uses standard `@M_KOJO_MESSAGE_COM_K{id}_{270+Y}` form.

### 2.8 The kojo selector (RESULTS infix) — and how multi-variant works

A character directory may contain **multiple author-variant subdirectories** at the same time:

```
個人口上/049 Satori [さとり]/
├── さとり/                          ← variant A
├── さとり(24.5.14)/                 ← variant B
└── 古明地觉_试制口上v0.053/        ← variant C
```

The engine loads **all of them** at startup — every `.ERB` is parsed and every `@LABEL` exists in memory. The question is then: when the engine wants to dispatch a kojo line for Satori, *which variant's labels does it call?* That's what the **kojo selector** is for.

#### How the selector works

In each variant's existence-check label, the author sets a unique selector string:

```erb
;In variant A's M_KOJO_K49_イベント.ERB:
@M_KOJO_K49(ARG)
RESULTS = _ORTHODOX
RETURN 1

;In variant B's M_KOJO_K49_イベント.ERB:
@M_KOJO_K49(ARG)
RESULTS = _2024_05_14
RETURN 1
```

(Or — to coexist without colliding — each variant uses a different versioned existence label like `@M_KOJO_K49_2(ARG)` / `@M_KOJO_K49_3(ARG)`. The engine checks both.)

Then **every other label in that variant must be prefixed** with the same selector:

```erb
;In variant A:
@M_KOJO_ORTHODOX_FLAGSETTING_K49           ← prefix matches RESULTS
@M_KOJO_ORTHODOX_EVENT_K49_1(ARG, ARG:1)
@M_KOJO_ORTHODOX_MESSAGE_COM_K49_300

;In variant B:
@M_KOJO_2024_05_14_FLAGSETTING_K49         ← different prefix
@M_KOJO_2024_05_14_EVENT_K49_1(ARG, ARG:1)
```

The engine's dispatch templates expand `%RESULTS%` at runtime to whichever selector is currently active for that character, so it ends up calling exactly the right variant's labels.

#### So which variant is "active"?

The currently-active variant for character N is stored in `CFLAG:N:口上セレクタ` (a small integer). The engine reads it at the start of each dispatch:

- If `CFLAG:N:口上セレクタ == 0` (default), the engine calls `@M_KOJO_K{N}(ARG)` and uses whatever `RESULTS` it sets.
- If `CFLAG:N:口上セレクタ == V` (some version number), the engine calls `@M_KOJO_K{N}_<V>(ARG)` instead, and uses *that* version's `RESULTS`.

This means: **only one variant runs at a time per character**, even though all variants are loaded into memory. Players (or installers) flip `CFLAG:N:口上セレクタ` to choose. Most users only install one variant per character anyway.

#### Selectors are optional

If a character only has one variant, **leave the selector empty** (don't set `RESULTS` in the existence check). The engine then expands `%RESULTS%` to the empty string and dispatches `@M_KOJO_FLAGSETTING_K{id}`, `@M_KOJO_MESSAGE_COM_K{id}_300`, etc. — the standard naming. **This is the case ~95% of the time.**

Only set a non-empty selector if you specifically want to ship alongside a competing version of the same character without label collisions.

#### Practical advice for you (the helper LLM)

When the user says "I want to write a kojo for Reimu":

- Default: write with no selector. All labels start with `@M_KOJO_<KIND>_K1_<n>`.
- If the user mentions another author's existing kojo for the same character ("I want it to coexist with the official one"), then introduce a selector — name it after the user or their version (e.g. `_USER_NAME` or `_v01`).
- If the user is editing an existing kojo file that already uses a selector, **match it**. Don't strip the selector or add a new one. Look at the existence check to see what's there.

---


---

## Author-extension idioms

### 10.1 Function library

Put `#FUNCTION` / `#FUNCTIONS` definitions in `M_KOJO_K{id}_関数ライブラリ.ERB` (or `Lib/`). The author's `K{id}_*` functions are private namespace; bodies call them via `K{id}_FOO()` and `%K{id}_BAR()%`.

Example (Tsukasa K139 has these; pattern is common):

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
        ; how Tsukasa calls MASTER
        SIF TALENT:139:恋人
            RETURNF MASTERNAME:139
        RETURNF MASTERNAME:139 + "桑"
    CASEELSE
        RETURNF CALLNAME:ARG + "さん"
ENDSELECT
```

### 10.2 Special-events library

`M_KOJO_K{id}_<charname>特殊イベント.ERB` — standalone `@K{id}_<NAME>` labels:

```erb
;CALL K139_PREG_WISH
;==========================================================================================
;子どもがほしいな
;==========================================================================================
@K139_PREG_WISH
PRINTFORML <event-intro-line>
CALL ASK_YN("yes-text", "no-text")
IF !RESULT
    ; player accepted
    PRINTFORMW <success-line>
    TALENT:139:妊娠願望 = 1
ELSE
    PRINTFORML <decline-line>
ENDIF
RETURN 1
```

Invoke from elsewhere:

```erb
;in some daily-event body:
SIF <conditions ripe>
    CALL K139_PREG_WISH
```

### 10.3 Char-unique counter

`K{id}_固有カウンター<n>_<name>.ERB`:

```erb
@UNIQUE_COUNTER1_ABLE_K{id}
SIF TFLAG:62
    RETURN 0
SIF ABL:[[<charname>]]:欲望 < 5
    RETURN 0
RETURN 1

@UNIQUE_COUNTER1_FREQUENCY_K{id}
RESULTS = 脱衣愛撫            ; type-key
RETURN 10                     ; baseline frequency

@UNIQUE_COUNTER1_MESSAGE_K{id}
PRINTFORML <message-body>

@UNIQUE_COUNTER1_SOURCE_K{id}
;side-effects:
SOURCE:[[<charname>]]:性行動 += 150
SOURCE:[[<charname>]]:誘惑 += 200
;optionally:
;CALL TOUCH_SET(SET_FROM_YUBI, 1, [[<charname>]])
;CALL EVENT_COUNTER_POSE_69([[<charname>]], 2)
```

### 10.4 SOURCE — the post-action affection ledger

This is the most commonly missed pattern. **Every counter / unique-counter body should write to SOURCE.** Otherwise the kojo prints text but doesn't shift affection.

Slots: `性行動, 露出, 逸脱, 与快Ｃ, 誘惑, 侮辱, 挑発, 加虐, 征服, 情愛, 反感, 歓楽, 達成, 愛情経験`. Authors pick relevant slots and add small-to-large positive (or negative) deltas.

### 10.5 Multi-person SCOM dispatch

```erb
@M_KOJO_MESSAGE_SCOM_K<id>_<n>
    CALL TRAIN_MESSAGE
    CALL M_KOJO_MESSAGE_SCOM_K<id>_<n>_1     ; first participant body
    LOCAL = MASTER_POSE(<role>, 1, 1)         ; resolve 2nd participant id
    LOCAL:1 = RESULT
    LOCAL:2 = TARGET
    TARGET = LOCAL
    TRYCALLFORM M_KOJO_MESSAGE_SCOM_K{TARGET}_<n>_2   ; their version of _2
    TARGET = LOCAL:2
    RETURN LOCAL:1
```

The engine swaps `TARGET` to the 2nd participant and dispatches **into their kojo**. So your `_2` body might be called from another character's `_1`. Bodies must use `TARGET` consistently.

---

