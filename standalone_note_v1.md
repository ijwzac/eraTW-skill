# eraTW 口上 — Structural Reference (v1)

**Purpose**: this is a self-contained reference for the *structure* of `個人口上/<id> <name>/<variant>/` directories — the per-character kōjō (口上, "dialogue") files that drive eraTW's character dialogue & behavior. It is intended for downstream LLMs scanning character dirs to identify novel features.

**Scope**: structure and language only. Personality/voice is per-author and out of scope.

**Synthesis sources**: 006 Luna, 042 Hatate, 049 Satori, 139 Tsukasa.

---

## 1. The dispatch contract

### 1.1 What an "individual kōjō" is

eraTW is implemented in **Emuera** (an interpreter for the era-script DSL). The engine drives the game-loop and per-character behavior, but at every "should this character speak now?" point it dispatches into per-character labels using `TRYCALLFORM`/`TRYCCALLFORM` (silent on missing label). This means **every kōjō is a set of labels keyed by a fixed naming convention**, scattered across one or more `.ERB` files in the character's directory.

An "individual kōjō" lives at:
```
ERB/口上・メッセージ関連/個人口上/<3-digit-ID> <ROMAJI_NAME> [<JP_NAME>]/<author-variant-name>/
```

Inside the variant directory, files are named `M_KOJO_K<id>_<category>.ERB` (or `.erb`). The engine doesn't enforce *which* file holds *which* label — only that the *labels* exist with the right names.

### 1.2 The dispatcher in `KOJO_MESSAGE.ERB`

The central function is `@KOJO_MESSAGE_SEND(ARGS, ARG:1, ARG:2, ...)`. It receives:
- `ARGS` — a string-key for the kind of dialogue: `"ENCOUNTER"`, `"SP_EVENT"`, `"EVENT"`, `"COMMAND"`, `"COUNTER"`, `"PALAM"`, `"MARK"`, `"DIRECT"`, `"SUCCESS"`, `"ENDING"`, plus extensions: `"ONABARE"`, `"PERMISSION"`, `"LOST_VIRGIN_STOP"`, `"CHILD"`, `"DANMAKU"`, `"IRAI"`, `"GIFT"`, `"DAILY"`, `"DIARY"`, `"MUSHI_BATTLE"`, `"GRAVITY"`, `"SUIKA"`, `"ODEKAKE"`, `"SEX_FRIEND"`, `"BEFORETRAIN"`.
- `ARG:1` — numeric event/command id.
- `ARG:2` — the speaker (a character id).
- `ARG:3..6` — extra args.
- `ARGS:1`, `ARGS:2` — string-form id and extra string arg.

Inside, a giant `SELECTCASE ARGS` constructs a label name dynamically and invokes it. The construction is roughly:

```
TRYCALLFORM M_KOJO%RESULTS%_<KIND>_K{NO:TARGET}_{ARG:1}(ARG:3, ARG:4)
;          ^^^^^^^^                ^^^^^^^^^^   ^^^^^^^
;          kōjō-selector           char-id      event/command id
```

`RESULTS` is a per-character "kōjō selector" string set during the existence check (see §1.4). For most characters it's empty; some (e.g. Satori) set `RESULTS = "_ORTHODOX"` and prefix all labels accordingly.

### 1.3 The dispatch shapes (every label-form the engine looks for)

