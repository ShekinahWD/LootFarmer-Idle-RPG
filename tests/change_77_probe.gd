extends Node
## Change 77 focused checks (real main scene and simulation; state set directly is labelled "fixture"):
## - The Regional card regional_c3 keeps its id and set membership; Camp Survey (camps 50% cheaper) became Camp
##   Supplies: the first visit to each owned camp in a Prestige run gives 1 random supply, free.
## - Existing owners (a released schema 8 save with the card) get the new effect; the discount is gone.
## - One reward per camp per run: revisits, teleports, respawns, save/reload never repeat it; different camps
##   reward independently; Prestige makes every kept camp eligible again; Hard Reset clears everything.
## - A full inventory never consumes the reward: it waits and is given once a slot is free.
## - Only a real visit counts: owned camp, alive, current reachable map, card owned.
## - UI: card name, headline and description; the reward notice uses the toast lane.
## Run: Godot --headless --path . res://tests/change_77_probe.tscn -- --probe --profile=probe-c77 --no-autosave --first-run-complete
var checks:=0
var failures:=0
var game
var sim
var granted: Array=[]
var waits:=0

func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
    else:print("  ok  ",label_)
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame
func _ready() -> void:call_deferred("run")

func run() -> void:
    SettingsState.mute_all_sfx()
    TranslationServer.set_locale("en")
    get_window().size=Vector2i(720,1280)
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.camp_supply_granted.connect(func(id: String)->void:granted.append(id))
    sim.camp_supply_waiting.connect(func()->void:waits+=1)
    await frames(6)
    card_checks()
    await existing_profile_checks()
    visit_checks()
    real_step_checks()
    full_inventory_checks()
    await persistence_checks()
    prestige_checks()
    await hard_reset_checks()
    normalize_checks()
    await ui_checks()
    print("CHANGE_77_CHECKS %d FAILURES %d" % [checks,failures])
    game.queue_free();await frames(2);AudioService.stop_all_sfx()
    get_tree().quit(1 if failures>0 else 0)

func fresh(card:=true) -> void:
    get_tree().paused=false
    sim.held=false
    sim.new_profile();sim.set_physics_process(false);sim.suspended=false;SaveService.write_blocked=false
    sim.state.tutorial.mode="none"
    sim.campaign.onboarding.reveal_all(true)
    sim.state.tutorial.seen.append("road_ahead")
    game._close();game.banner.queue.clear();game.banner._finish();game.toast_queue.clear();game.toast_important.clear();game.get_node("Toast").hide();game.toast_time=0.0
    if card:sim.state.owned_cards.append("regional_c3") # fixture: card owned
    granted.clear();waits=0

func at_camp(camp: int) -> void:
    var a: Array=sim.campaign.stage().spawns[camp]
    sim.state.player.x=a[0];sim.state.player.y=a[1] # fixture: standing at the camp

func away() -> void:
    sim.state.player.x=float(sim.campaign.stage().size[0])*.5;sim.state.player.y=40.0 # fixture: far from every camp

func supplies_total() -> int:
    var n:=0
    for id in sim.supply_ids():n+=sim.quantity(id)
    return n

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

# ---------------------------------------------------------------- card
func card_checks() -> void:
    print("-- The card")
    var d: Dictionary=sim.catalog.campaign.cards.get("regional_c3",{})
    var raw: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/game/catalog.json")).campaign.cards.get("regional_c3",{})
    check(str(raw.get("path",""))=="regional" and str(raw.get("name",""))=="CONTENT_REGIONAL_C3_NAME" and str(raw.get("description",""))=="CONTENT_REGIONAL_C3_DESCRIPTION","regional_c3 keeps its id, path and string keys")
    check(str(d.effect)=="camp_supplies" and int(d.value)==1,"Its effect is camp_supplies, 1 per camp")
    var effects: Array=[]
    for id in sim.catalog.campaign.cards:effects.append(str(sim.catalog.campaign.cards[id].effect))
    for c in sim.catalog.campaign.combos:effects.append(str(c.effect))
    check(not effects.has("camp_discount"),"No card or set grants camp_discount any more")
    check(tr("CONTENT_REGIONAL_C3_NAME")=="Camp Supplies","Name: Camp Supplies")
    check(not tr("CONTENT_REGIONAL_C3_DESCRIPTION").contains("50") and tr("CONTENT_REGIONAL_C3_DESCRIPTION").contains("supply"),"Description: %s" % tr("CONTENT_REGIONAL_C3_DESCRIPTION"))
    check(game.PRESTIGE_CARD_SCRIPT.headline(d)=="+1","Headline: %s" % game.PRESTIGE_CARD_SCRIPT.headline(d))
    var set_: Dictionary={}
    for c in sim.catalog.campaign.combos:
        if str(c.id)=="regional_set":set_=c
    check(set_.get("cards",[])==["regional_c1","regional_c2","regional_c3"] and str(set_.effect)=="reveal","The Regional set still needs regional_c3 and still gives its reveal bonus")

