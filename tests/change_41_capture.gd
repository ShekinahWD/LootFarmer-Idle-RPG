extends Node
## Change 41 rendered desktop evidence (not a gate, not Android validation): the mode chooser, the Guided
## movement lesson with the joystick framed at Center, Left and Right, Settings (Joystick position and the
## Discord button), the HUD with each joystick position and both trackers, a Prestige collection at its
## true requirement, and equipment drops arriving (one kill with weapon + outfit + supply, then three
## kills at once) at fixed arrival times.
## Run windowed (432x960, 540x960, 768x1024):
##   godot --path . --resolution 540x960 res://tests/change_41_capture.tscn -- --probe --profile=probe-c41cap
##       --no-autosave --first-run-complete --shape=540x960 [--drops-only] [--out=res://docs/Change_41_Evidence/]
## --drops-only uses nothing added in Change 41, so the same scenario renders the earlier drops (run it in a
## worktree of the previous commit with --out pointing here and --tag=before).
var game
var sim
var shape:="540x960"
var tag:="after"
var out:="res://docs/Change_41_Evidence/"
var drops_only:=false
## --lang=de_DE: the chooser, the lesson and Settings in that language (file names carry it).
var lang:=""
func _ready() -> void:call_deferred("run")
func frames(n:=8) -> void:
    for i in range(n):await get_tree().process_frame
func shot(name_: String) -> void:
    game.banner.queue.clear();game.banner._finish()
    game.toast_queue.clear();game.get_node("Toast").hide()
    await frames(3)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
    get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(out+shape+"_"+name_+".png"))
func fresh(mode: String) -> void:
    get_tree().paused=false
    sim.new_profile();sim.set_physics_process(false);sim.suspended=false
    sim.state.tutorial.mode=mode
    if mode!="pending":sim.campaign.onboarding.reveal_all(true)
    game._close();game._cancel_confirm()
func run() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--shape="):shape=arg.trim_prefix("--shape=")
        elif arg.begins_with("--out="):out=arg.trim_prefix("--out=")
        elif arg.begins_with("--tag="):tag=arg.trim_prefix("--tag=")
        elif arg=="--drops-only":drops_only=true
        elif arg.begins_with("--lang="):lang=arg.trim_prefix("--lang=")
    SettingsState.mute_all_sfx()
    LocalizationService.set_test_device_locale("en_US")
    LocalizationService.select_language("automatic")
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    await frames(10)
    if lang!="":
        LocalizationService.select_language(lang);shape+="_"+lang
        await frames(6)
        await chooser_and_lesson()
        fresh("none");sim.state.tutorial.seen.append("road_ahead")
        game._open("settings");await frames(12)
        await shot("03_settings_top")
        LocalizationService.select_language("automatic")
    elif not drops_only:
        await chooser_and_lesson()
        await settings_and_hud()
    if lang=="":await drops()
    if not drops_only:SettingsState.set_joystick_position(1)
    print("CHANGE_41_CAPTURE complete shape=%s tag=%s" % [shape,tag])
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    get_tree().quit()

func chooser_and_lesson() -> void:
    SettingsState.set_joystick_position(1)
    fresh("pending");sim.state.tutorial.seen=[];sim.suspended=true
    await frames(16)
    await shot("01_chooser")
    game.guide.choose("guided");await frames(6)
    for position in [1,0,2]:
        SettingsState.set_joystick_position(position)
        # The demo at mid-travel: the ghost knob halfway toward the path.
        var guide=game.guide
        var cycle: float=guide.STICK_TRAVEL_SECONDS+guide.STICK_HOLD_SECONDS
        guide.pulse=floor(guide.pulse/cycle)*cycle+guide.STICK_TRAVEL_SECONDS*.6
        await frames(1);guide.pulse=floor(guide.pulse/cycle)*cycle+guide.STICK_TRAVEL_SECONDS*.6
        await shot("02_guided_move_%s" % game.stick.POSITIONS[position])
    SettingsState.set_joystick_position(1)