| Engine path | Label name template | Body invoked when |
|---|---|---|
| Existence | `@M_KOJO_K{id}(ARG)` | Engine asks "does this char have kōjō?" — must `RETURN 1`; can also set `RESULTS` (selector) and `RESULTS:1` (locale). Some authors version this as `@M_KOJO_K{id}_<v>(ARG)`. |
| Per-turn init | `@M_KOJO[%RESULTS%_]FLAGSETTING_K{id}` | Every turn, before kōjō runs. Authors flip `CFLAG:N:時間停止口上有/眠姦口上有/扮演口上有/破瓜中止口上有/口上内抱き寄せ判定_*/推倒禁止/来訪不能` here, and run their character-private state machine. |
| Color | `@M_KOJO[%RESULTS%_]COLOR_K{id}` | Every line; called to `SETCOLOR` for this character's voice. |
| Update | `@M_KOJO[%RESULTS%_]UPDATE_K{id}` | First-load / version-up; one-shot UI. |
| Encounter | `@M_KOJO[%RESULTS%_]ENCOUNTER_K{id}` | First-meeting cutscene. |
| Special event | `@M_KOJO[%RESULTS%_]SPEVENT_K{id}_{ev}(ARG, ARG:1)` | Dispatcher passes positional args: `ARG = sub-state` (0/1/2/...), `ARG:1 = secondary`. Body usually first calls `CALL SPEVENT_MESSAGE_{ev}(ARG, ARG:1)` for default narration, then prints the per-character version. |
| Generic event | `@M_KOJO[%RESULTS%_]EVENT_K{id}_{ev}(ARG, ARG:1)` | Like SPEVENT but for non-special. Engine has slots 1..30+ and named slots like `_ONABARE_<n>`. |
| Command (primary) success-flag | `@M_KOJO[%RESULTS%_]SUCCESS_COM_K{id}_{cmd}` | Before the message, sets `TFLAG:192` to control success/failure: `-2` end command, `-1` forced-fail, `0` COM-default, `1` forced great-success. |
| Command (primary) message | `@M_KOJO[%RESULTS%_]MESSAGE_COM_K{id}_{cmd}` | Per-command speech. Convention: `CALL TRAIN_MESSAGE` then dispatch to body. |
| Command (sub) message | `@M_KOJO[%RESULTS%_]MESSAGE_SCOM_K{id}_{cmd}` | Sub-command (TFLAG:50-driven SCOM family). Multi-person SCOM has `_<cmd>_1` (first participant) and `_<cmd>_2` (second). |
| Catch-all command | `@M_KOJO[%RESULTS%_]MESSAGE_COM_K{id}_00` | Fallback for any command this character handles generically. Engine tries this if the specific `_{cmd}` is missing. |
| Counter | `@M_KOJO[%RESULTS%_]MESSAGE_COUNTER_K{id}_{n}` | Auto-counter (idle reactions). `CALL EVENT_COUNTER_MESSAGE` then dispatch. |
| Danmaku | `@M_KOJO[%RESULTS%_]MESSAGE_COM_K{id}_DANMAKU(ARGS, 相手残機)` | Single label, scene picked by `ARGS` string: `"戦闘前"`, `"ハンデ"`, `"被弾"`, `"残忍酷薄"`, `"乾坤一擲"`, `"怪力乱神"`, `"戦闘後"`. |
| Mark / imprint | `@M_KOJO[%RESULTS%_]MESSAGE_MARKCNG_K{id}` | Engine sets one of `TFLAG:21` (反発), `TFLAG:22` (苦痛), `TFLAG:23` (快楽), `TFLAG:24` (不埒), `TFLAG:時姦刻印取得`, then calls. |
| Quest | `@M_KOJO_IRAI_K{id}(ROLE, SCENE, IRAI_ID)` | `ROLE`: `"CLIENT"` / `"TARGET"` / `"NO_REPORT"`. `SCENE`: `"依頼提示時"`, `"依頼非受託時"`, `"依頼受託時"`, `"依頼確認時"`, `"依頼破棄時"`, `"依頼実行直前"`, `"依頼実行直後"`, `"成功報告時"`, `"失敗報告時"`, `"依頼報告不要"`. Decode `IRAI_ID % 1000` for sub-id. |
| Diary | `@DIARY_K{id}_EXIST` (ret 1), `@DIARY_BEFORE_CHECK_K{id}` (set DIARY:N:M states), `@DIARY_TEXT_K{id}, PAGENUM, MODE, PAGECOUNT` (body), `@DIARY_AFTER_CHECK_K{id}` (cleanup); `@M_KOJO_MESSAGE_COM_K{id}_406` for "read diary" command. |
| Orgasm hook | `@M_KOJO[%RESULTS%_]MESSAGE_PALAMCNG_B_K{id}` | Engine calls when target climaxes. Branches on `NOWEX:Ｃ絶頂/Ｖ絶頂/Ｂ絶頂/Ａ絶頂/Ｍ絶頂/射精/噴乳/放尿/TotalEX`, `SYNCED_ORGASM(N)`, `TEQUIP:Ｖ接触部位`. |
| Child rearing | `@M_KOJO_EVENT_K{id}_CHILD_RAISING_<key>` (lifecycle: `_回復, _離乳, _玩具, _つかまり立ち, _よちよち, _会話寸前, _喋る, _語彙, _しつけ, _就学, _自立前, _自立`) and `_CHILD_RAISING_<activity>(ARGS, ARG, ARG:1)` (`_登下校, _吃飯, _BATH, _SLEEPING, _OYASUMI, _TOY, _OTHER`). Letters: `_CHILD_DIARY_口上手紙(ARG)`, `_CHILD_DIARY_共通手紙(ARG, ARGS)`, `_CHILD_DIARY_寺子屋(ARGS, ARG, ARG:1)`. |
| 角色介绍 (info screen) | `@CHARA_INFO_KOJO_K{id}()` | Override "角色介绍" tab content. Author-level — engine queries it when player opens the info pane. |
| Char-unique counters | `@UNIQUE_COUNTER<n>_ABLE_K{id}` (ret 0/1), `_FREQUENCY_K{id}` (set `RESULTS = "<type>"`, ret base+10 frequency), `_MESSAGE_K{id}` (print body), `_SOURCE_K{id}` (side-effects). `<type>` ∈ `ソフト, ベリーソフト, コミュ, 着衣, 脱衣愛撫, 脱衣強要, 抱き着き, 性交, 責め, おねだり`. |

### 1.4 The "kōjō selector" (`RESULTS` infix)

`@M_KOJO_K<id>(ARG)` is the existence check. Inside, an author can set `RESULTS = "_<NAME>"` to declare a selector, and prefix every other label with that selector. The dispatcher then looks for `M_KOJO<RESULTS>_*` instead of `M_KOJO_*`.

Example (Satori):
```erb
@M_KOJO_K49_3(ARG)
RESULTS:1 = 日版
RESULTS = _ORTHODOX
RETURN 1
```
→ engine looks for `@M_KOJO_ORTHODOX_EVENT_K49_1`, etc.

This lets multiple "voicings" of the same character coexist in the same dir (e.g. `_ORTHODOX_`, `_DRUNK_`, `_TEST_`). Empty `RESULTS = ""` is the default.

`RESULTS:1` is the locale (e.g. `日版`) — informational, doesn't affect dispatch.

### 1.5 Fallback hierarchy

When a specific kōjō label is missing, the engine falls through:

1. `M_KOJO[%RESULTS%_]MESSAGE_COM_K{id}_{cmd}` (specific).
2. `M_KOJO[%RESULTS%_]MESSAGE_COM_K{id}_00` (catch-all for this character).
3. `EVENT_MESSAGE_COM_*` files in `ERB/口上・メッセージ関連/` (engine defaults).
4. If `CFLAG:N:自動喘息`, `CALL AUTO_AEGI(N)` (auto-moan).

Bodies that should **silently produce no output** can `RETURN 1` after `LOCAL = 0`-gating, suppressing default fall-through.

---

## 2. File set & directory conventions

### 2.1 Variant directories

Every character ID has 1+ author-variant subdirectory:
- `006 Luna [ルナ]/ルナチャイルド/` — single variant.
- `042 Hatate [はたて]/{はたて, 试做型姫海棠 自制别人}/` — two.
- `049 Satori [さとり]/{さとり, さとり(24.5.14), 古明地觉_试制口上v0.053}/` — three.

**Only one variant is active** at runtime per character — but all coexist in the tree because the engine just scans for `.ERB` and the dispatcher's `RESULTS` selector keys which one fires.

### 2.2 File taxonomy

In a variant directory, files split labels by category. Conventional names (deviations exist):

