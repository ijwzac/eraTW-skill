# eraTW kojo (口上) Writing Guide — for LLMs Helping Users

This document is meant to be loaded into another LLM's context as a complete reference for helping a human user write or modify "口上" (kojo, character-dialogue files) for the game **eraTW**. It is engineered for SOTA reasoning models to consume directly — fields are flat and explicit, the contract is concrete, and there are no surprises.

---

## 0. Read this section first — Your role and limits

### 0.1 What this is

eraTW is a Japanese command-line text RPG built on the **Emuera** interpreter, a pre-existing era-script DSL. It features ~150 Touhou Project characters with whom the player ("MASTER") interacts. **A "kojo" (口上) is the *per-character dialogue + behavior script*** — one or more `.ERB` files that the engine dispatches into when something happens with that character.

Users want help writing kojo for their favorite character. They write the *dialogue and rough event descriptions* in plain English / Chinese / Japanese. **Your job is to translate those descriptions into the concrete labels, control flow, and file taxonomy that the engine expects.** You handle the structure. The user handles the content.

### 0.1.1 Language of the user, language of the output

**The user is almost certainly Chinese.** They will phrase requests in Chinese (sometimes mixed with Japanese terms borrowed from the original game, like `恋慕`, `親密`, `推倒`, `约会`, etc.). **Reply to the user in Chinese.** Address them in Chinese, explain decisions in Chinese, ask follow-up questions in Chinese.

**More importantly, the dialogue and prose you generate inside the kojo files must be in Chinese** — this is what the player sees on screen. The existing kojo corpus is largely Chinese-translated (see `灵梦/小悪魔/极/觉/典` etc. in the in-game text), so new content should match. Exceptions where mixed-language text is natural:

- Engine identifiers — labels (`@M_KOJO_*`), keywords (`IF/ELSE/RETURN`), CFLAG/TFLAG slot names — stay as the original Japanese / English (e.g. `CFLAG:N:時間停止口上有`, `TALENT:恋慕`). **Do not translate these**; the engine uses them as keys.
- Onomatopoeia, exclamations, "♥", and Japanese-style sigh-particles (`はぁ`, `んっ`) are commonly kept as-is for stylistic flavor — match the existing kojo's style.
- Quotations from the original Touhou source material may stay Japanese when the user explicitly wants the canonical line.
- Author memos (`readme.txt`, `フラグ管理メモ.txt`) can be in any language the user prefers.

In short: **structural identifiers stay Japanese (engine-required); player-visible prose is Chinese; comments and memos follow the user's preference**.

### 0.2 What this is NOT

This game *does* contain adult content as a feature, including categories like "sexual harassment commands," "sex commands," and others. **You are not generating that content.** Your job is to produce:

- The **right label names** so the engine dispatches.
- The **right control flow** (`IF`/`SELECTCASE`/`RAND`/etc.) so branches fire on the right conditions.
- The **right file organization** so the kojo loads.
- **Placeholder prose** when needed (one-line `;TODO: <description>` is plenty).

If a user asks you to generate explicit prose, redirect: "I'll write the structural skeleton with placeholders; you fill in the lines you want." That keeps you firmly in the role of *structural assistant for an existing game*, not *content generator*.

For non-adult parts of kojo (most daily commands, events, info-screen, diary, child-rearing, danmaku, conversation, etc.), generating actual prose is fine — that's the "galgame writing" the user is doing.

### 0.3 What you should be able to do after reading this

1. Given a character ID (1-159) and a name, scaffold the complete file set for a new variant.
2. Given a description like "she wakes up next to MASTER and is embarrassed," locate the right label slot, write the body with the right guards, and emit `PRINTFORML` lines.
3. Given an existing kojo and "make her say something different on rainy days," modify the right body and add `IF GROUPMATCH(TIME:5, 4, 5, 6, 7)` guard.
4. Identify why a kojo isn't firing (often: missing `RETURN 1` in existence check, wrong selector, label name typo).
5. Recommend the right tier of complexity (basic / rich / extreme) for the user's ambition.
6. Translate "I want her to react to me using time-stop on her sister" into `IF FLAG:70 && CFLAG:36:時間停止口上有 && EXP:36:60..63` guard logic.

### 0.4 If a user uploads files — do not read content closely

The user may share their existing kojo or other characters' kojo for reference. **Read them for structure, not content.** Bodies that contain explicit prose: skim only enough to recognize the surrounding control flow and file role. Quote at most 1-2 lines of dialogue when essential.

### 0.5 Most-common first-pass mistakes — read every time

These are the bugs we see in nearly every first-pass kojo generation. Each one is detailed in its own section later, but you must hold them in your head while writing:

1. **`@FOO(ARG, TYPE = 0)` will not compile.** Emuera only accepts positional `ARG / ARG:N / ARGS / ARGS:N` parameter names. Custom names like `TYPE`, `相手残機`, `OPTION` raise a Lv2 warning and the variable becomes unreadable inside the body. Use `@FOO(ARG, ARG:1 = 0)` and (optionally) `TYPE = ARG:1` as an alias on the first line of the body. → §3.1
2. **`[[X]]` silently compiles to `0` when X is not in `STR.csv`.** Most character names — `[[アリス]]`, `[[ルナサ]]`, `[[メルラン]]`, `[[幽々子]]`, `[[ライコ]]`, etc. — are NOT in `STR.csv`, so `CASE [[ルナサ]]` becomes `CASE 0` and matches ARG=0 by accident. **Default to numeric IDs with comments**: `CASE 22  ;ルナサ`. Reserve `[[X]]` for names you've grep-confirmed in `STR.csv`. → §3.7
3. **`MASTER`, `TARGET`, `PLAYER`, `ASSI` are bare identifiers, not `[[MASTER]]`.** Writing `[[MASTER]]` produces a warning. → §3.7
4. **`@M_KOJO_EVENT_K{id}_1(ARG, ARG:1)` fires once PER CELL TRANSITION** the character makes anywhere on MASTER's current world map, not "once when entering MASTER's room." A char walking bedroom→corridor→dining will print 3 dialogue lines while MASTER is still asleep. **Mandatory first guard: `SIF CFLAG:{id}:現在位置 != CFLAG:MASTER:現在位置 / RETURN 0`.** Then branch on ARG sub-phase (1=MASTER walks in, 2=char walks in, 3-5=bath sub-phases). Same applies to `_2` (morning) and `_3` (sleep). → §2.4.1
5. **`@M_KOJO_EVENT_K{id}_GRAVITY` is a SILENT NPC-AI movement attractor**, not a "gravity event." It fires every NPC-movement-decision tick (many times per turn). The body must set `TCVAR:{id}:引力点 = <location-code>` and **must not call any `PRINT*`**. → §2.4
6. **`@M_KOJO_MESSAGE_COM_K{id}_00` fires on EVERY undefined cmd**, not "rarely." Default to `LOCAL = 0 / RETURN 0` (silent) unless you specifically want one identical line on every undefined cmd. → §2.4
7. **`@M_KOJO_MESSAGE_MARKCNG_K{id}` fires after every action that *could* affect a mark**, not only on mark transitions. Body must guard `SIF !TFLAG:21 && !TFLAG:22 && !TFLAG:23 && !TFLAG:24 && !TFLAG:時姦刻印取得 / RETURN 0` before printing. → §2.4
8. **`CFLAG:N:约会中` is a MAIN_MAP code, not a boolean.** After any first date, the slot is permanently non-zero. `IF CFLAG:N:约会中` is always-true thereafter. The canonical "currently dating with this character" predicate is `CHK_DATENOW(CFLAG:MASTER:约会中) && FLAG:约会的对象 == TARGET`. → §5.5
9. **Slot names must match the actual CSV byte-for-byte.** This fork uses simplified-Chinese in many CFLAG names (`约会中`, `历史` etc.) — Japanese-kanji forms like `約会中` *do not resolve*. Some slot names that "look canonical" (`BASE:N:疲労`, `TFLAG:逢瀬時間`) **don't exist in this fork's CSVs**. → §0.6 verification pass
10. **Files must be UTF-8 with BOM**, ideally CRLF. Without BOM, Chinese characters in some string contexts silently break. Write tools default to LF/no-BOM; prepend BOM after every write/edit. → §0.6
11. **Display name in `CSV/Chara/Chara<N> *.csv` must match what your kojo prose calls the character.** The engine prints `%CALLNAME:N%` from CSV — if your prose calls her "莉莉卡" but the CSV says "莉莉喀", the player sees both inconsistently. Check `名前` and `呼び名` rows before authoring; edit CSV if you want a different display name. → §0.6
12. **An early-return `IF` branch suppresses everything below it.** Bodies that gate broad conditions (room class, weather, time-of-day) at the top of a cascade will block all the rich relationship content for most of the game. RAND-gate broad conditions, or move them inside the relationship branches as flavor sub-conditions, instead of as early-return blockers.

### 0.6 Verification pass (run before declaring done)

After scaffolding a new kojo, before handing back to the user, verify:

```bash
# Adjust paths to match the user's install
DIR="<kojo variant dir, e.g. ERB/口上・メッセージ関連/個人口上/100 Rei'sen [レイセン]/myvar>"
CSVDIR="<root>/CSV"

cd "$DIR"

echo "=== [[ ]] symbols not in STR.csv (will silently become 0) ==="
grep -hoE "\[\[[^]]+\]\]" *.ERB | sort -u | while read s; do
    name="${s:2:-2}"
    grep -qE ",${name}\b" "$CSVDIR/STR.csv" || echo "MISSING: $s"
done

echo "=== Custom-named function parameters (must be ARG/ARG:N/ARGS/ARGS:N only) ==="
grep -nE "^@.*\([A-Za-z_][A-Za-z0-9_]*\s*=" *.ERB | \
    grep -vE "ARG(:[0-9]+)?\s*=" | grep -vE "ARGS(:[0-9]+)?\s*="

echo "=== Unverified CFLAG/TFLAG/TCVAR slot names (must exist in CSV) ==="
grep -hoE "(CFLAG|TFLAG|TCVAR):([A-Z]+:)?[^a-z0-9 :,()<>=&|!*+\r\n_-]+\b" *.ERB | \
    sed -E 's/^(CFLAG|TFLAG|TCVAR):([A-Z]+:)?//' | sort -u | while read slot; do
    grep -qF ",${slot}" "$CSVDIR"/{CFLAG,TFLAG,TCVAR}.csv || echo "MISSING: $slot"
done

echo "=== Files missing UTF-8 BOM ==="
for f in *.ERB; do
    head -c 3 "$f" | xxd -p | grep -q "efbbbf" || echo "$f"
done

echo "=== EVENT_K_X bodies missing the same-cell guard ==="
grep -l "@M_KOJO_EVENT_K[0-9]\+_[123](" *.ERB | while read f; do
    grep -qE "現在位置.*!=.*MASTER:現在位置" "$f" || echo "$f: missing 現在位置 != MASTER:現在位置 guard"
done
```

If any check fails, fix and re-run. **Re-run after every Edit pass** because tools sometimes strip BOM on rewrite.

---

## 1. The big picture

