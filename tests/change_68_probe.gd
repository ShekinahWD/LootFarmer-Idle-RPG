extends Node
## Change 68 focused checks (real main scene and simulation; state set directly is labelled "fixture"):
## - Prices: Critical Chance 25 Gems x1.25, Critical Damage 15 Gems x1.25, ceil(base*growth^level) for all
##   20 levels; the button shows the debited price; other upgrades unchanged.
## - Stats: fresh 5% / 110%; +1 point and +10 points per level; rank 20 = 25% / 310%; caps 75% / x4 intact.
## - Player Upgrades rows show the effective stat now -> after the next level from sim.stats():
##   5% -> 6%, "Critical hits: 110% -> 120% damage"; with equipped gear, stored gear and Prestige cards;
##   a capped Critical Chance shows no fictitious gain; rank 20 shows MAX with the real value.
## - Combat: a critical hit deals 1.10x at level 0 and 1.20x at level 1 of the same non-critical hit.
## - Save/load and Prestige keep the owned levels; nothing refunded; same totals and prices after reload.
## Pass --capture=<dir> to also save the Player Upgrades tab at the current window size.
var checks:=0
var failures:=0
var game
var sim
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
    else:print("  ok  ",label_)
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame
func near(a: float,b: float) -> bool:return absf(a-b)<1e-6
func _ready() -> void:call_deferred("run")

func run() -> void:
    SettingsState.mute_all_sfx()
    TranslationServer.set_locale("en")
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    await frames()
    price_checks()
    stat_checks()
    combat_checks()
    persistence_checks()
    await ui_checks()
    var capture:=""
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--capture="):capture=arg.trim_prefix("--capture=")
    if capture!="":await capture_rows(capture)
    print("CHANGE_68_CHECKS %d FAILURES %d" % [checks,failures])
    get_tree().quit(1 if failures>0 else 0)

func fresh() -> void:
    get_tree().paused=false
    sim.held=false
    sim.new_profile();sim.set_physics_process(false);sim.suspended=false;SaveService.write_blocked=false
    sim.state.tutorial.mode="none";sim.campaign.onboarding.reveal_all(true)
    game._close();game.banner.queue.clear();game.banner._finish();game.toast_queue.clear();game.get_node("Toast").hide()
    sim.state.player.quiet=1e9
    for e in sim.state.enemies:e.aggro=false
func reload() -> void:
    sim.restore(JSON.parse_string(JSON.stringify(sim.snapshot())))

func price_checks() -> void:
    print("-- prices")
    fresh()
    var cc: Dictionary=sim.catalog.upgrades.critical_chance
    var cd: Dictionary=sim.catalog.upgrades.critical_damage
    check(int(cc.base)==25 and near(float(cc.growth),1.25) and int(cc.cap)==20 and near(float(cc.effect),.01),"Critical Chance: 25 Gems, x1.25, 20 levels of +1 point")
    check(int(cd.base)==15 and near(float(cd.growth),1.25) and int(cd.cap)==20 and near(float(cd.effect),.1),"Critical Damage: 15 Gems, x1.25, 20 levels of +10 points")
    sim.state.gems=1e9
    for id in ["critical_chance","critical_damage"]:
        var base:=25 if id=="critical_chance" else 15
        var prices: Array=[]
        var ok:=true
        for i in range(20):
            var price: int=sim.upgrade_cost(id)
            prices.append(price)
            var before: float=sim.state.gems
            ok=ok and price==ceili(base*pow(1.25,i)) and sim.buy_upgrade(id) and near(before-sim.state.gems,price)
        check(ok,"%s: 20 purchases debit ceil(%d x 1.25^level): %s" % [id,base,str(prices)])
        check(not sim.buy_upgrade(id) and sim.level(id)==20,id+": level 21 refused")
    fresh()
    check(sim.upgrade_cost("critical_chance")==25 and sim.upgrade_cost("critical_damage")==15,"Level 1 costs 25 / 15")
    sim.state.gems=1e6;sim.buy_upgrade("critical_chance");sim.buy_upgrade("critical_damage")
    check(sim.upgrade_cost("critical_chance")==32 and sim.upgrade_cost("critical_damage")==19,"Level 2 costs 32 / 19")
    fresh()
    check(sim.upgrade_cost("gem_chance")==10 and sim.upgrade_cost("gem_amount")==25 and sim.upgrade_cost("boss_gem_chance")==50 and sim.upgrade_cost("focus")==25 and sim.upgrade_cost("skill_auto_slots")==100,"Other Gem upgrades unchanged")

