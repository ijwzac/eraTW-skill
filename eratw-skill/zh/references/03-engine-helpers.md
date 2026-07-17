# 引擎 helper（完整参考）

## 5. 引擎 helper

### 5.1 前置消息与协同

```erb
CALL TRAIN_MESSAGE                  ; 针对 COM 的引擎前置旁白
CALL EVENT_COUNTER_MESSAGE          ; 针对 COUNTER 的引擎前置旁白
CALL MARK_MESSAGE                   ; 针对 MARKCNG 的引擎前置旁白
CALL SPEVENT_MESSAGE_<n>(ARG, ARG:1); 针对 SPEVENT n 的引擎前置旁白
CALL AUTO_AEGI(N)                   ; 引擎兜底自动喘息
CALL ADD_KISS                       ; 递增接吻计数器
```

### 5.2 UI 提示

```erb
CALL ASK_YN                            ; 默认标签：[0] はい / [1] いいえ
CALL ASK_YN("yes-text", "no-text")    ; 把 RESULT 设为 0（是）或 1（否）——注意极性
CALL ASK_M("opt0", w0, "opt1", w1, …) ; 多选；w=0 置灰，w=1 启用；RESULT = 索引
INPUT                                  ; 读整数 → RESULT
INPUTS                                 ; 读字符串 → RESULTS
PRINTBUTTON @"label", @"return-string"
```

`ASK_YN` / `ASK_M` 两者内部都会对无效输入循环重试——你无需再自己包一层输入循环。`ASK_M` 的逐选项权重表达式在为假时会变灰（不可选）：

```erb
CALL ASK_M("买",     MONEY >= 1000,       \
           "不买",   1,                     \
           "撒娇",   TALENT:MASTER:謎の魅力,\
           "抢走",   ABL:MASTER:戦闘能力 >= 3)
SELECTCASE RESULT
    CASE 0    ;买了
    CASE 1    ;拒绝
    CASE 2    ;撒娇
    CASE 3    ;抢走
ENDSELECT
```

### 5.3 图像 / 表情 / 对话

```erb
CALL PRINT_FACE, char_id, expr[, clothes[, variant]]
;   expr  ∈ "通常", "笑顔", "発情", "憤怒", "睡眠", "性交", "自慰", "笑", ...
;   clothes ∈ "服", "服1", "裸", ...
;   variant ∈ "_1", "_2", "_変更後", ...

CALL SPTALK, char_id, expr, ?, @"line // line // line"  ; 最多 6 行，// 为换行

CALL HPH_PRINT, @"<带 HPH 后缀和 \@…\@ 三元式的文本>", "L"
CALL 画像セット(@"顔絵_<state>_<expr>_{[[N]]}", x, y, w, h, _, _, "default")
CALL 画像一斉表示("左", 0, 1)
CALL PRINT_GROUP(LOCALS, 3, 350)    ; 打印 N 个条目，带延迟
```

### 5.4 姿势 / 状态 / 装备

```erb
CALL TOUCH_SET(SET_FROM_YUBI, 1, [[N]])   ; 登记触碰
CALL EVENT_COUNTER_POSE_69([[N]], M)       ; 设置 69 姿势
CALL DATUI_BOTTOM([[N]], M)                ; M=1 拉下，M=2 脱去
CALL DATUI_TOP, CALL DATUI_INNER           ; 同一族
```

### 5.5 判定式 / 访问器

