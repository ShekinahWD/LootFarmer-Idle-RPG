extends Node
## Change 67 Phase 2 audit capture (windowed, 432x960 / 540x960; desktop evidence, not phone performance):
##   Godot --path . --resolution 432x960 tests/change_67_vfx_capture.tscn -- --no-autosave --first-run-complete [--out=<dir>] [--only=combat|collect|boss|revive]
## Live gameplay with the simulation running: a fight with kills and drops, collecting loot by tap,
## a boss defeat and a revive. Frames every STEP seconds as <out>/<w>x<h>/<sequence>_<i>_<ms>.png.
## Fixtures (labelled) only place actors and set HP; combat, drops and collection are the real rules.
var sim
var game
var out:=""
var only:=""
func _ready() -> void:call_deferred("run")
func frames(n:=6) -> void:
    for i in range(n):await get_tree().process_frame
func wait(seconds: float) -> void:
    await get_tree().create_timer(seconds,true,false,true).timeout

func run() -> void:
    var root:="user://change_67_vfx_capture/"
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--only="):only=arg.trim_prefix("--only=")
        if arg.begins_with("--out="):root=arg.trim_prefix("--out=").trim_suffix("/")+"/"
    var view:=Vector2(DisplayServer.window_get_size())
    out=root+"%dx%d/" % [int(view.x),int(view.y)]
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
    TranslationServer.set_locale("en")
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    await frames(10)
    if only in ["","combat"]:await combat()
    if only in ["","collect"]:await collect()
    if only in ["","boss"]:await boss()
    if only in ["","revive"]:await revive()
    if only in ["","crit"]:await crit()
    if only in ["","supply"]:await supplies()
    print("CHANGE_67_VFX_CAPTURE ",ProjectSettings.globalize_path(out))
    get_tree().quit(0)

func fresh() -> void:
    get_tree().paused=false
    sim.new_profile();sim.suspended=false;sim.held=false
    sim.state.tutorial.mode="none";sim.campaign.onboarding.reveal_all(true)
    sim.state.tutorial.seen.append("road_ahead") # fixture: no goals card
    game._close();game.toast_queue.clear();game.get_node("Toast").hide()
    game.banner.queue.clear();game.banner._finish()
    await frames(4)

func save(name: String) -> void:
    get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(out)+name+".png")

func record(prefix: String,length: float,step: float) -> void:
    var start:=Time.get_ticks_msec()
    var next:=0.0
    var index:=0
    while true:
        await get_tree().process_frame
        var t:=(Time.get_ticks_msec()-start)/1000.0
        if t>=next:
            await RenderingServer.frame_post_draw
            save("%s_%02d_%04d" % [prefix,index,int(t*1000)])
            index+=1
            next+=step
        if t>=length:break
    print("SEQUENCE ",prefix," frames ",index)

## The nearest normal enemies, moved next to the player (fixture placement only).
func gather(count: int,boss:=false) -> Array:
    var foes: Array=[]
    for e in sim.state.enemies:
        if bool(sim.catalog.groups[int(e.group)].boss)==boss and e.hp>0:foes.append(e)
    var p: Vector2=sim.position_of(sim.state.player)
    foes.sort_custom(func(a,b):return sim.position_of(a).distance_to(p)<sim.position_of(b).distance_to(p))
    foes=foes.slice(0,count)
    sim.campaign.reveal_circle(p,140)
    for i in range(foes.size()):
        foes[i].x=p.x+18+16*i;foes[i].y=p.y-6+10*i
    return foes

func combat() -> void:
    await fresh()
    sim.add_item("iron_sword",1);sim.equip("iron_sword") # fixture: kills within the clip
    var foes:=gather(2)
    for f in foes:f.aggro=true
    sim.state.player.target=str(foes[0].id) if "target" in sim.state.player else ""
    await record("combat",3.0,.1)

func collect() -> void:
    await fresh()
    var foes:=gather(1)
    var f: Dictionary=foes[0]
    f.hp=0;f.dead_age=9.0;f.respawn=999.0 # fixture: defeated, drops on the ground
    sim.state.pickups.clear()
    for id in sim.catalog.groups[int(f.group)].loot:sim._drop(id,f)
    sim._drop("potion",f)
    await wait(1.0)
    save("collect_before")
    _tap_all()
    await record("collect",1.0,.04)

## Taps each drop in turn, 0.25 s apart, while the recording runs.
func _tap_all() -> void:
    await wait(.08)
    for uid in game.world.pickups.keys():
        if not game.world.pickups.has(uid):continue
        var node: Node2D=game.world.pickups[uid]
        var screen: Vector2=game.world.get_viewport().get_canvas_transform()*node.global_position
        game.world.collect_at(screen)
        await wait(.25)

func boss() -> void:
    await fresh()
    sim.add_item("diamond_sword",1);sim.equip("diamond_sword") # fixture: a strong weapon
    var bosses:=gather(1,true)
    if bosses.is_empty():return
    var b: Dictionary=bosses[0]
    b.hp=1.0;b.aggro=true # fixture: one hit from defeat, standing next to the hero
    var p: Vector2=sim.position_of(sim.state.player)
    b.x=p.x+14;b.y=p.y
    sim.select_target(str(b.id))
    await record("boss",2.4,.1)

func revive() -> void:
    await fresh()
    sim.state.player.hp=0.0 # fixture: the player has just fallen
    sim.state.player.respawn=1.0
    await record("revive",2.6,.1)

## A hero's critical hit on an enemy beside them. The hit itself is the simulation's: the hero's crit
## chance is raised for the clip (fixture) and the enemy is struck by the real attack.
func crit() -> void:
    await fresh()
    var foes:=gather(1)
    var f: Dictionary=foes[0]
    var p: Vector2=sim.position_of(sim.state.player)
    f.x=p.x+16;f.y=p.y;f.aggro=false;f.hp=1e6 # fixture: a sturdy target beside the hero
    sim.state.upgrades["critical_chance"]=1000 # fixture: every hit crits during the clip
    sim.profile_epoch+=1 # the stat popups take the raised chance as their new baseline (no popup)
    sim.select_target(str(f.id))
    await record("crit",2.0,.05)
    sim.state.upgrades.erase("critical_chance")

## Each supply used by the hero (the real use_item), then the auras still running.
func supplies() -> void:
    await fresh()
    sim.state.supplies=["","","","",""] # fixture: five supply slots
    for id in ["potion","coin_boost","guard_tonic","recovery_salve","wisdom_tonic"]:sim.add_item(id,2)
    sim.state.player.hp=sim.stats().hp*.4 # fixture: hurt, so the potion heals
    for e in sim.state.enemies:e.aggro=false
    for id in ["potion","coin_boost","guard_tonic","recovery_salve","wisdom_tonic"]:
        if id=="recovery_salve":sim.state.player.hp=sim.stats().hp*.4 # fixture: hurt again (its own use rule)
        sim.use_item(id)
        await record("supply_"+id,1.3,.1)
    await record("supply_auras",2.0,.25)
