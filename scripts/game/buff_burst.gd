extends Node2D
## Change 60 follow-up: the Cartoon Coffee "Positive_Buff_V3" / "Negative_Buff_V3" bursts, rebuilt natively
## (the pack ships Unity particle prefabs, which Godot cannot load). Same five layers and tints as the
## prefabs: a light-ray aura behind the character, then rings, arrows, glow dots and thin light lines that
## rise (positive, green) or fall (negative, red) over a rectangle around the body. The textures are
## downsized copies of the pack's white masks in assets/vfx/buff/, tinted here.
##
## The world owns one burst per polarity and moves it with the player each frame; the stat feedback
## calls world.buff_burst(positive) as each stat popup starts, so the burst matches the popup's colour.
## Replaying while it runs only extends the emission. CPUParticles2D (no shader compile on phones), local
## coordinates (the effect follows the player like the prefabs' local simulation), at most ~40 particles.
## It is a World child, so it pauses with the tree.

const ARROW:=preload("res://assets/vfx/buff/Arrow_006.png")
const GLOW:=preload("res://assets/vfx/buff/Glow_001.png")
const RING:=preload("res://assets/vfx/buff/Circle_Outline_003.png")
const RAY:=preload("res://assets/vfx/buff/Light_Ray_007.png")
## Prefab start colours. The prefab auras (dark green / dark red) rely on Unity's additive HDR blend;
## with normal blending over snow they read as a dull brown, so the aura uses the main tint, lighter.
const TINTS:={
    true:{"main":Color(.53,.97,.56),"bright":Color(.66,.97,.53),"aura":Color(.53,.97,.56,.5)},
    false:{"main":Color(.99,.16,.11),"bright":Color(.99,.16,.11),"aura":Color(.99,.16,.11,.45)}}
## Seconds each play keeps emitting (the prefabs emit for 1 s; popups start 1 s apart).
const EMIT:=.85
## Body centre above the feet, and the emission rectangle's half extents (world units).
const BODY:=Vector2(0,-13)
## Centre of the visible character (its 24x24 frame is padded on top: the pixels span about -15..+2),
## where the rings expand so they enclose the whole character.
const RING_CENTER:=Vector2(0,-7)
## Arrow spawn points, relative to BODY: two columns on each side of the character (its pixels are about
## 14 wide), at staggered heights, so the arrows stay off the body and apart from each other.
const ARROW_POINTS:=[Vector2(-14,-6),Vector2(-21,4),Vector2(-14,12),Vector2(-21,-2),
    Vector2(14,0),Vector2(21,-6),Vector2(14,8),Vector2(21,6)]
const AREA:=Vector2(11,9)
const AURA_HEIGHT:=58.0
const AURA_WIDTH:=34.0

var positive:=true
var layers: Array=[]
var aura: Sprite2D
var emit_left:=0.0
var aura_age:=INF

