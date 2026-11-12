# LootFarmer: Comprehensive Reusable Game Development Playbook Reconciliation

**Task type:** Documentation-only audit and consolidation  
**Repository:** Current local LootFarmer Git workspace  
**Primary output:** `docs/Reusable_Game_Development_Playbook.md` (canonical copy)  
**Baseline:** Determine from the *actual current Git history*; Change 36 was reported committed as `38ba11b`, but do not assume no later changes.  
**Authorization:** Developer approved this documentation update. **Do not push.**

## 1. Objective

Perform a careful, **full-playbook reconciliation** of the lessons learned and developer decisions across LootFarmer's recent feature, marketing, localization, publishing and balance work, especially **Changes 27 through 36**. The Playbook is already extensive: **read the complete existing file and preserve its validated processes**. Do not append a huge duplicate Change log or rewrite the guide from scratch. Find missing rules, contradictions, ambiguous instructions, and stale advice; apply the smallest complete, durable improvements in their proper thematic sections.

The Playbook must describe **principles reusable by future games**, not hardcode LootFarmer's title, URLs, boss names, equipment, stage counts or prices as universal requirements. Specific games may be referenced as **clearly labeled proven examples** with citations to their project reports.

## 2. Establish the authoritative sources before editing

1. Inspect `git status`, recent commits, and the current worktree. Do not reset, clean, rebase, delete, or alter user files. Choose the **next chronological Change number** from the actual history when committing.
2. Read the **entire** `docs/Reusable_Game_Development_Playbook.md`, including its historical section moves, TOC/indexes, stage lifecycle and maintenance instructions. This file is the authoritative output. Determine whether another root copy exists and how it is synchronized; do **not** introduce diverging copies.
3. Read the available reports, briefs, scripts and evidence for Changes **27–36**, particularly:
   - Change 27: original Google Play capture production and release/export lessons.
   - Change 28–29: inspect actual history/reports before inferring any lesson; do not fabricate coverage for absent changes.
   - Change 30: redesigned app icon and Android adaptive/themed assets; review its research, visual tests and provenance.
   - Change 31: icon-workflow Playbook documentation (already present, avoid duplication).
   - Change 32: approved trailer-production workflow.
   - Change 33: revised trailer with equipment transformation and four seasonal shots; read `docs/LootFarmer_Change_33_Report.md` and production manifest.
   - Change 34: screenshot creative redesign; read `docs/LootFarmer_Change_34_Report.md`, `marketing/screenshots/README.md`, `docs/Change_34_Evidence/`.
   - Change 35: cross-platform review request and target-drag tutorial; read `docs/LootFarmer_Change_35_Report.md` and relevant implementations.
   - Change 36: supplies and focused final-boss balance investigation; read `docs/LootFarmer_Change_36_Report.md` and its audit fixtures.
4. Cross-check project-specific design docs, marketing materials, tests, existing Playbook paragraphs, and developer decisions incorporated in briefs. **A proposal or planned feature is not the same as a validated implementation.** If reports disagree with code, record the discrepancy rather than silently converting it into a universal rule.
5. Produce a **coverage matrix** in the change report: subject, supporting source(s), existing Playbook section(s), status (already covered / corrected / added / still unverified), and edit rationale. The goal is to know what changed and why, not to maximize rewritten text.

## 3. Required reconciliation topics

### A. Authentic Google Play screenshots and creative QA (Change 34)

Review **section 87**, especially 87.1–87.9. Add missing guidance without duplicating its existing authentic-image, locale-neutral and target-resolution policies:

