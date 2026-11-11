extends Node
## Change 6 behaviour probe. Real main scene and simulation; state set directly is labelled.
var checks:=0
var failures:=0
var sim
var game
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
func _ready() -> void:call_deferred("run")
func fresh() -> void:
    sim.new_profile();sim.state.tutorial.mode="none";sim.suspended=false;SaveService.write_blocked=false;sim.rng.seed=66123;game._close()
func frames(n:=6) -> void:
    for i in range(n):await get_tree().process_frame
func run() -> void:
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim;sim.set_physics_process(false);fresh()
    layout_checks()
    prestige_checks()
    card_checks()
    rest_checks()
    await save_checks()
    await ui_checks()
    await tutorial_checks()
    print("CHANGE_6_CHECKS ",checks," FAILURES ",failures)
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    await get_tree().create_timer(.1).timeout
    get_tree().quit(1 if failures else 0)

## No farming spot can be auto-acquired from another, camps are outside acquisition, bosses are
## the farthest encounters from arrival on every stage.
func layout_checks() -> void:
    var acquire: float=sim.catalog.world.acquisition+sim.catalog.world.reach
    for stage in sim.catalog.stages:
        var actors: Array=[]
        for g in stage.groups:
            for v in sim.campaign.variants(g):
                for i in range(1 if sim.catalog.groups[g].boss else 6):actors.append([g,v,sim.spawn_home(g,v,i)])
        var worst:=INF
        for a in actors:
            for b in actors:
                if a[0]!=b[0] or a[1]!=b[1]:worst=minf(worst,a[2].distance_to(b[2]))
        check(worst>acquire,"Stage %d: farming spots outside each other's acquisition (%.0f > %.0f)" % [stage.id,worst,acquire])
        var arrival:=Vector2(stage.spawns[0][0],stage.spawns[0][1])
        var far_normal:=0.0;var near_boss:=INF
        for g in stage.groups:
            var d: float=arrival.distance_to(Vector2(sim.catalog.groups[g].center[0],sim.catalog.groups[g].center[1]))
            if sim.catalog.groups[g].boss:near_boss=minf(near_boss,d)
            else:far_normal=maxf(far_normal,d)
        check(near_boss>far_normal,"Stage %d: every boss is farther from arrival than every normal type" % stage.id)
        for camp in stage.spawns:
            var nearest:=INF
            for a in actors:nearest=minf(nearest,Vector2(camp[0],camp[1]).distance_to(a[2]))
            check(nearest>sim.catalog.world.acquisition,"Stage %d: camp outside acquisition of every spot" % stage.id)
    # Farming one variant through deaths and respawns never walks to a neighbour.
    fresh()
    var home: Vector2=sim.campaign.spot(0,2)
    sim.state.player.x=home.x;sim.state.player.y=home.y;sim.campaign.reveal()
    var groups_hit: Dictionary={}
    for i in range(1800):
        sim.step(.1)
        var t: Dictionary=sim._find_actor(sim.locked_target)
        if not t.is_empty():groups_hit["%d:%d" % [int(t.group),int(t.get("variant",2))]]=true
    check(groups_hit.keys()==["0:2"],"Idle farming stays on its spot through kills and respawns: %s" % [groups_hit.keys()])
    check(sim.position_of(sim.state.player).distance_to(home)<120 or sim.state.player.hp<=0 or sim.campaign.resting_camp()>=0,"Player remains at its farming spot")

## Change 8 replaced the Winter II gate: Prestige opens with the first boss defeated, then any ready
## opportunity that can award a card may reset (early routes included).
func prestige_checks() -> void:
    for route in ["challenge_o1","specialist_o1","offline_o2","trophy_o1"]:
        fresh()
        sim.state.opportunities[route]={"ready":true,"baseline":{},"step":0,"count":0}   # fixture: readiness
        check(sim.campaign.prestige_block_reason()=="PRESTIGE_LOCKED_BOSS_DEFEAT","Early %s waits for the first boss" % route)
        check(not sim.campaign.begin_prestige() and sim.state.prestige_batch.is_empty(),"Begin refused before the first boss: "+route)
        sim.state.group_kills[sim.campaign.prestige_unlock_group()]=1   # fixture: Snowman defeated
        check(sim.campaign.prestige_block_reason()=="","Early %s may reset after the first boss" % route)
    fresh()
    sim.state.group_kills[sim.campaign.prestige_unlock_group()]=1;sim.state.opportunities["specialist_o1"]={"ready":true,"baseline":{},"step":0,"count":0}
    check(sim.campaign.prestige_block_reason()=="","A ready opportunity may prestige")
    check(sim.campaign.begin_prestige() and sim.campaign.offered_cards().size()==3,"Batch offers three path cards")
    sim.state.prestige_batch={};sim.touch()
    fresh();sim.campaign.progress("boss","boss-snowman",1);sim.state.counters["boss:boss-snowman"]=1;sim.campaign.evaluate()
    check(sim.state.opportunities.has("hunter_o1") and not sim.state.opportunities.has("challenge_o1"),"Snowman discovers the bounty; the unassisted challenge moved to the Cyan Robot")
    check(sim.campaign.hunter_goal(1)==1,"First bounty asks one Snowman defeat (Change 61; it was 10)")

