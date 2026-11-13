extends Node
## Change 71 focused checks (real main scene and simulation; state set directly is labelled "fixture"):
## - Coin prices: no Coin upgrade step above x1.8 on any map; the cheap-first taper at its boundaries; the shop,
##   the card and the purchase charge one price; levels and prices survive Prestige.
## - Main inventory organisation: category and sort reorder the dock grid through gear_view only (owned items
##   never move), taps/holds/browse/guide target the right item, the choice survives close, Prestige, a disk
##   save/reload and older settings, and Hard Reset returns All / Default.
## - Supplies shop: shared saved quantity (x1 default), atomic bulk purchase (exact Coins and copies, or no
##   change), invalid / unaffordable / full requests refused, buying gives no Supply Mastery, UI rows.
## - Follow / Unfollow: one size and colour (red Follow, green Unfollow) in Mastery, Missions and Prestige.
## - Compact trackers: no "Next:" line on the HUD; the Prestige panel keeps it.
## - HUD: MINIMAP -> ZOOM -> status stack top-right, no permanent boss objective, three trackers clear of the
##   left controls at four screen shapes, every joystick position and German; toasts clear of the columns.
## - Boss upgrades, missions through Prestige and the real day boundary, bulk evolution, Prestige celebration.
## Run: Godot --headless --path . res://tests/change_71_probe.tscn -- --probe --profile=probe-c71 --no-autosave --first-run-complete
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
    price_checks()
    await inventory_checks()
    await shop_checks()
    await follow_checks()
    tracker_text_checks()
    await hud_checks()
    boss_checks()
    mission_checks()
    evolve_checks()
    await prestige_fx_checks()
    SettingsState.reset_inventory_view();SettingsState.set_supply_buy_amount(1)
    print("CHANGE_71_CHECKS %d FAILURES %d" % [checks,failures])
    game.queue_free();await frames(2);AudioService.stop_all_sfx()
    get_tree().quit(1 if failures>0 else 0)

func fresh() -> void:
    get_tree().paused=false
    sim.held=false
    sim.new_profile();sim.set_physics_process(false);sim.suspended=false;SaveService.write_blocked=false
    sim.state.tutorial.mode="none"
    sim.campaign.onboarding.reveal_all(true)
    sim.state.tutorial.seen.append("road_ahead")
    game._close();game.banner.queue.clear();game.banner._finish();game.toast_queue.clear();game.get_node("Toast").hide()

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

# ---------------------------------------------------------------- Coin prices
func price_checks() -> void:
    print("-- Coin prices")
    fresh()
    var worst:=0.0;var worst_at:=""
    for id in sim.catalog.upgrades:
        var d: Dictionary=sim.catalog.upgrades[id]
        if d.currency!="coins" or int(d.cap)<2 or d.get("sequence",false):continue
        var targets: Array=[-1]
        match str(d.scope):
            "type","normal_type","boss_type":
                targets=[]
                for g in range(sim.catalog.groups.size()):
                    if sim._upgrade_scope_valid(id,g):targets.append(g)
            "stage":targets=range(1,9)
            "camp":targets=[11,21,41,81]
        for g in targets:
            var key: String=sim._upgrade_key(id,g)
            var before:=0
            for n in range(int(d.cap)):
                sim.state.upgrades[key]=n # fixture: level n
                var price: int=sim.upgrade_cost(id,g)
                if n>0 and before>0 and float(price)/before>worst:
                    worst=float(price)/before;worst_at="%s g%d L%d->%d (%d->%d)" % [id,g,n,n+1,before,price]
                before=price
            sim.state.upgrades.erase(key)
    check(worst<=1.8,"No Coin upgrade costs more than x1.8 the level before (worst x%.2f at %s)" % [worst,worst_at])
    # The reported cliff: Enemy XP on a Winter II type, levels 5 -> 6 (was 38 -> 209).
    var g2:=-1
    for g in range(sim.catalog.groups.size()):
        if int(sim.catalog.groups[g].stage)==2 and not sim.catalog.groups[g].boss:g2=g;break
    var prices: Array=[]
    for n in range(10):
        sim.state.upgrades["group_xp:%d" % g2]=n
        prices.append(sim.upgrade_cost("group_xp",g2))
    sim.state.upgrades.erase("group_xp:%d" % g2)
    print("    group_xp on %s: %s" % [sim.catalog.groups[g2].id,str(prices)])
    check(prices[0]==10 and prices[2]==19 and prices[4]==60 and prices[5]==105 and prices[8]==572,"Enemy XP Winter II: cheap start, smooth middle, full price from level 9 (%s)" % str(prices))
    # One price for the card, the purchase and the deduction; kept through Prestige.
    sim.state.coins=100000.0;sim.state.discovered[str(g2)]=true;sim.state.unlocked_stage=2 # fixture: Winter II reached
    for n in range(6):
        var cost: int=sim.upgrade_cost("group_xp",g2)
        var coins: float=float(sim.state.coins)
        check(sim.buy_upgrade("group_xp",g2) and is_equal_approx(coins-float(sim.state.coins),cost),"Purchase %d charges the displayed %d" % [n+1,cost])
    var level: int=sim.level("group_xp",g2);var next: int=sim.upgrade_cost("group_xp",g2)
    check(do_prestige() and sim.level("group_xp",g2)==level and sim.upgrade_cost("group_xp",g2)==next,"Prestige keeps the level and the next price (%d)" % next)

