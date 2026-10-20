extends "res://addons/marketing_capture/scenario_adapter.gd"
## Copy/rename into the game's OWN marketing/game_scenarios.gd.
## This is deliberately nonfunctional until save isolation + authentic
## scenarios are implemented. Never copy gameplay state between games.

func is_capture_safe() -> bool:
	# REQUIRED: verify game-specific switches/singletons prove that the game's
	# normal player save path is unused and autosaving is disabled.
	# Example for a game with a SaveService.using_test_save property:
	# return SaveService.using_test_save and not SaveService.autosave_enabled
	return false


func prepare_scenario(scenario_id: String, options: Dictionary, game_root: Node, capture: Dictionary) -> bool:
	# REQUIRED: build a deterministic AUTHENTIC gameplay situation from the
	# approved game GDD. Set camera, entity placement, and UI appropriately.
	# This must be synchronous for Movie Maker's first recorded frame.
	# For a video clip, gameplay continues at its normal fixed delta.
	# For a screenshot, capture_runner freezes gameplay after this function.
	print("Example adapter not yet implemented: ", scenario_id, " ", options, " ", game_root, " ", capture)
	return false
