extends Node
## Change 81 focused checks (real main scene and simulation; state set directly is labelled "fixture"):
## 1. Camp Reveal Radius: one global permanent Gem upgrade, 10/20/40 Gems, +25% of the base camp radius per level
##    for every owned camp (later camps and other maps too); no per-camp purchase route; save/load, Prestige,
##    Hard Reset; the one-time migration of per-camp records (best camp level, at most 3).
## 2. Auto Skill: slot N needs manual Skill Slot N, on both purchase ids; no Gems taken when refused; the locked
##    reason in the UI; capacity bought before the rule is kept and only activates on owned slots.
## 3. Spring I / Spring II enemy attack damage x1.5 (normal types every variant, bosses, summoned helpers); enemy
##    skills scale from that one damage value (no second x1.5); intervals, heals and Focus unchanged; earlier
##    stages unchanged; Spring boss HP x2/3 (the first-clear correction).
## 4. Green Alien: hidden before discovery, the introduction once, the sealed-boss tap, the Boss Keys chip on every
##    map, 13 distinct keys, Ready to Challenge, Prestige, the final defeat; "Enemy types defeated" on Spring II.
## 5. Boss-key pickup: credited and saved before the animation, once per new key, tap or automatic, a covered or
##    hidden chip, Prestige reset; the chip count follows the landing.
## 6. Level cap 500: XP curve unchanged, level-ups to the cap, MAX state, saves above the cap, Prestige.
## 7. Obsidian Sword / Axe to ^500: caps, the 0.5 tail, ^100 saves, milestones ^100-^500 (equipped only, once),
##    merge previews, Merge All / Auto-Merge, save/load, other weapons unchanged.
## Run: Godot --headless --path . res://tests/change_81_probe.tscn -- --probe --profile=probe-c81 --no-autosave --first-run-complete
var checks:=0
var failures:=0
var game
var sim
var key_events: Array=[]

func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
    else:print("  ok  ",label_)
func near(a: float,b: float,eps:=1e-6) -> bool:return absf(a-b)<=eps
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame
func _ready() -> void:call_deferred("run")

func run() -> void:
    get_tree().create_timer(900.0,true,false,true).timeout.connect(func():push_error("CHANGE_81 watchdog");get_tree().quit(2))
    SettingsState.mute_all_sfx()
    TranslationServer.set_locale("en")
    get_window().size=Vector2i(720,1280)
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.key_earned.connect(func(g: int,_at: Vector2,total: int)->void:key_events.append([g,total]))
    await frames(6)
    camp_radius_checks()
    await camp_radius_persistence_checks()
    camp_radius_migration_checks()
    await camp_radius_ui_checks()
    auto_skill_checks()
    await auto_skill_ui_checks()
    combat_data_checks()
    combat_skill_checks()
    await final_boss_checks()
    await key_fx_checks()
    await level_cap_checks()
    obsidian_checks()
    await obsidian_persistence_checks()
    await obsidian_ui_checks()
    print("CHANGE_81_CHECKS %d FAILURES %d" % [checks,failures])
    game.queue_free();await frames(2);AudioService.stop_all_sfx()
    get_tree().quit(1 if failures>0 else 0)

func fresh() -> void:
    get_tree().paused=false
    sim.held=false
    sim.new_profile();sim.set_physics_process(false);sim.suspended=false;SaveService.write_blocked=false
    sim.state.tutorial.mode="none"
    sim.campaign.onboarding.reveal_all(true)
    sim.state.tutorial.seen.append("road_ahead")
    game._close();game.banner.queue.clear();game.banner._finish();game.toast_queue.clear();game.toast_important.clear();game.get_node("Toast").hide();game.toast_time=0.0
    game.key_fx.clear()
    key_events.clear()

func gi(id: String) -> int:
    for g in range(sim.catalog.groups.size()):
        if sim.catalog.groups[g].id==id:return g
    return -1

func texts(node: Node,out: Array) -> Array:
    if (node is Label or node is Button or node is RichTextLabel) and node.is_visible_in_tree():out.append(str(node.text))
    for c in node.get_children():texts(c,out)
    return out

func do_prestige() -> bool:
    var g: int=sim.campaign.prestige_unlock_group()
    if not sim.state.bosses_found.has("boss-snowman"):sim.state.bosses_found.append("boss-snowman") # fixture: found
    if int(sim.state.group_kills[g])<1:sim.state.group_kills[g]=1 # fixture: defeated once
    sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0} # fixture: ready
    sim.state.consumed.erase("hunter_o1")
    if not sim.campaign.begin_prestige():return false
    var guard:=0
    while not sim.state.prestige_batch.is_empty() and guard<40:
        guard+=1
        if not sim.campaign.choose_card(str(sim.campaign.offered_cards()[0])):return false
    return sim.state.prestige_batch.is_empty()

