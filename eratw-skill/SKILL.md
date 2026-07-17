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
| Official empty template (canonical multi-file skeleton + the doc-banner comments that ARE the spec) — **read first** before scaffolding from scratch | `reference-kojo/口上テンプレ/M_KOJO_KX_*.ERB`, especially `M_KOJO_KX_イベント.ERB` |
| Filled-in worked-example kojo (when you need to see a real-world body, not just an empty stub) | `reference-kojo/reimu/M_KOJO_K1_*.ERB` (and `霊夢さんのreadme.txt`); grep specific commands as needed |
| First-party helper functions (`ASK_YN`, `ASK_M`, `TEXTR`, `HPH_PRINT`, `FIRSTTIME`, `AddEXP`) — what they do and when to use them | `references/03-engine-helpers.md` §5.2–§5.6.1 |
| **命令速查：某命令号能读哪些 state（`TFLAG:193` 成败 + 命令专属变量）、口上标签、触发/分发要点 —— 写任何 `_COM_K{id}_{号}` 命令体前必查该命令那一节** | `references/12-命令速查.md` |
| **高频惯用法目录：作者通行的成句写法（同房判定、关系分层、随机池、时段门控…），可直接照抄** | `references/13-高频惯用法.md` |
| **引擎行为源文件：命令/事件的"语义与分发"（`KOJO_MESSAGE.ERB` 分发器、`COMMON.ERB` helper 库、`EVENT_MESSAGE_COM300/400.ERB` 命令默认叙述）—— 命令速查不够时来这查/grep** | `references/data/engine/`（见其 `README.md`） |
| **日记系统（DIARY）：4 标签职责、`DIARY` 状态机 0/1/2/3、`PAGESET`、每日挑页、5 大坑、正确骨架** | `references/14-日记系统.md` |
| **依赖系（IRAI 委托）：`@M_KOJO_IRAI` 标签、ROLE/SCENE 枚举、`依頼名` CASE 值、骨架、debug 触发法** | `references/15-依赖系.md` |
| **刻印(MARK)系统：全表、不埒/反発刻印怎么获得(阈值)/消除/机械影响、`MARK:不埒刻印==n` 台词分层、`MARKCNG`+`TFLAG:24` 瞬时旁白、debug 增减** | `references/16-刻印系统.md` |

**For chatbot mode**, when you need any of the above, tell the user verbatim: *"Please upload `references/<filename>` from the eraTW-skill repository, or paste its contents."* Always name the **specific file** — don't say "upload the data" generically.

> **扩充本 SKILL 的方法论（枚举 + 样例双驱动）。** 早期这套 references 是"样例驱动"的——研读若干现成口上、把见到的东西写下来；结果被样例用到的命令/helper 有成段讲解，没被用到的（如 403/415/416、`SHIRAHU` 的同房惯用法）要么只在某张表里留一格、要么散落在打包的原始 CSV 里没被消化，导致写作时检索不到。**扩充时务必同时"枚举驱动"**：把权威枚举表逐条过一遍再消化——`Train.csv` 每个命令、`COMMON.ERB` 每个 helper、各 `EVENT_MESSAGE_COM*.ERB` 的命令 state 语义——而不是只补样例里碰巧出现的那些。新沉淀的通用知识写进 `references/12-命令速查.md`（命令级 state）、`references/13-高频惯用法.md`（成句套路）、`references/data/engine/`（行为源文件）。**新增的 SKILL 内容一律用中文描述**，仅标签名/代码标识符/必要术语保留原文（整份 SKILL 汉化是后续单独工程）。

### 0.5 If a user uploads existing kojo files

The user may share their current kojo or other characters' kojo for reference. **Read for structure, not content.** Bodies that contain explicit prose: skim only enough to see surrounding control flow and file role. Quote at most 1-2 lines of dialogue when essential.

**Reference priority order** when figuring out "how should this be structured":

