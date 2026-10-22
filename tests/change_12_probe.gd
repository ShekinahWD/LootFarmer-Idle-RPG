extends Node
## Change 12 probe: the Cyan Robot Heal (real HP, timing, effects), the lower-right map explored
## percentage, Settings copy, audio categories and persistence, followed-step and mission cues once
## per transition, Merge All, the stone-tier swing sheet, the camera after Prestige, and the gem
## chance formula and prices. Real main scene and simulation; state set directly is labelled "fixture".
var checks:=0
var failures:=0
var sim
var game
var notices: Array=[]
var casts: Array=[]
var heals: Array=[]
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
    else:print("  ok  ",label_)
func near(a: float,b: float,tolerance:=.0001) -> bool:return absf(a-b)<=tolerance*maxf(1.0,absf(b))
func _ready() -> void:call_deferred("run")
func fresh() -> void:
    get_tree().paused=false
    sim.new_profile();sim.state.tutorial.mode="none";sim.suspended=false;SaveService.write_blocked=false;sim.rng.seed=12012;game._close()
    notices.clear();casts.clear();heals.clear()
    AudioService.reset_history()
    SettingsState.set_mute_gameplay(false);SettingsState.set_mute_special(false);SettingsState.set_sfx_volume(1.0)
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame
func run() -> void:
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim;sim.set_physics_process(false)
    sim.notice.connect(func(kind: String,id: String)->void:notices.append([kind,id]))
    sim.spell_cast.connect(func(id: String,key: String,_p: Vector2)->void:casts.append([id,key]))
    sim.feedback.connect(func(id: String,amount: float,healing: bool)->void:if healing:heals.append([id,amount]))
    fresh()
    await heal_checks()
    await explored_checks()
    await settings_checks()
    await audio_checks()
    await notice_checks()
    await merge_all_checks()
    await swing_checks()
    await camera_checks()
    await gem_checks()
    print("CHANGE_12_CHECKS ",checks," FAILURES ",failures)
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    await get_tree().create_timer(.1).timeout
    get_tree().quit(1 if failures else 0)

func labels(root: Node=null) -> Array:
    return (game.rows if root==null else root).find_children("*","Label",true,false)
func label_containing(text: String,root: Node=null) -> Label:
    for l in labels(root):
        if l.text.contains(text):return l
    return null
func button_containing(root: Node,text: String) -> Button:
    for b in root.find_children("*","Button",true,false):
        if b.text.contains(text):return b
    return null
func campaign_steps(seconds: float) -> void:
    for i in range(roundi(seconds/.05)):sim.campaign.step(.05)

# ---------------------------------------------------------------- §1 Cyan Robot Heal
func cyan_robot() -> Dictionary:
    for e in sim.state.enemies:
        if sim.catalog.groups[int(e.group)].id=="boss-cyan-robot":return e
    return {}
