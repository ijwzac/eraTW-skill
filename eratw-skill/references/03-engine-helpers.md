# Engine helpers (full reference)

## 5. Engine helpers

### 5.1 Pre-message & cooperation

```erb
CALL TRAIN_MESSAGE                  ; engine pre-narration for COMs
CALL EVENT_COUNTER_MESSAGE          ; engine pre-narration for COUNTERs
CALL MARK_MESSAGE                   ; engine pre-narration for MARKCNG
CALL SPEVENT_MESSAGE_<n>(ARG, ARG:1); engine pre-narration for SPEVENT n
CALL AUTO_AEGI(N)                   ; engine fallback auto-moan
CALL ADD_KISS                       ; increment kiss counter
```

### 5.2 UI prompts

```erb
CALL ASK_YN("yes-text", "no-text")    ; sets RESULT to 0 (yes) or 1 (no) — note polarity
CALL ASK_M("opt0", w0, "opt1", w1, …) ; multi-choice; w=0 grey-out, w=1 enable; RESULT = idx
INPUT                                  ; read int → RESULT
INPUTS                                 ; read str → RESULTS
PRINTBUTTON @"label", @"return-string"
```

### 5.3 Image / face / talk

```erb
CALL PRINT_FACE, char_id, expr[, clothes[, variant]]
;   expr  ∈ "通常", "笑顔", "発情", "憤怒", "睡眠", "性交", "自慰", "笑", ...
;   clothes ∈ "服", "服1", "裸", ...
;   variant ∈ "_1", "_2", "_変更後", ...

CALL SPTALK, char_id, expr, ?, @"line // line // line"  ; up to 6 lines, // is line break

CALL HPH_PRINT, @"<text with HPH suffix and \@…\@ ternaries>", "L"
CALL 画像セット(@"顔絵_<state>_<expr>_{[[N]]}", x, y, w, h, _, _, "default")
CALL 画像一斉表示("左", 0, 1)
CALL PRINT_GROUP(LOCALS, 3, 350)    ; print N items with delay
```

### 5.4 Pose / state / equip

```erb
CALL TOUCH_SET(SET_FROM_YUBI, 1, [[N]])   ; register touch
CALL EVENT_COUNTER_POSE_69([[N]], M)       ; set 69 pose
CALL DATUI_BOTTOM([[N]], M)                ; M=1 pull down, M=2 strip
CALL DATUI_TOP, CALL DATUI_INNER           ; same family
```

### 5.5 Predicates / accessors

```erb
RAND:N, RAND(N)
FIRSTTIME(SELECTCOM)                       ; first time using cmd
FIRSTTIME("UP01", 0, 49)                   ; string-keyed firsttime
GROUPMATCH(VAR, V1, V2, V3)                ; equivalent to ==
BATHROOM(loc), OUTROOF(loc), DATE_HITOGOMI(loc), WITH_MOB()
GET_MAPID(loc)
GET_TARGETNUM()                            ; chars in current room
FINDCHARA(start_loc, current_loc)
SHIRAHU(N)                                 ; char N in normal state
CHK_DATENOW(CFLAG:N:约会中)                ; date currently underway (note simplified 约!)
;
; CRITICAL — `CFLAG:N:约会中` is NOT a boolean; it stores the MAIN_MAP code at
; date start. After ANY date in this character's history, the slot holds that
; map code (e.g. 5) and is NEVER auto-reset. So `IF CFLAG:N:约会中` is
; effectively `IF 5` = always true after first date.
;
; The canonical "currently dating" predicate uses CHK_DATENOW (which compares
; the stored map vs. current MAIN_MAP) AND verifies the partner:
;     IF CHK_DATENOW(CFLAG:MASTER:约会中) && FLAG:约会的对象 == TARGET
;
; Anti-pattern (always-true after first date):
;     IF CFLAG:TARGET:约会中               ;DON'T DO THIS
CHK_FOCUS(start, current, end)             ; range check
MASTER_POSE(role, ?, ?)                    ; multi-person scene id lookup
ALCOHOL_TASTE(TFLAG:194), ALCOHOL_FACE()
ESTRUS_CYCLE(N)
SYNCED_ORGASM(N)
TIME_PROGRESS(TFLAG:<key>)
NEMUKE()                                   ; sleepiness
CHARA_HOLIDAY(N)
GET_SUCCESS_RATE()
GETDEFCOLOR()
```

### 5.6 Quest / gift / diary helpers

```erb
IRAI_ID_TO_CLIENT(IRAI_ID)
IS_COMMON_IRAI(IRAI_ID)
STR_DATA_IRAI(IRAI_ID, "依頼名", CLIENT_ID)
CSVCALLNAME(client_id)
GET_GIFTDATA(item_id, "得点")
CHARA_DIARY_PAGESETTING(char, page)
```

### 5.7 Author-helper conventions

If you write a function library, use these naming idioms (mirroring the Eiki K30 originals):

```erb
@K{id}_FIND_LOVER()      #FUNCTION   ; -1=this char, 0=none, 1=elsewhere, 2=in-room
@K{id}_FIND_AROUND(ARG = 0)  #FUNCTION  ; nearest known char id
@K{id}_DRUNK()           #FUNCTION   ; 0..3
@K{id}_BOKKI()           #FUNCTION   ; 0..3
@K{id}_BE_SEEN()         #FUNCTION   ; 0/1
@K{id}_C_NAME(ARG, TYPE = 0)  #FUNCTIONS  ; how this char calls another
@K{id}_GREETING()        #FUNCTIONS  ; time-of-day greeting
@K{id}_AENAI                          ; "days since seen" intro line
@K{id}_KOUSAI                         ; anniversary
@K{id}_NURESUKE()                     ; wetness/transparency
@K{id}_AMANURE                        ; rain trigger
@K{id}_ROOM_DESCRIPTION()             ; room description
@K{id}_SET_C_NAME(ARG)                ; interactive nickname dialog
```

---

