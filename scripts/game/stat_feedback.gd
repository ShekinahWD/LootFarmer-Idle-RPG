extends Control
## Change 60: floating feedback when the player's effective stats change ("↑ +15 Maximum health",
## "↓ −5 Damage"). The source of truth is sim.stats() itself (stored weapons 30%, stored outfits 15%,
## cards, caps and supply buffs included), compared only when sim.revision moves, so nothing here
## rebuilds a breakdown per frame. Current HP is not a stat (combat damage and healing never appear).
##
## Each changed stat gets its own popup; starts are SPACING seconds apart in ORDER. A stat that changes
## again before its popup starts is coalesced into one net delta, measured against what was last shown,
## so the backlog holds at most one entry per stat and never shows a gain the totals did not make.
## While `blocked` (pause, a modal, an open sheet, a held world) nothing starts and live popups freeze.
## A replaced profile (new, loaded, Prestige: sim.profile_epoch) takes a fresh baseline and clears all.
## Session-only: nothing is saved. Lives in the Map control, above the world, and ignores input.
## Each popup also plays the matching green/red buff burst on the character (world.buff_burst).

const ORDER:=["hp","damage","defense","crit","crit_damage","lifesteal","regen","regen_pct","speed"]
## Percentage stats are fractions internally (0.005 = 0.5 points).
const PERCENT:=["crit","lifesteal","speed","regen_pct"]
const SPACING:=1.0
const LIFE:=1.9
const RISE:=72.0
const FADE_IN:=.12
const FADE_OUT:=.6
const POP:=.2
const POOL:=3
const FONT_SIZE:=30
## World units above the player's feet where a popup starts (just over the head and the hit numbers).
const HEAD:=Vector2(0,-30)
const GAIN:=Color(.45,1,.5)
const LOSS:=Color(1,.42,.38)

var ui: Node
var sim: Node
var shown: Dictionary={}
var latest: Dictionary={}
var queue: Array=[]
var revision:=-1
var epoch:=-1
var wait:=0.0
## [{label, age}] in start order.
var live: Array=[]
var pool: Array=[]

func setup(owner_ui: Node) -> void:
    ui=owner_ui
    sim=ui.sim
    set_anchors_preset(Control.PRESET_FULL_RECT)
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    # Above the map's chips and buttons (it never takes input), below the sheet (10) and banners (15).
    z_index=5
    for i in range(POOL):
        var label:=Label.new()
        label.mouse_filter=Control.MOUSE_FILTER_IGNORE
        label.add_theme_font_size_override("font_size",FONT_SIZE)
        label.add_theme_constant_override("outline_size",9)
        label.add_theme_color_override("font_outline_color",Color(.06,.07,.1,.92))
        label.visible=false
        add_child(label)
        pool.append(label)

## Called every frame by game_ui (which keeps running while the tree is paused).
func update(dt: float,blocked: bool) -> void:
    if sim==null:return
    if epoch!=sim.profile_epoch:
        _rebaseline()
    elif revision!=sim.revision:
        revision=sim.revision
        _measure()
    if blocked:return
    wait=maxf(0.0,wait-dt)
    if wait<=0.0 and not queue.is_empty():_start_next()
    if live.is_empty():return
    var anchor:=_anchor()
    for entry in live.duplicate():
        entry.age+=dt
        if entry.age>=LIFE:
            _release(entry)
            continue
        _place(entry,anchor)

## Pending stats and their net deltas in display order (for checks).
func pending() -> Array:
    var result: Array=[]
    for key in queue:result.append([key,float(latest[key])-float(shown[key])])
    return result

func clear() -> void:
    queue.clear()
    wait=0.0
    for entry in live.duplicate():_release(entry)
    if ui!=null and ui.world.has_method("stop_buff_bursts"):ui.world.stop_buff_bursts()

func _rebaseline() -> void:
    epoch=sim.profile_epoch
    revision=sim.revision
    clear()
    shown=_copy(sim.stats())
    latest=shown.duplicate()