```
eraTW/
├── ERB/                    ; all game logic (the *.ERB scripts)
│   ├── 口上・メッセージ関連/
│   │   ├── KOJO_MESSAGE.ERB        ; the dispatcher (engine code, don't modify)
│   │   ├── COMMON_KOJO.ERB         ; library helpers
│   │   ├── EVENT_MESSAGE*.ERB      ; engine-default narration
│   │   └── 個人口上/                ; YOUR DOMAIN: per-character kojo
│   │       ├── 001 Reimu [霊夢]/
│   │       │   └── <variant1>/
│   │       │       ├── M_KOJO_K1_イベント.ERB
│   │       │       ├── M_KOJO_K1_日常系コマンド.ERB
│   │       │       └── ... ~10-25 files
│   │       ├── 002 Ruukoto [る～こと]/
│   │       └── ...
│   ├── COMMON.ERB          ; engine code
│   ├── BATTLE.ERB
│   ├── 天候*.ERB            ; weather subsystem (a "plugin" example)
│   └── ...                 ; many other system files
├── CSV/                    ; static data (tables)
│   ├── CFLAG.csv           ; CFLAG slot → human name dictionary
│   ├── TFLAG.csv           ; TFLAG slot → name
│   ├── TCVAR.csv
│   ├── Talent.csv          ; talent slots (恋慕, 思慕, 処女, …)
│   ├── Abl.csv             ; ability slots (親密, 欲望, Ｂ感覚, …)
│   ├── Mark.csv            ; imprint/mark slots
│   ├── Item.csv            ; items
│   ├── Equip.csv           ; equipment slots
│   ├── Train.csv           ; training-command IDs
│   ├── Chara/              ; per-character static data CSVs
│   │   ├── Chara1 霊夢.csv
│   │   ├── Chara2 る～こと.csv
│   │   └── ... (one per character)
│   └── ...
├── dat/                    ; small binary saves
├── sav/                    ; player save files
├── resources/              ; sprite / portrait images (.webp, .png), 顔.CSV
├── font/, sound/, lang/    ; assets / localization
├── Emuera*.exe             ; the engine binaries (multiple variants)
└── emuera.config, README*  ; engine config / readmes
```

**Key insight**: there's no plugin manifest. The engine scans `ERB/` recursively at load time; *adding a new file is the entire installation*. To install a new kojo variant, the user drops the variant directory into `個人口上/<id> <name>/` — no further setup.

---

## 2. The engine ↔ kojo dispatch contract

### 2.1 The mental model

There are two kinds of code in this game and you must keep them separated in your head:

1. **Engine code** — `KOJO_MESSAGE.ERB`, `EVENT_MESSAGE*.ERB`, etc. **You never write or modify these.** They came with the game and they implement the dispatch loop.
2. **Kojo code** — files under `個人口上/<id> <name>/<variant>/M_KOJO_K<id>_*.ERB`. **This is what you write.** The engine reaches into these files looking for **specific label names** and calls whichever ones it finds.

The contract between the two is just a **list of label names**. The engine declares: *"if you define `@M_KOJO_MESSAGE_COM_K1_300`, I will call it whenever the player uses command 300 on character 1 (Reimu)."* You define the labels you care about; the engine ignores the rest.

So as a kojo author **you do not write `TRYCALLFORM ...`** — that line lives inside the engine and is not your concern. You only write `@LABEL_NAME` definitions. The engine reads the list of well-known label names (catalog in §2.3 below) and calls them.

### 2.2 The dispatch flow, step-by-step

Concrete walk-through of what happens when the player uses command 300 (会話 = "talk") on character ID 1 (Reimu):

1. The engine processes the player input and decides "this is a COMMAND on TARGET=1 with command-id=300".
2. Engine calls its internal function `@KOJO_MESSAGE_SEND("COMMAND", 300, 1, ...)`.
3. Inside that function (in `KOJO_MESSAGE.ERB`), the engine **constructs a label name from a template** and tries to call it:
   ```
   TRYCALLFORM M_KOJO%RESULTS%_MESSAGE_COM_K{NO:TARGET}_{ARG:1}
                       ↓                 ↓             ↓
                       (selector,        K1            300       → label resolves to:
                        usually empty)                            @M_KOJO_MESSAGE_COM_K1_300
   ```
   `TRYCALLFORM` is the engine's "try to call this label, but stay silent if it's not defined" command.
4. If you defined `@M_KOJO_MESSAGE_COM_K1_300` in your kojo files, the engine runs your body. If you didn't, the engine silently moves on to a fallback (a generic `_00` label, then engine-default narration).

That's the whole magic. The engine names labels using a few build-rules (one per dispatch kind — see catalog in §2.3); you provide the labels you want to populate. **You never write `TRYCALLFORM`. You write `@`-prefixed label definitions.**

### 2.2.1 What ARG, ARG:1, ARG:3 etc. mean (positional arguments)

When the engine constructs a label name, some of its inputs go into the *name*; others get passed as **positional arguments to the body**:

```
TRYCALLFORM M_KOJO_EVENT_K1_5(ARG:3, ARG:4)
                          ↓   ↓     ↓
                          K=1 then ARG:3 and ARG:4 are passed as positional args
                          event=5
```

The engine has an `ARG`/`ARG:1`/`ARG:2`/... namespace internally to hold all the input fields. When constructing the label, it puts some into the *name string* (for label dispatch) and forwards the rest as positional arguments. **You don't define `ARG:3`/`ARG:4`; the engine fills them.** Your job is to **receive and read** them in your label header:

```erb
@M_KOJO_EVENT_K1_5(ARG, ARG:1)
;       ^                  ^
;       Reimu              you receive ARG (engine's ARG:3) and ARG:1 (engine's ARG:4)

;Body — read ARG to decide which sub-state of event 5 we're in:
IF ARG == 0
    PRINTFORML 「<line for ARG=0 — e.g. propose>」
ELSEIF ARG == 1
    PRINTFORML 「<line for ARG=1 — e.g. accept>」
ENDIF
RETURN 1
```

What each positional `ARG` means **depends on the dispatch kind**: for SPEVENT, `ARG` is usually a sub-state code (0=propose, 1=accept, 2=reject); for EVENT, `ARG` is documented per slot; for child-rearing `(ARGS, ARG, ARG:1)`, `ARGS` is the life-stage string. The catalog in §2.3 documents what each label's args mean.

### 2.3 The dispatch kinds (which engine event you can hook)

Here's the full list of `ARGS` keys the engine uses internally — each one corresponds to a *family of label names* the engine tries to call:

| ARGS | When it fires | Label families it builds |
|---|---|---|
| `"ENCOUNTER"` | First-meeting cutscene. | `@M_KOJO_ENCOUNTER_K{id}` |
| `"SP_EVENT"` | One-shot scripted events (kiss after date, confession, …). | `@M_KOJO_SPEVENT_K{id}_{ev}(ARG, ARG:1)` |
| `"EVENT"` | Generic events (room entry, morning, sleep, …). | `@M_KOJO_EVENT_K{id}_{ev}(ARG, ARG:1)` |
| `"COMMAND"` | Player chose a command. | `@M_KOJO_MESSAGE_COM_K{id}_{cmd}` (and `_SUCCESS_COM_*`, `_MESSAGE_SCOM_*`) |
| `"COUNTER"` | Counter / idle reaction. | `@M_KOJO_MESSAGE_COUNTER_K{id}_{n}` |
| `"PALAM"` | After-action stat-change reaction (pre-orgasm). | `@M_KOJO_MESSAGE_PALAMCNG_A/A2/B/B2/F_K{id}` |
| `"MARK"` | Mark / imprint acquired. | `@M_KOJO_MESSAGE_MARKCNG_K{id}` |
| `"DIRECT"`, `"SUCCESS"`, `"ENDING"` | Misc / endings. | (engine-internal) |
| `"ONABARE"` | "Outburst" — reaction to a previous violation. | `@M_KOJO_EVENT_K{id}_ONABARE_<n>(ARG)` |
| `"PERMISSION"` | Push-down consent check. | `@M_KOJO_EVENT_K{id}_PERMISSION_<n>(ARG)` |
| `"LOST_VIRGIN_STOP"` | Mid-action virginity-loss interrupt. | `@M_KOJO_EVENT_K{id}_LOST_VIRGIN_STOP(ARG)` |
| `"CHILD"` | Child-rearing event. | `@M_KOJO_EVENT_K{id}_CHILD_RAISING_<key>` |
| `"DANMAKU"` | Bullet-hell duel. | `@M_KOJO_MESSAGE_COM_K{id}_DANMAKU(ARGS, 相手残機)` |
| `"IRAI"` | Quest dialogue. | `@M_KOJO_IRAI_K{id}(ROLE, SCENE, IRAI_ID)` |
| `"GIFT"` | Gift-receipt reaction. | `@M_KOJO_EVENT_K{id}_GIFT(ARG, ARG:1)` |
| `"DAILY"` | Daily event. | `@M_KOJO_DAILY_EVENT_K{id}_{n}(ARG, ARG:1, ARG:2, ARG:3, ARG:4, ARGS:1, ARGS:2)` |
| `"DIARY"` | Diary read. | `@DIARY_K{id}_EXIST`, `@DIARY_TEXT_K{id}, ...`, `@M_KOJO_MESSAGE_COM_K{id}_406` |
| `"MUSHI_BATTLE"` | Insect battle. | `@M_KOJO_MESSAGE_COM_K{id}_MUSHI_BATTLE` |
| `"GRAVITY"` | Gravity-anomaly event. | `@M_KOJO_EVENT_K{id}_GRAVITY` |
| `"SUIKA"` | Suika/festival event. | `@M_KOJO_MESSAGE_COM_K{id}_SUIKA` |
| `"ODEKAKE"` | Going-out / date-related. | (event-style) |
| `"SEX_FRIEND"` | Sex-friend ("炮友") contract event. | `@KOJO_SF_CONTRACT_EVENT_K{id}(ARGS)` |
| `"BEFORETRAIN"` | Pre-training hook. | `@K{id}_BEFORETRAIN` |

The detailed catalog of every label form, what each ARG means, and what to put in the body — that's the rest of this section.

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

## 3. The DSL (Emuera-script) — primer

### 3.1 Variables and arrays

```erb
LOCAL = 1                  ; numeric local — auto-allocated
LOCAL:1 = 5                ; second slot of LOCAL array
LOCALS = "hello"           ; string local
LOCALS:1 = "world"

#DIM CONST K_FOO = 1100    ; compile-time constant
#DIM 知り合い, 6 = 29, 65, 51, 49, 38, 1   ; array literal init
#DIM SAVEDATA RAGE_GAUGE   ; per-char persistent across saves
#DIMS SAVEDATA NICKNAME    ; same, string
#DIM SAVEDATA GLOBAL G     ; globally persistent (use sparingly)
#LOCALSIZE 200             ; expand local array
```

**Default args** (positional only — Emuera does NOT allow custom parameter names):
```erb
@MY_HELPER(ARG, ARG:1 = 0)
;ARG:1 defaults to 0 if caller omits it
;          ─────────
;          MUST be ARG / ARG:N / ARGS / ARGS:N — custom names like
;          `TYPE`, `OPTION`, `相手残機` raise compile warning
;          "参数错误:变量"X"未在此函数中定义" and the variable becomes
;          unreadable inside the body.
;
;If you want named-style readability inside the body, alias at the top:
;@MY_HELPER(ARG, ARG:1 = 0)
;TYPE = ARG:1
;... use TYPE freely below ...
```

