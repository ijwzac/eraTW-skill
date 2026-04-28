# eraTW-skill

A [Claude Skill](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview) for helping users write or modify per-character dialogue/behavior scripts ("口上"/kojo) for **eraTW** — a [Touhou Project](https://en.touhouwiki.net/) text-RPG built on the [Emuera](https://gitlab.com/eraDB/Emuera) era-script engine.

## Repo layout

```
eraTW-skill/
├── eratw-skill/              ← the skill itself; copy this dir into ~/.claude/skills/
│   ├── SKILL.md              ← entry point with YAML frontmatter
│   └── references/           ← lazy-loaded supplementary docs + canonical CSVs
│       ├── 01-engine-label-catalog.md
│       ├── 02-state-bus-namespaces.md
│       ├── 03-engine-helpers.md
│       ├── 04-dsl-full.md
│       ├── 05-event-arg-subphases.md
│       ├── 06-workflow-recipes.md
│       ├── 07-other-topics.md
│       ├── 08-character-id-table.md
│       ├── 09-persona-tips.md
│       ├── 10-encoding-and-tools.md
│       └── data/               ← canonical CSVs from a working eraTW install
│           ├── README.md
│           ├── Train.csv, CFLAG.csv, TFLAG.csv, …
│           └── Chara/Chara<N> *.csv (~150 files)
└── meta/                      ← session-internal artifacts (NOT for skill users)
    ├── post_test_bugfixes_lyrica.md
    ├── notes_phase1_*.md
    ├── standalone_note_v[12].md
    └── subagent_findings.md
```

## How to use the skill

### Claude Code

Copy `eratw-skill/` (the inner directory, not the repo root) into `~/.claude/skills/`. Or symlink it. Or use a [plugin](https://docs.claude.com/en/agents-and-tools/agent-skills/distribute-skills) wrapper.

```bash
# Linux/macOS
cp -r eratw-skill ~/.claude/skills/

# Windows (PowerShell)
Copy-Item -Recurse eratw-skill $env:USERPROFILE\.claude\skills\
```

Once installed, mention kojo / eraTW / a Touhou character / a `K<N>` label in any Claude Code session and the skill auto-activates. Claude reads SKILL.md and lazy-loads `references/*.md` and `references/data/*.csv` only as needed.

### Generic chatbot (no file system, e.g. claude.ai web, ChatGPT, Gemini)

Paste `eratw-skill/SKILL.md` into the chat as a system or context message. When the assistant needs more depth, it will name the specific reference file you should upload (e.g. *"Please upload `references/data/Train.csv`"*). Upload it; continue.

The SKILL.md has a built-in mode-detection section (§0.4) that handles this gracefully.

## Status

WIP. Driven by real-world test feedback. The current version reflects bugs found while scaffolding a Lyrica (K20) kojo, logged in [`meta/post_test_bugfixes_lyrica.md`](./meta/post_test_bugfixes_lyrica.md).

Known limitations:

- The CSV data in `references/data/` comes from one specific fork. Other forks may differ.
- The skill currently assumes a Chinese-speaking user; non-Chinese users would need to rewrite §0.3 of SKILL.md.
- A canonical reference kojo (likely Reimu K1) is **not yet copied into the skill**. Future iteration: include `eratw-skill/reference-kojo/` with annotated excerpts from a complete working kojo, since the bugfix log shows an LLM scaffolding from scratch needs a worked example to mimic.

## License

Documentation only; no game code from eraTW itself is bundled. The game's own license travels with each character's kojo directory under `ERB/口上・メッセージ関連/個人口上/` in the actual game install.