# ---------------------------------------------------------------- main inventory organisation
func inventory_fixture() -> void:
    fresh()
    sim.state.upgrades["gear_slots"]=6;sim.state.gear.resize(sim.equipment_slot_count());sim.state.gear.fill("") # fixture: 9 slots
    for pair in [["wood_sword",3],["unit-blue-cap_outfit",12],["stone_axe",1],["skill_heal",2],["wood_axe",7],["unit-red-scarf_outfit",7]]:
        sim.add_item(pair[0],pair[1],false,false)
    sim.equip("wood_sword")
    game._set_inventory_view(0,0)

func shown_ids() -> Array:
    var grid: Node=game.dock.get_node("Inventory/GearColumn/GearScroll/Gear")
    var ids: Array=[]
    for p in range(grid.get_child_count()):
        if grid.get_child(p).visible:ids.append(sim.state.gear[game.gear_view[p]])
    return ids

func inventory_checks() -> void:
    print("-- Main inventory organisation")
    await inventory_fixture()
    await frames(3)
    var gear_before: Array=sim.state.gear.duplicate()
    check(shown_ids()==sim.state.gear,"Default + All: the dock is the slot order (empties included)")
    game._set_inventory_view(0,3);await frames(2)
    var by_qty: Array=shown_ids().filter(func(i):return i!="")
    check(by_qty==["unit-blue-cap_outfit","wood_axe","unit-red-scarf_outfit","wood_sword","skill_heal","stone_axe"],"Quantity: 12, 7, 7 (slot order breaks the tie), 3, 2, 1 (%s)" % str(by_qty))
    check(shown_ids().slice(by_qty.size()).all(func(i):return i==""),"Empty slots follow the items")
    check(sim.state.gear==gear_before,"Sorting never moves an owned item")
    # Taps resolve through the view: position 1 is the Wood Axe, wherever its slot is.
    game._select_view_slot(0,1);await frames(2)
    check(game.panel=="item" and game.selected=="wood_axe","Hold on the 2nd shown slot opens the Wood Axe")
    game._close();await frames(1)
    game._activate_view_slot(0,0);await frames(2)
    check(game.panel=="item" and game.selected=="unit-blue-cap_outfit","Tap on the 1st shown slot opens the Blue Cap Outfit")
    var browse: Array=game._browse_list()
    check(browse==by_qty,"Browsing follows the shown order")
    game._close()
    check(game.inventory_sort==3 and SettingsState.inventory_sort==3,"Closing the panel keeps the sort")
    game._set_inventory_view(1,1);await frames(2)
    check(shown_ids().filter(func(i):return i!="").all(func(i):return sim.catalog.items[i].kind=="weapon"),"Weapons + Tier shows only weapons")
    var slot: Control=game.guide._slot("stone_axe")
    check(slot!=null and slot==game.gear_slot_node(sim.state.gear.find("stone_axe")),"The guide points at the item's shown slot")
    check(game.guide._slot("unit-blue-cap_outfit")==game.dock.get_node("Inventory/GearColumn/Head/Filters"),"An item the category hides points the guide at Filters")
    check(game.dock.get_node("Inventory/GearColumn/Head/Filters").text.begins_with(tr("WEAPONS")),"The dock button names the saved category")
    # Merge through the item panel acts on the shown item.
    game._activate_view_slot(0,0);await frames(2)
    var first: String=game.selected
    check(sim.catalog.items[first].kind=="weapon","The first shown slot is a weapon (%s)" % first)
    game._close()
    # Evolution: an item ready to evolve ranks first.
    sim.state.items["wood_axe"].merge=int(sim.catalog.progression.evolution.required_merge) # fixture: ^20
    sim.add_item("wood_axe",sim.evolution_spare_cost("wood_axe"),false,false)
    game._set_inventory_view(0,2);await frames(2)
    check(shown_ids()[0]=="wood_axe" and sim.evolve_block_reason("wood_axe").is_empty(),"Evolution: the ready Wood Axe ranks first")
    # Persistence: disk save and reload, older settings, Prestige, Hard Reset.
    game._set_inventory_view(2,3)
    check(SaveService.save_now(),"Disk save")
    SettingsState.inventory_filter=0;SettingsState.inventory_sort=0
    SaveService.load_and_apply();await frames(2)
    check(SettingsState.inventory_filter==2 and SettingsState.inventory_sort==3,"Reload restores Outfits + Quantity")
    var old: Dictionary=SettingsState.to_save_dict();old.erase("inventory_filter");old.erase("inventory_sort");old.erase("supply_buy_amount")
    SettingsState.from_save_dict(old)
    check(SettingsState.inventory_filter==0 and SettingsState.inventory_sort==0 and SettingsState.supply_buy_amount==1,"Older settings load All / Default / x1")
    SettingsState.from_save_dict({"inventory_filter":9.0,"inventory_sort":-3,"supply_buy_amount":"x"})
    check(SettingsState.inventory_filter==3 and SettingsState.inventory_sort==0 and SettingsState.supply_buy_amount==1,"Out-of-range values are clamped or defaulted")
    game._set_inventory_view(1,2)
    check(do_prestige() and SettingsState.inventory_filter==1 and SettingsState.inventory_sort==2,"Prestige keeps the organisation")
    check(SaveService.hard_reset() and SettingsState.inventory_filter==0 and SettingsState.inventory_sort==0,"Hard Reset returns All / Default")
    game.get_node("Safe").remove_theme_constant_override("margin_top")

