extends "farmstead_adapter.gd"
## Self-test spy: counts calls to the privileged telemetry methods. The decision engine must never call them.

var telemetry_calls:=0

func progress_signature() -> String:
	telemetry_calls+=1;return super.progress_signature()
func trace_sample() -> Dictionary:
	telemetry_calls+=1;return super.trace_sample()
func state_digest() -> String:
	telemetry_calls+=1;return super.state_digest()
func game_summary() -> Dictionary:
	telemetry_calls+=1;return super.game_summary()
func generic_metrics() -> Dictionary:
	telemetry_calls+=1;return super.generic_metrics()