# ================================================================ 1. Camp Reveal Radius
func camp_radius_checks() -> void:
    print("-- Camp Reveal Radius: one global Gem upgrade")
    var d: Dictionary=sim.catalog.upgrades.camp_radius
    check(str(d.currency)=="gems" and str(d.scope)=="global" and int(d.cap)==3 and Array(d.prices)==[10.0,20.0,40.0] and near(float(d.effect),.25),"Catalog: Gems, global, 3 levels at 10 / 20 / 40, +25% each")
    fresh()
    sim.state.gems=1000 # fixture: Gems granted
    var base: float=sim.campaign.fog_rules.camp_radius
    check(sim.level("camp_radius")==0 and near(sim.campaign.camp_reveal_radius(),base),"Level 0: the base camp radius (%.0f)" % base)
    var paid: Array=[]
    for n in range(3):
        var before: int=int(sim.state.gems)
        var cost: int=sim.upgrade_cost("camp_radius")
        check(sim.buy_upgrade("camp_radius"),"Buy level %d" % (n+1))
        paid.append(before-int(sim.state.gems))
        check(paid[-1]==cost,"…charged exactly its price (%d)" % cost)
        check(near(sim.campaign.camp_reveal_radius(),base*(1.0+.25*(n+1))),"…radius +%d%% of the base" % (25*(n+1)))
    check(paid==[10,20,40] and 1000-int(sim.state.gems)==70,"Paid 10 + 20 + 40 = 70 Gems")
    var gems: int=int(sim.state.gems)
    check(not sim.buy_upgrade("camp_radius") and int(sim.state.gems)==gems and sim.upgrade_block_reason("camp_radius")=="UPGRADE_MAX","A 4th level is refused and costs nothing")
    check(not sim.buy_upgrade("camp_radius",10) and int(sim.state.gems)==gems,"No per-camp purchase route (camp_radius:10 refused, nothing charged)")
    check(sim.level("camp_radius",10)==3 and sim.level("camp_radius",81)==3,"Any group argument reads the one global level")
    # Every owned camp, on any map, reveals the same radius (reveal() reads it per camp).
    sim.state.explored={} # fixture: unexplored maps
    sim.state.player.x=-500;sim.state.player.y=-500 # fixture: the hero far outside the map
    sim.campaign.reveal()
    var a: Array=sim.campaign.stage().spawns[0]
    var inside:=Vector2(a[0],a[1])+Vector2(base*1.6,0)
    var outside:=Vector2(a[0],a[1])+Vector2(base*1.9,0)
    check(sim.campaign.cell_known(inside) and not sim.campaign.cell_known(outside),"Winter I camp 0 reveals 1.75x the base radius")
    sim.state.camps["3"]=[0,1];sim.state.unlocked_stage=3;sim.campaign.camp_action(3,1,true) # fixture: camps on Summer I; travel
    sim.state.explored.erase("3")
    sim.state.player.x=-500;sim.state.player.y=-500
    sim.campaign.reveal()
    var b: Array=sim.campaign.stage().spawns[1]
    var mid:=Vector2(sim.campaign.stage().size[0],sim.campaign.stage().size[1])*.5
    check(int(sim.state.stage)==3 and sim.campaign.cell_known(Vector2(b[0],b[1])+(mid-Vector2(b[0],b[1])).normalized()*base*1.6),"A camp on another map (Summer I camp 1) gets the same radius")
    var c: Array=sim.campaign.stage().spawns[2]
    sim.state.coins=1e9;sim.state.camps_known["3"]=[0,1,2] # fixture: Coins, the camp found on the map
    check(sim.campaign.camp_action(3,2,false),"Buy Summer I camp 2")
    sim.state.player.x=-500;sim.state.player.y=-500
    sim.campaign.reveal()
    var centre:=Vector2(sim.campaign.stage().size[0],sim.campaign.stage().size[1])*.5
    var probe:=Vector2(c[0],c[1])+(centre-Vector2(c[0],c[1])).normalized()*base*1.6
    check(sim.state.camps["3"].has(2) and sim.campaign.cell_known(probe),"A camp bought later gets the bonus at once")

func camp_radius_persistence_checks() -> void:
    print("-- Camp Reveal Radius: save, Prestige, Hard Reset")
    fresh()
    sim.state.gems=200;sim.buy_upgrade("camp_radius");sim.buy_upgrade("camp_radius")
    check(SaveService.save_now(),"Disk save")
    sim.state.upgrades.erase("camp_radius") # fixture: in-memory loss the reload must undo
    SaveService.load_and_apply();await frames(2)
    check(sim.level("camp_radius")==2,"Reload keeps level 2")
    check(do_prestige() and sim.level("camp_radius")==2,"Prestige keeps it (permanent Gem upgrade)")
    check(SaveService.hard_reset(),"Hard Reset");await frames(2)
    check(sim.level("camp_radius")==0,"Hard Reset clears it")

func migrate(upgrades: Dictionary) -> Dictionary:
    var snap: Dictionary=sim.snapshot()
    snap.migrations=Array(snap.migrations).filter(func(m):return m!="camp_radius_global")
    snap.upgrades=upgrades
    return sim.campaign.normalize_snapshot(snap)

func camp_radius_migration_checks() -> void:
    print("-- Camp Reveal Radius: per-camp saves")
    fresh()
    sim.state.camps["2"]=[0,1];sim.state.unlocked_stage=2 # fixture
    var out: Dictionary=migrate({"camp_radius:10":2,"camp_radius:21":4,"camp_radius:11":1,"gem_chance":3}) # fixture: Change 80 records
    check(int(out.upgrades.get("camp_radius",0))==3 and not out.upgrades.has("camp_radius:10") and not out.upgrades.has("camp_radius:21") and not out.upgrades.has("camp_radius:11"),"Best camp level 4 -> global 3 (MAX), per-camp records removed: %s" % [out.upgrades])
    check(int(out.upgrades.gem_chance)==3,"Other upgrades untouched")
    check(sim.campaign.legacy_camp_radius=={"records":3,"best":4,"level":3},"Report: %s" % [sim.campaign.legacy_camp_radius])
    check(Array(out.migrations).has("camp_radius_global") and sim.campaign.valid_snapshot(out),"Migration recorded; the save is valid")
    var again: Dictionary=sim.campaign.normalize_snapshot(out)
    check(again.upgrades==out.upgrades,"Migrating twice changes nothing")
    out=migrate({"camp_radius:10":1})
    check(int(out.upgrades.get("camp_radius",0))==1,"One camp at level 1 -> global level 1")
    out=migrate({"camp_radius:10":"x","camp_radius:12":0})
    check(not out.upgrades.has("camp_radius") and not out.upgrades.has("camp_radius:10"),"Malformed / zero records -> nothing granted")
    out=migrate({})
    check(not out.upgrades.has("camp_radius") and Array(out.migrations).has("camp_radius_global"),"No records -> level 0")
    var snap: Dictionary=sim.snapshot()
    snap.migrations=Array(snap.migrations).filter(func(m):return m!="camp_radius_global")
    snap.upgrades={"camp_radius:10":3}
    sim.restore(snap)
    check(sim.level("camp_radius")==3 and sim.campaign.camp_reveal_radius()>sim.campaign.fog_rules.camp_radius*1.7,"A restored old save reveals with the migrated level")

