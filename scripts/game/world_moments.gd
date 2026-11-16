extends Node2D
## Change 67 follow-up: moving around the world and beating a boss each have their own moment, on
## the ground where it happens (the map-travel iris and the boss title are drawn by game_ui).
##
##   Camp teleport (same map)   cyan "blink": a wind swirl collapses where the hero stood and a shard
##                              streak leaves upward; a beat later the swirl bursts open around the hero
##                              at the camp with a flattened ring and motes. (Circle_Wind_004,
##                              Wind_Shard_002, Power_Up ring squash)
##   Map travel                 violet "portal" at the arrival point: rotating violet rays, three rings
##                              rippling out violet to gold, a shockwave, embers. (Radial_Loop_V1 rays,
##                              Impact_Sonar rings, Shockwave_001)
##   Respawn camp selected      gold "beacon" planted at the camp: a gold beam, a ground ring and rising
##                              stars. (Light_Ray_007, Star_Bursts / Star_004)
##   Boss defeated              triumph at the boss: a white flash, a big shockwave, gold god-rays turning
##                              behind the fallen boss, a confetti and coin shower, gold embers.
##                              (Radial_Loop_V1, Confetti_Bursts_Center_V2, Coins_GravityUp, Explosion embers)
##
## Presentation only; one instance of each moment, replayed (a new one restarts it); game time (it
## pauses with the world). Particles use normal blending where colour must hold on bright floors.

const GLOW:=preload("res://assets/vfx/buff/Glow_001.png")
const RAY:=preload("res://assets/vfx/buff/Light_Ray_007.png")
const SOFT_RING:=preload("res://assets/vfx/buff/Circle_Outline_003.png")
const RING:=preload("res://assets/vfx/celebration/Circle_Outline_002.png")
const SHOCK:=preload("res://assets/vfx/celebration/Shockwave_001.png")
const STAR:=preload("res://assets/vfx/celebration/Star_004.png")
const SWIRL:=preload("res://assets/vfx/moments/Circle_Wind_004.png")
const SHARD:=preload("res://assets/vfx/moments/Wind_Shard_002.png")
const RAYS:=preload("res://assets/vfx/moments/Radial_Glow_002.png")
const CONFETTI:=preload("res://assets/vfx/moments/Confetti_Sheet.png")
const COINS:=preload("res://assets/vfx/supply/Coin_Spin_Sheet.png")
const CYAN:=Color(.36,.94,1)
const VIOLET:=Color(.72,.45,1)
const GOLD:=Color(1,.8,.3)
const ALIEN:=Color(.45,1,.5)
const BODY:=Vector2(0,-7)

var add_material:=CanvasItemMaterial.new()
var moments: Dictionary={}

