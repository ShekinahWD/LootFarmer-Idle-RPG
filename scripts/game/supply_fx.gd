extends Node2D
## Change 67 follow-up: every supply says what it did, on the hero, in its own look.
##
## Activation (a manual tap or auto-use, after the simulation applied the supply): a burst in the
## supply's colour (glow, a ring spreading at the feet, its own particles) and its name rising above
## the hero, plus its cue. While a timed supply lasts, a light aura keeps saying it is on, ending with it.
##
##   Health Potion (heal)       green crosses rising, green ring    Cartoon Coffee Healing_V5 (Heal_001, Circle_Outline_003)
##   Coin Tonic (coins)         spinning gold coins thrown up       Coins_GravityUp_V1 (Coin Spin sprite sheet, 6 frames)
##                              aura: a coin popping now and then
##   Guard Tonic (guard)        a blue hexagon shield closing in    Shield_On (Hexagon_Circle_001 enter, _002 burst, Hexagon_001)
##                              aura: the faint shield bubble
##   Recovery Salve (recovery)  pink hearts rising                  Heart_Buff_V1 (Heart_001)
##                              aura: a heart rising now and then
##   Wisdom Tonic (xp)          violet stars rising                 Star_Buff_V1 (Star_004), recoloured to the XP violet
##                              aura: a star rising now and then
##
## Presentation only (sim.supply_used, sim.buff_time, sim.state.boost_time); one burst and one aura per
## supply kind, reused; at most ~60 particles in total; game time (it pauses with the world).

const GLOW:=preload("res://assets/vfx/buff/Glow_001.png")
const RING:=preload("res://assets/vfx/celebration/Circle_Outline_002.png")
const SOFT_RING:=preload("res://assets/vfx/buff/Circle_Outline_003.png")
const CROSS:=preload("res://assets/vfx/supply/Heal_001.png")
const COINS:=preload("res://assets/vfx/supply/Coin_Spin_Sheet.png")
const SHIELD:=preload("res://assets/vfx/supply/Hexagon_Circle_001.png")
const SHIELD_OUTER:=preload("res://assets/vfx/supply/Hexagon_Circle_002.png")
const HEX:=preload("res://assets/vfx/supply/Hexagon_001.png")
const HEART:=preload("res://assets/vfx/supply/Heart_001.png")
const STAR:=preload("res://assets/vfx/celebration/Star_004.png")
const THEMES:={
    "heal":{"color":Color(.42,1,.52),"cue":"spell_heal"},
    "coins":{"color":Color(1,.82,.28),"cue":"supply_buff"},
    "guard":{"color":Color(.38,.78,1),"cue":"supply_guard"},
    "recovery":{"color":Color(1,.5,.78),"cue":"supply_buff"},
    "xp":{"color":Color(.74,.58,1),"cue":"supply_buff"}}
## The hero's body centre above the feet (the visible pixels span about -15..+2).
const BODY:=Vector2(0,-7)
const BURST:=1.0
const LABEL_TIME:=1.4

var sim
var add_material:=CanvasItemMaterial.new()
var coin_material:=CanvasItemMaterial.new()
var bursts: Dictionary={}
var auras: Dictionary={}
var label: Label
var label_age:=INF
var last_burst:=-INF
var clock:=0.0

func setup(value) -> void:
    sim=value

func _ready() -> void:
    add_material.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD
    coin_material.particles_animation=true
    coin_material.particles_anim_h_frames=1
    coin_material.particles_anim_v_frames=6
    coin_material.particles_anim_loop=true
    texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
    for kind in THEMES:
        var color: Color=THEMES[kind].color
        var b:={"node":Node2D.new(),"age":INF,"kind":kind}
        var n: Node2D=b.node
        n.visible=false
        add_child(n)
        b.glow=_sprite(n,GLOW,true,0)
        b.ring=_sprite(n,SOFT_RING if kind=="heal" else RING,true,0)
        if kind=="guard":
            b.shield=_sprite(n,SHIELD,true,2)
            b.outer=_sprite(n,SHIELD_OUTER,true,2)
        b.particles=_burst_particles(n,kind,color)
        bursts[kind]=b
        if kind!="heal":auras[kind]=_aura(kind,color)
    label=Label.new()
    label.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
    label.mouse_filter=Control.MOUSE_FILTER_IGNORE
    label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size",10)
    label.add_theme_color_override("font_outline_color",Color(.04,.04,.06))
    label.add_theme_constant_override("outline_size",4)
    label.z_index=100
    label.visible=false
    add_child(label)

func _sprite(parent: Node2D,texture: Texture2D,additive: bool,z: int) -> Sprite2D:
    var s:=Sprite2D.new()
    s.texture=texture
    if additive:s.material=add_material
    s.z_index=z
    s.visible=false
    parent.add_child(s)
    return s