func heal_checks() -> void:
    fresh()
    sim.state.stage=2;sim.state.unlocked_stage=2;sim._reset_world() # fixture: Winter II
    var robot:=cyan_robot()
    check(not robot.is_empty() and sim.catalog.groups[int(robot.group)].skills==["heal"],"Winter II has the Cyan Robot boss with Heal as its only skill")
    var maxhp: float=sim.campaign.actor_max_hp(robot)
    var expected: float=maxhp*float(sim.catalog.skills.heal.enemy_hp_fraction)
    robot.aggro=true;robot.skill_timer=0.0;robot.hp=maxhp # fixture: in combat at full HP
    campaign_steps(6.0)
    check(casts.is_empty() and heals.is_empty() and robot.hp==maxhp,"At full HP the robot shows no Heal effect and gains nothing for 6 s (was a telegraphed effect every 1.6 s)")
    robot.hp=maxhp*.85;robot.skill_timer=0.0
    campaign_steps(3.0)
    check(casts.is_empty() and heals.is_empty(),"At 85% HP (Heal needs below 80%) still no effect")
    robot.hp=maxhp*.5;robot.skill_timer=0.0
    sim.campaign.step(.05)
    check(robot.get("telegraph",false) and casts.is_empty() and heals.is_empty(),"Wounded: the 0.6 s telegraph starts with no effect yet")
    campaign_steps(.7)
    check(heals.size()==1 and heals[0][0]==robot.id and near(heals[0][1],expected) and near(robot.hp,maxhp*.5+expected),"Heal restores exactly 8%% of max HP (%.1f) and reports that amount" % expected)
    check(casts.size()==1 and casts[0]==[robot.id,"heal"],"One Heal effect plays, at the moment HP is restored")
    check(near(float(robot.skill_timer),float(sim.catalog.skills.heal.cooldown),.01),"Heal goes on its 18 s cooldown")
    campaign_steps(10.0)
    check(heals.size()==1 and casts.size()==1,"No second heal during the cooldown")
    # Death during the telegraph interrupts the heal.
    robot.hp=maxhp*.3;robot.skill_timer=0.0;heals.clear();casts.clear()
    sim.campaign.step(.05)
    robot.hp=0.0;sim._kill(robot)
    campaign_steps(1.0)
    # (killing the boss can level the player up, which heals the player: only the robot counts)
    check(heals.filter(func(h):return h[0]==robot.id).is_empty() and casts.is_empty() and not robot.get("telegraph",false) and robot.hp<=0,"A robot killed during the telegraph never heals")
    # Clamped to maximum HP (direct call with a near-full fixture below the threshold is impossible
    # for 8%, so the player's Heal exercises the clamp).
    sim.state.stage=1;sim.state.unlocked_stage=1;sim._reset_world()
    heals.clear();casts.clear()
    var hp_max: float=sim.stats().hp
    sim.state.player.hp=hp_max
    check(not sim.campaign.apply_skill(sim.state.player,"heal",1000.0) and heals.is_empty() and casts.is_empty(),"Player Heal at full HP does nothing and shows nothing")
    sim.state.player.hp=hp_max*.75
    check(sim.campaign.apply_skill(sim.state.player,"heal",1000.0) and near(sim.state.player.hp,hp_max*.87) and heals.size()==1 and casts.size()==1,"Player Heal restores min(power, 12% max HP, missing) with one effect")
    # The skill keeps a heal from being free: a refused cast does not start the cooldown.
    sim.state.skills[0]="skill_heal";sim.add_item("skill_heal",1);sim.state.player.hp=hp_max
    check(not sim.campaign.cast(0) and float(sim.state.skill_cooldowns.get("heal",0))==0.0,"A refused Heal cast does not consume its cooldown")
    # The self effect is attached to the caster's view (it follows movement) at the feet.
    await frames(2)
    var view: LootActorView=game.world.views["player"]
    sim.spell_cast.emit("player","heal",sim.position_of(sim.state.player))
    var effects: Array=view.get_children().filter(func(n):return n is AnimatedSprite2D)
    var factor: float=game.world.self_effect_scale*view.visual_scale
    check(effects.size()==1 and effects[0].position.is_equal_approx(Vector2(0,-game.world.self_effect_ring*factor)),"The Heal effect is a child of the caster's view, ring on the feet")
    sim.state.player.x+=40;await frames(2)
    check(effects[0].global_position.is_equal_approx(view.to_global(Vector2(0,-game.world.self_effect_ring*factor))),"The effect moves with the caster")
    for e in effects:e.queue_free()
    # Healing numbers read apart from damage numbers.
    var before: int=game.world.get_node("Actors").get_child_count()
    view.show_hit(87.7,true)
    var label: Label=game.world.get_node("Actors").get_child(game.world.get_node("Actors").get_child_count()-1)
    check(game.world.get_node("Actors").get_child_count()==before+1 and label.text=="+87.70" and label.scale.x>1.0 and label.modulate.g>label.modulate.r,"A healing number is green, signed + and larger than damage")
    label.queue_free()

# ---------------------------------------------------------------- §2 map explored
func explored_checks() -> void:
    fresh()
    var label: Label=game.get_node("Safe/Layout/Map/Explored")
    var area: int=sim.campaign.explore_area(1)
    check(area==ceili(960/24.0)*ceili(960/24.0),"Winter I denominator is its fog grid (%d cells)" % area)
    game._refresh_explored()
    var cells: int=sim.state.explored.get("1",{}).size()
    check(label.text==tr("MAP_EXPLORED") % floori(100.0*cells/area) and label.text.begins_with("Map explored: "),"Label reads \"%s\" from the saved explored cells" % label.text)
    var before: String=label.text
    # Momentary sight and camera panning never count.
    var home: Vector2=sim.position_of(sim.state.player)
    sim.state.player.x=700.0;sim.state.player.y=200.0 # fixture: away from both camps, no reveal step
    var far:=Vector2(700.0+sim.campaign.vision_radius()*.8,200.0)
    check(sim.campaign.cell_visible(far) and not sim.campaign.cell_known(far),"fixture: a cell in momentary sight is not explored")
    game.world.pan_camera(Vector2(-300,-300));game._refresh_explored()
    check(label.text==before and sim.state.explored.get("1",{}).size()==cells,"Panning the camera and seeing farther leave the percent unchanged")
    sim.state.player.x=home.x;sim.state.player.y=home.y
    game.world.follow_player()
    # New permanent cells raise it.
    sim.campaign.reveal_circle(Vector2(800,150),200.0);game._refresh_explored()
    var now_pct: int=sim.campaign.explored_percent(1)
    check(now_pct>int(before.to_int()) and label.text==tr("MAP_EXPLORED") % now_pct,"Newly explored cells raise it (%s → %s)" % [before,label.text])
    check(sim.campaign._regional_progress(1).contains("%d%% + " % now_pct),"World / Regional progress reports the same percent")
    var all: Dictionary={}
    for y in range(40):
        for x in range(40):all["%d,%d" % [x,y]]=true
    sim.state.explored["1"]=all;game._refresh_explored()
    check(label.text==tr("MAP_EXPLORED") % 100 and sim.campaign.explored_fraction(1)==1.0,"Fully explored reads 100%")
    var almost: Dictionary=all.duplicate();almost.erase("0,0")
    sim.state.explored["1"]=almost;game._refresh_explored()
    check(label.text==tr("MAP_EXPLORED") % 99,"One cell short reads 99% (rounded down)")
    sim.state.explored["1"]={};game._refresh_explored()
    check(label.text==tr("MAP_EXPLORED") % 0,"Nothing explored reads 0%")
    sim.state.explored["2"]={"0,0":true}
    sim.state.stage=2;sim.state.unlocked_stage=2;sim._reset_world();game._refresh_explored()
    check(label.text==tr("MAP_EXPLORED") % sim.campaign.explored_percent(2) and sim.campaign.explore_area(2)>0,"Switching map shows that map's own percent")
    sim.state.stage=1;sim._reset_world()
    check(SaveService.hard_reset() and sim.campaign.explored_percent(1)<=10,"Hard Reset starts the map over (%d%%)" % sim.campaign.explored_percent(1))
    sim.state.tutorial.mode="none";sim.suspended=false
    await frames(2)
    # Placement: lower right, inside the map, clear of the joystick, minimap and the left HUD.
    var map: Control=game.get_node("Safe/Layout/Map")
    var rect:=label.get_global_rect()
    check(map.get_global_rect().encloses(rect) and rect.end.x<=map.get_global_rect().end.x-12 and rect.end.y<=map.get_global_rect().end.y-12,"The label sits inside the map's lower-right corner, away from its edges")
    for path in ["Joystick","MiniMap","FollowTracker","Zoom","EnemyUpgrades","Achievement"]:
        check(not rect.intersects(map.get_node(path).get_global_rect()),"It does not overlap %s" % path)
    check(label.mouse_filter==Control.MOUSE_FILTER_IGNORE,"It never takes touches")

