extends Node2D
## Supplied sheet frames; sparse weather with no simulation effects. Particles belong to the world:
## one authored pattern repeats on a fixed world grid (PERIOD) and drifts with time, so panning or
## zooming the camera reveals more of the same field instead of carrying the weather along.
@export var period:=Vector2(440,500)
@export var particles_per_period:=12
@export var drift:=Vector2(8,28)
var sim
var clock: float=0
var weather: String=""
var texture: Texture2D
func _process(dt: float) -> void:
    if sim==null:return
    var kind: String=sim.campaign.stage().weather
    if kind!=weather:
        weather=kind
        texture=null
        if kind=="rain":texture=load("res://assets/PixelPlains/Rain full anim sheet 52x216.png")
        elif kind=="blue_leaves":texture=load("res://assets/PixelPlains/Winter/Falling leaves.png")
        elif kind=="leaves":texture=load("res://assets/PixelPlains/Fall/Falling leaves.png")
    clock+=dt
    queue_redraw()
func _draw() -> void:
    if texture==null:return
    var camera: Camera2D=get_parent().get_node("Camera")
    var half: Vector2=get_viewport_rect().size/camera.zoom*.5
    for particle in particles(Rect2(camera.position-half,half*2).grow(120)):
        var pos: Vector2=particle[0];var i: int=particle[1]
        if not sim.campaign.cell_known(pos):continue
        if weather=="rain":draw_texture_rect_region(texture,Rect2(pos,Vector2(26,108)),Rect2((int(clock*10)+i)%15*52,0,52,216),Color(1,1,1,.4))
        else:draw_texture_rect_region(texture,Rect2(pos,Vector2(16,16)),Rect2((int(clock*8)+i)%8*16,(i%6)*16,16,16),Color(1,1,1,.65))
## World positions [position, index] of the particles inside a world rect at the current clock.
## Depends only on the clock and the world grid, never on the camera (the rect only culls).
func particles(visible_rect: Rect2) -> Array:
    var result: Array=[]
    var first:=Vector2i(floori(visible_rect.position.x/period.x),floori(visible_rect.position.y/period.y))
    var last:=Vector2i(floori(visible_rect.end.x/period.x),floori(visible_rect.end.y/period.y))
    for cy in range(first.y,last.y+1):
        for cx in range(first.x,last.x+1):
            var origin:=Vector2(cx,cy)*period
            for i in range(particles_per_period):
                # Same local pattern in every period cell: a particle leaving one cell is continued by
                # its twin entering from the neighbouring cell, so wrapping never pops.
                var pos:=origin+Vector2(fposmod(i*83.0+clock*drift.x,period.x),fposmod(i*47.0+i*i*13.0+clock*drift.y,period.y))
                if visible_rect.has_point(pos):result.append([pos,i])
    return result
