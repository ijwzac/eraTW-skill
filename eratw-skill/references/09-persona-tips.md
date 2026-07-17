# 人设翻译提示

## 14. 人设翻译提示（给结构骨架注入人味）

当用户写「她开朗但容易慌乱」时，把它翻译成：

| 人设特征 | 对应译法 |
|---|---|
| 「开朗」 | 默认的 `RAND:N` 级联偏向欢快的台词；若适用则 `TALENT:坦率 = 1`。 |
| 「容易慌乱」 | 性交系/性骚扰命令里常让她结巴；首次触发的 `FIRSTTIME(SELECTCOM)` 分支表现出震惊/困惑。 |
| 「内敛」 | 许多命令主体较短 / 单行。若骄傲则 `TALENT:自尊心 = 1`。 |
| 「占有欲强」 | `EVENT_K{id}_7`（撞见约会）反应更强烈；玩家跟别人调情时 `RELATION:N:<rival_id>` 增量为负。 |
| 「易醉」 | `TALENT:酒耐性 = -2`；许多命令按 `BASE:酒気 > MAXBASE:酒気/2` 分支。 |
| 「爱吃」 | `TALENT:大胃王 = 1`；`@K{id}_COOKING_REACTION` 覆盖大量菜名。 |
| 「傲娇」 | 首次的 `FIRSTTIME` 分支抗拒；后续分支接受；若可用则使用 `TALENT:傲嬌`；`TALENT:自尊心` 高。 |
| 「会读心」 | 主体使用 `\@ <thought-cond> ? <reading-line> # <neutral-line> \@`；频繁提到「知道你在想什么」。 |
| 「爱 cosplay」 | `IF FLAG:ファッション == <some-cosplay-id>` 分支；helper `K{id}_CHECK_HEN_T()` 拒绝不想要的装扮。 |
| 「有姐妹/亲属」 | `RELATION:N:<sis-id>` 增量；亲属在房间内时触发事件（`CFLAG:<sis-id>:現在位置 == CFLAG:N:現在位置`）。 |
| 「住在<某地>」 | `MAIN_MAP == <id>` 且 `CFLAG:N:現在位置 == <loc>`。 |

---
