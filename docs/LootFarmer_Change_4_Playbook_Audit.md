# LootFarmer — Playbook applicability audit — Change 4

Reviewed against the supplied merged playbook, including fog sections 117.9, 124.12 and 127.6. Each numbered section below has an explicit disposition. **Implemented** means the applicable source pattern is present, not that every platform acceptance rule has passed. **Partial** means source work is present but visual/device evidence is outstanding. **Release gate** is not certified. **Not applicable** identifies a different game subsystem or workflow; it is not permission to omit a relevant requirement.

| Section | Topic | Disposition / evidence |
|---:|---|---|
| 0 | Canonical new-project startup flow: GDD first, then Android bootstrap | Release/startup gate: existing project preserved; phone/export/publishing evidence not available. See Change_4_Validation. |
| 1 | Start with a deliberately small game | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 2 | Build in checkpoints | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 3 | Give each progression layer one job | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 4 | Make the campaign structure deterministic | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 5 | Introduce archetypes one at a time | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 6 | Use stage scaling and base stats separately | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 7 | Support units need percentage-aware scaling | Not applicable to this campaign change: no corresponding worker/building/resource/army/social subsystem or publishing action. |
| 8 | Automation should be progression, not a settings toggle | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 9 | Automation should wait, not fail | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 10 | Physical resources create stronger feedback | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 11 | Secondary economy systems should use shared resources | Not applicable to this campaign change: no corresponding worker/building/resource/army/social subsystem or publishing action. |
| 12 | Worker systems need a visible loop | Not applicable to this campaign change: no corresponding worker/building/resource/army/social subsystem or publishing action. |
| 13 | Use visual feedback for every automated action | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 14 | Design mobile UI from the beginning | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 15 | Three cards per row is a strong mobile default | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 16 | Management surfaces: one job per surface, grouped by the player's mental model | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 17 | Show current effective stats and what is boosting them | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 18 | Teaching: state-driven, contextual, concise and safe | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 19 | Do not shrink UI to solve positioning bugs | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 20 | Modal sizing must be intentionally mobile-sized | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 21 | Use notification badges | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 22 | Asset workflow for pixel-art packs | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 23 | Never put an entire spritesheet in a portrait | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 24 | Avoid pixelation by respecting source resolution | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 25 | Use Y-sort for battlefield actors | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 26 | Treat pause and modal state as game systems | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 27 | Build Hard Reset alongside every persistent system | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 28 | Reset run-transient worker state | Not applicable to this campaign change: no corresponding worker/building/resource/army/social subsystem or publishing action. |
| 29 | Save active-run state intentionally | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 30 | Prevent reload exploits | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 31 | Offline rewards should reuse normal multipliers carefully | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 32 | Separate repeatable run rewards, first-clear rewards, and mission rewards | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 33 | Reward screens should be receipts | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 34 | Snapshot mission rewards at assignment | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 35 | Mission difficulty and reward-currency rolls should be independent | Not applicable to this campaign change: no corresponding worker/building/resource/army/social subsystem or publishing action. |
| 36 | Gate context-specific meta choices by content unlock | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 37 | Design the post-campaign loop explicitly | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 38 | Avoid recursive proc systems | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 39 | Define damage order | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 40 | Number formatting belongs in one utility | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 41 | Debug tools are not optional | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 42 | Build visual probes before final polish | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 43 | Static validation checklist for AI coding | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 44 | AI collaboration and the iteration loop | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 45 | Avoid giant one-shot feature batches | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 46 | Always design the reset path at implementation time | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 47 | Mobile vs desktop recommendations | Release/startup gate: existing project preserved; phone/export/publishing evidence not available. See Change_4_Validation. |
| 48 | Performance considerations for Android | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 49 | Store-ready polish checklist | Release/startup gate: existing project preserved; phone/export/publishing evidence not available. See Change_4_Validation. |
| 50 | Reusable architecture template for the next game | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 51 | Recommended first-week plan for the next small game | Release/startup gate: existing project preserved; phone/export/publishing evidence not available. See Change_4_Validation. |
| 52 | Centralize external/community links | Not applicable to this campaign change: no corresponding worker/building/resource/army/social subsystem or publishing action. |
| 53 | Persist valuable random offers before display | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 54 | Rare content needs visual identity, not only higher numbers | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 55 | Give manual play a progression path when automation exists | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 56 | Run a dedicated UI consistency audit before final gameplay QA | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 57 | Pull volatile runtime state at the save boundary | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 58 | Persist unresolved rewards until consumption | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 59 | Automated probes must create legitimate deterministic state | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 60 | Diagnose stale tests before changing production code | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 61 | Save compatibility depends on the development phase | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 62 | Final recommendations | Release/startup gate: existing project preserved; phone/export/publishing evidence not available. See Change_4_Validation. |
| 63 | Keep an asset implementation registry | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 64 | Have a confirmed ADB path for Android iteration | Release/startup gate: existing project preserved; phone/export/publishing evidence not available. See Change_4_Validation. |
| 65 | Cap subjective AI visual iteration | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 66 | Classify authored UI assets before choosing stretch, tile, slice, or crop | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 67 | Prefer editor-visible artistic composition, but keep responsive rules in code | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 68 | Real-device validation must happen before declaring responsive UI complete | Release/startup gate: existing project preserved; phone/export/publishing evidence not available. See Change_4_Validation. |
| 69 | Show combat progress truthfully | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 70 | Reuse one panel family and reserve exceptions for semantic meaning | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 71 | When mimicking an asset-author reference, preserve its composition grammar rather than copying irrelevant decoration | Not applicable to this campaign change: no corresponding worker/building/resource/army/social subsystem or publishing action. |
| 72 | Preserve learned enemy rhythms across Elite variants | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 73 | Use authored palette variants before tinting important progression visuals | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 74 | Never use double dashes in written text | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 75 | Fractional currencies should be real values, not hidden remainder systems | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 76 | Repeated UI tweens must be idempotent under rapid updates | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 77 | Do not replace a shared utility with a partial rewrite | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 78 | Reuse visual language, not interaction type | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 79 | Support AI should evaluate while moving, not only after arrival | Not applicable to this campaign change: no corresponding worker/building/resource/army/social subsystem or publishing action. |
| 80 | Worker assignment should spread naturally before stacking | Not applicable to this campaign change: no corresponding worker/building/resource/army/social subsystem or publishing action. |
| 81 | Name upgrades by the resource they actually modify | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 82 | Mobile readability often requires reallocating world space, not only enlarging UI | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 83 | Constrain decorative trajectories to believable environment boundaries | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 84 | Final mobile acceptance should precede long-form balance QA | Release/startup gate: existing project preserved; phone/export/publishing evidence not available. See Change_4_Validation. |
| 85 | Use sparse semantic audio in automation-heavy games | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 86 | Price global game-speed upgrades as compound accelerators | Not applicable to this campaign change: no corresponding worker/building/resource/army/social subsystem or publishing action. |
| 87 | Automate Play Store screenshot generation as reusable editor tooling | Release/startup gate: existing project preserved; phone/export/publishing evidence not available. See Change_4_Validation. |
| 88 | Test the exact release artifact before declaring the game finished | Release/startup gate: existing project preserved; phone/export/publishing evidence not available. See Change_4_Validation. |
| 89 | Use one source of truth for application version names | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 90 | Float progress needs aligned display precision and completion tolerance | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 91 | Mission difficulty includes player agency, not only target size | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 92 | Rebalance reward sources and sinks as one economy | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 93 | Progression-based rare rewards are easier to reason about than arbitrary random ranges | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 94 | Offline rewards should be predictable enough to explain | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 95 | Release stabilization is a different mode from feature development | Release/startup gate: existing project preserved; phone/export/publishing evidence not available. See Change_4_Validation. |
| 96 | Synchronize continuity documentation after the release candidate changes materially | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 97 | Turn validated human corrections into reusable specifications | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 98 | Changed-files patches are not commutative | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 99 | A design reversal is a cross-system migration | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 100 | Prepared saves and debug presets are part of production QA tooling | Release/startup gate: existing project preserved; phone/export/publishing evidence not available. See Change_4_Validation. |
| 101 | Brand from the game's authored visual language | Not applicable to this campaign change: no corresponding worker/building/resource/army/social subsystem or publishing action. |
| 102 | Make defeat screens diagnostic, not merely terminal | Not applicable to this campaign change: no corresponding worker/building/resource/army/social subsystem or publishing action. |
| 103 | Build terrain from connected topology, not isolated decorative sprites | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 104 | Animate water as one coherent system, not scattered effects | Not applicable to this campaign change: no corresponding worker/building/resource/army/social subsystem or publishing action. |
| 105 | Treat the game-specific GDD as the design authority before implementation | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 106 | Build the GDD through a staged interview, not one giant questionnaire | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 107 | Keep reusable methodology separate from each game's design authority | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 108 | End major development phases with a reusable-lesson checkpoint | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 109 | Store state where its lifetime already lives | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 110 | Make irreversible transitions one saved step, and build the exit first | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 111 | Simulate in state, present with events | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 112 | Pacing bots find what rule probes cannot | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 113 | Godot editor and tool boundaries | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 114 | Choices with a slot budget: one control per item type, not per unit | Not applicable to this campaign change: no corresponding worker/building/resource/army/social subsystem or publishing action. |
| 115 | City-builder worker economy: tasks, drop-offs, storage and construction | Not applicable to this campaign change: no corresponding worker/building/resource/army/social subsystem or publishing action. |
| 116 | State architecture: one authoritative state, a disposable world | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 117 | Navigation grid and movement | Implemented fog/state checks in campaign_probe; physical touch/path/visibility matrix remains a device gate. |
| 118 | Resource nodes | Not applicable to this campaign change: no corresponding worker/building/resource/army/social subsystem or publishing action. |
| 119 | Building plots and buildings | Not applicable to this campaign change: no corresponding worker/building/resource/army/social subsystem or publishing action. |
| 120 | Worker lifecycle | Not applicable to this campaign change: no corresponding worker/building/resource/army/social subsystem or publishing action. |
| 121 | Touch input arbitration and the map camera | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 122 | World picking, selection and the selection marker | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 123 | Contextual information panels | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 124 | HUD and assignment presentation | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 125 | World readability and feedback techniques | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 126 | Recreating the stack: dependency order and stage gates | Applicable source pattern implemented/retained. See state contracts, runtime catalog, campaign/content probes and current validation limitations. |
| 127 | Validation matrix | Implemented fog/state checks in campaign_probe; physical touch/path/visibility matrix remains a device gate. |
| 128 | Text hierarchy and card anatomy on phones | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 129 | Controls and action organization | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 130 | Army management: production, slots, stances and squads | Not applicable to this campaign change: no corresponding worker/building/resource/army/social subsystem or publishing action. |
| 131 | Soft counters and combat specialization | Not applicable to this campaign change: no corresponding worker/building/resource/army/social subsystem or publishing action. |
| 132 | Native localization from first implementation — English-first, 20 languages at release | Partial: existing native UI/scene/asset/gesture patterns retained and extended. Headless scene/routes checked; rendered visual, audio and phone acceptance pending. |
| 133 | Universal video generator — trailers, social and custom formats | Release/startup gate: existing project preserved; phone/export/publishing evidence not available. See Change_4_Validation. |
| 134 | Google Play ASO and localized store publishing | Release/startup gate: existing project preserved; phone/export/publishing evidence not available. See Change_4_Validation. |
| 135 | Reusable Godot toolkit — versioned code, not recreated per game | Pinned toolkit retained unchanged. Patch excludes caches, builds and credentials; no toolkit reimplementation. |
| 136 | Whole-project review and design reconciliation | Current docs reconcile approvals vs implementation vs evidence; legacy authority archived; remaining gates explicitly listed. |
| 137 | Campaign migration and verification lessons | Shared travel check, refund migration, loadout ceiling, per-opportunity provenance and baked scenes exercised in current probes. |

## Focused cross-system findings

- Travel is blocked by one simulation-owned query; all camp and stage actions use it.
- Selling is absent from active gameplay; migration contains only one-time refund compatibility logic.
- Fog derives from player and camps only; camera/map UI never grants discovery. Unknown actors, pickups and effects share the same disclosure check.
- The stage scenes are editor-visible TileMapLayers; actor, control, pause/save/audio/number/localization utilities reuse existing architecture.
- Evolution math is catalog-derived, never compounded from live stock/random/card totals. Shared storage capacity includes every runtime tier id.
- Claims and batched card choices are durable state transactions. Offline save failure restores both state and RNG.
- No global “all rules passed” or production-ready claim is made. Outstanding rendered/device/release checks are recorded explicitly rather than fabricated.
