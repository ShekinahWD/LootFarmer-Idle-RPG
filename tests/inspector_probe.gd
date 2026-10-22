extends Node
var game
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        push_error(message)
func texts(node: Node) -> String:
    var result: String=node.text+"\n" if node is Label or node is Button else ""
    for child in node.get_children():result+=texts(child)
    return result
func tap(point: Vector2) -> void:
    game.world.collect_at(game.world.get_canvas_transform()*point)
func _ready() -> void:
    call_deferred("run")
func run() -> void:
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate()
    add_child(game)
    game.sim.set_physics_process(false)
    game.sim.new_profile()
    await get_tree().process_frame
    await get_tree().process_frame
    var sim=game.sim
    for i in range(4):check(is_equal_approx(sim.gear_chance(i),[.10,.09,.08,.30][i]),"Authored base drop probability %d" % i)
    sim.state.coins=100000
    sim.state.gems=100000
    sim.buy_upgrade("loot",0)
    check(is_equal_approx(sim.gear_chance(0),.11),"Gear upgrade adds one percentage point")
    for i in range(15):sim.buy_upgrade("loot",3)
    var money: int=sim.state.coins
    check(sim.upgrade_maxed("loot",3) and not sim.buy_upgrade("loot",3) and sim.state.coins==money,"Boss chance cap prevents wasted purchases")
    tap(sim.position_of(sim.state.player)+Vector2(0,-10))
    check(game.panel=="upgrades","Player tap opens player upgrades")
    game._close()
    var enemy: Dictionary=sim.state.enemies[0]
    tap(sim.position_of(enemy)+Vector2(0,-10))
    check(game.panel=="enemy" and game.group==0,"Enemy tap opens matching group")
    var locked:=texts(game.rows)
    check(locked.contains("???") and not locked.contains("18") and not locked.contains("Wooden Sword"),"Locked inspector hides stats and drop identities")
    check(sim.buy_upgrade("reveal_stats",0),"Stats reveal can be purchased")
    game._refresh_panel()
    check(texts(game.rows).contains("HP 42") and texts(game.rows).contains("???"),"Stats reveal leaves drops locked")
    check(sim.buy_upgrade("reveal_drops",0),"Drops reveal can be purchased")
    game._refresh_panel()
    var unlocked:=texts(game.rows)
    check(unlocked.contains(tr("ITEM_SPROUT")) and unlocked.contains("11.00%") and not unlocked.contains("???"),"Drop list uses exact current per-item probabilities")
    check(sim.level("reveal_stats",1)==0,"Information unlock is per group")
    var saved: Dictionary=sim.snapshot()
    sim.new_profile()
    sim.restore(saved)
    check(sim.level("reveal_stats",0)==1 and sim.level("reveal_drops",0)==1,"Reveals survive save restore")
    sim.state.victory=true
    sim.state.offer=["hp"]
    check(sim.prestige("hp"),"Prestige saves successfully")
    check(sim.level("reveal_stats",0)==0 and sim.level("reveal_drops",0)==0 and sim.level("loot",0)==0,"Prestige resets all purchased group upgrades")
    sim.new_profile()
    check(sim.level("reveal_stats",0)==0,"Hard reset removes information unlocks")
    # Legacy snapshots need no new mandatory state fields.
    sim.restore(saved)
    check(not SaveService.write_blocked,"Existing schema remains readable")
    game._close()
    var before: Vector2=sim.position_of(sim.state.player)
    sim.state.coins=1000
    tap(game.world.get_node("Camps/Camp1").position)
    check(game.panel=="camp","Locked camp tap opens unlock panel")
    game.rows.get_child(1).pressed.emit()
    check(sim.state.spawns.has(1) and sim.state.spawn==1 and sim.position_of(sim.state.player)==before,"Unlock selects camp without teleporting")
    game._close()
    tap(game.world.get_node("Camps/Camp0").position)
    game.world._process(0)
    check(sim.state.spawn==0 and game.world.get_node("Camps/Camp0/Selected").visible and not game.world.get_node("Camps/Camp1/Selected").visible,"Owned camp tap changes exclusive selected marker")
    check(sim.position_of(sim.state.player)==before,"Camp reselection never teleports")
    var map: Control=game.get_node("Safe/Layout/Map")
    check(is_equal_approx(game.stick.position.x+game.stick.size.x*.5,map.size.x*.5),"Joystick is bottom-center")
    check(game.get_node("Safe/Layout/Map/History").position.x<30 and game.get_node("Safe/Layout/Map/History").position.y<30,"Recent finds sit top-left")
    check(game.world.get_node("Ground").get_used_rect().size.x*16>1500,"Map has decorated overscan beyond movement bounds")
    for page in ["upgrades","enemy","camp","travel"]:
        game._open(page)
        await get_tree().process_frame
        await get_tree().process_frame
        check(game.sheet.get_global_rect().end.y<=game.get_node("Safe/Layout/Dock").global_position.y and game.rows.size.x<=game.sheet.size.x,"Inspector fits available map area: "+page)
    var font: Font=game.get_theme_default_font()
    check(font is FontFile and font.multichannel_signed_distance_field,"Shared font uses scalable MSDF rendering")
    check(game.world.get_node("Group0").texture_filter==CanvasItem.TEXTURE_FILTER_LINEAR,"World labels override pixel-art filtering")
    print("INSPECTOR_PROBE checks=%d failures=%d" % [checks,failures])
    game.queue_free()
    await get_tree().process_frame
    get_tree().quit(1 if failures else 0)
