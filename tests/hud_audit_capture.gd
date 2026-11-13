extends Node
## HUD clutter investigation (design proposal only; not a gate, not Android validation, changes no game code).
## Stages one busy Winter I scene, renders it with the shipped HUD ("current") or with a proposed layout
## drawn over the real game ("A", "B", "C"), and measures how much of the map and of the action zone
## around the player the HUD covers.
##   godot --path . --resolution 540x960 res://tests/hud_audit_capture.tscn -- --probe --profile=probe-hud
##       --no-autosave --first-run-complete --shape=540x960 --layout=current|A|B|C [--inset=l,t,r,b] [--joystick=0|1|2]
## Output: tests/tmp/hud_audit/<layout>/<shape>[_variant]_<name>.png, the same with _zones (occupancy drawn),
## and metrics.json per run (ignored by Git).
## A mock freezes the game's 0.15 s HUD tick after the real HUD has filled itself, hides the real controls it
## replaces and draws stand-ins from the game's own theme, art and live texts.
var game
var sim
var map: Control
var shape:="540x960"
var layout:="current"
var variant:=""
var inset:=Vector4.ZERO
var joystick:=1
var lang:=""
var mock: Control
var zones: Control
var metrics: Array=[]
var hit_frames:=999
## The fight zone: the enemies' aggro radius around the player (world units), where blows are traded.
const ZONE_UNITS:=58.0
var combat:=false

class Zones extends Control:
    var rects: Array=[]
    var centre:=Vector2.ZERO
    var radius:=0.0
    var area:=Rect2()
    func _draw() -> void:
        for r in rects:
            draw_rect(r,Color(1,.15,.2,.38))
            draw_rect(r,Color(1,.2,.25,.95),false,2.0)
        draw_arc(centre,radius,0,TAU,96,Color(.3,1,.5,.95),3.0)
        draw_circle(centre,radius,Color(.3,1,.5,.10))

func _ready() -> void:call_deferred("run")
func frames(n:=8) -> void:
    for i in range(n):await get_tree().process_frame

func run() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--shape="):shape=arg.trim_prefix("--shape=")
        elif arg.begins_with("--layout="):layout=arg.trim_prefix("--layout=")
        elif arg.begins_with("--joystick="):joystick=int(arg.trim_prefix("--joystick="))
        elif arg.begins_with("--lang="):lang=arg.trim_prefix("--lang=")
        elif arg.begins_with("--inset="):
            var p:=arg.trim_prefix("--inset=").split(",")
            inset=Vector4(float(p[0]),float(p[1]),float(p[2]),float(p[3]))
    SettingsState.mute_all_sfx()
    LocalizationService.set_test_device_locale("en_US")
    LocalizationService.select_language("automatic" if lang=="" else lang)
    SettingsState.set_joystick_position(joystick)
    SettingsState.set_camera_zoom(2.0)
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    map=game.get_node("Safe/Layout/Map")
    await frames(10)
    if inset!=Vector4.ZERO:
        for pair in [["margin_left",inset.x],["margin_top",inset.y],["margin_right",inset.z],["margin_bottom",inset.w]]:
            game.get_node("Safe").add_theme_constant_override(pair[0],int(pair[1]))
        variant="inset"
    if joystick!=1:variant+=("_" if variant!="" else "")+"stick"+str(joystick)
    if lang!="":variant+=("_" if variant!="" else "")+lang
    sim.feedback.connect(func(_id: String,_amount: float,healing: bool)->void:
        if not healing:hit_frames=0)
    await fixture()
    quiet()
    # 1. Three followed objectives, standing beside the enemies, nothing happening.
    combat=false
    await present()
    await shot("01_three_objectives")
    # 2. The same with a fight running: damage numbers, speech, loot feed and Gem pickup.
    combat=true
    await fight()
    quiet()
    await present()
    await beat()
    await shot("02_combat")
    # 3. A toast arrives during the fight.
    quiet()
    game._toast(tr("OFFLINE_CLAIMED"))
    await frames(6)
    await present()
    await beat()
    await shot("03_combat_toast")
    # 4. A milestone banner and a toast together.
    game._toast(tr("OFFLINE_CLAIMED"))
    sim.milestone.emit("discovered","expedition_o1")
    await frames(30)
    await present()
    await beat()
    await shot("04_combat_banner_toast")
    # 5. The zoom slider opened from its button (Change 72), in a fight.
    quiet()
    if game.has_method("_toggle_zoom"):
        game._toggle_zoom()
        await present()
        await shot("05_zoom_open")
        game._toggle_zoom()
    # 6. The fight is over: the pills and chips return to their full form.
    combat=false
    sim.clear_target()
    if "hud_combat_time" in game:game.hud_combat_time=0.0
    await present()
    await shot("06_after_combat")
    var dir:="res://tests/tmp/hud_audit/%s/" % layout
    var f:=FileAccess.open(dir+shape+("_"+variant if variant!="" else "")+"_metrics.json",FileAccess.WRITE)
    f.store_string(JSON.stringify(metrics,"  "));f.close()
    print("HUD_AUDIT complete layout=%s shape=%s" % [layout,shape])
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    get_tree().quit()

