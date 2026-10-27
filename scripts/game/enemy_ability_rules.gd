class_name EnemyAbilityRules
extends Resource
## Change 13 enemy abilities beyond the catalog's skill rotation (resources/game/enemy_abilities.tres):
## which types summon helpers, and how the final boss chooses between Heal, attacks and summoning.
@export var summons: Array[SummonRule]=[]
## Final boss (the catalog's `final` type). Below this share of its maximum HP Heal comes first
## whenever it is off cooldown; above it the boss never heals and attacks or summons instead.
@export_range(.1,.9,.05) var final_heal_below:=.5
## Share of the final boss's maximum HP one Heal restores (other enemies keep the catalog's 8%).
@export_range(.01,.2,.01) var final_heal_fraction:=.04
## Attack skills the final boss draws from at random (existing skills and effects only).
@export var final_attack_pool: PackedStringArray=PackedStringArray(["fire","strike","frost","lightning"])
## Seconds between two of the final boss's actions (each skill also keeps its own cooldown).
@export var final_action_gap:=11.0
## Warning before a boss skill or a summon resolves (the existing boss telegraph).
@export var telegraph:=.6
## Tint on summoned helpers so they read apart from the map's own encounters.
@export var helper_tint:=Color(.78,.66,1.0)
## Change 16: per-type skill cooldowns for enemy casts, "<type id>:<skill>" -> seconds. Every other
## enemy cast uses the catalog skill's cooldown. The Cyan Robot heals 50% more often (18 s -> 12 s).
@export var skill_cooldowns: Dictionary={}

## Seconds an enemy of this type waits after casting this skill (an override, else the catalog's).
func skill_cooldown(type_id: String,key: String,catalog_cooldown: float) -> float:
    return float(skill_cooldowns.get(type_id+":"+key,catalog_cooldown))

func summon_rule(summoner_id: String) -> SummonRule:
    for rule in summons:
        if rule!=null and rule.summoner_id==summoner_id:return rule
    return null

## The rule whose helpers copy this type (helper stats come from it), or null.
func helper_rule(helper_id: String) -> SummonRule:
    for rule in summons:
        if rule!=null and rule.helper_id==helper_id:return rule
    return null
