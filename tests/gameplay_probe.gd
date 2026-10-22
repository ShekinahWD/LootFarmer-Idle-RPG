extends Node
## Core gameplay rules (consolidated in Change 11 from the legacy gameplay, progression and change_1
## probes; obsolete contracts such as selling, the old victory/offer prestige, potion merging and
## schema-4 refunds were removed with their features). A standalone simulation, no UI: inventory
## identity and evolution, supply use rules, attack timing and single contact, reload safety,
## respawn, pause and suspension, Prestige retention, invalid saves, leash and regeneration,
## automation (collection, auto-merge, auto-use), spawn upgrades, focus, variant loadouts and XP.
var sim: LootSimulation
var checks:=0
var failures: Array[String]=[]

func check(value: bool,description: String) -> void:
    checks+=1
    if not value:
        failures.append(description)
        push_error(description)
    else:print("  ok  ",description)

func _ready() -> void:
    call_deferred("run")

func reset() -> void:
    get_tree().paused=false
    sim.new_profile()
    sim.state.tutorial.mode="none";sim.suspended=false # fixture: onboarding chooser answered
    sim.rng.seed=12345

## sim.step() clamps each call to 0.1 s (frame-spike safety), so longer spans run as 0.1 s steps.
func advance(seconds: float) -> void:
    var left:=seconds
    while left>.0001:
        sim.step(minf(.1,left))
        left-=.1

func ready_prestige() -> void:
    sim.state.group_kills[sim.campaign.prestige_unlock_group()]=1 # fixture: first boss defeated
    sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0} # fixture: one ready

func run() -> void:
    check(BootContext.is_probe and BootContext.profile_name.begins_with("probe-"),"Probe is isolated before save load")
    sim=LootSimulation.new()
    add_child(sim)
    sim.set_physics_process(false)
    inventory_rules()
    supply_rules()
    combat_rules()
    respawn_and_clock_rules()
    await prestige_rules()
    world_rules()
    automation_rules()
    variant_rules()
    print("GAMEPLAY_PROBE checks=%d failures=%d" % [checks,failures.size()])
    get_tree().quit(0 if failures.is_empty() else 1)

func inventory_rules() -> void:
    reset()
    check(sim.add_item("wood_sword",4),"Acquire initial weapon stack")
    var extras: Dictionary=sim.record("wood_sword").extras.duplicate()
    sim.equip("wood_sword")
    sim.merge("wood_sword",true)
    check(sim.quantity("wood_sword")==1 and sim.record("wood_sword").merge==3,"Three duplicates yield three merges and one retained copy")
    check(sim.record("wood_sword").extras==extras,"Merge never changes extra stats")
    sim.add_item("unit-blue-cap_outfit")
    sim.add_item("unit-red-scarf_outfit")
    check(not sim.add_item("iron_sword"),"Full equipment row rejects a new identity")
    check(sim.add_item("wood_sword"),"Full equipment row still stacks an existing identity")
    reset()
    sim.add_item("wood_sword",201)
    sim.merge("wood_sword",true)
    sim.equip("wood_sword")
    check(sim.record("wood_sword").merge==100 and sim.quantity("wood_sword")==101,"Weapon merge cap ^100 keeps evolution stock")
    check(not sim.merge("wood_sword"),"At cap merge consumes nothing")
    check(sim.evolve("wood_sword"),"Eligible evolution succeeds")
    check(sim.quantity("wood_sword")==1 and sim.quantity("stone_sword")==1 and sim.state.weapon=="wood_sword","Evolution keeps the source equipped and creates one target")
    check(sim.record("wood_sword").merge==100 and sim.record("stone_sword").merge==0,"Evolution keeps each identity's progression")
    sim.add_item("wood_sword",100)
    sim.record("stone_sword").merge=9
    var target_extras: Dictionary=sim.record("stone_sword").extras.duplicate()
    sim.evolve("wood_sword")
    check(sim.record("stone_sword").merge==9 and sim.record("stone_sword").extras==target_extras,"Existing target merge and roll survive evolution")
    reset()
    sim.add_item("wood_sword",201)
    sim.merge("wood_sword",true)
    sim.add_item("unit-blue-cap_outfit")
    sim.add_item("unit-red-scarf_outfit")
    check(not sim.evolve("wood_sword") and sim.quantity("wood_sword")==101,"Full row blocks evolution before spending")

