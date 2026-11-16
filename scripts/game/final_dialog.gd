extends Control
## Change 83: the two Green Alien decisions, built from the game's own panel styles (theme Card, Primary, Danger,
## HudChipButton). While either is open the world is held (game_ui adds it to sim.held and modal_open) and Back
## answers it with the safe choice.
##
##   warning  "FINAL BOSS — DANGER" before the first updated encounter: no escape once the arena seals. Set
##            Recommended Volume (Music 40% / Sound Effects 100%, temporary; it does not answer the question),
##            Yes, Fight! (accept: saved, then the 13-key ceremony) and No, Not Yet (cancel; asked again later).
##   ending   the one-time end of the main adventure, after the first victory's celebration (or after a later
##            victory when it was never acknowledged): Continue Playing, Leave an Honest Review (the build's
##            storefront), Join Our Discord. Any of the three acknowledges it once; the links never block play.
##
## Layout: one centred card at most 600 wide and inside the safe area, its body scrolling if a language runs
## long; buttons are full-width rows (64 px tall) so long translations wrap instead of truncating.
signal answered(kind: String,choice: String)

const BOSS_RED:=Color(1,.36,.32)
const GOLD:=Color(1,.86,.5)
var kind:=""
var dim: ColorRect
var card: PanelContainer
var art: TextureRect
var title: Label
var body: Label
var note: Label
var buttons: VBoxContainer
var scroll: ScrollContainer
var generation:=0

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter=Control.MOUSE_FILTER_STOP
    process_mode=Node.PROCESS_MODE_ALWAYS
    z_index=21
    dim=ColorRect.new();dim.color=Color(0,0,0,.62);dim.mouse_filter=Control.MOUSE_FILTER_STOP
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(dim)
    card=PanelContainer.new();card.theme_type_variation=&"Card"
    add_child(card)
    var margin:=MarginContainer.new()
    for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,18)
    card.add_child(margin)
    var box:=VBoxContainer.new();box.add_theme_constant_override("separation",10)
    margin.add_child(box)
    var head:=HBoxContainer.new();head.add_theme_constant_override("separation",12);head.alignment=BoxContainer.ALIGNMENT_CENTER
    box.add_child(head)
    art=TextureRect.new();art.custom_minimum_size=Vector2(64,64);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    head.add_child(art)
    title=Label.new();title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    title.add_theme_font_size_override("font_size",28);title.add_theme_constant_override("outline_size",6)
    title.add_theme_color_override("font_outline_color",Color.BLACK)
    head.add_child(title)
    scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
    scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
    box.add_child(scroll)
    var text:=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;text.add_theme_constant_override("separation",8)
    scroll.add_child(text)
    body=Label.new();body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    body.add_theme_font_size_override("font_size",20)
    text.add_child(body)
    note=Label.new();note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;note.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    note.add_theme_font_size_override("font_size",17);note.add_theme_color_override("font_color",Color(.8,.84,.9))
    text.add_child(note)
    buttons=VBoxContainer.new();buttons.add_theme_constant_override("separation",8)
    box.add_child(buttons)
    hide()

func is_open() -> bool:return visible

## The danger question. recommended: whether the temporary mix is on now (the button says so).
func open_warning(boss_art: Texture2D) -> void:
    kind="warning"
    art.texture=boss_art
    title.text=tr("FINAL_DANGER_TITLE");title.add_theme_color_override("font_color",BOSS_RED)
    body.text=tr("FINAL_DANGER_BODY")
    note.text=tr("FINAL_DANGER_AUDIO_NOTE");note.visible=true
    _clear_buttons()
    var audio:=_button("",&"HudChipButton",func()->void:_toggle_audio())
    audio.set_meta("final_role","audio")
    _sync_audio_button()
    var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);buttons.add_child(row)
    var yes:=_button(tr("FINAL_DANGER_YES"),&"Danger",func()->void:_answer("yes"),row);yes.set_meta("final_role","yes")
    var no:=_button(tr("FINAL_DANGER_NO"),&"",func()->void:_answer("no"),row);no.set_meta("final_role","no")
    _show()
    no.grab_focus()

