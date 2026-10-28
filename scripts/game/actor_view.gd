@tool
class_name LootActorView
extends Node2D
## Shared, presentation-only actor. Outfit sheets contain their own body pixels.
@export var body_texture: Texture2D = preload("res://assets/PixelPlains/Characters 24x24/Basic character v2.png"):
    set(value):
        body_texture=value
        if is_node_ready():
            _body.texture=value
@export var weapon_texture: Texture2D
@export var attack_texture: Texture2D
## Multiplies the swing sheet only (Change 12: stone-tier weapons tint the Iron set swing warm gray).
@export var attack_tint: Color = Color.WHITE
@export_range(1.0,3.0,.25) var visual_scale: float=1.0
@export var preview_walking := false
@export var cell_size := Vector2(24,24)
@export var idle_frames := 8
@export var idle_row := 0
@export var walk_row := 1
@export var death_row := 2
@export var walk_frames := 4
@export var death_frames := 9
@export var idle_fps := 5.0
@export var walk_fps := 10.0
@export var death_fps := 12.0
## HP bar (Change 8: remaining/maximum HP drawn inside it). Width scales with the actor; the text
## is laid out at 1/hp_text_scale size and scaled down so it stays crisp under the camera zoom.
@export var hp_bar_width := 32.0
@export var hp_bar_height := 7.0
@export var hp_text_scale := 0.25
## Size of a healing number relative to a damage number (Change 12).
@export var heal_text_scale := 1.3
## Change 13: a summoned helper's body tint, and the World banner above the HP bar of a discovered
## boss the next map still needs (the Gate node holds its art and colour).
@export var body_tint := Color.WHITE
## Change 16: a boss's name in threatening red above its HP bar (the Name label's own colours), and
## one small icon per skill an enemy carries. They stack upward from the HP bar (name, skill icons,
## World banner, then the speech line), so nothing overlaps. Sizes are world units.
@export var name_text_scale := 0.3
@export var skill_icon_size := 9.0
@export var skill_plate_color := Color(.04,.06,.09,.82)
var display_name := ""
var skill_icons: Array = []
var gate := false
var elapsed:=0.0
var actor: Dictionary={}
var disclosed:=true
var max_hp:=100.0
var _last_body: Texture2D
## Change 24: the world's look id last applied to this view (world.gd bookkeeping; -1 = none).
var look_id:=-1
var hit_tween: Tween
var speech_tween: Tween

## Change 24: child nodes are looked up once (the view runs every frame for every on-screen actor),
## and the scale-dependent layout (shadow, HP bar, its text) is written only when visual_scale changes.
@onready var _visual: Node2D=$Visual
@onready var _body: Sprite2D=$Visual/Body
@onready var _weapon: Sprite2D=$Visual/Weapon
@onready var _attack: Sprite2D=$Visual/Attack
@onready var _shadow: Sprite2D=$Shadow
@onready var _hp: ProgressBar=$HP
@onready var _hp_text: Label=$HP/Text
@onready var _marker: Control=$Marker
@onready var _speech: Label=$Speech
@onready var _name: Label=$Name
@onready var _skills: Node2D=$Skills
@onready var _gate: Sprite2D=$Gate
var _layout_scale:=-1.0
var _weapon_scaled: Texture2D

func _ready() -> void:
    _body.texture=body_texture
    _weapon.texture=weapon_texture
    _weapon.visible=weapon_texture!=null
    _weapon.rotation=-.35

## Change 24 (world view pool): back to a neutral state before the view is reused for another actor.
func recycle() -> void:
    actor={}
    disclosed=true
    elapsed=0.0
    display_name=""
    skill_icons=[]
    gate=false
    body_tint=Color.WHITE
    if hit_tween and hit_tween.is_valid():hit_tween.kill()
    if speech_tween and speech_tween.is_valid():speech_tween.kill()
    _speech.text=""
    _marker.visible=false
    for child in get_children():
        if child is AnimatedSprite2D:child.queue_free()
    visible=false

