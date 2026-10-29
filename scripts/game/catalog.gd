class_name LootCatalog
extends RefCounted
## Authored definitions are data, shared by simulation, UI and probes.
const DATA_PATH = "res://data/game/catalog.json"
var items: Dictionary
var groups: Array
var upgrades: Dictionary
var cards: Array
var world: Dictionary
var stages: Array
var skills: Dictionary
var campaign: Dictionary
var progression: Dictionary
## Removed item id -> replacement (Change 7 shared weapons); applied when a save loads.
var legacy_items: Dictionary
var _icons: Dictionary = {}

func _init() -> void:
    var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
    items = data.items
    groups = data.groups
    upgrades = data.upgrades
    cards = data.cards
    world = data.world
    progression = data.progression
    stages = data.stages
    skills = data.skills
    campaign = data.campaign
    legacy_items = data.get("legacy_items",{})
    relocalize()
    # JSON numbers are floats and Array.has() is type-strict: stage group ids must be ints, or
    # stage().groups.has(group) fails for every int group (it silently disabled Focus before Change 8).
    for entry in stages:
        var ids: Array=[]
        for g in entry.groups:ids.append(int(g))
        entry.groups=ids

## Display names and descriptions are translated from the authored keys, which stay in name_key and
## description_key; the UI calls this again when the language changes (Localization Batch 01).
func relocalize() -> void:
    for entry in groups+stages+skills.values()+campaign.cards.values()+campaign.opportunities+campaign.combos:
        for field in ["name","description"]:
            if entry.has(field):
                if not entry.has(field+"_key"):entry[field+"_key"]=entry[field]
                entry[field]=tr(entry[field+"_key"])

func name_of(id: String) -> String:
    return "ITEM_" + id.to_upper()

func icon(id: String) -> Texture2D:
    if not items.has(id):
        return null
    var art:=art_id(id)
    if _icons.has(art):
        return _icons[art]
    var entry: Dictionary = items[art]
    var source: Texture2D
    var region: Rect2
    if entry.has("icon_path"):
        source = load(entry.icon_path)
        region = Rect2(Vector2.ZERO, source.get_size())
    else:
        source = load(entry.texture)
        var r: Array = entry.icon
        region = Rect2(r[0], r[1], r[2], r[3])
    var bounds := source.get_image().get_region(Rect2i(region)).get_used_rect()
    var atlas := AtlasTexture.new()
    atlas.atlas = source
    atlas.region = Rect2(region.position + Vector2(bounds.position), Vector2(bounds.size))
    _icons[art] = atlas
    return atlas

func art_id(id: String) -> String:
    return str(items.get(id,{}).get("art_id",id))

func display_name(id: String) -> String:
    var title: String=tr(items[art_id(id)].get("name",name_of(art_id(id))))
    if id!=art_id(id):
        return tr("ITEM_TIER_NAME") % [title,int(items[id].tier)]
    return title
