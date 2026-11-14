extends RefCounted
## The game-capability / intent contract (player-profiles.contract/1). A game's adapter extends this file
## (or implements the same methods) and maps the game's LEGITIMATE player actions onto generic intents.
## Defaults declare everything unsupported, so a minimal adapter is honest by construction.
##
## Three groups of methods, kept strictly apart:
##  1. POLICY-FACING (what a player could perceive): observe(), options(), and the action entry points
##     begin() / advance() / cancel() / steer(). The decision engine reads ONLY these.
##  2. SIMULATION/SESSION plumbing for the driver: step(), set_clock(), sessions, failure checks.
##  3. PRIVILEGED TELEMETRY for reports only: progress_signature(), trace_sample(), game_summary(),
##     generic_metrics(), state_digest(). The engine never reads them.
##
## OPTION (one Dictionary per thing the player could do now; return them from options()):
##   id            String   unique and stable within one call (also the default family)
##   intent        String   one of Framework.INTENTS
##   kind          String   "instant" (one transaction: buy, claim, toggle) or "activity" (ongoing: farm, explore, attempt)
##   label         String   human text for logs
##   feature       String   the game system it uses (familiarity/learning key), e.g. "shop", "boss", "travel"
##   family        String   cooldown/caution key shared by similar options (default: id)
##   eligible      bool     false when the game would refuse it now; then `block` says why (the game's own reason)
##   block         String
##   cost          {resource: amount}   optional; the first key is the resource it competes for
##   affordable    bool     default true
##   shortfall     float    0..1, how far from affordable (1 - holdings/cost); default 0
##   benefit       float    0..1, the player-observable value estimate relative to the alternatives
##   confidence    float    0..1 estimated chance of success for a risky option, or -1 when not risky
##   risk          float    0..1, what a failure would cost relative to normal progress
##   urgency       float    0..1, how pressing (recover options); >= the profile's reaction threshold interrupts
##   novelty       float    0..1, new / unowned / unseen content
##   milestone     bool     advances an explicit progression milestone
##   advances      bool     leaves current content behind (completionists and collectors hesitate)
##   optional      bool     side content
##   bottleneck    bool     removes a current progression blocker
##   commitment_s  float    expected active seconds an activity takes (or 0)
## Missing optional fields take the defaults above. An option is never a grant: begin() must call the
## game's own action functions, and the game decides the outcome.
##
## OBSERVATION (observe()): {"progress": float, "health": 0..1 or -1 unsupported, "area_completion": 0..1 or -1,
##   "collection_completion": 0..1 or -1, "resources": {name: amount}, "urgent": [options with urgency > 0]}
## Only values a player could see on screen. Unsupported values are -1, never a fabricated 0.

const Framework:=preload("framework.gd")

# ---------------------------------------------------------------- identity and capabilities
func integration_info() -> Dictionary:
	return {"game":"unknown","adapter_version":"0","strategy_version":"0","contract":Framework.CONTRACT_VERSION}

## {"intents": {intent: {"supported": bool, "note": String}}, "features": {"sessions","offline","automation","persistence": bool}}
func capabilities() -> Dictionary:
	var intents: Dictionary={}
	for i in Framework.INTENTS:intents[i]={"supported":i=="wait","note":"" if i=="wait" else "not declared"}
	return {"intents":intents,"features":{"sessions":false,"offline":false,"automation":false,"persistence":false}}

## Receives the resolved profile once, before the run, so tactics can derive their parameters from traits.
func configure(_profile: Dictionary) -> void:pass

## Cadence of the simulation step and of engine ticks, in seconds of active time.
func step_seconds() -> float:return 0.1
func tick_seconds() -> float:return 0.5
## Multiplies every profile duration (decision interval, cooldowns, patience). 1 = typical session game.
func time_scale() -> float:return 1.0

# ---------------------------------------------------------------- policy-facing
func observe() -> Dictionary:
	return {"progress":0.0,"health":-1.0,"area_completion":-1.0,"collection_completion":-1.0,"resources":{},"urgent":[]}
func options() -> Array:return []
## Executes an option through the game's own actions. {"status": "done"|"started"|"rejected"|"failed", "reason": String}
func begin(_option: Dictionary) -> Dictionary:return {"status":"rejected","reason":"unsupported"}
## Advances the current activity and the player's reflexes one tick.
## {"status": "running"|"done"|"failed"|"idle", "reason": String}
func advance(_now: float) -> Dictionary:return {"status":"idle","reason":""}
## Stops the current activity (the engine switches plans).
func cancel() -> void:pass
## Called before every simulation step (continuous input such as movement).
func steer() -> void:pass

# ---------------------------------------------------------------- simulation and sessions (driver)
func set_clock(_unix: float) -> void:pass
func step(_dt: float) -> bool:return false
func blocked_reason() -> String:return ""
## "" or why the run must stop (an action error, a broken invariant).
func failed() -> String:return ""
func goal_reached(_goal: String) -> bool:return false
func session_can_end() -> bool:return true
func leave_session(_n: int) -> void:pass
## "" or a persistence failure. mode: "cold" (reload from save) or "warm" (resume).
func return_session(_n: int,_away_s: float,_mode: String) -> String:return ""
func teardown() -> void:pass

# ---------------------------------------------------------------- privileged telemetry (reports only)
func progress_signature() -> String:return ""
func trace_sample() -> Dictionary:return {}
func state_digest() -> String:return ""
## Game-specific measured results (free-form, stays under summary.game).
func game_summary() -> Dictionary:return {}
## Generic metrics with fixed keys. Unsupported entries are the string "unsupported"; unmeasured are null.
##   milestones: [{key, t, c}] in order;  economy: {resource: {earned, spent}} | "unsupported";
##   automation_owned: int | "unsupported";  failures: int;  successes: int
func generic_metrics() -> Dictionary:
	return {"milestones":[],"economy":"unsupported","automation_owned":"unsupported"}