A few legacy kojo (K5, K6, K7) use the workaround `@FOO(ARGS, 相手残機)` followed by `#DIM 相手残機` immediately after — this compiles and runs but produces a Lv2 warning at load. Don't replicate that style for new kojo; use positional + alias.

**Function markers** — for callable functions inside expressions:
```erb
@MY_INT_FUNC()
#FUNCTION
RETURNF 42

@MY_STR_FUNC()
#FUNCTIONS
RETURNF "hello"
```

Use site: `IF MY_INT_FUNC() > 0 ...`, `PRINTFORML 「%MY_STR_FUNC()%」`.

### 3.2 Control flow

```erb
IF cond
ELSEIF cond
ELSE
ENDIF

SIF cond                    ; single-line: applies to next stmt only
    PRINTFORML something

SELECTCASE expr
    CASE 0, 2, 4            ; multiple match
    CASE 5 TO 10            ; range
    CASE Is >= 100          ; comparison
    CASEELSE
ENDSELECT

FOR LOCAL, 0, 10            ; end EXCLUSIVE — runs 0..9
NEXT
WHILE cond
WEND
BREAK
CONTINUE

$LOOP                       ; goto label
... 
GOTO LOOP                   ; jumps to $LOOP

[SKIPSTART]                 ; preprocessor: skip
... (commented-out source)
[SKIPEND]
```

### 3.3 Calls

```erb
CALL MY_LABEL                       ; invoke; ignores any return
CALLF MY_INT_FUNC(args)             ; invoke #FUNCTION
TRYCALL MY_LABEL                    ; silent on missing
CALLFORM SOME_PREFIX{LOCAL}_SUFFIX  ; build name dynamically
TRYCALLFORM ...                     ; silent on missing dynamic
TRYCCALLFORM ... CATCH ... ENDCATCH ; try/catch dynamic
RETURN 1                            ; return numeric from a body
RETURN                              ; void return
```

### 3.4 Output

```erb
PRINTFORML 「这是一句日语风的台词%CALLNAME:MASTER%」    ; format + line
PRINTFORMW <text>                                       ; format + WAIT for keypress
PRINTL <text>                                           ; non-format line
PRINTW <text>                                           ; non-format wait
PRINTFORMD <text>                                       ; format, descriptive (no narration prefix)
PRINTFORMDL <text>                                      ; format, descriptive, line
PRINTFORMDW <text>                                      ; format, descriptive, wait

PRINTDATA                                              ; engine picks ONE at random
    DATAFORM 选项一
    DATAFORM 选项二
    DATAFORM 选项三
ENDDATA
PRINTDATAW                                              ; same with wait
PRINTDATAL                                              ; same with line

PRINTBUTTON @"按钮文字", @"按钮按下后RESULTS的值"
```

### 3.5 Color

```erb
SETCOLOR C_CREAM                ; named: C_CREAM, C_AQUA, C_PINK, C_DEFCOLOR, C_HTML
SETCOLOR 0xFF69B4               ; hex
SETCOLOR 255, 105, 180          ; RGB
RESETCOLOR
```

### 3.6 String interpolation forms

| Form | Purpose |
|---|---|
| `%CALLNAME:N%` | display-name of char N (or `MASTER`/`PLAYER`/`TARGET`). |
| `%MASTERNAME:N%` | per-char nickname for MASTER (mutable). |
| `%CHILDNAME:char:idx%` | child name. |
| `%TEXTR("a/b/c/d")%` | random pick. |
| `%UNICODE(0xN)%` | unicode char (`0x2665` = ♥). `* N` repeats. |
| `\@ <expr> ? <a> # <b> \@` | inline ternary. |
| `%CSVCSTR(N, slot)%` | per-char CSV string lookup. |
| `%CSTR:N:slot%` | per-char mutable string. |
| `%CALLNAME:N%`, `%PANTSNAME(EQUIP:..., N)%`, `%CLOTHNAME(slot, EQUIP:N:slot)%`, `%OPPAI_DESCRIPTION(N, 1)%` | engine helpers. |
| `%K{id}_<func>(args)%` | call author's `#FUNCTIONS` and interpolate. |

### 3.7 Special tokens

- `[[<name>]]` — parse-time char-id lookup (e.g. `[[極]]` → 42). **Important quirks:**
  - **`[[X]]` only resolves names in `CSV/STR.csv`**, NOT names in `CSV/Chara/Chara<N> *.csv`. Most character names you'd think to use (`[[アリス]]`, `[[ルナサ]]`, `[[メルラン]]`, `[[幽々子]]`, `[[ライコ]]`, etc.) **are not in STR.csv** even though their CSV files exist. They fail silently — `[[X]]` becomes literal `0` when unresolved, so `CASE [[ルナサ]]` becomes `CASE 0` and matches ARG=0.
  - **`MASTER`, `TARGET`, `PLAYER`, `ASSI` are built-in numeric pseudo-constants** — write them bare, never as `[[MASTER]]` (which is wrong and produces a warning).
  - **Recommended default**: use the numeric char ID with a comment explaining the ID, e.g. `CASE 22  ;ルナサ Lunasa`. This always works and is more readable when grepping. Reserve `[[X]]` for names you've verified are in `STR.csv` (mostly location names and a small set of major chars like `[[極]]`/`[[文]]`).
  - **To verify** before using `[[X]]`: grep `STR.csv` for the exact name (byte-exact, including kanji-form). If it doesn't appear, fall back to numeric ID + comment.
- `@"text"` — string literal supporting `//` line breaks.
- `\n` inside a `DATAFORM` — line break.

### 3.8 Built-in math/string ops

| Op | Notes |
|---|---|
| `RAND:N`, `RAND(N)` | uniform 0..N-1. |
| `MAX(a, b)`, `MIN(a, b)`, `ABS(n)` | math. |
| `INRANGE(v, lo, hi)` | bounds-check. |
| `STRLENS(s)`, `STRLENSU(s)` | byte/char length (U is unicode-aware). |
| `STRCOUNT(s, "regex")` | count regex matches. |
| `REPLACE s, "pattern", "repl"` | in-place replace. |
| `FINDELEMENT(arr, val, start)` | find array index. |
| `SETBIT v, k`, `CLEARBIT v, k`, `GETBIT(v, k)` | bit ops. |
| `INPUT` (int → RESULT), `INPUTS` (string → RESULTS) | user input. |
| `TWAIT <ms>, <flag>`, `GETKEY(<n>)` | wait / read keypress. |
| `CLEARLINE <n>`, `REUSELASTLINE <text>` | UI manipulation. |
| `REDRAW <mode>`, `CURRENTREDRAW()`, `LINECOUNT` | drawing-mode. |
| `VARSET <name>` (clear), `VARSET <name> <value>` (set) | variable reset. |
| `TIMES <var>, <factor>` | multiply by float, store back. |

---

## 4. The state-bus

The state-bus is the *vocabulary* every kojo body reads from. Mastering it is the difference between a kojo that "works" and one that "feels right."

Convention: `<NAMESPACE>:<CHAR_ID>:<SLOT>` (defaulting CHAR_ID to TARGET if omitted). All slots resolve via `CSV/<file>.csv`.

### 4.1 Per-character namespaces

> **Important — slot names listed here are aspirational, not verified.** The eraTW corpus has multiple forks; some slot names are different on this fork (simplified-Chinese vs Japanese-kanji variants, slots that exist on one fork and not another). **Always grep the actual `CSV/<file>.csv` for byte-exact slot names before using them in code.** Concrete examples of mismatches we hit in practice:
> - `约会中` (simplified 约) is the canonical CFLAG row; `約会中` (Japanese 約) does not resolve.
> - `BASE:N:疲労` is *not* a slot in this fork's `CSV/Base.csv`. Use `BASE:N:気力 < MAXBASE:N:気力 / 2` as the canonical "tired" predicate.
> - `TFLAG:逢瀬時間` is *not* in this fork's `CSV/TFLAG.csv`. There is no general "days since last met" TFLAG; use a private CFLAG slot you control (e.g. `CFLAG:N:1080 = DAY` and diff against today).

| Namespace | What it stores | Notable slots |
|---|---|---|
| `TALENT:N:slot` | Talents (booleans, small ints). | `恋慕, 思慕, 恋人, 愛欲, 炮友, 処女, 無接吻経験, 兒童, 幼児／幼児退行, 年齢, 体型, 形状, 胸圍, 性別, 酒耐性, 妊娠, 育児中, 妊娠願望, 大胃王, 坦率, 自尊心, 無知, 小悪魔, 魅力, 魅惑, 謎之魅力, 膽怯, 傲慢, 叛逆, 施虐狂, 性別嗜好, 両面通吃, 讨厌男人, 態度, 非処女, 非童貞, 破瓜, Ａ破瓜, 出産経験, 膣射経験, 人妻, 未亡人, 接吻魔, 心情, …` |
| `ABL:N:slot` | Ability ranks (-1..0..+5). | `親密, 欲望, Ｂ感覚, Ａ感覚, Ｃ感覚, Ｖ感覚, Ｐ感覚, Ｍ感覚, 従順, 奉仕精神, 教養, 料理技能, 戦闘能力, 露出癖, 接吻経験, 学習経験, 愛情経験, 約會経験, 演奏経験, 出産経験` |
| `EXP:N:slot` | Experience counters (raw int). | `接吻経験, 料理経験, 愛情経験, 約會経験, 学習経験, 出産経験, 無自覚絶頂経験, 60..63` |
| `BASE:N:slot` | Physiological base values. **Verify in `CSV/Base.csv`.** | This fork's actual rows include: `体力, 気力, 射精, 母乳, 尿意, 勃起, 精力, 法力, TSP, 情緒, 理性, 憤怒, 工作量, 深度, 酒気, 潜伏率, 身高, 体重`. **No `疲労` slot — use `BASE:N:気力 < MAXBASE:N:気力 / 2` for "tired" instead.** |
| `MAXBASE:N:slot` | Max base values. | (mirror of BASE). |
| `NOWEX:N:slot` | Current physiological event state. | `射精, 噴乳, 放尿, Ｃ絶頂, Ｖ絶頂, Ｂ絶頂, Ａ絶頂, Ｍ絶頂, TotalEX` |
| `EX:slot` | Engine-side cumulative state. | `膣内精液` |
| `PALAM:slot` | Status parameters. | `欲情` |
| `PALAMLV:N` | Threshold lookup. | `IF PALAM:欲情 >= PALAMLV:5`. |
| `MARK:N:slot` | Imprint state (-1..0..+3). | `不埒刻印, 反発刻印, 苦痛刻印, 快楽刻印, 時姦刻印` |
| `STAIN:N:slot` | Body-fluid stains. | `精液, 愛液, 汗` |
| `EQUIP:N:slot` | Clothing. | `下半身内衣２, 上半身内衣１, 上半身内衣２, 服, …` |
| `TEQUIP:N:slot` (or `TEQUIP:slot`) | Per-target situational equipment. | `50` (V-insertion holder), `51` (A-insertion holder), `口球, 眼罩, 縄, 陰蒂夾, 乳頭夾, 振動棒, 子宮, 六九式, 飛機杯, Ｖ接触部位, 11..18` (touch zones), `101..107` (secondary). |
| `CFLAG:N:slot` (or `CFLAG:slot`) | Persistent character flags (any int). | Engine-defined: `現在位置, 初期位置, 面識, 好感度, 信賴度, 睡眠, 約会中, 妊娠自覚状態, 無自覚妊娠, 没穿内裤, 允许无套, 清い交際, 恶作剧, 出禁, 推倒禁止, 来訪不能, 自動喘息, 時間停止口上有, 眠姦口上有, 扮演口上有, 破瓜中止口上有, 口上内抱き寄せ判定_*, 口上セレクタ, 継承`. Author-private: `1000-1999`. Engine-reserved: `1990-1999`. |
| `TCVAR:N:slot` (or `TCVAR:slot`) | Per-target transient (per-day reset). | `破瓜, Ａ破瓜, 中止接吻, 烂醉, 初次拥抱, 媚薬, 今天的礼物, 発情`, `100/101` (last V/A inserter ID), `102/104` (climax flags), `112, 302` (talk-availability). Author-private: `350-399`. |
| `CSTR:N:slot` | Per-char mutable strings. (slots ≥40 typically free.) |
| `DIARY:N:M` | Diary state. 0=locked / 1=read / 2=daily-event-readable / 3=on-demand-readable. |
| `MAX_DIARY_PAGE:N:0` | Total diary pages. |
| `RELATION:N:M` | **Inter-character affinity** between N and M. |
| `SOURCE:N:slot` | Post-action affection ledger. Slots: `性行動, 露出, 逸脱, 与快Ｃ, 誘惑, 侮辱, 挑発, 加虐, 征服, 情愛, 反感, 歓楽, 達成, 愛情経験`. |
| `CUSTOM_TALENT:N:slot` (+ `_NAME, _COLOR, _TYPE`) | Char-defined talents (info-pane). |
| `custom_button_name:N:Y` | Char-defined button labels. |

