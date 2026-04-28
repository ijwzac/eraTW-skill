# eraTW 口上 — Structural Reference (v2)

**Purpose**: Self-contained reference for the *structure* of `個人口上/<id> <name>/<variant>/` directories — the per-character kōjō files that drive eraTW's character dialogue & behavior.

**Scope**: Structure and language only. Personality/voice is per-author and out of scope.

**v2 changes from v1**: Added the **MESSAGECHECK** dispatch family (engine-side, missed in v1), the **EXTRASOURCE** family, the **new kōjō API** ("カスタム" — custom buttons / talents / commands / version migration), the **PALAMCNG_A/A2/B/B2/F** orgasm matrix, the **SPECIALDAY_EVENT** / **BEFORETRAIN** / **RUN_INTO** / **SF_CONTRACT** / **DAILY_EVENT** label families, the **`SAVEDATA` storage modifier**, the **`RELATION:N:M`** inter-character namespace, the **`CUSTOM_TALENT`** info-pane override, plus ~30 more engine helpers.

---

## 1. The dispatch contract

### 1.1 What an "individual kōjō" is

eraTW is implemented in **Emuera** (an interpreter for the era-script DSL). The engine drives the game-loop and per-character behavior, but at every "should this character speak now?" point it dispatches into per-character labels using `TRYCALLFORM`/`TRYCCALLFORM` (silent on missing label).

An "individual kōjō" lives at:
```
ERB/口上・メッセージ関連/個人口上/<3-digit-ID> <ROMAJI_NAME> [<JP_NAME>]/<author-variant-name>/
```

Inside a variant directory, files are named `M_KOJO_K<id>_<category>.ERB` (or `.erb`/`.ERH`). The engine **doesn't enforce** which file holds which label — only that the *labels* exist with the right names. It scans recursively.

### 1.2 The dispatcher in `KOJO_MESSAGE.ERB`

`@KOJO_MESSAGE_SEND(ARGS, ARG:1, ARG:2, …)` is the central function. ARGS is a string-key for the dispatch kind:

```
"ENCOUNTER"  "SP_EVENT"   "EVENT"   "COMMAND"  "COUNTER"   "PALAM"
"MARK"       "DIRECT"     "SUCCESS" "ENDING"   "ONABARE"   "PERMISSION"
"LOST_VIRGIN_STOP"        "CHILD"   "DANMAKU"  "IRAI"      "GIFT"
"DAILY"      "DIARY"      "MUSHI_BATTLE"       "GRAVITY"   "SUIKA"
"ODEKAKE"    "SEX_FRIEND" "BEFORETRAIN"
```

Other args: `ARG:1` numeric event/command id, `ARG:2` speaker (char id), `ARG:3..6` extra, `ARGS:1..2` string forms.

The dispatcher constructs label names dynamically:

```
TRYCALLFORM M_KOJO%RESULTS%_<KIND>_K{NO:TARGET}_{ARG:1}(ARG:3, ARG:4)
;          ^^^^^^^^                ^^^^^^^^^^^^   ^^^^^^^
;          kōjō-selector           char-id        event/command id
```

`%RESULTS%` is the per-character "kōjō selector" set during the existence check (§1.5).

### 1.3 Engine-callable label catalog (every dispatch shape)

Bracketed `[%RESULTS%_]` slots in the prefix mean: "if a kōjō-selector is set, the engine inserts it here." Most characters leave it empty.

| Engine path | Label template | Notes |
|---|---|---|
| Existence | `@M_KOJO_K{id}(ARG)` (or `@M_KOJO_K{id}_<v>(ARG)`) | Returns 1 to claim the kōjō exists. Set `RESULTS = "_<NAME>"` here for selector. `<v>` = engine-version number for compatibility. |
| Per-turn init | `@M_KOJO[%RESULTS%_]FLAGSETTING_K{id}` | Runs **every turn**. Set `CFLAG:N:時間停止口上有/眠姦口上有/扮演口上有/破瓜中止口上有/口上内抱き寄せ判定_*/推倒禁止/来訪不能/自動喘息`. Author state-machine ticks live here. |
| Color | `@M_KOJO[%RESULTS%_]COLOR_K{id}` | `SETCOLOR` for character voice. |
| One-shot UI | `@M_KOJO[%RESULTS%_]UPDATE_K{id}` | Once per game-version-load. Use `INPUT`/`ASK_YN`/`ASK_M` for permission UIs. |
| First meeting | `@M_KOJO[%RESULTS%_]ENCOUNTER_K{id}` | First-meeting cutscene. Can offer `INPUT` choices and mutate stats/talents. |
| Special event | `@M_KOJO[%RESULTS%_]SPEVENT_K{id}_{ev}(ARG, ARG:1)` | One-shot story events (kiss, confession, return). Body usually first calls `CALL SPEVENT_MESSAGE_{ev}(ARG, ARG:1)`. `ARG = 0/1/2/...` selects sub-state. |
| Generic event | `@M_KOJO[%RESULTS%_]EVENT_K{id}_{ev}(ARG, ARG:1)` | Engine has slots 1..30+ and named slots `_ONABARE_<n>`, `_LOST_VIRGIN_STOP`, `_PERMISSION_<n>`, `_GIFT`, `_GRAVITY`. |
| Daily event | `@M_KOJO[%RESULTS%_]DAILY_EVENT_K{id}_{n}(ARG, ARG:1, ARG:2, ARG:3, ARG:4, ARGS:1, ARGS:2)` | **7-arg signature** — five numeric, two string. |
| Command success-flag | `@M_KOJO[%RESULTS%_]SUCCESS_COM_K{id}_{cmd}` | Set `TFLAG:192` to override (-2 end / -1 fail / 0 default / 1 great-success). |
| Command message | `@M_KOJO[%RESULTS%_]MESSAGE_COM_K{id}_{cmd}` | `CALL TRAIN_MESSAGE` then dispatch to body. |
| Command sub-message | `@M_KOJO[%RESULTS%_]MESSAGE_SCOM_K{id}_{cmd}` | Sub-command (TFLAG:50-driven). Multi-person SCOM has `_<cmd>_1` (first participant) and `_<cmd>_2` (second). |
| Catch-all command | `@M_KOJO[%RESULTS%_]MESSAGE_COM_K{id}_00` | Engine fallback for any cmd this char handles. |
| Counter | `@M_KOJO[%RESULTS%_]MESSAGE_COUNTER_K{id}_{n}` | Auto/idle reactions. `CALL EVENT_COUNTER_MESSAGE` then body. |
| Danmaku | `@M_KOJO[%RESULTS%_]MESSAGE_COM_K{id}_DANMAKU(ARGS, 相手残機)` | Single label, scene picked by `ARGS` string: `"戦闘前"`, `"ハンデ"`, `"被弾"`, `"残忍酷薄"`, `"乾坤一擲"`, `"怪力乱神"`, `"戦闘後"`. |
| Mark / imprint | `@M_KOJO[%RESULTS%_]MESSAGE_MARKCNG_K{id}` | Engine sets `TFLAG:21` (反発), `TFLAG:22` (苦痛), `TFLAG:23` (快楽), `TFLAG:24` (不埒), `TFLAG:時姦刻印取得` then calls. |
| Quest | `@M_KOJO[%RESULTS%_]IRAI_K{id}(ROLE, SCENE, IRAI_ID)` | `ROLE` ∈ `"CLIENT"/"TARGET"/"NO_REPORT"`. `SCENE` ∈ `"依頼提示時"/"非受託時"/"受託時"/"確認時"/"破棄時"/"実行直前"/"実行直後"/"成功報告時"/"失敗報告時"/"報告不要"`. |
| Diary | `@DIARY_K{id}_EXIST`, `@DIARY_BEFORE_CHECK_K{id}`, `@DIARY_TEXT_K{id}, PAGENUM, MODE, PAGECOUNT`, `@DIARY_AFTER_CHECK_K{id}`. Plus `@M_KOJO_MESSAGE_COM_K{id}_406` for the "read diary" command. |
| Diary state-set | `@M_KOJO_DIARYSETTING_K{id}(ARG)` | Optional helper between BEFORE_CHECK and TEXT. |
| Orgasm hook A-tier | `@M_KOJO[%RESULTS%_]MESSAGE_PALAMCNG_A_K{id}` | "After action" generic state-change. |
| Orgasm hook A2-tier | `@M_KOJO[%RESULTS%_]MESSAGE_PALAMCNG_A2_K{id}` | Secondary A-tier (some characters use both). |
| Orgasm hook B-tier | `@M_KOJO[%RESULTS%_]MESSAGE_PALAMCNG_B_K{id}` | Climax: branches on `NOWEX:Ｃ絶頂/Ｖ絶頂/Ｂ絶頂/Ａ絶頂/Ｍ絶頂/射精/噴乳/放尿/TotalEX`, `SYNCED_ORGASM(N)`, `TEQUIP:Ｖ接触部位`. |
| Orgasm hook B2-tier | `@M_KOJO[%RESULTS%_]MESSAGE_PALAMCNG_B2_K{id}` | Secondary climax tier. |
| Orgasm hook F-tier | `@M_KOJO[%RESULTS%_]MESSAGE_PALAMCNG_F_K{id}` | Fallback. |
| Child rearing milestones | `@M_KOJO_EVENT_K{id}_CHILD_RAISING_<key>` | `<key>` ∈ `回復/離乳/玩具/つかまり立ち/よちよち/会話寸前/喋る/語彙/しつけ/就学/自立前/自立`. |
| Child rearing daily | `@M_KOJO_EVENT_K{id}_CHILD_RAISING_<activity>(ARGS, ARG, ARG:1)` | `<activity>` ∈ `登下校/吃飯/BATH/SLEEPING/OYASUMI/TOY/OTHER`. |
| Child letters | `@M_KOJO_EVENT_K{id}_CHILD_DIARY_口上手紙(ARG)`, `_共通手紙(ARG, ARGS)`, `_寺子屋(ARGS, ARG, ARG:1)`. |
| Char-info screen | `@CHARA_INFO_KOJO_K{id}()` (or `@CHARA_INFO_KOJO_<selector>_K{id}()`) | Override 角色介绍 tab. Author-level. |
| Char-unique counter | `@UNIQUE_COUNTER<n>_ABLE_K{id}` (ret 0/1) + `_FREQUENCY_K{id}` (set `RESULTS = "<type>"`, ret base+freq) + `_MESSAGE_K{id}` + `_SOURCE_K{id}`. `<type>` ∈ `ソフト/ベリーソフト/コミュ/着衣/脱衣愛撫/脱衣強要/抱き着き/性交/責め/おねだり`. |
| **Special-day event** | `@SPECIALDAY_EVENT_K{id}` | Anniversary/holiday handler. Branches on `DAY:2` (month) / `DAY:3` (day-of-month). Author-defined. |
| **Pre-train hook** | `@K{id}_BEFORETRAIN` (or `@M_KOJO[%RESULTS%_]_BEFORETRAIN_K{id}`) | Day-start state machine — runs before the engine's TRAIN dispatch. |
| **Run-into / random encounter** | `@RUN_INTO_K{id}(MAP_ID)` | When player enters a map and randomly meets this character. Char-defined. |
| **Sex-friend contract** | `@KOJO_SF_CONTRACT_EVENT_K{id}(ARGS)` | "炮友" agreement event. |
| **Quest blocking** | `@M_KOJO_CHECK_K{id}_IRAI_BLOCKED(ARGS, ARG, ARG:1)` | Predicate to suppress quest dialogue. |

