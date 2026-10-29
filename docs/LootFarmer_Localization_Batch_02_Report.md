# LootFarmer — Localization Batch 02 Report (Change 39)

**Batch:** it-IT, nl-NL, pl-PL, ru-RU, uk-UA (Playbook 132.5, batch 2 of 5+5+5+4) · **Date:** 2026-10-29 · **Godot:** 4.7.2 stable
**Status: PASS (test-only).** All five catalogs are complete, validated and integrated behind the Batch 01 probe-only override. Normal players still see only English: the global 20-language gate is closed and Automatic resolves to English. Physical Android checks are still to do (see Limitations). The translations were reviewed by me (Claude), **not by native speakers**.

## 1. English source audit (done first)

| | Count | SHA-256 |
|---|---|---|
| `en.po` at the start (Change 38, `fb92399`) | 1,941 | `4440b694…f26ffaf4` |
| **`en.po` at the end (Change 39)** | **1,941** | **`4440b694…f26ffaf4` (unchanged)** |

No code changed since Change 38. The audit was rerun anyway:

1. **Static scan:** every `tr("KEY")` in `scripts/` exists in `en.po`, and no UI text, title, tooltip or toast is assigned an English literal. Result: 0 missing keys, 0 hardcoded strings.
2. **Rendered pseudo-locale sweep:** the maintained `localization_sweep` (pseudo + English + 10 languages) still reports no text outside the catalog.
3. **Dynamic and glued text:** reviewed where code builds sentences, because Polish, Russian and Ukrainian decline what English leaves alone.
   - `_short_stat` glues `"+%s %s"` (number + `STATS_SHORT_*`).
   - Mission cards join `GOAL_*` and an enemy name.
   - `FOLLOW_NEXT` appends `" ×%d"`.
   - Names reach `FOLLOW_GOAL_KILL_TARGET`, `MISSION_DO_*`, `FOLLOW_*` in the nominative together with their map ("Blue Cap (Winter I)").
   - Durations, card values and Prestige chain progress from Change 38 are intact.

**Findings:**

- **No English source change was needed.** Every glued fragment can be translated correctly with the right word form:
  - genitive stat labels after a number (ru *урона*, uk *шкоди*, pl *obrony*);
  - a colon before a name the code cannot inflect (*Победи: %s*).
  Batch 01 catalogs are therefore untouched (verified identical to `fb92399`).
- **Plural intent:** the source has no gettext plurals. Only three lines use "(s)": `CAMPS_HIDDEN`, `PRESTIGE_BATCH`, `PRESTIGE_CONFIRM_SUMMARY`, `MILESTONE_PRESTIGED_DETAIL` uses "card(s)" too. Adding `msgid_plural` would change the source, code and all Batch 01 catalogs. Instead, Polish, Russian and Ukrainian use count-neutral wording, which is correct for every number (glossary "Counts and plurals"). The validator now enforces it. Recorded as an accepted limit; real plural forms remain an option for the global gate.
- **The 113 unreferenced keys** (e.g. `HELP_0`–`HELP_7`, `PRESTIGE_CONFIRM`, `NO_OFFLINE`, `LANGUAGE_NOTE`, `MISSION_GOAL`, `UPGRADE_COST`, `CLAIM_REWARD`, `COINS`, `GEMS`, `HISTORY_SOLD`) are still unreferenced. They were kept and translated, not deleted.
- **Intentional non-player-visible exceptions** are unchanged from Batch 01 (skill-block reason codes, the `"HERE"` compass value).

## 2. Catalogs

`localization/{it_IT,nl_NL,pl_PL,ru_RU,uk_UA}.po`, written from scratch against the current English. Headers: `Language`, `Plural-Forms` (three forms for pl/ru/uk), source hash, no fuzzy header.

**The drafts were reference only.** Each had 125 adapted entries (UI basics, stage and some enemy names) and 1,217 fuzzy English fallbacks. Their item names glued the English enemy name onto the outfit word (*Костюм Blue Cap*, *Miecz Sunglasses*, *Spada di Plain*), and the drafts gave Cyan Robot and Teal Dinosaur the same Russian and Ukrainian colour. Backups of the five drafts are outside the repository (session scratchpad).

