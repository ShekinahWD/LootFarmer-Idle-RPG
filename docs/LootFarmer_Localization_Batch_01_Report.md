# LootFarmer — Localization Batch 01 Report (Change 38)

**Batch:** es-419, es-ES, pt-BR, fr-FR, de-DE (Playbook 132.5, batch 1 of 5+5+5+4) · **Date:** 2026-10-28 · **Godot:** 4.7.2 stable
**Status: PASS (test-only).** All five catalogs are complete, validated and integrated behind a probe-only override. Normal players still see only English: the global 20-language gate is closed and Automatic resolves to English. Physical Android checks are still to do (see Limitations).

## 1. English source audit (done first)

| | Count | SHA-256 |
|---|---|---|
| Historical draft source (`en(1).po`, from the partial-draft ZIP) | 1,921 | `b334a6de…3015172` |
| Current `en.po` at the start (Change 37, `e83e439`) | 1,935 | `f7767fe3…e22800827` |
| **Final `en.po` (Change 38)** | **1,941** | **`4440b694…f26ffaf4`** |

**Since the draft (1,921 → 1,935):** the 14 Change 35 strings in `tools/change35_strings.json`: review invitation, Google Play/itch.io buttons, the open-failure message, Feedback section, the Basic and Guided targeting lessons. Two strings were reworded by Change 36 (`SUPPLY_MASTERY_EXPLAIN`, `SUPPLY_NO_MERGE`: mastery every 3 uses). One obsolete draft key, `CONTENT_ITEMS_SKILL_HEAL`, was absent from that draft only; it exists in `en.po` and is translated. None of the drafts had the Change 35 or 36 text.

**Audit method.** I did not rely on key parity with the draft:

1. **Static scan** of every string literal in `scripts/` and every scene `text`/`tooltip_text`/`title`, compared against `en.po`.
2. **Data-driven key check:** 655 keys the code builds at run time (`GUIDE_<step>`, `UP_<id>`, `PANEL_<id>`, `COMBO_<id>`, `SKILL_DESC_<id>`, `LANG_<id>`, `COMPASS_<dir>`, item, enemy, stage and skill names) must exist.
3. **Rendered pseudo-locale sweep:** every catalog string is wrapped in ⟦ ⟧ and 59 real screens are walked: HUD, item details, 5 Upgrades tabs, enemy tabs, World, Missions, Prestige, Stats, Settings, Help, Level, Farming Guide, Mastery, Offline, Filters, Teleport, camp, travel map, three confirmations, the review invitation and its failure state, a banner, a toast, the onboarding chooser, all six Basic cards, The Road Ahead, and every `GUIDE_*` card. Any visible Latin text outside the markers did not come from the catalog. The same run switches language while panels are open, so stale text shows up too.

**Player-visible gaps found and fixed (presentation only; no gameplay or save keys changed):**

| # | Gap | Fix | New/changed key |
|---|---|---|---|
| 1 | Prestige-chain progress showed an English enemy name built from its id ("Blue Cap") and glued a verb fragment to it ("Hunt" + name), which no other language can reorder | One whole goal phrase with the translated group name; no stray double space | `CHAIN_GOAL_KILL_TARGET` "Hunt %s" (new), `CHAIN_PROGRESS` "Step %d/%d · %s · %d/%d" (one `%s` fewer) |
| 2 | Prestige card headline hardcoded "+%d pts" and "−%ss" | Keys; English output unchanged | `CARD_VALUE_POINTS`, `CARD_VALUE_SECONDS` |
| 3 | Durations hardcoded "1h 02m / 4m 09s / 37s" (Stats, offline welcome) | Keys; English output unchanged | `DURATION_HOURS_MINUTES`, `DURATION_MINUTES_SECONDS`, `DURATION_SECONDS` |
| 4 | Enemy, stage, skill, card, opportunity and combo names were translated once at catalog load and never again | `catalog.relocalize()` keeps the authored keys (`name_key`, `description_key`) and re-translates on a language change | — |
| 5 | View Camp button text set once at start | Redrawn on a language change | — |
| 6 | Inventory slot labels ("Empty", badges) cached without the language | Cache cleared on a language change | — |
| 7 | Onboarding chooser and the guide's Skip / Got it set once in `setup()` | `tutorial_guide._localize()` on `NOTIFICATION_TRANSLATION_CHANGED` | — |

