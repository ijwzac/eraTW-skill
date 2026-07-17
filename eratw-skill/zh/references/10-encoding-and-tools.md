# 文件编码、行尾与工具提示

## 必须使用 UTF-8 BOM

Emuera 引擎要求 `.ERB` 文件采用带字节顺序标记（BOM：`EF BB BF`）的 UTF-8。

- **不带 BOM** 时，引擎在某些字符串语境下无法解析中文字符（静默出错）。
- **CRLF** 行尾更受青睐，但实践中 **LF** 也能被容忍。

## 写文件工具（Claude `Write`/`Edit` 等）如何交互

大多数 LLM 写文件工具默认使用 **LF**、**不带 BOM**。每次调用 `Write` 或 `Edit` 之后，你都必须核实文件是否仍带 BOM。若没有，就补上一个。

### 补 BOM 的 Bash 单行脚本

```bash
prepend_bom() {
    local f="$1"
    head -c 3 "$f" | xxd -p | grep -q "efbbbf" && return 0
    printf '\xef\xbb\xbf' > "$f.tmp"
    cat "$f" >> "$f.tmp"
    mv "$f.tmp" "$f"
}

# 对某个口上目录下的每个 .ERB 应用
for f in path/to/個人口上/<charname>/<variant>/*.ERB; do
    prepend_bom "$f"
done
```

### 可选：把 LF 转成 CRLF

```bash
unix2dos *.ERB
```

引擎容忍 LF，所以这一步只是外观上的调整——但如果你想让文件完全符合项目约定，就运行它。

## 快速检查 BOM

```bash
for f in *.ERB; do
    head -c 3 "$f" | xxd -p | grep -q "efbbbf" || echo "$f missing BOM"
done
```

## 游戏内调试技巧

当你需要诊断运行时行为（谓词不触发、某行打印太频繁等）时：

- **`PRINTFORML [DBG] {var1}={var1} {var2}={var2}`** —— 临时的内联状态检查。在 PRINTFORM 系列命令里，`{...}` 形式会在花括号内做插值。临时加上，交付前删掉。
- **`PRINT VARDUMP(var)`** —— 转储整个数组/结构体。
- **用 `DEBUG_MODE.bat` 运行** 可获得带栈信息的实时控制台。
- **跟踪 `emuera.log` 与 `<timestamp>.log`** 查看引擎警告（游戏根目录下轮转的 `<YYYYMMDD-HHMMSS>.log` 文件）。
- **对付黏滞状态 bug**（谓词判断出错，是因为某槽位从上一回合残留了非零值）时，在谓词主体*内部*放一条调试 `PRINTFORML`，确认触发时刻该槽位实际持有什么值。约会中 map-id-与-布尔值混淆的 bug（SKILL.md 坑 #8）就是典型例子。

## 核实某槽位在 CSV 中存在

如果引擎警告 `无法解析的标识符"<name>"`，说明该槽位没在对应的 CSV 里找到。

```bash
# 检查 CFLAG 槽位
grep -F ",约会中" path/to/CSV/CFLAG.csv

# 检查 TFLAG 槽位
grep -F ",時姦刻印取得" path/to/CSV/TFLAG.csv

# 检查 TCVAR 槽位
grep -F ",発情" path/to/CSV/TCVAR.csv

# 检查 BASE 槽位 —— 核实 "気力" 存在、"疲労" 不存在
grep -F ",気力" path/to/CSV/Base.csv
grep -F ",疲労" path/to/CSV/Base.csv     # 应为空
```

如果你想要的槽位不存在，要么找到规范的替代品（已知的不匹配见 SKILL.md §1 坑 #9），要么使用作者私有区间里的私有槽位（CFLAG 1000-1999，TCVAR 350-399）。
