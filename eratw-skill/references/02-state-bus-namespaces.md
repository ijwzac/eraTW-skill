# State-bus namespaces (full reference)

## 4. The state-bus

The state-bus is the *vocabulary* every kojo body reads from. Mastering it is the difference between a kojo that "works" and one that "feels right."

Convention: `<NAMESPACE>:<CHAR_ID>:<SLOT>` (defaulting CHAR_ID to TARGET if omitted). All slots resolve via `CSV/<file>.csv`.

### 4.1 Per-character namespaces

> **Important — slot names listed here are aspirational, not verified.** The eraTW corpus has multiple forks; some slot names are different on this fork (simplified-Chinese vs Japanese-kanji variants, slots that exist on one fork and not another). **Always grep the actual `CSV/<file>.csv` for byte-exact slot names before using them in code.** Concrete examples of mismatches we hit in practice:
> - `约会中` (simplified 约) is the canonical CFLAG row; `約会中` (Japanese 約) does not resolve.
> - `BASE:N:疲労` is *not* a slot in this fork's `CSV/Base.csv`. Use `BASE:N:気力 < MAXBASE:N:気力 / 2` as the canonical "tired" predicate.
> - `TFLAG:逢瀬時間` is *not* in this fork's `CSV/TFLAG.csv`. There is no general "days since last met" TFLAG; use a private CFLAG slot you control (e.g. `CFLAG:N:1080 = DAY` and diff against today).

| Namespace | What it stores | Notable slots |
|---|---|---|
| `TALENT:N:slot` | Talents (booleans, small ints). | `恋慕, 思慕, 恋人, 愛欲, 炮友, 処女, 無接吻経験, 兒童, 幼児／幼児退行, 年齢, 体型, 形状, 胸圍, 性別, 酒耐性, 妊娠, 育児中, 妊娠願望, 大胃王, 坦率, 自尊心, 無知, 小悪魔, 魅力, 魅惑, 謎之魅力, 膽怯, 傲慢, 叛逆, 施虐狂, 性別嗜好, 両面通吃, 讨厌男人, 態度, 非処女, 非童貞, 破瓜, Ａ破瓜, 出産経験, 膣射経験, 人妻, 未亡人, 接吻魔, 心情, …` |
| `ABL:N:slot` | Ability ranks (-1..0..+5). | `親密, 欲望, Ｂ感覚, Ａ感覚, Ｃ感覚, Ｖ感覚, Ｐ感覚, Ｍ感覚, 従順, 奉仕精神, 教養, 料理技能, 戦闘能力, 露出癖, 接吻経験, 学習経験, 愛情経験, 約會経験, 演奏経験, 出産経験` |
| `EXP:N:slot` | Experience counters (raw int). | `接吻経験, 料理経験, 愛情経験, 約會経験, 学習経験, 出産経験, 無自覚絶頂経験, 60..63` |
| `BASE:N:slot` | Physiological base values. **Verify in `CSV/Base.csv`.** | This fork's actual rows include: `体力, 気力, 射精, 母乳, 尿意, 勃起, 精力, 法力, TSP, 情緒, 理性, 憤怒, 工作量, 深度, 酒気, 潜伏率, 身高, 体重`. **No `疲労` slot — use `BASE:N:気力 < MAXBASE:N:気力 / 2` for "tired" instead.** |
| `MAXBASE:N:slot` | Max base values. | (mirror of BASE). |
| `NOWEX:N:slot` | Current physiological event state. | `射精, 噴乳, 放尿, Ｃ絶頂, Ｖ絶頂, Ｂ絶頂, Ａ絶頂, Ｍ絶頂, TotalEX` |
| `EX:slot` | Engine-side cumulative state. | `膣内精液` |
| `PALAM:slot` | Status parameters. | `欲情` |
| `PALAMLV:N` | Threshold lookup. | `IF PALAM:欲情 >= PALAMLV:5`. |
| `MARK:N:slot` | Imprint state (-1..0..+3). | `不埒刻印, 反発刻印, 苦痛刻印, 快楽刻印, 時姦刻印` |
| `STAIN:N:slot` | Body-fluid stains. | `精液, 愛液, 汗` |
| `EQUIP:N:slot` | Clothing. | `下半身内衣２, 上半身内衣１, 上半身内衣２, 服, …` |
| `TEQUIP:N:slot` (or `TEQUIP:slot`) | Per-target situational equipment. | `50` (V-insertion holder), `51` (A-insertion holder), `口球, 眼罩, 縄, 陰蒂夾, 乳頭夾, 振動棒, 子宮, 六九式, 飛機杯, Ｖ接触部位, 11..18` (touch zones), `101..107` (secondary). |
| `CFLAG:N:slot` (or `CFLAG:slot`) | Persistent character flags (any int). | Engine-defined: `現在位置, 初期位置, 面識, 好感度, 信賴度, 睡眠, 約会中, 妊娠自覚状態, 無自覚妊娠, 没穿内裤, 允许无套, 清い交際, 恶作剧, 出禁, 推倒禁止, 来訪不能, 自動喘息, 時間停止口上有, 眠姦口上有, 扮演口上有, 破瓜中止口上有, 口上内抱き寄せ判定_*, 口上セレクタ, 継承`. Author-private: `1000-1999`. Engine-reserved: `1990-1999`. |
| `TCVAR:N:slot` (or `TCVAR:slot`) | Per-target transient (per-day reset). | `破瓜, Ａ破瓜, 中止接吻, 烂醉, 初次拥抱, 媚薬, 今天的礼物, 発情`, `100/101` (last V/A inserter ID), `102/104` (climax flags), `112, 302` (talk-availability). Author-private: `350-399`. |
| `CSTR:N:slot` | Per-char mutable strings. (slots ≥40 typically free.) |
| `DIARY:N:M` | Diary state. 0=locked / 1=read / 2=daily-event-readable / 3=on-demand-readable. |
| `MAX_DIARY_PAGE:N:0` | Total diary pages. |
| `RELATION:N:M` | **Inter-character affinity** between N and M. |
| `SOURCE:N:slot` | Post-action affection ledger. Slots: `性行動, 露出, 逸脱, 与快Ｃ, 誘惑, 侮辱, 挑発, 加虐, 征服, 情愛, 反感, 歓楽, 達成, 愛情経験`. |
| `CUSTOM_TALENT:N:slot` (+ `_NAME, _COLOR, _TYPE`) | Char-defined talents (info-pane). |
| `custom_button_name:N:Y` | Char-defined button labels. |

