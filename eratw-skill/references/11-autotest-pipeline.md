# 11 — Autotest pipeline (semi-automated kojo testing)

> **STATUS: VALIDATED end-to-end on Luna Child K6 (2026-07).**
> Confirmed working: clip_tap capture; the state-injecting battery (incl. 好感度/心情 layering — the harness must zero those or high real values shadow lower tiers); `[[TID BEGIN/OK]]` markers + `at_update.ps1`; the **marker-based manual test** (`[[MT TID]]`, §11.8) with `manual_scan.ps1`; the **one-click launcher** `run_eratw_test.bat` (§11.12); BOM/lazy-cache handling.
>
> ### ⭐ CURRENT AUTHORITATIVE CONVENTIONS (supersede any stale detail below)
> These are the tested, current design. Where §11.3 etc. say otherwise (DEBUGGERR fire-when-0, `TCVAR:{id}:399`), that is **superseded** — kept only as background.
>
> 1. **Guard = a single persistent three-state "arm" flag `CFLAG:{id}:1099`** (NOT `DEBUGGERR` — dev builds default it to 0 too, and it gates other game debug; NOT `TCVAR`, which clears daily). States: **0** = never armed (default; real players are always 0 → **never fires**, safe) · **1** = armed (only a debug command sets it) → fires once, battery sets it **2** · **2** = already ran (CFLAG is persistent, survives day-change) → won't re-fire. Hook: `IF CFLAG:{id}:1099 == 1 / CALL …AUTOTEST / RETURN 1 / ENDIF`. Arm/re-arm from the debug console: `CFLAG:{id}:1099 = 1`. Why default-0-never-fires beats DEBUGGERR: safety is intrinsic, not dependent on an external switch.
> 2. **Deterministic testing of RAND/candidate-pool dialogue** (e.g. 会話 300 down-compat pool): a plain `CALL …_300_1` just RANDs a line, so the harness can't hit a *specific* line. Add a **force-line hook `CFLAG:{id}:1098`**: when `>0`, the dialogue body skips all RAND and plays exactly that line-code. The harness sets `CFLAG:{id}:1098 = <code>` before each `CALL`, giving one deterministic `[[TID]]` per line (and the TIDs then match the `;@AT` tags 1:1 — no orphans). Reset `CFLAG:{id}:1098 = 0` after. Save/restore it like any mutated slot. (`CFLAG:1000–1999` is the 口上用確保領域 reserved kojo range — 1098/1099 are safe free slots.)
> 3. **Clipboard capture loss is mostly a config problem, not a timing one.** The real culprit for a dropped `[[TID … OK]]` at a screen boundary is `emuera.config` line **`画面のリフレッシュ時にクリップボードとバッファを消去する:YES`** — it wipes the clipboard+buffer on every screen refresh, so a marker printed right at a refresh vanishes before clip_tap polls it. **Set it to `NO`.** Also raise `総バッファサイズ` (default 300) to ≥1000 so a full run doesn't scroll off, keep `クリップボードに貼り付ける行数:500` / `更新間隔:200`. A residual single lost line is still possible → judge pass/fail by reading the actual dialogue text, never by OK-marker presence alone.
> 4. **Any child-`powershell` call that carries CJK + quotes must use `-EncodedCommand` (Base64/UTF-16LE), never `-Command "<string>"`.** `-Command` lets the command-line parser eat the embedded double-quotes → the child treats the Chinese as a command name and errors, and the error text can get captured as if it were the return value (this broke the folder-picker `P` option). `$enc=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($code)); powershell -STA -NoProfile -EncodedCommand $enc`.
>
> 5. **Every `[[MT]]` manual-test marker is guarded by ONE per-character switch `@K{id}_MT_ON()`** — a `#FUNCTION` in the kojo's function-library file that `RETURNF 1` during dev/test and `RETURNF 0` before release. Each marker is written as a two-line pair: `SIF K{id}_MT_ON()` immediately above `PRINTL [[MT <TID>]]`. Dev = markers print → cliplog captures them; release = **flip that one function to `0`** and every marker across every file goes silent, so players never see `[[MT …]]`. This decouples "marker present in source" from "marker visible to players": a hard-to-reach-but-safe branch can **ship with its marker still in the file**, silenced, instead of forcing you to either test it or delete it. Before release the AI reports how many manual TIDs are still `待手动测试`/`测试失败`, then asks the user whether to (a) flip the switch to `0`, and (b) comment out any *dangerous* still-untested branches. See §11.8. (`manual_scan.ps1 -Apply` is guard-aware: when it deletes a passed `PRINTL [[MT]]` line it also removes the `SIF K{id}_MT_ON()` line directly above it, so no orphan guard is left swallowing the next real line.)
>
> **Older correction still valid:** manual-test coverage is marker-based (`[[MT <TID>]]` + grep), not signature-matching.
>
> **Battery coverage is NOT automatic — cross-check & prune (§11.13).** "Autotest all-green" only proves the branches the battery *actually exercises*. A branch tagged `;@AT 待自动测试` is a **promise the AI made while writing**, not proof it's wired into `@M_KOJO_K{id}_AUTOTEST`. These drift apart (front/back inconsistency). During testing the AI must diff the two sets and add missing branches; and it may **de-register** already-passed branches from the battery to keep it lean — that pruning is the **AI's job, not the launcher's**.