### 4.2 Per-game globals

| Global | Means |
|---|---|
| `FLAG:slot` (or `FLAG:NUMBER`) | Global flags. `FLAG:70` = time-stop (alias `FLAG:時間停止`); `FLAG:扮演` = role-play target char ID; `FLAG:出禁人数` = banned-char count; `FLAG:周回数` = NG+ cycle; `FLAG:口上文本設定`, `FLAG:口上色`, `FLAG:口上セレクタ`, `FLAG:約会的对象`, `FLAG:甲斐性無`, `FLAG:ファッション`. |
| `TIME` | Minutes-of-day. |
| `TIME:2` | Hour bucket. |
| `TIME:5` | Weather phase (4-7 = rain, 5 = heavy rain). |
| `DAY` (= `DAY:0`) | Game day count. |
| `DAY:2` | Month. |
| `DAY:3` | Day-of-month. |
| `MAIN_MAP` | Current world-map ID (0=Hakurei, 1=Myouren, 2=Human Village, 3=Scarlet, 4=Bamboo, 5=Magic Forest, 6=Sanzu, 7=Tengu foot, 8=Tengu peak, 9=Underground, …). |
| `SELECTCOM` | Currently-selected command ID (mutable). |
| `TFLAG:50` | Active SCOM ID. |
| `TFLAG:192` | SUCCESS_COM override. |
| `TFLAG:193, 194` | Mood/result codes (per-command-documented). |
| `TFLAG:21..24` + `時姦刻印取得` | Mark codes. |
| `TFLAG:62` | Time-stop suppress. |
| `TFLAG:400` | Date-presence flag. |
| `TARGET, MASTER, PLAYER, ASSI, CHARANUM` | Char-ID resolutions. |
| `TARGET:N` | N-th element of multi-target array. |
| `RESULT, RESULTS, RESULTS:1` | Return values. |
| `PREVCOM` | Previous command. |
| `DISHNAME, DISH_TASTE` | Cooking globals. |
| `LINECOUNT` | Current cursor line. |

---

## 5. Engine helpers

### 5.1 Pre-message & cooperation

```erb
CALL TRAIN_MESSAGE                  ; engine pre-narration for COMs
CALL EVENT_COUNTER_MESSAGE          ; engine pre-narration for COUNTERs
CALL MARK_MESSAGE                   ; engine pre-narration for MARKCNG
CALL SPEVENT_MESSAGE_<n>(ARG, ARG:1); engine pre-narration for SPEVENT n
CALL AUTO_AEGI(N)                   ; engine fallback auto-moan
CALL ADD_KISS                       ; increment kiss counter
```

### 5.2 UI prompts

```erb
CALL ASK_YN("yes-text", "no-text")    ; sets RESULT to 0 (yes) or 1 (no) — note polarity
CALL ASK_M("opt0", w0, "opt1", w1, …) ; multi-choice; w=0 grey-out, w=1 enable; RESULT = idx
INPUT                                  ; read int → RESULT
INPUTS                                 ; read str → RESULTS
PRINTBUTTON @"label", @"return-string"
```

### 5.3 Image / face / talk

```erb
CALL PRINT_FACE, char_id, expr[, clothes[, variant]]
;   expr  ∈ "通常", "笑顔", "発情", "憤怒", "睡眠", "性交", "自慰", "笑", ...
;   clothes ∈ "服", "服1", "裸", ...
;   variant ∈ "_1", "_2", "_変更後", ...

CALL SPTALK, char_id, expr, ?, @"line // line // line"  ; up to 6 lines, // is line break

CALL HPH_PRINT, @"<text with HPH suffix and \@…\@ ternaries>", "L"
CALL 画像セット(@"顔絵_<state>_<expr>_{[[N]]}", x, y, w, h, _, _, "default")
CALL 画像一斉表示("左", 0, 1)
CALL PRINT_GROUP(LOCALS, 3, 350)    ; print N items with delay
```

### 5.4 Pose / state / equip

```erb
CALL TOUCH_SET(SET_FROM_YUBI, 1, [[N]])   ; register touch
CALL EVENT_COUNTER_POSE_69([[N]], M)       ; set 69 pose
CALL DATUI_BOTTOM([[N]], M)                ; M=1 pull down, M=2 strip
CALL DATUI_TOP, CALL DATUI_INNER           ; same family
```

### 5.5 Predicates / accessors

```erb
RAND:N, RAND(N)
FIRSTTIME(SELECTCOM)                       ; first time using cmd
FIRSTTIME("UP01", 0, 49)                   ; string-keyed firsttime
GROUPMATCH(VAR, V1, V2, V3)                ; equivalent to ==
BATHROOM(loc), OUTROOF(loc), DATE_HITOGOMI(loc), WITH_MOB()
GET_MAPID(loc)
GET_TARGETNUM()                            ; chars in current room
FINDCHARA(start_loc, current_loc)
SHIRAHU(N)                                 ; char N in normal state
CHK_DATENOW(CFLAG:N:约会中)                ; date currently underway (note simplified 约!)
;
; CRITICAL — `CFLAG:N:约会中` is NOT a boolean; it stores the MAIN_MAP code at
; date start. After ANY date in this character's history, the slot holds that
; map code (e.g. 5) and is NEVER auto-reset. So `IF CFLAG:N:约会中` is
; effectively `IF 5` = always true after first date.
;
; The canonical "currently dating" predicate uses CHK_DATENOW (which compares
; the stored map vs. current MAIN_MAP) AND verifies the partner:
;     IF CHK_DATENOW(CFLAG:MASTER:约会中) && FLAG:约会的对象 == TARGET
;
; Anti-pattern (always-true after first date):
;     IF CFLAG:TARGET:约会中               ;DON'T DO THIS
CHK_FOCUS(start, current, end)             ; range check
MASTER_POSE(role, ?, ?)                    ; multi-person scene id lookup
ALCOHOL_TASTE(TFLAG:194), ALCOHOL_FACE()
ESTRUS_CYCLE(N)
SYNCED_ORGASM(N)
TIME_PROGRESS(TFLAG:<key>)
NEMUKE()                                   ; sleepiness
CHARA_HOLIDAY(N)
GET_SUCCESS_RATE()
GETDEFCOLOR()
```

### 5.6 Quest / gift / diary helpers

```erb
IRAI_ID_TO_CLIENT(IRAI_ID)
IS_COMMON_IRAI(IRAI_ID)
STR_DATA_IRAI(IRAI_ID, "依頼名", CLIENT_ID)
CSVCALLNAME(client_id)
GET_GIFTDATA(item_id, "得点")
CHARA_DIARY_PAGESETTING(char, page)
```

### 5.7 Author-helper conventions

If you write a function library, use these naming idioms (mirroring the Eiki K30 originals):

```erb
@K{id}_FIND_LOVER()      #FUNCTION   ; -1=this char, 0=none, 1=elsewhere, 2=in-room
@K{id}_FIND_AROUND(ARG = 0)  #FUNCTION  ; nearest known char id
@K{id}_DRUNK()           #FUNCTION   ; 0..3
@K{id}_BOKKI()           #FUNCTION   ; 0..3
@K{id}_BE_SEEN()         #FUNCTION   ; 0/1
@K{id}_C_NAME(ARG, TYPE = 0)  #FUNCTIONS  ; how this char calls another
@K{id}_GREETING()        #FUNCTIONS  ; time-of-day greeting
@K{id}_AENAI                          ; "days since seen" intro line
@K{id}_KOUSAI                         ; anniversary
@K{id}_NURESUKE()                     ; wetness/transparency
@K{id}_AMANURE                        ; rain trigger
@K{id}_ROOM_DESCRIPTION()             ; room description
@K{id}_SET_C_NAME(ARG)                ; interactive nickname dialog
```

---

## 6. The standard body shape

Every command body looks like:

```erb
;==================================================
;<cmd-id>,<command-name>
;TFLAG:193(1=mood-up 0=neutral -1=mood-down)
;CFLAG:诶嘿嘿==2&&TCVAR:20(<situational sub-state>)
;PREVCOM(<previous-cmd-numbers that affect this>)
;<other discriminants relevant to this command>
;==================================================
@M_KOJO_SUCCESS_COM_K<id>_<cmd>
;成否判定
TFLAG:192 = 0                         ; -2 end, -1 fail, 0 default, 1 great-success

@M_KOJO_MESSAGE_COM_K<id>_<cmd>
CALL TRAIN_MESSAGE                    ; engine default narration (omit if you want full custom)
CALL M_KOJO_MESSAGE_COM_K<id>_<cmd>_1  ; dispatch to body
RETURN RESULT

@M_KOJO_MESSAGE_COM_K<id>_<cmd>_1
;-------------------------------------------------
;記入チェック（=0, 非表示、1, 表示）
LOCAL = 1                              ; 1 = filled in, 0 = stub-skip
;-------------------------------------------------
IF LOCAL
    IF FLAG:時間停止                   ; time-stop: silent unless 時間停止口上有 set
    ELSEIF CFLAG:睡眠                  ; sleeping: silent unless 眠姦口上有 set
    ELSEIF TALENT:恋人                 ; tier 5 — partner
        SELECTCASE RAND:3
            CASE 1
                PRINTFORML 「lover-line-A」
                PRINTFORMW lover-narr-A
            CASE 0
                PRINTFORML 「lover-line-B」
                PRINTFORMW lover-narr-B
            CASEELSE
                PRINTFORML 「lover-line-C」
                PRINTFORMW lover-narr-C
        ENDSELECT
    ELSEIF TALENT:愛欲 || TALENT:炮友  ; tier 4
        ...
    ELSEIF TALENT:恋慕                 ; tier 3
        ...
    ELSEIF TALENT:思慕                 ; tier 2
        ...
    ELSE                                ; tier 1/0
        ...
    ENDIF
ENDIF
RETURN 1
```

