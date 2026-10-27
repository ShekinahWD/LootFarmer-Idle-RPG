extends Node
var style: WeatherStyle
var clock: float=0
var checks:=0
var failures:=0
func _ready() -> void:call_deferred("run")
func check(ok: bool) -> void:
    checks+=1
    if not ok:failures+=1;push_error("Weather output differs from supplied implementation")
func run() -> void:
    var weather=load("res://scripts/game/season_weather.gd").new()
    var rect:=Rect2(-400,-500,3000,2200)
    for kind in ["rain","leaves","blue_leaves"]:
        style=load("res://resources/game/weather_"+kind+".tres");weather.style=style
        for t in [0.0,.099,.1,.899,.9,1.0,1.499,1.5,17.35,333.789]:
            clock=t;weather.clock=t
            check(original_particles(rect)==weather.particles(rect))
            check(original_particles(Rect2(800,700,900,600))==weather.particles(Rect2(800,700,900,600)))
    style=load("res://resources/game/weather_rain.tres");weather.style=style
    var before:=Time.get_ticks_usec()
    for i in range(300):clock=i*.016;original_particles(rect)
    var old_usec:=Time.get_ticks_usec()-before
    before=Time.get_ticks_usec()
    for i in range(300):weather.clock=i*.016;weather.particles(rect)
    var new_usec:=Time.get_ticks_usec()-before
    print("WEATHER_CPU original_us=",old_usec," optimized_us=",new_usec," ratio=",float(new_usec)/old_usec)
    print("CHANGE_17_WEATHER_CHECKS ",checks," FAILURES ",failures)
    weather.free();get_tree().quit(1 if failures else 0)
func original_particles(visible_rect: Rect2) -> Array:
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
