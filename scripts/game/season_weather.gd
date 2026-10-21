extends Node2D
## Supplied sheet frames; sparse, camera-local weather with no simulation effects.
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
    var center=get_parent().get_node("Camera").position
    for i in range(12):
        var pos=center+Vector2(fmod(i*83.0+clock*8,440)-220,fmod(i*47.0+clock*28,500)-250)
        if not sim.campaign.cell_known(pos):continue
        if weather=="rain":draw_texture_rect_region(texture,Rect2(pos,Vector2(26,108)),Rect2((int(clock*10)+i)%15*52,0,52,216),Color(1,1,1,.4))
        else:draw_texture_rect_region(texture,Rect2(pos,Vector2(16,16)),Rect2((int(clock*8)+i)%8*16,(i%6)*16,16,16),Color(1,1,1,.65))