## Card values are substantial, effects distinct inside a path, and the new effects apply.
func card_checks() -> void:
    var cards: Dictionary=sim.catalog.campaign.cards
    check(cards.size()==48 and sim.catalog.campaign.combos.size()==17,"48 cards (Change 54) and 17 combos")
    var effects: Dictionary={}
    for id in cards:
        var d: Dictionary=cards[id]
        effects[d.path+":"+d.effect]=int(effects.get(d.path+":"+d.effect,0))+1
        var floor_value: float=.03 if d.effect in ["crit","gear_chance","gem_chance"] else (.05 if d.effect=="lifesteal" or d.effect=="supply_chance" else .1)
        # Change 54: Crowd Guard is per attacker (-4% each beyond the first, up to -20%).
        if d.effect=="crowd_guard":floor_value=.03
        check(float(d.value)>=floor_value,"Card %s is substantial (%s %s)" % [id,d.effect,d.value])
        check(sim.catalog.campaign.paths.has(d.path),"Card %s has path art" % id)
    for key in effects:check(effects[key]==1,"Distinct effect within path "+key)
    check(cards.hunter_c2.effect!=cards.challenge_c2.effect,"Boss Guard and Resolve no longer duplicate")
    fresh();var base_steal: float=sim.stats().lifesteal;var base_price: int=sim.campaign.camp_price(1)
    sim.state.owned_cards=["challenge_c2","regional_c3"];sim.touch()
    check(is_equal_approx(sim.stats().lifesteal,base_steal+.05),"Resolve grants life steal")
    check(sim.campaign.camp_price(1)==ceili(base_price*.5),"Camp Survey halves camp prices")
    var headline: String=load("res://scripts/game/prestige_card.gd").headline(cards.challenge_c1)
    check(headline=="+15 pts","Point-based cards show points, not percent: "+headline)

func rest_checks() -> void:
    fresh()
    var camp: Array=sim.campaign.stage().spawns[0]
    sim.state.player.x=camp[0];sim.state.player.y=camp[1];sim.state.player.quiet=10
    check(is_equal_approx(sim.campaign.rest_rate(),float(sim.catalog.progression.rest.camp)),"Resting beside an owned camp heals fast")
    sim.state.player.x=camp[0]+400;sim.state.player.y=camp[1]-400
    check(is_equal_approx(sim.campaign.rest_rate(),float(sim.catalog.progression.rest.field)),"Away from camps recovery is slow")
    sim.state.player.quiet=0
    check(sim.campaign.rest_rate()==0,"No recovery while in combat")
    sim.state.player.quiet=10;sim.state.player.hp=10;var before: float=sim.state.player.hp
    sim.state.player.x=camp[0];sim.state.player.y=camp[1];sim.step(.1);sim.step(.1)
    check(sim.state.player.hp>before,"Out-of-combat recovery applies in the real step")
    check(sim.supply_cooldown("potion")>=4.0,"Potions cannot be chained every two seconds")

func save_checks() -> void:
    fresh()
    sim.add_item("wood_sword",3);sim.equip("wood_sword");sim.campaign.reveal_segment(sim.position_of(sim.state.player),Vector2(300,500))
    var expected=sim.snapshot()
    check(int(expected.fog_layout_revision)==int(sim.campaign.fog_rules.layout_revision),"New profiles carry the current fog layout revision")
    check(SaveService.save_now(),"Current profile writes")
    sim.state.items={};SaveService.load_and_apply()
    check(sim.quantity("wood_sword")==3 and sim.snapshot().explored==expected.explored and not SaveService.write_blocked,"Current save reloads with items and exploration")
    # A current-schema save written before the layout moved: actors re-home, discovery resets once.
    var old=sim.snapshot();old.fog_layout_revision=1
    for a in old.enemies:a.home_x+=300;a.x=a.home_x
    sim.restore(old)
    var homed:=true
    for a in sim.state.enemies:
        var bits: PackedStringArray=str(a.id).trim_prefix("g").split("_")
        if Vector2(a.home_x,a.home_y).distance_to(sim.spawn_home(int(a.group),int(a.get("variant",2)),int(bits[2])))>1:homed=false
    check(homed,"Saved enemies re-home to the current layout")
    check(sim.state.fog_layout_revision==sim.campaign.fog_rules.layout_revision and SaveService.save_now() and not SaveService.write_blocked,"Layout-revision save stays writable without Hard Reset")
    await frames(2)