```erb
RAND:N, RAND(N)
FIRSTTIME(SELECTCOM)                       ; 首次使用某命令
FIRSTTIME("UP01", 0, 49)                   ; 以字符串为键的 firsttime
GROUPMATCH(VAR, V1, V2, V3)                ; 等价于 ==
BATHROOM(loc), OUTROOF(loc), DATE_HITOGOMI(loc), WITH_MOB()
GET_MAPID(loc)
GET_TARGETNUM()                            ; 当前房间中的角色数
FINDCHARA(start_loc, current_loc)
SHIRAHU(N)                                 ; 角色 N 处于正常状态
CHK_DATENOW(CFLAG:N:约会中)                ; 约会正在进行中（注意是简体 约！）
;
; 关键——`CFLAG:N:约会中` 不是布尔值；它在约会开始时存储的是
; MAIN_MAP 代码。在本角色历史上发生过任何一次约会之后，该槽位就
; 保留着那个地图代码（例如 5），并且永远不会自动重置。所以
; `IF CFLAG:N:约会中` 实际上是 `IF 5` = 首次约会后恒为真。
;
; 规范的「当前正在约会」判定使用 CHK_DATENOW（它比较存储的地图与
; 当前 MAIN_MAP），并同时核实对象：
;     IF CHK_DATENOW(CFLAG:MASTER:约会中) && FLAG:约会的对象 == TARGET
;
; 反模式（首次约会后恒为真）：
;     IF CFLAG:TARGET:约会中               ;不要这样做
CHK_FOCUS(start, current, end)             ; 区间检查
MASTER_POSE(role, ?, ?)                    ; 多人场景 id 查表
ALCOHOL_TASTE(TFLAG:194), ALCOHOL_FACE()
ESTRUS_CYCLE(N)
SYNCED_ORGASM(N)
TIME_PROGRESS(TFLAG:<key>)
NEMUKE()                                   ; 困倦度
CHARA_HOLIDAY(N)
GET_SUCCESS_RATE()
GETDEFCOLOR()
```

### 5.6 任务 / 礼物 / 日记 helper

```erb
IRAI_ID_TO_CLIENT(IRAI_ID)
IS_COMMON_IRAI(IRAI_ID)
STR_DATA_IRAI(IRAI_ID, "依頼名", CLIENT_ID)
CSVCALLNAME(client_id)
GET_GIFTDATA(item_id, "得点")
CHARA_DIARY_PAGESETTING(char, page)
```

### 5.6.1 便捷文本 + EXP

```erb
%TEXTR("A/B/C")%                           ; 内联随机文本变体（在 PRINTFORM* 内使用）
%TEXTR("A/B/C/")%                          ; 结尾斜杠会额外加一个空字符串选项
CALL HPH_PRINT(@"text with HPH ♥", "L")    ; 打印文本，其中 HPH 展开为粉色爱心；模式 "L"/"W"/"D" 设定等待
CALL AddEXP("<exp-slot>", <char>, <delta>) ; 等价于 `EXP:<char>:<slot> += <delta>` + 自动黄色 "X +N (callname)" 消息
```

用 `AddEXP` 代替手动 `EXP:N:slot += K / SETCOLOR / PRINTFORMW / RESETCOLOR`——更短，且不会拼错那个黄色颜色常量。

当每个备选项都是单条短语时，`TEXTR` 比 `SELECTCASE RAND:N` 更轻量。把 SELECTCASE 留给带多行或带副作用的分支。

### 5.7 作者 helper 约定

如果你要写一个函数库，请使用以下命名习惯（对齐 Eiki K30 的原版）：

```erb
@K{id}_FIND_LOVER()      #FUNCTION   ; -1=本角色, 0=无, 1=在别处, 2=在房间内
@K{id}_FIND_AROUND(ARG = 0)  #FUNCTION  ; 最近的已知角色 id
@K{id}_DRUNK()           #FUNCTION   ; 0..3
@K{id}_BOKKI()           #FUNCTION   ; 0..3
@K{id}_BE_SEEN()         #FUNCTION   ; 0/1
@K{id}_C_NAME(ARG, TYPE = 0)  #FUNCTIONS  ; 本角色如何称呼另一角色
@K{id}_GREETING()        #FUNCTIONS  ; 按时段的问候
@K{id}_AENAI                          ; 「距上次相见多少天」的开场白
@K{id}_KOUSAI                         ; 纪念日
@K{id}_NURESUKE()                     ; 湿润度/透明度
@K{id}_AMANURE                        ; 下雨触发
@K{id}_ROOM_DESCRIPTION()             ; 房间描述
@K{id}_SET_C_NAME(ARG)                ; 交互式昵称对话
```

---
