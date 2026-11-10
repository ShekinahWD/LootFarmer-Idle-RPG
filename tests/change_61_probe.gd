extends Node
## Change 61 (Guided tutorial restructure): the gameplay contracts behind the new lessons, in every mode.
## - Select vs Travel: travel never changes the respawn camp; the choice is kept per stage.
## - The one-time 30-defeat mission: unlocked by finding the Snowman (all modes), counts later defeats
##   only, survives refresh / save / Prestige, never auto-claimed, pays once.
## - hunter_o1: discovered with the Snowman, followable before the first defeat, ready after one.
## - Old Guided saves: finished stays finished; past-the-boss skips the new pre-boss lessons; a save
##   still before the boss continues into the new lessons.
## - Optional Prestige at the Winter II lesson leads to the unchanged final card after the reset.
## - The offline item hint is not suppressed by a lack of Gems and mentions supplies.
## The full Guided walk (every step by its real action) is in change_20_probe.
var checks:=0
var failures:=0
var game
var sim
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame
func _ready() -> void:call_deferred("run")
func fresh(mode:="none") -> void:
    sim.new_profile();sim.set_physics_process(false);sim.suspended=false
    sim.state.tutorial.mode=mode
    if mode!="guided":sim.campaign.onboarding.reveal_all(true)
    game._close();game.banner.queue.clear();game.banner._finish()
func calm() -> void:
    sim.state.player.quiet=20
    for e in sim.state.enemies:e.aggro=false
func enemy(boss: bool) -> Dictionary:
    for e in sim.state.enemies:
        if bool(sim.catalog.groups[int(e.group)].boss)==boss and (not boss or sim.catalog.groups[int(e.group)].id=="boss-snowman"):return e
    return {}
func find_snowman() -> void:
    var s:=enemy(true)
    sim.state.player.x=s.x;sim.state.player.y=s.y+40;sim.campaign.reveal()
    sim.campaign.evaluate() # the one-second campaign tick
func roundtrip() -> void:
    sim.restore(JSON.parse_string(JSON.stringify(sim.snapshot())))
