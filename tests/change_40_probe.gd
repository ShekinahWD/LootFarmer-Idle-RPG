extends Node
## Change 40: progressive localization activation and the Settings language dropdown (Playbook 129.1, 132.5).
## 1. Readiness: Automatic's device-locale matcher (regions, scripts, separators, legacy codes, unsupported
##    languages) and that no device locale ever reaches a draft language.
## 2. Dropdown content: Automatic first with the language it resolves to, native names that never change with
##    the UI language, the closed control following the choice.
## 3. Placement at the three portrait shapes, Settings scrolled to the top and to the bottom: the menu stays inside
##    the visible screen, matches the button's width, opens on the roomier side without covering the button, has
##    thumb-sized rows, and scrolls (with a visible bar) when it is taller than the room.
## 4. Input: keyboard/controller (open, move, choose), Escape, Android Back (menu first, then the panel), a tap
##    outside (closes without reaching the map), a window resize, the panel's own refreshes while the menu is open,
##    and nothing left open once Settings closes.
var checks:=0
var failures:=0
var game
var sim
var shape:=""

func check(value: bool,message: String) -> void:
    checks+=1
    if not value:
        failures+=1
        push_error(message)
    else:print("ok  ",message)
func _ready() -> void:call_deferred("run")
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame

func run() -> void:
    SettingsState.mute_all_sfx()
    LocalizationService.set_test_device_locale("en_US")
    LocalizationService.select_language("automatic")
    readiness()
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.set_physics_process(false)
    await frames(10)
    sim.new_profile();sim.state.tutorial.mode="none";sim.campaign.onboarding.reveal_all(true);sim.state.tutorial.seen.append("road_ahead");sim.touch()
    await frames(6)
    await content()
    for size in [Vector2i(432,960),Vector2i(540,960),Vector2i(768,1024)]:
        await placement(size)
    await input_paths()
    LocalizationService.select_language("automatic")
    LocalizationService.set_test_device_locale("")
    print("CHANGE_40_PROBE checks=%d failures=%d" % [checks,failures])
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    get_tree().quit(1 if failures>0 else 0)

func dropdown() -> OptionButton:
    for b in game.rows.find_children("*","OptionButton",true,false):
        if b.get_script()==game.LANGUAGE_DROPDOWN:return b
    return null

func key(action: StringName,pressed:=true) -> void:
    var e:=InputEventAction.new();e.action=action;e.pressed=pressed
    get_tree().root.push_input(e)

## A real Escape key press and release (game_ui handles Escape in _unhandled_key_input, which sees key events only).
func escape() -> void:
    for pressed in [true,false]:
        var e:=InputEventKey.new();e.keycode=KEY_ESCAPE;e.physical_keycode=KEY_ESCAPE;e.pressed=pressed
        get_tree().root.push_input(e);await frames(1)
    await frames(2)

# ---------------------------------------------------------------- 1. readiness
func readiness() -> void:
    var service=LocalizationService
    var enabled: Array=service.ENABLED_LANGUAGES
    for pair in [["en_US","en_US"],["en_GB","en_US"],["en","en_US"],["","en_US"],["es_ES","es_ES"],["es-ES","es_ES"],["es_419","es_419"],["es_MX","es_419"],["es","es_419"],["pt_BR","pt_BR"],["pt_PT","pt_BR"],["pt","pt_BR"],["fr_BE","fr_FR"],["de_LI","de_DE"],["it_IT","it_IT"],["nl_NL","nl_NL"],["pl_PL","pl_PL"],["ru_RU","ru_RU"],["ru_BY","ru_RU"],["uk_UA","uk_UA"],["uk","uk_UA"],["sr_Latn_RS","en_US"],["sv_SE","en_US"],["ru_RU.UTF-8","ru_RU"],["de_DE@euro","de_DE"],["ar_EG","en_US"]]:
        check(service.match_device_locale(pair[0],enabled)==pair[1],"Device %s -> %s (got %s)" % [pair[0],pair[1],service.match_device_locale(pair[0],enabled)])
    # Draft languages are never chosen, whatever the device reports (incl. legacy "in" and script tags).
    var reached: Array=[]
    for device in ["ja_JP","ko_KR","zh_CN","zh_TW","zh_Hant_HK","zh_Hans_CN","zh"]:
        var got: String=service.match_device_locale(device,enabled)
        if got!="en_US":reached.append(device+"->"+got)
    check(reached.is_empty(),"No device locale reaches a Batch 04 draft; all fall back to English (%s)" % str(reached))
    # The rules for future batches already route correctly once a locale is enabled (pure function, no catalogs).
    var future:=["en_US","id_ID","zh_CN","zh_TW"]
    check(service.match_device_locale("in_ID",future)=="id_ID" and service.match_device_locale("zh_Hant_HK",future)=="zh_TW" and service.match_device_locale("zh_HK",future)=="zh_TW" and service.match_device_locale("zh_SG",future)=="zh_CN" and service.match_device_locale("zh",future)=="zh_CN","Legacy Indonesian and Chinese script/region rules are ready for later batches")
    check(service.ENABLED_LANGUAGES.all(func(l):return l in service.RELEASE_LANGUAGES and service.NATIVE_NAMES.has(l) and service.GODOT_LOCALES.has(l)),"Every enabled language is a target language with a native name and a Godot locale")
    check(not service.ALL_LANGUAGES_CERTIFIED and service.ENABLED_LANGUAGES.size()<service.RELEASE_LANGUAGES.size(),"Enabled is not certified: the final 20-language QA gate is still open")

