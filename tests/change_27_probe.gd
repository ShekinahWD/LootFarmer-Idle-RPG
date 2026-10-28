extends "res://tests/change_20_probe.gd"
## Change 27: the first Snowman defeat of a profile's lifetime drops the weapon it carries.
## - Gear chance 0 fixture: the first defeat still drops exactly one copy of the catalog weapon, as an
##   ordinary ground pickup; the second defeat does not.
## - A natural drop of that weapon on the first defeat is not duplicated.
## - Every other reward (coins, XP, gems, outfit/supply/skill rolls, kills) matches an ordinary defeat
##   under the same RNG state; no extra milestone, notice or event fires.
## - Save -> reload and Prestige never grant it again; Hard Reset re-arms it.
## - Guided, Basic and None alike; a changed catalog weapon (fixture) is respected.
## - Release version 27 (exact-version check; earlier probes check ">=").
## - Store assets: the Release preset's launcher icons exist and ship; marketing sources, outputs,
##   toolkit and capture addons do not; the marketing adapter refuses a non-capture profile.
var snow:=-1
var signals: Array=[]

func run() -> void:
    get_window().size=Vector2i(720,1280)
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    await frames()
    for i in range(sim.catalog.groups.size()):
        if str(sim.catalog.groups[i].id)=="boss-snowman":snow=i
    check(snow>=0 and str(sim.catalog.groups[snow].weapon)=="stone_axe","Snowman carries the Stone Axe in the catalog")
    check(sim.campaign.onboarding.rules.first_kill_weapon_bosses==PackedStringArray(["boss-snowman"]),"Only the Snowman is listed (onboarding_rules.tres)")
    sim.milestone.connect(func(k,id):signals.append("milestone:%s:%s" % [k,id]))
    sim.notice.connect(func(k,id):signals.append("notice:%s:%s" % [k,id]))
    sim.event.connect(func(k):signals.append("event:"+k))
    var base_chance: float=float(sim.catalog.groups[snow].gear_chance)
    first_kill_checks()
    natural_checks()
    equivalence_checks()
    persistence_checks()
    mode_checks()
    catalog_weapon_checks()
    sim.catalog.groups[snow].gear_chance=base_chance
    static_checks()
    print("CHANGE_27_CHECKS %d FAILURES %d" % [checks,failures])
    game.queue_free();await frames();AudioService.stop_all_sfx();get_tree().quit(1 if failures else 0)

func snowman() -> Dictionary:
    for e in sim.state.enemies:
        if int(e.group)==snow and not sim.is_helper(e):return e
    return {}

## A real defeat through the simulation's own kill path (the enemy is alive first).
func defeat() -> Array:
    var e:=snowman()
    if e.is_empty():return ["<no snowman>"]
    e.hp=0.0
    var before: int=sim.state.pickups.size()
    sim._kill(e)
    var items: Array=[]
    for p in sim.state.pickups.slice(before):items.append(str(p.item))
    return items

## Respawns the defeated Snowman at once (a fixture for a second defeat in the same run).
func revive() -> void:
    var e:=snowman()
    e.hp=float(sim.enemy_definition(snow).hp);e.respawn=0.0
    sim.state.boss_respawns.erase(str(e.id))

func chance(value: float) -> void:
    sim.catalog.groups[snow].gear_chance=value # fixture: natural carried-loot roll

func first_kill_checks() -> void:
    fresh("none");chance(-100.0)
    check(int(sim.state.group_kills[snow])==0,"Fresh profile: no Snowman defeats yet")
    var items:=defeat()
    check(items.count("stone_axe")==1,"First defeat at gear chance 0 drops one Stone Axe (%s)" % [items])
    check(not items.has("boss-snowman_outfit"),"…and no outfit (the natural roll still applies)")
    var ground: Array=sim.state.pickups.filter(func(p):return str(p.item)=="stone_axe")
    check(ground.size()==1 and int(ground[0].group)==snow and float(ground[0].ttl)==300.0,"…as an ordinary ground pickup from the Snowman")
    check(sim.quantity("stone_axe")==0,"…not inserted into the inventory")
    revive()
    items=defeat()
    check(not items.has("stone_axe") and int(sim.state.group_kills[snow])==2,"Second defeat: no guaranteed weapon (%s)" % [items])

