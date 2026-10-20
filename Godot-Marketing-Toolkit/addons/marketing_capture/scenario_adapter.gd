extends Node
## Per-game capture adapter contract. Extend this script in the game
## (res://marketing/game_scenarios.gd) and name it in the manifest's
## "adapter_script". capture_runner instantiates it beside the game's actual
## main scene. Everything game-specific lives in the extending script; this
## file and the runner never import game classes.
##
## Safety: a capture must never touch the player's save. A dedicated test
## save and no autosave are proved by is_capture_safe(), which fails closed.
##
## Timing: prepare_scenario() runs synchronously inside the runner's _ready,
## before the first rendered (and, for a video, recorded) frame. The adapter
## is a Node: per-frame staging (camera moves, scripted input, HUD
## presentation) may run from its own _process or its children's while the
## clip plays. It processes PAUSABLE: a screenshot job runs "capture_frame"
## frames of that live staging, then the runner freezes the tree and captures.

func is_capture_safe() -> bool:
	# Fail closed until each game explicitly provides save isolation.
	return false


func prepare_scenario(_scenario_id: String, _options: Dictionary, _game_root: Node, _capture: Dictionary) -> bool:
	# Synchronous. Position actual game entities, camera and UI into a
	# deterministic valid state through the game's own debug/test paths; never
	# fabricate visuals. `_capture` is the whole job (kind, size, fps,
	# capture_frame...). Return false to abort the capture.
	return false
