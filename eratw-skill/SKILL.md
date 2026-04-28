---
name: eratw-skill
description: Help users write or modify per-character dialogue/behavior scripts ("口上"/kojo) for eraTW (Touhou) — a text-RPG built on the Emuera era-script engine. Use when the user mentions kojo/口上, eraTW/eratw/etw, Touhou era game, character ID like K1 K42 K49 K139, label patterns like @M_KOJO_*, paths under 個人口上/, command IDs like 300=会話 311=擁抱, or asks to write/edit dialogue for a Touhou character (灵梦, 古明地觉, 姬海棠极, 露娜, 早苗, etc.).
---

# eraTW Kojo (口上) Writing Skill

A skill for helping a user write or modify per-character dialogue scripts for **eraTW**, a text-RPG built on the Emuera era-script engine featuring ~150 Touhou Project characters. A "kojo" (口上) is the per-character dialogue + behavior script — one or more `.ERB` files the engine dispatches into when something happens with that character.

**Read sections 0 through 11 inline.** Sections marked with `→ references/<file>.md` link to optional appendix material that gets loaded on demand when needed.

---

## 0. Read this first — Role, mode, output language, and where to find more material

### 0.1 Your role

The user writes the *story and rough event descriptions* in plain language. **Your job is to translate that into the concrete labels, control flow, and file taxonomy the engine expects.** You handle structure. The user handles content.

### 0.2 Adult content disclaimer

This game *does* contain adult content as a feature, including categories like "sexual harassment commands" and "sex commands." **You are not generating that content.** Your job is structure. If a user asks you to generate explicit prose, redirect: "I'll write the structural skeleton with placeholders; you fill in the lines." For non-adult parts (most daily commands, events, info-screen, diary, child-rearing, danmaku, conversation, etc.), generating actual prose is fine — that's the "galgame writing" the user is doing.

### 0.3 Language of the user, language of the output

**The user is Chinese.** They will phrase requests in Chinese (sometimes mixed with Japanese game-jargon: `恋慕`, `親密`, `推倒`, `约会`, etc.). **Reply to the user in Chinese.**

**The dialogue prose you generate inside kojo files must be in Chinese** (this is what the player sees). Existing kojo are largely Chinese-translated, so new content matches. Exceptions where mixed-language is natural:

- **Engine identifiers stay as the original** — labels (`@M_KOJO_*`), keywords (`IF/RETURN`), CFLAG/TFLAG slot names (`CFLAG:N:時間停止口上有`, `TALENT:恋慕`). **Never translate these** — the engine uses them as keys.
- Onomatopoeia, exclamations, "♥", and Japanese particle-style sighs (`はぁ`, `んっ`) commonly stay as-is for stylistic flavor.
- Quotations from canonical Touhou source may stay Japanese when the user wants the canon line.

**`;`-prefixed comments inside `.ERB` kojo files must also be Chinese — even though many existing kojo use Japanese for their comments.** This includes:

- Section banner descriptions (e.g. `;==================================================` / `;310, 摸屁股` rather than `;310,お尻を触る`).
- The doc-banner state contract above each command body (`;TFLAG:193 (1=不快 2/3=害羞 4=任由摆布)` rather than `;TFLAG:193(1=不快 2&&3=恥ずかしがる 4=されるがまま)`).
- The "記入チェック" filled-in marker comment — write as `;填写检查 (=0 不显示, =1 显示)` rather than the Japanese form.
- Inline explanations and TODOs.

The slot/talent names *embedded inside* the comment (`TALENT:膽怯`, `CFLAG:诶嘿嘿`, etc.) stay as-is — those are identifiers, not prose. Only the explanatory text around them switches to Chinese.

Author-external memo files (`readme.txt`, `フラグ管理メモ.txt`, `衣装メモ.txt` in the kojo dir) follow user preference — they're not loaded by the engine and are for the user's own bookkeeping.

**Summary**: structural identifiers stay Japanese (engine-required); player-visible prose AND in-file `;` comments are Chinese; only external memos follow user preference.

### 0.4 Mode detection — Claude Code vs chatbot

This skill ships with a `references/` directory of supplementary docs (full label catalog, state-bus, engine helpers, etc.) and `references/data/` containing the game's CSV files (canonical slot names, command IDs, character data).

**Detect your mode:**

- **Claude Code mode** (or any environment with file-system access): you can `Read` / `Glob` / `Grep` files under `references/`. Treat them as lazy-loaded — only fetch when the question requires that depth.
- **Chatbot mode** (the user pasted SKILL.md into a chat with no file access): you cannot read `references/`. When you encounter a question that needs ground-truth lookup (slot names, command IDs, character names, etc.), ask the user to upload the specific file by name.

**Quick decision flow when you need lookup data:**