### 1.4 The MESSAGECHECK family (the key v2 addition)

Before invoking any *MESSAGE* body, the engine first looks for a parallel `_MESSAGECHECK_*` label. The label returns a **bitfield**:

| Bit | Meaning |
|---|---|
| `bit 0` | If 1, suppress engine's default narration (the "情景文本" — i.e. the `TRAIN_MESSAGE` / `EVENT_COUNTER_MESSAGE` / `MARK_MESSAGE` / `SPEVENT_MESSAGE_<n>` pre-narration). |
| `bit 1` | If 1, suppress the kōjō's own message body. |

So:
- `RETURN 0` — show both (default).
- `RETURN 1` — hide engine narration, show kōjō.
- `RETURN 2` — show engine narration, hide kōjō.
- `RETURN 3` — hide both.

Use case: a character who at certain moments wants to print their own narration *instead of* the engine's, or wants to print *only* engine narration without the kōjō line.

The dispatcher does:

```erb
TRYCALLFORM M_KOJO%KOJO_NAME%_MESSAGE_MESSAGECHECK_%LOCALS%_K{NO:TARGET}_{LOCAL}
SKIP_MESSAGE = GETBIT(RESULT, 0)
SKIP_KOJO    = GETBIT(RESULT, 1)
```

The MESSAGECHECK family covers all dispatch kinds:

| Engine path | Label template |
|---|---|
| Command | `@M_KOJO[%RESULTS%_]MESSAGE_MESSAGECHECK_COM_K{id}_{cmd}` |
| Sub-command | `@M_KOJO[%RESULTS%_]MESSAGE_MESSAGECHECK_SCOM_K{id}_{cmd}` |
| Special event | `@M_KOJO[%RESULTS%_]SPEVENT_MESSAGECHECK_K{id}_{ev}` |
| Generic event | `@M_KOJO[%RESULTS%_]EVENT_MESSAGECHECK_K{id}_{ev}` |
| Counter | `@M_KOJO[%RESULTS%_]MESSAGE_COUNTER_MESSAGECHECK_K{id}_{n}` |
| Mark | `@M_KOJO[%RESULTS%_]MESSAGE_MARKCNG_MESSAGECHECK_K{id}` |
| Daily event | `@M_KOJO[%RESULTS%_]DAILY_EVENT_MESSAGECHECK_K{id}_{n}` |
| Orgasm A-tier | `@M_KOJO[%RESULTS%_]MESSAGE_PALAMCNG_MESSAGECHECK_A_K{id}_{n}` (and `_A2_*` variant) |
| Orgasm B-tier | `@M_KOJO[%RESULTS%_]MESSAGE_PALAMCNG_MESSAGECHECK_B_K{id}_{n}` |

These are **optional** — if a character doesn't define them, the engine just renders both narration and kōjō.

### 1.5 EXTRASOURCE family — post-message side-effect hook

After the message body runs, the engine looks for an EXTRASOURCE label to apply additional `SOURCE:` ledger updates, separate from those in the message body itself:

```
@M_KOJO[%RESULTS%_]EXTRASOURCE_COM_K{id}_{cmd}      ; per-command
@M_KOJO[%RESULTS%_]EXTRASOURCE_COM_K{id}_GENERAL    ; catch-all for any cmd
@M_KOJO[%RESULTS%_]EXTRASOURCE_SCOM_K{id}_{cmd}     ; per-SCOM
@M_KOJO[%RESULTS%_]EXTRASOURCE_SCOM_K{id}_GENERAL   ; catch-all
```