| File | Holds |
|---|---|
| `M_KOJO_K{id}_イベント.ERB` | `@M_KOJO_K{id}` (existence), `_FLAGSETTING`, `_COLOR`, `_UPDATE`, `_ENCOUNTER`, `_SPEVENT_*`, `_EVENT_*`. **Often the largest file.** |
| `M_KOJO_K{id}_日常系コマンド.ERB` | COMs in 300–4xx range (talk/touch/cook/eat/work/...). |
| `M_KOJO_K{id}_性交系コマンド.ERB` | COMs in 60–7x range (penetrative). |
| `M_KOJO_K{id}_セクハラコマンド.ERB` | COMs in 310–330 range (sexual harassment). |
| `M_KOJO_K{id}_愛撫系コマンド.ERB` | foreplay COMs. |
| `M_KOJO_K{id}_加虐系コマンド.ERB` | SM 100–108. |
| `M_KOJO_K{id}_ハードなコマンド.ERB` | "hard" extra. |
| `M_KOJO_K{id}_奉仕系コマンド.ERB` | service-led COMs. |
| `M_KOJO_K{id}_道具系コマンド.ERB` | toys 40–4x, 100–18x. |
| `M_KOJO_K{id}_派生コマンド.ERB` | SCOMs. |
| `M_KOJO_K{id}_カウンター.ERB` | COUNTER labels. |
| `M_KOJO_K{id}_弾幕勝負.ERB` | DANMAKU. |
| `M_KOJO_K{id}_依頼.ERB` | IRAI quest dispatcher. |
| `M_KOJO_K{id}_刻印取得.ERB` | MARKCNG. |
| `M_KOJO_K{id}_絶頂.ERB` | PALAMCNG_B (orgasm). |
| `M_KOJO_K{id}_日記.ERB` | DIARY (incl. command 406). |
| `M_KOJO_K{id}_育児イベント.ERB` | CHILD_RAISING / CHILD_DIARY. |
| `M_KOJO_K{id}_コマンド.ERB` | misc / catch-all (some authors merge categories here). |
| `M_KOJO_K{id}_関数ライブラリ.ERB` | author-private helpers — `#FUNCTION` definitions. |
| `M_KOJO_K{id}_<charname>特殊イベント.ERB` | author-private major one-shot events `@K{id}_<NAME>`. |
| `M_KOJO_K{id}_コマンド自動喘ぎ.ERB` | auto-pant string-construction. |
| `M_KOJO_K{id}_コマンド酔夢想.ERB` | drunken-state extra dialogue. |
| `K{id}_固有カウンター<n>_<name>.ERB` | char-unique counter scaffold. |
| `K{id}C_<charname>用DIM.ERH` | constant declarations (`#DIM CONST`). |
| `Lib/` | optional subdir for library files (loaded recursively). |
| `自分用メモ/` | optional author memo subdir. |
| `readme.txt`, `ライセンス.txt`, `ライセンステンプレ.txt`, `フラグ管理メモ.txt`, `衣装メモ.txt`, `CFLAG一覧.txt`, `omake.txt`, etc. | author docs/memos. **Not loaded by engine** (only `.ERB`/`.erb`/`.ERH` are). |

Variant alternatives:
- **Sub-directory layout** (Satori v0.053): `一般/`, `性/`, `自作/`, `其它/` — files prefixed `M_KOJO_K{id}_<eventid>_*` per topic.
- **Per-event-id files** (Satori 24.5.14): `M_KOJO_K{id}_イベント_<eventid>(<title>).erb` — one file per event.
- **Single-file consolidation** (Hatate 试做型): everything packed into `M_KOJO_K{id}_イベント.ERB`, `M_KOJO_K{id}_コマンド.ERB`, `M_KOJO_K{id}_COUNTER.ERB` — three big files.

### 2.3 Cross-cutting directory in `ERB/口上・メッセージ関連/`

```
COMMON_KOJO.ERB         — SAMEROOM, KOJO_ACTIVE_INFO, SET_KOJO_COLOR,
                          SEND_ASSISTANT_KOJO, OPPAI_DESCRIPTION
KOJO_MESSAGE.ERB        — the dispatcher (SELECTCASE ARGS giant)
EVENT_MESSAGE.ERB       — engine-default post-train messages
EVENT_MESSAGE_COM*.ERB  — engine-default per-command messages (no specific char)
EVENT_MESSAGE_*.ERB     — defaults for marks, orgasm, derived COMs, undress, etc.
AUTO_AEGI.ERB           — auto-moan fallback
STAND_COM_IMAGE.ERB     — command-image display
TINKO_TYPE.ERB          — penis-type description
個人口上/                — per-character dirs (this doc's focus)
```

Bodies often `CALL` into these:
- `CALL TRAIN_MESSAGE` — engine pre-message before a primary COM.
- `CALL EVENT_COUNTER_MESSAGE` — pre-message before a COUNTER.
- `CALL MARK_MESSAGE` — pre-message before MARKCNG.
- `CALL SPEVENT_MESSAGE_<n>(ARG, ARG:1)` — engine's default narration for SPEVENT `n`.
- `CALL AUTO_AEGI(N)` — engine's auto-moan for char N.

---

## 3. The DSL (Emuera-script) used in bodies

### 3.1 Syntax

| Construct | Form |
|---|---|
| Label declaration | `@LABEL_NAME` or `@LABEL_NAME(ARG, ARGS, ARG:1, TYPE = 0)` (default args allowed). |
| Numeric local | `LOCAL`, `LOCAL:1`, …, `LOCAL:101`. The `:N` index = element N of the array. |
| String local | `LOCALS`, `LOCALS:1`, … |
| Variable declaration | `#DIM <name>`, `#DIMS <name>` (string), `#DIM CONST <name> = <val>` (compile-time). Optional `<size>` and `= <a>, <b>, …` for array literal init. |
| Function marker (numeric) | `#FUNCTION` directly after the label. Returns via `RETURNF <int>`. |
| Function marker (string) | `#FUNCTIONS`. Returns via `RETURNF "<str>"`. |
| Set local-array size | `#LOCALSIZE 200` |
| Conditional | `IF / ELSEIF / ELSE / ENDIF` (block); `SIF <cond>` (single-line — applies only to the next stmt). |
| Switch | `SELECTCASE <expr> / CASE <vals|TO|IS> / CASEELSE / ENDSELECT`. Examples: `CASE 0 TO 2`, `CASE Is >= 4`, `CASE 1, 3, 5`. |
| Loop | `FOR LOCAL, start, end / NEXT` (end exclusive). `BREAK`, `CONTINUE`. |
| Goto | `$LABEL` then `GOTO LABEL`. Common idiom: `$LOOP / ... / GOTO LOOP` for INPUT retry. |
| Block exclude | `[SKIPSTART] ... [SKIPEND]` — preprocessor: lines inside are not compiled. |
| Calls | `CALL <LABEL>(args)`, `TRYCALL <LABEL>` (silent on missing), `CALLFORM <prefix>{<expr>}<suffix>(args)` (dynamic name), `TRYCALLFORM` (silent), `TRYCCALLFORM ... CATCH ... ENDCATCH` (try/catch). |
| Return | `RETURN <int>` (a numeric body), `RETURNF <val>` (a `#FUNCTION` body), `RETURN` (void). |
| Output | `PRINTL`, `PRINTW` (wait), `PRINTFORML` (with `%...%`), `PRINTFORMW`, `PRINTFORMD` (??), `PRINTFORMDL` (with delimiter), `PRINTFORMDW`. |
| Random text picker | `PRINTDATA / DATAFORM <text> / ENDDATA` — engine picks one DATAFORM at random. |
| Color | `SETCOLOR <NAMED|0xHEX|R,G,B>`, `RESETCOLOR`. Named: `C_CREAM`, `C_AQUA`, `C_PINK`, `C_DEFCOLOR`, `C_HTML`, etc. |
| Comment | `;` to end of line. |
| Author-region marker | `;==================================================` and `;-------------------------------------------------` are conventional banners; `;※※※…` for section dividers. Not interpreted. |