# ---------------------------------------------------------------- Supplies shop
func shop_checks() -> void:
    print("-- Supplies shop")
    fresh()
    SettingsState.set_supply_buy_amount(1)
    var unit:=int(sim.supply("potion").price)
    sim.state.coins=float(unit*5)
    check(sim.purchase_consumables("potion",5) and sim.quantity("potion")==5 and is_equal_approx(sim.state.coins,0.0),"x5 charges exactly 5 x %d and adds 5" % unit)
    check(sim.supply_mastery("potion")==0 and int(sim.state.supply_uses.get("potion",0))==0,"Buying gives no Supply Mastery")
    sim.state.coins=float(unit*5-1)
    check(not sim.purchase_consumables("potion",5) and sim.quantity("potion")==5 and is_equal_approx(sim.state.coins,unit*5-1.0),"One Coin short: nothing bought, nothing charged")
    check(sim.consumable_purchase_block("potion",5)=="NOT_ENOUGH_COINS","…and the reason is Not enough coins")
    sim.state.coins=1e9
    for n in [0,-5,1000]:
        check(not sim.purchase_consumables("potion",n) and sim.quantity("potion")==5 and is_equal_approx(sim.state.coins,1e9),"Invalid amount %d is refused without change" % n)
    # The single supply slot holds the potion: another supply has no room.
    check(sim.consumable_purchase_block("coin_boost",1)=="INVENTORY_FULL" and not sim.purchase_consumables("coin_boost",3) and sim.quantity("coin_boost")==0 and is_equal_approx(sim.state.coins,1e9),"No free supply slot: refused, nothing charged")
    check(sim.purchase_consumable("potion") and sim.quantity("potion")==6,"The single purchase still buys one")
    # Saved quantity, shared by every card; the UI buys exactly that many.
    SettingsState.set_supply_buy_amount(25)
    check(SaveService.save_now(),"Disk save")
    SettingsState.supply_buy_amount=1;SaveService.load_and_apply()
    check(SettingsState.supply_buy_amount==25,"The chosen x25 survives a reload")
    sim.state.coins=float(unit*25)
    game.player_tab=2;game._open("upgrades");await frames(4)
    var buy: Button=null
    var chips: Array=[]
    for b in game.rows.find_children("*","Button",true,false):
        if b.get_meta("guide","")=="buy_supply_potion":buy=b
        if str(b.get_meta("guide","")).begins_with("supply_qty_"):chips.append(b)
    check(chips.size()==5 and chips.all(func(b):return b.size.y>=48),"Five quantity chips (x1 x5 x10 x25 Custom), touch-sized")
    check(chips.filter(func(b):return b.theme_type_variation==&"Primary").map(func(b):return b.get_meta("guide"))==["supply_qty_25"],"x25 is the highlighted choice")
    check(buy!=null and buy.text==tr("SHOP_BUY_N") % 25 and not buy.disabled,"The Buy button buys x25")
    var labels: String=" | ".join(game.rows.find_children("*","Label",true,false).map(func(l):return l.text))
    check(labels.contains(tr("SHOP_TOTAL") % [25,game.fmt_cost(unit*25)]) and labels.contains(tr("SHOP_UNIT_OWNED") % [game.fmt_cost(unit),"6"]),"Card shows unit price, owned and the total")
    var qty: int=sim.quantity("potion")
    buy.pressed.emit();await frames(2)
    check(sim.quantity("potion")==qty+25 and is_equal_approx(sim.state.coins,0.0) and SettingsState.supply_buy_amount==25,"Pressing Buy buys 25 at once and keeps x25")
    game._refresh_panel(true);await frames(2)
    for b in game.rows.find_children("*","Button",true,false):
        if b.get_meta("guide","")=="buy_supply_potion":buy=b
    check(buy.disabled,"Without Coins for 25 the Buy button is disabled (x25 is not lowered)")
    # Custom: steps keep the value inside 1..999.
    for b in game.rows.find_children("*","Button",true,false):
        if b.get_meta("guide","")=="supply_qty_custom":b.pressed.emit()
    await frames(2)
    var plus: Button=null
    for b in game.rows.find_children("*","Button",true,false):
        if b.text=="+10":plus=b
    check(plus!=null,"Custom shows the -10 -1 +1 +10 steps")
    if plus!=null:
        plus.pressed.emit();await frames(2)
        check(SettingsState.supply_buy_amount==35,"+10 makes x35 (saved)")
    SettingsState.set_supply_buy_amount(5000)
    check(SettingsState.supply_buy_amount==999,"Custom is bounded at 999")
    SettingsState.set_supply_buy_amount(1);game.supply_custom=false
    game._close()

