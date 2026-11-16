extends Node2D
## Change 82: the Green Alien arena barrier, drawn in the world (presentation only; the simulation owns the circle
## in campaign.arena and enforces it in sim._move). A green-gold energy ring on the ground with a soft halo, a
## band of hexagon cells (the existing supply Hexagon_001 texture) and short light shafts rising from it, turning
## slowly. It closes by shrinking in from wider with a flash, flares where the hero presses against it, and opens
## by swelling outward and fading (victory, defeat or reset). Additive, thin and translucent so actors, telegraphs,
## the joystick and the HUD stay readable. Game time: it pauses with the world.
## Change 83: while the arena's Green Alien is enraged the whole wall turns crimson (ring, halo, turning dashes,
## hexagon cells, shafts and the contact flare) over RAGE_BLEND seconds, with a thin crimson core and dark edge
## drawn with normal blending under it (rage_layer) so the red holds on bright grass, where an additive red alone
## washes out to orange. Radius, collision and blocking are the simulation's and do not change. The colour follows
## the simulation every frame (actor.rage), so it is red for exactly as long as that boss is enraged and the next
## boss's wall starts in its normal colours.

const HEX:=preload("res://assets/vfx/supply/Hexagon_001.png")
const ENERGY:=Color(.42,1,.55)
const EDGE:=Color(.85,1,.7)
const GOLD:=Color(1,.85,.4)
const RAGE_ENERGY:=Color(1,.16,.12)
const RAGE_EDGE:=Color(1,.55,.45)
const RAGE_GOLD:=Color(1,.32,.18)
const RAGE_CORE:=Color(.78,.04,.06)
const RAGE_BLEND:=.6
const CLOSE_SECONDS:=.55
const OPEN_SECONDS:=.7
const SEGMENTS:=144
const SHAFTS:=56
const CELLS:=40
const BUMP_SECONDS:=.45

var sim
var center:=Vector2.ZERO
var radius:=0.0
## "closing" / "closed" / "opening" / "" (hidden)
var phase:=""
var age:=0.0
var time:=0.0
var add_material:=CanvasItemMaterial.new()
## 0 normal, 1 fully enraged (eased toward the simulation's state).
var rage:=0.0
var rage_layer: Node2D

func _ready() -> void:
    add_material.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD
    material=add_material
    texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
    process_mode=Node.PROCESS_MODE_PAUSABLE
    # Above the fog (50): the barrier is a landmark of the fight and reads even over ground not explored yet.
    z_index=51
    visible=false
    rage_layer=Node2D.new()
    rage_layer.show_behind_parent=true
    rage_layer.use_parent_material=false
    rage_layer.material=CanvasItemMaterial.new()
    rage_layer.draw.connect(_draw_rage_core)
    add_child(rage_layer)

func close(at: Vector2,r: float) -> void:
    center=at;radius=r;phase="closing";age=0.0;visible=true
    # Change 83: a new closing starts in the colour of the boss it holds (never the previous boss's red).
    rage=1.0 if boss_enraged() else 0.0
    queue_redraw()

func open() -> void:
    if phase=="" or phase=="opening":return
    phase="opening";age=0.0
    queue_redraw()

## Hard stop with no animation (a map change or a new profile while open).
func clear() -> void:
    phase="";visible=false;rage=0.0

## Whether the boss this closed arena holds is enraged now.
func boss_enraged() -> bool:
    if sim==null or not sim.campaign.arena_active():return false
    return sim.campaign.enraged(sim._find_actor(str(sim.campaign.arena.get("boss",""))))

func _process(delta: float) -> void:
    if sim==null:return
    # Self-heal against the simulation: a closed arena is always drawn, an open one never stays.
    if sim.campaign.arena_active() and (phase=="" or phase=="opening"):close(sim.campaign.arena_center(),sim.campaign.arena_radius())
    elif not sim.campaign.arena_active() and phase in ["closing","closed"]:open()
    if phase=="":
        rage=0.0
        return
    if phase!="opening":rage=move_toward(rage,1.0 if boss_enraged() else 0.0,delta/RAGE_BLEND)
    age+=delta;time+=delta
    if phase=="closing" and age>=CLOSE_SECONDS:phase="closed"
    if phase=="opening" and age>=OPEN_SECONDS:
        phase="";visible=false
        return
    queue_redraw()
    rage_layer.queue_redraw()

