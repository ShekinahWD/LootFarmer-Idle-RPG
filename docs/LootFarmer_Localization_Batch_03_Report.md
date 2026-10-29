# LootFarmer — Localization Batch 03 Report (Change 42)

**Batch:** tr-TR, id-ID, vi-VN, th-TH, hi-IN (Playbook 132.5, batch 3 of 5+5+5+4) · **Date:** 2026-10-29 · **Godot:** 4.7.2 stable · **Previous:** Change 41 `7ff484f`
**Status: PASS, enabled.** The five catalogs are complete and validated, Thai and Hindi have bundled OFL script fonts, and the five locales joined `ENABLED_LANGUAGES`: **English + 15 translations = 16 selectable languages**. The four Batch 04 drafts (ja, ko, zh-CN, zh-TW) stay hidden, refused and unpackaged. Translations were written and reviewed by Claude, **not by native speakers**; nothing was tested on a physical phone (section 10).

## 1. Baseline (verified, not assumed)

| | Value |
|---|---|
| Git | `main` at `7ff484f` (Change 41); developer's uncommitted `project.godot` (version 27, icon uid, key order) and `export_presets.cfg` (Windows runnable preset and editor-added keys) present before and after, never reverted |
| `localization/en.po` | **1,951 keys**, SHA-256 `d6102fcc…d47fe7e3` — matches the Change 41 report; unchanged by this change |
| Enabled before | en + es-419, es-ES, pt-BR, fr-FR, de-DE, it-IT, nl-NL, pl-PL, ru-RU, uk-UA (11); `validate_localization` 10 catalogs, 0 problems |
| Batch 03 drafts | 1,921 keys each (the older source), 1,215 fuzzy English fallbacks each, item names glued to English enemy names. Used as reference only; backups outside the repository (session scratchpad) |

## 2. English source audit

- **Static:** every literal `tr("KEY")` in `scripts/` resolves in `en.po` (0 missing); 35 dynamic `tr(expr)` sites reviewed (mission/goal/follow kinds, panel titles, supply rules, joystick/slot choices, store CTA, guide keys + `_DETAIL`) — every key they can build exists. Codes the UI never shows (`HEALTH_FULL`, `SKILL_COOLDOWN`, … skill-block reason codes) are the documented exceptions.
- **Rendered:** the pseudo-locale sweep (in the suite) reports no on-screen text outside the catalog; the Change 41 additions (joystick position, Discord, chooser details, drop notices, collection 21/31/41 text) are all catalog-driven.
- **Glued phrases** reviewed for word-order languages: `"+%s %s"` stat labels, `NEXT_MERGE_GAIN + gains`, `HISTORY_ITEM`, compass + camp + distance (`FARMING_LOCATION`), names arriving in the nominative with their map (`NAME_ON_MAP`), `MISSION_GOAL`.
- **Result: no English source change was needed.** All 10 earlier catalogs are byte-identical to `7ff484f`. The 113 unreferenced keys were not touched.
- **Plurals:** the source still has no gettext plurals. Turkish, Indonesian, Vietnamese and Thai do not inflect nouns after numerals; Hindi does, so it follows the count-neutral rule (§4).

## 3. Catalogs

`localization/{tr_TR,id_ID,vi_VN,th_TH,hi_IN}.po`, written from scratch in English key order; headers carry `Language`, `Plural-Forms`, the batch and the English source hash. Item and tier names (610 per language) are generated from each language's 48 enemy names, so an item always matches its enemy.

