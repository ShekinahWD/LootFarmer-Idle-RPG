extends OptionButton
## Settings › Language (Change 40, Playbook 129.1, 132.2): one dropdown of the languages this build offers, each
## in its own language and script, Automatic first with the language it resolves to ("Automatic (Deutsch)").
## Its menu opens below the button, or above when there is more room there, always inside the safe area, and
## scrolls when the list is taller than the room. Tap outside, Escape and Android Back close it (game_ui.back); a
## full-screen scrim dims the screen behind the menu and keeps the tap that closes it from reaching the map or HUD.
## The panel reconciler reuses this control across refreshes, so it keeps its own items up to date: it rebuilds
## them only when the offered list, the choice or the locale changes, and never while the menu is open.

const GROUP := &"dropdown"
const MARGIN := 12.0
## Below this many rows on the roomier side, the menu covers the button instead (still inside the safe area).
const MIN_ROWS := 3

var _signature := ""
## The process frame the menu last closed in: the Escape that closed it must not also close the panel.
var closed_frame := -1
## Shown while the menu is open, until the end of the frame it closes in (Playbook 129.1).
var catcher := ColorRect.new()
## The engine's dropdown arrow, drawn at twice its size so it reads as a dropdown at phone scale.
static var _arrow: Texture2D


func _init() -> void:
    auto_translate_mode = AUTO_TRANSLATE_MODE_DISABLED
    text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    alignment = HORIZONTAL_ALIGNMENT_LEFT
    size_flags_horizontal = SIZE_EXPAND_FILL
    custom_minimum_size = Vector2(0, 72)
    add_theme_font_size_override("font_size", 22)
    add_theme_constant_override("arrow_margin", 18)
    if _arrow == null:
        var image := ThemeDB.get_default_theme().get_icon("arrow", "OptionButton").get_image()
        image.resize(image.get_width() * 2, image.get_height() * 2, Image.INTERPOLATE_BILINEAR)
        _arrow = ImageTexture.create_from_image(image)
    add_theme_icon_override("arrow", _arrow)
    var menu := get_popup()
    menu.auto_translate_mode = AUTO_TRANSLATE_MODE_DISABLED
    menu.about_to_popup.connect(_place_menu)
    menu.popup_hide.connect(_menu_closed)
    # An internal, top-level child: the panel reconciler never sees it, and it covers the whole screen.
    catcher.name = "OutsideTapCatcher"
    catcher.top_level = true
    catcher.color = Color(0, 0, 0, 0.45)
    # A top-level item draws first among the canvas roots; z_index lifts it over the HUD and the sheet (the menu,
    # an embedded window, still draws above it).
    catcher.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
    catcher.mouse_filter = MOUSE_FILTER_STOP
    catcher.visible = false
    catcher.gui_input.connect(func(_event: InputEvent) -> void: catcher.accept_event())
    add_child(catcher, false, INTERNAL_MODE_FRONT)
    item_selected.connect(_on_item_selected)
    # The off-tree description the panel builds is compared with the live control by its text: fill it now.
    refresh()


func _enter_tree() -> void:
    add_to_group(GROUP)
    _style_menu_scroll_bar(get_popup())
    if not SettingsState.settings_changed.is_connected(refresh):
        SettingsState.settings_changed.connect(refresh)
    if not get_viewport().size_changed.is_connected(close_menu):
        get_viewport().size_changed.connect(close_menu)
    refresh()


func _exit_tree() -> void:
    close_menu()
    if SettingsState.settings_changed.is_connected(refresh):
        SettingsState.settings_changed.disconnect(refresh)
    if get_viewport().size_changed.is_connected(close_menu):
        get_viewport().size_changed.disconnect(close_menu)


func _notification(what: int) -> void:
    if what == NOTIFICATION_TRANSLATION_CHANGED:
        refresh()
    elif what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
        close_menu()


## A scrolling menu shows an obvious thumb on its dark panel (Playbook 146.6, last paragraph): wider, in the theme's slider fill
## (the volume sliders' blue) on the slider track.
func _style_menu_scroll_bar(node: Node) -> void:
    for child in node.get_children(true):
        if child is ScrollContainer:
            var bar: VScrollBar = child.get_v_scroll_bar()
            bar.custom_minimum_size.x = 14
            var thumb := get_theme_stylebox("grabber_area", "HSlider")
            var track := get_theme_stylebox("slider", "HSlider")
            bar.add_theme_stylebox_override("grabber", thumb)
            bar.add_theme_stylebox_override("grabber_highlight", thumb)
            bar.add_theme_stylebox_override("grabber_pressed", thumb)
            bar.add_theme_stylebox_override("scroll", track)
            return
        _style_menu_scroll_bar(child)


