# HANDOFF — eraTW autotest-pipeline investigation

**Date:** 2026-06-15. **Context:** building an automated test pipeline so an AI session can verify an eraTW kojo by driving the game, with minimal user effort. This is exploratory work, NOT yet folded into the skill. The skill itself lives at `learning/eratw-skill/` (SKILL.md + references/ + reference-kojo/).

---

## The goal

Let an AI session: write a kojo → write an autotest → launch the game in debug → trigger the autotest → read the game's output → diagnose/iterate. Ideally unattended (user only grants permission to launch).

Test subject this session: **Merlin K21** kojo (`ERB/口上・メッセージ関連/個人口上/021 Merlin [メルラン]/メルラン/`), written by another Claude session.

---

## CURRENT STATUS (where we are right now)

- Harness file `…/021 Merlin [メルラン]/メルラン/M_KOJO_K21_AUTOTEST.ERB` is currently in **`@EVENTLOAD` form** (fires after loading a save; guarded by `SIF !DEBUGGERR / RETURN`).
- **NEXT STEP we were about to do:** disable lazy loading, relaunch, have user load a save → harness should auto-run. Specifically:
  1. Back up `emuera.config` → `emuera.config.autotest_bak`.
  2. Edit `emuera.config`: `USELAZYLOADING:YES` → `USELAZYLOADING:NO` (event-function files are excluded under lazy loading; `@EVENTLOAD` is an event function, so it won't load otherwise).
  3. Delete `lazyloading.dat`, kill my Emuera instances (NOT the user's PID 29808), relaunch `Emuera_lazyloading_for_developer.exe -Debug`, start clip_tap.
  4. Check `emuera.log` clean + `@EVENTLOAD` harness loaded (not excluded, since lazy now off).
  5. User loads a save → `@EVENTLOAD` fires → harness CALLs Merlin labels → clip_tap captures `=====AUTOTEST_K21_BEGIN=====` … `=====AUTOTEST_K21_END=====`.
  6. After: **restore `emuera.config` from backup** (so user's normal play stays fast).
- A game instance (was PID 24032) and a clip_tap powershell may still be running — check and kill leftovers (keep user's 29808).

---

## THE KEY ARCHITECTURE FINDINGS (hard-won, all empirically verified)

### Capture pipeline — WORKS ✅
- **clip_tap** (`learning/eratw-skill/tools/clip_tap.ps1`) polls the Windows clipboard and appends changed text to a log file → AI reads it. **This is the real-time transcript.** Validated: it captured title screen, new-game text, and debug-console output live.
- Emuera auto-copies **newly-displayed** text to the clipboard (`表示したテキストをクリップボードにコピーする:YES`, `新しい行のみコピーする:YES`, ~800ms, 25-line cap). So clip_tap only sees text when something new prints (nothing at a static screen).
- **Console output → main game window → clipboard → clip_tap.** Proven with `PRINTL AUTOTEST_PING_123`.
- Two channels, distinct roles:
  - **`emuera.log`** = compile/load errors + halts ONLY. **Write-on-halt** — a *successful* load does NOT rewrite it (it keeps the previous error!). Don't read it as a success signal. Clear it before each launch.
  - **clip_tap** = live runtime text.
- `debug/console.log` also holds the load-time warnings.

### Launch — WORKS ✅
- `Start-Process .\Emuera_lazyloading_for_developer.exe -ArgumentList "-Debug"` → window title shows "(Debug Mode)". `-Debug` is REQUIRED for debug features (`DEBUGGERR==1`, debug console).
- Multi-instance allowed (`多重起動を許可する:YES`); the user's own game (PID 29808 this session) runs alongside — never kill it.

### Debug console — partial; CANNOT trigger a kojo harness ❌
- Opened via menu `调试(D)` → `打开调试窗口` → `控制台` tab (needs `-Debug`).
- **CAN:** variable assignments (state injection / cheating), expressions, and invoking a `#FUNCTION` as an expression. Output goes to the main window → clip_tap.
- **CANNOT:** flow-control commands — `CALL`/`IF`/`GOTO` → error `不能使用流程控制类命令`.
- A `#FUNCTION` is console-callable BUT **a `#FUNCTION` body cannot contain `CALL`** → error `CALL命令中不能使用#FUNCTION(S)`. So a #FUNCTION can't invoke the kojo's procedure-labels.
- **Conclusion: the console is a great CHEAT/STATE tool but cannot trigger a harness that CALLs kojo labels.** The trigger must come from a real procedure context (event hook or in-game command).
- Integer interpolation uses `{expr}`; string interpolation uses `%expr%` (e.g. `{KOJO()}` for int-returning, `%K21_GREETING()%` for string).

### Lazy loading — excludes event-function files ❌ (critical)
- With `USELAZYLOADING:YES` (default), any file containing an **event function** (`@EVENTFIRST`, `@EVENTLOAD`, `@EVENTTRAIN`, etc.) is **NOT loaded** — log says `…ERB has event function EVENTFIRST, file excluded.` (Confirmed: harness with `@EVENTFIRST` never ran.)
- So **event-hook auto-run harnesses require `USELAZYLOADING:NO`** (full load ~4.5s — totally acceptable).
- Auto-run hooks that exist in the engine: `@EVENTFIRST` (new-game start), **`@EVENTLOAD` (after loading a save)**, `@EVENTEND`, `@EVENTCOMEND`. `@EVENTLOAD` is the best (load = realistic state + minimal clicks).

### State injection (cheating) — WORKS ✅ (verified slot names)
Plain assignments in the debug console, character index = 21 (Merlin). Read back with `PRINTFORML x={CFLAG:21:好感度}`:
```
CFLAG:21:好感度 = 1000        ; affection
ABL:21:親密 = 5               ; intimacy
ABL:21:従順 = 5               ; obedience
CFLAG:21:面識 = 1             ; acquainted
TALENT:21:恋慕 = 1            ; (also 恋人 / 思慕 / 愛欲 / 炮友 all work — tier toggles)
TCVAR:21:発情 = 1             ; estrus
CFLAG:21:現在位置 = CFLAG:MASTER:現在位置   ; teleport Merlin to you
FLAG:時間停止 = 1             ; (= FLAG:70)
MONEY = 100000               ; built-in
CFLAG:21:诶嘿嘿 = 2          ; うふふ playful-drunk mood (assignment works; no visible effect until a command branches on it)
```
**Did NOT work / unreliable:** `FLAG:89 = 1` (weather — multi-flag plugin, exact mapping unknown), `CFLAG:21:约会中 = …` (finicky). No per-character `信頼`/trust slot exists in this fork (only globals `FLAG:29 信頼度上昇率`, `EX:19`); use 好感度/親密/従順 instead. Drunkenness has no clean single slot (`BASE:21:酒気` is tolerance; state flags `CFLAG:21:528 烂酔奸`, `529 不會喝酒`).

---

## OPERATIONAL GOTCHAS (must document in skill)

1. **`lazyloading.dat` is a STALE cache.** It does NOT reflect edits. Delete it to pick up changed/new ERB files. `USELAZYLOADING:YES` makes all exes honor it.
2. **`emuera.log` is halt-only** (see above) — never trust it as a "load succeeded" signal. Tell: use cache-rebuilt flag / clip_tap instead. Clear it before each launch.
3. **Autosave hits `save99.sav`** (`オートセーブを行なう:YES`). A new game (and likely day-advance) overwrites it. ALWAYS back up `sav/` before testing; restore after.
4. **PowerShell path wildcards:** folder names contain `[サニー]` etc.; `[` `]` are wildcard metacharacters → use `-LiteralPath` on Test-Path/Move-Item/Copy-Item.
5. **`$pid` is a read-only automatic variable** in PowerShell — don't name a function param `$pid` (use `$procId`). This silently broke my SendKeys helper.
6. **Stray backup/variant folders inside the kojo tree cause duplicate-label load failures.** Subdirectory scanning is on (`サブディレクトリを検索する:YES`), so e.g. `005 Sunny/サニーミルク - backup_5_14_2024/` collides with the live `サニーミルク/` (`An item with the same key has already been added. Key: M_KOJO_K5`). The lazy cache tolerated these (last-wins); a clean full rebuild rejects them.

---

## ENVIRONMENT CHANGES I MADE (need eventual cleanup / awareness)

- **Saves backed up:** `sav_autotest_backup/` (11 files, pristine). Restore tested & working. `save99.sav` was overwritten by an autosave once and restored — currently all saves verified byte-identical to backup.
- **Moved out of the loaded ERB tree → `_disabled_kojo_dups_由autotest移出/`** (at game root) to fix duplicate-label collisions for a clean full rebuild (all reversible):
  - `サニーミルク - backup_5_14_2024` (K5) — stray backup, safe to leave moved.
  - `ルナチャイルド - backup_5_14_2024` (K6) — stray backup.
  - `スターサファイア - backup_5_14_2024` (K7) — stray backup.
  - `012_Rumia_露米娅~宵暗之花 - Moe茗 (REAL VARIANT)` (K12) — **REAL content variant**, not a backup; set aside to break the collision. To restore it needs a `RESULTS` selector (else it re-collides with the canonical `ルーミア`). **User decision pending.**
- **Test harness file:** `…/021 Merlin [メルラン]/メルラン/M_KOJO_K21_AUTOTEST.ERB` (currently `@EVENTLOAD` form). **MUST be deleted before shipping / when done.**
- **New tool:** `learning/eratw-skill/tools/clip_tap.ps1` (keep — it's useful).
- **`lazyloading.dat`** has been deleted/rebuilt several times (harmless; regenerates).
- **`emuera.config` NOT yet changed** (still `USELAZYLOADING:YES`). If I set it to NO for the test, RESTORE it from the backup I'll make.
- Temp files at game root: `.game_pid.tmp`, `.tap_pid.tmp`, `autotest_cliplog.txt`, `emuera.log`, `debug/` — all disposable.

---

## NEXT STEPS

1. **Finish the `@EVENTLOAD` + `USELAZYLOADING:NO` test** (steps under CURRENT STATUS). This is the most promising trigger: auto-runs on save-load, full fidelity, no console, CALL works. If it runs and clip_tap shows the markers + Merlin's ENCOUNTER text → **the pipeline is fully validated.**
2. If `@EVENTLOAD` works, generalize: the harness loops relationship tiers (set `TALENT:21:恋慕` etc.) × commands, CALLs each label, prints delimited markers. Consider `OUTPUTLOG`/`SAVETEXT` to dump to a file too (verify syntax; clip_tap is the proven channel).
3. **Restore `emuera.config`** after testing.
4. **Decide on the moved Rumia K12 variant** (restore w/ selector, or leave moved).
5. **Delete the harness file** when done.
6. Eventually: **fold all this into the SKILL** as an autotest-workflow section. CRITICAL notes the user insisted on:
   - The autotest harness (event-hook or `@SYSTEM_TITLE`/`@EVENTLOAD`/`@EVENTFIRST`) **MUST be disabled/removed after testing** — an event hook fires on every matching event (incl. the player's normal game). The `DEBUGGERR` guard makes it safe-by-default (only fires under `-Debug`), but the file must still be removed before shipping.
   - **Never break the player's saves or game logic.** Always back up `sav/`, restore after; guard test code behind `DEBUGGERR`; restore any config changes.
   - **Fidelity caveat:** a harness that directly CALLs labels is a UNIT test of label *bodies* (compile, branch, output) under set state. It does NOT test dispatch *timing* (e.g. EVENT_K_1 over-firing per cell, GRAVITY/MARKCNG spam — skill pitfalls #4/#5/#7). Running from a loaded save (`@EVENTLOAD`) gives realistic state (chars registered) and avoids false-fails; but timing bugs still need real play or reading `KOJO_MESSAGE.ERB`. "Autotest passes" ≠ "correct in play."

---

## WORKFLOW THE USER CONVERGED ON (their words, refined)

Finish kojo → write autotest → start the clipboard listener (clip_tap) that builds a real-time log → launch the game in debug to run the autotests → use the real-time log to check for issues. Plus: prefer **an existing player save (backed up)** as the fixture over a new game (new game = lots of setup clicks + noise). Trigger = `@EVENTLOAD` (auto-runs on load) with lazy loading disabled — NOT the debug console (it can't CALL).

---

## KEY FILE PATHS

- Game root: `d:\Game\TouHou\Yoiyami Dreamer\datas\eraTW\`
- Skill: `learning/eratw-skill/` (SKILL.md, references/01-10, reference-kojo/口上テンプレ + reimu)
- clip_tap tool: `learning/eratw-skill/tools/clip_tap.ps1`
- Merlin kojo: `ERB/口上・メッセージ関連/個人口上/021 Merlin [メルラン]/メルラン/`
- Harness: `…/メルラン/M_KOJO_K21_AUTOTEST.ERB` (DELETE when done)
- Save backup: `sav_autotest_backup/`
- Engine entry: `ERB/TITLE.ERB` (@SYSTEM_TITLE), `ERB/SYSTEM.ERB` (@EVENTFIRST), in-game cheat menu `ERB/DLC/DEBUG.ERB` (gated by DEBUGGERR; entry hook not yet found; its fns are CALL-based so not console-usable anyway)
- Exes: `Emuera_lazyloading_for_developer.exe` (debug), `Emuera_lazyloading_for_player.exe`, `Emuera1824+v21+EMv18+EEv46.exe`. All honor `USELAZYLOADING` config.

---

## DIVISION OF LABOR (important)

- **The USER drives all in-game GUI manually** — clicking, pressing Enter, loading saves (`[1] 继续了哦` → slot), opening the debug console (`调试(D)` → `打开调试窗口` → `控制台` tab), typing console commands, and clicking to advance past `PRINTFORMW` waits. Ask them to do these and report what they see.
- **The AI does:** launch the exe, run/read clip_tap, read `emuera.log`, edit ERB/config files, back up/restore saves.
- My SendKeys keystroke automation FAILED (the `$pid` read-only bug). It *could* be fixed (rename param to `$procId`), but **manual-by-user has been reliable** — don't block on automating keystrokes.
- **PIDs are session-specific.** The numbers in this doc (user's game 29808, test instances 24032 etc.) are dead after compact/relaunch. Always re-enumerate `Get-Process Emuera*` and CONFIRM WITH THE USER which instance is theirs before killing anything.

---

## COMMAND COOKBOOK (exact working forms, gotchas baked in)

```powershell
cd "d:\Game\TouHou\Yoiyami Dreamer\datas\eraTW"

# 0. Identify instances — never kill the user's. Confirm with user.
Get-Process -Name "Emuera*" -ErrorAction SilentlyContinue | Select-Object Id,MainWindowTitle

# 1. Back up saves (once) and restore (after every run)
Copy-Item -Recurse sav sav_autotest_backup            # backup (already done this session)
Copy-Item sav_autotest_backup\*.sav sav\ -Force        # restore all

# 2. Launch fresh + clip_tap. Delete cache so edits load. Clear stale logs.
Remove-Item lazyloading.dat,emuera.log,autotest_cliplog.txt -ErrorAction SilentlyContinue
$p = Start-Process ".\Emuera_lazyloading_for_developer.exe" -ArgumentList "-Debug" -PassThru
$p.Id | Out-File .game_pid.tmp
$tap = Start-Process powershell -PassThru -WindowStyle Hidden -ArgumentList @(
  "-STA","-ExecutionPolicy","Bypass","-File",".\learning\eratw-skill\tools\clip_tap.ps1",
  "-LogFile",".\autotest_cliplog.txt","-WatchPid",$p.Id,"-IntervalMs","300")
$tap.Id | Out-File .tap_pid.tmp
Start-Sleep -Seconds 30

# 3. Check load (clean = no halt). emuera.log is halt-only.
if (Test-Path emuera.log) { Get-Content emuera.log -Raw -Encoding UTF8 } else { "clean" }

# 4. Read transcript — ALWAYS -Encoding UTF8 (Read tool mangles CJK; ASCII markers are safe).
Get-Content autotest_cliplog.txt -Encoding UTF8 -Tail 30
Select-String -Path autotest_cliplog.txt -Pattern "AUTOTEST_K21_BEGIN|AUTOTEST_K21_END" -Encoding UTF8

# 5. Kill my instances (NOT the user's) + tap when done
Stop-Process -Id ([int](Get-Content .game_pid.tmp)) -Force -ErrorAction SilentlyContinue
Stop-Process -Id ([int](Get-Content .tap_pid.tmp)) -Force -ErrorAction SilentlyContinue

# NOTE: paths with [サニー] etc. need -LiteralPath on Test-Path/Move-Item/Copy-Item (brackets = wildcards).
```

**Config toggle for the `@EVENTLOAD` test — use the Edit tool, NOT PowerShell Set-Content** (emuera.config has Japanese text; rewriting it risks corrupting encoding). Back it up first (`Copy-Item emuera.config emuera.config.autotest_bak`), then Edit the single line `USELAZYLOADING:YES` → `USELAZYLOADING:NO`; restore from backup after.

---

## CURRENT HARNESS FILE CONTENT (verbatim)

`ERB/口上・メッセージ関連/個人口上/021 Merlin [メルラン]/メルラン/M_KOJO_K21_AUTOTEST.ERB`:
```erb
@EVENTLOAD
SIF !DEBUGGERR
	RETURN
PRINTL =====AUTOTEST_K21_BEGIN=====
TARGET = 21
PRINTFORML [INFO] K21=%CALLNAME:21% MASTER=%CALLNAME:MASTER% MESHIKI={CFLAG:21:面識}
PRINTL ---ENCOUNTER---
CALL M_KOJO_ENCOUNTER_K21
PRINTL ---COLOR---
CALL M_KOJO_COLOR_K21
PRINTL ---CMD300---
CALL M_KOJO_MESSAGE_COM_K21_300
PRINTL =====AUTOTEST_K21_END=====
```
(Variants tried this session that did NOT work: `@EVENTFIRST` form — excluded by lazy loading; plain `@KOJO_AUTOTEST_K21` procedure — console can't `CALL` it; `#FUNCTION` form — can't contain `CALL`. The `@EVENTLOAD` + `USELAZYLOADING:NO` combo is the untested-but-expected-good path.)

**SUCCESS looks like** (in `autotest_cliplog.txt` after user loads a save):
```
=====AUTOTEST_K21_BEGIN=====
[INFO] K21=梅露蘭 MASTER=... MESHIKI=...
---ENCOUNTER---
「啊啦——是新面孔呢？」 ...
---COLOR---
---CMD300---
... (会話 dialogue) ...
=====AUTOTEST_K21_END=====
```
If `@EVENTLOAD` fires but a label errors, emuera.log/clip_tap shows it → that's a real Merlin-kojo bug to report. If `@EVENTLOAD` doesn't fire at all (no BEGIN marker) → lazy loading wasn't actually disabled (re-check config + delete lazyloading.dat).