# ---------------------------------------------------------------- existing owners
func existing_profile_checks() -> void:
    print("-- Existing owners (released schema 8 save owning Camp Survey)")
    fresh(false)
    var file:=FileAccess.open("res://tests/fixtures/old_saves/schema8_late.json",FileAccess.READ)
    var data: Dictionary=JSON.parse_string(file.get_as_text()).sections.lootfarmer
    check(data.owned_cards.has("regional_c3") and not data.has("camp_supplies"),"fixture: the old save owns regional_c3 and has no camp_supplies field")
    sim.restore(data);await frames(2)
    check(sim.state.owned_cards.has("regional_c3") and sim.state.camp_supplies=={},"Loaded: card still owned, no camp rewarded yet")
    check(is_equal_approx(sim.campaign.bonus("camp_supplies"),1.0) and is_zero_approx(sim.campaign.bonus("camp_discount")),"The owner now has Camp Supplies and no discount")
    check(sim.campaign.combo_owned(sim.catalog.campaign.combos.filter(func(c):return str(c.id)=="regional_set")[0]),"The Regional set stays complete for this owner")
    var base: int=ceili(50*sim.campaign.map_cost_factor(int(sim.state.stage)))
    check(sim.campaign.camp_price(1)==base,"Camp 1 costs the full map price (%d), not half" % base)
    sim.state.player.hp=sim.stats().hp;at_camp(0)
    var before:=supplies_total();var coins: float=sim.state.coins;var gems: float=sim.state.gems
    var id: String=sim.campaign.camp_supply_step()
    check(id!="" and supplies_total()==before+1,"Standing at the Winter I camp gives this owner 1 supply (%s)" % id)
    check(is_equal_approx(sim.state.coins,coins) and is_equal_approx(sim.state.gems,gems),"…free: no Coins or Gems spent")

# ---------------------------------------------------------------- visits
func visit_checks() -> void:
    print("-- Visits")
    fresh(false)
    at_camp(0)
    check(sim.campaign.camp_supply_step()=="" and supplies_total()==0 and sim.state.camp_supplies.is_empty(),"Without the card a camp gives nothing and records nothing")
    fresh()
    away()
    check(sim.campaign.camp_supply_step()=="" and supplies_total()==0,"Away from every camp: nothing")
    at_camp(0)
    var coins: float=sim.state.coins
    var id: String=sim.campaign.camp_supply_step()
    check(id in ["potion","coin_boost"] and sim.quantity(id)==1 and supplies_total()==1,"First visit to Winter I camp 0: exactly 1 random Winter I supply (%s)" % id)
    check(is_equal_approx(sim.state.coins,coins),"No Coins paid")
    check(sim.state.camp_supplies=={"1":[0]},"Recorded as rewarded this run: %s" % [sim.state.camp_supplies])
    check(granted==[id],"One reward notice")
    for i in range(5):sim.campaign.camp_supply_step()
    check(supplies_total()==1 and granted.size()==1,"Staying at the camp gives nothing more")
    away();sim.campaign.camp_supply_step();at_camp(0)
    check(sim.campaign.camp_supply_step()=="" and supplies_total()==1,"Leaving and returning gives nothing more")
    # An unowned camp is not a visit.
    sim.state.coins=1e6
    at_camp(1)
    check(sim.campaign.camp_supply_step()=="" and supplies_total()==1,"Standing at a camp not owned gives nothing")
    sim.state.camps_known["1"]=[1] # fixture: camp 1 sighted
    check(sim.select_spawn(1),"Winter I camp 1 bought the normal way")
    var id2: String=sim.campaign.camp_supply_step()
    check(id2!="" and supplies_total()==2 and sim.state.camp_supplies=={"1":[0,1]},"A different camp gives its own supply (%s)" % id2)
    # Teleport back and forth.
    check(sim.campaign.camp_action(1,0,true),"Teleport to camp 0")
    sim.campaign.camp_supply_step()
    check(sim.campaign.camp_action(1,1,true),"Teleport to camp 1")
    sim.campaign.camp_supply_step()
    check(supplies_total()==2,"Teleporting between rewarded camps gives nothing more")
    # Death and respawn at the camp.
    sim.state.player.hp=0.0
    check(sim.campaign.camp_supply_step()=="","A defeated player is not visiting")
    sim.state.player.hp=sim.stats().hp
    check(sim.campaign.camp_supply_step()=="" and supplies_total()==2,"Respawning at a rewarded camp gives nothing more")
    # Another map: its camps reward independently, the map's own pool.
    sim.state.unlocked_stage=2;sim.state.camps["2"]=[0,1,2] # fixture: Winter II reached, camps owned
    check(sim.campaign.camp_action(2,2,true),"Teleport to Winter II camp 2")
    var id3: String=sim.campaign.camp_supply_step()
    check(id3 in ["potion","coin_boost","guard_tonic"] and supplies_total()==3,"Winter II camp 2 gives its supply from the Winter II pool (%s)" % id3)
    check(sim.state.camp_supplies=={"1":[0,1],"2":[2]},"Per-map, per-camp record: %s" % [sim.state.camp_supplies])
    # A kept camp on a map beyond the current reach (stage set directly) is not a legitimate visit.
    sim.state.unlocked_stage=1 # fixture: inconsistent reach
    at_camp(0)
    check(sim.campaign.camp_supply_step()=="","A map beyond this run's reach never rewards")

