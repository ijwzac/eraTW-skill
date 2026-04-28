# Beyond kojo — broader game-modification topics

## 12. Beyond kojo — broader game-modification topics

### 12.1 The CSV layer

`CSV/` holds static-data tables. They're enumeration files — slot-id → name mappings:

| File | Maps |
|---|---|
| `CFLAG.csv` | character-flag slot IDs to human names. **Crucial for understanding kojo**: when you see `CFLAG:6:1001`, look up row 1001 of CFLAG.csv to find that author's intent. |
| `TFLAG.csv` | turn-flag slot IDs. |
| `TCVAR.csv` | per-target var slots. |
| `Talent.csv` | talents like `恋慕`, `処女`, `兒童`. |
| `Abl.csv` | ability slots. |
| `CSTR.csv` | per-char string slots. |
| `Mark.csv` | imprint slots. |
| `Item.csv` | item definitions. |
| `Equip.csv`, `Tequip.csv` | equipment. |
| `Train.csv` | training command IDs. |
| `Palam.csv` | parameter slots. |
| `Juel.csv` | juel currency. |
| `Stain.csv` | body-fluid stain slots. |
| `Str.csv` | UI strings. |
| `Source.csv`, `ex.csv`, `exp.csv` | EXP curves. |
| `Base.csv`, `GameBase.csv` | game metadata. |
| `Chara/` | per-character static data CSVs. One per character. |

**To add a new author-private CFLAG slot**: edit `CFLAG.csv` to add a row (e.g. `1234,my_new_flag`). Then in your kojo, `CFLAG:N:my_new_flag` works (and `CFLAG:N:1234` too).

### 12.2 Other ERB subdirectories

| Subdir/File | Role |
|---|---|
| `初期設定.ERB`, `SYSTEM.ERB`, `TITLE.ERB`, `NEWGAME/` | Game start, title screen, new-game flow. |
| `DIM.ERH` | Variable schema declarations. |
| `COMMON.ERB` (83 KB) | Engine common subroutines. |
| `BATTLE.ERB`, `CASINO/`, `NOUMIN.ERB`, `YASAI.ERB` | Mini-systems (battle, casino, farming, vegetables). |
| `天候*` | Weather subsystem (`ERH` for headers, `ERB` for logic). |
| `時間停止解除.ERB` | Time-stop release. |
| `潜伏モード関連/` | Stealth/sneak mode. |
| `衣服/` | Clothing. |
| `グラフィック表示ライブラリ/` | Image-display library. |
| `ステータス計算関連/` (subdir) | Status computation: `ABL/`, `ATTITUDE.ERB`, `STAIN.ERB`, `TRACHECK*.ERB`. **End-of-turn affection ledger lives here.** |
| `ステータス表示関連/` (subdir) | UI: portraits, color, BAR, IMAGE, INFO, look. |
| `キャラデータ/` (subdir) | `Chara_data_<N>_<name>.ERB` — runtime-loaded character setup. |
| `カラム機能/` (subdir) | Column / panel UI. |
| `イベント関連/` (subdir) | Date events, festivals, gifts, jealousy/affair, pregnancy. |
| `コマンド関連/` (subdir) | The command system: `COMABLE/`, `COMF/`, `SCOMF/`, `COMORDER.ERB`. |
| `SHOP関連/` (subdir) | Shop. |
| `ALTER/`, `MOVEMENTS/`, `OBJ/`, `COLOREDMAPS/`, `DLC/`, `NEWCHARACTERリソース作成/` | Misc: re-skinning, locations, maps, DLC, resource generation. |
| `method_from_anon/`, `method_from_eratohoЯeverse/` | Library subroutines from anon contributors. |
| `魔改内容/` | Mod-specific content. |

### 12.3 The command system (`コマンド関連/`)

This is what kojo *hooks into*. The split:

- **`COMF/`**: per-command implementation files. Filenames embed command ID: `COMF1 クンニ.ERB`, `COMF12 胸揉み.ERB`, `COMF184 野外プレイ.ERB`. **These define what the command does mechanically**; kojo files supply per-character speech.
- **`SCOMF/`**: sub-command implementations (the SCOM family).
- **`COMABLE/`** (`COMABLE.ERB`, `COMABLE_300.ERB`, `_400`, `_500`, `_600`, `_700`, `_80`): "Is this command currently usable?" gates. The numeric suffixes match command-ID ranges.
- **`COMORDER.ERB`**: command sequencing/chaining.
- **`USERCOM.ERB`** + **`USERCOM_*`**: user-defined commands.

