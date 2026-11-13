extends Node
## Change 76 rendered desktop evidence (not a gate, not Android validation): the Supplies tab's Auto Buy section
## (all locked; slot 1 chooser open; three active slots restocked / waiting for Coins / waiting for room; slot 2
## chooser with the duplicate disabled), the boss weapon notice on the HUD with other notices queued, and the
## Prestige keep/reset lists with camps on the kept side.
## Run windowed (432x960, 540x960; the monitor clamps taller windows):
##   godot --path . --resolution 540x960 res://tests/change_76_capture.tscn -- --probe --profile=probe-c76cap
##       --no-autosave --first-run-complete --shape=540x960 [--lang=de_DE]
## Output: tests/tmp/change_76_capture/<shape>[_<lang>]_<name>.png (ignored by Git).
var game
var sim
var shape:="540x960"
var lang:=""

func _ready() -> void:call_deferred("run")
func frames(n:=8) -> void:
    for i in range(n):await get_tree().process_frame

func shot(name_: String) -> void:
    await frames(4)
    var dir:="res://tests/tmp/change_76_capture/"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
    var file:=dir+shape+("_"+lang if lang!="" else "")+"_"+name_+".png"
    get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(file))
    print("SHOT ",file)

func fresh() -> void:
    get_tree().paused=false
    sim.new_profile();sim.set_physics_process(false);sim.suspended=false
    sim.state.tutorial.mode="none"
    sim.campaign.onboarding.reveal_all(true)
    sim.state.tutorial.seen.append("road_ahead")
    game._close();game._cancel_confirm()
    game.banner.queue.clear();game.banner._finish();game.toast_queue.clear();game.get_node("Toast").hide()

func supplies_tab() -> void:
    game.player_tab=2;game._open("upgrades");await frames(6)
    var scroll: ScrollContainer=game.get_node("Sheet/Margin/Content/Scroll")
    for l in game.rows.find_children("*","Label",true,false):
        if l.text==tr("AUTO_BUY_TITLE"):
            scroll.scroll_vertical=int(l.get_global_rect().position.y-scroll.get_global_rect().position.y+scroll.scroll_vertical)-8
    await frames(4)

func run() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--shape="):shape=arg.trim_prefix("--shape=")
        elif arg.begins_with("--lang="):lang=arg.trim_prefix("--lang=")
    SettingsState.mute_all_sfx()
    LocalizationService.set_test_device_locale("en_US")
    LocalizationService.select_language("automatic" if lang=="" else lang)
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    await frames(10)
    # 1. Everything locked, 120 Gems (the first unlock affordable).
    fresh()
    sim.state.gems=120.0;sim.state.coins=350.0
    await supplies_tab()
    await shot("01_auto_buy_locked")
    # 2. Slot 1 just unlocked: its chooser is open.
    for b in game.rows.find_children("*","Button",true,false):
        if b.get_meta("guide","")=="auto_buy_unlock_0":b.pressed.emit()
    await frames(4)
    await supplies_tab()
    await shot("02_auto_buy_chooser")
    # 3. Three slots active: restocked, waiting for Coins, waiting for room.
    fresh()
    sim.state.gems=1000.0
    for i in range(3):sim.buy_upgrade("auto_buy_slots")
    sim.buy_upgrade("supply_slots")
    sim.set_auto_buy(0,"potion");sim.set_auto_buy(1,"coin_boost");sim.set_auto_buy(2,"guard_tonic")
    sim.state.coins=float(5*int(sim.supply("potion").price))
    sim.auto_buy_step()
    sim.add_item("recovery_salve",2,false,false) # fixture: the second supply slot is taken
    sim.state.coins=150.0
    await supplies_tab()
    await shot("03_auto_buy_three_active")
    # 4. Slot 2's chooser: Health Potion is in slot 1, so it is disabled here.
    for b in game.rows.find_children("*","Button",true,false):
        if b.get_meta("guide","")=="auto_buy_change_1":b.pressed.emit()
    await frames(4)
    await supplies_tab()
    await shot("04_auto_buy_duplicate_disabled")
    game.auto_buy_edit=-1
    # 5. The boss weapon notice on the HUD, other notices queued behind it (4 s into its 8 s).
    fresh()
    sim.event.emit("ITEM_ENHANCED");sim.event.emit("INVENTORY_FULL");sim.event.emit("NOT_ENOUGH_COINS")
    for i in range(40):game._update_toast(.1)
    await frames(2)
    await shot("05_boss_weapon_notice_4s")
    # 6. Prestige confirmation: what stays and what resets.
    fresh()
    game._open_prestige_confirm(["hunter_o1"]);await frames(40)
    await shot("06_prestige_keep_reset")
    print("CHANGE_76_CAPTURE complete shape=%s" % shape)
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    get_tree().quit()
