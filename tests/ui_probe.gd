extends Node
## Core HUD and presentation contracts (kept, repaired in Change 11): map/dock layout, enemy-panel
## purchases, supply use from a slot, tap-to-collect ground loot, joystick, walk/death/attack frames,
## camera zoom bounds and follow, ground-item size and the enemy HP bar.
var checks:=0
var failures:=0
var game
func check(value: bool,message: String) -> void:
    checks+=1
    if not value:
        failures+=1
        push_error(message)
func _ready() -> void:
    call_deferred("run")
func run() -> void:
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate()
    add_child(game)
    game.sim.set_physics_process(false)
    game.sim.new_profile()
    game.sim.state.tutorial.mode="none";game.sim.suspended=false # fixture: onboarding chooser answered
    await get_tree().process_frame
    await get_tree().process_frame
    check(game.get_node("Safe/Layout/Map").size.y>=400,"Map keeps playable area")
    check(game.get_node("Safe/Layout/Dock").get_global_rect().end.y<=game.size.y+1,"Inventory stays inside viewport")
    game._open("upgrades")
    await get_tree().process_frame
    check(not get_tree().paused,"Management panel leaves combat running")
    check(game.sheet.get_global_rect().end.y<game.get_node("Safe/Layout/Dock").global_position.y,"Sheet does not cover inventory header")
    game.group=1
    game.enemy_tab=1
    game.sim.state.coins=1000
    game.sim.state.gems=1000
    game.sim.campaign.discover_spot(1,2) # fixture: the type has been found (enemy panels need it)
    game.sim.touch()
    game._open("enemy")
    var bought:=false
    for row in game.rows.find_children("*","Button",true,false):
        if row.get_meta("upgrade","")=="loot":
            row.pressed.emit()
            bought=true
            break
    check(bought and game.sim.level("loot",1)==1,"Enemy panel buys the correct group's upgrade")
    var nav: Node=game.get_node("Safe/Layout/Dock/Content/Navigation")
    check(["World","Missions","Prestige","Upgrades","Settings"].all(func(n):return nav.has_node(n)),"Navigation: World, Missions, Prestige, Upgrades, Settings")
    game.sim.add_item("potion",4)
    game._select_slot(1,0)
    game.sim.state.player.hp=50
    var used:=false
    for row in game.actions.find_children("*","Button",true,false)+game.actions.get_children():
        if row is Button and row.text==tr("USE"):
            row.pressed.emit()
            used=true
            break
    check(used and game.sim.quantity("potion")==3,"Supply slot opens functional use action")
    game._close()
    game.sim._drop("wood_sword",game.sim.state.player)
    await get_tree().process_frame
    var surface=game.get_node("Safe/Layout/Map/GestureSurface")
    var drop: Dictionary=game.sim.state.pickups[0]
    var tap_position: Vector2=(game.world.get_canvas_transform()*Vector2(drop.x,drop.y))*surface.size/game.world.get_viewport_rect().size
    surface.begin_pointer(0,tap_position)
    surface.end_pointer(0,tap_position)
    check(game.sim.quantity("wood_sword")==1,"Map tap release collects ground loot")
    var stick=game.stick
    var start:=InputEventScreenTouch.new()
    start.index=2
    start.pressed=true
    start.position=stick.size*.5+Vector2(60,0)
    stick._gui_input(start)
    check(stick.direction.x>.8 and game.stick_input.x>.8,"Joystick emits movement direction")
    var stop:=InputEventScreenTouch.new()
    stop.index=2
    stop.pressed=false
    stick._input(stop)
    check(stick.direction==Vector2.ZERO,"Release outside joystick clears movement")
    game._open("settings")
    # Change 40 (Playbook 132.5): Settings offers the enabled languages in one dropdown; the languages not enabled
    # yet are not listed at all, and the localization service refuses them.
    var offered: Array=[]
    for row in game.rows.find_children("*","OptionButton",true,false):
        if row.get_script()==game.LANGUAGE_DROPDOWN:offered=range(row.item_count).map(func(i):return row.get_item_metadata(i))
    var drafts:=LocalizationService.RELEASE_LANGUAGES.filter(func(l):return not l in LocalizationService.ENABLED_LANGUAGES)
    check(offered==["automatic"]+LocalizationService.ENABLED_LANGUAGES and drafts.size()==9 and not drafts.any(func(l):return l in offered or LocalizationService.select_language(l)),"The dropdown offers Automatic and the 11 enabled languages; the 9 drafts are absent and refused")
    for panel in ["item","upgrades","travel","stats","history","prestige"]:
        game._open(panel)
    var actor=load("res://scenes/game/actor.tscn").instantiate()
    add_child(actor)
    actor.actor=game.sim.state.player.duplicate(true)
    actor.actor.moving=true
    actor.actor.hp=100
    var positions: Dictionary={}
    for i in range(8):
        actor._process(.1)
        positions[str(actor.get_node("Visual/Body").region_rect)]=true
    check(positions.size()==4,"Walk traverses all four verified row-one poses")
    actor.actor.hp=0
    actor.actor.dead_age=.5
    actor._process(.01)
    check(actor.visible and actor.get_node("Visual/Body").region_rect.position.y==48,"Death keeps its non-targetable visible sequence")
    actor.actor.dead_age=1.01
    actor._process(.01)
    check(not actor.visible,"Death presentation ends before respawn")
    game._close()
    SettingsState.set_camera_zoom(2.0)
    game.get_node("Safe/Layout/Map/Zoom/Slider").value=2.25
    check(is_equal_approx(SettingsState.camera_zoom,2.25),"Zoom slider changes camera setting")
    SettingsState.set_camera_zoom(.25)
    check(SettingsState.camera_zoom==1.0,"Zoom cannot go farther than original framing")
    SettingsState.set_camera_zoom(9.0)
    check(SettingsState.camera_zoom==3.0,"Close zoom has a bounded range")
    get_tree().paused=true
    game._process(.01)
    check(is_equal_approx(game.world.get_node("Camera").zoom.x,game.world.get_viewport_rect().size.x/360.0*3.0),"Zoom updates while paused")
    get_tree().paused=false
    var saved_settings: Dictionary=SettingsState.to_save_dict()
    SettingsState.reset_to_defaults()
    SettingsState.from_save_dict(saved_settings)
    check(SettingsState.camera_zoom==3.0,"Camera zoom survives settings round trip")
    game.sim.state.player.x=70
    game.sim.state.player.y=1110
    game.world._process(0)
    check(game.world.get_node("Camera").position==Vector2(70,1110),"Camera follows player on both axes")
    game.sim._drop("potion",game.sim.state.player)
    game.world._process(0)
    for pickup in game.world.pickups.values():
        var icon: Sprite2D=pickup.get_node("Icon")
        var extent: Vector2=icon.texture.get_size()*icon.scale
        check(maxf(extent.x,extent.y)<=14.01,"Every ground item fits world-sized bounds")
    actor.actor.hp=100
    actor.actor.moving=false
    actor.attack_texture=game.world.ATTACKS.wood_sword
    actor.actor.attack_contact=.08
    actor.actor.attack_age=.08
    actor._process(0)
    check(actor.get_node("Visual/Attack").visible and actor.get_node("Visual/Attack").region_rect.position.x==128,"Real slash frame matches accelerated hit timing")
    actor.actor.attack_age=.33
    actor._process(0)
    check(not actor.get_node("Visual/Attack").visible,"Attack recovers without looping")
    actor.actor.id="enemy_test"
    actor._process(0)
    var fill=actor.get_node("HP").get_theme_stylebox("fill")
    check(fill is StyleBoxTexture and fill.modulate_color.r>fill.modulate_color.g,"Enemy health is red")
    print("UI_PROBE checks=%d failures=%d" % [checks,failures])
    actor.queue_free()
    game.queue_free()
    await get_tree().process_frame
    await get_tree().process_frame
    get_tree().quit(1 if failures else 0)
