extends Control
## Brief celebration for major milestones (prestige discovery/completion, cards, new stages).
## Presentation only: rewards are already granted. Queued so messages never overlap; it waits
## while a panel, confirmation or pause holds the screen, never takes input except its own plate,
## and leaves the persistent Prestige badge as the way back.
signal opened(kind: String)
@export var hold_seconds:=3.2
@export var spark_frames:=16
@export var spark_size:=Vector2(25,27)
const SPARKS=preload("res://assets/PixelPlains/Sparks 25x27.png")
var queue: Array=[]
var current: Dictionary={}
var age:=0.0
var held:=false
var spark_textures: Array=[]
var tween: Tween

func _ready() -> void:
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    hide()
    $Plate/Row/Art.texture=UiArt.cropped($Plate/Row/Art.texture)
    for i in range(spark_frames):
        var atlas:=AtlasTexture.new();atlas.atlas=SPARKS;atlas.region=Rect2(Vector2(i*spark_size.x,0),spark_size)
        spark_textures.append(atlas)
    $Plate.gui_input.connect(func(event: InputEvent)->void:
        if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
            opened.emit(str(current.get("kind","")));_finish())

## cards: Array of {"icon": Texture2D, "text": String}
func push(kind: String,title: String,subtitle: String,cards: Array=[]) -> void:
    for entry in queue+[current]:
        if entry.get("title","")==title and entry.get("subtitle","")==subtitle:return
    queue.append({"kind":kind,"title":title,"subtitle":subtitle,"cards":cards})
    while queue.size()>4:queue.pop_front()

func pending() -> int:
    return queue.size()+(0 if current.is_empty() else 1)

func _process(dt: float) -> void:
    if held:
        if not current.is_empty():
            queue.push_front(current);_finish()
        return
    if current.is_empty():
        if queue.is_empty():return
        _begin(queue.pop_front())
    age+=dt
    var frame:=int(age*20.0)%spark_frames
    for i in range($Sparks.get_child_count()):
        $Sparks.get_child(i).texture=spark_textures[(frame+i*5)%spark_frames]
    if age>=hold_seconds:_finish()

func _begin(entry: Dictionary) -> void:
    current=entry;age=0.0
    $Plate/Row/Text/Title.text=entry.title
    $Plate/Row/Text/Subtitle.text=entry.subtitle
    $Plate/Row/Text/Subtitle.visible=entry.subtitle!=""
    var chips: HBoxContainer=$Plate/Row/Text/Rewards
    for child in chips.get_children():child.queue_free()
    for card in entry.cards:
        var chip:=HBoxContainer.new();chip.mouse_filter=Control.MOUSE_FILTER_IGNORE
        var icon:=TextureRect.new();icon.texture=card.icon;icon.custom_minimum_size=Vector2(30,30);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
        var label:=Label.new();label.text=card.text;label.add_theme_font_size_override("font_size",18);label.add_theme_constant_override("outline_size",4);label.mouse_filter=Control.MOUSE_FILTER_IGNORE
        chip.add_child(icon);chip.add_child(label);chips.add_child(chip)
    chips.visible=not entry.cards.is_empty()
    show()
    $Plate.pivot_offset=$Plate.size*.5
    if tween and tween.is_valid():tween.kill()
    $Plate.scale=Vector2(.85,.85);modulate.a=0.0
    tween=create_tween().set_parallel()
    tween.tween_property(self,"modulate:a",1.0,.15)
    tween.tween_property($Plate,"scale",Vector2.ONE,.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    # Change 12: the sound plays at the milestone itself (game_ui._milestone via the audio service),
    # not when a held banner is finally shown.

func _finish() -> void:
    current={}
    if tween and tween.is_valid():tween.kill()
    hide();modulate.a=1.0;$Plate.scale=Vector2.ONE