- Plan the **sequence as a portfolio**, not as six isolated screenshots. Select shots that communicate *distinct* actual mechanics, progression and environments. Eliminate repetitive backgrounds, identical equipped appearances and repeated enemies.
- For games with multiple zones/seasons, actively represent that variety where relevant. Do not require four seasons in future games that do not have them.
- Tie each capture to a **real gameplay event** and record provenance (scenario, state/seed, event log, actual inventory item source, environment and equipment). Don't invent drops or show items inaccessible through normal play.
- Capture each storefront device category from its **own real target viewport**, never scale/crop one category to pose as another. Verify resolution, orientation, UI legibility and genuine visual correspondence between categories.
- Retain **raw untouched** captures separately. For default no-overlay screenshots, the final upload should be byte-identical to the approved raw frame when feasible. Generated outputs should not be bundled into runtime exports.
- Compare *old vs. new* with paired evidence; create a **full-set contact sheet** and one small-preview contact sheet **per device class**. Inspect actual images at native resolution and thumbnail size; numerical validators alone cannot establish composition quality.
- Maintain reproducibility and deterministic checks where possible, but distinguish inconsequential animation ordering changes from substantive content mismatches.
- Verify one category's artwork and subject consistency across other categories, and preserve already approved marketing assets by hash when editing screenshots only.

### B. Video storytelling and the gameplay-equipment hook (Changes 32–33)

Review section 133 and section 87's shared capture workflow. Fill gaps only where the recent results established them:

- A trailer must communicate the game's actual differentiator; where characters can wear enemy loot, show the **observable chain** of fight → authentic drop → pickup → real equip action → changed player appearance. A stats panel alone is weaker evidence of an appearance transformation.
- Where menus obscure the key event, an **approved marketing-only capture/presentation mode** may temporarily hide them while **using the real equipment system**. Do not fake inventory results, mutate ordinary-game behavior, or claim a human could perform invisible actions in the shipping UI without explanation.
- Prefer **tight gameplay close-ups** to explain visual gear changes and keep each shot long enough to read. Don't zoom so far that the setting becomes unrecognizable. Showcase distinct worlds/outfits/weapons without wasting time on redundant menus.
- Use actual seasonal/environmental effects and gameplay footage. Prefer reusing previously approved raw clips and composition assets; recapture only what the revised story genuinely requires. Keep end-card branding consistent with approved feature graphics.
- Preserve editable, reproducible video timelines, capture manifests, soundtrack provenance, contact sheets and technical/frame/audio verification.
- **Match cuts** across synchronized attacks/equipment/season changes are an **optional idea for future videos**, not a current trailer requirement or validated standard. Do not retrofit the approved trailer.
- Review any overly specific landscape-derived social-media framing defaults against portrait-first games. Do not automatically impose letterboxed landscape cuts on a native portrait game's future social edits; such changes should reflect real tested formats and human approval, not claim Change 33 validated a social-media workflow.

### C. Marketing writing voice and localization (sections 74, 132–134)

- Add a reusable writing rule (near section 74 or the relevant store-copy section) against **formulaic three-part, staccato advertising fragments** repeated as a slogan or paragraph, such as three short imperative sentences in a row. Prefer connected, natural wording that explains a specific playable fantasy and benefit. This is a **style preference**, not a ban on all short sentences or punchy headings. Preserve the existing prohibition on double dashes.
- Keep **runtime UI `.po` localization** clearly distinct from **store listing localization**. They have different source fields, terminology expectations, locale mappings, approval and validation processes.
- Before translating runtime text, audit the **current shipping code/resources** for player-visible strings missing from the English source catalog. Include freshly implemented tutorials, prompts, Settings, errors, dynamic and storefront-specific button labels. Reconcile English source changes (including supplemental string manifests) before requesting 19 translations.
- Translation should be **natural and gameplay-aware**, not literal. Preserve semantic distinctions (merge vs. evolve vs. upgrade, supplies vs. equipment, Precision/Prestige/game-specific nouns), interpolation placeholders, plurals, context and stable msgids. Adopt authentic regional language, including Spanish variants where applicable.
- Follow the existing **5 + 5 + 5 + 4** integration-batch gate, validate fonts and layouts at device widths, and test locale persistence, fallback and save compatibility. Partially translated catalogs are **not release-ready**. Keep them inaccessible to normal players until all intended languages meet agreed acceptance gates.
- Preserve separate runtime-to-Play locale mappings and approved English store-copy source. Avoid unverified keyword rankings, blindly translated titles, misleading feature claims or hard-coded cross-platform store assumptions.
- The 19-language partial translation ZIP and untracked ASO folder are **user-owned work in progress**: never move/delete/commit them incidentally during documentation cleanup. An archive accidentally placed in `localization/` should be reported as an integration/test hazard, not automatically deleted.

