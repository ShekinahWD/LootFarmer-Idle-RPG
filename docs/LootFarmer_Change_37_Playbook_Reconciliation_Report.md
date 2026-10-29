# LootFarmer Change 37: Playbook reconciliation for Changes 27 to 36

**Date:** 2026-10-28. **Brief:** `docs/LootFarmer_Playbook_Comprehensive_Reconciliation_Changes_27_to_36.md` (untracked, supplied by the developer). **Baseline:** Change 36, `38ba11b` (latest commit; no later change existed). **Scope:** documentation only. The canonical `docs/Reusable_Game_Development_Playbook.md` and this report are the only files changed. No code, scene, resource, data, localization, marketing, export or test file was touched. Nothing was pushed.

## 1. Sources reviewed

| Change | Sources read | Notes |
|---|---|---|
| 27 | `LootFarmer_Change_27_Report.md`, `LootFarmer_Change_27_Google_Play_Store_Assets.md` (brief) | First store media; Playbook 87.7 got one line in that change |
| 28 | `LootFarmer_Change_28_Report.md`, `LootFarmer_Feature_Graphic_Creative_Redesign.md` | Feature graphic |
| 29 | Commit `5b381f2` (Playbook-only) | No report file exists; the commit itself is the record (101.1) |
| 30 | `LootFarmer_Change_30_Report.md`, `LootFarmer_App_Icon_Creative_Redesign.md` | App icon |
| 31 | Commit `8a24319` (Playbook-only) | No report file exists; the commit is the record (101.2) |
| 32 | `LootFarmer_Change_32_Report.md`, `LootFarmer_Change_32_Store_Trailer_Redesign.md`, `marketing/trailer/README.md` | Trailer redesign; brief records the "no three-fragment slogan" and music-only directives |
| 33 | `LootFarmer_Change_33_Report.md`, `marketing/trailer/README.md` | Revision requested in conversation; **no brief file exists** |
| 34 | `LootFarmer_Change_34_Report.md`, `LootFarmer_Google_Play_Screenshots_Creative_Redesign.md`, `marketing/screenshots/README.md` | Screenshot redesign |
| 35 | `LootFarmer_Change_35_Report.md` and its commit's Playbook diff (42 lines) | Review invitation and targeting lesson were already documented in 18.3, 20, 26.2, 52.1, 52.2, 132.3 |
| 36 | `LootFarmer_Change_36_Report.md` | Supplies 3 uses; final-boss audit |
| Localization (pending) | `docs/LootFarmer_Localization_Batch_01_Implementation.md` (untracked brief), `docs/LootFarmer_Google_Play_ASO_20_Locales_Package/` report and locale map (untracked) | Read only. Both are the developer's work in progress; neither was moved, edited or committed |
| Toolkit | `Godot-Marketing-Toolkit` `fit_window()` and `ui_group` code | To check two Playbook statements against the code |

Evidence folders (`docs/Change_27_Evidence` to `Change_36_Evidence`) were consulted through the reports that describe them; images were not re-inspected, because no Playbook claim here depends on judging pixels.

## 2. Coverage matrix

Status: **covered** (already in the Playbook, left alone), **added**, **corrected**, **open** (not verified; recorded as such).

