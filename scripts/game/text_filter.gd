class_name TextFilter
## Change 78: crisp text over pixel art. The UI root draws with nearest filtering so the pixel-art icons and
## frames stay sharp, but the theme font is MSDF, which needs linear sampling: drawn nearest, its glyph edges
## step like enlarged pixels on dense phone screens (1.5-2x the 720 px reference) and wherever text is scaled.
## Every Label and RichTextLabel therefore draws with linear filtering, and the theme's pixel-art stylebox
## textures (a label's chip frame, for example) keep nearest filtering through a CanvasTexture of their own.
## Buttons keep their parent's nearest filtering: their item icons are atlas regions, which a CanvasTexture
## cannot carry.

static var _installed:=false

## Once per run: wrap the theme's stylebox textures, smooth the text already in `root`, and every text node
## added to the tree afterwards.
static func install(root: Node,theme: Theme) -> void:
    if theme!=null:protect_pixel_styleboxes(theme)
    for node in root.find_children("*","",true,false):smooth(node)
    if _installed:return
    _installed=true
    root.get_tree().node_added.connect(smooth)

## A text-only control that inherits its filtering draws its MSDF glyphs with linear filtering instead.
static func smooth(node: Node) -> void:
    if (node is Label or node is RichTextLabel) and (node as CanvasItem).texture_filter==CanvasItem.TEXTURE_FILTER_PARENT_NODE:
        (node as CanvasItem).texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR

## Each StyleBoxTexture of the theme draws its (whole-image) texture with nearest filtering whatever its
## control's filter. Atlas regions are left as they are (a CanvasTexture cannot hold a region); no label
## draws one.
static func protect_pixel_styleboxes(theme: Theme) -> void:
    for type in theme.get_stylebox_type_list():
        for name in theme.get_stylebox_list(type):
            var box:=theme.get_stylebox(name,type) as StyleBoxTexture
            if box==null:continue
            box.texture=nearest(box.texture)

## The texture wrapped in a nearest-filtered CanvasTexture (unchanged when it already is one, or is an atlas
## region or null).
static func nearest(texture: Texture2D) -> Texture2D:
    if texture==null or texture is AtlasTexture or texture is CanvasTexture:return texture
    var wrapped:=CanvasTexture.new()
    wrapped.diffuse_texture=texture
    wrapped.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    return wrapped
