extends Node
## Change 76 focused checks (real main scene and simulation; state set directly is labelled "fixture"):
## - Camps are permanent: Prestige keeps owned camps (and each map's respawn choice) while map access, items and
##   run state still reset; kept camps stay the live array of the current map; travel works again once a map is
##   reached; disk save/reload; Hard Reset clears them; older profiles get camps lost to earlier Prestiges back
##   from Map Mastery's lifetime record, exactly once.
## - Boss weapon notice: ITEM_ENHANCED is an important toast (>= 8 s, never shortened by a queue), measured
##   through the real toast queue with other notices before and after it; ordinary toasts keep their timing.
## - Auto Buy Supplies: Gem unlocks 100 / 160 / 250 (kept by Prestige), three slots, no duplicates, buys 5 when
##   below 2 (0, 1, 2 and more owned), waits on Coins / room / locks without switching off, never loops, three
##   supplies at once, the real step drives it, Prestige / save / reload / Hard Reset, older and damaged saves.
## - Supplies tab UI at four portrait shapes: slot cards, Gem prices, chooser, duplicate prevention, badges,
##   touch sizes and no horizontal overflow.
## Run: Godot --headless --path . res://tests/change_76_probe.tscn -- --probe --profile=probe-c76 --no-autosave --first-run-complete
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
func _ready() -> void:call_deferred("run")

func run() -> void:
    SettingsState.mute_all_sfx()
    TranslationServer.set_locale("en")
    get_window().size=Vector2i(720,1280)
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    await frames(6)
    await camp_checks()
    migration_checks()
    toast_checks()
    await auto_buy_checks()
    await auto_buy_persistence_checks()
    await ui_checks()
    print("CHANGE_76_CHECKS %d FAILURES %d" % [checks,failures])
    game.queue_free();await frames(2);AudioService.stop_all_sfx()
    get_tree().quit(1 if failures>0 else 0)

func fresh() -> void:
    get_tree().paused=false
    sim.held=false
    sim.new_profile();sim.set_physics_process(false);sim.suspended=false;SaveService.write_blocked=false
    sim.state.tutorial.mode="none"
    sim.campaign.onboarding.reveal_all(true)
    sim.state.tutorial.seen.append("road_ahead")
    game._close();game.banner.queue.clear();game.banner._finish();game.toast_queue.clear();game.toast_important.clear();game.get_node("Toast").hide()

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

# ---------------------------------------------------------------- camps
func camp_checks() -> void:
    print("-- Camps through Prestige")
    fresh()
    sim.state.coins=1e7
    sim.state.camps_known["1"]=[1] # fixture: camp 1 of Winter I sighted
    check(sim.select_spawn(1) and sim.state.camps["1"]==[0,1],"Winter I camp 1 bought the normal way")
    check(sim.select_spawn(1) and int(sim.state.spawn)==1,"…and selected as the respawn camp")
    sim.state.unlocked_stage=3 # fixture: maps 2-3 reached this run
    sim.state.camps["2"]=[0,2];sim.state.camps["3"]=[0,1,2];sim.state.respawns["2"]=2 # fixture: owned there
    sim.add_item("wood_axe",1,false,false);sim.state.run_kills["x"]=1 # fixture: run state that must reset
    var before_camps: Dictionary=sim.state.camps.duplicate(true)
    var coins_before: float=sim.state.coins
    check(do_prestige(),"Prestige completes")
    check(sim.state.camps==before_camps,"Prestige keeps every owned camp (%s)" % [sim.state.camps])
    check(sim.state.spawns==sim.state.camps["1"] and is_same(sim.state.spawns,sim.state.camps["1"]),"The kept Winter I camps are the live camp list of the current map")
    check(int(sim.state.spawn)==1 and int(sim.state.respawns.get("2",-1))==2,"Each map's chosen respawn camp is kept (Winter I: camp 1)")
    check(int(sim.state.unlocked_stage)==1 and int(sim.state.stage)==1,"Map access still resets to Winter I")
    check(sim.quantity("wood_axe")==0 and sim.state.run_kills.is_empty(),"Items and run kills still reset")
    check(is_equal_approx(sim.state.coins,coins_before),"Coins kept as before (Change 50 rule unchanged)")
    check(sim.campaign.travel_reason(1,1)=="","Travel to the kept Winter I camp 1 works at once")
    check(sim.campaign.travel_reason(2,2)=="STAGE_LOCKED","A kept camp on a map not reached yet this run waits for the map")
    sim.state.unlocked_stage=2 # fixture: Winter II reached again
    check(sim.campaign.travel_reason(2,2)=="","…and is usable as soon as the map is reached again (no repurchase)")
    check(sim.campaign.camp_action(2,2,true) and int(sim.state.stage)==2 and int(sim.state.spawn)==2 and sim.state.spawns==[0,2],"Teleport to Winter II arrives with its kept camps and respawn choice")
    sim.state.camps_known["2"]=[1] # fixture: the remaining camp sighted
    check(sim.select_spawn(1) and sim.state.camps["2"]==[0,2,1],"A new camp bought after Prestige joins the kept ones")
    check(do_prestige() and sim.state.camps["2"]==[0,2,1] and sim.state.camps["1"]==[0,1],"A second Prestige keeps them again")
    # Disk save and reload.
    check(SaveService.save_now(),"Disk save")
    sim.state.camps={"1":[0]};sim.campaign.configure_stage()
    SaveService.load_and_apply();await frames(2)
    check(sim.state.camps.get("1",[])==[0,1] and sim.state.camps.get("2",[])==[0,2,1] and sim.state.camps.get("3",[])==[0,1,2],"Reload restores the owned camps")
    check(sim.state.spawns==sim.state.camps[str(sim.state.stage)],"…as the live camp list of the current map")
    # Hard Reset.
    check(SaveService.hard_reset(),"Hard Reset")
    check(sim.state.camps=={"1":[0]} and sim.state.respawns.is_empty() and sim.state.spawns==[0],"Hard Reset clears camp progression")

