# EVENT_K_X subphase reference (ARG semantics per slot)


The engine fires several EVENT slots **multiple times per turn** with `ARG` distinguishing the sub-phase. **If you ignore ARG**, the body fires for every sub-phase (3-5 times per visit) and the dialogue prints repeatedly. Always branch on ARG, and `RETURN 0` from each branch (so other sub-phases can match).

Authoritative ARG semantics (extracted from 001 Reimu / 霊夢 reference):

**`@M_KOJO_EVENT_K{id}_1(ARG, ARG:1)` — room/cell encounter.** Fires once **per cell transition the character makes on the same world map** as MASTER, even if MASTER is in a different cell. **Mandatory first guard:**
```erb
@M_KOJO_EVENT_K{id}_1(ARG, ARG:1)
LOCAL = 1
SIF !LOCAL || FLAG:時間停止
    RETURN 0
;Engine fires this on every NPC cell-step. Reject when not co-located:
SIF CFLAG:{id}:現在位置 != CFLAG:MASTER:現在位置
    RETURN 0
;Then branch on ARG sub-phase:
SELECTCASE ARG
    CASE 1   ;MASTER walks in, char already in room
        ...
        RETURN 0
    CASE 2   ;char walks in, MASTER already in room
        ...
        RETURN 0
    CASE 3   ;char enters bathroom while MASTER bathing — joins
        ...
        RETURN 0
    CASE 4   ;char enters bathroom, exits politely
        ...
        RETURN 0
    CASE 5   ;char enters bathroom, MASTER kicks them out
        ...
        RETURN 0
ENDSELECT
RETURN 0
```

**`@M_KOJO_EVENT_K{id}_2(ARG, ARG:1)` — morning.** Fires for every char on the same world-map as MASTER, every morning — even if char is in a different cell. **Same first guard required:**
```erb
SIF CFLAG:{id}:現在位置 != CFLAG:MASTER:現在位置
    RETURN 0
```

**`@M_KOJO_EVENT_K{id}_3(ARG, ARG:1)` — bedtime.** Same map-vs-cell distinction as `_2`. Same guard required.

For other EVENT slots (4..30+), check the corresponding body in 001 Reimu's kojo for ARG semantics; the pattern of "guard first, branch ARG, RETURN 0 per branch" applies universally.

**Why this isn't obvious from the engine source**: the dispatcher in `KOJO_MESSAGE.ERB` doesn't filter by current-cell; it filters only by *map presence*. The cell check is the kojo's responsibility. Most reference kojo include this guard but they don't emphasize it — it has to be observed by reading them.