| Locale | Keys | Fuzzy | Empty | Placeholder errors | Symbol errors | Raw keys | Count-agreement errors | English copies (unapproved / allowlisted) |
|---|---|---|---|---|---|---|---|---|
| it_IT | 1,941 | 0 | 0 | 0 | 0 | 0 | — | 0 / 12 |
| nl_NL | 1,941 | 0 | 0 | 0 | 0 | 0 | — | 0 / 38 |
| pl_PL | 1,941 | 0 | 0 | 0 | 0 | 0 | 0 | 0 / 10 |
| ru_RU | 1,941 | 0 | 0 | 0 | 0 | 0 | 0 | 0 / 2 |
| uk_UA | 1,941 | 0 | 0 | 0 | 0 | 0 | 0 | 0 / 2 |

**English-identical entries:** each is named per key with its reason in `tools/localization_allowlist.json`.

- **ru, uk:** only the brand titles.
- **pl:** Auto, Boss, Offline, Hindi, Teleport.
- **it:** Auto, MAX, Offline, Boss, crit, Farming, Feedback, Hindi.
- **nl:** HP/XP abbreviations; the loanwords Upgrades, Outfit(s), Offline, Boosts, Feedback; the cognates Prestige, Elite, Winter I/II, Details, Filters, Thai, Hindi.

Full numbers: `docs/Localization_Batch_02_Evidence/catalog_validation.json`.

**Linguistic review (manual, by me; not a native-speaker sign-off).**

- **Concepts kept distinct in every language:** merge, evolve, upgrade, Supply Mastery, Map Mastery and player level; claim versus collect; gear versus supplies (glossary).
- **Placeholder order:** reviewed by hand for all 105 entries with repeated `%s`/`%d`, per language. No reversal found. Restructured lines keep the English argument order (e.g. «Объединено копий: %d · предметов: %d»).
- **Grammar corrections made during review:**
  - *Counts:* pl/ru/uk number-plus-noun lines rewritten count-neutral. 2 Polish lines changed from "+%s obrażeń" (wrong for 2–4) to "obrażenia +%s". Polish "%s ukończone" changed to "%s: ukończono", which agrees with any category name.
  - *Stat labels:* the short labels glued after "+N" became invariant genitives (ru *урона, вампиризма*; uk *шкоди, крадіжки життя*; pl *kradzieży życia*).
  - *Italian:* count lines with "carta/e"-style slashes removed. *Saetta* instead of *Colpo di fulmine*, which means love at first sight.
  - *Ukrainian:* «Зароби» (imperative), «Оніксова коса».
  - *Polish:* "przedmioty (wraz z zapasami)" instead of the tautological "zapas zapasów".
  - *Dutch:* *IJsstoot* with the IJ digraph capitalised. *vak* for slot, because *slot* means "lock" in Dutch. "XP per verslagen vijand" instead of a copied English line.
- **Names:** item names are built from the enemy name in the genitive (pl/ru/uk), as Italian *Costume da …* / *Spada di …*, or as Dutch hyphenated compounds. Fixed numbers in Prestige descriptions are inflected by hand: *3 босса / 3 bossów / 3 боси*, *72 часа / 72 godziny / 72 години*. Cyan Robot and Teal Dinosaur now have different colours in every language.
- **Russian and Ukrainian are independent.** Ukrainian has its own vocabulary:
  - *мапа* for map and *картка* for card; Russian uses *карта* for both, so Russian card = *карточка*;
  - *вбрання* (ru *костюм*);
  - *поєднати* (ru *объединить*);
  - *нагода* (ru *возможность*);
  - *Торкнись* (ru *Нажми*).
  The probe measures 57 of 1,899 worded lines identical, all numbers, abbreviations or true cognates (*Престиж*, *Пауза*, *Зима I*).
- **Register:** informal everywhere (tu / je / ty / ты / ти), as in Batch 01 except French.

## 3. Runtime integration

- **Gate (unchanged for players):**
  - `project.godot` registers only `res://localization/en.po`.
  - `TRANSLATIONS_RELEASE_READY = false`.
  - Automatic → `en`.
  - A saved `ru_RU`, `it`, `ru` or `uk_UA` preference loads as Automatic (English).
  - Settings lists Automatic, English and 19 languages, 19 disabled, with no notice.
- **Test-only override:**
  - `LocalizationService.TEST_BATCHES` gains `"batch02"`.
  - `--test-languages=` now accepts a comma list (`batch01,batch02`), still only with a probe/capture profile.
  - `enable_test_batch("batch02")` is refused outside probes, and so is an unknown batch name.
  - With both batches registered, 9 languages stay disabled.
