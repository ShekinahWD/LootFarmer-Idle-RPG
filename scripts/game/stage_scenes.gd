extends RefCounted
## Change 24 (Playbook 44): one small cache of the baked stage scenes, shared by the world view and
## the campaign's obstacle reader, so a stage file is parsed once instead of once per reader on every
## visit. Likely destinations are parsed on a background thread before travel
## (ResourceLoader.load_threaded_request); taking a scene that is still loading waits for that load
## only. At most CAPACITY PackedScenes stay referenced (least recently used goes first); the
## instantiated stage in the world does not need its PackedScene to stay alive.
## Used through preload (no class_name), so it works in fresh checkouts before an editor scan.
const CAPACITY:=4
static var _scenes: Dictionary={}
static var _order: Array=[]
static var _pending: Dictionary={}

static func path(id: int) -> String:
    return "res://scenes/game/stages/stage_%d.tscn" % id

## Start parsing a stage scene in the background (no effect if cached, loading or unknown).
static func request(id: int) -> void:
    if _scenes.has(id) or _pending.has(id) or not ResourceLoader.exists(path(id)):return
    if ResourceLoader.load_threaded_request(path(id),"PackedScene")==OK:_pending[id]=true

## Move finished background loads into the cache (called once per frame by the world view).
static func poll() -> void:
    for id in _pending.keys():
        if ResourceLoader.load_threaded_get_status(path(id))!=ResourceLoader.THREAD_LOAD_IN_PROGRESS:_take(id)

static func scene(id: int) -> PackedScene:
    if _pending.has(id):_take(id)
    if not _scenes.has(id):
        var packed: PackedScene=load(path(id)) if ResourceLoader.exists(path(id)) else null
        if packed==null:return null
        _scenes[id]=packed
    _use(id)
    return _scenes[id]

static func cached(id: int) -> bool:
    return _scenes.has(id)

static func _take(id: int) -> void:
    _pending.erase(id)
    var packed=ResourceLoader.load_threaded_get(path(id))
    if packed is PackedScene:
        _scenes[id]=packed
        _use(id)

static func _use(id: int) -> void:
    _order.erase(id)
    _order.append(id)
    while _order.size()>CAPACITY:_scenes.erase(_order.pop_front())
