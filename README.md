# eraTW Kojo (口上) Writing Guide

A reference for writing per-character dialogue/behavior scripts ("口上") for **eraTW** (era The World) — a [Touhou Project](https://en.touhouwiki.net/) text-RPG built on the [Emuera](https://gitlab.com/eraDB/Emuera) era-script engine.

## What's in this repo

- **[`eraTW_kojo_writing_guide.md`](./eraTW_kojo_writing_guide.md)** — the main deliverable. A self-contained reference designed to be loaded into another LLM's context, so that LLM can help a human user write or modify a character's kojo. Covers dispatch contract, label catalog, DSL primer, state-bus, file taxonomy, workflow recipes, and a full character ID ⇆ name appendix.
- **[`post_test_bugfixes_lyrica.md`](./post_test_bugfixes_lyrica.md)** — a real-world test report. After the guide was used to scaffold a Lyrica (K20) kojo, every bug found at runtime was logged here with root cause and a "guide gap" — what the guide *should* have said but didn't. This is the most valuable feedback artifact in the repo and drives ongoing improvements.
- **`standalone_note_v1.md`, `standalone_note_v2.md`** — earlier consolidation passes that fed into the final guide. v2 is the more complete one.
- **`notes_phase1_overview.md`** — initial scan of the eraTW codebase (CSV/ERB/dat layout, dispatcher mechanics).
- **`notes_phase1_per_char/`** — line-by-line notes from reading four reference characters' kojo: 006 Luna (simplest), 042 Hatate (rich), 049 Satori (meta-content), 139 Tsukasa (clothing/wetness state).
- **`subagent_findings.md`** — survey of ~149 character variant directories, looking for structural patterns the four samples missed.

## How to use the guide

The guide is intended for an LLM (Claude, GPT, Gemini, …) that is helping a non-technical user modify their game files. Drop it into the assistant's context (or convert to a [Claude Skill](https://docs.claude.com/en/agents-and-tools/agent-skills/overview)) and ask the assistant something like *"我想给 049 古明地觉 写一段下雪天的会话"*.

## Status

WIP. The guide produces correct first-pass output for *most* sections, but `post_test_bugfixes_lyrica.md` documents many concrete failure modes still being addressed. See that file for the current list of known guide gaps.

## License

Documentation only; no code from the eraTW game itself is included. The game's own license and license-template files travel with each character's kojo directory under `ERB/口上・メッセージ関連/個人口上/`.