# ---------------------------------------------------------------- Follow buttons
func follow_buttons() -> Array:
    return game.rows.find_children("*","Button",true,false).filter(func(b):return b.has_meta("follow_button"))

func follow_checks() -> void:
    print("-- Follow / Unfollow")
    fresh()
    sim.state.bosses_found.append("boss-snowman")
    sim.state.opportunities["expedition_o1"]={"ready":false,"baseline":{},"step":0,"count":3} # fixture: in progress
    sim.campaign.refresh_missions()
    var seen: Array=[]
    for surface in ["mastery","missions","prestige"]:
        game.mastery_stage=1
        game._open(surface);await frames(4)
        var buttons:=follow_buttons()
        check(not buttons.is_empty(),"%s offers Follow" % surface)
        if buttons.is_empty():continue
        var b: Button=buttons[0]
        check(b.text==tr("FOLLOW") and b.theme_type_variation==&"ToggleOff","%s: Follow is red (ToggleOff)" % surface)
        check(b.custom_minimum_size==game.FOLLOW_BUTTON_SIZE and b.size.x<game.rows.size.x*.6,"%s: compact button (%s), never card-wide" % [surface,b.size])
        b.pressed.emit();await frames(3)
        var on: Array=follow_buttons().filter(func(x):return x.text==tr("UNFOLLOW"))
        check(on.size()==1 and on[0].theme_type_variation==&"ToggleOn","%s: Unfollow is green (ToggleOn)" % surface)
        seen.append(surface)
        game._close()
    check(str(sim.state.follow_mastery)!="" and str(sim.state.follow_mission)!="" and str(sim.state.follow)!="","One Mastery, one mission and one Prestige follow at once")

