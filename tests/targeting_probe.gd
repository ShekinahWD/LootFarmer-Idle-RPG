extends Node
## Targeting and aim contracts (kept, repaired in Change 11): lock persistence, manual selection,
## chasing a selected enemy, release-to-select aiming, pinch cancel, movement clearing targets and the
## half-second idle before acquisition.
var checks:=0
var failures:=0
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        push_error(label_)
## sim.step() clamps each call to 0.1 s, so longer spans run as 0.1 s steps.
func advance(sim,seconds: float) -> void:
    var left:=seconds
    while left>.0001:
        sim.step(minf(.1,left))
        left-=.1
func _ready() -> void:
    call_deferred("run")
func run() -> void:
    var game=load("res://scenes/game/main.tscn").instantiate()
    add_child(game)
    var sim=game.sim
    sim.set_physics_process(false)
    sim.new_profile()
    sim.state.tutorial.mode="none";sim.suspended=false # fixture: onboarding chooser answered (Change 11)
    await get_tree().process_frame
    await get_tree().process_frame
    for enemy in sim.state.enemies:enemy.hp=0
    var first: Dictionary=sim.state.enemies[0]
    var second: Dictionary=sim.state.enemies[1]
    first.hp=100
    first.x=sim.state.player.x+40
    first.y=sim.state.player.y
    check(sim._combat_target().id==first.id,"Acquires an initial target")
    second.hp=100
    second.x=sim.state.player.x+5
    second.y=sim.state.player.y
    check(sim._combat_target().id==first.id,"Closer spawned enemy does not steal target")
    sim.state.player.idle=1
    sim.step(.05)
    check(sim.locked_target==first.id,"Lock survives attack processing")
    check(sim.select_target(second.id),"Manual target selection succeeds")
    check(sim._combat_target().id==second.id and sim.state.player.windup==0,"Manual selection cancels pending old strike")
    second.x=sim.state.player.x+200
    sim.campaign.reveal_circle(sim.position_of(second),80) # fixture: explored ground (fog, Change 8: only seen enemies are targets)
    var before: float=sim.state.player.x
    sim.step(.1)
    check(sim.state.player.x>before and sim.locked_target==second.id,"Chases selected enemy beyond acquisition radius")
    sim._kill(second)
    check(sim.manual_target=="" and sim.locked_target=="","Death clears lock and arrow")
    check(sim._combat_target().id==first.id,"Acquires replacement after death")
    sim.select_target(first.id)
    var surface=game.get_node("Safe/Layout/Map/GestureSurface")
    game.world.update_camera()
    var scale_: Vector2=surface.size/game.world.get_viewport_rect().size
    var start: Vector2=game.world.player_screen_position()*scale_
    var end: Vector2=(game.world.get_canvas_transform()*(sim.position_of(first)+Vector2(0,-10)))*scale_
    surface.begin_pointer(0,start)
    surface.move_pointer(0,end)
    check(surface.aiming and surface.dragging and game.world.following_player,"Player drag aims without panning")
    surface.end_pointer(0,end)
    check(sim.manual_target==first.id and not surface.aiming,"Release selects and removes aim line")
    game.world._process(0)
    var marker: TextureRect=game.world.views[first.id].get_node("Marker")
    check(marker.visible and marker.texture!=null and marker.modulate==Color(1,.75,.2),"Manual target shows its gold marker")
    surface.begin_pointer(0,start)
    surface.move_pointer(0,start+Vector2(80,0))
    surface.begin_pointer(1,start+Vector2(0,80))
    check(not surface.aiming and surface.pinched,"Second finger cancels aim for pinch")
    surface.cancel_gesture()
    sim._kill(sim.state.player)
    check(sim.locked_target=="" and sim.manual_target=="","Player death clears target")
    sim.new_profile()
    sim.state.tutorial.mode="none";sim.suspended=false # fixture: onboarding chooser answered (Change 11)
    for enemy in sim.state.enemies:
        enemy.hp=0
        enemy.respawn=99
    var old_enemy: Dictionary=sim.state.enemies[0]
    var nearby: Dictionary=sim.state.enemies[1]
    old_enemy.hp=100
    old_enemy.x=sim.state.player.x+180
    old_enemy.y=sim.state.player.y
    nearby.hp=100
    nearby.x=sim.state.player.x+10
    nearby.y=sim.state.player.y
    for enemy in [old_enemy,nearby]:
        enemy.home_x=enemy.x
        enemy.home_y=enemy.y
    sim.select_target(old_enemy.id)
    sim.state.player.cooldown=0.8
    sim.movement=Vector2.LEFT
    sim.step(.01)
    check(sim.locked_target=="" and sim.manual_target=="","Manual movement clears both automatic and manual target state")
    check(sim.state.player.windup==0 and sim.state.player.target=="","Movement cancels pending strike")
    check(sim.state.player.cooldown>.7,"Movement preserves weapon cooldown")
    sim.movement=Vector2.ZERO
    advance(sim,.49)
    check(sim.locked_target=="","No acquisition before half-second idle")
    sim.step(.011)
    check(sim.locked_target==nearby.id,"After half-second acquire nearby enemy instead of returning to old target")
    check(sim.state.player.windup==0,"Acquisition does not bypass remaining cooldown")
    advance(sim,.30)
    check(sim.state.player.windup>0,"Attack begins when cooldown permits")
    sim.movement=Vector2.RIGHT
    sim.step(.01)
    check(sim.locked_target=="","Movement also clears automatically acquired target")
    sim.new_profile()
    sim.state.tutorial.mode="none";sim.suspended=false # fixture: onboarding chooser answered (Change 11)
    sim.add_item("wood_sword",2)
    var base: float=sim.normal("wood_sword").damage
    var increment: float=sim.merge_gain("wood_sword","damage") # explicit catalog merge_gain (Change 6+)
    sim.merge("wood_sword")
    check(is_equal_approx(sim.normal("wood_sword").damage,base+increment),"A merge adds the authored merge gain")
    check(is_equal_approx(sim.stats().damage,5+(base+increment)*float(sim.catalog.progression.stored_weapon_factor)),"Stored weapon receives the stronger merged contribution")
    print("TARGETING_PROBE checks=%d failures=%d" % [checks,failures])
    get_tree().quit(1 if failures else 0)