**Mode:** Claude Code only (needs file access + ability to launch the game). Requires the user present to drive in-game GUI (load a save, open the debug console, click through dialogue). This is the advanced counterpart to SKILL.md §3 (paste-the-log debugging): instead of the user hand-triggering each case and pasting logs, you install a small **autotest harness** inside the kojo that exercises many dialogue branches in one action, and you read a **live clipboard transcript** to diagnose.

This whole file is *empirically derived* — the "what does NOT work" section below is the map of dead-ends so you don't waste a session re-discovering them.

---

## 11.1 The pipeline at a glance

1. Write / edit the kojo.
2. Tag each dialogue branch with a status flag + a stable test-id (§11.7).
3. Add a small **autotest battery** label + a **3-line guarded hook** in one command handler (§11.4–11.5). Both live *inside the kojo folder* — no engine/core files are ever edited.
4. Launch the game (`-Debug`) and start the clipboard transcript tool (§11.6).
5. The user loads a save, enables the guard, and triggers the hook (talks to the character). The battery runs, dumping delimited output.
6. Read the transcript; a script (or you) maps results back to source lines and updates the status flags (§11.7).
7. For branches the battery can't reach, the user plays normally in **integration mode** and the tool marks them as it sees them (§11.8).
8. **Before delivery: disarm** — comment out / delete the hook and the harness file (§11.4, §11.9). Non-negotiable.

---

## 11.2 What does NOT work (ruled out empirically — don't retry)

- **The debug console cannot trigger a harness.** The `-Debug` console accepts variable *assignments* (great for cheating in state) and *expressions*, and can invoke a `#FUNCTION` as an expression — but it **rejects flow control**: `CALL` / `IF` / `GOTO` → `不能使用流程控制类命令`. And a `#FUNCTION` body **cannot contain `CALL`** (`CALL命令中不能使用#FUNCTION(S)`). So the console can set up state but can never call your kojo's procedure labels. The trigger must come from a *real procedure context*.
- **Event hooks are single-definition in this fork.** `@EVENTFIRST` (new game), `@EVENTLOAD` (after load), `@BEFORETRAIN` (day start) etc. are owned by the base game (`SYSTEM.ERB`, `BEFORETRAIN.ERB`). A *second* definition of the same event function in a kojo file is silently ignored — only the game's runs. (Mods that need a day-start hook inject a flag-guarded `CALL` into the canonical file's `;custom code` section, e.g. `BEFORETRAIN.ERB` — that's editing a core file, which we avoid for tests.)
- **Lazy loading excludes event-function files.** With `USELAZYLOADING:YES` (the player default), any file containing an event function (`@EVENTLOAD`, `@EVENTFIRST`, …) is *not loaded* at all (`… has event function EVENTFIRST, file excluded`). So an event-hook harness wouldn't even load without `USELAZYLOADING:NO`.
- **The custom-command button API (`@KOJO_COM_NAME/ABLE/K{id}_{n}`, cmd 270+n) is NOT dispatched by this engine.** Even a correctly-authored slot produces no button (the shipped `即兴合奏` custom command also doesn't appear). Confirmed unsupported on this install — do not build a "run autotest" button.

**Conclusion:** the only reliable, non-invasive trigger is a **guarded hook inside an existing player-selectable command handler** (a plain procedure → `CALL` works; a regular file → loads under lazy loading).

---

## 11.3 `DEBUGGERR` — the guard flag (know what it really is)

`DEBUGGERR` is a **game-native `#DIM SAVEDATA` flag** (declared in `ERB\DLC\DLC.ERH`), used by the base game (shop debug, option print, user-command handling, `@IS_DEBUGGERR`). It is **NOT** set by launching with `-Debug` — that only enables the debug *console/menu*. `DEBUGGERR` is toggled manually via the in-game **幻想乡之主 debug menu** (`DLCCHIOSEMENU.ERB`) or by typing `DEBUGGERR = 1` / `= 0` in the debug console.

Because it's a *shared* flag, toggling it also flips the game's other debug behaviors. If you'd rather keep the test fully isolated, declare **your own** dedicated flag instead (e.g. a private `CFLAG:{id}:` slot or a `#DIM SAVEDATA AUTOTEST_ARMED`) and guard on that — cleaner, but one more thing the user sets. Either way the guard logic below is identical.

---

## 11.4 The trigger hook (fires the battery)

Add these lines at the very top of one command handler the character actually has — 会話 (`@M_KOJO_MESSAGE_COM_K{id}_300`) is the natural choice:

```erb
@M_KOJO_MESSAGE_COM_K{id}_300
;=== AUTOTEST hook (TEMP — DELETE before delivery) ===
IF !DEBUGGERR
	CALL M_KOJO_K{id}_AUTOTEST
	RETURN 1
ENDIF
;=== end AUTOTEST hook ===
CALL TRAIN_MESSAGE
CALL M_KOJO_MESSAGE_COM_K{id}_300_1
RETURN RESULT
```

**Direction chosen for this project (SUPERSEDED — see the ⭐ callout at the top):** the guard is now the three-state arm flag `CFLAG:{id}:1099` (`==1` fires, battery sets `2`; arm with `CFLAG:{id}:1099 = 1`). The old "fire when `DEBUGGERR == 0`, set `1`" scheme was dropped because dev builds default `DEBUGGERR` to 0 (so it would fire for a player once they toggled debug) and because zeroing `DEBUGGERR` disables the game's other debug output. Do not reuse `DEBUGGERR` as the guard.

> ⚠️ **This is "default-armed": `0` is also the normal *player* state.** If this hook ships in a delivered kojo, a player's first 会話 will trigger the whole test dump. Therefore **disarming before delivery is mandatory** (§11.9), and the surest disarm is to *comment out the hook + delete the harness file* — not merely setting the flag (a player's save is at `0`). If you prefer safe-by-default, invert to `IF DEBUGGERR` (fires only when the user deliberately enables debug) and drop the reset; the tradeoff is one console keystroke to arm.