**Key contract points**:
- Always emit both `@M_KOJO_SUCCESS_COM_K<id>_<cmd>` and `@M_KOJO_MESSAGE_COM_K<id>_<cmd>` for any command this character handles. `SUCCESS` can be a single-line `TFLAG:192 = 0`.
- The `CALL <body>_1` / body-label split is convention. Some authors fold it inline, but the convention matches readability and lets `_1` be re-CALLed independently from elsewhere.
- `RETURN 1` from the body marks "I handled it"; engine does not fall through.
- `RETURN 0` or no return: engine falls through to `_00` catch-all then to engine defaults.
- Last `PRINTFORML` of a body should usually be a `PRINTFORMW` so the player advances.
- Use `%CALLNAME:MASTER%` not `"主人公"` — names are user-configurable.
- Random variation: `SELECTCASE RAND:N / CASE 0 / … / CASEELSE` (default is highest-probability).
- Single-line random: use `%TEXTR("a/b/c")%` inside a `PRINTFORML`.

---

## 7. The "filled-in" gating idiom

Bodies open with `LOCAL = 1` (filled) or `LOCAL = 0` (stub). `LOCAL = 0` causes the body to fall through silently. **Do not "fix" `LOCAL = 0` bodies** — they are intentional stubs.

Sub-branches use `LOCAL:1 = 1/0` for sub-toggles:

```erb
LOCAL = 1
IF LOCAL
    ;-------------------------------------------------
    ;初めて
    ;記入チェック
    LOCAL:1 = 1
    ;-------------------------------------------------
    IF LOCAL:1 && FIRSTTIME(SELECTCOM)
        ; first-time-only branch
    ENDIF
    ;-------------------------------------------------
    ;基本セット
    ;-------------------------------------------------
    IF FLAG:70
    ELSEIF TALENT:恋慕
        ...
    ELSE
        ...
    ENDIF
ENDIF
RETURN 1
```

This lets an author selectively enable/disable parts.

---

## 8. The branching cascade

The canonical conditional cascade in a daily/sex/sexual-harassment body:

| Order | Guard | Comment |
|---|---|---|
| 1 | `IF FLAG:時間停止` (`= FLAG:70`) | Time-stop active; usually silent unless `CFLAG:N:時間停止口上有 = 1` is set in FLAGSETTING. |
| 2 | `ELSEIF CFLAG:睡眠` (or `CFLAG:TARGET:睡眠`) | Sleeping; silent unless `CFLAG:N:眠姦口上有 = 1`. |
| 3 | `ELSEIF FLAG:扮演` | Role-play; silent unless `CFLAG:N:扮演口上有 = 1`; can branch on `CFLAG:(FLAG:扮演):出禁`. |
| 4 | `ELSEIF CFLAG:318 == 1` | "Extreme silent treatment / unfriendly" — many characters have this. |
| 5 | `ELSEIF CFLAG:诶嘿嘿 == 2` | "Drunken playful 'ehehe' mood" — branch further on `TCVAR:20` for sub-action. |
| 6 | `ELSEIF TALENT:恋人` | Tier 5 — partner. |
| 7 | `ELSEIF TALENT:愛欲 \|\| TALENT:炮友` | Tier 4 — lust without commitment. |
| 8 | `ELSEIF TALENT:恋慕` | Tier 3 — in love. |
| 9 | `ELSEIF TALENT:思慕` | Tier 2 — admiring. |
| 10 | `ELSE` | Tier 1/0 — neutral or hostile. |

Some authors collapse into a helper `陥落状態()` returning 0..5; the bodies then use `IF 陥落状態() >= 4 ...` instead of testing TALENT directly.

For sex commands, add intermediate guards on `BASE:MASTER:勃起`, `TCVAR:破瓜`, `TFLAG:193`, `TFLAG:194`, etc. — refer to the doc-banner state contract above each command.

---

## 9. Per-character file taxonomy

A complete kojo has 1+ author-variant directory under `個人口上/<id> <name>/`. Inside, files split labels by category. **The engine doesn't enforce *which* file holds *which* label** — only that the right labels exist. Common file names:

| File | Holds |
|---|---|
| `M_KOJO_K{id}_イベント.ERB` | Existence / FLAGSETTING / COLOR / UPDATE / ENCOUNTER / SPEVENT_* / EVENT_*. **Often the largest file.** |
| `M_KOJO_K{id}_日常系コマンド.ERB` | Daily commands (300–4xx range). |
| `M_KOJO_K{id}_性交系コマンド.ERB` | Sex commands (60–7x range). |
| `M_KOJO_K{id}_セクハラコマンド.ERB` | Sexual-harassment (310–330). |
| `M_KOJO_K{id}_愛撫系コマンド.ERB` | Foreplay. |
| `M_KOJO_K{id}_加虐系コマンド.ERB` | SM/discipline (100–108). |
| `M_KOJO_K{id}_ハードなコマンド.ERB` | Extreme. |
| `M_KOJO_K{id}_奉仕系コマンド.ERB` | Service-led. |
| `M_KOJO_K{id}_道具系コマンド.ERB` | Toys (40–4x, 100–18x). |
| `M_KOJO_K{id}_派生コマンド.ERB` | SCOMs. |
| `M_KOJO_K{id}_カウンター.ERB` | COUNTER labels. |
| `M_KOJO_K{id}_弾幕勝負.ERB` | Danmaku duel. |
| `M_KOJO_K{id}_依頼.ERB` | Quests (IRAI). |
| `M_KOJO_K{id}_刻印取得.ERB` | Mark / imprint. |
| `M_KOJO_K{id}_絶頂.ERB` | Climax (PALAMCNG_*). |
| `M_KOJO_K{id}_日記.ERB` | Diary + command 406. |
| `M_KOJO_K{id}_育児イベント.ERB` | Child-rearing. |
| `M_KOJO_K{id}_INFO.ERB` | `@CHARA_INFO_KOJO_K{id}()`. |
| `M_KOJO_K{id}_カスタム.ERB` (or `of_new_kojo_api.ERB`) | New custom-button / custom-cmd API. |
| `M_KOJO_K{id}_関数ライブラリ.ERB` | author-private `#FUNCTION` definitions. |
| `M_KOJO_K{id}_<charname>特殊イベント.ERB` | author-private one-shot story events. |
| `M_KOJO_K{id}_コマンド自動喘ぎ.ERB` | Auto-pant. |
| `M_KOJO_K{id}_コマンド酔夢想.ERB` | Drunken dialogue. |
| `K{id}_固有カウンター<n>_<name>.ERB` | Char-unique counter scaffold. |
| `K{id}C_<charname>用DIM.ERH` | `#DIM CONST` constant declarations. |
| `Lib/`, `追加ファイル/`, `おまけ/`, `自分用メモ/` | Optional subdirectories. |
| `readme.txt`, `ライセンス*.txt`, `フラグ管理メモ.txt`, `衣装メモ.txt`, `*.txt` | Author docs (not loaded). |

Variant-style file organizations (any are valid):
- **Standard** (one file per category): the table above.
- **Subdirectory** (`一般/`, `性/`, `自作/`, `其它/`): topical grouping.
- **Per-event-id** (`M_KOJO_K{id}_イベント_<eventid>(<title>).erb`): one file per event.
- **Numbered-prefix** (`M_KOJO_K{id}_00_DIM.ERH`, `_01_イベント.ERB`, …): load-priority.
- **Single-file consolidation** (everything in 1-3 big files).

---

## 10. Author-extension idioms

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

## 12. Beyond kojo — broader game-modification topics

### 12.1 The CSV layer

`CSV/` holds static-data tables. They're enumeration files — slot-id → name mappings:

| File | Maps |
|---|---|
| `CFLAG.csv` | character-flag slot IDs to human names. **Crucial for understanding kojo**: when you see `CFLAG:6:1001`, look up row 1001 of CFLAG.csv to find that author's intent. |
| `TFLAG.csv` | turn-flag slot IDs. |
| `TCVAR.csv` | per-target var slots. |
| `Talent.csv` | talents like `恋慕`, `処女`, `兒童`. |
| `Abl.csv` | ability slots. |
| `CSTR.csv` | per-char string slots. |
| `Mark.csv` | imprint slots. |
| `Item.csv` | item definitions. |
| `Equip.csv`, `Tequip.csv` | equipment. |
| `Train.csv` | training command IDs. |
| `Palam.csv` | parameter slots. |
| `Juel.csv` | juel currency. |
| `Stain.csv` | body-fluid stain slots. |
| `Str.csv` | UI strings. |
| `Source.csv`, `ex.csv`, `exp.csv` | EXP curves. |
| `Base.csv`, `GameBase.csv` | game metadata. |
| `Chara/` | per-character static data CSVs. One per character. |

**To add a new author-private CFLAG slot**: edit `CFLAG.csv` to add a row (e.g. `1234,my_new_flag`). Then in your kojo, `CFLAG:N:my_new_flag` works (and `CFLAG:N:1234` too).

### 12.2 Other ERB subdirectories

| Subdir/File | Role |
|---|---|
| `初期設定.ERB`, `SYSTEM.ERB`, `TITLE.ERB`, `NEWGAME/` | Game start, title screen, new-game flow. |
| `DIM.ERH` | Variable schema declarations. |
| `COMMON.ERB` (83 KB) | Engine common subroutines. |
| `BATTLE.ERB`, `CASINO/`, `NOUMIN.ERB`, `YASAI.ERB` | Mini-systems (battle, casino, farming, vegetables). |
| `天候*` | Weather subsystem (`ERH` for headers, `ERB` for logic). |
| `時間停止解除.ERB` | Time-stop release. |
| `潜伏モード関連/` | Stealth/sneak mode. |
| `衣服/` | Clothing. |
| `グラフィック表示ライブラリ/` | Image-display library. |
| `ステータス計算関連/` (subdir) | Status computation: `ABL/`, `ATTITUDE.ERB`, `STAIN.ERB`, `TRACHECK*.ERB`. **End-of-turn affection ledger lives here.** |
| `ステータス表示関連/` (subdir) | UI: portraits, color, BAR, IMAGE, INFO, look. |
| `キャラデータ/` (subdir) | `Chara_data_<N>_<name>.ERB` — runtime-loaded character setup. |
| `カラム機能/` (subdir) | Column / panel UI. |
| `イベント関連/` (subdir) | Date events, festivals, gifts, jealousy/affair, pregnancy. |
| `コマンド関連/` (subdir) | The command system: `COMABLE/`, `COMF/`, `SCOMF/`, `COMORDER.ERB`. |
| `SHOP関連/` (subdir) | Shop. |
| `ALTER/`, `MOVEMENTS/`, `OBJ/`, `COLOREDMAPS/`, `DLC/`, `NEWCHARACTERリソース作成/` | Misc: re-skinning, locations, maps, DLC, resource generation. |
| `method_from_anon/`, `method_from_eratohoЯeverse/` | Library subroutines from anon contributors. |
| `魔改内容/` | Mod-specific content. |

