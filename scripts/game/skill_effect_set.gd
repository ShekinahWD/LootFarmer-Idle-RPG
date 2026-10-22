class_name SkillEffectSet
extends Resource
## Change 14: one SkillEffectStyle per skill key (heal, focus, frost, fire, lightning, strike), plus
## "warning" for a boss's attack wind-up, "summon" on a summoner and "summon_appear" where a helper
## appears. world.gd reads it.
@export var styles: Dictionary={}
## z_index of effects drawn above actors (the Actors node is 1; fog 50 and weather 51 stay on top).
@export var above_z: int=2

## The style for a key; an unknown key gets a centred effect at its point, above the actors.
func style(key: String) -> SkillEffectStyle:
    return styles[key] if styles.has(key) else SkillEffectStyle.new()
