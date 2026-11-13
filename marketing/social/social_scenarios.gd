extends "res://marketing/game_scenarios.gd"
## LootFarmer social-video adapter (the vertical social masters, marketing/social/README.md). It extends the store
## adapter and adds ONE data-driven scenario, "soc": a staged profile (the store adapter's own
## _stage_profile / _late_profile), a placement, and a list of timed steps. Every step calls what the
## player's own tap calls (the item panel's Merge / Evolve buttons, sim.equip, sim.collect, sim.use_item,
## the Teleport picker's own controls, campaign.settle_offline / the Claim button). Fixtures stand in for
## play time only; combat, crits, drops, merges, evolutions, travel and their effects are the game's code.
## Every other scenario id is handled by the store adapter unchanged. Nothing here ships.

func prepare_scenario(scenario_id: String,options_: Dictionary,game_root: Node,capture: Dictionary) -> bool:
    if scenario_id!="soc":
        var done: bool=super.prepare_scenario(scenario_id,options_,game_root,capture)
        # The store profile predates the ^20 cap of evolvable weapons (Change 51): show what merges now.
        if done and scenario_id=="shot_prestige":
            for id in sim.state.items:
                if sim.catalog.items[id].kind=="weapon":sim.record(id).merge=mini(int(sim.record(id).merge),sim.merge_cap(id))
            game.slot_signatures.clear();game._refresh_slots()
        # Change 73: timed steps on the store adapter's scenarios too (the Prestige card kept by its own
        # button, so the committed Prestige plays its celebration).
        if done and options_.has("steps"):
            sim.milestone.connect(func(kind,id):print(LOG,"MILESTONE ",kind," ",id," t=",clock))
            sim.event.connect(func(key):print(LOG,"EVENT ",key," t=",clock))
            for a in options_.get("steps",[]):
                var entry: Array=a
                timeline.append([float(entry[0]),func():_act(entry.slice(1))])
            timeline.sort_custom(func(x,y):return float(x[0])<float(y[0]))
        return done
    game=game_root;sim=game.sim;job=capture;scenario=scenario_id;options=options_
    fps=float(capture.get("fps",30))
    _settings().set_music_volume(0.0)
    # Change 73: the capture profile's saved inventory view, slot size and shop quantity (Change 71
    # preferences) start from their defaults in every take, unless the take stages one.
    _settings().set_supply_buy_amount(1)
    _settings().set_inventory_zoom(int(options.get("inventory_zoom",2)))
    game._set_inventory_view(0,0);game._layout_inventory()
    var ok:=_soc()
    if ok:sim.milestone.connect(func(kind,id):print(LOG,"MILESTONE ",kind," ",id," t=",clock))
    if ok and bool(options.get("clean",false)):_clean_view()
    if ok and str(options.get("hud",""))=="match":_match_hud()
    if ok and options.has("cam"):_camera_track()
    print(LOG,"prepared soc ok=",ok," size=",capture.get("width"),"x",capture.get("height"))
    return ok

var soc_boss: Dictionary={}

## options.seed_search > 1 with options.want_drops: the seeds seed .. seed+n-1 are played in turn (the same
## staged fight, then the simulation's own 60 Hz steps to the defeat) and the first whose real kill drops
## every wanted item is kept and staged again for the take. Found, never forced (a take whose kill does not
## drop them logs COLLECT MISSING and is refused at review).
func _soc() -> bool:
    var n:=int(options.get("seed_search",0))
    if n>1:
        var first:=int(options.get("seed",6901))
        var found:=-1
        for s in range(first,first+n):
            options["seed"]=s
            if not _soc_build():continue
            var t:=0.0
            while t<40.0 and float(soc_boss.hp)>0 and sim.state.player.hp>0:
                sim.step(1.0/60.0);t+=1.0/60.0
            var drops: Array=sim.state.pickups.filter(func(d):return int(d.group)==int(soc_boss.group)).map(func(d):return str(d.item))
            var ok:=float(soc_boss.hp)<=0
            for id in options.get("want_drops",[]):
                if not drops.has(str(id)):ok=false
            # want_exact: nothing else dropped either, so the two items lie alone on the ground.
            if bool(options.get("want_exact",false)) and drops.size()!=options.get("want_drops",[]).size():ok=false
            print(LOG,"SEARCH seed ",s," defeated=",float(soc_boss.hp)<=0," drops=",drops," ok=",ok)
            if ok:
                found=s;break
        if found<0:return false
        options["seed"]=found
    return _soc_build() and _soc_finish()

