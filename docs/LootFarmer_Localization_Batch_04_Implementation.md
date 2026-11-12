# LootFarmer — Runtime Localization Batch 04 of 04 (Final Four Languages)

**Goal:** Complete and enable Japanese, Korean, Simplified Chinese, and Traditional Chinese in the current local Godot repository, while preserving all prior work. This is the **final translation batch**, not authorization to publish or to claim real-device certification.

**Scope:** In-game/runtime localization only. Google Play/itch.io ASO listings are a separate workstream. Work directly in the developer's Git repository, not in an earlier uploaded ZIP. Read the current canonical `docs/Reusable_Game_Development_Playbook.md` before proceeding, especially the **latest** §§0.11, 129.1, 132.1–132.6, 134.3 and relevant font, export, UI, test, documentation and source-control sections. Also read the existing Batch 01–03 reports, Change 40 and Change 42 reports, localization glossary, readiness list, validators and probes. The current Playbook takes precedence over any older attached version or earlier English-only rollout instructions.

## Current checkpoint: independently verify, do not assume

- Last reported commit: **Change 42, `bd7401a`**, not pushed. Confirm Git HEAD, history, status and actual files first. Infer the next chronological Change from Git (expected **Change 43** if unchanged).
- Last reported English catalog: **1,951 keys**, unchanged during Change 42. Check source count, checksum, PO validity, references and placeholders in the current repository; don't copy an older `en.po` into it.
- Available runtime languages: **English + 15 completed translations = 16 selectable**. The existing language dropdown, native-script labels, Automatic resolver, preference persistence, test mechanisms, per-locale font system, and **single `ENABLED_LANGUAGES` readiness list** are established working infrastructure. Preserve them.
- Four unfinished draft catalogs remain. Treat them as untrusted raw drafts, not accepted translations: `ja_JP`, `ko_KR`, `zh_CN`, `zh_TW` (verify actual repository filenames/locale IDs and Godot's locale resolution, don't blindly rename files).
- Existing reported tests: **43/46 in the developer's working tree** with three recurring failures (`export_manifest`, `change_27_probe`, `change_26_probe`) attributed to unrelated uncommitted icon/version changes in `project.godot` and `export_presets.cfg`; corresponding checks reportedly pass in a clean copy. Re-evaluate rather than taking that attribution on faith. **Do not discard or stage the user's changes.**
- Thai and Hindi fonts already use locale-specific fallbacks; their resource licenses and Godot text data were handled in Change 42. Avoid altering these behaviors when introducing CJK fonts.
- **Published game:** user has already released LootFarmer. This task does **not** authorize uploading a new AAB/APK, publishing, pushing Git or changing Play Store/itch.io listings.

## A. Audit English source and preserve previously completed languages

1. Before translating, inspect `localization/en.po`, string references (`tr()` and constructed IDs), all player-facing UI and generated text, the latest Change 41 game features, localization validators, current export manifests and the shared terminology glossary.
2. Specifically examine: tutorial mode chooser and movement/targeting steps; joystick Left/Center/Right setting; Focus Farming and defensive targeting; Prestige 21/31/41 collection counts; equipment, outfits, weapons, merges and evolution; three-successful-use supply mastery; drop feedback; bosses/skills/missions/mastery; review invitation for Google Play/itch.io; Discord; automatic language labels; number/unit/duration interpolation; confirmation/error and empty states. **Store listing translations are not runtime translations.**
3. If any genuinely missing or semantically wrong English source key is found, fix it narrowly and propagate the new/changed meaning to **all 15 already-enabled non-English catalogs plus these four**. Validate parity and include exact key-level accounting in the report. Otherwise leave source and the other 15 translations unchanged. Never remove the 113 previously identified unused keys solely because they seem unused.
4. Preserve semantic identifiers and translated whole sentences; avoid stitching grammar-sensitive fragments where a complete templated string is available. Inspect *all* multi-placeholder entries manually for value order and intended meaning; structural placeholder equality alone is insufficient.

## B. Produce four complete, natural `.po` catalogs