func camp_radius_ui_checks() -> void:
    print("-- Camp Reveal Radius: UI")
    fresh()
    sim.state.gems=100
    game.player_tab=0;game._open("upgrades");await frames(4)
    var buttons: Array=game.action_buttons.filter(func(b):return str(b.id)=="camp_radius")
    check(buttons.size()==1 and int(buttons[0].group)==-1 and str(buttons[0].node.text)=="10","Upgrades > Player: one Camp reveal radius card, 10 Gems")
    check(" | ".join(texts(game,[])).contains("Camp reveal radius (all camps)"),"The card says it is for all camps")
    game._close()
    game._open("world");await frames(4)
    check(game.action_buttons.filter(func(b):return str(b.id)=="camp_radius").is_empty(),"World offers no per-camp radius purchase")
    check(" | ".join(texts(game,[])).contains("Camp reveal radius: +0% on every camp"),"World names the shared radius")
    game._close()
    sim.buy_upgrade("camp_radius")
    game.selected_camp=0;game._open("camp");await frames(4)
    check(" | ".join(texts(game,[])).contains("+25% Camp reveal radius"),"The camp panel shows the camp's actual radius")
    game._close()

# ================================================================ 2. Auto Skill
func auto_skill_checks() -> void:
    print("-- Auto Skill needs its skill slot")
    fresh()
    sim.state.skills_seen=["heal"] # fixture: a skill found
    sim.state.gems=5000
    check(sim.upgrade_block_reason("skill_auto_slots")=="" and sim.buy_upgrade("skill_auto_slots") and sim.automatic_skill_capacity()==1,"Slot 1 (the default skill slot) can be automated: 100 Gems")
    var gems: int=int(sim.state.gems)
    check(sim.upgrade_block_reason("skill_auto_slots")=="AUTO_SKILL_NEEDS_SLOT" and sim.auto_skill_required_slot()==2,"Slot 2 locked: needs Skill Slot 2")
    check(not sim.buy_upgrade("skill_auto_slots") and not sim.buy_upgrade("skill_auto_1") and not sim.buy_upgrade("skill_auto_0") and int(sim.state.gems)==gems and sim.automatic_skill_capacity()==1,"Both purchase ids refused, no Gems taken")
    check(sim.buy_upgrade("skill_slots") and sim.upgrade_block_reason("skill_auto_slots")=="","Buying Skill Slot 2 unlocks it")
    gems=int(sim.state.gems)
    check(sim.buy_upgrade("skill_auto_1") and gems-int(sim.state.gems)==250 and sim.automatic_skill_capacity()==2,"Slot 2 automated for 250 Gems (price unchanged)")
    check(sim.upgrade_block_reason("skill_auto_slots")=="AUTO_SKILL_NEEDS_SLOT" and sim.auto_skill_required_slot()==3 and not sim.buy_upgrade("skill_auto_slots"),"Slot 3 locked until Skill Slot 3")
    check(sim.buy_upgrade("skill_slots") and sim.buy_upgrade("skill_auto_slots") and sim.automatic_skill_capacity()==3,"Skill Slot 3 then slot 3 automated")
    check(sim.upgrade_block_reason("skill_auto_slots")=="UPGRADE_MAX","All three: MAX")
    print("-- Auto Skill: capacity bought before the rule")
    fresh()
    sim.state.skills_seen=["heal","fire"]
    var snap: Dictionary=sim.snapshot()
    snap.upgrades={"skill_auto_slots":3} # fixture: 3 automatic slots, no extra skill slot (allowed before Change 81)
    sim.restore(snap)
    check(sim.automatic_skill_capacity()==3,"Kept: capacity 3 after load")
    sim.state.items["skill_heal"]={"qty":1,"merge":0,"extras":{}};sim.state.skills[0]="skill_heal" # fixture
    check(sim.assign_automatic_skills([0]) and sim.automatic_skill_assignments()==[0],"Only the owned slot 1 is active")
    check(not sim.assign_automatic_skills([0,1]),"Slot 2 cannot be activated without its skill slot")
    sim.state.gems=1000;sim.buy_upgrade("skill_slots")
    sim.state.items["skill_fire"]={"qty":1,"merge":0,"extras":{}};sim.state.skills[1]="skill_fire" # fixture
    check(sim.assign_automatic_skills([0,1]) and sim.automatic_skill_assignments()==[0,1],"…it works once Skill Slot 2 is bought (no repurchase)")
    check(do_prestige() and sim.automatic_skill_capacity()==3 and sim.level("skill_slots")==1,"Prestige keeps both")

func auto_skill_ui_checks() -> void:
    print("-- Auto Skill: UI")
    fresh()
    sim.state.skills_seen=["heal"];sim.state.gems=5000
    sim.buy_upgrade("skill_auto_slots")
    game.player_tab=0;game._open("upgrades");await frames(4)
    var all:=" | ".join(texts(game,[]))
    check(all.contains("Unlock Skill Slot 2 first"),"The card shows the locked reason with the slot number")
    var buy: Array=game.action_buttons.filter(func(b):return str(b.id)=="skill_auto_slots")
    check(buy.size()==1 and bool(buy[0].node.disabled),"…and its button is disabled")
    game._close()
    sim.buy_upgrade("skill_auto_slots")
    for i in range(3):game._update_toast(.1)
    check(str(game.get_node("Toast/Text").text)=="Unlock Skill Slot 2 first","A refused purchase explains itself: %s" % game.get_node("Toast/Text").text)