func stat_checks() -> void:
    print("-- stats")
    fresh()
    check(near(sim.stats().crit,.05) and near(sim.stats().crit_damage,1.1),"Fresh profile: 5% / 110%")
    check(near(sim.stats_with_upgrade("critical_chance").crit,.06) and near(sim.stats_with_upgrade("critical_damage").crit_damage,1.2),"Preview +1: 6% / 120%")
    check(near(sim.stats().crit,.05) and near(sim.stats().crit_damage,1.1) and sim.level("critical_chance")==0,"Preview is non-mutating")
    for n in [1,5,10,15,20]:
        sim.state.upgrades["critical_chance"]=n;sim.state.upgrades["critical_damage"]=n;sim.touch() # fixture
        check(near(sim.stats().crit,.05+.01*n) and near(sim.stats().crit_damage,1.1+.1*n),"Rank %d: %s%% / %s%%" % [n,str(roundi(sim.stats().crit*100)),str(roundi(sim.stats().crit_damage*100))])
    sim.record("wood_sword").extras={"crit":10.0,"crit_damage":10.0};sim.add_item("wood_sword");sim.equip("wood_sword");sim.touch() # fixture
    check(near(sim.stats().crit,1.0) and near(sim.stats().crit_damage,13.1),"No caps: chance stops at 100%, damage 1,310%")
    sim.record("wood_sword").extras={"crit":.6,"crit_damage":5.0};sim.touch() # fixture: past the old 75% / x4
    check(near(sim.stats().crit,.85) and near(sim.stats().crit_damage,8.1),"Old caps gone: 85% / 810%")

func crit_ratio() -> float:
    # Same victim, same attacker: the critical hit's damage over the non-critical hit's damage.
    var victim: Dictionary=sim.state.enemies[1]
    var hits:={}
    for i in range(200):
        victim.hp=1e7;victim.x=sim.state.player.x+5;victim.y=sim.state.player.y
        var before: float=victim.hp
        sim._start_attack(sim.state.player,victim,1.0)
        sim._resolve_attack(sim.state.player,.23)
        hits[bool(victim.get("critical_hit",false))]=before-victim.hp
        if hits.size()==2:break
    return float(hits.get(true,0.0))/maxf(1e-9,float(hits.get(false,0.0)))

func combat_checks() -> void:
    print("-- combat")
    fresh();sim.state.upgrades["critical_chance"]=20;sim.touch() # fixture: 25% so both outcomes occur
    check(absf(crit_ratio()-1.1)<1e-4,"Critical hit = 1.10x the same non-critical hit")
    sim.state.upgrades["critical_damage"]=1;sim.touch()
    check(absf(crit_ratio()-1.2)<1e-4,"With one Critical Damage level: 1.20x")

func persistence_checks() -> void:
    print("-- save / Prestige")
    fresh();sim.state.upgrades["critical_chance"]=7;sim.state.upgrades["critical_damage"]=4;sim.state.gems=3.0 # fixture: old purchases
    reload()
    check(sim.level("critical_chance")==7 and sim.level("critical_damage")==4 and near(sim.state.gems,3.0),"Old levels load intact, no refund")
    check(near(sim.stats().crit,.12) and near(sim.stats().crit_damage,1.5),"Old levels give 12% / 150% under the new rule")
    check(sim.upgrade_cost("critical_chance")==ceili(25*pow(1.25,7)) and sim.upgrade_cost("critical_damage")==ceili(15*pow(1.25,4)),"Next prices from saved levels")
    # Real Prestige transaction with an earned opportunity (change_17 fixture convention).
    sim.state.reward_stage=8
    sim.state.bosses_found.append("boss-snowman")
    sim.state.opportunities.expedition_1={"ready":true,"baseline":{},"step":0,"count":0}
    sim.state.group_kills[sim.campaign.prestige_unlock_group()]=1 # fixture: first boss defeated
    if not sim.campaign.awardable_ids().is_empty() and sim.campaign.begin_prestige():
        var guard:=0
        while not sim.state.prestige_batch.is_empty() and guard<40:
            guard+=1
            sim.campaign.choose_card(str(sim.campaign.offered_cards()[0]))
    check(int(sim.state.prestiges)==1 and sim.level("critical_chance")==7 and sim.level("critical_damage")==4 and sim.upgrade_cost("critical_chance")==ceili(25*pow(1.25,7)),"Prestige keeps both levels and prices (prestiges %d, levels %d/%d)" % [int(sim.state.prestiges),sim.level("critical_chance"),sim.level("critical_damage")])

func benefit_label(id: String) -> String:
    for b in game.rows.find_children("*","Button",true,false):
        if b.get_meta("upgrade","")==id and b.is_visible_in_tree():
            var card: Node=b.get_parent()
            var labels: Array=card.find_children("*","Label",true,false)
            return labels[1].text if labels.size()>1 else ""
    return ""
func buy_text(id: String) -> String:
    for b in game.rows.find_children("*","Button",true,false):
        if b.get_meta("upgrade","")==id and b.is_visible_in_tree():return b.text
    return ""
func open_player() -> void:
    game._close();await frames(2)
    game.player_tab=0;game._open("upgrades");await frames(6)

