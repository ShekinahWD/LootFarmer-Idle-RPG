extends Node
var checks:=0
var failures:=0
var game
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        push_error(label_)
func _ready() -> void:call_deferred("run")
func frames() -> void:
    for i in range(5):await get_tree().process_frame
func run() -> void:
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate()
    add_child(game)
    var sim=game.sim
    sim.set_physics_process(false)
    sim.new_profile()
    sim.state.coins=1000000
    sim.state.gems=1000000.0
    check(sim.upgrade_cost("gem_chance")==50 and sim.upgrade_cost("gem_amount")==50,"Global gem starting prices")
    check(not sim.buy_upgrade("gem_chance",0) and not sim.buy_upgrade("gem_amount",2),"Per-type gem purchases are rejected")
    check(sim.buy_upgrade("gem_chance") and sim.buy_upgrade("gem_amount"),"Global upgrades purchased")
    for g in range(4):
        check(is_equal_approx(sim.gem_chance(g),.09),"Chance applies globally")
    check(is_equal_approx(sim.gem_amount(),1.5),"Amount is fractional")
    check(sim.upgrade_cost("gem_chance")==75 and sim.upgrade_cost("gem_amount")==75,"Global prices follow authored table")
    sim.state.group_kills[1]=25
    check(is_equal_approx(sim.gem_chance(1),.095) and is_equal_approx(sim.gem_chance(0),.09),"Achievements stay type-specific")
    sim.state.upgrades.gem_chance=12
    sim.state.upgrades.gem_amount=10
    check(sim.upgrade_maxed("gem_chance") and sim.upgrade_maxed("gem_amount"),"Global upgrades cap at approved levels")
    check(is_equal_approx(sim.gem_base_chance(),.20) and is_equal_approx(sim.gem_amount(),6),"Caps give 20 percent and six gems")
    sim.new_profile()
    var old: Dictionary=sim.snapshot()
    old.schema=3
    old.erase("focus_variant")
    old.gems=10.5
    old.upgrades={"gem_chance:0":2,"gem_amount:1":1,"focus:0":1}
    sim.restore(old)
    check(not SaveService.write_blocked and sim.state.schema==5,"Schema 3 migration accepted")
    check(is_equal_approx(sim.state.gems,82.5),"Old type gem purchases refunded exactly")
    check(sim.level("gem_chance")==0 and not sim.state.upgrades.has("gem_chance:0"),"Old purchases removed")
    var migrated: Dictionary=sim.snapshot()
    sim.restore(migrated)
    check(is_equal_approx(sim.state.gems,82.5),"Migrated reload never refunds twice")
    # Real gem reward rolls with deterministic RNG: every awarded amount stays 1.5.
    sim.state.upgrades.gem_amount=1
    var before: float=sim.state.gems
    sim.rng.seed=17
    for i in range(100):sim._reward(sim.state.enemies[0])
    var gained: float=sim.state.gems-before
    check(gained>0 and is_equal_approx(gained/1.5,round(gained/1.5)),"Reward path preserves fractional gems")
    game.gem_pickup_time=0
    game._show_gem_pickup(1.1)
    check(game.get_node("Safe/Layout/Map/GemPickup/Amount").text=="+1.10","Gem pickup displays fractions")
    sim.new_profile()
    sim.state.gems=1000
    sim.buy_upgrade("focus",0)
    for variant in range(3):
        sim.state.focus=-1
        check(sim.focus(0,variant),"Select specific farm variant")
        sim.state.player.x=180+variant*360
        sim.state.player.y=sim.catalog.groups[0].center[1]
        # Wrong variant is nearer; selection must still honor the chosen one.
        var target: Dictionary=sim._combat_target()
        check(not target.is_empty() and int(target.variant)==variant,"Only selected variant is acquired")
        check(is_equal_approx(sim.farming_position().x,180+variant*360),"Return destination matches camp column")
    sim.state.player.hp=0
    sim.state.player.respawn=0
    sim.step(.1)
    var distance: float=sim.position_of(sim.state.player).distance_to(sim.farming_position())
    sim.step(.6)
    check(sim.position_of(sim.state.player).distance_to(sim.farming_position())<distance,"Respawn returns toward selected variant")
    var focused: Dictionary=sim.snapshot()
    sim.restore(focused)
    check(sim.state.focus==0 and sim.state.focus_variant==2,"Selected variant survives save/load")
    sim.movement=Vector2.RIGHT
    sim.step(.1)
    check(sim.state.focus==-1,"Joystick cancels focused farming")
    sim.movement=Vector2.ZERO
    # Every generated identity has a unique chain and stable art.
    for root in ["sprout","robot","dinosaur","reaper","potion","coin_boost","iron_sword","death_scythe"]:
        var current: String=root
        while sim.catalog.items[current].next!="":
            var next: String=sim.catalog.items[current].next
            var source: Dictionary=sim.catalog.items[current]
            var target: Dictionary=sim.catalog.items[next]
            check(int(target.tier)==int(source.tier)+1 and sim.catalog.art_id(next)==root,"Stable identity/art and increasing tier")
            for stat in source.normal:
                var max_value: float=float(source.normal[stat][0])+100*float(source.get("merge_gain",{}).get(stat,float(source.normal[stat][1])*3))
                check(is_equal_approx(target.normal[stat][0],max_value*1.25),"New tier starts 25% above previous merge-100 base")
            current=next
        check(int(sim.catalog.items[current].tier)==7,"Evolution ends at tier seven")
    sim.new_profile()
    sim.add_item("sprout",101)
    sim.record("sprout").merge=100
    check(sim.evolve("sprout"),"Outfit evolves")
    var outfit: String=sim.catalog.items.sprout.next
    check(sim.quantity("sprout")==1 and sim.record("sprout").merge==100 and sim.quantity(outfit)==1 and sim.record(outfit).merge==0,"Evolution spends spare copies and preserves source")
    check(sim.equip(outfit),"Generated outfit equips")
    sim.state.gems=100
    sim.buy_upgrade("supply_slots")
    sim.add_item("potion",101)
    sim.record("potion").merge=100
    check(sim.evolve("potion"),"Consumable evolves")
    var potion: String=sim.catalog.items.potion.next
    check(is_equal_approx(sim.normal(potion).heal,62.5),"Potion tier 2 heals 62.5 base")
    sim.state.player.hp=1
    check(sim.use_item(potion) and is_equal_approx(sim.state.player.hp,63.5),"Evolved potion uses its actual stats")
    sim.state.upgrades["merge_gear:0"]=1
    check(sim.can_auto_merge(outfit),"Evolved outfit inherits source-type auto merge")
    sim.state.upgrades.merge_supplies=1
    check(sim.can_auto_merge(potion),"Evolved consumable inherits player auto merge")
    var save: Dictionary=sim.snapshot()
    sim.restore(JSON.parse_string(JSON.stringify(save)))
    check(not SaveService.write_blocked and sim.quantity(outfit)==1,"Generated identities survive validation and save/load")
    await frames()
    check(game.world.views.player.body_texture.resource_path==sim.catalog.items.sprout.texture,"Evolved outfit retains in-world art")
    check(game._tier_color("sprout")!=game._tier_color(outfit),"Tier colors differ")
    var colors: Array=[]
    for hex in sim.catalog.progression.tier_colors:
        check(not colors.has(hex),"Every tier color is distinct")
        colors.append(hex)
    var upgrades=game.get_node("Safe/Layout/Map/EnemyUpgrades")
    var achievements=game.get_node("Safe/Layout/Map/Achievement")
    check(upgrades.position.y>=achievements.position.y+achievements.size.y and upgrades.position.x==achievements.position.x,"Upgrades sit beneath achievements")
    game.player_tab=3
    game._open("upgrades")
    await frames()
    check(game.action_buttons.size()==2 and game.action_buttons[0].group==-1,"Global gem tab contains two global upgrades")
    game.group=0
    game.enemy_tab=1
    game._open("enemy")
    for action in game.action_buttons:check(action.id not in ["gem_chance","gem_amount"],"Enemy upgrade tab contains no gem upgrade")
    sim.new_profile()
    sim.state.gems=100
    sim.buy_upgrade("supply_slots")
    sim.add_item("coin_boost",101)
    sim.record("coin_boost").merge=100
    check(sim.evolve("coin_boost"),"Tonic evolves")
    var tonic: String=sim.catalog.items.coin_boost.next
    check(sim.use_item(tonic) and is_equal_approx(sim.state.boost_power,.6875),"Evolved tonic uses its higher potency")
    sim.add_item(tonic,1)
    sim.state.upgrades.auto_use=1
    sim.bind_auto(sim.state.supplies.find(tonic))
    sim._automate(10.1)
    check(sim.quantity(tonic)==0 and sim.state.boost_time==60,"Auto use recognizes evolved tonic family")
    sim.new_profile()
    sim.add_item("sprout_tier_7",101)
    sim.record("sprout_tier_7").merge=100
    check(not sim.evolve("sprout_tier_7") and sim.quantity("sprout_tier_7")==101,"Tier seven cannot evolve or consume stock")
    # Full inventory must not spend evolution stock.
    sim.new_profile()
    sim.add_item("sprout",101)
    sim.record("sprout").merge=100
    sim.add_item("robot")
    sim.add_item("dinosaur")
    check(not sim.evolve("sprout") and sim.quantity("sprout")==101,"Full gear inventory refuses evolution atomically")
    sim.new_profile()
    sim.state.victory=true
    sim.state.offer=["hp"]
    sim.state.upgrades={"gem_chance":2,"gem_amount":2}
    sim.state.group_kills=[25,0,0,0]
    check(sim.prestige("hp") and sim.level("gem_chance")==0 and sim.level("gem_amount")==0 and sim.state.group_kills[0]==25,"Prestige resets global gem upgrades but keeps achievements")
    print("EVOLUTION_FARMING_PROBE checks=%d failures=%d" % [checks,failures])
    game.queue_free()
    await frames()
    get_tree().quit(1 if failures else 0)