func _process(dt: float) -> void:
    elapsed+=dt
    var walking:=preview_walking
    var row:=idle_row
    var col:=int(elapsed*idle_fps)%idle_frames
    var facing:=1.0
    var attack_age:=9.0
    var dead:=false
    if not actor.is_empty():
        walking=actor.moving
        facing=actor.facing
        attack_age=actor.attack_age
        dead=actor.hp<=0
        visible=disclosed and (not dead or actor.dead_age<float(death_frames)/death_fps+.2)
        _shadow.visible=visible
        _hp.visible=not dead and actor.hp<max_hp
        _hp.value=100.0*actor.hp/max_hp
        if _hp.visible:
            var text:=hp_text(float(actor.hp),max_hp)
            if _hp_text.text!=text:
                _hp_text.text=text
                # A longer number may have grown the label; keep it the bar's width as before.
                _hp_text.size=Vector2(hp_bar_width*visual_scale,hp_bar_height)/hp_text_scale
        _visual.modulate=Color(2,1.4,1.4) if actor.hurt>0 else Color.WHITE
    if walking:
        row=walk_row
        col=int(elapsed*walk_fps)%walk_frames
    if dead:
        row=death_row
        col=mini(death_frames-1,int(actor.dead_age*death_fps))
    _visual.scale=Vector2(facing*visual_scale,visual_scale)
    _visual.position=Vector2.ZERO
    var bar:=Vector2(hp_bar_width*visual_scale,hp_bar_height)
    if _layout_scale!=visual_scale:
        _layout_scale=visual_scale
        _shadow.scale=Vector2.ONE*visual_scale
        _hp.position=Vector2(-bar.x*.5,-27*visual_scale-bar.y+3)
        _hp.size=bar
        _hp_text.scale=Vector2.ONE*hp_text_scale
        _hp_text.size=bar/hp_text_scale
    var top:=_stack_overhead(bar,dead)
    _marker.position=Vector2(-8,top-16 if _stack_used else -38*visual_scale)
    _speech.position.y=minf(-52*visual_scale,top-14)
    if not dead and actor.get("hurt",0)>0:
        _visual.position.x=-facing*2.0*sin(float(actor.hurt)/.16*PI)
    if dead:
        _visual.modulate.a=clampf((float(death_frames)/death_fps+.2-float(actor.dead_age))/.2,0,1)
    _body.self_modulate=body_tint
    _body.region_rect=Rect2(Vector2(col,row)*cell_size,cell_size)
    # First slash is frame 2. Match its onset to authoritative windup,
    # including upgraded attack speed. Frames 0–4 contain one swing;
    # frame 5 begins a second swing and must not play for the same attack.
    var contact: float=maxf(.01,float(actor.get("attack_contact",.22)))
    var frame:=mini(4,int(attack_age/contact*2.0))
    var duration: float=float(actor.get("attack_duration",contact*2.5))
    var attacking:=attack_age<duration and not dead and not walking
    _attack.visible=attacking and attack_texture!=null
    _attack.texture=attack_texture
    _attack.self_modulate=attack_tint
    _attack.region_rect=Rect2(frame*64,0,64,32)
    _weapon.visible=weapon_texture!=null and not dead and not _attack.visible
    if _weapon.texture!=weapon_texture or _weapon_scaled!=weapon_texture:
        _weapon.texture=weapon_texture
        _weapon_scaled=weapon_texture
        if weapon_texture!=null:
            _weapon.scale=Vector2.ONE*12.0/maxf(weapon_texture.get_width(),weapon_texture.get_height())
    # The effort face is authored in row 3 on each 24x24 outfit sheet.
    # Hop reaches its forward apex at the simulation's contact, then recovers.
    if attacking:
        var phase:=attack_age/contact
        var effort:=phase>=.5 and phase<1.7
        _body.region_rect=Rect2(0,3*cell_size.y if effort else 0,cell_size.x,cell_size.y)
        if attack_texture==null:
            var pulse:=sin(clampf(phase/2.0,0,1)*PI)
            _visual.position+=Vector2(pulse*4.0*facing,-pulse*5.0)
            _visual.scale.y=visual_scale-.08*pulse
        else:
            _visual.position.x+=sin(clampf(phase/2.0,0,1)*PI)*1.5*facing

