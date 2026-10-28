class_name OnboardingRules
extends Resource
## Change 15 first-profile rules (Playbook 18.10): the early equipment guarantee, the same in every
## onboarding mode, and the Basic overview timing. Change 25 removed the Basic/None menu-reveal level
## backstops (those modes open every menu at once; Guided has its own staged reveal).
## Edit the values in resources/game/onboarding_rules.tres.

## Eligible normal-enemy kills (bosses and summoned helpers never count) by which the profile's first
## weapon or outfit drops, if nothing dropped naturally before.
@export_range(1,20) var first_item_kills: int=5
## Further eligible kills by which a copy that can be merged with an owned item drops.
@export_range(1,20) var copy_kills: int=5
## Change 27: bosses (catalog group ids) whose first defeat in the profile's lifetime always drops the
## weapon they carry (catalog weapon), unannounced, in every mode. A natural drop of that weapon on
## the same kill counts; later defeats use the ordinary drop chances. Hard Reset re-arms it.
@export var first_kill_weapon_bosses: PackedStringArray=PackedStringArray(["boss-snowman"])
## Basic overview: each card advances after this many seconds on screen (or on Got it / Skip).
@export_range(5.0,60.0,1.0) var card_seconds: float=20.0
## Change 16 Guided opening, "Follow the path to your left.": a Winter I point on the path that leads
## from the arrival camp to the first enemies. The guide's arrow points from the player toward it, and
## the lesson completes once the player is within path_reach of it (or after the first defeat, so a
## player who walks elsewhere is never stuck).
@export var path_target: Vector2=Vector2(300,810)
@export var path_reach: float=110.0
