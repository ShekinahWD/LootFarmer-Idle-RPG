# LootFarmer Change 4 — Campaign implementation

This cumulative source update implements the approved eight-stage seasonal game, shared fogged map and camp reveal, combat-blocked teleport, skills and elite variants, missions, persistent boss-key final quest, unique prestige paths/cards/sets, and fixed offline rewards.

Items retain spare-copy growth at ^100; evolution starts at 85% intrinsic source power. Gear/skill automerge now upgrades from 10 to 1 second. Selling is removed; migration refunds its old purchases once while preserving inventory. Map and automation upgrades use scope checks and shared effective-value getters. The final boss growth curve was corrected to stay within the authored item ceiling.

Current rule tests: 260 campaign checks + 656 content checks, zero failures. Static source/resource checks: 1,772, zero failures. Evidence and the reusable playbook audit are included. Device/render/audio/pacing/release acceptance remains explicitly open in Change_4_Validation; the available headless engine was 4.6, while the project declares 4.7.

Extract at the existing project root as described in Change_4_Apply. No generated caches, player saves, credentials or raw asset bundle copies are included.
