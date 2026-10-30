# LootFarmer — Localization Batch 04 Report (Change 43) and 20-Language Audit

**Batch:** ja-JP, ko-KR, zh-CN, zh-TW (Playbook 132.5, final batch of 5+5+5+4) · **Date:** 2026-10-30 · **Godot:** 4.7.2 stable · **Previous:** Change 42 `bd7401a`
**Status: PASS, enabled.** The four catalogs are complete and validated, each draws with its own OFL regional Noto Sans subset, and all four joined `ENABLED_LANGUAGES`: **English + 19 translations = 20 selectable languages, 21 dropdown rows with Automatic.** `ALL_LANGUAGES_CERTIFIED` stays **false**: translations were written and reviewed by Claude, **not by native speakers**, and **nothing was tested on a physical phone** (§11). In-game translation is complete; public-release certification is not.

## 1. Baseline (verified, not assumed)

| | Value |
|---|---|
| Git | `main` at `bd7401a` (Change 42), not pushed. Developer's uncommitted `project.godot` (version 27, `config/icon` as `uid://drj4h6jnqymfy`, key order) and `export_presets.cfg` (Windows runnable preset, export path, editor-added keys) present before and after. `project.godot` is byte-identical to the developer's copy; in `export_presets.cfg` only the three `export_files=` lines were regenerated (checked line by line against a copy taken at the start) |
| `localization/en.po` | **1,951 keys**, SHA-256 `d6102fccdbae9721e20d5baa922c9a50d88ec85324c09b9b179832d3d47fe7e3` — unchanged by this change |
| Enabled before | en + 15 (Batches 01–03), 16 selectable |
| Batch 04 drafts | untracked `localization/{ja_JP,ko_KR,zh_CN,zh_TW}.po`: 1,921 keys (older source), 1,215 fuzzy English fallbacks each, zh_TW essentially a character conversion of zh_CN. Reference only; the four drafts are backed up outside the repository (session scratchpad) and the files were replaced by the finished catalogs. The developer's other untracked localization files (`README_TRANSLATION_STATUS.md`, `check_draft.py`, `translation_status.json`, `untranslated_ids.*`) were left untouched |

## 2. English source audit

- No code or UI has changed since the Change 42 audit (`7ff484f`, documented in the Batch 03 report §2: static `tr()` scan, 35 dynamic key sites, pseudo-locale rendered sweep). Re-checked now: `validate_localization` (every scene-text key present, unique keys) and the pseudo-locale sweep (part of the maintained suite, §10) report no text outside the catalog.
- Batch 04-specific review of glued or multi-placeholder strings: `MISSION_GOAL`, `HISTORY_ITEM`, `FARMING_LOCATION` + `COMPASS_*`, `NAME_ON_MAP`, `FOLLOW_COLLECT` (item, then enemy), `LEVEL_PANEL_XP`, `SKILL_DESC_*` (multiplier, current value, range), `DROP_ALL_CONFIRM`, `SUPPLY_EFFECT_*` (up to four values). All could be phrased naturally in Japanese, Korean and Chinese without reordering (GDScript `%` has no positional arguments).
- **Result: no English source change was needed.** The 15 earlier catalogs are byte-identical to `bd7401a`; the 113 unreferenced English keys were not touched.

## 3. Catalogs

Written from scratch in the English key order: the 1,272 distinct non-item English texts were translated once per language (keys sharing an English text share its translation; every sharing key was checked for a different context), and the 616 outfit/weapon item names are generated from each language's 48 enemy names. Headers carry `Language`, `Plural-Forms: nplurals=1` and the English source hash.

| Locale | Keys | Fuzzy | Empty | Placeholder / symbol errors | English-identical (unapproved / allowlisted) | Charset rule | Distinct characters | Font chain |
|---|---|---|---|---|---|---|---|---|
| ja_JP | 1,951 | 0 | 0 | 0 / 0 | 0 / 9 | all CJK in CP932 | 736 | Noto Sans JP subset → DejaVu |
| ko_KR | 1,951 | 0 | 0 | 0 / 0 | 0 / 5 | particle rule, keep-all joiners | 590 | Noto Sans KR subset → DejaVu |
| zh_CN | 1,951 | 0 | 0 | 0 / 0 | 0 / 5 | all CJK in GB2312 | 887 | Noto Sans SC subset → DejaVu |
| zh_TW | 1,951 | 0 | 0 | 0 / 0 | 0 / 5 | all CJK in Big5 | 888 | Noto Sans TC subset → DejaVu |