### 4.2 Per-game globals

| Global | Means |
|---|---|
| `FLAG:slot` (or `FLAG:NUMBER`) | Global flags. `FLAG:70` = time-stop (alias `FLAG:時間停止`); `FLAG:扮演` = role-play target char ID; `FLAG:出禁人数` = banned-char count; `FLAG:周回数` = NG+ cycle; `FLAG:口上文本設定`, `FLAG:口上色`, `FLAG:口上セレクタ`, `FLAG:約会的对象`, `FLAG:甲斐性無`, `FLAG:ファッション`. |
| `TIME` | Minutes-of-day. |
| `TIME:2` | Hour bucket. |
| `TIME:5` | Weather phase (4-7 = rain, 5 = heavy rain). |
| `DAY` (= `DAY:0`) | Game day count. |
| `DAY:2` | Month. |
| `DAY:3` | Day-of-month. |
| `MAIN_MAP` | Current world-map ID (0=Hakurei, 1=Myouren, 2=Human Village, 3=Scarlet, 4=Bamboo, 5=Magic Forest, 6=Sanzu, 7=Tengu foot, 8=Tengu peak, 9=Underground, …). |
| `SELECTCOM` | Currently-selected command ID (mutable). |
| `TFLAG:50` | Active SCOM ID. |
| `TFLAG:192` | SUCCESS_COM override. |
| `TFLAG:193, 194` | Mood/result codes (per-command-documented). |
| `TFLAG:21..24` + `時姦刻印取得` | Mark codes. |
| `TFLAG:62` | Time-stop suppress. |
| `TFLAG:400` | Date-presence flag. |
| `TARGET, MASTER, PLAYER, ASSI, CHARANUM` | Char-ID resolutions. |
| `TARGET:N` | N-th element of multi-target array. |
| `RESULT, RESULTS, RESULTS:1` | Return values. |
| `PREVCOM` | Previous command. |
| `DISHNAME, DISH_TASTE` | Cooking globals. |
| `LINECOUNT` | Current cursor line. |

---