| Language | Expected file / locale | Linguistic review priorities |
|---|---|---|
| **Japanese** | `localization/ja_JP.po` / `ja_JP` | Natural Japanese game UI and polite/direct register by context; appropriate kanji/kana, RPG terminology; compact but clear buttons; correct particles, number counters, width and punctuation. Don't mimic English word order. |
| **Korean** | `localization/ko_KR.po` / `ko_KR` | Natural Korean gaming language; consistent verb endings/register and terms; correct particles and number+unit grammar; spacing, Hangul syllables, punctuation and short-label readability. |
| **Simplified Chinese** | `localization/zh_CN.po` / `zh_CN` | Natural Mainland Simplified Chinese gaming vocabulary and UI conventions; correct simplified glyphs, concise instructions and stat terms; do not merely auto-convert a Traditional catalog. |
| **Traditional Chinese** | `localization/zh_TW.po` / `zh_TW` | Independent Taiwan-oriented terminology and word choices, traditional glyphs and punctuation; not only a glyph conversion of Simplified Chinese. Verify regional equipment/combat nomenclature. |

For **each of the four languages**:

- Fully translate and contextually review **every current English key**: no missing/extra/duplicate/fuzzy/empty strings, broken PO syntax, unexplained English leftovers, invalid markup, whitespace loss, newline errors or placeholder mismatches. Target expected count **1,951 each**, changing only if English legitimately changed in this run.
- Work from the English source and actual game context. Do not translate word-for-word, transliterate existing English terms mechanically, or copy the other Chinese variant wholesale. Keep approved proper names, UI symbols, game name and universal abbreviations when appropriate. Use the project's intentional-English allowlist for **each identical entry and its reason**.
- Preserve exact semantic IDs, `msgctxt` if present, numeric format arguments including named/ordered placeholders and escaped `%`, rich text tokens, valid `%`/`^`/coin/gem/stat notation, item tiers, line breaks and interpolation. Validate **actual formatted examples** across small/large values, not just regex parity.
- Because the English PO does not necessarily have plural forms, phrase counts/quantities naturally for any integer with the existing formatter. Check grammatical relation of variables and numbers and avoid inventing a pluralization API or silently changing game mechanics.
- Keep terms for loot/drop, stealing/wearing enemy equipment, merging duplicates, evolution, supplies, skills, boss summoning, Prestige, 13-key progression and Focus Farming internally consistent. Document notable JA/KO/zh-CN/zh-TW choices in `docs/LootFarmer_Localization_Glossary.md`.
- Explicitly report that text was reviewed by the implementing agent, **not** by native speakers unless native speakers actually review it. Avoid calling a translation “native approved” based on automated checks alone.

## C. CJK fonts, shaping and layout quality

1. Inspect the existing Godot 4.7 font/theme setup, fallback chains, `FontVariation` resources, packaging and Change 42 per-locale font approach before adding anything. Check Japanese kana + kanji, Korean Hangul syllables and punctuation, and region-specific Simplified/Traditional Han glyph forms. **A Unicode code point present in a font is not proof that the displayed glyph is correct for that locale.**
2. Prefer properly licensed **Noto Sans CJK regional variants or other suitable existing licensed font assets** if present and appropriate. Otherwise source versioned fonts with verified redistribution rights (e.g. SIL OFL), record provenance, actual files, license and inclusion in `docs/LootFarmer_Asset_Registry.md`. Do not include unlicensed system fonts or distribute font files via the final chat message. Mind APK/AAB size and inspect actual build size changes; subset only through an already verified reproducible process that retains required glyphs.
3. Preserve Thai/Hindi locale-specific font handling. Keep the established Latin/Cyrillic/Indic typography unchanged; don't globally add CJK fallback resources if that alters line height or metrics for all languages. Choose **locale-appropriate Han fallback order** for Japanese vs Chinese variants and verify mixed-script runs, numerals, punctuation, arrows and symbols.
4. Validate Godot text rendering and CJK line-breaking behavior, including punctuation at beginning/end of lines (kinsoku), no missing glyph/tofu boxes, no clipped Hangul or kana, touch targets, scrollbars and truncated labels. Ensure characters stay readable rather than shrinking critical text below the Playbook's practical floor. Verify string-by-string actual text layout, not just PO validity.
5. Perform scripted sweeps and **real rendered window captures** at established sizes **432×960, 540×960, 768×1024** for all four languages; inspect full resolution **and realistic on-phone scale**. Cover: Settings dropdown (closed, open, scrolled with 21 entries including Automatic); HUD and stage/boss chips; maps/camps; mission/follower/filter; item/gear details including outfits and weapons, merging, supplies/skills; Prestige collection/rewards; upgrades and purchase errors; Guided/Basic tutorials and Help; review prompt on both storefront configurations; confirmation/empty states. Explicitly capture screens missed by earlier sweeps where practical.
6. Verify live switching while panels are open, dynamic string refresh, correct number/unit placement and saves; test selected language persistence and inactive/automatic detection. The known **English Next Stage / View Camp overlap** is an existing issue: document it if unchanged, and fix any **new locale-induced** overlap; do not expand into unrelated redesign without need.
7. Report desktop screenshots as desktop-window evidence. **A real Android phone check is a separate open release gate**: no claims of real-device CJK certification without an actual device test.