func _ints(list: Array) -> Array:
    return list.map(func(x):return int(x))

func _soc_build() -> bool:
    var o:=options
    soc_boss={}
    var seed_value:=int(o.get("seed",6901))
    if str(o.get("base","stage"))=="late":
        if not _late_profile(seed_value):return false
        # The store profile predates the ^20 cap of evolvable weapons (Change 51): keep to what merges now.
        for id in sim.state.items:
            if sim.catalog.items[id].kind=="weapon":sim.record(id).merge=mini(int(sim.record(id).merge),sim.merge_cap(id))
    elif not _stage_profile(int(o.get("stage",1)),int(o.get("level",1)),o.get("items",[]),o.get("wear",[]),seed_value):return false
    # Upgrades a player at this point owns (levels within each upgrade's cap).
    var ups: Dictionary=o.get("upgrades",{})
    for key in ups:sim.state.upgrades[key]=int(ups[key])
    # Spare copies picked up from earlier kills (merge level untouched).
    if o.has("supply_capacity"):
        sim.state.upgrades["supply_slots"]=int(o.supply_capacity)-1
        sim.state.supplies.resize(int(o.supply_capacity));sim.state.supplies.fill("")
    for pair in o.get("extra",[]):
        if not sim.add_item(str(pair[0]),int(pair[1]),true,false):
            push_error(LOG+"cannot add "+str(pair[0]));return false
    if o.has("camps"):
        sim.state.camps[str(sim.state.stage)]=_ints(o.camps);sim.state.camps_known[str(sim.state.stage)]=_ints(o.camps)
    if o.has("camps_by_stage"):
        for key in o.camps_by_stage:
            sim.state.camps[str(key)]=_ints(o.camps_by_stage[key]);sim.state.camps_known[str(key)]=_ints(o.camps_by_stage[key])
    for boss_id in o.get("challenges",[]):sim.campaign.progress("restricted",str(boss_id),1)
    for i in range(2):sim.campaign.evaluate()
    # Change 73: objectives followed through the game's own toggles (the panels' Follow buttons call these).
    for f in o.get("follow",[]):_follow(f)
    if o.has("hp"):sim.state.player.hp=sim.stats().hp*float(o.hp)
    else:sim.state.player.hp=sim.stats().hp
    # Placement.
    if o.has("boss"):
        soc_boss=_actor_of(str(o.boss))
        if soc_boss.is_empty():
            push_error(LOG+"no boss "+str(o.boss));return false
        if bool(o.get("pack",false)):
            var top:=soc_boss
            for e in sim.state.enemies:
                if int(e.group)==int(top.group) and not sim.is_helper(e) and sim.position_of(e).distance_to(sim.position_of(top))<=140.0 and sim.position_of(e).y>sim.position_of(soc_boss).y:soc_boss=e
        if bool(o.get("farm",true)):_farm_upgrades([int(soc_boss.group)],bool(o.get("auto_collect",false)))
        sim.campaign.reveal_circle(Vector2(soc_boss.home_x,soc_boss.home_y),float(o.get("explored",360.0)))
        for e in sim.state.enemies:
            if int(e.group)==int(soc_boss.group):sim.campaign.discover_spot(int(e.group),int(e.get("variant",2)))
        _place_player(sim.position_of(soc_boss)+Vector2(float(o.get("dx",0)),float(o.get("dy",30))))
        if bool(o.get("aggro",true)):soc_boss.aggro=true
        if o.has("summon_in"):soc_boss.summon_cd=float(o.summon_in)
    elif o.has("near"):
        var spot:=_spot_of(str(o.near))
        if bool(o.get("farm",true)):
            var normals: Array=sim.campaign.stage().groups.filter(func(x):return not sim.catalog.groups[x].boss)
            _farm_upgrades(normals,bool(o.get("auto_collect",false)))
        for e in sim.state.enemies:
            if spot.distance_to(Vector2(e.home_x,e.home_y))<=260.0:sim.campaign.discover_spot(int(e.group),int(e.get("variant",2)))
        sim.campaign.reveal_circle(spot,float(o.get("explored",420.0)))
        _place_player(spot+Vector2(float(o.get("dx",0)),float(o.get("dy",24))))
    elif o.has("pos"):
        sim.campaign.reveal_circle(Vector2(o.pos[0],o.pos[1]),float(o.get("explored",300.0)))
        _place_player(Vector2(o.pos[0],o.pos[1]))
    if not ups.is_empty() or o.has("hp"):
        if not o.has("hp"):sim.state.player.hp=sim.stats().hp
    var skill_at: Dictionary=o.get("skill_at",{})
    for key in skill_at:sim.state.skill_cooldowns[key]=float(skill_at[key])
    # The real fight fast-forwarded to shortly before the moment the clip shows.
    if o.has("fight_until") and not soc_boss.is_empty():
        var max_hp: float=float(sim.enemy_definition(int(soc_boss.group)).hp)
        var t:=0.0
        while t<float(o.get("fight_limit",300.0)) and float(soc_boss.hp)>max_hp*float(o.fight_until) and sim.state.player.hp>0:
            sim.step(.05);t+=.05
        print(LOG,"prefight ",t,"s boss=",float(soc_boss.hp)/max_hp," player=",sim.state.player.hp/sim.stats().hp)
        if (sim.state.player.hp<=0 or float(soc_boss.hp)<=0) and float(o.fight_until)>0:return false
    if o.has("player_hp_until"):
        var t2:=0.0
        while t2<300.0 and sim.state.player.hp>sim.stats().hp*float(o.player_hp_until):
            sim.step(.05);t2+=.05
        print(LOG,"prefight to player hp ",sim.state.player.hp/sim.stats().hp," after ",t2,"s")
    # Staging: the boss used its skills shortly before (their real cooldowns still running), so none lands
    # on the moment the clip shows.
    if o.has("boss_skill_in") and not soc_boss.is_empty():
        var def: Dictionary=sim.enemy_definition(int(soc_boss.group))
        if not soc_boss.has("skill_cds"):soc_boss.skill_cds={}
        for key in def.get("skills",[]):soc_boss.skill_cds[key]=float(o.boss_skill_in)
        print(LOG,"boss skills ",def.get("skills",[])," held for ",o.boss_skill_in," s")
    _advance(float(o.get("advance",0.0)))
    if o.has("farm_drops"):_farm_until_drops(int(o.farm_drops),float(o.get("farm_limit",120.0)))
    if bool(o.get("full_hp",false)):sim.state.player.hp=sim.stats().hp
    return true

