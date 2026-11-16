extends Node
## Change 84 focused checks (real main scene and simulation; state set directly is labelled "fixture"). No combat
## ladders, balance sweeps or player profiles.
## 1. Heal icon: the Green Alien's head row shows Heal (its Change 13 kit casts Heal, which the catalog's skill list
##    never named); every other type's row is its catalog list; drops and mastery keep the catalog list.
## 2. Heal is used: below 50% it telegraphs and casts Heal (4%), starts the 10 s cooldown; above 50% it never heals;
##    Rage keeps its immediate Heal and +20%.
## 3. Attack: definition damage 1,245.5378 -> 968.7388 (x7/9), so a 900 hit becomes 700; HP, interval, defense,
##    Heal values and every other type unchanged; Rage does not change its outgoing hit.
## Run: Godot --headless --path . res://tests/change_84_probe.tscn -- --probe --profile=probe-c84 --no-autosave --first-run-complete
var checks:=0
var failures:=0
var game
var sim
var casts: Array=[]

func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
    else:print("  ok  ",label_)
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame
func _ready() -> void:call_deferred("run")

func run() -> void:
    get_tree().create_timer(300.0,true,false,true).timeout.connect(func():push_error("CHANGE_84 watchdog");get_tree().quit(2))
    SettingsState.mute_all_sfx()
    TranslationServer.set_locale("en")
    get_window().size=Vector2i(540,960)
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.spell_cast.connect(func(id: String,key: String,_at: Vector2)->void:casts.append([id,key]))
    await frames(6)
    await icon_checks()
    heal_checks()
    damage_checks()
    print("CHANGE_84_CHECKS %d FAILURES %d" % [checks,failures])
    game.queue_free();await frames(2);AudioService.stop_all_sfx()
    get_tree().quit(1 if failures>0 else 0)

# ---------------------------------------------------------------- fixtures (as in the Change 83 probe)
func fresh() -> void:
    get_tree().paused=false
    if game.final_dialog.is_open():game.final_dialog.close()
    sim.held=false
    sim.new_profile();sim.set_physics_process(false);sim.suspended=false;SaveService.write_blocked=false
    sim.state.tutorial.mode="none"
    sim.campaign.onboarding.reveal_all(true)
    sim.state.tutorial.seen.append("road_ahead")
    sim.state.tutorial.seen.append("final_intro")
    game._close();game.banner.queue.clear();game.banner._finish();game.toast_queue.clear();game.toast_important.clear();game.get_node("Toast").hide();game.toast_time=0.0
    casts.clear()
    SettingsState.restore_recommended()
func spring_two() -> void:
    sim.state.stage=8;sim.state.unlocked_stage=8;sim.state.spawns=[0,1,2];sim.state.camps["8"]=[0,1,2]
    sim.campaign.configure_stage();sim._reset_world() # fixture: Spring II reached, its camps owned
func alien() -> Dictionary:
    for a in sim.state.enemies:
        if bool(sim.catalog.groups[int(a.group)].final) and not sim.is_helper(a):return a
    return {}
func final_g() -> int:
    for g in range(sim.catalog.groups.size()):
        if bool(sim.catalog.groups[g].final):return g
    return -1
## The whole introduction done earlier (fixture: 13 keys, unsealed, warning and ceremony seen).
func introduced() -> void:
    sim.state.final_discovered=true
    sim.state.keys=[]
    for d in sim.catalog.groups:
        if d.boss and not d.final:sim.state.keys.append(str(d.id))
    sim.state.final_unsealed=true;sim.state.final_warning_ok=true;sim.state.final_experience=true
func sturdy() -> void:
    sim.state.player_level=500;sim._stats_revision=-1;sim.state.player.hp=sim.stats().hp
func place(offset: Vector2) -> void:
    var a:=alien()
    sim.state.player.x=float(a.home_x)+offset.x;sim.state.player.y=float(a.home_y)+offset.y
    sim.campaign.reveal()
func steps(seconds: float,dt:=.05) -> void:
    var t:=0.0
    while t<seconds-1e-6:
        sim.step(dt);t+=dt
func calm_boss() -> void:
    var a:=alien();a.cooldown=99.0;a.skill_timer=99.0;a.summon_cd=99.0 # fixture: the boss holds its attacks
func engaged() -> Dictionary:
    fresh();spring_two();sturdy();introduced()
    place(Vector2(30,0));steps(.1)
    return alien()
func maxhp() -> float:return float(sim.enemy_definition(final_g()).hp)

# ================================================================ 1. Heal icon
func icon_checks() -> void:
    print("-- Heal icon")
    var d: Dictionary=sim.catalog.groups[final_g()]
    check(d.skills==["focus","fire","strike"],"Cause: the catalog list has no Heal (%s); the final kit casts it anyway" % [d.skills])
    check(sim.campaign.shown_skills(d)==["focus","fire","strike","heal"],"Shown skills add Heal for the final boss")
    var others:=true
    for g in range(sim.catalog.groups.size()):
        var o: Dictionary=sim.catalog.groups[g]
        if not bool(o.final) and sim.campaign.shown_skills(o)!=Array(o.skills):others=false
    check(others,"Every other type shows exactly its catalog skills")
    check(sim.enemy_definition(final_g()).skills==["focus","fire","strike"],"Skill drops and mastery keep the catalog list (definition unchanged)")
    var a:=engaged();calm_boss()
    game.world._process(0);await frames(2)
    var view=game.world.views.get(str(a.id))
    check(view!=null,"Fixture: the Green Alien has a world view")
    if view==null:return
    var icons: Array=view.skill_icons
    check(icons.size()==4 and icons[3]!=null and icons[3]==game.world.textures.get("skill_heal"),"World: 4 icons over the Green Alien, the last the Heal icon")
    check(view._skills.visible and view._skills.get_child_count()==4,"World: the icon row is visible with 4 sprites")
    var shown:=0
    for e in sim.state.enemies:
        var o: Dictionary=sim.catalog.groups[int(e.group)]
        if not bool(o.final) and not sim.is_helper(e) and game.world.views.has(e.id):
            if game.world.views[e.id].skill_icons.size()!=sim.enemy_definition(int(e.group),int(e.get("variant",2))).skills.size():shown=-999
            shown+=1
    check(shown>0,"Other enemies on the map keep their own icon rows (%d checked)" % shown)