Change 35 strings: all 14 present, translated in all five catalogs and rendered in the sweep (review dialog for both stores, the open-failure state, Settings → Feedback, Basic card 2/6, Guided targeting cards).

**Intentional exceptions (not player-visible):** seven skill-block reason codes returned by `campaign.skill_cast_block_reason()` (`SKILL_COOLDOWN`, `HEALTH_FULL`, `NOT_IN_COMBAT`, `PLAYER_DEAD`, `SKILL_SLOT_UNAVAILABLE`, `SKILL_TARGET_OUT_OF_RANGE`, `SKILL_UNKNOWN`) and `"HERE"` (internal compass value) only disable buttons or select a key; they are never shown, so no English text was added. Compact number suffixes (K/M/B…) and the `^` merge level are the same in every language (glossary).

**Obsolete-key candidates (kept, translated, not removed):** 113 keys have no static reference in scripts, scenes or data, for example `HELP_0`–`HELP_7`, the original `CARD_*` set, `PRESTIGE_CONFIRM`, `NO_OFFLINE`, `LANGUAGE_NOTE`, `MISSION_GOAL`, `SHOW_ALL_MENUS*`, and now `LANG_DISABLED`. Removing them is a separate source-cleanup decision; it would shrink every catalog but changes nothing on screen.

`python tools/validate_localization.py` also checks the English catalog: unique keys, no empty text, and every scene-text key present.

## 2. Catalogs

`localization/{es_419,es_ES,pt_BR,fr_FR,de_DE}.po`, written from scratch against the final English. The draft files were reference only: their 706–707 "adapted" entries were re-reviewed, and item names and terms were redone for consistency with the glossary. Headers are clean: no fuzzy header, `Language`, `Plural-Forms`, source hash.

| Locale | Keys | Fuzzy | Empty | Placeholder errors | Symbol errors | Raw keys | English copies (unapproved / allowlisted) |
|---|---|---|---|---|---|---|---|
| es_419 | 1,941 | 0 | 0 | 0 | 0 | 0 | 0 / 6 |
| es_ES | 1,941 | 0 | 0 | 0 | 0 | 0 | 0 / 6 |
| pt_BR | 1,941 | 0 | 0 | 0 | 0 | 0 | 0 / 10 |
| fr_FR | 1,941 | 0 | 0 | 0 | 0 | 0 | 0 / 16 |
| de_DE | 1,941 | 0 | 0 | 0 | 0 | 0 | 0 / 26 |

Allowlisted copies are brand titles, abbreviations (Auto, MAX) and true cognates or established loanwords (fr *Missions*, *Camp*, *Prestige*; de *Upgrades*, *Boss*, *Winter I*; pt *Item*, *Elite*, *Offline*), each named per key in `tools/localization_allowlist.json`. Full numbers: `docs/Localization_Batch_01_Evidence/catalog_validation.json`.

**Linguistic review (manual, by me; not a native-speaker sign-off).**

- **Concepts kept distinct:** merge, evolve, upgrade, Supply Mastery and Map Mastery, Prestige, and claim versus collect stay separate in every language.
- **Placeholder order:** reviewed by hand for all 106 entries with repeated `%s`/`%d`. One reversal found and fixed: de `LIGHTNING_SLOW_DESCRIPTION` had swapped the percentage and the duration.
- **Meaning errors fixed during review:**
  - es "las pociones curan más de una vez" → "más de golpe" (potions heal more *at once*, not more than once).
  - de "Sein Sieg öffnet Winter II" → "Ihn zu besiegen öffnet Winter II" (the player's victory, not the boss's).
  - fr compass directions now carry their preposition ("À l’est du camp 3", not "Au est").
  - pt "Ao norte do acampamento".
  - pt boss alert punctuation.
  - "Plain" gear uses adjectives.
  - es and fr Grim Reaper outfit takes its article.
