class_name MasteryRules
extends Resource
## Change 15 Map Mastery: what completes each map and the permanent rewards. Every map has the same
## five categories (Explore, Hunt, Research, Collect, Forge), derived from the catalog; only the
## thresholds and rewards live here. Edit the values in resources/game/mastery_rules.tres.

## Forge: a normal enemy's outfit must reach this merge level once (any run).
@export var normal_outfit_merge: int=25
## Forge: a boss outfit must reach this merge level once (any run).
@export var boss_outfit_merge: int=5
## Hunt: the kill-achievement milestone every type of the map must reach (2 = the second milestone:
## 100 kills for a normal type, 3 for a boss), counted from lifetime kills.
@export_range(1,8) var hunt_milestone: int=2
## Permanent rewards for mastering each map, in map order (Winter I first). Keys are the same bonus
## keys as Prestige cards (campaign.bonus): hp, damage, coins, xp, gear_chance and gem_chance.
## Percentages are fractions (0.1 = +10%); gear_chance and gem_chance are percentage points.
@export var map_rewards: Array[Dictionary]=[]
## Added once all eight maps are mastered (100% game completion), with the Master Farmer title.
@export var completion_reward: Dictionary={}