# ---------------------------------------------------------------- 2. content
func content() -> void:
    game._open("settings");await frames(4)
    var d:=dropdown()
    check(d!=null and d.item_count==LocalizationService.available_languages().size()+1 and d.auto_translate_mode==Node.AUTO_TRANSLATE_MODE_DISABLED,"One dropdown with Automatic plus every enabled language (%d choices), never auto-translated" % d.item_count)
    var natives: Array=range(1,d.item_count).map(func(i):return d.get_item_text(i))
    LocalizationService.select_language("uk_UA");await frames(6)
    d=dropdown()
    check(range(1,d.item_count).map(func(i):return d.get_item_text(i))==natives,"Language names stay the same in a Ukrainian UI")
    check(d.text=="Українська" and d.get_item_text(0)=="Автоматично (English)","Closed: Українська; Automatic reads Автоматично (English)")
    LocalizationService.set_test_device_locale("de_AT")
    LocalizationService.select_language("automatic");await frames(6)
    d=dropdown()
    check(TranslationServer.get_locale()=="de_DE" and d.text=="Automatisch (Deutsch)" and d.selected==0,"Automatic on an Austrian device: German UI, the closed dropdown reads Automatisch (Deutsch)")
    LocalizationService.set_test_device_locale("en_US");await frames(6)
    d=dropdown()
    check(TranslationServer.get_locale()=="en" and d.text=="Automatic (English)","…and follows the device back to English")
    check(d.get_global_rect().size.y>=64 and d.text_overrun_behavior==TextServer.OVERRUN_TRIM_ELLIPSIS,"The closed control is thumb-sized and trims rather than overflows")
    game._close();await frames(2)

# ---------------------------------------------------------------- 3. placement
func settle() -> void:
    var top: Control=game.get_node("Safe/Layout/Top")
    var last:=Rect2();var since:=Time.get_ticks_msec()
    for i in range(3000):
        await get_tree().process_frame
        var r:=top.get_global_rect()
        if r!=last:last=r;since=Time.get_ticks_msec()
        elif Time.get_ticks_msec()-since>=600:return

## PopupMenu keeps its ScrollContainer among internal children (PanelContainer > VBoxContainer > ...).
func menu_scroll(node: Node) -> ScrollContainer:
    for c in node.get_children(true):
        if c is ScrollContainer:return c
        var found:=menu_scroll(c)
        if found!=null:return found
    return null

func placement(size: Vector2i) -> void:
    get_window().size=size
    await settle()
    shape="%dx%d" % [size.x,size.y]
    game._open("settings");await frames(8)
    var scroll: ScrollContainer=game.get_node("Sheet/Margin/Content/Scroll")
    for where in ["top","bottom"]:
        scroll.scroll_vertical=0 if where=="top" else int(scroll.get_v_scroll_bar().max_value)
        await frames(4)
        var d:=dropdown()
        var button:=d.get_global_rect()
        d.show_popup();await frames(3)
        var menu:=d.get_popup()
        var rect:=Rect2(Vector2(menu.position),Vector2(menu.size))
        var view:=get_viewport().get_visible_rect()
        var rows: int=d.item_count
        var row: float=(menu.get_contents_minimum_size().y-menu.get_theme_stylebox("panel").get_minimum_size().y)/rows
        var label:="%s, Settings at the %s (button %s, menu %s, view %s)" % [shape,where,str(button),str(rect),str(view.size)]
        check(menu.visible and view.encloses(rect),"Menu inside the visible screen: "+label)
        check(absf(rect.size.x-maxf(button.size.x,menu.get_contents_minimum_size().x))<2,"Menu as wide as the button: "+label)
        check(not rect.intersects(button.grow(-1)),"Menu opens beside the button, not over it: "+label)
        check(row>=56,"Rows are thumb-sized (%d units): %s" % [int(row),label])
        var bar:=menu_scroll(menu).get_v_scroll_bar() if menu_scroll(menu)!=null else null
        var taller: bool=menu.get_contents_minimum_size().y>rect.size.y+1
        if taller:
            check(bar!=null and bar.visible and bar.max_value>bar.page,"Taller than the room: the menu scrolls with a visible bar: "+label)
            print("info  scrolling menu at ",label)
        else:
            check(rect.size.y>=menu.get_contents_minimum_size().y-1,"All %d rows fit without scrolling: %s" % [rows,label])
        check(d.selected>=0 and d.get_popup().is_item_checked(d.selected),"The current choice is marked in the menu: "+label)
        d.close_menu();await frames(2)
    game._close();await frames(2)