---

## 11.5 The battery (`@M_KOJO_K{id}_AUTOTEST`)

A single temporary label, in its own file `M_KOJO_K{id}_AUTOTEST.ERB` inside the kojo folder. It:

1. **Saves** every state slot it will mutate into a local array.
2. **Sets up state internally** — all the "cheats" as plain ERB assignments, so the user types nothing in the console.
3. **CALLs the dialogue bodies** across each relationship tier / condition, bracketed by ASCII markers + test-ids.
4. **Restores** every saved slot.
5. **Resets the guard** (`DEBUGGERR = 1`) so it fires once per enable.

```erb
;============================================================
;AUTOTEST harness for K{id} — TEMPORARY. DELETE before delivery.
;Triggered by the DEBUGGERR-guarded hook in the 会話 handler.
;Sets state internally (no console typing), CALLs bodies across
;tiers, prints delimiter + [[TID]] markers, restores state.
;============================================================
@M_KOJO_K{id}_AUTOTEST
#DIM sav, 16
;--- save mutated slots ---
sav:0 = TALENT:{id}:恋人
sav:1 = TALENT:{id}:愛欲
sav:2 = TALENT:{id}:炮友
sav:3 = TALENT:{id}:恋慕
sav:4 = TALENT:{id}:思慕
sav:5 = CFLAG:{id}:面識
sav:6 = FLAG:時間停止

TARGET = {id}
CFLAG:{id}:面識 = 1
FLAG:時間停止 = 0

PRINTL =====AUTOTEST_K{id}_BEGIN=====

;--- one tier, one bracketed CALL ---
PRINTL [[TID K{id}_300_neutral BEGIN]]
CALL AT_CLEAR_TIERS_K{id}
CALL M_KOJO_MESSAGE_COM_K{id}_300_1
PRINTL [[TID K{id}_300_neutral OK]]

PRINTL [[TID K{id}_300_恋人 BEGIN]]
CALL AT_CLEAR_TIERS_K{id}
TALENT:{id}:恋人 = 1
CALL M_KOJO_MESSAGE_COM_K{id}_300_1
PRINTL [[TID K{id}_300_恋人 OK]]
; … repeat per tier / per command …

;--- restore ---
TALENT:{id}:恋人 = sav:0
TALENT:{id}:愛欲 = sav:1
TALENT:{id}:炮友 = sav:2
TALENT:{id}:恋慕 = sav:3
TALENT:{id}:思慕 = sav:4
CFLAG:{id}:面識 = sav:5
FLAG:時間停止 = sav:6
DEBUGGERR = 1              ; fire once per enable

PRINTL =====AUTOTEST_K{id}_END=====
PRINTW [AUTOTEST] done — state restored — click to return
RETURN 1

;--- helper: zero all relationship tiers ---
@AT_CLEAR_TIERS_K{id}
TALENT:{id}:恋人 = 0
TALENT:{id}:愛欲 = 0
TALENT:{id}:炮友 = 0
TALENT:{id}:恋慕 = 0
TALENT:{id}:思慕 = 0
RETURN 1
```

**Rules that make the battery correct:**