func settings_and_hud() -> void:
    fresh("none");sim.state.tutorial.seen.append("road_ahead")
    game._open("settings");await frames(12)
    await shot("03_settings_top")
    # A collection contract one copy short of its true requirement (20 of 21 picked up), followed.
    var item: String=sim.campaign.contract_outfit("blue-cap")
    sim.state.opportunities["collection_o1"]={"ready":false,"baseline":{},"step":0,"count":0}
    for name_ in sim.campaign.collection_names(1):
        var id: String=sim.campaign.contract_outfit(name_)
        var copies:=20 if id==item else 21
        sim.add_item(id,copies,false,false)
        sim.state.online_items[id]=float(copies);sim.state.opportunities.collection_o1["item_"+id]=float(copies)
    sim.state.follow="collection_o1"
    sim.state.missions=[];sim.state.follow_mission="main:0"
    game._close();await frames(8)
    for position in [0,1,2]:
        SettingsState.set_joystick_position(position)
        await frames(4)
        await shot("04_hud_joystick_%s" % game.stick.POSITIONS[position])
    SettingsState.set_joystick_position(1)
    game._open("prestige");await frames(12)
    var scroll: ScrollContainer=game.get_node("Sheet/Margin/Content/Scroll")
    for node in game.rows.find_children("*","Label",true,false):
        if str(node.text).contains("Blue Cap") and str(node.text).contains("/21"):
            scroll.ensure_control_visible(node);break
    await frames(6)
    await shot("05_prestige_collection_20_of_21")
    game._close()

## Drops: one kill with weapon, outfit and supply, captured at fixed arrival times (the arrival is
## presentation only, so its time is set directly), then three kills at once.
func drops() -> void:
    get_tree().paused=false
    sim.new_profile();sim.set_physics_process(false);sim.suspended=false
    sim.state.tutorial.mode="none";sim.campaign.onboarding.reveal_all(true);sim.state.tutorial.seen.append("road_ahead")
    game._close()
    var foes: Array=[]
    for e in sim.state.enemies:
        if not sim.catalog.groups[int(e.group)].boss:foes.append(e)
    foes.sort_custom(func(a,b):return sim.position_of(a).distance_to(sim.position_of(sim.state.player))<sim.position_of(b).distance_to(sim.position_of(sim.state.player)))
    var at: Vector2=sim.position_of(sim.state.player)+Vector2(0,-40)
    sim.campaign.reveal_circle(at,120)
    for i in range(mini(3,foes.size())):
        foes[i].x=at.x-46+46*i;foes[i].y=at.y-(14 if i==1 else 0)
        # Defeated, past the death animation and not yet back (the drops lie where they fell).
        foes[i].hp=0;foes[i].dead_age=9.0;foes[i].respawn=999.0
    await frames(6)
    var first: Dictionary=foes[0]
    sim.rng.seed=41
    sim.state.pickups.clear()
    # The type's full loadout (weapon and outfit) plus a supply: the representative mixed drop.
    for id in sim.catalog.groups[int(first.group)].loot:sim._drop(id,first)
    sim._drop("potion",first)
    var times:=[0.06,0.17,0.3,1.0] if not drops_only else [0.0]
    await frames(2)
    for t in times:
        for node in game.world.pickups.values():
            if "age" in node:node.age=t;node.clock=t;node._arrive();node.queue_redraw()
        await frames(1)
        await shot("06_%s_drop_single_t%03d" % [tag,int(t*100)])
    await get_tree().create_timer(.4).timeout
    await shot("07_%s_drop_single_settled" % tag)
    for i in range(1,mini(3,foes.size())):
        for id in sim.catalog.groups[int(foes[i].group)].loot:sim._drop(id,foes[i])
    await frames(2)
    for node in game.world.pickups.values():
        if "age" in node and node.age<INF:node.age=.17;node.clock=.17;node._arrive();node.queue_redraw()
    await frames(1)
    await shot("08_%s_drop_simultaneous_kills" % tag)
