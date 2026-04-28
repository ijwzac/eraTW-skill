# 006 Luna [ルナ] / ルナチャイルド — structural notes

Author-variant directory: `006 Luna [ルナ]/ルナチャイルド/` (single variant; backup dir `ルナチャイルド - backup_5_14_2024` is dead weight). Char ID = **6**.

The `readme.txt` documents the persona constraint: **most kōjō only fires when the player is a child** (`TALENT:MASTER:年齢 == -1` or `TALENT:MASTER:幼児／幼児退行`, with an opt-in via `CFLAG:6:1001 = 1` set in `@M_KOJO_UPDATE_K6`). Knowing this is essential because nearly every body in this directory wraps the *entire* logic in that outer `IF`, and it shapes how the file *appears* to be incomplete when it is actually conditionally suppressed.

## File set

| File | Lines | Role |
|------|-------|------|
| `M_KOJO_K6_イベント.erb` | 4558 | Existence + flag/color/update + ENCOUNTER + SPEVENT + EVENT (all event-class hooks live here) |
| `M_KOJO_K6_日常系コマンド.erb` | 3894 | COM 300–4xx daily commands |
| `M_KOJO_K6_性交系コマンド.erb` | 1424 | COM 60–7x sex positions |
| `M_KOJO_K6_カウンター.erb` | 1049 | COUNTER 1–92 (auto/idle reactions) |
| `M_KOJO_K6_派生コマンド.erb` | 940 | SCOM 1–19 derived sub-commands |
| `M_KOJO_K6_日記.ERB` | 783 | Diary (existence/before/text/after labels + COM 406) |
| `M_KOJO_K6_セクハラコマンド.erb` | 553 | COM 310–330 sexual-harassment |
| `M_KOJO_K6_育児イベント.erb` | 543 | Child-rearing events |
| `M_KOJO_K6_加虐系コマンド.ERB` | 430 | COM 100–108 SM/discipline |
| `M_KOJO_K6_依頼.erb` | 130 | Quest/request dispatcher |
| `M_KOJO_K6_弾幕勝負.erb` | 122 | Danmaku duel |
| `M_KOJO_K6_刻印取得.erb` | 80 | Mark-acquisition lines |
| `readme.txt`, `ライセンステンプレ.txt` | — | Author docs (not loaded) |

## Engine-facing label catalog (everything dispatched by `KOJO_MESSAGE_SEND`)

### In `M_KOJO_K6_イベント.erb`

```
@M_KOJO_K6(ARG)                   ; existence — must RETURN 1, no logic
@M_KOJO_FLAGSETTING_K6            ; init: optional CFLAGs that turn on
                                  ; sleep-rape/time-stop/role-play/refuse-push/no-visit/etc.
@M_KOJO_COLOR_K6                  ; SETCOLOR for character voice
@M_KOJO_UPDATE_K6                 ; one-time UI: ask player whether to allow
                                  ; child-only kōjō to fire on non-child players.
                                  ; Sets CFLAG:6:1001 = 1 if accepted.
@M_KOJO_ENCOUNTER_K6              ; first-meeting cutscene; offers a one-shot
                                  ; INPUT to retune Luna's ABL/EXP.

;-- Special events (engine passes ARG, ARG:1; calls SPEVENT_MESSAGE_<n> for default narration) --
@M_KOJO_SPEVENT_K6_1(ARG,ARG:1)   ; first kiss after date (TCVAR:中止接吻=1 to abort)
@M_KOJO_SPEVENT_K6_2(ARG,ARG:1)   ; date-confession: ARG=0 propose / 1 accept / 2 reject
@M_KOJO_SPEVENT_K6_3(ARG,ARG:1)   ; date return; ARG=0 normal, 1/2/3 = repulse-mark de-escalation tiers

;-- Generic events --
@M_KOJO_EVENT_K6_1(ARG,ARG:1)     ; room encounter; ARG=1 player-enters, 2 target-enters,
                                  ;   3-5 bath in/leave/kicked, 6 outdoor encounter, 7 caught dating
@M_KOJO_EVENT_K6_2(ARG,ARG:1)     ; morning; ARG=1 not-cohabit-other-up, ARG:1=0/1 in-target's-room,
                                  ;   ARG=2 cohabit-other-up, 3 cohabit-other-asleep, 4 you-up-then-they-wake
@M_KOJO_EVENT_K6_3(ARG,ARG:1)     ; bedtime
... and ~50 more numbered events for festivals, gifts, jealousy, weather, …
```