- **CALL the `_1` body directly** (`@M_KOJO_MESSAGE_COM_K{id}_300_1`), *not* the wrapper `_300` — the wrapper `CALL`s `TRAIN_MESSAGE` (advances/consumes a turn) and would recurse into the hook. The `_1` body is pure dialogue.
- **Verify every label and slot name against the actual kojo before writing** — a wrong `CALL` target or a non-existent slot *halts* the whole battery. (This is also how the battery catches the kojo's own mistakes: a bad label → halt → that branch is `测试失败`.)
- **Each dialogue branch already ends in `PRINTFORMW`**, so the screen holds at each step and the transcript captures every chunk. You usually don't need to add your own waits.
- **Save→mutate→restore is mandatory** so the loaded save isn't left altered. Running the test also consumes one in-game turn via the command — harmless as long as the user doesn't save; still, always work from a backed-up save.
- **State-injection slots** (verified working as plain assignments): `CFLAG:{id}:好感度`, `CFLAG:{id}:面識`, `ABL:{id}:親密`, `ABL:{id}:従順`, `TALENT:{id}:恋慕/恋人/愛欲/炮友/思慕`, `TCVAR:{id}:発情`, `FLAG:時間停止` (=`FLAG:70`), `MONEY`. (No per-character `信頼`/trust slot exists in this fork — use 好感度/親密/従順.)

---

## 11.6 Capture — the clipboard transcript (`tools/clip_tap.ps1`)

Emuera auto-copies newly-displayed text to the Windows clipboard (config `表示したテキストをクリップボードにコピーする:YES`, `新しい行のみコピーする:YES`). `tools/clip_tap.ps1` polls the clipboard and appends every change to a log file — a **live transcript** you can `Read`.

- **Single-instance guarded** (named mutex): a second copy exits immediately. If you ever see duplicated, same-timestamp blocks, a stray instance is running — kill all `clip_tap.ps1` processes (excluding your own shell) and relaunch one.
- **Read with `-Encoding UTF8`.** ASCII markers (`=====`, `[[TID …]]`) are safe to grep; CJK needs the encoding flag.
- **`emuera.log` is halt-only** — written on compile error / runtime halt, *not* rewritten on a clean run. Never read it as a "success" signal; use the transcript. Clear it before each launch so a stale error doesn't mislead you.
- Static screens copy nothing — the transcript only grows when new text prints (i.e. as the user clicks through).

Typical launch (Claude Code side; the user does the in-game steps):

```powershell
cd "<game root>"
Remove-Item lazyloading.dat,emuera.log,<log>.txt -ErrorAction SilentlyContinue   # clear stale cache+log
$p = Start-Process ".\Emuera_lazyloading_for_developer.exe" -ArgumentList "-Debug" -PassThru
Start-Process powershell -WindowStyle Hidden -ArgumentList @(
  "-STA","-ExecutionPolicy","Bypass","-File",".\learning\eratw-skill\tools\clip_tap.ps1",
  "-LogFile",".\<log>.txt","-WatchPid",$p.Id,"-IntervalMs","300")
```

`clip_tap.ps1` stops when the watched game PID exits (or via `-StopFile` / `-MaxSeconds`).

> ### ⚠️ `lazyloading.dat` — delete it after adding ANY new label (root cause of "my new command/derived kojo does nothing in-game")
> `lazyloading.dat` is the engine's **symbol index**: "label X lives in file Y". With `USELAZYLOADING:YES` (player default) the engine consults this cache to lazy-load only the files it needs. The trap that bites hardest:
> - **A NEWLY-ADDED label** (a new `@M_KOJO_MESSAGE_COM_K{id}_NNN`, a new `_SCOM_`, a new event handler) is **not in the stale index** → the engine believes it doesn't exist → `TRYCALLFORM` silently falls through to the engine's generic narration. The player sees the **command's default text but none of your kojo lines** — exactly the "banner shows, my dialogue doesn't" symptom.
> - **An EDIT to an EXISTING label's body** usually DOES take effect (the label is already indexed, so when the file lazy-loads the engine reads the current bytes). This asymmetry is why you can see a diary's *rewritten text* fine while a *newly-added* 304/掏耳朵 label appears dead — and it makes the bug very confusing if you don't know the rule.
> **Fix: delete `lazyloading.dat` before launching whenever you added labels this session.** The engine rebuilds it (full scan) on next start. The launcher (`start_pipeline.ps1`) now deletes it automatically on every run; a *manual* exe launch does not, so delete it by hand. Symptom-first rule of thumb: **new label + "does nothing in game" + no compile error ⇒ stale `lazyloading.dat` first, before you touch the code.**

---

## 11.7 Status flags + the scriptable test-id convention

**Per-dialogue status flag** — a single `;`-comment tag on each dialogue branch, in Chinese (minimal, clear):

| Flag | Meaning |
|---|---|
| `待自动测试` | generated; will be covered by the autotest battery |
| `待手动测试` | needs real play (events / danmaku / sex-scene / context-driven); the battery can only *smoke-test* it |
| `测试通过` | passed — by the battery, or seen during integration play |
| `测试失败` | the battery reached it and the game halted/errored here → needs fixing |

No separate "smoke" or "random" flag: event labels stay `待手动测试` (the battery smoke-CALLs them only to catch crashes → `测试失败` on halt); RAND branches just accrue `测试通过` line-by-line as each variant actually appears over several runs.

**Whose job is the flag:** the AI classifies `待自动测试` vs `待手动测试` when it *writes* each line. The smoke test is the backstop — an "auto" line that secretly needs context will crash and surface as `测试失败`.

**Scriptable correlation (so flag updates cost no tokens):**

- Tag each testable branch in the kojo with a stable id comment: `;@TID K{id}_300_恋人`.
- The battery brackets each exercised branch: `PRINTL [[TID <id> BEGIN]]` … CALL … `PRINTL [[TID <id> OK]]`.
- A script reads the transcript and rewrites the `;@AT <status> <id>` line in the source (`tools/at_update.ps1`). Verdict is **END-sentinel gated** so a clipboard-dropped `OK` does not cause a false failure:
  - **END sentinel (`=====AUTOTEST_K{id}_END=====`) present** → the battery ran to completion, no halt → **every TID that printed a `BEGIN` = `测试通过`**, even if its `OK` was lost at a screen boundary.
  - **END sentinel absent** → execution halted → the culprit is the block whose `BEGIN` is the **last marker in the log** (nothing ran after it) = `测试失败`; every earlier `BEGIN` has a later marker so it completed = `测试通过`.
  - **TID absent from log** → leave as-is.
  - Why not "BEGIN alone = pass": `BEGIN` is printed *before* the `CALL`, so a body that halts still shows its `BEGIN`. The END-sentinel / later-marker check is what actually proves the body ran — that's the one thing the battery exists to verify.
- **Self-locating:** the battery's first output line is `PRINTL [[KOJODIR <path-relative-to-game-root>]]` (the author hardcodes the path when writing the harness). `at_update.ps1` reads that line and resolves the kojo folder against `-GameRoot`, so it needs **no `-KojoDir`** — pass one only to override. This is how the one-click launcher figures out which folder to edit without asking the user to type a path (it just shows the detected folder for confirmation).

---

## 11.8 Manual-test coverage — the `[[MT]]` marker method (replaces signature-matching)

The battery can't reach event/danmaku/約会/context dialogue — those only fire in real play. Instead of trying to *recognise* each line's text in the transcript (fragile: interpolation, RAND, duplicate text), **make each branch announce itself**:

**At kojo-authoring time**, directly under every `;@AT 待手动测试 <TID>` tag, add a **guarded** machine marker containing the TID — a `SIF K{id}_MT_ON()` line immediately followed by the `PRINTL [[MT <TID>]]` line:

```erb
		;@AT 待手动测试 K6_EV1_今日首问候
		SIF K6_MT_ON()
		PRINTL [[MT K6_EV1_今日首问候]]
		IF TALENT:6:恋人
			PRINTFORMW 「啊，……今天，还是第一次见你呢。」
		...
```

- The marker is a plain `PRINTL` so it prints whenever that branch actually runs in-game → it lands in cliplog.

#### The `@K{id}_MT_ON()` master switch (guards ALL markers)

Every `[[MT]]` marker is gated by **one** per-character function, defined once in the kojo's function-library file:

```erb
;===== 手动测试标记总开关（[[MT]] 守护开关）=====
;开发/测试期 = 1：所有 PRINTL [[MT ...]] 标记正常打印，供实录抓取。
;正式发布前 = 0：AI 汇报覆盖率后改成 0，全部标记一处静默，普通玩家永不可见。
@K6_MT_ON()
#FUNCTION
RETURNF 1
```

Why this matters (it changes the delivery model):

- **Dev/test = `1`**: markers print naturally as the player triggers each branch; cliplog captures them; `manual_scan.ps1` counts them.
- **Release = `0`** (flip the single `RETURNF`): every marker in every file goes silent at once. A player NEVER sees `[[MT …]]`, even for branches that were never tested.
- **This decouples "marker in source" from "marker visible to players."** Some branches are genuinely hard to reach (rare events, weather/time-gated, R18-gated) but harmless. Previously the only ways to make them player-safe were to test them or delete the marker. Now the user can **ship with the marker still present, just silenced** — useful when they want to publish now and polish later.
- **Release-time AI flow** (the point of the switch):
  1. Count TIDs still tagged `;@AT 待手动测试` or `;@AT 测试失败` (these are the untested/failed manual branches) and report them to the user by name.
  2. Ask: **flip `@K{id}_MT_ON()` to `RETURNF 0`?** (makes all markers player-invisible in one edit).
  3. Ask whether any *dangerous* still-untested branch should be temporarily `[SKIPSTART]/[SKIPEND]`-commented until it's been verified (safe-but-untested branches can just ride along, silenced).
  This guarantees the user knows exactly what has and hasn't been exercised before they publish, and the flip is one line, fully reversible.

- **`SIF` + `PRINTL` must stay adjacent** (guard line directly above the marker line). `manual_scan.ps1 -Apply` is guard-aware — when a branch passes and its marker line is deleted, the `SIF K{id}_MT_ON()` line right above it is deleted too, so you never get an orphan `SIF` swallowing the following real dialogue line.
- **TID must start with `K<id>_`** (e.g. `K6_…`) so the char is readable from the marker alone.
- **Format is load-bearing** — both the tag line and the marker line must be *single-line, exact-format*, because `manual_scan.ps1 -Apply` edits them programmatically. The two canonical single-line forms:
  - `<indent>;@AT 待手动测试 <TID>`
  - `<indent>PRINTL [[MT <TID>]]`
  Anything off-format is skipped (safe), but never split these across lines or reformat them.

**`tools/manual_scan.ps1`** then:
- **Scan** (default): greps cliplog for every `[[MT <TID>]]`, dedups, reports which branches were triggered (and to which characters, from the `K<id>_` prefix). Optionally `-OutFile` to write the list.
- **Apply** (`-Apply -KojoDir <dir>`): for each triggered TID, rewrite `;@AT 待手动测试 <TID>` → `;@AT 测试通过 <TID>` **and delete** the `PRINTL [[MT <TID>]]` line **plus the `SIF K{id}_MT_ON()` guard line directly above it** — turning a tested branch back into clean, marker-free source with no orphan guard. UTF-8 BOM + CRLF preserved. (Only exact-format lines are touched; validated surgical.)

A passed branch loses its marker+guard the moment it's confirmed 测试通过. Branches that **remain** untested keep their guarded marker — and that is now **safe to ship** as long as `@K{id}_MT_ON()` is flipped to `RETURNF 0` at release (markers stay in source but never print). So "no `[[MT]]` in source" is no longer a hard delivery gate; "`@K{id}_MT_ON()` returns 0" is. You may still choose to delete all remaining markers for a truly clean release — both are acceptable.

> **Tell the user this (it looks alarming otherwise):** while manual-testing, seeing a line like `[[MT K6_EV1_今日首问候]]` pop up right before a piece of dialogue is **normal and expected** — it's the test marker doing its job, and it will be auto-removed once that dialogue is marked as passed.

---

## 11.9 Safety rules — never break the player's game

> **两种交付语境别混淆。** 下面的"发布前删脚手架"规则针对**面向玩家发布可游玩的口上**。若某份口上是**随 SKILL 发布的教学范例**（如 `reference-kojo/luna-K6/`），则可以**有意保留** AUTOTEST 测试套件 + `[[MT]]` 标记 + `@K{id}_MT_ON()` 开关，作为方法论的正面示范——但**必须在该口上的 README（或其它 AI 会读到的地方）写明"这是刻意保留的参考、不是没清理干净"**，并说明玩家向发布时应如何清理。别让读者把教学范例里的脚手架误当成必须删的残留。

1. **Disarm before delivery — blocking.** Comment out the 3-line hook *and* delete `M_KOJO_K{id}_AUTOTEST.ERB` before handing the kojo back. With the default-armed (`IF !DEBUGGERR`) design a shipped hook fires for every player. Merely resetting the flag is not enough — remove the code. (The AUTOTEST arm flag `CFLAG:{id}:1099` defaults to 0 = never-fires, so a stray hook is *inert* on a fresh player save, but still remove it.)
1b. **Silence manual-test markers before delivery — blocking.** Flip `@K{id}_MT_ON()` to `RETURNF 0` (one edit) so no `[[MT …]]` prints for players. Unlike the AUTOTEST hook, guarded markers left in source are harmless *once the switch is 0* — you don't have to delete them. First **report** to the user which manual TIDs are still `待手动测试`/`测试失败` (§11.8), so the flip is an informed decision, not a silent one.
2. **Back up saves.** Autosave writes `save99.sav`; day-advance and new-game overwrite it. Copy `sav/` before testing, restore after. Verify with a hash if the user is anxious.
3. **Restore all mutated state** in the battery (save→mutate→restore), and reset any config you changed (e.g. if you ever set `USELAZYLOADING:NO`, restore `YES`).
4. **Guard everything behind the flag** so normal play is untouched while the harness is present.
5. **Keep files UTF-8 with BOM.** The battery uses CJK *identifiers* (`TALENT:{id}:恋人`, `FLAG:時間停止`); without BOM they won't match the CSV slot names. `Write`/`Edit` tools strip BOM — re-apply it after every write (see references/10).

---

## 11.10 Fidelity + coverage (set expectations honestly)

- **The battery is a UNIT test of label *bodies*** — it confirms each branch compiles, its guard selects it, and it prints without halting under the state you set. It does **not** test dispatch *timing* (EVENT firing per cell-transition, GRAVITY/MARKCNG over-firing — SKILL §1 pitfalls #4/#5/#7). Those still need real play or reading the dispatch. "Autotest passes" ≠ "correct in play."
- **RAND branches are non-deterministic:** "pass" means the branch was reached without error, not byte-identical output. Coverage of RAND siblings accrues over several runs.
- **Rough coverage** (varies by character; event-heavy characters skew lower): ~45–55% of dialogue is cleanly autotestable (daily commands, harassment, diary, encounter/color), ~10% partial (sex/counter/mark/orgasm — need session context), ~40–45% needs real play (the events file + danmaku). Report which is which so the user knows what to cover by hand.

---

## 11.11 Division of labor

- **The user drives all in-game GUI**: loads a save, opens the debug console (`调试(D)` → `打开调试窗口` → `控制台`), types the arm command `CFLAG:{id}:1099 = 1`, selects commands, clicks through dialogue.
- **You (Claude Code) do**: launch the exe, run/read `clip_tap`, read `emuera.log`, edit the kojo + harness, back up/restore saves, run the flag-updater.
- **PIDs are session-specific** — always re-enumerate `Get-Process Emuera*` and confirm with the user before killing anything (never kill the user's own game instance).

---

## 11.12 One-click launcher for chat users (`run_eratw_test.bat`)

For users who don't have Claude Code driving their machine, the SKILL ships a double-click launcher at the SKILL top level: **`run_eratw_test.bat`** → runs `start_pipeline.ps1`. It makes the whole capture pipeline runnable by a non-technical user.

**What it does, in order:**
1. Auto-locates the game root (searches upward from the SKILL folder for the Emuera exe).
2. Menu: **[1] developer(debug)** — for AUTOTEST (has the Debug menu) — or **[2] player** — the normal game, for manual testing.
3. **Warns first**, then (on confirm) kills any leftover `clip_tap` + previous game, archives the old `cliplog.txt`, **and deletes `lazyloading.dat` + `emuera.log`** (so newly-added labels are re-indexed — see the ⚠️ callout in §11.6; skipping this is why freshly-added commands/derived kojo appear dead in-game).
4. Launches the chosen game and a **hidden** `clip_tap` writing to `<skill>/cliplog.txt`.
5. Shows an explanation panel, then a **live monitor** (last 10 lines of cliplog, refreshed every 2 s). It continuously extracts any AUTOTEST block into **`<skill>/test_result.txt`**.
6. When the user **closes the game**, it: finalizes `test_result.txt` (AUTOTEST block + the deduped list of `[[MT]]` manual markers seen), reports counts, then runs **two write-back offers**, each confirming the target folder before touching anything:
   - **AUTOTEST** — if an AUTOTEST block is present, it reads the block's `[[KOJODIR]]` line to auto-detect the kojo folder, shows it for confirmation, and runs `at_update.ps1` (`;@AT` → 测试通过/测试失败). If there's no AUTOTEST block it says so and skips. When every branch passed, it then **offers to comment out the trigger hook** (`disarm_autotest.ps1`) so 会話 won't fire the test again — reversible with `-Rearm`.
   - **Manual** — locates the folder(s) that actually contain the `[[MT]]` markers (by char id), asks the user to confirm each, and runs `manual_scan.ps1 -Apply` (`;@AT 待手动测试` → 测试通过 and deletes the `[[MT]]` line + its `SIF K{id}_MT_ON()` guard line).

   The launcher is the single entry point: it drives `clip_tap`, `manual_scan`, and `at_update` for the user — they never run the sub-scripts by hand.

**`test_result.txt`** is the single small file a chat user hands to the AI for review (it holds both the AUTOTEST transcript and the manual-test hit list).

**When guiding a chat user, the AI must explain:**
- **What the launcher is for** — it starts the game + a background recorder so their dialogue gets captured automatically; they never copy/paste logs by hand.
- **Which button** — developer(debug) to run AUTOTEST; player for manual play. Dev's debug console is a tiny window with **no size setting** — drag the bottom-right corner to enlarge; input line is at the very bottom (nudge past the "总在最前面/always-on-top" button).
- **AUTOTEST arming** — the guard defaults to **never fire** (arm flag `CFLAG:{id}:1099 == 0`). To run the battery, type `CFLAG:{id}:1099 = 1` in the debug console, then click 会話. It fires once and sets the flag to `2`; to run again, type `CFLAG:{id}:1099 = 1` once more.
- **`[[MT …]]` markers are normal** — during manual testing a line like `[[MT K6_EV1_今日首问候]]` will appear right before some dialogue; that's the expected test marker, not a bug, and it's auto-removed once the branch is confirmed passed.
- **Keep the console window open** until they close the game, so the post-game scan runs.

The launcher and all markers/harness are **development-only** — same delivery rule as §11.9: before shipping a kojo, the AUTOTEST hook + `AUTOTEST.ERB` are removed, and `@K{id}_MT_ON()` is flipped to `RETURNF 0` (guarded `[[MT]]` markers may then stay in source, silenced; or be deleted).

---

## 11.14 一键 arm：哨兵文件 + FLAGSETTING 钩子（让启动器开关 autotest，免去调试台打字）

手动在调试台敲 `CFLAG:{id}:1099 = 1` 很烦。更顺手的办法：**让启动器（bat）在启动前用一个哨兵文件 arm 自动测试**。机制（已实测方案，Emuera 无法从命令行/config 设变量、也没有启动 autoexec，故走哨兵文件）：

1. **哨兵文件放在口上目录里**，用**文件名**编码状态（因 `EXISTFILE` 只能判存在、读不了内容）：`autotest.on`＝启用 / `autotest.off`＝禁用。它同时是「本口上是本 skill 写的、且带自动测试」的**发现标记**。写口上时默认放一个 `autotest.off`。
2. **口上的 `@M_KOJO_FLAGSETTING_K{id}`**（引擎会替每个角色调用它）里加一段（临时脚手架，交付玩家版前删）：
   ```erb
   ;哨兵在则 arm。`!= 2` 是承重守卫、【不可省】，理由见下方 ⚠。路径相对游戏根、写死本口上目录。
   IF CFLAG:{id}:1099 != 2 && EXISTFILE("ERB/…/個人口上/<角色目录>/autotest.on")
       CFLAG:{id}:1099 = 1
   ENDIF
   ```
   `EXISTFILE` 路径相对游戏根（Emuera 工作目录）；把本口上目录的相对路径写死即可（与 AUTOTEST 测试套件首行 `[[KOJODIR …]]` 同一路径）。玩家没有 `autotest.on` 文件时整段无副作用。

   > ### ⚠ FLAGSETTING 不是「读档时调一次」——它被调用得非常频繁
   > 本 fork 实测有**两个**调用点，都是 `FOR LOCAL,1,CHARANUM` 逐角色调用：
   > - `ERB\SYSTEM.ERB:75` `@EVENTLOAD` —— 读档时调用；
   > - `ERB\ステータス表示関連\INFO.ERB:922` `@INFO_RENEW_TARGET` —— **每次刷新目标/状态信息时**都调用。
   >
   > 所以 **FLAGSETTING 里绝不能写「每执行一次就产生一次副作用」的代码**，放进去的东西必须幂等。
   > 落到 arm 钩子上：`!= 2` 就是那道承重守卫——**去掉它**，测试套件跑完把待命位置 2 之后，下一次信息刷新又会把它打回 1，于是**每点一次「会話」就重跑一整轮测试套件**，没完没了。
   > 随之而来的代价（可接受）：哨兵只能让**还没跑过**的存档待命。同一存档想再跑一轮，仍需调试台输 `CFLAG:{id}:1099 = 1`，或换一个没跑过的存档。
3. **启动器**启动前 `Get-ChildItem 個人口上 -Recurse` 扫 `autotest.on|autotest.off` → 列出所有本 skill 口上及当前状态 → 问玩家「全部启用/全部禁用/保持」→ 在 `.on`↔`.off` 间 `Rename-Item`。（本项目 `start_pipeline.ps1` 已实装。）
4. 玩家读档进游戏、跟该角色**会話**一次 → FLAGSETTING 已把待命位置 1 → 测试套件触发。**全程不用在调试台打字**（前提是该存档还没跑过，见上方 ⚠）。**游戏结束后的回写环节不受影响，保持原样**。

> 为什么走命令行/config/存档都不行：Emuera 唯一命令行开关是 `-Debug`（无「设变量/跑命令」参数）；`emuera.config` 无启动执行项；存档是二进制、外改高危。哨兵文件 + FLAGSETTING（普通用户函数、lazyload 安全、每次读档必调）是唯一干净落点。

## 11.15 纯冒烟 TID（没有台词分支的测试项）：把 `;@AT` 标签写在测试套件里

`at_update.ps1` 收尾可能报：

```
WARN: TIDs in log with no source ;@AT tag: K6_COLOR
```

含义：日志里出现了 `[[TID X …]]`，但**整个口上目录的 `.ERB` 里找不到对应的 `;@AT … X` 标签**——这个 TID 没有「写作承诺」当归宿。两种成因：

1. **真写漏了**：改了 TID 名却没同步改标签、或忘了给分支打标签 → 去补，这正是这条警告的价值。
2. **纯冒烟测试**：这个测试项压根没有台词分支可挂标签。典型＝`M_KOJO_COLOR_K{id}`（只设颜色，`CALL` 一下确认不崩）。

第 2 种的约定：**把 `;@AT` 标签写在测试套件里、紧挨 `[[TID … BEGIN]]` 之上**。`at_update.ps1` 扫的是整个口上目录的 `.ERB`（含 `AUTOTEST.ERB`），所以它照样认得，状态也照常回写——**工具一行都不用改**：

```erb
;--- COLOR（无台词，仅应用颜色）---
;纯冒烟测试：没有台词分支可挂标签，故标签写在这里
;@AT 待自动测试 K{id}_COLOR
PRINTL [[TID K{id}_COLOR BEGIN]]
CALL M_KOJO_COLOR_K{id}
RESETCOLOR
PRINTL [[TID K{id}_COLOR OK]]
```

> 不要用「忽略这条警告」来对付第 2 种——警告一旦有了习惯性噪声，第 1 种（真写漏）就会被一起忽略掉。

## 11.13 The battery only tests what you wired into it — cross-check `待自动测试`, and prune passed ones (AI's job, not the launcher's)

> ### ⭐原则：能自动测试的，尽量当场就接进测试套件——别默认丢给手动测试
> **手动测试极耗用户时间**（要真去游戏里一个个触发场景、点过对话）。所以写一个分支时，**先判断它能不能靠状态注入自动测试**：凡是分支只依赖可注入的状态（`TFLAG:193` 成败、`TALENT:*` 关系、`CFLAG:*:好感度`、`BASE:*:酒気`、`Activity_Type:*`、直接 `CALL` 事件/派生/日记 body 等），就应当**标 `待自动测试` 并在同一轮把 `[[TID]]` 块加进测试套件**，而不是图省事标 `待手动测试`。
> - **真正只能手动**的才标 `待手动测试`：交互菜单（body 里 `CALL ASK_YN`/`ASK_M` 会停下等玩家点击，测试套件答不了）、强依赖具体房间/地图/在场角色且难注入的、需要真实约会/事件时序的。
> - **工作量大、这轮来不及全部接线时**：至少**在代码里留 TODO**——保留 `;@AT 待自动测试 <TID>` 标签本身就是待接线的 TODO（§11.13 的 grep 交叉核对会把它挑出来），可再加一行 `;TODO: 待接入 AUTOTEST 测试套件` 提醒。**绝不要**把一个明明能自动测的分支标成 `待手动测试` 就了事——那等于把成本转嫁给用户。
> - 判据一句话：**这个分支的所有触发条件，我能不能在测试套件里用几行赋值凑出来、然后直接 `CALL` 它的 body？** 能，就自动测。



"AUTOTEST all-green" is a narrower claim than it sounds. It means **only** that the branches the battery actually `CALL`s ran without halting under the state it set. It says **nothing** about branches you *tagged* `;@AT 待自动测试` but never added a `[[TID … BEGIN]]` block for in `@M_KOJO_K{id}_AUTOTEST`. These two lists drift apart because they're written at different times: the `;@AT 待自动测试` tag is a promise made **while authoring the branch**; the battery entry is added **later, by hand**. It's easy to tag ten branches and wire only seven — and a green run then reads as "all tested" when three were never exercised. This is a front/back inconsistency bug, not a test result.

**So during testing the AI must actively reconcile the two sets** (the launcher/`at_update.ps1` will NOT do this — they only flip `;@AT` status for TIDs that appear in the transcript):

1. **List the promised set** — every `;@AT 待自动测试 <TID>` across the kojo folder:
   `grep -rho ';@AT 待自动测试 K[0-9]*_[^ ]*' *.ERB | sort -u`
2. **List the wired set** — every TID the battery brackets:
   `grep -ho '\[\[TID \(K[0-9]*_[^ ]*\) BEGIN\]\]' M_KOJO_K{id}_AUTOTEST.ERB | sort -u`
3. **Diff.** Promised-but-not-wired = coverage holes → **add a `[[TID … BEGIN]]` … CALL … `[[TID … OK]]` block to the battery** for each (set up the state that branch needs, CALL the `_1` body). Wired-but-not-promised = usually a stale/renamed TID → fix or drop.
4. **Report the holes to the user** before declaring the autotest pass meaningful — "battery green, but N tagged branches aren't wired in; I've added them / they still need wiring."

**Pruning (de-registration).** Once a battery-exercised branch is confirmed `测试通过`, its `[[TID]]` block can be **removed from `@M_KOJO_K{id}_AUTOTEST`** to keep the battery focused on what's still unverified (mirrors how a passed `[[MT]]` marker is removed). This trimming is the **AI's** call and edit — the launcher/`at_update.ps1` never touch the battery body, only the `;@AT` tags in the kojo. Don't prune reflexively: keep a branch wired if it's cheap and you want it as a permanent regression smoke-test; prune when the battery has grown noisy and re-runs are slow. Either way, the `;@AT 测试通过` tag in the source is the durable record that it passed — the battery entry is optional after that.