# ---------------------------------------------------------------- 4. input
func input_paths() -> void:
    get_window().size=Vector2i(432,960)
    await settle()
    game._open("settings");await frames(6)
    var scroll: ScrollContainer=game.get_node("Sheet/Margin/Content/Scroll")
    scroll.scroll_vertical=int(scroll.get_v_scroll_bar().max_value);await frames(4)
    var offset:=scroll.scroll_vertical
    var d:=dropdown()
    # Keyboard/controller: focus, ui_accept opens on the current item, ui_down moves, ui_accept chooses.
    d.grab_focus();await frames(1)
    key(&"ui_accept");key(&"ui_accept",false);await frames(3)
    check(d.is_menu_open() and d.get_popup().get_focused_item()==d.selected,"ui_accept opens the menu on the current choice (%d)" % d.get_popup().get_focused_item())
    for i in range(6):
        key(&"ui_down");key(&"ui_down",false);await frames(1)
    var target: String=d.get_item_metadata(d.get_popup().get_focused_item())
    key(&"ui_accept");key(&"ui_accept",false);await frames(8)
    d=dropdown()
    check(not d.is_menu_open() and SettingsState.selected_language==target and target=="de_DE","Six steps down and ui_accept choose %s and close the menu" % target)
    check(game.sheet.visible and game.panel=="settings" and dropdown()==d,"Settings stays open with the same dropdown")
    await get_tree().create_timer(.2).timeout
    check(absi(scroll.scroll_vertical-offset)<=8,"The Settings scroll position is kept across the language switch (%d -> %d)" % [offset,scroll.scroll_vertical])
    # Escape closes only the menu.
    d.show_popup();await frames(2)
    await escape()
    check(not d.is_menu_open() and game.sheet.visible,"Escape closes the menu and leaves Settings open")
    await escape()
    check(not game.sheet.visible,"A second Escape closes Settings")
    game._open("settings");await frames(6)
    d=dropdown()
    # Android Back: the menu first, then the panel.
    d.show_popup();await frames(2)
    game._notification(NOTIFICATION_WM_GO_BACK_REQUEST);await frames(3)
    check(not d.is_menu_open() and game.sheet.visible,"Android Back closes the menu and leaves Settings open")
    game._notification(NOTIFICATION_WM_GO_BACK_REQUEST);await frames(3)
    check(not game.sheet.visible,"The next Back closes Settings")
    game._open("settings");await frames(6)
    d=dropdown()
    # A tap outside the menu (on the map) closes it and does not reach the map.
    d.show_popup();await frames(2)
    var menu_rect:=Rect2(Vector2(d.get_popup().position),Vector2(d.get_popup().size))
    # The point is on the map above the Settings sheet, so the press would start a map gesture if it got through.
    var map_top: float=game.get_node("Safe/Layout/Map").get_global_rect().position.y
    var outside:=Vector2(get_viewport().get_visible_rect().size.x*.5,(map_top+game.sheet.get_global_rect().position.y)*.5)
    var surface=game.get_node("Safe/Layout/Map/GestureSurface")
    check(not menu_rect.has_point(outside) and surface.get_global_rect().has_point(outside) and not game.sheet.get_global_rect().has_point(outside),"(fixture) the tap point %s is on the map, outside the menu and the sheet" % str(outside))
    var press:=InputEventMouseButton.new();press.button_index=MOUSE_BUTTON_LEFT;press.pressed=true;press.position=outside;press.global_position=outside
    get_tree().root.push_input(press);await frames(1)
    var reached: bool=not surface.pointers.is_empty()
    var release:=press.duplicate();release.pressed=false
    get_tree().root.push_input(release);await frames(3)
    check(not d.is_menu_open(),"A tap outside closes the menu")
    check(not reached and game.sheet.visible,"…and the tap does not reach the map (no gesture began) or close Settings")
    # Panel refreshes while the menu is open do not rebuild or close it.
    d.show_popup();await frames(2)
    for i in range(4):
        sim.state.coins+=1.0;sim.touch();await get_tree().create_timer(.3).timeout
    check(d.is_menu_open() and dropdown()==d and d.item_count==LocalizationService.available_languages().size()+1,"Panel refreshes keep the open menu and its items")
    # Resizing the window (rotation, split screen) closes it rather than leaving it misplaced.
    get_window().size=Vector2i(540,960);await frames(3)
    check(not d.is_menu_open(),"A window resize closes the menu")
    await settle()
    # Closing Settings leaves no menu behind.
    d=dropdown()
    d.show_popup();await frames(2)
    var was_open: bool=d.is_menu_open()
    game._close();await frames(3)
    check(was_open and not d.get_popup().visible,"Closing Settings closes its menu (was open: %s, visible in tree: %s)" % [was_open,d.is_visible_in_tree()])
    LocalizationService.select_language("automatic");await frames(4)
