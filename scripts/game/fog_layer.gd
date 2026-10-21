extends Node2D
var sim
var revision: int=-1
var stage_id: int=-1
func _process(_dt: float) -> void:
    if sim!=null and (revision!=sim.campaign.discovery_revision or stage_id!=int(sim.state.stage)):
        revision=sim.campaign.discovery_revision;stage_id=int(sim.state.stage);queue_redraw()
func _draw() -> void:
    if sim==null:return
    var cell: float=sim.campaign.fog_rules.cell_size
    var width=ceili(sim.catalog.world.size[0]/cell)
    var height=ceili(sim.catalog.world.size[1]/cell)
    var mask=sim.state.explored.get(str(sim.state.stage),{})
    for y in range(height):
        var start:=-1
        for x in range(width+1):
            var hidden: bool=x<width and not mask.has("%d,%d" % [x,y])
            if hidden and start<0:start=x
            elif not hidden and start>=0:
                draw_rect(Rect2(Vector2(start,y)*cell,Vector2(x-start,1)*cell),sim.campaign.fog_rules.cover_color)
                start=-1
