extends "res://tests/change_20_probe.gd"
## Change 50 (approved progression brief, B1): schema 9 save migration and the approved Prestige rules.
## - A real schema 8 file on disk migrates on load: merge memory from current records and Map Mastery's
##   best merges (levels lost to older Prestiges come back), owned records rise to it, no copy is added,
##   weapons above any cap keep their exact level, an untouched copy of the old file is kept, and loading
##   once and twice gives the same profile.
## - Owning no copy grants no power; finding the item again restores its remembered level.
## - Prestige keeps Coins, every upgrade, merge memory and earned main objectives; pays finished missions
##   and pending offline Coins/Gems once; resets items, rolls and map access (camps kept since Change 76) and missions; prices
##   new missions from the new run's map access.
## - A failed write rolls the whole transaction back; an open batch survives two reloads and pays once.
## - Hard Reset clears merge memory; an unreadable schema is copied aside before the fresh profile.
## Runs with --first-run-complete.
func run() -> void:
    get_window().size=Vector2i(720,1280)
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    await frames(6)
    migration_checks()
    memory_checks()
    prestige_checks()
    rollback_checks()
    reset_checks()
    print("CHANGE_50_CHECKS %d FAILURES %d" % [checks,failures])
    game.queue_free();await frames();AudioService.stop_all_sfx();get_tree().quit(1 if failures else 0)

func path(tag:="") -> String:
    return SaveService.save_path() if tag=="" else SaveService.save_path().trim_suffix(".json")+"."+tag+".json"

func clear_files() -> void:
    for f in [path(),path()+".bak",path()+".tmp",path("schema8_backup"),path("rejected_schema_99"),path("rejected_invalid")]:
        if FileAccess.file_exists(f):DirAccess.remove_absolute(ProjectSettings.globalize_path(f))

## Writes a save file exactly as an older build would (file version 3, sections.lootfarmer).
func write_file(section: Dictionary) -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BootContext.save_directory()))
    var data:={"version":SaveService.SAVE_VERSION,"settings":SettingsState.to_save_dict(),"sections":{"lootfarmer":section},"last_seen_unix":int(Time.get_unix_time_from_system())}
    var f:=FileAccess.open(path(),FileAccess.WRITE);f.store_string(JSON.stringify(data));f.close()

func reload() -> void:
    SaveService.last_load_result=""
    SaveService.load_and_apply()

## A released schema 8 profile: Wood Axe ^5 x3 (Map Mastery best ^40 from an older run), Iron Sword ^100
## x2 (above any weapon cap), Stone Sword ^30 only in Map Mastery (not owned), an outfit ^250 only in
## Map Mastery, and a supply record (never remembered).
func schema8_fixture() -> Dictionary:
    fresh();sim.state.coins=777;sim.state.unlocked_stage=3;sim.state.reward_stage=3
    sim.add_item("wood_axe",3);sim.record("wood_axe").merge=5
    sim.add_item("iron_sword",2);sim.record("iron_sword").merge=100
    sim.add_item("potion",4)
    sim.state.mastery.merge["wood_axe"]=40;sim.state.mastery.merge["stone_sword"]=30
    sim.state.mastery.merge["unit-blue-cap_outfit"]=250;sim.state.mastery.merge["iron_sword"]=60
    var snap: Dictionary=sim.snapshot()
    snap.schema=8;snap.erase("merge_memory");snap.erase("migrations")
    return snap