func run() -> void:
    get_window().size=Vector2i(720,1280)
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    await frames()
    # ---------------------------------------------------------------- Select vs Travel
    fresh("none")
    sim.state.coins=1000000;sim.state.camps_known["1"]=[1]
    sim.select_spawn(1)
    check(sim.state.spawns.has(1) and int(sim.state.spawn)==0,"Unlocking a camp never selects it")
    sim.select_spawn(1)
    check(int(sim.state.spawn)==1 and int(sim.state.respawns.get("1",-1))==1,"Respawn here selects camp 2 and records it for Winter I")
    calm()
    check(sim.campaign.camp_action(1,0,true) and int(sim.state.spawn)==1,"Travel to the arrival camp keeps camp 2 as the respawn camp")
    var at: Array=sim.campaign.stage().spawns[0]
    check(sim.position_of(sim.state.player).distance_to(Vector2(at[0],at[1]))<1,"Travel moves the player to the arrival camp")
    sim.state.player.hp=0;sim.state.player.respawn=0;sim.step(0.05)
    var respawn_at: Array=sim.campaign.stage().spawns[1]
    check(sim.position_of(sim.state.player).distance_to(Vector2(respawn_at[0],respawn_at[1]))<1,"Death returns the player to the selected camp, not the travel destination")
    sim.state.unlocked_stage=2;calm()
    check(sim.campaign.camp_action(2,0,true) and int(sim.state.stage)==2 and int(sim.state.spawn)==0,"A new stage starts with its arrival camp as respawn")
    calm()
    check(sim.campaign.camp_action(1,0,true) and int(sim.state.spawn)==1,"Returning to Winter I restores its selected respawn camp")
    roundtrip()
    check(int(sim.state.spawn)==1 and int(sim.state.respawns.get("2",-1))==0,"Respawn choices survive a JSON restore")
    calm();sim.state.player.quiet=0;sim.state.enemies[0].aggro=true;sim.state.enemies[0].hp=10
    check(not sim.campaign.camp_action(1,1,true),"Travel stays blocked during combat")
    # ---------------------------------------------------------------- 30-defeat mission and hunter_o1 (Basic)
    fresh("basic")
    var normal:=enemy(false)
    sim.campaign.killed(normal)
    check(not sim.campaign.hunt_open() and sim.campaign.hunt_progress()==0,"No mission before the Snowman is found")
    find_snowman()
    check(sim.campaign.hunt_open() and sim.campaign.hunt_progress()==0,"Finding the Snowman unlocks the mission at 0/30 (earlier kills never count)")
    check(sim.state.opportunities.has("hunter_o1") and sim.campaign.can_follow("hunter_o1"),"hunter_o1 is discovered and followable before the first defeat")
    check(sim.campaign.opportunity_progress("hunter_o1")=="0 / 1","hunter_o1 needs one Snowman defeat")
    check(sim.campaign.guided.next_step()=="" and sim.campaign.prestige_gate_reason()=="","Basic receives no Guided step or Guided Prestige lock")
    check(sim.campaign.toggle_follow_mission("hunt",0) and sim.campaign.followed_mission().get("kind","")=="hunt","Basic can follow the mission")
    game._open("missions");await frames(2)
    var follow_button: Button=null;var claim_button: Button=null
    for node in game.rows.find_children("*","Button",true,false):
        if node.get_meta("guide","")=="follow_hunt":follow_button=node
    check(follow_button!=null and follow_button.text==tr("UNFOLLOW"),"Missions lists the mission with its Unfollow control")
    game._close()
    for i in range(29):sim.campaign.killed(normal)
    check(not sim.campaign.hunt_ready() and not sim.campaign.hunt_claimable(),"29 defeats are not enough")
    sim.state.mission_day="1999-01-01";sim.campaign.refresh_missions()
    roundtrip()
    check(sim.campaign.hunt_open() and int(sim.campaign.hunt_progress())==29 and sim.campaign.followed_mission().get("kind","")=="hunt","Progress and the follow survive daily refresh and restore")
    sim.state.upgrades["mission_claim"]=1;sim.state.mission_auto=true
    sim.campaign.killed(normal)
    for i in range(3):sim.campaign.automate(1.0)
    check(sim.campaign.hunt_claimable() and sim.campaign.has_claimable() and not bool(sim.campaign.hunt_state().claimed),"30/30 is ready, lights the Missions badge, and Auto Claim leaves it for the player")
    var coins: float=sim.state.coins;var gems: float=sim.state.gems
    check(sim.campaign.claim_hunt() and not sim.campaign.claim_hunt(),"Claim pays once")
    check(is_equal_approx(sim.state.coins-coins,float(sim.catalog.campaign.main_rewards[3][0])) and is_equal_approx(sim.state.gems-gems,float(sim.catalog.campaign.main_rewards[3][1])),"Reward is the main-objective scale (%s)" % str(sim.catalog.campaign.main_rewards[3]))
    check(not sim.campaign.hunt_open() and sim.campaign.followed_mission().is_empty(),"A claimed mission leaves Missions and the tracker")
    sim._kill(enemy(true))
    check(sim.state.opportunities.hunter_o1.ready and int(sim.state.unlocked_stage)==2,"One Snowman defeat readies hunter_o1 and unlocks Winter II")
    check(sim.campaign.HUNTER_KILLS.slice(1)==[20,30,10] and sim.catalog.campaign.cards.size()==48 and sim.catalog.campaign.paths.size()==11,"Other Hunter counts, the 48 cards and 11 paths are unchanged")
    check(sim.campaign.begin_prestige(),"Basic can Prestige with hunter_o1 ready")
    while not sim.state.prestige_batch.is_empty():sim.campaign.choose_card(sim.campaign.offered_cards()[0])
    check(bool(sim.campaign.hunt_state().claimed) and not sim.campaign.hunt_open(),"Prestige keeps the claimed mission: no second reward")
    # ---------------------------------------------------------------- old Guided saves
    for case in [["complete",["move","kill","tutorial_final"],false,""],["before boss",["move","target","kill","collect","equip","close_equip","merge","close_merge","mission_wait","missions","close_missions","upgrade_wait","player_upgrade","close_upgrade","camp","boss_find","boss_preparation","boss_farm"],false,"gear_bonus"],["after boss",["move","target","kill","collect","equip","close_equip","merge","close_merge","mission_wait","missions","close_missions","upgrade_wait","player_upgrade","close_upgrade","camp","boss_find","boss_preparation","boss_farm","expand_inventory","close_inventory","potion_buy","potion_use","prestige_intro","boss_win"],true,"world_open"]]:
        fresh("guided")
        var snap: Dictionary=sim.snapshot()
        snap.tutorial.flow={"done":case[1],"times":{},"wait_seconds":{},"gem_grant":true,"supply_grant":false,"boss_kills":5,"final_seconds":0.0}
        snap.erase("hunt");snap.erase("respawns")
        if case[2]:
            snap.group_kills[sim.campaign.prestige_unlock_group()]=1;snap.bosses_found=["boss-snowman"];snap.unlocked_stage=2
            snap.upgrades["gear_slots"]=1;snap.gear.resize(3+int(sim.catalog.upgrades.gear_slots.effect));snap.gear.fill("")
            snap.supply_uses={"potion":1}
        sim.restore(JSON.parse_string(JSON.stringify(snap)))
        check(sim.state.has("hunt") and sim.state.has("respawns"),"Old save gains the Change 61 records ("+case[0]+")")
        if case[0]=="complete":check(sim.campaign.guided.complete() and sim.campaign.guided.next_step()=="","A finished Guided save stays finished")
        else:check(sim.campaign.guided.next_step()==case[3],"Old save '%s' continues at %s (got %s)" % [case[0],case[3],sim.campaign.guided.next_step()])
    # ---------------------------------------------------------------- optional Prestige -> final card
    fresh("guided")
    var flow=sim.campaign.guided
    flow.data().done=flow.STEPS.slice(0,flow.STEPS.find("winter_two")+1)
    sim.state.unlocked_stage=2;find_snowman();sim._kill(enemy(true));calm()
    sim.campaign.camp_action(2,0,true)
    check(flow.next_step()=="prestige_optional" and sim.campaign.prestige_block_reason()=="","The optional lesson allows the reset")
    check(sim.campaign.begin_prestige(),"Prestige from the optional lesson")
    while not sim.state.prestige_batch.is_empty():sim.campaign.choose_card(sim.campaign.offered_cards()[0])
    check(int(sim.state.stage)==1 and int(sim.state.prestiges)==1 and flow.next_step()=="tutorial_final","After the reset the unchanged final card follows on Winter I")
    check(tr("GUIDE_TUTORIAL_FINAL")=="THE ROAD AHEAD","Final title unchanged")
    # ---------------------------------------------------------------- offline hint
    fresh("none")
    var gear: String=sim.catalog.groups[0].loot[0]
    sim.add_item(gear,1);sim.state.gems=0
    check(game.offline_gear_hint_due(),"The offline item hint is due without Gems")
    for u in ["offline_weapon","offline_outfit"]:sim.state.upgrades[u]=1
    check(not game.offline_gear_hint_due(),"Unlocked kinds the player owns end the hint")
    sim.add_item("potion",1)
    check(game.offline_gear_hint_due(),"Supplies count for the hint")
    check("supplies" in tr("OFFLINE_ITEMS_HINT"),"The hint mentions supplies")
    print("CHANGE_61_CHECKS ",checks," FAILURES ",failures)
    get_tree().quit(1 if failures else 0)
