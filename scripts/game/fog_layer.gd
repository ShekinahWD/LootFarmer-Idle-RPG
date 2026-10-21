extends Node2D
## Presentation of the discovery store (playbook 117.9): explored cells are clear, unexplored cells
## in the player's momentary sight get the lighter vision veil, every other cell is covered.
## Redrawn when discovery changes or the player's sight moves to another cell; never writes state.
var sim
var revision: int=-1
var stage_id: int=-1
var sight:=Vector3(-1,-1,-1)
func _process(_dt: float) -> void:
    if sim==null:return
    var cell: float=sim.campaign.fog_rules.cell_size
    var p: Vector2=sim.position_of(sim.state.player)
    var now:=Vector3(floorf(p.x/cell),floorf(p.y/cell),sim.campaign.vision_radius() if sim.state.player.hp>0 else -1.0)
    if revision!=sim.campaign.discovery_revision or stage_id!=int(sim.state.stage) or now!=sight:
        revision=sim.campaign.discovery_revision;stage_id=int(sim.state.stage);sight=now;queue_redraw()
func _draw() -> void:
    if sim==null:return
    var rules=sim.campaign.fog_rules
    var cell: float=rules.cell_size
    var width=ceili(sim.catalog.world.size[0]/cell)
    var height=ceili(sim.catalog.world.size[1]/cell)
    var mask=sim.state.explored.get(str(sim.state.stage),{})
    var player: Vector2=sim.position_of(sim.state.player)
    var radius: float=sight.z
    for y in range(height):
        var start:=-1
        var kind:=0
        for x in range(width+1):
            # 0 clear, 1 vision veil, 2 cover
            var next:=0
            if x<width and not mask.has("%d,%d" % [x,y]):
                next=1 if radius>0 and (Vector2(x,y)*cell+Vector2.ONE*cell*.5).distance_to(player)<=radius else 2
            if next!=kind:
                if kind>0:draw_rect(Rect2(Vector2(start,y)*cell,Vector2(x-start,1)*cell),rules.cover_color if kind==2 else rules.vision_color)
                start=x;kind=next
