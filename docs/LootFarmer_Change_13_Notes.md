# LootFarmer — Change 13 Notes

Baseline: Change 12 (`2ffa8fb`, tests/docs `2e7675c`). Brief: docs/LootFarmer_Change_13_Package/LootFarmer_Change_13_Instructions.md. Before this change the repository had no Auto Evolution, no exact-identity Auto-Merge and no 12 s potion, so every item was implemented here, not just verified.

Build commits: `d2fe421` (implementation), `7a194e9` (rain and banner tuned after the rendered check), `5f64ba4` (rest of the currency sweep). **Build from `5f64ba4` or later.** The later tests/docs commit does not change the game.

## What changed

| # | Area | Change | Where |
|---|---|---|---|
| 1 | Auto-Merge by exact item | Auto-Merge covers exactly the items an enemy type drops: its loot weapon and outfit, and the base skill item of each of its skills. Evolved successors and legacy tiers follow their own droppers. Two Stone Swords evolved from Wood Swords stay unmerged until a type whose own loot holds the Stone Sword (for example the Cyan Robot) has Auto-Merge; then every owned Stone Sword merges, whatever its origin. A shared drop works through any of its droppers. Supplies are never covered. The timed merge cycle, one copy kept and the ^100 / ^500 caps are unchanged. | `sim.droppers`, `gear_group`, `can_auto_merge`; `campaign.merge_cycle` |
| 2 | Auto Evolution | A one-time unlock per enemy type, **2,000 gems on every map** (catalog `flat`), beside Auto-Merge in the type's Upgrades → Automation. Once a second, each owned weapon that a type with the unlock drops evolves once if the manual rule allows it (^100, 101 copies, a free slot for a new successor): same function, same cost, same result. It never evolves outfits, skills, supplies or the last tier, never grants Auto-Merge to the new tier, and never manages a tier its type does not drop. It waits silently when the inventory is full. Kept by Prestige (gem rule), removed by Hard Reset. Types with no evolvable weapon cannot buy it (every current type has one). | `sim.evolve_group`, `evolve_block_reason`, `evolvable_drops`; `campaign.auto_evolve`; `game_ui._enemy_panel`, `_upgrade_benefit` |
| 3 | Health Potion | Base cooldown **12 s** (was 5 s); heal still 20% → 40% of max HP. Mastery milestones keep ×0.9 / ×0.85 / ×0.8, with a **10 s floor**: 12 → 10.8 → 10.2 → 10 s. The timer, details, milestone text, auto-use, save/load and Pause all read `supply_cooldown()` (floor in `supply_cooldown_with`). | catalog `potion.supply.cooldown_floor`; `sim.supply_cooldown_with` |
| 4 | Rainy maps | Summer II and Spring II only. Rain is denser (64 streaks per 440×500 world cell, was 12) and more visible (alpha 0.62, was 0.40), still world-anchored. The map art (terrain, scenery, props) is multiplied by an overcast tint (0.77, 0.78, 0.92), measured from the supplied reference pair (dark ÷ bright average colour). Camps are restored to their own colours; actors, HP bars, loot, effects, fog and rain are never tinted. No shader and no extra draw. All values are inspector resources. | `resources/game/weather_*.tres` (`WeatherStyle`); `season_weather.gd`; `world._apply_ambient` |
| 5 | Skill prices | Automatic casting **100 / 250 / 500 gems** (slots 1–3); second skill slot **300**, third **600**. Caps, gating and Prestige permanence unchanged. | catalog; tools/change8_catalog.py kept in sync |
| 5 | Skill cooldowns | **Lightning 4 → 8 s** (the only ~4 s skill). **Fire 8 → 10 s**, so Lightning does not tie with Fire (Fire's 1.6× area hit would otherwise dominate Lightning's 1.4× single target). Frost 10, Strike 10, Focus 15 and Heal 18 are unchanged. The same values drive player and enemy casts. The cooldown upgrade (−5% per level, 6 levels, 2 s floor) is unchanged, so Lightning reaches 5.6 s. Item details now show "Cooldown: n s" for every skill, from the cast's own getter. | catalog skills; `campaign.cast` → `sim.player_upgrade_value` |
| 6 | Next-stage guidance | Under the minimap: "Next stage · Bosses 0/2" (stages 1–7) or "World clear · n/9" (Spring II), read from the same run kills and gate list as the unlock rule. Hidden on an earlier map whose exit is already open and after the world is cleared. Never takes touches. World lists each gate boss: "✓ Elephant · defeated" or "• Undiscovered boss · still needed". A discovered boss that still counts carries a gold World banner (the World button's icon) above its HP bar and on its map and minimap marker; an undiscovered one never does. The marker clears on the kill and stays off when the boss respawns. Recomputed after load, travel and Hard Reset. | `campaign.gate_status`, `gate_required`; `main.tscn Map/Gate`; `game_ui._refresh_gate`; `actor.tscn Gate`; `map_view._gate_badge` |
| 7 | Currency format | One presentation for Coins and Gems: `NumberFormat.currency(value, round_up)`. Below 100, up to two decimals; 100–999, whole amounts; from 1,000, K/M/B… with up to two decimals and no trailing zeros. Balances and rewards round down, prices and amounts still needed round up. Purchases compare exact numbers. Details below. | `number_format.gd`; `game_ui.fmt_currency`, `fmt_cost` |
| 9 | Summoned helpers | Three boss types (table below) call helpers from `resources/game/enemy_abilities.tres`. The boss telegraphs for 0.6 s with a tinted `cast` effect, then the helpers appear around it outside solid scenery, with the same effect and the pack's `summon_01` sound. Helpers copy an existing normal type of the same map (art, attack), scaled down, tinted violet, with no skills, loot, coins, XP or gems. Killing one advances nothing (no kills, achievements, missions, discovery, keys, Prestige). They dissolve when the summoner dies, leaves the fight or the player dies, when they leave their leash, and on a map change. They are never saved. At most `max_alive` live per summoner; a call waits while the cap is reached and then restarts its cooldown. Helpers never summon. | `sim.spawn_helpers`, `helper_bound`, `is_helper`, `clear_helpers`; `campaign._summon_step`; `world._summoned` |
| 10 | Final boss | The Green Alien keeps its HP, damage, gate (13 keys), drops and completion rule. In combat it now chooses an action every 11 s (plus the 0.6 s telegraph). **Below 50% HP, Heal first** whenever Heal is off its 18 s cooldown: +4% of max HP (12.2K). Otherwise it picks at random a ready skill from **Fire, Strike, Frost, Lightning** (in reach) or Focus. Each skill keeps its own cooldown. Above 50% it never heals. With nothing ready it waits 0.5 s and never stalls. It also summons (below). No Rage bar (see below). | `campaign._final_turn`, `final_choice`, `heal_first`, `heal_threshold`; `EnemyAbilityRules` |

### Summoners

| Summoner (map) | Helper type | First call | Cooldown | Per call | Max alive | Helper HP / damage |
|---|---|---|---|---|---|---|
| Grim Reaper (Autumn II) | Horned Hood | 6 s | 22 s | 2 | 2 | 50% / 40% (290 HP, 10 dmg) |
| Sunflower (Spring II) | Sprout | 8 s | 24 s | 2 | 2 | 35% / 30% (3.4K HP, 47 dmg) |
| Green Alien, final (Spring II) | Green Cap | 8 s | 20 s | 2 | 3 | 40% / 35% (2.3K HP, 40 dmg) |

The summoners are later bosses only; normal types never summon, so farming spots are not crowded. Helpers do not assist other spots: assistance is per type and variant, and helpers use their own variant.

### Rage bar: not implemented

A Rage meter would need a new rule to mean anything (for example enrage below some HP), and that would push the final fight harder on top of the new Heal phase. The fight already reads clearly: Heal plays only when it heals, with a green number; attacks are telegraphed; summons show a tinted effect on the boss and on the helpers. The brief asks not to add a decorative meter, so none was added.

### Potion floor: the formula

| | Heal per cast | Cooldown | Heal per second | Cost |
|---|---|---|---|---|
| Potion ^0 | 20% max HP | 12 s | 1.67% | one charge |
| Potion ^100 (with floor) | 40% | 10 s | 4.0% | one charge |
| Potion ^100 without floor | 40% | 9.6 s | 4.17% | one charge |
| Potion ^100 before Change 13 | 40% | 4 s | 10% | one charge |
| Heal skill | min(power, 12% max HP) | 18 s (12.6 s with 6 upgrades) | ≤ 0.67% (≤ 0.95%) | free |

The floor keeps mastery from cutting more than 2 s off the 12 s base. The potion stays the burst heal limited by stock; Heal stays the free sustain that fills the 10–12 s between potions and keeps working when the stock runs out.

## §7 currency sweep: surfaces audited and fixed

Searched: every `tr()` string with coins or gems in `localization/en.po`, every `coins`/`gems`/price/cost display path in `game_ui.gd`, `campaign.gd` progress text, `tutorial_guide.gd`, the HUD, and dynamic labels set after initialisation.

| Surface | Before | Now |
|---|---|---|
| HUD Coins / Gems | own helper; rounded half-up ("2.00K" for 1,999) | `fmt_currency` (round down): 1.99K, 5.2K |
| Upgrade buy buttons (player, enemy, map, camp radius, Auto Evolution) | currency helper, round half-up | `fmt_cost` (round up): 1.47K, 2K |
| **Camp unlock price** (World and the camp panel) | raw "Locked · 4800 coins" | "Locked · 4.8K coins" |
| Supply shop buttons (item details, Upgrades → Supplies) | raw `%d` | `fmt_cost` |
| Reroll button and confirmation | raw `%d` | `fmt_cost` |
| Enemy panel: coins and gems per kill | "×1.00" | `fmt_currency` |
| Farming Guide rewards | generic value formatter | `fmt_currency` |
| Recent finds, gem history | "+3.00" | "+3" |
| Offline receipt and rates | "120.00 coins/h" | `fmt_currency` |
| Welcome back claim panel, mission and main-objective reward chips | already `fmt_currency` | unchanged (new format) |
| Earn-coins missions progress | "1234.5 / 2400" via the count formatter | "1.23K / 2.4K" |
| Prestige Offering progress | raw "15234 / 20000 coins · 40 / 100 gems" (untranslated) | `OFFERING_PROGRESS` "15.23K / 20K coins · 40 / 100 gems" |
| Prestige offline-income milestone | "1234.5 / 10000" | "1.23K / 10K" |
| Coin/gem upgrade benefits (Coins per enemy, Gem amounts, offline rates) | generic value formatter | `fmt_currency` |
| Tutorial "N more coins needed" | `int(price − coins)` (truncated) | `currency(…, round_up)` |
| Written amounts in descriptions | "Donate 2,000 / 20,000 / 100,000 coins", "Earn 10,000 coins", "5,000 gems" | 2K / 20K / 100K / 10K / 5K |
| Teleport and travel | free (no fee) | — |
| Settings, Stats, Level panel, Prestige cards | no currency amounts (percentages only) | — |

Exact exceptions: none needed. Detailed breakdowns show percentages, not currency. The level cap "LEVEL n / 1,000" is not a currency and stays exact.

## Balance check (one fixture pass, not a campaign)

`tests/change_9_balance` (deterministic duels, one seed), final values in docs/Change_13_Evidence/balance.log:

| Duel | Change 9 | Change 13 |
|---|---|---|
| Final boss, ^300 boss outfit, 3 skills, 4 cards | win 58 s, 25% HP left | **loss at 72 s, boss at 3%** |
| Final boss, ^300, 6 cards (extra row) | — | win, 91% HP left |
| Final boss, ^400 (extra row) | — | win, 30% HP left |
| Final boss, ^500 | win | win 74 s, 60% HP left |
| Red Panda ^500 / ^300 with 6 cards | win / win | win 8% left / win 60% left |
| Bee first kill | loss (already) | loss (unchanged) |

Decomposition (same fixture, settings changed in a throwaway script): with the old skill cooldowns, the new final-boss kit at an 11 s pace still wins ^300 (18.5% HP left, against 24.9% without Heal and summons). The **requested player-skill slowdown** (Lightning 8 s, Fire 10 s) is what tips ^300 into a narrow loss. Summons made no measurable difference in that duel (boss at 3.0% with them, 3.3% without). An attack every ~3 s, the first tuning, lost by about 40%, so the pace was set to 11 s, close to the old rotation's ~11.6 s average. The final boss stays feasible with ^400, ^500 or more cards. The non-gating fixture's "^300 with 4 cards" expectation now fails by that margin, and device play decides. Change 12's Bee and Red Panda flag still applies.

## Tests

- `tests/change_13_probe` (in the maintained suite): **154 checks, 0 failures**. It covers Auto-Merge (sword and axe Wood→Stone, shared drops, outfits, skills, supplies, no evolution, stop at ^100), Auto Evolution (price on Winter I and the final map, purchase, manual prerequisites, one tier per pass, the successor's own dropper, full inventory silence, last tier and outfits, panel placement and 2K price, save/load, Prestige, Hard Reset), the potion (12 s, mastery 10.8 / 10.2 / 10, floor, use, refusal, auto-use timing, details, save/load, Pause), skills (cooldowns, prices, the 8 s cast, the details line), guidance (HUD text and placement, no touch, discovery-only markers in world and on the map, 1/2 after one kill, World lines, unlock, earlier maps, respawned boss, Spring II, load, Hard Reset), currency (13 formatter cases, HUD, camp price, exact purchase, upgrade button, Offering, offline income, coin missions, no `%d` currency strings, no unabbreviated written amounts), rain (only Summer II and Spring II, density, overcast, camps, untinted actors, world-anchored particles, clear and leaf maps unchanged), summons (three types on later maps, delay, count, scales, outside scenery, cap over 60 s, no rewards, removal, cooldown, never saved, no chains, dissolve on leave, death and map change, tint, sound) and the final boss (no heal above 50%, several pool skills, pacing, heal first below 50% with no attack warning, attacks while Heal cools down, a single heal when ready, summons ≤ 3, inert without keys, baseline unchanged).
- `tests/change_13_capture`: desktop renders in docs/Change_13_Evidence/ui/ (01 rain and overcast with the gate line and banner; 02 the same frame without the tint; 03 banner close-up; 04 World gate lines; 05 camp prices 1.6K / 4.8K; 06 Auto Evolution beside Auto-Merge; 07 Grim Reaper helpers; 08 final boss healing with helpers).
- **Maintained suite** (`python tools/run_probes.py`): one full run after the implementation, **22 / 22** once four stale contracts were updated (change_7: exact-identity Auto-Merge; change_8: 300-gem second slot; change_10: currency format in the enemy panel; change_11: potion floor). Targeted reruns followed the later fixes. `validate_campaign_source`: 1,358 checks (10 new Change 13 contracts, and change13_catalog `--check`).
- No pacing bots, soak runs or multi-seed campaigns.

## Saves

No save-schema change (schema 7) and no migration. Current saves keep loading. The only new saved value is the per-type `auto_evolve` level. Helpers are never saved. A potion cooldown saved at more than 12 s cannot happen, and an older save's running cooldown simply counts down.

## Android-only checks (not tested on a phone)

- **Rain:** visibility and clutter at zooms 1, 2 and 3; the overcast tone against the reference; legibility of enemies, HP bars, loot and fog under it; frame time on a low-end phone in Summer II and Spring II.
- **Next stage line:** fit under the minimap on narrow and tall screens and with large safe-area insets; the gold banner on bosses (2×, 2.5× scale) and on 16–24 px map markers.
- **Currency labels:** shorter amounts in buttons and cards (1.47K, 2K, 4.8K).
- **Summons:** whether the violet tint and cast effect read as "summoned" and not as a new encounter; the `summon_01` sound in the mix; frame time in a final-boss fight with helpers.
- **Balance:** the 12 s potion; Lightning 8 s and Fire 10 s; the 100 / 250 / 500 and 300 / 600 gem prices; the 2,000-gem Auto Evolution pace; the final boss (Heal at 50%, 11 s pace, three helpers) with ^300 to ^500 gear; the Grim Reaper and Sunflower with helpers.