# ---------------------------------------------------------------- compact trackers
func tracker_text_checks() -> void:
    print("-- Compact trackers")
    fresh()
    sim.state.opportunities["expedition_o1"]={"ready":false,"baseline":{},"step":0,"count":3} # fixture: step 1 of 3
    var full: String=sim.campaign.follow_summary("expedition_o1")
    var compact: String=sim.campaign.follow_summary("expedition_o1",true)
    var next_word: String=tr("FOLLOW_NEXT").get_slice("%",0)
    check(full.contains(next_word) and not compact.contains(next_word) and full.begins_with(compact),"Expedition: the panel keeps Next, the tracker does not")
    sim.state.follow="expedition_o1";game._refresh_follow_tracker()
    check(not game.get_node("Safe/Layout/Map/FollowTracker/Row/Text/Step").text.contains(next_word),"The HUD tracker shows the current step only")

# ---------------------------------------------------------------- HUD
func hud_fixture() -> void:
    fresh()
    sim.state.bosses_found.append("boss-snowman")
    var g: int=sim.nearest_group()
    sim.state.discovered[str(g)]=true;sim.campaign.discover_spot(g,0)
    game.combat_group=g
    sim.state.follow_mission="main:0"
    sim.state.opportunities["collection_o1"]={"ready":false,"baseline":{},"step":0,"count":0}
    sim.state.follow="collection_o1"
    sim.state.follow_mastery="1:hunt"
    sim.touch()

## The HUD lays out on its 0.15 s tick; headless frames are faster, so the probe runs the tick on each frame.
func hud_ticks(n:=4) -> void:
    for i in range(n):
        game.elapsed=1.0
        await frames(2)