func _soc_finish() -> bool:
    var o:=options
    # Event log (review evidence and cut points).
    sim.summon_warning.connect(func(id):print(LOG,"SUMMON_WARNING ",id," t=",clock))
    sim.summoned.connect(func(id,ids):print(LOG,"SUMMON ",id," helpers=",ids.size()," t=",clock))
    sim.spell_cast.connect(func(id,key,_p):if id=="player":print(LOG,"PLAYER_SKILL ",key," t=",clock))
    if not options.has("cam"):
        sim.feedback.connect(func(id,amount,healing):
            if healing:return
            var a: Dictionary=sim._find_actor(id)
            print(LOG,"HIT ",id," ",snappedf(amount,1.0)," crit=",bool(a.get("critical_hit",false))," t=",clock))
    sim.merged.connect(func(id,before,after):print(LOG,"MERGED ",id," ^",before," -> ^",after," t=",clock))
    sim.evolved.connect(func(source,target):print(LOG,"EVOLVED ",source," -> ",target," t=",clock))
    sim.collected.connect(func(uid):print(LOG,"COLLECTED ",uid," t=",clock))
    sim.supply_used.connect(func(id):print(LOG,"SUPPLY ",id," t=",clock))
    sim.traveled.connect(func(map_changed,_a,_b):print(LOG,"TRAVELED map_changed=",map_changed," stage=",sim.state.stage," t=",clock))
    sim.boss_defeated.connect(func(id,_g,_at):print(LOG,"BOSS_DEFEATED ",id," t=",clock))
    sim.revived.connect(func():print(LOG,"REVIVED t=",clock))
    sim.event.connect(func(key):print(LOG,"EVENT ",key," t=",clock))
    if not soc_boss.is_empty() and bool(o.get("watch",true)):_watch(soc_boss)
    for a in o.get("after_defeat",[]):
        var entry: Array=a
        after_defeat.append([float(entry[0]),func():_act(entry.slice(1))])
    for a in o.get("steps",[]):
        var entry: Array=a
        timeline.append([float(entry[0]),func():_act(entry.slice(1))])
    timeline.sort_custom(func(x,y):return float(x[0])<float(y[0]))
    _hud_clean()
    var s: Dictionary=sim.stats()
    print(LOG,"soc stage=",sim.state.stage," level=",sim.state.player_level," weapon=",sim.state.weapon," outfit=",sim.state.outfit," dmg=",s.damage," hp=",s.hp," crit=",s.crit," x",s.crit_damage)
    return true

