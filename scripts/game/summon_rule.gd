class_name SummonRule
extends Resource
## Change 13: one enemy type that calls helpers (resources/game/enemy_abilities.tres). Helpers are
## copies of an existing normal type, drawn with its own art, that fight next to the summoner and
## give no rewards of any kind. They dissolve when the summoner dies, stops fighting or leaves.
## Stable catalog id of the summoning type (e.g. "boss-grim-reaper").
@export var summoner_id:=""
## Stable catalog id of the normal type whose look and attacks the helpers copy.
@export var helper_id:=""
## Seconds after the summoner starts fighting before its first call.
@export var first_delay:=6.0
## Seconds between calls.
@export var cooldown:=22.0
## Helpers created by one call (never more than max_alive living at once).
@export_range(1,4) var per_cast:=2
## Living helpers per summoner; a call waits while this many are alive.
@export_range(1,4) var max_alive:=2
## Helper HP and damage as a share of the copied type's normal values.
@export_range(.05,1.0,.05) var hp_scale:=.5
@export_range(.05,1.0,.025) var damage_scale:=.4
## Helpers appear on a ring this far from the summoner.
@export var spawn_radius:=34.0
