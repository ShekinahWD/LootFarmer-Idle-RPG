# LootFarmer — Checkpoints — Change 2

Current stage: prototype Change 1 exists; final GDD is open. ZIP 6 adds art/audio without gameplay changes. Signing was deferred for prototype work; release gates remain.

1. Documentation consolidation: delivered in Change 2. Current rules, evidence and open decisions are separated; old documents retained as history.
2. Finish design: confirm world counts/gates/travel/reset; review the complete upgrade catalog; author opportunity/card/combo, mission, skill and offline tables. Resolve the small state-contract gaps listed in the audit. Do not treat earlier example counts as approved content.
3. Implement final systems in focused batches after design closure and implementation authorization: shared catalog/save foundations, world progression, missions, revised prestige transactions, offline economy and skills with supplied VFX/SFX. Add targeted tests with each owning feature; keep inspector-editable scenes and central effective-value getters.
4. Balance and integration: fix the existing boss-loadout failure; validate first-prestige pacing, 15–60 minute missions, upgrade affordability, idle sessions, simultaneous spawn/skill limits and long-term progression. Verify per-type collection and reset scopes across systems.
5. Release validation: exact Godot/export-template pair; signed Android package; real-device gestures/safe areas/performance/audio/lifecycle; 20-language translation/font/layout gate; save/clock/interruption checks; reviewed asset provenance; authentic toolkit captures; clean source/export audit. Headless tests do not satisfy phone acceptance.

Every implementation handoff records its integer change, changed paths, migrations, fresh checks versus inherited evidence and remaining failures. Documentation-only batches do not advance executable/store/save versions. Never delete untracked work to clean a handoff.
