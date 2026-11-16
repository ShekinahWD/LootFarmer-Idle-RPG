extends Node2D
## Change 82: the Green Alien unsealing ceremony, drawn in the world (presentation only). The simulation owns the
## clock (campaign.ceremony_time; the world is frozen while it runs) and this node only reads it every frame, so
## pause, background and a dropped ceremony stay in step with no timers of its own. The 13 keys are the existing
## boss-key art (assets/ui/Key - Gold.png, the Change 81 pickup); the glows, rings and sparkles are the
## repository's existing VFX textures.
##
##   0.00-0.65  13 keys pop in one by one around the hero on a gold ground ring.
##   0.40-2.90  they orbit (an ellipse at body height, keys behind the hero drawn behind it), faster and brighter.
##   2.90-3.45  they tighten into a bright knot above the hero's head.
##   3.45-4.10  one after another they streak along an arc into the Green Alien.
##   4.10       the seal breaks (world_moments "unseal" at the boss, shake, cue, banner; started by world/game_ui).
##   4.10-5.60  the boss shines while the message reads; then the fight starts and the arena closes.

const KEY:=preload("res://assets/ui/Key - Gold.png")
const GLOW:=preload("res://assets/vfx/buff/Glow_001.png")
const RING:=preload("res://assets/vfx/buff/Circle_Outline_003.png")
const STAR:=preload("res://assets/vfx/celebration/Star_004.png")
const GOLD:=Color(1,.82,.3)
const COUNT:=13
## World units (the hero's visible body spans about -15..+2 above its feet).
const KEY_SIZE:=13.0
const GLOW_SIZE:=18.0
const ORBIT:=Vector2(30,15)
const BODY:=-11.0
const KNOT_LIFT:=-34.0
const APPEAR:=.05
const POP:=.25
const ORBIT_FROM:=.4
const RAMP:=2.5
const GATHER_AT:=2.9
const FLY_AT:=3.45
const FLY_STAGGER:=.025

var sim
## -> world position of an actor's feet as drawn (falls back to the simulation position).
var feet: Callable
var keys: Array=[]
var glows: Array=[]
var ring: Sprite2D
var sparkles: CPUParticles2D
var add_material:=CanvasItemMaterial.new()

func _ready() -> void:
    add_material.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD
    texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
    process_mode=Node.PROCESS_MODE_PAUSABLE
    ring=Sprite2D.new();ring.texture=RING;ring.material=add_material;ring.z_index=0
    add_child(ring)
    for i in range(COUNT):
        var g:=Sprite2D.new();g.texture=GLOW;g.material=add_material
        add_child(g);glows.append(g)
        var k:=Sprite2D.new();k.texture=KEY
        add_child(k);keys.append(k)
    sparkles=CPUParticles2D.new()
    sparkles.texture=STAR;sparkles.material=add_material;sparkles.z_index=3
    sparkles.amount=18;sparkles.lifetime=.7;sparkles.local_coords=false;sparkles.emitting=false
    sparkles.emission_shape=CPUParticles2D.EMISSION_SHAPE_RING
    sparkles.emission_ring_radius=ORBIT.x;sparkles.emission_ring_inner_radius=ORBIT.x*.6
    sparkles.direction=Vector2(0,-1);sparkles.spread=40;sparkles.gravity=Vector2.ZERO
    sparkles.initial_velocity_min=6;sparkles.initial_velocity_max=18
    sparkles.scale_amount_min=.02;sparkles.scale_amount_max=.045
    sparkles.color=GOLD.lightened(.3)
    var ramp:=Gradient.new()
    ramp.offsets=PackedFloat32Array([0.0,.25,1.0])
    ramp.colors=PackedColorArray([Color(1,1,1,0),Color.WHITE,Color(1,1,1,0)])
    sparkles.color_ramp=ramp
    add_child(sparkles)
    visible=false

func running() -> bool:
    return visible

## The orbit angle after t seconds: 1.4 rad/s, accelerating smoothly by +7.6 rad/s over RAMP seconds.
static func orbit_angle(t: float) -> float:
    var u:=clampf(t-ORBIT_FROM,0.0,RAMP)
    var a:=1.4*t+7.6*u*u/(2.0*RAMP)
    if t>ORBIT_FROM+RAMP:a+=7.6*(t-ORBIT_FROM-RAMP)
    return a

