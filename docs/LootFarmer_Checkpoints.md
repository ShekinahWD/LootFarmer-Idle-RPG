# LootFarmer — Checkpoint plan v0.3

Current handoff: **Change 1**, `LootFarmer_Change_1_Notes.md` and the current GDD authority. Automated checks do not replace the physical Android gate. The existing boss-loadout balance fixture still fails on both the supplied source and this update; revisit player-level/loadout targets during the next GDD balance pass.

Date: 2026-10-18. Current stage: compact CP1–CP6 source implementation complete, awaiting human gameplay/device acceptance. GDD approved; signing explicitly deferred.

Read LootFarmer_GDD.md and LootFarmer_Design_Audit.md together. The standalone Playbook remains authoritative. Do not collapse design approval, signed baseline and gameplay into one unreviewed implementation batch. GDD and implementation are now authorized. The user confirmed the prepared bootstrap in Godot and explicitly deferred signing; prototype development proceeded under that exception. No second design approval is needed.

**Current override:** signed Android export/device validation below remains the release baseline, but the user deferred it for this prototype. CP1–CP6 are implemented; acceptance evidence and remaining device/pacing checks are in `LootFarmer_Prototype_Status.md`. The original acceptance criteria below remain useful; implementation does not imply all human gates passed.

## Gate 1 — Design approval (complete)

The user explicitly approved the GDD, corrected A01–A03 and approved A04–A18. Title: LootFarmer - Idle RPG. Initial numbers remain tunable without changing behavioral contracts.

First-playable acceptance target: complete one compact run with three groups, boss/cats and prestige, then demonstrate retained automation/capacity/card and reset run-specific state. It is a smaller complete content slice, not permission to omit localization/persistence/editor-editability requirements.

## Checkpoint 0 — Clean project and signed Android baseline

1. Confirm final working game identity, target Godot patch version and portrait reference resolution. Inspect supplied starter and obtain a validated production engineering reference where needed. Never assume the blank supplied starter is already certified.
2. Transfer compatible platform configuration; remove all previous game identity and gameplay. Derive Android package from Playbook convention using the approved name. Configure stretch/safe areas, mobile rendering, touch input, audio/settings/save shells, English localization, probe paths and source-control exclusions.
3. Create the dedicated upload keystore outside the repository with the developer's local secure credentials; configure release signing without exposing passwords. Follow the Playbook Windows JDK/SDK paths only after verifying the local installation.
4. Verify matching Godot export templates, Android SDK/JDK and Android build template in that order after signing identity. Pin included Marketing Capture Toolkit 1.0.2 and check install/status; retain source with .gdignore where appropriate. No rebuilt marketing infrastructure.
5. Open clean project, validate desktop startup and export a release-signed APK. Install and test the exact APK on physical Android. Human device verification cannot be replaced by a claim from container checks.
6. Commit/archive evidence: engine/toolkit versions, package, build identifier, signing alias/path only, artifact hash, device result and known issues. No gameplay checkpoint begins before this gate passes.

## Checkpoint 1 — Core gameplay (production stage 3)

Build reusable base actor, verified animation mapping, unarmed movement/idle/attack/death; joystick override; one first-group enemy; nearest-target pursuit; stop-to-attack delay; one damage owner; enemy/player death and respawn. Author world/actor composition in editable scenes/resources.

Acceptance: manual movement cancels attack safely; 1-second delay works; chase stops at kill location; no duplicated damage/loot on simultaneous hits or cancelled animations; first enemy does not alert its group. One-shot death remains visible without remaining targetable. Initial save/pause/lifecycle support applies immediately, not only at CP5.

## Checkpoint 2 — Variety and loot (stage 4)

Three groups, individual/proximity/group-alert behaviors, leash/regeneration, upward open map, gear/consumable pickups with expiry; sword tiers/outfit visuals; equipping and shared item identity; UI slot counts and inventory capacity rejection. Contextual onboarding and English keys accompany features.

Acceptance: full inventory stacks existing identity but leaves new identity on ground; equipment is shown in its inventory slot and actor; missing asset poses have approved fallbacks; manual pickup and attack inputs do not conflict. Immediate currency credits occur once per enemy. Acquisition UI shows three recent entries, expandable to ten.

## Checkpoint 3 — Restart/debug tools (stage 5)

Complete explicit pause and confirmed Hard Reset across live/dead/paused/menu states. Add isolated developer fixtures for currencies, progression and deterministic seeds. Keep test-only controls out of release exports. Production saves and probe saves must never share a path.

Acceptance: Hard Reset from pause resets once and resumes valid state; loading fixtures does not touch a real profile. Save recovery and lifecycle regression checks are already running.

