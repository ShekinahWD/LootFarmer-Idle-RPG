extends Node
## Player Profiles framework: the generic command-line runner. Game-independent.
##   godot --headless --path <project> res://addons/player_profiles/runner/run_scene.tscn -- \
##         --integration=res://<game>/<integration>.gd --player-profile=<id> --seed=1 --active-minutes=30 \
##         --output=<absolute folder> [any option of core/run_session.gd options_from_args()]
## The integration owns isolation (test saves, autosave off) in prepare() and removes it in cleanup().
## Last line: PLAYTEST_RESULT ok=... ; exit 0 sound run, 1 action/engine/contract error, 2 bad arguments.

const RunSession:=preload("../core/run_session.gd")

func _ready() -> void:call_deferred("run")

func run() -> void:
	var o:=RunSession.options_from_args(OS.get_cmdline_user_args())
	var path:=str(o.raw.get("integration",""))
	if path=="" or not ResourceLoader.exists(path):
		_fail(2,"--integration=res://.../integration.gd is required");return
	var integration=load(path).new()
	var problem: String=integration.prepare(self,o)
	if problem!="":
		_fail(2,problem);return
	var result:=RunSession.execute(integration,o,self)
	integration.cleanup()
	if str(result.error)!="" and result.summary.is_empty():
		_fail(int(result.exit),str(result.error));return
	print(str(result.summary.get("_sentinel","PLAYTEST_RESULT ok=false stop=%s" % str(result.summary.get("stop_reason","?")))))
	get_tree().quit(int(result.exit))

func _fail(code: int,text: String) -> void:
	print("PLAYTEST_RESULT ok=false stop=engine_failure detail=",text)
	get_tree().quit(code)