# ================================================================ 3. Spring combat
const DAMAGE_BEFORE:={"boss-bee":150.1769,"boss-orange-tabby-cat":160.9878,"boss-red-panda":379.0051,"boss-sunflower":346.0978,"boss-green-alien":415.013}
const HP_BEFORE:={"boss-bee":66473.5039,"boss-orange-tabby-cat":74114.4774,"boss-red-panda":79643.6942,"boss-sunflower":88798.5502,"boss-green-alien":137031.1606}
## Unchanged earlier-stage values (Change 79/80 catalog).
const EARLY:={"boss-snowman":[599.9344,8.0003],"boss-grim-reaper":[20153.3056,86.9885],"boss-black-cat":[18075.5621,108.7357],"boss-elephant":[3141.3918,44.1668]}

func combat_data_checks() -> void:
    print("-- Spring I / II attack damage")
    var scale: Dictionary=sim.catalog.progression.combat.normal_damage_scale
    check(near(float(scale["7"]),.9) and near(float(scale["8"]),.9) and scale.size()==2,"Normal damage scale Spring I/II 0.60 -> 0.90 (x1.5); no other stage scaled")
    var ok:=true
    for g in range(sim.catalog.groups.size()):
        var d: Dictionary=sim.catalog.groups[g]
        if d.boss or int(d.stage)<7:continue
        for v in [0,1,2,3]:
            var mult: float=[.75,1.25,1.0,1.15][v]
            var before: float=float(d.damage)*mult*.6
            var after: float=float(sim.enemy_definition(g,v).damage)
            if not near(after/before,1.5,1e-6):ok=false
    check(ok,"Every Spring normal type and variant hits exactly x1.50 its Change 80 damage")
    ok=true
    for id in DAMAGE_BEFORE:
        var g:=gi(id)
        var dmg: float=float(sim.enemy_definition(g).damage)
        if dmg<1.5*float(DAMAGE_BEFORE[id])-1e-6 or dmg>1.51*float(DAMAGE_BEFORE[id]):ok=false
        if not near(float(sim.enemy_definition(g).hp)/float(HP_BEFORE[id]),2.0/3.0,1e-4):ok=false
        print("     %s damage %.1f -> %.1f (x%.4f), HP %.0f -> %.0f" % [id,DAMAGE_BEFORE[id],dmg,dmg/float(DAMAGE_BEFORE[id]),HP_BEFORE[id],sim.enemy_definition(g).hp])
    check(ok,"Spring bosses: damage x1.50 (+0.1% rounding at most), HP x2/3")
    ok=true
    for id in EARLY:
        var d: Dictionary=sim.catalog.groups[gi(id)]
        if not near(float(d.hp),float(EARLY[id][0]),1e-3) or not near(float(d.damage),float(EARLY[id][1]),1e-3):ok=false
    check(ok,"Earlier-stage bosses unchanged (Snowman, Elephant, Black Cat, Grim Reaper)")
    var intervals: Dictionary={"unit-bunny-ears":1.5,"unit-sprout":1.5,"boss-bee":1.4,"boss-orange-tabby-cat":1.35,"boss-red-panda":1.33,"boss-sunflower":1.32,"boss-green-alien":1.3}
    ok=true
    for id in intervals:
        if not near(float(sim.catalog.groups[gi(id)].interval),float(intervals[id])):ok=false
    check(ok,"Attack intervals unchanged")
    var sun=sim.abilities.summon_rule("boss-sunflower")
    var alien=sim.abilities.summon_rule("boss-green-alien")
    var reaper=sim.abilities.summon_rule("boss-grim-reaper")
    check(near(sun.damage_scale,.45) and near(alien.damage_scale,.525) and near(reaper.damage_scale,.4),"Helpers: Sunflower 0.30 -> 0.45, Green Alien 0.35 -> 0.525 (x1.5); Grim Reaper (Autumn II) unchanged")
    check(near(float(sim.enemy_definition(gi("unit-sprout"),4).damage),float(sim.catalog.groups[gi("unit-sprout")].damage)*.45),"A summoned Sprout hits with the new share")
    check(near(float(sim.catalog.skills.heal.enemy_hp_fraction),.08) and near(float(sim.abilities.final_heal_fraction),.04) and near(float(sim.catalog.skills.focus.power),.15) and near(float(sim.catalog.skills.strike.power),2.8) and near(float(sim.catalog.skills.fire.power),1.6),"Skill powers, heals and Focus unchanged")

## An enemy skill hits for definition damage x power once: the x1.5 is in the definition only.
func combat_skill_checks() -> void:
    print("-- Enemy skills scale once")
    fresh()
    sim.state.stage=8;sim.state.unlocked_stage=8;sim.campaign.configure_stage();sim._reset_world() # fixture: Spring II
    var g:=gi("unit-pink-flower-hood")
    var e: Dictionary={}
    for a in sim.state.enemies:
        if int(a.group)==g and int(a.get("variant",2))==3:e=a;break
    check(not e.is_empty(),"fixture: a Pink Flower Hood skill variant on Spring II")
    var p: Dictionary=sim.state.player
    p.x=float(e.x)+10;p.y=float(e.y);p.hp=1e9 # fixture: next to it, huge HP
    var before: float=p.hp
    check(sim.campaign.apply_skill(e,"fire",float(sim.catalog.skills.fire.power)),"It casts Fire")
    var defense: float=float(sim.stats().defense)
    var expected: float=float(sim.catalog.groups[g].damage)*1.15*.9*1.6*sim.campaign.damage_multiplier(e,p)*100.0/(100.0+defense)
    check(near(before-float(p.hp),expected,1e-3),"Fire = catalog damage x1.15 (variant) x0.90 (Spring) x1.6 (power): %.2f" % (before-float(p.hp)))
    check(near(expected/(expected/1.5),1.5) and near((before-float(p.hp))/(float(sim.catalog.groups[g].damage)*1.15*.6*1.6*sim.campaign.damage_multiplier(e,p)*100.0/(100.0+defense)),1.5,1e-6),"…exactly x1.5 the Change 80 Fire (not x2.25)")
    var boss: Dictionary={}
    for a in sim.state.enemies:
        if int(a.group)==gi("boss-red-panda"):boss=a
    p.x=float(boss.x)+10;p.y=float(boss.y);p.hp=1e9
    before=p.hp
    sim.campaign.apply_skill(boss,"frost",1.2)
    check(near(before-float(p.hp),float(sim.enemy_definition(gi("boss-red-panda")).damage)*1.2*sim.campaign.damage_multiplier(boss,p)*100.0/(100.0+defense),1e-3),"Red Panda Frost = boss damage x1.2 (one x1.5, from the boss damage)")

