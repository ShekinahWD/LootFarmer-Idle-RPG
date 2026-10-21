extends Node2D
const SPARK=preload("res://assets/PixelPlains/Sparks 25x27.png")
var clock: float=0
func _process(dt: float) -> void:
    if not visible:return
    clock+=dt
    queue_redraw()
func _draw() -> void:
    if fmod(clock,4.0)>1.2:return
    var frame=mini(15,int(fmod(clock,4.0)/1.2*16))
    draw_texture_rect_region(SPARK,Rect2(-12,-20,25,27),Rect2(frame*25,0,25,27))