func ui_checks() -> void:
    print("-- Player Upgrades rows")
    fresh();sim.state.gems=10000.0
    await open_player()
    check(benefit_label("critical_chance")=="5% → 6%","Fresh: Critical Chance reads '%s'" % benefit_label("critical_chance"))
    check(benefit_label("critical_damage")=="Critical hits: 110% → 120% damage","Fresh: Critical Damage reads '%s'" % benefit_label("critical_damage"))
    check(buy_text("critical_chance")==game.fmt_cost(25) and buy_text("critical_damage")==game.fmt_cost(15),"Buttons show 25 / 15")
    # Equipped gear, stored gear and Prestige cards all count, exactly as stats() does.
    sim.record("wood_sword").extras={"crit":.04,"crit_damage":.2};sim.add_item("wood_sword");sim.equip("wood_sword") # fixture
    sim.record("stone_sword").extras={"crit":.1,"crit_damage":.5};sim.add_item("stone_sword") # fixture: stored at 30%
    sim.state.owned_cards.append_array(["challenge_c1","challenge_c3"]);sim.touch() # fixture: Prestige +15 points, +75 points
    await open_player()
    var s: Dictionary=sim.stats()
    var cc_now: String=game.fmt_value(s.crit*100)+"%";var cc_next: String=game.fmt_value(sim.stats_with_upgrade("critical_chance").crit*100)+"%"
    var cd_now: String=game.fmt_value(s.crit_damage*100)+"%";var cd_next: String=game.fmt_value(sim.stats_with_upgrade("critical_damage").crit_damage*100)+"%"
    check(not stored_missing() and near(s.crit,.05+.04+.03+.15) and near(s.crit_damage,1.1+.2+.15+.75),"Gear/stored/Prestige fixture: %s / %s" % [cc_now,cd_now])
    check(benefit_label("critical_chance")==cc_now+" → "+cc_next and cc_now=="27%" and cc_next=="28%","With bonuses: '%s'" % benefit_label("critical_chance"))
    check(benefit_label("critical_damage")=="Critical hits: %s → %s damage" % [cd_now,cd_next] and cd_now=="220%" and cd_next=="230%","With bonuses: '%s'" % benefit_label("critical_damage"))
    sim.state.gems=10000.0
    var shown:=benefit_label("critical_damage")
    var buy: Button=null
    for b in game.rows.find_children("*","Button",true,false):
        if b.get_meta("upgrade","")=="critical_damage" and b.is_visible_in_tree():buy=b
    buy.pressed.emit();await frames(4)
    check(sim.level("critical_damage")==1 and near(sim.stats().crit_damage,2.3) and shown.contains("230%"),"Purchase matches the preview (230%)")
    await get_tree().create_timer(1.0,true,false,true).timeout;await frames(2)
    check(benefit_label("critical_damage")=="Critical hits: 230% → 240% damage","Row refreshes after the purchase: '%s'" % benefit_label("critical_damage"))
    # Critical Chance at 100%: no fictitious gain.
    sim.record("wood_sword").extras={"crit":1.0,"crit_damage":.2};sim.touch() # fixture
    await open_player()
    check(benefit_label("critical_chance")=="100% · every hit is already critical","At 100%%: '%s'" % benefit_label("critical_chance"))
    check(benefit_label("critical_damage").contains("→"),"Critical Damage never stops: '%s'" % benefit_label("critical_damage"))
    # Rank 20: the real value and MAX, no level-21 preview.
    fresh();sim.state.upgrades["critical_chance"]=20;sim.state.upgrades["critical_damage"]=20;sim.touch() # fixture
    await open_player()
    check(benefit_label("critical_chance")=="25% · maxed" and benefit_label("critical_damage")=="Critical hits: 310% damage · maxed","Rank 20: '%s' / '%s'" % [benefit_label("critical_chance"),benefit_label("critical_damage")])
    check(buy_text("critical_chance")==tr("UPGRADE_MAX"),"Rank 20 button reads MAX")
    # Stats panel uses the same numbers.
    game._close();await frames(2)
    game._open("stats");await frames(6)
    var found:=false
    for l in game.rows.find_children("*","Label",true,false):
        if l.text=="310% (×3.10)":found=true
    if not found:
        for l in game.rows.find_children("*","Label",true,false):print("    stats label: ",l.text)
    check(found,"Stats panel: Critical multiplier 310% (×3.10)")
    game._close();await frames(2)

func stored_missing() -> bool:
    return not sim.stat_sources().get("SOURCE_STORED",{}).has("crit")

func capture_rows(dir: String) -> void:
    fresh();sim.state.gems=10000.0;sim.state.upgrades["critical_damage"]=3;sim.touch() # fixture
    await open_player();await frames(10)
    var size:=get_viewport().get_visible_rect().size
    DirAccess.make_dir_recursive_absolute(dir)
    var path:="%s/change_68_upgrades_%dx%d.png" % [dir,int(size.x),int(size.y)]
    get_viewport().get_texture().get_image().save_png(path)
    print("CAPTURE ",path)
