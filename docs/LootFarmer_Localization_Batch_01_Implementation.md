# LootFarmer — Runtime Localization, Batch 01 of 04

**Scope:** Five runtime languages only: **Spanish (Latin America), Spanish (Spain), Portuguese (Brazil), French, German**.  
**Godot:** project's pinned version (previous source ZIP reported Godot 4.7).  
**Workflow:** Reusable Game Development Playbook §132.1–132.6 and the project's current localization/tests/UI guidance.  
**Execution:** Claude Code in the developer's **current local Git repository**, not an older ZIP snapshot.  
**Authorization:** Implement, validate, document, and commit; **do not push or publish**.

## 0. Critical handoff status: partial drafts, not translations ready to ship

There is a prior archive named `LootFarmer_Runtime_19_Languages_Partial_Drafts.zip`. It is **not** a complete translation package. For the first five locales, its 1,921-key historical baseline contains roughly **1,214–1,215 English fallback/fuzzy entries per language**. The draft report calls these *unfinished* and says to keep all languages disabled. Any existing `msgstr` that repeats English or any nonempty `msgstr` must **not** be considered proof of translation.

Historical English source: `en(1).po`, SHA-256 `b334a6deaf542da8120ad0c7066618e92b5450514f85c44695d369fea3015172`, **1,921 message IDs**. That is an identification aid, **not a frozen key-count target**. The project advanced through **Change 35** (`090e279`), which introduced a cross-platform review prompt, Basic/Guided enemy-targeting lessons and 14 new English strings reportedly in `tools/change35_strings.json`. Later changes may also have updated English text. **The current repository's canonical English catalog and runtime source of truth win over every archived draft.** Do not overwrite a current catalog with an old one.

If the partial drafts are not in the local repository, the developer can attach/copy the partial-draft ZIP as a translation reference. It has project-relative paths (e.g. `localization/es_419.po`) and an `untranslated_ids.csv`. Do not assume these drafts have already been imported. Do not enable them just to inspect them. The Google Play ASO/20-locale listing files are **separate marketing copy**, not runtime translation sources.

## 1. Source freeze, key audit, and gap recovery — perform FIRST

1. Read the canonical `docs/Reusable_Game_Development_Playbook.md`, especially §132.1–132.6, and the current GDD, localization service, settings, UI scenes, content resources, project configuration, and localized-string validators.
2. Inspect the live Git worktree and history. Preserve all untracked developer work, including the untracked extracted ASO package. Do not alter unrelated files, screenshots, trailer, gameplay, balancing, store listings, or the approved review/targeting behavior.
3. Establish the actual current `localization/en.po` path, encoding, locale headers, message IDs, msgctxt/plural conventions, formatting placeholders, current key count and SHA-256. Record what changed since the historical 1,921-key draft. Inspect `tools/change35_strings.json` and any newer feature catalogs/English strings. **Consolidate any omitted player-visible text into the canonical English source** before translating; do not blindly append or duplicate keys.
4. **Audit missing translations from the game itself**: search scripts, scenes, reusable UI components, resources/content tables, prompts, help/tutorial cards, targeting guidance, review panel (including Google Play/itch.io labels and failure messages), prestige, equipment, supplies, skills, inventory, settings, offline rewards, map, quests, combat/status notifications, accessibility copy (if present), error/confirmation messages and number/plural/date or currency-related formatting. Look for (a) hardcoded player-visible English that is not meant to be a brand/proper noun, (b) references to absent English IDs, (c) obsolete IDs, (d) strings built by concatenating pieces that need grammar-aware whole messages, and (e) missing placeholder/plural intent. Scan scene text, dynamic code paths and resource-driven UI, not just `tr()` calls.
5. For genuine gaps, add **stable semantic English IDs** with natural source wording; update the affected **presentation paths only** to reference them and to redraw correctly when locale changes. Keep gameplay data/save keys stable. Do not refactor unrelated gameplay. Record intentionally untranslated brand names (`LootFarmer`, etc.) and other justified exceptions in a glossary. Obtain the actual completed/current English key count; do not hardcode 1,921 or 1,935.
6. Run the English source-key and placeholder validators and representative English UI checks. Record the final source hash and any intentional exceptions before translating this batch. If a critical source-text problem cannot be resolved, stop and report it rather than generating catalogs against an unstable catalog.

## 2. First-batch locale manifest