| Need | File to read or request |
|------|-------------------------|
| Command ID → name (e.g. "what's command 311?") | `references/data/Train.csv` |
| Verify a CFLAG slot name | `references/data/CFLAG.csv` |
| Verify a TFLAG slot name | `references/data/TFLAG.csv` |
| Verify a TCVAR slot name | `references/data/TCVAR.csv` |
| Verify a TALENT slot name | `references/data/Talent.csv` |
| Verify an ABL slot name | `references/data/Abl.csv` |
| Verify a BASE slot (no `疲労`!) | `references/data/Base.csv` |
| Item IDs (alcohol, food, gifts) | `references/data/Item.csv` |
| Whether `[[X]]` resolves at parse time | `references/data/Str.csv` |
| Per-character data (`名前`, `呼び名`) | `references/data/Chara/Chara<N> <name>.csv` |
| Full engine-callable label catalog (every shape) | `references/01-engine-label-catalog.md` |
| State-bus full namespace tables | `references/02-state-bus-namespaces.md` |
| Engine helper functions | `references/03-engine-helpers.md` |
| DSL primer (full Emuera-script reference) | `references/04-dsl-full.md` |
| EVENT_K_X subphase ARG semantics (mandatory before EVENT bodies) | `references/05-event-arg-subphases.md` |
| Worked recipes (new-from-scratch, scripted-event, modify-existing) | `references/06-workflow-recipes.md` |
| Game-modification beyond kojo (CSV layer, weather plugin, COMF) | `references/07-other-topics.md` |
| Character ID ⇆ name table (Romaji/Japanese/Chinese) | `references/08-character-id-table.md` |
| Persona-translation tips | `references/09-persona-tips.md` |
| File encoding (UTF-8 BOM, CRLF, BOM-prepend recipe) | `references/10-encoding-and-tools.md` |

**For chatbot mode**, when you need any of the above, tell the user verbatim: *"Please upload `references/<filename>` from the eraTW-skill repository, or paste its contents."* Always name the **specific file** — don't say "upload the data" generically.

### 0.5 If a user uploads existing kojo files

The user may share their current kojo or other characters' kojo for reference. **Read for structure, not content.** Bodies that contain explicit prose: skim only enough to see surrounding control flow and file role. Quote at most 1-2 lines of dialogue when essential.

---

## 1. Most-common first-pass mistakes — read every time

These are the bugs we see in nearly every first-pass kojo generation. Hold them in your head while writing. Each one is detailed in the relevant section/reference below.

1. **`@FOO(ARG, TYPE = 0)` will not compile.** Emuera only accepts positional `ARG / ARG:N / ARGS / ARGS:N` parameter names. Custom names like `TYPE`, `相手残機`, `OPTION` raise a Lv2 warning and the variable becomes unreadable inside the body. Use `@FOO(ARG, ARG:1 = 0)` and (optionally) `TYPE = ARG:1` as an alias on the first line of the body. → §7 / `references/04-dsl-full.md`
2. **`[[X]]` silently compiles to `0` when X is not in `Str.csv`.** Most character names — `[[アリス]]`, `[[ルナサ]]`, `[[メルラン]]`, `[[幽々子]]`, `[[ライコ]]`, etc. — are NOT in `Str.csv`, so `CASE [[ルナサ]]` becomes `CASE 0` and matches ARG=0 by accident. **Default to numeric IDs with comments**: `CASE 22  ;ルナサ`. Reserve `[[X]]` for names you've grep-confirmed in `Str.csv`.
3. **`MASTER`, `TARGET`, `PLAYER`, `ASSI` are bare identifiers, not `[[MASTER]]`.** Writing `[[MASTER]]` produces a warning.
4. **`@M_KOJO_EVENT_K{id}_1(ARG, ARG:1)` fires once PER CELL TRANSITION** the character makes anywhere on MASTER's current world map, not "once when entering MASTER's room." A char walking bedroom→corridor→dining will print 3 dialogue lines while MASTER is still asleep. **Mandatory first guard:** `SIF CFLAG:{id}:現在位置 != CFLAG:MASTER:現在位置 / RETURN 0`. Then branch on ARG sub-phase (1=MASTER walks in, 2=char walks in, 3-5=bath sub-phases). Same applies to `_2` (morning) and `_3` (sleep). → `references/05-event-arg-subphases.md`
5. **`@M_KOJO_EVENT_K{id}_GRAVITY` is a SILENT NPC-AI movement attractor**, not a "gravity event." It fires every NPC-movement-decision tick (many per turn). Body must set `TCVAR:{id}:引力点 = <location-code>` and **must not call any `PRINT*`**. → `references/01-engine-label-catalog.md`
6. **`@M_KOJO_MESSAGE_COM_K{id}_00` fires on EVERY undefined cmd**, not "rarely." Default to `LOCAL = 0 / RETURN 0` (silent) unless you specifically want one identical line on every undefined cmd.
7. **`@M_KOJO_MESSAGE_MARKCNG_K{id}` fires after every action that *could* affect a mark**, not only on transitions. Body must guard `SIF !TFLAG:21 && !TFLAG:22 && !TFLAG:23 && !TFLAG:24 && !TFLAG:時姦刻印取得 / RETURN 0` before printing.
8. **`CFLAG:N:约会中` is a MAIN_MAP code, not a boolean.** After any first date, the slot is permanently non-zero. `IF CFLAG:N:约会中` is always-true thereafter. Canonical predicate for "currently dating with this character": `CHK_DATENOW(CFLAG:MASTER:约会中) && FLAG:约会的对象 == TARGET`.
9. **Slot names must match the actual CSV byte-for-byte.** This fork uses simplified-Chinese in many CFLAG names (`约会中`, `历史` etc.) — Japanese-kanji forms like `約会中` *do not resolve*. Some slot names that "look canonical" don't exist in this fork's CSVs (e.g. `BASE:N:疲労` doesn't exist; use `BASE:N:気力 < MAXBASE/2` for "tired". `TFLAG:逢瀬時間` doesn't exist; track with a private CFLAG instead).
10. **Files must be UTF-8 with BOM**, ideally CRLF. Without BOM, Chinese characters in some string contexts silently break. Write tools default to LF/no-BOM; prepend BOM after every write/edit. → `references/10-encoding-and-tools.md`
11. **Display name in `CSV/Chara/Chara<N> *.csv` must match what your kojo prose calls the character.** The engine prints `%CALLNAME:N%` from CSV — if your prose calls her "莉莉卡" but the CSV says "莉莉喀", the player sees both inconsistently. Check `名前` and `呼び名` rows before authoring; edit CSV if you want a different display name.
12. **An early-return `IF` branch suppresses everything below it.** Bodies that gate broad conditions (room class, weather, time-of-day) at the top of a cascade will block all the rich relationship content for most of the game. RAND-gate broad conditions, or move them inside relationship branches as flavor sub-conditions, instead of as early-return blockers.