func hud_checks() -> void:
    print("-- HUD layout")
    var map: Control=game.get_node("Safe/Layout/Map")
    check(game.get_node_or_null("Safe/Layout/Map/Objective")==null,"The permanent Winter I boss objective is gone")
    for lang in ["en","de_DE"]:
        LocalizationService.select_language("automatic" if lang=="en" else lang)
        for shape in [Vector2i(720,1280),Vector2i(720,1600),Vector2i(960,1280),Vector2i(720,1080)]:
            get_window().size=shape
            await frames(8)
            for stick in [0,1,2]:
                SettingsState.set_joystick_position(stick)
                await hud_fixture()
                await hud_ticks()
                var mini: Rect2=map.get_node("MiniMap").get_rect();var zoom: Rect2=map.get_node("Zoom").get_rect()
                var chip: Rect2=map.get_node("Mastery").get_rect();var explored: Rect2=map.get_node("Explored").get_rect();var gate: Rect2=map.get_node("Gate").get_rect()
                var tag:="%s %dx%d stick %d" % [lang,shape.x,shape.y,stick]
                var trackers: Array=[map.get_node("FollowTracker"),map.get_node("MissionTracker"),game.mastery_tracker].filter(func(t):return t.visible)
                if stick==1 and shape==Vector2i(720,1280):
                    check(mini.position.y<=20 and mini.end.x<=map.size.x-12 and mini.size.x>=160,"%s: minimap top-right, full size %s" % [tag,mini])
                    # Change 74: Map Explored is the minimap's caption under it; the zoom is a button beside the minimap (slider on demand).
                    check(absf(explored.end.x-mini.end.x)<=1 and explored.position.y>=mini.end.y and not map.get_node("Zoom").visible and map.get_node("ZoomButton").get_rect().end.x<=mini.position.x and chip.position.y>=explored.end.y and (not map.get_node("Gate").visible or gate.position.y>=chip.end.y),"%s: minimap (zoom button beside) -> Map Explored -> Mastery -> Next Stage" % tag)
                check(gate.end.x<=map.size.x+.5 and explored.end.x<=map.size.x+.5,"%s: status chips inside the map (gate %s, map %s)" % [tag,gate,map.size])
                check(trackers.size()==3,"%s: three trackers shown" % tag)
                var clearance: float=game.tracker_clearance()
                check(clearance>=8,"%s: trackers clear of the left controls by %.0f" % [tag,clearance])
                var stick_rect: Rect2=map.get_node("Joystick").get_rect()
                var overlap:=""
                for i in range(trackers.size()):
                    var r: Rect2=trackers[i].get_rect()
                    if r.intersects(stick_rect):overlap+=" stick %s/%s" % [r,stick_rect]
                    if r.end.y>map.size.y:overlap+=" below map %s" % r
                    for other in [mini,zoom,chip,explored]:
                        if r.intersects(other):overlap+=" stack %s/%s" % [r,other]
                    for j in range(i+1,trackers.size()):
                        if r.intersects(trackers[j].get_rect()):overlap+=" each other"
                check(overlap=="","%s: trackers clear of each other, the joystick and the map stack%s" % [tag,overlap])
                # A toast while the three trackers show: placed clear of every HUD column, or held.
                game._say("Auto Farm turned off");await hud_ticks(2)
                var toast: Control=game.get_node("Toast")
                var clear:=true
                if toast.visible:
                    for r in game._toast_blockers():
                        if r.intersects(toast.get_global_rect()):clear=false
                check(clear,"%s: the toast is clear of trackers and HUD columns (shown: %s)" % [tag,toast.visible])
                game.toast_queue.clear();toast.hide()
    LocalizationService.select_language("automatic")
    SettingsState.set_joystick_position(1)
    get_window().size=Vector2i(720,1280);await frames(3)

# ---------------------------------------------------------------- boss upgrades
func boss_checks() -> void:
    print("-- Boss upgrades")
    fresh()
    var rolls: Dictionary=sim.catalog.upgrades.boss_item_rolls
    for g in range(sim.catalog.groups.size()):
        if not sim.catalog.groups[g].boss:continue
        var base: float=float(sim.catalog.groups[g].respawn)
        var need:=ceili((base-15.0)/5.0)
        var key:="boss_spawn_cooldown:%d" % g
        sim.state.upgrades[key]=need-1 # fixture
        var ok: bool=not sim.upgrade_maxed("boss_spawn_cooldown",g) and sim.spawn_cooldown(g)>15.0
        sim.state.upgrades[key]=need
        ok=ok and sim.upgrade_maxed("boss_spawn_cooldown",g) and is_equal_approx(sim.spawn_cooldown(g),15.0)
        sim.state.upgrades[key]=need+3
        ok=ok and is_equal_approx(sim.spawn_cooldown(g),15.0)
        check(ok,"%s: %ds -> 15 s after %d levels, never below" % [sim.catalog.groups[g].id,int(base),need])
        sim.state.upgrades.erase(key)
        var prices: Array=[]
        for n in range(4):
            sim.state.upgrades["boss_item_rolls:%d" % g]=n
            prices.append(sim.upgrade_cost("boss_item_rolls",g))
        sim.state.upgrades["boss_item_rolls:%d" % g]=4
        check(prices==[25,35,50,100] and sim.upgrade_maxed("boss_item_rolls",g) and int(sim.group_upgrade_value("boss_item_rolls",g))==5,"%s: x2..x5 cost 25, 35, 50, 100 Gems, stop at x5" % sim.catalog.groups[g].id)
        sim.state.upgrades.erase("boss_item_rolls:%d" % g)
    check(rolls.currency=="gems" and rolls.get("flat",false),"Boss item rolls: flat Gem prices")

