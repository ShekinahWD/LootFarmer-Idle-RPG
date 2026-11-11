extends Node2D
## Change 67 follow-up: a critical hit's impact on its target, so a crit reads as a harder hit.
## Adapted from the Cartoon Coffee "Impact_Hit_Lv3" (Light_Ray_006 flash, Impact_008 ring, spiky
## Impact_001, fast sparks) and "Impact_Cartoon_Hit_V2" (the comic Hit Effect 001 burst, white to
## yellow) prefabs, rebuilt with Sprite2D and one CPUParticles2D per slot.
##
## Presentation only: the simulation has already applied the critical damage. A fixed pool of SLOTS
## impacts (the oldest is reused), about 0.3 s each, game time (it pauses with the world). The world
## calls play() from the hit feedback and adds the camera kick; the number is drawn by the actor view.

const FLASH:=preload("res://assets/vfx/combat/Light_Ray_006.png")
const COMIC:=preload("res://assets/vfx/combat/Hit_Effect_001.png")
const SPIKE:=preload("res://assets/vfx/combat/Impact_001.png")
const RING:=preload("res://assets/vfx/combat/Impact_008.png")
const GLOW:=preload("res://assets/vfx/buff/Glow_001.png")
const SLOTS:=3
const LENGTH:=.26
## World units (an ordinary enemy is about 24 tall); bosses scale it with their visual scale.
const SIZE:=34.0
const GOLD:=Color(1,.82,.25)
const HOT:=Color(1,.55,.18)

var slots: Array=[]
var next:=0
var add_material:=CanvasItemMaterial.new()

func _ready() -> void:
    add_material.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD
    texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
    z_index=2 # in front of the actors, under the fog (50) and the hit numbers (100)
    for i in range(SLOTS):
        var holder:=Node2D.new()
        holder.visible=false
        var flash:=_sprite(holder,FLASH,true)
        var ring:=_sprite(holder,RING,true)
        var spike:=_sprite(holder,SPIKE,false)
        var comic:=_sprite(holder,COMIC,false)
        var sparks:=CPUParticles2D.new()
        sparks.texture=GLOW
        sparks.material=add_material
        sparks.emitting=false
        sparks.one_shot=true
        sparks.explosiveness=1.0
        sparks.amount=10
        sparks.lifetime=.28
        sparks.lifetime_randomness=.3
        sparks.local_coords=true
        sparks.spread=180
        sparks.gravity=Vector2.ZERO
        sparks.initial_velocity_min=90;sparks.initial_velocity_max=170
        sparks.damping_min=220;sparks.damping_max=300
        sparks.particle_flag_align_y=true
        sparks.split_scale=true
        sparks.scale_curve_x=_curve([[0,.035],[1,.02]])
        sparks.scale_curve_y=_curve([[0,.16],[1,.05]])
        sparks.color=Color(1,.9,.55)
        var ramp:=Gradient.new()
        ramp.offsets=PackedFloat32Array([0.0,.6,1.0])
        ramp.colors=PackedColorArray([Color.WHITE,Color(1,1,1,.8),Color(1,1,1,0)])
        sparks.color_ramp=ramp
        holder.add_child(sparks)
        add_child(holder)
        slots.append({"node":holder,"flash":flash,"ring":ring,"spike":spike,"comic":comic,"sparks":sparks,"age":INF,"size":SIZE,"facing":1.0})

func _sprite(parent: Node2D,texture: Texture2D,additive: bool) -> Sprite2D:
    var s:=Sprite2D.new()
    s.texture=texture
    if additive:s.material=add_material
    parent.add_child(s)
    return s

func _curve(points: Array) -> Curve:
    var c:=Curve.new()
    for p in points:c.add_point(Vector2(p[0],p[1]))
    return c

## A crit on a target whose body centre is at (world units); facing points away from the attacker.
func play(at: Vector2,scale_factor: float,facing: float) -> void:
    var slot: Dictionary=slots[next]
    next=(next+1)%SLOTS
    slot.age=0.0
    slot.size=SIZE*clampf(scale_factor,.8,2.2)
    slot.facing=facing
    var node: Node2D=slot.node
    node.position=at
    node.visible=true
    slot.spike.rotation=randf()*TAU
    slot.comic.rotation=randf_range(-.4,.4)
    slot.comic.flip_h=facing<0
    slot.sparks.restart()
    slot.sparks.emitting=true
    _apply(slot)

func active() -> int:
    return slots.filter(func(s):return s.node.visible).size()

func stop() -> void:
    for slot in slots:
        slot.age=INF
        slot.node.visible=false
        slot.sparks.emitting=false

func _process(delta: float) -> void:
    for slot in slots:
        if not slot.node.visible:continue
        slot.age+=delta
        if slot.age>=LENGTH+.1:
            slot.node.visible=false
            continue
        _apply(slot)

func _apply(slot: Dictionary) -> void:
    var u:=clampf(float(slot.age)/LENGTH,0,1)
    var size: float=slot.size
    var out:=1.0-pow(1.0-u,3.0)
    # Flash: a white-gold burst of rays, biggest on the first frames.
    _show(slot.flash,size*(.5+.6*out),Color(1,.85,.5,.55*(1.0-u)),u<1)
    # Ring: spreads past the body.
    _show(slot.ring,size*(.4+1.1*out),Color(GOLD,.9*(1.0-u)),u<1)
    # Spike: the hard orange star, pops then shrinks.
    var pop:=minf(1.0,u/.25)*(1.0-maxf(0,(u-.35)/.65))
    _show(slot.spike,size*(.5+.5*pop),Color(HOT,pop),pop>0)
    # Comic burst: white for an instant, then yellow (the prefab's gradient), held briefly.
    var comic_alpha:=1.0 if u<.55 else 1.0-(u-.55)/.45
    var tint:=Color.WHITE.lerp(Color(1,.99,.13),minf(1.0,u/.3))
    _show(slot.comic,size*(.55+.25*minf(1.0,u/.2)),Color(tint,comic_alpha),u<1)

func _show(s: Sprite2D,px: float,color: Color,shown: bool) -> void:
    s.visible=shown
    if not shown:return
    s.scale=Vector2.ONE*px/s.texture.get_width()
    s.modulate=color