### 3.2 Output-string interpolation

Inside a `PRINTFORML` (or `PRINTFORMW` etc.) text, the following are expanded at print time:

| Form | Means |
|---|---|
| `%CALLNAME:N%` | display-name of character `N` (or `MASTER`/`PLAYER`/`TARGET`/`ASSI`). |
| `%MASTERNAME:N%` | the per-character nickname for MASTER (mutable: `MASTERNAME:N = "..."`). |
| `%CHILDNAME:char_id:idx%` | child name for `char_id`'s `idx`-th child. |
| `%NAME:N%` | the player's true name. |
| `%CSVCALLNAME(N)%` | display-name from CSV (lookup-table form). |
| `%CSVCSTR(N, slot)%` | per-character string from CSV row N, slot `slot`. |
| `%TEXTR("a/b/c/d")%` | random pick of `a`, `b`, `c`, or `d`. |
| `%UNICODE(0xN)%` | arbitrary unicode char (`0x2665` = ♥). |
| `%PANTSNAME(EQUIP:..., N)%` | engine helper: panties-description by equip+char. |
| `%CLOTHNAME(slot, EQUIP:N:slot)%` | engine helper: cloth-description. |
| `%OPPAI_DESCRIPTION(N, 1)%` | engine helper: breast-description. |
| `%PANTS_DESCRIPTION(EQUIP:..., N)%` | similar. |
| `%SHOW_BOTTOM(N)%` | similar. |
| `%"text", width, LEFT%` | fixed-width padded text. |
| `\@ <expr> ? <a> # <b> \@` | inline ternary, evaluated at print time. |
| `{<expr>}` | numeric/string expression interp (in CALLFORM and inside `PRINTFORM`). |

### 3.3 Special tokens

| Token | Means |
|---|---|
| `[[<name>]]` | parse-time look-up of character ID by display-name (e.g. `[[極]]` resolves to 42 via `STR.csv`). |
| `@"text"` | a string literal that supports trailing `//` for line breaks (used in `SPTALK`, `HPH_PRINT`). |

### 3.4 Built-in math/string ops in expressions

- `+`, `-`, `*`, `/`, `%`, `++`, `--`, `+=`, `-=`, etc.
- Bitwise: `&`, `|`, `^`, `~`. (`!` boolean negation is also a thing.)
- Comparison: `==`, `!=`, `<`, `<=`, `>`, `>=`.
- Logical: `&&`, `||`, `!`.
- `RAND:N` — uniform 0..N-1. `RAND(N)` form in expressions also works.
- `MAX(a, b)`, `MIN(a, b)`, `ABS(n)`.
- `STRLENS(s)`, `STRLENSU(s)` (unicode-aware), `STRCOUNT(s, "regex")`, `REPLACE s, "regex", "replacement"`.
- `INRANGE(v, lo, hi)`.
- `INPUT` — read int into RESULT. `INPUTS` — read string into RESULTS.
- `CLEARLINE 1`, `REUSELASTLINE <text>` — UI manipulation.
- `PRINTBUTTON @"label", @"return-string"` — clickable button.
- `SETBIT <var>, <bit>`, `CLEARBIT <var>, <bit>`, `GETBIT(<var>, <bit>)`.
- `VARSET <name>` (clear), `VARSET <name> <value>` (set).

---

## 4. The state-bus (every namespace bodies read or write)

### 4.1 Per-character namespaces

(`N` = char ID. Default = `TARGET`. `MASTER`, `PLAYER`, `ASSI`, `RANDOM_CHARANUM` resolve to char IDs.)

