# LootFarmer — Runtime Localization, Batch 02 of 04

**Authorized task:** Implement, validate, document and commit the second localization batch in the developer's **current local Git repository**. Do not push or publish.

**Five target languages only:** Italian (`it_IT`), Dutch (`nl_NL`), Polish (`pl_PL`), Russian (`ru_RU`), Ukrainian (`uk_UA`).

**Baseline:** Change 38, commit `fb92399`, completed Batch 01. Its authoritative handoff is `docs/LootFarmer_Localization_Batch_01_Report.md` and the current `docs/LootFarmer_Localization_Glossary.md`. The English catalog was reported as **1,941 keys** after the Batch 01 source audit; **verify the current count and hash rather than assuming them**. The current repository always outranks historical ZIPs or older drafts.

**Reusable methodology:** Read `docs/Reusable_Game_Development_Playbook.md`, particularly §§132.1–132.6 (English source, locale mapping, batch gates, live switching and export validation), plus localization/UI/testing guidance (§§60.1, 121.8–121.9, 134.3, 145.4 where relevant). Apply the validated source audit, semantic review, layout inspection and regression methods from Change 38. Do not treat a language as ready merely because its `.po` file parses.

## A. Establish the live baseline before writing translations

1. Inspect Git status, latest commit history, project Godot version, canonical `localization/en.po`, translation service, catalog validator, source-string scanner, locale manifest, test switch, Settings availability gate, font configuration, `docs/LootFarmer_Localization_Batch_01_Report.md`, glossary and test coverage. Preserve unrelated changes, especially untracked extracted ASO files and the other draft locales.
2. Confirm the **five completed Batch 01 catalogs** (`es_419.po`, `es_ES.po`, `pt_BR.po`, `fr_FR.po`, `de_DE.po`) remain unchanged, complete, and test-selectable only. All 19 non-English languages remain disabled in normal builds and Automatic still resolves to English.
3. Verify the current English source count, SHA-256, formatting contract and semantic IDs. The last report stated **1,941** keys, with all Change 35 review/targeting strings and Change 36 supply strings included. Do not replace the source with an older 1,921- or 1,935-key snapshot, and do not overwrite the completed Batch 01 catalogs with the prior partial drafts.
4. **Audit player-visible English strings again** before translating: code, scenes, resource-driven content, dynamically synthesized labels, full-sentence grammar, plural/numeric formatting, saves/settings, review invitation, tutorial/help, prestige, missions, gear and supplies. Check the 113 reportedly unused English keys without deleting them just for being unreferenced. If a genuine source omission is discovered, fix the English source and necessary presentation path, update affected completed Batch 01 translations for any changed/new IDs, and revalidate their parity. Document the exceptions and why they are necessary. Avoid unrelated gameplay changes.
5. Review previous batch's semantic corrections, including whole-sentence Prestige chain progress, localized card value and time duration strings, and live UI redraw after language changes. Do not regress them.

## B. Produce five complete, natural catalogs

| Display language | Runtime PO path | Linguistic focus |
|---|---|---|
| Italian | `localization/it_IT.po` | Natural Italian RPG/UI language; concise imperatives and proper gender/number agreement. |
| Dutch | `localization/nl_NL.po` | Natural Netherlands Dutch; consistent compounds and familiar gaming vocabulary. |
| Polish | `localization/pl_PL.po` | Appropriate cases, plural forms, numbers, and inflections in UI and gameplay sentences. |
| Russian | `localization/ru_RU.po` | Natural Cyrillic UI copy, case agreement, plural/count forms, and readable labels. |
| Ukrainian | `localization/uk_UA.po` | **Independent** Ukrainian wording, spelling and grammar, not Russian text with superficial substitutions. Correct Cyrillic glyphs and plural/count forms. |

- Use current English **meaning and gameplay context** as the source, not literal word-for-word substitution. Existing draft `.po` files can be consulted but are **untrusted incomplete starting points**: review every populated entry, then complete every remaining one. Store-listing ASO translations are a different workstream and must not be copied in as gameplay copy.
- Translate gameplay concepts precisely: loot/drop versus collect, gear versus outfits and weapons, merging duplicates versus evolving items, supply mastery through **three successful uses per level**, idle/auto-combat, camping/teleportation, boss summons, 13-key gate, mission/prestige objectives, targeting by dragging from hero to enemy, and the honest review invitation with storefront-specific labels. Translate **player-facing text**, not internal IDs or data/save keys.
- Preserve all current English message IDs, context, structured metadata, valid PO syntax, `msgid_plural` / `msgstr[n]` forms, formatting placeholders (types/count/order, including escaped percent signs), markup and intentional newlines. Follow **each locale's actual plural and grammar rules**, and examine sentences with multiple formatted values individually; automate checking for invalid substitutions and manually verify semantic order.
- Preserve approved proper names (such as LootFarmer) and abbreviations where appropriate; list **each English-identical `msgstr` and its reason**. An identical string is not automatically a failure, but an unexplained English fallback is. Do not accept fuzzy, empty, raw semantic IDs or inappropriate English text as “finished.”
- Maintain the multilingual glossary and note meaningful terminology decisions, especially case/plural handling, action verbs, equipment terms, and differences between Russian and Ukrainian. Translate naturally rather than producing mechanically identical language pairs.
- Do not falsify claims of native-speaker review. State that this is agent-performed linguistic review unless actual native review occurs.

## C. Integrate and test without enabling a release