func _ready() -> void:
    add_material.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD
    texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
    # --- camp teleport: two places (where the hero left, where they arrived)
    var m:=_moment("teleport",.75)
    _layer(m,"from",SWIRL,{"t0":0,"d":.38,"size":[46,6],"alpha":[1,.5],"spin":7.0,"color":CYAN,"y":-4})
    _layer(m,"from",SHARD,{"t0":0,"d":.3,"size":[18,18],"stretch":[1,4.5],"alpha":[.95,0],"rot":-PI*.5,"color":CYAN.lightened(.3),"y":-22,"anchor_up":true})
    _layer(m,"from",GLOW,{"t0":0,"d":.3,"size":[40,10],"alpha":[.7,0],"color":CYAN,"add":true,"y":-7})
    _layer(m,"to",GLOW,{"t0":.12,"d":.35,"size":[10,56],"alpha":[.9,0],"color":CYAN,"add":true,"y":-7})
    _layer(m,"to",SHARD,{"t0":.08,"d":.22,"size":[18,18],"stretch":[4.5,1],"alpha":[.95,0],"rot":-PI*.5,"color":CYAN.lightened(.3),"y":-4,"anchor_up":true})
    _layer(m,"to",SWIRL,{"t0":.12,"d":.55,"size":[8,78],"alpha":[1,0],"spin":-6.0,"color":CYAN,"y":-4})
    _layer(m,"to",RING,{"t0":.16,"d":.45,"size":[10,52],"flat":.42,"alpha":[.95,0],"color":CYAN.lightened(.2),"y":1})
    m.particles["to"]=_motes(m,"to",STAR,CYAN,10,.12)
    # --- map travel: one portal where the hero arrives
    m=_moment("portal",1.4)
    _layer(m,"to",RAYS,{"t0":.1,"d":1.3,"size":[40,170],"alpha":[.8,0],"hold":.45,"spin":1.6,"color":VIOLET,"y":-7})
    _layer(m,"to",GLOW,{"t0":.1,"d":.5,"size":[20,90],"alpha":[.9,0],"color":VIOLET,"add":true,"y":-7})
    for i in range(3):
        _layer(m,"to",SOFT_RING,{"t0":.15+i*.16,"d":.6,"size":[10,96],"alpha":[1,0],"color":VIOLET.lerp(GOLD,i/2.0),"y":-7})
    _layer(m,"to",SHOCK,{"t0":.12,"d":.45,"size":[20,110],"alpha":[.8,0],"color":VIOLET.lightened(.4),"y":-7})
    m.particles["to"]=_motes(m,"to",GLOW,VIOLET.lightened(.3),18,.15,true)
    # --- respawn camp selected: a beacon at the camp
    m=_moment("beacon",1.2)
    _layer(m,"to",RAY,{"t0":0,"d":1.1,"size":[34,34],"stretch":[0,3.0],"alpha":[1,0],"hold":.45,"color":GOLD,"y":0,"anchor_up":true})
    _layer(m,"to",RING,{"t0":0,"d":.6,"size":[14,70],"flat":.42,"alpha":[1,0],"color":GOLD,"y":1})
    _layer(m,"to",SOFT_RING,{"t0":.2,"d":.6,"size":[14,56],"flat":.42,"alpha":[.9,0],"color":GOLD.lightened(.3),"y":1})
    m.particles["to"]=_motes(m,"to",STAR,GOLD,12,0.0)
    # --- boss defeated
    m=_moment("boss",2.2)
    _layer(m,"to",RAYS,{"t0":.05,"d":2.0,"size":[60,190],"alpha":[.7,0],"hold":1.1,"spin":.7,"color":GOLD,"y":0})
    _layer(m,"to",RAYS,{"t0":.1,"d":1.9,"size":[40,140],"alpha":[.55,0],"hold":1.0,"spin":-.45,"color":Color(1,.95,.7),"y":0})
    _layer(m,"to",GLOW,{"t0":0,"d":.45,"size":[30,170],"alpha":[1,0],"color":Color(1,.97,.85),"add":true,"y":0})
    _layer(m,"to",SHOCK,{"t0":.02,"d":.55,"size":[24,200],"alpha":[.9,0],"color":GOLD.lightened(.4),"y":0})
    _layer(m,"to",RING,{"t0":.08,"d":.6,"size":[20,160],"flat":.45,"alpha":[1,0],"color":GOLD,"y":14})
    m.particles["to"]=_confetti(m,"to")
    m.particles["coins"]=_coins(m,"to")
    m.particles["embers"]=_motes(m,"to",GLOW,GOLD,22,0.0,true,true)
    # --- Change 82: the Green Alien's seal breaks (the 13 keys strike it): a white-gold flash, a green-gold
    # shockwave, alien-green god-rays turning behind the boss, two rings and rising sparks; held while the
    # banner reads. (Radial_Glow_002, Shockwave_001, Circle_Outline_002/003, Star_004, Glow_001)
    m=_moment("unseal",1.6)
    _layer(m,"to",GLOW,{"t0":0,"d":.4,"size":[30,150],"alpha":[1,0],"color":Color(1,.98,.85),"add":true,"y":0})
    _layer(m,"to",SHOCK,{"t0":.02,"d":.6,"size":[20,190],"alpha":[.95,0],"color":ALIEN.lightened(.3),"y":0})
    _layer(m,"to",RAYS,{"t0":.05,"d":1.5,"size":[50,170],"alpha":[.75,0],"hold":.6,"spin":.9,"color":ALIEN,"y":0})
    _layer(m,"to",RAYS,{"t0":.1,"d":1.4,"size":[36,120],"alpha":[.6,0],"hold":.55,"spin":-.6,"color":GOLD,"y":0})
    _layer(m,"to",RING,{"t0":.06,"d":.65,"size":[16,140],"flat":.45,"alpha":[1,0],"color":GOLD,"y":14})
    _layer(m,"to",SOFT_RING,{"t0":.2,"d":.7,"size":[16,110],"flat":.45,"alpha":[.9,0],"color":ALIEN,"y":14})
    m.particles["to"]=_motes(m,"to",STAR,GOLD,20,0.0,true,true)
    for key in moments:moments[key].node_to.visible=false

