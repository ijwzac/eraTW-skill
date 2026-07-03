# 11 — Autotest pipeline (semi-automated kojo testing)

> **STATUS: DRAFT — not yet validated end-to-end. NOT wired into SKILL.md's read-path.**
> Proven on Merlin K21: clip_tap capture, the 会話-hook trigger, the state-injecting battery, fire-once, the three dead-ends (§11.2), the `DEBUGGERR` nature, BOM/lazy-cache handling, the clip_tap single-instance fix.
> **Not yet validated (design only):** the *flipped* guard (`IF !DEBUGGERR` + reset) — only the un-flipped form was tested; the `;@TID` + `[[BEGIN]]/[[OK]]` marker convention; applying the flag taxonomy to real source; the flag-updater script; the integration-test monitor (§11.8); a comprehensive battery + event smoke-tests.
> **Plan:** validate the whole pipeline on the next kojo (Luna Child K6) as a real trial, fix what breaks, then fold the validated version into SKILL.md. Do not treat the unvalidated parts as ground truth until then.

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

**Direction chosen for this project: fire when `DEBUGGERR == 0`, and the battery sets it to `1` at the end** — so the test auto-fires on the first 会話 of a dev session (no arming), then stops re-firing. To run again, set `DEBUGGERR = 0` in the console.

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

`clip_tap.ps1` stops when the watched game PID exits (or via `-StopFile` / `-MaxSeconds`). Delete `lazyloading.dat` whenever you edit a kojo file — it's a **stale cache** that won't reflect edits otherwise.

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
- A script reads the transcript: **`BEGIN`+`OK` → `测试通过`; `BEGIN` with no `OK` → `测试失败`** (an Emuera halt stops the run, so the last un-`OK`'d id is the culprit — robust); **absent → leave as-is**. It then rewrites the `;@TID <id>` line's status flag in the source.

---

## 11.8 Integration-test mode (cover the `待手动测试` lines by playing)

The battery can't faithfully reach event/danmaku/context dialogue. For those, the user just *plays*, and the transcript tool watches for them:

- The tool loads the kojo files, collects every `待手动测试` line (by `;@TID`), and extracts a **signature** — the longest *literal* substring of that line's `PRINTFORM…` (skipping `%…%` / `{…}` interpolation and `\@…\@` escapes).
- While the user plays, whenever a clipboard chunk contains a signature, the tool marks that id `测试通过` (it was genuinely seen in real play).
- **Limitation:** fully-dynamic lines (no stable literal) or two lines sharing identical text can't be uniquely matched — flag those "ambiguous, verify by hand." Good tagging (distinct literals) makes this reliable.

(clip_tap is the base; the flag-updater and the integration-matcher are built per project as small scripts around the same transcript.)

---

## 11.9 Safety rules — never break the player's game

1. **Disarm before delivery — blocking.** Comment out the 3-line hook *and* delete `M_KOJO_K{id}_AUTOTEST.ERB` before handing the kojo back. With the default-armed (`IF !DEBUGGERR`) design a shipped hook fires for every player. Merely resetting the flag is not enough — remove the code.
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

- **The user drives all in-game GUI**: loads a save, opens the debug console (`调试(D)` → `打开调试窗口` → `控制台`), types `DEBUGGERR = 0/1`, selects commands, clicks through dialogue.
- **You (Claude Code) do**: launch the exe, run/read `clip_tap`, read `emuera.log`, edit the kojo + harness, back up/restore saves, run the flag-updater.
- **PIDs are session-specific** — always re-enumerate `Get-Process Emuera*` and confirm with the user before killing anything (never kill the user's own game instance).