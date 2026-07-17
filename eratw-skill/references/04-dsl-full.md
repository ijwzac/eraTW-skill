# DSL（Emuera-script）——完整入门

SKILL.md 把标准正文形态（Standard Body Shape，§6）保留在正文内联，因为它是最常复用的模板。本文件收纳其余的语言参考。

## 3. DSL（Emuera-script）——入门

### 3.1 变量与数组

```erb
LOCAL = 1                  ; 数值局部变量——自动分配
LOCAL:1 = 5                ; LOCAL 数组的第二个槽位
LOCALS = "hello"           ; 字符串局部变量
LOCALS:1 = "world"

#DIM CONST K_FOO = 1100    ; 编译期常量
#DIM 知り合い, 6 = 29, 65, 51, 49, 38, 1   ; 数组字面量初始化
#DIM SAVEDATA RAGE_GAUGE   ; 逐角色，跨存档持久化
#DIMS SAVEDATA NICKNAME    ; 同上，字符串
#DIM SAVEDATA GLOBAL G     ; 全局持久化（谨慎使用）
#LOCALSIZE 200             ; 扩展局部数组
```

**默认参数**（仅限位置——Emuera 不允许自定义参数名）：
```erb
@MY_HELPER(ARG, ARG:1 = 0)
;若调用方省略 ARG:1，则默认为 0
;          ─────────
;          必须是 ARG / ARG:N / ARGS / ARGS:N——自定义名字如
;          `TYPE`、`OPTION`、`相手残機` 会引发编译警告
;          "参数错误:变量"X"未在此函数中定义"，且该变量在函数体内
;          变得不可读。
;
;若你想在函数体内获得命名式的可读性，请在顶部起别名：
;@MY_HELPER(ARG, ARG:1 = 0)
;TYPE = ARG:1
;... 下方随意使用 TYPE ...
```

少数遗留口上（K5、K6、K7）用了 `@FOO(ARGS, 相手残機)` 后紧跟一行 `#DIM 相手残機` 的变通写法——这能编译并运行，但在加载时产生 Lv2 警告。新口上不要复制这种风格；请用位置参数 + 别名。

**函数标记**——用于表达式内可调用的函数：
```erb
@MY_INT_FUNC()
#FUNCTION
RETURNF 42

@MY_STR_FUNC()
#FUNCTIONS
RETURNF "hello"
```

使用处：`IF MY_INT_FUNC() > 0 ...`、`PRINTFORML 「%MY_STR_FUNC()%」`。

### 3.2 控制流

```erb
IF cond
ELSEIF cond
ELSE
ENDIF

SIF cond                    ; 单行：只作用于紧接的下一条语句
    PRINTFORML something

SELECTCASE expr
    CASE 0, 2, 4            ; 多值匹配
    CASE 5 TO 10            ; 区间
    CASE Is >= 100          ; 比较
    CASEELSE
ENDSELECT

FOR LOCAL, 0, 10            ; 结束值不含在内——运行 0..9
NEXT
WHILE cond
WEND
BREAK
CONTINUE

$LOOP                       ; goto 标签
... 
GOTO LOOP                   ; 跳转到 $LOOP

[SKIPSTART]                 ; 预处理器：跳过
... (被注释掉的源代码)
[SKIPEND]
```

### 3.3 调用

```erb
CALL MY_LABEL                       ; 调用；忽略任何返回值
CALLF MY_INT_FUNC(args)             ; 调用 #FUNCTION
TRYCALL MY_LABEL                    ; 缺失时静默
CALLFORM SOME_PREFIX{LOCAL}_SUFFIX  ; 动态构造名字
TRYCALLFORM ...                     ; 动态调用，缺失时静默
TRYCCALLFORM ... CATCH ... ENDCATCH ; 动态 try/catch
RETURN 1                            ; 从正文返回数值
RETURN                              ; 空返回
```

### 3.4 输出

```erb
PRINTFORML 「这是一句日语风的台词%CALLNAME:MASTER%」    ; 格式化 + 换行
PRINTFORMW <text>                                       ; 格式化 + 等待按键
PRINTL <text>                                           ; 非格式化行
PRINTW <text>                                           ; 非格式化等待
PRINTFORMD <text>                                       ; 格式化，描述性（无旁白前缀）
PRINTFORMDL <text>                                      ; 格式化，描述性，换行
PRINTFORMDW <text>                                      ; 格式化，描述性，等待

PRINTDATA                                              ; 引擎随机挑选其中一条
    DATAFORM 选项一
    DATAFORM 选项二
    DATAFORM 选项三
ENDDATA
PRINTDATAW                                              ; 同上，带等待
PRINTDATAL                                              ; 同上，带换行

PRINTBUTTON @"按钮文字", @"按钮按下后RESULTS的值"
```

