extends Node
## Change 40 evidence: the Settings language dropdown, rendered. Windowed only (the menu is an embedded window,
## composited into the root viewport's texture):
##   godot --path . --resolution 540x960 res://tests/change_40_capture.tscn -- --probe --profile=probe-c40-shots
##       --no-autosave --first-run-complete --out=res://docs/Change_40_Evidence/ --shape=540x960
## Writes <out><shape>_<screen>.png and <out><shape>_layout.json (button and menu rectangles per screen).
var game
var sim
var out:="res://docs/Change_40_Evidence/"
var shape:=""
var layout: Dictionary={}

func _ready() -> void:call_deferred("run")
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame

func run() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
        elif arg.begins_with("--shape="):shape=arg.trim_prefix("--shape=")
    if shape=="":shape="%dx%d" % [get_window().size.x,get_window().size.y]
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
    SettingsState.mute_all_sfx()
    LocalizationService.set_test_device_locale("en_US")
    LocalizationService.select_language("automatic")
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.campaign.review.opener=func(_url: String)->int:return ERR_CANT_OPEN
    await frames(10)
    sim.new_profile();sim.set_physics_process(false)
    sim.state.tutorial.mode="none";sim.campaign.onboarding.reveal_all(true);sim.state.tutorial.seen.append("road_ahead")
    sim.state.unlocked_stage=3;sim.touch()
    await get_tree().create_timer(1.0).timeout
    game.banner.queue.clear();game.banner._finish()
    game.toast_queue.clear();game.get_node("Toast").hide()
    var scroll: ScrollContainer
    # 1. Closed, English, the Language section brought into view.
    game._open("settings");await frames(10)
    scroll=game.get_node("Sheet/Margin/Content/Scroll")
    await reveal()
    await shot("closed_automatic")
    # 2. Open with Settings at the top of its scroll, then at the bottom.
    scroll.scroll_vertical=0;await frames(4)
    await open_shot("open_settings_top")
    scroll.scroll_vertical=int(scroll.get_v_scroll_bar().max_value);await frames(4)
    await open_shot("open_settings_bottom")
    # 3. The list scrolled to its last choices (Русский, Українська visible).
    dropdown().show_popup();await frames(6)
    var bar:=menu_bar()
    if bar!=null:bar.value=bar.max_value
    await frames(4)
    await shot("open_list_end")
    dropdown().close_menu();await frames(3)
    # 4. Keyboard/controller: focus on the dropdown, opened with ui_accept, focus moved down three rows.
    dropdown().grab_focus();await frames(2)
    await shot("closed_focus")
    key(&"ui_accept");await frames(4)
    for i in range(3):key(&"ui_down");await frames(1)
    await frames(3)
    await shot("open_keyboard")
    dropdown().close_menu();await frames(3)
    # 5. Russian chosen: Cyrillic UI, closed and open.
    LocalizationService.select_language("ru_RU");await frames(10)
    await reveal()
    await shot("closed_ru")
    await open_shot("open_ru")
    # 6. Automatic on a German device: German UI, "Automatisch (Deutsch)".
    LocalizationService.set_test_device_locale("de_DE")
    LocalizationService.select_language("automatic");await frames(10)
    await reveal()
    await shot("closed_automatic_de")
    await open_shot("open_automatic_de")
    var f:=FileAccess.open(ProjectSettings.globalize_path(out+shape+"_layout.json"),FileAccess.WRITE)
    f.store_string(JSON.stringify(layout,"  "));f.close()
    print("CHANGE_40_CAPTURE shape=%s screens=%d" % [shape,layout.size()])
    LocalizationService.select_language("automatic")
    LocalizationService.set_test_device_locale("")
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    get_tree().quit()

func dropdown() -> OptionButton:
    for b in game.rows.find_children("*","OptionButton",true,false):
        if b.get_script()==game.LANGUAGE_DROPDOWN:return b
    return null

func menu_bar(node: Node=null) -> VScrollBar:
    if node==null:node=dropdown().get_popup()
    for c in node.get_children(true):
        if c is ScrollContainer:return c.get_v_scroll_bar()
        var found:=menu_bar(c)
        if found!=null:return found
    return null

func key(action: StringName) -> void:
    for pressed in [true,false]:
        var e:=InputEventAction.new();e.action=action;e.pressed=pressed
        get_tree().root.push_input(e)

## Scrolls Settings so the Language section sits in the middle of the sheet.
func reveal() -> void:
    var scroll: ScrollContainer=game.get_node("Sheet/Margin/Content/Scroll")
    await frames(4)
    var d:=dropdown()
    var y: float=d.get_global_rect().position.y-scroll.get_global_rect().position.y+scroll.scroll_vertical
    scroll.scroll_vertical=int(maxf(0,y-scroll.size.y*.5))
    await frames(6)

func open_shot(screen: String) -> void:
    dropdown().show_popup();await frames(6)
    await shot(screen)
    dropdown().close_menu();await frames(3)

func shot(screen: String) -> void:
    await frames(2)
    var d:=dropdown()
    var menu:=d.get_popup()
    var bar:=menu_bar()
    layout[screen]={"view":str(get_viewport().get_visible_rect()),"button":str(d.get_global_rect()),"text":d.text,
        "menu_open":menu.visible,"menu":str(Rect2(Vector2(menu.position),Vector2(menu.size))) if menu.visible else "",
        "menu_scrolls":bar!=null and menu.visible and bar.visible and bar.max_value>bar.page,"locale":TranslationServer.get_locale()}
    get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(out+"%s_%s.png" % [shape,screen]))
