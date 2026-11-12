extends RefCounted
## Change 65: the one tutorial-card registry (Playbook 18.1-18.2: one data source, one renderer). The
## Basic opening shows the first ESSENTIAL_COUNT cards; Settings → Help & Tutorials shows all of them.
## Both read the same ids, texts (HELP_CARD_<ID>_TITLE / _ACTION / _SUPPORT) and animation
## (help_demo.gd, drawn by help_viewer.gd). Nothing here touches gameplay: a card explains a system, it
## never unlocks, reveals or grants anything.
##
## Reading progress lives in the profile under tutorial.help (kept by Prestige with the rest of the
## tutorial record, cleared by Hard Reset): viewed card ids, the last Help card, the Help Auto-Advance
## preference, whether the Basic opening finished and the Basic card it was last on. Ids, never indices, so adding cards later keeps
## saved progress valid.

## Order is the Read All order. category: exactly one of CATEGORIES. loop: the demo's loop in seconds.
const CARDS:=[
    {"id":"movement_combat","category":"combat","loop":6.0},
    {"id":"manual_target","category":"combat","loop":6.5},
    {"id":"collect_equip","category":"equipment","loop":7.0},
    {"id":"merge_gear","category":"equipment","loop":6.0},
    {"id":"player_upgrades","category":"farming","loop":7.0},
    {"id":"enemy_automation","category":"farming","loop":7.5},
    {"id":"missions","category":"progression","loop":7.0},
    {"id":"explore_camps","category":"progression","loop":8.0},
    {"id":"skills_supplies","category":"combat","loop":7.0},
    {"id":"offline_rewards","category":"progression","loop":8.0},
    {"id":"weapon_evolution","category":"equipment","loop":7.0},
    {"id":"prestige","category":"permanent","loop":8.0},
    {"id":"map_details_mastery","category":"permanent","loop":8.0},
    {"id":"advanced_farming","category":"farming","loop":8.0},
]
const ESSENTIAL_COUNT:=8
const CATEGORIES:=["combat","equipment","farming","progression","permanent"]
## Change 25-61 Basic overview ids. A Basic profile that had seen all of them (or The Road Ahead) has
## finished its opening and never replays the new deck.
const LEGACY_BASIC_DECK:=["overview","basic_target","basic_gear","basic_growth","basic_world","basic_prestige"]
## Auto-Advance waits at least one demo loop and this reading time (seconds per word of the two lines,
## plus a base), whichever is longer.
const READ_BASE_SECONDS:=2.5
const READ_SECONDS_PER_WORD:=0.32
const READ_MIN_SECONDS:=6.0

static func ids() -> Array:
    return CARDS.map(func(c):return str(c.id))

static func essential() -> Array:
    return ids().slice(0,ESSENTIAL_COUNT)

static func has(id: String) -> bool:
    return ids().has(id)

static func card(id: String) -> Dictionary:
    for c in CARDS:
        if str(c.id)==id:return c
    return {}

static func category_of(id: String) -> String:
    return str(card(id).get("category",""))

static func in_category(category: String) -> Array:
    return CARDS.filter(func(c):return str(c.category)==category).map(func(c):return str(c.id))

static func loop_seconds(id: String) -> float:
    return float(card(id).get("loop",6.0))

static func title_key(id: String) -> String:return "HELP_CARD_%s_TITLE" % id.to_upper()
## Change 69: a card whose English meaning changed reads a new key (the translated old key is left in the
## catalogs until it is retired), so no language shows a now-false rule.
const TEXT_OVERRIDES:={"advanced_farming":{"action":"HELP_CARD_ADVANCED_FARMING_ACTION_V69","support":"HELP_CARD_ADVANCED_FARMING_SUPPORT_V69"}}
static func action_key(id: String) -> String:return str(TEXT_OVERRIDES.get(id,{}).get("action","HELP_CARD_%s_ACTION" % id.to_upper()))
static func support_key(id: String) -> String:return str(TEXT_OVERRIDES.get(id,{}).get("support","HELP_CARD_%s_SUPPORT" % id.to_upper()))
static func category_key(category: String) -> String:return "HELP_CAT_%s" % category.to_upper()

## Seconds Auto-Advance waits on a card: one full loop and a comfortable reading time.
static func dwell_seconds(id: String,action_text: String,support_text: String) -> float:
    var words:=(action_text+" "+support_text).split(" ",false).size()
    return maxf(maxf(loop_seconds(id),READ_MIN_SECONDS),READ_BASE_SECONDS+READ_SECONDS_PER_WORD*words)

# ---------------------------------------------------------------- reading progress (tutorial.help)

static func initial() -> Dictionary:
    return {"viewed":[],"last":"","auto":false,"basic_done":false,"basic_last":""}

static func progress(tutorial: Dictionary) -> Dictionary:
    if not tutorial.get("help") is Dictionary:tutorial["help"]=initial()
    return tutorial.help

static func viewed(tutorial: Dictionary,id: String) -> bool:
    return progress(tutorial).viewed.has(id)

static func viewed_count(tutorial: Dictionary,list: Array=[]) -> int:
    var source: Array=ids() if list.is_empty() else list
    return source.filter(func(i):return viewed(tutorial,str(i))).size()

## True when it changed the record.
static func mark_viewed(tutorial: Dictionary,id: String) -> bool:
    if not has(id):return false
    var p:=progress(tutorial)
    if p.viewed.has(id):return false
    p.viewed.append(id)
    return true

static func set_last(tutorial: Dictionary,id: String) -> bool:
    if not has(id):return false
    var p:=progress(tutorial)
    if str(p.last)==id:return false
    p.last=id
    return true

static func basic_done(tutorial: Dictionary) -> bool:
    return bool(progress(tutorial).basic_done)

## Load normalization (campaign.normalize_snapshot): unknown ids and malformed fields are dropped; a Basic
## profile past the old overview deck (or The Road Ahead) has its opening finished.
static func normalize(out: Dictionary) -> void:
    if not out.get("tutorial") is Dictionary:return
    var t: Dictionary=out.tutorial
    var raw=t.get("help")
    var p:=initial()
    if raw is Dictionary:
        if raw.get("viewed") is Array:
            for id in raw.viewed:
                if id is String and has(id) and not p.viewed.has(id):p.viewed.append(id)
        if raw.get("last") is String and has(raw.last):p.last=raw.last
        p.auto=raw.get("auto") is bool and raw.auto
        p.basic_done=raw.get("basic_done") is bool and raw.basic_done
        if raw.get("basic_last") is String and essential().has(raw.basic_last):p.basic_last=raw.basic_last
    var seen: Array=t.seen if t.get("seen") is Array else []
    if not p.basic_done and str(t.get("mode",""))=="basic":
        if seen.has("road_ahead") or LEGACY_BASIC_DECK.all(func(i):return seen.has(i)):p.basic_done=true
    t["help"]=p