**English-identical entries** (per key, with reason, in `tools/localization_allowlist.json`): all four `APP_TITLE`, `GAME_TITLE`, `DISCORD` (brands), `PLAYER_STATUS`, `HUD_HP` (HP in the HUD); ja also `STATS_SHORT_HP`, `SKILL_AMOUNT_HP` (HP) and `UPGRADE_MAX`, `VALUE_MAX` (MAX, as Japanese game UI writes it).
**Simplified vs Traditional:** written separately with regional vocabulary (设置/設定, 保存/儲存, 首领/頭目, 暴击/爆擊, 精英/菁英, 物品/道具, 卡牌/卡片, 点击/輕觸, 奥术/秘法, 精通/熟練度, 小熊猫/小貓熊, 墨镜/太陽眼鏡 …) and punctuation (“” vs 「」). Of 1,951 keys, the Batch 04 probe counts how many with Han text are identical in both: under one eighth, all short shared words (技能, 武器, 雪人 …).
Full numbers: `docs/Localization_Batch_04_Evidence/catalog_validation.json` (all 19 catalogs).

## 4. Linguistic review (Claude; not native-speaker approval)

Terminology and register rules are in `docs/LootFarmer_Localization_Glossary.md` (new Batch 04 table). Merge (合成/합성), evolve (進化/진화), upgrade (強化/강화), Supply Mastery and Map Mastery (熟練度 / 숙련도 / 精通 / 熟練度), player level, claim vs pick up, gear vs supplies, Prestige (転生 / 환생 / 转生 / 轉生, always distinct from respawn 復活 / 부활 / 复活) stay distinct in every language.

- **Japanese:** friendly 〜しよう for guidance, です/ます for system messages and errors, full-width punctuation, no space before counters and units (5体, 2.5秒, 1時間05分).
- **Korean:** -하세요 / -습니다; **no batchim-dependent particle (을/를, 이/가, 은/는, 와/과, (으)로) after a placeholder** — the validator enforces it, the Korean analogue of the Turkish suffix rule (e.g. `PRESTIGE_CARD_CONFIRM` is *선택: %s · 영구히 보유할까요?*).
- **Chinese:** “Cap” enemies are 鸭舌帽 / 棒球帽, because 绿帽 (green hat) is an insult; Grim Reaper 死神; Tier 阶 / 階.
- **Mechanical script checks (all clean):** CP932 / GB2312 / Big5 membership (catches a Traditional glyph in zh_CN or a Simplified one in zh_TW/ja), Korean particle rule, placeholder order and type, symbols (^ × → ✓ • ‹), newline counts. All multi-placeholder entries were written with the English argument order and checked against their formatted output with small and large sample values (probe §6).

## 5. Fonts and rendering

**Investigation:** the theme font DejaVu Sans has no kana, Hangul or Han. Change 42 swaps a script chain into the theme only while its locale is active (Godot sizes a line by the tallest font of the chain). The toolkit already vendors the OFL Noto Sans JP/KR/SC/TC variable fonts with hashes (49.7 MB) and EverFort has a verified subsetting script, so nothing was downloaded.

**Fonts added** (details and hashes in `docs/LootFarmer_Asset_Registry.md`): `tools/build_cjk_fonts.py` checks each source against the toolkit manifest, instances weight 400 and subsets to the characters each catalog needs that DejaVu lacks → `NotoSans{JP,KR,SC,TC}-LootFarmer.ttf` (286 / 79 / 217 / 251 KB) plus four endonym subsets (3–4 KB) for the dropdown. Licences beside the fonts; OFL Reserved Font Name "Source" is not used by the subsets' family names.