func _curve(points: Array) -> Curve:
    var c:=Curve.new()
    for p in points:c.add_point(Vector2(p[0],p[1]))
    return c

func _ramp(stops: Array) -> Gradient:
    var g:=Gradient.new()
    g.offsets=PackedFloat32Array(stops.map(func(s):return float(s[0])))
    g.colors=PackedColorArray(stops.map(func(s):return Color(1,1,1,float(s[1]))))
    return g

func _particles(parent: Node2D,texture: Texture2D,amount: int,life: float) -> CPUParticles2D:
    var p:=CPUParticles2D.new()
    p.texture=texture
    # Normal blending: LootFarmer's floors are bright (sand, snow, camp tiles), where additive
    # particles wash out to white; the theme colours only hold drawn as they are.
    p.emitting=false
    p.amount=amount
    p.lifetime=life
    p.lifetime_randomness=.3
    p.local_coords=false
    p.gravity=Vector2.ZERO
    p.z_index=2
    parent.add_child(p)
    return p

## The activation burst's own particles, per kind (positions are world coordinates: local_coords off,
## so they stay where they were thrown while the hero walks on).
func _burst_particles(parent: Node2D,kind: String,color: Color) -> CPUParticles2D:
    var p: CPUParticles2D
    match kind:
        "coins":
            p=_particles(parent,COINS,9,.9)
            p.material=coin_material
            p.one_shot=true;p.explosiveness=.85
            p.direction=Vector2(0,-1);p.spread=38
            p.initial_velocity_min=70;p.initial_velocity_max=110
            p.gravity=Vector2(0,260)
            p.scale_amount_min=.12;p.scale_amount_max=.17
            p.anim_speed_min=1.5;p.anim_speed_max=2.5
            p.anim_offset_max=1.0
            p.color_ramp=_ramp([[0,1],[.8,1],[1,0]])
        "guard":
            p=_particles(parent,HEX,8,.7)
            p.one_shot=true;p.explosiveness=.6
            p.emission_shape=CPUParticles2D.EMISSION_SHAPE_SPHERE_SURFACE
            p.emission_sphere_radius=15
            p.direction=Vector2(0,-1);p.spread=180
            p.initial_velocity_min=4;p.initial_velocity_max=10
            p.scale_amount_min=.09;p.scale_amount_max=.15
            p.color=color
            p.color_ramp=_ramp([[0,0],[.25,1],[1,0]])
        _:
            var texture: Texture2D={"heal":CROSS,"recovery":HEART,"xp":STAR}[kind]
            p=_particles(parent,texture,10,.9)
            p.one_shot=true;p.explosiveness=.5
            p.emission_shape=CPUParticles2D.EMISSION_SHAPE_RECTANGLE
            p.emission_rect_extents=Vector2(10,6)
            p.direction=Vector2(0,-1);p.spread=10
            p.initial_velocity_min=22;p.initial_velocity_max=38
            # Large enough that the cross, heart or star reads as its shape at phone size.
            p.scale_amount_min=.12;p.scale_amount_max=.17
            p.scale_amount_curve=_curve([[0,.4],[.3,1],[1,.7]])
            if kind=="xp":p.angular_velocity_min=-90;p.angular_velocity_max=90
            p.color=color
            p.color_ramp=_ramp([[0,0],[.15,1],[.7,1],[1,0]])
    return p

## A timed supply's aura while it lasts: the guard bubble, or a sparse trickle of its particles.
func _aura(kind: String,color: Color) -> Dictionary:
    var a:={"node":Node2D.new(),"alpha":0.0}
    var n: Node2D=a.node
    n.visible=false
    add_child(n)
    if kind=="guard":
        a.shield=_sprite(n,SHIELD,true,2)
        a.shield.visible=true
        a.shield.modulate=Color(color,0)
        return a
    var p: CPUParticles2D
    if kind=="coins":
        p=_particles(n,COINS,2,.8)
        p.material=coin_material
        p.direction=Vector2(0,-1);p.spread=30
        p.initial_velocity_min=55;p.initial_velocity_max=75
        p.gravity=Vector2(0,240)
        p.scale_amount_min=.1;p.scale_amount_max=.12
        p.anim_speed_min=2;p.anim_speed_max=2
        p.color_ramp=_ramp([[0,1],[.8,1],[1,0]])
    else:
        p=_particles(n,HEART if kind=="recovery" else STAR,3,1.3)
        p.emission_shape=CPUParticles2D.EMISSION_SHAPE_RECTANGLE
        p.emission_rect_extents=Vector2(9,5)
        p.direction=Vector2(0,-1);p.spread=8
        p.initial_velocity_min=12;p.initial_velocity_max=18
        p.scale_amount_min=.09;p.scale_amount_max=.12
        p.color=color
        p.color_ramp=_ramp([[0,0],[.2,.85],[.75,.85],[1,0]])
    p.emitting=false
    a.particles=p
    return a

