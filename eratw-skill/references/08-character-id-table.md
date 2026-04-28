# Character ID ⇆ name correspondence table

## Appendix A — Character ID ⇆ name correspondence table

This table maps engine character IDs (1-159, used in `K<id>` label suffixes) to directory names, romaji, Japanese names, and **commonly-used Chinese names**.

**Important caveats** for the LLM reading this:

- **The engine ID is the leading number in the directory name** (e.g. `042 Hatate [はたて]/` → `K42`). This ID is what appears in every label like `@M_KOJO_MESSAGE_COM_K42_300`. **It is the only authoritative identifier**; everything else is a display name.
- **Chinese names are NOT canonical.** The Touhou fandom has multiple competing Chinese translations for nearly every character. The user may give you a Chinese name slightly different from this table — for example, 帕露西/帕露珞/水桥帕露西 are all common renderings of `Parsee`. **When in doubt, match against the romaji or the Japanese name in brackets**, never the Chinese name alone. If the user's name is ambiguous, ask "你是指 ID 60 帕露西 (パルスィ) 吗？" and confirm.
- IDs **145, 153, 155-158** are intentionally skipped in the dir layout. IDs that appear in the table but with a note "empty/stub directory" have a directory but no kojo — those characters are unimplemented in the current build.
- The "directory name" column is the **exact** string under `個人口上/`. Use it verbatim when constructing paths.

