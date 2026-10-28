extends Node2D
## Supplied sheet frames; sparse weather with no simulation effects. Particles belong to the world:
## one authored pattern repeats on a fixed world grid (the style's period) and drifts with time, so
## panning or zooming the camera reveals more of the same field instead of carrying the weather along.
## Change 13: each weather's look lives in an inspector-editable WeatherStyle; rain is denser and its
## ambient tint darkens the map art toward an overcast sky (world.gd applies it to the stage only).
@export var styles: Dictionary={
    "rain":preload("res://resources/game/weather_rain.tres"),
    "blue_leaves":preload("res://resources/game/weather_blue_leaves.tres"),
    "leaves":preload("res://resources/game/weather_leaves.tres"),
}
var sim
var clock: float=0
var weather: String=""
var style: WeatherStyle
func _process(dt: float) -> void:
    if sim==null:return
    var kind: String=sim.campaign.stage().weather
    if kind!=weather:
        weather=kind
        style=styles.get(kind)
        queue_redraw() # Also clear the previous weather commands on a dry stage.
    clock+=dt
    if style!=null:queue_redraw()
## The map-art tint of the current weather (white without weather).
func ambient_tint() -> Color:
    return style.ambient_tint if style!=null else Color.WHITE
# Reused pattern buffers: trigonometry/modulo/frame work happens once per particle index, not
# once per repeated grid cell. Production drawing does not allocate an Array for every particle.
var _pattern:=PackedVector2Array()
var _frames:=PackedInt32Array()
var _regions: Array[Rect2]=[]
var _pattern_clock: float=-INF
var _pattern_style: WeatherStyle
func _prepare_pattern() -> void:
    if style==null:return
    if _pattern_style==style and _pattern_clock==clock:return
    _pattern_style=style;_pattern_clock=clock
    _pattern.resize(style.particles_per_period);_frames.resize(style.particles_per_period)
    _regions.resize(style.particles_per_period)
    var tick:=int(clock*style.fps)
    for i in range(style.particles_per_period):
        var frame: int=(tick+i)%style.frames
        var at:=clock
        if style.splash_frame>=0 and frame>=style.splash_frame:
            at=float(tick-(frame-style.splash_frame))/style.fps
        _pattern[i]=Vector2(fposmod(i*83.0+at*style.drift.x,style.period.x),fposmod(i*47.0+i*i*13.0+at*style.drift.y,style.period.y))
        _frames[i]=frame
        _regions[i]=Rect2(Vector2(frame,i%style.frame_rows)*style.frame_size,style.frame_size)

func _draw() -> void:
    if style==null or style.texture==null:return
    _prepare_pattern()
    var camera: Camera2D=get_parent().get_node("Camera")
    var half: Vector2=get_viewport_rect().size/camera.zoom*.5
    var rect:=Rect2(camera.position-half,half*2).grow(120)
    var first:=Vector2i(floori(rect.position.x/style.period.x),floori(rect.position.y/style.period.y))
    var last:=Vector2i(floori(rect.end.x/style.period.x),floori(rect.end.y/style.period.y))
    # Visibility inputs are invariant during this draw. Avoid re-deriving card/upgrade bonuses for
    # each drop in unexplored ground; exact same cell-centred predicate as campaign.can_see().
    # Change 24: one campaign.Sight per draw (the stage's byte mask indexed per drop, no string key).
    var view=sim.campaign.sight()
    var bounds:=Rect2(Vector2.ZERO,Vector2(sim.catalog.world.size[0],sim.catalog.world.size[1]))
    var area:=rect.intersection(bounds)
    for cy in range(first.y,last.y+1):
        for cx in range(first.x,last.x+1):
            var origin:=Vector2(cx,cy)*style.period
            for i in range(_pattern.size()):
                var pos:=origin+_pattern[i]
                if not area.has_point(pos) or not view.sees(pos):continue
                draw_texture_rect_region(style.texture,Rect2(pos,style.draw_size),_regions[i],style.color)

## Diagnostic API retained for existing probes. Rendering uses the buffers directly.
func particles(visible_rect: Rect2) -> Array:
    var result: Array=[]
    if style==null:return result
    _prepare_pattern()
    var period:=style.period
    var first:=Vector2i(floori(visible_rect.position.x/period.x),floori(visible_rect.position.y/period.y))
    var last:=Vector2i(floori(visible_rect.end.x/period.x),floori(visible_rect.end.y/period.y))
    for cy in range(first.y,last.y+1):
        for cx in range(first.x,last.x+1):
            var origin:=Vector2(cx,cy)*period
            for i in range(_pattern.size()):
                var pos:=origin+_pattern[i]
                if visible_rect.has_point(pos):result.append([pos,i,_frames[i]])
    return result
