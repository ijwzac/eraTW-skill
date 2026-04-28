# meta/ — session-internal artifacts

Material that fed into building the skill but is **not** part of the skill itself. Most of these are research notes, audit logs, and earlier consolidation passes. **The skill's helper LLM should not read these** — they will only confuse it. The right entry-point for an LLM is `../eratw-skill/SKILL.md`.

## Contents

| File | What it is |
|---|---|
| [`post_test_bugfixes_lyrica.md`](./post_test_bugfixes_lyrica.md) | The single most-important artifact in this dir. A real-world test report from another Claude Code session that used an early version of the guide to scaffold a Lyrica (K20) kojo. Logs every bug found at runtime, root cause, and "guide gap" (what the guide should have said but didn't). The current SKILL.md and references/ are largely shaped by this feedback. **Read this if you're iterating on the skill itself.** |
| [`notes_phase1_overview.md`](./notes_phase1_overview.md) | Initial scan of the eraTW codebase — top-level layout of CSV/, ERB/, dat/, plus dispatcher mechanics in `KOJO_MESSAGE.ERB`. |
| [`notes_phase1_per_char/`](./notes_phase1_per_char/) | Line-by-line notes from reading four reference characters' kojo: 006 Luna (simplest), 042 Hatate (rich, by author すし), 049 Satori (kojo-selector + meta-content reactions), 139 Tsukasa (clothing-wetness + nicknames + author すし again). |
| [`subagent_findings.md`](./subagent_findings.md) | Audit report from sub-agents that scanned ~149 character variant directories looking for structural patterns the four samples missed. Surfaces the MESSAGECHECK family, EXTRASOURCE, the new "custom" kojo API, RELATION namespace, B2/F orgasm tiers, SPECIALDAY/BEFORETRAIN/RUN_INTO/SF_CONTRACT labels, and ~30 more idioms. |
| [`standalone_note_v1.md`](./standalone_note_v1.md) | First synthesis pass after reading the four reference characters. Structured as a learning reference for sub-agents. |
| [`standalone_note_v2.md`](./standalone_note_v2.md) | Second synthesis pass after the sub-agent audit. Adds the MESSAGECHECK family, EXTRASOURCE, the new kojo API, B2/F tiers, and updates the tier-classification of all 153 characters. v2 is the more complete reference of the two. |

## Why this dir exists

A skill (per Anthropic's [Agent Skills](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview) standard) should ship with **only the artifacts a helper LLM needs to do the user's job**. Research process, internal memos, abandoned drafts, and bug-fix logs make a skill harder to navigate and add token cost without value.

These files are kept in the repo because they document *how* the skill was built — useful for future iteration, replication of the methodology against a new game, or auditing the skill's claims. They are deliberately segregated from `eratw-skill/` so a downstream tool that copies the skill into `~/.claude/skills/` won't accidentally pick them up.
