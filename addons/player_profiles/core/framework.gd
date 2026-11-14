extends RefCounted
## Player Profiles framework: versions, the generic intent vocabulary and stop classes.
## Game-independent. Nothing in this package may reference a specific game, its classes or its paths.

const FRAMEWORK_VERSION:="1.0.0"
const SUMMARY_SCHEMA:="player-profiles.summary/1"
const PROFILE_SCHEMA:="player-profiles.profiles/1"
const CONTRACT_VERSION:="player-profiles.contract/1"

## The generic intents a game maps its legitimate player actions onto. A game declares which it supports
## (adapter.capabilities()); unsupported intents are reported as `unsupported`, never as zero.
## Order is also the deterministic tie-break order (earlier wins on an exact score tie).
const INTENTS:=["recover","claim_rewards","progress_main","attempt_challenge","strengthen","improve_economy",
	"invest_automation","explore","complete_optional","collect","wait"]

const INTENT_DOC:={
	"recover":"recover or survive: heal, retreat, leave danger",
	"claim_rewards":"claim rewards already earned (finished tasks, offline earnings)",
	"progress_main":"pursue the main objective: the next stage, level, area or reset milestone",
	"attempt_challenge":"attempt a challenging objective that can fail (a boss, a hard level, a risky event)",
	"strengthen":"strengthen or prepare: gear, stats, character or base improvements, grinding to get stronger",
	"improve_economy":"improve income or resource production",
	"invest_automation":"invest in passive, offline or automation systems, or switch owned automation on",
	"explore":"discover or explore unknown content",
	"complete_optional":"complete optional content: side tasks, achievements, daily objectives",
	"collect":"collect variety: unowned items, sets, rare content",
	"wait":"continue the current plan or idle",
}

## Decisions the engine itself records (not adapter options).
const ENGINE_DECISIONS:=["save_for_goal","session_leave","session_return"]

## Option outcome statuses (adapter.begin / adapter.advance) and engine-side refusals.
const OUTCOMES:=["done","started","running","rejected","failed","idle"]
const ENGINE_REFUSALS:=["ineligible","unaffordable","not_ready","cooldown","unsupported","invalid"]

## Stop classes. The value says whether the run itself was sound (a stall or a spent budget is a finding).
const STOPS:={"duration_reached":true,"goal_reached":true,"stalled":true,
	"calendar_reached":true,"time_budget_exceeded":true,"wall_timeout":false,"action_error":false,
	"engine_failure":false,"contract_error":false}

static func intent_index(intent: String) -> int:
	var i:=INTENTS.find(intent)
	return INTENTS.size() if i<0 else i