- **Godot locale mapping** (`GODOT_LOCALES`, validator `GODOT_LOCALE`): `it_IT→it_IT`, `nl_NL→nl_NL`, `pl_PL→pl_PL`, `ru_RU→ru_RU`, `uk_UA→uk_UA`. Probe-verified device matches for when Automatic is enabled later: `ru`→ru_RU, `uk`→uk_UA (not Russian), `pl`→pl_PL, `it_CH`→it_IT, `nl_BE`→nl_NL.
- **Live switching:** the Batch 01 machinery redraws everything.
  - Probe-verified from the real Settings button (Russian), and with Upgrades, Prestige, Missions, World, Mastery and an item open while switching among uk, pl, it, nl and ru.
  - Panels redraw, the HUD level line redraws, View Camp, the guide's buttons and catalog enemy/stage names are re-translated, and no English is left.
- **Persistence:** Ukrainian survives save and reload (not replaced by the Russian that was selected in between), and progression is untouched. Restarting without the override opens the same save in English.
- **Export:** unchanged. The test-only load site stays family `test_language_catalogs` with no values, so release exports carry none of the catalogs; `export_rules.json` wording now names both batches. Test exports with the catalogs were not built (global-gate task).

## 4. Fonts and layout

- **Glyphs:** DejaVu Sans (theme font) has every character each catalog uses, plus the full alphabet of each script. That includes Russian ё and Ukrainian і ї є ґ, the Ukrainian apostrophe ’, Polish ą ć ę ł ń ó ś ź ż, «» and „” quotes, and the no-break space: it 94, nl 89, pl 100, ru 137, uk 138 distinct characters. Rendered text was inspected, not just byte validity. No new font was needed.
- **Headless sweep** (it, nl, pl, ru, uk × 432x960, 540x960, 768x1024): 883 screen checks, **0 findings**. It checks raw keys, English leaks, text outside the catalog, clipped single-line text, horizontal overflow, small buttons and missing scroll indicators.
- **Windowed sweep with screenshots** (English + 5 languages): 336 / 359 / 363 screen checks at the three shapes, **0 findings**.
- **Next Stage chip / View Camp overlap** (known since Batch 01):
  - Rechecked in the onboarding fixture. In English the chip overlaps the right end of the View Camp button by a few pixels.
  - The first Dutch, Russian and Polish versions made it worse, because the longer chip grew leftward over the button ("Kamp bekij…", "Осмотреть лагер…").
  - **Fixed in the localized layout** with shorter, equivalent chip labels: *Verder: bazen 0/1*, *Dalej: bossowie 0/1*, *Дальше: боссы 0/1*, *Далі: боси 0/1*. The full meaning stays in the chip's tooltip.
  - All five now clear the button (`screens/next_stage_chip_vs_view_camp_432x960.png`).
  - The English overlap itself is unchanged and stays a pre-existing English layout issue (out of scope: no UI refactor).

## 5. Validation

| Check | Result |
|---|---|
| `python tools/validate_localization.py`: structure, placeholders in order, symbols, copy-through allowlist, raw keys, English words, headers, `project.godot` gate, scene keys, **new:** pl/ru/uk count agreement | 0 problems, 10 catalogs × 1,941 keys |
| `localization_batch02_probe` (new, in suite). Covers: gate, refusal outside probes, routing and device matches, Godot loader returns all 1,941 keys × 5, glyph coverage, ru/uk independence, both batches together, dynamic formatting of every placeholder string, durations, count lines for 1/2/5/21/22, live switching, persistence, old settings, restart without override | 101/101 |
| `localization_batch01_probe` (unchanged) | passes in the suite |
| `localization_sweep` (defaults now pseudo + English + Batch 01 + Batch 02 × 3 shapes) | 0 findings in the suite |
| Full maintained suite (`python tools/run_probes.py`) | see section 8 |

The suite runner now also runs `tools/validate_localization.py` as a static check, so a catalog regression fails the suite.

## 6. Visual evidence

`docs/Localization_Batch_02_Evidence/`:

- `contact_sheets/contact_<shape>_<group>.jpg`: 15 sheets, English plus the five languages side by side, at 432x960 (20:9), 540x960 (16:9) and 768x1024 (4:3). They cover 27 screens:
  - HUD; skill and supply item details; stage banner;
  - drop and reset confirmations;
  - Upgrades tabs (Player, Supplies, Gems); enemy tabs (Overview, Upgrades);
  - World, Missions, Prestige, Mastery, Farming Guide, Teleport, Stats, Level;
  - Settings top and language list; Help;
  - review invitation and its failure state;
  - onboarding chooser, Basic targeting card, The Road Ahead.