func _draw() -> void:
    if phase=="":return
    var r:=radius
    var a:=1.0
    var flash:=0.0
    match phase:
        "closing":
            var u:=clampf(age/CLOSE_SECONDS,0,1)
            var e:=1.0-pow(1.0-u,3.0)
            r=lerpf(radius+46.0,radius,e)
            a=u
            flash=1.0-u
        "opening":
            var u:=clampf(age/OPEN_SECONDS,0,1)
            r=lerpf(radius,radius+60.0,1.0-pow(1.0-u,2.0))
            a=1.0-u
            flash=.6*(1.0-u)
    var pulse:=.85+.15*sin(time*3.2)
    # Change 83: the wall's palette (normal green-gold, enraged crimson); rage also beats a little faster.
    var energy:=ENERGY.lerp(RAGE_ENERGY,rage)
    var edge:=EDGE.lerp(RAGE_EDGE,rage)
    var gold:=GOLD.lerp(RAGE_GOLD,rage)
    if rage>0:pulse=.8+.2*sin(time*(3.2+3.0*rage))
    # Halo outside and inside the line, then the bright core.
    draw_arc(center,r+3,0,TAU,SEGMENTS,Color(energy,.16*a*pulse),12.0,true)
    draw_arc(center,r-4,0,TAU,SEGMENTS,Color(energy,.22*a*pulse),7.0,true)
    draw_arc(center,r,0,TAU,SEGMENTS,Color(edge.lerp(Color.WHITE,flash),(.75+.25*flash)*a),2.5,true)
    # Turning dashes along the line.
    for i in range(24):
        var s:=time*.35+TAU*i/24.0
        draw_arc(center,r+1.5,s,s+.12,6,Color(gold,.55*a),2.0,true)
    # Hexagon cells riding the barrier, breathing out of phase.
    var cell:=11.0
    for i in range(CELLS):
        var ang:=-time*.18+TAU*i/CELLS
        var p:=center+Vector2(cos(ang),sin(ang))*r
        var k:=.5+.5*sin(time*2.6+i*1.7)
        draw_texture_rect(HEX,Rect2(p-Vector2(cell,cell)*.5,Vector2(cell,cell)),false,Color(energy,(.12+.28*k)*a))
    # Light shafts rising from the ring (the wall's height on a top-down map).
    for i in range(SHAFTS):
        var ang:=time*.12+TAU*i/SHAFTS
        var p:=center+Vector2(cos(ang),sin(ang))*r
        var h:=(12.0+7.0*sin(time*3.0+i*2.3))*(1.0+flash)
        var w:=1.6
        var base:=Color(energy,.42*a)
        draw_polygon(PackedVector2Array([p+Vector2(-w,0),p+Vector2(w,0),p+Vector2(w,-h),p+Vector2(-w,-h)]),
            PackedColorArray([base,base,Color(energy,0),Color(energy,0)]))
    # A flare where the hero pressed against the barrier.
    var bump: Vector2=sim.campaign.arena_bump
    var since: float=float(sim.state.get("playtime_total",0.0))-float(sim.campaign.arena_bump_clock)
    if phase!="opening" and bump!=Vector2.INF and since>=0 and since<BUMP_SECONDS:
        var u:=since/BUMP_SECONDS
        var ang:=(bump-center).angle()
        var spread:=.22+.25*u
        draw_arc(center,r,ang-spread,ang+spread,16,Color(Color.WHITE,(1.0-u)*a),4.0,true)
        draw_arc(center,r-6-10*u,ang-spread*.8,ang+spread*.8,16,Color(gold,.7*(1.0-u)*a),2.0,true)

## Change 83: the enraged wall's solid core (normal blending, under the additive layers): a dark edge and a crimson
## band on the line, so the red reads on bright floors as well as on dark ones.
func _draw_rage_core() -> void:
    if phase=="" or rage<=0.0:return
    var a:=rage*(1.0-clampf(age/OPEN_SECONDS,0,1) if phase=="opening" else 1.0)
    var r:=radius
    if phase=="closing":r=lerpf(radius+46.0,radius,1.0-pow(1.0-clampf(age/CLOSE_SECONDS,0,1),3.0))
    elif phase=="opening":r=lerpf(radius,radius+60.0,1.0-pow(1.0-clampf(age/OPEN_SECONDS,0,1),2.0))
    rage_layer.draw_arc(center,r,0,TAU,SEGMENTS,Color(.12,0,0,.55*a),6.5,true)
    rage_layer.draw_arc(center,r,0,TAU,SEGMENTS,Color(RAGE_CORE,.85*a),3.5,true)