**Architecture:**
- `ui_font_{japanese,korean,chinese_simplified,chinese_traditional}.tres`: regional face **first**, DejaVu second, swapped into the theme only for that locale (`SCRIPT_FONTS`). Kana, Hangul, Han and full-width punctuation draw from the regional face; digits and Latin from DejaVu (probe-verified per glyph for every string).
- **Regional glyph forms:** a shared Han character draws from the JP face in Japanese, SC in Simplified and TC in Traditional Chinese (probe). Measured outline differences between the subsets (`regional_glyph_forms.json`): of the Han characters both faces contain, JP vs SC 140 of 279 differ, JP vs TC 211 of 346, SC vs TC 179 of 485 — region-specific faces are necessary, coverage alone is not.
- **Other locales unchanged:** English, German, Russian, Vietnamese keep plain DejaVu; Thai and Hindi keep their Change 42 chains; English label height unchanged (probe). CJK line height is 1.448 em vs DejaVu 1.164 em, only in CJK locales; the sweep's `clipped_y` check finds no label or button shorter than its text.
- **Dropdown:** `ui_font_all_scripts.tres` gained the four endonym faces (line height unchanged — Thai remains the tallest, probe-verified). In a CJK locale `LocalizationService.selector_font` adds that locale's face for the translated "Automatic".
- **Found and fixed — Godot fallback order:** Godot 4.7 prefers a fallback that declares the run's script over an earlier fallback that does not. The 3–4 glyph endonym subsets lost their OpenType script records, so in a Japanese UI 日本語 drew from the JP catalog face instead of the endonym face, and 简体中文 mixed faces. Fix: `script_support` (Hani / Hang) declared in the endonym imports; every endonym now draws from its own regional face in every UI language (probe).
- **Import:** no MSDF for the CJK faces (plain rasterisation per size), so dense Han glyphs stay sharp.

**Line breaking:**
- Japanese and Chinese (ICU, `include_text_server_data` already on): across 7,351 (ja), 4,974 (zh-CN) and 5,035 (zh-TW) wrap points at a 70 px width, **no line starts with closing punctuation, 、。！？）」 or 々, and none ends with an opening bracket**. ICU's default rules do allow a break before small kana and ー (517 of 7,351 Japanese wrap points at that extreme width) — permitted non-strict Japanese line breaking, documented rather than changed.
- **Found and fixed — Korean word wrapping:** Godot breaks Hangul between any two syllables (4,107 of 5,783 wrap points were inside a word); the Korean review title wrapped as "즐기 / 고". Godot ignores ICU's `@lw=keepall`, and Label has no keep-all option. `tools/korean_keep_all.py` puts U+2060 WORD JOINERs inside every Korean word (10,833, CSS keep-all definition; the validator fails a word without them). HarfBuzz draws nothing for them (identical width and glyphs, compared by rendering), and the subsets got an **empty `.notdef`**, because a joiner at a font-run boundary ("2.5<U+2060>초") stays as glyph 0. Result: **0 of 5,535 Korean wrap points inside a word**; the title now wraps "LootFarmer 재미있게 / 즐기고 계신가요?".

## 6. Runtime integration

