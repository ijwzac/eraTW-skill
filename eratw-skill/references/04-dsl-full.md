# DSL (Emuera-script) — full primer

SKILL.md keeps the Standard Body Shape (§6) inline because it's the most-reused template. This file holds the rest of the language reference.

## 3. The DSL (Emuera-script) — primer

### 3.1 Variables and arrays

```erb
LOCAL = 1                  ; numeric local — auto-allocated
LOCAL:1 = 5                ; second slot of LOCAL array
LOCALS = "hello"           ; string local
LOCALS:1 = "world"

#DIM CONST K_FOO = 1100    ; compile-time constant
#DIM 知り合い, 6 = 29, 65, 51, 49, 38, 1   ; array literal init
#DIM SAVEDATA RAGE_GAUGE   ; per-char persistent across saves
#DIMS SAVEDATA NICKNAME    ; same, string
#DIM SAVEDATA GLOBAL G     ; globally persistent (use sparingly)
#LOCALSIZE 200             ; expand local array
```

**Default args** (positional only — Emuera does NOT allow custom parameter names):
```erb
@MY_HELPER(ARG, ARG:1 = 0)
;ARG:1 defaults to 0 if caller omits it
;          ─────────
;          MUST be ARG / ARG:N / ARGS / ARGS:N — custom names like
;          `TYPE`, `OPTION`, `相手残機` raise compile warning
;          "参数错误:变量"X"未在此函数中定义" and the variable becomes
;          unreadable inside the body.
;
;If you want named-style readability inside the body, alias at the top:
;@MY_HELPER(ARG, ARG:1 = 0)
;TYPE = ARG:1
;... use TYPE freely below ...
```

A few legacy kojo (K5, K6, K7) use the workaround `@FOO(ARGS, 相手残機)` followed by `#DIM 相手残機` immediately after — this compiles and runs but produces a Lv2 warning at load. Don't replicate that style for new kojo; use positional + alias.

**Function markers** — for callable functions inside expressions:
```erb
@MY_INT_FUNC()
#FUNCTION
RETURNF 42

@MY_STR_FUNC()
#FUNCTIONS
RETURNF "hello"
```

Use site: `IF MY_INT_FUNC() > 0 ...`, `PRINTFORML 「%MY_STR_FUNC()%」`.

### 3.2 Control flow

```erb
IF cond
ELSEIF cond
ELSE
ENDIF

SIF cond                    ; single-line: applies to next stmt only
    PRINTFORML something

SELECTCASE expr
    CASE 0, 2, 4            ; multiple match
    CASE 5 TO 10            ; range
    CASE Is >= 100          ; comparison
    CASEELSE
ENDSELECT

FOR LOCAL, 0, 10            ; end EXCLUSIVE — runs 0..9
NEXT
WHILE cond
WEND
BREAK
CONTINUE

$LOOP                       ; goto label
... 
GOTO LOOP                   ; jumps to $LOOP

[SKIPSTART]                 ; preprocessor: skip
... (commented-out source)
[SKIPEND]
```

### 3.3 Calls

```erb
CALL MY_LABEL                       ; invoke; ignores any return
CALLF MY_INT_FUNC(args)             ; invoke #FUNCTION
TRYCALL MY_LABEL                    ; silent on missing
CALLFORM SOME_PREFIX{LOCAL}_SUFFIX  ; build name dynamically
TRYCALLFORM ...                     ; silent on missing dynamic
TRYCCALLFORM ... CATCH ... ENDCATCH ; try/catch dynamic
RETURN 1                            ; return numeric from a body
RETURN                              ; void return
```

### 3.4 Output

```erb
PRINTFORML 「这是一句日语风的台词%CALLNAME:MASTER%」    ; format + line
PRINTFORMW <text>                                       ; format + WAIT for keypress
PRINTL <text>                                           ; non-format line
PRINTW <text>                                           ; non-format wait
PRINTFORMD <text>                                       ; format, descriptive (no narration prefix)
PRINTFORMDL <text>                                      ; format, descriptive, line
PRINTFORMDW <text>                                      ; format, descriptive, wait

PRINTDATA                                              ; engine picks ONE at random
    DATAFORM 选项一
    DATAFORM 选项二
    DATAFORM 选项三
ENDDATA
PRINTDATAW                                              ; same with wait
PRINTDATAL                                              ; same with line

PRINTBUTTON @"按钮文字", @"按钮按下后RESULTS的值"
```