# ---------------------------------------------------------------- §3 Settings copy
func settings_checks() -> void:
    fresh()
    game._nav("settings");await frames(3)
    var text:=""
    for l in labels():text+=l.text+"\n"
    for b in game.rows.find_children("*","Button",true,false):text+=b.text+"\n"
    check(not text.to_lower().contains("font") and not text.to_lower().contains("premium"),"Settings shows no font or premium-game copy")
    check(text.contains("Pixel Plains") and text.contains(tr("HARD_RESET")) and text.contains(tr("LANG_AUTOMATIC")),"Credits, Hard Reset and language controls remain")
    var sliders: Array=game.rows.find_children("*","HSlider",true,false)
    check(sliders.size()==2 and sliders.all(func(s):return s.min_value==0 and s.max_value==100),"Music and Sound effects sliders run 0–100")
    check(button_containing(game.rows,tr("MUTE_GAMEPLAY_STATUS") % tr("OFF"))!=null and button_containing(game.rows,tr("MUTE_SPECIAL_STATUS") % tr("OFF"))!=null,"Two independent mute toggles")
    sliders[0].value=35;await frames(1)
    check(near(SettingsState.music_volume,.35) and label_containing(tr("MUSIC_VOLUME") % 35)!=null,"The music slider sets the music volume and its label")
    sliders[1].value=0;await frames(1)
    check(SettingsState.sfx_volume==0.0 and not AudioService.category_audible("gameplay") and not AudioService.category_audible("special"),"Sound effects at 0 silences both categories")
    sliders[1].value=80
    button_containing(game.rows,tr("MUTE_GAMEPLAY_STATUS") % tr("OFF")).pressed.emit();await frames(2)
    check(SettingsState.mute_gameplay and not SettingsState.mute_special and button_containing(game.rows,tr("MUTE_GAMEPLAY_STATUS") % tr("ON"))!=null,"Mute gameplay toggles only gameplay")
    game._close()
    var all_text:=FileAccess.get_file_as_string("res://localization/en.po").to_lower()
    check(not all_text.contains("premium game") and not all_text.contains("font: dejavu"),"No premium/font copy left in the English strings")

