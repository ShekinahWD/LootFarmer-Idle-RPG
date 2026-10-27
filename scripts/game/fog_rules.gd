extends Resource
## Discovery-only, unobstructed radial reveal in stage-local coordinates.
@export_enum("discovery_only") var mode: String="discovery_only"
@export_range(8,96,8) var cell_size: float=24.0
## Permanent reveal around the walking player (explored cells, saved). Change 8 cut it to a third of
## Change 7's 144 so exploring is close to the player; sight is the separate vision radius below.
@export var player_radius: float=48.0
## Momentary sight = player_radius x vision_factor (reveal-radius upgrades and cards scale both).
## Seen terrain and enemies show and can be fought; nothing is remembered and no spot is discovered.
@export_range(1.0,4.0,.25) var vision_factor: float=2.0
## Stationary reveal around an unlocked camp (Change 7 lowered it from 192).
@export var camp_radius: float=160.0
## Camps are landmarks: sighted from this far away (remembered per stage), and this much of the
## camp's footprint is revealed so the camp shows through the fog. Enemy spots never use it.
@export var camp_sight_radius: float=400.0
@export var camp_footprint_radius: float=40.0
## Change 16: a living boss the player can see within this distance is found for good: one
## "!WARNING BOSS FOUND!" and the notification sound, the first time only (finding the Snowman opens
## Prestige). Momentary sight still decides what is visible, so this is a cap, not a reveal.
@export var boss_sight_radius: float=160.0
@export_range(.05,.5,.05) var update_interval: float=.15
## Change 15: fog cells no walking player can reveal (inside large solid scenery), per stage number,
## as "x,y" cell keys. They count neither as explored nor in the map's area, so "Map Explored: 100%"
## and Map Mastery's Explore are always reachable. Regenerate with tools/fog_reachability.gd after
## moving solid scenery; change_15_probe recomputes and compares them.
@export var unreachable_cells: Dictionary={}
## Change 6 moved encounter sites: revision 2 resets saved discovery once (playbook 117.9).
@export var layout_revision: int=2
@export var cover_color: Color=Color(.035,.05,.07,1)
## Cells in momentary sight that are not explored yet: a lighter veil over visible terrain.
@export var vision_color: Color=Color(.035,.05,.07,.5)