### 12.3 The command system (`コマンド関連/`)

This is what kojo *hooks into*. The split:

- **`COMF/`**: per-command implementation files. Filenames embed command ID: `COMF1 クンニ.ERB`, `COMF12 胸揉み.ERB`, `COMF184 野外プレイ.ERB`. **These define what the command does mechanically**; kojo files supply per-character speech.
- **`SCOMF/`**: sub-command implementations (the SCOM family).
- **`COMABLE/`** (`COMABLE.ERB`, `COMABLE_300.ERB`, `_400`, `_500`, `_600`, `_700`, `_80`): "Is this command currently usable?" gates. The numeric suffixes match command-ID ranges.
- **`COMORDER.ERB`**: command sequencing/chaining.
- **`USERCOM.ERB`** + **`USERCOM_*`**: user-defined commands.

Command-ID namespace partitioning:
| Range | Family |
|---|---|
| 0–99 | Misc / primitive (`COMF1 クンニ`, `COMF11 乳首吸い`, `COMF15 クリ愛撫`, `COMF80 手を引く`). |
| 100s | SM / discipline (`COMF100 スパンキング`, `COMF105 縄`, `COMF107 拘束プレイ`). |
| 120s–140s | Assistant-involving / advanced. |
| 180s | Aids / situational (`COMF180 ローション`, `COMF184 野外プレイ`). |
| **300s** | **Daily-life** (会話 300, 泡茶 301, 身体接觸 302, 道歉 303, …). |
| **400s** | **Housekeeping/training** (掃除 410, 戦闘訓練 411, 学习 412, 料理 413, 吃飯 414, 演奏 416, 午睡 417, 祈願 421, 浴室 431, 等待 440). |
| 500s | (Battle/spell — needs verification.) |
| **600s** | **Date** (約会). |
| **700s** | **Self-pleasure** (`700 自慰系/`). |
| 80s SCOMF | Derived sub-commands (TFLAG:50). |

For new commands: choose an ID outside used ranges (e.g. 270-279 for the new-API custom-command space).

### 12.4 The weather subsystem — example "system plugin"

`天候システム.ERH` (header), `天候予測システム.ERB`, `天候管理拡張.ERB`, `日時天候管理.ERB` (~220 KB total). This is the canonical example of a non-kojo plugin: a self-contained subsystem.

**Pattern of a system plugin**:
1. Drop `.ERH` headers and `.ERB` source files into `ERB/` (or a subdir under it).
2. The `.ERH` declares `#DIM`/`#DIMS`/`#DIM CONST` for the plugin's namespaces.
3. The `.ERB` files declare labels (`@MY_PLUGIN_*`) callable from the rest of the engine.
4. Engine scans recursively, picks up the new files at next launch.
5. To "register" the plugin with existing kojo or commands, you add a `CALL MY_PLUGIN_*` invocation at appropriate hook points.

Example: weather affects kojo. The `天候*` system writes `TIME:5` (the global weather phase). Bodies read `TIME:5` and branch on weather. There's no "registration" step — the kojo just reads the global.

For more complex plugins (a new economy system, a new mini-game), you might:
- Add a new `MAIN_MAP` ID to host the mini-game.
- Add a new ERB file with the game logic.
- Register a player-side command in `COMF/` to enter the mini-game.
- (Optionally) add per-character kojo reactions to the mini-game in each char's `M_KOJO_K{id}_イベント.ERB`.

### 12.5 The resources/ directory

Sprite/portrait images. `mkResourceXml.py` is the build script that produces resource XMLs. Per-character images go under `resources/<charid>_<key>.webp` (or similar). Image-display in kojo uses `CALL PRINT_FACE, char, expr, clothes, variant` to look up the corresponding resource.

To add new character images:
1. Add the image files (`.webp` / `.png`) to `resources/`.
2. Update `resources/顔.csv` to declare the new key.
3. In your kojo, `CALL PRINT_FACE, <id>, "<your-key>", ...` to use it.

### 12.6 Save-game compatibility

Persistent state lives in `sav/`. Variable types affecting save format:
- `CFLAG`, `TALENT`, `ABL`, `EXP`, `BASE`, `MARK`, `CSTR`, `DIARY`, `MAX_DIARY_PAGE` — saved per-character.
- `CFLAG` global slots, `FLAG`, `TIME`, `DAY`, `MAIN_MAP` — saved as game-state.
- `#DIM SAVEDATA <name>` — kojo-defined per-char persistence.
- `#DIM SAVEDATA GLOBAL <name>` — kojo-defined cross-game persistence.

Adding a new `SAVEDATA` doesn't break old saves (engine zero-fills missing). Removing one *does* — old saves still have the value but the runtime no longer cares.

For save-migration on version-up: implement `@KOJO_VERSION_UPDATE_K{id}` to read the old value, transform, and write to the new slot (custom-API only).

---

## 13. Quality-of-life conventions

### 13.1 The doc-banner state contract

Every command body should be preceded by a `;` doc-banner enumerating the relevant TFLAG/TCVAR/MARK/CFLAG codes:

```
;==================================================
;310,摸屁股
;TFLAG:193(1=不快(TALENT:膽怯なら涙目) 2&&3=恥ずかしがる … 4=されるがまま)
;CFLAG:诶嘿嘿==2&&TCVAR:20(70=強制舐陰 71=口交強制 …)
;CFLAG:诶嘿嘿==2&&TEQUIP:六九式(胖次ありTCVAR:20(70～72)はこちら)
;PREVCOM(305=膝枕)
;TFLAG:400(1=约会先or地底の路人が反応する)
;==================================================
```

These are the discriminants the body should branch on. Always include them — they're the "API surface" of the command.

### 13.2 Banner style

Section dividers: `;※※※※※※※※※※※※※※※※※※※※※※※※※`
Sub-section: `;==================================================`
Item: `;-------------------------------------------------`

### 13.3 License files

Most kojo ship a `ライセンステンプレ.txt` or `ライセンス.txt`. Include yours. Reference: see existing characters' files for templates. Common license matrix (○=allowed, ×=forbidden, △=ask):
- 単体での再アップロード
- 本体への同梱・口上まとめへの収録
- バグ・誤字脱字の修正
- 口上の加筆 / 改変
- 他言語版バリアントへの流用・翻訳
- 金銭のやり取りを伴う利用
- 二次創作 / era以外への流用

### 13.4 Author memos

`readme.txt`, `フラグ管理メモ.txt`, `衣装メモ.txt`, `CFLAG一覧.txt`, `自分用メモ/` — keep these as `.txt` files alongside ERB. Engine ignores them. Useful for documenting your CFLAG/TCVAR scheme, costume slots, version history, and TODO lists.

### 13.5 Skip-blocks

`[SKIPSTART] ... [SKIPEND]` excludes a region from compilation. Use for:
- Long author commentary at the top of files.
- Code that should only fire on engines with newer features (the new custom-cmd API).
- Disabled work-in-progress.

### 13.6 Variant naming

If you fork an existing character's kojo, give your variant directory a distinct name (e.g. `<name> v0.5_my-edition` or `<name> 自制别人`). Keep the original next to yours; the engine selects via `RESULTS` selector.

### 13.7 Testing tips

- Run the game with `DEBUG_MODE.bat` to see runtime errors.
- The engine logs to `emuera.log` and rotation files like `20240616-042436.log`.
- Add `PRINTL <debug>` lines temporarily, `PRINT VARDUMP(<var>)` for state inspection.
- Common bug: a typo in the label name. `TRYCALLFORM` is silent; the engine will just not find your label. Double-check names (especially the `_K<id>` suffix).

---

## 14. Persona-translation tips (humanizing the structural skeleton)

When the user writes "she's cheerful but easily flustered," translate that into:

| Persona trait | Translation |
|---|---|
| "Cheerful" | Default `RAND:N` cascades skew toward upbeat lines; `TALENT:坦率 = 1` if applicable. |
| "Easily flustered" | Sex/sexual-harassment commands often have her stutter; first-time `FIRSTTIME(SELECTCOM)` branches show shock/confusion. |
| "Reserved" | Many command bodies are short / single-line. `TALENT:自尊心 = 1` if proud. |
| "Possessive" | `EVENT_K{id}_7` (caught-dating) has stronger reactions; `RELATION:N:<rival_id>` deltas are negative when player flirts. |
| "Drunk easily" | `TALENT:酒耐性 = -2`; many commands branch on `BASE:酒気 > MAXBASE:酒気/2`. |
| "Loves food" | `TALENT:大胃王 = 1`; `@K{id}_COOKING_REACTION` covers a lot of dish names. |
| "Tsundere" | First-time `FIRSTTIME` branches resist; later branches accept; uses `TALENT:傲嬌` if available; high `TALENT:自尊心`. |
| "Reads minds" | Bodies use `\@ <thought-cond> ? <reading-line> # <neutral-line> \@`; references "知道你在想什么" frequently. |
| "Cosplay-loving" | `IF FLAG:ファッション == <some-cosplay-id>` branches; helper `K{id}_CHECK_HEN_T()` rejects unwanted outfits. |
| "Has a sister/relative" | `RELATION:N:<sis-id>` deltas; events trigger when the relative is in-room (`CFLAG:<sis-id>:現在位置 == CFLAG:N:現在位置`). |
| "Lives at <place>" | `MAIN_MAP == <id>` and `CFLAG:N:現在位置 == <loc>`. |

---

## 15. Reference: file layout summary (cheatsheet)

```
個人口上/<id> <name>/
└── <variant-name>/
    ├── M_KOJO_K{id}_イベント.ERB                 ; existence/FLAGSETTING/COLOR/UPDATE/ENCOUNTER/SPEVENT/EVENT
    ├── M_KOJO_K{id}_日常系コマンド.ERB           ; COMs 300-4xx
    ├── M_KOJO_K{id}_性交系コマンド.ERB           ; COMs 60-7x
    ├── M_KOJO_K{id}_セクハラコマンド.ERB         ; COMs 310-330
    ├── M_KOJO_K{id}_愛撫系コマンド.ERB           ; foreplay
    ├── M_KOJO_K{id}_加虐系コマンド.ERB           ; SM 100-108
    ├── M_KOJO_K{id}_ハードなコマンド.ERB         ; extra
    ├── M_KOJO_K{id}_奉仕系コマンド.ERB           ; service
    ├── M_KOJO_K{id}_道具系コマンド.ERB           ; toys
    ├── M_KOJO_K{id}_派生コマンド.ERB             ; SCOMs
    ├── M_KOJO_K{id}_カウンター.ERB               ; COUNTER
    ├── M_KOJO_K{id}_弾幕勝負.ERB                 ; DANMAKU
    ├── M_KOJO_K{id}_依頼.ERB                     ; IRAI
    ├── M_KOJO_K{id}_刻印取得.ERB                 ; MARKCNG
    ├── M_KOJO_K{id}_絶頂.ERB                     ; PALAMCNG_*
    ├── M_KOJO_K{id}_日記.ERB                     ; DIARY + cmd 406
    ├── M_KOJO_K{id}_育児イベント.ERB             ; CHILD_*
    ├── M_KOJO_K{id}_INFO.ERB                     ; CHARA_INFO_KOJO
    ├── M_KOJO_K{id}_カスタム.ERB                 ; KOJO_CUSTOM_* (new-API only)
    ├── M_KOJO_K{id}_関数ライブラリ.ERB           ; #FUNCTION definitions
    ├── M_KOJO_K{id}_<charname>特殊イベント.ERB   ; @K{id}_<NAME>...
    ├── K{id}_固有カウンター<n>_<name>.ERB        ; UNIQUE_COUNTER<n>_*
    ├── K{id}C_<charname>用DIM.ERH                ; #DIM CONST constants
    ├── Lib/                                       ; library files (recursively scanned)
    ├── 追加ファイル/                              ; supplementary files
    ├── readme.txt                                 ; persona / version / instructions
    ├── ライセンステンプレ.txt                     ; license
    ├── フラグ管理メモ.txt                         ; CFLAG/TCVAR memo
    └── 衣装メモ.txt                               ; costume slot memo
```

