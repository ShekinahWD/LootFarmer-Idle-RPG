extends RefCounted
## Farmstead fixture integration (see core/run_session.gd INTEGRATION). Pure data: no save files, no
## global state, nothing to isolate. Option `--variant=full|plain` picks the capability model.

const Adapter:=preload("farmstead_adapter.gd")
const Sim:=preload("farmstead_sim.gd")

var variant:="full"

func info() -> Dictionary:return {"game":"farmstead-fixture","integration_version":"farmstead-integration-1"}

func prepare(_host: Node,options: Dictionary) -> String:
	variant=str(options.get("raw",{}).get("variant",variant))
	if not variant in ["full","plain"]:return "--variant must be full or plain"
	return ""

func create_adapter(context: Dictionary):
	var a=Adapter.new()
	a.setup(context,variant)
	return a

func fingerprint() -> String:
	return (FileAccess.get_sha256((Sim as Script).resource_path)+"|"+variant).sha256_text()

func cleanup() -> void:pass

func sentinel_extra(adapter) -> String:
	var g: Dictionary=adapter.game_summary()
	return "hall=%d stars=%d relics=%d contracts=%d" % [int(g.hall),int(g.stars),int(g.relics),int(g.contracts_done)]