func migration_checks() -> void:
    print("-- Older profiles")
    fresh()
    var snap: Dictionary=sim.snapshot()
    # fixture: a released profile that prestiged before Change 76 (camps lost, Map Mastery remembers them)
    snap.migrations.erase("camps_permanent")
    snap.camps={"1":[0.0],"2":[0.0,1.0]}
    snap.mastery.camps={"1":[0,1],"2":[0,2],"3":[0,1,9],"x":[1]}
    snap.erase("auto_buy")
    var out: Dictionary=sim.campaign.normalize_snapshot(snap)
    check(out.camps.get("1",[])==[0,1] and out.camps.get("2",[])==[0,1,2] and out.camps.get("3",[])==[0,1],"Camps owned in earlier runs are owned again (invalid entries ignored): %s" % [out.camps])
    check(out.migrations.has("camps_permanent"),"…recorded as a one-time migration")
    check(out.auto_buy==["","",""],"A save without Auto Buy starts with three empty slots")
    var again: Dictionary=out.duplicate(true)
    again.camps={"1":[0]};again.mastery.camps={"1":[0,1]}
    check(sim.campaign.normalize_snapshot(again).camps=={"1":[0]},"The migration never repeats on a later load")
    var current: Dictionary=sim.snapshot()
    current.camps={"1":[0,1],"2":[0,2]}
    check(sim.campaign.normalize_snapshot(current).camps=={"1":[0,1],"2":[0,2]},"A current profile's unlocked camps load unchanged")
    var damaged: Dictionary=sim.snapshot()
    damaged.auto_buy=["potion","potion",5,"wood_axe"]
    check(sim.campaign.normalize_snapshot(damaged).auto_buy==["potion","",""],"Damaged Auto Buy data: duplicates, non-supplies and extra slots are cleared")
    damaged.auto_buy="potion"
    check(sim.campaign.normalize_snapshot(damaged).auto_buy==["","",""],"A non-list Auto Buy value becomes empty slots")

# ---------------------------------------------------------------- toasts
## Runs the real toast queue in 0.1 s steps; returns how long `text` stayed on screen (s) and the order shown.
func run_queue(text: String,limit:=60.0) -> Dictionary:
    var shown:=0.0;var order: Array=[];var t:=0.0
    var toast: Control=game.get_node("Toast")
    while t<limit and (not game.toast_queue.is_empty() or toast.visible or t==0.0):
        game._update_toast(.1);t+=.1
        var now: String=game.get_node("Toast/Text").text if toast.visible else ""
        if now!="" and (order.is_empty() or order.back()!=now):order.append(now)
        if now==text:shown+=.1
    return {"shown":shown,"order":order}