func real_step_checks() -> void:
    print("-- The real simulation step")
    fresh()
    at_camp(0)
    for i in range(20):sim.step(.05)
    check(supplies_total()==1 and sim.state.camp_supplies=={"1":[0]},"One second of play at the camp gives exactly 1 supply")
    for i in range(60):sim.step(.05)
    check(supplies_total()==1,"Three more seconds give nothing more")
    check(game.toast_queue.has(tr("CAMP_SUPPLY_RECEIVED") % sim.catalog.display_name(str(granted[0]))),"The toast lane names the supply: %s" % [game.toast_queue])
    fresh()
    sim.state.camps["1"].append(1) # fixture: camp 1 owned (state.spawns is this live array)
    sim.state.prestige_batch={"ids":["x"],"choices":[]} # fixture: a Prestige choice is open
    at_camp(1)
    for i in range(10):sim.step(.05)
    check(supplies_total()==0,"Nothing is given while a Prestige choice is open")
    sim.state.prestige_batch={}

# ---------------------------------------------------------------- full inventory
func full_inventory_checks() -> void:
    print("-- Full inventory")
    fresh()
    check(sim.state.supplies.size()==1,"fixture: the starting inventory has 1 supply slot")
    sim.add_item("guard_tonic",1,false,false) # fixture: the only slot holds a Winter II supply
    at_camp(0)
    check(sim.campaign.camp_supply_pool(1).is_empty(),"No Winter I supply fits")
    check(sim.campaign.camp_supply_step()=="" and sim.state.camp_supplies.is_empty() and sim.quantity("guard_tonic")==1,"Full: nothing given, nothing lost, the camp is NOT marked")
    check(waits==1 and game.toast_queue.has(tr("CAMP_SUPPLY_WAITING")),"One waiting notice")
    for i in range(5):sim.campaign.camp_supply_step()
    check(waits==1,"…not repeated while the player stays")
    sim._remove("guard_tonic",1) # fixture: the player frees the slot (used or dropped)
    var id: String=sim.campaign.camp_supply_step()
    check(id!="" and supplies_total()==1 and sim.state.camp_supplies=={"1":[0]},"Once a slot is free the same visit gives the supply (%s)" % id)
    fresh()
    sim.add_item("guard_tonic",1,false,false)
    at_camp(0);sim.campaign.camp_supply_step()
    away();sim.campaign.camp_supply_step()
    sim._remove("guard_tonic",1)
    sim.add_item("potion",3,false,false) # fixture: a stack that the reward can join
    at_camp(0)
    var id2: String=sim.campaign.camp_supply_step()
    check(id2=="potion" and sim.quantity("potion")==4,"A later visit gives it, joining a stack when that is the only room")

# ---------------------------------------------------------------- persistence
func persistence_checks() -> void:
    print("-- Save and reload")
    fresh()
    sim.state.camps["1"].append(1) # fixture: camp 1 owned (state.spawns is this live array)
    at_camp(0);sim.campaign.camp_supply_step()
    check(sim.state.camp_supplies=={"1":[0]},"Camp 0 rewarded")
    var total:=supplies_total()
    check(SaveService.save_now(),"Disk save")
    sim.state.camp_supplies={};sim.state.items={} # fixture: in-memory change the reload must undo
    SaveService.load_and_apply();await frames(2)
    check(sim.state.camp_supplies=={"1":[0]} and supplies_total()==total,"Reload restores the record and the supply (no loss, no duplicate)")
    at_camp(0)
    check(sim.campaign.camp_supply_step()=="" and supplies_total()==total,"Reopening at a rewarded camp gives nothing")
    at_camp(1)
    check(sim.campaign.camp_supply_step()!="" and supplies_total()==total+1,"An unrewarded camp still gives its supply after reload")
    var snap: Dictionary=sim.save_snapshot()
    check(snap.camp_supplies=={"1":[0,1]},"The save carries the record")