### D. Cross-platform review invitations and targeting tutorials (Change 35)

Sections **18.3, 18.8, 20, 26.2, 52.1–52.2 and 132.3** already contain many of these lessons. **Preserve them and avoid new redundant sections.** Verify that they clearly capture:

- Distribution-channel identification through a **single explicit export/store tag**, never the OS, package ID or debug/release type; no/unknown/ambiguous tags mean no prompt and no store action. Test the **exported artifact**, not just the preset text.
- Review eligibility based on **saved, cumulative active foreground gameplay**, excluding pause, background, offline settlement and the invitation itself. Eligibility starts a **pending** state; showing it needs a separate safe-state arbiter.
- Safe presentation in two layers (world and UI): no boss threat/combat, no low HP, no active input, no tutorial/dialog/critical panel, appropriate cooldown and continuous safe window. While the modal is open, **freeze combat and gameplay**, not merely overlay it.
- Visually polished **existing UI style** with an explicit and honest CTA, **immediately available** Review and Maybe Later/Back; **no forced three-second delay or visual-introduction animation**. No rewards or incentives, no filtering by positive sentiment, no dishonest claims that a review was actually submitted.
- Save the decision to prevent repeat auto-prompts per profile across store changes; Hard Reset follows the game's normal profile semantics. Show a permanent Settings/Feedback link when channel is configured. Failed store opening should be safely retryable.
- Gesture tutorials must describe **real input semantics**: drag from the hero toward an enemy and release to target; expose the same lesson in concise card/Help and context-driven Guided versions. Complete a Guided step based on real successful targeting, not elapsed time, auto-attack or a visual demo. Provide a bounded anti-softlock fallback if no valid target becomes available; preserve preexisting save/tutorial step state.
- Reuse the **tested design pattern**, not LootFarmer-specific 60 min / 50% HP / 2 s values or the specific store URLs as mandated constants for every genre. Such values are configurable examples, unless a cross-project policy explicitly requires them.
- Distinguish automated proof from **unverified real-device store-link handling and current storefront review-request policies**. Do not mark either as verified based only on desktop probes.

### E. Legitimate late-game balance audits and supply progression (Change 36)

Review sections **92, 140, 141.1** and other relevant test/balance sections. Extend existing principles rather than creating a LootFarmer-only guide:

- Separate **one authorized balance value change** from an **audit-only investigation**; do not silently fix bosses or adjust unrelated values because a report discovers a problem.
- Model consumable **stock, successful-use counter and mastery** separately. If changing uses-per-level, verify UI, thresholds, milestones, caps, remainder/carryover, old saves, and whether production behavior already reads the shared data value. Derive mastery from recorded successful uses when that is the established contract; do not silently spend extra copies or reset retained progress.
- A reproducible final-boss audit must run the **real combat simulation** and inspect actual skills, healing, summon/helper damage, auto-cast, supplies, resource use and survival. Verify items are drop-obtainable (not legacy IDs) and **actually equipped**, and that Prestige cards/upgrades used in fixtures can be legitimately acquired and purchased.
- Clearly distinguish: (1) a constructed simulation fixture that is technically legal, (2) a build demonstrated through real progression actions, and (3) an actual full-playthrough proof. Label direct test setup of item merge levels, supply uses, stock, player level and currencies.
- Present at least **minimum credible winning** and **recommended resilient** builds, failures around the minimum, reproducible seeds/trials, combat durations, HP/deaths/consumption and limitations. A cluster of 5 deterministic wins does **not** establish a probabilistic win rate across real players.
- Identify **survival cliffs** and possible mandatory bonuses; test counterfactuals (missing supply, omitted card, lower mastery, no Prestige) one variable at a time before recommending a difficulty change. An end boss being beatable does **not** logically establish every earlier boss is enjoyable or balanced.
- Distinguish **measured farming rates** from arithmetic projections and **unmeasured total playthrough time**. Do not claim end-to-end preparation hours if campaign climbs, offline gains, missions, Gem sources or prerequisite runs were not measured.
- Mark suggested tuning as **proposals, not validated changes**, unless implementation and counterfactual retesting actually occurred.