| Namespace | What it stores | Examples |
|---|---|---|
| `TALENT:N:slot` | Talents/traits — boolean flags or small ints. | `TALENT:恋慕`, `TALENT:思慕`, `TALENT:恋人`, `TALENT:愛欲`, `TALENT:炮友`, `TALENT:処女`, `TALENT:無接吻経験`, `TALENT:兒童`, `TALENT:幼児／幼児退行`, `TALENT:年齢`, `TALENT:体型`, `TALENT:形状`, `TALENT:胸圍`, `TALENT:性別`, `TALENT:酒耐性`, `TALENT:妊娠`, `TALENT:育児中`, `TALENT:妊娠願望`, `TALENT:大胃王`, `TALENT:坦率`, `TALENT:自尊心`, `TALENT:無知`, `TALENT:小悪魔`, `TALENT:魅力`, `TALENT:魅惑`, `TALENT:謎之魅力`, `TALENT:膽怯`, `TALENT:傲慢`, `TALENT:叛逆`, `TALENT:施虐狂`, `TALENT:性別嗜好`, `TALENT:両面通吃`, `TALENT:讨厌男人`, `TALENT:思慕`, `TALENT:態度` (-2..0..+2), `TALENT:非処女`, `TALENT:非童貞`, `TALENT:破瓜`, `TALENT:Ａ破瓜`, `TALENT:出産経験`, `TALENT:膣射経験`, `TALENT:人妻`, `TALENT:未亡人` … |
| `ABL:N:slot` | Abilities (-1..0..+5 or so, like grades). | `ABL:親密`, `ABL:欲望`, `ABL:Ｂ感覚`, `ABL:Ａ感覚`, `ABL:Ｃ感覚`, `ABL:Ｖ感覚`, `ABL:Ｐ感覚`, `ABL:Ｍ感覚`, `ABL:従順`, `ABL:奉仕精神`, `ABL:教養`, `ABL:料理技能`, `ABL:戦闘能力`, `ABL:露出癖`, `ABL:接吻経験`, `ABL:学習経験`, `ABL:愛情経験`, `ABL:約會経験`, `ABL:演奏経験`, `ABL:出産経験`. |
| `EXP:N:slot` | Experience — counters. | `EXP:接吻経験`, `EXP:料理経験`, `EXP:愛情経験`, `EXP:約會経験`, `EXP:学習経験`, `EXP:60..63` (sex-act counters), `EXP:出産経験`, `EXP:無自覚絶頂経験`. |
| `BASE:N:slot` | Physiological base values. | `BASE:勃起`, `BASE:体力`, `BASE:酒気`, `BASE:活力`, `BASE:精神`, `BASE:興奮`, `BASE:疲労`. |
| `MAXBASE:N:slot` | Max base values. | `MAXBASE:酒気`, `MAXBASE:勃起`. |
| `NOWEX:N:slot` (or `NOWEX:slot`) | Current physiological event state. | `NOWEX:射精`, `NOWEX:噴乳`, `NOWEX:放尿`, `NOWEX:Ｃ絶頂`, `NOWEX:Ｖ絶頂`, `NOWEX:Ｂ絶頂`, `NOWEX:Ａ絶頂`, `NOWEX:Ｍ絶頂`, `NOWEX:TotalEX`, `NOWEX:11` (??). |
| `EX:slot` | Engine-side cumulative state. | `EX:膣内精液`. |
| `PALAM:slot` | Parameters (HP/MP-style; or status). | `PALAM:欲情`. |
| `PALAMLV:N` | Threshold lookup — "level N of parameter scaling". | Used in `IF PALAM:欲情 >= PALAMLV:5`. |
| `MARK:N:slot` | Marks/imprints (-1..0..+3). | `MARK:不埒刻印`, `MARK:反発刻印`, `MARK:苦痛刻印`, `MARK:快楽刻印`, `MARK:時姦刻印`. |
| `STAIN:N:slot` | Body-fluid stains. | `STAIN:精液`, `STAIN:愛液`, `STAIN:汗`. |
| `EQUIP:N:slot` | Equipment slots. | `EQUIP:下半身内衣２`, `EQUIP:上半身内衣１`, `EQUIP:上半身内衣２`, `EQUIP:服`, `EQUIP:139:7`. |
| `TEQUIP:N:slot` (or `TEQUIP:slot`) | Per-target equipment (insertion). | `TEQUIP:50` / `:51` (V/A insertion), `TEQUIP:口球`, `TEQUIP:眼罩`, `TEQUIP:縄`, `TEQUIP:陰蒂夾`, `TEQUIP:乳頭夾`, `TEQUIP:振動棒`, `TEQUIP:子宮`, `TEQUIP:六九式`, `TEQUIP:飛機杯`, `TEQUIP:Ｖ接触部位`, `TEQUIP:11..18` (touch zones), `TEQUIP:101..107` (secondary touch zones). |
| `CFLAG:N:slot` (or `CFLAG:slot`) | Persistent character flags (any int). Mostly engine-named (`現在位置`, `初期位置`, `面識`, `好感度`, `睡眠`, `約会中`, `妊娠自覚状態`, `無自覚妊娠`, `没穿内裤`, `允许无套`, `清い交際`, `恶作剧`, `出禁`, `推倒禁止`, `来訪不能`, `自動喘息`, `時間停止口上有`, `眠姦口上有`, `扮演口上有`, `破瓜中止口上有`, `口上内抱き寄せ判定_*`, `口上セレクタ`, `继承`, `1000` (color), `345` (??), `318` (silent-treatment?), `诶嘿嘿`, `初次拥抱`); plus author-private numbered slots typically 1000–1999. |
| `TCVAR:N:slot` (or `TCVAR:slot`) | Per-target transient (per-day) variables. Engine-named (`破瓜`, `Ａ破瓜`, `中止接吻`, `烂醉`, `初次拥抱`, `媚薬`, `今天的礼物`, `発情`, `100` / `101` (last V/A inserter ID), `102` / `104` (climax flags), `112` (??), `302` (talk-availability), `350..399` author-private). |
| `CSTR:N:slot` | Per-character mutable string slots. (Used for nicknames, custom info-text.) |
| `DIARY:N:M` | Diary state for char N, page M: 0 = locked, 1 = read, 2 = daily-event-readable, 3 = on-demand-readable. |
| `MAX_DIARY_PAGE:N:0` | Total diary pages for N. |

### 4.2 Per-game globals