# ---------------------------------------------------------------- missions through Prestige and the day boundary
func mission_checks() -> void:
    print("-- Daily missions")
    fresh()
    sim.clock_override=1700000000.0 # fixture: a fixed day
    sim.state.missions=[];sim.campaign.refresh_missions()
    var m: Dictionary=sim.state.missions[0]
    m.progress=m.goal # fixture: complete, unclaimed
    sim.state.missions[1].progress=1 # fixture: partial
    var before: Array=sim.state.missions.duplicate(true)
    var coins: float=float(sim.state.coins)
    check(do_prestige(),"Prestige")
    check(sim.state.missions==before and is_equal_approx(float(sim.state.coins),coins),"Prestige keeps every mission (progress, rewards, claims) and pays none")
    sim.campaign.refresh_missions()
    check(sim.state.missions==before,"Same day after Prestige: no re-roll")
    var reward: float=float(sim.state.missions[0].coins)
    coins=float(sim.state.coins)
    check(sim.campaign.claim_mission(0) and is_equal_approx(float(sim.state.coins),coins+reward),"The finished mission pays once when claimed")
    check(not sim.campaign.claim_mission(0),"…and never twice")
    sim.clock_override+=86400.0 # the next calendar day
    sim.campaign.refresh_missions()
    check(sim.state.missions[0].day==sim.today() and not sim.state.missions[0].claimed,"Next day: the claimed mission is replaced")
    check(int(sim.state.missions[1].progress)==1,"…the unfinished one keeps its progress")
    sim.clock_override=-1.0

# ---------------------------------------------------------------- bulk evolution
func evolve_checks() -> void:
    print("-- Bulk evolution")
    fresh()
    var id:="wood_axe";var target: String=sim.catalog.items[id].next
    var cost: int=sim.evolution_spare_cost(id)
    sim.add_item(id,1+3*cost+1,false,false)
    sim.state.items[id].merge=int(sim.catalog.progression.evolution.required_merge) # fixture: ^20
    var counter: float=sim.campaign.counter("evolve")
    check(sim.evolution_bulk_count(id)==3,"1 kept + 3 x %d spare (+1 extra) = 3 evolutions" % cost)
    check(sim.evolve_all(id)==3 and sim.quantity(id)==2 and sim.quantity(target)==3,"Evolve all: 3 copies of %s, the source keeps 2" % target)
    check(sim.campaign.counter("evolve")==counter+3,"Mission credit counts all three")
    check(sim.evolve_all(id)==0 and sim.quantity(id)==2 and sim.quantity(target)==3,"Not enough copies: nothing changes")

# ---------------------------------------------------------------- Prestige celebration
func prestige_fx_checks() -> void:
    print("-- Prestige celebration")
    fresh()
    var fx=game.world.prestige_fx
    game._open("prestige");await frames(2)
    check(do_prestige(),"Prestige committed")
    var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SaveService.save_path())) if FileAccess.file_exists(SaveService.save_path()) else {}
    check(int(sim.state.prestiges)>=1 and not saved.is_empty(),"The Prestige is saved before any effect runs")
    await frames(2)
    check(fx.active and fx.visible and not game.sheet.visible,"The celebration plays with the Prestige panel closed")
    check(fx.icons.size()>=1 and fx.icons.size()<=fx.MAX_ICONS,"Path icons bounded (%d)" % fx.icons.size())
    var owned: Array=sim.state.owned_cards.duplicate()
    for i in range(48):sim.state.owned_cards.append(sim.catalog.campaign.cards.keys()[i % sim.catalog.campaign.cards.size()]) # fixture: a large collection
    fx.play()
    check(fx.icons.size()<=fx.MAX_ICONS and fx.stars.size()<=fx.MAX_STARS,"A large collection stays bounded (%d icons, %d stars)" % [fx.icons.size(),fx.stars.size()])
    sim.state.owned_cards=owned
    var prestiges: int=int(sim.state.prestiges)
    fx.seek(fx.IMPACT+.1);fx.stop();fx.play();fx.seek(fx.END-.01)
    check(int(sim.state.prestiges)==prestiges and fx.active,"Restarting or skipping the effect changes nothing in the game")
    fx._process(1.0)
    check(not fx.active and not fx.visible and fx.icons.is_empty(),"It ends cleanly")
    fx.play();sim.milestone.emit("reset","")
    check(not fx.active and not fx.visible,"A Hard Reset stops it")