The `ARG` parameter is *event-specific*: it's a sub-state selector. The conventional shape is `IF LOCAL:1 && ARG == <code>`. Authors document what each ARG value means in inline comments above each branch.

### In every `*_<category>コマンド.erb`

For each command ID `N` that the character handles:

```
@M_KOJO_SUCCESS_COM_K6_<N>        ; (optional) override TFLAG:192 to force success/fail.
TFLAG:192 = 0                     ; -2 = end command, -1 = forced fail, 0 = COM-default, 1 = forced great-success

@M_KOJO_MESSAGE_COM_K6_<N>        ; engine entry. Convention:
CALL TRAIN_MESSAGE                ;   1) print engine default narration
CALL M_KOJO_MESSAGE_COM_K6_<N>_1  ;   2) call body
RETURN RESULT

@M_KOJO_MESSAGE_COM_K6_<N>_1      ; the body
LOCAL = 1                         ; 1 = filled-in, 0 = stub-skip
IF LOCAL
    ; one or more `IF guards` then PRINTFORML/PRINTFORMW lines or a SELECTCASE RAND:N
ENDIF
RETURN 1
```

Some commands omit `CALL TRAIN_MESSAGE` (e.g. 350 推倒, 351 連れ出し, 351 帯出去, 405 外出, 413 料理, 604 散歩, 605 寄り道, 354 添い寝). The pre-narration is then the kōjō's own responsibility.

For multi-person scenes (especially in `派生コマンド`), the `_1` body is for the first participant; a `_2` body exists for the second, and the engine swaps `TARGET` between them:

```
@M_KOJO_MESSAGE_SCOM_K6_9
    CALL TRAIN_MESSAGE
    CALL M_KOJO_MESSAGE_SCOM_K6_9_1     ; first person
    LOCAL = MASTER_POSE(4,1,1)          ; resolve 2nd participant ID
    LOCAL:1 = RESULT
    LOCAL:2 = TARGET
    TARGET = LOCAL
    TRYCALLFORM M_KOJO_MESSAGE_SCOM_K{TARGET}_9_2  ; their version, dispatched by char ID
    TARGET = LOCAL:2
    RETURN LOCAL:1
```

This is **important**: SCOM bodies must be aware they may be running on a partner's TARGET, not Luna's, when reading variables.

### In `M_KOJO_K6_カウンター.erb`

```
@M_KOJO_MESSAGE_COUNTER_K6_<N>
CALL EVENT_COUNTER_MESSAGE
CALL M_KOJO_MESSAGE_COUNTER_K6_<N>_1
RETURN RESULT
@M_KOJO_MESSAGE_COUNTER_K6_<N>_1
    ...
RETURN 1
```

Counter IDs in this file follow a documented numeric grouping:
- 1–4: friendly proximity
- 11–16: ベリーソフト (closer, smiling, leaning)
- 20–27: ソフト (eye-contact, pose, sniff, light touch)
- 30–39: 性騷擾 (kiss, hug, breast/groin grope, panty-flash, treat-snatch)
- 41–44: おねだり (asking-for V/A insertion)
- 50–60: 愛撫 (manual/oral/anal/breast/deep-kiss)
- 70–77: 奉仕 (sub-led service)
- 80–92: 性交 counters
- 100s: "诶嘿嘿Counter" (still empty in Luna)