- **Regional Spanish:** es-ES differs from es-419 in 185 entries (pulsa/toca, Ajustes/Configuración, recoger/recolectar, perfect/preterite, coste/costo, Gafas/Lentes de Sol, Papá Noel/Santa, Seta/Hongo, ¡Vale!, decimal comma). Routing is tested: es → Latin America, es_ES → Spain.
- **Typography:**
  - French: narrow no-break space before `: ; ? !`, no-break space before `%`.
  - es and de: no-break space in "5 %".
  - All five: a number stays glued to its unit or word ("12 s", "5 Minuten").
- **Accepted limits:**
  - No gettext plurals exist in the source, so "(s)" forms mirror English.
  - Settings shows language names in the UI language (see glossary).
  - Automated checks cannot certify wording; a native-speaker read-through is still advisable before release.

## 3. Runtime integration

- **Gate (unchanged for players):**
  - `project.godot` still registers only `res://localization/en.po`.
  - `LocalizationService.TRANSLATIONS_RELEASE_READY = false`.
  - Automatic → `en`.
  - `select_language()` refuses anything not available.
  - A saved non-English preference loads as Automatic.
- **Test-only override:** `--test-languages=batch01`, accepted only with a probe/capture profile (`BootContext`), or `LocalizationService.enable_test_batch("batch01")` from a probe. It loads the five `.po` files through Godot's PO loader. Outside probes it returns false and registers nothing (probe-checked). `set_test_locale()` (probes only) pins a locale for the pseudo sweep.
- **Godot locale mapping:**

  | Language | Godot locale |
  |---|---|
  | `es_419` | `es` (Godot folds it; es_MX and es_AR fall back to it) |
  | `es_ES` | `es_ES` |
  | `pt_BR` | `pt_BR` |
  | `fr_FR` | `fr_FR` (fr_CA would match) |
  | `de_DE` | `de_DE` (de_AT would match) |

  Device detection is still off: Automatic is English.
- **Settings › Language** lists Automatic, English and all 19 other release languages as chips. The 19 are disabled (14 with the batch override), the current choice is highlighted, and there is no development notice (Change 16 rule kept; audit LOC-02 resolved).
- **Live switching:**
  - `game_ui` handles `NOTIFICATION_TRANSLATION_CHANGED`: catalog names re-translated, open panel rebuilt in place, retained panel dropped, HUD redrawn on the next tick, slot cache cleared, View Camp redrawn.
  - The guide redraws its fixed texts.
  - Scene-authored keys auto-translate.
- **Persistence:** the choice lives in `settings.selected_language`, separate from progression. A non-string value no longer crashes `SettingsState.from_save_dict` (pre-existing bug found by the probe).
- **Layout fixes (they help English too):**
  - Upgrades tab labels step their font down (18 → 13) to fit instead of ellipsizing ("Consommables", "Sin conexión", "Suprimentos").
  - The Map Mastery HUD chip steps down (17 → 13) instead of hiding the category count ("Meisterschaft 0 % · 0/5").
  - The upgrade card's blocking reason wraps instead of being cut.
- **Export:**
  - `tools/export_rules.json` registers the test-only load site as family `test_language_catalogs` with no values.
  - The regenerated manifest is still 239 release files, with the test catalogs absent.
  - `export_presets.cfg` is unchanged.
  - Test exports with the catalogs included were not built; that check belongs to the global gate, when they are registered in `project.godot` (see Limitations).

## 4. Validation