| User-facing locale | Godot/project catalog filename | Target |
|---|---|---|
| Spanish — Latin America | `localization/es_419.po` | Idiomatic broad Latin-American game Spanish |
| Spanish — Spain | `localization/es_ES.po` | Natural Spain gaming Spanish, deliberately different where appropriate |
| Portuguese — Brazil | `localization/pt_BR.po` | Brazilian game vocabulary, **not** European Portuguese |
| French | `localization/fr_FR.po` | Natural and consistent French gaming terminology |
| German | `localization/de_DE.po` | Concise, idiomatic German UI and proper grammatical inflection |

**Important Godot nuance:** Godot may normalize `es_419` to generic `es`; preserve the explicit **Latin America vs Spain** distinction through a tested locale mapping, without creating a collision. Keep store-facing tags separate from Godot runtime IDs (§132.6). Do not enable device-locale Automatic at this stage.

## 3. Translation creation and linguistic quality

- Work **only on these five locales** this batch. Use any earlier `.po` files merely as *partial reference drafts*. Audit even the previously adapted 706–707 entries, especially 574 item-name combinations, names, genders/cases, enemy gear and menu wording. Do not simply strip `fuzzy` flags or copy source strings.
- Finish **every** current English ID in every selected locale. Translate remaining English fallback/fuzzy entries using natural, locally appropriate wording. Respect gameplay context over literal word-for-word translation. Preserve all source meaning and mechanics; do not invent benefits, requirements or numbers.
- Prioritize correct genre-specific concepts: **idle combat/farming**, **loot/drop**, **outfits**, **weapons**, **gear/equipment**, **merge**, **evolution**, **mastery**, **Prestige**, **supplies/consumables**, **quests/missions**, **camps/travel**, **targeting by dragging from the hero**, **reviews/honest feedback**, etc. Distinguish equipment item evolution from supply mastery, and avoid translations that change an actionable instruction.
- Keep a consistent glossary per locale, including the Spanish regional distinctions, item naming patterns, terminology, capitalization and approved proper nouns. Use genuine regional variants, not one Spanish catalog copied under two filenames.
- Preserve identifiers, placeholders (`%s`, `%d`, `%.1f`, `%%`, `{name}` etc.), escaped percent symbols, plurals, newlines/markup, punctuation semantics, order and any required formatting controls. Reorder placeholders only in a syntax-safe way supported by the actual formatter. Respect Godot PO header/locale conventions; valid Unicode and accents.
- Make text compact **without erasing meaning**. No false shortening such as removing warnings, costs, consequences, or eligibility. Prefer flexible layouts and wrapping to truncating essential information. Do not translate game/store brand names that were intentionally preserved.
- Plan internally by semantic groups (HUD, menus, tutorials, gear/catalog, prestige, combat, etc.) to control review complexity, but deliver **all five complete catalogs as one validated first batch**. If reliable complete idiomatic translation is not feasible, explicitly report which catalogs/entries are unfinished and **do not declare Batch 01 passed**. No partially translated locale may be enabled for players.
- Do not use the Google Play ASO translations as direct substitutes for gameplay strings; the language intent, character limits, and context differ.

## 4. Integrate safely, but retain the global release gate

1. Import/register these five complete `.po` files in Godot, preserving the canonical English catalog. Verify the locale identifiers actually resolve to the intended catalog (particularly both Spanish variants). Do not overwrite approved English or alter any saved progression/state.
2. The Settings menu must continue to display English plus all 19 other release languages, **with all 19 non-English options disabled for normal production players until the entire 20-language rollout passes** (§132.5). Add an **explicit test-only locale override** to exercise this batch and live switching without weakening the production readiness gate. Automatic stays English-only. This applies to editor, APK/AAB, Windows builds and first-run/restored profiles.
3. Test locale switching while panels are open, updated labels with `NOTIFICATION_TRANSLATION_CHANGED` where needed, preferences across restart, English fallback for unsupported devices, content-defined labels and grammar-sensitive numeric placeholders. Catch the case where scene `text` is a key and `.text` reads back the raw key (§145.4).
4. Inspect actual glyph coverage and UI fitting at the game's portrait reference size and representative small/large devices/windows. Check HUD, inventory filter and item popup, upgrades, skills, help cards, Guided targeting demo, mission/prestige panels, Settings, 60-minute review prompt and its error path, scroll panels, map/camp messages, confirmation and save states. Cover long German and French strings, both Spanish variants and Portuguese accents. Scrollbars must remain discoverable; buttons and touch targets remain usable. Never hide meaningful information to make a screenshot pass.
5. Use screenshots/contact sheets at realistic dimensions and visually review at least representative **smallest / reference / larger** viewport sizes, with actual locale text and correct window sizing (not a headless 64×64 default). Distinguish automated bounds from a human visual inspection; report physical-device checks as pending if no Android device was used.
6. Validate the five catalogs' inclusion/encoding in **test exports** where feasible, while preserving the **production disabled gate** and not falsely claiming they are release ready. Do not trigger translations for the other 14 languages.