Counter handlers can have **side effects** — Luna's counter 34 increments `BASE:MASTER:勃起 += 5`.

### In `M_KOJO_K6_弾幕勝負.erb`

```
@M_KOJO_MESSAGE_COM_K6_DANMAKU(ARGS, 相手残機)
#DIM 相手残機
LOCAL = 1
IF LOCAL
    ; one branch per ARGS string:
    ;   "戦闘前", "ハンデ", "被弾", "残忍酷薄", "乾坤一擲", "怪力乱神", "戦闘後"
ENDIF
RETURN 1
```

Single-label dispatcher with a *string* arg (`ARGS`) for scene and an *int* arg (`相手残機` = opponent lives). The skill names are author-game's danmaku skill IDs.

### In `M_KOJO_K6_刻印取得.erb`

```
@M_KOJO_MESSAGE_MARKCNG_K6
CALL MARK_MESSAGE
IF TFLAG:22 == 1/2/3 ...   ; 苦痛刻印 levels
IF TFLAG:時姦刻印取得 ...   ; 時姦刻印
IF TFLAG:23 == 1/2/3 ...   ; 快楽刻印
IF TFLAG:24 == 11/12/13 ...; 不埒刻印 (快楽-driven, 1x)
IF TFLAG:24 == 31/32/33 ...; 不埒刻印 (恭順-driven, 3x)
IF TFLAG:21 == 1/2/3 ...   ; 反発刻印
```

A single label, branched on TFLAG codes that the engine sets right before calling.

### In `M_KOJO_K6_依頼.erb`

```
@M_KOJO_IRAI_K6(ROLE, SCENE, IRAI_ID)
#DIMS ROLE, SCENE
#DIM  IRAI_ID
;       ROLE   = "CLIENT" / "TARGET" / "NO_REPORT"
;       SCENE  = "依頼提示時" / "依頼非受託時" / "依頼受託時" / "依頼確認時" /
;                "依頼破棄時" / "依頼実行直前" / "依頼実行直後" /
;                "成功報告時" / "失敗報告時" / "依頼報告不要"
;       IRAI_ID% 1000      = quest sub-id
;       IRAI_ID_TO_CLIENT  = quest client char id
;       IS_COMMON_IRAI     = is generic-pool quest?
;       STR_DATA_IRAI(IRAI_ID, "依頼名", CLIENT_ID) = quest title
;       CSVCALLNAME(CLIENT_ID)                     = client display name
SELECTCASE ROLE
CASE "CLIENT"
    IF IS_COMMON_IRAI(IRAI_ID)
        SELECTCASE STR_DATA_IRAI(...)
            CASE "<one of the engine's common quest names>"
                SELECTCASE SCENE ...
        ENDSELECT
    ENDIF
    ; then the per-character固有 quests
    SELECTCASE STR_DATA_IRAI(...)
        CASE "<this character's unique quest names>"
            SELECTCASE SCENE ...
    ENDSELECT
CASE "TARGET"   ; only "依頼実行直前"/"依頼実行直後" reach here
    ...
CASE "NO_REPORT"; only "依頼報告不要" reaches here
    ...
ENDSELECT
```

### In `M_KOJO_K6_日記.ERB`

```
@DIARY_K6_EXIST                     ; existence guard (RETURN 1)
@DIARY_BEFORE_CHECK_K6              ; called every turn; sets DIARY:6:N = 2 or 3
@DIARY_TEXT_K6, PAGENUM, MODE, PAGECOUNT  ; the body
    #DIM PAGENUM, PAGECOUNT
    #DIMS MODE                      ; "デイリー" or "指令"
    CALL M_KOJO_COLOR_K6
    SETCOLOR C_CREAM
    IF MODE == "デイリー"
        CALL PRINT_FACE, 6, "発情", "裸", "_1"  ; portrait by mood/clothing/variant
        ...
    ENDIF
    PRINTFORMDL - %CALLNAME:6%の日記 PAGE.{PAGECOUNT} ----
    SELECTCASE PAGENUM
        CASE 1, 2, ...              ; one body per page
    ENDSELECT
@DIARY_AFTER_CHECK_K6               ; per-day cleanup (reset transient flags)
@M_KOJO_MESSAGE_COM_K6_406          ; "read diary" command — TFLAG:194 holds reader's target ID
;   Diary state:
;     DIARY:char:page = 0=locked, 1=read, 2=daily-event-readable, 3=on-demand-readable
;     MAX_DIARY_PAGE:char:0       = total pages
;     CALL CHARA_DIARY_PAGESETTING(char, page) registers the page slot
;     SHIRAHU(char)               = char is in normal state (not asleep/timestopped)
```

