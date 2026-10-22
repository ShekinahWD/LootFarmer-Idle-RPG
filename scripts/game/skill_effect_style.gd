class_name SkillEffectStyle
extends Resource
## Change 14: where and how one skill's effect sheet (magic-spells-vfx-lite, 64 px frames) is drawn.
## Lives in resources/game/skill_effects.tres; the same entry serves player and enemy casts.
## Anchor: "target" the hit actor's feet (single-target strikes), "point" the cast's world point (an
## area's centre), "caster" a child of the caster's view (self effects follow the caster),
## "caster_ground" the caster's feet, fixed in the world (an area around the caster).
@export_enum("target","point","caster","caster_ground") var anchor: String="point"
## Row of the 64 px frame that sits on the anchor: 53 for the zap's ground ring, 52 for the self
## rings, 32 for a centred burst.
@export_range(0.0,64.0,0.5) var contact_y: float=32.0
## World pixels above the anchor's feet where the contact row goes, per unit of actor scale
## (10 is the middle of a 24 px body).
@export var lift: float=0.0
@export var scale: float=1.0
## Scale (and lift) with the anchored actor's rendered size: bosses draw at visual_scale 2 to 2.5.
@export var scale_with_actor: bool=true
## Above every actor (a bolt or blast striking the body) or on the ground beneath them.
@export var above_actors: bool=true
@export var tint: Color=Color.WHITE