func ui_checks() -> void:
    fresh()
    for id in ["wood_sword","unit-blue-cap_outfit","wood_axe"]:sim.add_item(id,2)
    sim.add_item("potion",2)
    var map: Control=game.get_node("Safe/Layout/Map")
    game.selected="wood_sword";game.selected_slot=-1;game._open("item");await frames(8)
    # Comparison plus the per-item toggle may reach the available height; overflow scrolls above pinned actions.
    var natural_height: float=game.sheet.get_combined_minimum_size().y+game.rows.get_combined_minimum_size().y+4
    var expected_height:=clampf(natural_height,minf(200,map.size.y-game.sheet_inset.y*2),map.size.y-game.sheet_inset.y*2)
    check(absf(game.sheet.size.y-expected_height)<2,"Item details size to content, bounded by the map")
    check(is_equal_approx(game.sheet.position.y+game.sheet.size.y,map.global_position.y+map.size.y-game.sheet_inset.y),"Sheet is anchored to the bottom of the map")
    var bar_rect: Rect2=game.actions.get_global_rect()
    var prev: Button=game.actions.get_child(0);var next: Button=game.actions.get_child(game.actions.get_child_count()-1)
    check(prev.disabled and not next.disabled,"First item: previous disabled, next enabled")
    next.pressed.emit();await frames(8)
    check(game.selected=="unit-blue-cap_outfit","Next follows the inventory display order")
    check(game.actions.get_global_rect().position.y==bar_rect.position.y,"Pinned actions keep their position while browsing")
    game._browse(1);await frames(8)
    check(game.selected=="wood_axe" and game.actions.get_child(game.actions.get_child_count()-1).disabled,"Last item: next disabled")
    game._browse(1);await frames(2)
    check(game.selected=="wood_axe","Boundary does not wrap")
    # Stale callbacks: an action captured for one item never acts on another.
    var equip_for_scarf: Button=game.actions.get_child(1)
    game._browse(-1);await frames(4)
    var weapon_before: String=sim.state.weapon
    if is_instance_valid(equip_for_scarf) and not equip_for_scarf.is_queued_for_deletion():
        equip_for_scarf.pressed.emit()
        check(sim.state.weapon==weapon_before,"A reused button acts only on the item now shown")
    else:
        check(true,"Browsing replaces the action bar; the old item's button no longer exists")
    var now_equip: Button=game.actions.get_child(1)
    now_equip.pressed.emit();await frames(2)
    check(sim.state.weapon==game.selected or sim.catalog.items[game.selected].kind!="weapon","Equip acts on the item currently shown")
    # Item consumed while open moves to a neighbour instead of a dead panel.
    game.selected="potion";game.selected_slot=0;game._open("item");await frames(4)
    sim.state.player.hp=1;sim.state.use_cd=0;sim.use_item("potion");sim.state.use_cd=0;sim.use_item("potion");game._refresh_panel(true);await frames(4)
    check(sim.quantity("potion")==0 and game.rows.get_child_count()>0,"Panel survives the item running out")
    # Values refresh in place: same button nodes after a currency change.
    game._open("upgrades");await frames(6)
    var first: Button=game.action_buttons[0].node
    sim.state.coins+=1000;sim.state.gems+=1000;sim.touch();game._refresh_panel();await frames(2)
    check(is_instance_valid(first) and game.action_buttons[0].node==first and not first.disabled,"Upgrade buttons keep identity while values change (valid=%s same=%s disabled=%s reason=%s)" % [is_instance_valid(first),game.action_buttons[0].node==first,first.disabled if is_instance_valid(first) else "-",sim.upgrade_block_reason(game.action_buttons[0].id,-1)])
    var height: float=game.sheet.size.y
    sim.state.coins=0;sim.state.gems=0;sim.touch();game._refresh_panel();await frames(4)
    check(is_equal_approx(game.sheet.size.y,height),"A disabled reason does not resize the panel")
    # Toast never sits on an open panel; it appears once the panel closes.
    game._event("SAVED");await frames(3)
    check(not game.get_node("Toast").visible and game.notice.text!="","Feedback uses the panel notice line while open")
    game._close();game._toast("Probe toast");await frames(3)
    check(game.get_node("Toast").visible,"Toast shows on the HUD")
    # Prestige choices are real cards and the selection is explicit.
    fresh();sim.state.unlocked_stage=3;sim.state.group_kills[sim.campaign.prestige_unlock_group()]=1;sim.state.opportunities["arsenal_o1"]={"ready":true,"baseline":{},"step":0,"count":0}
    sim.campaign.begin_prestige();game._open("prestige");await frames(8)
    var cards: Array=game.rows.find_children("*","Button",true,false).filter(func(b):return b.get_meta("guide","")=="card")
    check(cards.size()==3 and cards.all(func(c):return c.get_script()==load("res://scripts/game/prestige_card.gd")),"Batch renders three prestige card scenes")
    var keep: Button=game.actions.get_child(game.actions.get_child_count()-1)
    check(keep.disabled,"Keep is disabled until a card is selected")
    cards[0].pressed.emit();await frames(6)
    keep=game.actions.get_child(game.actions.get_child_count()-1)
    check(not keep.disabled and game.selected_card!="","Selecting a card enables Keep")
    sim.state.prestige_batch={};sim.touch();game._close()
    # Repeated open/close does not grow the tree.
    # Change 24: the last closed panel's controls are retained (bounded: one panel), so the baseline is
    # taken after one warm-up round; further rounds must not grow the tree.
    await frames(4)
    for i in range(6):
        game._open(["upgrades","world","missions","prestige","settings","stats"][i%6]);await frames(1);game._close();await frames(1)
    await frames(6)
    var before:=count(game)
    for i in range(24):
        game._open(["upgrades","world","missions","prestige","settings","stats"][i%6]);await frames(1);game._close();await frames(1)
    await frames(6)
    check(count(game)<=before,"Open/close cycles do not grow the tree (%d -> %d)" % [before,count(game)])

