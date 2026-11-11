extends Control
## Change 65: the one tutorial-card viewer (Playbook 18.2: the Basic opening opens the very deck Help
## offers). It shows a card of help_cards.gd: its title, one action line, one support line and its looping
## demonstration (help_demo.gd), with Previous / Next, the position (N/8 in the Basic opening, N/14 in
## Help), Auto-Advance, and Back to Topics + Close (Help) or Skip Overview (Basic).
## While it is open the world is held (game_ui sets sim.held), as for the review invitation: reading a card
## costs no health, time or loot. Its panel has one fixed size per screen size, so cards never move it.
## A card counts as viewed after a deliberate Next / Finish, a Close or Back to Topics after a short look
## (VIEW_SECONDS), or a completed Auto-Advance wait; never merely for appearing.
signal finished(context: String)
signal topics_requested(category: String)
const HelpCards=preload("res://scripts/game/help_cards.gd")
const HelpDemo=preload("res://scripts/game/help_demo.gd")
const VIEW_SECONDS:=1.0
const BUTTON_HEIGHT:=72.0
## Text sizes (canvas units). The panel is only as tall as its content (no empty band).
const TITLE_SIZE:=36
const ACTION_SIZE:=31
const SUPPORT_SIZE:=25
const NOTE_SIZE:=22
var ui
var sim
## "basic" (the Basic opening), "help_all" (Read All Tutorials) or "help_topic" (a card chosen by topic).
var context:=""
var sequence: Array=[]
var index:=0
var auto:=false
## Active seconds the current card has been on screen, and the part counted toward Auto-Advance.
var shown:=0.0
var dwell:=0.0
var backdrop: ColorRect
var panel: PanelContainer
var position_label: Label
var category_label: Label
var title_label: Label
var action_label: Label
var support_label: Label
var note_label: Label
var demo: Control
var auto_bar: ProgressBar
var prev_button: Button
var next_button: Button
var auto_button: Button
var topics_button: Button
var close_button: Button
var skip_button: Button

func setup(owner_ui) -> void:
    ui=owner_ui;sim=ui.sim
    name="HelpViewer"
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter=Control.MOUSE_FILTER_STOP
    theme=ui.theme
    backdrop=ColorRect.new();backdrop.color=Color(0,0,0,.72);backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(backdrop)
    panel=PanelContainer.new();panel.name="Panel";panel.theme_type_variation=&"Backing";add_child(panel)
    var margin:=MarginContainer.new()
    for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,14)
    panel.add_child(margin)
    var box:=VBoxContainer.new();box.name="Content";box.add_theme_constant_override("separation",8);margin.add_child(box)
    var head:=HBoxContainer.new();head.add_theme_constant_override("separation",10);box.add_child(head)
    category_label=_label(20,Color(.72,.88,1));category_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;category_label.autowrap_mode=TextServer.AUTOWRAP_OFF
    category_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;head.add_child(category_label)
    position_label=_label(21,Color(1,.88,.5));position_label.autowrap_mode=TextServer.AUTOWRAP_OFF;position_label.name="Position";head.add_child(position_label)
    title_label=_label(TITLE_SIZE,Color(1,.88,.5));title_label.name="Title";title_label.add_theme_constant_override("outline_size",4);box.add_child(title_label)
    demo=HelpDemo.new();demo.name="Demo";demo.size_flags_horizontal=Control.SIZE_EXPAND_FILL;box.add_child(demo);demo.setup(ui)
    auto_bar=ProgressBar.new();auto_bar.show_percentage=false;auto_bar.custom_minimum_size=Vector2(0,6);auto_bar.max_value=1.0;auto_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(auto_bar)
    action_label=_label(ACTION_SIZE,Color.WHITE);action_label.name="Action";box.add_child(action_label)
    support_label=_label(SUPPORT_SIZE,Color(.85,.88,.93));support_label.name="Support";box.add_child(support_label)
    note_label=_label(NOTE_SIZE,Color(.6,1,.75));note_label.name="Note";box.add_child(note_label)
    var nav:=HBoxContainer.new();nav.add_theme_constant_override("separation",10);box.add_child(nav)
    prev_button=_button(nav,"Previous",func()->void:step(-1))
    next_button=_button(nav,"Next",func()->void:step(1));next_button.theme_type_variation=&"Primary"
    var extra:=HBoxContainer.new();extra.add_theme_constant_override("separation",10);box.add_child(extra)
    auto_button=_button(extra,"Auto",toggle_auto)
    topics_button=_button(extra,"Topics",back_to_topics)
    skip_button=_button(extra,"Skip",func()->void:close_viewer())
    close_button=_button(extra,"Close",func()->void:close_viewer())
    hide()

func _label(font_size: int,color: Color) -> Label:
    var l:=Label.new();l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.mouse_filter=Control.MOUSE_FILTER_IGNORE
    l.add_theme_font_size_override("font_size",font_size);l.add_theme_color_override("font_color",color)
    return l

