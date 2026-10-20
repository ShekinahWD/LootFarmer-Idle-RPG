# LootFarmer 0.6.0 — Enemy-type progression

Apply this changed-files ZIP over 0.5.5 in the folder containing project.godot. Signing/export presets are not changed. Increase the Android version code before uploading a new AAB. Back up your save before testing migration.

## Enemy-type upgrades
All outfit-only, weapon-only and combined camps share their enemy type's purchases and achievements. The boss has its own progression. Summoned cats have no upgrades, achievements or rewards.

The enemy panel's Upgrades tab now contains:
- Focused farming: 25 gems, one level per enemy type. Unlocking Sprout does not unlock Robot, Dinosaur or the boss. Once unlocked, selection is available in that enemy panel and World. Joystick movement cancels farming selection as before.
- Gear drop chance: +1 percentage point per level, 15 levels. Without prestige cards the maximums are Sprout 25%, Robot 24%, Dinosaur 23%, boss 45%. The upgrade bonus is added after the prestige-card-modified base, so its contribution never exceeds +15 points. Existing gear-upgrade levels remain at the same level with the new +1-point effect.
- Consumable drop chance: separate +1 percentage point per level, 15 levels. Each eligible consumable roll receives the bonus: potion 10% to 25%; tonic 2.5% to 17.5%. Sprout still cannot drop tonic. Rolls remain independent.
- XP earned: +10% per level, 20 levels, maximum +200% (3x base XP). Variant XP differences remain.
- Existing coin/gem amount and gem-chance upgrades remain per enemy type.

Drop upgrades cost 20 coins initially, growing x1.35 per level. XP costs 25 coins initially, growing x1.4. These are initial tuning values in data/game/catalog.json.

ALL purchased group upgrades reset at prestige, including focused farming and the stats/drop-information reveals. Existing global automation/capacity upgrades retain their prior persistence rules.

## Permanent achievements
Kills are accumulated separately for Sprout, Robot, Dinosaur and boss, across camp variants and prestige runs. Milestones award bonuses automatically; no claim button or currency cost.

Regular enemy milestones: 25, 100, 250, 500, 1,000, 2,500, 5,000 and 10,000 kills.
Boss milestones: 1, 3, 10, 25, 50, 100, 250 and 500 kills.
Each milestone grants +5% damage against that type and +0.5 percentage points gem drop chance from that type. Eight milestones total +40% damage and +4 points gem chance. Achievement gem chance is added after the existing 25% farming/card cap, allowing up to 29%. No other enemy type receives the bonus.

The enemy panel has an Achievements tab with progress, completed milestones and bonuses. During combat, a compact group progress button opens the corresponding details. Counts and rewards survive prestige and save/load; hard reset clears them.

## Save migration
Schema 3 migrates schema 1/2 saves automatically. Existing currency, items, group purchases and other progress are preserved. Previous global focused-farming ownership becomes a per-type unlock for all four types for the current run, then resets at prestige. Historical kill counts were not tracked; achievement counts therefore begin at zero. Invalid achievement state is rejected by save validation.

## Validation
Godot 4.5.1 headless: group progression 24 checks, inspector 32, gameplay 52, progression/layout 88 and UI 24. All 220 assertions passed. Coverage includes local bonus isolation, caps and rejected purchases, real damage contact, shared camp kills, schema-2 migration, prestige save/persistence and UI navigation. Android visual and long-run economy balance testing remain outstanding.
