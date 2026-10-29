extends Resource
## Change 35: when the one automatic review invitation may appear (review_invitation.gd decides with
## these values; game_ui only asks it). Edit the values in resources/game/review_rules.tres.
## Used through preload (no class_name), like stage_scenes.gd.

## Saved active play (state.playtime_total: simulation steps only, so never pause, background,
## offline time, a Prestige choice or the invitation itself) before the invitation becomes pending.
@export_range(60.0,36000.0,60.0) var eligible_seconds: float=3600.0
## Seconds the world must stay continuously safe before the panel appears (no flash between attacks).
@export_range(0.5,10.0,0.5) var safe_seconds: float=2.0
## The player's current HP must be at least this fraction of max HP.
@export_range(0.0,1.0,0.05) var min_health_fraction: float=0.5
## No living boss within this many world pixels of the player (a boss arena is never a quiet moment;
## the catalog leash is 220).
@export var boss_clearance: float=280.0