Command-ID namespace partitioning:
| Range | Family |
|---|---|
| 0–99 | Misc / primitive (`COMF1 クンニ`, `COMF11 乳首吸い`, `COMF15 クリ愛撫`, `COMF80 手を引く`). |
| 100s | SM / discipline (`COMF100 スパンキング`, `COMF105 縄`, `COMF107 拘束プレイ`). |
| 120s–140s | Assistant-involving / advanced. |
| 180s | Aids / situational (`COMF180 ローション`, `COMF184 野外プレイ`). |
| **300s** | **Daily-life** (会話 300, 泡茶 301, 身体接觸 302, 道歉 303, …). |
| **400s** | **Housekeeping/training** (掃除 410, 戦闘訓練 411, 学习 412, 料理 413, 吃飯 414, 演奏 416, 午睡 417, 祈願 421, 浴室 431, 等待 440). |
| 500s | (Battle/spell — needs verification.) |
| **600s** | **Date** (約会). |
| **700s** | **Self-pleasure** (`700 自慰系/`). |
| 80s SCOMF | Derived sub-commands (TFLAG:50). |

For new commands: choose an ID outside used ranges (e.g. 270-279 for the new-API custom-command space).

### 12.4 The weather subsystem — example "system plugin"

`天候システム.ERH` (header), `天候予測システム.ERB`, `天候管理拡張.ERB`, `日時天候管理.ERB` (~220 KB total). This is the canonical example of a non-kojo plugin: a self-contained subsystem.

**Pattern of a system plugin**:
1. Drop `.ERH` headers and `.ERB` source files into `ERB/` (or a subdir under it).
2. The `.ERH` declares `#DIM`/`#DIMS`/`#DIM CONST` for the plugin's namespaces.
3. The `.ERB` files declare labels (`@MY_PLUGIN_*`) callable from the rest of the engine.
4. Engine scans recursively, picks up the new files at next launch.
5. To "register" the plugin with existing kojo or commands, you add a `CALL MY_PLUGIN_*` invocation at appropriate hook points.

Example: weather affects kojo. The `天候*` system writes `TIME:5` (the global weather phase). Bodies read `TIME:5` and branch on weather. There's no "registration" step — the kojo just reads the global.

For more complex plugins (a new economy system, a new mini-game), you might:
- Add a new `MAIN_MAP` ID to host the mini-game.
- Add a new ERB file with the game logic.
- Register a player-side command in `COMF/` to enter the mini-game.
- (Optionally) add per-character kojo reactions to the mini-game in each char's `M_KOJO_K{id}_イベント.ERB`.

### 12.5 The resources/ directory

Sprite/portrait images. `mkResourceXml.py` is the build script that produces resource XMLs. Per-character images go under `resources/<charid>_<key>.webp` (or similar). Image-display in kojo uses `CALL PRINT_FACE, char, expr, clothes, variant` to look up the corresponding resource.

To add new character images:
1. Add the image files (`.webp` / `.png`) to `resources/`.
2. Update `resources/顔.csv` to declare the new key.
3. In your kojo, `CALL PRINT_FACE, <id>, "<your-key>", ...` to use it.

### 12.6 Save-game compatibility

Persistent state lives in `sav/`. Variable types affecting save format:
- `CFLAG`, `TALENT`, `ABL`, `EXP`, `BASE`, `MARK`, `CSTR`, `DIARY`, `MAX_DIARY_PAGE` — saved per-character.
- `CFLAG` global slots, `FLAG`, `TIME`, `DAY`, `MAIN_MAP` — saved as game-state.
- `#DIM SAVEDATA <name>` — kojo-defined per-char persistence.
- `#DIM SAVEDATA GLOBAL <name>` — kojo-defined cross-game persistence.

Adding a new `SAVEDATA` doesn't break old saves (engine zero-fills missing). Removing one *does* — old saves still have the value but the runtime no longer cares.

For save-migration on version-up: implement `@KOJO_VERSION_UPDATE_K{id}` to read the old value, transform, and write to the new slot (custom-API only).

---