func quiet() -> void:
    game.banner.queue.clear();game.banner._finish()
    game.toast_queue.clear();game.get_node("Toast").hide();game.toast_time=0.0

## Fixture (state set directly): Winter I, level 17, the Snowman found, two enemy groups known, a Mastery
## objective, the Hunt mission and a Prestige opportunity followed, like the reported screenshot.
func fixture() -> void:
    get_tree().paused=false
    sim.new_profile();sim.set_physics_process(false);sim.suspended=false
    sim.state.tutorial.mode="none"
    sim.campaign.onboarding.reveal_all(true)
    sim.state.tutorial.seen.append("road_ahead")
    game._close();game._cancel_confirm()
    sim.state.player_level=17
    sim.state.coins=4270.0;sim.state.gems=137.0
    for pair in [["unit-blue-cap_outfit",3],["wood_sword",6],["potion",1]]:
        if sim.catalog.items.has(pair[0]):sim.add_item(pair[0],pair[1],false,false)
    sim.equip("unit-blue-cap_outfit");sim.equip("wood_sword")
    sim.state.player.hp=sim.stats().hp
    var snow: int=sim.campaign.prestige_unlock_group()
    sim.state.bosses_found.append(str(sim.catalog.groups[snow].id))
    for g in [0,1]:
        sim.state.discovered[str(g)]=true
        for v in sim.campaign.variants(g):sim.campaign.discover_spot(g,int(v))
    sim.state.group_kills[1]=1370
    sim.campaign.refresh_missions()
    sim.state.follow_mission="main:0"
    sim.state.opportunities["expedition_o1"]={"ready":false,"baseline":{},"step":1,"count":0}
    sim.state.follow="expedition_o1"
    sim.state.follow_mastery="1:explore"
    var at: Vector2=sim.campaign.spot(1,2)+Vector2(0,34)
    sim.state.player.x=at.x;sim.state.player.y=at.y;sim.clear_target();sim.campaign.reveal()
    game.world.follow_player()
    game.combat_group=1
    sim.touch()
    await frames(24)

## Runs the real simulation until the player and the enemies trade blows.
func fight() -> void:
    for i in range(160):
        sim.step(.05)
        hit_frames+=1
        await get_tree().process_frame
        if i>50 and hit_frames<=2:break
    for n in range(3):
        sim.state.clock=float(sim.state.clock)+2.0
        sim.history("HISTORY_CURRENCY","gems",1.0,0.0)
    sim.touch()
    await frames(3)

## A few more simulation steps, stopping right after the next hit, so every shot carries live combat text.
func beat() -> void:
    if not combat:return
    hit_frames=999
    for i in range(120):
        sim.step(.05)
        hit_frames+=1
        await get_tree().process_frame
        if hit_frames==4:break

## Lets the real HUD write its texts, then (for a mock) freezes it and lays the proposal over it.
func present() -> void:
    game.elapsed=1.0
    await frames(3)
    game.elapsed=1.0
    await frames(3)

