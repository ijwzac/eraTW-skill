# EVENT_K_X subphase reference (ARG semantics per slot)

**For the complete ARG-map table covering all 34 EVENT slots, see `01-engine-label-catalog.md` §2.4.2.** This file zooms in on the slots where the cell-guard pattern is critical (slots 1/2/3) and explains *why* the pattern is mandatory.

The engine fires several EVENT slots **multiple times per turn** with `ARG` distinguishing the sub-phase. **If you ignore ARG**, the body fires for every sub-phase (3-5 times per visit) and the dialogue prints repeatedly. Always branch on ARG, and `RETURN 0` from each branch (so other sub-phases can match).

Authoritative ARG semantics (cross-checked between `001 Reimu / 霊夢` filled-in kojo, the official empty template `reference-kojo/口上テンプレ/M_KOJO_KX_イベント.ERB`, and `口上作者様へ.txt`):

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

For other EVENT slots (4..34), see the table in `01-engine-label-catalog.md` §2.4.2 — most don't need the cell-guard (they're already gated by the trigger), but the pattern of "branch ARG, RETURN 0 per branch" applies universally for any slot where ARG has multiple values.

**Why this isn't obvious from the engine source**: the dispatcher in `KOJO_MESSAGE.ERB` doesn't filter by current-cell; it filters only by *map presence*. The cell check is the kojo's responsibility. Most reference kojo include this guard but they don't emphasize it — it has to be observed by reading them.


---

## Finding what each EVENT/SPEVENT slot & ARG means (authoritative)

The engine dispatches kojo events with `CALL KOJO_MESSAGE_SEND("EVENT"|"SP_EVENT", <slot>, ARG, <sub>[, ...])`, and **every call site is commented `;<口上名>,<sub>,<描述>`**. So the ground truth for "when does `@M_KOJO_EVENT_K{id}_<slot>` fire and what is each ARG sub-phase" is the callers, NOT this doc. Grep the engine (exclude `個人口上/`):

```
grep -rnB1 'KOJO_MESSAGE_SEND("EVENT", *<slot>' ERB/
```

Richest call sites: `ERB/MOVEMENTS/MOVEMENT2.ERB` (@KITAKU 帰宅/约会), `ERB/COMMON.ERB`, `ERB/ANOTHER_TALK.ERB`, `ERB/MOVEMENTS/JOB_仕事開始終了処理.ERB`.

**Confirmed mappings (this fork):**

| slot | 口上名 | fires when | ARG sub-phases (from call-site comments) |
|---|---|---|---|
| EVENT 1 | 遭遇 | you & char share a cell | 1=你进来 2=她进来 3-5=浴室 6=外出遭遇 7=约会中撞见 8=当日室内首次问候 9=当日外出首次问候 (see §2.4.2) |
| EVENT 2 | 朝(起床) | around her `CFLAG:起床時間` | (morning greeting) |
| EVENT 3 | おやすみ(就寝) | around her `CFLAG:就寝時間` | 2=就寝前 3=睡眠中 7=部屋から出て寝た… |
| EVENT 20 | **帰宅口上** | **date/outing end — @KITAKU** | **1=通常帰宅 2=约会中帰宅 3=玄関先見送り 4=邀去房间 5=同行 6=拒绝 7=今夜不想回 8=留宿 9=断った** |
| EVENT 21 | 陥落素質取得 | 关系升级 | 1=恋慕 3=爱欲 5=炮友 |
| EVENT 26 | ONABARE(被撞见自慰) | — | 0/2/4 phases |
| SP_EVENT 1/2/3 | 约会帰り里程碑/兜底 | 约会归途（玩家手动结束这条路） | 1=初吻 2=告白 **3=兜底：已初吻·未到告白时每次手动结束约会都走这里** |

### ⭐GIFT 事件的 ARG 分档（`@M_KOJO_EVENT_K{id}_GIFT`）

`@M_KOJO_EVENT_K{id}_GIFT(ARG, GIFT_ID, 評価点, GIFT_NAME, SENSE)` —— 收到礼物。派发源＝`ERB\イベント関連\贈り物関連\贈り物.ERB:310-346`。
参数名是**作者自取**的（引擎只按位置传值），故 body 里必须 `#DIM 評価点` / `#DIMS GIFT_NAME` 之类声明，否则恒读到 0/空（坑 #1）。

| ARG | 含义 | 触发条件（`評価点` 范围 0–999） |
|---|---|---|
| 1 | 角色主动回赠 | 她送你东西时 |
| 2 | **珍藏** | `評価点 >= 700`，**每次都发** |
| 3 | 刷新「最爱」纪录 | `評価点 >= 700` **且** ≥ 她收过的历史最高分（`CFLAG:{id}:获得的礼物`） |
| 4 | **普通收下** | `400 <= 評価点 <= 699` —— **最常见的一档** |
| 5 | 偷偷变卖 | `評価点 < 400` |

三个容易写错的地方：