### 3.5 颜色

```erb
SETCOLOR C_CREAM                ; 具名：C_CREAM, C_AQUA, C_PINK, C_DEFCOLOR, C_HTML
SETCOLOR 0xFF69B4               ; 十六进制
SETCOLOR 255, 105, 180          ; RGB
RESETCOLOR
```

### 3.6 字符串插值形式

| 形式 | 用途 |
|---|---|
| `%CALLNAME:N%` | 角色 N（或 `MASTER`/`PLAYER`/`TARGET`）的显示名。 |
| `%MASTERNAME:N%` | 逐角色对 MASTER 的昵称（可变）。 |
| `%CHILDNAME:char:idx%` | 孩子的名字。 |
| `%TEXTR("a/b/c/d")%` | 随机挑选。 |
| `%UNICODE(0xN)%` | unicode 字符（`0x2665` = ♥）。`* N` 表示重复。 |
| `\@ <expr> ? <a> # <b> \@` | 内联三元式。 |
| `%CSVCSTR(N, slot)%` | 逐角色 CSV 字符串查表。 |
| `%CSTR:N:slot%` | 逐角色可变字符串。 |
| `%CALLNAME:N%`、`%PANTSNAME(EQUIP:..., N)%`、`%CLOTHNAME(slot, EQUIP:N:slot)%`、`%OPPAI_DESCRIPTION(N, 1)%` | 引擎 helper。 |
| `%K{id}_<func>(args)%` | 调用作者的 `#FUNCTIONS` 并插值。 |

### 3.7 特殊记号

- `[[<name>]]`——解析期角色 id 查表（例如 `[[極]]` → 42）。**重要怪癖：**
  - **`[[X]]` 只解析 `CSV/STR.csv` 中的名字**，不解析 `CSV/Chara/Chara<N> *.csv` 中的名字。大多数你会想用的角色名（`[[アリス]]`、`[[ルナサ]]`、`[[メルラン]]`、`[[幽々子]]`、`[[ライコ]]` 等）**都不在 STR.csv 中**，尽管它们的 CSV 文件确实存在。它们会静默失败——未解析时 `[[X]]` 变成字面量 `0`，所以 `CASE [[ルナサ]]` 变成 `CASE 0`，会匹配 ARG=0。
  - **`MASTER`、`TARGET`、`PLAYER`、`ASSI` 是内建的数值伪常量**——直接裸写它们，绝不要写成 `[[MASTER]]`（那是错的，会产生警告）。
  - **推荐默认做法**：使用数值角色 ID，并加注释说明该 ID，例如 `CASE 22  ;ルナサ Lunasa`。这总是有效，且在 grep 时更易读。把 `[[X]]` 留给你已核实存在于 `STR.csv` 中的名字（大多是地点名以及一小撮主要角色如 `[[極]]`/`[[文]]`）。
  - **使用 `[[X]]` 前如何核实**：在 `STR.csv` 中 grep 精确的名字（逐字节精确，含汉字字形）。如果没出现，回退到数值 ID + 注释。
- `@"text"`——支持 `//` 换行的字符串字面量。
- `DATAFORM` 内的 `\n`——换行。

### 3.8 内建数学/字符串运算

| 运算 | 说明 |
|---|---|
| `RAND:N`、`RAND(N)` | 均匀分布 0..N-1。 |
| `MAX(a, b)`、`MIN(a, b)`、`ABS(n)` | 数学。 |
| `INRANGE(v, lo, hi)` | 边界检查。 |
| `STRLENS(s)`、`STRLENSU(s)` | 字节/字符长度（U 版本感知 unicode）。 |
| `STRCOUNT(s, "regex")` | 统计正则匹配数。 |
| `REPLACE s, "pattern", "repl"` | 就地替换。 |
| `FINDELEMENT(arr, val, start)` | 查找数组索引。 |
| `SETBIT v, k`、`CLEARBIT v, k`、`GETBIT(v, k)` | 位运算。 |
| `INPUT`（整数 → RESULT）、`INPUTS`（字符串 → RESULTS） | 用户输入。 |
| `TWAIT <ms>, <flag>`、`GETKEY(<n>)` | 等待 / 读取按键。 |
| `CLEARLINE <n>`、`REUSELASTLINE <text>` | UI 操作。 |
| `REDRAW <mode>`、`CURRENTREDRAW()`、`LINECOUNT` | 绘制模式。 |
| `VARSET <name>`（清空）、`VARSET <name> <value>`（设置） | 变量重置。 |
| `TIMES <var>, <factor>` | 乘以浮点数，结果写回。 |

---
