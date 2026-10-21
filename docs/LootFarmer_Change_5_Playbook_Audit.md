# LootFarmer — Playbook audit — Change 5

Based on the complete supplied reusable file (sections 0–137), current source and the correction evidence. This replaces Change 4’s generic applicability claims. “Retained” identifies a source pattern, not fresh exhaustive verification. “Partial” and “gate” are unfinished acceptance work. Other-game examples are not new LootFarmer requirements.

The requested faults are corrected, but full compliance is not certified. Concrete remaining implementation gaps: first-profile progression gating beyond the guide, fully editor-authored dynamic menus, updater-only panel refresh, expanded defeat diagnostics and comprehensive actionable badge coverage. Device, localization, full visual-state and natural-pacing gates remain open. No placeholder art was created to hide these gaps.

| Section | Topic | Finding / evidence boundary |
|---:|---|---|
| 0 | Canonical new-project startup flow: GDD first, then Android bootstrap | Release gate: existing Android bootstrap retained; no signed artifact or device validation in this batch. |
| 1 | Start with a deliberately small game | Retained: eight-stage scope is already approved; this patch adds corrections, not another game loop. |
| 2 | Build in checkpoints | Updated: Checkpoints records Change 5 and separates source checks from release gates. |
| 3 | Give each progression layer one job | Retained: campaign.gd separates run state, persistent keys/cards and prestige resets; campaign probes cover resets. |
| 4 | Make the campaign structure deterministic | Checked: eight authored stage scenes and stable catalog IDs; static checker loads all referenced resources. |
| 5 | Introduce archetypes one at a time | Corrected: catalog stages 1/2/3 introduce passive retaliation, individual proximity, then assistance. Skills begin late stage 2. |
| 6 | Use stage scaling and base stats separately | Retained: fixed enemy levels and authored growth; first enemy uses prototype 18 HP / 2 damage / 2 seconds. |
| 7 | Support units need percentage-aware scaling | Corrected: Heal uses 12% player and 8% enemy HP ceilings; potion burst checked across seven tiers. No support-unit subsystem. |
| 8 | Automation should be progression, not a settings toggle | Retained: automation capabilities and rate purchases remain progression-owned in catalog/simulation. |
| 9 | Automation should wait, not fail | Retained: campaign/content probes exercise unavailable automation and eligible targets; no new scheduler introduced. |
| 10 | Physical resources create stronger feedback | Retained: world pickups remain visible collectible actors; currency feedback stays immediate. |
| 11 | Secondary economy systems should use shared resources | Applicable pattern retained: coins/gems fund shared upgrades; no worker economy added. |
| 12 | Worker systems need a visible loop | Not applicable: no worker or hauling subsystem. |
| 13 | Use visual feedback for every automated action | Partial: attack/contact ownership retained; supplied VFX now below actors. All six effects not visually accepted in live dense combat. |
| 14 | Design mobile UI from the beginning | Partial: reference layout and safe-area helper retained; 450×800 render checked, physical phone required. |
| 15 | Three cards per row is a strong mobile default | Adapted: three gear identities per row; full-width mission cards prioritize progress/reward legibility. |
| 16 | Management surfaces: one job per surface, grouped by the player's mental model | Improved: mission, map, statistics and prestige surfaces use shared cards and semantic navigation; screenshots cover representative states. |
| 17 | Show current effective stats and what is boosting them | Improved: stats cards and healing details show effective role/cooldown/cap. Exhaustive boosted-state visual audit remains open. |
| 18 | Teaching: state-driven, contextual, concise and safe | Partial: tutorial_guide owns mode/state, lessons, highlights and arbitration; tests cover suspend/resume/reset. First-profile progression gates and full touch walkthrough remain open. |
| 19 | Do not shrink UI to solve positioning bugs | Checked visually: frame margins and inventory height corrected without reducing the base font to fit. |
| 20 | Modal sizing must be intentionally mobile-sized | Partial: modal layout screenshots fit portrait viewport; extreme aspect ratios and translated text need acceptance. |
| 21 | Use notification badges | Retained: enemy achievement progress entry and pickup notices; complete actionable badge audit remains open. |
| 22 | Asset workflow for pixel-art packs | Corrected: owned Kenney frames and PixelPlains icons/props; actual nine-slices matched to textures. Registry records mappings. |
| 23 | Never put an entire spritesheet in a portrait | Retained: actor/portrait atlas crops; captured cards show one character, not full sheets. |
| 24 | Avoid pixelation by respecting source resolution | Checked visually: nearest filtering retained for pixel art; no generated high-resolution replacement art. |
| 25 | Use Y-sort for battlefield actors | Checked: Actors keeps Y-sort; spell z=0 below actor container z=1. |
| 26 | Treat pause and modal state as game systems | Checked: guide respects pause, modal and confirmation ownership; simulation remains authoritative for combat/travel locks. |
| 27 | Build Hard Reset alongside every persistent system | Checked: Hard Reset clears progression/tutorial and keeps settings; old development profiles recover writable. |
| 28 | Reset run-transient worker state | Adapted: no workers; transient combat/cooldowns reset in simulation and prestige tests. |
| 29 | Save active-run state intentionally | Corrected: actual JSON disk reload preserves current actor/inventory/ID/fog/tutorial data. |
| 30 | Prevent reload exploits | Checked within scope: cooldown, offline once-only and persistent card transactions in campaign/content probes; OS interruption remains a device gate. |
| 31 | Offline rewards should reuse normal multipliers carefully | Retained: offline fixed-rate snapshot and source provenance; failure rollback probe passes. |
| 32 | Separate repeatable run rewards, first-clear rewards, and mission rewards | Retained: kill/drop, mission claim and persistent completion ownership remain separate. |
| 33 | Reward screens should be receipts | Retained: offline screen displays already credited settlement, not a second claim. |
| 34 | Snapshot mission rewards at assignment | Retained: regular mission rewards stored at assignment; cards display catalog-backed main rewards. |
| 35 | Mission difficulty and reward-currency rolls should be independent | Source retained: mission kind/target eligibility and stored rewards; natural completion-time distribution not measured. |
| 36 | Gate context-specific meta choices by content unlock | Retained: eligible cards/opportunities derive from unlocked progress; campaign/content transaction checks retained. |
| 37 | Design the post-campaign loop explicitly | Retained: final completion, persistent keys and optional prestige remain GDD-defined. |
| 38 | Avoid recursive proc systems | Retained: tagged offline/mission grants do not recursively count as online drops. |
| 39 | Define damage order | Retained: simulation owns combat resolution; no damage ordering change in this patch. |
| 40 | Number formatting belongs in one utility | Retained: NumberFormat remains shared; UI calls existing formatters. |
| 41 | Debug tools are not optional | Added: isolated change_5_probe and rendered capture fixture; no debug state enters production profile. |
| 42 | Build visual probes before final polish | Performed: eight actual Godot renders included; screenshot review corrected panel slicing. |
| 43 | Static validation checklist for AI coding | Performed: static source validator and intended-engine probe suite; counts in validation report. |
| 44 | AI collaboration and the iteration loop | Followed: user explicitly authorized code; changed-files patch on ZIP 7, with docs and evidence. |
| 45 | Avoid giant one-shot feature batches | Risk recorded: inherited campaign batch is broad; correction tests target reported faults, not an assertion of full pacing. |
| 46 | Always design the reset path at implementation time | Checked: old dev reset, Hard Reset and prestige keep/reset boundaries documented and exercised. |
| 47 | Mobile vs desktop recommendations | Partial: desktop source/render verification complete for scoped corrections; Android acceptance remains open. |
| 48 | Performance considerations for Android | Improved: fog redraw revision and minimap cadence avoid unconditional full redraw; no handset frame-time measurements. |
| 49 | Store-ready polish checklist | Release gate: store polish, 20-language acceptance and signed device package not certified. |
| 50 | Reusable architecture template for the next game | Retained: simulation/state/presentation/service split; no new project bootstrap required. |
| 51 | Recommended first-week plan for the next small game | Not applicable: initial weekly planning for a new game, not this established correction patch. |
| 52 | Centralize external/community links | Retained: shared external-link configuration unchanged; no new service destinations. |
| 53 | Persist valuable random offers before display | Retained: prestige offers and choices persisted before presentation; transaction probes cover resume. |
| 54 | Rare content needs visual identity, not only higher numbers | Corrected: boss scale 2× (final 2.5×), authored arena props and signs; bee/squirrel deliberate size exceptions. |
| 55 | Give manual play a progression path when automation exists | Retained: manual collecting/casting/merging remains useful alongside purchased automation; healing roles now separated. |
| 56 | Run a dedicated UI consistency audit before final gameplay QA | Partial: representative UI consistency renders reviewed; not every transient, locale or screen size accepted. |
| 57 | Pull volatile runtime state at the save boundary | Checked: SaveService providers snapshot live simulation; disk roundtrip added. |
| 58 | Persist unresolved rewards until consumption | Retained: pending prestige selections and mission claims use durable state; failure paths exercised. |
| 59 | Automated probes must create legitimate deterministic state | Checked: fixtures use isolated profiles and public item APIs, explicit setup, deterministic RNG; ceiling fixture labelled artificial. |
| 60 | Diagnose stale tests before changing production code | Followed: outdated schema-preservation expectations replaced with authorized reset contract, not discarded silently. |
| 61 | Save compatibility depends on the development phase | Corrected: schema 7 development reset policy; current JSON numeric IDs normalized. Production migration obligations not implied. |
| 62 | Final recommendations | Partial: reusable recommendations applied by topic; no blanket completion claim. |
| 63 | Keep an asset implementation registry | Improved: Asset Registry records frames, cards, boss props, spell layer and source-owned art; dynamic menus still partly code-built. |
| 64 | Have a confirmed ADB path for Android iteration | Device gate: no ADB-connected phone available. |
| 65 | Cap subjective AI visual iteration | Followed: bounded render correction passes; no endless art redesign or new art generation. |
| 66 | Classify authored UI assets before choosing stretch, tile, slice, or crop | Corrected: panel-000 uses 12-pixel corners; card texture has separate slices; screenshot confirms no corner stretching. |
| 67 | Prefer editor-visible artistic composition, but keep responsive rules in code | Partial: stage landmarks and info_card are editor-visible; runtime menu composition is still partly imperative. |
| 68 | Real-device validation must happen before declaring responsive UI complete | Device gate: physical phone touch/safe-area/text acceptance not performed. |
| 69 | Show combat progress truthfully | Retained: actor bars are simulation-driven, now styled with owned theme; boss hit bounds scale with art. |
| 70 | Reuse one panel family and reserve exceptions for semantic meaning | Improved: one frame family and contrasting Card variation across mission/upgrade/achievement surfaces. |
| 71 | When mimicking an asset-author reference, preserve its composition grammar rather than copying irrelevant decoration | Applicable principle: owned pixel-art frames retained; no unrelated ornaments or invented pack assets. |
| 72 | Preserve learned enemy rhythms across Elite variants | Retained: variant attack interval derives from type; first-type slower rhythm applies across its variants. |
| 73 | Use authored palette variants before tinting important progression visuals | Partial: authored actor appearances preserved; existing tier tints retained, no new palette-variant art claimed. |
| 74 | Never use double dashes in written text | Writing convention applied to current explanatory docs; command-line flags remain literal code. |
| 75 | Fractional currencies should be real values, not hidden remainder systems | Retained: fractional currency stored directly and tested through disk roundtrip. |
| 76 | Repeated UI tweens must be idempotent under rapid updates | Partial: transient stage VFX cleanup added; no exhaustive rapid-UI tween stress test. |
| 77 | Do not replace a shared utility with a partial rewrite | Followed: shared services edited locally for save/reset/audio shutdown; unrelated utility APIs retained. |
| 78 | Reuse visual language, not interaction type | Improved: progress and reward icons remain informational; claim controls stay distinct buttons. |
| 79 | Support AI should evaluate while moving, not only after arrival | Not applicable: no mobile support-unit AI. |
| 80 | Worker assignment should spread naturally before stacking | Not applicable: no worker assignment allocation. |
| 81 | Name upgrades by the resource they actually modify | Retained: upgrade names and benefit rows identify actual effects; no rename of currencies. |
| 82 | Mobile readability often requires reallocating world space, not only enlarging UI | Improved: inventory uses card-height layout and restores map space; physical readability still needs phone test. |
| 83 | Constrain decorative trajectories to believable environment boundaries | Retained: weather assets unchanged; no new particle trajectories. |
| 84 | Final mobile acceptance should precede long-form balance QA | Outstanding: finish phone acceptance before certifying long-form balance. |
| 85 | Use sparse semantic audio in automation-heavy games | Retained: semantic audio service; stop/cleanup added for shutdown. Actual device mix/density not heard in this environment. |
| 86 | Price global game-speed upgrades as compound accelerators | Not applicable: global speed has no new priced progression system in this patch. |
| 87 | Automate Play Store screenshot generation as reusable editor tooling | Deferred release workflow: in-engine QA captures added; no Play Store destination capture package claimed. |
| 88 | Test the exact release artifact before declaring the game finished | Release gate: no APK/AAB built or tested. |
| 89 | Use one source of truth for application version names | Updated: project application version 5; export codes/signing unchanged because no release is produced. |
| 90 | Float progress needs aligned display precision and completion tolerance | Retained: mission progress uses shared number formatting; full fractional-boundary UI audit remains open. |
| 91 | Mission difficulty includes player agency, not only target size | Retained: eligibility constraints prevent unavailable mission targets; measured 15–60-minute pacing remains open. |
| 92 | Rebalance reward sources and sinks as one economy | Partial: opening and heal/potion roles adjusted together; whole-economy natural playtest still required. |
| 93 | Progression-based rare rewards are easier to reason about than arbitrary random ranges | Retained: prestige eligibility and existing rarity schedules unchanged. |
| 94 | Offline rewards should be predictable enough to explain | Retained: offline rate/cap/eligible item snapshot and receipt remain explicit. |
| 95 | Release stabilization is a different mode from feature development | Not release stabilization: this is an authorized development correction batch. |
| 96 | Synchronize continuity documentation after the release candidate changes materially | Updated: current design/state/balance/asset/status docs reference Change 5; earlier evidence remains historical. |
| 97 | Turn validated human corrections into reusable specifications | Updated: reusable lessons on JSON roundtrips, slices, healing roles and conditional migration placed in owning sections. |
| 98 | Changed-files patches are not commutative | Followed: patch is based only on ZIP 7; overwrite root-relative paths; do not reapply old patches afterwards. |
| 99 | A design reversal is a cross-system migration | Corrected: skill schedule synchronized across catalog, roster, tutorial, missions and docs; old dev saves explicitly reset. |
| 100 | Prepared saves and debug presets are part of production QA tooling | Added: deterministic correction and visual fixtures; not shipped as a forced player loadout. |
| 101 | Brand from the game's authored visual language | Deferred: no branding or marketing assets requested. |
| 102 | Make defeat screens diagnostic, not merely terminal | Partial: existing death/respawn retained; no expanded diagnostic defeat report added. |
| 103 | Build terrain from connected topology, not isolated decorative sprites | Retained: baked TileMapLayers and floor topology; boss approach props augment existing clearings. |
| 104 | Animate water as one coherent system, not scattered effects | Retained: existing water art/rendering unchanged; no new water animation accepted. |
| 105 | Treat the game-specific GDD as the design authority before implementation | Followed: user corrections override old stage/skill schedule; current GDD records choices. |
| 106 | Build the GDD through a staged interview, not one giant questionnaire | Not applicable now: already-approved design and explicit code authorization, not initial GDD interview. |
| 107 | Keep reusable methodology separate from each game's design authority | Followed: numeric game balance stays in game docs; reusable file contains general lessons only. |
| 108 | End major development phases with a reusable-lesson checkpoint | Performed: lessons consolidated into owning playbook sections and checkpoint updated. |
| 109 | Store state where its lifetime already lives | Checked: tutorial and discovery stored in profile; presentation caches remain transient. |
| 110 | Make irreversible transitions one saved step, and build the exit first | Retained: claims/choices/evolution save transactions and rollback tests; no new irreversible service. |
| 111 | Simulate in state, present with events | Retained: simulation state owns combat; actor/world nodes present state and events. |
| 112 | Pacing bots find what rule probes cannot | Outstanding: no new natural-play pacing bot run. Seeded upper-bound probe does not prove pacing. |
| 113 | Godot editor and tool boundaries | Improved: authoring generator now requires explicit destructive rebuild flag to protect scene edits; runtime does not generate maps. |
| 114 | Choices with a slot budget: one control per item type, not per unit | Adapted: skill family slots use one binding per slot; no army unit cards. |
| 115 | City-builder worker economy: tasks, drop-offs, storage and construction | Not applicable: no city-building worker economy. |
| 116 | State architecture: one authoritative state, a disposable world | Checked: one simulation state, disposable actor views; saves normalize state before world presentation. |
| 117 | Navigation grid and movement | Fog corrected: resource-owned 24-unit grid, discovery-only, player/camp sources, continuous movement sampling, bounded keys. No city-builder navigation grid required. |
| 118 | Resource nodes | Not applicable: collectible drops are not worker-exploited finite resource nodes. |
| 119 | Building plots and buildings | Not applicable: camps are authored unlocks, not buildable plots/construction. |
| 120 | Worker lifecycle | Not applicable: no worker lifecycle. |
| 121 | Touch input arbitration and the map camera | Retained/partial: existing touch arbitration and camera; camera-only fog invariance tested. Physical multi-touch still unverified. |
| 122 | World picking, selection and the selection marker | Corrected: shared actor pick rectangle scales for bosses; map uses owned marker icons. Full overlapping-target touch matrix remains open. |
| 123 | Contextual information panels | Partial: shared cards added; current reconciliation still constructs temporary panel trees, so updater-only architecture is not complete. |
| 124 | HUD and assignment presentation | Improved: HUD hierarchy, semantic navigation and revision/cadence minimap updates; no worker assignment panel needed. |
| 125 | World readability and feedback techniques | Improved: layered effects, themed HP, owned markers and boss scale; dense-combat visual/audio acceptance remains open. |
| 126 | Recreating the stack: dependency order and stage gates | Partial: inherited production services retained and focused probes pass; Android stage gates remain outstanding. |
| 127 | Validation matrix | Partial: save/fog/opening/healing/tutorial/campaign probes and captures pass; OS interruption, device gesture/performance and all visual states not certified. |
| 128 | Text hierarchy and card anatomy on phones | Improved: reusable title/body/progress/reward cards with stable upgrade reason rows; translated/extreme-size cases remain open. |
| 129 | Controls and action organization | Improved: separate informational cards and action buttons, disabled reasons, tutorial mode choice. Full management edge-case audit remains open. |
| 130 | Army management: production, slots, stances and squads | Not applicable: no army production, squads, formations or support-unit pool. |
| 131 | Soft counters and combat specialization | Not applicable to this correction: no new army counter system; do not invent mechanics to satisfy an example. |
| 132 | Native localization from first implementation — English-first, 20 languages at release | Partial: new English strings use native PO keys; 19 additional release locales still outstanding. |
| 133 | Universal video generator — trailers, social and custom formats | Release gate: marketing video generator retained; no new video/social package requested or validated. |
| 134 | Google Play ASO and localized store publishing | Release gate: no Google Play publishing or ASO task authorized. |
| 135 | Reusable Godot toolkit — versioned code, not recreated per game | Retained: pinned reusable toolkit files unchanged; no replacement toolkit generated. |
| 136 | Whole-project review and design reconciliation | Performed with limits: all numbered sections receive specific disposition; remaining source/device/pacing gaps explicitly recorded. |
| 137 | Campaign migration and verification lessons | Corrected: shared travel authority retained, dev-reset exception clarified, actual JSON roundtrip added; full pacing and device release verification remain open. |

## Fog reconciliation (117.9, 124.12, 127.6)

The game GDD chooses permanent discovery-only fog; do not add temporary current-vision darkness from another game's example. Player and unlocked camps reveal within resource-owned radii. Camera pans, map opening and offline rewards never reveal. Continuous movement samples the segment; teleport reveals the destination only. Dead player sources do not reveal. Fresh spawn/restore/travel initialize discovery; inactive maps retain saved data. Layout revision invalidates incompatible discovery. Main world and both map views query the same state and bounds. Unknown markers do not expose hidden positions. Fog redraw follows discovery revision; minimap refresh is throttled. Automated evidence covers source/camera/segment/dead-player/bounds and persistence cases; real handset performance and gestures remain unverified.

## Tutorial reconciliation (18)

Guided/Overview/None selection is persisted without changing mechanics. Completed lessons derive from actual state; one controller arbitrates panel/pause/confirmation conflicts and highlights live controls. A saved incomplete guide resumes, prestige keeps completed lessons and Hard Reset restores selection. Contextual introductions explain proximity, skills and assistance. No forced purchases or free rewards were introduced. The full first-profile gate examples from other games have not been invented for LootFarmer; a concrete game-specific gate contract and complete hands-on walkthrough remain acceptance work.
