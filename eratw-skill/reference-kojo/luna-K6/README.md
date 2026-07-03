# luna-K6 — 露娜切露德 (Luna Child), a modern worked example

A **fresh, from-scratch kojo for Luna Child (K6)**, authored with this skill and used as the live testbed for the autotest pipeline (`../../references/11-autotest-pipeline.md`).

Unlike `reimu/` (an older monolithic filled example) this one is written to current conventions:

- **Full modern multi-file split** — one file per category (`イベント`, `日常系コマンド`, `派生コマンド`, `カウンター`, `弾幕勝負`, `刻印取得`, `日記`, `セクハラコマンド`, `性交系コマンド`, `加虐系コマンド`, `絶頂`, `関数ライブラリ`, `of_new_kojo_api`).
- **Chinese prose + Chinese `;` comments**, engine identifiers left in Japanese.
- **Canon persona**: timid #1-coward / argumentative moonlight fairy, night-owl (「因夜失眠」), sound-erasing (响指消音), trips constantly, covets coffee; frequent Sunny (K5) / Star (K7) trio flavor.
- All the SKILL §1 pitfalls handled deliberately: same-cell guard on `EVENT_1/2/3`, silent `GRAVITY`, `#DIM`/`#DIMS` on `GIFT`/`DIARY_TEXT`/`RUN_INTO`, command IDs verified against `Train.csv`, UTF-8 BOM.

## Content register

Daily / social / event dialogue is richly filled (SFW-forward). Adult-category commands (`性交系`, `加虐系`, `絶頂`, `353`) are **structural stubs** (`LOCAL = 0`) for the author to fill.

## Autotest tags

Testable dialogue regions carry a one-line status tag:

```
;@AT <status> <TID>       e.g.  ;@AT 待自动测试 K6_300_恋人
```

- `<status>` ∈ `待自动测试 · 待手动测试 · 测试通过 · 测试失败`
- `<TID>` is a stable join key so a script can map test output back to the source region and rewrite the flag.

## Status

**WIP.** Content is complete and passes the §2 static verification. Still in progress: finishing the tagging pass across all files, the autotest harness (`M_KOJO_K6_AUTOTEST.ERB`, guarded by `TCVAR:6:399`), and the end-to-end pipeline run. See `../../../HANDOFF.md`.

> These `.ERB` files are a **copy** of the working kojo under the game tree
> (`ERB/…/006 Luna [ルナ]/露娜切露德_重制/`). The game install is the source of truth;
> this copy is here as a skill reference.
