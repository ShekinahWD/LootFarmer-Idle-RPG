class_name OutfitSlotStyles
extends Resource
## Change 10: how an outfit's inventory slot looks at each ^100 merge milestone. The outfit keeps its
## id, art, tier and stack; only the slot changes: an ornamental frame over the tier-coloured
## background, a small lift of that background (the tier hue stays recognisable) and the colour of
## the "qty · ^merge" line. One entry per milestone in the parallel arrays, ascending merge order;
## ^0-^99 keeps the plain slot. Edited in the inspector (resources/game/outfit_slot_styles.tres).
@export var merges: PackedInt32Array=PackedInt32Array([100,200,300,400,500])
## Owned Kenney Fantasy UI border art (white line art, transparent centre), tinted by frame_colors.
@export var frames: Array[Texture2D]=[]
@export var frame_colors: PackedColorArray=PackedColorArray()
## Share (0-1) the tier-coloured background is lightened at each milestone.
@export var background_lift: PackedFloat32Array=PackedFloat32Array()
## Nine-patch margin of the border art and how far the frame sits inside the slot edge.
@export var patch_margin: int=12
@export var frame_inset: float=1.0

## 0 below the first milestone, then 1..merges.size().
func rank(merge_level: int) -> int:
    var result:=0
    for i in range(merges.size()):
        if merge_level>=merges[i]:result=i+1
    return result

func frame_color(rank_index: int) -> Color:
    return frame_colors[clampi(rank_index-1,0,frame_colors.size()-1)] if rank_index>0 and not frame_colors.is_empty() else Color.WHITE

func lift(rank_index: int) -> float:
    return background_lift[clampi(rank_index-1,0,background_lift.size()-1)] if rank_index>0 and not background_lift.is_empty() else 0.0

## Configures a full-rect NinePatchRect overlay for this rank (hidden at rank 0).
func apply(frame: NinePatchRect,rank_index: int) -> void:
    var show: bool=rank_index>0 and rank_index<=frames.size()
    if frame.visible!=show:frame.visible=show
    if not show:return
    var texture: Texture2D=frames[rank_index-1]
    if frame.texture!=texture:frame.texture=texture
    var color:=frame_color(rank_index)
    if frame.modulate!=color:frame.modulate=color
    frame.patch_margin_left=patch_margin;frame.patch_margin_right=patch_margin
    frame.patch_margin_top=patch_margin;frame.patch_margin_bottom=patch_margin
    frame.draw_center=false
    frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
    frame.set_anchors_preset(Control.PRESET_FULL_RECT)
    frame.offset_left=frame_inset;frame.offset_top=frame_inset
    frame.offset_right=-frame_inset;frame.offset_bottom=-frame_inset