- **Readiness:** `ENABLED_LANGUAGES` gained `ja_JP, ko_KR, zh_CN, zh_TW` (one line; still the single source for Settings, Automatic, loading and the export allowlist). `GODOT_LOCALES` identity (Godot keeps zh_CN and zh_TW distinct: each routes to its own catalog, probe-verified), `NATIVE_NAMES` 日本語 / 한국어 / 简体中文 / 繁體中文, `TEST_BATCHES["batch04"]` (used for the test-only pass before activation: probe 171/171 and headless sweep 712 checks / 0 findings while still disabled).
- **Automatic — found and fixed:** the resolver took exact language+region before script, so `zh_Hant_CN` would read Simplified and `zh_Hans_HK` Traditional. Chinese now resolves by **script first** (Hant → zh_TW, Hans → zh_CN), then region (TW/HK/MO → zh_TW; CN/SG and every other → zh_CN), and **generic `zh` → zh_CN** (documented deterministic fallback). Java's `zh_TW_#Hant` form is parsed. Probe matrix (36 device codes): zh_CN, zh-CN, zh_SG, zh_Hans, zh_Hans_CN, zh-Hans-SG, zh_Hans_HK, zh_Hans_TW, zh, zh_CN.UTF-8 → 简体中文; zh_TW, zh_HK, zh_MO, zh_Hant, zh_Hant_TW, zh-Hant-HK, zh_TW_#Hant, zh_Hant_CN → 繁體中文; ja, ja_JP, ja-JP → 日本語; ko, ko_KR, ko_KP → 한국어; yue_HK, wuu, mn_MN, be_BY → English (never a neighbour); es_MX, es_ES, pt_PT, in_ID, uk_UA, th, hi_IN, en_GB unchanged. On a Hong Kong device the closed dropdown reads *自動 (繁體中文)* and the UI draws Traditional Chinese.
- **Dropdown:** Automatic + 20 languages = **21 rows**, no duplicates, release order, native names; scrolls with the visible bar at 432x960, 540x960 and 768x1024 (`change_40_probe`, captures in §7); keyboard, Escape/Back and the scrim unchanged.
- **Live switching:** with Settings, Upgrades, Prestige, Missions, World, Mastery and an item open, switching ja → zh_CN → ko → zh_TW → th → ja → de → zh_CN redraws titles, HUD, View Camp, catalog names, the theme font and the open dropdown's font at once; nothing English is left; back to English restores DejaVu.
- **Persistence and old saves:** zh_TW survives save/reload (not replaced by the zh_CN chosen in between), progression unchanged; a draft-era save that stored ja_JP or ko_KR keeps it and now applies it; a locale outside the target set resets to Automatic; restarting without any test switch reopens the save in Japanese.

## 7. Visual evidence

`docs/Localization_Batch_04_Evidence/` — desktop Godot windows (not phone screenshots), reviewed at full size and on the sheets:
- `contact_sheets/contact_<shape>_<group>.jpg`: 15 sheets, English + the four languages side by side at 432x960, 540x960 and 768x1024 — HUD, skill/supply items, banner, toast, reset/drop/exit confirmations; all Upgrades tabs and enemy tabs; World, Missions, Prestige (top and end), Mastery, Farming Guide, Teleport, Stats, Level; Settings (top and end), Filters, history, offline, travel map, camp, Help; mode chooser, all six Basic cards incl. targeting, The Road Ahead, review invitation for Google Play and itch.io and its failure state.
- `screens/`: 16 full-size 432x960 captures (four per language).
- `dropdown/`: closed and open menu in each CJK language, the 21-row list end, Automatic on a Hong Kong device, at all three shapes, with `<shape>_layout.json` rectangles.
- `sweep_<shape>.json` (windowed: en + Batch 04; Korean re-captured after the keep-all fix), `catalog_validation.json`, `regional_glyph_forms.json`.

Windowed sweeps: 280 + 298 + 309 screen checks, 0 findings (Korean re-sweep after the fix: 56 + 60 + 63, 0 findings). At a 432 px desktop window the 720-unit canvas is scaled to 0.6, so these captures show CJK glyphs at ~11 px; on a 1080 px phone the same 18-unit label is ~27 physical pixels. Smallest UI sizes are 13 units (fitted chips) and 10 units (slot counters, digits only).

**Next Stage chip / View Camp (known English overlap):** unchanged and not worsened — the CJK chip labels are shorter than English (e.g. *次のステージ · ボス 0/1*, *下一关 · 首领 0/1*).

## 8. Export verification

Built in a clean worktree of `bd7401a` + exactly this change's files (`project.godot` = HEAD, `export_presets.cfg` = HEAD + the regenerated `export_files`), so the developer's uncommitted preset edits (Windows export path, runnable flag) did not affect the builds. The manifest generator, run in that worktree, produces **280 files** (264 + 4 catalogs + 8 font files + 4 font chains); the three `export_files` lines were spliced into the developer's `export_presets.cfg` and the manifest is byte-identical in both trees. The local signing configuration and the Android build template were copied into the throwaway worktree for the build and removed with it.