func _measure() -> void:
    latest=_copy(sim.stats())
    var added:=false
    for key in ORDER:
        if not queue.has(key) and _meaningful(key,float(latest[key])-float(shown[key])):
            queue.append(key);added=true
    if added:queue.sort_custom(func(a,b):return ORDER.find(a)<ORDER.find(b))

func _start_next() -> void:
    while not queue.is_empty():
        var key: String=queue.pop_front()
        var delta:=float(latest[key])-float(shown[key])
        # The net change may have cancelled out (or drifted under the threshold) while it waited.
        if not _meaningful(key,delta):continue
        shown[key]=latest[key]
        _show(key,delta)
        wait=SPACING
        return

func _show(key: String,delta: float) -> void:
    if pool.is_empty():_release(live[0])
    var label: Label=pool.pop_back()
    label.text=text(key,delta)
    label.add_theme_color_override("font_color",GAIN if delta>0 else LOSS)
    label.reset_size()
    label.pivot_offset=label.size*.5
    # A long localized name never runs past the map edges: shrink the popup to fit.
    var fit:=minf(1.0,(size.x-16.0)/maxf(1.0,label.size.x))
    var entry:={"label":label,"age":0.0,"fit":fit}
    live.append(entry)
    _place(entry,_anchor())
    label.visible=true
    # The Cartoon Coffee buff burst (buff_burst.gd) on the character, in the popup's colour.
    ui.world.buff_burst(delta>0)

## "↑ +15 Maximum health", "↓ −5.43 Damage", "↑ +0.5% Critical chance": the existing localized stat
## names; percentage stats in percentage points; whole numbers bare, otherwise up to two decimals.
func text(key: String,delta: float) -> String:
    var amount: String=ui.fmt_value(absf(delta)*100.0)+"%" if key in PERCENT else ui.fmt_value(absf(delta))
    return ("↑ +" if delta>0 else "↓ −")+amount+" "+tr("STAT_"+key.to_upper())

func _place(entry: Dictionary,anchor: Vector2) -> void:
    var label: Label=entry.label
    var t:=clampf(entry.age/LIFE,0.0,1.0)
    var rise:=RISE*(1.0-pow(1.0-t,2.0))
    # Brief emphasis on arrival, then a steady rise and a fade.
    var pop:=1.0+.25*maxf(0.0,1.0-entry.age/POP)
    label.scale=Vector2.ONE*pop*float(entry.fit)
    var alpha:=minf(1.0,entry.age/FADE_IN)*clampf((LIFE-entry.age)/FADE_OUT,0.0,1.0)
    label.modulate.a=alpha
    # Scaling is about the centre, so the visible box is inset by `slack` on each side.
    var slack:=label.size.x*(1.0-float(entry.fit))*.5
    var pos:=anchor+Vector2(-label.size.x*.5,-label.size.y-rise)
    var left:=8.0-slack
    pos.x=clampf(pos.x,left,maxf(left,size.x-8.0-label.size.x+slack))
    pos.y=clampf(pos.y,8.0,maxf(8.0,size.y-label.size.y-8.0))
    label.position=pos

## The player's head in this control's coordinates. The world renders in a SubViewport whose container
## can be taller than the Map (it runs on under the HUD), so convert through the container itself.
func _anchor() -> Vector2:
    var world: Node2D=ui.world
    var container: Control=world.get_viewport().get_parent()
    var screen: Vector2=world.get_canvas_transform()*(sim.position_of(sim.state.player)+HEAD)
    screen*=container.size/Vector2(world.get_viewport_rect().size)
    return get_global_transform().affine_inverse()*(container.get_global_transform()*screen)

func _release(entry: Dictionary) -> void:
    live.erase(entry)
    var label: Label=entry.label
    label.visible=false
    pool.append(label)

func _copy(stats: Dictionary) -> Dictionary:
    var result: Dictionary={}
    for key in ORDER:result[key]=float(stats.get(key,0.0))
    return result

## Ignores floating-point noise and anything that would print as zero.
func _meaningful(key: String,delta: float) -> bool:
    return absf(delta)>=(.0001 if key in PERCENT else .005)