| Global | Means |
|---|---|
| `FLAG:slot` (or `FLAG:NUMBER`) | Global flags. `FLAG:70` = time-stop active (alias `FLAG:時間停止`); `FLAG:扮演` = role-play target char ID; `FLAG:出禁人数` = banned-character count; `FLAG:周回数` = game-cycle (NG+) count; `FLAG:口上文本設定`, `FLAG:口上色`, `FLAG:口上セレクタ`; `FLAG:約会的对象`; `FLAG:6` (??); `FLAG:甲斐性無`. |
| `TIME` | Minutes-of-day. |
| `TIME:2` | Hour bucket. |
| `TIME:5` | Weather phase (4–7 = rain, 5 = heavy rain). |
| `DAY:0` | Game-day count. |
| `DAY:2` | ?(month-of-year). |
| `DAY:3` | ?(day-of-month). |
| `MAIN_MAP` | Current world-map ID (0 = Hakurei, 1 = Myouren, 2 = Human Village, 3 = Scarlet, 4 = Bamboo, 5 = Magic Forest, 6 = Sanzu, 7 = Tengu Mountain (foot), 8 = Tengu Mountain (peak), 9 = Underground, …). |
| `SELECTCOM` | Currently-selected command ID — **mutable**: bodies sometimes reassign for delegation. |
| `TFLAG:50` | Active sub-command (SCOM) ID. |
| `TFLAG:192` | Override for SUCCESS_COM (-2/-1/0/1). |
| `TFLAG:193` | Mood/result of the action (-5..-1..0..1..2..N). |
| `TFLAG:194` | Sub-result (e.g. for 推倒: 0..4 = different rejection reasons). |
| `TFLAG:21..24` | Mark codes (反発/苦痛/快楽/不埒). |
| `TFLAG:時姦刻印取得` | Mark code (時姦). |
| `TFLAG:62` | (Hatate uses for "time-stop suppress.") |
| `TARGET`, `MASTER`, `PLAYER`, `ASSI` | Char-ID resolutions for the active speaker, player, player's char id, assistant. |
| `CHARANUM` | Total characters. |
| `RANDOM_CHARANUM` | Marker for "random char". |
| `TARGET:N` | N-th element of the multi-target array (`TARGET:0` = current). |
| `RESULT`, `RESULTS` | Return values from the most recent CALL/INPUT. |
| `PREVCOM` | Previous command. |

### 4.3 SOURCE — the post-action affection ledger

```erb
SOURCE:[[char]]:slot += N
```

Bodies write `SOURCE:` as side-effect, and `ステータス計算関連/` reads it at end-of-turn to apply ABL/EXP/CFLAG:好感度 deltas. **Counter and unique-counter handlers should always update SOURCE.** Common slots:

`性行動, 露出, 逸脱, 与快Ｃ, 誘惑, 侮辱, 挑発, 加虐, 征服, 情愛, 愛情経験`.

---

## 5. Engine-side helpers (called from bodies)

### 5.1 Pre-message helpers (call before printing)

- `CALL TRAIN_MESSAGE` — engine's default narration for a primary COM (e.g. "X 说着话。"). Most COM bodies start with this.
- `CALL EVENT_COUNTER_MESSAGE` — pre-narration for a COUNTER.
- `CALL MARK_MESSAGE` — pre-narration for MARKCNG.
- `CALL SPEVENT_MESSAGE_<n>(ARG, ARG:1)` — pre-narration for SPEVENT n.

### 5.2 UI prompts

- `CALL ASK_YN("yes-text", "no-text")` — yes/no. Sets `RESULT` to 0 (yes) / 1 (no). [Note: 0=yes is unusual.]
- `CALL ASK_M("opt0", w0, "opt1", w1, ..., "optN", wN)` — multi-choice with per-option weights (1=enabled, 0=greyed). `RESULT` = chosen index.
- `INPUT` — read int.
- `INPUTS` — read string into `RESULTS`.
- `PRINTBUTTON @"label", @"return-string"`.

### 5.3 Image / face / talk

- `CALL PRINT_FACE, char_id, expr, [clothes, [variant]]` — display character portrait.
  - `expr`: `"通常", "発情", "笑顔", "憤怒", "睡眠", "性交", "自慰"`, …
  - `clothes`: `"服", "服1", "裸", "服+冠"`, …
  - `variant`: `"_1"`, `"_別差分"`, …
- `CALL SPTALK, char_id, expr, ?, @"line // line // line"` — speech bubble. `//` = newline. Up to 6 lines.
- `CALL HPH_PRINT, @"text", "L"` — "panting" stylized print (HPH = author convention).
- `CALL 画像セット(@"<image-key>", x, y, w, h, _, _, "default-image")` — set image.
- `CALL 画像一斉表示(<position>, <flags>, <delay>)` — flush image-set displays.

### 5.4 Pose / state / equip helpers

- `CALL TOUCH_SET(SET_FROM_YUBI, 1, [[N]])` — register a touch-action on N (other modes exist).
- `CALL EVENT_COUNTER_POSE_69([[N]], M)` — set 69 pose.
- `CALL EVENT_COUNTER_POSE_<other>([[N]], M)` — other engine-defined poses.
- `CALL DATUI_BOTTOM([[N]], M)` — undress bottom (`M=1` pull down, `M=2` full strip).
- `CALL DATUI_TOP([[N]], M)`, `CALL DATUI_INNER`, etc. (similar).
- `CALL ADD_KISS` — increment kiss counter.

### 5.5 Predicates / accessors

- `RAND:N` / `RAND(N)` — uniform 0..N-1.
- `FIRSTTIME(<key>)` — has this command been used the first time? Forms:
  - `FIRSTTIME(SELECTCOM)`
  - `FIRSTTIME(SELECTCOM, 1)` — alt second arg.
  - `FIRSTTIME(TFLAG:50 + 500)` — SCOM key (offset by 500).
  - `FIRSTTIME("UP01", 0, 49)` — string-keyed, with char-id scope.
- `GROUPMATCH(VAR, V1, V2, …)` — `VAR == V1 || VAR == V2 || …`.
- `BATHROOM(loc)`, `OUTROOF(loc)`, `DATE_HITOGOMI(loc)`, `WITH_MOB()` — location predicates.
- `GET_MAPID(loc)` — convert loc id → map id.
- `GET_TARGETNUM()` — number of TARGETs in current room.
- `FINDCHARA(start_loc, current_loc)` — char-presence helper.
- `SHIRAHU(N)` — char `N` is in normal state (not asleep/timestopped).
- `CHK_DATENOW(CFLAG:N:約会中)` — date currently underway.
- `CHK_FOCUS(start, current, end)` — focus location range.
- `MASTER_POSE(role, ?, ?)` — multi-person scene participant lookup.
- `ALCOHOL_TASTE(TFLAG:194)` — saké-flavor preference.
- `ESTRUS_CYCLE(N)` — char's estrus phase.
- `SYNCED_ORGASM(N)` — synced climax with N?
- `TIME_PROGRESS(TFLAG:<key>)` — minutes since marker.
- `IRAI_ID_TO_CLIENT(IRAI_ID)`, `IS_COMMON_IRAI(IRAI_ID)`, `STR_DATA_IRAI(IRAI_ID, key, client)`, `CSVCALLNAME(client_id)` — quest helpers.
- `GET_GIFTDATA(item, "key")` — gift-table lookup.
- `CHARA_DIARY_PAGESETTING(char, page)` — register diary page.
- `K_<char-helper>(...)` — per-character author helpers (e.g. `K42_FIND_LOVER`, `陥落状態`).