| Subject | Source | Playbook section | Status | Rationale |
|---|---|---|---|---|
| Authentic, language-neutral screenshots, every class its own render, raw masters, byte-identical uploads | C27, C34 | 87 intro, 87.1, 87.9 | covered | Already precise; not reworded |
| Screenshot set as a portfolio (distinct mechanics, places, looks, enemies; hook in the first images) | C34 report and brief | 87.10 step 2 | added | Change 27's set passed every technical check and failed creatively; no rule covered set composition |
| Per-frame provenance: logged real events, seed search, loot-table legality probe, provenance manifest | C34 | 87.10 step 3 | added | 87.8 required true state but not proof per frame |
| Draft exploration and recorded rejection reasons (VFX covering subject, panels without payoff) | C34 | 87.10 step 4 | added | |
| Full-set contact sheet, per-class store-card sheets, before/after pairs, inspection at size | C34 | 87.10 step 5 | added | |
| Same-moment and distinct-scene metrics; determinism re-render and presentation-only differences | C34 | 87.10 step 6 | added | |
| Hash-protect other approved media; retire pipeline jobs that would overwrite the new set | C28, C30, C34 | 101.1, 101.2 (covered), 87.10 step 7 (added) | added | Extends the existing 101 rule to screenshots |
| Desktop/Chromebook slot for a portrait-only game | C27, C34 | 87.1 | added | Eligibility is unverified; images alone do not prove it |
| Seasons/zones variety | C32 to C34 | 87.10, 133.7 | added, labelled game-specific | Four seasons are LootFarmer content, not a requirement |
| Window larger than the monitor | C27, toolkit code | 87.7 | **corrected** | The section said both "raise the max size to exceed the screen" and "choose sizes that fit the monitor". The toolkit's `fit_window()` lifts the limit (C27 rendered 1800×3200 on a 1080 px monitor); the "fit the monitor" advice now applies only to ad-hoc evidence captures |
| Clean shots hide only the registered UI group | C33, toolkit | 87.2 | covered, one line added | Notes the same group serves video and that hiding UI changes presentation only |
| ALWAYS UI root shows paused state in frozen captures | C27 | 87.7 | covered | Added in Change 27 |
| Feature graphic workflow | C28, C29 | 101.1 | covered | |
| Portrait end card from the feature graphic | C28 plan, C32/C33 result | 101.1 step 7 | **corrected** | Said "a plan, not yet validated in a finished video"; Changes 32/33 animated it and verified layers and last frame pixel-identical |
| App icon workflow, adaptive/themed, artifact inspection | C30, C31 | 101.2, 49 | covered | |
| Trailer hook as an observable chain (carry, fight, drop, pickup, equip, changed look) | C32 brief and report, C33 | 133.7 step 1 | added | |
| Clean takes with real equip calls; no faked actions or ordinary-game changes | C33 | 133.7 step 2 | added | |
| Close-ups, readable holds, camera beyond the slider only in clean shots, staging around HUD corners | C32, C33 | 133.7 step 3 | added | |
| Real weather, seed-found drops, banner-free staged history, logged events | C32, C33 | 133.7 steps 4 and 5 | added | Candidate lessons listed in the C32/C33 reports |
| Card reading time, end card from the brand, reuse before recapture, re-render previous cut byte-identical | C32, C33 | 133.7 steps 6 and 7, 133.2 (covered) | added | |
| Trailer evidence set and media protection | C32, C33 | 133.7 step 8 | added | |
| Music-only audio excluded at source and verified by residual | C32 | 133.1, 133.3 | added | 133 described only game-audio-plus-music |
| Trailer orientation example | C32 | 133.1 | **corrected** | "Play Store 16:9" read as a default; now "the game's native orientation" with both examples |
| Social 5 focused + 5 full-landscape split | Everfort; LootFarmer portrait | 133.5, 0.9 row 17, 49, 134.4 | **corrected** | Marked mandatory for landscape games; portrait games decide their variants with the developer. No portrait social package has been produced, so nothing portrait-specific is claimed |
| Match cuts | Brief | 133.7 | added as future option | Explicitly not validated and not to be retrofitted |
| Natural copy, no formulaic three-fragment slogans | C32 brief, reconciliation brief | 74.1 | added | Style preference, not a ban on short text; double-dash rule kept |
| Runtime `.po` versus store listing localization | Batch 01 brief, ASO package | 132 intro (covered), 134.3 | added | One paragraph that neither substitutes for the other |
| English source audit of the shipping game before the freeze | Batch 01 brief | 132.4 | added, labelled approved procedure not yet executed | Batch 01 has not run; method only |
| Translation quality gates (natural, glossary distinctions, regional variants, copy-through and fuzzy detection, partial drafts never enabled) | Batch 01 brief | 132.5 | added, same label | 5+5+5+4 batching was already covered and is unchanged |
| Handoff archives outside the folders the game and probes read | C36 suite result | 132.5, 60.1 | added | The 19-language archive in `localization/` failed `change_35_probe` |
| Runtime-to-Play locale map, metadata policy, no unverified keyword claims | ASO package | 134.1 to 134.3 | covered | |
| Storefront from one export tag, artifact verified, no tag means no prompt | C35 | 52.1 | covered | |
| Eligibility on saved active play, pending state, two-layer quiet moment, honest copy, immediate buttons, retryable failure, one invitation per profile, Settings link | C35 | 52.2 | covered | |
| Review modal holds the world | C35 | 26.2 | covered | |
| Review panel in the game's own style; thresholds and URLs as per-game data | C35 | 52.2 | added | The pattern is reusable; 60 min / 50% / 280 px / 2 s are LootFarmer tuning |
| Real-device link handling and store review policy | C35 | 52.2 | open (already stated) | Unchanged; still not verified |
| Gesture lesson shows the real gesture, completes on real success, bounded escape, step insertion into saved tutorials | C35 | 18.3 | covered, one sentence added | Added that Help shows the same card and that escape time is per-game data |
| One authorized value change versus audit-only investigation | C36 | 112.2 | added | |
| Real simulation, legitimate builds, real Prestige transaction, labelled seeding, non-zero exit on legitimacy failure | C36 | 112.2, 140.1 and 140.2 (covered) | added | 140 kept; cross-reference added from 140.2 |
| Three evidence classes (legal fixture, demonstrated progression, full playthrough) | C36, brief | 112.2 | added | |
| Minimum and recommended builds, neighbours, one-variable counterfactuals, determinism versus win rate | C36 | 112.2 | added | |
| Survival cliffs and mandatory progression | C36 | 112.2 | added | |
| Measured farm rates versus projected hours; no total playthrough time claimed | C36 | 112.2 | added | |
| Superseded historical audits labelled, not deleted | C36 (`change_9_balance`) | 112.2 | added | |
| Consumable stock versus use-based mastery | C11 | 141.1 | covered | |
| Changing uses-per-level (single source, remainder, clamp, fixtures, copy, threshold effect) | C36 | 141.1 | added | |
| Licence records as a publication gate | C27 to C34 (REL-02) | 49 Assets, 136.3 (covered) | added | 49 had no such line although every media report lists REL-02 |
| Exact test counts; environment contamination reported, not hidden | C36 (38/39) | 60.1, 43 and 44.2 (covered) | added | |
| Probes that read registered/exported state instead of folder contents | C36 | 60.1 | added as recommendation | Not applied in LootFarmer |
| Toolkit version used by a game is evidence, not a ceiling | C27 to C34 | 135.2 | added | |
| Scoped creative batches; no AI-fabricated gameplay | C28 to C34 | 45, 87.8, 101.1, 101.2 | covered | |
| First Snowman weapon guarantee | C27 | 144.1 | covered | Same pattern as the existing pity-guarantee rule; nothing new to generalize |

