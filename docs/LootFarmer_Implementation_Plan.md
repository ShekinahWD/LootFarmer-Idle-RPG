# LootFarmer — Implementation and verification status — Change 17

## Change 17 — current gameplay authority (27 October 2026)

Change 17 supersedes earlier descriptions of skill power/cooldowns, supply mastery/healing, automatic skill slots and mission rewards. It adds persistent boss countdown APIs and permanent critical upgrades, reuses the supply interval/shop systems, and optimizes rain calculations without changing authored appearance. Schema 8 saves remain compatible; existing mastery and automation purchases migrate. No UI/tutorial implementation is included.

Read [Change 17 behavior and decisions](LootFarmer_Change_17_Notes.md), [Claude integration API](LootFarmer_Change_17_Claude_Integration.md) and [validation and unresolved balance](LootFarmer_Change_17_Validation.md). The later numbered sections below are historical change records; Change 17 takes precedence where their rules differ.

The user explicitly authorized code and all-game design implementation, including combat-blocked teleport and the 10→1-second automerge correction. The earlier documentation-only restriction and provisional merge-rate note are superseded.

Implemented: catalog/state normalization and authorized development reset; item surplus and 85% evolution; eight seasonal scenes, gates/camps/fog/minimap; six skills and fourth variants; regular/main missions and persistent key quest; 33 prestige opportunities/cards and 17 combos; durable batched choices; fixed offline rates and category upgrades; removal of selling; native English strings and source packaging.

Change 5 adds opening corrections, tutorial modes, healing roles, UI cards, boss landmarks, save roundtrips and fog fixes.

Current verification: see Change_5_Validation and Change_5_Playbook_Audit. Headless campaign and content probes exercise behavior and transactions. Do not interpret seeded reachability as measured player pacing.

Remaining release work: verify Android export templates; Android lifecycle, real touch gestures and safe-area sizes; dense-scene frame/audio performance; visual animation/terrain/UI review; lowest viable loadouts and natural first-prestige/economy pacing; asset-provenance closure; localization freeze/translations; signed artifact QA and marketing captures. These need their actual environment and evidence, and are not reported as completed by source tests.

Change 6 adds the full-game review implementation: encounter layout tool and boss arena relocation, enemy balance formula tool, Winter prestige gate, prestige card retune and presentation, celebration banner, guided routes with pointer, panel host rewrite (content sizing, pinned actions, in-place refresh, item browsing), notification queue and contrast, recovery roles, and the pacing bot. Verification: Change_6_Validation.
