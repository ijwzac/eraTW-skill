# File encoding, line endings, and tooling tips

## UTF-8 with BOM is REQUIRED

The Emuera engine expects `.ERB` files in UTF-8 with the byte-order-mark (BOM: `EF BB BF`).

- **Without BOM**, the engine fails to parse Chinese characters in some string contexts (silent breakage).
- **CRLF** line endings are preferred but **LF** is tolerated in practice.

## How write-tools (Claude `Write`/`Edit`, etc.) interact

Most LLM file-writing tools default to **LF**, **no BOM**. After every `Write` or `Edit` call you must verify the file still has a BOM. If not, prepend one.

### Bash one-liner to prepend BOM

```bash
prepend_bom() {
    local f="$1"
    head -c 3 "$f" | xxd -p | grep -q "efbbbf" && return 0
    printf '\xef\xbb\xbf' > "$f.tmp"
    cat "$f" >> "$f.tmp"
    mv "$f.tmp" "$f"
}

# Apply to every .ERB in a kojo dir
for f in path/to/個人口上/<charname>/<variant>/*.ERB; do
    prepend_bom "$f"
done
```

### Optional: convert LF to CRLF

```bash
unix2dos *.ERB
```

The engine tolerates LF, so this step is cosmetic — but if you want the file to match the project convention exactly, run it.

## Quick BOM check

```bash
for f in *.ERB; do
    head -c 3 "$f" | xxd -p | grep -q "efbbbf" || echo "$f missing BOM"
done
```

## In-game debug techniques

When you need to diagnose runtime behavior (predicate not firing, line printing too often, etc.):

- **`PRINTFORML [DBG] {var1}={var1} {var2}={var2}`** — temporary inline state inspection. The `{...}` form interpolates inside curly braces in PRINTFORM-family commands. Add temporarily, remove before delivering.
- **`PRINT VARDUMP(var)`** — dump entire array/struct.
- **Run with `DEBUG_MODE.bat`** for a live console with stack info.
- **Tail `emuera.log` and `<timestamp>.log`** for engine warnings (the rotated `<YYYYMMDD-HHMMSS>.log` files in the game root).
- **For sticky-state bugs** (predicate evaluates wrong because a slot is non-zero from a previous turn), place a debug `PRINTFORML` *inside* the predicate's body to confirm what value the slot actually holds at trigger time. The 约会中 map-id-vs-boolean bug (SKILL.md pitfall #8) is a textbook example.

## Verifying a slot exists in CSV

If the engine warns `无法解析的标识符"<name>"`, the slot wasn't found in the corresponding CSV.

```bash
# Check CFLAG slot
grep -F ",约会中" path/to/CSV/CFLAG.csv

# Check TFLAG slot
grep -F ",時姦刻印取得" path/to/CSV/TFLAG.csv

# Check TCVAR slot
grep -F ",発情" path/to/CSV/TCVAR.csv

# Check BASE slot — verify "気力" exists, "疲労" doesn't
grep -F ",気力" path/to/CSV/Base.csv
grep -F ",疲労" path/to/CSV/Base.csv     # should be empty
```

If the slot you wanted doesn't exist, either find the canonical alternative (see SKILL.md §1 pitfall #9 for known mismatches) or use a private slot in the author-private range (CFLAG 1000-1999, TCVAR 350-399).