## Lays out the overhead stack from the HP bar upward and returns its top (world units, negative is
## up): the boss name, the skill icons, then the World banner of a required boss (Change 13). Each
## item takes its own row, so names, icons, banner and HP bar never overlap. With nothing to show the
## top is the HP bar's and the target marker and speech keep their usual places.
var _stack_used:=false
func _stack_overhead(bar: Vector2,dead: bool) -> float:
    var y:=-27*visual_scale-bar.y+2
    _stack_used=false
    var alive:=visible and not dead
    var named:=display_name!="" and alive
    _name.visible=named
    if named:
        if _name.text!=display_name:_name.text=display_name
        _name.scale=Vector2.ONE*name_text_scale
        _name.position=Vector2(-_name.size.x*.5*name_text_scale,y-_name.size.y*name_text_scale)
        y-=_name.size.y*name_text_scale+1
        _stack_used=true
    _sync_skill_icons()
    _skills.visible=alive and not skill_icons.is_empty()
    if _skills.visible:
        var count:=skill_icons.size()
        # Each icon's disc is 1.24 icon sides wide; rows and neighbours keep a unit of air around it.
        var cell:=skill_icon_size*1.24+1
        for i in range(count):
            (_skills.get_child(i) as Sprite2D).position=Vector2((i-(count-1)*.5)*cell,y-cell*.5)
        y-=cell+1
        _stack_used=true
    _gate.visible=gate and alive
    if _gate.visible:
        # The banner art fills the middle 16 of its 32 px at 0.75 scale: 12 world units tall.
        _gate.position=Vector2(0,y-6)
        y-=13
        _stack_used=true
    return y

## One Sprite2D per skill icon, each scaled to skill_icon_size; rebuilt only when the list changes.
func _sync_skill_icons() -> void:
    var holder: Node2D=_skills
    while holder.get_child_count()<skill_icons.size():
        var sprite:=Sprite2D.new()
        # A dark disc behind the icon, like the HUD chips, so thin effect art reads on snow and sand.
        var plate:=Polygon2D.new()
        var points:=PackedVector2Array()
        for k in range(12):points.append(Vector2.RIGHT.rotated(TAU*k/12.0))
        plate.polygon=points
        plate.color=skill_plate_color
        plate.show_behind_parent=true
        sprite.add_child(plate)
        holder.add_child(sprite)
    while holder.get_child_count()>skill_icons.size():
        var extra:=holder.get_child(holder.get_child_count()-1)
        holder.remove_child(extra)
        extra.queue_free()
    for i in range(skill_icons.size()):
        var sprite: Sprite2D=holder.get_child(i)
        var texture: Texture2D=skill_icons[i]
        if sprite.texture!=texture:
            sprite.texture=texture
            if texture!=null:
                sprite.scale=Vector2.ONE*skill_icon_size/maxf(texture.get_width(),texture.get_height())
                # The disc is drawn in the sprite's space: a radius of 0.62 of the icon's side.
                (sprite.get_child(0) as Polygon2D).scale=Vector2.ONE*maxf(texture.get_width(),texture.get_height())*.62

## "18/25", "1.2K/3.4K": whole numbers below 1,000 (rounded up, so a living actor never reads 0).
static func hp_text(hp: float,maximum: float) -> String:
    return "%s/%s" % [_hp_number(ceilf(maxf(0,hp))),_hp_number(ceilf(maximum))]

static func _hp_number(value: float) -> String:
    return str(int(value)) if value<1000 else NumberFormat.number(value,1)

func show_hit(value: float, healing: bool, critical: bool=false, on_player: bool=false) -> void:
    # Keep each hit independent, including after its actor dies or despawns.
    var label: Label=$Hit.duplicate()
    get_parent().add_child(label)
    # Small horizontal spread so simultaneous hits stay readable instead of stacking. Healing (Change
    # 12) is centred above the head and a little larger, so it reads apart from incoming damage.
    if healing:
        label.position=position+Vector2(-22,-35*visual_scale-10)
        label.pivot_offset=label.size*.5
        label.scale=Vector2.ONE*heal_text_scale
    else:
        label.position=position+Vector2(-22+randf_range(-12,12),-35*visual_scale-randf_range(0,6))
    label.text=("+" if healing else "−")+NumberFormat.number(value,2)+("!" if critical else "")
    # Sign and "!" carry the meaning; colour reinforces it (outlined for snow and bright effects).
    label.modulate=Color(.45,1,.55) if healing else (Color(1,.78,.2) if critical else (Color(1,.42,.38) if on_player else Color.WHITE))
    label.z_index=100
    var tween:=label.create_tween()
    tween.set_parallel()
    tween.tween_property(label,"position:y",label.position.y-22,1.8)
    tween.tween_property(label,"modulate:a",0.0,.7).set_delay(1.1)
    tween.chain().tween_callback(label.queue_free)

func say(key: String) -> void:
    if speech_tween and speech_tween.is_valid():
        speech_tween.kill()
    $Speech.text=tr(key)
    $Speech.modulate.a=1.0
    speech_tween=create_tween()
    speech_tween.tween_interval(.65)
    speech_tween.tween_property($Speech,"modulate:a",0.0,.3)