func migration_checks() -> void:
    clear_files()
    var old:=schema8_fixture()
    write_file(old)
    reload()
    check(SaveService.last_load_result=="primary","The schema 8 file loads as the primary save (%s)" % SaveService.last_load_result)
    check(int(sim.state.schema)==9 and sim.state.migrations.has("schema9_merge_memory") and sim.state.migrations.count("schema9_merge_memory")==1,"It migrates to schema 9 once")
    check(int(sim.state.coins)==777 and int(sim.state.unlocked_stage)==3,"Coins and map access are untouched")
    var m: Dictionary=sim.state.merge_memory
    check(int(m.get("wood_axe",0))==40 and int(m.get("stone_sword",0))==30 and int(m.get("unit-blue-cap_outfit",0))==250 and int(m.get("iron_sword",0))==100,"Merge memory = best of records and Map Mastery %s" % str(m))
    check(not m.has("potion"),"Supplies are never remembered")
    check(sim.quantity("wood_axe")==3 and int(sim.record("wood_axe").merge)==40,"The owned Wood Axe rises to its remembered ^40 without a new copy")
    # Change 51 converts the old-stat Iron Sword into its legacy copy (same quantity and level).
    check(sim.quantity("iron_sword_legacy")==2 and int(sim.record("iron_sword_legacy").merge)==100,"Iron Sword keeps its exact ^100 (as its legacy copy)")
    check(not sim.state.items.has("stone_sword") and not sim.state.items.has("unit-blue-cap_outfit"),"Remembered but unowned items get no inventory record")
    check(FileAccess.file_exists(path("schema8_backup")),"An untouched copy of the schema 8 file is kept")
    var kept=JSON.parse_string(FileAccess.get_file_as_string(path("schema8_backup")))
    check(kept is Dictionary and int(kept.sections.lootfarmer.schema)==8,"The kept copy is the original schema 8 save")
    check(SaveService.save_now(),"The migrated profile saves")
    reload()
    check(SaveService.last_load_result=="primary" and int(sim.state.schema)==9,"Reload 1 reads schema 9")
    # Compared between two loads from disk (JSON numbers read back as floats).
    var first: String=JSON.stringify(sim.state.merge_memory)+JSON.stringify(sim.state.items)
    check(SaveService.save_now(),"Saved again")
    reload()
    var second: String=JSON.stringify(sim.state.merge_memory)+JSON.stringify(sim.state.items)
    check(first==second and sim.state.migrations.has("schema9_merge_memory") and sim.state.migrations.count("schema9_merge_memory")==1,"Reload 2 is identical (no second migration, no duplicated copies)")
    # The schema 8 copy is never replaced by later migrations of other files.
    kept=JSON.parse_string(FileAccess.get_file_as_string(path("schema8_backup")))
    check(int(kept.sections.lootfarmer.schema)==8,"The schema 8 copy is still the original after more saves")

func memory_checks() -> void:
    fresh()
    var base: float=sim.stats().damage
    sim.state.merge_memory={"stone_sword":30}
    sim.touch()
    check(is_equal_approx(sim.stats().damage,base),"A remembered item the player does not own adds no power")
    check(sim.add_item("stone_sword") and int(sim.record("stone_sword").merge)==30,"Finding it again restores ^30")
    sim.add_item("stone_sword",2)
    sim.merge("stone_sword")
    check(int(sim.state.merge_memory.stone_sword)==30 or int(sim.state.merge_memory.stone_sword)==int(sim.record("stone_sword").merge),"A merge keeps memory at the record's level")
    sim.add_item("wood_axe",3);sim.merge("wood_axe");sim.merge("wood_axe")
    check(int(sim.state.merge_memory.get("wood_axe",0))==2,"Merging records the new level")
    sim.restore(JSON.parse_string(JSON.stringify(sim.snapshot())))
    check(int(sim.state.merge_memory.get("wood_axe",0))==2 and int(sim.state.merge_memory.get("stone_sword",0))>=30,"Memory survives a JSON round trip")

## A run ready for Prestige: first boss found, one ready Hunter opportunity, and every kind of state.
func prestige_fixture() -> void:
    fresh()
    var s: Dictionary=sim.state
    s.coins=50000.0;s.gems=900.0;s.unlocked_stage=3;s.player_level=25
    if not s.bosses_found.has("boss-snowman"):s.bosses_found.append("boss-snowman")
    s.group_kills[3]=2;s.run_kills["unit-blue-cap"]=50
    sim.campaign.discover_spot(0,2)
    sim.add_item("wood_axe",6);sim.merge("wood_axe");sim.merge("wood_axe");sim.merge("wood_axe")
    sim.equip("wood_axe")
    sim.add_item("unit-blue-cap_outfit",2)
    sim.add_item("potion",3)
    s.supply_uses["potion"]=12
    for up in [["coin_amount",0],["loot",0],["group_xp",0],["movement",-1],["gem_chance",-1],["map_detail",1]]:
        check(sim.buy_upgrade(str(up[0]),int(up[1])),"Fixture buys %s" % str(up))
    s.camps_known["1"]=[0,1]
    check(sim.campaign.camp_action(1,1,false),"Fixture buys camp 1 of Winter I")
    check(sim.buy_upgrade("camp_radius",11),"Fixture buys that camp's reveal radius")
    s.main_ready["3"]=true
    s.offline_pending={"id":"probe","seconds":7200.0,"longest":7200.0,"rewarded_hours":2.0,"coins":240.0,"gems":4.0,"items":{"wood_axe":2}}
    sim.campaign.refresh_missions()
    var m: Dictionary=s.missions[0]
    if str(m.kind)=="waiting":m.kind="coins";m.target="";m.goal=10.0
    m.progress=float(m.goal);m.claimed=false
    s.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0}
    sim.touch()