func supply_rules() -> void:
    reset()
    sim.add_item("potion",2)
    var maxhp: float=sim.stats().hp
    sim.state.player.hp=maxhp*.8
    check(not sim.use_item("potion") and sim.quantity("potion")==2,"Exactly 80 percent HP rejects a potion without spending")
    sim.state.player.hp=maxhp*.8-.1
    check(sim.use_item("potion") and sim.quantity("potion")==1,"Below 80 percent uses one potion")
    sim.state.player.hp=maxhp*.3
    check(not sim.use_item("potion"),"Cooldown prevents a second use")
    sim.state.supplies.append("")
    sim.add_item("coin_boost",2,false) # fixture: bought copies (stock only, mastery ^0)
    check(sim.use_item("coin_boost") and is_equal_approx(sim.state.boost_time,30) and is_equal_approx(sim.state.boost_power,.25),"Coin Tonic: +25% coins for 30 s")
    check(not sim.use_item("coin_boost") and sim.quantity("coin_boost")==1,"A running Coin Tonic is not wasted by a second use")

func combat_rules() -> void:
    reset()
    var enemy: Dictionary=sim.state.enemies[0]
    sim.campaign.reveal_circle(sim.position_of(enemy),120) # fixture: this ground is explored (fog, Change 8)
    sim.state.player.x=enemy.x-25
    sim.state.player.y=enemy.y
    advance(.49)
    check(enemy.hp==sim.enemy_definition(0,0).hp,"Stop-to-attack delay prevents early damage")
    sim.step(.02)
    check(sim.state.player.windup>0,"Attack starts after half a second")
    var before_hp: float=enemy.hp
    sim.movement=Vector2.DOWN
    advance(.3)
    check(enemy.hp==before_hp and sim.state.player.windup==0,"Manual movement cancels pending contact")
    sim.movement=Vector2.ZERO
    sim.state.player.x=enemy.x-25
    sim.state.player.y=enemy.y
    advance(1.01)
    advance(.23)
    var after: float=enemy.hp
    sim.step(.01)
    check(after<before_hp and is_equal_approx(enemy.hp,after),"Contact resolves once")
    var assisted:=false
    for other in sim.state.enemies:
        if other.group==0 and other.id!=enemy.id and other.aggro:assisted=true
    check(not assisted,"A passive first type does not alert its neighbours")
    enemy.hp=1
    sim.state.player.cooldown=0.0
    advance(.6)
    advance(.3)
    check(enemy.hp<=0,"Contact kills a weakened enemy")
    var earned: float=sim.state.coins
    var xp: float=sim.state.xp
    advance(.5)
    check(sim.state.coins==earned and sim.state.xp==xp,"A kill rewards only once")
    var snap:=sim.snapshot()
    sim.restore(snap)
    sim.step(.1)
    check(sim.state.coins==earned and sim.state.enemies[0].hp<=0,"Reload does not resurrect or reward a killed enemy")

func respawn_and_clock_rules() -> void:
    reset()
    sim.state.player.hp=0
    sim._kill(sim.state.player)
    advance(9)
    check(sim.state.player.hp==0,"Respawn respects the ten second delay")
    advance(1.01)
    var camp: Array=sim.campaign.stage().spawns[int(sim.state.spawn)]
    check(sim.state.player.hp==sim.stats().hp and is_equal_approx(sim.state.player.y,float(camp[1])),"Respawn restores HP at the selected camp")
    check(sim.state.coins==0 and sim.state.gems==0,"Death costs no currency")
    reset()
    sim._drop("wood_sword",sim.state.player)
    var time: float=sim.state.clock
    var ttl: float=sim.state.pickups[0].ttl
    get_tree().paused=true
    sim.step(100)
    check(sim.state.clock==time and sim.state.pickups[0].ttl==ttl,"Explicit pause freezes all simulation clocks")
    get_tree().paused=false
    sim.suspended=true
    sim.step(100)
    check(sim.state.clock==time,"Background suspension does not simulate")
    sim.suspended=false
    advance(301)
    check(sim.state.pickups.is_empty(),"Ground loot expires after 300 s of simulated time")