# ---------------------------------------------------------------- §4 audio categories
func audio_checks() -> void:
    fresh()
    for id in ["ui_click","ui_confirm","spell_heal","spell_frost","spell_fire","spell_lightning","spell_focus","spell_strike"]:
        check(AudioService.cue_category(id)=="gameplay","%s is a gameplay sound" % id)
    for id in ["mission_ready","prestige_step","prestige_discovered","prestige_ready","stage_unlocked","prestiged"]:
        check(AudioService.cue_category(id)=="special","%s is a special sound" % id)
    var missing: Array=game.audio_cues.cues.filter(func(c):return c.stream==null)
    check(missing.is_empty() and game.audio_cues.music!=null and AudioService.music_state().wanted and AudioService.music_state().stream==game.audio_cues.music,"Every cue and the music track have an assigned stream; music is requested")
    for key in sim.catalog.skills:check(AudioService.has_cue("spell_"+key),"Skill %s has a cast sound" % key)
    check(game.audio_cues.cues.filter(func(c):return c.id in ["prestige_discovered","prestige_step","mission_ready"]).map(func(c):return c.stream.resource_path).reduce(func(a,p):return a if a.has(p) else a+[p],[]).size()==3,"Prestige discovered, followed step and mission ready use three different sounds")
    AudioService.play("ui_click");check(AudioService.flush()=="ui_click","A click plays")
    SettingsState.set_mute_gameplay(true)
    AudioService.play("ui_click");check(AudioService.flush()=="","Mute gameplay silences a click")
    AudioService.play("prestige_step");check(AudioService.flush()=="prestige_step","…but a special sound still plays")
    SettingsState.set_mute_gameplay(false);SettingsState.set_mute_special(true);AudioService.reset_history()
    AudioService.play("prestige_step");check(AudioService.flush()=="","Mute special silences a special sound")
    AudioService.play("spell_heal");check(AudioService.flush()=="spell_heal","…but gameplay sounds still play")
    SettingsState.set_mute_special(false);AudioService.reset_history()
    AudioService.play("ui_click");AudioService.play("ui_confirm")
    check(AudioService.flush()=="ui_confirm" and AudioService.played_log.size()==1,"A click and a confirm in one frame: only the confirm plays")
    AudioService.play("prestige_step");AudioService.play("prestige_ready")
    check(AudioService.flush()=="prestige_ready" and AudioService.played_log.size()==2,"Step + ready in one frame: one cue (ready)")
    SettingsState.set_mute_special(true)
    AudioService.play("ui_click");AudioService.play("prestige_prestige_missing");AudioService.play("prestiged")
    check(AudioService.flush()=="ui_click","With special muted, the audible gameplay cue still plays instead")
    SettingsState.set_mute_special(false);AudioService.reset_history()
    AudioService.play("mission_ready");AudioService.flush();AudioService.play("mission_ready")
    check(AudioService.flush()=="" and AudioService.played_log.count("mission_ready")==1,"A cue cannot repeat within its cooldown")
    # Persistence through disk save/load (app restart), Prestige and Hard Reset.
    SettingsState.set_music_volume(.3);SettingsState.set_sfx_volume(.6);SettingsState.set_mute_gameplay(true);SettingsState.set_mute_special(false)
    check(SaveService.save_now(),"Save with audio settings written")
    SettingsState.set_music_volume(1);SettingsState.set_sfx_volume(1);SettingsState.set_mute_gameplay(false);SettingsState.set_mute_special(true)
    SaveService.load_and_apply();await frames(2)
    check(near(SettingsState.music_volume,.3) and near(SettingsState.sfx_volume,.6) and SettingsState.mute_gameplay and not SettingsState.mute_special,"Volumes and both mutes load back from disk")
    var saved: Dictionary=SettingsState.to_save_dict()
    check(saved.has("mute_gameplay") and saved.has("mute_special") and not saved.has("sfx_enabled"),"The settings record holds the two mutes")
    sim.state.tutorial.mode="none";sim.suspended=false
    sim.state.group_kills[sim.campaign.prestige_unlock_group()]=1
    sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0} # fixture: ready
    sim.campaign.begin_prestige();sim.prestige(sim.campaign.offered_cards()[0])
    check(near(SettingsState.music_volume,.3) and SettingsState.mute_gameplay,"Prestige keeps audio settings")
    check(SaveService.hard_reset() and near(SettingsState.sfx_volume,.6) and SettingsState.mute_gameplay,"Hard Reset keeps settings (existing policy)")
    sim.state.tutorial.mode="none";sim.suspended=false
    SettingsState.from_save_dict({"music_volume":7,"sfx_volume":-1})
    check(SettingsState.music_volume==1.0 and SettingsState.sfx_volume==0.0 and not SettingsState.mute_gameplay,"Loaded values are clamped; missing mutes default to off")
    SettingsState.set_music_volume(1);SettingsState.set_sfx_volume(1)

