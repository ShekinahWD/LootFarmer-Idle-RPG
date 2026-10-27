# LootFarmer — Change 17: Gameplay and systems

Baseline: `lootFarmer(20261027-123702).zip` (27 October 2026). Apply this patch to that snapshot, not the earlier 04:26 upload. Project version and Android version code were already 17 and are unchanged. No commits. No interface, tutorial, navigation, art, or scene redesign.

## Implemented behavior

1. **Boss countdowns:** one saved record per boss actor, with stage, group, remaining seconds and authored home coordinates. All maps advance together in active, unpaused simulation time. On restart/background resume, elapsed wall time advances the timers once. Negative elapsed time contributes zero. Inactive normal enemies and ground loot still freeze. A boss whose timer expired away respawns on the first simulation step after returning. Old dead-actor timers migrate. Prestige clears run timers; Hard Reset clears everything.
2. **Boss Gems:** investigation confirmed the existing 5% shared base was correct. Preserve it, Gem Chance, achievement/Card/Mastery bonuses and Boss Gem Chance; `gem_chance(group)` remains the authoritative total, clamped to 0–100%. Covered for every enemy type.
3. **Critical Chance:** `critical_chance`, +1 percentage point ×20 levels; ceil(250 ×1.5^level) Gems. Adds once through stat sources; existing total cap 75%.
4. **Critical Damage:** `critical_damage`, +5 percentage points ×20; ceil(200 ×1.5^level) Gems. Existing total multiplier cap 4×. Both upgrades survive Prestige.
5. **Healing:** player Heal and the Health Potion work at any HP below maximum, outside combat as well as during combat. Their automatic paths use the same actions and cooldown/inventory checks. Full health or death cannot consume them. Recovery Salve keeps its distinct 90% manual / 60% automatic thresholds; enemy Heal thresholds are unchanged.
6. **Automatic supplies:** first `auto_use` purchase costs 100 Gems. Existing cap (3 automatic supply slots), ×2.6 price growth and permanence remain.
7. **Automatic skills:** buy capacity (`skill_auto_slots`) for 100 / 250 / 500 Gems; assign any equipped slot, not a predetermined position. Atomic assignment validates unique zero-based indices, equipped/unlocked slots and purchased capacity. Saved legacy unlocks convert once into the same number of capacity units. Existing selected positions are retained within capacity. Positions are bindings, so replacing the skill there changes what is automated; empty positions are dormant (including after Prestige). Old purchase IDs route to the pooled purchase for compatibility, but old UI toggles are not the new selection interface.
8. **Supply mastery:** each supply has its own successful-use counter. Every five uses grant one mastery level, cap 100. Drop, shop, offline receipt, discard and pickup grant none. Existing earned mastery migrates to fixed credit; new uses accumulate on top without granting the collected-copy bonus again. Credit and use remainder survive Prestige. Effects/cooldowns use pre-use mastery; the fifth use earns the level for subsequent uses.
9. **Supply interval:** reuse `use_speed`, avoiding a duplicate track. It now costs Gems, starts at 100, keeps ×1.6 cost growth and 8 levels of −1 second (10 → 2 seconds). Existing bought levels are kept without refund or extra charge. This is the automation polling interval, not a bypass of the potion's 12-second cooldown / 10-second mastery floor.
10. **Supply shop:** reuse `purchase_consumable`: Potion 100, Coin Tonic 200, Guard Tonic 300, Recovery Salve 400, Wisdom Tonic 500 Coins. Fixed prices, inventory/payment validation unchanged. No new stage purchase gate. UI additions belong to Claude.
11. **Skill cooldowns:** all six catalog base cooldowns are 20 seconds. Existing family reductions remain −5% ×6 (14 seconds at max). Existing enemy-specific Cyan Robot Heal override remains 12 seconds; it is not a player/global skill cooldown.
12. **Skill power:** requested ^0 → ^500 family curves, including all legacy tiers. The existing logarithmic effective merge curve determines intermediate values. Merge Wisdom accelerates progress along this curve, capped at the endpoint. Skill-strength bonuses apply afterward; Heal caps at 30% max HP. Fire caps at 3× current damage after skill, Focus and target bonuses, before defense, with a final damage ceiling so minimum-damage rounding cannot exceed it. Skill surplus stock and legacy tier multipliers cannot inflate this family curve. Owned legacy identities, quantities and merges remain loadable. Weapon/outfit progression is untouched. Enemy skill power definitions remain separate; enemies have no player merge levels.
13. **Lightning:** same single target and reach; player Lightning reduces that enemy's basic attack rate to 50% for 3 seconds, or 1.5 for bosses. Cooldown and pending windup advance at that rate; partial expiry is accounted for. Movement is unchanged. Enemy Lightning has not gained an unrequested new player debuff.
14. **Boss statuses:** `status_duration` / `apply_timed_status` centralize the 50% boss duration rule. Frost, Lightning and Focus use it; strength and damage are unchanged by resistance. This includes the boss's own timed Focus buff. Future timed effects must use the same entry point.
15. **Mission Coins:** 40 normal-enemy kills for regular missions, 80 for boss missions. Income is the arithmetic mean of current normal-enemy Coin payouts at the highest-ever unlocked stage, including their Coin upgrades, active Coin Tonic and existing Coin bonuses. Mission Coin bonuses apply once afterward. All regular mission kinds receive this Coin reward; main objectives are unchanged.
16. **Mission Gems:** preserve base rewards (kill 0, boss/coins 5, gear/merge/cast 3), then multiply by [1,2,3,5,8,12,18,25] and Mission Gem bonuses once. A persistent `reward_stage` survives Prestige; access/gate kills still reset. Existing visited maps provide migration evidence. Rewards refresh from immutable base data while unclaimed and immediately before claiming; displayed compatibility fields are never multiplied again. Claim still uses the existing atomic save/rollback path.
17. **Rain investigation:** repeated grid-cell particle math, per-particle temporary arrays and repeated visibility bonus calculation were found. Pattern buffers now calculate the same particle/frame data once per index per frame, production drawing streams them directly, and visibility inputs are captured once per draw. Density, texture, size, opacity, timing, drift, splash anchoring, tint and draw order are unchanged. A dry-stage transition explicitly clears prior draw commands. See the validation report for measured CPU results and physical-device limits.

