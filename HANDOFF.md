# HANDOFF — eraTW 口上(kojo)写作 SKILL + 露娜(K6)测试用例

> **权威现状/待办以记忆文件为准**：`C:\Users\lzh\.claude\projects\d--Game-TouHou-Yoiyami-Dreamer-datas-eraTW\memory\luna-kojo-pending-todo.md`（每轮更新，含全部引擎知识与本轮改动）。本文件只做高层导航。
> 本文件早期(2025-06)记录的 Merlin K21 `@EVENTLOAD` harness / `SIF !DEBUGGERR` 守卫 / `-Debug` 触发那套**已全部作废**，勿参考。

## 目标
打磨 **eratw-skill**（帮 LLM 写 eraTW 角色口上的 Claude Skill），并以从零写 **露娜切露德(K6)** 口上作为方法论实测用例。仓库 `github.com/ijwzac/eraTW-skill`（用户=ijwzac），工作副本在 `learning/`。

## 当前架构（已实测跑通）
- **半自动测试流水线**：双击 `learning/eratw-skill/run_eratw_test.bat`（以 `-STA` 启动 `start_pipeline.ps1`）→ 选 dev/player 版 → 启游戏 + 后台 clip_tap 实时抓词到 `cliplog.txt` → 关游戏后扫标记、回写 `;@AT` 状态、生成 `test_result.txt`。clip_tap 现传 `-MaxSeconds 86400` 且监控循环自愈重启（修了 60 分钟自停）。
- **自动测试 AUTOTEST**：`M_KOJO_K6_AUTOTEST.ERB` 测试套件，守卫＝`CFLAG:6:1099` 三态待命位（0 从未待命/玩家默认→永不触发；1 已待命→跑一次置 2；2 已跑）。开测＝启动器问「是否启用」时选启用（哨兵文件法，见 references/11 §11.14），读档+会話一次即触发；**同一存档重测**才需调试台输 `CFLAG:6:1099 = 1`（哨兵只 arm 没跑过的存档——`!= 2` 守卫承重、不可去）。判定＝END 哨兵门控（`at_update.ps1`）。**不再用 DEBUGGERR/TCVAR:399**。
- **300 候选池确定性测试**：`CFLAG:6:1098`＝强制台词号（>0 跳过所有随机直接演该编号），harness 逐条 set 它。
- **手动测试**：`待手动测试` 分支打 `PRINTL [[MT <TID>]]` 标记（其上一行 `SIF K{id}_MT_ON()` 守护），`manual_scan.ps1` 扫 cliplog 去重回写、`-Apply` 删标记时连带删守护行。
- **手动测试标记总开关 `@K{id}_MT_ON()`**（函数库 `#FUNCTION`，开发`RETURNF 1`/发布`RETURNF 0`）：一处翻转即可让全部 `[[MT]]` 静默、玩家不可见。见 references/11 §11.8。
- **自动测试覆盖 ≠ 全覆盖**（§11.13）：`;@AT 待自动测试` 是写作承诺、未必已接入测试套件 `[[TID BEGIN]]`；测试时 AI 须 grep 交叉核对补齐；通过分支可由 AI（非 bat）从测试套件注销。
- **交付前**：①注释 会話 AUTOTEST 钩子 + 删 `AUTOTEST.ERB`；②**翻转 `@K{id}_MT_ON()`→`RETURNF 0`**（先汇报还剩多少 `待手动测试`/`测试失败`；标记可带守护静默留存、不必强删）；③还原 `emuera.config`（备份 `emuera.config.bak_clip`）。bat 只提醒、不自动关钩子。