---

## 16. Final reminders for you (the helper LLM)

1. **Structure first, prose later.** Always scaffold the file taxonomy and label names *before* asking the user about content.
2. **Default to the standard cascade.** For most commands, the `IF FLAG:時間停止 / ELSEIF CFLAG:睡眠 / ELSEIF TALENT:恋人 / ... / ELSE` cascade is sufficient. Only add custom guards when the user's persona requires it.
3. **Use `LOCAL = 0` stubs liberally.** A new kojo with 50% commands stubbed is normal — those slots fall back to engine defaults. Don't force the user to fill everything.
4. **Always emit both `SUCCESS_COM` and `MESSAGE_COM` for any command you handle.** Even if `SUCCESS_COM` is just `TFLAG:192 = 0`.
5. **Update `SOURCE:N:<slot>` in counter / unique-counter handlers.** Without it, the kojo prints text but doesn't shift affection.
6. **Use `%CALLNAME:MASTER%`** not "你"/"主人公"/etc.
7. **Don't quote R18 lines from existing kojo.** When showing examples, redact prose to placeholders (`<dialogue>`, `<narration>`).
8. **For ID lookup**: char ID = the directory's leading number (1-159). The CSV file `Chara<N> <name>.csv` confirms the name.
9. **For new-API features**: only use `@KOJO_CUSTOM_BUTTON_*` etc. if you confirmed the user runs a recent engine. Wrap in `[SKIPSTART]/[SKIPEND]` if uncertain.
10. **Persistent storage**: prefer `CFLAG:N:1000-1999` (author-private) and `TCVAR:N:350-399` (author-private) over `SAVEDATA` modifiers unless you specifically need cross-game persistence.
11. **For inter-character interactions**: read each character's ID from the directory list. Use `RELATION:N:M` for affinity if the engine version supports it; otherwise compose from `CFLAG:M:好感度` reads.
12. **Test mentally before delivering**: do the labels match? Is the existence check returning 1? Are guards in the right cascade order?

When the user asks "make X react to Y," the formula is:
- **WHAT slot?** Identify the engine label (command, event, counter).
- **WHAT guard?** Identify the discriminant (TFLAG / CFLAG / TALENT / time / weather).
- **WHAT body?** Generate `PRINTFORML` lines that reflect the requested persona × guard.

Then deliver the patch. Use unified-diff style if modifying, full-file style if creating.

Good luck. The user is trying to make a creative thing that they care about; your job is to do the boring infrastructure work so they can focus on their character.

---

## Appendix A — Character ID ⇆ name correspondence table

This table maps engine character IDs (1-159, used in `K<id>` label suffixes) to directory names, romaji, Japanese names, and **commonly-used Chinese names**.

**Important caveats** for the LLM reading this:

- **The engine ID is the leading number in the directory name** (e.g. `042 Hatate [はたて]/` → `K42`). This ID is what appears in every label like `@M_KOJO_MESSAGE_COM_K42_300`. **It is the only authoritative identifier**; everything else is a display name.
- **Chinese names are NOT canonical.** The Touhou fandom has multiple competing Chinese translations for nearly every character. The user may give you a Chinese name slightly different from this table — for example, 帕露西/帕露珞/水桥帕露西 are all common renderings of `Parsee`. **When in doubt, match against the romaji or the Japanese name in brackets**, never the Chinese name alone. If the user's name is ambiguous, ask "你是指 ID 60 帕露西 (パルスィ) 吗？" and confirm.
- IDs **145, 153, 155-158** are intentionally skipped in the dir layout. IDs that appear in the table but with a note "empty/stub directory" have a directory but no kojo — those characters are unimplemented in the current build.
- The "directory name" column is the **exact** string under `個人口上/`. Use it verbatim when constructing paths.