### 3.5 Color

```erb
SETCOLOR C_CREAM                ; named: C_CREAM, C_AQUA, C_PINK, C_DEFCOLOR, C_HTML
SETCOLOR 0xFF69B4               ; hex
SETCOLOR 255, 105, 180          ; RGB
RESETCOLOR
```

### 3.6 String interpolation forms

| Form | Purpose |
|---|---|
| `%CALLNAME:N%` | display-name of char N (or `MASTER`/`PLAYER`/`TARGET`). |
| `%MASTERNAME:N%` | per-char nickname for MASTER (mutable). |
| `%CHILDNAME:char:idx%` | child name. |
| `%TEXTR("a/b/c/d")%` | random pick. |
| `%UNICODE(0xN)%` | unicode char (`0x2665` = ♥). `* N` repeats. |
| `\@ <expr> ? <a> # <b> \@` | inline ternary. |
| `%CSVCSTR(N, slot)%` | per-char CSV string lookup. |
| `%CSTR:N:slot%` | per-char mutable string. |
| `%CALLNAME:N%`, `%PANTSNAME(EQUIP:..., N)%`, `%CLOTHNAME(slot, EQUIP:N:slot)%`, `%OPPAI_DESCRIPTION(N, 1)%` | engine helpers. |
| `%K{id}_<func>(args)%` | call author's `#FUNCTIONS` and interpolate. |

### 3.7 Special tokens

- `[[<name>]]` — parse-time char-id lookup (e.g. `[[極]]` → 42). **Important quirks:**
  - **`[[X]]` only resolves names in `CSV/STR.csv`**, NOT names in `CSV/Chara/Chara<N> *.csv`. Most character names you'd think to use (`[[アリス]]`, `[[ルナサ]]`, `[[メルラン]]`, `[[幽々子]]`, `[[ライコ]]`, etc.) **are not in STR.csv** even though their CSV files exist. They fail silently — `[[X]]` becomes literal `0` when unresolved, so `CASE [[ルナサ]]` becomes `CASE 0` and matches ARG=0.
  - **`MASTER`, `TARGET`, `PLAYER`, `ASSI` are built-in numeric pseudo-constants** — write them bare, never as `[[MASTER]]` (which is wrong and produces a warning).
  - **Recommended default**: use the numeric char ID with a comment explaining the ID, e.g. `CASE 22  ;ルナサ Lunasa`. This always works and is more readable when grepping. Reserve `[[X]]` for names you've verified are in `STR.csv` (mostly location names and a small set of major chars like `[[極]]`/`[[文]]`).
  - **To verify** before using `[[X]]`: grep `STR.csv` for the exact name (byte-exact, including kanji-form). If it doesn't appear, fall back to numeric ID + comment.
- `@"text"` — string literal supporting `//` line breaks.
- `\n` inside a `DATAFORM` — line break.

### 3.8 Built-in math/string ops

| Op | Notes |
|---|---|
| `RAND:N`, `RAND(N)` | uniform 0..N-1. |
| `MAX(a, b)`, `MIN(a, b)`, `ABS(n)` | math. |
| `INRANGE(v, lo, hi)` | bounds-check. |
| `STRLENS(s)`, `STRLENSU(s)` | byte/char length (U is unicode-aware). |
| `STRCOUNT(s, "regex")` | count regex matches. |
| `REPLACE s, "pattern", "repl"` | in-place replace. |
| `FINDELEMENT(arr, val, start)` | find array index. |
| `SETBIT v, k`, `CLEARBIT v, k`, `GETBIT(v, k)` | bit ops. |
| `INPUT` (int → RESULT), `INPUTS` (string → RESULTS) | user input. |
| `TWAIT <ms>, <flag>`, `GETKEY(<n>)` | wait / read keypress. |
| `CLEARLINE <n>`, `REUSELASTLINE <text>` | UI manipulation. |
| `REDRAW <mode>`, `CURRENTREDRAW()`, `LINECOUNT` | drawing-mode. |
| `VARSET <name>` (clear), `VARSET <name> <value>` (set) | variable reset. |
| `TIMES <var>, <factor>` | multiply by float, store back. |

---

