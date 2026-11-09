extends Resource
## Change 41: how a ground drop looks and arrives (presentation only; drop rates, positions, pickup
## rules and timers belong to the simulation and are untouched). Edited in the inspector:
## resources/game/pickup_style.tres (used through preload, no class_name). A drop is collectible from
## its first frame; the arrival plays on top of that and never delays a tap or an Auto-Collect.

@export_group("Size")
## Rendered icon size in world pixels (the larger side of the item art).
@export var gear_size:=16.0
@export var supply_size:=14.0

@export_group("Arrival")
## A new drop hops out of the defeated enemy: it rises hop_height world pixels and lands on its real
## spot over hop_seconds, growing from pop_from_scale with a small overshoot. Only drops that appear
## during play arrive this way; drops already on the ground (a load, a map change) are simply there.
@export var hop_seconds:=0.34
@export var hop_height:=11.0
@export var pop_from_scale:=0.35
@export var pop_overshoot:=1.22
## While hopping, the drop draws above the actors (the dying enemy), then returns beneath them.
@export var hop_above_actors:=true
## Supplies arrive with a lower hop than equipment, so gear stays the more noticeable drop.
@export var supply_hop_scale:=0.6

@export_group("Equipment glint")
## Weapons and outfits sit on a soft ring in their tier colour (catalog progression.tier_colors), the
## same colour as their inventory slot. Supplies have no ring.
@export var glint_radius:=Vector2(9.0,3.6)
@export var glint_alpha_min:=0.28
@export var glint_alpha_max:=0.6
@export var glint_pulse_speed:=3.2
@export var glint_width:=1.6
## The bright line is the tier colour lightened by this share, over a thin dark edge, so a dark tier
## colour still reads on sand, snow and grass.
@export var glint_lighten:=0.45
@export var glint_edge_alpha:=0.45

@export_group("Sparkle")
## The pack's 16-frame sparkle (Sparks 25x27). It plays once as a drop lands, then every
## spark_interval seconds with a phase that differs per drop, so many drops never flash in unison.
@export var spark_seconds:=1.2
@export var spark_interval:=4.0
@export var landing_spark_scale_gear:=1.35
@export var landing_spark_scale_supply:=1.0

@export_group("Idle float")
## Change 59: once landed, the icon floats gently up and down around its real spot (the icon child
## only; the drop's position, ring, sparkle and pickup radius stay put). float_height is the whole
## travel in world pixels, float_period one full cycle in seconds; each drop has its own phase from
## its uid. A freshly landed drop eases into the float over float_ease_in seconds.
@export var float_height:=2.5
@export var float_period:=1.8
@export var float_ease_in:=0.4

@export_group("Reminder hand")
## Change 59: one pointing hand at a time points at the oldest uncollected drop on screen. It shows
## from reminder_delay seconds of ground time (pausable play time, from the drop's ttl) for
## reminder_seconds, then again every reminder_interval seconds while the drop remains.
@export var reminder_delay:=10.0
@export var reminder_interval:=10.0
@export var reminder_seconds:=3.0
@export var reminder_fade:=0.15
@export var reminder_texture: Texture2D=preload("res://assets/ui/Hand.png")
## The visible (non-transparent) part of the texture and the fingertip inside it, in texture pixels.
## The hand's visible size is reminder_size_ratio times the drop's icon size (1.0 = never larger).
@export var reminder_art_rect:=Rect2(11,10,234,236)
@export var reminder_tip:=Vector2(51,12)
@export_range(0.3,1.0) var reminder_size_ratio:=1.0
## World pixels between the icon's corner and the fingertip, and a small poke toward the loot.
@export var reminder_gap:=1.0
@export var reminder_poke:=1.0
@export var reminder_poke_speed:=7.0
## Draw order: above ground loot and actors, below fog and weather.
@export var reminder_z:=3