| ID | Romaji (dir) | 日本語 | 中文常用名 | Directory (under 個人口上/) |
|---|---|---|---|---|
| 1 | Reimu | 霊夢 | 博丽灵梦 | `001 Reimu [霊夢]` |
| 2 | Ruukoto | る～こと | 茹~克托 / 露~克托 | `002 Ruukoto [る～こと]` |
| 3 | Kana | カナ | 卡娜·安娜贝拉尔 | `003 Kana [カナ]` (stub) |
| 4 | Mima | 魅魔 | 魅魔 | `004 Mima [魅魔]` |
| 5 | Sunny | サニー | 桑尼米尔克 | `005 Sunny [サニー]` |
| 6 | Luna | ルナ | 露娜切尔德 | `006 Luna [ルナ]` |
| 7 | Star | スター | 斯塔萨菲雅 | `007 Star [スター]` |
| 8 | Chiyuri | ちゆり | 北白河千百合 | `008 Chiyuri [ちゆり]` (stub) |
| 9 | Yumemi | 夢美 | 冈崎梦美 | `009 Yumemi [夢美]` |
| 10 | Suika | 萃香 | 伊吹萃香 | `010 Suika [萃香]` |
| 11 | Marisa | 魔理沙 | 雾雨魔理沙 | `011 Marisa [魔理沙]` |
| 12 | Rumia | ルーミア | 露米娅 | `012 Rumia [ルーミア]` |
| 13 | Daiyousei | 大妖精 | 大妖精 | `013 Daiyousei [大妖精]` |
| 14 | Cirno | チルノ | 琪露诺 | `014 Cirno [チルノ]` |
| 15 | Sakuya | 咲夜 | 十六夜咲夜 | `015 Sakuya [咲夜]` |
| 16 | Remilia | レミリア | 蕾米莉亚 (蕾米莉亚·斯卡蕾特) | `016 Remilia [レミリア]` |
| 17 | Alice | アリス | 爱丽丝 (爱丽丝·玛格特罗依德) | `017 Alice [アリス]` |
| 18 | Lily W | リリーＷ | 莉莉白 | `018 Lily W [リリーＷ]` |
| 19 | Lily B | リリーＢ | 莉莉布莱克 | `019 Lily B [リリーＢ]` |
| 20 | Lyrica | リリカ | 莉莉卡 (莉莉卡·普利兹姆利巴) | `020 Lyrica [リリカ]` (stub) |
| 21 | Merlin | メルラン | 梅露兰 (梅露兰·普利兹姆利巴) | `021 Merlin [メルラン]` (stub) |
| 22 | Lunasa | ルナサ | 露娜萨 (露娜萨·普利兹姆利巴) | `022 Lunasa [ルナサ]` |
| 23 | Youmu | 妖夢 | 魂魄妖梦 | `023 Youmu [妖夢]` |
| 24 | Chen | 橙 | 橙 | `024 Chen [橙]` |
| 25 | Ran | 藍 | 八云蓝 | `025 Ran [藍]` |
| 26 | Yukari | 紫 | 八云紫 | `026 Yukari [紫]` |
| 27 | Wriggle | リグル | 莉格露 (莉格露·奈特巴格) | `027 Wriggle [リグル]` |
| 28 | Mystia | ミスティア | 米斯蒂娅 (米斯蒂娅·萝蕾拉) | `028 Mystia [ミスティア]` |
| 29 | Aya | 文 | 射命丸文 | `029 Aya [文]` |
| 30 | Eiki | 映姫 | 四季映姬·亚玛萨那度 | `030 Eiki [映姫]` |
| 31 | Sanae | 早苗 | 东风谷早苗 | `031 Sanae [早苗]` |
| 32 | Kanako | 神奈子 | 八坂神奈子 | `032 Kanako [神奈子]` |
| 33 | Suwako | 諏訪子 | 洩矢诹访子 | `033 Suwako [諏訪子]` |
| 34 | Tenshi | 天子 | 比那名居天子 | `034 Tenshi [天子]` |
| 35 | Iku | 衣玖 | 永江衣玖 | `035 Iku [衣玖]` |
| 36 | Orin | お燐 | 火焰猫燐 / 阿燐 | `036 Orin [お燐]` |
| 37 | Okuu | お空 | 灵乌路空 / 阿空 | `037 Okuu [お空]` |
| 38 | Koishi | こいし | 古明地恋 | `038 Koishi [こいし]` |
| 39 | Nazrin | ナズーリン | 娜兹琳 | `039 Nazrin [ナズーリン]` |
| 40 | Kogasa | 小傘 | 多多良小伞 | `040 Kogasa [小傘]` |
| 41 | Nue | ぬえ | 封兽鵺 | `041 Nue [ぬえ]` |
| 42 | Hatate | はたて | 姬海棠果 (kojo 内常用「极」) | `042 Hatate [はたて]` |
| 43 | Kasen | 華扇 | 茨木华扇 | `043 Kasen [華扇]` |
| 44 | Ellen | エレン | 艾伦 | `044 Ellen [エレン]` |
| 45 | Rikako | 理香子 | 朝仓理香子 | `045 Rikako [理香子]` (empty) |
| 46 | Meira | 明羅 | 明罗 | `046 Meira [明羅]` (empty) |
| 47 | Rika | 里香 | 里香 | `047 Rika [里香]` |
| 48 | Louise | ルイズ | 路易兹 | `048 Louise [ルイズ]` (empty) |
| 49 | Satori | さとり | 古明地觉 | `049 Satori [さとり]` |
| 50 | Flandre | フラン | 芙兰朵露 (芙兰朵露·斯卡蕾特) / 芙兰 | `050 Flandre [フラン]` |
| 51 | Nitori | にとり | 河城荷取 | `051 Nitori [にとり]` |
| 52 | Reisen | 鈴仙 | 铃仙·优昙华院·稻叶 | `052 Reisen [鈴仙]` |
| 53 | Tewi | てゐ | 因幡帝 | `053 Tewi [てゐ]` |
| 54 | Patchouli | パチュリー | 帕秋莉 (帕秋莉·诺蕾姬) / 帕琪 | `054 Patchouli [パチュリー]` |
| 55 | Byakuren | 白蓮 | 圣白莲 | `055 Byakuren [白蓮]` |
| 56 | Miko | 神子 | 丰聪耳神子 | `056 Miko [神子]` |
| 57 | Kokoro | こころ | 秦心 (秦こころ) | `057 Kokoro [こころ]` |
| 58 | Meiling | 美鈴 | 红美铃 / 美铃 | `058 Meiling [美鈴]` |
| 59 | Koakuma | 小悪魔 | 小恶魔 | `059 Koakuma [小悪魔]` |
| 60 | Parsee | パルスィ | 水桥帕露西 / 帕露西 | `060 Parsee [パルスィ]` |
| 61 | Mokou | 妹紅 | 藤原妹红 | `061 Mokou [妹紅]` |
| 62 | Kaguya | 輝夜 | 蓬莱山辉夜 | `062 Kaguya [輝夜]` |
| 63 | Kagerou | 影狼 | 今泉影狼 | `063 Kagerou [影狼]` |
| 64 | Yuugi | 勇儀 | 星熊勇仪 | `064 Yuugi [勇儀]` |
| 65 | Momiji | 椛 | 犬走椛 | `065 Momiji [椛]` |
| 66 | Yuyuko | 幽々子 | 西行寺幽幽子 | `066 Yuyuko [幽々子]` |
| 67 | Keine | 慧音 | 上白泽慧音 | `067 Keine [慧音]` |
| 68 | Yuuka | 幽香 | 风见幽香 | `068 Yuuka [幽香]` |
| 69 | Mamizou | マミゾウ | 二岩猯藏 | `069 Mamizou [マミゾウ]` |
| 70 | Kosuzu | 小鈴 | 本居小铃 | `070 Kosuzu [小鈴]` |
| 71 | Shinmyoumaru | 針妙丸 | 少名针妙丸 | `071 Shinmyoumaru [針妙丸]` |
| 72 | Eirin | 永琳 | 八意永琳 | `072 Eirin [永琳]` |
| 73 | Sekibanki | 蛮奇 | 赤蛮奇 | `073 Sekibanki [蛮奇]` |
| 74 | Letty | レティ | 蕾蒂 (蕾蒂·霍瓦特罗克) | `074 Letty [レティ]` |
| 75 | Medicine | メディスン | 梅蒂欣 (梅蒂欣·梅兰可莉) | `075 Medicine [メディスン]` |
| 76 | Komachi | 小町 | 小野塚小町 | `076 Komachi [小町]` |
| 77 | Shizuha | 静葉 | 秋静叶 | `077 Shizuha [静葉]` (empty) |
| 78 | Minoriko | 穣子 | 秋穰子 | `078 Minoriko [穣子]` |
| 79 | Hina | 雛 | 键山雏 | `079 Hina [雛]` |
| 80 | Akyuu | 阿求 | 稗田阿求 | `080 Akyuu [阿求]` |
| 81 | Renko | 蓮子 | 宇佐见莲子 | `081 Renko [蓮子]` |
| 82 | Maribel | メリー | 玛艾露贝莉 / 梅莉 | `082 Maribel [メリー]` |
| 83 | Kisume | キスメ | 钓瓶落 / 露珠 | `083 Kisume [キスメ]` |
| 84 | Yamame | ヤマメ | 黑谷山女 | `084 Yamame [ヤマメ]` (incomplete) |
| 85 | Ichirin | 一輪 | 云居一轮 | `085 Ichirin [一輪]` |
| 86 | Murasa | 水蜜 | 村纱水蜜 | `086 Murasa [水蜜]` |
| 87 | Shou | 星 | 寅丸星 | `087 Shou [星]` |
| 88 | Kyouko | 響子 | 幽谷响子 | `088 Kyouko [響子]` |
| 89 | Yoshika | 芳香 | 宫古芳香 | `089 Yoshika [芳香]` |
| 90 | Seiga | 青娥 | 霍青娥 | `090 Seiga [青娥]` |
| 91 | Tojiko | 屠自古 | 苏我屠自古 | `091 Tojiko [屠自古]` |
| 92 | Futo | 布都 | 物部布都 | `092 Futo [布都]` |
| 93 | Wakasagihime | わかさぎ姫 | 若鹭姬 | `093 Wakasagihime [わかさぎ姫]` (empty) |
| 94 | Benben | 弁々 | 九十九弁弁 | `094 Benben [弁々]` |
| 95 | Yatsuhashi | 八橋 | 九十九八桥 | `095 Yatsuhashi [八橋]` |
| 96 | Raiko | 雷鼓 | 堀川雷鼓 | `096 Raiko [雷鼓]` |
| 97 | Seija | 正邪 | 鬼人正邪 | `097 Seija [正邪]` |
| 98 | Yorihime | 依姫 | 绵月依姬 | `098 Yorihime [依姫]` |
| 99 | Toyohime | 豊姫 | 绵月丰姬 | `099 Toyohime [豊姫]` |
| 100 | Rei'sen | レイセン | 玲(月之都) (レイセン) | `100 Rei'sen [レイセン]` |
| 101 | Tokiko | 朱鷺子 | 朱鹭子 | `101 Tokiko [朱鷺子]` |
| 102 | Shinki | 神綺 | 神绮 | `102 Shinki [神綺]` (empty) |
| 103 | Yumeko | 夢子 | 梦子 | `103 Yumeko [夢子]` |
| 104 | Yuki | ユキ | 雪 | `104 Yuki [ユキ]` |
| 105 | Mai (PC-98) | マイ | 舞 (PC-98) | `105 Mai (PC-98) [マイ]` |
| 106 | Sumireko | 菫子 | 宇佐见菫子 | `106 Sumireko [菫子]` |
| 107 | Seiran | 清蘭 | 清兰 | `107 Seiran [清蘭]` |
| 108 | Ringo | 鈴瑚 | 铃瑚 | `108 Ringo [鈴瑚]` |
| 109 | Doremy | ドレミー | 哆来咪·苏伊特 / 朵蕾米 | `109 Doremy [ドレミー]` |
| 110 | Sagume | サグメ | 稀神探女 | `110 Sagume [サグメ]` |
| 111 | Clownpiece | クラウンピース | 克劳恩皮丝 | `111 Clownpiece [クラウンピース]` |
| 112 | Junko | 純狐 | 纯狐 | `112 Junko [純狐]` |
| 113 | Hecatia | ヘカーティア | 赫卡蒂亚·拉碧斯拉祖利 / 赫卡提亚 | `113 Hecatia [ヘカーティア]` |
| 114 | Kurumi | くるみ | 库露米 | `114 Kurumi [くるみ]` (empty) |
| 115 | Elly | エリー | 艾莉 | `115 Elly [エリー]` (empty) |
| 116 | Mugetsu | 夢月 | 梦月 | `116 Mugetsu [夢月]` (empty) |
| 117 | Gengetsu | 幻月 | 幻月 | `117 Gengetsu [幻月]` |
| 118 | Larva | ラルバ | 拉露瓦 / 拉尔瓦 | `118 Larva [ラルバ]` |
| 119 | Nemuno | ネムノ | 坂田合欢奈 / 古入道合欢 | `119 Nemuno [ネムノ]` |
| 120 | Aunn | あうん | 高丽野阿吽 | `120 Aunn [あうん]` |
| 121 | Narumi | 成美 | 矢田寺成美 | `121 Narumi [成美]` |
| 122 | Mai Teireida | 舞 | 丁礼田舞 | `122 Mai Teireida [舞]` |
| 123 | Satono | 里乃 | 尔子田里乃 | `123 Satono [里乃]` |
| 124 | Okina | 隠岐奈 | 摩多罗隐岐奈 | `124 Okina [隠岐奈]` |
| 125 | Joon | 女苑 | 依神女苑 | `125 Joon [女苑]` |
| 126 | Shion | 紫苑 | 依神紫苑 | `126 Shion [紫苑]` |
| 127 | Eika | 瓔花 | 瓔花·惠比寿 (Eika Ebisu) | `127 Eika [瓔花]` |
| 128 | Urumi | 潤美 | 牛崎润美 | `128 Urumi [潤美]` (empty) |
| 129 | Kutaka | 久侘歌 | 庭渡久侘歌 | `129 Kutaka [久侘歌]` |
| 130 | Yachie | 八千慧 | 杨弁庭八千慧 / 八千慧 | `130 Yachie [八千慧]` |
| 131 | Mayumi | 磨弓 | 杖刀偶磨弓 | `131 Mayumi [磨弓]` (empty) |
| 132 | Keiki | 袿姫 | 埴安神袿姬 | `132 Keiki [袿姫]` |
| 133 | Saki | 早鬼 | 骊驹早鬼 | `133 Saki [早鬼]` |
| 134 | Miyoi | 美宵 | 殿户美宵 / 美宵 | `134 Miyoi [美宵]` |
| 135 | Mike | ミケ | 三毛 / 密绵猫 | `135 Mike [ミケ]` (empty) |
| 136 | Takane | たかね | 山城高祢 / 天弓孝 | `136 Takane [たかね]` (empty) |
| 137 | Sannyo | 駒草 | 驹草山如 | `137 Sannyo [駒草]` (empty) |
| 138 | Misumaru | 魅須丸 | 玉造魅须丸 | `138 Misumaru [魅須丸]` (empty) |
| 139 | Tsukasa | 典 | 菅牧典 | `139 Tsukasa [典]` |
| 140 | Megumu | 龍 | 饭纲丸龙 | `140 Megumu [龍]` |
| 141 | Chimata | 千亦 | 天弓千亦 | `141 Chimata [千亦]` |
| 142 | Momoyo | 百々世 | 太田百百世 | `142 Momoyo [百々世]` (empty) |
| 143 | Yuuma | 尤魔 | 尤魔 / 优魔 (吉吊八千慧的同伴) | `143 Yuuma [尤魔]` |
| 144 | Ibaraki's Arm | 影華扇 | 影华扇 (茨木的手臂) | `144 Ibaraki's Arm [影華扇]` (empty) |
| 146 | Elis | エリス | 艾莉丝 (PC-98 旧作) | `146 Elis [エリス]` (empty) |
| 147 | Sariel | サリエル | 萨莉艾尔 | `147 Sariel [サリエル]` (empty) |
| 148 | Sara | サラ | 萨拉 | `148 Sara [サラ]` (empty) |
| 149 | Orange | オレンジ | 奥伦琪 | `149 Orange [オレンジ]` (empty) |
| 150 | Konngara | 矜羯羅 | 矜羯罗 | `150 Konngara [矜羯羅]` (empty) |
| 151 | YuugenMagan | ユウゲンマガン | 幽玄魔眼 | `151 YuugenMagan [ユウゲンマガン]` (empty) |
| 152 | Kikuri | キクリ | 菊理 | `152 Kikuri [キクリ]` (empty) |
| 154 | Enoko | 慧ノ子 | 慧之子 | `154 Enoko [慧ノ子]` |
| 159 | 先代 | 先代 | 先代博丽巫女 | `159 先代` |

**Skipped IDs**: 145, 153, 155-158 — no directory exists.

**To resolve a user-given Chinese name to an ID**:
1. Search the 中文常用名 column for an exact or partial match.
2. If multiple plausible matches (e.g. user says "舞" — could be 105 Mai PC-98 or 122 丁礼田舞), confirm with the user using both English/romaji and the era to disambiguate ("你是指 PC-98 旧作的舞 (105) 还是后期作品的丁礼田舞 (122)？").
3. The directory under `個人口上/` is the source of truth — once you know the ID, the directory name is fixed and you can build all paths from it.
