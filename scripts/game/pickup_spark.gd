extends Node2D
## A ground drop's presentation (Change 41): the icon at its real spot, a short arrival hop for drops
## that appear during play, a tier-coloured ring under equipment and the pack's sparkle, once on landing
## and then periodically with a per-drop phase. Every value comes from the PickupStyle resource. The
## world sets position, visibility and fade; this node never changes the simulation's pickup.
## Change 59: once landed, the icon child floats gently (float_* in the style); the node itself, the
## ring and the sparkle stay on the real spot. The world's reminder hand reads icon_offset().
## style is resources/game/pickup_style.tres (scripts/game/pickup_style.gd).
const SPARK=preload("res://assets/PixelPlains/Sparks 25x27.png")
@export var style: Resource=preload("res://resources/game/pickup_style.tres")
var clock: float=0
## Seconds since this drop arrived (INF for a drop that was already on the ground).
var age: float=INF
var gear:=false
var glint_color:=Color.WHITE
var phase:=0.0
var base_scale:=Vector2.ONE
var float_phase:=0.0

## kind: the item kind; tier_color: its inventory colour; uid: the pickup's id (sparkle phase);
## fresh: it dropped just now (it hops in) rather than being there already (a load or map change).
func setup(texture: Texture2D,kind: String,tier_color: Color,uid: int,fresh: bool) -> void:
    gear=kind in ["weapon","outfit"]
    glint_color=tier_color
    phase=fmod(float(uid)*0.618,1.0)*style.spark_interval
    float_phase=fmod(float(uid)*0.382,1.0)*TAU
    var icon: Sprite2D=$Icon
    icon.texture=texture
    base_scale=Vector2.ONE*(style.gear_size if gear else style.supply_size)/maxf(texture.get_width(),texture.get_height())
    icon.scale=base_scale
    icon.position=Vector2.ZERO
    age=0.0 if fresh else INF
    clock=phase
    _arrive()

func _process(dt: float) -> void:
    if not visible:return
    clock+=dt
    if age<INF:
        var hopping: bool=age<style.hop_seconds
        age+=dt
        if hopping:_arrive()
        # After the landing sparkle the drop joins the periodic sparkle like any other.
        if age>=style.hop_seconds+style.spark_seconds:age=INF
    if age>=style.hop_seconds:_float()
    queue_redraw()

## The idle float: a sine around the real spot at this drop's own phase. A drop that has just landed
## eases in from rest, so the float never jumps out of the arrival hop.
func _float() -> void:
    var ease_in: float=1.0
    if age<INF:ease_in=clampf((age-style.hop_seconds)/maxf(style.float_ease_in,.01),0.0,1.0)
    var y: float=-style.float_height*.5*ease_in*sin(TAU*clock/maxf(style.float_period,.1)+float_phase)
    $Icon.position=Vector2(0,y)

## The icon's current offset from the drop's real spot (arrival hop or float) and its displayed size.
func icon_offset() -> Vector2:
    return $Icon.position

func icon_size() -> float:
    return style.gear_size if gear else style.supply_size

## The hop: a parabola up and down onto the real spot, scaling from small with a short overshoot.
func _arrive() -> void:
    var icon: Sprite2D=$Icon
    if age>=style.hop_seconds:
        icon.position=Vector2.ZERO;icon.scale=base_scale
        if z_index!=0:z_index=0
        return
    var t: float=clampf(age/maxf(style.hop_seconds,.01),0.0,1.0)
    var height: float=style.hop_height*(1.0 if gear else style.supply_hop_scale)
    icon.position=Vector2(0,-height*4.0*t*(1.0-t))
    var grow: float=lerpf(style.pop_from_scale,style.pop_overshoot,minf(1.0,t/.7)) if t<.7 else lerpf(style.pop_overshoot,1.0,(t-.7)/.3)
    icon.scale=base_scale*grow
    var wanted: int=2 if style.hop_above_actors else 0
    if z_index!=wanted:z_index=wanted

func _draw() -> void:
    var landed: bool=age>=style.hop_seconds
    if gear and landed:
        var pulse: float=.5+.5*sin(clock*style.glint_pulse_speed)
        var alpha: float=lerpf(style.glint_alpha_min,style.glint_alpha_max,pulse)
        _ellipse(style.glint_radius,Color(0,0,0,style.glint_edge_alpha*alpha),style.glint_width+1.0)
        _ellipse(style.glint_radius,Color(glint_color.lightened(style.glint_lighten),alpha),style.glint_width)
    if not landed:return
    # The sparkle: once as the drop lands (age counts from its arrival), then every spark_interval
    # seconds at this drop's own phase.
    var landing: bool=age<INF
    var since: float=age-style.hop_seconds if landing else fmod(clock,style.spark_interval)
    if since<0 or since>=style.spark_seconds:return
    var frame: int=mini(15,int(since/style.spark_seconds*16))
    var scale_: float=(style.landing_spark_scale_gear if gear else style.landing_spark_scale_supply) if landing else 1.0
    var size: Vector2=Vector2(25,27)*scale_
    draw_texture_rect_region(SPARK,Rect2(Vector2(-size.x*.5,-20*scale_),size),Rect2(frame*25,0,25,27))

func _ellipse(radius: Vector2,color: Color,width: float) -> void:
    var points:=PackedVector2Array()
    for i in range(25):
        var a:=TAU*i/24.0
        points.append(Vector2(cos(a)*radius.x,sin(a)*radius.y+3.0))
    draw_polyline(points,color,width,false)
