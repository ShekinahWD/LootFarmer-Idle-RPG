extends Control
## Change 35: the review invitation panel, in the visual language of the Prestige confirmation
## (Backing plate, gold border, divider, corner sparks), shown like any game panel: no entrance
## animation, no timer, both buttons usable from the first visible frame. Presentation only; game_ui
## decides when it opens and what each answer does (review_invitation.gd keeps the state).
## The store button's text comes from the configured channel (distribution_channels.gd).
signal review_pressed
signal later_pressed
@export var max_width:=600.0
@export var edge_margin:=20.0
## The spark sheet's first frame decorates two corners, still (the panel has no animation).
@export var spark_sheet: Texture2D
@export var spark_size:=Vector2(25,27)
@onready var review_button: Button=$Plate/Margin/Content/Actions/Review
@onready var later_button: Button=$Plate/Margin/Content/Actions/Later
@onready var error_label: Label=$Plate/Margin/Content/Scroll/Body/Error
var prewarming:=false

## In front of the game (the invisible startup layout pass does not count).
func is_open() -> bool:return visible and not prewarming

func _ready() -> void:
    $Plate/Margin/Content/Header/Art.texture=UiArt.cropped($Plate/Margin/Content/Header/Art.texture)
    if spark_sheet!=null:
        var atlas:=AtlasTexture.new();atlas.atlas=spark_sheet;atlas.region=Rect2(Vector2(spark_size.x*4,0),spark_size)
        for spark in $Plate/Sparks.get_children():spark.texture=atlas
    review_button.pressed.connect(func()->void:review_pressed.emit())
    later_button.pressed.connect(func()->void:later_pressed.emit())
    _prewarm()

## A wrapped label that has never been drawn reports its zero-width line breaks on the first resize,
## so the first real open would measure a far too tall panel. Lay the panel out and draw it once at
## startup, invisible and input-transparent, so every real open has its final size on frame one.
func _prewarm() -> void:
    await get_tree().process_frame
    if visible:return
    prewarming=true
    modulate.a=0.0;_input_transparent(true)
    show();_layout()
    await get_tree().process_frame
    _layout()
    await get_tree().process_frame
    if prewarming:hide()
    _end_prewarm()

## Every control of the panel ignores input while it is laid out invisibly (the map, joystick and HUD
## underneath must keep every touch); the authored filters come back afterwards.
var saved_filters: Dictionary={}
func _input_transparent(on: bool) -> void:
    if on:
        for node in [self]+find_children("*","Control",true,false):
            saved_filters[node]=node.mouse_filter;node.mouse_filter=Control.MOUSE_FILTER_IGNORE
    else:
        for node in saved_filters:
            if is_instance_valid(node):node.mouse_filter=saved_filters[node]
        saved_filters.clear()

func _end_prewarm() -> void:
    if prewarming or not saved_filters.is_empty():_input_transparent(false)
    prewarming=false
    modulate.a=1.0

## cta: the store-specific button text; loot: a few of the game's own icons for the accent row.
func open(cta: String,loot: Array) -> void:
    _end_prewarm()
    review_button.text=cta
    error_label.hide()
    var row: HBoxContainer=$Plate/Margin/Content/Scroll/Body/Loot
    for child in row.get_children():
        row.remove_child(child);child.queue_free()
    for texture in loot:
        var icon:=TextureRect.new()
        icon.texture=texture
        icon.custom_minimum_size=Vector2(40,40)
        icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
        icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
        row.add_child(icon)
    $Plate/Margin/Content/Scroll.scroll_vertical=0
    show()
    # Twice: the first pass gives the wrapped labels their width, the second measures them.
    _layout();_layout()
    review_button.grab_focus()

## The store page could not be opened: say so, keep both buttons (Review can be tried again).
func show_error(text: String) -> void:
    error_label.text=text
    error_label.show()
    _layout()

func close() -> void:
    hide()

func _process(_dt: float) -> void:
    if visible:_layout()

## Centred in the safe area, as wide as allowed and as tall as its content; on a short screen the
## message scrolls and the two buttons stay on screen. Wrapped labels get their width before they
## are measured, so the first frame already has its final size.
func _layout() -> void:
    var insets:=LayoutService.get_safe_area_insets_canvas()
    var available:=size-Vector2(insets.x+insets.z,insets.y+insets.w)-Vector2(edge_margin,edge_margin)*2
    if available.x<=0 or available.y<=0:return
    var plate: Control=$Plate
    var width:=minf(max_width,available.x)
    var style: StyleBox=plate.get_theme_stylebox("panel")
    var inner:=width-44.0-style.get_margin(SIDE_LEFT)-style.get_margin(SIDE_RIGHT)
    var header_text:=maxf(80.0,inner-80.0-16.0)
    for label in [$Plate/Margin/Content/Header/Text/Title,$Plate/Margin/Content/Header/Text/Lead]:
        if not is_equal_approx(label.custom_minimum_size.x,header_text):label.custom_minimum_size.x=header_text
    # The scroll reserves its vertical bar's width beside the body.
    var body_width: float=inner-$Plate/Margin/Content/Scroll.get_v_scroll_bar().get_combined_minimum_size().x
    for label in [$Plate/Margin/Content/Scroll/Body/Text,error_label]:
        if not is_equal_approx(label.custom_minimum_size.x,body_width):label.custom_minimum_size.x=body_width
    # Sort the containers now at the final width (they would otherwise sort at the end of the frame),
    # so every wrapped label reports its real height before the plate height is chosen.
    if not is_equal_approx(plate.size.x,width):plate.size=Vector2(width,plate.size.y)
    _sort_now()
    var body: Control=$Plate/Margin/Content/Scroll/Body
    var chrome: float=plate.get_combined_minimum_size().y
    var wanted:=Vector2(width,minf(chrome+body.get_combined_minimum_size().y,available.y))
    if not plate.size.is_equal_approx(wanted):
        plate.size=wanted
        _sort_now()
    var at:=Vector2(insets.x+edge_margin+(available.x-width)*.5,insets.y+edge_margin+(available.y-plate.size.y)*.5)
    if not plate.position.is_equal_approx(at):plate.position=at

func _sort_now() -> void:
    $Plate.notification(Container.NOTIFICATION_SORT_CHILDREN)
    for node in $Plate.find_children("*","Container",true,false):
        node.notification(Container.NOTIFICATION_SORT_CHILDREN)
