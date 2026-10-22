# LootFarmer — Change 14 Playbook Compliance Audit

Date: 2026-10-22. Scope: the eight Change 14 corrections, checked against `docs/Reusable_Game_Development_Playbook.md` as it is in the repository. This audit covers only the rules these changes touch; it is not a whole-game audit (see the Change 13 audit for that). Desktop and headless checks cannot prove phone layout, colour or feel; those items are in the last column.

Evidence keys:

- **P14:** `tests/change_14_probe` (202 checks).
- **CAP:** `tests/change_14_capture` (desktop renders in `docs/Change_14_Evidence/ui/`).
- **SUITE:** `python tools/run_probes.py` (23 / 23).

| # | Playbook rule | Status | Evidence | Android-only |
|---|---|---|---|---|
| 1 | §14 / §19.1 mobile HUD: a new element gets its own region; safe area; no shrinking | Compliant | The map facts form one top-right cluster inside the `Safe` margin container: zoom, Map Explored, minimap, Next Stage. No accepted control was resized or moved, except that the minimap shifted down 34 px to make room. P14 checks the order, that nothing overlaps (the cluster, the joystick, the enemy buttons, History, the follower), no-touch, and a 60 / 40 px inset. | Fit on narrow screens; the 277 px Next Stage chip beside the enemy name |
| 2 | §124 / §125.8 readable HUD text | Compliant | `HudChip` / `HudChipLabel` use the theme's existing Kenney backing panel at 86% dark, with 18–19 px text. P14 measures 10:1 to 17:1 contrast over snow, grass, sand and dirt. CAP 01–04. | Arm's-length legibility |
| 3 | §21 badges: one look per meaning, ready versus afford | **Fixed** | The badge reads `campaign.has_claimable()`, the same rule as the listed Claim buttons. Purchases never light it. P14 runs the matrix: fresh, ready objective beyond three, claim, unlisted final, daily, waiting, auto-claim on/off, Hard Reset. | — |
| 4 | §138.3 ambient particles belong to the world | Compliant (extended) | The splash phase is frozen at the impact time and stays a pure function of the clock and grid. P14: 7,813 splash steps with 0 slides; pan and zoom leave every particle in place. | Zoom 1–3 look |
| 5 | §13.2 / §138.4 / §142.1 one authoritative contact; effects anchored to the art; telegraphs announce, they do not duplicate | **Fixed** | `skill_effects.tres` places each effect by its contact row, lift, scale and layer. A single-target strike plays on the actor it hit. Wind-ups emit `skill_warning` (a small marker, no sound), and the hit plays once. P14 covers the player on a normal enemy and a 2× boss, an enemy's and a boss's Lightning on the player, the boss Heal, and Heal/Focus on the caster. CAP 05–10. | Readability of Lightning and the warning marker; effects over HP bars |
| 6 | §63.1 / §67 inspector-editable presentation | Compliant (improved) | New resources and nodes: `skill_effects.tres` (`SkillEffectSet` / `SkillEffectStyle`), `WeatherStyle.splash_frame`, the `HudChip` theme styles, the joystick's Backplate / Rim node modulates. The self-effect exports in `world.gd` moved into the resource with the same values. | — |
| 7 | §129.5 one edit rule for every surface that edits the same thing | Compliant | Reveal Stats / Reveal Drops on both tabs call the same `_group_upgrade_card` → `sim.buy_upgrade`. P14: one charge, Max on Upgrades, the info on Overview, refusal on re-buy, Farming Guide count. CAP 11. | — |
| 8 | §14.3 / §121 touch input unchanged | Compliant | Joystick anchors, offsets, size, radius and input code are unchanged. Every new layer is `MOUSE_FILTER_IGNORE`. P14 drags to the edge and releases. | Thumb feel unchanged |
| 9 | §18.1 / §18.5 / §18.8 teaching: once, decided in state, on the existing carrier, arbitrated, no input | Compliant | The first purchase writes `focus_unlocked` (saved, kept by Prestige, cleared by Hard Reset). The hint is session-only and uses the guide's pointer, frame and caption with Got it. The step declares its surfaces, and other panels suspend it. It points only at enabled, visible controls and ignores input. It ends on Farm on, Got it, 45 s or another map. "None" gets the confirmation only. P14 covers every path; CAP 12–13. | Whether players understand the arrow and line |
| 10 | §61.1 pre-release saves | Compliant | No schema change or migration. The only new saved value is a seen string. | — |
| 11 | §60.1 layered testing | Compliant | Essential smoke runs before the build commit, one focused probe, one full suite run and one capture run, all sequential. No pacing, soak or balance runs: no combat values changed. | — |
| 12 | §74 no double dashes in written text | Compliant | The new `en.po` strings and the Change 14 docs contain none. | — |
| 13 | §22 / §63 asset reuse | Compliant | No new art or audio. Reused: the Kenney panel-000 (chips) and panel-014 (backplate, rim), the magic-spells cast sheet (wind-up marker), and the existing rain sheet frames. | — |

## Android checklist

1. Map Explored and Next Stage chips readable on Winter snow, Summer II and Spring II rain, Autumn and fog; the Next Stage chip does not crowd the enemy name on narrow phones.
2. After claiming every Missions reward, the `!` disappears; it reappears for a new manual claim.
3. Rain splashes stay in place at zooms 1–3.
4. Lightning visibly strikes the target (normal enemy and boss, player and enemy casts); the orange wind-up marker reads as a warning.
5. The joystick is easy to find on snow and in rain, without dominating the view.
6. After the first Focused Farming purchase, the arrow leads to Farm and the line explains it; nothing stays on screen afterwards.
