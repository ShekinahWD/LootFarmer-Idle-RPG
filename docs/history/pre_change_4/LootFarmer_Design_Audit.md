# LootFarmer — Design reconciliation audit — Change 3

This is a documentation/source reconciliation, not a fresh gameplay audit. Inherited Change 2 audit and its source findings are retained under history/pre_change_3. Current source: ZIP 6, Change 2 documentation, supplied fog playbook, seasonal source index and subsequent explicit user decisions.

## Resolved design areas

Eight stages (34 normal types, 14 bosses), 4/6/7 double-boss gates, final boss with 13 persistent keys, safe camps/free travel, stage fog/intelligence/radius upgrades, reviewed upgrade ownership/currency/reset, 3–8 mission slots, fixed offline rates, six skills by Stage 4, fourth equipped+skill variants, boss skill-roll rule, no selling, ^100 spare-stock bonus, 85% evolution baseline. All are in the current GDD; conflicting older notes are archived.

## Implementation gaps

Runtime remains compact Change 1. Implement all final-world maps/gates/camps/fog, skills, missions, revised prestige, offline economy, stored outfit contribution, quantity/evolution redesign, sell removal and reviewed upgrade changes. Art presence does not mean integration. The pre-existing boss-loadout failure remains uncorrected. Historical headless results are not current Android acceptance.

## Remaining approval / authoring / release work

- Gear/skill auto-merge frequency purchase was not explicitly approved after selling was removed. Keep it provisional, not a blocker to documenting or implementing unrelated approved systems.
- Exact equipment art ids, visual weapon pairings and new-profile capacities require implementation inspection; roster body-sheet sources are verified separately. Higher skill tiers remain evolution-only.
- All new prices, level/stat formulas, card values, goals, map sizes and offline rates are delegated baseline tuning, require reachability and device playtests; no claim of economy completion.
- Latest approvals override previous examples: mission slots max 8, movement max +100%, permanent keys, no auto-sell (including offline), independent fourth-variant item rolls, one boss skill roll.
- Preserve licensing follow-ups for PixelPlains and generic audio. Preserve original spell licenses; this patch contains no assets.
- Source ZIP 6 contains generated caches and export-credential metadata. This patch includes documentation only; it does not delete those user files or read credential values.

## Evidence ownership

Current documentation validation is recorded in Change_3_Validation. Change_1_Evidence remains inherited. No Godot execution, audio listening, full animation playback, physical phone, signing or runtime migration has been tested in this documentation batch. Use Playbook 136 and Implementation Plan for honest follow-through.