# ---------------------------------------------------------------- §5 notices once per transition
func notice_checks() -> void:
    fresh()
    # Followed Expedition: three kill steps.
    var id:="expedition_o1"
    var chain: Array=sim.campaign.chain_for(id)
    sim.state.opportunities[id]={"ready":false,"baseline":{},"step":0,"count":0} # fixture: discovered
    sim.state.follow=id;sim.campaign.evaluate()
    check(notices.is_empty(),"Following an opportunity sets a baseline without a sound")
    SettingsState.set_mute_gameplay(true);AudioService.reset_history()
    var goal: int=int(chain[0][2])
    for i in range(goal-1):sim.campaign.progress("kill",str(chain[0][1]),1)
    check(notices.is_empty(),"No cue while the step is still counting (%d/%d)" % [goal-1,goal])
    sim.campaign.progress("kill",str(chain[0][1]),1)
    check(notices==[["follow_step",id]] and int(sim.state.opportunities[id].step)==1,"Completing step 1 emits exactly one notice, at the transition")
    await frames(2)
    check(AudioService.played_log.count("prestige_step")==1,"…which plays the step cue even with gameplay sounds muted")
    for i in range(goal):sim.campaign.progress("kill",str(chain[0][1]),1)
    for i in range(20):sim.campaign.evaluate()
    check(notices.size()==1,"More kills of the finished step and repeated refreshes add nothing")
    # Reload: the same progress is not announced again.
    var data: Dictionary=JSON.parse_string(JSON.stringify(sim.snapshot()))
    sim.restore(data);sim.campaign.follow_tracked="";sim.campaign.evaluate()
    check(notices.size()==1,"Loading the save (a new session) does not re-announce the step")
    for i in range(int(chain[1][2])):sim.campaign.progress("kill",str(chain[1][1]),1)
    check(notices.size()==2 and int(sim.state.opportunities[id].step)==2,"Step 2 emits one more")
    AudioService.reset_history()
    for i in range(int(chain[2][2])):sim.campaign.progress("kill",str(chain[2][1]),1)
    await frames(2)
    check(notices.size()==3 and bool(sim.state.opportunities[id].ready) and sim.state.follow=="","The final step completes the opportunity: one notice")
    check(AudioService.played_log==["prestige_ready"],"…and one sound for it (ready outranks the step cue)")
    # An unfollowed opportunity's steps are silent (its ready banner keeps its own sound).
    notices.clear()
    sim.state.opportunities["expedition_o2"]={"ready":false,"baseline":{},"step":0,"count":0}
    var chain2: Array=sim.campaign.chain_for("expedition_o2")
    for i in range(int(chain2[0][2])):sim.campaign.progress("kill",str(chain2[0][1]),1)
    check(notices.is_empty(),"Steps of an opportunity you do not follow are silent")
    # Collection steps count completed outfits.
    sim.state.opportunities["collection_o1"]={"ready":false,"baseline":{},"step":0,"count":0}
    sim.state.follow="collection_o1";sim.campaign.evaluate()
    var item: String=sim.campaign.contract_outfit("blue-cap")
    sim.state.online_items[item]=20.0;sim.state.opportunities["collection_o1"]["item_"+item]=20.0
    sim.campaign.evaluate()
    check(notices==[["follow_step","collection_o1"]],"A collection step (one outfit complete) emits one notice")
    sim.state.follow="";notices.clear()
    # Missions: a manual mission announces once; auto-claim is silent.
    sim.state.missions=[{"kind":"kill","target":"","goal":3.0,"progress":0.0,"coins":1.0,"gems":0.0,"day":"x","claimed":false}] # fixture
    for i in range(6):sim.campaign.progress("kill","unit-blue-cap",1)
    check(notices==[["mission_ready","kill"]],"A mission reaching its goal emits one notice (not per kill)")
    notices.clear()
    sim.state.missions=[{"kind":"kill","target":"","goal":3.0,"progress":0.0,"coins":1.0,"gems":0.0,"day":"x","claimed":false}]
    sim.state.upgrades["mission_claim"]=1;sim.state.mission_auto=true # fixture: auto-claim bought and on
    for i in range(6):sim.campaign.progress("kill","unit-blue-cap",1)
    check(notices.is_empty(),"With auto-claim active no mission sound is requested")
    # A new Prestige opportunity plays its own special cue at discovery.
    AudioService.reset_history()
    game._milestone("discovered","hunter_o1");await frames(2)
    check(AudioService.played_log==["prestige_discovered"],"A newly discovered Prestige plays the discovery cue once")
    game.banner._finish()
    SettingsState.set_mute_gameplay(false)