# ---------------------------------------------------------------- Prestige
func prestige_checks() -> void:
    print("-- Prestige")
    fresh()
    sim.state.coins=1e7
    sim.state.camps["1"].append(1);sim.state.unlocked_stage=2;sim.state.camps["2"]=[0,2] # fixture: camps owned
    at_camp(0);sim.campaign.camp_supply_step();at_camp(1);sim.campaign.camp_supply_step()
    check(sim.state.camp_supplies=={"1":[0,1]},"Both Winter I camps rewarded")
    var owned: Array=sim.state.owned_cards.duplicate()
    check(do_prestige(),"Prestige completes")
    check(sim.state.camp_supplies.is_empty(),"Prestige clears the per-run reward record")
    check(sim.state.camps.get("1",[])==[0,1] and sim.state.camps.get("2",[])==[0,2],"Owned camps are kept (Change 76)")
    check(int(sim.state.unlocked_stage)==1,"Map access still resets")
    var all_owned:=true
    for id in owned:all_owned=all_owned and sim.state.owned_cards.has(id)
    check(all_owned and sim.state.owned_cards.size()>owned.size(),"Card ownership kept and the new card added")
    check(supplies_total()==0,"Run items reset as before")
    sim.state.player.hp=sim.stats().hp
    at_camp(0)
    check(sim.campaign.camp_supply_step()!="","Winter I camp 0 rewards again in the new run")
    check(sim.campaign.camp_action(1,1,true) and sim.campaign.camp_supply_step()!="","Kept camp 1 rewards again in the new run")
    check(sim.campaign.travel_reason(2,2)=="STAGE_LOCKED","Winter II's kept camp waits until the map is reached again")
    check(supplies_total()==2,"Exactly one supply per camp in the new run")

func hard_reset_checks() -> void:
    print("-- Hard Reset")
    fresh()
    at_camp(0);sim.campaign.camp_supply_step()
    check(SaveService.hard_reset(),"Hard Reset")
    await frames(2)
    check(sim.state.camp_supplies.is_empty() and not sim.state.owned_cards.has("regional_c3") and sim.state.camps=={"1":[0]},"Hard Reset clears the record, the card and the camps")
    at_camp(0)
    check(sim.campaign.camp_supply_step()=="" and supplies_total()==0,"…so nothing is given afterwards")

func normalize_checks() -> void:
    print("-- Older and damaged saves")
    fresh()
    var snap: Dictionary=sim.snapshot()
    snap.erase("camp_supplies")
    check(sim.campaign.normalize_snapshot(snap).camp_supplies=={},"A save from before Change 77 starts with no camp rewarded")
    snap.camp_supplies={"1":[0.0,0,1.0,7,"x"],"2":"bad","99":[0],"y":[1],"3":[]}
    check(sim.campaign.normalize_snapshot(snap).camp_supplies=={"1":[0,1]},"Damaged record: duplicates, invalid camps and maps dropped, numbers made ints")
    snap.camp_supplies="bad"
    var out: Dictionary=sim.campaign.normalize_snapshot(snap)
    check(out.camp_supplies=={} and sim.campaign.valid_snapshot(out),"A non-dictionary record becomes empty and the save stays valid")

# ---------------------------------------------------------------- UI
func texts(node: Node,out: Array) -> Array:
    if (node is Label or node is Button or node is RichTextLabel) and node.is_visible_in_tree():out.append(str(node.text))
    for c in node.get_children():texts(c,out)
    return out

func ui_checks() -> void:
    print("-- UI")
    fresh()
    game._open("prestige");await frames(4)
    var all:=" | ".join(texts(game,[]))
    check(not all.contains("Camp Survey") and not all.contains("Camps cost 50%"),"No Camp Survey or 50% camp text in the Prestige panel")
    check(all.contains("Camp Supplies"),"The owned card is listed as Camp Supplies")
    game._close()
    # The reward notice is a toast (non-blocking), not a panel or a banner.
    fresh()
    at_camp(0);sim.campaign.camp_supply_step()
    check(not game.sheet.visible and game.banner.queue.is_empty(),"The reward opens no panel or banner")
    for i in range(3):game._update_toast(.1)
    var toast: Control=game.get_node("Toast")
    check(toast.visible and str(game.get_node("Toast/Text").text).begins_with("Camp Supplies: +1 "),"Toast shown: %s" % game.get_node("Toast/Text").text)
    var rect: Rect2=toast.get_global_rect()
    check(rect.size.x<=get_window().size.x and rect.position.x>=0,"The toast fits the screen width")