# ================================================================ 4. Green Alien
func spring_two() -> void:
    sim.state.stage=8;sim.state.unlocked_stage=8;sim.campaign.configure_stage();sim._reset_world() # fixture: Spring II reached
func alien() -> Dictionary:
    for a in sim.state.enemies:
        if bool(sim.catalog.groups[int(a.group)].final):return a
    return {}
func kill_boss(id: String) -> void:
    var g:=gi(id)
    var a: Dictionary=sim._actor("probe_%s" % id,0,0,1,g) # fixture: the defeated boss actor
    a["variant"]=2
    sim._kill(a)

func final_boss_checks() -> void:
    print("-- Green Alien: before discovery")
    fresh()
    spring_two()
    await frames(3)
    game._refresh_final_chip();game._refresh_gate()
    check(not game.get_node("Safe/Layout/Map/FinalKeys").visible and sim.campaign.final_objective()=="","No Boss Keys chip before the discovery")
    kill_boss("boss-red-panda")
    check(sim.state.keys.is_empty() and key_events.is_empty(),"A boss defeated before the discovery gives no key")
    game._refresh_gate()
    var gate_text: String=game.get_node("Safe/Layout/Map/Gate/Row/Label").text
    check(gate_text.begins_with("Enemy types defeated ·"),"Spring II gate chip: %s" % gate_text)
    print("-- Green Alien: discovery and introduction")
    var ga:=alien()
    sim.state.player.x=float(ga.x)+100;sim.state.player.y=float(ga.y) # fixture: walk up to it
    sim.campaign.step(.016)
    check(bool(sim.state.final_discovered),"Coming near discovers it")
    game.banner.queue.clear();game.banner._finish()
    game._final_intro_check()
    var entry: Dictionary=game.banner.queue[0] if not game.banner.queue.is_empty() else {}
    check(str(entry.get("title",""))=="YOU ARE NOT WORTHY!" and str(entry.get("subtitle","")).contains("defeat the other 13 bosses") and bool(entry.get("warning",false)),"The introduction banner (red, prominent)")
    check(sim.state.tutorial.seen.has("final_intro"),"Acknowledged in the profile")
    game.banner.queue.clear();game.banner._finish()
    game._final_intro_check()
    check(game.banner.queue.is_empty(),"Never shown twice")
    print("-- Green Alien: sealed")
    game.toast_queue.clear();game.get_node("Toast").hide();game.toast_time=0.0
    sim.state.player.hp=sim.stats().hp
    check(not sim.select_target(str(ga.id)) and sim.locked_target=="" and not bool(ga.aggro),"Tapping it starts nothing")
    for i in range(3):game._update_toast(.1)
    check(str(game.get_node("Toast/Text").text)=="The Green Alien refuses to fight you. Boss Keys: 0 / 13","…and explains: %s" % game.get_node("Toast/Text").text)
    sim.state.upgrades["focus"]=1;sim.campaign.discover_spot(int(ga.group),2);sim.state.discovered[str(int(ga.group))]=true # fixture: Focus owned, spot known
    check(not sim.focus(int(ga.group)) and int(sim.state.focus)<0,"It cannot be farmed while sealed")
    var chip: Control=game.get_node("Safe/Layout/Map/FinalKeys")
    game._refresh_final_chip()
    check(chip.visible and str(chip.get_node("Row/Lines/Caption").text)=="Final Boss" and str(chip.get_node("Row/Lines/Value").text)=="Boss Keys 0/13","Chip: Final Boss / Boss Keys 0/13")
    print("-- Green Alien: keys")
    kill_boss("boss-red-panda")
    check(sim.state.keys==["boss-red-panda"] and key_events==[[gi("boss-red-panda"),1]],"A new boss key is credited once, with its signal")
    kill_boss("boss-red-panda")
    check(sim.state.keys.size()==1 and key_events.size()==1,"The same boss again: no second key, no second pickup")
    check(SaveService.save_now(),"Disk save")
    sim.state.keys=[] # fixture: in-memory loss
    SaveService.load_and_apply();await frames(2)
    check(sim.state.keys==["boss-red-panda"],"The key is in the save (no animation needed)")
    game.key_fx.clear()
    game._refresh_final_chip()
    check(str(chip.get_node("Row/Lines/Value").text)=="Boss Keys 1/13","After a load the chip shows 1/13")
    sim.state.stage=1;sim.campaign.configure_stage();sim._reset_world() # fixture: another map
    game.elapsed=1.0;await frames(2);game._refresh_final_chip()
    check(chip.visible and str(chip.get_node("Row/Lines/Value").text)=="Boss Keys 1/13","…on every map (Winter I)")
    check(game.tracker_clearance()>=0 or game.tracker_clearance()==INF,"No collision with the objective pills")
    var bosses: Array=[]
    for d in sim.catalog.groups:
        if d.boss and not d.final:bosses.append(str(d.id))
    check(bosses.size()==13,"13 other bosses")
    for id in bosses:kill_boss(id)
    check(sim.state.keys.size()==13 and key_events.size()==13 and int(key_events[-1][1])==13,"13 distinct keys")
    game.key_fx.clear()
    game._refresh_final_chip()
    check(str(chip.get_node("Row/Lines/Caption").text)=="Green Alien" and str(chip.get_node("Row/Lines/Value").text)=="Ready to Challenge","Chip: Green Alien / Ready to Challenge")
    spring_two()
    ga=alien()
    # Change 82: with 13 keys it waits for the one-time unsealing ceremony (tests/change_82_probe), then it is a target.
    check(not sim.campaign.target_allowed(ga),"13 keys: still waiting for the Change 82 ceremony")
    sim.state.final_unsealed=true # fixture: the Change 82 ceremony completed
    check(sim.campaign.target_allowed(ga) or not sim.campaign.can_see(sim.position_of(ga)),"Unsealed: it can be targeted")
    check(not sim.campaign.final_sealed(int(ga.group)),"…no longer sealed")
    print("-- Green Alien: Prestige and victory")
    check(do_prestige(),"Prestige")
    check(sim.state.keys.size()==13 and bool(sim.state.final_discovered),"Prestige keeps the keys and the discovery")
    game._refresh_final_chip()
    check(chip.visible,"The chip stays after Prestige")
    sim.state.group_kills[int(ga.group)]=1 # fixture: the Green Alien defeated
    game._refresh_final_chip()
    check(not chip.visible and sim.campaign.final_objective()=="","After the victory the tracked objective is gone")
    print("-- Green Alien: met before this build")
    fresh()
    var snap: Dictionary=sim.snapshot()
    snap.final_discovered=true;snap.keys=["boss-snowman"]
    snap.migrations=Array(snap.migrations).filter(func(m):return m!="final_intro_seen")
    snap.tutorial.seen=Array(snap.tutorial.seen).filter(func(k):return k!="final_intro")
    sim.restore(snap)
    game.banner.queue.clear();game.banner._finish()
    game._final_intro_check()
    check(game.banner.queue.is_empty() and sim.state.tutorial.seen.has("final_intro") and sim.state.keys==["boss-snowman"],"No retroactive popup; keys kept")