func toast_checks() -> void:
    print("-- Boss weapon notice")
    fresh()
    var enhanced:=tr("ITEM_ENHANCED")
    check(game.toast_reading_time(enhanced,true,true)>=8.0 and is_equal_approx(game.toast_reading_time(enhanced,true,true),game.toast_reading_time(enhanced,false,true)),"Important reading time is >= 8 s and the same with others waiting (%.1f s)" % game.toast_reading_time(enhanced,true,true))
    check(game.toast_reading_time(enhanced,true)<game.toast_reading_time(enhanced,false) and game.toast_reading_time(enhanced,false)<=6.0,"Ordinary toasts keep their timing (busy cut, 6 s cap)")
    var long:="x".repeat(400)
    check(is_equal_approx(game.toast_reading_time(long,true,true),game.IMPORTANT_TOAST_MAX_SECONDS),"An important toast is bounded (%.0f s)" % game.IMPORTANT_TOAST_MAX_SECONDS)
    # Alone.
    sim.event.emit("ITEM_ENHANCED")
    var r:=run_queue(enhanced)
    check(r.shown>=7.9,"Alone: shown %.1f s" % r.shown)
    # A pickup moment: notices before and after it, all queued at once.
    fresh()
    sim.event.emit("NOT_ENOUGH_COINS");sim.event.emit("ITEM_ENHANCED");sim.event.emit("INVENTORY_FULL");sim.event.emit("SPOT_UNDISCOVERED")
    check(game.toast_important.has(enhanced) and game.toast_important.size()==1,"Only the boss weapon notice is marked important")
    r=run_queue(enhanced)
    check(r.shown>=7.9,"With three other notices queued around it: shown %.1f s (was 3.3 s)" % r.shown)
    check(r.order==[tr("NOT_ENOUGH_COINS"),enhanced,tr("INVENTORY_FULL"),tr("SPOT_UNDISCOVERED")],"Every notice is still shown, in order: %s" % [r.order])
    check(game.toast_important.is_empty(),"The important mark ends with its toast")
    # A panel opened while it shows: it waits with its remaining time and finishes after.
    fresh()
    sim.event.emit("ITEM_ENHANCED")
    for i in range(20):game._update_toast(.1)
    game._open("upgrades");game._update_toast(.1)
    check(not game.get_node("Toast").visible and game.toast_queue.front()==enhanced,"Opening a panel holds it (queued again at the front)")
    var left: float=float(game.toast_resume.get("time",0))
    check(left>=5.5,"…with its remaining time (%.1f s)" % left)
    game._close()
    r=run_queue(enhanced)
    check(r.shown>=left-.15,"…and it resumes for that time after the panel closes (%.1f s)" % r.shown)
    # In an open panel it uses the notice line, unchanged.
    fresh()
    game._open("upgrades")
    sim.event.emit("ITEM_ENHANCED")
    check(game.notice.text==enhanced and game.toast_queue.is_empty(),"With a panel open it is written on the notice line")
    game._close()

