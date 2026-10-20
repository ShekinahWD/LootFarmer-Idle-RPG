extends Node
var checks:=0
var failures:=0
var game
func check(ok: bool,message: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        push_error(message)
func _ready() -> void:
    call_deferred("run")
func run() -> void:
    game=load("res://scenes/game/main.tscn").instantiate()
    add_child(game)
    var sim: LootSimulation=game.sim
    sim.set_physics_process(false)
    sim.new_profile()
    await get_tree().process_frame
    await get_tree().process_frame
    check(sim.state.enemies.size()==28,"Three variants with three enemies per tier and one boss")
    for tier in range(3):
        var armor:=sim.enemy_definition(tier,0)
        var weapon:=sim.enemy_definition(tier,1)
        var both:=sim.enemy_definition(tier,2)
        check(armor.hp>weapon.hp and armor.damage<weapon.damage,"Enemy specialization %d" % tier)
        check(both.hp==armor.hp and both.damage==weapon.damage,"Combined advantages %d" % tier)
        check(armor.loot==[armor.body] and armor.weapon=="","Outfit-only drop %d" % tier)
        check(weapon.loot==[weapon.weapon] and weapon.body=="","Weapon-only drop %d" % tier)
        check(both.loot.has(both.body) and both.loot.has(both.weapon),"Combined worn drops %d" % tier)
        if tier>0:
            check(weapon.hp>sim.enemy_definition(tier-1,2).hp,"Next tier requires progression %d" % tier)
    var boss:=sim.enemy_definition(3)
    check(boss.loot==[boss.weapon,boss.body],"Boss drops its visible equipment")
    check(sim.stats().hp==100 and sim.stats().damage==5,"Level one base")
    sim.gain_xp(12)
    check(sim.state.player_level==2 and sim.state.xp==0,"Exact XP threshold")
    check(sim.stats().hp==105 and sim.stats().damage==5.5,"Level increases only base HP and damage")
    check(sim.state.player.hp==105,"Level up adds new health capacity")
    sim.gain_xp(100)
    check(sim.state.player_level>2 and sim.state.xp<sim.xp_required(),"Multi-level XP carry")
    sim.state.player_level=999
    sim.state.xp=0.0
    sim.touch()
    sim.gain_xp(sim.xp_required()*4)
    check(sim.state.player_level==1000 and sim.state.xp==0,"Level cap discards surplus XP")
    sim.gain_xp(999)
    check(sim.state.xp==0,"No XP growth at cap")
    sim.new_profile()
    sim.add_item("wood_sword",4)
    sim.record("wood_sword").extras={"crit":.02}
    sim.touch()
    check(is_equal_approx(sim.stats().damage,5.9),"Stored weapon contributes 30 percent once")
    check(is_equal_approx(sim.stats().crit,.056),"Stored extras contribute 30 percent")
    sim.merge("wood_sword",true)
    check(is_equal_approx(sim.stats().damage,5+3.36*.3),"Stored merge stats update")
    sim.equip("wood_sword")
    check(is_equal_approx(sim.stats().damage,8.36),"Equipped weapon gets 100 percent without double count")
    sim.add_item("iron_sword")
    sim.equip("iron_sword")
    check(is_equal_approx(sim.stats().damage,27+3.36*.3),"Swap recalculates both contributions")
    sim.sell("wood_sword",true)
    check(is_equal_approx(sim.stats().damage,27),"Selling last stored weapon removes contribution")
    sim.add_item("sprout")
    check(sim.stats().hp==100,"Stored outfits do not contribute")
    var save:=sim.snapshot()
    sim.new_profile()
    sim.restore(save)
    check(not SaveService.write_blocked and sim.state.weapon=="iron_sword","New save round trip")
    save.schema=1
    save.erase("xp")
    save.erase("player_level")
    sim.restore(save)
    check(not SaveService.write_blocked and sim.state.player_level==1 and sim.quantity("iron_sword")==1 and sim.state.enemies.size()==28,"Legacy migration preserves items and rebuilds map")
    sim.gain_xp(100)
    sim.state.victory=true
    sim.state.offer=["hp"]
    check(sim.prestige("hp") and sim.state.player_level==1 and sim.state.xp==0 and sim.stats().hp==105,"Prestige resets level and retains card")
    sim.new_profile()
    sim.state.player.x=180
    sim.state.player.y=1150
    var e: Dictionary=sim.state.enemies[0]
    e.hp=1
    e.x=180
    e.y=1150
    sim._start_attack(sim.state.player,e,1)
    sim._resolve_attack(sim.state.player,.23)
    var xp: float=sim.state.xp
    var coins: int=sim.state.coins
    sim._resolve_attack(sim.state.player,1)
    check(e.hp==0 and xp>0 and sim.state.coins==coins and sim.state.xp==xp,"Contact kills and rewards only once")
    # Sample independent loot rolls; all gear must belong to this variant.
    for variant in range(3):
        sim.state.pickups=[]
        e.variant=variant
        for i in range(100):sim._reward(e)
        var valid:=true
        for drop in sim.state.pickups:
            if sim.catalog.items[drop.item].kind!="consumable" and not sim.enemy_definition(0,variant).loot.has(drop.item):valid=false
        check(valid,"Reward rolls respect worn equipment %d" % variant)
    sim.new_profile()
    game._refresh_slots()
    await get_tree().process_frame
    check(game.get_node("Safe/Layout/Map").position.y==0,"Gameplay above HUD")
    check(game.get_node("Safe/Layout/Top").position.y>=game.get_node("Safe/Layout/Map").size.y,"Status below gameplay")
    check(game.get_node("Safe/Layout/Dock/Content/Inventory/SupplyColumn").position.x>game.get_node("Safe/Layout/Dock/Content/Inventory/GearColumn").position.x,"Side by side inventory")
    for id in ["wood_sword","robot","potion"]:sim.add_item(id)
    game.selected="wood_sword"
    game._open("item")
    await get_tree().process_frame
    await get_tree().process_frame
    check(game.rows.size.x<=game.sheet.size.x,"Item card fits sheet")
    for panel in ["upgrades","enemy","travel","stats","settings","history","camp","prestige"]:
        game.group=0
        game._open(panel)
        await get_tree().process_frame
        await get_tree().process_frame
        check(game.rows.size.x<=game.sheet.size.x,"Panel fits width: "+panel)
    game._close()
    await get_tree().process_frame
    var view: LootActorView=game.world.views["player"]
    sim.state.player.attack_age=.22
    sim.state.player.attack_contact=.22
    view.attack_texture=null
    view.actor=sim.state.player
    view._process(0)
    check(view.get_node("Visual").position.y<0 and view.get_node("Visual/Body").region_rect.position.y==72,"Unarmed hop and authored effort frame")
    sim.state.player.hp=0
    sim.state.player.dead_age=.4
    view._process(0)
    check(view.visible and view.get_node("Visual/Body").region_rect.position.y==48,"Death animation remains visible")
    sim.state.player.dead_age=1.1
    view._process(0)
    check(not view.visible,"Death completes before hiding")
    sim.new_profile()
    for size_ in [Vector2i(720,1280),Vector2i(720,1600),Vector2i(600,1100)]:
        get_tree().root.size=size_
        await get_tree().process_frame
        await get_tree().process_frame
        game._layout_sheet()
        check(game.get_node("Safe/Layout/Dock").get_global_rect().end.y<=game.size.y+1,"Dock stays on screen %s" % size_)
        for id in sim.catalog.items:
            sim.new_profile()
            sim.add_item(id,3)
            game.selected=id
            game.selected_slot=0 if sim.catalog.items[id].kind=="consumable" else -1
            game._open("item")
            await get_tree().process_frame
            await get_tree().process_frame
            check(game.rows.size.x<=game.sheet.size.x,"Item card fits %s %s" % [id,size_])
    game._close()
    print("PROGRESSION_PROBE checks=",checks," failures=",failures)
    game.queue_free()
    await get_tree().process_frame
    get_tree().quit(0 if failures==0 else 1)