## Skill endpoints (before skill-strength/target bonuses)

| Skill | ^0 | ^500 |
|---|---:|---:|
| Heal | 10% maximum HP | 30% maximum HP |
| Frost Burst | 0.5× damage | 2× damage |
| Fire Burst | 0.75× damage | 3× damage, effective hard cap |
| Lightning Strike | 1.25× damage | 5× damage |
| Arcane Focus | +10% damage | +50% damage |
| Arcane Strike | 2× damage | 8× damage |

`progression.change17` in `data/game/catalog.json` owns the curve endpoints, end level, status rules, supply timing floor/mastery divisor and mission scaling. Upgrade definitions and supply prices remain in their existing catalog sections. `normal(skill).power` returns HP for Heal (compatible with its existing consumer); `skill_base_power` returns Heal's fraction. Use `skill_power` for actual casts, not raw legacy `items[id].normal` values.

## Decisions and limits

- The mastery source and old fixed auto-skill purchase model conflicted with this brief and were explicitly replaced, with compatibility handling rather than a schema reset. Schema remains 8, outer container version 2.
- Price schedules and 40/80 mission kill equivalents fill the choices left open by the brief. They are authored balance decisions, not claims of device playtest approval.
- A separate late-game benchmark has unresolved victory targets. Do not retune enemies or silently raise skills to make old benchmarks green; see validation report for baseline comparisons. These fixtures omit the new critical upgrades and use ^50 skills; they do not prove the game is unbeatable.
- Android CPU/GPU frame-time and visual acceptance remain developer device checks. Desktop/headless results cannot establish the cause of the reported phone slowdown.
- The interface is deliberately incomplete for the new APIs. Old descriptions still mention 80% Heal eligibility and collection-based mastery, and old auto-skill controls still describe fixed slots. Claude must integrate the handoff before release.