## Seconds since the last activation burst (the world skips the generic stat burst right after one,
## so a Guard Tonic shows its shield, not a second green burst).
func since_burst() -> float:
    return clock-last_burst

## The supply id was just used (sim.supply_used). at: the hero's feet.
func play(id: String,at: Vector2) -> void:
    if sim==null or not sim.catalog.items.has(id):return
    var kind: String=str(sim.supply(id).get("effect",""))
    if not bursts.has(kind):return
    var b: Dictionary=bursts[kind]
    b.age=0.0
    var n: Node2D=b.node
    n.position=at
    n.visible=true
    b.particles.global_position=at+BODY
    b.particles.restart()
    b.particles.emitting=true
    last_burst=clock
    AudioService.play(THEMES[kind].cue)
    label.text=sim.catalog.display_name(id)
    label.add_theme_color_override("font_color",Color(THEMES[kind].color).lightened(.35))
    label.reset_size()
    label_age=0.0
    _apply_burst(b)

func stop() -> void:
    for b in bursts.values():
        b.age=INF;b.node.visible=false;b.particles.emitting=false
    for a in auras.values():
        a.alpha=0.0;a.node.visible=false
        if a.has("particles"):a.particles.emitting=false
    label.visible=false;label_age=INF

## Called by the world every frame with the hero's feet position.
func follow(at: Vector2,delta: float) -> void:
    clock+=delta
    for b in bursts.values():
        if b.age<INF:
            b.age+=delta
            b.node.position=at
            if b.age>=BURST+.2:b.age=INF;b.node.visible=false
            else:_apply_burst(b)
    if label_age<INF:
        label_age+=delta
        var u:=label_age/LABEL_TIME
        label.visible=u<1
        # Above the heal number and the HP bar, which sit at about -45.
        label.position=at+Vector2(-label.size.x*.5,-60-12*u)
        label.modulate.a=1.0 if u<.65 else 1.0-(u-.65)/.35
        if u>=1:label_age=INF
    if sim==null:return
    for kind in auras:
        var a: Dictionary=auras[kind]
        var on: bool=(float(sim.state.boost_time)>0) if kind=="coins" else _buff_on(kind)
        a.alpha=move_toward(a.alpha,1.0 if on else 0.0,delta/.35)
        a.node.visible=a.alpha>0
        a.node.position=at
        if a.has("shield"):
            var pulse:=.5+.5*sin(clock*3.0)
            a.shield.position=BODY
            a.shield.scale=Vector2.ONE*(36.0+2.0*pulse)/SHIELD.get_width()
            a.shield.rotation+=delta*.4
            a.shield.modulate=Color(THEMES[kind].color,(.38+.14*pulse)*a.alpha)
        if a.has("particles"):
            a.particles.global_position=at+BODY
            a.particles.emitting=on

func _buff_on(kind: String) -> bool:
    for id in sim.state.buffs:
        if sim.catalog.items.has(id) and str(sim.supply(id).get("effect",""))==kind and sim.buff_time(id)>0:return true
    return false

func _apply_burst(b: Dictionary) -> void:
    var u:=clampf(float(b.age)/BURST,0,1)
    var color: Color=THEMES[b.kind].color
    var g: Sprite2D=b.glow
    var gu:=clampf(u/.45,0,1)
    g.visible=gu<1
    g.position=BODY
    g.scale=Vector2.ONE*(20.0+40.0*(1.0-pow(1.0-gu,3.0)))/GLOW.get_width()
    g.modulate=Color(color,.6*(1.0-gu))
    var r: Sprite2D=b.ring
    var ru:=clampf(u/.55,0,1)
    r.visible=ru<1
    r.position=Vector2(0,1)
    r.scale=Vector2(1,.42)*(12.0+40.0*(1.0-pow(1.0-ru,3.0)))/r.texture.get_width()
    r.modulate=Color(color.lightened(.2),.95*(1.0-ru))
    if b.kind=="guard":
        # Shield_On: the bubble closes in onto the hero, then its outer ring bursts.
        var s: Sprite2D=b.shield
        var su:=clampf(u/.35,0,1)
        s.visible=u<.7
        s.position=BODY
        s.scale=Vector2.ONE*lerpf(70.0,38.0,1.0-pow(1.0-su,2.0))/SHIELD.get_width()
        s.modulate=Color(color.lightened(.2),(.85*su) if u<.35 else .85*(1.0-(u-.35)/.35))
        var o: Sprite2D=b.outer
        var ou:=clampf((u-.3)/.4,0,1)
        o.visible=u>=.3 and ou<1
        o.position=BODY
        o.scale=Vector2.ONE*(38.0+30.0*ou)/SHIELD_OUTER.get_width()
        o.modulate=Color(color.lightened(.4),.9*(1.0-ou))
