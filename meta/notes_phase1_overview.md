# Phase 1 — Game-folder rough scan

Goal: orient inside `eraTW/` and identify *which subtrees do what* before diving into 口上.
This is structural only — file/folder *roles*, not contents.

## 1. Top-level layout (`eraTW/`)

| Path | Role |
|------|------|
| `Emuera*.exe` | Engine binaries (Emuera + variants: lazyloading, RainForTW, etc.). Each `.exe` is a complete interpreter; the game *is* the surrounding ERB/CSV/dat files, not the exe. |
| `emuera.config` / `lazyloading.cfg` / `lazyloading.dat` | Engine config for window size, shortcut keys, lazy-loading mode. Player-facing, not script-relevant. |
| `DEBUG_MODE.bat` | Launches an exe with debug flags. |
| `ERB/` | **All game logic** — Emuera scripts (`.ERB` / `.erb` are case-insensitive on Windows). This is where 口上 lives. |
| `CSV/` | **All static data tables** — character stats, talent definitions, flag-name dictionaries, item tables, etc. |
| `dat/` | Tiny binary saves used by chara_0 (the player). |
| `sav/` | Player save files. |
| `resources/` | Sprite/portrait images and the `mkResourceXml.py` build script. |
| `font/` | Bundled fonts. |
| `sound/` | BGM/SE if present. |
| `lang/` | Localization. |
| `README集/`, `原版+前人整合等各种readme/`, `*.txt` | Human docs/readmes, version histories. |

## 2. `CSV/` — the static-data layer

These are flat tables. Most are tiny (≤10 KB) and act as **enumerations**: they map a numeric ID to a human-readable name. ERB code reads these as `CFLAG:N`, `TFLAG:N`, etc., and the names in CSV are what makes that readable.

| File | What it defines |
|------|-----------------|
| `Abl.csv` | Ability slots (親密, 欲望, Ｂ感覚, Ａ感覚, Ｃ感覚 …). |
| `Talent.csv` | Talent / trait flags (恋慕, 処女, 兒童, etc.). |
| `CFLAG.csv` | **Character flag** numeric slots (per-character integer state). 9.5 KB — large and load-bearing. |
| `TFLAG.csv` | **Turn flag** slots (per-turn / per-command transient state). |
| `TCVAR.csv` | Per-character variable state (TCVAR is "TARGET-character VAR"). |
| `CSTR.csv` | Per-character string slots. |
| `FLAG.csv` | **Global flags** (game-wide state, e.g. cutscene locks). |
| `Item.csv` | Item definitions. |
| `Equip.csv` / `Tequip.csv` | Equipment / character-slot equipment. |
| `Train.csv` | Training-command IDs. |
| `Palam.csv` | Parameter slots (HP/MP-style). |
| `Juel.csv` | "Juel" gem currency. |
| `Mark.csv` | Mark/imprint type IDs (refer to 刻印取得 kōjō). |
| `Stain.csv` | Body-fluid stain slots. |
| `Str.csv` | 76 KB — biggest. String-table for many fixed UI strings. |
| `Base.csv` / `GameBase.csv` | Game metadata. |
| `Source.csv` / `ex.csv` / `exp.csv` | Source/EXP curves. |
| `_Rename.csv` / `_Replace.csv` | Engine-level identifier remapping. |
| `Chara/` | Per-character static stats — `Chara<N> <name>.csv` for ~150 characters + `Chara0.csv` for the player. |

Key fact: a kōjō file's guard `CFLAG:NNN` only makes sense when read alongside `CFLAG.csv`. Same for `TFLAG`, `TCVAR`, `Talent`, `Abl`. The CSV layer is the *namespace* that the kōjō DSL reads against.

## 3. `ERB/` — code

The flat `.ERB` files at the ERB root handle bootstrap, big system loops, and global commands. The subdirectories are organized by feature:

