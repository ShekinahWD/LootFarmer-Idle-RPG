# LootFarmer — Current project entry point — Change 17

## Change 17 — current gameplay authority (27 October 2026)

Change 17 supersedes earlier descriptions of skill power/cooldowns, supply mastery/healing, automatic skill slots and mission rewards. It adds persistent boss countdown APIs and permanent critical upgrades, reuses the supply interval/shop systems, and optimizes rain calculations without changing authored appearance. Schema 8 saves remain compatible; existing mastery and automation purchases migrate. No UI/tutorial implementation is included.

Read [Change 17 behavior and decisions](LootFarmer_Change_17_Notes.md), [Claude integration API](LootFarmer_Change_17_Claude_Integration.md) and [validation and unresolved balance](LootFarmer_Change_17_Validation.md). The later numbered sections below are historical change records; Change 17 takes precedence where their rules differ.

Current state (2026-10-23): Change 16 on top of Change 15. Read in this order:

1. LootFarmer_GDD.md: approved behavior; the Change 16 section lists this change's rules.
2. LootFarmer_Change_16_Notes.md: what Change 16 changed, where, the per-map economy table, interpretations and open device checks.
3. LootFarmer_Upgrade_Catalog.md, LootFarmer_Content_and_Balance.md, LootFarmer_Prestige_Catalog.md: prices, balance values and Prestige content (each has a Change 16 section).
4. LootFarmer_State_Contracts.md: save records, reset matrix and transactions (Change 16 section).
5. LootFarmer_Test_Suite.md and LootFarmer_Change_16_Playbook_Audit.md: the maintained suite, test updates and Playbook compliance.
6. LootFarmer_Asset_Registry.md and Reusable_Game_Development_Playbook.md: resources and reusable methods.

Runtime: save schema 8 (unchanged by Change 16; new records default on load), fog layout revision 2. Earlier change notes and evidence folders are historical. Tuning is first-pass where marked; bot and probe measurements are not human playtests. This source handoff is not a signed Android release.

---

Historical (Change 6) entry point:

1. LootFarmer_GDD.md: approved behavior, including no teleport during combat and the Change 6 contract summary.
2. LootFarmer_Upgrade_Catalog.md: exact runtime upgrade ids, costs, caps and persistence (prices unchanged in Change 6; five labels corrected).
3. LootFarmer_Content_and_Balance.md and LootFarmer_Enemy_Roster.csv: stage content, the Change 6 enemy formula, layout rules and measured pacing.
4. LootFarmer_Prestige_Catalog.md: generated opportunity and card matrices with the Change 6 review.
5. LootFarmer_State_Contracts.md: save, migration, reset, gate and transaction rules.
6. LootFarmer_Change_6_Validation.md and LootFarmer_Change_6_Playbook_Audit.md: current evidence, coverage matrix and remaining gates.
7. LootFarmer_Asset_Registry.md and Reusable_Game_Development_Playbook.md: resources and reusable methods.
8. LootFarmer_Change_6_Apply.md: installation of the Change 6 changed files.

Runtime is Change 6 (application version 6, save schema 7, fog layout revision 2). Change 1–5 reports and history are historical evidence. Tuning remains subject to observed playtests; bot measurements are not human playtests. This source handoff is not a signed Android release.