| Target | Artifact | Result | localization/ | Fonts / text data |
|---|---|---|---|---|
| Google Play (Android Release) | signed `LootFarmerIdleRPG.c43.aab`, **63.94 MB** (Change 42: 63.17 MB, +0.77 MB) | `VERIFY_EXPORT PASS`, 280/280 sources; `com.shekinahwelefuldesigns.lootfarmeridlerpg`, versionCode/versionName 27, min SDK 24, target 36; ABIs arm64-v8a + armeabi-v7a only | **exactly 20 catalogs** (en + 19) | DejaVu, Noto Thai, Noto Devanagari, 4 regional CJK + 4 endonym faces, `icudt_godot.dat` |
| itch.io Android (Android itch.io APK) | `android_itch.pck` (`--export-pack`, 19.27 MB) | `VERIFY_EXPORT PASS`, 280/280 | 20 | same 11 fonts, ICU data |
| itch.io Windows (Windows itch.io) | **`LootFarmerIdleRPG.exe` built** (128.47 MB, PCK embedded) and `windows_itch.pck` (19.27 MB) | pack `VERIFY_EXPORT PASS`, 280/280; the `.exe`'s embedded pack contains the same 20 catalogs, 11 fonts and ICU data (directory read from the binary) | 20 | same |

- **Not packed** (checked in all three): the developer's `untranslated_ids.*`, `check_draft.py`, `translation_status.json`, `README_TRANSLATION_STATUS.md`, the ASO package, tests, tools, docs, licence text files (the OFL notice is embedded in each font).
- **itch.io APK itself not built:** Godot stopped with "Code Signing: Could not find release keystore" — the local credentials define no release keystore for that preset. I did not create one. What is verified for itch.io Android is the exact resource pack the APK would contain, not the finished, signed APK.
- Artifacts stay outside the repository (deleted with the worktree); verifier reports are in `docs/Localization_Batch_04_Evidence/export/`. Nothing was uploaded, published or pushed. As in Changes 40/42, the headless Godot process behind the AAB's Gradle build did not exit on its own and was ended by the export script's timeout.

## 9. Global 20-language readiness

| Check | Status |
|---|---|
| All 19 catalogs: exact English key set and order, 1,951 keys, no fuzzy/empty/raw keys, placeholders, symbols, newlines | **verified** (`validate_localization`, 0 problems) |
| Intentional English documented per key and reason | **verified** (allowlist; counts es 7/7, pt 11, fr 17, de 27, it 13, nl 39, pl 11, ru 3, uk 3, tr 4, id 22, vi 7, th 6, hi 8, ja 9, ko 5, zh 5/5) |
| Count/plural grammar (pl/ru/uk/hi count-neutral; Turkish no suffix on placeholders; Korean no particle on placeholders) | **verified** by validator rules |
| Glyph coverage and shaping per script (Latin, extended Latin, Cyrillic, Vietnamese, Thai, Devanagari, Japanese, Korean, Simplified, Traditional), system fonts off | **verified** (Batch 01–04 probes, sweep `missing_glyph`) |
| Script fallback does not alter other locales' metrics | **verified** (probes: English/German/Russian/Vietnamese DejaVu, Thai/Hindi chains unchanged, dropdown height unchanged) |
| Line breaking: Thai dictionary breaks, CJK punctuation, Korean keep-all | **verified** (desktop) |
| Rendered layout of every screen class, 21 languages × 3 shapes | **verified** headless (maintained sweep) and windowed for Batch 04 |
| Settings dropdown 21 rows, Automatic routing incl. Chinese script/region, persistence, old saves, live switching | **verified** (probes) |
| Store-specific review prompt (Google Play / itch.io) in every language | **verified** (sweep surfaces `review_google_play`, `review_itch_io`, `review_open_failed`) |
| Export contents for all three storefront presets | see §8 |
| **Native-speaker review** of any of the 19 languages | **not done — blocks the certification flag** |
| **Real Android device matrix** (Playbook 132.6: German, Russian, Hindi, Thai, Japanese, Simplified Chinese + Korean, Traditional Chinese) | **not done — blocks public release with these locales** |
| `ALL_LANGUAGES_CERTIFIED` | **false** (correctly) |