## SKILL 结构（`learning/eratw-skill/`）
- `SKILL.md` 主体（**§0.7 ⛔作业边界(写操作只许落在口上文件夹/禁系统级永久操作/不确定就问)** / **§0.8 HANDOFF.md 自觉维护(context压缩与换session接手)** / **§0.4 ⭐references 三层读取策略(A层必读/B层沾边读全/C层只grep)** / §0 导航含资料查找表 / §1 常见坑含 #13 写命令前 grep 清单 / §2 校验 / §9.5 内容自查①-④…）。
- **references 三层（§0.4，规则非建议）**：**A 层动手前必读**＝02状态总线/03helper/04DSL/05事件ARG/07其它/09人设/10编码/**11自动测试(13.1k,虽大仍必读——几乎每段口上都要挂测试且直接牵扯用户操作)**/13惯用法，合计~30k；**B 层沾边就读全文**（别grep一行就走）＝12命令速查(写任何命令)/01标签目录/06recipes/14日记/15依赖/16刻印；**C 层只grep永不整份读**＝08角色名表/`data/**`(~190 CSV,是核查基准非读物)/`data/engine/*.ERB`/**`reference-kojo/reimu`(~236k token,其中コマンド.ERB 一个就183k,能撑爆200k窗口)**。判据＝表格占比高的查表型只grep、散文型才谈读。
- `references/01-16`：01 标签目录 / 02 状态总线 / 03 helper / 04 DSL / 05 事件ARG(含约会结束3路径 + ⭐GIFT ARG分档) / 06 recipe / 07 其它 / 08 角色ID / 09 人设 / 10 编码工具 / 11 autotest流水线(§11.8 MT总开关 / §11.13 覆盖交叉核对 / §11.14 哨兵一键arm+⚠FLAGSETTING调用频率 / §11.15 纯冒烟TID) / **12 命令速查** / **13 高频惯用法** / **14 日记系统** / **15 依赖系** / **16 刻印系统**。
- `references/data/`：权威 CSV（Train/TFLAG/CFLAG/Item/Chara…）+ **`data/engine/`**（KOJO_MESSAGE.ERB 分发器 / COMMON.ERB helper库 / EVENT_MESSAGE_COM300+400 命令语义 + README）。
- `reference-kojo/`：`luna-K6/`(露娜同步副本) / `reimu/`(K1样例) / `口上テンプレ/`(官方空模板)。
- 约定：**新增 SKILL 内容一律中文**（标签名/代码标识符保留原文）；整份 SKILL 汉化留作后续单独工程。

## 露娜 K6 现状
- 目录：`ERB\口上・メッセージ関連\個人口上\006 Luna [ルナ]\露娜切露德_重制\`（15 个 .ERB + AUTOTEST 临时测试套件）。
- 人设：迟钝/爱讲理/头号胆小鬼的夜之月光妖精；消音能力；偷咖啡；爱摔跤；常带桑尼(K5)/斯塔(K7)三妖精味。就寝2:00/起床8:00(非昼夜颠倒)。SFW 为主，成人类目留 LOCAL=0 桩。
- 已写命令：300会話(候选池)/301泡茶/302身体接触/304帮忙干活/306撫肚/307捏脸/309摸头/311拥抱/312接吻/332劝酒/403休憩/410扫除/411弹幕训练/413料理(仅禁断菜单)/415招待吃饭/416演奏/派生SCOM60掏耳朵；事件 EVENT_1/2/3/13/20/21/26、SPEVENT_1/2、SPECIALDAY(十六夜,从EVENT_1 CASE8 CALL)、GIFT/RUN_INTO/CHARA_INFO 等；日记(已修好)；依赖(新建 M_KOJO_K6_依頼.ERB)。

## 待办/未决
- 已落地(第5-7批)：命令速查(doc12)全量校准勘误入§F；**约会结束3路径**查清(手动回家→SP_EVENT3已填/到点回家→EVENT_20/倦意归途NEMUKE≥720→默认无口上仅衰弱发EVENT_20)写进references/05；**EVENT_4「移動時すれちがい」路过对话已给露娜写好**(打招呼/无视×好感度×是否和别人约会,禁同格守卫)；掏耳朵真因=露娜幼児体型让305青蛙失败(引擎COMF305体型闸,非口上问题)入doc12；找丢失物依赖攻略(纳兹琳灵摆/debug CFLAG:6:403=3)。
- **⏳两个调查agent在跑(compact后到)**：①@VISIT/活动时间——角色约会"到点回家"何时触发、是否要等露娜2点、debug强制法；②刻印(MARK)系统全解(不埒刻印/反発刻印获得消除影响)，#2拟沉淀成SKILL references新文件(如16-刻印系统)。
- 已落地(第8-9批)：全部 `[[MT]]` 标记套 `@K6_MT_ON()` 总开关(发布前翻0静默)；日记重写(4页真正文+随好感度解锁)+406时停/睡眠守卫(`!SHIRAHU`)；自动测试交叉核对(§11.13)——补 406/DIARY/COUNTER 漏洞、注销已通过 ENCOUNTER→307。
- **⭐lazyloading.dat 元凶**：加了新标签必须删 `lazyloading.dat` 再启动，否则新标签在游戏里不触发(旧符号索引)。这是 304/掏耳朵"没台词"的真因(代码本身正确)。**启动器已修成会自动删**；手动启 exe 要手删。见 SKILL §3/§11.6/§11.12。
- **✅SKILL 汉化【已完成】(2026-07-17)**：`SKILL.md` + `references/01-07,09,10,11` 已全部换成中文正式版；临时的 `zh/` 平行目录**已删除**——正式位置即唯一事实源，**别再建平行译文目录**（两份必然漂移，这轮就是在收拾这个）。`08`(罗马名对照表)保持英文、`12-16` 本来就是中文，均原样保留。覆盖前经 4 个 agent 全文逐行比对，并把译文落后的块补齐到与英文等价。
- **可选/待用户定夺**：EVENT_20 补 CASE 7/8/9 留宿(当前只到CASE6)；倦意归途/掏耳朵体型闸是否改引擎(在口上目录外,未动)。
- 交付前清理：注释 AUTOTEST 钩子 + 删 AUTOTEST.ERB + **翻转 `@K6_MT_ON()`→0** + **删 FLAGSETTING 哨兵 arm 段 + 哨兵文件 autotest.off** + 还原 emuera.config。（教学范例发布则按 luna-K6/README 有意保留脚手架。）
- **术语**：test battery 中文用「**测试套件**」（不用「电池」，已全量改）。
- **自动测试 bat 一键开关(哨兵法,已实装)**：口上目录 `autotest.on/off` + FLAGSETTING `EXISTFILE` + 启动器扫描改名；玩家读档+会話一次即触发。见 references/11 §11.14。
- **⏳恢复上下文必读记忆第15批**（第14批那6件事已全部做完）。两个重要引擎纠错：①**FLAGSETTING 不只读档调用**——`SYSTEM.ERB:75 @EVENTLOAD` 与 `INFO.ERB:922 @INFO_RENEW_TARGET`（每次刷新状态信息）都调，故里面必须幂等，哨兵 arm 的 `!= 2` 守卫**承重不可去**；②**GIFT 的 ARG2 与 ARG3 连发**（≥700 先发2、破纪录再追发3），重要解锁挂 ARG2，且 ARG2/ARG4 别漏写（ARG4=400-699 是最常见档）。

## 关键路径
- 游戏根：`d:\Game\TouHou\Yoiyami Dreamer\datas\eraTW`
- 记忆：`C:\Users\lzh\.claude\projects\d--Game-TouHou-Yoiyami-Dreamer-datas-eraTW\memory\`（`MEMORY.md` 索引 + `luna-kojo-pending-todo.md` 权威现状）
- SKILL：`d:\Game\TouHou\Yoiyami Dreamer\datas\eraTW\learning\eratw-skill\SKILL.md`
- 露娜口上：`d:\Game\TouHou\Yoiyami Dreamer\datas\eraTW\ERB\口上・メッセージ関連\個人口上\006 Luna [ルナ]\露娜切露德_重制\`

## 通用铁律
- 只改露娜口上目录 + `learning/` + `emuera.config`（有备份）。绝不破坏玩家存档/游戏逻辑。测试代码守卫在 CFLAG:6:1099，交付前删除。
- ERB 文件 UTF-8 **带 BOM**；每次 Edit/Write 后重存 BOM（用 `open(p,'w',encoding='utf-8-sig')`）。CJK 别用 PowerShell 命令行参数传（会乱码），从文件读或用 Bash。
- 含 `[サニー]` 等方括号的路径在 Test-Path/Move-Item 要 `-LiteralPath`（方括号=通配符）。
- 改口上后跑 balance 校验：`IF==ENDIF`、`SELECTCASE==ENDSELECT`。