# ================================================================ 5. Boss-key pickup
func step_fx(seconds: float) -> void:
    var t:=0.0
    while t<seconds:
        game.key_fx._process(.05);t+=.05

func key_fx_checks() -> void:
    print("-- Boss-key pickup")
    fresh()
    spring_two()
    sim.state.final_discovered=true;sim.state.tutorial.seen.append("final_intro")
    game.elapsed=1.0;await frames(3)
    var chip: Control=game.get_node("Safe/Layout/Map/FinalKeys")
    game._refresh_final_chip();game._layout_hud()
    check(chip.visible and chip.size.x>0,"fixture: the chip is laid out (%s)" % [chip.size])
    var landed: Array=[]
    game.key_fx.arrived.connect(func(total: int)->void:landed.append(total))
    kill_boss("boss-sunflower")
    check(sim.state.keys==["boss-sunflower"] and game.key_fx.in_flight()==1,"Credited before the pickup plays; one key in flight")
    game._refresh_final_chip()
    check(str(chip.get_node("Row/Lines/Value").text)=="Boss Keys 0/13","The chip waits for the key to land")
    step_fx(.5)
    var node: Control=game.key_fx.keys[0].node
    check(node.visible and node.size.x>=96,"A large key (%dpx) shows over the boss" % int(node.size.x))
    check(str(node.get_node("Count").text)=="Boss Key 1/13","…with its count")
    step_fx(5.0)
    check(game.key_fx.in_flight()==0 and landed==[1],"Untouched, it flies to the chip by itself")
    check(str(chip.get_node("Row/Lines/Value").text)=="Boss Keys 1/13","…and the chip shows 1/13")
    # Tap: the key leaves at once.
    kill_boss("boss-red-panda")
    step_fx(.6)
    var entry: Dictionary=game.key_fx.keys[0]
    var touch:=InputEventMouseButton.new();touch.pressed=true;touch.button_index=MOUSE_BUTTON_LEFT
    entry.node.gui_input.emit(touch)
    check(str(entry.phase)=="fly","A tap sends it to the chip now")
    step_fx(1.0)
    check(landed==[1,2],"Landed (2)")
    # A panel over the chip: the key fades where it is (no flight across the panel); the reward stands.
    kill_boss("boss-bee")
    game._open("missions");await frames(3)
    step_fx(4.0)
    check(landed==[1,2,3] and sim.state.keys.size()==3,"Covered chip: the key fades in place, nothing lost")
    game._close();await frames(2)
    # Rapid rewards are staggered; a Prestige reset drops the flights but never the keys.
    kill_boss("boss-orange-tabby-cat");kill_boss("boss-grim-reaper")
    check(game.key_fx.in_flight()==2 and float(game.key_fx.keys[1].age)<0,"Two quick keys: the second waits its turn")
    sim.milestone.emit("reset","")
    check(game.key_fx.in_flight()==0 and sim.state.keys.size()==5,"A reset clears the flights; the 5 keys stay")
    kill_boss("boss-black-cat")
    var avoid: Array=game._key_fx_avoid()
    entry=game.key_fx.keys[0]
    game.key_fx.avoid=func()->Array:return [Rect2(Vector2.ZERO,game.get_node("Safe/Layout/Map").size)] # fixture: a protected control under the whole map
    step_fx(.5)
    check(entry.node.mouse_filter==Control.MOUSE_FILTER_IGNORE,"A key over a protected control (joystick) takes no touch (%d protected rects live)" % avoid.size())
    game.key_fx.avoid=game._key_fx_avoid
    step_fx(4.0)
    game.get_tree().paused=true
    kill_boss("boss-squirrel")
    game.get_tree().paused=false
    check(sim.state.keys.size()==7,"A key earned around a pause is credited")
    step_fx(5.0)
    check(game.key_fx.in_flight()==0,"…and its pickup completes")