---

## 2. Verification pass — run before declaring done

After scaffolding a new kojo, before handing back to the user, verify:

```bash
# Adjust paths to match the user's install
DIR="<kojo variant dir, e.g. ERB/口上・メッセージ関連/個人口上/100 Rei'sen [レイセン]/myvar>"
CSVDIR="<game root>/CSV"

cd "$DIR"

echo "=== [[ ]] symbols not in Str.csv (will silently become 0) ==="
grep -hoE "\[\[[^]]+\]\]" *.ERB | sort -u | while read s; do
    name="${s:2:-2}"
    grep -qE ",${name}\b" "$CSVDIR/Str.csv" || echo "MISSING: $s"
done

echo "=== Custom-named function parameters (must be ARG/ARG:N/ARGS/ARGS:N only) ==="
grep -nE "^@.*\([A-Za-z_][A-Za-z0-9_]*\s*=" *.ERB | \
    grep -vE "ARG(:[0-9]+)?\s*=" | grep -vE "ARGS(:[0-9]+)?\s*="

echo "=== Unverified CFLAG/TFLAG/TCVAR slot names (must exist in CSV) ==="
grep -hoE "(CFLAG|TFLAG|TCVAR):([A-Z]+:)?[^a-z0-9 :,()<>=&|!*+\r\n_-]+\b" *.ERB | \
    sed -E 's/^(CFLAG|TFLAG|TCVAR):([A-Z]+:)?//' | sort -u | while read slot; do
    grep -qF ",${slot}" "$CSVDIR"/{CFLAG,TFLAG,TCVAR}.csv || echo "MISSING: $slot"
done

echo "=== Files missing UTF-8 BOM ==="
for f in *.ERB; do
    head -c 3 "$f" | xxd -p | grep -q "efbbbf" || echo "$f"
done

echo "=== EVENT_K_X bodies missing the same-cell guard ==="
grep -l "@M_KOJO_EVENT_K[0-9]\+_[123](" *.ERB | while read f; do
    grep -qE "現在位置.*!=.*MASTER:現在位置" "$f" || echo "$f: missing 現在位置 != MASTER:現在位置 guard"
done
```

If any check fails, fix and re-run. **Re-run after every Edit pass** because tools sometimes strip BOM on rewrite.

---

## 3. Debugging with the user

The verification pass (§2) catches static issues. But many bugs only show at runtime — a line that prints too many times, a predicate that doesn't fire, a CFLAG slot that's silently the wrong type. This section is the **iteration loop** you run *with the user* whenever something doesn't behave right after a kojo edit.

### 3.1 How to get the game's log out

The game has two relevant menu actions under **「文件」** (File menu):

- **「保存日志」** — saves the current session log to a file in the game directory.
- **「将日志复制到剪切板」** — copies the session log to clipboard, ready for the user to paste into chat.

**The user pastes the relevant log section into the conversation; you read it.** Don't ask the user to summarize — let them paste raw. Logs are small and structured.

In addition, the game writes `emuera.log` (live, appended) and `<YYYYMMDD-HHMMSS>.log` (per-session) files in the game root directory. The user can also share those.

### 3.2 Compilation errors — must be fixed before anything else plays

Compilation errors prevent the game from loading. They appear at game launch.

**A healthy launch shows roughly four lines:**

```
如果出現了錯誤、請根據目錄下的報錯指導文件進行報錯
1702 files were found in the lazy loading table
Loading complete. Took 2.19 seconds.
Press Enter or click to proceed.
```

**Any `警告Lv2:` lines between the second and third are compilation errors.** Example:

```
如果出現了錯誤、請根據目錄下的報錯指導文件進行報錯
1702 files were found in the lazy loading table
警告Lv2:口上・メッセージ関連\個人口上\020 Lyrica [リリカ]\リリカ\M_KOJO_K20_日記.ERB:第40行:函数"@DIARY_TEXT_K20"的参数错误:变量"PAGENUM"未在此函数中定义
@DIARY_TEXT_K20, PAGENUM, MODE, PAGECOUNT
警告Lv2:口上・メッセージ関連\個人口上\020 Lyrica [リリカ]\リリカ\M_KOJO_K20_日記.ERB:第41行:变量"PAGENUM"未在此函数中定义
SELECTCASE PAGENUM
Loading complete. Took 2.19 seconds.
Press Enter or click to proceed.
```