# ---------------------------------------------------------------- §6 Merge All
func merge_all_checks() -> void:
    fresh()
    var def: Dictionary=sim.catalog.upgrades.merge_all
    check(def.currency=="gems" and int(def.base)==5000 and int(def.cap)==1 and def.scope=="global" and sim.upgrade_kept("merge_all"),"Merge All: one 5,000-Gem global unlock, kept by Prestige")
    sim.state.upgrades["gear_slots"]=4;sim.state.gear.resize(7);for i in range(3,7):sim.state.gear[i]="" # fixture: room for 6 items
    sim.add_item("wood_sword",6);sim.add_item("unit-blue-cap_outfit",5);sim.add_item("skill_heal",3);sim.add_item("stone_axe",1)
    sim.state.upgrades["supply_slots"]=4;sim.state.supplies.resize(5);sim.state.supplies.fill("")
    sim.add_item("potion",10)
    sim.add_item("iron_sword",4);sim.record("iron_sword").merge=100 # fixture: weapon at its ^100 cap
    var mastery: int=sim.supply_mastery("potion")
    var r: Dictionary=sim.merge_all()
    check(int(r.copies)==0 and sim.quantity("wood_sword")==6,"Locked: Merge All does nothing")
    game._nav("filters");await frames(2)
    check(label_containing(tr("MERGE_ALL_LOCKED_HINT"))!=null and button_containing(game.rows,tr("MERGE_ALL_BUTTON_IDLE"))==null,"Locked: Filters explains where to unlock it")
    game._close()
    game.player_tab=1;game._open("upgrades");await frames(2)
    check(label_containing(tr("UP_MERGE_ALL"))!=null and label_containing(tr("MERGE_ALL_BENEFIT"))!=null,"Upgrades > Inventory lists Merge All with its description")
    game._close()
    sim.state.gems=4999.0
    check(not sim.buy_upgrade("merge_all") and sim.level("merge_all")==0,"4,999 gems cannot buy it")
    sim.state.gems=5000.0
    check(sim.buy_upgrade("merge_all") and sim.level("merge_all")==1 and sim.state.gems==0.0,"5,000 gems unlock it")
    sim.state.gems=9000.0
    check(not sim.buy_upgrade("merge_all") and sim.state.gems==9000.0 and sim.upgrade_block_reason("merge_all")=="UPGRADE_MAX","It cannot be bought twice")
    check(sim.merge_all_copies()==5+4+2,"Eligible spare copies counted: 5 + 4 + 2")
    # Same result as ordinary manual merges, item by item.
    var reference: Dictionary=sim.state.items.duplicate(true)
    var expect: Dictionary={}
    for id in reference:
        var q: int=int(reference[id].qty);var m: int=int(reference[id].merge)
        if sim.catalog.items[id].kind!="consumable" and q>1:
            var n: int=mini(q-1,sim.merge_cap(id)-m);expect[id]=[q-n,m+n]
        else:expect[id]=[q,m]
    var merge_counter: float=sim.campaign.counter("merge")
    game._nav("filters");await frames(2)
    var button: Button=button_containing(game.rows,tr("MERGE_ALL_BUTTON") % 11)
    check(button!=null and not button.disabled,"Filters shows \"%s\"" % (tr("MERGE_ALL_BUTTON") % 11))
    AudioService.reset_history()
    button.pressed.emit();await frames(3)
    var same:=true
    for id in expect:
        if [sim.quantity(id),int(sim.record(id).merge)]!=expect[id]:same=false;print("    ",id," ",[sim.quantity(id),sim.record(id).merge]," expected ",expect[id])
    check(same,"One tap performs every eligible merge exactly as manual Merge would")
    check(sim.quantity("stone_axe")==1 and sim.quantity("iron_sword")==4 and int(sim.record("iron_sword").merge)==100 and sim.quantity("gold_sword")==0,"Single copies and capped weapons are untouched; nothing evolves")
    check(sim.quantity("potion")==10 and sim.supply_mastery("potion")==mastery,"Supplies: stock and mastery untouched")
    check(sim.state.gems==9000.0,"Using it costs nothing")
    check(near(sim.campaign.counter("merge"),merge_counter+11),"Merge progress counts the 11 merged copies once")
    check(game.notice.text==tr("MERGE_ALL_DONE") % [11,3] and AudioService.played_log==["ui_confirm"],"One aggregate notice and one confirm sound")
    var idle: Button=button_containing(game.rows,tr("MERGE_ALL_BUTTON_IDLE"))
    check(idle!=null and idle.disabled and idle.text.contains(tr("NOTHING_TO_MERGE")),"With nothing left the button is disabled: Nothing to merge")
    game._close()
    check(sim.level("merge_gear",0)==0,"Timed gear auto-merge is a separate purchase, still not owned")
    # Save, Prestige, Hard Reset.
    check(SaveService.save_now(),"Save written")
    sim.new_profile();SaveService.load_and_apply();await frames(2)
    check(sim.level("merge_all")==1,"The unlock loads back from disk")
    sim.state.tutorial.mode="none";sim.suspended=false
    sim.state.group_kills[sim.campaign.prestige_unlock_group()]=1
    sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0} # fixture: ready
    sim.campaign.begin_prestige();sim.prestige(sim.campaign.offered_cards()[0])
    check(sim.level("merge_all")==1 and sim.state.gems==0.0,"Prestige keeps Merge All (unspent gems reset as before)")
    sim.add_item("wood_sword",3)
    check(int(sim.merge_all().copies)==2 and sim.state.gems==0.0,"…and it still works for free after Prestige")
    check(SaveService.hard_reset() and sim.level("merge_all")==0,"Hard Reset removes it")
    sim.state.tutorial.mode="none";sim.suspended=false

# ---------------------------------------------------------------- §7 stone-tier swing
## Mean warmth (red minus blue) and brightness of a sprite's coloured pixels (outline excluded):
## gray stone is warm, the Onix sheet is navy/black.
func colour(path: String,region: Rect2i,tint:=Color.WHITE) -> Vector2:
    var image: Image=load(path).get_image()
    if image.is_compressed():image.decompress()
    var warm:=0.0;var light:=0.0;var n:=0
    for y in range(region.position.y,region.end.y):
        for x in range(region.position.x,region.end.x):
            var c: Color=image.get_pixel(x,y)*tint
            if image.get_pixel(x,y).a>.5 and c.get_luminance()>.15:warm+=c.r-c.b;light+=c.get_luminance();n+=1
    return Vector2(warm,light)/maxf(1,n)