| ID | Romaji (dir) | 日本語 | 中文常用名 | Directory (under 個人口上/) |
|---|---|---|---|---|
| 1 | Reimu | 霊夢 | 博丽灵梦 | `001 Reimu [霊夢]` |
| 2 | Ruukoto | る～こと | 茹~克托 / 露~克托 | `002 Ruukoto [る～こと]` |
| 3 | Kana | カナ | 卡娜·安娜贝拉尔 | `003 Kana [カナ]` (stub) |
| 4 | Mima | 魅魔 | 魅魔 | `004 Mima [魅魔]` |
| 5 | Sunny | サニー | 桑尼米尔克 | `005 Sunny [サニー]` |
| 6 | Luna | ルナ | 露娜切尔德 | `006 Luna [ルナ]` |
| 7 | Star | スター | 斯塔萨菲雅 | `007 Star [スター]` |
| 8 | Chiyuri | ちゆり | 北白河千百合 | `008 Chiyuri [ちゆり]` (stub) |
| 9 | Yumemi | 夢美 | 冈崎梦美 | `009 Yumemi [夢美]` |
| 10 | Suika | 萃香 | 伊吹萃香 | `010 Suika [萃香]` |
| 11 | Marisa | 魔理沙 | 雾雨魔理沙 | `011 Marisa [魔理沙]` |
| 12 | Rumia | ルーミア | 露米娅 | `012 Rumia [ルーミア]` |
| 13 | Daiyousei | 大妖精 | 大妖精 | `013 Daiyousei [大妖精]` |
| 14 | Cirno | チルノ | 琪露诺 | `014 Cirno [チルノ]` |
| 15 | Sakuya | 咲夜 | 十六夜咲夜 | `015 Sakuya [咲夜]` |
| 16 | Remilia | レミリア | 蕾米莉亚 (蕾米莉亚·斯卡蕾特) | `016 Remilia [レミリア]` |
| 17 | Alice | アリス | 爱丽丝 (爱丽丝·玛格特罗依德) | `017 Alice [アリス]` |
| 18 | Lily W | リリーＷ | 莉莉白 | `018 Lily W [リリーＷ]` |
| 19 | Lily B | リリーＢ | 莉莉布莱克 | `019 Lily B [リリーＢ]` |
| 20 | Lyrica | リリカ | 莉莉卡 (莉莉卡·普利兹姆利巴) | `020 Lyrica [リリカ]` (stub) |
| 21 | Merlin | メルラン | 梅露兰 (梅露兰·普利兹姆利巴) | `021 Merlin [メルラン]` (stub) |
| 22 | Lunasa | ルナサ | 露娜萨 (露娜萨·普利兹姆利巴) | `022 Lunasa [ルナサ]` |
| 23 | Youmu | 妖夢 | 魂魄妖梦 | `023 Youmu [妖夢]` |
| 24 | Chen | 橙 | 橙 | `024 Chen [橙]` |
| 25 | Ran | 藍 | 八云蓝 | `025 Ran [藍]` |
| 26 | Yukari | 紫 | 八云紫 | `026 Yukari [紫]` |
| 27 | Wriggle | リグル | 莉格露 (莉格露·奈特巴格) | `027 Wriggle [リグル]` |
| 28 | Mystia | ミスティア | 米斯蒂娅 (米斯蒂娅·萝蕾拉) | `028 Mystia [ミスティア]` |
| 29 | Aya | 文 | 射命丸文 | `029 Aya [文]` |
| 30 | Eiki | 映姫 | 四季映姬·亚玛萨那度 | `030 Eiki [映姫]` |
| 31 | Sanae | 早苗 | 东风谷早苗 | `031 Sanae [早苗]` |
| 32 | Kanako | 神奈子 | 八坂神奈子 | `032 Kanako [神奈子]` |
| 33 | Suwako | 諏訪子 | 洩矢诹访子 | `033 Suwako [諏訪子]` |
| 34 | Tenshi | 天子 | 比那名居天子 | `034 Tenshi [天子]` |
| 35 | Iku | 衣玖 | 永江衣玖 | `035 Iku [衣玖]` |
| 36 | Orin | お燐 | 火焰猫燐 / 阿燐 | `036 Orin [お燐]` |
| 37 | Okuu | お空 | 灵乌路空 / 阿空 | `037 Okuu [お空]` |
| 38 | Koishi | こいし | 古明地恋 | `038 Koishi [こいし]` |
| 39 | Nazrin | ナズーリン | 娜兹琳 | `039 Nazrin [ナズーリン]` |
| 40 | Kogasa | 小傘 | 多多良小伞 | `040 Kogasa [小傘]` |
| 41 | Nue | ぬえ | 封兽鵺 | `041 Nue [ぬえ]` |
| 42 | Hatate | はたて | 姬海棠果 (kojo 内常用「极」) | `042 Hatate [はたて]` |
| 43 | Kasen | 華扇 | 茨木华扇 | `043 Kasen [華扇]` |
| 44 | Ellen | エレン | 艾伦 | `044 Ellen [エレン]` |
| 45 | Rikako | 理香子 | 朝仓理香子 | `045 Rikako [理香子]` (empty) |
| 46 | Meira | 明羅 | 明罗 | `046 Meira [明羅]` (empty) |
| 47 | Rika | 里香 | 里香 | `047 Rika [里香]` |
| 48 | Louise | ルイズ | 路易兹 | `048 Louise [ルイズ]` (empty) |
| 49 | Satori | さとり | 古明地觉 | `049 Satori [さとり]` |
| 50 | Flandre | フラン | 芙兰朵露 (芙兰朵露·斯卡蕾特) / 芙兰 | `050 Flandre [フラン]` |
| 51 | Nitori | にとり | 河城荷取 | `051 Nitori [にとり]` |
| 52 | Reisen | 鈴仙 | 铃仙·优昙华院·稻叶 | `052 Reisen [鈴仙]` |
| 53 | Tewi | てゐ | 因幡帝 | `053 Tewi [てゐ]` |
| 54 | Patchouli | パチュリー | 帕秋莉 (帕秋莉·诺蕾姬) / 帕琪 | `054 Patchouli [パチュリー]` |
| 55 | Byakuren | 白蓮 | 圣白莲 | `055 Byakuren [白蓮]` |
| 56 | Miko | 神子 | 丰聪耳神子 | `056 Miko [神子]` |
| 57 | Kokoro | こころ | 秦心 (秦こころ) | `057 Kokoro [こころ]` |
| 58 | Meiling | 美鈴 | 红美铃 / 美铃 | `058 Meiling [美鈴]` |
| 59 | Koakuma | 小悪魔 | 小恶魔 | `059 Koakuma [小悪魔]` |
| 60 | Parsee | パルスィ | 水桥帕露西 / 帕露西 | `060 Parsee [パルスィ]` |
| 61 | Mokou | 妹紅 | 藤原妹红 | `061 Mokou [妹紅]` |
| 62 | Kaguya | 輝夜 | 蓬莱山辉夜 | `062 Kaguya [輝夜]` |
| 63 | Kagerou | 影狼 | 今泉影狼 | `063 Kagerou [影狼]` |
| 64 | Yuugi | 勇儀 | 星熊勇仪 | `064 Yuugi [勇儀]` |
| 65 | Momiji | 椛 | 犬走椛 | `065 Momiji [椛]` |
| 66 | Yuyuko | 幽々子 | 西行寺幽幽子 | `066 Yuyuko [幽々子]` |
| 67 | Keine | 慧音 | 上白泽慧音 | `067 Keine [慧音]` |
| 68 | Yuuka | 幽香 | 风见幽香 | `068 Yuuka [幽香]` |
| 69 | Mamizou | マミゾウ | 二岩猯藏 | `069 Mamizou [マミゾウ]` |
| 70 | Kosuzu | 小鈴 | 本居小铃 | `070 Kosuzu [小鈴]` |
| 71 | Shinmyoumaru | 針妙丸 | 少名针妙丸 | `071 Shinmyoumaru [針妙丸]` |
| 72 | Eirin | 永琳 | 八意永琳 | `072 Eirin [永琳]` |
| 73 | Sekibanki | 蛮奇 | 赤蛮奇 | `073 Sekibanki [蛮奇]` |
| 74 | Letty | レティ | 蕾蒂 (蕾蒂·霍瓦特罗克) | `074 Letty [レティ]` |
| 75 | Medicine | メディスン | 梅蒂欣 (梅蒂欣·梅兰可莉) | `075 Medicine [メディスン]` |
| 76 | Komachi | 小町 | 小野塚小町 | `076 Komachi [小町]` |
| 77 | Shizuha | 静葉 | 秋静叶 | `077 Shizuha [静葉]` (empty) |
| 78 | Minoriko | 穣子 | 秋穰子 | `078 Minoriko [穣子]` |
| 79 | Hina | 雛 | 键山雏 | `079 Hina [雛]` |
| 80 | Akyuu | 阿求 | 稗田阿求 | `080 Akyuu [阿求]` |
| 81 | Renko | 蓮子 | 宇佐见莲子 | `081 Renko [蓮子]` |
| 82 | Maribel | メリー | 玛艾露贝莉 / 梅莉 | `082 Maribel [メリー]` |
| 83 | Kisume | キスメ | 钓瓶落 / 露珠 | `083 Kisume [キスメ]` |
| 84 | Yamame | ヤマメ | 黑谷山女 | `084 Yamame [ヤマメ]` (incomplete) |
| 85 | Ichirin | 一輪 | 云居一轮 | `085 Ichirin [一輪]` |
| 86 | Murasa | 水蜜 | 村纱水蜜 | `086 Murasa [水蜜]` |
| 87 | Shou | 星 | 寅丸星 | `087 Shou [星]` |
| 88 | Kyouko | 響子 | 幽谷响子 | `088 Kyouko [響子]` |
| 89 | Yoshika | 芳香 | 宫古芳香 | `089 Yoshika [芳香]` |
| 90 | Seiga | 青娥 | 霍青娥 | `090 Seiga [青娥]` |
| 91 | Tojiko | 屠自古 | 苏我屠自古 | `091 Tojiko [屠自古]` |
| 92 | Futo | 布都 | 物部布都 | `092 Futo [布都]` |
| 93 | Wakasagihime | わかさぎ姫 | 若鹭姬 | `093 Wakasagihime [わかさぎ姫]` (empty) |
| 94 | Benben | 弁々 | 九十九弁弁 | `094 Benben [弁々]` |
| 95 | Yatsuhashi | 八橋 | 九十九八桥 | `095 Yatsuhashi [八橋]` |
| 96 | Raiko | 雷鼓 | 堀川雷鼓 | `096 Raiko [雷鼓]` |
| 97 | Seija | 正邪 | 鬼人正邪 | `097 Seija [正邪]` |
| 98 | Yorihime | 依姫 | 绵月依姬 | `098 Yorihime [依姫]` |
| 99 | Toyohime | 豊姫 | 绵月丰姬 | `099 Toyohime [豊姫]` |
| 100 | Rei'sen | レイセン | 玲(月之都) (レイセン) | `100 Rei'sen [レイセン]` |
| 101 | Tokiko | 朱鷺子 | 朱鹭子 | `101 Tokiko [朱鷺子]` |
| 102 | Shinki | 神綺 | 神绮 | `102 Shinki [神綺]` (empty) |
| 103 | Yumeko | 夢子 | 梦子 | `103 Yumeko [夢子]` |
| 104 | Yuki | ユキ | 雪 | `104 Yuki [ユキ]` |
| 105 | Mai (PC-98) | マイ | 舞 (PC-98) | `105 Mai (PC-98) [マイ]` |
| 106 | Sumireko | 菫子 | 宇佐见菫子 | `106 Sumireko [菫子]` |
| 107 | Seiran | 清蘭 | 清兰 | `107 Seiran [清蘭]` |
| 108 | Ringo | 鈴瑚 | 铃瑚 | `108 Ringo [鈴瑚]` |
| 109 | Doremy | ドレミー | 哆来咪·苏伊特 / 朵蕾米 | `109 Doremy [ドレミー]` |
| 110 | Sagume | サグメ | 稀神探女 | `110 Sagume [サグメ]` |
| 111 | Clownpiece | クラウンピース | 克劳恩皮丝 | `111 Clownpiece [クラウンピース]` |
| 112 | Junko | 純狐 | 纯狐 | `112 Junko [純狐]` |
| 113 | Hecatia | ヘカーティア | 赫卡蒂亚·拉碧斯拉祖利 / 赫卡提亚 | `113 Hecatia [ヘカーティア]` |
| 114 | Kurumi | くるみ | 库露米 | `114 Kurumi [くるみ]` (empty) |
| 115 | Elly | エリー | 艾莉 | `115 Elly [エリー]` (empty) |
| 116 | Mugetsu | 夢月 | 梦月 | `116 Mugetsu [夢月]` (empty) |
| 117 | Gengetsu | 幻月 | 幻月 | `117 Gengetsu [幻月]` |
| 118 | Larva | ラルバ | 拉露瓦 / 拉尔瓦 | `118 Larva [ラルバ]` |
| 119 | Nemuno | ネムノ | 坂田合欢奈 / 古入道合欢 | `119 Nemuno [ネムノ]` |
| 120 | Aunn | あうん | 高丽野阿吽 | `120 Aunn [あうん]` |
| 121 | Narumi | 成美 | 矢田寺成美 | `121 Narumi [成美]` |
| 122 | Mai Teireida | 舞 | 丁礼田舞 | `122 Mai Teireida [舞]` |
| 123 | Satono | 里乃 | 尔子田里乃 | `123 Satono [里乃]` |
| 124 | Okina | 隠岐奈 | 摩多罗隐岐奈 | `124 Okina [隠岐奈]` |
| 125 | Joon | 女苑 | 依神女苑 | `125 Joon [女苑]` |
| 126 | Shion | 紫苑 | 依神紫苑 | `126 Shion [紫苑]` |
| 127 | Eika | 瓔花 | 瓔花·惠比寿 (Eika Ebisu) | `127 Eika [瓔花]` |
| 128 | Urumi | 潤美 | 牛崎润美 | `128 Urumi [潤美]` (empty) |
| 129 | Kutaka | 久侘歌 | 庭渡久侘歌 | `129 Kutaka [久侘歌]` |
| 130 | Yachie | 八千慧 | 杨弁庭八千慧 / 八千慧 | `130 Yachie [八千慧]` |
| 131 | Mayumi | 磨弓 | 杖刀偶磨弓 | `131 Mayumi [磨弓]` (empty) |
| 132 | Keiki | 袿姫 | 埴安神袿姬 | `132 Keiki [袿姫]` |
| 133 | Saki | 早鬼 | 骊驹早鬼 | `133 Saki [早鬼]` |
| 134 | Miyoi | 美宵 | 殿户美宵 / 美宵 | `134 Miyoi [美宵]` |
| 135 | Mike | ミケ | 三毛 / 密绵猫 | `135 Mike [ミケ]` (empty) |
| 136 | Takane | たかね | 山城高祢 / 天弓孝 | `136 Takane [たかね]` (empty) |
| 137 | Sannyo | 駒草 | 驹草山如 | `137 Sannyo [駒草]` (empty) |
| 138 | Misumaru | 魅須丸 | 玉造魅须丸 | `138 Misumaru [魅須丸]` (empty) |
| 139 | Tsukasa | 典 | 菅牧典 | `139 Tsukasa [典]` |
| 140 | Megumu | 龍 | 饭纲丸龙 | `140 Megumu [龍]` |
| 141 | Chimata | 千亦 | 天弓千亦 | `141 Chimata [千亦]` |
| 142 | Momoyo | 百々世 | 太田百百世 | `142 Momoyo [百々世]` (empty) |
| 143 | Yuuma | 尤魔 | 尤魔 / 优魔 (吉吊八千慧的同伴) | `143 Yuuma [尤魔]` |
| 144 | Ibaraki's Arm | 影華扇 | 影华扇 (茨木的手臂) | `144 Ibaraki's Arm [影華扇]` (empty) |
| 146 | Elis | エリス | 艾莉丝 (PC-98 旧作) | `146 Elis [エリス]` (empty) |
| 147 | Sariel | サリエル | 萨莉艾尔 | `147 Sariel [サリエル]` (empty) |
| 148 | Sara | サラ | 萨拉 | `148 Sara [サラ]` (empty) |
| 149 | Orange | オレンジ | 奥伦琪 | `149 Orange [オレンジ]` (empty) |
| 150 | Konngara | 矜羯羅 | 矜羯罗 | `150 Konngara [矜羯羅]` (empty) |
| 151 | YuugenMagan | ユウゲンマガン | 幽玄魔眼 | `151 YuugenMagan [ユウゲンマガン]` (empty) |
| 152 | Kikuri | キクリ | 菊理 | `152 Kikuri [キクリ]` (empty) |
| 154 | Enoko | 慧ノ子 | 慧之子 | `154 Enoko [慧ノ子]` |
| 159 | 先代 | 先代 | 先代博丽巫女 | `159 先代` |

**Skipped IDs**: 145, 153, 155-158 — no directory exists.

**To resolve a user-given Chinese name to an ID**:
1. Search the 中文常用名 column for an exact or partial match.
2. If multiple plausible matches (e.g. user says "舞" — could be 105 Mai PC-98 or 122 丁礼田舞), confirm with the user using both English/romaji and the era to disambiguate ("你是指 PC-98 旧作的舞 (105) 还是后期作品的丁礼田舞 (122)？").
3. The directory under `個人口上/` is the source of truth — once you know the ID, the directory name is fixed and you can build all paths from it.