---

## 6. Author-extension patterns

These are *reusable structural ideas* that the four target characters (and many others) employ.

### 6.1 Function library (`関数ライブラリ.ERB` or `Lib/`)

A set of `#FUNCTION` / `#FUNCTIONS` definitions for character-private helpers. Common ones:

- `@K{id}_FIND_LOVER()` — returns char id of MASTER's lover, or status code.
- `@K{id}_FIND_AROUND()` — returns char id of relevant character in room (priority: known-friend list > random).
- `@K{id}_DRUNK()` — returns drunkenness tier.
- `@K{id}_BOKKI()` — returns erection tier.
- `@K{id}_AENAI` — "days since seen" line.
- `@K{id}_KOUSAI` — anniversary line.
- `@K{id}_NURESUKE()` — wetness/transparency line.
- `@K{id}_AMANURE` — rain-soaking trigger.
- `@K{id}_C_NAME(ARG, TYPE = 0)` — name-of-character lookup.
- `@K{id}_SET_C_NAME(ARG)` — interactive nickname-setting routine.
- `@K{id}_BE_SEEN()` — "is anyone watching?" predicate.
- `@CHARA_INFO_KOJO_K{id}()` — overrides the 角色介绍 tab content.

Pattern: declare `#DIM CONST` constants in a `.ERH` header file (e.g. `K42C_<charname>用DIM.ERH`) for self-documenting CFLAG slot names: `#DIM CONST K42C_結婚 = 1100`. Then bodies write `CFLAG:42:K42C_結婚` instead of `CFLAG:42:1100`.

### 6.2 Special-events library (`<charname>特殊イベント.ERB`)

A set of standalone `@K{id}_<NAME>` labels — major one-shot story events. Each:
- Has a `;CALL K{id}_<NAME>` comment above it documenting the caller convention.
- Branches on its own state-progress CFLAG (e.g. `CFLAG:42:1413` for time-stop-reveal).
- Calls `ASK_YN`/`ASK_M`/`PRINT_FACE`/`HPH_PRINT` for player choices.
- Mutates state at the end (CFLAG progression, TALENT grant, TFLAG/TCVAR set).

Examples:
- `@K42_4KANO` — "the 4 tengus love MASTER" event.
- `@K42_PREGNANCY_DESIRE` — "I want a child."
- `@K139_ONASAPO` — "self-pleasure supporter."
- `@K139_AFFAIR` — "secret affair."

The author's main kōjō files have `IF <conditions> ... CALL K{id}_<NAME>` to invoke them when conditions ripen.

### 6.3 Char-unique counters (`K{id}_固有カウンター<n>_<name>.ERB`)

Per file, four labels:
```
@UNIQUE_COUNTER<n>_ABLE_K{id}        ; eligibility (RETURN 0/1)
@UNIQUE_COUNTER<n>_FREQUENCY_K{id}   ; RESULTS = "<type>"; RETURN base+freq
@UNIQUE_COUNTER<n>_MESSAGE_K{id}     ; print body
@UNIQUE_COUNTER<n>_SOURCE_K{id}      ; SOURCE: ledger updates + pose/touch/undress side-effects
```

`<type>` ∈ `ソフト, ベリーソフト, コミュ, 着衣, 脱衣愛撫, 脱衣強要, 抱き着き, 性交, 責め, おねだり`.

### 6.4 The `LOCAL = 0/1` "filled-in" gate

Every body of a per-command label opens with:
```erb
@M_KOJO_MESSAGE_COM_K<id>_<cmd>_1
LOCAL = 1                          ; 1 = filled, 0 = stub
IF LOCAL
    ; the actual logic
ENDIF
RETURN 1
```

**`LOCAL = 0` is intentional**, not a placeholder — it suppresses the body entirely and falls through to engine defaults. Many commands are stubs with `LOCAL = 0`. Don't "fix" them.

Within a body, sub-branches sometimes use `LOCAL:1 = 0/1` to gate further sub-cases (e.g. "first-time only", "drunk only").

### 6.5 The doc-banner state contract

Every command body is preceded by an inline-comment listing the relevant TFLAG/TCVAR/MARK/CFLAG codes and what each value means. Example:

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

These are not formal docstrings, but every author follows the convention. The values listed are the discriminants that the engine sets before calling, which the body should branch on.

### 6.6 Branching cascades

Canonical relationship-tier cascade:
```erb
IF FLAG:時間停止 (=FLAG:70)            ; time-stop active — short-circuit unless 時間停止口上有 set
    ...
ELSEIF CFLAG:睡眠 (or CFLAG:TARGET:睡眠) ; sleeping — short-circuit unless 眠姦口上有 set
    ...
ELSEIF CFLAG:318 == 1                   ; "extreme silent treatment" / 不機嫌
    ...
ELSEIF CFLAG:诶嘿嘿 == 2                ; drunken / playful "ehehe" mood
    ; sub-action via TCVAR:20
    ...
ELSEIF FLAG:扮演 (or with sub-cases)    ; role-play active
    ...
ELSEIF TALENT:恋人                      ; tier 5 — partner
    ...
ELSEIF TALENT:愛欲 || TALENT:炮友      ; tier 4 — lust without commitment
    ...
ELSEIF TALENT:恋慕                      ; tier 3 — in love
    ...
ELSEIF TALENT:思慕                      ; tier 2 — admiring
    ...
ELSE
    ; tier 1 / 0 — normal / hostile
ENDIF
```

Some authors use a helper `陥落状態()` (fall-tier function) returning 0..5.

Random variation idiom:
```erb
SELECTCASE RAND:N
    CASE 0
        ...
    CASE 1
        ...
    ...
    CASEELSE
        ; default — most-frequent
ENDSELECT
```

### 6.7 Multi-person SCOM dispatch

