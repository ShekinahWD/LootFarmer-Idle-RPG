class_name OnboardingRules
extends Resource
## Change 15 first-profile progression (Playbook 18.10): the early equipment guarantee and the menu
## reveal backstops. The same rules apply in every onboarding mode; the mode only changes how much
## the guide explains. Edit the values in resources/game/onboarding_rules.tres.

## Eligible normal-enemy kills (bosses and summoned helpers never count) by which the profile's first
## weapon or outfit drops, if nothing dropped naturally before.
@export_range(1,20) var first_item_kills: int=5
## Further eligible kills by which a copy that can be merged with an owned item drops.
@export_range(1,20) var copy_kills: int=5
## Player levels that reveal a feature even when its demonstrated action has not happened, so the
## reveal chain never stalls for a player who ignores a new menu (never a timer).
@export var missions_level: int=3
@export var enemy_level: int=4
@export var world_level: int=5
@export var upgrades_level: int=6
@export var objective_level: int=7
## Basic guidance: a feature card or tip retires after this many seconds on screen (or on Got it).
@export_range(5.0,60.0,1.0) var card_seconds: float=20.0
