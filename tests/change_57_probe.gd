extends "res://tests/change_20_probe.gd"
## Change 57 (B8 release readiness): real save files written by the released pre-update build (commit 3dd2eab,
## schema 8; tests/fixtures/old_saves, generated with that build's own APIs) load in this build from disk.
## For each: the load is "primary" (no reset), schema 9 with both migrations once, an untouched schema 8 copy
## is kept, combat stats equal the old build's (old-stat weapons became legacy copies), merge memory holds every
## historical level, nothing is lost (Coins, Gems, cards, consumed ids, unclaimed main objectives, finished
## missions, pending offline earnings), loading twice changes nothing, and a Prestige afterwards applies the
## approved rules. The open-batch save resumes and pays once. Runs with --first-run-complete.
const FIXTURES:="res://tests/fixtures/old_saves/schema8_%s.json"
func run() -> void:
    get_window().size=Vector2i(720,1280)
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    await frames(6)
    fresh_checks()
    mid_checks()
    late_checks()
    batch_checks()
    clear_files()
    print("CHANGE_57_CHECKS %d FAILURES %d" % [checks,failures])
    game.queue_free();await frames();AudioService.stop_all_sfx();get_tree().quit(1 if failures else 0)

func path(tag:="") -> String:
    return SaveService.save_path() if tag=="" else SaveService.save_path().trim_suffix(".json")+"."+tag+".json"
func clear_files() -> void:
    for f in [path(),path()+".bak",path()+".tmp",path("schema8_backup"),path("rejected_invalid"),path("rejected_schema_8")]:
        if FileAccess.file_exists(f):DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
## Installs a fixture as this profile's save file and loads it like a game start.
func install(name: String) -> Dictionary:
    clear_files()
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BootContext.save_directory()))
    var text:=FileAccess.get_file_as_string(FIXTURES % name)
    var f:=FileAccess.open(path(),FileAccess.WRITE);f.store_string(text);f.close()
    reload()
    return JSON.parse_string(text)
func reload() -> void:
    SaveService.last_load_result=""
    SaveService.load_and_apply()
    # Harness state (as fresh()): the probe drives actions directly, with no step running.
    sim.set_physics_process(false);sim.suspended=false;get_tree().paused=false
func near(a: float,b: float) -> bool:return absf(a-b)<=1e-4*maxf(1.0,absf(b))
## No stat may fall. A weapon kept above its new merge cap now also earns the existing at-cap stock bonus
## (+0.05% per spare copy), so a stat may rise by at most 1%.
func same_stats(old: Dictionary,label: String) -> void:
    var now: Dictionary=sim.stats()
    var bad: Array=[]
    for k in old:
        var a: float=float(old[k]);var b: float=float(now.get(k,0.0))
        if b<a-1e-6*maxf(1.0,absf(a)) or b>a*1.01+1e-6:bad.append("%s %s->%s" % [k,a,b])
    check(bad.is_empty(),"%s: no combat stat lost against the old build (at most the at-cap stock bonus gained) %s" % [label,str(bad)])
func common(name: String,old: Dictionary) -> void:
    check(SaveService.last_load_result=="primary","%s: loads as the primary save (%s)" % [name,SaveService.last_load_result])
    check(int(sim.state.schema)==9 and sim.state.migrations.count("schema9_merge_memory")==1 and sim.state.migrations.count("legacy_weapons_h24")==1,"%s: schema 9, each migration once" % name)
    check(FileAccess.file_exists(path("schema8_backup")) and int(JSON.parse_string(FileAccess.get_file_as_string(path("schema8_backup"))).sections.lootfarmer.schema)==8,"%s: untouched schema 8 copy kept" % name)
    var s: Dictionary=old.sections.lootfarmer
    check(near(float(sim.state.coins),float(s.coins)) and near(float(sim.state.gems),float(s.gems)) and int(sim.state.player_level)==int(s.player_level),"%s: Coins, Gems and level unchanged" % name)
    check(sim.state.owned_cards==s.owned_cards and sim.state.consumed==s.consumed,"%s: cards and consumed opportunities unchanged" % name)
    var first: String=JSON.stringify([sim.state.items,sim.state.merge_memory,sim.state.coins,sim.state.owned_cards])
    check(SaveService.save_now(),"%s: saves" % name)
    reload();reload()
    var again: String=JSON.stringify([sim.state.items,sim.state.merge_memory,sim.state.coins,sim.state.owned_cards])
    check(SaveService.last_load_result=="primary" and JSON.parse_string(first)==JSON.parse_string(again),"%s: two more loads change nothing" % name)

func fresh_checks() -> void:
    var old:=install("fresh")
    common("fresh",old)
    same_stats(old._old_build_stats,"fresh")

