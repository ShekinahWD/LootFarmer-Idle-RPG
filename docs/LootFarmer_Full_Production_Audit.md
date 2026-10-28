# LootFarmer — Full Production Audit & Documentation Consolidation

**Task type:** Repository-wide, evidence-based production audit; documentation edits authorized; **no gameplay, UI, scene, asset, test-logic, or build-configuration modifications in this pass**.

**Source of truth:** Claude's **current working repository**, not an attached ZIP, an older patch, or this document. Work from the repository root and inspect the actual files. Do not commit unless explicitly instructed by the developer.

**Goal:** Determine what is truly complete, what still needs correction or on-device verification, and what remains between the current project and an approved release. Consolidate project documentation and update the reusable Playbook with **verified, reusable implementation practices learned from the actual asset packs and Godot project**. Report findings and proposed remedies before changing implementation.

## 1. Authority, ground rules, and audit discipline

1. Read `docs/Reusable_Game_Development_Playbook.md` **in full** first and follow its applicable workflow, evidence, mobile UI, asset, test, save, localization, marketing, and publication rules. Examine the repository's `docs/LootFarmer_Design_README.md`, `docs/LootFarmer_GDD.md`, `docs/LootFarmer_State_Contracts.md`, `docs/LootFarmer_Content_and_Balance.md`, `docs/LootFarmer_Upgrade_Catalog.md`, `docs/LootFarmer_Prestige_Catalog.md`, `docs/LootFarmer_Asset_Registry.md`, `docs/LootFarmer_Test_Suite.md`, current numbered change reports (including Change 22 and subsequent committed changes), test files, runtime data, scripts, scenes, assets, export settings, and source-control status. Locate relevant files by repository search; paths are hints, not a substitute for discovery.
2. **Actual current implementation + latest explicitly approved decisions** govern what is shipped. Use approved GDD/catalogs for design intent, and investigate mismatches rather than arbitrarily choosing a side. Old notes, historical GDD snapshots, and previous test claims are history, not proof that current code works. Where source documents disagree, document the conflict and which approval or implementation supports the proposed resolution.
3. The developer has repeatedly played and tested Android builds, including hard resets after major changes. **Stages 1–5 currently feel well balanced to the developer.** Preserve that finding; do not restart balance design or claim that the game has not been playtested. Stages 6–8 and edge cases can still need acceptance checks. Balance changes must be evidence-driven and approved separately.
4. This is **audit-first**. Do not silently fix bugs, refactor code, optimize performance, regenerate assets, alter project settings, install dependencies, export/publish, or introduce new features. You **may edit documentation**, including the game's active design documents and reusable Playbook, as specified below. If a test can be run without modifying tracked source or user saves, run it and report the exact command, results and limits; otherwise document the verification plan.
5. Preserve `.gitignore`/project cleanliness and existing files; do not reset, overwrite developer changes, reformat unrelated documents, or create untracked generated assets. Do not use a ZIP as your baseline. Report actual repository revision/branch/worktree state to make the findings reproducible.
6. Every finding must distinguish **Verified**, **Needs correction**, **Missing**, and **Requires physical Android verification**. Use severity **P0 release blocker, P1 major, P2 polish, P3 optional**; include evidence (real file/symbol/line references and, when available, test or measurement logs), impact, remedy, acceptance criterion, and responsible phase. Never present desktop simulation as physical-phone acceptance. Separate observations from hypotheses.

## 2. Scope — full production audit

### A. GDD and content compliance

- Audit approved gameplay and content across all **eight stages** (Winter I/II, Summer I/II, Autumn I/II, Spring I/II), enemy types, bosses, unlock gates, camp travel, final boss, stage boundaries and completion.
- Audit combat/targeting, enemy behaviors, skills/status effects, player upgrades, Coins/Gems economy, equipment/merge/evolve, consumables, automation, inventory, drops, missions and Main Objectives, Prestige cards, Map Mastery, offline rewards, death/respawn, hard reset, tutorial modes and ending announcements.
- Verify progression limits, purchase gating and unlocks, UI text reflecting actual mechanics, persist/reset ownership and cards across Prestige, and whether all advertised systems have complete UI and tests.
- Cross-check approved catalogs and state contracts against current implementation; distinguish outdated documentation from actual broken behavior. Flag unreachable content, dead paths, placeholders and inconsistent terminology.

### B. Performance & stability (explicit Stage 15)

- Review `_process`/`_physics_process` hot paths, repeated allocation, full UI rebuilding, label measurement/layout loops, signal duplication, redundant polling, map/fog updates, save serialization cadence, object/sprite instancing, caches, AI/targeting queries, drops, inventory filtering/merging, sound/VFX and weather.
- Focus stress scenarios: **rainy Summer II and Spring II**, many enemies and effects, bosses with helpers, full automation and skills, large inventories, expanded Prestige/Mastery lists, frequent stage teleport, repeated modal open/close, app suspension/resume, and long play sessions.
- Record reproducible test scenes/scenarios and actual measurements **when environment allows** (frame time/FPS distribution, CPU/GPU timing, allocations/memory, worst-case spikes, rendering/draw-call hotspots, initialization/loading time). Specify hardware, resolution, Godot version, test length and build type. **Never invent device measurements.** If physical Android access is unavailable, mark phone profiling pending and provide precise steps for the developer.
- Recommend safe, localized optimizations **only when supported by evidence**. Preservation of animation, pixel-art appearance, gameplay and authoring/editability is an acceptance requirement; test before/after instead of treating less code as automatically faster.

