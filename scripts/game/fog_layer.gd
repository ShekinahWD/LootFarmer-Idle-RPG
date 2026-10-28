extends Node2D
## Presentation of the discovery store (playbook 117.9): explored cells are clear, unexplored cells
## in the player's momentary sight get the lighter vision veil, every other cell is covered.
## Never writes state. Change 24: one texture draw with the fog_veil shader instead of one rectangle
## per run of cells. The explored mask is uploaded as a texture (one texel per cell) only when
## discovery or the stage changes; moving sight only updates two shader parameters. Same colours
## (fog_rules), same cell edges and the same cell-centred sight test as before.
const VEIL=preload("res://resources/game/fog_veil.gdshader")
var sim
var revision: int=-1
var stage_id: int=-1
var sight:=Vector3(-1,-1,-1)
var _texture: ImageTexture
var _cells:=Vector2i.ZERO
var _veil: ShaderMaterial
func _ready() -> void:
    _veil=ShaderMaterial.new()
    _veil.shader=VEIL
    material=_veil
    texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func _process(_dt: float) -> void:
    if sim==null:return
    var cell: float=sim.campaign.fog_rules.cell_size
    var p: Vector2=sim.position_of(sim.state.player)
    var now:=Vector3(floorf(p.x/cell),floorf(p.y/cell),sim.campaign.vision_radius() if sim.state.player.hp>0 else -1.0)
    if revision!=sim.campaign.discovery_revision or stage_id!=int(sim.state.stage):
        revision=sim.campaign.discovery_revision;stage_id=int(sim.state.stage)
        _upload_mask()
    if now!=sight:
        sight=now
        _veil.set_shader_parameter("player",p)
        _veil.set_shader_parameter("radius",now.z)
## The current stage's explored mask as an L8 image; the texture is recreated (and the single draw
## re-recorded) only when the grid size changes.
func _upload_mask() -> void:
    var rules=sim.campaign.fog_rules
    var st:=int(sim.state.stage)
    var cells:=Vector2i(sim.campaign.fog_columns(st),sim.campaign.fog_rows(st))
    var image:=Image.create_from_data(cells.x,cells.y,false,Image.FORMAT_L8,sim.campaign.explored_mask(st))
    if _texture==null or cells!=_cells:
        _texture=ImageTexture.create_from_image(image)
        _cells=cells
        _veil.set_shader_parameter("explored",_texture)
        _veil.set_shader_parameter("cells",Vector2(cells))
        _veil.set_shader_parameter("cell_size",float(rules.cell_size))
        _veil.set_shader_parameter("cover_color",rules.cover_color)
        _veil.set_shader_parameter("vision_color",rules.vision_color)
        queue_redraw()
    else:
        _texture.update(image)
    # The player position also follows the stage (arrival at a camp on another map).
    sight=Vector3(-1,-1,-2)
func _draw() -> void:
    if _texture==null:return
    draw_texture_rect(_texture,Rect2(Vector2.ZERO,Vector2(_cells)*sim.campaign.fog_rules.cell_size),false)