func _moment(key: String,length: float) -> Dictionary:
    var m:={"key":key,"age":INF,"length":length,"layers":[],"particles":{},"node_from":Node2D.new(),"node_to":Node2D.new(),"scale":1.0}
    add_child(m.node_from);add_child(m.node_to)
    m.node_from.visible=false
    moments[key]=m
    return m

func _layer(m: Dictionary,place: String,texture: Texture2D,p: Dictionary) -> void:
    var s:=Sprite2D.new()
    s.texture=texture
    if p.get("add",false):s.material=add_material
    s.visible=false
    if p.get("anchor_up",false):s.offset=Vector2(texture.get_width()*.5,0) if p.get("rot",0.0)!=0.0 else Vector2(0,-texture.get_height()*.5)
    m["node_"+place].add_child(s)
    p.sprite=s
    m.layers.append(p)

func _curve(points: Array) -> Curve:
    var c:=Curve.new()
    for pt in points:c.add_point(Vector2(pt[0],pt[1]))
    return c

func _fade(stops: Array) -> Gradient:
    var g:=Gradient.new()
    g.offsets=PackedFloat32Array(stops.map(func(st):return float(st[0])))
    g.colors=PackedColorArray(stops.map(func(st):return Color(1,1,1,float(st[1]))))
    return g

func _particles(m: Dictionary,place: String,texture: Texture2D,amount: int,life: float) -> CPUParticles2D:
    var p:=CPUParticles2D.new()
    p.texture=texture
    p.emitting=false
    p.one_shot=true
    p.explosiveness=.8
    p.amount=amount
    p.lifetime=life
    p.lifetime_randomness=.3
    p.local_coords=true
    p.gravity=Vector2.ZERO
    p.z_index=2
    m["node_"+place].add_child(p)
    return p

## Rising motes (stars or glow dots); burst: thrown in every direction instead of rising.
func _motes(m: Dictionary,place: String,texture: Texture2D,color: Color,amount: int,delay: float,additive:=false,burst:=false) -> CPUParticles2D:
    var p:=_particles(m,place,texture,amount,.9)
    if additive:p.material=add_material
    p.position=BODY
    p.set_meta("delay",delay)
    p.emission_shape=CPUParticles2D.EMISSION_SHAPE_RECTANGLE
    p.emission_rect_extents=Vector2(12,6)
    if burst:
        p.spread=180;p.initial_velocity_min=60;p.initial_velocity_max=150
        p.damping_min=80;p.damping_max=120;p.gravity=Vector2(0,60)
        p.scale_amount_min=.05;p.scale_amount_max=.1
    else:
        p.direction=Vector2(0,-1);p.spread=14
        p.initial_velocity_min=26;p.initial_velocity_max=48
        p.scale_amount_min=.09 if texture==STAR else .05;p.scale_amount_max=.14 if texture==STAR else .09
        if texture==STAR:p.angular_velocity_min=-120;p.angular_velocity_max=120
    p.color=color
    p.color_ramp=_fade([[0,0],[.15,1],[.7,1],[1,0]])
    return p