| Locale | Keys | Fuzzy | Empty | Placeholder / symbol errors | Raw keys | Count errors | English-identical (unapproved / allowlisted) | Distinct characters | Font |
|---|---|---|---|---|---|---|---|---|---|
| tr_TR | 1,951 | 0 | 0 | 0 / 0 | 0 | — | 0 / 4 | 95 | DejaVu Sans |
| id_ID | 1,951 | 0 | 0 | 0 / 0 | 0 | — | 0 / 22 | 83 | DejaVu Sans |
| vi_VN | 1,951 | 0 | 0 | 0 / 0 | 0 | — | 0 / 7 | 183 | DejaVu Sans |
| th_TH | 1,951 | 0 | 0 | 0 / 0 | 0 | — | 0 / 6 | 131 | DejaVu + Noto Sans Thai |
| hi_IN | 1,951 | 0 | 0 | 0 / 0 | 0 | 0 | 0 / 8 | 131 | DejaVu + Noto Sans Devanagari |

**English-identical entries** (each named per key with its reason in `tools/localization_allowlist.json`):
- all five: `APP_TITLE`, `GAME_TITLE` (brand), `DISCORD` (service name);
- id, vi, th, hi: `PLAYER_STATUS`, `HUD_HP`, `STATS_SHORT_HP` (HP abbreviation); hi also `SUPPLY_AMOUNT_XP`, `MASTERY_REWARD_XP` (XP);
- tr, vi: `BOSS_LABEL` ("Boss" is the players' word; Turkish *patron* means employer);
- id: KBBI/gaming loanwords *level* (6 keys; *tingkat* is reserved for item tier), *item* (2), *reset*, *offline*, *damage/dmg* (5), *farming*.

Full numbers: `docs/Localization_Batch_03_Evidence/catalog_validation.json`.

## 4. Linguistic review (Claude; not native-speaker approval)

Terminology is in the shared glossary (`docs/LootFarmer_Localization_Glossary.md`, new Batch 03 table and rules). Merge / evolve / upgrade / Supply Mastery / Map Mastery / player level, claim vs pick up, gear vs supplies, loot vs trophy stay distinct in every language.

**Placeholder order** (GDScript `%` has no positional arguments): all 128 keys with two or more value placeholders were printed side by side with English for Turkish and Hindi (the verb-final languages) and checked by hand. Six lines I had reordered were fixed before integration: tr/hi `SKILL_DESC_HEAL`, `SKILL_DESC_FROST`, `SKILL_DESC_FIRE`, tr `SUPPLY_EFFECT_COINS`, `SUPPLY_EFFECT_XP`. Indonesian, Vietnamese and Thai keep the English argument order by construction.

**Corrections made during review**
- *Turkish:* no case suffix is attached to a placeholder (vowel harmony depends on the unknown value): 9 lines rewritten (`Seç: Kamp %d`, `Kuşan: yuva %d`, `Can (seviye %d)`, `Kamp %d yanında`, `en fazla ^%d`, `canın %%%s kadarı`, `^%s seviyesine`, …); fixed names keep their proper suffix (*Kardan Adam'ı, Kış II'yi, Yaz I'e*). Trophy became *kupa* (I had first reused *ganimet*, the loot word). "Unlocked but OFF" no longer says *açık* (open) next to *KAPALI*. Percent sign first (*%12*): the validator now compares `%%` by count, not position. All-caps headers checked for İ/ı (*SEVİYE, KUŞANILI, AÇIK*); the UI never auto-uppercases.
- *Hindi:* count-neutral wording where a noun would inflect (1 सिक्का / 2 सिक्के): *सिक्के: %s*, *मर्ज हुई प्रतियाँ: %d*, `CAMP_STATE_LOCKED`, `SPAWN_BUY`, `CLAIM_REWARD`, `OFFLINE_RATES`, `COIN_UPGRADE_GAIN`; the validator now enforces it (`COUNT_FOLLOWERS['hi_IN']`, danda treated as punctuation). Verbs never agree with a name placeholder (*हराएँ: %s*). Item names use *की* (पोशाक and तलवार are both feminine).
- *Thai:* **ค่าย replaced the loanword แคมป์ for "camp"** (80 occurrences): Godot's ICU dictionary wrapped it as แคม|ป์. **ๆ attached** (ใกล้ๆ, 11 lines), so a line can never start with ๆ.
- *Indonesian:* collection descriptions name the button (*Tombol Serahkan mengambil 20 …*); title *Petani Ulung*.
- *Vietnamese:* Summer is consistently *Mùa Hè*; Onyx scythe *Mã Não Đen*; Prestige *Chuyển sinh*, deliberately distinct from respawn *hồi sinh*. Every string is NFC (precomposed tone marks).
- *Script checks (all clean):* no orphan combining marks, no space before a Thai mark, no stray Latin words in Thai/Hindi except HP/XP/EXP, brands and Roman stage numerals.

## 5. Fonts and text shaping

**Investigation:** the theme uses one font, DejaVu Sans (MSDF). It covers every Turkish and Vietnamese character (precomposed Vietnamese), but has **no Thai and no Devanagari**; its import allows system fallback, which on the Windows desktop silently drew Thai through Windows fonts — so every check below runs with system fallback switched off or uses `Font.has_char`, which never consults system fonts.

**Fonts added** (details in `docs/LootFarmer_Asset_Registry.md`): Noto Sans Thai 2.002 and Noto Sans Devanagari 2.007, SIL OFL 1.1, byte-identical to the copies already vendored and hash-recorded in `Godot-Marketing-Toolkit/assets/fonts/` (nothing downloaded). Not subset (small; keeps GSUB/GPOS intact). Licences beside them in `assets/Fonts/`; the OFL notice is also embedded in each font's name table.

**Architecture decision (measured):** a fallback chain in the theme would change every existing layout — Godot sizes a line by the tallest font in the chain (Noto Thai 1.511 em vs DejaVu 1.164 em): English Label height went 19 → 24.3 px in the test, while Latin widths were unchanged. So:
- `resources/game/ui_font_thai.tres` / `ui_font_devanagari.tres` (DejaVu + one Noto fallback) become the theme default font **only while th_TH or hi_IN is active** (`LocalizationService.SCRIPT_FONTS`, switched together with the locale, live);
- every other locale keeps the plain DejaVu theme font, so the 11 earlier languages render exactly as before;
- the language dropdown and its menu always use `ui_font_all_scripts.tres`, so ไทย and हिन्दी show in every locale.

**Shaping and line breaking** (`localization_batch03_probe`, system fallback off): every catalog character of each locale is in that locale's chain; every glyph of all 1,951 strings × 5 comes from a bundled font (no empty box); क्ष shapes as one conjunct glyph; कि places the i-matra before its consonant in one cluster (no dotted circle); ट्रॉफ़ियाँ ligates; ปั้น stacks vowel and tone mark; Thai without spaces breaks only at dictionary word boundaries (ปลด|ล็อก|ค่าย|แล้ว) and no Thai catalog line can wrap before a following vowel, ๆ or mark; a Thai sentence wraps to 4 lines in a 130 px label; Vietnamese stacked diacritics shape without missing glyphs.
**Exports:** `internationalization/locale/include_text_server_data=true` (the one-line addition to `project.godot`) packs Godot's ICU data (`icudt_godot.dat`, 4.8 MB) so Thai wraps the same way in exported builds; `verify_export.py` now fails if the setting is on and the data is missing.
**Line height:** Thai/Hindi lines are taller by design (their own metrics); the sweep's new `clipped_y` check found no UI label or button shorter than its text in any language.

## 6. Runtime integration

- **Readiness:** `ENABLED_LANGUAGES` gained the five ids (one line, still the single source for Settings, Automatic, loading and the export manifest); `GODOT_LOCALES` (identity), `NATIVE_NAMES` (*Türkçe, Bahasa Indonesia, Tiếng Việt, ไทย, हिन्दी*), `TEST_BATCHES["batch03"]` (used for the test-only pass before activation). `ALL_LANGUAGES_CERTIFIED` stays false. `project.godot` still registers only `en.po`; catalogs load on first use.
- **Automatic** (probe-verified): tr, tr_TR, tr_CY → tr_TR; id, id_ID, id-ID and the legacy Android codes in, in_ID → id_ID; vi → vi_VN; th → th_TH; hi → hi_IN; en_IN, ms_MY, jv_ID → English (no neighbour language); ja_JP, zh_CN → English (Batch 04 never reached). On a Thai device the closed dropdown reads *อัตโนมัติ (ไทย)* and the UI draws Thai.
- **Dropdown:** Automatic + 16 languages (17 rows), in release order, native names; at 540x960 and 768x1024 the menu scrolls with the visible bar, at 432x960 the Change 40 placement rules still hold (`change_40_probe`).
- **Live switching:** from the real dropdown to ไทย with Settings open, then Upgrades, Prestige, Missions, World, Mastery and an item open while switching hi → tr → vi → id → th → hi: titles, HUD, View Camp, catalog names and the theme font redraw at once; nothing English left; back to English restores DejaVu.
- **Persistence and old saves:** Hindi survives save/reload (not replaced by the Vietnamese chosen in between), progression untouched; a stored th_TH from a test build is kept; a stored Batch 04 draft (ja_JP) shows English and stays stored; restarting without any test switch reopens the save in Turkish.

## 7. Visual evidence

`docs/Localization_Batch_03_Evidence/` (desktop Godot windows; reviewed at full size and on the contact sheets):
- `contact_sheets/contact_<shape>_<group>.jpg`: 15 sheets, English + the five languages side by side at 432x960, 540x960 and 768x1024, 38 screens: HUD, skill/supply items, stage banner, toast, drop/reset/exit confirmations; Upgrades tabs, enemy tabs; World, Missions, Prestige, Mastery, Farming Guide, Teleport, Stats, Level; Settings top/end, Filters, history, offline, travel map, camp, Help; mode chooser, Basic cards incl. targeting, The Road Ahead, review invitation and its failure state.
- `screens/`: 17 full-size 432x960 captures (Thai HUD/Upgrades/skill/Help, Hindi HUD/Prestige/Mastery/Road Ahead, Turkish Settings/Stats/Level, Vietnamese Missions/supply/chooser, Indonesian World/review/targeting) and `next_stage_chip_vs_view_camp_432x960.png`.
- `dropdown/`: closed and open menu in Thai and Hindi, Automatic on a Thai device, and the scrolled list end in English at all three shapes.
- `sweep_<shape>.json` (windowed) and `sweep_headless_en_batch03.json`.

**Next Stage chip / View Camp (known English overlap):** all five Batch 03 chip labels are narrower than English with the real fonts (151–207 px vs 215 px at 18 px; German 254), so none worsens it. The English overlap itself is unchanged and out of scope.

## 8. Export verification (real packages, clean worktree)

The manifest generator refuses the working tree (the developer's icon-uid edit adds `launcher_192.png` differences — the known cause), so `tools/export_manifest.json` and the three `export_files` lines were regenerated in a clean worktree of `7ff484f` + this change and spliced into the developer's `export_presets.cfg` (every other line of their copy untouched). **264 files** (was 254: +5 catalogs, +2 fonts, +3 font chains).

| Preset | Artifact | Result | localization/ | Fonts / ICU |
|---|---|---|---|---|
| Android Release (Google Play) | signed `LootFarmerIdleRPG.c42.aab`, 63.17 MB (Change 40: 59.60 MB) | VERIFY_EXPORT PASS, 264/264, ABIs arm64-v8a + armeabi-v7a, `com.shekinahwelefuldesigns.lootfarmeridlerpg`, versionCode 27 (HEAD) | en + 15 | DejaVu, Noto Thai, Noto Devanagari, 3 chains, `icudt_godot.dat` 4.8 MB |
| Android itch.io APK | `android_itch.pck` (`--export-pack`) | PASS, 264/264 | en + 15 | same |
| Windows itch.io | `windows_itch.pck` (`--export-pack`) | PASS, 264/264 | en + 15 | same |

No Batch 04 catalog, `untranslated_ids.*`, `check_draft.py`, `translation_status.json`, ASO file, test or tool is packed. The AAB was signed with the developer's local keystore configuration (copied into the throwaway worktree for the build and deleted afterwards); the itch.io APK and Windows executables themselves were not built (the packs are their exact resource content). Nothing was uploaded, published or pushed. Artifacts are in the ignored `tests/tmp/export/` of the worktree.

## 9. Tests

| Check | Result |
|---|---|
| `validate_localization` (now also: `%%` by count, Hindi count rule) | 16 enabled, 15 catalogs × 1,951 keys, 4 drafts hidden, **0 problems** |
| `localization_batch03_probe` (new, registered) | 132/132 test-only before activation; **135/135** after (in the suite) |
| `localization_sweep` (defaults now 17 languages × 3 shapes; new `missing_glyph`, `clipped_y` checks) | **2,996 screen checks, 0 findings** (in the suite, 248 s; timeout raised to 900 s) |
| windowed sweep, en + Batch 03 × 3 shapes | 1,055 screen checks, 0 findings |
| Updated for 16 languages / 4 drafts | `localization_batch01_probe`, `localization_batch02_probe`, `change_40_probe` (dropdown size from the enabled list), `change_35_probe` (en + 15 shipped), `ui_probe`, `bootstrap_probe` (draft examples now Batch 04) |
| Tooling fix | `validate_campaign_source.py` read scripts in the Windows code page and crashed on the new Thai/Devanagari text; it now reads UTF-8 |

**Full maintained suite (`python tools/run_probes.py`, 46 entries = 3 static checks + 43 Godot scenes), once at the end in the developer's working tree: 43/46**, no script errors or timeouts. The three failures are the pre-existing ones from the developer's uncommitted `project.godot` / `export_presets.cfg` edits (the same three as Changes 39–41), not regressions:

| Check | Failure | Cause |
|---|---|---|
| `export_manifest` | stale: the working-tree generator adds `launcher_192.png` | uncommitted `config/icon` uid |
| `change_27_probe` | project icon is the launcher icon | same |
| `change_26_probe` | core file `uid://drj4h6jnqymfy` ships | same |

**Clean worktree** (`7ff484f` + exactly this change's files, `project.godot` = HEAD + `include_text_server_data`): `validate_campaign_source`, `export_manifest`, `validate_localization`, `change_27_probe`, `change_26_probe`, `change_35_probe`, `localization_batch01/02/03_probe`, `change_40_probe`: **10/10 pass**. Exports were built from that worktree (its committed config, versionCode 27).

Key totals: `localization_batch01_probe` 82/82, `localization_batch02_probe` 102/102, `localization_batch03_probe` 135/135, `change_40_probe` 86/86, `localization_sweep` 2,996 checks / 0 findings.

## 10. Limitations and open items

- **No native-speaker review** of any of the five languages. Highest value before release: Hindi register and gender agreement, Thai wording/word-wrap feel, Turkish suffix-free task lines, Indonesian loanword density (22 English-identical lines).
- **No physical Android device was used.** Before an update with these languages reaches players, run the Playbook 132.6 smoke test on a phone, especially **Thai and Hindi**: shaping and stacking at real density, line height in dense panels, the dropdown by touch (17 rows) and Android Back, Automatic with the phone set to Thai, Hindi, Indonesian (check that the device reports `in_ID` or `id_ID` and both resolve) and Turkish, persistence across an app restart. The ICU line-breaking data is verified in the exported pack, not on a device.
- Known and unchanged: the English Next Stage chip / View Camp overlap; 113 unreferenced English keys; the developer's `localization/untranslated_ids.csv` imported by Godot as CSV translations in the folder the game reads (not registered, not exported).
- A headless Godot process from the AAB export may linger on the build machine (as in Change 40); I was not permitted to stop it.
- **Next:** Batch 04 — Japanese, Korean, Simplified Chinese, Traditional Chinese (CJK fonts will need subsetting and per-locale Han ordering). Not started.