`DIARY:N:0` is reserved (don't use).

### In `M_KOJO_K6_育児イベント.erb`

Three label kinds:

1. **Per-milestone** (no args): `@M_KOJO_EVENT_K6_CHILD_RAISING_<key>` for keys `回復, 離乳, 玩具, つかまり立ち, よちよち, 会話寸前, 喋る, 語彙, しつけ, 就学, 自立前, 自立`. The body is a one-shot prose block, often gated on `TALENT:恋慕 || TALENT:思慕`.

2. **Per-life-stage** (with args `(ARGS, ARG, ARG:1)`): `@M_KOJO_EVENT_K6_CHILD_RAISING_<activity>` for activities `登下校, 吃飯, BATH, SLEEPING, OYASUMI, TOY, OTHER`. `ARGS` selects life stage (`"幼児期" / "幼少期" / "授乳" / "離乳食" / "幼少期" / ...`).

3. **Letters/school**: `@M_KOJO_EVENT_K6_CHILD_DIARY_口上手紙(ARG)`, `_共通手紙(ARG, ARGS)`, `_寺子屋(ARGS, ARG, ARG:1)`. `ARG` is the child's index; `ARGS` is the event-flavor key.

In bodies, `%CHILDNAME:6:(TALENT:6:育児中)%` interpolates the child's name. `CFLAG:6:1001 == 1` may extend availability.

## Vocabulary used in bodies (this character's reference set)

### Output

- `PRINTFORML <text>` — formatted text + newline; allows `%...%` and `\@ ... \@` interpolation.
- `PRINTFORMW <text>` — same + then **wait for keypress**.
- `PRINTL <text>`, `PRINTW <text>` — non-formatted variants.
- `PRINTFORMDL - <text> ---` — formatted line w/ delimiter (used in diary headers).
- `PRINTDATA / DATAFORM <text> / ENDDATA` — randomly picks **one** of the contained DATAFORMs to print.
- `SETCOLOR <NAMED|HEX|R,G,B>` — change ink color.
  - Named constants used here: `C_CREAM`, `C_AQUA`, `C_PINK`. Other `C_*` likely exist.
  - Hex form: `SETCOLOR 0xf7c9ff`.
  - RGB form: `SETCOLOR 255,230,250`.
- `RESETCOLOR` — pop back to default.

### Interpolation

- `%CALLNAME:N%` — display name for character N (or `MASTER`/`PLAYER`/`TARGET`/`ASSI`).
- `%CHILDNAME:char:idx%` — name of child `idx` belonging to `char`.
- `%UNICODE(0xN) *1%` — print arbitrary unicode char (`0x2665` = ♥).
- `\@ <expr> ? <a> # <b> \@` — inline ternary. Evaluated, picks `<a>` or `<b>`.

### Control flow

- `IF / ELSEIF / ELSE / ENDIF` (block); `SIF` (single-line: applies only to the next statement).
- `SELECTCASE <expr> / CASE <vals|range> / CASEELSE / ENDSELECT`. Range: `CASE 0 TO 2`, comparison: `CASE Is >= 4`.
- `FOR LOCAL, start, end / NEXT`. End is exclusive.
- `RETURN <int>` (numeric), `RETURNF <int>` (within `#FUNCTION`).
- `$LABEL` followed later by `GOTO LABEL` — goto, used to retry an INPUT loop.
- `CALL <LABEL>(<args>)` — invokes a label. `TRYCALL <LABEL>` swallows missing-label.
- `CALLFORM <prefix>{<expr>}<suffix>` — dynamic-name call. `TRYCALLFORM` is its silent variant.

### Local variables

- `LOCAL`, `LOCALS`, `LOCAL:1`, `LOCAL:101`, … — auto-allocated function-locals (numeric and string namespaces). Indexed access (`:N`) gives "the Nth slot of LOCAL".
- `ARG`, `ARGS`, `ARG:1`, … — call args. Declared via `(ARG, ARGS, ARG:1)` in the label header or `#DIM ARG`/`#DIMS ARGS`.
- `#DIM <name>` (numeric), `#DIMS <name>` (string).

### Reading game state

- **Globals**: `TARGET` (current target char id), `MASTER`, `PLAYER`, `ASSI` (assistant), `SELECTCOM` (active command id, mutable), `RESULT`, `RESULTS`, `PREVCOM`, `RANDOM_CHARANUM`, `CHARANUM`, `TFLAG:50` (active SCOM id).
- **Time**: `TIME` (minutes-of-day; 360–1080 = 06:00–18:00), `TIME:2` (hour bucket), `TIME:5` (weather phase?), `DAY:0` (game day count).
- **Per-character namespaces** (always indexable by char id; default = `TARGET`):
  - `TALENT:N:slot` — talents like `恋慕`, `思慕`, `恋人`, `炮友`, `処女`, `兒童`, `年齢`, `幼児／幼児退行`, `胸圍`, `体型`, `形状`, `酒耐性`, `無接吻経験`.
  - `ABL:N:slot` — abilities: `親密`, `欲望`, `Ｂ感覚`, `Ａ感覚`, `Ｃ感覚`, `Ｖ感覚`, `料理技能`, `奉仕精神`, `教養`, `戦闘能力`, `露出癖`, `従順`.
  - `CFLAG:N:slot` (or `CFLAG:slot`) — character flags (named or numeric). E.g. `CFLAG:6:1001` (private author flag), `CFLAG:6:1002` (date-location memory), `CFLAG:6:現在位置`, `CFLAG:6:初期位置`, `CFLAG:6:面識`, `CFLAG:6:好感度`, `CFLAG:6:約会中`, `CFLAG:睡眠`, `CFLAG:318`, `CFLAG:诶嘿嘿`, `CFLAG:6:妊娠自覚状態`, `CFLAG:6:無自覚妊娠`, `CFLAG:6:没穿内裤`.
  - `TCVAR:N:slot` (or `TCVAR:slot`) — per-target variables: `TCVAR:破瓜`, `TCVAR:Ａ破瓜`, `TCVAR:中止接吻`, `TCVAR:20`, `TCVAR:100`/`101` (last V/A inserter ID), `TCVAR:102`/`104` (climax flags), `TCVAR:302`, `TCVAR:6:今天的礼物`, `TCVAR:烂醉`, `TCVAR:初次拥抱`, `TCVAR:媚薬`, `TCVAR:MASTER:112`.
  - `TEQUIP:N:slot` (or `TEQUIP:slot`) — current per-target equipment: `TEQUIP:口球`, `TEQUIP:眼罩`, `TEQUIP:縄`, `TEQUIP:50`/`51` (V/A insertion equipment slots, may equal a char ID like `MASTER`).
  - `MARK:N:slot` (or `MARK:slot`) — mark state: `MARK:不埒刻印`, `MARK:6:反発刻印`.
  - `EXP:N:slot` — experience: `EXP:接吻経験`, `EXP:6:学習経験`, `EXP:6:料理経験`.
  - `BASE:N:slot` — physiological base: `BASE:MASTER:勃起`.
  - `NOWEX:N:slot` — current physiological state: `NOWEX:PLAYER:射精`, `NOWEX:PLAYER:11`.
  - `PALAM:slot` — parameters: `PALAM:欲情`, `PALAMLV:N`.
- **Globals**: `FLAG:NUMBER` / `FLAG:NAME` — `FLAG:70` is "time-stop active" (alias `FLAG:時間停止`), `FLAG:扮演`, `FLAG:6` (something printed?), `FLAG:口上文本設定`, `FLAG:口上色`, `FLAG:口上セレクタ`, `FLAG:約会的对象`, `FLAG:甲斐性無`.
- **Diary**: `DIARY:N:M` per-page state, `MAX_DIARY_PAGE:N:0` total.

### Engine helpers (called as `CALL ...` or used in expressions)

- `RAND:N` — uniform 0..N-1.
- `FIRSTTIME(SELECTCOM)` — first execution this game.
- `FIRSTTIME(SELECTCOM, 1)` — first-execution gate (alt-arg form, seen elsewhere).
- `FIRSTTIME(TFLAG:50 + 500)` — SCOM first-time variant (offset to avoid overlap with COM).
- `FIRSTTIME(350,1)` — explicit numeric form.
- `GROUPMATCH(VAR, V1, V2, ...)` — bool: VAR is one of V1/V2/...
- `BATHROOM(loc?)`, `OUTROOF(loc?)`, `FINDCHARA(start, current)`, `SHIRAHU(N)`, `CHK_DATENOW(CFLAG:N:約会中)`.
- `MASTER_POSE(role, ?, ?)` — multi-person participant lookup; returns char id in `RESULT`.
- `ALCOHOL_TASTE(TFLAG:194)` — sake-flavor preference score.
- `GET_GIFTDATA(item, "得点")` — gift-table lookup.
- Quest helpers: `IRAI_ID_TO_CLIENT(IRAI_ID)`, `IS_COMMON_IRAI(IRAI_ID)`, `STR_DATA_IRAI(IRAI_ID, key, client)`, `CSVCALLNAME(client_id)`.
- `TIME_PROGRESS(TFLAG:膝枕した)` — minutes-since marker.
- Diary: `CHARA_DIARY_PAGESETTING(char, page)`.
- Subroutines called in scenes: `CALL TRAIN_MESSAGE`, `CALL EVENT_COUNTER_MESSAGE`, `CALL MARK_MESSAGE`, `CALL SPEVENT_MESSAGE_<n>(ARG, ARG:1)`, `CALL PRINT_FACE, char[, expr[, clothes[, variant]]]`, `CALL SPTALK, char, expr, ?, @"line // line // line"` (multi-line speech bubble; `//` separates lines, max 6).

### Meta / dispatcher contract

- Every body should `RETURN 1` (success) or `RETURN 0` (kōjō handled nothing — engine may fall back).
- The `LOCAL = 1 / 0` "記入チェック" pattern at the top of every body is the project-wide convention for "is this slot filled?". `LOCAL = 0` causes a quick fall-through to `RETURN 1` (silent). The engine then falls through to the catch-all `M_KOJO_MESSAGE_COM_K6_00` (not present in Luna) and finally to `EVENT_MESSAGE_*`.
- `IF FLAG:時間停止` (alias of `FLAG:70`) usually short-circuits with no print, *unless* `CFLAG:N:時間停止口上有 = 1` is set in `@M_KOJO_FLAGSETTING_K<id>`.
- `CFLAG:318 == 1` (whatever 318 means in CFLAG.csv — appears to be an "extreme rage / silent treatment" state) is the second-most-common short-circuit guard.

## Documented per-command state-table comments

Every command body opens with a doc-banner enumerating the relevant state vector:

```
;==================================================
;310,摸屁股
;TFLAG:193(1=不快(TALENT:膽怯なら涙目) 2&&3=恥ずかしがる … 4=されるがまま)
;CFLAG:诶嘿嘿==2&&TCVAR:20(70=強制舐陰 71=口交強制 72=肛門奉仕 …)
;CFLAG:诶嘿嘿==2&&TEQUIP:六九式(胖次ありTCVAR:20(70～72)はこちら)
;PREVCOM(305=膝枕
;TFLAG:400(1=约会先or地底の路人が反応する)
;==================================================
```

These comments are the *contract* for which discriminants the body should branch on. They are not formal — but every author follows the same convention, so a kōjō that ignores them silently degrades into the ELSE/CASEELSE branch.

## Persona-specific quirks (Luna)

- All daily/sex/sexual-harassment commands wrap their entire body in `IF TALENT:MASTER:年齢 == -1 || TALENT:MASTER:幼児／幼児退行 || CFLAG:6:1001 == 1`. If the player is an adult, Luna prints nothing — engine falls back to defaults.
- Three-way co-presence checks: `IF CFLAG:6:現在位置 == CFLAG:5:現在位置 && CFLAG:6:現在位置 == CFLAG:7:現在位置` activates joint-Sunny+Star scenes (chars 5 = Sunny, 7 = Star — the trio). Bodies switch character voice via `SETCOLOR` per speaker.
- Confession command 352 has a poetic-cryptic branch unlocked by `TIME:2 >= 5 && TIME:2 <= 7 && TIME:5 < 2 && ABL:MASTER:教養 > 1` — late-night, clear weather, educated player. Otherwise falls back to the standard branch.
- Counter 34 (`股間をまさぐる`) and similar bodies **mutate state** as a side-effect: `BASE:MASTER:勃起 += 5`. Bodies are not pure print.
- Mark command on `BASE:MASTER:勃起 >= 1000` adds an extra "I felt it" line in command 311 — bodies can read player physiological state to add color.
- `@M_KOJO_UPDATE_K6` confronts the player with a Y/N prompt (uses `INPUT` + `$LOOP / GOTO LOOP`), and the choice flips `CFLAG:6:1001` permanently. This is the canonical "config dialog" pattern in update hooks.
- `@M_KOJO_ENCOUNTER_K6` similarly offers an `INPUT`-driven stat retune (re-set Luna's `ABL:6:料理技能 = 3` etc).

## Heuristics for writing a new file in this style

1. Match the file taxonomy. If you write a daily command, put it in `M_KOJO_K<id>_日常系コマンド.erb`. The engine doesn't care, but readers, tools, and license templates assume this layout.
2. Always emit both `@M_KOJO_SUCCESS_COM_K<id>_<N>` (set `TFLAG:192 = 0`) and `@M_KOJO_MESSAGE_COM_K<id>_<N>` for any command you handle.
3. Every body opens `LOCAL = 1` / `LOCAL = 0` as the flip switch. Stubs with `LOCAL = 0` are intentional — keep them.
4. Use `IF FLAG:時間停止` and `IF CFLAG:睡眠` early-outs.
5. The hierarchy of preference for branches in a daily-life command is conventionally:
   `FLAG:70 → CFLAG:睡眠 → CFLAG:诶嘿嘿==2 (situational) → TCVAR:20 (sub-action) → TALENT:恋慕 → TALENT:思慕 → ABL:N:thresholds → ELSE`.
6. Every printed line should end with a wait — last `PRINTFORML` of a body is usually a `PRINTFORMW` instead, so the player advances. Bodies that fall through to `RETURN 1` without printing are silent (relying on the engine's TRAIN_MESSAGE).
7. Use `%CALLNAME:MASTER%` not "你"/"主人公" — names are user-configurable.
8. For random variations, prefer `SELECTCASE RAND:N` with an explicit `CASEELSE` for the highest-probability default. Use `PRINTDATA / DATAFORM / ENDDATA` only for *one*-line random variants where structure is identical.
9. `RETURN 1` from a body marks it handled. `RETURN 0` is rarely used (and tells the engine to also print its own narration) — only Luna's existence/UPDATE labels return 0/non-1.
