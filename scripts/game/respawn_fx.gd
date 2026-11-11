extends Node2D
## Change 67 (Phase 2): the hero's arrival after a revive. Before, the fallen hero faded out and then
## appeared at the respawn camp with nothing marking the moment. Now a short light column comes down
## onto the respawn point, a flattened ring spreads at the feet and a few motes rise, adapted from the
## Cartoon Coffee Power_Up rings (Energy-ring squash at the feet) and the buff burst's Light_Ray_007 aura.
## One instance owned by the world, replayed on each revive; about 0.7 s; presentation only (the
## simulation has already moved and healed the hero); it pauses with the world.

const RAY:=preload("res://assets/vfx/buff/Light_Ray_007.png")
const RING:=preload("res://assets/vfx/celebration/Circle_Outline_002.png")
const GLOW:=preload("res://assets/vfx/buff/Glow_001.png")
const TINT:=Color(.78,.95,1)
const LENGTH:=.7
## World units: the column's size over the hero (whose visible pixels span about -15..+2) and the
## ring's widest reach at the feet.
const COLUMN:=Vector2(30,64)
const RING_WIDTH:=46.0

var column: Sprite2D
var ring: Sprite2D
var motes: CPUParticles2D
var age:=INF
var add_material:=CanvasItemMaterial.new()

func _ready() -> void:
    add_material.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD
    texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
    column=Sprite2D.new()
    column.texture=RAY
    column.material=add_material
    column.z_index=0 # behind the actors (z 1), like the buff aura
    add_child(column)
    ring=Sprite2D.new()
    ring.texture=RING
    ring.material=add_material
    ring.z_index=0
    add_child(ring)
    motes=CPUParticles2D.new()
    motes.texture=GLOW
    motes.material=add_material
    motes.z_index=2 # in front of the hero, under the fog
    motes.emitting=false
    motes.one_shot=true
    motes.explosiveness=.7
    motes.amount=8
    motes.lifetime=.6
    motes.local_coords=true
    motes.emission_shape=CPUParticles2D.EMISSION_SHAPE_RECTANGLE
    motes.emission_rect_extents=Vector2(10,3)
    motes.direction=Vector2(0,-1);motes.spread=12
    motes.gravity=Vector2.ZERO
    motes.initial_velocity_min=18;motes.initial_velocity_max=34
    motes.scale_amount_min=.035;motes.scale_amount_max=.06
    motes.color=TINT
    var ramp:=Gradient.new()
    ramp.offsets=PackedFloat32Array([0.0,.2,1.0])
    ramp.colors=PackedColorArray([Color(1,1,1,0),Color.WHITE,Color(1,1,1,0)])
    motes.color_ramp=ramp
    add_child(motes)
    visible=false

## Plays at the hero's feet (world position).
func play(at: Vector2) -> void:
    position=at
    age=0.0
    visible=true
    motes.restart()
    motes.emitting=true
    _apply()

func stop() -> void:
    age=INF
    motes.emitting=false
    visible=false

func running() -> bool:
    return visible

func _process(delta: float) -> void:
    if not visible:return
    age+=delta
    if age>=LENGTH+.3:
        stop()
        return
    _apply()

func _apply() -> void:
    var u:=clampf(age/LENGTH,0,1)
    # Column: drops in fast (stretching down from above), then thins and fades.
    var drop:=clampf(u/.25,0,1)
    var fade:=1.0-clampf((u-.35)/.65,0,1)
    var w:=COLUMN.x*(1.0-.5*u)
    column.scale=Vector2(w,COLUMN.y*drop)/Vector2(RAY.get_size())
    column.position=Vector2(0,-COLUMN.y*drop*.5)
    column.modulate=Color(TINT,.85*fade)
    column.visible=age<LENGTH
    # Ring: a flattened circle spreading from the feet.
    var r:=1.0-pow(1.0-u,3.0)
    ring.scale=Vector2(1.0,.42)*(10.0+(RING_WIDTH-10.0)*r)/RING.get_width()
    ring.position=Vector2(0,1)
    ring.modulate=Color(TINT,.9*(1.0-u))
    ring.visible=age<LENGTH
