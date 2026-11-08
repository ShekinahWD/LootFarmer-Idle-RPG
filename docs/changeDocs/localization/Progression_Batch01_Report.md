# LootFarmer — Progression update localization, Batch 01 of 04 (Change 58)

**Date:** 7 November 2026 · **Locales:** es_419, es_ES, pt_BR, fr_FR, de_DE · **Scope:** the 104 keys of Changes 50–55 (100 new, 4 changed meaning) · **Status:** integrated and validated automatically; Android device check and native-speaker review pending. **Batch 02 not started.**

## Inputs

| Item | Value |
|---|---|
| English catalog | `localization/en.po`, 2,027 keys, SHA-256 `8212766e4a508781d1567b34f3ac1864f510890e09ff7a0898707dc736fab02f` (matches the package) |
| Package | `LootFarmer_Progression_Localization_19_Languages.zip` (developer-supplied; read in place by the tool, never extracted into the project; per-file hashes match `translation_validation.json`) |
| Scope | `change_scope.json` 104 IDs = `tools/localization_pending.json` 104 keys; 25 retired IDs absent from every catalog |
| Baseline | the five catalogs at `1cac252` (1,923 approved entries each) |

## Integration

`tools/integrate_translation_batch.py` (new, reusable for Batches 02–04) takes only the scoped entries from the package and inserts them into the current catalogs at their English position (the validator requires English order; the package appended them at the end). It proves the old file is reproduced exactly when the scoped entries are removed, then records the five locales in each key's `translated` list.

```
python tools/integrate_translation_batch.py docs/LootFarmer_Progression_Localization_19_Languages.zip --batch=batch01 \
  --corrections=docs/changeDocs/localization/Progression_Batch01_Corrections.json --write
python tools/integrate_translation_batch.py <same> --check --baseline-rev=HEAD      # before the commit
```

| Locale | Approved entries unchanged | Changed / removed | Added (scope) | Corrected vs package | Total keys |
|---|---:|---:|---:|---:|---:|
| es_419 | 1,923 / 1,923 | 0 / 0 | 104 | 55 | 2,027 |
| es_ES | 1,923 / 1,923 | 0 / 0 | 104 | 57 | 2,027 |
| pt_BR | 1,923 / 1,923 | 0 / 0 | 104 | 44 | 2,027 |
| fr_FR | 1,923 / 1,923 | 0 / 0 | 104 | 71 | 2,027 |
| de_DE | 1,923 / 1,923 | 0 / 0 | 104 | 66 | 2,027 |

`git diff` of each catalog contains only added lines (104 × 3). The headers are unchanged; the old `X-LootFarmer-Source` metadata was left as it was. Evidence: `Progression_Batch01_Evidence/integration_check_vs_1cac252.txt`.

## Corrections to the 104 (all recorded with reasons in `Progression_Batch01_Corrections.json`)

1. **Misplaced translations (blocking, all five locales).** The ten Expedition/Collection O4–O8 descriptions had been translated in interleaved order and filed in key order. As a result, eight of them per locale described a different opportunity: *Beach route* showed the Holiday collection text, *Holiday collection* showed the Beach route, and so on. Only Expedition O4 and Collection O8 were correct. Each translation was moved to its own key (40 values). The tool now refuses any scoped value whose numbers differ from the English ones unless the corrections file names a reasoned exception (one: es "por duplicado" = 2 copies). This gate catches 7 of the 8 shifts per locale. Collection O6/O7 share the same numbers (31/30), so that pair was caught by review only.
2. **Terminology drift from the approved catalogs** (the 1,923 approved entries decide, not the package): de *Kostüm/Lager/Gelegenheit/Kopie/Upgrades/weiterentwickeln/Spielerstufe*; fr *rang*, *copies en trop*, *Maîtrise des cartes*, *récupérer*; es *EXP/PV/reclamar/enfriamiento/Mejoras del mapa/jugador*; pt *PV/Detalhe do mapa/Melhorias do mapa/inimigos comuns*. Also the fr infinitive for objectives, rules and follow lines, boss articles, and the approved Collection O1 sentence for O4–O8. `MAIN_HINT_9` had added a `→` that the English does not have.
3. **Regional:** es_ES uses the present perfect (*has comprado*, *ha alcanzado*, *se han añadido*), *pulsa*, *Papá Noel*, *Seta* and *por partida*; es_419 the preterite, *toca*, *Santa*, *Hongo*, *recolecta* and *volver a sortear* (es_ES *volver a tirar*). 32 of the 104 values differ between the two; 218 of 2,027 across the whole catalog.
4. **Typography of the approved catalogs:** a no-break space after numbers and numeric placeholders and before `%` (pt: none before `%`); decimal comma except in es_419 (the package wrote `0.5 s` everywhere); fr U+202F before `: ; ? !` and `’`.
5. fr `MAP_DETAIL_NEXT_2` "pour **les** examiner" became "pour **l’**examiner" (one marker).

