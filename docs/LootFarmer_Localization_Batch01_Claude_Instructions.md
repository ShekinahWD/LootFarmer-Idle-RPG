# LootFarmer — Progression Update Localization, Batch 01 of 04

**Mode:** Implement, validate and commit **only the first five locales** in the approved Changes 50–55 localization handoff. Do **not** retranslate, rewrite or linguistically review the previously approved translations.

## Source artifacts

1. `LootFarmer_Progression_Localization_19_Languages.zip` (ChatGPT translation package; provided with this instruction). Inside are the complete `.po` catalogs and `README_FOR_CLAUDE.txt`, `change_scope.json`, `translation_validation.json`.
2. `docs/changeDocs/localization/Progression_Update_Translation_Handoff.json` (Claude's frozen English strings and placeholders).
3. The **current working tree's** `localization/en.po` and 5 existing target `.po` files: authoritative baseline. Read `docs/Reusable_Game_Development_Playbook.md`, particularly §132.4–132.6, plus the project's existing localization validators and per-locale readiness list.

**English SHA-256 expected:** `8212766e4a508781d1567b34f3ac1864f510890e09ff7a0898707dc736fab02f`. Confirm that the current English file matches; if not, stop and report the difference before applying the package. Preserve all unrelated working-tree modifications.

## Exact scope: batch01 only

| Locale | File in translation ZIP | Current approved entries to preserve | New/changed entries to integrate |
|---|---|---:|---:|
| Latin American Spanish | `localization/es_419.po` | 1,923 | 104 |
| European Spanish | `localization/es_ES.po` | 1,923 | 104 |
| Brazilian Portuguese | `localization/pt_BR.po` | 1,923 | 104 |
| French (France) | `localization/fr_FR.po` | 1,923 | 104 |
| German (Germany) | `localization/de_DE.po` | 1,923 | 104 |

**Total:** 520 new/changed localized values (100 new + 4 changed-meaning keys per locale). Each final catalog must contain **2,027 non-header keys**, matching English. The **25 retired keys** listed in the package must remain absent. Do not touch locales from batches 02–04.

## Mandatory change isolation

1. Back up or take a Git baseline of each of the five currently approved `.po` files *before* copying anything. Keep the translation ZIP **outside** `localization/` and the game's import paths.
2. Use the **104 IDs in `change_scope.json`** as the only content-change allowlist. The ZIP contains complete catalogs for convenience; it is **not** permission to rewrite the old 1,923 entries.
3. Diff the original versus candidate catalog at the **key/value** level. Verify **all 1,923 previously approved translations remain byte-for-byte unchanged as values**; preserve headers and surrounding formatting as much as practicable. If any unrelated value differs, restore it from the baseline rather than re-reviewing the old translation.
4. For each of the 104 scoped IDs, verify faithful, natural, gameplay-aware wording against the frozen English meaning, existing in-game terminology and applicable regional usage. Preserve exact number/type/order of GDScript `%s`/`%d` tokens, symbols such as `^` and `→`, markup, punctuation required by the interface and costs/consequences.
5. Check that `es_419` and `es_ES` remain genuinely distinct regional variants. **Do not rewrite any existing translation or alter locale mapping unrelated to this batch.**
6. Verify the 25 retired IDs have not reappeared. Do not add synthetic or fallback English translations to satisfy counts.

## Validation and acceptance gates

- Catalog parsing/format; exact 2,027-key parity with the current English catalog; duplicate/fuzzy/empty-value detection; placeholders, escapes, markup and plural structures. Run the project's established validators; report the actual commands and results.
- Automated equality check for **each of the 1,923 previously approved entries per locale**, with **zero unrelated modifications**. Report a per-locale count of unchanged and changed keys. If translating or fixing one of the 104 keys, record the specific correction and reason.
- Localized content QA focused on the **104 new/changed entries only**: Prestige retain/reset text, evolution and 31-copy rules, weapon bonuses/rerolls, new Prestige objectives/cards, Map Detail and offline-reward hints. Existing copy receives structural-integrity testing only, not a new linguistic review.
- Godot locale routing, live-language switch with relevant panels open, persistence, font/glyph coverage, line wrapping, scrolling/clipping and redraw. Inspect representative UI at **432×960 and 540×960**, including Prestige selection (up to 8 cards), item reroll controls, Prestige confirmation, World/Map hints and Offline upgrades. Use real captures/probes where available; explicitly distinguish automated, visual and device validation.
- Follow the Playbook's per-locale readiness and packaging gates. **Do not automatically enable previously disabled locales** or change release/export allowlists without all required checks and developer approval. Do not inadvertently disable already-enabled ones. Android validation remains pending unless actually performed.
- No gameplay/economy/Prestige changes, no save schema or GDD modifications, no store push/release. Only make necessary localization-related fixes within the five-locale batch.

## Workflow and deliverable

1. Verify handoff/hash/baselines; integrate **batch01**.
2. Execute targeted validation, correct problems **within the 104-key scope**, and revalidate. Stop and report blockers if any gating check cannot pass.
3. Write a compact batch01 handoff report in the project documentation area designated by the Playbook: locale list, English hash, counts, integrity diff results, scripts/tests and captures used, corrections, unresolved issues (especially Android), and next-batch readiness.
4. **Commit this completed batch** (including any required `.uid`/registration adjustments and its report) using the established Change N convention, after automated validation; do not wait for manual Android acceptance to commit. Preserve unrelated uncommitted edits. Do **not** push or publish.
5. Return the commit hash, files modified, per-locale counts, test results, remaining QA, and a clear **STOP: batch02 not started** statement.

**Critical boundary:** This is **integration and focused QA of five translations**, not a general localization overhaul. The 1,923 old approved entries per locale are protected; review and potentially correct only the 104 approved new/changed IDs.
