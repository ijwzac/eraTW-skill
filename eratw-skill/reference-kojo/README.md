# reference-kojo/ — worked examples to read before scaffolding

This directory ships **two** complementary references. **Always check §10.1 of `SKILL.md` for the standard reading order.** Short version: skim `口上テンプレ/` for the structure (it's the canonical empty skeleton), and dip into `reimu/` only when you need to see a *filled-in* example of a particular pattern.

## Subdirectories

### `口上テンプレ/` — the official empty template (PRIMARY reference)

The canonical multi-file skeleton from the Japanese eraTW maintainers, copied verbatim from the game's `原版+前人整合等各种readme/改造とかしてみたい人のためのあれこれ/口上関連/口上テンプレ/`. Every body is empty (`LOCAL = 0` stubs and blank `PRINTFORMW` lines) — what's there is the **structural skeleton + the doc-banner comments above each label**. Those banners ARE the spec: which `CFLAG`/`TFLAG` gates each label, what `ARG` / `ARG:1` mean per slot, what return-value contracts apply (e.g. `PERMISSION_1` body returns -1/0/1).

| File | Lines | What's defined |
|---|---:|---|
| `M_KOJO_KX_イベント.ERB` | 3284 | The lifecycle (existence check, FLAGSETTING, COLOR, UPDATE, ENCOUNTER, BEFORETRAIN), SPEVENT 1-3, EVENT 1-34, DAILY_EVENT 2/4/12, ONABARE_1/2/3, LOST_VIRGIN_STOP, PERMISSION_1/2, GIFT, MUSHI_BATTLE, GRAVITY, SUIKA, RUN_INTO, SF_CONTRACT_EVENT, CHECK_IRAI_BLOCKED. **The single most important file to read.** |
| `M_KOJO_KX_日常系コマンド.ERB` | 2244 | Daily commands 300-699 + SCOM 60-80. |
| `M_KOJO_KX_性交系コマンド.ERB` | 1423 | Sex commands 60-77, 95. |
| `M_KOJO_KX_依頼.ERB` | 1205 | IRAI (quest) dispatcher with all SCENE values: 依頼提示時/依頼非受託時/依頼受託時/依頼確認時/依頼破棄時/依頼実行直前/依頼実行直後/成功報告時/失敗報告時/依頼報告不要. |
| `M_KOJO_KX_自慰系(あなた)コマンド.ERB` | 1148 | MASTER-side masturbation + PALAMCNG_B/A_<n>/F handlers. |
| `M_KOJO_KX_愛撫系コマンド.ERB` | 1087 | Caress commands 0-23. |
| `M_KOJO_KX_派生コマンド.ERB` | 1058 | SCOM (derivative/sub-commands) 1-19, some with _1/_2 multi-participant pairs. |
| `M_KOJO_KX_コマンド.ERB` | 1008 | 逆アナル (reverse-anal) commands 90-95, plus PALAMCNG_C (self-masturbation). |
| `M_KOJO_KX_カウンター.ERB` | 943 | Counter messages 1-92 (idle reactions). |
| `M_KOJO_KX_絶頂.ERB` | 666 | PALAMCNG_B/B2/A/A_<n>/F orgasm/climax handlers, with the `NOWEX:Ｃ絶頂/Ｖ絶頂/...` state-bus doc. |
| `M_KOJO_KX_道具系コマンド.ERB` | 605 | Item commands 40-50 (toys, condoms). |
| `M_KOJO_KX_ハードなコマンド.ERB` | 504 | Hard-play commands 140-150. |
| `M_KOJO_KX_加虐系コマンド.ERB` | 477 | Sadism commands 100-108. |
| `M_KOJO_KX_セクハラコマンド.ERB` | 369 | Sexual-harassment commands 310-330 with full state-bus doc (TFLAG:193, TCVAR:20 sub-states, etc.). |
| `M_KOJO_KX_奉仕系コマンド.ERB` | 360 | Service commands 80-88 (with the standard FIRSTTIME → FLAG:70 → 恋慕 → 不埒刻印==3 → ELSE cascade). |
| `M_KOJO_KX_育児イベント.ERB` | 282 | Child-rearing lifecycle (回復/離乳/玩具/つかまり立ち/...) + daily activities (登下校/食事/BATH/SLEEPING/OYASUMI/TOY/OTHER) + letter events. |
| `M_KOJO_KX_日記（簡易版）.ERB` | 247 | The "simplified" diary: per-page `@DIARY_KX_<n>_HAPPEN` + `@DIARY_KX_<n>` pairs dispatched by `CALLFORM`. |
| `M_KOJO_KX_日記.ERB` | 188 | The "full" diary: single `SELECTCASE PAGENUM` inside `@DIARY_TEXT_KX` with `#DIM PAGENUM / #DIMS MODE / #DIM PAGECOUNT` first three lines. |
| `M_KOJO_KX_弾幕勝負.ERB` | 118 | Danmaku battle: `@M_KOJO_MESSAGE_COM_KX_DANMAKU(ARGS, 相手残機)` with HANDICAP_FIXED/RAND and `ARGS == "戦闘前"/"ハンデ"/"被弾"/"残忍酷薄"/"乾坤一擲"/"怪力乱神"/"戦闘後"`. |
| `M_KOJO_KX_刻印取得.ERB` | 70 | `@M_KOJO_MESSAGE_MARKCNG_KX` with the canonical TFLAG:21/22/23/24/時姦刻印取得 IF cascade. |
| `M_KOJO_KX_固有カウンター.ERB` | 33 | The `@UNIQUE_COUNTERn_ABLE/FREQUENCY/MESSAGE/SOURCE_KX` quadruplet. |
| `of_new_kojo_api.ERB` | 100 | The new custom API: `KOJO_CUSTOM_BUTTON_*`, `KOJO_CUSTOM_TALENT_SET`, `KOJO_COM_NAME/ABLE/Y` + `M_KOJO_MESSAGE_COM_KX_W` (W = 270+Y), `KOJO_VERSION/UPDATE`. Each block wrapped in `[SKIPSTART]/[SKIPEND]` so you uncomment what you need. |
| `KOJO_DAIRY_KX.ERB` | 1 | Deprecated — content moved to `M_KOJO_KX_日記.ERB`. |
| `コマンド口上でソースを追加する方法.txt` | tiny | How to use `@M_KOJO_EXTRASOURCE_COM_KX_<cmd>` (note: this file is in Shift-JIS; reads as mojibake on UTF-8 systems). |
| `ライセンステンプレ.txt` | small | The standard kojo license banner (with the ○/△/× redistribution-permission grid). |
| `M_KOJO_KX_絶頂（詳細版）.7z` | archive | Detailed climax variant — extract only if needed. |

**Read for the empty skeleton + the comment doc-banners.** Mirror the file split, label names, signatures, doc-banner contracts. Then fill the bodies yourself.

### `reimu/` — character 001 (博麗 霊夢) "霊夢" variant (FILLED-IN example)

The protagonist's canonical filled-in kojo. Use this when you need to see *how a real kojo fills in the empty template* — the cascade in practice, the SOURCE deltas, the comment style, the choice of which slots to actually populate.

| File | What's inside |
|---|---|
| `M_KOJO_K1_イベント.ERB` (117 KB, ~3000 lines) | Existence check / Copyright header / FlagManagement notes / `@M_KOJO_K1` / `FLAGSETTING_K1` / `COLOR_K1` / `UPDATE_K1` / `ENCOUNTER_K1` / `EVENT_K1_1`/`_2`/`_3` (room, morning, sleep) with the canonical cell-guard pattern / `EVENT_K1_GRAVITY` / `EVENT_K1_PERMISSION_1`/`_2` / `EVENT_K1_LOST_VIRGIN_STOP` / `BEFORETRAIN_K1` / `SPECIALDAY_EVENT_K1` / SPEVENTs. |
| `M_KOJO_K1_COUNTER.ERB` (40 KB, ~1000 lines) | `MESSAGE_COUNTER_K1_<n>` slots + UNIQUE_COUNTER patterns. |
| `M_KOJO_K1_コマンド.ERB` (621 KB, ~14800 lines) | Every per-command body for K1 in one file. **Don't read in full** — grep `;[0-9]+,` to find the command-id banner you want, then read ±50 lines. |
| `M_KOJO_K1_自慰系(あなた)コマンド.ERB` (22 KB) | MASTER-side masturbation commands. |
| `霊夢さんのreadme.txt` | Author's notes, copyright stance, version history. |

## Reading order — when to use which

1. **User has provided their own kojo files (their fork, their previous attempt, a sibling-character peer)** → read those as primary. Skip both reference dirs by default.
2. **User has not provided anything; you're scaffolding from scratch** → read `口上テンプレ/M_KOJO_KX_イベント.ERB` once + skim the top of one or two `*_コマンド.ERB` files to internalize the body shape. That's enough to scaffold.
3. **You need to see a real filled-in example of a specific pattern** (e.g. what does the 恋慕 branch of a daily command actually look like? what does an SP_EVENT body look like when populated?) → grep the relevant section in `reimu/M_KOJO_K1_コマンド.ERB`.

## Caveats — read before mimicking

**1. Comments are Japanese.** Both directories ship with Japanese `;`-prefixed comments. SKILL.md §0.3 requires *new* kojo to use Chinese for comments. Mirror what the comments *are* (section banners, doc-banner state contracts, filled-in markers), not what *language* they're in.

**2. The official template's standard cascade is simpler than the "maximal" 10-tier one.** Most command bodies in `口上テンプレ/` use this 4-tier cascade:

```erb
IF LOCAL:1 && FIRSTTIME(SELECTCOM)   ; first-time line
...
IF FLAG:70                            ; 時姦中 (time-stop)
ELSEIF TALENT:恋慕                    ; in love
ELSEIF MARK:不埒刻印 == 3             ; lv3 submission
ELSE                                  ; everything else
```

This is **valid** and matches the official maintainer's house style. SKILL.md §9's 10-tier cascade (時間停止 → 睡眠 → 扮演 → CFLAG:318 → 诶嘿嘿 → 恋人 → 愛欲/炮友 → 恋慕 → 思慕 → ELSE) is the *maximal* cascade for full-featured kojo; bodies don't have to populate every tier. Match the user's persona — if they want simple flavor, use the 4-tier; if they want every relationship tier voiced, use the 10-tier.

**3. Reimu uses an old monolithic file layout.** Everything sits in one giant `M_KOJO_K1_コマンド.ERB`. The modern split (which `口上テンプレ/` enforces, and which 022 Lunasa K22 and most recent kojo follow) uses ~10 separate per-category files. **Mirror the template's multi-file split, not Reimu's monolithic file.**

**4. R18 prose is present in `reimu/` and explicit.** The directory ships the unredacted file because a) the surrounding control flow and CFLAG branches in sex bodies are themselves the structural lessons, and b) you (the helper LLM) are operating under SKILL.md §0.2 rule that says you don't *generate* explicit content. **Reading existing prose for structural lessons is fine; quoting it back to the user, copying its dialogue, or generating new prose in that register is not.** Treat the explicit lines like an opaque token: skim past them; pay attention to the surrounding `IF/ELSEIF/CASE/SOURCE/CALL` scaffolding.