## UI nodes only: the world viewport's combat text and effects come and go with simulated time
## (Change 15 hardening: a damage number expiring during the cycles made this check flaky).
func count(node: Node) -> int:
    var n:=1
    for c in node.get_children():
        if c is SubViewportContainer:continue
        n+=count(c)
    return n

## Physical camp route: approach, discover, open the visible camp control and buy manually.
func tutorial_checks() -> void:
    fresh();sim.state.tutorial.mode="guided";sim.campaign.guided.data().done=sim.campaign.guided.STEPS.slice(0,sim.campaign.guided.STEPS.find("potion_use")+1) # Change 61: camp follows the potion lessons
    await frames(3)
    check(game.guide.pending=="camp" and game.guide.step=="camp_approach","Undiscovered camp asks for a physical approach")
    check(game.guide.path_point!=Vector2.INF,"Camp direction guides movement toward the first camp")
    var camp: Array=sim.campaign.stage().spawns[1]
    sim.state.camps_known["1"]=[1];sim.state.coins=0;await frames(3)
    check(game.guide.step=="camp_earn","Known but unaffordable camp asks for coins")
    sim.state.coins=sim.campaign.camp_price(1);sim.touch();await frames(3)
    check(game.guide.step=="camp_approach","Affordable camp still requires approaching it")
    sim.state.player.x=float(camp[0]);sim.state.player.y=float(camp[1]);game._settle_camp();await frames(3)
    check(game.guide.step=="camp_view" and game.guide.target!=null,"Approaching exposes the camp control")
    game.selected_camp=1;game._open("camp");await frames(8)
    check(game.guide.step=="camp_buy" and game.guide.target!=null and game.guide.target.get_meta("guide","")=="camp_buy_1","Camp panel points at Unlock")
    check(game.guide.pointer.visible,"Pointer shown inside the camp panel")
    game._open("stats");await frames(4)
    check(game.guide.suspended_by=="stats" and not game.guide.pointer.visible and not game.guide.card.visible,"Unrelated panel hides all guidance")
    game._open("camp");await frames(8)
    if game.guide.target!=null:game.guide.target.pressed.emit()
    await frames(4)
    check(sim.state.spawns.has(1) and int(sim.state.spawn)==0,"Unlock buys the camp without silently selecting it")
    check(sim.campaign.guided.data().done.has("camp"),"Camp lesson completes on the purchase")
    for node in game.guide.find_children("*","Control",true,false):
        if node!=game.guide.intro_button and node!=game.guide.skip_button and node.get_parent()!=game.guide.chooser and not game.guide.chooser.is_ancestor_of(node) and node!=game.guide.blocker and node!=game.guide.chooser:
            if node.mouse_filter!=Control.MOUSE_FILTER_IGNORE:check(false,"Guide node takes input: "+str(node.name))
    check(true,"Guide presentation ignores input")
    # Doing a lesson ahead of time completes it.
    fresh();sim.state.tutorial.mode="guided";sim.add_item("wood_sword",2);sim.equip("wood_sword");sim.merge("wood_sword");await frames(3)
    check(sim.state.tutorial.done.has("equip") and sim.state.tutorial.done.has("merge"),"Lessons done out of order are recognised")
