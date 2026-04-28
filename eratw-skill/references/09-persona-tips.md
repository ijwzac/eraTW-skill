# Persona-translation tips

## 14. Persona-translation tips (humanizing the structural skeleton)

When the user writes "she's cheerful but easily flustered," translate that into:

| Persona trait | Translation |
|---|---|
| "Cheerful" | Default `RAND:N` cascades skew toward upbeat lines; `TALENT:坦率 = 1` if applicable. |
| "Easily flustered" | Sex/sexual-harassment commands often have her stutter; first-time `FIRSTTIME(SELECTCOM)` branches show shock/confusion. |
| "Reserved" | Many command bodies are short / single-line. `TALENT:自尊心 = 1` if proud. |
| "Possessive" | `EVENT_K{id}_7` (caught-dating) has stronger reactions; `RELATION:N:<rival_id>` deltas are negative when player flirts. |
| "Drunk easily" | `TALENT:酒耐性 = -2`; many commands branch on `BASE:酒気 > MAXBASE:酒気/2`. |
| "Loves food" | `TALENT:大胃王 = 1`; `@K{id}_COOKING_REACTION` covers a lot of dish names. |
| "Tsundere" | First-time `FIRSTTIME` branches resist; later branches accept; uses `TALENT:傲嬌` if available; high `TALENT:自尊心`. |
| "Reads minds" | Bodies use `\@ <thought-cond> ? <reading-line> # <neutral-line> \@`; references "知道你在想什么" frequently. |
| "Cosplay-loving" | `IF FLAG:ファッション == <some-cosplay-id>` branches; helper `K{id}_CHECK_HEN_T()` rejects unwanted outfits. |
| "Has a sister/relative" | `RELATION:N:<sis-id>` deltas; events trigger when the relative is in-room (`CFLAG:<sis-id>:現在位置 == CFLAG:N:現在位置`). |
| "Lives at <place>" | `MAIN_MAP == <id>` and `CFLAG:N:現在位置 == <loc>`. |

---