### F. Asset provenance, publishing, QA and workflow consistency

- Reconcile approved feature graphic, Play/Android icon, trailer, screenshot, ASO and store-publishing practices with actual tested workflows. Keep each creative asset as its **own scoped batch** and protect unrelated approved assets; no AI-fabricated gameplay or unauthorized image generation, with editable/reproducible sourced compositions.
- Keep distinction between **toolkit version validated in this project** and a global requirement; preserve reusable toolkit versioning and update procedures.
- Ensure release guidance calls out **actual third-party game-art/audio licensing evidence** as a distribution gate, independent of technical export success.
- Require an explicit validation matrix and report exact test pass/fail counts; never write “all tests pass” when an unrelated test actually fails. Record any environment contamination such as an untracked archive in a monitored directory and provide a non-destructive correction recommendation.
- Where a review note describes a behavior that was *already written in the Playbook*, mark it **covered** instead of rewording it just to generate a diff.

## 4. Editing rules

- **Documentation only.** Do not alter `.gd`, `.tscn`, `.tres`, `.json`, `.po`, game balance, UI, save formats, builds, source images, video, marketing exports, tools, tests or export presets. If a real implementation defect is uncovered, **report it separately**, do not fix it under this scope.
- Edit the **existing canonical Playbook** in place, respecting its numbering, historical section cross-references, topic ordering and navigational aids. Introduce the smallest necessary subsection(s); do not renumber hundreds of sections, flood appendices or reintroduce already covered material.
- Prefer precise, actionable instructions, verification/acceptance checks, and known pitfalls over narration. Keep universal rules game-agnostic. Call out examples and provenance separately.
- Separate **validated**, **recommended**, **not yet verified**, and **optional/future** statements. In particular: screenshot creative improvements have evidence; social match cuts are not validated; player-device review-link behavior and storefront legal/policy checks remain pending.
- Do not include user secrets, local signing credentials, or personal identifiers. Keep exact project-specific store URLs in that game's docs, not hardcoded as universal Playbook defaults.
- Preserve line-ending/format conventions and make sure links and section references still work. Inspect `git diff --check`; run relevant Markdown/link/section-reference validation if available. No full gameplay test suite needed for a docs-only change unless repo policy expressly requires it; do not falsely report it as run.

## 5. Required deliverables

1. **Updated `docs/Reusable_Game_Development_Playbook.md`** in the current repository.
2. **Documentation reconciliation report** under `docs/` (choose a descriptive filename) containing:
   - Baseline and precise commit/change number.
   - Sources reviewed (including reports that were unavailable).
   - Section-by-section coverage matrix: already covered, modified, newly added, open/unverified.
   - Before/after summary for every substantive update and why it was needed.
   - Any contradictions resolved, sources that prevailed, outstanding gaps requiring developer input/real-device tests.
   - A concise note that the four-season marketing example is **game-specific** and match cuts are **future consideration only**.
   - Validation performed and exact results.
3. **Commit** only the Playbook and its reconciliation report (plus any directly required documentation index update) using the **next available Change number** in current Git history. Do not amend a prior commit. **Do not push.**
4. Final message: commit hash, files changed, meaningful new/updated sections, anything already covered and therefore untouched, outstanding checks, and validation results.

## 6. Acceptance criteria

The update is successful when (a) **all relevant developer-approved practices** from Changes 27–36 have been either documented or explicitly marked already present; (b) the Playbook is internally consistent and remains genuinely reusable; (c) no gameplay/code/marketing/localization assets changed; (d) uncertain or unfinished work is not mislabeled as verified; and (e) the resulting commit is reviewable and not pushed.

**Proceed autonomously, do the source audit first, and avoid asking for repeated creative approval.**
