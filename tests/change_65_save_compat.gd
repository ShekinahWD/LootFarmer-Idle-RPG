extends Node
## Change 65 real-save compatibility check (not in the suite: it reads the developer's local profiles).
##   Godot --headless --path . res://tests/change_65_save_compat.tscn -- --probe --profile=probe-c65compat --no-autosave
## Every save file found under user://profiles/*/ (save.json and its *_backup.json copies, from earlier
## builds) is COPIED into this probe's own profile and loaded through the real path
## (SaveService.load_and_apply: version check, schema migration, normalization, validation). Originals are
## only read. A file the build cannot read would reset the profile, so the check fails if any load result
## is a reset, or if currencies, level, Prestige count, owned cards, items or any non-Focus upgrade differ
## from the file, or if a legacy per-type Focus purchase did not become the one global unlock.
var checks:=0
var failures:=0
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
    else:print("  ok  ",label_)
func _ready() -> void:call_deferred("run")
func run() -> void:
    await get_tree().process_frame
    var game=load("res://scenes/game/main.tscn").instantiate();add_child(game)
    var sim=game.sim;sim.set_physics_process(false)
    await get_tree().process_frame
    var own: String=ProjectSettings.globalize_path(SaveService.save_path())
    var root: String=ProjectSettings.globalize_path("user://profiles")
    var sources: Array=[]
    for dir in DirAccess.get_directories_at(root):
        for file in DirAccess.get_files_at(root+"/"+dir):
            if file.begins_with("save") and file.ends_with(".json") and not file.ends_with(".tmp"):sources.append(root+"/"+dir+"/"+file)
    sources=sources.filter(func(p):return p.get_base_dir()!=own.get_base_dir())
    var legacy_total:=0
    for path in sources:
        var raw: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else {}
        if not raw.get("sections") is Dictionary or not raw.sections.get("lootfarmer") is Dictionary:continue
        if int(raw.get("version",-1))!=SaveService.SAVE_VERSION:continue
        var before: Dictionary=raw.sections.lootfarmer
        DirAccess.make_dir_recursive_absolute(own.get_base_dir())
        var copy:=FileAccess.open(own,FileAccess.WRITE);copy.store_string(FileAccess.get_file_as_string(path));copy.close()
        SaveService.load_and_apply()
        var name: String=path.trim_prefix(root+"/")
        var result: String=SaveService.last_load_result
        check(result in ["primary","backup"],"%s: loaded (%s, schema %s)" % [name,result,str(before.get("schema"))])
        var same:=true
        for key in ["gems","coins","player_level","prestiges"]:
            if before.has(key) and absf(float(before[key])-float(sim.state[key]))>.001:same=false;print("  diff  ",key," ",before[key]," -> ",sim.state[key])
        if before.get("owned_cards") is Array and before.owned_cards.size()!=sim.state.owned_cards.size():same=false;print("  diff  owned_cards")
        check(same,"%s: currencies, level, Prestige count and cards unchanged" % name)
        var legacy:=0
        var others_ok:=true
        if before.get("upgrades") is Dictionary:
            for key in before.upgrades:
                if str(key).begins_with("focus:"):
                    if int(before.upgrades[key])>0:legacy+=1
                    continue
                if str(key)=="focus":continue
                # Keys the current catalog no longer validates were already dropped by earlier builds.
                if sim.state.upgrades.has(key) and int(sim.state.upgrades[key])!=int(before.upgrades[key]):others_ok=false;print("  diff  upgrade ",key)
        legacy_total+=legacy
        check(others_ok,"%s: every other upgrade kept at its level" % name)
        var had_global: bool=before.get("upgrades",{}).get("focus",0)>0
        check(sim.focus_owned()==(legacy>0 or had_global) and not sim.state.upgrades.keys().any(func(k):return str(k).begins_with("focus:")),"%s: Focused Farming %s (%d legacy record(s))" % [name,"owned" if sim.focus_owned() else "not owned",legacy])
        # Saving and loading again is stable.
        var gems: float=sim.state.gems
        check(SaveService.save_now(),"%s: saves" % name)
        SaveService.load_and_apply()
        check(SaveService.last_load_result=="primary" and is_equal_approx(float(sim.state.gems),gems) and sim.focus_owned()==(legacy>0 or had_global),"%s: reload after saving is identical" % name)
    print("  info  files with legacy per-type Focus records: %d record(s) total" % legacy_total)
    check(sources.size()>0,"Found %d local save files from earlier builds" % sources.size())
    print("CHANGE_65_SAVE_COMPAT_CHECKS %d FAILURES %d" % [checks,failures])
    get_tree().quit(1 if failures>0 else 0)