- `screens/`: 15 full-size captures at the narrowest shape, plus the chip comparison:
  - Russian: HUD, Prestige, review;
  - Ukrainian: supply and skill details, language list;
  - Polish: Upgrades, drop confirmation, Mastery;
  - Italian: Missions, Road Ahead;
  - Dutch: targeting card, Stats;
  - English targeting card.
- `catalog_validation.json`, `sweep_<shape>.json`.

I reviewed the full-size captures and every contact sheet myself, in desktop Godot windows, not on a phone. Outfit and weapon item details were neither captured nor swept: the sweep fixture equips them, so they leave the inventory grid. The item panel is the same component as the captured skill and supply panels, and the probes open an item with a language switch. The outfit- and weapon-specific lines (milestones, evolution) were checked only as text, by the validator and by hand. A fixture with a stored outfit and weapon is a small follow-up.

## 7. Limitations and device TODO

- **No Android device was used.** Representative phone check still to do:
  - Russian and Polish with the longest strings: HUD, Upgrades tabs, Prestige, item details, review invitation, persistence across app restart.
  - Ukrainian glyphs (і ї є ґ ’) on device.
  - This must be a test build with `--test-languages=batch02`, or the global gate.
- **No native-speaker review.** It is advisable before release, especially for Polish and Ukrainian case forms in item names and the informal register in Russian.
- **Test exports with the catalogs** (APK/AAB/Windows) were not built. That belongs to the global gate, when the catalogs are registered in `project.godot` and `tools/verify_export.py` runs.
- **Pre-existing, not changed:**
  - The English Next Stage chip / View Camp overlap.
  - 113 unreferenced English keys.
  - The developer's untracked `localization/untranslated_ids.csv`, which Godot imports as a CSV translation (`untranslated_ids.*.translation`). It is not registered in `project.godot` and not in the export allowlist, but it sits in the folder the game reads (Playbook 132.5 hazard; left for its owner).
  - The uncommitted `project.godot` / `export_presets.cfg` edits in the working tree.
- **Numbers formatted by code** keep the decimal point (`1.5`), as in Batch 01; only numbers written inside sentences use the decimal comma.

## 8. Regression and handoff

**Full maintained suite, final run in the working tree: 40/43 pass**, no script errors and no timeouts. The suite is `validate_campaign_source`, `export_manifest`, `validate_localization` and 40 Godot scenes.

| Probe | Result |
|---|---|
| localization_batch01_probe | 77/77 |
| localization_batch02_probe | 101/101 |
| localization_sweep | 2,114 checks, 0 findings |

**The 3 failures are pre-existing and outside this change.**

- **Failing checks:**
  - `export_manifest`: Android itch.io version 27 ≠ project 26.
  - `change_27_probe`: project version and launcher icon.
  - `change_26_probe`: icon uid.
- **Cause:** all three read the developer's uncommitted edits to `project.godot` and `export_presets.cfg`, which were in the working tree before this change started (`config/version` 27 → 26, icon path → uid, an extra Windows preset). Those edits were left untouched and are not in the commit.
- **Clean worktree:** on a clean worktree of the final Change 39 commit, all three pass (`validate_campaign_source`, `export_manifest`, `validate_localization`, `change_27_probe`, `change_26_probe`: 5/5). That run also found a regression of mine: the `export_rules.json` wording change had left `tools/export_manifest.json` stale. It was regenerated (still 239 files, no catalogs) and committed.

**Handoff for Batch 03 (tr_TR, id_ID, vi_VN, th_TH, hi_IN):**

1. Translate against `en.po` `4440b694…` (1,941 keys). The drafts in `localization/` are reference only; their item names are English-glued.
2. Add `"batch03"` to `TEST_BATCHES` and `GODOT_LOCALES`, and its locales to `GODOT_LOCALE` in the validator.
3. Fonts: **Thai and Devanagari are not in DejaVu Sans.** Batch 03 needs script fallbacks (`FontVariation` chain) with licence provenance, and Thai line breaking (`include_text_server_data`). The glyph check will fail until then.
4. Turkish: dotted/dotless i casing in all-caps headers (`LEVEL`, `COMPARE_*`); check uppercase strings by hand.
5. Extend the count-agreement idea only if a language needs it (Turkish, Indonesian, Vietnamese, Thai and Hindi have no count inflection on nouns after numerals in the same way).
6. Do not register any catalog in `project.godot` before the global gate.