func natural_checks() -> void:
    fresh("none");chance(100.0)
    var items:=defeat()
    check(items.count("stone_axe")==1 and items.has("boss-snowman_outfit"),"Natural Stone Axe on the first defeat is not duplicated (%s)" % [items])

## The same RNG state, first defeat vs an ordinary (second lifetime) defeat: identical rewards apart
## from the one added weapon.
func equivalence_checks() -> void:
    var results: Array=[]
    for prior in [0,1]:
        fresh("none");chance(.5)
        sim.state.group_kills[snow]=prior # fixture: lifetime defeats before this one
        sim.rng.seed=2727
        signals.clear()
        var items:=defeat()
        results.append({"items":items,"coins":float(sim.state.coins),"xp":float(sim.state.xp),"level":int(sim.state.player_level),"gems":float(sim.state.gems),"signals":signals.duplicate(),"rng":sim.rng.state})
    var first: Array=results[0].items.duplicate()
    var ordinary: Array=results[1].items
    check(not ordinary.has("stone_axe") or first.count("stone_axe")==ordinary.count("stone_axe"),"Seeded fixture is meaningful (%s / %s)" % [first,ordinary])
    if not ordinary.has("stone_axe"):first.erase("stone_axe")
    check(first==ordinary,"Other drops identical to an ordinary defeat (%s vs %s)" % [results[0].items,ordinary])
    for key in ["coins","xp","level","gems"]:
        check(results[0][key]==results[1][key],"%s identical to an ordinary defeat" % key)
    check(results[0].signals==results[1].signals,"No extra announcement: same signals (%s vs %s)" % [results[0].signals,results[1].signals])

func persistence_checks() -> void:
    # Save -> disk reload, then the respawned Snowman: no second grant.
    fresh("none");chance(-100.0)
    check(defeat().has("stone_axe"),"Persistence fixture: first defeat drops the axe")
    check(SaveService.save_now(),"Save after the first defeat succeeds")
    SaveService.load_and_apply()
    check(int(sim.state.group_kills[snow])==1,"Lifetime defeat survives a disk reload")
    revive()
    check(not defeat().has("stone_axe"),"After reload the next defeat grants nothing extra")
    # JSON round trip of the save snapshot.
    fresh("none");chance(-100.0)
    defeat()
    sim.restore(JSON.parse_string(JSON.stringify(sim.snapshot())))
    revive()
    check(not defeat().has("stone_axe"),"After a snapshot round trip the next defeat grants nothing extra")
    # Prestige keeps the lifetime record: a new run's first Snowman defeat is ordinary.
    fresh("none");chance(-100.0)
    defeat()
    sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0} # fixture: ready
    var prestiged: bool=sim.campaign.begin_prestige() and sim.prestige(sim.campaign.offered_cards()[0])
    check(prestiged and int(sim.state.prestiges)==1,"Prestige completes")
    check(int(sim.state.group_kills[snow])==1 and int(sim.state.run_kills.get("boss-snowman",0))==0,"Prestige keeps the lifetime defeat, clears the run's")
    sim.suspended=false
    var after:=defeat()
    check(not after.has("stone_axe"),"First defeat after Prestige is ordinary (%s)" % [after])
    # Hard Reset makes a new profile: the guarantee is back.
    check(SaveService.hard_reset(),"Hard Reset succeeds")
    sim.suspended=false;sim.state.tutorial.mode="none"
    check(int(sim.state.group_kills[snow])==0,"Hard Reset clears lifetime defeats")
    check(defeat().count("stone_axe")==1,"After Hard Reset the first defeat drops the axe again")

func mode_checks() -> void:
    for mode in ["guided","basic","none"]:
        fresh(mode);chance(-100.0)
        if mode!="none":sim.campaign.onboarding.choose_mode(mode)
        check(defeat().count("stone_axe")==1,"%s: first defeat drops the Stone Axe" % mode)
    # The Change 15 normal-enemy guarantee is untouched: a boss never counts as one of its kills.
    fresh("none");chance(-100.0)
    var o: Dictionary=sim.state.onboarding
    o.loot_phase=sim.campaign.onboarding.LOOT_NONE;o.loot_kills=0 # fixture: early guarantee still open
    defeat()
    check(int(o.loot_kills)==0,"A Snowman defeat is not an early-guarantee kill")

