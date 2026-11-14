extends RefCounted
## LootFarmer player-profile integration (see res://addons/player_profiles/core/run_session.gd INTEGRATION).
## Isolation: runs only in a `probe-pp-*` save namespace, starts from an empty profile, never touches the
## player's real save, and removes its own save files at the end. The game build is identified by the
## content fingerprint (catalog and rule resources) plus the runner's git state.

const Runtime:=preload("res://tests/playtest/lootfarmer_adapter.gd")
const Adapter:=preload("res://tests/playtest/lootfarmer/lf_adapter.gd")
const FINGERPRINT_FILES:=["res://data/game/catalog.json","res://resources/game/enemy_abilities.tres","res://resources/game/fog_rules.tres",
    "res://resources/game/onboarding_rules.tres","res://resources/game/mastery_rules.tres"]

var adapter
var precleaned:=false

func info() -> Dictionary:return {"game":"lootfarmer","integration_version":"lootfarmer-integration-1"}

func prepare(host: Node,_options: Dictionary) -> String:
    if not BootContext.profile_name.begins_with("probe-pp-"):
        return "run with --profile=probe-pp-<id> (an isolated save namespace)"
    # A leftover from an interrupted run is removed and the save service reloads (now "new").
    if SaveService.last_load_result!="new":
        precleaned=true
        wipe()
        SaveService.load_and_apply()
    SaveService.write_blocked=false
    host.get_tree().paused=false
    return ""

func create_adapter(context: Dictionary):
    var sim=load("res://scripts/game/simulation.gd").new()
    context.host.add_child(sim);sim.set_physics_process(false)
    var rt=Runtime.new()
    rt.setup(sim,context.recorder,int(context.seed),float(context.start_unix))
    adapter=Adapter.new()
    adapter.setup(rt)
    return adapter

func fingerprint() -> String:
    var context:=HashingContext.new()
    context.start(HashingContext.HASH_SHA256)
    for path in FINGERPRINT_FILES:context.update(FileAccess.get_sha256(path).to_utf8_buffer())
    return context.finish().hex_encode()

func cleanup() -> void:
    if adapter!=null:adapter.teardown()
    wipe()

func sentinel_extra(a) -> String:
    var rt=a.rt
    return "level=%d stage=%d prestiges=%d deaths=%d" % [rt.level(),rt.stage(),rt.prestiges(),rt.deaths.size()]

## Removes this run's isolated save files. Only ever touches user://profiles/probe-pp-*.
func wipe() -> void:
    if not BootContext.profile_name.begins_with("probe-pp-"):return
    SaveService.write_blocked=true
    var directory:=BootContext.save_directory()
    var dir:=DirAccess.open(directory)
    if dir==null:return
    for name in dir.get_files():dir.remove(name)
    DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