| Check | Result |
|---|---|
| `python tools/validate_localization.py` (structure, placeholders in order, symbols, copy-through, raw keys, English stopwords, headers, `project.godot` gate, scene keys) | 0 problems, 5 catalogs × 1,941 keys |
| `localization_batch01_probe` (new, in suite): gate, refusal outside probes, routing incl. es-419 ≠ es-ES, Godot loader returns the catalog text for all 1,941 keys × 5, theme-font glyph coverage, live switch from the real Settings button and with Upgrades/Prestige/Missions/World/Mastery/item open, retained panel, back to English, save → reload, old/foreign settings, restart without the override | 77/77 |
| `localization_sweep` (new, in suite): pseudo + English + 5 languages × 432x960 / 540x960 / 768x1024 headless; raw keys, English leaks, non-catalog text, clipped single-line text, horizontal overflow, small buttons, scrollbar presence | 0 findings (1,231 screen checks) |
| Same sweep windowed with screenshots, each shape | 0 findings (336 / 356 / 364 screen checks) |
| Glyphs (DejaVu Sans) | all 95–104 distinct characters per catalog present |
| Full maintained suite (`python tools/run_probes.py`) | **41/41 pass** (validator, export_manifest and 39 Godot scenes), no script errors, no timeouts |

Updated existing contracts: `change_35_probe` checks what players can select and what `project.godot` registers, instead of counting files in `localization/` (the developer's drafts may sit there). `ui_probe` checks the 19 languages are listed disabled and refused. `change_16_probe` has the same "no development notice" assertion with an updated message.

## 5. Visual evidence

`docs/Localization_Batch_01_Evidence/`:

- `contact_sheets/contact_<shape>_<group>.jpg`: 15 sheets, English plus the 5 languages side by side, at 432x960 (20:9), 540x960 (16:9) and 768x1024 (4:3). Each covers 26 screens: HUD, item details, Upgrades tabs, enemy tabs, World, Missions, Prestige, Mastery, Farming Guide, Stats, Level, Teleport, Settings top and language list, Help, drop and reset confirmations, review invitation and its failure state, onboarding chooser, Basic targeting card, The Road Ahead, stage banner.
- `screens/`: 13 full-size captures at the narrowest shape (German HUD, item, Upgrades, drop confirmation, targeting card; French review, Prestige, enemy panel; both Spanish language lists; Portuguese Road Ahead and Missions; Latin-American review failure).
- `catalog_validation.json`.

I reviewed the captures myself (desktop windows, not a phone). Observed and **not** changed, because English behaves the same: the "Next Stage" chip under the minimap can overlap the floating View Camp button when the camp sits right below the minimap.

## 6. Limitations and device TODO

- **No Android device was used.** Still to do on a real phone: German and French Settings → language switch, HUD, Upgrades tabs, item details, review invitation, guide cards, persistence across app restart. This must be a test build with `--test-languages=batch01`, or the global gate.
- **Test exports with the five catalogs** (APK/AAB/Windows) were not built: production exports must not carry them yet. When the gate opens, register all catalogs in `project.godot`, regenerate the manifest and run `tools/verify_export.py`.
- **Linguistic quality** was reviewed by me, not by native speakers.
- **Headless layout:** after a resize or a large inventory change, the HUD relayouts over about 200 frames from Godot's 64×64 headless start (pre-existing `_layout_inventory` convergence). The sweep waits for 0.6 s of stable layout.

## 7. Handoff for Batch 02 (it_IT, nl_NL, pl_PL, ru_RU, uk_UA)

1. Translate against `en.po` `4440b694…` (1,941 keys). The drafts in `localization/` are reference only.
2. Add `"batch02": [...]` to `LocalizationService.TEST_BATCHES` and `GODOT_LOCALES`. The validator, probe constants and sweep `--langs` then pick them up; extend `BATCH` in `localization_batch01_probe.gd` or add a batch-02 probe.
3. Cyrillic (ru, uk): DejaVu Sans covers it; the glyph check will confirm.
4. Keep the glossary columns and allowlist per locale. Hand-review placeholder order for repeated `%s`.
5. Do not register any catalog in `project.godot` before the global gate.