func mid_checks() -> void:
    var old:=install("mid")
    common("mid",old)
    same_stats(old._old_build_stats,"mid")
    check(sim.quantity("stone_axe_legacy")==3 and int(sim.record("stone_axe_legacy").merge)==60 and sim.state.weapon=="stone_axe_legacy","mid: the equipped Stone Axe ^60 is its legacy copy (old power)")
    check(sim.quantity("wood_sword")==6 and int(sim.record("wood_sword").merge)==40,"mid: Wood Sword (unchanged stats) keeps ^40 above the new cap")
    var m: Dictionary=sim.state.merge_memory
    check(int(m.get("wood_sword",0))==40 and int(m.get("stone_axe",0))==60 and int(m.get("iron_sword",0))==70 and int(m.get("unit-straw-hat_outfit_t2",0))==150 and int(m.get("unit-blue-cap_outfit",0))==120,"mid: merge memory holds current and historical levels %s" % str(m))
    check(not sim.state.items.has("iron_sword"),"mid: a remembered level grants no item")
    check(sim.state.main_ready.has("3") and not sim.state.offline_pending.is_empty(),"mid: the earned main objective and the offline claim are still there")
    var mission: Dictionary=sim.state.missions[0]
    check(float(mission.progress)>=float(mission.goal) and not mission.claimed,"mid: the finished mission is still claimable")
    # The fixture's departure snapshot also settles the minutes since it was written into the same claim.
    var coins: float=float(sim.state.coins)
    var pending: float=float(sim.state.offline_pending.coins)
    check(pending>=180.0 and sim.campaign.claim_offline() and sim.quantity("wood_sword")>=7 and near(float(sim.state.coins),coins+pending),"mid: the offline claim pays once (%.0f Coins and the Wood Sword copy)" % pending)
    var paid: float=float(sim.state.coins)
    reload()
    check(sim.state.offline_pending.is_empty() or float(sim.state.offline_pending.coins)<pending,"mid: …and is not paid again after a reload")
    # A Prestige on the migrated profile: approved rules.
    sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0}
    var upgrades: Dictionary=sim.state.upgrades.duplicate()
    coins=float(sim.state.coins)
    check(sim.campaign.begin_prestige() and sim.campaign.choose_card(str(sim.campaign.offered_cards()[0])),"mid: Prestige")
    check(float(sim.state.coins)>=coins and sim.state.upgrades==upgrades and sim.state.items.is_empty() and sim.state.main_ready.has("3"),"mid: Coins and upgrades kept, items reset, main objective still claimable")
    check(sim.add_item("stone_axe") and int(sim.record("stone_axe").merge)==60 and near(float(sim.normal("stone_axe").damage),7.6*.8*(1+.02*60)),"mid: a new Stone Axe has the new stats at the remembered ^60")

func late_checks() -> void:
    var old:=install("late")
    common("late",old)
    same_stats(old._old_build_stats,"late")
    check(sim.state.weapon=="diamond_sword_legacy" and int(sim.record("diamond_sword_legacy").merge)==100,"late: the Diamond Sword ^100 is its legacy copy, equipped")
    check(sim.quantity("gold_axe_legacy")==4 and sim.quantity("emerald_sword_legacy")==1,"late: stored old-stat weapons became legacy copies")
    check(sim.state.gear.size()==13 and sim.state.owned_cards.size()==20,"late: 13 equipment slots and 20 cards")
    for c in sim.catalog.campaign.combos:
        if (c.cards as Array).all(func(id):return sim.state.owned_cards.has(id)):check(sim.campaign.combo_owned(c),"late: Set %s active" % c.id)
    check(int(sim.state.merge_memory.get("diamond_sword",0))==100 and int(sim.state.merge_memory.get("obsidian_sword",0))==5,"late: canonical merge memory kept (Diamond ^100, Obsidian ^5)")
    var awardable: Array=sim.campaign.awardable_ids()
    for op in sim.catalog.campaign.opportunities:
        if not str(op.id).right(1) in ["1","2","3"]:check(not sim.state.consumed.has(op.id),"late: new opportunity %s not consumed" % op.id)

func batch_checks() -> void:
    var old:=install("batch")
    check(SaveService.last_load_result=="primary" and not sim.state.prestige_batch.is_empty(),"batch: the open Prestige batch survives the update")
    reload()
    check(not sim.state.prestige_batch.is_empty() and sim.quantity("wood_axe")==5,"batch: and a second load")
    var offered: Array=sim.campaign.offered_cards()
    check(offered.size()==4,"batch: Hunter now offers its four cards (%d)" % offered.size())
    check(sim.campaign.choose_card(str(offered[0])) and sim.state.prestige_batch.is_empty() and float(sim.state.coins)>=777.0,"batch: the choice completes the Prestige; Coins kept (%.0f)" % float(sim.state.coins))
    check(int(sim.state.merge_memory.get("wood_axe",0))==12 and sim.state.items.is_empty(),"batch: the run's Wood Axe ^12 is remembered, items reset")
    reload();reload()
    var after: float=float(sim.state.coins)
    reload()
    check(sim.state.prestige_batch.is_empty() and int(sim.state.prestiges)==1 and near(float(sim.state.coins),after),"batch: reloads after the commit change nothing")