func prestige_rules() -> void:
    reset()
    sim.state.coins=123
    sim.state.gems=45
    sim.state.upgrades={"collect:0":1,"collect_range:0":2,"gear_slots":1,"respawn":3,"loot:0":2,"auto_use":1}
    sim.state.gear.append("")
    sim.state.auto_slots=[0]
    sim.state.camps["1"]=[0,1];sim.state.spawns=sim.state.camps["1"]
    sim.state.spawn=1
    sim.state.focus=1
    sim.add_item("wood_sword",5)
    ready_prestige()
    check(sim.campaign.begin_prestige(),"Prestige batch begins")
    var card: String=sim.campaign.offered_cards()[0]
    check(sim.prestige(card),"Prestige commits a durable new run")
    check(sim.state.coins==0 and sim.state.gems==0 and sim.state.items.is_empty(),"Prestige resets the run economy and items")
    check(sim.level("collect",0)==1 and sim.level("collect_range",0)==2 and sim.level("auto_use")==1 and sim.state.gear.size()==4,"Prestige keeps automation levels and capacity")
    check(sim.level("respawn")==0 and sim.level("loot",0)==0 and sim.state.spawn==0 and sim.state.camps["1"]==[0],"Prestige clears coin run upgrades and camps")
    check(sim.state.auto_slots.is_empty() and sim.state.focus==-1,"Prestige clears unsafe automation bindings")
    check(sim.state.owned_cards.count(card)==1 and sim.state.prestiges==1,"The card is owned exactly once")
    check(not sim.campaign.begin_prestige(),"The same opportunity cannot prestige again")
    SaveService.load_and_apply()
    await get_tree().process_frame
    check(sim.state.owned_cards.has(card) and sim.state.prestiges==1,"Prestige survives reloading")
    get_tree().paused=true
    check(SaveService.hard_reset(),"Hard Reset commits from pause")
    check(not get_tree().paused and sim.state.owned_cards.is_empty() and sim.state.prestiges==0,"Hard Reset clears progression and resumes")
    SaveService.load_and_apply()
    await get_tree().process_frame
    check(sim.state.owned_cards.is_empty(),"Reset backup does not resurrect cards")
    check(TranslationServer.get_locale().begins_with("en"),"English-only gate remains active")
    reset()
    var malformed:=sim.snapshot()
    malformed.items={"wood_sword":{"qty":2,"merge":101,"extras":{}}}
    sim.restore(malformed)
    check(SaveService.last_load_result=="invalid_profile_reset" and sim.state.items.is_empty() and not SaveService.write_blocked,"An invalid profile loads as a fresh, writable profile (pre-release policy)")

func world_rules() -> void:
    reset()
    var guard: Dictionary=sim.state.enemies[4]
    guard.x=guard.home_x+250
    guard.y=guard.home_y
    guard.aggro=true
    sim.state.player.x=guard.x-10
    sim.state.player.y=guard.y
    sim.step(.1)
    check(guard.returning and not guard.aggro,"A leashed enemy returns home")
    var half: float=float(sim.enemy_definition(int(guard.group),int(guard.variant)).hp)*.5
    guard.hp=half
    guard.quiet=4.9
    advance(.3)
    check(guard.hp>half,"An enemy regenerates after five seconds without a hit")
    reset()
    sim.state.upgrades={"focus:1":1}
    sim.campaign.discover_spot(1,2) # fixture: auto-farm only walks to found spots
    check(sim.focus(1),"Focus on a found spot")
    sim.state.player.hp=0
    sim._kill(sim.state.player)
    advance(10.1)
    var start_y: float=sim.state.player.y
    advance(1.1)
    check(sim.state.player.y<start_y and sim.state.focus==1,"Focus resumes travel after respawn")
    sim.movement=Vector2.RIGHT
    sim.step(.1)
    check(sim.state.focus==-1,"Manual movement cancels focus")
    sim.movement=Vector2.ZERO

