extends Resource
## Discovery-only, unobstructed radial reveal in stage-local coordinates.
@export_enum("discovery_only") var mode: String="discovery_only"
@export_range(8,96,8) var cell_size: float=24.0
@export var player_radius: float=144.0
@export var camp_radius: float=192.0
@export_range(.05,.5,.05) var update_interval: float=.15
## Change 6 moved encounter sites: revision 2 resets saved discovery once (playbook 117.9).
@export var layout_revision: int=2
@export var cover_color: Color=Color(.035,.05,.07,1)