| Subdir / file | Role |
|---|---|
| `初期設定.ERB` | Game start init. |
| `SYSTEM.ERB`, `TITLE.ERB`, `NEWGAME/` | Title screen, new-game flow. |
| `DIM.ERH` | Variable-dimension declarations (the engine's `#DIM` schema). |
| `COMMON.ERB` (83 KB) | Engine-wide common subroutines. |
| `BATTLE.ERB`, `CASINO/`, `NOUMIN.ERB`, `YASAI.ERB`, `アイテム解説.ERB` | Mini-systems (battle, casino, farming "農民", veggies, item descriptions). |
| `天候*` (`システム.ERH` / `予測*.ERB` / `管理拡張.ERB` / `日時天候管理.ERB`) | Weather subsystem (and the example "plugin" archetype). |
| `時間停止解除.ERB` | Time-stop release. |
| `潜伏モード関連/` | Stealth / sneak mode. |
| `衣服/` | Clothing system. |
| `グラフィック表示ライブラリ/` | Graphics-display library. |
| `ステータス計算関連/` | Status computation: `ABL/`, `ATTITUDE.ERB`, `STAIN.ERB`, `TRACHECK*.ERB`, etc. — these compute affection/orgasm/post-train state changes after every command. |
| `ステータス表示関連/` | UI display: character portraits, color, BAR, IMAGE, INFO, look. |
| `キャラデータ/` | `Chara_data_<N>_<name>.ERB` — one per character; runtime-loaded character setup. |
| `カラム機能/` | Column / panel UI. |
| `イベント関連/` | Date events, daily events, festivals, gifts, jealousy/affair, pregnancy. |
| `コマンド関連/` | Player command system: `COMABLE/`, `COMF/`, `SCOMF/`, `COMORDER.ERB`, `USERCOM*`, etc. |
| `SHOP関連/` | Shop interactions. |
| `ALTER/`, `MOVEMENTS/`, `OBJ/`, `COLOREDMAPS/`, `DLC/`, `NEWCHARACTERリソース作成/` | Misc subsystems (re-skinning, location movements, map backgrounds, DLC, resource generation). |
| `method_from_anon/`, `method_from_eratohoЯeverse/` | Library subroutines lifted from anon contributors and eratohoR. |
| `魔改内容/` | Mod-specific content. |
| `口上・メッセージ関連/` | **The kōjō / message tree — Phase 2's focus.** |

### `コマンド関連/` (the command layer that kōjō hooks into)

| Subdir/file | Role |
|---|---|
| `COMABLE/` (`COMABLE.ERB`, `COMABLE_300.ERB`, `_400`, `_500`, `_600`, `_700`, `_80`, etc.) | "Is this command available right now?" gates. The numeric suffixes match the command-ID ranges. |
| `COMF/` | "Command Function" — the per-command implementation files, named by command ID + label, e.g. `COMF12 胸揉み.ERB`, `COMF184 野外プレイ.ERB`. The file name's numeric prefix is the command ID. **These define what each command does mechanically; kōjō files supply the per-character dialogue.** |
| `SCOMF/` | "Sub-command function" — derived/secondary commands (60s, 70s, 80s ranges). |
| `COMORDER.ERB` | Command sequencing / chaining. |
| `USERCOM.ERB`, `USERCOM_*` | User-defined command system / hooks. |
| `カレンダー.ERB` | In-game calendar. |
| `催眠発動.ERB` | Hypnosis activation. |
| `外出先から帰宅.ERB` | "Returning home from outside." |
| `集合.ERB` | Group gathering. |
| `願掛けパッチ.ERB` | "Wish-making" patch. |

### Command-ID namespace (extracted from `COMF/` naming)

The command-ID space is partitioned by *hundreds*:
- **0–99**: misc / primitive (e.g. `COMF1 クンニ`, `COMF11 乳首吸い`, `COMF15 クリ愛撫`, `COMF80 手を引く`).
- **100s**: SM / discipline tools (`COMF100 スパンキング`, `COMF101 鞭`, `COMF105 縄`, `COMF107 拘束プレイ`).
- **120s–140s**: assistant-involving / advanced (`COMF122 助手を犯させる`, `COMF140 イラマチオ`, `COMF141 フィストファック`).
- **180s**: situational / aids (`COMF180 ローション`, `COMF181 媚薬`, `COMF184 野外プレイ`, `COMF188 シャワー`).
- **300s**: daily-life commands (会話 300, 泡茶 301, 身体接觸 302 …) — **these match the IDs in `M_KOJO_K<id>_日常系コマンド.ERB`**.
- **400s**: housekeeping/training (掃除 410, 戦闘訓練 411, 学习 412, 料理 413, 吃飯 414, 415, 演奏 416, 午睡 417, 祈願 421, 浴室 431, 等待 440, 聽課 441, 伐採 442).
- **500s**: presumably battle/spell commands (need to verify).
- **600s**: date commands (約会).
- **700s**: self-pleasure / "自慰系" (separate `700 自慰系/` subdir under COMF).
- **80** and lower SCOMF: derived sub-commands accessed via `TFLAG:50`.

Cross-references in this scheme:
- A character's `M_KOJO_K<id>_日常系コマンド.ERB` defines the per-character speech for command IDs 300–4xx.
- `COMF/COMF<id> <name>.ERB` defines what that command actually *does* mechanically.
- The dialogue is dispatched only after the engine decides the command was selected; kōjō never decides "what happens", only "what's said."

## 4. `ERB/口上・メッセージ関連/` — the kōjō tree

This subtree contains:

```
COMMON_KOJO.ERB           library: SAMEROOM, KOJO_ACTIVE_INFO, SET_KOJO_COLOR,
                          SEND_ASSISTANT_KOJO, KOJO_CHECK, OPPAI_DESCRIPTION, …
KOJO_MESSAGE.ERB          dispatcher: KOJO_MESSAGE_SEND(ARGS, …) — a giant
                          SELECTCASE on ARGS that fans out to the right
                          M_KOJO_<...>_K<id>_<key> labels.
EVENT_MESSAGE.ERB         common (character-agnostic) post-train messages:
                          PALAM_MESSAGE_C / _D, OPPAI_DESCRIPTION, …
EVENT_MESSAGE_COM.ERB
EVENT_MESSAGE_COM300.ERB  default (no-character-specific) command messages.
EVENT_MESSAGE_COM400.ERB
EVENT_MESSAGE_COM500.ERB
EVENT_MESSAGE_COM700.ERB
EVENT_MESSAGE_COM80~.ERB
EVENT_MESSAGE_COM_SM系.ERB
EVENT_MESSAGE_COM_セクハラ.ERB
EVENT_MESSAGE_COM_押し倒し.ERB
EVENT_MESSAGE_COM_道具系.ERB
EVENT_MESSAGE_挿入系COM/ (subdir)
EVENT_MESSAGE_派生COM.ERB
EVENT_MESSAGE_脱衣.ERB
EVENT_MESSAGE_MARK.ERB
EVENT_MESSAGE_ORGASM.ERB
AUTO_AEGI.ERB             auto-moaning for sleep/etc when no kōjō covers it
STAND_COM_IMAGE.ERB       command-image display
TINKO_TYPE.ERB            penis-type description
個人口上/                  per-character kōjō (153 character dirs).
```

**Critical insight from `KOJO_MESSAGE.ERB`:**

The dispatcher builds label names *dynamically*:

```erb
TRYCALLFORM M_KOJO%RESULTS%_EVENT_K{NO:TARGET}_{ARG:1}(ARG:3,ARG:4)
TRYCALLFORM M_KOJO%RESULTS%_MESSAGE_%LOCALS%_K{NO:TARGET}_{LOCAL}
```

- `NO:TARGET` = the character's numeric ID.
- `RESULTS` = a *kōjō-selector suffix* (often empty `""`; non-empty when a character has multiple alternative voicings — see `KOJO_ACTIVE_INFO` and `CFLAG:ARG:口上セレクタ`).
- `LOCALS` = `"COM"` for primary commands, `"SCOM"` for sub-commands (toggled by `TFLAG:50`).
- `LOCAL` = the command ID.

So the label **`@M_KOJO_MESSAGE_COM_K59_300`** means: *Koakuma (id 59), kōjō selector empty, COMMAND-style message, primary COM family, command 300 (会話).* The dispatcher **falls back gracefully** when a label is missing (`TRYCALLFORM` is "try-call" — silent if not defined, hence the LOCAL=0 stubs in every kōjō file). On missing, the engine falls back to `M_KOJO%RESULTS%_MESSAGE_COM_K{NO}_00` (a generic catch-all for that character) and from there to `EVENT_MESSAGE_*` (the no-character defaults).

Other dispatch shapes in the same file:
- `M_KOJO%RESULTS%_ENCOUNTER_K{NO}` (first-impression / on-encounter line).
- `M_KOJO%RESULTS%_SPEVENT_K{NO}_{event_id}(ARG:3,ARG:4)` (special events with arg passing).
- `M_KOJO%RESULTS%_EVENT_K{NO}_{event_id}(ARG:3,ARG:4)` (regular events).
- `M_KOJO%RESULTS%_MESSAGE_COM_K{NO}_{cmd}` / `_SCOM_K{NO}_{cmd}` (command messages).
- Special `_MESSAGECHECK_*` variants returning a bitfield of `{SKIP_MESSAGE, SKIP_KOJO}` so a kōjō can override default text without printing.

There are also gating CFLAGs that decide whether kōjō runs at all in special states:
- `CFLAG:N:時間停止口上有` — does this character have time-stop dialogue?
- `CFLAG:N:扮演口上有` — does this character have role-play dialogue?
- `CFLAG:N:眠姦口上有` — does this character have sleep-rape dialogue?
- `CFLAG:N:自動喘息` — fall back to AUTO_AEGI moaning.
- `CFLAG:N:口上セレクタ` — selector index for alternative voicings (multiple kōjō personas per character).

Set in `Chara_data_<N>_<name>.ERB` at character init.

## 5. `個人口上/` — character-keyed kōjō dirs

153 directories at the top level. Naming: `<3-digit-ID> <ROMAJI_NAME> [<JP_NAME>]`. IDs are not contiguous (e.g. 145, 153, 155–158 missing).

Each character directory contains **1 or more author-variant subdirectories**. Examples:

- `006 Luna [ルナ]/`: only `ルナチャイルド/` (one variant, "child" persona).
- `042 Hatate [はたて]/`: `はたて/` and `试做型姬海棠 自制别人/` (two authors).
- `049 Satori [さとり]/`: `さとり/`, `さとり(24.5.14)/`, `古明地觉_试制口上v0.053/` (three).
- `139 Tsukasa [典]/`: `典/` and `典（机翻更新版）/` (two).

The author-variant directory is what actually gets loaded; multiple variants coexist in the tree but only one is selected at a time (via `CFLAG:N:口上セレクタ`).

Inside an author-variant directory, files follow a near-canonical taxonomy keyed by feature/category, all named **`M_KOJO_K<id>_<category>.ERB`**:

| File | Contains labels of shape | Purpose |
|---|---|---|
| `M_KOJO_K<id>_日常系コマンド.ERB` | `@M_KOJO_MESSAGE_COM_K<id>_<3xx/4xx>` | Daily commands (talk, hug, kiss, train, eat, …). Largest file usually. |
| `M_KOJO_K<id>_性交系コマンド.ERB` | `@M_KOJO_MESSAGE_COM_K<id>_<5xx>` | Penetrative/sexual commands. |
| `M_KOJO_K<id>_セクハラコマンド.ERB` | `@M_KOJO_MESSAGE_COM_K<id>_<...>` | Sexual-harassment commands. |
| `M_KOJO_K<id>_愛撫系コマンド.ERB` | command messages | Foreplay-tier commands. |
| `M_KOJO_K<id>_加虐系コマンド.ERB` | command messages | Sadistic/hard commands. |
| `M_KOJO_K<id>_ハードなコマンド.ERB` | command messages | "Hard" commands (extreme). |
| `M_KOJO_K<id>_奉仕系コマンド.ERB` | command messages | "Service" (sub-led) commands. |
| `M_KOJO_K<id>_道具系コマンド.ERB` | command messages | Tool/toy-using commands. |
| `M_KOJO_K<id>_派生コマンド.ERB` | `@M_KOJO_MESSAGE_SCOM_K<id>_<n>` | Derived sub-commands. |
| `M_KOJO_K<id>_コマンド.ERB` | command messages | Generic command file (some authors merge categories). |
| `M_KOJO_K<id>_イベント.ERB` | `@M_KOJO_EVENT_K<id>_<event_id>` and `@M_KOJO_SPEVENT_K<id>_<event_id>` | Events, special events. Largest file in heavy authorings. |
| `M_KOJO_K<id>_カウンター.ERB` | `@M_KOJO_COUNTER_K<id>_<n>` | "Counter" — interrupted/forced/NTR scenarios. |
| `M_KOJO_K<id>_弾幕勝負.ERB` | `@M_KOJO_DANMAKU_K<id>_<n>` | Danmaku duels. |
| `M_KOJO_K<id>_依頼.ERB` | `@M_KOJO_IRAI_K<id>_<n>` | Quest/request dialogue. |
| `M_KOJO_K<id>_刻印取得.ERB` | `@M_KOJO_MARK_K<id>_<n>` | Mark/imprint acquisition lines. |
| `M_KOJO_K<id>_絶頂.ERB` | `@M_KOJO_ORGASM_K<id>_<n>` | Climax lines. |
| `M_KOJO_K<id>_日記.ERB` | `@M_KOJO_DIARY_K<id>_<n>` | Diary entries. |
| `M_KOJO_K<id>_育児イベント.ERB` | events | Child-rearing. |
| `K<id>_固有カウンター<n>_<name>.ERB` | character-unique counter scenarios | Optional, character-specific. |
| `M_KOJO_K<id>_典特殊イベント.ERB`, `M_KOJO_K<id>_関数ライブラリ.ERB`, `M_KOJO_K<id>_コマンド酔夢想.ERB`, `_自動喘ぎ.ERB`, etc. | Author-specific extras | Highly variable. |
| `readme.txt` / `readme*.txt` / `ライセンステンプレ.txt` / `ライセンス.txt` | Author docs/license | Not loaded. |
| `CFLAG一覧.txt`, `フラグ管理メモ.txt`, `衣装メモ.txt`, `さとりの日記.txt`, ... | Author memos | Not loaded. |
| `Lib/`, `自分用メモ/` | Author libraries / memos | Sometimes contains additional ERB files actually loaded by the engine. |

**File-extension note:** `.erb` and `.ERB` are mixed and equivalent. Some authors use `*.txt` for memos; some use `*.txt` for actual content not yet promoted to ERB (e.g. `さとりの日記.txt`).

**Variability across authors** is the hard part of the eventual document: the file-set is *de facto canonical* but not enforced. Some characters have only the bare minimum; some have ~25 files including lookalikes. Tsukasa has its own function library (`関数ライブラリ.ERB`) — meaning author-defined helpers are allowed and used.

## 6. The "weather plugin" mentioned in the task

`ERB/天候システム.ERH`, `天候予測システム.ERB`, `天候管理拡張.ERB`, `日時天候管理.ERB` — sizable (≈220 KB total). This is the prototype of what a non-kōjō "plugin" looks like: a self-contained subsystem implemented as one or more `.ERB` files at the ERB root, declaring its own state via `.ERH` (header) plus runtime logic in `.ERB`. **For the eventual document, the right framing is:**

- A "plugin" is a file (or set of files) under `ERB/` that the engine simply picks up at load time. There is no plugin manifest — Emuera scans ERB/ recursively. So adding a plugin = dropping new ERB files.
- A *kōjō plugin* (the most common kind) is a new author-variant directory under `個人口上/<id> <name>/`, containing the `M_KOJO_K<id>_*` file set.
- A *system plugin* (like weather) is one or more new `.ERB`/`.ERH` files anywhere under `ERB/`, exposing labels callable from the rest of the engine.

## 7. What I need next (going into Phase 2)

To turn this scaffold into a useful per-character note, I have to learn (from Luna first):
1. The **complete control-flow vocabulary**: which Emuera primitives, predicates, helpers, and variable namespaces are in use.
2. The **per-category file shape**: header banner conventions, label naming, function-arg patterns (e.g. `@LABEL(ARG, ARG:1)`), use of `LOCAL = 1` / `LOCAL = 0` stub gating.
3. The **state-bus** — which CFLAG/TFLAG/TCVAR ranges mean what (cross-referencing CSV/CFLAG.csv etc. only when needed).
4. Author-defined helpers and how character-unique files (`*固有カウンター*`, `*特殊イベント*`, `関数ライブラリ`) integrate.
5. **Meta-content reactions** (Satori) — does she read `CFLAG`/`TFLAG` of *other* characters or `MASTER` to "see" what you're doing?