func prestige_checks() -> void:
    clear_files()
    prestige_fixture()
    var s: Dictionary=sim.state
    var missions_before: Array=s.missions.duplicate(true)
    var coins_before: float=float(s.coins);var gems_before: float=float(s.gems)
    var upgrades_before: Dictionary=s.upgrades.duplicate(true)
    var camps_before: Dictionary=s.camps.duplicate(true)
    check(camps_before.get("1",[])==[0,1],"Fixture owns Winter I camps 0 and 1")
    check(sim.campaign.begin_prestige(),"Prestige begins (%s)" % sim.campaign.prestige_block_reason())
    var offered: Array=sim.campaign.offered_cards()
    check(not offered.is_empty() and sim.campaign.choose_card(str(offered[0])),"The last card completes the Prestige")
    s=sim.state
    check(is_equal_approx(float(s.coins),coins_before+240.0),"Coins kept + offline Coins paid once (daily mission remains unclaimed) (%s vs %s)" % [s.coins,coins_before+240.0])
    check(is_equal_approx(float(s.gems),gems_before+4.0),"Gems kept + offline Gems; daily mission not auto-claimed")
    check(s.upgrades==upgrades_before,"Every purchased upgrade keeps its level (Coin and Gem, map and camp)")
    check(sim.quantity("wood_axe")==0 and sim.quantity("potion")==0 and s.weapon=="" and not s.gear.has("wood_axe"),"Items and loadout reset")
    check(int(s.merge_memory.get("wood_axe",0))==3,"Merge memory keeps the run's Wood Axe ^3")
    check(s.offline_pending.is_empty() and sim.quantity("wood_axe")==0,"Pending offline items end with the inventory (never claimable later)")
    check(s.main_ready.has("3"),"An earned main objective stays claimable")
    # Change 76: owned camps are permanent; map access still resets.
    check(int(s.unlocked_stage)==1 and s.camps==camps_before,"Map access resets; owned camps are kept (Change 76)")
    check(int(s.supply_uses.get("potion",0))==12 and sim.supply_mastery("potion")==2,"Supply Mastery stays across Prestige")
    check(s.missions==missions_before and not s.missions[0].claimed,"Daily mission progress, rewards and claim state survive Prestige")
    check(int(s.player_level)==25,"Player level kept")
    check(sim.campaign.reward_stage()==1,"Missions are priced from the new run's map access")
    check(s.missions==missions_before,"Existing missions are not replaced or repriced at Prestige")
    # Camp radius stays bought and, since Change 76, its camp stays owned, so it keeps acting.
    check(int(sim.level("camp_radius",11))==1 and s.spawns.has(1),"Camp radius kept with its camp still owned")
    # Reacquiring restores the remembered level, with fresh rolled attributes.
    check(sim.add_item("wood_axe") and int(sim.record("wood_axe").merge)==3,"The Wood Axe found again is ^3")
    check(SaveService.save_now(),"Post-Prestige profile saves")
    reload()
    check(int(sim.state.merge_memory.get("wood_axe",0))==3 and is_equal_approx(float(sim.state.coins),coins_before+240.0),"Reload keeps the settled Prestige")

func rollback_checks() -> void:
    clear_files()
    prestige_fixture()
    var coins_before: float=float(sim.state.coins)
    check(sim.campaign.begin_prestige(),"Batch opens")
    reload();reload()
    check(not sim.state.prestige_batch.is_empty() and sim.quantity("wood_axe")==3,"An open batch survives two reloads with the run intact")
    var offered: Array=sim.campaign.offered_cards()
    SaveService.write_blocked=true
    check(not sim.campaign.choose_card(str(offered[0])),"A blocked write fails the final choice")
    check(is_equal_approx(float(sim.state.coins),coins_before) and sim.quantity("wood_axe")==3 and not sim.state.offline_pending.is_empty() and sim.state.prestige_batch.choices.is_empty(),"…and rolls everything back (no payout, items kept)")
    SaveService.write_blocked=false
    check(sim.campaign.choose_card(str(offered[0])),"The retry completes")
    var paid: float=float(sim.state.coins)
    reload();reload()
    check(is_equal_approx(float(sim.state.coins),paid) and sim.state.prestige_batch.is_empty() and sim.state.offline_pending.is_empty(),"Two reloads after the commit pay nothing twice")

func reset_checks() -> void:
    sim.state.merge_memory["wood_axe"]=9
    check(SaveService.hard_reset(),"Hard Reset completes")
    check(sim.state.merge_memory.is_empty() and int(sim.state.schema)==9,"Hard Reset clears merge memory")
    clear_files()
    var future: Dictionary=sim.snapshot();future.schema=99
    write_file(future)
    reload()
    check(FileAccess.file_exists(path("rejected_schema_99")),"A save this build cannot read is copied aside before the fresh profile")
    check(int(sim.state.schema)==9 and sim.state.items.is_empty(),"…and the game starts a fresh profile")
    clear_files()