# ================================================================ 2. Heal use
func heal_checks() -> void:
    print("-- Heal use")
    var a:=engaged();calm_boss()
    a.skill_cds={};a.skill_timer=0.0
    a.hp=maxhp()*.6;casts.clear();steps(1.0)
    check(not casts.has([str(a.id),"heal"]),"Above 50%: no Heal")
    calm_boss();a.hp=maxhp()*.4;a.skill_timer=0.0;a.skill_cds={};casts.clear()
    check(sim.campaign.final_choice(a)=="heal","Below 50% and off cooldown: Heal comes first")
    var h0: float=a.hp
    steps(.05)
    check(bool(a.get("telegraph",false)) and str(a.get("pending",""))=="heal","Heal is telegraphed")
    steps(.8)
    check(casts.has([str(a.id),"heal"]),"Heal is cast (spell_cast heal)")
    check(absf(float(a.hp)-h0-maxhp()*.04)<maxhp()*.002,"It restores 4%% of max HP (%.0f)" % [float(a.hp)-h0])
    check(absf(float(a.skill_cds.get("heal",0))-10.0)<1.0,"…and starts the 10 s Heal cooldown (%.1f)" % float(a.skill_cds.get("heal",0)))
    check(sim.campaign.final_choice(a)!="heal","On cooldown it does not heal again")
    # Rage keeps its immediate Heal x1.2.
    a.skill_cds={};a.hp=maxhp()*.19;var r0: float=a.hp
    steps(.05)
    check(sim.campaign.enraged(a) and absf(float(a.hp)-r0-maxhp()*.048)<maxhp()*.002,"Rage: one immediate Heal of 4.8% (unchanged)")
    a.hp=maxhp()*.3;a.skill_cds.heal=0.0;var r1: float=a.hp
    check(sim.campaign.apply_skill(a,"heal",float(sim.catalog.skills.heal.power)) and absf(float(a.hp)-r1-maxhp()*.048)<1.0,"Rage: a later Heal restores +20% (4.8%)")
    check(is_equal_approx(float(sim.abilities.final_heal_fraction),.04) and is_equal_approx(float(sim.abilities.final_heal_below),.5) and is_equal_approx(sim.campaign.RAGE_HEAL,1.2),"Heal values unchanged (4%, below 50%, Rage x1.2)")

# ================================================================ 3. Attack
func boss_hit(a: Dictionary) -> float:
    var p: Dictionary=sim.state.player
    p.hp=sim.stats().hp;p.x=float(a.x)+10;p.y=float(a.y)
    a.target="player";a.windup=.0001
    var h0: float=p.hp
    sim._resolve_attack(a,.05)
    return h0-float(p.hp)

func damage_checks() -> void:
    print("-- Attack damage")
    var d: Dictionary=sim.catalog.groups[final_g()]
    check(absf(float(d.damage)-968.7388)<.001 and sim.catalog.progression.balance.boss_tuning["boss-green-alien"]==[0.6,2.5293],"Attack 1,245.5378 -> %s (boss_tuning 3.252 -> 2.5293)" % [d.damage])
    check(absf(float(d.damage)/1245.5378-7.0/9.0)<1e-4,"x7/9 (tuning rounded to 4 places): a 900 hit becomes %.1f" % [900.0*float(d.damage)/1245.5378])
    check(absf(float(d.hp)-182708.2142)<.01 and is_equal_approx(float(d.interval),1.3) and float(d.defense)==0.0 and int(d.respawn)==120,"HP, interval, defense and respawn unchanged")
    check(sim.catalog.progression.balance.boss_tuning["boss-sunflower"]==[0.3,1.356] and sim.catalog.progression.balance.boss_tuning["boss-red-panda"]==[0.3,1.485],"Other bosses' tuning unchanged")
    var a:=engaged();calm_boss()
    var mult: float=sim.campaign.damage_multiplier(a,sim.state.player)
    var defense: float=float(sim.stats().defense)
    var expected: float=float(d.damage)*mult*100.0/(100.0+defense)
    var hit:=boss_hit(a)
    check(absf(hit-expected)<.01,"Real hit on the probe hero: %.1f (definition x %.2f x 100/(100+%.1f defense))" % [hit,mult,defense])
    check(absf(hit/(1245.5378*mult*100.0/(100.0+defense))-7.0/9.0)<1e-4,"…7/9 of the Change 83 hit for the same hero")
    a.rage=true
    var raged:=boss_hit(a)
    check(absf(raged-hit)<.01 and is_equal_approx(sim.campaign.attack_speed_factor(a),1.5),"Rage: same hit, attacks x1.5 as often (unchanged)")
    a.rage=false