func catalog_weapon_checks() -> void:
    var original: String=str(sim.catalog.groups[snow].weapon)
    sim.catalog.groups[snow].weapon="wood_sword" # fixture: a different carried weapon
    sim._definitions.clear()
    fresh("none");chance(-100.0)
    var items:=defeat()
    check(items.count("wood_sword")==1 and not items.has("stone_axe"),"A changed catalog weapon is the one guaranteed (%s)" % [items])
    sim.catalog.groups[snow].weapon=original
    sim._definitions.clear()
    # Other bosses are not listed: a first Cyan Robot defeat at gear chance 0 drops no weapon.
    var robot:=-1
    for i in range(sim.catalog.groups.size()):
        if str(sim.catalog.groups[i].id)=="boss-cyan-robot":robot=i
    var saved: float=float(sim.catalog.groups[robot].gear_chance)
    sim.catalog.groups[robot].gear_chance=-100.0
    fresh("none")
    sim.state.stage=2;sim.state.unlocked_stage=2;sim._reset_world()
    var cyan: Dictionary={}
    for e in sim.state.enemies:
        if int(e.group)==robot:cyan=e
    var before: int=sim.state.pickups.size()
    cyan.hp=0.0;sim._kill(cyan)
    check(not sim.state.pickups.slice(before).any(func(p):return str(p.item)=="stone_sword"),"Unlisted bosses keep ordinary drops")
    sim.catalog.groups[robot].gear_chance=saved

func static_checks() -> void:
    var source:=FileAccess.get_file_as_string("res://scripts/game/onboarding.gd")
    var body:=source.substr(source.find("func boss_first_kill"))
    body=body.substr(0,body.find("\nfunc ",10))
    check(not body.contains("emit(") and not body.contains(" tr(") and not body.contains("(tr(") and not body.contains("history("),"The rule has no player-facing copy, banner or history line")
    var po:=FileAccess.get_file_as_string("res://localization/en.po").to_lower()
    check(not po.contains("first snowman") and not po.contains("first defeat"),"No UI copy mentions the first-defeat reward")
    check(str(ProjectSettings.get_setting("application/config/version"))=="27","Project version is 27 (Change 27)")
    var presets:=FileAccess.get_file_as_string("res://export_presets.cfg")
    var release:=presets.substr(presets.find("name=\"Android Release\""))
    release=release.substr(0,release.find("[preset.1]"))
    check(release.contains("version/code=27") and release.contains("version/name=\"\""),"Android Release version code is 27, name inherited")
    check(release.contains("package/unique_name=\"com.shekinahwelefuldesigns.lootfarmeridlerpg\""),"Package id unchanged")
    var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tools/export_manifest.json"))
    var shipped: Dictionary=manifest.files
    for key in ["main_192x192","adaptive_foreground_432x432","adaptive_background_432x432","adaptive_monochrome_432x432"]:
        var line:=release.substr(release.find("launcher_icons/%s=" % key)).get_slice("
",0)
        var path:=line.get_slice("\"",1)
        check(path.begins_with("res://assets/branding/") and ResourceLoader.exists(path) and shipped.has(path),"Launcher icon %s is set, loads and ships (%s)" % [key,path])
    var icon:=str(ProjectSettings.get_setting("application/config/icon"))
    check(icon=="res://assets/branding/launcher_192.png" and shipped.has(icon),"Project icon is the new launcher icon and ships")
    for prefix in ["res://marketing/","res://store_assets/","res://addons/","res://Godot-Marketing-Toolkit/","res://docs/"]:
        check(not shipped.keys().any(func(k):return str(k).begins_with(prefix)),"Nothing under %s ships" % prefix)
    check(release.contains("marketing/*") and release.contains("addons/marketing_capture/*"),"Release exclude_filter still names the marketing sources and capture addon")
    check(FileAccess.file_exists("res://store_assets/.gdignore") or not DirAccess.dir_exists_absolute("res://store_assets"),"Generated store assets are never imported (.gdignore)")
    var adapter: Node=load("res://marketing/game_scenarios.gd").new()
    check(not adapter.is_capture_safe(),"Marketing adapter refuses a non-capture (probe) profile")
    adapter.free()