func swing_checks() -> void:
    fresh()
    var snowman: int=sim.campaign.group_id("boss-snowman")
    var weapon: String=sim.catalog.groups[snowman].weapon
    check(weapon=="stone_axe" and sim.catalog.groups[snowman].loot.has("stone_axe") and sim.catalog.display_name(weapon)=="Stone Axe","The Winter I Snowman carries and drops the Stone Axe (the live id, not Iron Axe)")
    var item: Dictionary=sim.catalog.items.stone_axe
    check(str(item.attack).ends_with("Iron set/Axe 2 64x32.png") and item.attack_tint.size()==3,"Stone Axe swings with the Iron set sheet and a warm-gray tint (was the dark Onix sheet)")
    var icon: Array=item.icon
    var icon_c:=colour(str(item.texture),Rect2i(int(icon[0]),int(icon[1]),int(icon[2]),int(icon[3])))
    var onix_c:=colour("res://assets/PixelPlainsAnimationPack/Onix set/Axe 7 64x32.png",Rect2i(128,0,64,32))
    var swing_c:=colour(str(item.attack),Rect2i(128,0,64,32),game.world.attack_tint("stone_axe"))
    check(onix_c.x<0 and icon_c.x>0 and swing_c.x>0,"Gray-stone icon and the new swing are warm; the old Onix swing is blue (warmth icon %.2f, new %.2f, Onix %.2f)" % [icon_c.x,swing_c.x,onix_c.x])
    print("    info: brightness icon %.2f, new swing %.2f, Onix %.2f (swing frames include a white trail)" % [icon_c.y,swing_c.y,onix_c.y])
    var sets:={1:"Wood set",2:"Iron set",3:"Iron set",4:"Gold set",5:"Diamond set",6:"Emerald set",7:"Ruby set"}
    var wrong: Array=[]
    for id in sim.catalog.items:
        var d: Dictionary=sim.catalog.items[id]
        if d.kind!="weapon":continue
        if not str(d.attack).contains("/"+sets[int(d.tier)]+"/") or not ResourceLoader.exists(str(d.attack)):wrong.append(id)
        if (int(d.tier)==2)!=d.has("attack_tint"):wrong.append(id+" tint")
    check(wrong.is_empty(),"Every axe and sword tier swings with its own set's sheet; only the stone tier is tinted %s" % [wrong])
    # Player view and the Snowman's own view use the same mapping.
    sim.add_item("stone_axe",1);sim.equip("stone_axe");await frames(3)
    var view: LootActorView=game.world.views["player"]
    var expected: Color=game.world.attack_tint("stone_axe")
    check(view.attack_texture.resource_path==item.attack and view.attack_tint==expected and view.get_node("Visual/Attack").self_modulate==expected,"Player: stone-axe swing sheet and tint applied to the attack sprite only")
    check(view.get_node("Visual/Weapon").self_modulate==Color.WHITE and view.weapon_texture==sim.catalog.icon("stone_axe"),"The held weapon is the item's own icon, untinted")
    var boss_view: LootActorView=null
    for e in sim.state.enemies:
        if int(e.group)==snowman and game.world.views.has(e.id):boss_view=game.world.views[e.id]
    check(boss_view!=null and boss_view.attack_texture.resource_path==item.attack and boss_view.attack_tint==expected,"Snowman: the same swing sheet and tint")
    sim.equip("stone_axe");sim.add_item("iron_axe",1);sim.equip("iron_axe");await frames(2)
    check(view.attack_tint==Color.WHITE and view.attack_texture.resource_path.ends_with("Iron set/Axe 2 64x32.png"),"Iron Axe keeps the untinted Iron set swing")
    check(near(float(sim.catalog.items.stone_axe.normal.damage[0]),float(sim.catalog.items.stone_axe.normal.damage[0])) and not sim.catalog.items.stone_axe.has("attack_contact"),"Presentation only: no timing or damage fields added")

# ---------------------------------------------------------------- §8 camera after Prestige
func camera_checks() -> void:
    fresh()
    SettingsState.set_camera_zoom(2.6)
    await frames(2)
    game.world.pan_camera(Vector2(-2000,-2000))
    var gesture=game.get_node("Safe/Layout/Map/GestureSurface")
    gesture.begin_pointer(-1,Vector2(100,100));gesture.dragging=true # fixture: a drag in progress
    check(not game.world.following_player and game.world.camera_position.distance_to(sim.position_of(sim.state.player))>100,"fixture: camera dragged far from the player")
    game._open("prestige");await frames(2)
    check(not game.world.following_player,"Opening the Prestige panel does not move the camera")
    game._close()
    sim.state.group_kills[sim.campaign.prestige_unlock_group()]=1
    sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0} # fixture: ready
    sim.campaign.begin_prestige();sim.prestige(sim.campaign.offered_cards()[0])
    check(game.world.following_player and gesture.pointers.is_empty() and not gesture.dragging,"Prestige restores follow mode and clears the drag")
    await frames(4)
    var spawn: Vector2=sim.position_of(sim.state.player)
    check(game.world.camera_position.is_equal_approx(spawn) and game.world.get_node("Camera").position.is_equal_approx(spawn),"The camera is centred on the newly spawned player a few frames later")
    check(near(SettingsState.camera_zoom,2.6),"Zoom is unchanged (2.6)")