## 3. Before and after, substantive updates

- **Header and topic map.** Added a dated note listing every section touched; topic map now indexes 52, 74 and 140.
- **0.9 Stage 17, 49 Store, 134.4.** "5 focused + 5 full-landscape" no longer reads as universal; each points to 133.5.
- **18.3.** Help shows the same reference card; escape time and target choice are per-game data.
- **49 Assets.** New publication gate: retained licence or purchase records for build and store media.
- **49 Store.** Screenshot and video bullets point to 87.10 and 133.7.
- **52.2.** Two bullets: present the invitation in the game's own panel language with the world held; reuse the pattern, keep thresholds and URLs in the game's data and documents.
- **60.1.** Exact counts and named failures; environment-caused failures are reported with a non-destructive remedy; recommendation to assert registered or exported state.
- **74.1 (new).** Connected natural copy instead of three-fragment slogans, with an example and limits.
- **87.1, 87.2, 87.7.** Chromebook slot caveat; clean-shot group also serves video; window-limit contradiction resolved.
- **87.10 (new).** Portfolio planning, per-frame provenance, drafts, set review, metrics, protection, honest limits.
- **101.1 step 7.** Portrait end card now validated in a finished video.
- **112.2 (new).** Boss-readiness audit method.
- **132.4, 132.5.** Source audit before freeze; translation quality gates; archive placement. Both labelled as an approved procedure not yet executed.
- **133.1, 133.3.** Native-orientation trailer example; music-only variant and its verification.
- **133.5.** Landscape split marked as landscape-only; portrait games decide with the developer; nothing portrait-specific claimed.
- **133.7 (new).** Trailer storytelling method; match cuts recorded as a future option only.
- **134.3.** Store listing text and runtime catalogs never substitute for each other.
- **135.2.** A toolkit version a game used is evidence, not a ceiling; adapter-first fixes.
- **140.2, 141.1.** Cross-reference to 112.2; changing uses-per-level checklist.

## 4. Contradictions resolved and which source prevailed