func _confetti(m: Dictionary,place: String) -> CPUParticles2D:
    var p:=_particles(m,place,CONFETTI,40,1.8)
    var mat:=CanvasItemMaterial.new()
    mat.particles_animation=true;mat.particles_anim_h_frames=1;mat.particles_anim_v_frames=3;mat.particles_anim_loop=false
    p.material=mat
    p.explosiveness=.95
    p.direction=Vector2(0,-1);p.spread=70
    p.initial_velocity_min=110;p.initial_velocity_max=190
    p.gravity=Vector2(0,190)
    p.damping_min=30;p.damping_max=50
    p.angular_velocity_min=-360;p.angular_velocity_max=360
    p.scale_amount_min=.07;p.scale_amount_max=.11
    p.anim_speed_min=0;p.anim_speed_max=0
    p.anim_offset_min=0;p.anim_offset_max=1
    var colors:=Gradient.new()
    colors.offsets=PackedFloat32Array([0,.2,.4,.6,.8,1])
    colors.colors=PackedColorArray([Color(1,.35,.35),Color(1,.75,.2),Color(1,.95,.35),Color(.4,.95,.5),Color(.35,.7,1),Color(.8,.45,1)])
    colors.interpolation_mode=Gradient.GRADIENT_INTERPOLATE_CONSTANT
    p.color_initial_ramp=colors
    p.color_ramp=_fade([[0,1],[.8,1],[1,0]])
    return p

func _coins(m: Dictionary,place: String) -> CPUParticles2D:
    var p:=_particles(m,place,COINS,12,1.1)
    var mat:=CanvasItemMaterial.new()
    mat.particles_animation=true;mat.particles_anim_h_frames=1;mat.particles_anim_v_frames=6;mat.particles_anim_loop=true
    p.material=mat
    p.explosiveness=.9
    p.direction=Vector2(0,-1);p.spread=55
    p.initial_velocity_min=90;p.initial_velocity_max=150
    p.gravity=Vector2(0,280)
    p.scale_amount_min=.14;p.scale_amount_max=.18
    p.anim_speed_min=2;p.anim_speed_max=3;p.anim_offset_max=1
    p.color_ramp=_fade([[0,1],[.85,1],[1,0]])
    return p

## Plays a moment: to is where it lands (world units, feet or body), from the departure point (teleport).
func play(key: String,to: Vector2,from:=Vector2.INF,scale_factor:=1.0) -> void:
    var m: Dictionary=moments[key]
    m.age=0.0
    m.scale=scale_factor
    m.node_to.position=to
    m.node_to.scale=Vector2.ONE*scale_factor
    m.node_to.visible=true
    m.node_from.visible=from!=Vector2.INF
    if from!=Vector2.INF:m.node_from.position=from
    for p in m.particles.values():
        p.emitting=false
        p.set_meta("started",false)
    _apply(m)

func running(key: String) -> bool:
    return moments[key].age<INF

func stop() -> void:
    for m in moments.values():
        m.age=INF;m.node_to.visible=false;m.node_from.visible=false
        for p in m.particles.values():p.emitting=false

func _process(delta: float) -> void:
    for m in moments.values():
        if m.age==INF:continue
        m.age+=delta
        if m.age>=m.length+.6:
            m.age=INF;m.node_to.visible=false;m.node_from.visible=false
            continue
        _apply(m)

func _apply(m: Dictionary) -> void:
    var t: float=m.age
    for p in m.particles.values():
        if not p.get_meta("started",false) and t>=float(p.get_meta("delay",0.0)):
            p.set_meta("started",true);p.restart();p.emitting=true
    for l in m.layers:
        var s: Sprite2D=l.sprite
        var d: float=l.d
        var age: float=t-float(l.t0)
        s.visible=age>=0 and age<d
        if not s.visible:continue
        var u:=age/d
        var grow:=1.0-pow(1.0-u,3.0)
        var px: float=lerpf(l.size[0],l.size[1],grow)
        var hold: float=l.get("hold",0.0)
        var fade_u:=0.0 if u<hold else (u-hold)/maxf(.001,1.0-hold)
        var a: float=lerpf(l.alpha[0],l.alpha[1],fade_u)
        var sc:=Vector2.ONE*px/s.texture.get_width()
        if l.has("flat"):sc.y*=float(l.flat)
        if l.has("stretch"):
            var k: float=lerpf(l.stretch[0],l.stretch[1],minf(1.0,u/.35))
            sc=Vector2(sc.x,sc.y*k) if not l.has("rot") else Vector2(sc.x*k,sc.y)
        s.scale=sc
        s.rotation=float(l.get("rot",0.0))+float(l.get("spin",0.0))*age
        s.position=Vector2(0,float(l.get("y",0.0)))
        s.modulate=Color(l.color,a)