1. **The user's own kojo (their fork, previous attempt, or a sibling-character peer they uploaded)** — primary. Their fork's conventions, their author-private CFLAG ranges, the persona register they want to match. Skip reading anything in `reference-kojo/` by default if the user has provided their own structurally-similar files.
2. **`reference-kojo/口上テンプレ/`** (the official empty template) — secondary. This is the canonical structural skeleton + the doc-banner comments that ARE the spec for each label's `ARG` / `ARG:1` / return-contract. Skim `M_KOJO_KX_イベント.ERB` once at the start of a scaffolding session.
3. **`reference-kojo/reimu/`** (filled-in worked example) — tertiary. Only when you need to see *how* an empty stub gets filled in (e.g. what does the 恋慕 branch of `MESSAGE_COM_K1_311` look like with real prose? what's a real `EVENT_K1_GRAVITY` body?). Grep the specific section rather than reading whole files.

Mention which reference you're consulting when you do, so the user knows where the pattern came from.

### 0.6 `[SKIPSTART]/[SKIPEND]` — two legitimate uses you'll see in existing kojo

The Emuera parser skips everything between `[SKIPSTART]` and `[SKIPEND]` lines (each on its own line, square brackets included). Existing kojo (Reimu K1, Lunasa K22, Eiki K30, etc.) use this for two distinct purposes — both are valid:

1. **Dev-time multi-line comment / temporary disable.** Wrap a block you're not ready to ship — half-finished prose, an experimental cascade, an idea you might come back to. The block stays in the file (versionable, easy to re-enable by deleting two lines) but the engine doesn't compile it. This is the most common usage.
2. **Optional new-API features.** Wrap any `@KOJO_CUSTOM_BUTTON_*` / `@KOJO_CUSTOM_TALENT_*` block when you're not sure the user's engine version supports it; the file then loads cleanly on older engines too.

**When you write new code**: prefer `;`-prefixed line comments for short notes; reach for `[SKIPSTART]/[SKIPEND]` only when you genuinely want a multi-line block that's parseable but disabled. **When you read existing code**: don't assume a SKIPSTART block is "dead code to delete" — the author may be intentionally parking work-in-progress there.

---

## 1. Most-common first-pass mistakes — read every time

These are the bugs we see in nearly every first-pass kojo generation. Hold them in your head while writing. Each one is detailed in the relevant section/reference below.

1. **Custom-named function parameters need a `#DIM` declaration in the body.** Emuera's parser only auto-recognizes positional `ARG / ARG:N / ARGS / ARGS:N`. Any other identifier in the header — `TYPE`, `相手残機`, `OPTION`, `PAGENUM`, `MODE`, `PAGECOUNT` — raises a Lv2 warning and reads return zero unless the body declares the variable with `#DIM <name>` (numeric) or `#DIMS <name>` (string) immediately after the `@` line. **Two acceptable shapes:** ① rename to positional: `@FOO(ARG, ARG:1 = 0)` then optionally `TYPE = ARG:1` as an alias; ② keep the engine-required custom names (e.g. `@DIARY_TEXT_K{id}, PAGENUM, MODE, PAGECOUNT`) and declare them with `#DIM PAGENUM / #DIMS MODE / #DIM PAGECOUNT` on the first three body lines. The engine-callable labels that *require* shape ② are flagged in `references/01-engine-label-catalog.md` §2.4 — chiefly `@DIARY_TEXT_K{id}`. → §7 / `references/04-dsl-full.md`
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
13. **写任何命令处理体前，先查该命令能读哪些 state —— 别凭记忆猜变量名。** 顺序（拉取变推送）：
    1. **先查 `references/12-命令速查.md` 里该命令那一节**，拿到它的口上标签、`TFLAG:193` 成败、以及命令专属状态变量（如演奏 416 的 `TFLAG:使用楽器`、劝酒 332 的 `BASE:酒気`、午睡 417 的 `CFLAG:陪睡中`）及各取值含义。
    2. **速查里没有 / 资料不足**：`grep "^{号}," references/data/Train.csv` 确认命令名 → grep 现存口上里该命令顶部的 banner 注释（`grep -rn "_COM_K.*_{号}" 個人口上/` 看多个作者的 banner，去重收敛）→ grep 引擎命令语义（`references/data/engine/EVENT_MESSAGE_COM{3,4}00.ERB`，或游戏里 `ERB\コマンド関連\COMF\COMF{号}*.ERB` 的命令主体）。
    3. **仍不清楚**：派一个 Explore agent 去游戏文件夹（`ERB\` 全树）检索该命令/变量——这是补资料的正道，不要凭"这个命令应该有个 XX 变量"臆测。查到的新事实若属通用知识，回填进 `references/12` 与 `references/data/engine/`。

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

echo "=== IF / ENDIF balance per file ==="
# Invariant: one ENDIF per block-opening IF. ELSEIF (starts 'E') and SIF (starts 'S')
# are NOT block openers and are naturally excluded by anchoring on '^\s*IF\b'.
# (Do NOT compute (IF+ELSEIF)-SIF — that only balances when ELSEIF count == SIF count,
#  so a body full of SIF-guarded [[MT]] markers throws false positives.)
for f in *.ERB; do
    ifs=$(grep -cE "^[[:space:]]*IF\b" "$f")
    ends=$(grep -cE "^[[:space:]]*ENDIF\b" "$f")
    [ "$ends" -eq "$ifs" ] || echo "$f: IF (block openers)=$ifs, ENDIF=$ends"
done

echo "=== SELECTCASE / ENDSELECT balance per file ==="
for f in *.ERB; do
    s=$(grep -cE "^[[:space:]]*SELECTCASE\b" "$f")
    e=$(grep -cE "^[[:space:]]*ENDSELECT\b" "$f")
    [ "$s" -eq "$e" ] || echo "$f: SELECTCASE=$s, ENDSELECT=$e"
done

echo "=== [SKIPSTART] / [SKIPEND] balance per file ==="
for f in *.ERB; do
    s=$(grep -cF "[SKIPSTART]" "$f")
    e=$(grep -cF "[SKIPEND]"   "$f")
    [ "$s" -eq "$e" ] || echo "$f: [SKIPSTART]=$s, [SKIPEND]=$e"
done

echo "=== Duplicate @label across all files (will hide later definition) ==="
grep -hE "^@[A-Za-z_][A-Za-z0-9_]*" *.ERB | awk '{print $1}' | sort | uniq -d

echo "=== RAND:0 (would crash at runtime) ==="
grep -nE "RAND:0\b" *.ERB
```

If any check fails, fix and re-run. **Re-run after every Edit pass** because tools sometimes strip BOM on rewrite.

---

## 3. Debugging with the user

The verification pass (§2) catches static issues. But many bugs only show at runtime — a line that prints too many times, a predicate that doesn't fire, a CFLAG slot that's silently the wrong type. This section is the **iteration loop** you run *with the user* whenever something doesn't behave right after a kojo edit.

### 3.1 How to get the game's log out

The game has two relevant menu actions under **「文件」** (File menu):

- **「保存日志」** — saves the current session log to a file in the game directory.
- **「将日志复制到剪切板」** — copies the session log to clipboard, ready for the user to paste into chat.

**The user pastes the relevant log section into the conversation; you read it.** Ask users to paste only the relevant section, since the entire log can be long and contain lots of irrelevant content.

In addition, the game writes `emuera.log` and `<YYYYMMDD-HHMMSS>.log` (per-session) files in the game root directory. But the former may not be lively updated. The latter is generated by **「保存日志」**.

### 3.2 Compilation errors — must be fixed before anything else

Compilation errors don't prevent the game from loading, but they may crash the game anytime. They appear at game launch.

**A healthy launch shows roughly four lines:**

```
如果出現了錯誤、請根據目錄下的報錯指導文件進行報錯
1702 files were found in the lazy loading table
Loading complete. Took 2.19 seconds.
Press Enter or click to proceed.
```

**Lines between the second and third are likely compilation errors.** Example:

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

**⚠️ Newly-added label does nothing in-game, but there's NO compile error? Suspect `lazyloading.dat` FIRST — before touching the code.** With `USELAZYLOADING:YES` (player default), a **brand-new** label you just added is not in the stale symbol cache, so the engine acts as if it doesn't exist and falls through to generic narration (you see the command's default banner but none of your kojo lines). Body edits to *existing* labels usually DO show — that asymmetry is the confusing part. Delete `lazyloading.dat` in the game root and relaunch (the engine rebuilds it). The autotest launcher does this automatically; a manual exe launch does not. Full detail: `references/11-autotest-pipeline.md` §11.6.

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
├── 原版+前人整合等各种readme/             ; community tutorials & templates (see §12)
│   ├── 改造とかしてみたい人のためのあれこれ/  ; modding tutorials (kojo tutorials, helper-fn ref, …)
│   └── 資料/                               ; reference tables (CFLAG/TFLAG/TCVAR IDs, maps, …)
├── Emuera*.exe                           ; engine binaries (multiple variants)
├── emuera.config, README*                ; engine config
└── sav/, dat/, resources/, font/         ; saves, sprites, fonts
```

**Key insight**: there's no plugin manifest. The engine recursively scans `ERB/` at load time; *adding a new file is the entire installation*. Drop a variant directory into `個人口上/<id> <name>/` and you're done.

`原版+前人整合等各种readme/` is the original Japanese community's tutorial corpus — **most of the structural knowledge in this skill is sourced from there.** It's not loaded by the engine; it lives in the install for human reference. See §12 for what's in it and when to consult it directly.

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
| `"DAILY"` | Daily event. | `@M_KOJO_DAILY_EVENT_K{id}_{n}(ARG..., ARGS:1, ARGS:2)` — known n: 2 (夢精), 4 (物思い), 12 (特訓) |
| `"DIARY"` | Diary read. | `@DIARY_K{id}_*`, `@M_KOJO_MESSAGE_COM_K{id}_406` |
| `"CHILD"` | Child-rearing event. | `@M_KOJO_EVENT_K{id}_CHILD_RAISING_*` |
| `"GRAVITY"` | NPC AI movement decision (silent!). | `@M_KOJO_EVENT_K{id}_GRAVITY(ARG)` ← **silent**, sets `TCVAR:N:引力点`, never prints |
| `"BEFORETRAIN"` | Pre-training silent hook. | `@K{id}_BEFORETRAIN` ← **silent** |
| `"PERMISSION"` | Push-down consent (silent helper). | `@M_KOJO_EVENT_K{id}_PERMISSION_<n>(ARG)` |
| `"LOST_VIRGIN_STOP"` | Virginity-loss interrupt (silent). | `@M_KOJO_EVENT_K{id}_LOST_VIRGIN_STOP(ARG)` |
| `"GIFT"` | Gift received/given. | `@M_KOJO_EVENT_K{id}_GIFT(ARG, GIFT_ID, 評価点, GIFT_NAME, SENSE)` (5-arg, custom names — body needs `#DIM`/`#DIMS`) |
| `"ONABARE"` | Caught-masturbating outburst. | `@M_KOJO_EVENT_K{id}_26(ARG, ARG:1)` (main dialogue) + `_26_1(ARGS)` (action pre-judgment) + optional `_ONABARE_1/2/3` (narration override) |
| `"MUSHI_BATTLE"` | Bug-battle dialogue. | `@M_KOJO_MESSAGE_COM_K{id}_MUSHI_BATTLE(ARGS, ARG)` ← **writes `RESULTS = "..."`, NOT `PRINT*`** |
| `"SUIKA"` | Watermelon-split directional callouts. | `@M_KOJO_MESSAGE_COM_K{id}_SUIKA(ARGS, ARG)` ← **writes `RESULTS = "..."`, NOT `PRINT*`** |
| `"RUN_INTO"` | Random encounter on map. | `@RUN_INTO_K{id}(MAP_ID)` |
| `"SEX_FRIEND"` | "Sex friend" contract scene. | `@KOJO_SF_CONTRACT_EVENT_K{id}(ARGS)` ("導入" / "補正" / "成功" / "失敗") |
| `"IRAI_BLOCKED"` | Suppress specific quest from this char. | `@M_KOJO_CHECK_K{id}_IRAI_BLOCKED(ARGS, ARG, ARG:1)` ← returns 1 to block |
| `"ODEKAKE"`, `"DIRECT"`, `"SUCCESS"`, `"ENDING"` | Misc / niche. | (see references/01) |

**Distinguishing print vs silent vs RESULTS-only dispatch is critical**:
- **silent labels** (GRAVITY, BEFORETRAIN, PERMISSION, LOST_VIRGIN_STOP): putting `PRINTFORML` inside spams the player every tick → §1 pitfall #5
- **RESULTS-only labels** (MUSHI_BATTLE, SUIKA): use `RESULTS = "<line>"` then `RETURN 1` — the engine prints it itself with auto-formatting. `PRINTFORML` here breaks the display. See `references/01-engine-label-catalog.md` §2.4.3.

---

## 7. Standard body shape (the most-reused template)

Every command body follows this pattern. Use it as your default scaffold. The 10-tier cascade shown below is the *maximal* form; the official empty template (`reference-kojo/口上テンプレ/`) uses a simpler 4-tier cascade — see §9 for when each fits.

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

Two cascades are common; pick the one that fits the character's complexity.

### 9.1 Maximal (10-tier) cascade — for full-featured kojo with rich per-tier flavor

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

### 9.2 Official-template (4-tier) cascade — for simpler or partially-populated kojo

This is the cascade the official empty template (`reference-kojo/口上テンプレ/`) uses by default:

```erb
IF LOCAL:1 && FIRSTTIME(SELECTCOM)   ; first-time line (optional opener)
    PRINTFORMW <first-time-line>
    RETURN 1
ENDIF
;基本セット
IF FLAG:70                            ; 時姦中 (time-stop)
    PRINTFORMW <time-stop-line>
    RETURN 1
ELSEIF TALENT:恋慕                    ; in love
    PRINTFORMW <love-line>
    RETURN 1
ELSEIF MARK:不埒刻印 == 3             ; lv3 submission imprint
    PRINTFORMW <submission-line>
    RETURN 1
ELSE                                  ; everything else
    PRINTFORMW <default-line>
    RETURN 1
ENDIF
```

**Use the 4-tier** when the user's persona/character is simple, when they don't care about per-tier nuance, or when they want to populate just the most-common cases and let everything else fall through. **Use the 10-tier** when the user explicitly wants rich tier-distinct flavor (e.g. distinct lines for 思慕 vs 恋慕 vs 愛欲 vs 恋人), or when the persona requires gating on 扮演/CFLAG:318 etc.

Both are valid and match published kojo in the install. Don't force the 10-tier onto a body where 4 lines is enough.

### 9.3 Sex-command intermediate guards

For sex commands (60-77, 95, plus 逆アナル 90-95), add intermediate guards on `BASE:MASTER:勃起`, `TCVAR:破瓜`, `TFLAG:193` (success grade), `TFLAG:194` (SELECTCOM record), etc. — refer to the doc-banner state contract above each command in the template, and to `references/02-state-bus-namespaces.md`.

### 9.4 Early-return warning

Every early-return condition above the TALENT cascade *suppresses all relationship content below it*. For broad conditions (room class, weather, time-of-day), prefer RAND-gating or moving the condition inside relationship branches as flavor sub-conditions, instead of as an early-return blocker.

### 9.5 内容自查：生成完一段对话后，回头过一遍这两点

写完一条命令/事件的台词后，在交还前**自己审一遍**（这是内容质量检查，不是 §2 的机械校验）：

**① 称呼玩家 & 明显与好感相关的内容，必须随好感度变化——别锁死在生疏关系上。**
一条命令若只有「恋人 / 恋慕 / ELSE」三档，那个 `ELSE` 会同时覆盖**萍水相逢的陌生人**和**好感度 1400 的好朋友**——于是一个亲密玩家做出亲吻、请客、一起玩这类举动时，角色却用陌生人的冷淡语气回应（例：亲吻命令的 `ELSE` 是「你干什么！」+ 后退摔倒；一个 思慕/好朋友 玩家不该吃这个反应）。**修法二选一**：要么按 `CFLAG:{id}:好感度` 或关系 `TALENT` 多加中间档（思慕/熟络/心动），要么直接用 `%CALLNAME:MASTER%`（玩家名）而非「人类」「你这家伙」这类**锁定生疏**的称呼。好感度参考刻度（因作品/角色而异，仅作量级参考）：

| 好感度 | 大致关系 |
|---|---|
| < 250 | 生疏（初识/防备） |
| < 500 | 点头之交 |
| < 1000 | 熟人 |
| < 1500 | 好朋友 |
| < 3000 | 非常要好，常已进入「思慕」（`TALENT:思慕` 门槛之一即 好感度≥1500） |
| ≥ 3000 | 基本是恋慕/恋人 |

**要结合上下文灵活判断，不是见「人类」就改。** 关键区分：
- ❌ **锁定生疏**：「人类说要一起玩」——把玩家当外人陈述，任何好感度听着都像不熟。这种要改。
- ✅ **强调种族 + 傲娇**：「哼，人类也想玩妖精的游戏？那你可得跟上我们的节奏哦」——这是在拿「人类 vs 妖精」的身份调侃/逞强，带傲娇味，**任何好感度都可能这么说**，合理，不必改。
判据：这句话**换成恋人来说**还成立吗？成立（傲娇调侃）就留；不成立（暴露了「不熟」的前提）就按好感度分档或改用玩家名。

**② 克制对角色某个标志性特点的反复描写。**
把角色的招牌设定（能力、口癖、某个动作）**每一个分支都塞一遍**，读着就很「AI 完成命题作文」、不自然（例：露娜的「消音」能力若在会話、摸头、拥抱、接吻、礼物每条里都出现一次，就过量了）。让标志性特点**偶尔**出现、点到为止，其余分支用别的细节撑起人物。可参考 eratw 里其他角色口上的自然疏密度。**此项从简**——它是风格偏好、通常很安全，最终由用户拍板润色，不必花大量精力反复审查。

**③ 会持续很久的状态，它的专属台词要【入候选池】，不要写成排他覆盖。**
「约会中」这类状态**一持续就是几十个回合**，玩家在这期间会反复点「会話」。若写成
`IF 约会中 → 演约会台词 / ELSE → 平时的候选池`，那整场约会就**只剩那一句**翻来覆去，丰富度断崖式下降。
正确做法：把约会台词**按当前关系追加进候选池**，让它和平时的台词一起参与随机——约会味道点到为止，变化照旧：
```erb
IF CHK_DATENOW(CFLAG:MASTER:约会中) && FLAG:约会的对象 == TARGET
    IF TALENT:{id}:恋人
        pool:(LOCAL:1) = 70
    ELSEIF …
    ENDIF
    LOCAL:1 += 1
ENDIF
```
**排他覆盖只留给「压过一切」的短暂状态**：时间停止、睡眠、暴怒(318) 之类——这些状态下别的台词本来就说不通。
判据：问自己「这个状态会持续多久？玩家在这期间会点几次这个按钮？」超过两三次，就该入池。

**④ 增减好感度/信赖度等数值时，把变化打印出来。**
玩家看不到内部变量。悄悄 `CFLAG:{id}:好感度 -= 30` 而不吭声，玩家既不知道被罚了、也学不到「这么做有代价」，行为反馈整个断掉：
```erb
;好感度不足 30 时只会扣到 0，故先算出【实际】扣掉多少再打印，别报一个没真扣满的数
LOCAL = MIN(CFLAG:{id}:好感度, 30)
CFLAG:{id}:好感度 -= LOCAL
PRINTFORMW 【%CALLNAME:{id}%的好感度 -{LOCAL}　信赖度 -20】
```
注意打印的是**实际变化量**：有 clamp（下限 0、上限封顶）时，写死的字面量会撒谎。

---

## 10. When the user asks for X — quick recipes

Three common workflows. **Full worked examples** with file scaffolds, exact labels, and Chinese-prose templates are in `references/06-workflow-recipes.md`.

### 10.1 New variant from scratch (target: empty char dir)

1. **Before scaffolding, read the official template.** `reference-kojo/口上テンプレ/` is the canonical empty skeleton shipped with the skill. At minimum skim:
   - `M_KOJO_KX_イベント.ERB` — existence label, FLAGSETTING, COLOR, UPDATE, ENCOUNTER, BEFORETRAIN, SPEVENT 1-3, EVENT 1-34 (with full ARG doc-banners), DAILY_EVENT 2/4/12, ONABARE_1/2/3, LOST_VIRGIN_STOP, PERMISSION_1/2, GIFT, MUSHI_BATTLE, GRAVITY, SUIKA, RUN_INTO, SF_CONTRACT_EVENT, CHECK_IRAI_BLOCKED.
   - The TOC banners of `M_KOJO_KX_日常系コマンド.ERB` and `M_KOJO_KX_性交系コマンド.ERB` (grep `^;[0-9]+,` for command-id banners — don't read every body).
   - `of_new_kojo_api.ERB` if the user wants the new custom-API features.

   The doc-banner comments in the template ARE the spec — they tell you which `CFLAG` gates each label, what `ARG`/`ARG:1` mean per slot, and the return-value contracts (`PERMISSION_1` body returns -1/0/1, `LOST_VIRGIN_STOP` body returns 1=abort/0=proceed, `EVENT_KX_26_1` body returns -1/0/1, etc.). **This is the single most-load-bearing prep step.**

   Only consult `reference-kojo/reimu/` when you need to see a *filled-in* example of a specific body — grep `reimu/M_KOJO_K1_コマンド.ERB` for the command-id you're working on. Don't read whole Reimu files; they're old and monolithic.

   If the user's target character has a same-style sibling/peer with an existing kojo (e.g. one of three sisters, two characters of the same persona type), grep that one too; it'll often have the right `CFLAG:TARGET:*` situational branches and tone.

2. Confirm character ID and dir name (use `references/08-character-id-table.md` or grep `Chara/`).

3. **Scaffold the modern multi-file split** as the official template does:
   - **Always**: `イベント / 日常系コマンド / セクハラコマンド / 愛撫系コマンド / 加虐系コマンド / 道具系コマンド / 性交系コマンド / 派生コマンド / カウンター / 弾幕勝負 / 刻印取得 / 絶頂`.
   - **Common**: `奉仕系コマンド / 道具系 / ハードなコマンド / 依頼 / 育児イベント / 日記 (or 日記（簡易版）)`.
   - **Optional**: `自慰系(あなた)コマンド / 固有カウンター / of_new_kojo_api / 関数ライブラリ / INFO / <chara>特殊イベント`.

   File names are `M_KOJO_K<id>_<category>.ERB`. Match the template's filenames byte-for-byte (including 全角 parentheses in `自慰系(あなた)コマンド.ERB`). Reimu's monolithic single-`コマンド.ERB` layout is legacy — don't mirror it.

4. In `イベント.ERB` write the existence label `@M_KOJO_K<id>(ARG) RETURN 1` plus FLAGSETTING (with CFLAG enable-flags for the silent helpers you want — `破瓜キャンセル口上有`, `口上内抱き寄せ判定_初回`, `口上内抱き寄せ判定_通常`, `時間停止口上有`, `眠姦口上有`, `なりきり口上有`), COLOR, UPDATE, ENCOUNTER skeletons.

5. Fill ~5-10 most useful daily commands (300=会話, 301=泡茶, 302=身体接觸, 309=摸頭, 311=擁抱, 312=接吻, …) using the §7 template (with either §9.1 maximal or §9.2 4-tier cascade depending on persona complexity).

6. Leave `LOCAL = 0` stubs for everything else — engine falls back to default narration.

7. Run §2 verification pass.

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

---

## 12. The community tutorial corpus (`原版+前人整合等各种readme/`)

Your eraTW install almost certainly ships a directory `原版+前人整合等各种readme/` (literally "originals + various-prior-author-integration readmes"). **This is the original Japanese community's tutorial + reference corpus, and most of the structural knowledge in this skill is sourced from there.** It's not loaded by the engine — it lives in the install for human reference.

You normally don't need to read it: the skill has already extracted the relevant parts into `reference-kojo/` and `references/`. But you should **know it exists**, because (a) the user may reference it (asking "what's in `便利な関数.txt`?"), (b) the user may have a **newer version** of the corpus than what this skill was built from, and (c) for niche topics not covered here, it's the authoritative source.

### 12.1 Structure of `原版+前人整合等各种readme/`

```
原版+前人整合等各种readme/
├── eraTW_FAQ.txt                       ; player-facing FAQ (not for modders)
├── 更新内容・readme.txt                  ; ~400 KB changelog
├── 今後の課題・方針・思いつきetc.txt     ; maintainer's roadmap / notes
├── 改造とかしてみたい人のためのあれこれ/   ; THE MODDING TUTORIALS — read this first
│   ├── 口上関連/                         ; everything kojo-specific
│   │   ├── worldパッチ制作者による超初心者向け口上の書き方入門.txt
│   │   │                                 ; ★★★ The maintainer's beginner kojo intro (100 lines)
│   │   ├── TW口上作成周辺の注訳.txt
│   │   │                                 ; ★★★ "Tutorial-written-as-kojo" — covers IF/ELSEIF/SIF, &&/||, CFLAG, PRINTDATA
│   │   ├── 口上作者様へ.txt
│   │   │                                 ; ★★★★ Authoritative ENCOUNTER/EVENT 1-23/SP_EVENT 1-3 ARG semantics
│   │   ├── 超初心者向け使用頻度の高い変数の説明.txt
│   │   │                                 ; ★★★ FLAG vs CFLAG vs TFLAG vs TCVAR vs TALENT vs ABL vs BASE one-liners
│   │   ├── 口上テンプレ/                  ; ★★★★★ THE OFFICIAL EMPTY TEMPLATE — copied verbatim into reference-kojo/口上テンプレ/
│   │   ├── 別人版用口上テンプレ/          ; same template but for "alternate-personality" variants
│   │   ├── 口上ファイル以外のキャラ別メッセージ等.txt
│   │   ├── 口上作者様へ.txt              ; (same as above — see ★★★★)
│   │   ├── 日記帳れどめ.txt              ; diary-system documentation
│   │   ├── eraTheWorld proto4.11 イベントまとめ(仮)/     ; older EVENT reference (superseded)
│   │   ├── txt口上ノート/                ; plain-text kojo planning worksheets
│   │   └── TW用私製テンプレ/            ; one author's alternate template style
│   ├── 便利な関数.txt                    ; ★★★★ First-party helper-function reference (ASK_YN, ASK_M, TEXTR, HPH_PRINT, FIRSTTIME, AddEXP)
│   ├── キャラ追加のススメVer.2.0.txt     ; ★★ How to add a new character (CSV layer + chara-data + CHARAMOVE)
│   ├── キャラ設定向け参考資料.txt        ; character-stats setting guidance
│   ├── 改造関連FAQ.txt                   ; ★★ Don't-use-Notepad, use Sakura Editor, etc.
│   ├── お手軽！…仕事の追加講座.txt     ; easy job-add for non-programmers
│   ├── 下着追加のススメ80%版.txt         ; underwear-system mod tutorial
│   ├── eTW用コマンド作成例/              ; command-creation examples (COMF system)
│   ├── eratohoTWサクラエディタ用キーワードヘルプ/    ; Sakura Editor syntax highlighting
│   ├── MOB子素材作成のすすめ20180409/    ; mob-character asset creation
│   ├── NewIraiSystem.txt                 ; new IRAI (quest) system
│   ├── CharaXX テンプレ.csv              ; CSV template
│   ├── IRAI_XX 依頼テンプレ.ERB          ; quest template
│   ├── ROOMSETTING_XX.ERB                ; room-setting template
│   ├── IMAGE_IXX_○○ テンプレ.ERB        ; per-char image template
│   └── DAIRY_EVテンプレ.ERB              ; daily-event template
├── 資料/                                 ; reference tables (Shift-JIS encoded — read with --encoding shift_jis)
│   ├── 変数一覧/                         ; authoritative variable-ID tables
│   │   ├── CFLAGS.txt                    ; CFLAG:N ID table (273 lines)
│   │   ├── TFLAGS.txt                    ; TFLAG:N ID table (111 lines)
│   │   ├── TCVAR.txt, EXP.txt, FLAGS.txt, EQUIP.txt, TEQUIP.txt, …
│   │   └── 現在位置一覧.txt              ; CFLAG:300 (current location) ID enumeration
│   ├── 刻印取得条件.txt, 陥落系素質取得条件.txt   ; trait acquisition conditions
│   ├── 技能成長条件.txt                  ; skill growth conditions
│   ├── MAP.txt, 月マップ全景&ROOMSETTING一覧.txt, 紅魔館マップ全景.txt, 神社周辺見取り図.txt
│   └── 実装済みお仕事一覧.txt            ; jobs catalog
├── パッチ/                               ; 60+ version-pinned bugfix patches (historical, mostly irrelevant)
└── (etc — older readmes, version notes)
```

### 12.2 What's been integrated into this skill, and what hasn't

| Source file | Where it lives in the skill |
|---|---|
| `口上テンプレ/` (whole dir) | Copied verbatim to `reference-kojo/口上テンプレ/` |
| `口上作者様へ.txt` (EVENT 1-23 ARG semantics) | Integrated into `references/01-engine-label-catalog.md` §2.4.2 (extended to 1-34 from template) |
| `便利な関数.txt` (ASK_YN/ASK_M/TEXTR/HPH_PRINT/FIRSTTIME/AddEXP) | Integrated into `references/03-engine-helpers.md` §5.2 / §5.6.1 |
| `worldパッチ制作者による超初心者向け口上の書き方入門.txt` (PRINT-family, CALLNAME, SETCOLOR walkthrough) | The walkthrough's lessons are baked into §5–§8 here |
| `TW口上作成周辺の注訳.txt` (IF/SIF/&&/PRINTDATA tutorial) | Lessons baked into §1, §7, §8 |
| `超初心者向け使用頻度の高い変数の説明.txt` (FLAG vs CFLAG vs TFLAG one-liners) | Baked into §5 + `references/02-state-bus-namespaces.md` |
| `日記帳れどめ.txt` (diary-system 0/1/2/3 state) | Integrated into `references/01-engine-label-catalog.md` §2.4 DIARY row |
| `資料/変数一覧/*.txt` (CFLAG/TFLAG/TCVAR ID enumeration) | **Not integrated** — the skill assumes you read `references/data/CFLAG.csv` etc. for per-slot lookup. The Japanese textfiles cover the same data but in Shift-JIS. If a user asks "what's CFLAG:341 for?" and your CSV doesn't have it, check `資料/変数一覧/CFLAGS.txt`. |
| `キャラ追加のススメVer.2.0.txt` (new-character CSV scaffolding) | **Not integrated** — out of scope (this skill is kojo-only). If the user wants to scaffold a *whole new character* (CSV + CHARAMOVE + キャラデータ + kojo), point them at this file. |
| `パッチ/` (version-pinned bugfix patches) | **Not integrated** — historical. |
| `eTW用コマンド作成例/` (command-creation examples) | **Not integrated** — out of scope. |
| `下着追加のススメ80%版.txt` (underwear mod) | **Not integrated** — out of scope. |
| `NewIraiSystem.txt` (new quest system) | **Not integrated** — relevant only if the user wants to add a new quest type; quest *dialogue* is covered. |

### 12.3 Skill version vs install version

**This skill was built against the corpus as of approximately 2024-05 (the file `mtime` on the source dir).** The user's install may be newer. eraTW updates slowly and almost all updates are backwards-compatible with existing kojo, so the EVENT slot numbers / CFLAG IDs / label naming conventions you see here should still work — but be aware:

- **If the user's install has newer files in `原版+前人整合等各种readme/口上関連/口上テンプレ/`** (e.g. a file named `M_KOJO_KX_<新カテゴリ>.ERB` you don't recognize), trust their copy. Check the file directly — its doc-banner comments will tell you what it's for.
- **If the user reports an engine warning about a label that this skill doesn't document** (e.g. `@M_KOJO_FOO_K20` raised a warning), suggest they check the corresponding ERB engine file in their install. The engine source is the ultimate authority; this skill is a curated extract.
- **If the user references a tutorial or template file that's not in the table above**, ask them to share it — it may be new since this skill's last update.

You don't need to scan the corpus directory yourself unless the user specifically asks about something that's not covered here. The point of §12 is just: know it exists, know roughly what's in it, know where it lives in the install.