1. **87.7 window size.** Toolkit code (`fit_window()`) and the Change 27 report prevailed over the older "fit the monitor" paragraph, which is now scoped to ad-hoc captures.
2. **101.1 step 7.** The Change 32 and 33 reports prevailed over the Change 29 wording ("not yet validated").
3. **133.5 versus a portrait game.** The reconciliation brief and LootFarmer's portrait footage prevailed over the universal 5/5 wording; the Everfort-validated landscape rule is kept intact.
4. **133.1 audio default.** Not a contradiction; the music-only variant is added beside the existing game-audio method.

## 5. Deliberately left unchanged

- **Sections 138 to 146 stay as project-labelled batches.** The header asks to fold them at the next consolidation pass; doing so moves dozens of subsections and their cross-references, which is a separate reviewable change rather than part of this reconciliation.
- **Section 0.11 and 132.1 to 132.3, 132.6** (localization infrastructure, 20-language set, Godot mapping): accurate as written.
- **52.1, 26.2, 20** (Change 35): already precise.
- **133.2, 133.4, 133.6**: still accurate; LootFarmer's trailer followed them.
- **133.1's 20-language title-card localization rule**: unchanged. LootFarmer's trailer cards are English only; whether they get localized is the developer's decision at publication.
- **101.1, 101.2** beyond step 7: already complete.
- **The 2026-10-15 "Last consolidated" header paragraph**: historical record; its "5 focused + 5 full-landscape" wording describes Everfort's validated package.
- No Change-numbered section was added (no section 147).

## 6. Discrepancies found (reported, not fixed: out of scope)

- **Trailer outfit not obtainable.** The Change 33 trailer's Autumn shot uses the tier-1 Grim Reaper outfit. Change 34's loot-table probe found that tier is not dropped by any enemy and switched the screenshot to tier 3; the trailer was not revisited. That shot shows an item a player cannot get. Needs a decision: re-record that one season shot with an obtainable tier, or accept it.
- **Environment hazard.** `localization/LootFarmer_Runtime_19_Languages_Partial_Drafts.zip` (untracked) still makes `change_35_probe` fail, which asserts that the folder holds exactly one file. Recommended remedy: the developer moves the archive outside `localization/` (for example to a sibling folder); optionally a later change makes that probe check registered translations instead. Neither was done here.

## 7. Remaining gaps needing developer input or real-device tests

- REL-02: licence or purchase records for Pixel Plains art, its Animation Pack and `assets/sounds` (the trailer music). Store media stay unpublished until they exist.
- Developer review on a phone of the Change 33 trailer (picture, cards, music level) and of the 24 Change 34 screenshots.
- Chromebook listing eligibility for the portrait Desktop images.
- Review invitation: `OS.shell_open` with the Play and itch.io URLs on a real Android device and on Windows; Android system Back; current store review-request policies.
- Targeting lesson feel and the 60 s escape on a phone.
- Launcher and themed icon on a physical Android 13+ device; Play Console preview of icon and feature graphic.
- Localization Batch 01 has not run: the English source audit and translation gates in 132.4 and 132.5 are the required method, not yet validated evidence.
- Portrait social-video composition: undecided and unvalidated (133.5).
- Final-boss tuning proposals (helper damage, boss damage, action gap, Prestige signposting) and the untested no-Lifesteal card path remain proposals; whole-campaign time to the final boss is unmeasured.

**Game-specific versus reusable:** the four-season variety in LootFarmer's screenshots and trailer is that game's content, not a Playbook requirement. Match cuts are recorded for future consideration only and are not part of any approved video.

## 8. Validation performed

| Check | Result |
|---|---|
| Section-reference scan of every changed line (headings parsed; "section N", "§N" and dotted numbers in parentheses resolved against them) | 0 unresolved |
| Same scan over the whole file, compared with the Change 36 version | 60 unresolved numbers before and after, all code values and measurements (for example `Color(0.09, ...)`, "17.8 minutes"); no section reference broken |
| Duplicate heading numbers | none (465 numbered headings; 461 before, plus 74.1, 87.10, 112.2, 133.7) |
| Heading order | 74.1 before 75; 87.10 after 87.9; 112.2 after 112.1; 133.7 after 133.6 |
| Double dashes in added prose (outside backticks) | none |
| `git diff --check` | clean |
| Line endings | LF only (0 CR), as before |
| Files changed | the Playbook and this report only; untracked developer files untouched |
| Gameplay test suite | **not run**: documentation-only change; no executable file changed |