### C. Final UI/UX, onboarding and Android usability (Stage 13 plus release polish)

- Inspect every HUD surface, panel, modal, scrolling list, contextual menu, inventory/item details, world map/camps, mission and objective lists, Prestige stage cards, Map Mastery, upgrades, skills, settings, offline claim, tutorial steps, warnings and end-of-introduction announcement.
- Examine portrait phone widths, safe areas, accessibility/tap targets, font legibility, margins, touch arbitration, scroll indicators, keyboard/back navigation, layering/z-order, player and map marker visibility, dialog stability, panel position persistence and localization expansion.
- Check Guided/Basic/None flows, time-versus-state transitions, save/reload during tutorials, arrow ownership and one-time guidance (e.g. automatic mission claiming). Do not assume any earlier flickering/timing fixes are validated on-device just because a probe passed.
- Separate **visual polish** from actual wrong functionality and prioritize player-impacting failures.

### D. Supplied assets, effects, sound and editor-friendly implementation

- Inspect the **actual** Pixel Plains unit/sprite/animation/outfit/weapon content, Kenney Fantasy UI resources and skill VFX resources **present in this repository**. Check relevant licenses/provenance in the asset registry and exported-use boundaries.
- Audit sprite import/filtering, pixel scale, animation frame/action mapping, attack impact timing, hit/death/respawn cues, VFX layering and anchoring, terrain, fog, rain and weather, UI theme consistency, audio states, and unused or missing resources.
- Confirm the Playbook's preference for **Godot-editor-editable scenes/themes/resources/animations** rather than hardcoded visual composition where practical. Cite specific validated code/scene patterns that can be reused; avoid generic claims or game-specific tuning in the reusable guide.

### E. Architecture, integrity and persistence

- Review design boundaries, simulation ownership, event/state-driven UI, duplicated state/logic, high-coupling or fragile signaling, error handling, performance tradeoffs and maintainability, without rewriting the architecture.
- Audit save/load schema and migration, survival across app kills, offline pending claims (including exactly-once semantics), clock changes, Prestige and Hard Reset behavior, permanent vs resettable fields, equipment protection from auto-merge, mission automation for purchased slots, and unusual stage transition states.
- Check Android permission/export configuration, asset inclusions, versioning, console warnings and exceptions. Keep release/debug certificates and secrets out of reports.

### F. Localization, test coverage and release readiness

- Audit English localization key integrity, `TranslationServer` integration, UI expansion readiness, font/locale assets, and the **20-language release workflow** described in the Playbook. **Do not perform translation or mark languages complete prematurely**; catalog what is ready and what awaits localization freeze.
- Inventory maintained regression suites and meaningful missing tests. Run available non-destructive suites where feasible; capture commands and results. Check tests isolate saves, clean up generated files, and cover important failures rather than only string/static assertions.
- Audit readiness for exact release artifact validation, device performance, save compatibility and Google Play compliance; distinguish existing internal testing/release setup from final production readiness.
- **Do not omit marketing:** inspect the installed/pinned Godot Marketing Capture Toolkit and readiness for approved authentic screenshots (required device classes), Play Store icon/feature graphic, the 30-second store trailer, **10 master social videos (5 focused + 5 landscape)**, per-video posting copy, English ASO and 19 localized listings, localized release notes and final Play listing validation. These are **future-production gates**, not assets to generate in this audit.

## 3. Reusable Playbook and documentation consolidation — authorized edits

Only after inspecting the implementation and records:

1. Update the **active** LootFarmer design/readme/GDD/catalog/contract/test documentation to accurately describe the current verified game and outstanding gates. Make small, purposeful edits; keep historic reports/history untouched. Preserve business model: paid once, no ads, no in-app purchases, no tracking SDKs unless a subsequent decision explicitly changes it.
2. Update `docs/Reusable_Game_Development_Playbook.md` **in the owning sections**, not by appending an ever-growing sequence of project-specific change notes. Add **validated, genuinely cross-game** practices discovered in LootFarmer: asset inventory/action-frame mapping, world/player VFX, attack/hit/death feedback, fog and map composition, Godot 4.7 UI/scroll/confirm layout, tutorial state arbitration, frame-time measurement on Android, automated testing and data persistence as supported by source and tests. Retain practical editor editability. Differentiate verified practice from pending physical-device validation. Keep per-stage prices, specific LootFarmer buffs and all exclusive project parameters in the GDD/catalogs, **not** the reusable Playbook.
3. **Approved upcoming production stage:** revise the Playbook's current **19-stage roadmap** to **20 stages**, inserting after Stage 15:
   - **Stage 16 — Demo Generation, Content Stripping & Validation.** Generate a **separate, free demo Godot project** from the approved full-game source after balance/performance gates; demo contains only Winter I/II (Stages 1–2). Stage 3–8 maps, enemy/boss identities, gear/skills, progression data, scenes, scripts and assets not required by demo gameplay must be **physically absent** from the demo's delivered build, not merely locked/hidden. Build through a **positive allowlist / dependency-verified packaging pipeline**, keep shared gameplay mechanics unchanged, give demo a separate Android package and independent save, provide an end-of-demo invitation to purchase full game, and inspect **actual final APK/AAB/PCK content** for forbidden resources and bypassable full-game unlocks. No time-based lock is required; playing/replaying the first two stages remains possible. Define tests for no inaccessible assets/content and no dead dependencies. Note that a modified demo can be altered, but cannot expose source/resources never shipped. Consider optional demo-to-paid save transfer as a **separate unapproved design decision**, not an assumed feature.
   - Renumber previous stages 16–19 to **17–20**: Play Store Preparation & Marketing Assets; Release Candidate & Final Android Validation; Google Play Publishing; Post-Launch Support.
   - Align cross-references and indexes with the renamed stages without changing unrelated instructions. **Document Stage 16 now; do not generate or implement the demo in this audit.**
4. Maintain a concise **documentation change log** within the audit output listing exactly which documents changed and which approved behavior each edit reflects. If unsure about a decision or discover a real contradiction, describe it in findings rather than silently rewriting the GDD to match suspicious code.
5. The Playbook is a repository-wide, reusable guide; do **not** claim its entire body is automatically validated merely because LootFarmer has implemented a few example systems.

## 4. Required audit deliverables

Create a clearly named audit report under `docs/`, e.g. `docs/LootFarmer_Full_Production_Audit_Report.md`, and provide a concise final chat summary. The report must include:

1. **Audit baseline:** repository branch/revision, dirty worktree state, Godot version if verifiable, documents examined, scripts/scenes/resources/tests inspected, environment/tool limits.
2. **Executive status matrix** mapped to Playbook production stages, emphasizing Stages 13–20; clearly distinguish **developer-validated early-stage balance** from stages or devices not yet validated.
3. **GDD feature matrix:** subsystem, approved behavior/source, implementation evidence, test evidence, status and issue reference.
4. **Prioritized findings ledger:** P0–P3, Verified/Needs correction/Missing/Physical Android verification, reproduction, root-cause hypothesis vs verified cause, evidence, affected files, user impact, proposed remedy and specific acceptance tests. Group by release-blocking, performance, UI/UX, asset/presentation, progression/save, localization, marketing and documentation.
5. **Performance section:** measured baseline when available; otherwise an honest **Android profiling plan**, representative stress scenes, tooling and acceptance targets to be agreed (do not invent FPS thresholds or measured gains).
6. **UI/asset review:** list of each major surface and supplied asset family with findings, including editor-editability and visual validation gaps.
7. **Regression coverage map:** executed commands, pass/fail/skipped counts, missing coverage, physical device/manual steps, evidence paths. Desktop screenshots do not establish on-device acceptance.
8. **Documentation updates:** files changed and rationale; explicit confirmation of the approved Stage 16 demo roadmap insertion and the marketing deliverables remaining in the subsequent Stage 17.
9. **Next action plan:** small approved-correction batches ordered by impact/dependencies, with acceptance criteria; clear **stop/go** recommendation for moving from audit to measured performance and final UI revision. Do not implement the action plan until separately approved.

## 5. Acceptance checklist for this audit task

- [ ] Current repository inspected directly, not assumed from a previous ZIP or patch.
- [ ] Playbook read and applied; live GDD/contracts/catalogs reconciled with actual code and recent approvals.
- [ ] Runtime/performance, final UI/UX, animations/assets, progression/save, localization, testing and store **marketing assets/videos** all covered.
- [ ] Real-device verification separated from desktop/static proof; no fabricated benchmarks or passing claims.
- [ ] Stages 1–5 balance recorded as developer-accepted so far; Stages 6–8 remain to be evaluated as needed.
- [ ] Approved demo generation **documented as Stage 16** with real content stripping and APK/AAB/PCK inspection, but demo is **not built**.
- [ ] Marketing Store screenshots, feature graphic, trailer, 10 social videos, localized listings and publication remain visible future gates.
- [ ] Reusable Playbook captures only cross-project verified Godot and asset methods, maintains editability guidance, and stays free of exclusive LootFarmer tuning.
- [ ] No gameplay/scene/source/test implementation changes, no exports/publishing, no commit; only authorized docs created/updated.
- [ ] Prioritized report with file-level evidence and implementation recommendations delivered for developer review.

**Exit criterion:** Developer can review a trustworthy, prioritized list of remaining production work and an updated, internally consistent set of active documents **before** authorizing any fixes or demo generation.