func automation_rules() -> void:
    reset()
    sim.state.upgrades={"collect:0":1,"merge_gear:0":1,"auto_use":1}
    sim.add_item("wood_sword",3)
    sim.add_item("potion",2)
    sim.bind_auto(0)
    sim.state.player.hp=40
    sim._drop("wood_sword",{"group":0,"x":sim.state.player.x,"y":sim.state.player.y}) # a type 0 drop
    sim._automate(10.1)
    check(sim.state.pickups.is_empty() and sim.record("wood_sword").merge==1,"Collection and gear auto-merge use shared inventory rules")
    check(sim.quantity("potion")==1 and sim.state.player.hp>40,"Bound auto-use drinks a potion on its scheduled check")
    reset()
    sim.state.upgrades={"collect:0":1}
    var at:={"group":0,"x":sim.state.player.x,"y":sim.state.player.y}
    sim._drop("wood_sword",at)
    sim._drop("stone_sword",{"group":1,"x":at.x,"y":at.y})
    sim._drop("potion",{"group":1,"x":at.x,"y":at.y})
    sim._automate(9.9)
    check(sim.quantity("wood_sword")==0,"No collection before ten seconds")
    sim._automate(.1)
    check(sim.quantity("wood_sword")==1 and sim.quantity("stone_sword")==0 and sim.quantity("potion")==0,"A type's collector takes only that type's drops")
    sim.state.upgrades["collect:1"]=1;sim.state.upgrades["collect_batch:1"]=1
    sim._automate(10)
    check(sim.quantity("stone_sword")==1 and sim.quantity("potion")==1,"Each type's collector and batch work independently")
    reset()
    sim.state.gems=1e6
    sim.campaign.discover_spot(0,0)
    for i in range(3):sim.buy_upgrade("spawn_amount",0)
    check(sim.spawn_amount(0)==6 and not sim.buy_upgrade("spawn_amount",0),"Spawn amount caps at six")
    for variant in sim.campaign.variants(0):
        check(sim.state.enemies.filter(func(e):return int(e.group)==0 and int(e.variant)==variant).size()==6,"Six real actors on spot %d" % variant)
    for i in range(5):sim.buy_upgrade("spawn_cooldown",0)
    var actor: Dictionary=sim.state.enemies.filter(func(a: Dictionary)->bool:return int(a.group)==0)[0]
    sim._kill(actor)
    check(is_equal_approx(actor.respawn,float(sim.catalog.groups[0].respawn)*.5),"A death uses the upgraded respawn time")
    var boss:=sim.campaign.prestige_unlock_group()
    check(not sim.buy_upgrade("spawn_amount",boss) and sim.spawn_amount(boss)==1,"Bosses have no spawn upgrades")

func variant_rules() -> void:
    reset()
    var armor:=sim.enemy_definition(0,0)
    var weapon:=sim.enemy_definition(0,1)
    var both:=sim.enemy_definition(0,2)
    check(armor.hp>weapon.hp and armor.damage<weapon.damage,"Outfit-only enemies are tougher, weapon-only ones hit harder")
    check(armor.loot==[armor.body] and armor.weapon=="","Outfit-only spot drops only its outfit")
    check(weapon.loot==[weapon.weapon] and weapon.body=="","Weapon-only spot drops only its weapon")
    check(both.loot.has(both.body) and both.loot.has(both.weapon),"A full loadout drops both")
    var e: Dictionary=sim.state.enemies[0]
    for variant in [0,1,2]:
        sim.state.pickups=[]
        e.variant=variant
        for i in range(100):sim._reward(e)
        var valid:=true
        for drop in sim.state.pickups:
            if sim.catalog.items[drop.item].kind!="consumable" and not sim.enemy_definition(0,variant).loot.has(drop.item):valid=false
        check(valid,"Reward rolls respect the worn loadout %d" % variant)
    reset()
    check(sim.stats().hp==100 and sim.stats().damage==5,"Level one base")
    sim.gain_xp(12)
    check(sim.state.player_level==2 and sim.state.xp==0,"Exact XP threshold")
    check(sim.stats().hp==105 and sim.stats().damage==5.5 and sim.state.player.hp==105,"A level adds HP capacity and damage")
