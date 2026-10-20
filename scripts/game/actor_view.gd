@tool
class_name LootActorView
extends Node2D
## Shared, presentation-only actor. Outfit sheets contain their own body pixels.
@export var body_texture: Texture2D = preload("res://assets/PixelPlains/Characters 24x24/Basic character v2.png"):
    set(value):
        body_texture=value
        if is_node_ready():
            $Visual/Body.texture=value
@export var weapon_texture: Texture2D
@export var attack_texture: Texture2D
var hp_fill := StyleBoxFlat.new()
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
var elapsed:=0.0
var actor: Dictionary={}
var max_hp:=100.0
var _last_body: Texture2D
var hit_tween: Tween
var speech_tween: Tween

func _ready() -> void:
    $HP.add_theme_stylebox_override("fill",hp_fill)
    $Visual/Body.texture=body_texture
    $Visual/Weapon.texture=weapon_texture
    $Visual/Weapon.visible=weapon_texture!=null

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
        visible=not dead or actor.dead_age<float(death_frames)/death_fps+.2
        $Shadow.visible=visible
        $HP.visible=not dead and actor.hp<max_hp
        $HP.value=100.0*actor.hp/max_hp
        hp_fill.bg_color=Color(.95,.18,.22)
        $Visual.modulate=Color(2,1.4,1.4) if actor.hurt>0 else Color.WHITE
    if walking:
        row=walk_row
        col=int(elapsed*walk_fps)%walk_frames
    if dead:
        row=death_row
        col=mini(death_frames-1,int(actor.dead_age*death_fps))
    $Visual.scale.x=facing
    $Visual.position=Vector2.ZERO
    $Visual.scale.y=1.0
    if not dead and actor.get("hurt",0)>0:
        $Visual.position.x=-facing*2.0*sin(float(actor.hurt)/.16*PI)
    if dead:
        $Visual.modulate.a=clampf((float(death_frames)/death_fps+.2-float(actor.dead_age))/.2,0,1)
    $Visual/Body.region_rect=Rect2(Vector2(col,row)*cell_size,cell_size)
    # First slash is frame 2. Match its onset to authoritative windup,
    # including upgraded attack speed. Frames 0–4 contain one swing;
    # frame 5 begins a second swing and must not play for the same attack.
    var contact: float=maxf(.01,float(actor.get("attack_contact",.22)))
    var frame:=mini(4,int(attack_age/contact*2.0))
    var duration: float=float(actor.get("attack_duration",contact*2.5))
    var attacking:=attack_age<duration and not dead and not walking
    $Visual/Attack.visible=attacking and attack_texture!=null
    $Visual/Attack.texture=attack_texture
    $Visual/Attack.region_rect=Rect2(frame*64,0,64,32)
    $Visual/Weapon.visible=weapon_texture!=null and not dead and not $Visual/Attack.visible
    $Visual/Weapon.texture=weapon_texture
    $Visual/Weapon.rotation=-.35
    if weapon_texture!=null:
        $Visual/Weapon.scale=Vector2.ONE*12.0/maxf(weapon_texture.get_width(),weapon_texture.get_height())
    # The effort face is authored in row 3 on each 24x24 outfit sheet.
    # Hop reaches its forward apex at the simulation's contact, then recovers.
    if attacking:
        var phase:=attack_age/contact
        var effort:=phase>=.5 and phase<1.7
        $Visual/Body.region_rect=Rect2(0,3*cell_size.y if effort else 0,cell_size.x,cell_size.y)
        if attack_texture==null:
            var pulse:=sin(clampf(phase/2.0,0,1)*PI)
            $Visual.position+=Vector2(pulse*4.0*facing,-pulse*5.0)
            $Visual.scale.y=1.0-.08*pulse
        else:
            $Visual.position.x+=sin(clampf(phase/2.0,0,1)*PI)*1.5*facing

func show_hit(value: float, healing: bool, critical: bool=false) -> void:
    # Keep each hit independent, including after its actor dies or despawns.
    var label: Label=$Hit.duplicate()
    get_parent().add_child(label)
    label.position=position+Vector2(-22,-35)
    label.text=("+" if healing else "−")+NumberFormat.number(value,2)+("!" if critical else "")
    label.modulate=Color(.5,1,.6) if healing else (Color(1,.75,.2) if critical else Color(1,.85,.85))
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
