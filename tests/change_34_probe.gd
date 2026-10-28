extends "res://tests/change_20_probe.gd"
## Change 34: the Google Play screenshot set (marketing/screenshots/). Static checks only; the renders
## themselves are validated by marketing/screenshots/finalize_screenshots.py (store_assets/ is ignored).
## - The manifest has exactly six scenes x four portrait device classes (Phone 1080x1920, Tablet_7,
##   Tablet_10, Desktop), 9:16, the expected output names, and the same scene/options/frame on every
##   class; no toolkit overlay (no composed screenshots, no video); isolated capture profile, no autosave.
## - Every scenario has an adapter branch; every staged seed is pinned (no seed search).
## - Every worn or merged item is a real catalog drop of some enemy (no invented gear).
## - The set shows all four seasons (Winter, Summer, Autumn, Spring maps) and the weathers rain,
##   leaves and snow; the final boss is never staged.
## - The Change 27 manifest emits no screenshot jobs any more; the adapter refuses a probe profile.
## Maps the adapter stages without a stage option (the rest default to Spring II).
const STAGE_DEFAULT:={"shot_gear":4,"shot_merge":2,"shot_explore":3,"trailer_farm":6}
const SEASON:={1:"Winter",2:"Winter",3:"Summer",4:"Summer",5:"Autumn",6:"Autumn",7:"Spring",8:"Spring"}

func run() -> void:
    var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://marketing/screenshots/manifest.json"))
    var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/game/catalog.json"))
    var adapter_source:=FileAccess.get_file_as_string("res://marketing/game_scenarios.gd")
    var jobs: Array=manifest.capture_jobs
    check(jobs.size()==24,"24 capture jobs (%d)" % jobs.size())
    check(manifest.screenshots.is_empty() and manifest.videos.is_empty(),"No toolkit overlay: raw gameplay captures only")
    var args: Array=manifest.godot_user_args
    check(args.has("--profile=capture-store") and args.has("--no-autosave"),"Isolated capture profile without autosave")
    var sizes:={"Phone":Vector2i(1080,1920),"Tablet_7":Vector2i(1440,2560),"Tablet_10":Vector2i(1800,3200),"Desktop":Vector2i(1620,2880)}
    var by_number: Dictionary={}
    for job in jobs:
        var device: String=str(job.id).rsplit("_",true,1)[0]
        var number: String=str(job.id).rsplit("_",true,1)[1]
        var size:=Vector2i(int(job.width),int(job.height))
        check(sizes.get(device)==size and size.x*16==size.y*9 and size.x>=1080,"%s is a 9:16 portrait render at its class size %s" % [job.id,size])
        check(str(job.output)=="../../store_assets/raw/screenshots/%s/%s_%s.png" % [device,device,number],"%s writes its raw master" % job.id)
        check(str(job.kind)=="screenshot" and bool(job.capture_ui),"%s is a screenshot with the native HUD" % job.id)
        var key:=JSON.stringify([job.scenario,job.options,job.capture_frame])
        if not by_number.has(number):by_number[number]=key
        check(by_number[number]==key,"%s stages the same moment as the other classes" % job.id)
    check(by_number.keys()==["01","02","03","04","05","06"],"Scenes 01..06 in store order")
    var seasons: Dictionary={}
    var weathers: Dictionary={}
    var drops: Dictionary={}
    for g in catalog.groups:
        for id in g.loot:drops[str(id)]=true
    for job in jobs.slice(0,6):
        var o: Dictionary=job.options
        check(adapter_source.contains("\"%s\":ok=" % job.scenario),"Adapter handles %s" % job.scenario)
        check(not o.has("seed_search") or int(o.seed_search)<=1,"%s pins its seed" % job.id)
        var stage:=int(o.get("stage",STAGE_DEFAULT.get(str(job.scenario),8)))
        seasons[SEASON[stage]]=true
        weathers[str(catalog.stages[stage-1].weather)]=true
        var ids: Array=[]
        for pair in o.get("items",[]):ids.append(str(pair[0]))
        for id in o.get("wear",[]):ids.append(str(id))
        if o.has("item"):ids.append(str(o.item))
        for id in ids:check(drops.has(id),"%s: %s is a real enemy drop (some group's loot)" % [job.id,id])
        check(not JSON.stringify(o).contains("green-alien"),"%s never stages the final boss" % job.id)
    check(seasons.size()==4,"All four seasons shown (%s)" % ", ".join(seasons.keys()))
    check(weathers.has("rain") and weathers.has("leaves") and weathers.has("blue_leaves"),"Rain, falling leaves and snow maps are shown")
    var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://marketing/manifest.json"))
    check(not old.capture_jobs.any(func(j):return str(j.kind)=="screenshot"),"The Change 27 manifest no longer captures screenshots")
    var adapter: Node=load("res://marketing/game_scenarios.gd").new()
    check(not adapter.is_capture_safe(),"Marketing adapter refuses a non-capture (probe) profile")
    adapter.free()
    print("CHANGE_34_CHECKS %d FAILURES %d" % [checks,failures])
    get_tree().quit(1 if failures else 0)