1. Use the existing Batch 01 test-only localization override and production gating. Extend `--test-languages=...` or its current implemented equivalent to access **Batch 02's five locales for tests only**, alongside previously approved Batch 01 options when appropriate. Avoid a parallel localization system. Do not expose non-English choices to players in production, change the English-only Automatic fallback, or mark all 19 locales ready.
2. Verify Godot recognizes `it_IT`, `nl_NL`, `pl_PL`, `ru_RU`, `uk_UA` and routes each to the correct PO. Check that production export packaging excludes all disabled draft and test-only catalogs according to the current project's established gate. Never use the OS as a substitute for explicit storefront tags in the existing unrelated review system.
3. Check fonts and fallback/subset support **especially Cyrillic**: Russian and Ukrainian letters, punctuation, diacritics, Ukrainian-specific `і`, `ї`, `є`, `ґ`, and any relevant symbols. Inspect real rendered text, not just string-byte validity. Resolve missing glyphs with appropriately licensed fonts/assets already supported by project policy; record any new asset license provenance if a new font is genuinely required.
4. Exercise live switching with important panels **already open**; verify captions, enemy/item/map/skill/card labels, tutorial chooser, Help, review prompt, values, currency/numbers, time durations, plurals and dynamic responses redraw. Test persistence through save/reload and old-save compatibility.
5. Perform representative layout checks at the three established portrait viewport shapes from Batch 01. Inspect small buttons, tabs, scroll containers, shop/upgrades, item/merge popups, mastery chips, Settings, missions, Prestige, targeting Help/Guided cards, review modal and error state, long Russian/Polish compound phrasing, and wrapped purchase failures. Keep touch targets accessible and scroll indicators discoverable. **Check the known English Next Stage chip / View Camp overlap**: document it if unchanged; if a translated locale makes it worse, fix the localized layout within scope. Avoid unrelated UI refactoring.
6. Capture full-size and store-card-size / contact-sheet visual evidence using real Godot windows for **all five languages** and key English comparisons. State what was actually inspected. Do not claim phone-device validation unless a real phone was used; final Android/export validation is still a separate global release gate.
7. Add targeted tests for Batch 02: completeness and exact key-set parity, PO parsing, placeholder ordering and plural form correctness, intentional English-identical allowlist, script/glyph coverage, runtime mapping, test-only selectability, production gating and representative visual overflow. Reuse/extend existing probes rather than duplicating test tooling needlessly.

## D. Maintain rollout isolation

- **Do not translate Batch 03 or 04:** leave `tr_TR`, `id_ID`, `vi_VN`, `th_TH`, `hi_IN`, `ja_JP`, `ko_KR`, `zh_CN`, `zh_TW` and their drafts untouched. Keep the other four non-Batch-02 languages within the 14 prior drafts outside the five currently being finalized untouched too, except unavoidable source-audit reporting. (All 14 non-Batch-01 languages initially remain draft; only Batch 02's five may change this run.)
- Keep approved Batch 01 catalogs intact except for the narrow, explained source-key propagation described in section A; never silently rewrite them. Keep the 19-language ZIP, untracked ASO package, marketing media, exports, and unrelated project files untouched.
- No gameplay balance, supply rule, boss tuning, social media video, store description, monetization, or Playbook overhaul in this task.
- Leave production Language Settings visibility consistent with the **current validated project behavior and Playbook**: unavailable languages may remain listed as disabled, but must not become selectable. Do not add development notices in player-visible UI.

## E. Final checks, documentation and commit

1. Run focused source/localization validators, relevant Godot import and test-only switching probes, UI overflow/glyph sweeps and screenshot inspection. Once the batch is stable, run the **entire maintained regression suite once at the end**. If it fails, correct relevant regressions and rerun the necessary checks; report exact total/pass/fail rather than assuming 41/41.
2. Record `docs/LootFarmer_Localization_Batch_02_Report.md` with: live source SHA/count, missing-source-string audit and any added keys, translations of any new keys in previously approved catalogs, per-language totals, fuzzy/missing/duplicate/malformed placeholders/English-identical exceptions, linguistic issues identified/fixed, glossary updates, Godot mapping and production gate, test counts, screenshots/contact sheet paths, unresolved English/UI defects, native-speaker/device limitations, and Batch 03 handoff.
3. Update only directly relevant game localization and test documentation. The canonical Playbook was comprehensively reconciled in Change 37; modify it only if genuinely new **validated and reusable** guidance is discovered, and otherwise leave it alone.
4. When the batch is truly complete, **automatically commit** the five catalogs, necessary source/test/UI fixes and documentation as the next chronological Change number from actual Git history. Do **not push**. If any catalog is incomplete or material verification is blocked, describe the incomplete result explicitly rather than claiming PASS or marking languages production-ready.

## F. Completion report expected from Claude

- **Result:** PASS or BLOCKED; actual Change number, commit hash, no push.
- **English source:** current/final key counts, SHA and any missing strings discovered; confirmation Batch 01 remains intact.
- **Five new locales:** keys, fuzzy/missing/invalid placeholders/English fallback totals, plural validation, semantic issues and corrections for each.
- **Integration:** actual locale mapping, test-only access and production exclusion; live language switching/persistence.
- **Evidence:** screenshots/contact sheets, glyph/overflow results, tested device/window sizes and limitations.
- **Regression:** focused probes and maintained full suite exact count/result; any pre-existing failures explained separately.
- **Artifacts:** file paths, updated glossary and report; only then indicate Batch 03 next: Turkish, Indonesian, Vietnamese, Thai, Hindi.

**Acceptance rule:** All five Batch 02 catalogs are fully translated and linguistically reviewed, structurally equivalent to the *current* English source, correctly rendered and tested, with no new regressions and the global release gate still closed. No partially translated languages are automatically made available to players.
