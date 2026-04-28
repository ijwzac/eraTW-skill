# 049 Satori [さとり] — structural notes

Satori is the most structurally interesting character in the codebase because of three things her kōjō does that almost nobody else does:

1. **Mind-reading meta-commentary** on the player's *thought*. Every encounter scene pretends Satori is reading `MASTER`'s mental state — the body literally prints lines like "you wanted to use time-stop on me, didn't you?" — driven not by hidden flags but by author convention.
2. **Save-file re-incarnation detection**. The kōjō reads `FLAG:周回数` (game-cycle count) and `CFLAG:継承` (per-character carryover bits) to recognize *"we've met before in another playthrough"* — Satori complains that the player keeps resetting and forcing her to re-fall-in-love.
3. **Role-play (扮演) detection**. Massive branching on `FLAG:扮演 == 36/37/38` (Orin, Okuu, Koishi — Satori's family) to handle the case where MASTER is impersonating one of her family. Combined with `CFLAG:N:出禁` (banned/exiled) for whether the impersonatee is gone, it gives a full doppelgänger sub-plot.

There are three author variants in this character dir; the most loaded one is `さとり/` and is the focus.

## Variants

| Variant | What it is |
|---|---|
| `さとり/` | The "default" Satori — uses the `_ORTHODOX_` selector. Has the full file taxonomy. ~1.2 MB. |
| `さとり(24.5.14)/` | A 2024 update; **splits the giant event file into many smaller files keyed by event-CFLAG** (e.g. `M_KOJO_K49_イベント_1019(宴席の戯れに).erb`). Adds `FONT_AA(通用字符画).erb` (525 KB ASCII-art library). Has `M_KOJO_K49_イベント_DANMAKU(弹幕战斗模板).ERB` (a 200 KB danmaku scenario template). |
| `古明地觉_试制口上v0.053/` | A community-fork by *name-killed (NK)*. Organized as **directory-keyed subcategories**: `一般/`, `性/`, `自作/`, `其它/`. Includes a how-to: `コマンド口上でソースを追加する方法.txt`. WIP. |

This shows the **organization is fully author-discretion** — only the engine-callable label names are fixed; how those labels are spread across files is whatever the author wants. The dispatcher doesn't care which file holds which label.

## The kōjō selector ("RESULTS infix")

Satori's existence-check label is **not** the standard `@M_KOJO_K49(ARG)`. It's:

```erb
@M_KOJO_K49_3(ARG)
RESULTS:1 = 日版
RESULTS = _ORTHODOX
RETURN 1
```

- `RESULTS:1 = 日版` — the language (日 = Japanese; ASCII commentary later says it could be `_TEST_` or other).
- `RESULTS = _ORTHODOX` — the **kōjō selector suffix** for this character.

The dispatcher in `KOJO_MESSAGE.ERB` reads `RESULTS` after calling `KOJO_ACTIVE_INFO(N)` and substitutes it into the label name:

```
TRYCALLFORM M_KOJO%RESULTS%_EVENT_K{NO:TARGET}_{ARG:1}(ARG:3,ARG:4)
;          ^^^^^^^^
;          becomes _ORTHODOX, so the label resolved is:
;          M_KOJO_ORTHODOX_EVENT_K49_<arg1>(...)
```

That's why every Satori label in the file is `@M_KOJO_ORTHODOX_<KIND>_K49_<n>` instead of the conventional `@M_KOJO_<KIND>_K49_<n>`.

**Implication for authors**: by setting `RESULTS` in `@M_KOJO_K<id>_<v>`, an author can ship multiple "voicings" of the same character side by side (e.g., `_ORTHODOX_`, `_DRUNK_`, `_OUTBURST_`), each with a parallel set of labels, and switch between them at runtime by re-running the existence check.

The `_3` suffix on `@M_KOJO_K49_3` is itself a per-engine version selector (so the engine can call `@M_KOJO_K49_<v>` for compatibility with proto4.21 vs newer; only one of these should `RETURN 1`).

## Label inventory in `M_KOJO_K49_イベント.ERB`

(All prefixed `@M_KOJO_ORTHODOX_*` because of the selector.)

```
@M_KOJO_K49_3(ARG)                  ; existence + selector setting
@M_KOJO_ORTHODOX_FLAGSETTING_K49    ; init: SETBIT/CLEARBIT on CFLAG:49:1490, sets 眠姦口上有=1
@M_KOJO_ORTHODOX_COLOR_K49          ; SETCOLOR 0xDB7093
@M_KOJO_ORTHODOX_UPDATE_K49         ; FIRSTTIME-keyed UI ("UP01", "UP02") for permission grants
@M_KOJO_ORTHODOX_ENCOUNTER_K49      ; first-meeting; branches by current-MAIN_MAP and 扮演

;-- Special events (one-shot story) --
@M_KOJO_ORTHODOX_SPEVENT_K49_1(ARG, ARG:1)   ; first-kiss after date
@M_KOJO_ORTHODOX_SPEVENT_K49_2(ARG, ARG:1)   ; date confession
@M_KOJO_ORTHODOX_SPEVENT_K49_3(ARG, ARG:1)   ; date return

;-- Numbered events --
@M_KOJO_ORTHODOX_EVENT_K49_1 .. _30          ; the engine's event slots 1..30
@M_KOJO_ORTHODOX_EVENT_K49_ONABARE_1(ARG)    ; "outburst" (sleep-rape backlash) sub-events
@M_KOJO_ORTHODOX_EVENT_K49_ONABARE_2(ARG)
@M_KOJO_ORTHODOX_EVENT_K49_ONABARE_3(前戯１, 本番はどっちか, 回数, 注入量)
                                              ;   note: arg names use Japanese identifiers and
                                              ;   are *positional* like ARG/ARG:1; this is just
                                              ;   nicer to read
```

## State-machine at the top of FLAGSETTING

`@M_KOJO_ORTHODOX_FLAGSETTING_K49` does *more* than set flags — it executes per-turn rebalancing. The author's bit-flags namespace `CFLAG:49:1490`:

| Bit | Meaning |
|---|---|
| 0 | Family was time-stop-violated |
| 1 | At least one "把柄" (blackmail handle) acquired |
| 2 | Bareback refused |
| 3 | Drugged tea has been used |
| 4 | "Stay over" has been requested twice+ |
| 5 | Long-distance masturbation broadcast happened |
| 6 | "Pampered Satori" mode controller |
| 7-10 | Pampered-mode termination state |
| 11 | "Listening to grumbles" anger judgement |

Bit operations: `SETBIT CFLAG:49:1490, N`, `CLEARBIT CFLAG:49:1490, N`, `GETBIT(CFLAG:49:1490, N)`. Each bit is touched in different bodies as side-effect.

Per-turn rebalancing examples in FLAGSETTING:
- Iterates her family `FOR LOCAL, 36, 39 / IF EXP:LOCAL:60..63 ... SETBIT CFLAG:49:1490, 0 / NEXT`. (Detects "you used time-stop on Orin/Okuu/Koishi by checking THEIR experience counters.)
- Resets `EX:膣内精液 = 0` until consensual bareback (`CFLAG:49:允许无套 == 1 && ESTRUS_CYCLE(49) == 150`) — narratively, Satori is on contraceptives until consent.
- Computes a **new-地底-MAP region tag** in `CFLAG:49:1496` from `MAIN_MAP == 9`/`WITH_MOB() == 9`/`CHK_FOCUS(s, current, e)`.

This is the key idea: **`@M_KOJO_FLAGSETTING_K<id>` runs every turn**, not once. Authors use it as a "turn tick" hook for their character's private state machine.

## State-router pattern

There's an author-private "router" that delegates by player/character state. The `[SKIPSTART]/[SKIPEND]` block at top of `イベント.ERB` shows it:

```
IF FLAG:70                          ; time-stop
    CALL STOP49
ELSEIF CFLAG:TARGET:睡眠            ; sleeping
    CALL SLEEP49
ELSEIF CFLAG:诶嘿嘿 == 2            ; drunken-mood (诶嘿嘿 = "ehehe" = drunk)
    CALL UFUFUTO49()
ELSEIF (BASE:酒気 > (MAXBASE:酒気 / 10) * 4)   ; over-40%-saké
    CALL DRUNKER49()
ELSEIF 陥落状態() >= 4               ; fall-tier 4+ (恋人)
    IF 陥落状態() == 5
        ; pampered-mode active
    ENDIF
ELSEIF 陥落状態() == 3               ; 恋慕
ELSEIF 陥落状態() == 2               ; 思慕
ELSEIF 陥落状態() == 1               ; 合意
ELSE
ENDIF
```

`陥落状態()` is the author's helper (likely defined in another file or inferred from `TALENT:N:恋慕/恋人/思慕/愛欲/炮友` chain). Seeing this pattern, **the canonical state cascade for relationship branches is**:

```
TALENT:恋人 (5)  > TALENT:愛欲 (4)  > TALENT:炮友 (4)
                > TALENT:恋慕 (3)
                > TALENT:思慕 (2)
                > 合意 talent  (1)
                > none         (0)
```

(Other authors don't always go through `陥落状態()`; many test the talents directly. Both are equivalent.)

## Mind-reading inline-pronoun: heavy use of `\@ ... ? ... # ... \@`

Many lines look like:

```erb
PRINTFORMDL \@ FLAG:扮演 == 38 ? 姐姐 # 觉様 \@ ", 我最喜欢你了"
```

The inline ternary `\@ <cond> ? <then> # <else> \@` evaluates to the `<then>` or `<else>` substring **at print time**. This is heavily used to localize address ("you call me 姐姐 if impersonating my sister Koishi, otherwise 觉様"). The other characters use it occasionally; Satori uses it everywhere because so many of her lines have to mind-read context.

Other examples (from the SKIPSTART block):

```erb
\@ 陥落状態() >= 4 ? %CALLNAME:MASTER% # %CALLNAME:MASTER% \@   ; chooses how she addresses MASTER
\@ FLAG:扮演 == 38 ? おねえちゃん # 覚様 \@                      ; 38 = Koishi (sister) → "older sister"
\@ 陥落状態() >= 4 ? %MASTERNAME:49% # 你 \@                    ; once 恋人, switches to private nickname
```

## Reincarnation / continuity of identity

In the ENCOUNTER body (line ~356), the *first time you meet Satori in a new game cycle* is:

```erb
ELSEIF FLAG:周回数
    PRINTFORML 「……等等」
    PRINTFORMDL ... 听到那熟悉的声音呼唤着自己 ...
    PRINTFORML 「『终于又见面了......小五萝莉』？　……你的脑海里、为什么在想着这样奇怪的话？」
    ...
    IF GETBIT(CFLAG:継承, 1)
        PRINTFORMD 用非常可爱的笑容喊着夫君      ; you were married last time
    ELSEIF GETBIT(CFLAG:継承, 0)
        PRINTFORMD 脸上总是是带着幸福的笑意     ; you were lovers last time
    ELSE
        PRINTFORMD 与觉每一次的相遇、度过的每一天 ; just met before
    ENDIF
    ...
    PRINTFORM 「同样的人、同样的事重复了
    SIF FLAG:周回数 > 1
        PRINTFORM {FLAG:周回数}回                ; "{N} times"
    PRINTFORML 你…到底想干什么？」
```

`FLAG:周回数` is the engine-side game-cycle count. `CFLAG:継承` is the engine-side character-carryover bitfield (set when the player chose "carry this character over to the next game" during new-game). Bit 0 = "was lover", bit 1 = "was married". Satori reads both *and* recognizes that no normal NPC should be able to remember a previous game cycle; her mind-reading explains it.

## Role-play (扮演) and family-doppelgänger detection

`FLAG:扮演` holds the char ID the player is currently impersonating (set elsewhere in the engine when MASTER swaps appearance). For Satori, the body of every encounter pre-checks this:

```erb
IF GETBIT(CFLAG:1492, 1)
    IF FLAG:出禁人数 == 0 && (FLAG:扮演 == 36 || FLAG:扮演 == 37 || FLAG:扮演 == 38)
        ; you're impersonating Orin/Okuu/Koishi *and* the original is still in the world
        ; (出禁人数 = banned count, 0 = original is here)
        PRINTFORML 「………………还给我」                ; "give them back to me"
        ...
    ELSEIF FLAG:出禁人数 == -1 && ...
        ; doppelgänger mode (the original is gone)
        PRINTFORML 「真肮脏啊」
        ...
    ELSEIF FLAG:扮演 == 49
        ; you're impersonating Satori herself
        PRINTFORML 「……用着与我相似的姿态、很开心吗？」
        ...
    ELSEIF FLAG:扮演 && CFLAG:(FLAG:扮演):出禁
        ; impersonating someone who's been banned/exiled
        ...
    ELSEIF FLAG:扮演 && !CFLAG:(FLAG:扮演):出禁
        ; impersonating someone who's still around
        ...
    ENDIF
```

Three flags interact here:

- `FLAG:扮演` — the impersonatee's char ID, or 0.
- `FLAG:出禁人数` — total banned-count (0 means original is here, -1 means not).
- `CFLAG:N:出禁` — per-character "banned" flag.
- `CFLAG:1492` (Satori's switch) — bit 1 = "respond to 扮演 mode at all". If clear, Satori treats the impersonator as the ordinary character.

So the *semantics* of an impersonation depend on whether the target is also present. This pattern is unique to Satori (and Koishi).

## The ASCII-art library (variant 24.5.14 only)

`FONT_AA(通用字符画).erb` (525 KB) is a library of `@FONT_AA_<key>` labels, each containing a multi-line ASCII-art print. Other kōjō files in that variant `CALL FONT_AA_<key>` to print a portrait inline. The label file is **all data, no logic**. Don't read content; structurally, every label is just:

```
@FONT_AA_<key>
PRINTL <line of ASCII art>
PRINTL <line of ASCII art>
...
RETURN
```

This is the only character in the codebase that ships ASCII art at this scale — but the *technique* (a separate "asset" library called by name) is what's reusable.

## The auto-pant (`コマンド自動喘ぎ.ERB`) — string-construction pattern

The non-Skipped portion of this file is currently bracketed in `[SKIPSTART]/[SKIPEND]`, but its structure is illustrative. The label `@渧泣()` builds a moan-line dynamically by:

1. Examining `TEQUIP:TARGET:11..18` and `TEQUIP:TARGET:101..107` to learn which body parts are currently being touched (Ｃ = clitoris, Ｐ = penis (Satori has 扶她 in some configs), Ｖ = vagina, Ａ = anal, Ｂ = breast, Ｍ = mouth).
2. Concatenating a string `使用部位 = "ＣＶＡ"` from the active parts.
3. Branching on `STRLENSU(使用部位)` (4/3/2/1) to pick the right phrasing — "all four", "three at once", "X and Y", or just "X".
4. Branching on `陥落状態()` to pick a vocabulary tier — formal Japanese, informal Japanese, or relationship-state nicknames ("おまんこ"/"そこ"/"クリ" tiers).
5. The result is a formed string like `指令部位:0 = "阴蒂と欧金金"` to be `PRINTFORML`'d.

This is the most string-heavy kōjō in the project and shows that bodies can fully **synthesize text**, not just choose between fixed lines.

## Other notable Satori-specific patterns

- **`@M_KOJO_ORTHODOX_UPDATE_K49`** uses `FIRSTTIME("UP01", 0, 49)` and `FIRSTTIME("UP02", 0, 49)` — string-keyed `FIRSTTIME` with explicit char-ID scoping. Used to make permission UIs ask their question only once per game.
  - Once accepted, sets **`SETBIT CFLAG:49:1490, 6`** for "pampered-Satori-mode allowed".
  - On becoming a 恋人, mutates talents: `TALENT:49:自尊心 = 0` (drops her "high pride" talent), and depending on player gender either drops 讨厌男人 or grants 両面通吃.
- **`陥落状態()` is the author's term** for "fall tier", almost certainly defined in a hidden helper file. Other characters typically test talents directly.
- **The 24.5.14 variant**'s split-by-event-CFLAG file naming (`M_KOJO_K49_イベント_1019(宴席の戯れに).erb`) treats event IDs as routable file paths — so the author can ship/edit events in isolation. The file just contains the matching `@M_KOJO_ORTHODOX_EVENT_K49_<id>(...)` label.

## Heuristics for the LLM-doc

- A character can declare a **kōjō selector** (`RESULTS = _<NAME>`) and prefix all their labels with `_<NAME>_` to live alongside other variants of themselves. This is how multi-author / multi-mood character files coexist in the same dir.
- `@M_KOJO_FLAGSETTING_K<id>` runs **every turn** and is the right place for character-private state-machine ticks (bit-set flags, contraceptive-mode rebalancing, MAP-region tagging, etc.).
- Use `\@ cond ? a # b \@` inline ternaries to localize forms-of-address rather than nesting `IF/PRINTFORML` everywhere.
- For "I-recognize-you-from-a-past-life" branches, read `FLAG:周回数` and `CFLAG:継承` (the engine writes these on new-game-with-carryover).
- For impersonation-aware branches, three flags interact: `FLAG:扮演` (impersonatee char ID), `FLAG:出禁人数` (count of banned characters in world), `CFLAG:N:出禁` (per-char banned).
- Multi-line story scenes can synthesize text from active TEQUIP slots — this is the formula behind dynamic moans, dynamic descriptive prose, etc.
- ASCII art and other "asset" libraries are a legitimate file type — bundle them as a separate `<name>.erb` of label-keyed `PRINTL` blocks and `CALL` them by label from regular kōjō.