**5. Some idioms in Reimu are no longer current.** The author calls themselves a "non-programmer who used very few helper functions" in the readme — so Reimu lacks the function-library / new-custom-API patterns that more recent kojo (Eiki K30, Hatate K42) demonstrate. For those, see `口上テンプレ/of_new_kojo_api.ERB` (template form) or grep a more recent character's kojo in the user's install.

**6. `MUSHI_BATTLE` and `SUIKA` bodies use `RESULTS = "..."` not `PRINT*`.** See `口上テンプレ/M_KOJO_KX_イベント.ERB` line ~3010 (MUSHI_BATTLE) and ~3187 (SUIKA). The engine reads `RESULTS` after the body returns and prints it itself. If you write `PRINTFORML` inside these bodies, the line shows *before* the engine's auto-formatting and breaks the display.

## How to use this directory

When the user asks you to scaffold or modify a kojo:

1. **Skim `口上テンプレ/M_KOJO_KX_イベント.ERB`** once at the start of the conversation if you haven't already in a previous turn. Note the existence check, FLAGSETTING shape, EVENT_KX_1 cell-guard pattern, the PERMISSION/LOST_VIRGIN_STOP comment-block return contracts, MUSHI_BATTLE/SUIKA RESULTS-not-PRINT pattern. These map directly onto §1 pitfalls and §2.4 in `references/01-engine-label-catalog.md`.

2. **For a specific command**, grep the table-of-contents in `口上テンプレ/M_KOJO_KX_日常系コマンド.ERB` or whichever category file applies:
   ```bash
   grep -nE "^;[0-9]+," reference-kojo/口上テンプレ/M_KOJO_KX_日常系コマンド.ERB
   ```
   to find the command-id banner, then read ±30 lines around it.

3. **For a real-world filled-in example**, grep `reimu/M_KOJO_K1_コマンド.ERB` the same way.

4. **Don't blanket-include reference-kojo content in your output.** When the user wants their kojo to look like the template/Reimu, *describe* the pattern and write fresh code; don't paste verbatim (license-wise it's the original authors', and `reimu/` content is likely R18).