# ================================================================ 6. Level 500
func level_cap_checks() -> void:
    print("-- Level cap 500")
    fresh()
    check(sim.max_level()==500 and near(float(sim.catalog.progression.xp_base),12.0) and near(float(sim.catalog.progression.xp_growth),1.35),"Cap 500; XP requirement ceil(12 x L^1.35) unchanged")
    check(near(sim.xp_required(1),12.0) and near(sim.xp_required(100),ceilf(12.0*pow(100,1.35))) and near(sim.xp_required(499),ceilf(12.0*pow(499,1.35))),"Requirements at 1, 100, 499")
    sim.state.player_level=498;sim.state.xp=0.0 # fixture
    sim.gain_xp(sim.xp_required(498)+sim.xp_required(499)+1e9)
    check(int(sim.state.player_level)==500 and near(float(sim.state.xp),0.0),"Levels up to 500 and stops; XP past the cap is not kept")
    sim.gain_xp(1e9)
    check(int(sim.state.player_level)==500 and near(float(sim.state.xp),0.0),"More XP at the cap adds nothing")
    game.elapsed=1.0;await frames(2)
    var xp_text: String=game.top.get_node("Meters/XP/Text").text
    check(xp_text.contains("MAX"),"HUD: %s" % xp_text)
    game._open("level");await frames(4)
    var all:=" | ".join(texts(game,[]))
    check(all.contains("Level 500 / 500") and all.contains("Maximum level reached") and not all.contains("more to reach level"),"Level panel: MAX state, no next-level line")
    game._close()
    check(do_prestige() and int(sim.state.player_level)==500,"Prestige keeps level 500")
    print("-- Level cap: saves above 500")
    var snap: Dictionary=sim.snapshot()
    snap.player_level=873;snap.xp=12345.0 # fixture: a Change 80 profile above the new cap
    var out: Dictionary=sim.campaign.normalize_snapshot(snap)
    check(int(out.player_level)==500 and near(float(out.xp),0.0) and sim.campaign.clamped_player_level==873 and sim.campaign.valid_snapshot(out),"Level 873 -> 500 (XP 0), valid")
    sim.restore(snap)
    check(int(sim.state.player_level)==500 and near(float(sim.stats().damage),float(sim.stats_at_level(500).damage)),"Restored at 500 with level-500 stats")
    sim.state.player_level=250;sim.state.xp=100.0
    out=sim.campaign.normalize_snapshot(sim.snapshot())
    check(int(out.player_level)==250 and near(float(out.xp),100.0),"A profile under the cap is untouched")

# ================================================================ 7. Obsidian ^500
func give(id: String,merge_level: int,qty: int) -> void:
    sim.add_item(id,qty)
    sim.record(id).merge=merge_level;sim.record(id).extras={} # fixture: merge level, no random attribute