func _process(_delta: float) -> void:
    if sim==null:return
    var c=sim.campaign
    if not c.ceremony_active():
        if visible:visible=false;sparkles.emitting=false
        return
    var t: float=c.ceremony_time
    var boss: Dictionary=sim._find_actor(c.ceremony_boss)
    if boss.is_empty():return
    visible=true
    var hero: Vector2=feet.call("player")
    var target: Vector2=feet.call(str(boss.id))+Vector2(0,-12.0*float(sim.catalog.groups[int(boss.group)].visual_scale))
    var center:=hero+Vector2(0,BODY)
    var ramp:=clampf((t-ORBIT_FROM)/RAMP,0.0,1.0)
    # Ground ring under the hero: grows in, glows brighter with the orbit, fades as the keys leave.
    var ring_a:=clampf(t/.4,0.0,1.0)*(1.0-clampf((t-FLY_AT)/.4,0.0,1.0))
    ring.visible=ring_a>0
    ring.position=hero+Vector2(0,1)
    var ring_px:=lerpf(30.0,74.0,1.0-pow(1.0-clampf(t/.6,0,1),3.0))
    ring.scale=Vector2(1.0,.42)*ring_px/RING.get_width()
    ring.rotation=0.0
    ring.modulate=Color(GOLD,(.35+.3*ramp)*ring_a)
    sparkles.position=center
    var want_sparks:=t>=.3 and t<FLY_AT
    if want_sparks!=sparkles.emitting:sparkles.emitting=want_sparks
    var spin:=orbit_angle(t)
    var gather:=clampf((t-GATHER_AT)/(FLY_AT-GATHER_AT),0.0,1.0)
    gather=gather*gather*(3.0-2.0*gather)
    for i in range(COUNT):
        var k: Sprite2D=keys[i]
        var g: Sprite2D=glows[i]
        var born:=t-APPEAR*i
        if born<0:
            k.visible=false;g.visible=false
            continue
        var pop:=clampf(born/POP,0.0,1.0)
        var size_k:=1.0+.35*sin(pop*PI) if pop<1.0 else 1.0
        size_k*=pop
        var angle:=spin+TAU*i/COUNT
        var radius:=ORBIT.lerp(Vector2(5,3),gather)
        var lift:=lerpf(0.0,KNOT_LIFT-BODY,gather)
        var pos:=center+Vector2(cos(angle)*radius.x,sin(angle)*radius.y+lift)
        var behind:=sin(angle)<0 and gather<.5
        var fly_start:=FLY_AT+FLY_STAGGER*i
        var alpha:=1.0
        var rot:=sin(angle*1.5+i)*.25*(1.0-gather)
        var bright:=1.0+.35*ramp+.35*gather
        if t>=fly_start:
            var dur: float=c.CEREMONY_UNSEAL_AT-fly_start
            var u:=clampf((t-fly_start)/maxf(dur,.05),0.0,1.0)
            var e:=u*u
            var from:=center+Vector2(0,KNOT_LIFT-BODY)
            var ctrl:=from.lerp(target,.5)+Vector2((float(i)-6.0)*6.0,-70.0)
            pos=from.lerp(ctrl,e).lerp(ctrl.lerp(target,e),e)
            var ahead:=from.lerp(ctrl,minf(1.0,e+.05)).lerp(ctrl.lerp(target,minf(1.0,e+.05)),minf(1.0,e+.05))
            rot=(ahead-pos).angle()+PI*.5
            behind=false
            alpha=1.0 if u<1.0 else 0.0
            size_k*=lerpf(1.0,.7,u)
            g.scale=Vector2(.7,1.0+2.2*u)*GLOW_SIZE/GLOW.get_width()
        else:
            g.scale=Vector2.ONE*GLOW_SIZE*(.8+.3*ramp+.5*gather)/GLOW.get_width()
        k.visible=alpha>0;g.visible=alpha>0
        k.position=pos;g.position=pos
        k.rotation=rot;g.rotation=rot
        k.scale=Vector2.ONE*KEY_SIZE*size_k/KEY.get_width()
        k.modulate=Color(bright,bright,bright*.92,alpha)
        g.modulate=Color(GOLD,(.25+.2*ramp+.35*gather)*alpha*pop)
        # An orbiting key on the far side of the hero is drawn behind the hero (actors are z 1).
        k.z_index=0 if behind else 3
        g.z_index=0 if behind else 2