The glossary has a new section for these decisions (`docs/LootFarmer_Localization_Glossary.md`, "Progression update, Batch 01").

## Layout fixes found by the new probe (Change 58 code, every language benefits)

| Screen | Problem (432×960) | Fix |
|---|---|---|
| Item panel at the merge cap | A blocked Evolve button carried its reason (`EVOLUTION_NEEDS_COPIES`) unwrapped inside the action flow, so the sheet grew past the screen in es/pt/fr/de (Close cut off) | A blocked Evolve becomes a full-width wrapping row (`game_ui.gd`) |
| Prestige panel, collection in progress | German "Geforderte Gegenstände oder Währung abgeben" (Submit) widened the sheet | Submit wraps and fills the row beside Follow |
| Eight-card choice | Long card descriptions (de Crowd Guard, Second Wind) ran past the card's bottom edge | The card grows to its content and never shrinks below its designed size (`prestige_card.gd`) |
| Eight-card choice | "Tippe auf eine Karte, um si…" (also fr, pt) | The Keep/Pick button wraps to two lines inside the bar's height |
| Boss-enhanced weapon stats | es: the stat name was squeezed to one word per line and split inside a word ("Bonificació\|n") | The ▲ delta label shares the row and wraps (right-aligned) |

## Validation

| Check | Kind | Result |
|---|---|---|
| `python tools/validate_localization.py` | automated | PASS, 0 problems; the five catalogs have 2,027 keys, 0 fuzzy, 0 empty, 0 placeholder and 0 symbol errors, 0 pending missing. Batches 02–04 still have 104 pending keys each (English fallback, as before) |
| Validator negative test | automated | Removing a delivered key from de_DE is now reported ("delivered translation missing") |
| `integrate_translation_batch.py --check --baseline-rev=HEAD` | automated | 0 problems (table above) |
| `localization_batch01_probe` | automated (Godot) | PASS. It now runs all 2,027 keys × 5 through Godot's PO loader (it used to exclude the pending keys), checks glyphs, routing and Automatic, live switching, persistence, and that the progression keys stay regional (*sortear/tirar*) |
| `localization_progression_probe` (new) | automated (Godot), headless | PASS: 492 checks at 432×960 and 540×960 in en + 5 languages, covering 14 screens (World Map Detail hint, welcome-back offline hint and jump, Upgrades > Offline, boss-enhanced weapon with three Reroll slots, reroll confirmation, boss bonus hint, evolution rule, legacy copy, evolution-ready toast, Prestige with 48 opportunities, Prestige confirmation, eight-card choice). It confirms each listed progression key is actually on screen in the current language, and switches language live with the card choice and the item panel open. 0 findings |
| Same probe, windowed | rendered | PASS at `--resolution 432x960` and `540x960`; contact sheets in `Progression_Batch01_Evidence/contact_sheets/`, reports `probe_windowed_*.json` |
| Visual inspection | visual (desktop) | Read by Claude from the captures: all five layout fixes, the French confirmation, the Spanish boss stats, the Portuguese reroll confirmation, the German World hint |
| Full suite `python tools/run_probes.py` | automated | **56/56 PASS** in the working tree (validators, export manifest, all localization probes incl. `localization_sweep` 20 languages × 3 shapes, and the new probe), no script errors or timeouts; `Progression_Batch01_Evidence/suite_results.txt` |
| Android device | device | **Not performed** |

**Known findings that are not part of this batch** (counted as `known` by the probe, also present in English): the Prestige panel's card chips are designed as single-row ellipsis labels (Change 54), so card names are cut at both phone shapes in every language. The History feed's "+N" pickup buttons are 40 units tall (below the 44 tap guideline). Both are worth a separate UI decision.

## Packaging and activation

All 20 languages were already enabled (Changes 40–43). This batch changes no readiness list, export allowlist, locale mapping, font or `project.godot` registration. The catalogs keep their paths, so `export_manifest` stays unchanged (`language_catalogs:19`). No export package was built (`verify_export.py` was not run). The 20-language certification flag stays false.

## Remaining before release

- **Android device check** (Playbook 132.6): German (longest Latin) on a phone. Look at the Prestige card choice and confirmation, the boss-enhanced item with rerolls, and the World and offline hints, with live language switching and persistence.
- **Native-speaker review** of the 104 values: this batch is structurally validated and terminology-aligned by Claude, which is not the same as a native review.
- Batches 02–04 (14 locales) keep the English fallback for the 104 keys. The same interleaving very likely affects their package files; the integration tool's number gate will flag it.

## Next batch readiness

Batch 02 (it_IT, nl_NL, pl_PL, ru_RU, uk_UA) can follow the same path. It needs `--batch=batch02`, a reviewed corrections file, `localization_batch02_probe` switched to `translated_english(BATCH)`, and `--langs=en,it_IT,...` for the progression probe (Slavic count-neutral rule and Cyrillic glyphs apply). **Not started; awaiting authorization.**
