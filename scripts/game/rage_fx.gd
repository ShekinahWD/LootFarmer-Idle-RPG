extends Node2D
## Change 83: the enraged Green Alien's sustained aura, drawn in the world while its actor.rage latch holds (it
## follows the boss's drawn feet). Two soft additive glows breathing under and around the body, a thin crimson
## ground ring and a few embers rising from it. Kept low and translucent so the boss's HP bar, name, telegraphs and
## the hero stay readable, and cheap (two sprites, one ring, one 14-ember emitter). Game time: it pauses with the
## world. The entry burst itself is world_moments "rage".

const GLOW:=preload("res://assets/vfx/buff/Glow_001.png")
const RED:=Color(1,.16,.1)
var sim
## Callable(id) -> Vector2: where the actor's view stands (feet).
var feet: Callable
var boss_id:=""
var time:=0.0
var scale_factor:=1.0
var glow: Sprite2D
var halo: Sprite2D
var embers: CPUParticles2D
var add_material:=CanvasItemMaterial.new()

func _ready() -> void:
    add_material.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD
    texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
    process_mode=Node.PROCESS_MODE_PAUSABLE
    glow=_sprite();halo=_sprite()
    embers=CPUParticles2D.new()
    embers.texture=GLOW;embers.material=add_material
    embers.amount=14;embers.lifetime=1.1;embers.lifetime_randomness=.4
    embers.emission_shape=CPUParticles2D.EMISSION_SHAPE_RECTANGLE;embers.emission_rect_extents=Vector2(16,4)
    embers.direction=Vector2(0,-1);embers.spread=18
    embers.initial_velocity_min=18;embers.initial_velocity_max=34;embers.gravity=Vector2.ZERO
    embers.scale_amount_min=.035;embers.scale_amount_max=.06
    embers.color=Color(1,.38,.15)
    var ramp:=Gradient.new()
    ramp.offsets=PackedFloat32Array([0,.2,.7,1]);ramp.colors=PackedColorArray([Color(1,1,1,0),Color(1,1,1,.9),Color(1,1,1,.6),Color(1,1,1,0)])
    embers.color_ramp=ramp
    embers.emitting=false
    add_child(embers)
    visible=false

func _sprite() -> Sprite2D:
    var s:=Sprite2D.new();s.texture=GLOW;s.material=add_material;add_child(s);return s

## The enraged boss (or "" to stop). scale: the boss's visual scale.
func follow(id: String,visual_scale: float) -> void:
    if id==boss_id:return
    boss_id=id;scale_factor=visual_scale
    visible=id!=""
    embers.emitting=id!=""
    if id=="":embers.restart();embers.emitting=false

func _process(delta: float) -> void:
    if boss_id=="" or sim==null:return
    var a: Dictionary=sim._find_actor(boss_id)
    if not sim.campaign.enraged(a):
        follow("",1.0)
        return
    time+=delta
    position=feet.call(boss_id)
    var k:=scale_factor
    var beat:=.5+.5*sin(time*5.0)
    glow.position=Vector2(0,-9*k)
    glow.scale=Vector2.ONE*(44.0*k/GLOW.get_width())*(1.0+.12*beat)
    glow.modulate=Color(RED,.22+.12*beat)
    halo.position=Vector2(0,2)
    halo.scale=Vector2(1,.38)*(64.0*k/GLOW.get_width())*(1.0+.08*beat)
    halo.modulate=Color(1,.25,.1,.32+.15*beat)
    embers.position=Vector2(0,-2)
    queue_redraw()

func _draw() -> void:
    if boss_id=="":return
    var k:=scale_factor
    var beat:=.5+.5*sin(time*5.0)
    draw_set_transform(Vector2(0,2),0,Vector2(1,.42))
    draw_arc(Vector2.ZERO,(15.0+2.0*beat)*k,0,TAU,40,Color(1,.12,.08,.55),1.6,true)
    draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
