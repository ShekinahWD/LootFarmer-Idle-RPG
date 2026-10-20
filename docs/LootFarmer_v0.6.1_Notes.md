# LootFarmer 0.6.1 — Farming controls, readable progress and economy

Extract over version 0.6.0 in the folder containing project.godot. Export presets and signing settings are not overwritten. Increase your Android version code for the next Play upload.

## Merge balance and automation
Potion healing now gains 0.4 HP per merge before prestige merge-card multipliers: 10 base, 10.4 at merge 1, 50 at merge 100. Previously the increment was 0.03. Existing merge levels recalculate automatically. Coin-boost percentage progression is unchanged because it uses a different stat/unit.

Gear auto-merge is purchased in each enemy type's Upgrades tab. It applies to that type's weapons and outfits, shared across all camp variants, and resets on prestige. It no longer appears in player upgrades. Consumable auto-merge stays in player upgrades with its existing persistence. Global merge-speed upgrades still adjust the shared automation interval.

Existing global gear-auto-merge ownership migrates into all four type unlocks for the current run; the obsolete global purchase is removed on load. Group gear unlocks then follow the normal prestige reset rule.

## Prices and coin rewards
General enemy-upgrade price multipliers are 1x / 2x / 3x / 4x (Sprout / Robot / Dinosaur / boss). Coin-amount upgrades have stronger independent scaling:

| Enemy type | Initial coin-upgrade cost | Growth each level | Coins added per level |
|---|---:|---:|---:|
| Sprout | 30 | 1.4x | 0.5 |
| Robot | 120 | 1.5x | 1 |
| Dinosaur | 360 | 1.6x | 1 |
| Boss | 900 | 1.7x | 1 |

Costs use ceiling after applying tier and level growth. Existing purchases keep their levels. Rewards no longer round upward to whole coins: fractions flow through rewards, balance, spending and save/load. Sprout's first coin upgrade grants exactly +0.5 before cards/temporary boosts.

The HUD, monetary costs, coin-drop inspector and general numeric stat text use the existing NumberFormat helper from the reusable playbook. Examples: 1.50, 1.25K, 2.50M. Formatting is presentation-only; it does not round stored economy values. Discrete inventory counts remain whole numbers when small.

## Presentation
Enemy upgrades now use icon cards, filled level-progress bars, current/max counts and separate currency purchase buttons. Achievement milestones use a shared Kill achievements heading, enemy icon, colored progress bar, kill count below and short reward text. Completed milestones show full bars and a completion label.

Persistent enemy-section shortcuts open Upgrades or Achievements without tapping a moving enemy. They remain visible between kills. An attack-start signal updates the type even if a one-hit enemy dies before the next UI refresh. Moving between areas updates the section; focused farming and active targets take priority.

## Validation
Godot 4.5.1 headless: farming/UI regression 29 checks, UI 24, gameplay 52 and group progression 24; all 129 assertions passed. Tests cover fractional reward credit and save/load, formatting, potion recalculation, per-type automation isolation, old unlock migration, prestige behavior, prices, instant kills and portrait card bounds. Import passed without errors.

No Android visual render was available here. Verify card appearance and shortcut placement on the phone, and playtest the steeper coin-upgrade economy.