func _button(parent: Node,label: String,callback: Callable) -> Button:
    var b:=Button.new();b.name=label;b.custom_minimum_size=Vector2(0,BUTTON_HEIGHT);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    # Longer languages wrap to a second line inside the fixed button height rather than being cut.
    b.focus_mode=Control.FOCUS_NONE;b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    b.add_theme_font_size_override("font_size",22)
    b.pressed.connect(func()->void:
        callback.call()
        AudioService.play("ui_click"))
    parent.add_child(b)
    return b

func is_open() -> bool:
    return visible

func tutorial() -> Dictionary:
    return sim.state.tutorial

func current() -> String:
    return str(sequence[index]) if index>=0 and index<sequence.size() else ""

## The Basic opening: the first ESSENTIAL_COUNT cards, from the card it was last on. Auto-Advance starts
## off (the player reads at their own pace and can turn it on).
func open_basic() -> void:
    var deck:=HelpCards.essential()
    var start:=maxi(0,deck.find(str(HelpCards.progress(tutorial()).get("basic_last",""))))
    open("basic",deck,start,false)

## Help: all cards in Read All order from start_index, with the saved Auto-Advance preference.
func open_help(ctx: String,start_index: int) -> void:
    open(ctx,HelpCards.ids(),start_index,bool(HelpCards.progress(tutorial()).auto))

func open(ctx: String,ids: Array,start_index: int,auto_on: bool) -> void:
    context=ctx;sequence=ids.duplicate();index=clampi(start_index,0,sequence.size()-1);auto=auto_on
    ui.get_node("Safe/Layout/Map/GestureSurface").cancel_gesture()
    ui.stick.release()
    show()
    _localize()
    _show_card()
    _layout()

func _show_card() -> void:
    shown=0.0;dwell=0.0
    demo.show_card(current())
    var t:=tutorial()
    if context=="basic":
        HelpCards.progress(t).basic_last=current()
    else:
        HelpCards.set_last(t,current())
    SaveService.mark_dirty()
    _refresh_texts()

func _refresh_texts() -> void:
    var id:=current()
    title_label.text=tr(HelpCards.title_key(id))
    action_label.text=tr(HelpCards.action_key(id))
    support_label.text=tr(HelpCards.support_key(id))
    position_label.text="%d/%d" % [index+1,sequence.size()]
    var help:=context!="basic"
    var seen:=HelpCards.viewed(tutorial(),id)
    category_label.text=tr(HelpCards.category_key(HelpCards.category_of(id)))+("  ·  "+tr("HELP_VIEWED" if seen else "HELP_NOT_VIEWED") if help else "")
    # The Basic opening's last card says where the full library lives (no extra forced cards).
    var last:=index==sequence.size()-1
    note_label.text=tr("HELP_DISCOVERY_BASIC") if context=="basic" and last else ""
    note_label.visible=context=="basic"
    prev_button.disabled=index==0
    next_button.text=tr("HELP_FINISH") if last and context=="basic" else tr("HELP_NEXT")
    next_button.disabled=last and context!="basic"
    prev_button.text=tr("HELP_PREVIOUS")
    auto_button.text=tr("HELP_AUTO_ADVANCE") % tr("ON" if auto else "OFF")
    topics_button.text=tr("HELP_BACK_TO_TOPICS");topics_button.visible=help
    close_button.text=tr("CLOSE");close_button.visible=help
    skip_button.text=tr("HELP_SKIP_OVERVIEW");skip_button.visible=not help and not last
    auto_bar.value=0.0
    auto_bar.modulate.a=1.0 if auto else 0.25

func _localize() -> void:
    if visible and current()!="":_refresh_texts()

func _notification(what: int) -> void:
    if what==NOTIFICATION_TRANSLATION_CHANGED and title_label!=null:_localize()

## Previous (-1) / Next (+1). Next marks the card viewed; Next on the Basic opening's last card finishes it.
func step(delta: int) -> void:
    if not visible:return
    if delta>0:_mark_viewed()
    if delta>0 and index>=sequence.size()-1:
        if context=="basic":close_viewer()
        return
    index=clampi(index+delta,0,sequence.size()-1)
    _show_card()

func toggle_auto() -> void:
    auto=not auto;dwell=0.0
    if context!="basic":HelpCards.progress(tutorial()).auto=auto;SaveService.mark_dirty()
    _refresh_texts()

func back_to_topics() -> void:
    var category:=HelpCards.category_of(current())
    _leave()
    topics_requested.emit(category)

## Close (Help), Finish or Skip Overview (Basic). Closing the Basic opening finishes it for good.
func close_viewer() -> void:
    var ctx:=context
    _leave()
    if ctx=="basic":
        HelpCards.progress(tutorial()).basic_done=true
        sim.touch();SaveService.mark_committed()
    finished.emit(ctx)