# ---------------------------------------------------------------- Auto Buy
func auto_buy_checks() -> void:
    print("-- Auto Buy Supplies")
    var d: Dictionary=sim.catalog.upgrades.get("auto_buy_slots",{})
    check(d.get("prices",[]).map(func(v):return int(v))==[100,160,250] and int(d.get("cap",0))==3 and d.get("currency","")=="gems" and sim.upgrade_kept("auto_buy_slots"),"Unlock schedule 100 / 160 / 250 Gems, cap 3, kept by Prestige")
    fresh()
    check(sim.auto_buy_capacity()==0 and not sim.set_auto_buy(0,"potion") and sim.auto_buy_block(0,"potion")=="AUTO_BUY_SLOT_LOCKED","Before any unlock no slot can be set")
    sim.state.gems=99.0
    check(not sim.buy_upgrade("auto_buy_slots") and sim.auto_buy_capacity()==0 and is_equal_approx(sim.state.gems,99.0),"99 Gems: the first unlock is refused, nothing charged")
    sim.state.gems=510.0
    var paid: Array=[]
    for i in range(3):
        paid.append(sim.upgrade_cost("auto_buy_slots"))
        check(sim.buy_upgrade("auto_buy_slots") and sim.auto_buy_capacity()==i+1,"Unlock %d bought" % (i+1))
    check(paid==[100,160,250] and is_equal_approx(sim.state.gems,0.0),"Charged exactly 100, 160, 250 Gems (%s)" % [paid])
    sim.state.gems=1000.0
    check(sim.upgrade_maxed("auto_buy_slots") and not sim.buy_upgrade("auto_buy_slots") and sim.auto_buy_capacity()==3,"No fourth slot")
    # Selection rules.
    check(sim.set_auto_buy(0,"potion"),"Slot 1: Health Potion")
    check(not sim.set_auto_buy(1,"potion") and sim.auto_buy_block(1,"potion")=="AUTO_BUY_DUPLICATE" and sim.auto_buy_selection()==["potion","",""],"The same supply cannot take a second slot")
    check(not sim.set_auto_buy(1,"wood_axe") and not sim.set_auto_buy(3,"coin_boost") and not sim.set_auto_buy(-1,"coin_boost"),"Non-supplies and slots outside 1-3 are refused")
    check(sim.set_auto_buy(0,"potion"),"Choosing the supply a slot already has is accepted (no change)")
    check(sim.set_auto_buy(0,"coin_boost") and sim.set_auto_buy(1,"potion") and sim.auto_buy_selection()==["coin_boost","potion",""],"Changing a slot frees its old supply for another slot")
    check(sim.set_auto_buy(0,"") and sim.auto_buy_selection()==["","potion",""] and sim.auto_buy_ids()==["potion"],"A slot can be switched off")
    # Quantities: 0, 1, 2 and more owned (one supply slot holds the potion).
    var unit:=int(sim.supply("potion").price)
    for owned in [0,1,2,3,7]:
        if sim.quantity("potion")>0:sim._remove("potion",sim.quantity("potion"))
        if owned>0:sim.add_item("potion",owned,false,false) # fixture: stock
        sim.state.coins=float(unit*20)
        var bought: int=sim.auto_buy_step()
        var expect: int=owned+5 if owned<2 else owned
        check(sim.quantity("potion")==expect and is_equal_approx(sim.state.coins,unit*20.0-(unit*5 if owned<2 else 0)) and bought==(1 if owned<2 else 0),"%d owned -> %d (%s)" % [owned,sim.quantity("potion"),"bought 5 at the shop price" if owned<2 else "no purchase"])
    # No loops: further passes buy nothing while the stock is 2 or more.
    sim._remove("potion",sim.quantity("potion"));sim.state.coins=1e6
    var total:=0
    for i in range(50):total+=sim.auto_buy_step()
    check(total==1 and sim.quantity("potion")==5,"50 passes after running out buy once (%d purchase, 5 owned)" % total)
    # Using the stock down: buys again only when below 2.
    sim.state.player.hp=1.0
    for i in range(3):sim._remove("potion",1)
    check(sim.quantity("potion")==2 and sim.auto_buy_step()==0,"At 2 nothing is bought")
    sim._remove("potion",1)
    check(sim.auto_buy_step()==1 and sim.quantity("potion")==6,"At 1 it restocks to 6")
    # Not enough Coins: waits, keeps the slot, buys once affordable.
    sim._remove("potion",sim.quantity("potion"));sim.state.coins=float(unit*5-1)
    check(sim.auto_buy_step()==0 and sim.quantity("potion")==0 and is_equal_approx(sim.state.coins,unit*5-1.0),"One Coin short of 5: nothing bought, nothing charged")
    check(sim.auto_buy_wait_reason("potion")=="NOT_ENOUGH_COINS" and sim.auto_buy_ids()==["potion"],"…it waits on Coins and stays enabled")
    sim.state.coins=float(unit*5)
    check(sim.auto_buy_step()==1 and sim.quantity("potion")==5 and is_equal_approx(sim.state.coins,0.0),"…and buys as soon as the Coins are there")
    # No free supply slot: waits for room.
    fresh()
    sim.state.gems=1e4
    for i in range(2):sim.buy_upgrade("auto_buy_slots")
    sim.set_auto_buy(0,"potion");sim.set_auto_buy(1,"coin_boost")
    sim.add_item("guard_tonic",3,false,false) # fixture: the single supply slot is taken
    sim.state.coins=1e6
    check(sim.auto_buy_step()==0 and sim.quantity("potion")==0 and sim.auto_buy_wait_reason("potion")=="INVENTORY_FULL","No free supply slot: waits (Inventory full), nothing charged")
    check(is_equal_approx(sim.state.coins,1e6),"…Coins untouched")
    sim._remove("guard_tonic",3)
    check(sim.auto_buy_step()==1 and sim.quantity("potion")==5 and sim.quantity("coin_boost")==0,"Room for one: the first slot's supply is bought")
    check(sim.auto_buy_wait_reason("coin_boost")=="INVENTORY_FULL","…the other keeps waiting for room")
    # Three supplies at once.
    fresh()
    sim.state.gems=1e4
    for i in range(3):sim.buy_upgrade("auto_buy_slots")
    for i in range(2):sim.buy_upgrade("supply_slots")
    check(sim.state.supplies.size()==3,"Three supply slots (fixture through the normal Gem upgrade)")
    sim.set_auto_buy(0,"potion");sim.set_auto_buy(1,"coin_boost");sim.set_auto_buy(2,"guard_tonic")
    var cost:=5*(int(sim.supply("potion").price)+int(sim.supply("coin_boost").price)+int(sim.supply("guard_tonic").price))
    sim.state.coins=float(cost)
    var events: Array=[]
    var on_bought:=func(id: String,amount: int)->void:events.append([id,amount])
    sim.auto_bought.connect(on_bought)
    # Through the real simulation step (the campaign automation tick).
    sim.step(.1)
    check(sim.quantity("potion")==5 and sim.quantity("coin_boost")==5 and sim.quantity("guard_tonic")==5 and is_equal_approx(sim.state.coins,0.0),"One simulation step restocks all three (exactly %d Coins)" % cost)
    check(events==[["potion",5],["coin_boost",5],["guard_tonic",5]],"Each purchase is announced once")
    for i in range(30):sim.step(.1)
    check(events.size()==3,"No further purchases while stocked")
    sim.auto_bought.disconnect(on_bought)
    check(game.toast_queue.has(tr("AUTO_BUY_DONE") % [5,sim.catalog.display_name("potion")]),"The HUD announces 'Auto Buy: 5 × Health Potion'")
    check(sim.state.supply_uses.is_empty() and sim.supply_mastery("potion")==0,"Buying gives no Supply Mastery")
    # Locks: paused / Prestige choice never buy.
    for id in ["potion","coin_boost","guard_tonic"]:sim._remove(id,5)
    sim.state.coins=1e6
    get_tree().paused=true
    check(sim.auto_buy_step()==0 and sim.auto_buy_wait_reason("potion")=="ACTION_PAUSED","Paused: no purchase")
    get_tree().paused=false
    sim.state.prestige_batch={"ids":["x"],"choices":[]} # fixture: a Prestige choice open
    check(sim.auto_buy_step()==0,"During a Prestige choice: no purchase")
    sim.state.prestige_batch={}
    check(sim.auto_buy_step()==3,"Unlocked again: all three bought")

