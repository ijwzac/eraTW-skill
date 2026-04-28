# Sub-agent findings — Phase 2.2

Findings from background sub-agents scanning ~149 character variant directories. Each agent compared their slice against `standalone_note_v1.md` and reported only structurally novel features (not content/voice).

---

## Batch 02 (Kanako 032 → Rika 047)

### 036 Orin [お燐]

- **Custom kōjō-selector with non-trivial name**: `RESULTS = "_吧友火焔猫燐制作"` (variant author's signature embedded). Prefixes all labels `@M_KOJO_吧友火焔猫燐制作_*`. Confirms selectors can be arbitrary Unicode strings, not just short suffixes.
- **`RELATION:N:M` namespace** — *new state-bus category*. `RELATION:36:37 = 200`, `RELATION:36:49 = 150`, `RELATION:36:135 = 120` (lines 61-66 of `M_KOJO_K36_1_イベント.ERB`). Engine-side **inter-character affinity** between two char IDs. Bodies can both write and read it.

### 038 Koishi [こいし]

- **Subdirectory file-organization** (variant `古明地恋_试制口上v0.053`): files split across `一般/`, `性/`, `自作/`, `其它/` subdirectories. File names use `M_KOJO_K38_514_イベント.ERB` style — prefix-renamed (the `514` is the event index baked into the filename).
- **Custom file-naming with numeric prefix in parens** (variant `ERATW用古明地恋口上《想起之途》`): `M_KOJO_K38_(1)SYSTEM.ERB`, `_(1)UPDATE.ERB`, `_(1)EVENT.ERB`, `_(1)ENVIRONMENTAL.ERB`, `_(1)FIGHT.ERB`, `_(1)BOOK.ERB`. Breaks the conventional `_<category>` taxonomy.
- **Custom dice-roll / outcome-determination helpers** (in `(1)SYSTEM.ERB` lines 4-53): `@M_KOJO_K38_FINALSCORING`, `@M_KOJO_K38_TURNZERO`, `@M_KOJO_K38_SUCCESS`. Suggests this Koishi variant implements its own probability engine for action resolution.

### Notes

- **045 Rikako, 046 Meira**: No kōjō implementation in this build (character IDs reserved but no directory contents).
- All other characters in this batch (032 Kanako, 033 Suwako, 034 Tenshi, 035 Iku, 037 Okuu, 039 Nazrin, 040 Kogasa, 041 Nue, 043 Kasen, 044 Ellen, 047 Rika) match the reference exactly.

---

---

## Batch 00 (Reimu 001 → Remilia 016) — partial coverage

### 001 Reimu [霊夢]

- **Experimental "new kōjō API" file** `of_new_kojo_api_TEST.ERB` introducing entirely **new dispatch label families** (variant `霊夢無個性版【別人修正】`):
  - `@M_KOJO_無個性_SUCCESS_K1_GENERAL` — generic success-flag handler (replaces per-command).
  - `@M_KOJO_無個性_EXTRASOURCE_SCOM_K1_GENERAL` — generic SCOM source handler.
  - `@KOJO_無個性_CUSTOM_BUTTON_CONDITION_K1_*` — predicate for showing a custom UI button.
  - `@KOJO_無個性_CUSTOM_BUTTON_K1_*` — custom-button click handler.
  - `@KOJO_無個性_COM_NAME_K1_*` — character-defined command name hook.
  - `@KOJO_無個性_COM_ABLE_K1_*` — character-defined command availability predicate.
  - `@KOJO_無個性_COM_K1_*` — character-defined command body.
  - This is a new dispatch tier — characters can define **fully new commands** (not just override engine commands).
- Variants: `霊夢`, `灵梦-少女之梦-5.28`, `霊夢無個性版【別人修正】` (3 variants).

### 014 Cirno [チルノ]

- **`MESSAGECHECK_COM`/`MESSAGECHECK_SCOM` hook** — `@M_KOJO_MESSAGE_MESSAGECHECK_COM_K14_<n>` and `_SCOM_K14_<n>` for command N.
  - Lines 289-3705 of `M_KOJO_K14_日常系コマンド.erb`.
  - **(NOTE: this is actually documented in the engine's dispatcher — `KOJO_MESSAGE.ERB` lines 73-75 and 205-207 read it via `SKIP_MESSAGE = GETBIT(RESULT, 0)` / `SKIP_KOJO = GETBIT(RESULT, 1)`.) Missing from reference §1.3 — must be added.**
- Variants: `チルノ　大妖精なりきり対応ver0.9` (with Daiyousei impersonation support).
- Tier: extreme.

### Coverage gap

Sub-agent reported it could not finish all 16 (paths-handling issues). Confirmed-novel:
- 001 Reimu (extreme — custom-command API).
- 014 Cirno (extreme — MESSAGECHECK hook + impersonation support).

Other chars in batch (002 Ruukoto, 004 Mima, 005 Sunny, 007 Star) reported as basic/no novelty. **003 Kana** has a stub-only "GITマージ用ファイル" implementation. **008-013, 015-016 — unchecked** (need direct re-check if anything there matters).

---

---

## Batch 03 (Louise 048 → Kagerou 063)

### 048 Louise — empty directory.

### 050 Flandre [フラン]
- 3 variants. Tier: rich.
- **ASCII-art library** with `@FONT_AA_50()` using helpers `CHKFONT()`, `SETFONT` (engine-side, not in §5).
- **Custom label prefix `@M_KOJO_flandre_tokikorin_MESSAGE_COM_K50_*`** in alt3 variant (`芙兰-白泽球(23.3.5) 修复`) — character-name-based selector instead of `_ORTHODOX`-style.
- **Per-event-id file naming** `m_kojo_k50_イベント_1111(エロ魔法の書).ERB`.

### 053 Tewi [てゐ]
- Multiple variants. Tier: extreme.
- **Subdirectory organization within a single variant**: `追加ファイル/自動喘ぎ/`. Reference noted Satori-0.053 as variant-level only; Tewi shows it in-variant.
- **Author-implemented auto-pant function** `@K53_AUTO_PVOICE()` with its own header `K53_自動喘ぎ用DIM.ERH`. Per-character author-implemented AUTO_AEGI replacement (the engine fallback only triggers when `CFLAG:N:自動喘息` is set).
- Per-variant feature gatekeeping: alt variant adds `M_KOJO_K53_1_弾幕勝負.ERB` not present in primary.

### 054 Patchouli [パチュリー]
- Tier: minimal.
- **`@M_KOJO_自由行動判定_K54(ARG)`** — non-standard label form. Lives in `M_KOJO_K54_自由行動.ERB` (a new file category — "free action").

### 058 Meiling [美鈴] — extreme.
- Char-private function library `K58C_美鈴用関数.erb` + DIM header `K58C_美鈴用DIM.ERH`. (Standard pattern, full-tier implementation.)

### 059 Koakuma [小悪魔]
- Two variants. Tier: rich.
- Alt variant `小悪魔長髪短髪切り替え` introduces **`@K59_HAIR(ARG)` rendering switch** with `#FUNCTIONS` (long-hair / short-hair toggle).
- Variant-level feature gatekeeping (alt has DANMAKU/IRAI/COUNTER, primary lacks).

### 060 Parsee [パルスィ]
- One variant. Tier: rich.
- Major character-event file `M_KOJO_K60_1_帕露西口上事件.ERB` with `@K60_CHOUSHICANBAI`, `@K60_YEXI1/2`, `@K60_RENNAI`. Substantial story-event library.
- File-name infix `K60_1` (variant-numeric) instead of just `K60`.

### 061 Mokou [妹紅] — extreme.
- **File organization by command-range** rather than category: `M_KOJO_K61_コマンド000～愛撫.ERB`, `060～性交.ERB`, `100～加虐.ERB`, etc.
- Heavy use of bit-flag CFLAG (`SETBIT CFLAG:61:1614, ...`).

### 062 Kaguya [輝夜] — extreme.
- **Author-implemented auto-pant**: `@K62_AUTO_AEGI(ARGS, ARG)` with helpers `@K62_AEGI_LEVEL()`, `@K62_AEGI_PATTERN()`. Stored in dedicated file `M_KOJO_K62_オートあえぎ.ERB`.
- Character-event file `M_KOJO_K62_輝夜口上イベント.ERB` with `@K62_I_KUSARI`, `@K62_UDONGE`, `@K62_GETTO`.
- `@K62_ROOM_DESCRIPTION()` helper.

### 063 Kagerou [影狼] — extreme.
- **`@M_KOJO_MESSAGE_MESSAGECHECK_COM_K63_<n>` confirmed**: this hook (return bitfield 0/1/2/3 = show desc/kōjō/both) is genuinely used. Same as Cirno (014) finding — confirms it's a missed hook in the reference.
- **`@K63_BEFORETRAIN()` hook** — runs before training; reference §1.3 lists `BEFORETRAIN` as a SEND key but didn't catalog the per-character label form.
- Conversation file `M_KOJO_K63_会話.ERB` (separate from コマンド).
- Big helper library `M_KOJO_K63_独自関数.ERB` with `@K63_OTSUKIMI_TALK`, `@K63_職場見学`, `@K63_WEAR_SAILOR`, `@K63_眉カット`, `@K63_SECRET`.
- Character state slots: `CFLAG:63:既成事實`, `CFLAG:63:合意_诶嘿嘿`.
- Consolidated `M_KOJO_K63_固有カウンター.ERB` (multiple unique counters in one file vs. separate files per counter).

---

## Batch 07 (Doremy 109 → Satono 123)

### 110 Sagume [サグメ]
- Two variants. Tier: rich.
- **Dedicated `M_KOJO_K110_INFO.ERB`** with `@CHARA_INFO_KOJO_K110()` separate from イベント.
- **Variant-specific CHARA_INFO label**: `@CHARA_INFO_KOJO_寒鹭探心_K110` — variant-name infix (not selector via RESULTS, but baked into label).
- New file category: `M_KOJO_K110_1_梦.ERB` (dream-content), `M_KOJO_K110_自慰系(あなた)コマンド.ERB` (self-pleasure).

### 111 Clownpiece [クラウンピース]
- One variant. Tier: rich.
- **`@M_KOJO_DIARYSETTING_K111(ARG)`** — diary lifecycle helper (between BEFORE_CHECK and TEXT).
- **`@M_KOJO_K111_適当日期設定(ARG)`** — date-setting helper.

### 112 Junko [純狐]
- Two variants.
- Dedicated **`M_KOJO_K112_会話.ERB`** for talk command (split from コマンド).

### 113 Hecatia [ヘカーティア] — extreme.
- **Multi-word kōjō selector** `RESULTS = "_総合スレ７４９"` (thread/community origin embedded). Confirms selectors can be quite long.
- Standalone **`M_KOJO_K113_UPDATE处理.ERB`** — UPDATE logic split into its own file.
- **Character-data subdirectory** `キャラデータ/` with `Chara_data_113_ヘカーティア.ERB`. Mirrors the engine's `キャラデータ/` structure but inside a kōjō dir.
- Function library named idiomatically: **`ヘカーティアの関数まとめ.ERB`** (override of standard `関数ライブラリ` name). Engine doesn't care about file names; only labels matter.
- **`@FORM_K113()`** with `#FUNCTION` — multi-body form-switching (Hecatia's three-body lore).
- **`@HEARTCB_K113(ARG:1, ARG, ARGS)`** — heart-mark rendering helper using `SETFONT`/`UNICODE`.

### 114 Kurumi, 115 Elly, 116 Mugetsu — empty directories.

### 117 Gengetsu [幻月]
- Tier: basic.
- **`@SPECIALDAY_EVENT_K117`** — standalone "special date" event handler (anniversary-style).

### 118 Larva [ラルバ] — extreme.
- **`TextColor.ERH`** — color constants in a separate `.ERH` (e.g. `#DIMS SAVEDATA GLOBAL <name>`). Sets up ANSI-color constants.
- **`#DIMS SAVEDATA GLOBAL MOE_LARVA_CALL_YOU`** — *new DIM modifier*: `SAVEDATA GLOBAL` declares a globally-persistent string variable that survives saves. (Reference §3.1 only listed `#DIM`/`#DIMS`/`#DIM CONST`/`DYNAMIC`.)
- **Author-namespace prefix**: `@MOE_LARVA_*` labels alongside `@K118_*`.
- File names in Chinese: `M_KOJO_K118_高版本地文适配函数.ERB`, `M_KOJO_K118_对话用函数.ERB`, `M_KOJO_K118_自定义事件系.ERB`.

### 119–123 (Nemuno, Aunn, Narumi, Mai Teireida, Satono)
- All "賑やかし" placeholder variants — minimal.

---

---

## Batch 04 (Yuugi 064 → Minoriko 078)

### 064 Yuugi [勇儀] — rich.
- `@M_KOJO_MESSAGE_MESSAGECHECK_COM_K64_<cmd>`, `_MESSAGECHECK_SCOM_K64_<cmd>`. **Confirms MESSAGECHECK family.**
- `@M_KOJO_EXTRASOURCE_COM_K64_<cmd>` — *new label form*: post-message side-effect for SOURCE ledger updates.
- Extended event families: `@M_KOJO_DAILY_EVENT_K64_*`, `@M_KOJO_EVENT_K64_GIFT`, `@M_KOJO_MESSAGE_COM_K64_MUSHI_BATTLE`, `@M_KOJO_EVENT_K64_GRAVITY`.

### 065 Momiji [椛] — rich.
- `@M_KOJO_SPEVENT_MESSAGECHECK_K65_1` — SPEVENT message-check.
- Extensive `@M_KOJO_MESSAGE_PALAMCNG_MESSAGECHECK_*` matrix.

### 066 Yuyuko [幽々子] — extreme.
- `@M_KOJO_MESSAGE_PALAMCNG_B2_K66` — **second B-category orgasm variant** (B2 alongside B; another orgasm-tier).
- `@M_KOJO_MESSAGE_PALAMCNG_F_K66` — F-category orgasm fallback.
- 30+ `_PALAMCNG_MESSAGECHECK_A_*` and `_A2_*` (A is "after-action"; A2 is the secondary tier).

### 067 Keine, 068 Yuuka, 075 Medicine, 076 Komachi, 078 Minoriko
- All use `@M_KOJO_MESSAGE_PALAMCNG_B2_K{id}` — **B2 is widely used** as a secondary orgasm hook.

### 070 Kosuzu [小鈴] — extreme.
- **Numbered multi-file cascade**: `M_KOJO_K70_01_*.ERB` … `M_KOJO_K70_11_*.ERB`. Files numbered 01-11 with category names.

### 072 Eirin [永琳] — extreme.
- `@M_KOJO_DAILY_EVENT_MESSAGECHECK_K72_2` — DAILY-event message-check.
- `@M_KOJO_MESSAGE_COM_K72_MUSHI_BATTLE` — bug-battle dispatch (shared with K64).
- 34 EVENT labels — extensive event library.

### 076 Komachi [小町] — extreme.
- **`Lib/` subdirectory**: `Lib/M_KOJO_K76_関数ライブラリ.ERB`.
- **`@K76_BEFORETRAIN`** — character-private "day-start initialization" function.
- 31 EVENT labels.

### 071 Shinmyoumaru.
- `_PALAMCNG_MESSAGECHECK_*` appears in `M_KOJO_K71_コマンド.ERB` (unusual — usually only in 絶頂 file). Hooks are file-position-independent; engine just looks up labels.

### 077 Shizuha — empty directory.

---

## Batch 05 (Hina 079 → Wakasagihime 093)

### 079 Hina [雛] — rich.
- `追加ファイル/` subdirectory with `M_KOJO_K79_特殊イベント.ERB`, `M_KOJO_K79_特殊事件.ERB`, `M_KOJO_K79_絶頂到達.ERB`.
- Custom event-prefix: `@M_KOJO_MESSAGE_EVENT_K79_EX_TALK`, `_EX_350`, `_EX_ORGASM`. The `_EX_` infix appears to be an author-namespaced "extra event" tier.

### 081 Renko / 082 Maribel — basic.
- `M_KOJO_K81_INFO.ERB` / `M_KOJO_K82_INFO.ERB` containing `@CHARA_INFO_KOJO_K81/82()` — confirmed pattern.

### 083 Kisume [キスメ] — rich.
- `#FUNCTION`/`#FUNCTIONS` author helpers in main event file: `@M_KOJO_K83_FUKIGEN(ARG)`, `_YOIDORE(ARG)`, `_UFUFU(ARG)`, `_AUTO(ARGS)`.
- `@M_KOJO_K83_AUTO(ARGS)` returns randomized moan strings via `#FUNCTIONS`.
- New TALENT slot: `TALENT:心情` (mood) — possibly char-specific.
- `@M_KOJO_SPEVENT_MESSAGECHECK_K83_*`.
- New helper `ALCOHOL_FACE()` (engine).

### 087 Shou [星] — basic.
- Elaborate CFLAG state-tracking scheme: `CFLAG:1200`, `1201`, `1202` for "first-time after X" tracking.

### 090 Seiga [青娥] — extreme.
- `M_KOJO_K90_自慰系(あなた)コマンド.ERB` — **new file category**: player-self-pleasure commands.
- `M_KOJO_K90_INFO.ERB` with `@CHARA_INFO_KOJO_K90()`.
- 50+ counter labels with fine-grained event IDs.

### 092 Futo [布都] — basic.
- `@M_KOJO_MESSAGE_MARKCNG_MESSAGECHECK_K92` — **MARKCNG message-check**. Confirms the MESSAGECHECK family extends to marks.

### 093 Wakasagihime — empty directory.

---

## Batch 06 (Benben 094 → Ringo 108)

### 094 Benben — `@SPECIALDAY_EVENT_K94` (line 665 of イベント.ERB).

### 097 Seija [正邪] (`OwO自制正邪` variant) — extreme.
- `RESULTS = _OwO` selector.
- Files prefixed `NO.0M_KOJO_K97_OwO_*.ERB`, `NO.1M_KOJO_K97_OwO_*.ERB`, etc.
- **`@M_KOJO_OwO_DAILY_EVENT_K97_<n>(ARG, ARG:1, ARG:2, ARG:3, ARG:4, ARGS:1, ARGS:2)`** — DAILY_EVENT with 7-arg signature (ARG:0..4 + ARGS:1..2).
- New labels:
  - `@M_KOJO_OwO_EVENT_K97_LOST_VIRGIN_STOP`
  - `@M_KOJO_OwO_EVENT_K97_PERMISSION_*`
  - `@M_KOJO_OwO_EVENT_K97_GIFT`
  - `@M_KOJO_OwO_MESSAGE_COM_K97_MUSHI_BATTLE`
  - `@M_KOJO_OwO_MESSAGE_COM_K97_SUIKA`
  - `@M_KOJO_OwO_EVENT_K97_GRAVITY`
  - `@RUN_INTO_K97` — random encounter
  - `@KOJO_SF_CONTRACT_K97` — sex-friend contract

### 098 Yorihime [依姫] — rich.
- New file category `M_KOJO_K98_相关判定.ERB` (judgment/decision split).

### 099 Toyohime [豊姫] — rich.
- Selector `RESULTS = _STELLARIS`.
- Files use `_1_` versioning suffix: `M_KOJO_K99_1_UPDATE.ERB`.
- Mixed-case labels: `@M_KOJO_STELLARIS_ENCOUNTER_k99` (lowercase id).

### 102 Shinki, 105 Mai — empty directory or minimal.

### 103 Yumeko [夢子] — extreme.
- **Numerically prefixed file ordering**: `M_KOJO_K103_00_DIM.ERH`, `_01_イベント.ERB`, `_02_カウンター.ERB`, … `_18_奉仕系コマンド.ERB`. Implements load-priority via filename ordering.
- `00_DIM.ERH` includes versioning constant: `K103_TC_バージョン = 34`.
- `00_専用関数.ERB` is the function library.
- Custom **ONABARE arg signature**: `@M_KOJO_EVENT_K103_ONABARE_<n>(前戯１, 本番はどっちか, 回数, 注入量)`.

### 108 Ringo — function summary file `鈴瑚の関数まとめ.ERB`.

---

## Batch 09 (Megumu 140 → 先代 159)

### 140 Megumu [龍] — rich.
- Versioned existence check `@M_KOJO_K140_1(ARG)` with selector `RESULTS = _POWERED_BY_DARKMAN`.
- Dedicated `M_KOJO_K140_INFO.ERB` with `@CHARA_INFO_KOJO_POWERED_BY_DARKMAN_K140()` (selector applies to CHARA_INFO label too).
- `@SPECIALDAY_EVENT_K140`.
- `$INPUT_LOOP1 / INPUT / ...` retry idiom in ENCOUNTER.

### 143 Yuuma [尤魔] — extreme.
- Author-private file `M_KOJO_K143_尤魔性処理.ERB` with `@YUMA_DAILY_SEX`, `@YUMA_INFERTILITY`, `@YUMA_INFERTILITY2`.
- `CFLAG:143:口上内抱き寄せ判定_通常 = 1` — reference contract is followed (FLAGSETTING does this).
- UPDATE multi-step UI via `CALL ASK_M(...)` for "reset imprinting" ritual.

### 154 Enoko [慧ノ子] — extreme.
- **`of_new_kojo_api.ERB`** — same "new kōjō API" file family as Reimu (001). Confirms this is a **shared experimental framework** across multiple chars. Defines:
  - `@M_KOJO_EXTRASOURCE_SCOM_K154_GENERAL`, `_COM_K154_GENERAL` — generic SOURCE-mutation hooks.
  - `@KOJO_CUSTOM_BUTTON_CONDITION_K154_Y`, `@KOJO_CUSTOM_BUTTON_K154_Y` — UI custom-button system.
  - `@KOJO_CUSTOM_TALENT_SET_K154` — info-pane talent override.
  - `@KOJO_COM_NAME_K154_Y`, `@KOJO_COM_ABLE_K154_Y`, `@KOJO_COM_K154_Y`, `@KOJO_CAN_COM_K154_Y` — author-defined custom-command framework.
  - `@KOJO_VERSION_K154`, `@KOJO_VERSION_UPDATE_K154` — save-game version migration.
- `@K154_BEFORETRAIN` (pre-train hook).
- `@M_KOJO_SPEVENT_MESSAGECHECK_K154_<n>`, `@M_KOJO_DAILY_EVENT_MESSAGECHECK_K154_<n>`, `@M_KOJO_MESSAGE_COUNTER_MESSAGECHECK_K154_<n>` — **the full MESSAGECHECK family applied across kinds**.
- `@M_KOJO_DAILY_EVENT_K154_<n>(ARG, ARG:1, ARG:2, ARG:3, ARG:4, ARGS:1, ARGS:2)` — 7-arg DAILY_EVENT signature (matches Seija's).
- `@M_KOJO_EVENT_K154_26_1(ARGS)` — string-arg sub-event variant.
- `@M_KOJO_CHECK_K154_IRAI_BLOCKED(ARGS, ARG, ARG:1)` — quest-blocking label.
- `@KOJO_SF_CONTRACT_EVENT_K154(ARGS)` — sex-friend contract event.
- `@RUN_INTO_K154(MAP_ID)` — random-encounter handler.

### 159 先代 [predecessor] — rich.
- **Placeholder-ID file naming**: `M_KOJO_K1[]_*` and `M_KOJO_KX_*` (template-form, designed to be replaced).
- Backup file `M_KOJO_K1[]_イベント SAVE.ERB`.
- ENCOUNTER body branches on `GETBIT(CFLAG:31, ...)` (reincarnation bit-flags, confirming reference §7 edge case).
- Direct writes to `CFLAG:信賴度`, `CFLAG:好感度`, `ABL:16:親密` — **author-private global slots**.

### 142 Momoyo, 144 Ibaraki's Arm, 146 Elis, 147 Sariel, 148 Sara, 149 Orange, 150 Konngara, 151 YuugenMagan, 152 Kikuri — all empty directories.

---

---

## Batch 08 (Okina 124 → Misumaru 138)

### 127 Eika, 133 Saki, 134 Miyoi
- **`@SPECIALDAY_EVENT_K{id}`** confirmed widely-used pattern (also in 094 Benben, 117 Gengetsu, 140 Megumu). Branches on `DAY:2` (month) and `DAY:3` (day).

### 132 Keiki [袿姫] — extreme.
- **`KX`-prefixed file infix**: `M_KOJO_KX_弾幕勝負.ERB`, `M_KOJO_KX_性交系コマンド.ERB`, `M_KOJO_KX_育児イベント.ERB` — template-stub form (placeholder `KX` not yet replaced with `K132`). Engine likely won't dispatch (label mismatch); these are template files not yet edited.
- `OTHER_EVENT_K132.ERB` — author-private event file (purpose unclear).
- `SHIROTREE_K132.ERH` with `#DIM SAVEDATA SHOOT_WISH_COUNT` — **`SAVEDATA` modifier** for persistent global storage.

### 134 Miyoi [美宵] — extreme.
- Full diary implementation (only character in batch with diary).
- Stub redirect file `KOJO_DAIRY_K134.ERB` (note misspelled "DAIRY") — points to actual `日記.ERB`.

### 128 Urumi, 131 Mayumi, 135 Mike, 136 Takane, 137 Sannyo, 138 Misumaru — empty / stub.

---

## Batch 01 (Alice 017 → Sanae 031) — partial

### 017 Alice [アリス] — rich.
- Inline author helpers in command files: `@K17_SKIP_TRAIN_MESSAGE`, `@K17_SET_KOJO_COLOR`, `@K17_CLL_COUNTER`. Defined directly in `M_KOJO_K17_日常系コマンド.ERB` instead of in a Lib/関数ライブラリ.

### 018 Lily W [リリーＷ] — basic.
- Two variants. Test variant uses `@M_KOJO_K18_1(ARG)` (versioned existence check) with `RESULTS = _tokicoli` selector.
- External author-extension files: `Lilywhite_coax.erb`, `Lilywhite_wine.erb`, `Lilywhite_cosplay.erb` — non-standard file names with `@LILYCOAX`, `@LILYWINE`, `@LILYCOSPLAY` etc.

### 019 Lily B [リリーＢ] — minimal.
- `@M_KOJO_MESSAGE_MESSAGECHECK_COM_K19_<n>` stubs returning 1 — empty stubs of MESSAGECHECK family.

### Coverage gap
Batch 01 sub-agent reported "020–031 not implemented" — *likely incomplete*. Need direct re-check of 020-031, especially **030 Eiki** (canonical helper-library source) and **031 Sanae** (substantial).

---

(coverage holes to close: 020-031 from batch 01, plus partial coverage on 008-013/015-016 from batch 00)