func obsidian_checks() -> void:
    print("-- Obsidian Sword / Axe to ^500")
    fresh()
    check(sim.merge_cap("obsidian_sword")==500 and sim.merge_cap("obsidian_axe")==500,"Both Obsidian weapons merge to ^500")
    check(sim.merge_cap("emerald_sword")==20 and sim.merge_cap("obsidian_sword_legacy")==100 and sim.merge_cap("stone_axe")==20,"Other weapons unchanged (evolvable ^20, legacy ^100)")
    check(int(sim.catalog.items.obsidian_sword.tier)==7 and str(sim.catalog.items.obsidian_sword.next)=="" and int(sim.catalog.items.obsidian_axe.tier)==7,"Still tier 7 with no next tier")
    check(near(sim.merge_levels("obsidian_sword",100),100.0) and near(sim.merge_levels("obsidian_sword",101),100.5) and near(sim.merge_levels("obsidian_sword",300),200.0) and near(sim.merge_levels("obsidian_axe",500),300.0),"Tail: 0.5 level per merge past ^100 (^500 = 300 levels)")
    var sword: Array=sim.catalog.items.obsidian_sword.normal.damage
    give("obsidian_sword",100,6)
    sim.equip("obsidian_sword")
    var core100: float=float(sword[0])+float(sword[1])*100.0
    check(near(float(sim.normal("obsidian_sword").damage),core100*(1.0+.0005*5),1e-4),"A ^100 Sword with 5 spares keeps its ^100 value and spare-copy bonus")
    var preview: Dictionary=sim.merge_preview("obsidian_sword")
    check(sim.can_merge("obsidian_sword") and float(preview.damage)>0,"^100 can advance; the preview shows a gain (+%.2f)" % float(preview.damage))
    var dmg_before: float=float(sim.normal("obsidian_sword").damage)
    check(sim.merge("obsidian_sword") and int(sim.record("obsidian_sword").merge)==101,"^100 -> ^101")
    check(near(float(sim.normal("obsidian_sword").damage)-dmg_before,float(preview.damage),1e-4) and float(sim.normal("obsidian_sword").damage)>dmg_before,"The gain is exactly the preview")
    print("-- Obsidian milestones")
    var expect_sword:={99:[0,0,0,0],100:[.02,0,0,0],200:[.02,.10,0,0],300:[.04,.10,.10,0],400:[.04,.20,.10,0],500:[.06,.25,.15,0]}
    var ok:=true
    for m in expect_sword:
        var w: Dictionary=sim.weapon_milestones("obsidian_sword",m)
        var e: Array=expect_sword[m]
        var core: float=float(sword[0])+sim.merge_gain("obsidian_sword","damage")*sim.merge_levels("obsidian_sword",m)
        if not near(float(w.crit),e[0]) or not near(float(w.crit_damage),e[1]) or not near(float(w.damage),core*float(e[2]),1e-4) or not near(float(w.lifesteal),e[3]):ok=false;print("     sword ^%d %s" % [m,w])
    check(ok,"Sword: ^100 crit +2%, ^200 +10% crit dmg, ^300 crit 4% + 10% core damage, ^400 crit dmg 20%, ^500 crit 6% / 25% / 15% core")
    var axe: Array=sim.catalog.items.obsidian_axe.normal.damage
    var expect_axe:={100:[.01,0],200:[.01,.10],300:[.02,.10],400:[.02,.20],500:[.03,.25]}
    ok=true
    for m in expect_axe:
        var w: Dictionary=sim.weapon_milestones("obsidian_axe",m)
        var core: float=float(axe[0])+sim.merge_gain("obsidian_axe","damage")*sim.merge_levels("obsidian_axe",m)
        if not near(float(w.lifesteal),expect_axe[m][0]) or not near(float(w.damage),core*float(expect_axe[m][1]),1e-4) or float(w.crit)!=0.0:ok=false;print("     axe ^%d %s" % [m,w])
    check(ok,"Axe: lifesteal 1/1/2/2/3% and 0/10/10/20/25% core damage (no crit, no Defense/HP)")
    check(sim.weapon_milestones("emerald_sword",20).values().all(func(v):return float(v)==0.0) and sim.weapon_milestone_track("obsidian_sword_legacy").is_empty(),"No milestones on other or legacy weapons")
    # Equipped only, counted once.
    fresh()
    give("obsidian_sword",200,1)
    var crit0: float=float(sim.stats().crit)
    sim.equip("obsidian_sword")
    check(near(float(sim.stats().crit)-crit0,.02,1e-9) and near(float(sim.stat_sources().SOURCE_WEAPON_MILESTONE.crit_damage),.10),"Equipped ^200 Sword: +2% crit, +10% crit damage")
    check(near(float(sim.stats().crit_damage),1.1+.10,1e-9),"Crit damage 110% + 10% (no double count)")
    give("obsidian_axe",500,1)
    sim.touch()
    check(near(float(sim.stat_sources().SOURCE_WEAPON_MILESTONE.lifesteal),0.0) and near(float(sim.stats().crit)-crit0,.02,1e-9),"A stored ^500 Axe adds no milestone (only the equipped Sword's)")
    print("-- Obsidian merging to the cap")
    fresh()
    give("obsidian_axe",495,20)
    sim.state.upgrades["merge_all"]=1 # fixture: Merge All owned
    var result: Dictionary=sim.merge_all()
    check(int(sim.record("obsidian_axe").merge)==500 and int(result.copies)==5 and sim.quantity("obsidian_axe")==15,"Merge All stops at ^500 (5 copies), the rest stay as spares")
    check(not sim.can_merge("obsidian_axe") and not sim.merge("obsidian_axe") and sim.merge_preview("obsidian_axe").is_empty(),"At ^500: no merge, no preview")
    fresh()
    give("obsidian_sword",250,3)
    var gg: int=int(sim.droppers("obsidian_sword")[0])
    check(gg>=0 and int(sim.catalog.groups[gg].stage)>=7,"fixture: a Spring type that drops the Obsidian Sword (%s)" % sim.catalog.groups[gg].id)
    sim.state.upgrades["merge_gear:%d" % gg]=1 # fixture: Auto-Merge bought for that type
    for i in range(2):sim.campaign.merge_cycle(str(gg),1.0,1.0,gg)
    check(int(sim.record("obsidian_sword").merge)==252,"Auto-Merge advances past ^100 (^250 -> ^252): ^%d" % int(sim.record("obsidian_sword").merge))
    # A milestone is announced once, by the merge that reaches it.
    fresh()
    give("obsidian_sword",199,3)
    game.toast_queue.clear()
    sim.merge("obsidian_sword")
    var said: Array=game.toast_queue.filter(func(t):return str(t).contains("^200 milestone"))
    sim.merge("obsidian_sword")
    var again: Array=game.toast_queue.filter(func(t):return str(t).contains("milestone"))
    check(said.size()==1 and again.size()==1,"^199 -> ^200 names the milestone once; ^201 says nothing more: %s" % [game.toast_queue])
    # Masterwork IV still counts an Obsidian weapon at ^100 or more.
    var o:={"merge_obsidian_sword":350}
    check(sim.campaign.masterwork_best(o,4)==350 and sim.campaign.MASTERWORK_MERGE==100,"Masterwork IV: ^100 goal unchanged, higher levels count")

func obsidian_persistence_checks() -> void:
    print("-- Obsidian: save, memory")
    fresh()
    give("obsidian_sword",350,2)
    sim.remember_merge("obsidian_sword",350)
    sim.equip("obsidian_sword")
    var dmg: float=float(sim.stats().damage)
    check(SaveService.save_now(),"Disk save at ^350")
    sim.state.items={} # fixture: in-memory loss
    SaveService.load_and_apply();await frames(2)
    check(int(sim.record("obsidian_sword").merge)==350 and near(float(sim.stats().damage),dmg,1e-6),"Reload: ^350, same damage")
    check(sim.remembered_merge("obsidian_sword")==350,"Merge memory keeps ^350")
    var snap: Dictionary=sim.snapshot()
    snap.items.obsidian_sword.merge=501 # fixture: beyond any cap
    check(not sim.campaign.valid_snapshot(sim.campaign.normalize_snapshot(snap)),"^501 is rejected as invalid (bound = ^500)")
    snap.items.obsidian_sword.merge=100;snap.merge_memory={"obsidian_sword":100}
    check(sim.campaign.valid_snapshot(sim.campaign.normalize_snapshot(snap)),"A Change 80 ^100 save stays valid")

func obsidian_ui_checks() -> void:
    print("-- Obsidian: item card")
    fresh()
    give("obsidian_sword",220,3)
    sim.equip("obsidian_sword")
    game.selected="obsidian_sword";game.selected_slot=-1;game._open("item");await frames(4)
    var all:=" | ".join(texts(game,[]))
    check(all.contains("^220 / ^500"),"Merge track ^220 / ^500")
    check(all.contains("Milestones (while equipped): Critical Chance +2%, Critical Damage +10%"),"Active milestones listed")
    check(all.contains("Next at ^300: Critical Chance +4%, Critical Damage +10%, Damage +"),"Next milestone listed")
    check(game._milestone_rank("obsidian_sword")==2,"Slot frame rank 2 (the outfit frames)")
    game._close()
