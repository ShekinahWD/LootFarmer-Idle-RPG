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
    clock+=dt
    queue_redraw()
## The map-art tint of the current weather (white without weather).
func ambient_tint() -> Color:
    return style.ambient_tint if style!=null else Color.WHITE
func _draw() -> void:
    if style==null or style.texture==null:return
    var camera: Camera2D=get_parent().get_node("Camera")
    var half: Vector2=get_viewport_rect().size/camera.zoom*.5
    for particle in particles(Rect2(camera.position-half,half*2).grow(120)):
        var pos: Vector2=particle[0];var i: int=particle[1];var frame: int=particle[2]
        if not sim.campaign.can_see(pos):continue
        draw_texture_rect_region(style.texture,Rect2(pos,style.draw_size),Rect2(Vector2(frame,i%style.frame_rows)*style.frame_size,style.frame_size),style.color)
## World positions [position, index, frame] of the particles inside a world rect at the current clock.
## Depends only on the clock and the world grid, never on the camera (the rect only culls).
## Change 14: a particle in its splash frames is drawn where it was at the impact frame (the first
## splash frame's start), so the splash never slides with the drift.
func particles(visible_rect: Rect2) -> Array:
    var result: Array=[]
    if style==null:return result
    var period: Vector2=style.period
    var drift: Vector2=style.drift
    var tick: int=int(clock*style.fps)
    var first:=Vector2i(floori(visible_rect.position.x/period.x),floori(visible_rect.position.y/period.y))
    var last:=Vector2i(floori(visible_rect.end.x/period.x),floori(visible_rect.end.y/period.y))
    for cy in range(first.y,last.y+1):
        for cx in range(first.x,last.x+1):
            var origin:=Vector2(cx,cy)*period
            for i in range(style.particles_per_period):
                var frame: int=(tick+i)%style.frames
                var at: float=clock
                if style.splash_frame>=0 and frame>=style.splash_frame:
                    at=float(tick-(frame-style.splash_frame))/style.fps
                # Same local pattern in every period cell: a particle leaving one cell is continued by
                # its twin entering from the neighbouring cell, so wrapping never pops.
                var pos:=origin+Vector2(fposmod(i*83.0+at*drift.x,period.x),fposmod(i*47.0+i*i*13.0+at*drift.y,period.y))
                if visible_rect.has_point(pos):result.append([pos,i,frame])
    return result