## The one-time ending message.
func open_ending(hero_art: Texture2D) -> void:
    kind="ending"
    art.texture=hero_art
    title.text=tr("FINAL_ENDING_TITLE");title.add_theme_color_override("font_color",GOLD)
    body.text=tr("FINAL_ENDING_BODY")
    note.visible=false
    _clear_buttons()
    _button(tr("FINAL_ENDING_CONTINUE"),&"Primary",func()->void:_answer("continue")).set_meta("final_role","continue")
    _button(tr("FINAL_ENDING_REVIEW"),&"",func()->void:_answer("review")).set_meta("final_role","review")
    _button(tr("FINAL_ENDING_DISCORD"),&"",func()->void:_answer("discord")).set_meta("final_role","discord")
    _show()

## Back / Escape: the safe answer (No for the warning, Continue for the ending).
func back() -> void:
    if not visible:return
    _answer("no" if kind=="warning" else "continue")

func close() -> void:
    generation+=1
    hide();kind=""

## A button of the open panel by role (probes and the guide pointer).
func button(role: String) -> Button:
    for b in buttons.find_children("*","Button",true,false):
        if b.get_meta("final_role","")==role:return b
    return null

func _answer(choice: String) -> void:
    var was:=kind
    if choice!="audio":close()
    answered.emit(was,choice)

func _toggle_audio() -> void:
    if SettingsState.recommended_active():SettingsState.restore_recommended()
    else:SettingsState.apply_recommended()
    AudioService.play("ui_confirm")
    _sync_audio_button()

func _sync_audio_button() -> void:
    var b:=button("audio")
    if b==null:return
    b.text=tr("FINAL_AUDIO_ON") if SettingsState.recommended_active() else tr("FINAL_DANGER_AUDIO")

func _clear_buttons() -> void:
    for child in buttons.get_children():
        buttons.remove_child(child);child.queue_free()

func _button(text: String,variation: StringName,callback: Callable,parent: Node=null) -> Button:
    var b:=Button.new()
    b.text=text;b.theme_type_variation=variation
    b.custom_minimum_size=Vector2(0,64)
    b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    b.add_theme_font_size_override("font_size",20)
    b.pressed.connect(callback)
    (parent if parent!=null else buttons).add_child(b)
    return b

func _show() -> void:
    generation+=1
    var g:=generation
    modulate.a=0.0
    show()
    _layout()
    await get_tree().process_frame
    if g!=generation:return
    _layout()
    await get_tree().process_frame
    if g!=generation:return
    _layout()
    modulate.a=1.0
    card.pivot_offset=card.size*.5
    card.scale=Vector2.ONE*.9
    create_tween().tween_property(card,"scale",Vector2.ONE,.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _notification(what: int) -> void:
    if what==NOTIFICATION_RESIZED and visible and body!=null:_layout()

## A centred card inside the safe area: at most 600 wide, as tall as its content (the body scrolls beyond).
func _layout() -> void:
    var insets: Vector4=LayoutService.get_safe_area_insets_canvas()
    var room:=size-Vector2(insets.x+insets.z,insets.y+insets.w)-Vector2(32,48)
    if room.x<=0 or room.y<=0:return
    var width:=minf(600.0,room.x)
    body.custom_minimum_size.x=width-36.0
    note.custom_minimum_size.x=width-36.0
    var content:=body.get_combined_minimum_size().y+(note.get_combined_minimum_size().y+8.0 if note.visible else 0.0)
    scroll.custom_minimum_size.y=0
    card.size=Vector2(width,0)
    var chrome:=card.get_combined_minimum_size().y
    var height:=minf(room.y,chrome+content)
    scroll.custom_minimum_size.y=maxf(60.0,height-chrome)
    card.size=Vector2(width,height)
    card.position=Vector2(insets.x+(size.x-insets.x-insets.z-width)*.5,insets.y+24.0+(room.y-height)*.5)