## 5. Required structural validation

For **each** of the five catalogs, programmatically check and record:

- Exact semantic-ID set and uniqueness compared with the current canonical English source, including recently added review and targeting strings.
- `msgstr` nonempty for every translatable message; no remaining `fuzzy` flags; no accidental raw semantic IDs; zero unapproved English fallback/copy-through entries. Note intentional nontranslated names in a glossary with a targeted allowlist, not a sweeping exemption.
- Correct matching plural forms, placeholder tokens/types/counts, escaped sequences, punctuation where material, markup, dynamic substitutions and newlines.
- Valid `.po` syntax/import and expected actual Godot locale routing; test both Spanish variants independently.
- String coverage of real player-visible UI beyond catalog key parity, including new keys found by the source audit.
- Correct font/glyph rendering, layout and live refresh from actual rendered scenes.
- Backward-compatible settings/old save loads and no unintended new-language rollout in production.

**Do not treat 'all `msgstr` populated' or 'PO parse successful' as evidence of actual translation quality.** Run objective English-copy-through/fuzzy detection plus semantic linguistic review; record limitations of automated linguistic QA.

## 6. Test and commit discipline

- Follow the Playbook's verification layering: focused source/key checks, PO consistency checks, Godot import/switch tests, layout/glyph probes and screenshot review, relevant export smoke checks, then the maintained **full regression suite once the batch is stable**. Fix any regressions within this batch. Use the real current suite count, not a historical assumed value.
- Do not run a gameplay rebalance, generate store assets, or implement the next localization batch. Do not modify the approved core mechanics or storefront links. Do not silently change the review prompt timing or tutorial success rules.
- Create `docs/LootFarmer_Localization_Batch_01_Report.md` (or the project's established report location) containing: source SHA/count and uncovered-string audit, glossary/intent decisions, per-language counts/completion, exact additions/corrections, validations and actual rendering/screenshots, export checks, limitations/device TODO, and handoff for Batch 02. Update only necessary game-specific localization/test documentation. **Do not rewrite the reusable Playbook** unless a genuinely new procedure has been validated; if so, keep it short and game-independent and report it explicitly.
- Commit tracked source/catalogs/tests/docs with the **next chronological Change number from the current Git history** once the batch truly passes. **Do not push.** Leave unrelated untracked/ignored content (particularly the ASO extracted folder) alone. If blocking translation completeness or correctness prevents approval, report an honest partial result and the outstanding work; do not commit it under a 'completed localization' claim.

## 7. Completion report — required answer format

Provide a short summary with:

1. **Batch 01 status:** PASS / BLOCKED; commit hash, no push.
2. **English source audit:** original/current/final source count and SHA; player-visible hardcoded gaps added; Change 35 new strings accounted for.
3. **Five catalog results:** `es_419`, `es_ES`, `pt_BR`, `fr_FR`, `de_DE`: keys, fuzzy, missing, placeholder errors, unapproved English entries, and meaningful linguistic issues/fixes.
4. **Runtime behavior:** actual Godot locale mapping, production gate still disabled, test-only switching and saved settings.
5. **Visual/QA evidence:** paths to screenshots/contact sheets, key panels tested, glyph/overflow and Android/export checks honestly labeled.
6. **Tests:** targeted counts and real final maintained-suite outcome.
7. **Handoff:** paths to updated `.po`, glossary and batch report; **next batch only** `it_IT`, `nl_NL`, `pl_PL`, `ru_RU`, `uk_UA`.

**Acceptance definition:** All five fully translated and linguistically reviewed catalogs, exact current-English key/placeholder parity, demonstrated rendering/live switching, production language gate still closed, and no test regressions. Anything less is a blocked or partial batch, not completion.