func _button_by_text(text: String) -> Button:
    for b in game.pinned_rows.find_children("*","Button",true,false)+game.actions.find_children("*","Button",true,false)+game.rows.find_children("*","Button",true,false):
        if str(b.text)==text and b.is_visible_in_tree():return b
    return null

func _press(b: Button,what: String) -> void:
    if b==null or b.disabled:
        print(LOG,"PRESS MISSING ",what," t=",clock);return
    b.pressed.emit()
    print(LOG,"PRESS ",what," t=",clock)

func _teleport_map() -> Node:
    for n in game.rows.find_children("*","",true,false):
        if n.has_meta("teleport_map"):return n
    return null

func _act(a: Array) -> void:
    var what:=str(a[0])
    match what:
        "equip":_equip_direct(str(a[1]))
        "collect":
            if str(a[1])=="next":_collect_next()
            else:_collect_item(str(a[1]))
        "collect_all":
            for d in _pickups_near(float(a[1]) if a.size()>1 else 150.0):print(LOG,"COLLECT ",d.item," ok=",sim.collect(int(d.uid))," t=",clock)
        "tap_gear":_tap_gear(str(a[1]))
        "open":
            game._open(str(a[1]));print(LOG,"OPEN panel ",a[1]," t=",clock)
        "item":
            game.selected=str(a[1]);game._open("item");print(LOG,"OPEN item ",a[1]," t=",clock)
        "close":_close_panel()
        "evo_continue":
            # The evolution panel's Continue button.
            game.evolution_show.close();print(LOG,"EVOLUTION closed t=",clock," open=",game.evolution_show.is_open())
        "equip_btn":_press_pinned("EQUIP",str(a[1]))
        "guide":_press(game._guide_button(str(a[1])) as Button,"guide:"+str(a[1]))
        "merge":
            # The item panel's pinned Merge button (one copy).
            var before:=int(sim.record(str(a[1])).merge)
            _press(_button_by_text(tr("ITEM_MERGE_ACTION")),"merge "+str(a[1]))
            print(LOG,"MERGE ",a[1]," ^",before," -> ^",int(sim.record(str(a[1])).merge)," dmg=",sim.stats().damage," hp=",sim.stats().hp)
        "merge_copies":
            var id:=str(a[1])
            var b0:=int(sim.record(id).merge)
            var label:=tr("MERGE_ALL") % mini(sim.quantity(id)-1,sim.merge_cap(id)-b0)
            _press(_button_by_text(label),"merge copies '"+label+"'")
            print(LOG,"MERGE_COPIES ",id," ^",b0," -> ^",int(sim.record(id).merge)," dmg=",sim.stats().damage," hp=",sim.stats().hp)
        "evolve":
            var id2:=str(a[1])
            var label2:=tr("EVOLVE") % sim.catalog.display_name(str(sim.catalog.items[id2].next))
            _press(_button_by_text(label2),"evolve '"+label2+"'")
            print(LOG,"EVOLVE weapon=",sim.state.weapon," show=",game.evolution_show.is_open())
        "supply":print(LOG,"USE ",a[1]," ok=",sim.use_item(str(a[1]))," t=",clock)
        "zoom":_push_in(float(a[1]),float(a[2]))
        "teleport_open":
            game.teleport_target=[];game.teleport_stage=0;game._open("teleport");print(LOG,"TELEPORT open t=",clock)
        "teleport_stage":_press(game._guide_button("teleport_stage_%d" % int(a[1])) as Button,"teleport stage "+str(a[1]))
        "teleport_pick":
            var m:=_teleport_map()
            if m==null:print(LOG,"TELEPORT map missing")
            else:
                m.chosen.emit(int(a[1]));print(LOG,"TELEPORT pick camp ",a[1]," target=",game.teleport_target," t=",clock)
        "teleport_go":
            for b in game.pinned_rows.find_children("*","Button",true,false)+game.actions.find_children("*","Button",true,false):
                if b.get_meta("guide","")=="teleport_go":
                    _press(b,"teleport_go");return
            print(LOG,"TELEPORT go missing")
        "travel":print(LOG,"TRAVEL ",a[1],"/",a[2]," ok=",game._travel_to(int(a[1]),int(a[2]))," t=",clock)
        "focus":
            var g:=_group(str(a[1]))
            print(LOG,"FOCUS ",a[1]," ok=",sim.focus(g,int(a[2]) if a.size()>2 else 2)," t=",clock)
        "quick":
            # The map's Auto Farm button (Change 69); it calls sim.focus for the fought group's spot.
            var q: Button=game.get_node("Safe/Layout/Map/QuickFarm")
            print(LOG,"QUICK visible=",q.visible," text=",q.text," t=",clock)
            if q.visible:
                game.quick_changed_msec=0;q.pressed.emit()
                print(LOG,"QUICK pressed focus=",sim.state.focus," text=",q.text)
        "offline":
            # The game's own settlement for an absence of a[1] hours (the snapshot's clock moved back).
            sim.state.offline_snapshot=sim.campaign.offline_snapshot()
            var now: float=float(sim.state.offline_snapshot.time)+float(a[1])*3600.0
            sim.campaign.settle_offline(now)
            print(LOG,"OFFLINE settled hours=",a[1]," pending=",sim.state.offline_pending)
            game._offer_offline_claim()
        "claim_offline":
            for b in game.pinned_rows.find_children("*","Button",true,false)+game.actions.find_children("*","Button",true,false):
                if b.get_meta("guide","")=="claim_offline":
                    var coins: float=sim.state.coins
                    _press(b,"claim_offline");print(LOG,"CLAIMED coins ",coins," -> ",sim.state.coins);return
            print(LOG,"CLAIM missing")
        "aggro":
            var e:=_actor_of(str(a[1]))
            if not e.is_empty():e.aggro=true
        "place":
            _place_player(sim.position_of(sim.state.player)+Vector2(float(a[1]),float(a[2])))
        "hud_off":
            if hidden_ui.is_empty():_clean_view()
        "log":print(LOG,"NOTE ",a[1]," t=",clock," coins=",sim.state.coins," hp=",sim.state.player.hp/sim.stats().hp)
        # Change 73 steps.
        "tap":_press(_guide_any(str(a[1])),"tap "+str(a[1]))
        "tab":_press_tab(int(a[1]),int(a[2]))
        "tab_key":
            # A panel tab by its translation key (Filters' order row: SORT_TIER, SORT_QUANTITY, ...).
            var hit: Button=null
            for b in game.rows.find_children("*","Button",true,false):
                if str(b.text)==tr(str(a[1])) and b.is_visible_in_tree():hit=b
            _press(hit,"tab "+str(a[1]))
        "upgrades_tab":
            game.player_tab=int(a[1]);game._open("upgrades");print(LOG,"OPEN upgrades tab ",a[1]," t=",clock)
        "scroll":
            var sc: ScrollContainer=game.get_node("Sheet/Margin/Content/Scroll")
            sc.scroll_vertical=int(a[1]);print(LOG,"SCROLL ",a[1]," t=",clock)
        "pick_card":
            var offered: Array=sim.campaign.offered_cards()
            if int(a[1])<offered.size():
                game.selected_card=offered[int(a[1])];game._refresh_panel(true)
                print(LOG,"PRESTIGE card selected ",offered[int(a[1])]," of ",offered.size()," batch=",sim.state.prestige_batch.get("choices",[]).size(),"/",sim.state.prestige_batch.get("ids",[]).size()," t=",clock)
            else:print(LOG,"PICK_CARD missing ",a[1])
        "follow":_follow(a.slice(1))
        "confirm":_press(game.get_node("Confirm/Panel/Margin/Content/Actions/Confirm") as Button,"confirm dialog")
        "scroll_to":
            # Scrolls the open panel so the tagged control sits a[2] px below the scroll area's top.
            var target:=_guide_any(str(a[1]))
            var sc2: ScrollContainer=game.get_node("Sheet/Margin/Content/Scroll")
            if target==null:print(LOG,"SCROLL_TO missing ",a[1]);return
            sc2.scroll_vertical=int(sc2.scroll_vertical+target.global_position.y-sc2.global_position.y-float(a[2]))
            print(LOG,"SCROLL_TO ",a[1]," -> ",sc2.scroll_vertical," t=",clock)
        _:print(LOG,"UNKNOWN step ",what)