## 10. Tests

| Check | Result |
|---|---|
| `validate_localization` (new rules: CP932/GB2312/Big5 membership, Korean particle after a placeholder, Korean keep-all joiners) | 20 enabled, 19 catalogs × 1,951 keys, **0 problems** |
| `localization_batch04_probe` (new, registered) | **171/171** test-only before activation; **172/172** after (in the suite) |
| `localization_sweep` (defaults now pseudo + English + 19 languages × 3 shapes; U+2060 treated as a format character) | **3,714 screen checks, 0 findings** (in the suite, 312 s; timeout raised to 1,500 s) |
| headless sweep, Batch 04 test-only, 3 shapes | 712 checks, 0 findings |
| windowed sweeps, en + Batch 04, 3 shapes (+ Korean re-sweep) | 887 (+179) checks, 0 findings |
| Rewritten for the 20-language state (asserting the new availability, not weakened) | `localization_batch01/02/03_probe`, `change_40_probe` (CJK device routing), `change_35_probe` (en + 19 shipped), `ui_probe`, `bootstrap_probe` (a locale outside the target set is refused instead of a draft); `change_40_capture` gained the CJK cases |
| New tools | `tools/build_cjk_fonts.py` (`--check`), `tools/korean_keep_all.py` (`--check`) |

**Full maintained suite (`python tools/run_probes.py`, 47 entries = 3 static checks + 44 Godot scenes), once at the end in the developer's working tree: 47/47 PASS**, no script errors or timeouts (`docs/Localization_Batch_04_Evidence/suite_results.txt`).

**The three recurring failures (Changes 39–42) — investigated and fixed without touching the developer's files.** The attribution "uncommitted icon change" was correct but incomplete: the developer's `project.godot` stores `config/icon` as `uid://drj4h6jnqymfy`, which the `.import` sidecar shows is the **same file** (`assets/branding/launcher_192.png`); Godot's editor rewrites paths as uids. Proven in the clean worktree: with the developer's `project.godot` the generated manifest differs in exactly one entry, `launcher_192.png` dropping out. The tools, not the developer's edit, were wrong:
- `export_manifest` (stale): `tools/export_manifest.py` now resolves `uid://` references in `project.godot` through the `.import`/`.uid` sidecars;
- `change_27_probe` (project icon) and `change_26_probe` (core file `uid://…` ships): resolve the icon with `ResourceUID` before comparing.
All three now pass in the developer's working tree and in the clean worktree. `project.godot` was not modified; the generated manifest is byte-identical in both trees.

## 11. Limitations and open items

- **No native-speaker review** of Japanese, Korean or either Chinese (nor of Batches 01–03). Highest value: Japanese register mix (〜しよう vs です/ます), Korean honorific level and the many 터치/파밍 loanwords, Chinese idle-game terms (转生/轉生 for Prestige, 机遇/機會 for opportunity), Taiwan vocabulary choices (頭目, 菁英, 輕觸).
- **No physical device was used.** Before an update with these languages reaches players: run the Playbook 132.6 matrix on a phone, especially Japanese, Simplified Chinese, Korean and Traditional Chinese (glyph sharpness of non-MSDF CJK at real density, line height in dense panels, the 21-row dropdown by touch and Android Back, Automatic with the phone set to ja, ko, zh-CN, zh-TW and zh-HK — check the code the device reports), plus the Change 42 Thai/Hindi checks still open.
- Japanese uses ICU's non-strict line breaking (a line may start with a small kana or ー); Hong Kong/Macao players get Taiwan glyph forms (no HK face).
- Known and unchanged: the English Next Stage chip / View Camp overlap; 113 unreferenced English keys; the developer's `localization/untranslated_ids.csv` imported by Godot as CSV translations in the folder the game reads (not registered, not exported).
