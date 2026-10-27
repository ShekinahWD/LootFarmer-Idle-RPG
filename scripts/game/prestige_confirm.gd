extends Control
## Change 16: the Prestige confirmation as a milestone screen, in the visual language of the Prestige
## discovery banner (Backing plate, gold border, star art, animated sparks). It lists the opportunities
## being redeemed, then what is permanent (kept) and what this run resets, in two separate cards,
## with Cancel and Begin Prestige pinned under a scrolling body. Sized to the safe area, so it stays
## readable on a phone. Presentation only: the caller performs the Prestige on `confirmed`.
signal confirmed
## Widest the plate gets; it always leaves this margin to the safe-area edges.
@export var max_width:=640.0
@export var edge_margin:=20.0
@export var spark_frames:=16
@export var spark_size:=Vector2(25,27)
const SPARKS=preload("res://assets/PixelPlains/Sparks 25x27.png")
var spark_textures: Array=[]
var age:=0.0
var tween: Tween

func _ready() -> void:
    $Plate/Margin/Content/Header/Art.texture=UiArt.cropped($Plate/Margin/Content/Header/Art.texture)
    for i in range(spark_frames):
        var atlas:=AtlasTexture.new();atlas.atlas=SPARKS;atlas.region=Rect2(Vector2(i*spark_size.x,0),spark_size)
        spark_textures.append(atlas)
    $Plate/Margin/Content/Actions/Cancel.pressed.connect(close)
    $Plate/Margin/Content/Actions/Begin.pressed.connect(func()->void:
        close()
        confirmed.emit())

## opportunities: Array of {"icon": Texture2D, "text": String}; keep / reset: one line per entry.
func open(subtitle: String,opportunities: Array,keep: Array,reset: Array) -> void:
    $Plate/Margin/Content/Header/Text/Subtitle.text=subtitle
    var list: VBoxContainer=$Plate/Margin/Content/Scroll/Body/Opportunities
    for child in list.get_children():
        list.remove_child(child)
        child.queue_free()
    for entry in opportunities:
        var row:=HBoxContainer.new()
        row.add_theme_constant_override("separation",10)
        var icon:=TextureRect.new()
        icon.texture=entry.icon
        icon.custom_minimum_size=Vector2(36,36)
        icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
        row.add_child(icon)
        var label:=Label.new()
        label.text=str(entry.text)
        label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
        label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        label.add_theme_font_size_override("font_size",19)
        row.add_child(label)
        list.add_child(row)
    $Plate/Margin/Content/Scroll/Body/Keep/Box/List.text="\n".join(keep.map(func(line):return "✓  "+str(line)))
    $Plate/Margin/Content/Scroll/Body/Reset/Box/List.text="\n".join(reset.map(func(line):return "↺  "+str(line)))
    $Plate/Margin/Content/Scroll.scroll_vertical=0
    age=0.0
    show()
    _layout()
    $Plate.pivot_offset=$Plate.size*.5
    if tween and tween.is_valid():tween.kill()
    $Plate.scale=Vector2(.9,.9);modulate.a=0.0
    tween=create_tween().set_parallel()
    tween.tween_property(self,"modulate:a",1.0,.15)
    tween.tween_property($Plate,"scale",Vector2.ONE,.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    $Plate/Margin/Content/Actions/Cancel.grab_focus()

func close() -> void:
    if tween and tween.is_valid():tween.kill()
    modulate.a=1.0;$Plate.scale=Vector2.ONE
    hide()

func _process(dt: float) -> void:
    if not visible:return
    age+=dt
    var frame:=int(age*20.0)%spark_frames
    var sparks: Node=$Plate/Sparks
    for i in range(sparks.get_child_count()):
        sparks.get_child(i).texture=spark_textures[(frame+i*4)%spark_frames]
    _layout()

## Centred in the safe area: as wide as allowed, as tall as its content, never taller than the screen
## (the body scrolls instead), so both buttons always stay reachable.
func _layout() -> void:
    var insets:=LayoutService.get_safe_area_insets_canvas()
    var available:=size-Vector2(insets.x+insets.z,insets.y+insets.w)-Vector2(edge_margin,edge_margin)*2
    var plate: Control=$Plate
    var width:=minf(max_width,available.x)
    var body: Control=$Plate/Margin/Content/Scroll/Body
    var chrome: float=plate.get_combined_minimum_size().y
    var wanted:=Vector2(width,clampf(chrome+body.get_combined_minimum_size().y,320,available.y))
    if not plate.size.is_equal_approx(wanted):plate.size=wanted
    var at:=Vector2(insets.x+edge_margin+(available.x-width)*.5,insets.y+edge_margin+(available.y-plate.size.y)*.5)
    if not plate.position.is_equal_approx(at):plate.position=at

func _unhandled_key_input(event: InputEvent) -> void:
    if visible and event.is_action_pressed("ui_cancel"):
        close()
        get_viewport().set_input_as_handled()
