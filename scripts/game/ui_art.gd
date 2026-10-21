class_name UiArt
extends RefCounted
## Owned PixelPlains item files carry wide transparent margins; UI shows them cropped to the used
## pixels so icons fill their slots. Results are cached per source texture.
static var _cache: Dictionary={}

static func cropped(source: Texture2D) -> Texture2D:
    if source==null:return null
    var key:=source.get_rid().get_id()
    if not _cache.has(key):
        var atlas:=AtlasTexture.new()
        atlas.atlas=source
        atlas.region=Rect2(source.get_image().get_used_rect())
        _cache[key]=atlas
    return _cache[key]