# ---------------------------------------------------------------- Change 73 (social refresh) helpers

## A button by its guide tag in the open panel, its pinned row or its actions (what a tap reaches).
func _guide_any(key: String) -> Button:
    for b in game.rows.find_children("*","Button",true,false)+game.actions.find_children("*","Button",true,false)+game.pinned_rows.find_children("*","Button",true,false):
        if str(b.get_meta("guide",""))==key and b.is_visible_in_tree():return b
    return null

## The i-th button of the bar-th tab row in the open panel (Filters: 0 = category, 1 = order).
func _press_tab(bar: int,i: int) -> void:
    var bars: Array=game.rows.find_children("*","HBoxContainer",true,false).filter(func(n):return str(n.name).begins_with("Tabs"))
    if bar>=bars.size():
        print(LOG,"TAB missing bar ",bar," t=",clock);return
    var buttons: Array=bars[bar].get_children().filter(func(n):return n is Button)
    if i>=buttons.size():
        print(LOG,"TAB missing ",bar,"/",i," t=",clock);return
    _press(buttons[i],"tab %d/%d '%s'" % [bar,i,buttons[i].text])

## ["mastery", stage, category] | ["mission"] (the first open daily mission) | ["opportunity"] (the first
## followable Prestige opportunity): the same toggles the Follow buttons call.
func _follow(f: Array) -> void:
    match str(f[0]):
        "mastery":print(LOG,"FOLLOW mastery ",f[1],":",f[2]," ok=",sim.campaign.mastery.toggle_follow(int(f[1]),str(f[2]))," t=",clock)
        "mission":
            for i in range(sim.state.missions.size()):
                if sim.campaign.can_follow_mission("daily",i):
                    print(LOG,"FOLLOW mission ",i," ",sim.state.missions[i].get("kind","")," ok=",sim.campaign.toggle_follow_mission("daily",i)," t=",clock);return
            print(LOG,"FOLLOW mission none")
        "opportunity":
            for id in sim.state.opportunities:
                if sim.campaign.can_follow(id):
                    print(LOG,"FOLLOW opportunity ",id," ok=",sim.campaign.toggle_follow(id)," t=",clock);return
            print(LOG,"FOLLOW opportunity none")