func _leave() -> void:
    if shown>=VIEW_SECONDS:_mark_viewed()
    hide();demo.card_id=""
    SaveService.mark_dirty()

func _mark_viewed() -> void:
    if HelpCards.mark_viewed(tutorial(),current()):SaveService.mark_dirty()

## Android Back / Escape: Help returns to its topics, the Basic opening is skipped.
func back() -> void:
    if context=="basic":close_viewer()
    else:back_to_topics()

## The card advances (or stops on the last card, never wrapping) once its loop and reading time have
## both passed. The count runs only while the demo plays (visible, app in front) and no confirmation
## covers the viewer; Previous/Next restart it.
func _process(dt: float) -> void:
    if not visible:return
    _layout()
    var active: bool=demo.running() and not ui.get_node("Confirm").visible
    if not active:return
    shown+=dt
    if not auto:return
    var need:=HelpCards.dwell_seconds(current(),action_label.text,support_label.text)
    dwell=minf(need,dwell+dt)
    auto_bar.value=dwell/need
    if dwell>=need:
        _mark_viewed()
        if index<sequence.size()-1:
            index+=1;_show_card()
        else:
            # The last card stays (no wrap). The Basic opening finishes on its own after its last card.
            if context=="basic":close_viewer()
            else:auto=false;_refresh_texts()

## One size per screen size, sequence and language (Playbook 16.3, 19): the panel is as wide as the safe
## area allows (up to a cap) and only as tall as its content. The action, support and note lines reserve
## the height of the longest card of the open sequence in the current language, so moving between cards
## never resizes or moves the panel, and no card leaves an empty band. The demo keeps the 5:3 stage.
var _fitted:=""
var _demo_full:=240.0
func _layout() -> void:
    var insets:=LayoutService.get_safe_area_insets_canvas()
    var avail:=Vector2(ui.size.x-insets.x-insets.z,ui.size.y-insets.y-insets.w)
    var width:=minf(680.0,avail.x-24)
    var key:="%s:%s:%s:%d" % [str(avail),context,TranslationServer.get_locale(),sequence.size()]
    if key!=_fitted:
        _fitted=key
        var inner:=width-28-panel.get_theme_stylebox("panel").get_minimum_size().x
        # Wrapped labels measure their height at the panel's inner width (a zero width measures one
        # word per line and would stretch the panel far beyond the screen).
        for l in [title_label,action_label,support_label,note_label]:l.custom_minimum_size.x=inner
        var tallest:={"title":0.0,"action":0.0,"support":0.0}
        for id in sequence:
            tallest.title=maxf(tallest.title,_text_height(tr(HelpCards.title_key(id)),TITLE_SIZE,inner))
            tallest.action=maxf(tallest.action,_text_height(tr(HelpCards.action_key(id)),ACTION_SIZE,inner))
            tallest.support=maxf(tallest.support,_text_height(tr(HelpCards.support_key(id)),SUPPORT_SIZE,inner))
        title_label.custom_minimum_size.y=tallest.title
        action_label.custom_minimum_size.y=tallest.action
        support_label.custom_minimum_size.y=tallest.support
        # The Basic note shows on its last card only; its room is kept on every card of the opening.
        note_label.custom_minimum_size.y=_text_height(tr("HELP_DISCOVERY_BASIC"),NOTE_SIZE,inner) if context=="basic" else 0.0
        _demo_full=roundf(inner*.6)
        panel.size=Vector2(width,0)
    # The demo keeps the 5:3 stage at full width; on a screen shorter than the content it gives way first
    # (never the text or the controls). Recomputed from the full height each pass, so it never sticks small.
    var others: float=panel.get_combined_minimum_size().y-demo.custom_minimum_size.y
    var demo_h: float=clampf(avail.y-16-others,120.0,_demo_full)
    if demo.custom_minimum_size.y!=demo_h:demo.custom_minimum_size=Vector2(0,demo_h)
    var height:=minf(others+demo_h,avail.y-16)
    var wanted:=Vector2(width,height)
    # A container only grows to its contents, so the size is re-applied whenever it drifted.
    if not panel.size.is_equal_approx(wanted):panel.size=wanted
    var at:=Vector2(ui.centered_x(width,insets),insets.y+(avail.y-height)*.5)
    if not panel.position.is_equal_approx(at):panel.position=at

## The height a wrapped Label of this size needs for text at width: the wrapped lines times the Label's
## own line height (font height plus the theme's line spacing), plus its outline.
func _text_height(text: String,font_size: int,width: float) -> float:
    var font: Font=title_label.get_theme_font("font")
    var line: float=font.get_height(font_size)
    var lines: int=maxi(1,roundi(font.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,width,font_size).y/line))
    return ceilf(lines*(line+title_label.get_theme_constant("line_spacing")))
