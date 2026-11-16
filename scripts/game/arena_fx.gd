extends Node2D
## Change 82: the Green Alien arena barrier, drawn in the world (presentation only; the simulation owns the circle
## in campaign.arena and enforces it in sim._move). A green-gold energy ring on the ground with a soft halo, a
## band of hexagon cells (the existing supply Hexagon_001 texture) and short light shafts rising from it, turning
## slowly. It closes by shrinking in from wider with a flash, flares where the hero presses against it, and opens
## by swelling outward and fading (victory, defeat or reset). Additive, thin and translucent so actors, telegraphs,
## the joystick and the HUD stay readable. Game time: it pauses with the world.

const HEX:=preload("res://assets/vfx/supply/Hexagon_001.png")
const ENERGY:=Color(.42,1,.55)
const EDGE:=Color(.85,1,.7)
const GOLD:=Color(1,.85,.4)
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

func _ready() -> void:
    add_material.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD
    material=add_material
    texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
    process_mode=Node.PROCESS_MODE_PAUSABLE
    # Above the fog (50): the barrier is a landmark of the fight and reads even over ground not explored yet.
    z_index=51
    visible=false

func close(at: Vector2,r: float) -> void:
    center=at;radius=r;phase="closing";age=0.0;visible=true
    queue_redraw()

func open() -> void:
    if phase=="" or phase=="opening":return
    phase="opening";age=0.0
    queue_redraw()

## Hard stop with no animation (a map change or a new profile while open).
func clear() -> void:
    phase="";visible=false

func _process(delta: float) -> void:
    if sim==null:return
    # Self-heal against the simulation: a closed arena is always drawn, an open one never stays.
    if sim.campaign.arena_active() and (phase=="" or phase=="opening"):close(sim.campaign.arena_center(),sim.campaign.arena_radius())
    elif not sim.campaign.arena_active() and phase in ["closing","closed"]:open()
    if phase=="":return
    age+=delta;time+=delta
    if phase=="closing" and age>=CLOSE_SECONDS:phase="closed"
    if phase=="opening" and age>=OPEN_SECONDS:
        phase="";visible=false
        return
    queue_redraw()

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
    # Halo outside and inside the line, then the bright core.
    draw_arc(center,r+3,0,TAU,SEGMENTS,Color(ENERGY,.16*a*pulse),12.0,true)
    draw_arc(center,r-4,0,TAU,SEGMENTS,Color(ENERGY,.22*a*pulse),7.0,true)
    draw_arc(center,r,0,TAU,SEGMENTS,Color(EDGE.lerp(Color.WHITE,flash),(.75+.25*flash)*a),2.5,true)
    # Turning dashes along the line.
    for i in range(24):
        var s:=time*.35+TAU*i/24.0
        draw_arc(center,r+1.5,s,s+.12,6,Color(GOLD,.55*a),2.0,true)
    # Hexagon cells riding the barrier, breathing out of phase.
    var cell:=11.0
    for i in range(CELLS):
        var ang:=-time*.18+TAU*i/CELLS
        var p:=center+Vector2(cos(ang),sin(ang))*r
        var k:=.5+.5*sin(time*2.6+i*1.7)
        draw_texture_rect(HEX,Rect2(p-Vector2(cell,cell)*.5,Vector2(cell,cell)),false,Color(ENERGY,(.12+.28*k)*a))
    # Light shafts rising from the ring (the wall's height on a top-down map).
    for i in range(SHAFTS):
        var ang:=time*.12+TAU*i/SHAFTS
        var p:=center+Vector2(cos(ang),sin(ang))*r
        var h:=(12.0+7.0*sin(time*3.0+i*2.3))*(1.0+flash)
        var w:=1.6
        var base:=Color(ENERGY,.42*a)
        draw_polygon(PackedVector2Array([p+Vector2(-w,0),p+Vector2(w,0),p+Vector2(w,-h),p+Vector2(-w,-h)]),
            PackedColorArray([base,base,Color(ENERGY,0),Color(ENERGY,0)]))
    # A flare where the hero pressed against the barrier.
    var bump: Vector2=sim.campaign.arena_bump
    var since: float=float(sim.state.get("playtime_total",0.0))-float(sim.campaign.arena_bump_clock)
    if phase!="opening" and bump!=Vector2.INF and since>=0 and since<BUMP_SECONDS:
        var u:=since/BUMP_SECONDS
        var ang:=(bump-center).angle()
        var spread:=.22+.25*u
        draw_arc(center,r,ang-spread,ang+spread,16,Color(Color.WHITE,(1.0-u)*a),4.0,true)
        draw_arc(center,r-6-10*u,ang-spread*.8,ang+spread*.8,16,Color(GOLD,.7*(1.0-u)*a),2.0,true)
