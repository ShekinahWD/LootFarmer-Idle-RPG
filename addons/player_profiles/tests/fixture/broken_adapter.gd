extends "farmstead_adapter.gd"
## Contract-violation fixture for the self-test: a Farmstead adapter that offers malformed options and can
## hide one intent declaration. The engine must reject the bad options (counted as invalid) and keep playing.

var hide_intent:=false

func capabilities() -> Dictionary:
	var c: Dictionary=super.capabilities()
	if hide_intent:c.intents.erase("explore")
	return c

func options() -> Array:
	var out: Array=super.options()
	out.append({"id":"teleport_to_end","intent":"cheat","kind":"instant"})                            # unknown intent
	out.append({"id":"heal","intent":"recover","kind":"instant","benefit":1.0})                     # declared unsupported
	out.append({"id":"","intent":"wait","kind":"activity"})                                         # no id
	out.append({"id":"blocked_thing","intent":"strengthen","kind":"instant","eligible":false})      # no block reason
	out.append({"id":"too_good","intent":"strengthen","kind":"instant","benefit":7.0})              # benefit outside 0..1
	return out