- **ARG 2 与 ARG 3 会【连发】**：`贈り物.ERB:320` 先发 ARG 2，`:327` 判定破纪录后**再追发** ARG 3。所以 ARG 3 里别重复完整反应——ARG 2 放主反应、ARG 3 只补一句「这是我收到过最喜欢的」，否则玩家一次送礼要看两段雷同长文。
- **别把重要解锁挂在 ARG 3 上**：`評価点 >= 700` 本身就要命中 4 条以上喜好 tag（中性礼物≈500 落 ARG 4；只命中一条强喜好≈666，仍是 ARG 4；≥800 极罕见）。再叠一个「破历史纪录」，等于几乎不触发。要做「她很喜欢时解锁 X（日记页之类）」，挂 **ARG 2**。
- **别只写 ARG 3/1/5**：那样 400–699（最常见）以及每一次 ≥700 的送礼都没有她的反应，只剩引擎通用旁白。至少写 **2 和 4**。

### ⭐约会结束的两条独立路径（实测查明，务必分清）
约会有两种结束方式，**由不同引擎函数派发到不同口上标签，互不调用**：
- **路径①：玩家用「从外面回家」命令手动结束**（`外出先から帰宅.ERB:120-129` / `COMF464`）→ 调 `@DATE_EVENT`（`DATE_CMN.ERB:175-294`）：未被吻过发 **SP_EVENT 1(初吻，门槛=思慕即可)**、达阈值发 **SP_EVENT 2(告白)**、**其余落 SP_EVENT 3(兜底)**。**这条路从不调 `@KITAKU`，所以 EVENT 20 永不触发。**
- **路径②：角色自己到点回家 —— 分「访客/住人」两种，落点不同（重要）**：
  - **访客**（`CFLAG:角色:神社在住 == 0`，即该角色**不住在当前舞台 MAP** 上）：到 **`帰宅時間`**（`!VISIT`，`VISIT=TIME∈[来訪時間,帰宅時間)`，`COMMON.ERB:728`）→ `訪問帰宅処理`/`待客室処理` → `@KITAKU`（`MOVEMENT2.ERB`）→ **EVENT 20**（ARG 见上表）。
  - **住人**（`神社在住 != 0`，该角色住在当前 MAP）：`訪問帰宅処理` 对住人整段跳过、`@KITAKU` 开头 `SIF 神社在住 RETURN`——**住人根本不发 EVENT 20**。住人的约会自然结束靠 **`就寝時間`**（`睡眠時間()`）→ `CHARA_SLEEP`/`SLEEP_RESIDENT`（`SLEEP.ERB:277`）→ **EVENT 3 おやすみ口上（子 1-1「约会中に帰って寝る」）**。
  - **`神社在住` 由开局舞台定**（`MAP_DEFAULTRESIDENT`，据 CSV `初期位置/100 == MAIN_MAP`）：如露娜 `初期位置=33`→33/100=0→**在默认神社(MAP 0)开局她是住人**（约会到 `就寝2:00` 走 EVENT 3）；只有在她不住的舞台(`MAIN_MAP!=0`)她才是访客（约会到 `帰宅20:00` 走 EVENT 20）。
  - ⚠所以 `帰宅時間`(EVENT 20 那条) ≠ `就寝時間`(EVENT 3 那条)，别混：露娜 `来訪10:30/帰宅20:00/就寝2:00/起床8:00`（`Chara6.csv`）。两个 handler（EVENT_3 与 EVENT_20）都要写，但触发身份不同。
- **路径③：约会中「倦意归途」**（醒满 12 小时 `NEMUKE()>=720`，或酒气爆表）→ `デート終了タイムアップ処理.ERB @约会終了タイムUP処理`。**它不调 @KITAKU**；EVENT 20 只在该角色 `CFLAG:衰弱`(体力曾<500)为真时才发(ARG=2「筋疲力尽回去」)，否则**默认不发任何口上**、只 `SET_DATE(99)` 静默结束。→ 玩家"熬夜到天亮但体力还满地各自散伙"时，**露娜等非衰弱角色收不到任何归宅口上，这是设计如此**（`NEMUKE` 是纯作息/清醒时长，`COMMON.ERB:1165`，与体力无关）。想让这种情形也有台词，只能改引擎 `デート終了タイムアップ処理.ERB`（放宽第76行 `衰弱` 守卫为"参与约会者"），属引擎侧改动、在口上目录外。
- **玩家绝大多数是手动点「回家」结束约会 → 路径① → 初吻后每次都落 SP_EVENT 3。因此 `@M_KOJO_SPEVENT_K{id}_3` 才是实际游玩中最常触发的"约会归来"落点，应写丰富**（可按 思慕/恋慕/恋人 分层）。**别把它留空桩**——会导致"约会归来什么台词都没有"（露娜初版踩过这坑）。EVENT 20 那套要角色自然到点回家才走，玩家不一定碰得到。
- （⚠本文档旧版曾断言"约会归来只走 EVENT 20 ARG 2、不走 SPEVENT_3"，只说对了路径②、漏了玩家最常走的路径①，已订正。）

Char sleep/wake times are per-char in `CSV/Chara/CharaN.csv` (`就寝時間`/`起床時間`, minutes; `就寝` clamped ≤120=02:00).
