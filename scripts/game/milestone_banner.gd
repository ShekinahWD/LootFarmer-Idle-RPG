extends Control
## Brief celebration for major milestones (prestige discovery/completion, cards, new stages).
## Presentation only: rewards are already granted. Queued so messages never overlap; it waits
## while a panel, confirmation or pause holds the screen, never takes input except its own plate,
## and leaves the persistent Prestige badge as the way back.
signal opened(kind: String)
@export var hold_seconds:=3.2
@export var boss_warning_seconds:=8.0
@export var spark_frames:=16
@export var spark_size:=Vector2(25,27)
const SPARKS=preload("res://assets/PixelPlains/Sparks 25x27.png")
var queue: Array=[]
var current: Dictionary={}
var age:=0.0
var held:=false
var spark_textures: Array=[]
var tween: Tween
## Change 16: a warning (the first sight of a boss) jumps the queue and reads red: title, frame and
## sparks take warning_color, and its art is the boss itself. Other milestones keep the gold look.
@export var warning_color:=Color(1,.3,.24)
var title_color: Color
var frame_color: Color
var default_art: Texture2D

func _ready() -> void:
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    hide()
    $Plate/Row/Art.texture=UiArt.cropped($Plate/Row/Art.texture)
    default_art=$Plate/Row/Art.texture
    title_color=$Plate/Row/Text/Title.get_theme_color("font_color")
    frame_color=$Plate/Frame.modulate
    for i in range(spark_frames):
        var atlas:=AtlasTexture.new();atlas.atlas=SPARKS;atlas.region=Rect2(Vector2(i*spark_size.x,0),spark_size)
        spark_textures.append(atlas)
    $Plate.gui_input.connect(func(event: InputEvent)->void:
        if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
            opened.emit(str(current.get("kind","")));_finish())

## cards: Array of {"icon": Texture2D, "text": String}. art (Change 82): optional art for a gold celebration.
func push(kind: String,title: String,subtitle: String,cards: Array=[],art: Texture2D=null) -> void:
    for entry in queue+[current]:
        if entry.get("title","")==title and entry.get("subtitle","")==subtitle:return
    # Change 63: no fixed cap; a waiting banner is never dropped (duplicates are refused above).
    queue.append({"kind":kind,"title":title,"subtitle":subtitle,"cards":cards,"art":art})

## Change 82: a gold celebration shown next, ahead of anything queued (the Green Alien accepting the challenge).
func push_front(kind: String,title: String,subtitle: String,art: Texture2D=null) -> void:
    for entry in queue+[current]:
        if entry.get("title","")==title and entry.get("subtitle","")==subtitle:return
    queue.push_front({"kind":kind,"title":title,"subtitle":subtitle,"cards":[],"art":art})

## A warning shown next, ahead of queued celebrations, in warning_color with its own art.
## Change 83: seconds overrides the warning's hold time (the Green Alien's Rage warning reads for 5 s).
func push_warning(kind: String,title: String,subtitle: String,art: Texture2D=null,seconds:=-1.0) -> void:
    for entry in queue+[current]:
        if entry.get("title","")==title and entry.get("subtitle","")==subtitle:return
    queue.push_front({"kind":kind,"title":title,"subtitle":subtitle,"cards":[],"warning":true,"art":art,"seconds":seconds})

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
    var hold: float=float(current.get("seconds",-1.0)) if float(current.get("seconds",-1.0))>0 else (boss_warning_seconds if current.get("warning",false) else hold_seconds)
    if age>=hold:_finish()

func _begin(entry: Dictionary) -> void:
    current=entry;age=0.0
    var warning: bool=entry.get("warning",false)
    $Plate/Row/Text/Title.add_theme_color_override("font_color",warning_color if warning else title_color)
    $Plate/Frame.modulate=warning_color if warning else frame_color
    $Sparks.modulate=warning_color if warning else Color.WHITE
    $Plate/Row/Art.texture=entry.get("art") if entry.get("art")!=null else default_art
    $Plate/Row/Text/Title.text=entry.title
    $Plate/Row/Text/Subtitle.text=entry.subtitle
    $Plate/Row/Text/Subtitle.visible=entry.subtitle!=""
    # Change 64: the card chips wrap (an HFlowContainer). In one HBox row a path with 7-8 cards (Expedition,
    # Collection) made the plate wider than the screen, so the banner ran off both sides at 432x960.
    var chips: Container=$Plate/Row/Text/Rewards
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
