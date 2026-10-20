# LootFarmer v0.6.3 — farming, evolution and global gems

## Install

Apply over **v0.6.2**. Close the running game, extract this ZIP directly into the project folder and overwrite. Open project.godot and allow Godot to import the updated scripts/catalog/localization. Existing saves migrate; do not hard-reset. Back up the save before testing migration. No asset deletion, signing change, APK or AAB is included.

## Player-facing changes

- Enemy Upgrades is below Achievements, aligned left.
- After unlocking farming for an enemy type, select its Outfit, Weapon or Both variant tab and enable farming there. World also offers explicit variant choices. The selected camp is where the player returns after death; only enemies of that type and variant are auto-acquired. Boss has only Both. Joystick movement cancels farming; selecting the active choice again turns it off.
- Outfits and consumables now evolve; terminal weapon chains continue too. New tiers reuse their source artwork/attack animation, use distinct inventory background colors and show their tier in item details. Seven tiers maximum. Existing Wooden → Stone → Iron transitions retain their original stats.
- Evolution still requires merge ^100 and 101 copies: spend 100 spare copies, keep one source copy and its progression, receive one next-tier copy. Need either an existing target stack or a free slot in that item's category. It never consumes stock if the target does not fit.
- A generated tier's merge-0 normal stats equal 125% of the previous tier's merge-100 normal stats, before prestige merge multipliers. Its merge increment is 125% of the prior tier's increment. Extra-stat ranges stay unchanged; an unseen target ID rolls its own extras and starts at ^0. Existing target progression remains. Example: Potion T1 heals 50 HP at ^100; Potion T2 starts at 62.5 HP and gains 0.5 HP per merge before prestige bonuses.
- Evolved potions/tonics work with manual use, cooldowns and auto-use. Evolved gear inherits its source enemy type's auto-merge unlock. Base enemies and shops continue supplying base authored items. Evolution creates the higher-tier copies.

## Global gem balance

These upgrades are now in **Player → Gems**, apply to every enemy and reset on prestige. Group achievement gem bonuses remain local to their enemy type.

| Upgrade | Per level | Level cap | Starting cost | Cost growth |
|---|---:|---:|---:|---:|
| Drop chance | +0.1 percentage point | 20 (+2 points) | 50 gems | ×1.8 |
| Amount per successful drop | +0.1 gem | 10 (+1 gem) | 100 gems | ×1.8 |

Costs round upward. Fractional gems are real saved/spendable balances, shown with the shared formatter. Base chance is min(25%, 8% × prestige gem multiplier + global upgrade bonus), followed by that enemy type's achievement bonus. Amount starts at 1 gem per successful roll.

Schema 4 refunds the exact old catalog cost of purchased per-type gem chance/amount levels and removes those old tracks; global tracks start unpurchased. The migration happens once per saved profile. Existing equipment, merge levels, achievements, coins and other upgrades remain intact. Old focused-farming selections default to Both. The new type/variant selection persists through save/load.

## Documentation

Updated GDD, Prototype Status and Asset Registry. The complete reusable playbook is included in `docs/Reusable_Game_Development_Playbook.md`; section 22.4 records Pixel Plains source/frame/attack mappings, currency crops, Kenney Fantasy UI border slicing, text filtering, stable art identity for generated tiers, retired-font dependency checks and evidence limitations. The standalone playbook has also been updated.

## Verification

Godot 4.5.1 headless, with isolated profiles (target user editor: 4.7):

| Probe | Passed |
|---|---:|
| Evolution/farming/gems | 160 |
| Audit: scrolling, pause, markers and presentation | 121 |
| Gameplay | 52 |
| Farming UI/economy | 29 |
| UI | 24 |
| Group progression | 24 |
| Inventory | 125 |
| Attack timing | 49 |
| Camera | 17 |
| Total | 601 |

Checks include all generated chains and tier caps, source art, potion/tonic use and automation, exact costs/refunds, JSON save round-trip, no duplicate refund, fractional rewards, variant filtering/return after death, no evolution spending on full inventory, global upgrade scope and prestige reset. Existing probes were updated only where the intended structure/schema changed: six enemy upgrades instead of eight, schema 4 instead of 3. Editor import has no script errors.

No GPU/physical-phone visual acceptance or Android export was performed here. Check the stacked shortcuts, new player Gems tab, tier colors, long item names and farming choices on your phone before publishing the next internal-test build.

Run the new probe from the project folder:

    godot --headless --path . res://tests/evolution_farming_probe.tscn -- --profile=probe-evolution063 --no-autosave