Use case: a character who wants to apply different SOURCE:反感/SOURCE:情愛/etc. deltas based on player state (drunk, role-play, etc.) without putting that logic in every command body.

### 1.6 The "kōjō selector" (`RESULTS` infix)

`@M_KOJO_K<id>(ARG)` is the existence check. Inside, an author can set `RESULTS = "_<NAME>"` to declare a selector, and prefix every other label with that selector. The dispatcher then looks for `M_KOJO<RESULTS>_*` instead of `M_KOJO_*`.

Examples seen in the corpus:
- `RESULTS = _ORTHODOX` — Satori (049).
- `RESULTS = _OwO` — Seija (097).
- `RESULTS = _STELLARIS` — Toyohime (099).
- `RESULTS = _POWERED_BY_DARKMAN` — Megumu (140).
- `RESULTS = _tokicoli` — Lily W (018) test variant.
- `RESULTS = _吧友火焔猫燐制作` — Orin (036) (full Chinese phrase).
- `RESULTS = _総合スレ７４９` — Hecatia (113) (board-thread name).

`RESULTS:1` carries the locale (e.g. `日版`, `中版`) — informational, doesn't affect dispatch.

The selector can be any non-empty string. **Case matters**: `_STELLARIS_ENCOUNTER_K99` and `_STELLARIS_ENCOUNTER_k99` (lowercase id) are different labels — engine constructs both. Some authors use the lowercase id intentionally.

### 1.7 Versioned existence checks

The engine tries `@M_KOJO_K<id>(ARG)` and also `@M_KOJO_K<id>_<v>(ARG)` for compatibility with old engine versions. Only one should `RETURN 1`.

### 1.8 Fallback hierarchy

1. `M_KOJO[%RESULTS%_]MESSAGE_COM_K{id}_{cmd}` (specific).
2. `M_KOJO[%RESULTS%_]MESSAGE_COM_K{id}_00` (catch-all).
3. `EVENT_MESSAGE_COM_*` files in `ERB/口上・メッセージ関連/` (engine defaults).
4. If `CFLAG:N:自動喘息`, `CALL AUTO_AEGI(N)` (auto-moan).

Bodies that should silently produce no output `RETURN 1` after `LOCAL = 0`-gating, suppressing default fall-through.

### 1.9 The "new kōjō API" (`KOJO_*` framework)

Some characters (Reimu 001, Eiki 030, Enoko 154, and others) ship a `カスタム.ERB` or `of_new_kojo_api.ERB` file that uses an **extended dispatch family** for **author-defined custom commands and UI buttons**. This API was a later addition; not all engines that run this game support it.

Its label set:

| Label | Role |
|---|---|
| `@KOJO_CUSTOM_BUTTON_CONDITION_K{id}_{Y}` | Returns 1 to show button `Y` (range 0-9). Sets `custom_button_name:{id}:{Y} = "<label>"`. |
| `@KOJO_CUSTOM_BUTTON_K{id}_{Y}` | Click handler for button `Y`. |
| `@KOJO_CUSTOM_TALENT_SET_K{id}` | Populates `CUSTOM_TALENT:{id}:{slot}`, `CUSTOM_TALENT_NAME:{id}:{slot}`, `CUSTOM_TALENT_COLOR:{id}:{slot}` (0=normal/1=pink/2=red+bold), `CUSTOM_TALENT_TYPE:{id}:{slot}` (1=race/2=sexual/3=physical/4=mental/5=technical/0=other). Renders in 角色介绍 tab. |
| `@KOJO_COM_NAME_K{id}_{Y}` | Returns command name string in `RESULTS`. `Y` is a 0-9 sub-id. |
| `@KOJO_COM_ABLE_K{id}_{Y}` | Returns 1 if command `Y` is currently usable. |
| `@KOJO_COM_K{id}_{Y}` | Body of custom command `Y`. Returns 1 = execute, 0 = cancel-but-keep-source, -1 = cancel-and-skip-source. |
| `@KOJO_CAN_COM_K{id}_{Y}` | Predicate: can this command be queued? |
| `@KOJO_VERSION_K{id}` | Returns this character's kōjō version (semantic). |
| `@KOJO_VERSION_UPDATE_K{id}` | Save-game migration hook. Run when version changes. |

Custom command IDs map onto engine command space at offset `270 + Y` (so custom 0 = command 270). After hooked, the message body uses standard `@M_KOJO_MESSAGE_COM_K{id}_{270+Y}` form.

### 1.10 Other character-level extension labels

| Label | Notes |
|---|---|
| `@OTHER_EVENT_K{id}` | Author-private event dispatcher (Keiki 132). Purpose varies. |
| `@K{id}_<author-name>` | Any free-form author-private label callable from elsewhere in the kōjō. Examples: `@K42_4KANO`, `@K42_PREGNANCY_DESIRE`, `@K139_ONASAPO`, `@K139_AFFAIR`, `@K30_C_NAME(...)`, `@K30_BE_SEEN()`. Common shape `@K{id}_<NAME>` keeps namespace clean. |

---

## 2. File set & directory conventions

### 2.1 Variant directories

Every character ID has 1+ author-variant subdirectory. Multiple variants coexist; only one is "active" at runtime per character (selector controls which).

Variant directories named in many forms — Japanese name, Chinese name, version-tag, author-tag, etc.

### 2.2 Standard file taxonomy