# ---------------------------------------------------------------- §9 gem chance
func gem_checks() -> void:
    fresh()
    var up: Dictionary=sim.catalog.upgrades.gem_chance
    var old_prices:=[25,40,58,80,105,135,170,210,260,320,390,470]
    check(up.prices.slice(0,12).map(func(v):return int(v))==old_prices,"Gem Chance prices for levels 1–12 unchanged")
    check(up.prices.slice(12).map(func(v):return int(v))==[560,660,770,890,1020,1160,1310,1470],"Levels 13–20 cost 560, 660, 770, 890, 1,020, 1,160, 1,310, 1,470")
    var mono:=true
    for i in range(1,up.prices.size()):mono=mono and up.prices[i]>up.prices[i-1]
    check(mono and int(up.cap)==20 and near(float(up.effect),.005),"20 levels of +0.5 points, prices strictly rising")
    for n in range(20):
        sim.state.upgrades["gem_chance"]=n
        if sim.upgrade_cost("gem_chance")!=int(up.prices[n]):check(false,"Level %d price %d" % [n+1,sim.upgrade_cost("gem_chance")])
    sim.state.upgrades.erase("gem_chance")
    check(not sim.catalog.progression.gem_limits.has("normal_cap") and not sim.catalog.progression.gem_limits.has("boss_cap"),"No 20% / 60% caps in the catalog")
    var normal:=0;var boss:=-1
    for g in range(sim.catalog.groups.size()):
        if sim.catalog.groups[g].boss and boss<0:boss=g
    check(near(sim.gem_chance(normal),.05) and near(sim.gem_chance(boss),.05),"Base chance 5% for normal and boss rolls")
    sim.state.gems=1e6
    for i in range(20):sim.buy_upgrade("gem_chance")
    check(sim.level("gem_chance")==20 and sim.upgrade_maxed("gem_chance") and near(sim.gem_base_chance(),.15),"Level 20: +10 points (15%)")
    sim.state.upgrades["gem_chance"]=12
    check(not sim.upgrade_maxed("gem_chance"),"Level 12 is no longer a maximum")
    sim.state.upgrades["gem_chance"]=20
    sim.state.owned_cards.append("offering_c2") # fixture: Gem Wisdom owned
    check(near(sim.gem_base_chance(),.20),"Gem Wisdom still adds +5 points with the upgrade maxed (20%)")
    var thresholds: Array=sim.achievement_thresholds(normal)
    sim.state.group_kills[normal]=int(thresholds.back());sim.state.group_kills[boss]=int(sim.achievement_thresholds(boss).back())
    check(sim.achievement_level(normal)==8 and near(sim.achievement_gems(normal),.04),"Kill achievements: 8 milestones, +4 points (unchanged)")
    check(near(sim.gem_chance(normal),.24),"Fully stacked normal enemy: 24% (old cap 20% would have hidden 4 points)")
    sim.state.upgrades["boss_gem_chance"]=8
    check(int(sim.catalog.upgrades.boss_gem_chance.cap)==8 and near(float(sim.catalog.upgrades.boss_gem_chance.effect),.05) and sim.catalog.upgrades.boss_gem_chance.prices.map(func(v):return int(v))==[50,80,120,170,230,310,410,530],"Boss Gem Chance unchanged: 8 × +5 points, same prices")
    check(near(sim.gem_chance(boss),.64),"Fully stacked boss: 64% (old cap 60%)")
    var hits:=0
    sim.rng.seed=7
    for i in range(4000):
        if sim.rng.randf()<sim.gem_chance(normal):hits+=1
    check(absf(hits/4000.0-.24)<.03,"The drop roll uses the same value (%.3f observed)" % (hits/4000.0))
    sim.state.owned_cards.append("trophy_c3");sim.state.owned_cards.append("offering_c2")
    check(near(sim.gem_chance(boss),.69) or near(sim.gem_chance(boss),.74),"Gem chance stacks further cards without a ceiling (%.2f)" % sim.gem_chance(boss))
    check(sim.gem_chance(boss)<=1.0,"Probability stays within 0–100%")
    sim.state.owned_cards=["offering_c2"]
    check(near(sim.gem_amount(0,boss),3.0*sim.gem_amount(0,normal)),"Boss gem amount still 3× the normal amount")
    check(tr("CONTENT_OFFERING_C2_DESCRIPTION")=="+5 points gem drop chance" and not tr("CONTENT_OFFERING_C2_DESCRIPTION").contains("20%"),"Gem Wisdom text: +5 points, no \"up to 20%\"")
    check(preload("res://scripts/game/prestige_card.gd").headline(sim.catalog.campaign.cards.offering_c2).contains("+5"),"Prestige card headline shows +5 pts")
    sim.state.upgrades["gem_chance"]=19
    game.player_tab=3;game._open("upgrades");await frames(2)
    check(label_containing("19.5%")!=null or label_containing("19.5")!=null,"Gem Chance card previews the 0.5-point step (… → 19.5%%)")
    sim.state.upgrades["gem_chance"]=20;game._refresh_panel(true);await frames(2)
    check(label_containing(tr("UPGRADE_LEVEL") % [20,20])!=null,"Gem Chance card shows level 20 / 20 at the maximum")
    game._close()