## D. Progressive activation and complete 20-language inventory

1. Keep the existing **single readiness source** in `scripts/autoload/localization_service.gd` (`ENABLED_LANGUAGES`); reuse the Settings dropdown and Automatic resolver. While catalogs are incomplete, access them through a test-only override. Do not expose incomplete languages to production.
2. Once all four pass required source/meaning/font/layout/runtime tests, add exactly `ja`, `ko`, `zh_CN`, `zh_TW` or their **verified actual Godot-compatible IDs** to that readiness list; end with **English + 19 translations = 20 selectable languages** and **21 dropdown entries including Automatic**. Avoid duplicate rows caused by locale aliases.
3. Automatic device-language behavior must explicitly distinguish Chinese script/region: `zh-CN`/`zh-SG` and `zh-Hans` map to Simplified; `zh-TW`/`zh-HK`/`zh-MO` and `zh-Hant` map to Traditional. Handle generic `zh` via a documented deterministic fallback; do not choose by OS or storefront. Japanese -> Japanese; Korean -> Korean; unsupported locale -> English. Preserve special es-419/es-ES, pt-BR, Indonesian, Ukrainian and earlier mappings, including explicit manual choices and saved choice compatibility. Test conflicting script-region inputs with a justified rule.
4. Keep the same no-restart Settings behavior and Automatic label showing the resolved language. Verify dropdown placement/scrolling, scrollbar visibility, touch/Back/keyboard/controller interaction and no touch-through on narrow portrait sizes. Do not restore a language button grid.
5. Inspect actual **Google Play Android AAB**, **itch.io Android** game data and **itch.io Windows** game data for exact localization catalog and font contents, export feature tags, package/signing identity and positive file list. Generate/store only outputs needed for verification, within established project paths. Verify there are **exactly 20 catalog files** in the shipped data (if the existing packaging design stores one per language) and zero drafts/CSV/ASO/test/support files. Preserve license documents as required for release, not raw test artifacts in the build. If an itch.io APK or `.exe` cannot be built due to missing credentials, state precisely what was verified (PCK versus finished installation).
6. The existing **“all 20 languages certified”** flag is distinct from enabling translations in-game. **Do not mark Android/public-release certification complete** without the Playbook-required cross-script real-device acceptance. It is valid to have 20 selectable catalogs in development/export packages while the final public-release gate remains pending. Do not publish or upload a build.

## E. Global validation after the final batch

This is the last language batch, so in addition to targeted CJK verification, perform a **global 20-language regression and readiness audit**, without widening the translation task into gameplay balancing or changing published store metadata:

- English and all **19** non-English catalogs have identical key sets, valid PO syntax, consistent placeholders, no fuzzy/missing/empty/unexplained English strings; baseline English source hash/count recorded.
- All intentional-English exceptions documented; glossary coherent across the 20 languages; inspect currency/percent/duration/stat grammar and multiple placeholders, including region-specific typography and unit conventions.
- Font/script coverage and rendering verified for Latin, extended Latin, Cyrillic, Vietnamese, Thai, Devanagari, Japanese, Korean and both Chinese variants; script-specific fallback does not alter other locale metrics.
- Settings selection, Automatic routing, persistence, save migration behavior, language changes with panels open, store-specific review prompts, and the entire 21-option dropdown checked.
- All storefront exports contain only enabled catalog/font/data resources and no source-only tools, partial-draft files, untracked ASO package or `untranslated_ids.csv`. Export manifests/regeneration consistent with source tree.
- Check all established screen classes in the global automated sweep, plus targeted visual evidence of the newly added languages. Distinguish checks not performed (notably physical-device tests and human linguistic review).
- Add a concise **20-language readiness checklist** identifying what is verified now and what **still blocks release**; do not mislabel partial certification as release approval.

## F. Preserve unrelated edits; testing, docs, commit

- Inspect `git status` at start and end. **Preserve** the developer's uncommitted `project.godot` / `export_presets.cfg` edits and any other unrelated files exactly; include only your intended changes and generated allowlist/export lines. The prior recurring three dirty-working-tree failures must not be hidden or “fixed” by undoing developer work. If the current clean baseline differs, investigate and report exact evidence.
- Do not touch gameplay balance, boss damage, marketing videos, screenshots, icon/feature graphic, published listings, store review links, unrelated game systems, or the previously dropped optional Grim Reaper trailer correction.
- Build on existing validators/probes. Add/extend a **Batch 04 probe** plus global 20-language checks (not duplicate frameworks). Validate CJK glyph forms, text layout, PO parity, placeholders and dynamic interpolations, region routing, dropdown, export inclusion/exclusion and the previous 16 languages.
- Run targeted tests and Godot window/evidence capture during implementation; after fixes, run the **full maintained regression suite once at the end**. Report exact numerator/denominator in the current working tree and, if necessary, a clean copy. Do not claim the entire suite passes when only targeted tests do.
- Update `docs/LootFarmer_Localization_Glossary.md`, directly relevant localized test/export docs and write `docs/LootFarmer_Localization_Batch_04_Report.md`. Include: source key count/hash, audited gaps, per-locale coverage and explicit identical-text allowlist, CJK terminology distinctions, font license/source details, visual contact sheets and measured screen checks, live switching/device mapping, export file inventories/build sizes, global 20-language readiness matrix, test evidence, open native-speaker/Android/device checks and any known English overlap. Only add to the canonical Reusable Playbook if a **new verified, generally reusable lesson** is discovered; avoid redundant append-only documentation.
- Commit autonomously using the **actual next Change number** (expected **Change 43**) and sequential commit naming, without pushing. Avoid staging untracked or unrelated developer files. If a blocking issue cannot be resolved, give a candid BLOCKED/partial report and do **not** enable an incomplete language or claim 20-language completion.

## G. Acceptance / Claude handoff report

Return a concise evidence-based result:

1. **PASS or BLOCKED**, actual commit hash, no-push status, worktree preservation.
2. English source key count and SHA; missing-key audit and any changes propagated to previous catalogs.
3. Four translation coverage counts, corrections, terminology choices, exceptions, and status of manual agent review (not native-speaker approval).
4. CJK font provenance/licenses, per-locale fallback, actual rendered glyph/line-break inspection, screenshot/contact-sheet paths and responsive validation counts.
5. Explicit Chinese script/region device resolution and dropdown/select/persistence checks, with 20-language inventory and all 21 dropdown options.
6. Verified contents and sizes for Google Play and both itch.io distribution exports; exact status of APK/EXE generation.
7. Targeted and full-suite exact results (working tree vs clean tree if applicable), and outstanding issues.
8. A **release-readiness verdict separate from translation completion**: in-game batch may PASS while physical-device checks and native-speaker assessment remain pending. Do not publish.

**Stop after this final localization batch and global audit.** Do not begin a general UI redesign, performance optimization, store submission or post-release marketing task.