func is_menu_open() -> bool:
    return get_popup().visible


func close_menu() -> void:
    if get_popup().visible:
        get_popup().hide()


## Choices in order: Automatic, then the offered languages in release order.
func choices() -> Array[String]:
    var out: Array[String] = ["automatic"]
    out.append_array(LocalizationService.available_languages())
    return out


func label_of(choice: String) -> String:
    if choice == "automatic":
        var resolved := LocalizationService.resolved_language("automatic")
        return "%s (%s)" % [TranslationServer.translate("LANG_AUTOMATIC"), LocalizationService.NATIVE_NAMES.get(resolved, resolved)]
    return LocalizationService.NATIVE_NAMES.get(choice, choice)


## The choice the closed control shows: the preference, or English for a stored language this build lacks.
func current_choice() -> String:
    var value := SettingsState.selected_language
    return value if LocalizationService.is_selectable(value) else "en_US"


func refresh() -> void:
    if get_popup().visible:
        return
    var list := choices()
    var labels: Array[String] = []
    for choice in list:
        labels.append(label_of(choice))
    var current := current_choice()
    var signature := "|".join(labels) + "#" + current
    if signature == _signature:
        return
    _signature = signature
    clear()
    for i in range(list.size()):
        add_item(labels[i], i)
        set_item_metadata(i, list[i])
    select(list.find(current))


func _on_item_selected(index: int) -> void:
    var choice: String = get_item_metadata(index)
    if LocalizationService.select_language(choice):
        SaveService.mark_committed()
    AudioService.play("ui_click")
    refresh()


func _menu_closed() -> void:
    closed_frame = Engine.get_process_frames()
    catcher.hide.call_deferred()
    refresh.call_deferred()


## Called as the menu opens (before it is shown): its width matches the button, it opens on the side with
## more room, and a list taller than that room scrolls with half a row showing at the edge.
func _place_menu() -> void:
    var menu := get_popup()
    var view := get_viewport().get_visible_rect()
    var insets: Vector4 = LayoutService.get_safe_area_insets_canvas()
    var safe := Rect2(view.position + Vector2(insets.x, insets.y), view.size - Vector2(insets.x + insets.z, insets.y + insets.w)).grow(-MARGIN)
    var button := get_global_rect()
    catcher.position = view.position
    catcher.size = view.size
    catcher.show()
    menu.min_size = Vector2i.ZERO
    menu.max_size = Vector2i.ZERO
    var content: Vector2 = menu.get_contents_minimum_size()
    var rows := maxi(1, item_count)
    var chrome := menu.get_theme_stylebox("panel").get_minimum_size().y
    var row := (content.y - chrome) / rows
    var width := minf(maxf(button.size.x, content.x), safe.size.x)
    var below := safe.end.y - button.end.y
    var above := button.position.y - safe.position.y
    var room := maxf(below, above)
    var height := content.y
    var y := button.end.y
    if room < chrome + row * MIN_ROWS:
        height = minf(content.y, safe.size.y)
        y = clampf(button.end.y, safe.position.y, safe.end.y - height)
    else:
        if content.y > room:
            height = chrome + (floorf((room - chrome) / row - 0.5) + 0.5) * row
        if content.y > below and above > below:
            y = button.position.y - height
    var x := clampf(button.position.x, safe.position.x, safe.end.x - width)
    menu_rect = Rect2i(int(x), int(y), int(width), int(height))
    # OptionButton positions and sizes the menu itself after this signal; only the size limits survive, so the
    # final rectangle is applied once the menu is open (still before it is drawn).
    menu.min_size = menu_rect.size
    menu.max_size = menu_rect.size
    _apply_menu_rect.call_deferred()


## Where the menu was placed when it last opened (canvas units), for probes and captures.
var menu_rect := Rect2i()


func _apply_menu_rect() -> void:
    var menu := get_popup()
    if not menu.visible:
        return
    menu.position = menu_rect.position
    menu.size = menu_rect.size
    if selected >= 0:
        menu.scroll_to_item(selected)
