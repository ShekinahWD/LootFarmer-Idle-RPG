extends SceneTree
## Change 15: fog cells no walking player can reveal, per stage (campaign.compute_unreachable_cells).
## Usage: godot --headless --path . -s tools/fog_reachability.gd [-- --write]
## Without --write it compares with resources/game/fog_rules.tres (exit 1 on a mismatch); with
## --write it stores the result there. Run it after moving solid scenery.

func _initialize() -> void:
    # Autoloads (SaveService, BootContext) must exist before the campaign script compiles.
    await process_frame
    var catalog=JSON.parse_string(FileAccess.get_file_as_string("res://data/game/catalog.json"))
    var campaign=load("res://scripts/game/campaign.gd").new(null)
    var rules: Resource=load("res://resources/game/fog_rules.tres")
    var found: Dictionary={}
    var ok:=true
    for st in range(1,catalog.stages.size()+1):
        var cells: Array=campaign.compute_unreachable_cells(catalog.stages[st-1],st)
        if not cells.is_empty():found[st]=cells
        var stored: Array=rules.unreachable_cells.get(st,[])
        var same: bool=cells.size()==stored.size() and cells.all(func(c):return stored.has(c))
        if not same:ok=false
        print("stage %d unreachable %d %s" % [st,cells.size(),"ok" if same else "DIFFERS (stored %d)" % stored.size()])
    if "--write" in OS.get_cmdline_user_args():
        rules.unreachable_cells=found
        ResourceSaver.save(rules,"res://resources/game/fog_rules.tres")
        print("FOG_REACHABILITY written")
        quit(0)
        return
    print("FOG_REACHABILITY %s" % ("PASS" if ok else "FAIL"))
    quit(0 if ok else 1)
