extends Node
## Change 12 UI capture (rendered, not headless): the HUD with "Map explored", Settings with the
## audio controls, Filters with Merge All, the Merge All upgrade card and the stone-axe swing.
## Writes PNGs to docs/Change_12_Evidence/ui/. Desktop evidence only, not proof of phone layout.
var sim
var game
const OUT="res://docs/Change_12_Evidence/ui/"
func _ready() -> void:call_deferred("run")
func frames(n:=6) -> void:
    for i in range(n):await get_tree().process_frame
func shot(name: String) -> void:
    await frames(10)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+name+".png"))
func run() -> void:
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.new_profile();sim.state.tutorial.mode="none";sim.suspended=false
    sim.state.gems=1e6
    for i in range(4):sim.buy_upgrade("gear_slots")
    sim.state.gems=5200
    sim.add_item("unit-blue-cap_outfit",6);sim.add_item("wood_sword",4);sim.add_item("stone_axe",3)
    sim.equip("unit-blue-cap_outfit");sim.equip("stone_axe")
    sim.campaign.reveal_circle(Vector2(480,700),220.0)
    for i in range(20):sim.step(.1)
    sim.touch()
    await shot("01_hud_map_explored")
    game._nav("settings")
    await shot("02_settings_audio")
    game._close()
    game.player_tab=1;game._open("upgrades")
    await shot("03_merge_all_upgrade_locked")
    sim.buy_upgrade("merge_all");game._refresh_panel(true)
    await shot("04_merge_all_upgrade_owned")
    game._close()
    game._nav("filters")
    await shot("05_filters_merge_all")
    var b: Button=null
    for n in game.rows.find_children("*","Button",true,false):
        if n.text.begins_with(tr("MERGE_ALL_BUTTON_IDLE")):b=n
    if b:b.pressed.emit()
    await shot("06_filters_after_merge_all")
    game._close()
    # Stone-axe swing on the player: hold a frame mid-swing.
    SettingsState.set_camera_zoom(3.0)
    var p: Dictionary=sim.state.player
    # Suspend the simulation (pausing the tree would also stop the views from drawing the frame).
    sim.suspended=true
    p.attack_age=float(p.get("attack_contact",.22))*1.1;p.moving=false
    await shot("07_stone_axe_swing")
    sim.suspended=false
    print("CAPTURE done")
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    await get_tree().create_timer(.1).timeout
    get_tree().quit(0)