Each `警告Lv2:` line tells you:
- **File path** (relative to game root, e.g. `口上・メッセージ関連\個人口上\020 Lyrica [リリカ]\リリカ\M_KOJO_K20_日記.ERB`).
- **Line number** (e.g. `第40行` = line 40).
- **Function name affected** (e.g. `@DIARY_TEXT_K20`).
- **The actual cause** (e.g. `参数错误:变量"PAGENUM"未在此函数中定义` — "param error: variable PAGENUM not defined in this function" — see pitfall #1: custom param names don't work; use `ARG/ARG:1/ARGS/ARGS:1`).

**Workflow when the user pastes a compile error:**

1. Tell the user: **«请把游戏启动时出现的所有 `警告Lv2:` 行都贴给我。** A healthy launch only shows the first 2 and last 2 lines you saw — anything between is an error that needs fixing.»
2. Map each warning to a §1 pitfall (most warnings match one of the 12 listed there) or to the §2 verification-pass checks.
3. Patch the file. Show a diff.
4. **Confirm with the user**: «请重新启动游戏，看看 `警告Lv2:` 行有没有消失。» Repeat until clean.

**Don't move on to runtime testing until startup is clean.** A game with compile errors at launch may *appear* to run but the affected labels will be silently broken.

### 3.3 Runtime issues — proactive debug-print workflow

After every non-trivial kojo edit, **proactively ask the user**:

> «改完了。请在游戏里测试一下：[列出受影响的 cmd / 事件 / 触发条件]。如果有任何不对的地方（例如台词重复、不该触发的时候触发、对话乱序等），请告诉我并贴出 `「文件」→「将日志复制到剪切板」` 的内容。»

If the user reports an issue:

1. **Identify which body label fired** (or should have fired but didn't). Read the user's description; map it to a label.
2. **Add temporary debug-prints** to that body capturing the relevant state (recipe in §3.4 below).
3. **Hand back to the user**: «我加了一些临时的诊断打印。请重新触发刚才的操作 (e.g. 走进莉莉卡的房间)，然后用 `「文件」→「将日志复制到剪切板」` 把日志贴给我。»
4. **Diagnose from the captured state**. Common patterns:
   - A predicate evaluated wrong because a CFLAG was non-boolean (see pitfall #8 — `约会中` is a map-id).
   - A label fired more times than expected (see pitfall #4 — `EVENT_K_1` fires per cell transition).
   - A slot was zero because `[[X]]` failed to resolve (see pitfall #2).
   - A function param was unreadable inside the body (see pitfall #1).
5. **Patch and remove the debug-prints** in the same edit. Tell the user: «已修复。**注意我把诊断打印行删掉了**，这样以后正式玩的时候不会有 `[DBG]` 噪音。»

### 3.4 The debug-print recipe

To inspect state at any point in a body, add lines like:

```erb
;[DBG] — TEMPORARY; remove before declaring done
PRINTFORML [DBG] DAY={DAY:0} MAIN_MAP={MAIN_MAP} TIME:5={TIME:5} TIME:2={TIME:2}
PRINTFORML [DBG] ARG={ARG} ARG:1={ARG:1} SELECTCOM={SELECTCOM} TFLAG:50={TFLAG:50}
PRINTFORML [DBG] CFLAG:20:現在位置={CFLAG:20:現在位置} CFLAG:MASTER:現在位置={CFLAG:MASTER:現在位置}
PRINTFORML [DBG] CFLAG:20:约会中={CFLAG:20:约会中} FLAG:约会的对象={FLAG:约会的对象}
PRINTFORML [DBG] TALENT:恋慕={TALENT:恋慕} TALENT:恋人={TALENT:恋人} ABL:20:親密={ABL:20:親密}
```

Notes on the syntax:

- **`{<expr>}` inside any `PRINTFORM*` command** evaluates and substitutes the expression's value at print time. Numbers print as digits; strings print as text.
- **`PRINT VARDUMP(<arr>)`** dumps an entire array's contents.
- **Always prefix with `[DBG]`** so the user can spot your debug lines amid normal narration. Searching for `[DBG]` in the pasted log gets just the diagnostic output.
- **For predicates that branch silently** (return without printing), put a debug-print *inside each branch* with a unique tag so the log reveals which path was taken:
  ```erb
  IF CHK_DATENOW(CFLAG:MASTER:约会中) && FLAG:约会的对象 == TARGET
      PRINTFORML [DBG-A] dating-with-this-char branch taken
      ...
  ELSEIF TALENT:恋人
      PRINTFORML [DBG-B] lover branch taken
      ...
  ELSE
      PRINTFORML [DBG-C] fall-through branch taken
      ...
  ENDIF
  ```
- **Remove ALL debug lines** before declaring the kojo done. Grep for `[DBG]` in the file and delete each. The verification pass in §2 should catch any leftover.

### 3.5 What the user's bug-report message looks like

You should expect (and gently shape) the user to say something like:

> «我刚刚走进莉莉卡的房间，但她的台词出现了 3 次。日志如下: [paste]»

Or after a compile error:

> «游戏启动时报错: [paste 警告Lv2: block]»

Reply quickly with:

1. **Quote the relevant log line(s) back** so the user knows you read it.
2. **State the cause in one sentence** ("这是 §1 pitfall #4 — `EVENT_K_1` 每次角色走进新格子都会触发，body 缺少同格守卫。").
3. **Show the fix as a diff.**
4. **Tell the user the next step**: «请重新启动游戏看看是否还有报错。» / «请再触发一次该动作并粘贴新的日志。»

Iteration cycles tend to be 30-60 seconds each (game restart + repro + paste). Stay terse — don't over-explain.

---

## 4. The big picture — what's where

```
eraTW/
├── ERB/                                  ; ALL game logic (Emuera scripts)
│   ├── 口上・メッセージ関連/
│   │   ├── KOJO_MESSAGE.ERB              ; the dispatcher (engine — never modify)
│   │   ├── COMMON_KOJO.ERB               ; library helpers
│   │   ├── EVENT_MESSAGE*.ERB            ; engine default narration
│   │   └── 個人口上/                      ; YOUR DOMAIN: per-character kojo
│   │       ├── 001 Reimu [霊夢]/
│   │       │   └── <variant>/
│   │       │       ├── M_KOJO_K1_イベント.ERB
│   │       │       ├── M_KOJO_K1_日常系コマンド.ERB
│   │       │       └── … ~10-25 files
│   │       ├── 002 Ruukoto [る～こと]/
│   │       └── … 153 character dirs
│   ├── COMMON.ERB, BATTLE.ERB            ; engine code
│   ├── 天候*.ERB                          ; weather subsystem (a "system plugin" example)
│   ├── コマンド関連/                      ; command system (COMF/, SCOMF/, COMABLE/)
│   └── …                                 ; many other engine subdirs
├── CSV/                                  ; static data tables
│   ├── CFLAG.csv, TFLAG.csv, TCVAR.csv   ; flag slot dictionaries
│   ├── Talent.csv, Abl.csv, Mark.csv     ; per-char trait dictionaries
│   ├── Item.csv, Equip.csv, Train.csv    ; items / equipment / commands
│   ├── Base.csv, Palam.csv               ; physiological base / parameters
│   ├── Str.csv                           ; string table — gates [[X]] resolution
│   └── Chara/                            ; per-character data CSVs (1 per char)
├── Emuera*.exe                           ; engine binaries (multiple variants)
├── emuera.config, README*                ; engine config
└── sav/, dat/, resources/, font/         ; saves, sprites, fonts
```

**Key insight**: there's no plugin manifest. The engine recursively scans `ERB/` at load time; *adding a new file is the entire installation*. Drop a variant directory into `個人口上/<id> <name>/` and you're done.

---

## 5. Mental model — engine code vs kojo code

There are two kinds of code in this game; keep them separated:

1. **Engine code** — `KOJO_MESSAGE.ERB`, `EVENT_MESSAGE*.ERB`, etc. **You never write or modify these.** They came with the game and implement the dispatch loop.
2. **Kojo code** — files under `個人口上/<id> <name>/<variant>/M_KOJO_K<id>_*.ERB`. **This is what you write.** The engine reaches into these files looking for **specific label names** and calls whichever ones it finds.

The contract between the two is just a **list of label names**. The engine declares: *"if you define `@M_KOJO_MESSAGE_COM_K1_300`, I will call it whenever the player uses command 300 on character 1 (Reimu)."* You define the labels you care about; the engine ignores the rest.

So **as a kojo author you do not write `TRYCALLFORM ...`** — that line lives inside the engine and is not your concern. You only write `@LABEL_NAME` definitions. The engine reads the list of well-known label names and calls them. The full label catalog lives in `references/01-engine-label-catalog.md`.

### 5.1 The dispatch flow, step-by-step

Concrete walk-through of what happens when the player uses command 300 (会話) on character ID 1 (Reimu):

1. The engine processes the player input and decides "this is a COMMAND on TARGET=1 with command-id=300".
2. Engine calls its internal function `@KOJO_MESSAGE_SEND("COMMAND", 300, 1, ...)`.
3. Inside that function (in `KOJO_MESSAGE.ERB`), the engine **constructs a label name from a template** and tries to call it:
   ```
   TRYCALLFORM M_KOJO%RESULTS%_MESSAGE_COM_K{NO:TARGET}_{ARG:1}
                       ↓                 ↓             ↓
                       (selector,        K1            300       → label resolves to:
                        usually empty)                            @M_KOJO_MESSAGE_COM_K1_300
   ```
   `TRYCALLFORM` is the engine's "try to call this label, but stay silent if it's not defined."
4. If you defined `@M_KOJO_MESSAGE_COM_K1_300` in your kojo files, the engine runs your body. If not, the engine silently moves on to a fallback (the `_00` catch-all, then engine-default narration).

That's the whole magic. The engine names labels using a few build-rules (one per dispatch kind); you provide the labels you want to populate.

### 5.2 What ARG, ARG:1, ARG:3 etc. mean (positional arguments)

When the engine constructs a label name, some inputs go into the *name*; others get passed as **positional arguments to the body**:

```
TRYCALLFORM M_KOJO_EVENT_K1_5(ARG:3, ARG:4)
                          ↓   ↓     ↓
                          K=1 then ARG:3 and ARG:4 are passed as positional args
                          event=5
```

The engine has an `ARG`/`ARG:1`/`ARG:2`/... namespace internally. When constructing the label, it puts some into the *name string* (for label dispatch) and forwards the rest as positional arguments. **You don't define `ARG:3`/`ARG:4`; the engine fills them.** Your job is to **receive and read** them in your label header:

```erb
@M_KOJO_EVENT_K1_5(ARG, ARG:1)
;       ^                  ^
;       Reimu              you receive ARG (engine's ARG:3) and ARG:1 (engine's ARG:4)

;Body — read ARG to decide which sub-state of event 5 we're in:
IF ARG == 0
    PRINTFORML 「<line for ARG=0 — e.g. propose>」
ELSEIF ARG == 1
    PRINTFORML 「<line for ARG=1 — e.g. accept>」
ENDIF
RETURN 1
```

What each positional `ARG` means **depends on the dispatch kind**: for SPEVENT, `ARG` is usually a sub-state (0=propose, 1=accept, 2=reject); for EVENT, `ARG` is documented per-slot (see `references/05-event-arg-subphases.md`); for child-rearing `(ARGS, ARG, ARG:1)`, `ARGS` is the life-stage string. The full per-label arg semantics are in `references/01-engine-label-catalog.md`.

---

## 6. Dispatch kinds — quick reference

The engine's `ARGS` keys (full label catalog → `references/01-engine-label-catalog.md`):

| ARGS | When it fires | Label families it builds |
|---|---|---|
| `"ENCOUNTER"` | First-meeting cutscene. | `@M_KOJO_ENCOUNTER_K{id}` |
| `"SP_EVENT"` | One-shot scripted events (kiss, confession). | `@M_KOJO_SPEVENT_K{id}_{ev}(ARG, ARG:1)` |
| `"EVENT"` | Generic events (room entry, morning, sleep). | `@M_KOJO_EVENT_K{id}_{ev}(ARG, ARG:1)` |
| `"COMMAND"` | Player chose a command. | `@M_KOJO_MESSAGE_COM_K{id}_{cmd}` (+ `_SUCCESS_COM_*`, `_MESSAGE_SCOM_*`) |
| `"COUNTER"` | Auto / idle reaction. | `@M_KOJO_MESSAGE_COUNTER_K{id}_{n}` |
| `"PALAM"` | After-action stat-change (incl. orgasm). | `@M_KOJO_MESSAGE_PALAMCNG_A/A2/B/B2/F_K{id}` |
| `"MARK"` | Mark / imprint acquired. | `@M_KOJO_MESSAGE_MARKCNG_K{id}` |
| `"DANMAKU"` | Bullet-hell duel. | `@M_KOJO_MESSAGE_COM_K{id}_DANMAKU(ARGS, ARG)` |
| `"IRAI"` | Quest dialogue. | `@M_KOJO_IRAI_K{id}(ROLE, SCENE, IRAI_ID)` |
| `"DAILY"` | Daily event. | `@M_KOJO_DAILY_EVENT_K{id}_{n}(ARG..., ARGS:1, ARGS:2)` |
| `"DIARY"` | Diary read. | `@DIARY_K{id}_*`, `@M_KOJO_MESSAGE_COM_K{id}_406` |
| `"CHILD"` | Child-rearing event. | `@M_KOJO_EVENT_K{id}_CHILD_RAISING_*` |
| `"GRAVITY"` | NPC AI movement decision (silent!). | `@M_KOJO_EVENT_K{id}_GRAVITY(ARG)` ← **silent**, sets `TCVAR:N:引力点`, never prints |
| `"BEFORETRAIN"` | Pre-training silent hook. | `@K{id}_BEFORETRAIN` ← **silent** |
| `"PERMISSION"` | Push-down consent (silent helper). | `@M_KOJO_EVENT_K{id}_PERMISSION_<n>(ARG)` |
| `"LOST_VIRGIN_STOP"` | Virginity-loss interrupt (silent). | `@M_KOJO_EVENT_K{id}_LOST_VIRGIN_STOP(ARG)` |
| `"GIFT"`, `"ODEKAKE"`, `"SEX_FRIEND"`, `"ONABARE"`, `"MUSHI_BATTLE"`, `"SUIKA"`, `"DIRECT"`, `"SUCCESS"`, `"ENDING"` | Misc / special. | (see references/01) |

**Distinguishing print vs silent dispatch is critical** — putting `PRINTFORML` in a silent label (GRAVITY especially) spams the player every NPC-movement tick. → §1 pitfall #5

---

## 7. Standard body shape (the most-reused template)

Every command body follows this pattern. Use it as your default scaffold:

```erb
;==================================================
;<cmd-id>,<command-name>
;TFLAG:193(1=mood-up 0=neutral -1=mood-down)
;CFLAG:诶嘿嘿==2&&TCVAR:20(<situational sub-state>)
;PREVCOM(<previous-cmd-numbers that affect this>)
;==================================================
@M_KOJO_SUCCESS_COM_K<id>_<cmd>
;成否判定
TFLAG:192 = 0                         ; -2 end, -1 fail, 0 default, 1 great-success

@M_KOJO_MESSAGE_COM_K<id>_<cmd>
CALL TRAIN_MESSAGE                    ; engine default narration (omit if you want full custom)
CALL M_KOJO_MESSAGE_COM_K<id>_<cmd>_1  ; dispatch to body
RETURN RESULT

@M_KOJO_MESSAGE_COM_K<id>_<cmd>_1
;-------------------------------------------------
;記入チェック（=0, 非表示、1, 表示）
LOCAL = 1                              ; 1 = filled in, 0 = stub-skip
;-------------------------------------------------
IF LOCAL
    IF FLAG:時間停止                   ; time-stop: silent unless 時間停止口上有 set
    ELSEIF CFLAG:睡眠                  ; sleeping: silent unless 眠姦口上有 set
    ELSEIF TALENT:恋人                 ; tier 5 — partner
        SELECTCASE RAND:3
            CASE 1
                PRINTFORML 「<lover-line-A>」
                PRINTFORMW <lover-narr-A>
            CASE 0
                PRINTFORML 「<lover-line-B>」
                PRINTFORMW <lover-narr-B>
            CASEELSE
                PRINTFORML 「<lover-line-C>」
                PRINTFORMW <lover-narr-C>
        ENDSELECT
    ELSEIF TALENT:愛欲 || TALENT:炮友  ; tier 4 — lust
        ...
    ELSEIF TALENT:恋慕                 ; tier 3 — in love
        ...
    ELSEIF TALENT:思慕                 ; tier 2 — admiring
        ...
    ELSE                                ; tier 1/0 — neutral or hostile
        ...
    ENDIF
ENDIF
RETURN 1
```

Contract points to remember:

- Always emit both `@M_KOJO_SUCCESS_COM_K<id>_<cmd>` and `@M_KOJO_MESSAGE_COM_K<id>_<cmd>` for any command this character handles. SUCCESS can be a single-line `TFLAG:192 = 0`.
- The split `MESSAGE_COM_<cmd> → MESSAGE_COM_<cmd>_1` is convention; lets the body label be re-CALLed independently.
- `RETURN 1` from the body marks "I handled it"; engine does not fall through to defaults.
- `RETURN 0` or no return: engine falls through to `_00` catch-all then to engine defaults.
- Last `PRINTFORML` of a body should usually be `PRINTFORMW` so the player advances.
- Use `%CALLNAME:MASTER%`, not "你"/"主人公"/etc. — names are user-configurable.
- For random variation: `SELECTCASE RAND:N / CASE 0 / … / CASEELSE` (default = highest-probability).
- For single-line random: use `%TEXTR("a/b/c")%` inside a `PRINTFORML`.

---

## 8. The `LOCAL = 0/1` "filled-in" idiom

Bodies open with `LOCAL = 1` (filled) or `LOCAL = 0` (stub). `LOCAL = 0` causes the body to fall through silently. **Do not "fix" `LOCAL = 0` bodies** — they are intentional stubs.

Sub-branches use `LOCAL:1 = 1/0` for sub-toggles:

```erb
LOCAL = 1
IF LOCAL
    ;-------------------------------------------------
    ;初めて
    LOCAL:1 = 1
    ;-------------------------------------------------
    IF LOCAL:1 && FIRSTTIME(SELECTCOM)
        ; first-time-only branch
    ENDIF
    ;基本セット
    IF FLAG:70
    ELSEIF TALENT:恋慕
        ...
    ELSE
        ...
    ENDIF
ENDIF
RETURN 1
```

This lets an author selectively enable/disable parts.

---

## 9. The standard branching cascade

The canonical conditional cascade in a daily/sex/sexual-harassment body:

| Order | Guard | Comment |
|---|---|---|
| 1 | `IF FLAG:時間停止` (`= FLAG:70`) | Time-stop active; usually silent unless `CFLAG:N:時間停止口上有 = 1` is set in FLAGSETTING. |
| 2 | `ELSEIF CFLAG:睡眠` | Sleeping; silent unless `CFLAG:N:眠姦口上有 = 1`. |
| 3 | `ELSEIF FLAG:扮演` | Role-play; silent unless `CFLAG:N:扮演口上有 = 1`. Can branch on `CFLAG:(FLAG:扮演):出禁`. |
| 4 | `ELSEIF CFLAG:318 == 1` | "Extreme silent treatment / unfriendly" — many characters have this. |
| 5 | `ELSEIF CFLAG:诶嘿嘿 == 2` | "Drunken playful 'ehehe' mood" — branch further on `TCVAR:20` for sub-action. |
| 6 | `ELSEIF TALENT:恋人` | Tier 5 — partner. |
| 7 | `ELSEIF TALENT:愛欲 \|\| TALENT:炮友` | Tier 4 — lust without commitment. |
| 8 | `ELSEIF TALENT:恋慕` | Tier 3 — in love. |
| 9 | `ELSEIF TALENT:思慕` | Tier 2 — admiring. |
| 10 | `ELSE` | Tier 1/0 — neutral or hostile. |

Some authors collapse this into a helper `陥落状態()` returning 0..5; bodies then use `IF 陥落状態() >= 4 ...` instead of testing TALENT directly.

For sex commands, add intermediate guards on `BASE:MASTER:勃起`, `TCVAR:破瓜`, `TFLAG:193`, `TFLAG:194`, etc. — refer to the doc-banner state contract above each command.

**Watch out**: every early-return condition above the TALENT cascade *suppresses all relationship content below it*. For broad conditions (room class, weather, time-of-day), prefer RAND-gating or moving the condition inside relationship branches as flavor sub-conditions, instead of as an early-return blocker.

---

## 10. When the user asks for X — quick recipes

Three common workflows. **Full worked examples** with file scaffolds, exact labels, and Chinese-prose templates are in `references/06-workflow-recipes.md`.

### 10.1 New variant from scratch (target: empty char dir)

1. Confirm character ID and dir name (use `references/08-character-id-table.md` or grep `Chara/`).
2. Scaffold ~13 files: `イベント / 日常系 / 性交系 / セクハラ / 愛撫系 / 加虐系 / 道具系 / 派生 / カウンター / 弾幕勝負 / 刻印取得` plus optional `関数ライブラリ / 育児イベント / 日記 / INFO / 絶頂 / 奉仕系 / ハードな / 自慰系(あなた)`.
3. In `イベント.ERB` write the existence label `@M_KOJO_K<id>(ARG) RETURN 1` plus FLAGSETTING / COLOR / UPDATE / ENCOUNTER skeletons.
4. Fill ~5-10 most useful daily commands (300=会話, 301=泡茶, 302=身体接觸, 309=摸頭, 311=擁抱, 312=接吻, …) using the template in §7.
5. Leave `LOCAL = 0` stubs for everything else — engine falls back to default narration.
6. Run §2 verification pass.

### 10.2 Adding a one-shot scripted event (anniversary, holiday, etc.)

1. Decide the trigger: `@SPECIALDAY_EVENT_K<id>` for date-based, `@K<id>_<NAME>` author-private for state-driven.
2. Reserve a state-progress CFLAG (range 1000–1999, document it in `フラグ管理メモ.txt`).
3. Author the event body — usually a multi-step scene with `CALL ASK_YN(...)` at branching points and `SOURCE:N:<slot> += <delta>` on completion.
4. Hook the trigger from the existing `イベント.ERB` (add a `SIF <conditions> / CALL <event>` line in the appropriate engine slot).

### 10.3 Modifying an existing kojo (small content tweak)

1. Identify the file (which `M_KOJO_K<id>_<category>.ERB`).
2. Find the body label (`grep '^@'` for the relevant `_<cmd>` or `_<n>`).
3. Add the new branch in the right cascade position. For weather/time conditions, prefer **inside** the relationship branches (as flavor) over **before** them (as an early-return that blocks rich content).

---

## 11. Final reminders for you (the helper LLM)

1. **Structure first, prose later.** Always scaffold files and label names *before* asking the user about content.
2. **Default to the standard cascade** (§9). Only add custom guards when the user's persona explicitly requires.
3. **Use `LOCAL = 0` stubs liberally** — those slots fall back to engine defaults. Don't force the user to fill everything.
4. **Always emit both `SUCCESS_COM` and `MESSAGE_COM`** for any command. Even if SUCCESS is just `TFLAG:192 = 0`.
5. **Update `SOURCE:N:<slot>`** in counter / unique-counter handlers. Without it the kojo prints text but doesn't shift affection.
6. **Use `%CALLNAME:MASTER%`**, not 你/主人公/etc.
7. **Don't quote R18 lines from existing kojo.** When showing examples, redact prose to placeholders.
8. **For ID lookup**: char ID = leading number in the dir name. Confirm with `references/data/Chara/Chara<N> <name>.csv`.
9. **For new-API features** (`@KOJO_CUSTOM_BUTTON_*` etc.): only use if you've confirmed the user runs a recent engine. Wrap in `[SKIPSTART]/[SKIPEND]` if uncertain.
10. **Persistent storage**: prefer `CFLAG:N:1000-1999` (author-private) and `TCVAR:N:350-399` (author-private) over `SAVEDATA` modifiers.
11. **For inter-character interactions**: read each character's ID from the directory list. Use `RELATION:N:M` if the engine supports it; otherwise compose from `CFLAG:M:好感度`.
12. **Test mentally before delivering**: do the labels match? Is the existence check returning 1? Are guards in the right cascade order?
13. **Always run §2 verification pass** before declaring done. The most-common bugs are detectable mechanically.
14. **In Claude Code mode, lazy-load references** — only fetch what the current question needs. In chatbot mode, name the specific file the user should upload.

When the user asks "make X react to Y," the formula is:
- **WHAT slot?** Identify the engine label (command / event / counter).
- **WHAT guard?** Identify the discriminant (TFLAG / CFLAG / TALENT / time / weather).
- **WHAT body?** Generate `PRINTFORML` lines that reflect requested persona × guard.

Then deliver the patch. Use unified-diff style if modifying, full-file style if creating. Speak Chinese to the user; keep engine identifiers in their original Japanese/English.

Good luck. The user is making a creative thing they care about; your job is the boring infrastructure work so they can focus on their character.