func setup(is_positive: bool) -> void:
    positive=is_positive
    texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
    var tint: Dictionary=TINTS[positive]
    var up:=-1.0 if positive else 1.0
    aura=Sprite2D.new()
    aura.texture=RAY
    aura.z_index=0 # behind Actors (z 1), above the scenery
    aura.modulate=Color(tint.aura,0.0)
    aura.flip_v=not positive
    aura.scale=Vector2(AURA_WIDTH,AURA_HEIGHT)/Vector2(RAY.get_size())
    aura.visible=false
    add_child(aura)
    var front:=Node2D.new()
    front.z_index=2 # in front of the character, under the fog (50)
    add_child(front)
    # Rings: a few expanding outlines on the body.
    var rings:=_layer(front,RING,tint.main,3,.55)
    rings.emission_shape=CPUParticles2D.EMISSION_SHAPE_POINT
    rings.position=RING_CENTER
    rings.initial_velocity_min=0;rings.initial_velocity_max=0
    rings.scale_amount_min=.24;rings.scale_amount_max=.3
    rings.scale_amount_curve=_curve([[0,.3],[.35,1],[1,1]])
    # Arrows: rise (or fall), pointing the way they move.
    var arrows:=_layer(front,ARROW,tint.bright,7,1.0)
    arrows.emission_shape=CPUParticles2D.EMISSION_SHAPE_POINTS
    arrows.emission_points=PackedVector2Array(ARROW_POINTS)
    arrows.direction=Vector2(0,up)
    arrows.initial_velocity_min=8;arrows.initial_velocity_max=13
    # Arrow_006 points left; CPUParticles2D turns it -90 degrees to point up (positive), +90 down.
    arrows.angle_min=90.0*up;arrows.angle_max=90.0*up
    arrows.scale_amount_min=.22;arrows.scale_amount_max=.28
    arrows.scale_amount_curve=_curve([[0,.3],[.3,1],[.75,1],[1,0]])
    # Glow dots.
    var dots:=_layer(front,GLOW,tint.bright,12,.8)
    dots.direction=Vector2(0,up)
    dots.initial_velocity_min=5;dots.initial_velocity_max=9
    dots.scale_amount_min=.05;dots.scale_amount_max=.09
    dots.scale_amount_curve=_curve([[0,.3],[.3,1],[1,.6]])
    # Thin light lines (stretched glow).
    var lines:=_layer(front,GLOW,tint.main,8,.8)
    lines.direction=Vector2(0,up)
    lines.initial_velocity_min=9;lines.initial_velocity_max=14
    lines.scale_amount_min=.22;lines.scale_amount_max=.3
    lines.split_scale=true
    lines.scale_curve_x=_curve([[0,.1],[1,.1]])
    lines.scale_curve_y=_curve([[0,.4],[.3,1],[1,1]])
    visible=false

func _layer(parent: Node2D,texture: Texture2D,color: Color,amount: int,life: float) -> CPUParticles2D:
    var p:=CPUParticles2D.new()
    p.texture=texture
    p.emitting=false
    p.amount=amount
    p.lifetime=life
    p.lifetime_randomness=.4
    p.local_coords=true
    p.position=BODY
    p.emission_shape=CPUParticles2D.EMISSION_SHAPE_RECTANGLE
    p.emission_rect_extents=AREA
    p.spread=0.0
    p.gravity=Vector2.ZERO
    p.color=color
    var ramp:=Gradient.new()
    ramp.offsets=PackedFloat32Array([0.0,.15,1.0])
    ramp.colors=PackedColorArray([Color(1,1,1,0),Color.WHITE,Color(1,1,1,0)])
    p.color_ramp=ramp
    parent.add_child(p)
    layers.append(p)
    return p

func _curve(points: Array) -> Curve:
    var c:=Curve.new()
    for point in points:c.add_point(Vector2(point[0],point[1]))
    return c

## Starts the burst, or keeps an already running one emitting for another EMIT seconds.
func play() -> void:
    visible=true
    emit_left=EMIT
    for p in layers:p.emitting=true
    if aura_age>=1.0:aura_age=0.0

func stop() -> void:
    emit_left=0.0
    aura_age=INF
    aura.visible=false
    for p in layers:
        p.emitting=false
        p.restart()
        p.emitting=false
    visible=false

func running() -> bool:
    return visible

func _process(delta: float) -> void:
    if not visible:return
    if emit_left>0.0:
        emit_left-=delta
        if emit_left<=0.0:
            for p in layers:p.emitting=false
    # Aura: one fade in and out over a second, drifting the way the burst moves.
    if aura_age<1.0:
        aura_age+=delta
        var t:=clampf(aura_age,0.0,1.0)
        aura.visible=true
        aura.modulate.a=float(TINTS[positive].aura.a)*(minf(1.0,t/.25)*clampf((1.0-t)/.5,0.0,1.0))
        var drift:=6.0*t
        # Over the body either way: rising from the feet (positive) or coming down onto them (negative).
        aura.position=Vector2(0,-AURA_HEIGHT*.5+(-drift if positive else drift-6.0))
    else:
        aura.visible=false
    if emit_left<=0.0 and aura_age>=1.0 and not layers.any(func(p):return p.emitting):
        # Hidden once the last particles have had time to finish.
        emit_left-=delta
        if emit_left<-1.0:stop()