## Checkpoint 4 — Progression and automation (stage 6)

Manual merge, rerolls, selling, approved evolution, upgrades, inventory expansion, spawn selection, auto-collect, separate gear/consumable auto-merge, identity-list auto-sell with capacity upgrades, slot auto-use and group-focus return. Implement authored definitions, price tables/formulas, caps and formatting centrally. Protect equipped stock and transactional inventory transfers.

Acceptance: consuming copies never duplicates shared merge value; zero-quantity identities retain progression; cap stops consuming; evolution requires 101 source copies and output space; existing target rolls/levels persist. Verify healing at 79.9% versus 80%, stronger boost reuse, empty slots, sell/merge/collect ordering and save during purchase.

## Checkpoint 5 — Persistence/resume consolidation (stage 7)

Validate all accumulated save state, atomic writes, schema, corruption recovery, pause/background behavior, pending loot and timers. First playable has no offline simulation/rewards. Full-game offline system is a later extension at this owning stage after its design contract is approved, not accidental background farming.

Acceptance: cold restart, background during combat, empty inventory history, dead/respawning state, running boost, full inventory, pending reward, paused session. Repeated reload grants neither repeated kills nor repeated inventory transactions. Inspect second relaunch for one-time operations.

## Checkpoint 6 — Boss, completion and prestige (stage 8)

Death/cat fight, optional continued farming, persisted three-card offer, single choice, reset preview, atomic prestige and accumulating permanent bonus records. New run keeps approved automation/capacity and clears approved run state. Implement safe bootstrap values when automation is unlocked but inventory empty.

Acceptance: victory, defeat, fleeing, summon cap, boss re-kill, card-offer reload, cancellation, commit interruption and second relaunch. One prestige grants exactly one card. Complete a second run with meaningful speedup and no exponential duplication exploit.

## Cross-cutting gates for every checkpoint

- Save/reset correctness, English catalog completeness and tests accompany each feature.
- Show all 20 language options; English enabled only, Automatic forced English. Runtime IDs explicitly mapped; do not assume store tags equal Godot IDs.
- UI/actor scenes are visibly editable in Godot with safe preview data. Test a margin/texture/attachment edit survives runtime binding.
- Verify actual asset sheets and semantic contact/death timing. Prefer sparse semantic audio to sound on every farmed event.
- One consolidated issue list; fix smallest relevant batch. Smallest meaningful probe first, related tests next, whole regression once stable. Heavy simulations sequential. Treat SCRIPT ERROR as failure even on zero exit code.
- Incremental Android touch/readability/performance checks. Final exact device behavior cannot be certified by headless tests.
- Update GDD decisions and checkpoint evidence; report failures and limits candidly.

## After first playable — preserve the full lifecycle

Stage 9: approved content and offline expansion, other weapon families/consumables. Stage 10: complete onboarding/UI; stage 11: production art/animations/audio; stage 12: full feature/content freeze; stage 13: UI refinement and physical Android acceptance before long playthroughs; stage 14: full balance/softlock/endgame testing; stage 15: profiling/stability.

Localization freeze: final English catalog -> ChatGPT 19 translations -> developer copies -> import/validate/correct in mandatory 5+5+5+4 batches, report each batch before next. Enable all languages and device Automatic only after full 20-language gate. Preserve Spanish and Chinese variants and appropriate fonts/scripts.

Stage 16: use Toolkit 1.0.2 for authentic language-neutral gameplay screenshots, approved trailer and 10 portrait social masters (5 focused reframes + 5 full-landscape black-band cuts). Approve masters, then matching captions/hashtags one video at a time. No auto-post. Finalize and policy-check English Play title/short/full copy before translations; short copy sells the loop. Map Play-facing tags including uk/id/vi/th correctly and verify detected languages individually after import. One English release note approved before its translations. Private promotion/recipient data stays outside the Godot project.

Stage 17: exact release export and representative Android localization/media checks. Stage 18: one-time price and Play publishing with human approval. Stage 19: support/updates without tracking. Completing the compact prototype does not satisfy these release gates.

## v0.4.0 correction checkpoint

Implementation and headless checks complete for map/inspectors/camps/HUD/drop chances. Map tile composition inspected. Full rendered UI and Android review pending; signing still waived for prototype work. See current patch notes.


## Approved implementation revision — 0.5.0

The current interface, XP progression, stored-weapon bonuses, three-column enemy variants, worn-gear drops and schema-2 migration are specified in `LootFarmer_v0.5.0_Notes.md`. Those rules supersede earlier single-group map/UI and equipped-only stat descriptions. Test evidence is in `Progression_UI_Evidence/`. Physical-phone visual review and a complete natural run remain pending.