| File | Holds |
|---|---|
| `M_KOJO_K{id}_イベント.ERB` | Existence + FLAGSETTING + COLOR + UPDATE + ENCOUNTER + SPEVENT + EVENT. **Often the largest file.** |
| `M_KOJO_K{id}_日常系コマンド.ERB` | COMs in 300–4xx range. |
| `M_KOJO_K{id}_性交系コマンド.ERB` | COMs in 60–7x range. |
| `M_KOJO_K{id}_セクハラコマンド.ERB` | COMs 310–330. |
| `M_KOJO_K{id}_愛撫系コマンド.ERB` | foreplay COMs. |
| `M_KOJO_K{id}_加虐系コマンド.ERB` | SM 100–108. |
| `M_KOJO_K{id}_ハードなコマンド.ERB` | extra "hard". |
| `M_KOJO_K{id}_奉仕系コマンド.ERB` | service-led COMs. |
| `M_KOJO_K{id}_道具系コマンド.ERB` | toys 40–18x. |
| `M_KOJO_K{id}_派生コマンド.ERB` | SCOMs. |
| `M_KOJO_K{id}_カウンター.ERB` | COUNTER labels. |
| `M_KOJO_K{id}_弾幕勝負.ERB` | DANMAKU. |
| `M_KOJO_K{id}_依頼.ERB` | IRAI quest dispatcher. |
| `M_KOJO_K{id}_刻印取得.ERB` | MARKCNG. |
| `M_KOJO_K{id}_絶頂.ERB` | PALAMCNG_A/A2/B/B2/F. |
| `M_KOJO_K{id}_日記.ERB` | DIARY (incl. command 406). |
| `M_KOJO_K{id}_育児イベント.ERB` | CHILD_RAISING / CHILD_DIARY. |
| `M_KOJO_K{id}_コマンド.ERB` | misc / catch-all. |
| `M_KOJO_K{id}_INFO.ERB` | `@CHARA_INFO_KOJO_K{id}()` only. |
| `M_KOJO_K{id}_カスタム.ERB` (or `of_new_kojo_api.ERB`) | New kōjō API: CUSTOM_BUTTON / CUSTOM_TALENT / KOJO_COM_*. |
| `M_KOJO_K{id}_関数ライブラリ.ERB` | author-private helpers — `#FUNCTION` definitions. (Sometimes `M_KOJO_K{id}_<name>用関数.erb`, `<name>の関数まとめ.ERB`, etc.) |
| `M_KOJO_K{id}_<charname>特殊イベント.ERB` | author-private major one-shot events `@K{id}_<NAME>`. |
| `M_KOJO_K{id}_コマンド自動喘ぎ.ERB` | auto-pant string-construction. |
| `M_KOJO_K{id}_コマンド酔夢想.ERB` | drunken-state extra dialogue. |
| `K{id}_固有カウンター<n>_<name>.ERB` | char-unique counter scaffold. |
| `M_KOJO_K{id}_自慰系(あなた)コマンド.ERB` | player-self-pleasure (POV-shifted). |
| `M_KOJO_K{id}_会話.ERB` | dedicated conversation file. |
| `M_KOJO_K{id}_自由行動.ERB` | "free-action" handler. |
| `M_KOJO_K{id}_UPDATE.ERB` (or `_UPDATE処理.ERB`) | UPDATE logic split out of イベント. |
| `M_KOJO_K{id}_<charname>口上事件.ERB` | author-private story-event library. |
| `M_KOJO_K{id}_相关判定.ERB` | "judgment/decision" helper file. |
| `M_KOJO_K{id}_逆アナル系コマンド.ERB` | "reverse-anal" (futa-led) commands. |
| `M_KOJO_K{id}_SM・加虐系コマンド.ERB` | extended SM commands. |
| `M_KOJO_K{id}_オートあえぎ.ERB` (or `_オート喘ぎ.ERB`) | character-private auto-pant. |
| `K{id}C_<charname>用DIM.ERH` (or `<charname>用DIM.ERH`) | constant declarations. |
| `Lib/` (subdirectory) | Library files (loaded recursively). |
| `追加ファイル/` (subdirectory) | "Additional files" (loaded recursively). |
| `おまけ/` (subdirectory) | Author extras. |
| `自分用メモ/` (subdirectory) | Author memos. |
| `キャラデータ/` (subdirectory) | Character data overrides (mirroring engine's). |
| `readme.txt`, `ライセンス.txt`, `ライセンステンプレ.txt`, `フラグ管理メモ.txt`, `衣装メモ.txt`, `CFLAG一覧.txt`, `*.txt` | Author docs/memos. **Not loaded** by engine. |

### 2.3 Alternative file-organization patterns

- **Subdirectory layout** (Satori v0.053, Koishi 38): `一般/`, `性/`, `自作/`, `其它/` — files grouped by topic.
- **Per-event-id files** (Satori 24.5.14, Flandre 050): `M_KOJO_K{id}_イベント_<eventid>(<title>).erb` — one file per event.
- **Numbered-prefix multi-file** (Yumeko 103, Kosuzu 070): `M_KOJO_K{id}_00_DIM.ERH`, `_01_イベント.ERB`, `_02_カウンター.ERB`, …. Files are ordered by load priority.
- **Single-file consolidation** (Hatate 试做型, Aya 029, Kyouko 088): everything packed into 1-3 big files.
- **NO. numeric prefix** (Seija OwO 097): `NO.0M_KOJO_K{id}_OwO_*.ERB`, `NO.1M_KOJO_K{id}_OwO_*.ERB` — for variant file ordering.
- **In-variant `追加ファイル/`** (Hina 079, Tewi 053, Eiki 030): hold supplementary content / library helpers / specific events.
- **`KX`-prefixed templates** (Keiki 132, 先代 159): `M_KOJO_KX_*.ERB` and `M_KOJO_K1[]_*.ERB` are template stubs not yet customized for the actual char ID.
- **Variant-name infix in label** (Sagume 110): `@CHARA_INFO_KOJO_寒鹭探心_K110` instead of using the RESULTS selector.

### 2.4 Cross-cutting directory in `ERB/口上・メッセージ関連/`

```
COMMON_KOJO.ERB         — SAMEROOM, KOJO_ACTIVE_INFO, SET_KOJO_COLOR, OPPAI_DESCRIPTION
KOJO_MESSAGE.ERB        — the dispatcher
EVENT_MESSAGE.ERB       — engine-default post-train messages
EVENT_MESSAGE_COM*.ERB  — engine-default per-command messages (no specific char)
EVENT_MESSAGE_*.ERB     — defaults for marks, orgasm, derived COMs, undress, etc.
AUTO_AEGI.ERB           — auto-moan fallback
STAND_COM_IMAGE.ERB     — command-image display
TINKO_TYPE.ERB          — penis-type description
個人口上/                — per-character dirs
```

Bodies often `CALL` into these:
- `CALL TRAIN_MESSAGE` — engine pre-message before a primary COM.
- `CALL EVENT_COUNTER_MESSAGE` — pre-message before a COUNTER.
- `CALL MARK_MESSAGE` — pre-message before MARKCNG.
- `CALL SPEVENT_MESSAGE_<n>(ARG, ARG:1)` — engine's default narration for SPEVENT `n`.
- `CALL AUTO_AEGI(N)` — engine's auto-moan for char N.

---

## 3. The DSL (Emuera-script)

### 3.1 Syntax

| Construct | Form |
|---|---|
| Label declaration | `@LABEL_NAME` or `@LABEL_NAME(ARG, ARGS, ARG:1, TYPE = 0)` (default args allowed). |
| Numeric local | `LOCAL`, `LOCAL:1`, …, `LOCAL:101`. |
| String local | `LOCALS`, `LOCALS:1`, … |
| Variable declaration | `#DIM <name>`, `#DIMS <name>` (string). |
| Constant | `#DIM CONST <name> = <val>` — compile-time constant. |
| **Save-persistent storage** | `#DIM SAVEDATA <name>` (numeric) / `#DIMS SAVEDATA <name>` (string) — persists across save/load. |
| **Save-persistent global** | `#DIM SAVEDATA GLOBAL <name>` / `#DIMS SAVEDATA GLOBAL <name>` — additionally available across all characters. |
| Dynamic/local-scope | `#DIM DYNAMIC <name>` — local to the function. |
| Set local-array size | `#LOCALSIZE 200` |
| Array literal init | `#DIM <name>, <size> = <a>, <b>, <c>, …` |
| Function marker (numeric) | `#FUNCTION` after the label. Returns via `RETURNF <int>`. |
| Function marker (string) | `#FUNCTIONS`. Returns via `RETURNF "<str>"`. |
| Conditional | `IF / ELSEIF / ELSE / ENDIF`; `SIF <cond>` (single-line). |
| Switch | `SELECTCASE <expr> / CASE <vals|TO|IS> / CASEELSE / ENDSELECT`. Examples: `CASE 0 TO 2`, `CASE Is >= 4`, `CASE 1, 3, 5`. |
| Loop | `FOR LOCAL, start, end / NEXT` (end exclusive), `WHILE <cond> / WEND`, `BREAK`, `CONTINUE`. |
| Goto | `$LABEL` then `GOTO LABEL`. |
| Block exclude | `[SKIPSTART] ... [SKIPEND]` — preprocessor exclude. |
| Calls | `CALL <LABEL>(args)`, `CALLF <FUNC>(args)` (function call), `TRYCALL`/`TRYCALLFORM`/`TRYCCALLFORM ... CATCH ... ENDCATCH`. `CALLFORM` for dynamic name. |
| Return | `RETURN <int>` (numeric body), `RETURNF <val>` (function body). |
| Output | `PRINTL`, `PRINTW`, `PRINTFORML`, `PRINTFORMW`, `PRINTFORMD`, `PRINTFORMDL`, `PRINTFORMDW`, `PRINTDATA`/`PRINTDATAW`/`PRINTDATAL` (random pick from `DATAFORM`s), `PRINTBUTTON @"label", @"return"`, `PRINTPLAIN`. |
| Random text picker | `PRINTDATA / DATAFORM <text> / ENDDATA` — engine picks one DATAFORM at random. `\n` inside DATAFORM = line break. |
| Color | `SETCOLOR <NAMED|0xHEX|R,G,B>`, `RESETCOLOR`. Named: `C_CREAM`, `C_AQUA`, `C_PINK`, `C_DEFCOLOR`, `C_HTML`. |
| Drawing-mode | `REDRAW <mode>`, `CURRENTREDRAW()`, `LINECOUNT`, `CLEARLINE <n>`, `REUSELASTLINE <text>`. |
| Wait / input | `INPUT` (int → `RESULT`), `INPUTS` (string → `RESULTS`), `TWAIT <ms>, <flag>`, `GETKEY(<n>)`. |
| Bit / bitfield | `SETBIT <var>, <bit>`, `CLEARBIT <var>, <bit>`, `GETBIT(<var>, <bit>)`. |
| String ops | `STRLENS(s)`, `STRLENSU(s)` (unicode-aware), `STRCOUNT(s, "regex")`, `REPLACE s, "regex", "replacement"`, `+=` for string concat. |
| Math/array | `INRANGE(v, lo, hi)`, `MAX(a, b)`, `MIN(a, b)`, `ABS(n)`, `RAND:N` / `RAND(N)`, `FINDELEMENT(<array>, <value>, <start>)`. |
| `VARSET` | `VARSET <name>` (clear), `VARSET <name> <value>` (set). |
| **TIMES** | `TIMES <var>, <factor>` — multiply by float, store back in `<var>`. |
| Block-bracket | `{ ... }` around a multi-line `#DIMS = "...", "..."` declaration is a hint to the parser to keep it on one logical line. |
| Comment | `;` to end of line. |

### 3.2 Output-string interpolation

Inside `PRINTFORML`/`PRINTFORMW` text, the following expand at print time:

| Form | Means |
|---|---|
| `%CALLNAME:N%` | display-name of char `N`. |
| `%MASTERNAME:N%` | per-character nickname for MASTER (mutable: `MASTERNAME:N = "..."`). |
| `%CHILDNAME:char_id:idx%` | child name. |
| `%NAME:N%` | player's true name. |
| `%CSVCALLNAME(N)%` | display-name from CSV. |
| `%CSVCSTR(N, slot)%` | per-character string from CSV row `N`, slot `slot`. |
| `%CSTR:N:slot%` | per-character mutable string slot. |
| `%TEXTR("a/b/c/d")%` | random pick of `a`, `b`, `c`, or `d`. |
| `%UNICODE(0xN)%` | arbitrary unicode char (`0x2665` = ♥). `* N` repeats. |
| `%PANTSNAME(EQUIP:..., N)%`, `%CLOTHNAME(slot, EQUIP:N:slot)%`, `%OPPAI_DESCRIPTION(N, 1)%`, `%PANTS_DESCRIPTION(EQUIP:..., N)%`, `%SHOW_BOTTOM(N)%` | engine helpers (clothing/body description). |
| `%"text", width, LEFT%` | fixed-width padded text. |
| `\@ <expr> ? <a> # <b> \@` | inline ternary, evaluated at print time. Works inside `@"..."` strings too. |
| `{<expr>}` | numeric/string expression interp inside CALLFORM and certain PRINTFORM contexts. |
| `%K{id}_<func>(args)%` | invokes a `#FUNCTIONS` (string-returning) author function and interpolates. |

### 3.3 Special tokens

- `[[<name>]]` — parse-time char-id lookup (e.g. `[[極]]` resolves to 42).
- `@"text"` — string literal supporting `//` for line breaks (used in `SPTALK`, `HPH_PRINT`).

---

## 4. The state-bus

### 4.1 Per-character namespaces

| Namespace | What it stores | Example slots |
|---|---|---|
| `TALENT:N:slot` | Talents/traits — boolean or small int. | `恋慕, 思慕, 恋人, 愛欲, 炮友, 処女, 無接吻経験, 兒童, 幼児／幼児退行, 年齢, 体型, 形状, 胸圍, 性別, 酒耐性, 妊娠, 育児中, 妊娠願望, 大胃王, 坦率, 自尊心, 無知, 小悪魔, 魅力, 魅惑, 謎之魅力, 膽怯, 傲慢, 叛逆, 施虐狂, 性別嗜好, 両面通吃, 讨厌男人, 態度 (-2..0..+2), 非処女, 非童貞, 破瓜, Ａ破瓜, 出産経験, 膣射経験, 人妻, 未亡人, 接吻魔, 心情, …` |
| `ABL:N:slot` | Abilities — grade-like ints. | `親密, 欲望, Ｂ感覚, Ａ感覚, Ｃ感覚, Ｖ感覚, Ｐ感覚, Ｍ感覚, 従順, 奉仕精神, 教養, 料理技能, 戦闘能力, 露出癖, 接吻経験, 学習経験, 愛情経験, 約會経験, 演奏経験, 出産経験` |
| `EXP:N:slot` | Experience counters. | `接吻経験, 料理経験, 愛情経験, 約會経験, 学習経験, 出産経験, 無自覚絶頂経験, 60..63 (sex-act counters), …` |
| `BASE:N:slot` | Physiological base values. | `勃起, 体力, 酒気, 活力, 精神, 興奮, 疲労, 気力, 憤怒` |
| `MAXBASE:N:slot` | Max base values. |  |
| `NOWEX:N:slot` (or `NOWEX:slot`) | Current physiological event state. | `射精, 噴乳, 放尿, Ｃ絶頂, Ｖ絶頂, Ｂ絶頂, Ａ絶頂, Ｍ絶頂, TotalEX` |
| `EX:slot` | Engine-side cumulative state. | `膣内精液, …` |
| `PALAM:slot` | Status parameters. | `欲情, …` |
| `PALAMLV:N` | Level-threshold lookup. | Used as `IF PALAM:欲情 >= PALAMLV:5`. |
| `MARK:N:slot` | Marks / imprints. | `不埒刻印, 反発刻印, 苦痛刻印, 快楽刻印, 時姦刻印` |
| `STAIN:N:slot` | Body-fluid stains. | `精液, 愛液, 汗` |
| `EQUIP:N:slot` | Equipment slots (clothing). | `下半身内衣２, 上半身内衣１, 上半身内衣２, 服, …` |
| `TEQUIP:N:slot` (or `TEQUIP:slot`) | Per-target situational equipment. | `50, 51 (V/A insertion), 口球, 眼罩, 縄, 陰蒂夾, 乳頭夾, 振動棒, 子宮, 六九式, 飛機杯, Ｖ接触部位, 11..18 (touch zones), 101..107 (secondary touch), …` |
| `CFLAG:N:slot` (or `CFLAG:slot`) | Persistent character flags. | `現在位置, 初期位置, 面識, 好感度, 信賴度, 睡眠, 約会中, 妊娠自覚状態, 無自覚妊娠, 没穿内裤, 允许无套, 清い交際, 恶作剧, 出禁, 推倒禁止, 来訪不能, 自動喘息, 時間停止口上有, 眠姦口上有, 扮演口上有, 破瓜中止口上有, 口上内抱き寄せ判定_*, 口上セレクタ, 継承, 1000-1999 (author-private), 1990-1999 (engine-reserved), …` |
| `TCVAR:N:slot` (or `TCVAR:slot`) | Per-target transient (per-day). | `破瓜, Ａ破瓜, 中止接吻, 烂醉, 初次拥抱, 媚薬, 今天的礼物, 発情, 100/101 (last V/A inserter), 102/104 (climax flags), 112, 302 (talk-availability), 350-399 (author-private), …` |
| `CSTR:N:slot` | Per-character mutable string slots. (slots 20-39 sometimes used for info-text plug-ins; 80+ for nicknames.) |
| `DIARY:N:M` | Diary state. 0=locked / 1=read / 2=daily-event-readable / 3=on-demand-readable. |
| `MAX_DIARY_PAGE:N:0` | Total pages. |
| **`RELATION:N:M`** | **Inter-character affinity.** Bodies write `RELATION:36:37 = 200` (Orin↔Okuu affinity). |
| **`SOURCE:N:slot`** | Post-action affection ledger; bodies write, end-of-turn engine reads & applies deltas. Slots: `性行動, 露出, 逸脱, 与快Ｃ, 誘惑, 侮辱, 挑発, 加虐, 征服, 情愛, 反感, 歓楽, 達成, 愛情経験, …` |
| **`CUSTOM_TALENT:N:slot`** | char-defined talents shown in 角色介绍 tab. Set by `@KOJO_CUSTOM_TALENT_SET_K{id}`. |
| **`CUSTOM_TALENT_NAME:N:slot`**, `CUSTOM_TALENT_COLOR:N:slot`, `CUSTOM_TALENT_TYPE:N:slot` | display attrs for the above. |
| **`custom_button_name:N:Y`** | Char-defined button labels (Y = 0..9). Set by `@KOJO_CUSTOM_BUTTON_CONDITION_K{id}_{Y}`. |

### 4.2 Per-game globals

| Global | Means |
|---|---|
| `FLAG:slot` (or `FLAG:NUMBER`) | Global flags. `FLAG:70` = time-stop (alias `FLAG:時間停止`); `FLAG:扮演` = role-play target char ID; `FLAG:出禁人数` = banned-char count; `FLAG:周回数` = New-Game+ count; `FLAG:口上文本設定`, `FLAG:口上色`, `FLAG:口上セレクタ`, `FLAG:約会的对象`, `FLAG:甲斐性無`, `FLAG:ファッション` (player current cosplay), `FLAG:扮演`, `FLAG:6`. |
| `TIME` | Minutes-of-day. |
| `TIME:2` | Hour bucket. |
| `TIME:5` | **Weather phase** (4-7 = rain, 5 = heavy rain). |
| `DAY` | Game day count (alias of `DAY:0`). |
| `DAY:0` | Game day count. |
| `DAY:2` | Month. |
| `DAY:3` | Day-of-month. |
| `MAIN_MAP` | Current world-map ID. 0 = Hakurei, 1 = Myouren, 2 = Human Village, 3 = Scarlet, 4 = Bamboo, 5 = Magic Forest, 6 = Sanzu, 7 = Tengu (foot), 8 = Tengu (peak), 9 = Underground, … |
| `SELECTCOM` | Currently-selected command ID (mutable). |
| `TFLAG:50` | Active SCOM ID. |
| `TFLAG:192` | SUCCESS_COM override. |
| `TFLAG:193` | Mood/result. |
| `TFLAG:194` | Sub-result. |
| `TFLAG:21..24, 時姦刻印取得` | Mark codes. |
| `TFLAG:62` | Time-stop suppress (Hatate). |
| `TFLAG:400` | Date-presence flag. |
| `TARGET, MASTER, PLAYER, ASSI, RANDOM_CHARANUM, CHARANUM` | Char-ID resolutions. |
| `TARGET:N` | N-th element of multi-target array (`TARGET:0` = current). |
| `RESULT, RESULTS` | Return values. |
| `PREVCOM` | Previous command. |
| `DISHNAME, DISH_TASTE` | Cooking-system globals. |
| `LINECOUNT` | Current cursor line. |

---

## 5. Engine helpers

### 5.1 Pre-message / cooperation

- `CALL TRAIN_MESSAGE`, `CALL EVENT_COUNTER_MESSAGE`, `CALL MARK_MESSAGE`, `CALL SPEVENT_MESSAGE_<n>(ARG, ARG:1)`.
- `CALL AUTO_AEGI(N)` — auto-moan for char `N` if covered.
- `CALL ADD_KISS` — increment kiss counter.

### 5.2 UI prompts

- `CALL ASK_YN("yes-text", "no-text")` — sets `RESULT` (0 = yes, 1 = no — note polarity).
- `CALL ASK_M("opt0", w0, "opt1", w1, …, "optN", wN)` — multi-choice with weights (1=enabled, 0=greyed). `RESULT` = 0-based index.
- `INPUT`, `INPUTS`, `PRINTBUTTON`.
- `TWAIT <ms>, <flag>` — wait. `GETKEY(<n>)` — read keypress.

### 5.3 Image / face / talk

- `CALL PRINT_FACE, char_id, expr[, clothes[, variant]]` — display portrait. Args are positional; pass `""` to skip.
- `CALL SPTALK, char_id, expr, ?, @"line // line // line"` — speech bubble (max 6 lines).
- `CALL HPH_PRINT, @"text", "L"` — "panting" stylized print.
- `CALL 画像セット(@"<image-key>", x, y, w, h, _, _, "default-image")` — set image.
- `CALL 画像一斉表示(<position>, <flags>, <delay>)` — flush set images.
- `CALL PRINT_GROUP(LOCALS, <count>, <delay-ms>)` — print N items with delay between each.
- `REDRAW <mode>`, `CURRENTREDRAW()`, `CLEARLINE <n>`, `REUSELASTLINE <text>` — drawing mode.

### 5.4 Pose / state / equip helpers

- `CALL TOUCH_SET(SET_FROM_YUBI, 1, [[N]])` — register touch action.
- `CALL EVENT_COUNTER_POSE_69([[N]], M)`, `_その他([[N]], M)` — set pose.
- `CALL DATUI_BOTTOM([[N]], M)` (M=1 pull down, M=2 strip), `CALL DATUI_TOP`, `CALL DATUI_INNER`.

### 5.5 Predicates / accessors

- `RAND:N` / `RAND(N)`.
- `FIRSTTIME(<key>)` — has key been used? Forms: `FIRSTTIME(SELECTCOM)`, `FIRSTTIME(SELECTCOM, 1)`, `FIRSTTIME(TFLAG:50 + 500)`, `FIRSTTIME("UP01", 0, <id>)` (string-keyed with char scope).
- `GROUPMATCH(VAR, V1, V2, …)`.
- `BATHROOM(loc)`, `OUTROOF(loc)`, `DATE_HITOGOMI(loc)`, `WITH_MOB()` — location predicates.
- `GET_MAPID(loc)` — convert loc to map id.
- `GET_TARGETNUM()` — count of TARGETs in current room.
- `FINDCHARA(start_loc, current_loc)` — char-presence helper.
- `SHIRAHU(N)` — char `N` in normal state.
- `CHK_DATENOW(CFLAG:N:約会中)` — date currently underway.
- `CHK_FOCUS(start, current, end)` — focus location range.
- `MASTER_POSE(role, ?, ?)` — multi-person scene participant lookup.
- `ALCOHOL_TASTE(TFLAG:194)`, `ALCOHOL_FACE()` — alcohol predicates.
- `ESTRUS_CYCLE(N)` — char's estrus phase.
- `SYNCED_ORGASM(N)`.
- `TIME_PROGRESS(TFLAG:<key>)` — minutes since marker.
- `IRAI_ID_TO_CLIENT(IRAI_ID)`, `IS_COMMON_IRAI(IRAI_ID)`, `STR_DATA_IRAI(IRAI_ID, key, client)` — quest helpers.
- `GET_GIFTDATA(item, "key")` — gift table.
- `CHARA_DIARY_PAGESETTING(char, page)` — diary page registration.
- `NEMUKE()` — sleepiness gauge.
- `CHARA_HOLIDAY(N)` — char on holiday today?
- `GET_SUCCESS_RATE()` — engine-computed success-rate.
- `GETDEFCOLOR()` — default color.
- `K_<char-helper>(...)` — per-character author helpers (e.g. `K42_FIND_LOVER`, `K30_C_NAME`, `陥落状態`).
- `FISHER_YATES_SHAFFLE(N)` — shuffle (engine helper). `SHAFFLE_ARRAY:N` — shuffled output.
- `FUNC_FISHER_YATES_SHAFFLE(<dest>, N)` — function form.

---

## 6. Author-extension patterns

### 6.1 Function library

A set of `#FUNCTION` / `#FUNCTIONS` definitions. Common helpers (most authors borrow from Eiki K30 originally):

| Name | Returns | Purpose |
|---|---|---|
| `@K{id}_FIND_LOVER()` | int | -1=this char is lover, 0=no lover, 1=elsewhere, 2=in-room |
| `@K{id}_FIND_AROUND(ARG = 0)` | int | char ID of relevant nearby char (priority: known list → random) |
| `@K{id}_DRUNK()` | int | 0=sober..3=blackout |
| `@K{id}_BOKKI()` | int | 0=flaccid..3=max erection |
| `@K{id}_AENAI` | void | "days since seen" line |
| `@K{id}_KOUSAI` | void | anniversary line |
| `@K{id}_NURESUKE()` | void | wetness/transparency description |
| `@K{id}_AMANURE` | void | rain-soaking trigger |
| `@K{id}_C_NAME(ARG, TYPE = 0)` | string | "name-of-character" with suffix/style |
| `@K{id}_SET_C_NAME(ARG)` | int | interactive nickname-setting |
| `@K{id}_BE_SEEN()` | int | 1=somebody's watching |
| `@K{id}_GREETING()` | string | time-of-day greeting |
| `@K{id}_TRY_HARASS` | int | "did this advance succeed?" |
| `@K{id}_CHECK_HEN_T()` | int | "is player wearing weird cosplay?" |
| `@K{id}_ROOM_DESCRIPTION()` | void | room description |
| `@CHARA_INFO_KOJO_K{id}()` | int | overrides 角色介绍 tab |

Pattern: declare `#DIM CONST` constants in a `.ERH` header file (e.g. `K{id}C_<charname>用DIM.ERH`) for self-documenting CFLAG slot names.

### 6.2 Special-events library (`<charname>特殊イベント.ERB`)

A set of standalone `@K{id}_<NAME>` labels — major one-shot story events. Each:
- Has a `;CALL K{id}_<NAME>` comment above.
- Branches on its own state-progress CFLAG.
- Calls `ASK_YN`/`ASK_M`/`PRINT_FACE`/`HPH_PRINT`.
- Mutates state at the end (CFLAG progression, TALENT grant, etc.).

### 6.3 Char-unique counters

Per file, four labels:
```
@UNIQUE_COUNTER<n>_ABLE_K{id}        ; eligibility (RETURN 0/1)
@UNIQUE_COUNTER<n>_FREQUENCY_K{id}   ; RESULTS = "<type>"; RETURN base+freq
@UNIQUE_COUNTER<n>_MESSAGE_K{id}     ; print body
@UNIQUE_COUNTER<n>_SOURCE_K{id}      ; SOURCE: ledger updates + pose/touch/undress side-effects
```

### 6.4 The `LOCAL = 0/1` "filled-in" gate

```erb
@M_KOJO_MESSAGE_COM_K<id>_<cmd>_1
LOCAL = 1                          ; 1 = filled, 0 = stub
IF LOCAL
    ; logic
ENDIF
RETURN 1
```

`LOCAL = 0` is intentional — suppresses body; engine falls through. Don't "fix" them. `LOCAL:1 = 0/1` for sub-branch toggles.

### 6.5 The doc-banner state contract

Every command body opens with an inline-comment listing the relevant TFLAG/TCVAR/MARK/CFLAG codes:
```
;==================================================
;310,摸屁股
;TFLAG:193(1=不快 2&&3=恥ずかしがる 4=されるがまま)
;CFLAG:诶嘿嘿==2&&TCVAR:20(70=強制舐陰 71=口交強制 …)
;PREVCOM(305=膝枕)
;==================================================
```

### 6.6 Branching cascades

Canonical relationship-tier cascade:
```erb
IF FLAG:時間停止 (=FLAG:70)            ; time-stop — short-circuit unless 時間停止口上有 set
ELSEIF CFLAG:睡眠                      ; sleeping — short-circuit unless 眠姦口上有 set
ELSEIF CFLAG:318 == 1                  ; "extreme silent treatment"
ELSEIF CFLAG:诶嘿嘿 == 2               ; drunken/playful "ehehe"
ELSEIF FLAG:扮演                       ; role-play
ELSEIF TALENT:恋人                     ; tier 5 — partner
ELSEIF TALENT:愛欲 || TALENT:炮友      ; tier 4 — lust
ELSEIF TALENT:恋慕                     ; tier 3 — in love
ELSEIF TALENT:思慕                     ; tier 2 — admiring
ELSE                                    ; tier 1/0 — neutral/hostile
ENDIF
```

Some authors use `陥落状態()` helper returning 0..5 for the same.

Random variation: `SELECTCASE RAND:N / CASE 0 / … / CASEELSE` (default = most-frequent).

### 6.7 Multi-person SCOM dispatch

```erb
@M_KOJO_MESSAGE_SCOM_K<id>_<n>
    CALL TRAIN_MESSAGE
    CALL M_KOJO_MESSAGE_SCOM_K<id>_<n>_1     ; first participant body
    LOCAL = MASTER_POSE(<role>, 1, 1)         ; resolve 2nd participant id
    LOCAL:1 = RESULT
    LOCAL:2 = TARGET
    TARGET = LOCAL
    TRYCALLFORM M_KOJO_MESSAGE_SCOM_K{TARGET}_<n>_2   ; their version
    TARGET = LOCAL:2
    RETURN LOCAL:1
```

Multi-person SCOM bodies must be aware they may be running on a partner's TARGET.

### 6.8 Sleep auto-moan

A character can ship its own auto-moan instead of relying on the engine's `AUTO_AEGI`:
- `@K{id}_AUTO_AEGI(ARGS, ARG)` — string-construction body (Kaguya 062, Tewi 053).
- `@K{id}_AUTO_PVOICE()` — alt naming (Tewi 053).
- Bodies dynamically build phrases from `TEQUIP:11..18` (touch zones) → `使用部位 = "ＣＶＡ"` → `STRLENSU(使用部位)` → vocabulary tier (`陥落状態()`) → final formed line.

---

## 7. Edge cases and quirks

### 7.1 Default-args
`@LABEL(ARG, TYPE = 0)` — `TYPE` defaults to 0. Callers may omit. Useful for non-breaking arg additions.

### 7.2 Mutable `SELECTCOM`
Bodies sometimes write `SELECTCOM = 72` to delegate to another COM's body via `CALLFORM M_KOJO_MESSAGE_COM_K<id>_{SELECTCOM}_1`.

### 7.3 Side-effects in counter/unique-counter
`BASE:MASTER:勃起 += 5`-style mutations are normal. Bodies are not pure-print.

### 7.4 Diary state
`DIARY:N:0` is reserved (don't use). `MAX_DIARY_PAGE:N:0` holds total. `CALL CHARA_DIARY_PAGESETTING(char, page)` to register.

### 7.5 Per-turn vs once-per-load
- `@M_KOJO_FLAGSETTING_K<id>` runs **every turn**.
- `@M_KOJO_UPDATE_K<id>` runs **once per game-version-load**.
- `@M_KOJO_K<id>(ARG)` runs **on every dispatch** (existence check — must be cheap).

### 7.6 Reincarnation detection
`FLAG:周回数` ≠ 0 = NG+. `CFLAG:継承` is bit-set: bit 0 = was lover, bit 1 = was wife. Bodies test `GETBIT(CFLAG:継承, k)`.

### 7.7 Role-play detection
`FLAG:扮演 == N` = MASTER is impersonating char `N`. Combine with `FLAG:出禁人数` (banned count, 0 = original is here, -1 = doppelgänger mode) and `CFLAG:N:出禁` (per-char banned).

### 7.8 Bit-flag CFLAG
A single CFLAG slot can carry many booleans. `SETBIT CFLAG:N:slot, k`, `CLEARBIT CFLAG:N:slot, k`, `GETBIT(CFLAG:N:slot, k)`.

### 7.9 Author-private slot ranges
By convention CFLAG 1000–1999 and TCVAR 350–399 are author-private. Engine reserves CFLAG 1990–1999 for UPDATE-path. Engine helpers may also write specific slots in 1500-1599 (animation flags) and 1700-1899 (speech/state).

### 7.10 Per-char persistent storage
- `CSTR:N:slot` for strings (slots ≥40 typically free).
- `#DIM SAVEDATA <name>` for char-private numeric persistence.
- `#DIMS SAVEDATA <name>` for char-private strings.
- `#DIM[S] SAVEDATA GLOBAL <name>` for globally-persistent (but careful — collisions possible).

### 7.11 Selector quirks
- Selectors can be any string (Latin / Japanese / Chinese / mixed / very long).
- Lower vs uppercase char-id: `K99` and `k99` are different labels — engine constructs both forms only if the selector code does.
- `RESULTS:1` carries locale info; not used for dispatch.

### 7.12 ASCII art
At most 1 character in the corpus (Satori 24.5.14) ships an ASCII-art library. `@FONT_AA_<key>` labels with multi-line `PRINTL`. Engine helpers `CHKFONT()`/`SETFONT` are used.

### 7.13 MESSAGECHECK + MESSAGE coordination
A character can use MESSAGECHECK to suppress the kōjō body (`RETURN 2`) and instead print custom narration in MESSAGECHECK itself, then return. The MESSAGE body is then never called. Works for any dispatch family.

### 7.14 The new kōjō API gate
Characters using `KOJO_CUSTOM_BUTTON_*` etc. require an engine version with the API. Older engines silently ignore the labels. Authors typically wrap them in `[SKIPSTART]/[SKIPEND]` if shipping for mixed-version users.

### 7.15 Char-info CSTR plug-in
The `@CHARA_INFO_KOJO_K{id}()` body often ends with a commented-out `FOR LOCAL,20,40 / SIF CSTR:N:(LOCAL) != "" / PRINTFORML %CSTR:N:(LOCAL)% / NEXT` — a hook for downstream patches to inject custom info-text by writing into `CSTR:N:20..39`.

### 7.16 Label-name template stubs
Files named `M_KOJO_KX_*.ERB` or `M_KOJO_K1[]_*.ERB` are template forms not yet customized — engine will skip dispatch (no matching id). Don't assume these are active.

### 7.17 Inline `\n` in DATAFORM
`DATAFORM "line1\nline2"` — `\n` produces a line break inside the same DATAFORM entry.

---

## 8. Tier categorization (observed across corpus)

**Empty** — directory exists but no ERB files: 045 Rikako, 046 Meira, 077 Shizuha, 093 Wakasagihime, 102 Shinki, 104 Yuki, 114 Kurumi, 115 Elly, 116 Mugetsu, 128 Urumi, 131 Mayumi, 135 Mike, 136 Takane, 137 Sannyo, 138 Misumaru, 142 Momoyo, 144 Ibaraki's Arm, 146-152 (PC-98 lostsouls).

**Stub-only** — `LOCAL = 0` everywhere: 003 Kana (`HOGE`), 008 Chiyuri (`HOGE`), 020 Lyrica (`HOGE`), 021 Merlin (`HOGE`).

**Minimal** — basic file set with limited fills: 040 Kogasa, 052 Reisen, 056 Miko, 084 Yamame (`未完了`), 086 Murasa, 088 Kyouko, 089 Yoshika, 091 Tojiko, 119-123 (`賑やかし` placeholders), 126 Shion.

**Basic** — standard kōjō fills, no extensions: 002 Ruukoto, 004 Mima, 007 Star, 015 Sakuya (multi-variant), 016 Remilia (multi-variant), 017 Alice, 022 Lunasa, 023 Youmu, 024 Chen, 025 Ran, 026 Yukari, 027 Wriggle, 028 Mystia, 032 Kanako, 033 Suwako, 034 Tenshi, 035 Iku, 037 Okuu, 039 Nazrin, 043 Kasen, 044 Ellen, 047 Rika, 055 Byakuren, 057 Kokoro, 080 Akyuu, 081 Renko, 082 Maribel, 087 Shou, 092 Futo, 094 Benben, 095 Yatsuhashi, 096 Raiko, 100 Rei'sen, 101 Tokiko, 105 Mai, 107 Seiran, 108 Ringo, 117 Gengetsu, 124 Okina, 125 Joon, 141 Chimata.

**Rich** — significant Lib/extras, helpers, story-events: 029 Aya, 050 Flandre, 059 Koakuma, 060 Parsee, 064 Yuugi, 065 Momiji, 067 Keine, 068 Yuuka, 069 Mamizou, 071 Shinmyoumaru, 075 Medicine, 078 Minoriko, 079 Hina, 083 Kisume, 098 Yorihime, 099 Toyohime, 110 Sagume, 111 Clownpiece, 127 Eika, 130 Yachie, 133 Saki, 140 Megumu, 159 先代.

**Extreme** — full feature surface (Lib/, special-events, custom counters, info-screen, MESSAGECHECK, EXTRASOURCE, custom-cmd API): 001 Reimu, 006 Luna, 014 Cirno, 030 Eiki, 036 Orin, 038 Koishi, 042 Hatate, 049 Satori, 053 Tewi, 058 Meiling, 061 Mokou, 062 Kaguya, 063 Kagerou, 066 Yuyuko, 070 Kosuzu, 072 Eirin, 076 Komachi, 090 Seiga, 097 Seija, 103 Yumeko, 113 Hecatia, 118 Larva, 129 Kutaka, 132 Keiki, 134 Miyoi, 139 Tsukasa, 143 Yuuma, 154 Enoko.

The "extreme" tier characters are the canonical templates to mine when writing new kōjō; the "basic"/"rich" tier are good for cookie-cutter implementations.
