# Data files — canonical CSVs from eraTW

These are *exact copies* of the CSV files from a working eraTW install. They are the **ground truth** for verifying slot names, command IDs, talent codes, item IDs, and per-character display names. The skill's accuracy depends on consulting these rather than guessing.

## When to read each file

| Question | File |
|---|---|
| What is command 311 called? | `Train.csv` |
| Does CFLAG slot `约会中` exist? Does `約会中`? | `CFLAG.csv` (only the simplified form 约会中 resolves) |
| Does TFLAG slot `逢瀬時間` exist? | `TFLAG.csv` (no — author should use a private CFLAG instead) |
| What's TCVAR 350-399 used for? | `TCVAR.csv` (author-private range) |
| Does TALENT `恋慕` exist? What about `坦率`? | `Talent.csv` |
| Does ABL `親密` exist? What about `Ｂ感覚`? | `Abl.csv` |
| Is `BASE:N:疲労` valid? | `Base.csv` (no — use `気力` instead) |
| What item IDs are alcohols (for cmd 332)? | `Item.csv` (51-59, 560-580) |
| What equipment slot is 下半身内衣２? | `Equip.csv` |
| Will `[[アリス]]` resolve at parse time? | `Str.csv` (the master string table — most char names are NOT here) |
| What's character 100's display name (`%CALLNAME:100%`)? | `Chara/Chara100 レイセン.csv` |
| Verify a character ID ↔ romaji ↔ Japanese ↔ Chinese mapping | `../08-character-id-table.md` (a curated markdown table) |

## Practical recipes

### Resolve a command name from its ID

```bash
grep "^311," Train.csv
# → 311,擁抱,...
```

### Verify a CFLAG slot exists byte-exact

```bash
grep -F ",約会中" CFLAG.csv     # Japanese 約 — should be empty
grep -F ",约会中" CFLAG.csv     # Simplified 约 — should match
```

### List all alcohol items

```bash
awk -F, '/酒/ && $1 ~ /^[0-9]+$/ {print $1, $2}' Item.csv
```

### Look up a character's canonical display name

```bash
ls Chara/ | grep "^Chara20 "
# → Chara20 リリカ.csv
grep -E "^(名前|呼び名)," "Chara/Chara20 リリカ.csv"
```

## Notes on this corpus

- These files come from a specific eraTW fork. Other forks may have different slot names — when working on a user's install, encourage the user to upload their own CSVs if behavior differs.
- The `Chara/` directory has ~150 per-character CSVs. Each one has rows for `名前` (formal name), `呼び名` (display nickname), `情報` (description), plus stat rows.
- `Str.csv` is the master string-table that gates the `[[<name>]]` parse-time lookup. **Most character names are not in it** despite having `Chara/Chara<N> <name>.csv` files — see SKILL.md pitfall #2.
- `_Rename.csv` and `_Replace.csv` are engine-level identifier remappings; rarely relevant for kojo authoring.

## In chatbot mode

If you (the LLM) are running without file-system access and the user asks something that requires a lookup here, name the **specific file** and ask the user to upload or paste it. Don't guess.