func auto_buy_persistence_checks() -> void:
    print("-- Auto Buy persistence")
    fresh()
    sim.state.gems=1e4;sim.state.coins=1e6
    for i in range(2):sim.buy_upgrade("auto_buy_slots")
    sim.buy_upgrade("supply_slots")
    sim.set_auto_buy(0,"coin_boost");sim.set_auto_buy(1,"potion")
    sim.add_item("coin_boost",9,false,false);sim.add_item("potion",9,false,false) # fixture: stocked (no purchase)
    check(do_prestige(),"Prestige completes")
    check(sim.auto_buy_capacity()==2 and sim.auto_buy_selection()==["coin_boost","potion",""],"Prestige keeps the unlocks and the selections")
    check(sim.quantity("potion")==0 and sim.quantity("coin_boost")==0,"Supply stock still resets")
    sim.step(.1)
    check(sim.quantity("potion")==5 and sim.quantity("coin_boost")==5,"After Prestige the automation restocks the reset supplies at once (kept Coins)")
    check(SaveService.save_now(),"Disk save")
    sim.state.auto_buy=["","",""];sim.state.upgrades.erase("auto_buy_slots")
    SaveService.load_and_apply();await frames(2)
    check(sim.auto_buy_capacity()==2 and sim.auto_buy_selection()==["coin_boost","potion",""],"Reload restores the unlocks and the selections")
    check(SaveService.hard_reset(),"Hard Reset")
    check(sim.auto_buy_capacity()==0 and sim.auto_buy_selection()==["","",""],"Hard Reset clears the unlocks and the selections")

# ---------------------------------------------------------------- UI
func buttons(prefix: String) -> Array:
    return game.rows.find_children("*","Button",true,false).filter(func(b):return str(b.get_meta("guide","")).begins_with(prefix))
func labels() -> String:
    return " | ".join(game.rows.find_children("*","Label",true,false).map(func(l):return l.text))
func within(c: Control) -> bool:
    var area: Rect2=game.rows.get_global_rect()
    var r: Rect2=c.get_global_rect()
    return r.position.x>=area.position.x-1 and r.end.x<=area.end.x+1

