# Which kojo should ship with the skill as a reference?

The skill currently has no `eratw-skill/reference-kojo/` directory. The bugfix log explicitly recommends adding one — *"a worked example beats a list of rules"* — and called out at least 9 distinct things that the test session learned from grepping Reimu's kojo that the guide didn't cover. This file evaluates candidates so we can act later.

## Decision criteria

A reference kojo must:

1. **Be canonical to this fork.** Use simplified-Chinese flag forms (`约会中`, not `約会中`). Use byte-exact slot names from this fork's CSVs. Survive `grep` against `references/data/CFLAG.csv`.
2. **Cover the standard label set.** Every conventional file (`イベント / 日常系 / 性交系 / セクハラ / 愛撫系 / 加虐系 / 道具系 / 派生 / カウンター / 弾幕勝負 / 依頼 / 刻印取得 / 育児 / INFO / 絶頂 / 関数ライブラリ`) so an LLM scaffolding any new kojo can find a working example to mirror.
3. **Be readable, not extreme-tier.** Files that are 1MB+ each (Hatate's `日常系コマンド.ERB` is 1.1MB) tax the LLM's read window and bury patterns under content. We want a *complete-but-not-bloated* example.
4. **Have a non-restrictive persona gate.** Luna's kojo wraps every body in `IF TALENT:MASTER:年齢 == -1 || TALENT:MASTER:幼児／幼児退行 || CFLAG:6:1001 == 1` — fine if the LLM understands why, but distracting noise for a "what's the standard pattern?" reference.
5. **Use modern conventions** (BEFORETRAIN hooks, EVENT cell-guard pattern, MARKCNG silent-when-no-mark guard, etc.) rather than legacy idioms.
6. **Avoid heavy author-private weirdness.** Satori has a kojo selector (`_ORTHODOX`) that prefixes every label, plus mind-reading meta-commentary. Useful to study, dangerous to mimic by default.

## Candidates

### 001 Reimu / 霊夢/霊夢 — STRONG RECOMMENDATION ✓

**Pros:**

- The bugfix log explicitly used this as ground truth in 9 different cases. The Lyrica session author noted: *"for any standard daily/event/COM body, mirror the patterns in `001 Reimu [霊夢]/霊夢/M_KOJO_K1_*.ERB`"*.
- Uses simplified-Chinese flag forms throughout (`约会中`, `历史`).
- Has every standard category file. Covers EVENT_K_1 with all 5 ARG sub-phases.
- Empty selector — labels are just `@M_KOJO_*_K1_*`, no infix to confuse readers.
- Modern: includes the cell-guard pattern, MARKCNG guard, BEFORETRAIN hook.
- Reasonable size (need to confirm — likely ~1.5-2MB total).
- The protagonist of the franchise. The most-tested kojo in the corpus.

**Cons:**

- Reimu has heavy R18 content in her sex/sexual-harassment files (she's a lover-tier romanceable character). For a *reference* shipped in a skill, we should sample selectively (events, daily, encounter, INFO) and stub the explicit categories.

**Practical action**: copy the non-explicit category files in full (`イベント.ERB`, `日常系コマンド.ERB`, `カウンター.ERB`, `弾幕勝負.ERB`, `刻印取得.ERB`, `依頼.ERB`, `日記.ERB`, `育児イベント.ERB`, `INFO.ERB`, `関数ライブラリ.ERB` if present). For explicit categories (`性交系 / セクハラ / 愛撫系 / 加虐系 / 道具系 / 派生 / 絶頂 / 奉仕系 / ハードな`), copy a 50-line excerpt showing the *structural* skeleton (label naming, cascade shape, RETURN pattern) with all dialogue prose redacted to `;<line redacted>` placeholders. The point is to teach the LLM the structure, not give it explicit content to mimic.

### 030 Eiki / 映姫/映姫様 — STRONG SECONDARY ✓

**Pros:**

- Eiki is the **canonical helper-library source**. Most other authors' `関数ライブラリ.ERB` files have explicit "拝借自映姫様口上" comments. Shipping Eiki's `Lib/` (or its embedded equivalent) gives downstream LLMs the canonical pattern.
- Has the `カスタム.ERB` "new kojo API" file (custom buttons, custom commands). Reimu doesn't.
- Has `EVENT_K30_GRAVITY` written canonically (silent, sets `TCVAR:N:引力点`) — exactly what the bugfix log called out.
- Uses simplified-Chinese where appropriate.

**Cons:**

- Eiki is "extreme tier" — 17+ files including `M_KOJO_K30_カスタム.ERB`, dedicated `関数・お説教ライブラリ.ERB`, `おまけ/`, `追加ファイル/`. Total ~2.4MB. More than a beginner-friendly reference.
- A persona that's heavily overlap with new-kojo-API features the user may not need.

**Practical action**: ship a smaller subset — the `カスタム.ERB` file in particular — as a *secondary* reference for advanced features.

### 006 Luna / ルナチャイルド — SIMPLE BUT PERSONA-GATED

**Pros:**

- Smallest "complete" kojo (~525 KB across 12 files). Easy to fit in context.
- Already studied for [`meta/notes_phase1_per_char/006_Luna.md`](./notes_phase1_per_char/006_Luna.md). Well-documented.
- Has every standard category (no INFO; no カスタム).

**Cons:**

- Wraps every body in a player-must-be-児童 gate. Distracting for a generic reference.
- Persona-specific lines may not generalize.

**Practical action**: skip as primary; cite in `meta/` notes only.

### 139 Tsukasa / 典 — DON'T USE

Same author as Hatate (すし). Beautifully written but very large (~1.5MB total) and uses author-private patterns (`_C_NAME` with default args, wetness state machine, animal-form references) that are character-specific, not general.

### 049 Satori / さとり — DON'T USE AS PRIMARY

Excellent for showing kojo-selector mechanics (`RESULTS = "_ORTHODOX"`) and meta-content reactions. **But:** every label is prefixed with `_ORTHODOX_` which an LLM reading "the canonical example" might mistakenly think is the standard naming. Better to teach selectors as a §2.8 concept first; keep selector-using kojo out of the reference.

### 042 Hatate / はたて — DON'T USE AS PRIMARY

Most-thorough kojo in the corpus (~3.7MB) with `Lib/` subdirectory, function library, character-private DIM header (`K42C_*`), full new-API support. Too much. Cite in `meta/` notes; don't ship.

## Recommendation summary

**Primary reference: 001 Reimu / 霊夢/霊夢/**, with redaction of explicit prose in the sex-category files (keep structure, remove dialogue).

**Secondary reference (advanced features only)**: small excerpts from 030 Eiki / 映姫/映姫様/:
- `M_KOJO_K30_カスタム.ERB` — for the new "custom kojo API"
- `Lib/M_KOJO_K30_関数・お説教ライブラリ.ERB` — for the canonical function-library pattern
- `EVENT_K30_GRAVITY` body excerpt (~30 lines) — for the silent NPC-AI attractor pattern

**Where to put them**: `eratw-skill/reference-kojo/reimu/M_KOJO_K1_*.ERB` for Reimu, `eratw-skill/reference-kojo/eiki-snippets/<file>.ERB` for the Eiki excerpts. Add a `eratw-skill/reference-kojo/README.md` explaining what each file demonstrates.

**Anticipated size**: ~1-1.5MB total once explicit prose is redacted from Reimu's sex-category files. That fits comfortably within the skill.

## Next steps when we act on this

1. Copy `ERB/口上・メッセージ関連/個人口上/001 Reimu [霊夢]/霊夢/` → `eratw-skill/reference-kojo/reimu/`.
2. For each explicit-category file (`性交系コマンド.ERB`, `セクハラコマンド.ERB`, `愛撫系コマンド.ERB`, `加虐系コマンド.ERB`, `道具系コマンド.ERB`, `奉仕系コマンド.ERB`, `絶頂.ERB`, `ハードな*.ERB`), redact prose lines: keep all `@LABEL` definitions, all control flow (`IF/SELECTCASE/RAND/RETURN/etc.`), all `LOCAL = 0/1` gating, all `CALL`s, all `SOURCE:` updates; replace `PRINTFORML 「<dialogue>」` and `PRINTFORMW <narration>` content with `;<redacted>` placeholders.
3. Copy `M_KOJO_K30_カスタム.ERB`, `M_KOJO_K30_関数・お説教ライブラリ.ERB`, and the GRAVITY label body from 030 Eiki → `eratw-skill/reference-kojo/eiki-snippets/`.
4. Update `eratw-skill/SKILL.md` §0.4 to mention `reference-kojo/` as a discovery target.
5. Add explicit "go grep this" pointers in §6 (standard body shape) and §1 (pitfalls #4-7) — *"see `reference-kojo/reimu/M_KOJO_K1_イベント.ERB` lines NNN-MMM for the canonical EVENT_K_1 body with cell-guard and ARG cascade."*