# ---------------------------------------------------------------- measurement and output
func hud_rects() -> Array:
    var list: Array=[]
    var nodes: Array=[]
    for child in map.get_children():
        if child is Control and child!=mock and not (child.name in ["ViewportContainer","GestureSurface","StatFeedback"]):nodes.append(child)
    if mock!=null:nodes.append_array(mock.get_children())
    for path in ["Toast","Banner","FocusCountdown"]:nodes.append(game.get_node(path))
    for node in nodes:
        if not node.visible or node.modulate.a<=0.01 or node.is_queued_for_deletion():continue
        if node.name=="History":
            for row in node.get_children():list.append({"name":"Loot","rect":row.get_global_rect()})
            continue
        var r: Rect2=node.get_global_rect()
        if r.size.x<2 or r.size.y<2:continue
        list.append({"name":str(node.name),"rect":r})
    return list

func player_point() -> Vector2:
    var world=game.world
    var screen: Vector2=world.get_canvas_transform()*Vector2(float(sim.state.player.x),float(sim.state.player.y)-14.0)
    return map.global_position+screen*map.size/Vector2(world.get_viewport_rect().size)
func world_scale() -> float:
    var world=game.world
    return world.get_canvas_transform().get_scale().x*map.size.x/float(world.get_viewport_rect().size.x)

func measure(name_: String,list: Array) -> Dictionary:
    var area: Rect2=map.get_global_rect()
    var centre:=player_point()
    var radius: float=ZONE_UNITS*world_scale()
    var step:=4.0
    var total:=0;var covered:=0;var zone:=0;var zone_covered:=0
    var y: float=area.position.y+step*.5
    while y<area.end.y:
        var x: float=area.position.x+step*.5
        while x<area.end.x:
            var p:=Vector2(x,y)
            var hit:=false
            for e in list:
                if (e.rect as Rect2).has_point(p):hit=true;break
            total+=1
            if hit:covered+=1
            if p.distance_to(centre)<=radius:
                zone+=1
                if hit:zone_covered+=1
            x+=step
        y+=step
    var body:=Rect2(centre-Vector2(22,34)*world_scale()*.5,Vector2(22,34)*world_scale())
    var on_player: Array=[]
    for e in list:
        if (e.rect as Rect2).intersects(body):on_player.append(e.name)
    var names: Array=[]
    for e in list:names.append(e.name)
    return {"shot":name_,"layout":layout,"shape":shape,"variant":variant,"canvas":[get_viewport().get_visible_rect().size.x,get_viewport().get_visible_rect().size.y],
        "map":[area.size.x,area.size.y],"map_share_of_screen":snappedf(area.size.y/get_viewport().get_visible_rect().size.y*100,.1),
        "hud_elements":list.size(),"map_covered_pct":snappedf(100.0*covered/maxi(total,1),.1),
        "action_zone_covered_pct":snappedf(100.0*zone_covered/maxi(zone,1),.1),"on_player":on_player,"elements":names}

func shot(name_: String) -> void:
    await frames(2)
    var dir:="res://tests/tmp/hud_audit/%s/" % layout
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
    var base: String=dir+shape+("_"+variant if variant!="" else "")+"_"+name_
    get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(base+".png"))
    var list:=hud_rects()
    var m:=measure(name_,list)
    metrics.append(m)
    print("SHOT %s map %.1f%% zone %.1f%% on_player %s" % [base,m.map_covered_pct,m.action_zone_covered_pct,str(m.on_player)])
    zones=Zones.new()
    zones.set_anchors_preset(Control.PRESET_FULL_RECT);zones.mouse_filter=Control.MOUSE_FILTER_IGNORE;zones.z_index=100
    for e in list:zones.rects.append(e.rect)
    zones.centre=player_point();zones.radius=ZONE_UNITS*world_scale()
    game.add_child(zones)
    await frames(2)
    get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(base+"_zones.png"))
    zones.queue_free()
    await frames(1)