```erb
@M_KOJO_MESSAGE_SCOM_K<id>_<n>
    CALL TRAIN_MESSAGE
    CALL M_KOJO_MESSAGE_SCOM_K<id>_<n>_1     ; first participant's body
    LOCAL = MASTER_POSE(<role>, 1, 1)         ; resolve 2nd participant id
    LOCAL:1 = RESULT
    LOCAL:2 = TARGET
    TARGET = LOCAL
    TRYCALLFORM M_KOJO_MESSAGE_SCOM_K{TARGET}_<n>_2   ; their version
    TARGET = LOCAL:2
    RETURN LOCAL:1
```

The engine swaps `TARGET` to participant 2 and re-dispatches to **that character's** kōjō. So multi-person SCOM bodies must be aware that they may be called from a partner's TARGET.

### 6.8 `[SKIPSTART]/[SKIPEND]` for embedded multi-line text

Authors embed long author-comments at the top of files using these markers — the preprocessor excludes the lines from compilation. Don't confuse them with conditional-compile.

---

## 7. Edge cases and quirks

- **Default-args**: `@LABEL(ARG, TYPE = 0)` — declares `TYPE` defaults to `0`. Callers may omit.
- **Mutable `SELECTCOM`**: bodies sometimes write `SELECTCOM = 72` to delegate to another COM's body via `CALLFORM M_KOJO_MESSAGE_COM_K<id>_{SELECTCOM}_1`.
- **Counter/unique-counter side effects**: `BASE:MASTER:勃起 += 5`-style mutations are normal in counter handlers. Bodies are not pure-print.
- **Diary state**: `DIARY:N:0` is reserved (don't use). `MAX_DIARY_PAGE:N:0` holds total. `CALL CHARA_DIARY_PAGESETTING(char, page)` to register a page slot. Bodies accept `(PAGENUM, MODE, PAGECOUNT)` args; `MODE` ∈ `"デイリー"` (auto end-of-day) / `"指令"` (`406` "read diary").
- **`@M_KOJO_FLAGSETTING_K<id>`** runs every turn. Use it for character-private state-machine ticks.
- **`@M_KOJO_UPDATE_K<id>`** runs once per game-version-load. Use it for permission UIs (granting talents, choosing nickname mode).
- **`ENCOUNTER` body** can offer one-shot player choices (`INPUT` + `$LOOP / GOTO LOOP`) and can mutate stats/talents.
- **Reincarnation detection**: `FLAG:周回数` ≠ 0 = New Game+. `CFLAG:継承` is a bit-set: bit 0 = was lover, bit 1 = was wife.
- **Role-play detection**: `FLAG:扮演 == N` = MASTER is impersonating char `N`. Combine with `FLAG:出禁人数` (banned count) and `CFLAG:N:出禁` (per-char banned) to handle doppelgänger scenarios.
- **Bit-flag CFLAG**: a single CFLAG slot can carry many booleans. `SETBIT CFLAG:N:slot, k` / `CLEARBIT CFLAG:N:slot, k` / `GETBIT(CFLAG:N:slot, k)`.
- **Author-private CFLAG/TCVAR ranges**: by convention CFLAG 1000–1999 and TCVAR 350–399 are author-private. Engine reserves CFLAG 1998/1999 for UPDATE-path internal use.
- **`@CHARA_INFO_KOJO_K<id>()`** overrides the 角色介绍 tab. The body is rendered when the player opens the info pane. Often state-driven.
- **Per-author-variant kōjō selector**: `RESULTS = "_<NAME>"` in the existence check makes labels prefixed `M_KOJO_<NAME>_*`. Allows multiple coexisting variants.
- **Multi-line button strings**: `@"line // line // line"` — used by `SPTALK` and `HPH_PRINT`. `//` is the line-break.
- **Inline ternary**: `\@ <expr> ? <a> # <b> \@` is evaluated at print time inside `PRINTFORML` and works inside `@"..."` strings too.
- **Random text replace**: `%TEXTR("a/b/c")%` is a built-in RANDOM-pick. Use it inside any `PRINTFORML` for per-line variation that doesn't need branch-level state.
- **Char-unique-counter `RESULTS`**: `_FREQUENCY` returns the frequency *and* sets `RESULTS` to the type-string (`脱衣愛撫`, etc.). Both mean something to the engine.
- **Wetness / transparency state**: `TIME:5` ∈ {4,5,6,7} = rainy weather phases. Authors update `TCVAR:355` (or analog) to track soaked state.
- **Lover-mode nickname**: `MASTERNAME:N = "..."` is per-character mutable. Some authors also keep `CSTR:N:80` (or other slot) for "lover-mode private" name.
- **`@M_KOJO_K<id>(ARG)`** sometimes versioned: `@M_KOJO_K<id>_3(ARG)` means "engine version 3". The engine tries multiple versions for compatibility.
- **ASCII art**: at most 1 character (Satori 24.5.14) ships an ASCII-art library file. The labels are `@FONT_AA_<key>` with body of `PRINTL <multi-line ascii>`. Other characters do not have this.
- **`OBJ/CLASS/`** under ERB root holds engine-side per-class data (clothing IDs, dish flavors). Bodies usually access via interpolation helpers like `%CLOTHNAME(slot, equip)%`, not by direct ID.

---

## 8. Self-test for sub-agents

If you are a sub-agent reading this and scanning a character variant directory, you should be able to:

1. Identify the **set of files** and assign each to a category from §2.2.
2. List every **engine-callable label** in each file using a `^@` regex, and classify each by §1.3 form.
3. Note any **kōjō selector** the existence check sets (RESULTS infix).
4. Identify **author-private files** (`関数ライブラリ`, `特殊イベント`, `Lib/`, `K{id}_固有カウンター*`, `<charname>用DIM.ERH`) and the labels they define.
5. Identify any **non-standard labels** (not in §1.3 list) — these are character-unique extensions.
6. Identify any **non-standard interpolation forms** (not in §3.2) or non-standard primitives.
7. Identify any **CFLAG / TCVAR / TALENT / TEQUIP / etc. slot names** referenced that are not in §4.1's list.
8. Identify any **non-standard helper functions** called (anything not in §5).
9. Identify any **structural patterns** (in §6) used or absent.
10. Flag any **edge cases** (in §7) that this character demonstrates.

Output: list of "novel features" and quote a small representative excerpt for each, plus a count of how many are entirely-new vs. extensions of existing patterns.