func ui_checks() -> void:
    print("-- Supplies tab UI")
    for shape in [Vector2i(720,1280),Vector2i(720,1600),Vector2i(720,1080),Vector2i(960,1280)]:
        fresh()
        get_window().size=shape;await frames(3)
        sim.state.gems=120.0;sim.state.coins=0.0
        game.player_tab=2;game._open("upgrades");await frames(4)
        var unlock:=buttons("auto_buy_unlock_")
        check(unlock.size()==3 and not unlock[0].disabled and unlock[1].disabled and unlock[2].disabled,"%s: three locked slots, only the first can be unlocked" % shape)
        check(unlock.map(func(b):return b.text)==[game.fmt_cost(100),game.fmt_cost(160),game.fmt_cost(250)],"%s: Gem prices 100 / 160 / 250 shown" % shape)
        unlock[0].pressed.emit();await frames(3)
        check(sim.auto_buy_capacity()==1 and is_equal_approx(sim.state.gems,20.0),"%s: the unlock button buys slot 1 for 100 Gems" % shape)
        var picks:=buttons("auto_buy_pick_")
        check(picks.size()==6,"%s: unlocking opens the chooser (5 supplies + Off)" % shape)
        check(picks.all(func(b):return b.size.y>=56 and b.size.x>=150 and within(b)),"%s: chooser chips are touch-sized and inside the panel" % shape)
        for b in picks:
            if b.get_meta("guide")=="auto_buy_pick_potion":b.pressed.emit()
        await frames(3)
        check(sim.auto_buy_selection()[0]=="potion" and buttons("auto_buy_pick_").is_empty(),"%s: choosing Health Potion sets slot 1 and closes the chooser" % shape)
        var text:=labels()
        check(text.contains(tr("AUTO_BUY_SLOT") % [1,sim.catalog.display_name("potion")]) and text.contains(tr("AUTO_BUY_WAITING") % tr("NOT_ENOUGH_COINS")),"%s: slot 1 names its supply and that it waits for Coins" % shape)
        check(text.contains(sim.catalog.display_name("potion")+"  ·  "+tr("AUTO_BUY_BADGE")),"%s: the shop card shows the Auto Buy badge" % shape)
        check(text.contains(tr("AUTO_BUY_UNLOCK_PRICE") % game.fmt_cost(160)) and text.contains(tr("NOT_ENOUGH_GEMS")),"%s: slot 2 shows its price and why it cannot be bought yet" % shape)
        for c in game.rows.get_children():
            if c is Control and c.visible and not within(c):check(false,"%s: %s overflows the panel width" % [shape,c.name])
        # Second slot: the potion is disabled there.
        sim.state.gems=200.0;game._refresh_panel(true);await frames(3)
        buttons("auto_buy_unlock_1")[0].pressed.emit();await frames(3)
        var potion: Array=buttons("auto_buy_pick_potion")
        check(potion.size()==1 and potion[0].disabled and potion[0].text.contains(tr("AUTO_BUY_IN_SLOT") % 1),"%s: in slot 2's chooser the potion is disabled ('In slot 1')" % shape)
        for b in buttons("auto_buy_pick_coin_boost"):b.pressed.emit()
        await frames(3)
        check(sim.auto_buy_selection()==["potion","coin_boost",""],"%s: slot 2 takes Coin Tonic" % shape)
        # Change then Off.
        buttons("auto_buy_change_0")[0].pressed.emit();await frames(3)
        check(buttons("auto_buy_pick_").size()==6 and buttons("auto_buy_change_0")[0].theme_type_variation==&"Primary","%s: Change reopens slot 1's chooser (highlighted)" % shape)
        for b in buttons("auto_buy_pick_off"):b.pressed.emit()
        await frames(3)
        check(sim.auto_buy_selection()==["","coin_boost",""] and labels().contains(tr("AUTO_BUY_SLOT") % [1,tr("OFF")]),"%s: Off disables slot 1" % shape)
        buttons("auto_buy_change_1")[0].pressed.emit();await frames(2)
        game._close();game.player_tab=2;game._open("upgrades");await frames(3)
        check(game.auto_buy_edit==-1 and buttons("auto_buy_pick_").is_empty(),"%s: a chooser left open is closed when the panel reopens" % shape)
        var scroll: ScrollContainer=game.get_node("Sheet/Margin/Content/Scroll")
        check(scroll.get_v_scroll_bar().max_value>scroll.size.y,"%s: the tab scrolls (content %.0f > view %.0f)" % [shape,scroll.get_v_scroll_bar().max_value,scroll.size.y])
        game._close()
    get_window().size=Vector2i(720,1280);await frames(3)
