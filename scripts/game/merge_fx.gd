extends Control
## Change 67: merge feedback (presentation only; the simulation has already merged when any of this plays).
##
## Manual merge on the item card: the two copies converge on the item's icon, then a flash adapted from the
## Cartoon Coffee "Star_Flash_V1" prefab (additive glow, expanding Circle_Outline_002 ring, Star_003 four-point
## flash) plus a few Star_004 sparks from "Star_Bursts_Center_V3", an icon punch and the new merge level
## rising from the card. About a second, never blocks input, restarts cleanly on a quick second tap.
##
## Merge All (inventory panel): one flash on its button and a short staggered glint on the merged dock
## slots (at most GLINT_POOL at a time). Auto-Merge: a single small glint on that item's dock slot, silent,
## skipped while the slot is hidden or already glinting. Auto Evolution: a stronger gold glint on the new
## weapon's slot. Every glint comes from one fixed pool, so a burst of automatic merges at high game speed
## costs nothing extra.
##
## Real time: Tweens ignore Engine.time_scale and particles counter it, so the feedback reads the same at
## every game speed (Playbook 125.6).

const GLOW:=preload("res://assets/vfx/buff/Glow_001.png")
const RING:=preload("res://assets/vfx/celebration/Circle_Outline_002.png")
const FLASH_STAR:=preload("res://assets/vfx/celebration/Star_003.png")
const SPARK:=preload("res://assets/vfx/celebration/Star_004.png")
const GLINT_POOL:=8
## Copies start this far above and either side of the icon (base canvas px; kept on screen) and
## converge in CONVERGE seconds.
const COPY_OFFSET:=Vector2(64,-46)
const CONVERGE:=.24
const ICON_SIZE:=72.0

var add_material:=CanvasItemMaterial.new()
var tweens: Array[Tween]=[]
var ghosts: Array[TextureRect]=[]
var ghost_glows: Array[Sprite2D]=[]
var icon_double: TextureRect
var glow: Sprite2D
var ring: Sprite2D
var star: Sprite2D
var sparks: CPUParticles2D
var level_label: Label
var glints: Array[Node2D]=[]
var glint_busy: Dictionary={}
var glint_tweens: Dictionary={}

func _init() -> void:
    name="MergeFx"
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_material.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD

func _ready() -> void:
    for i in range(2):
        var g:=_sprite(GLOW);g.visible=false;ghost_glows.append(g)
        var t:=TextureRect.new()
        t.mouse_filter=Control.MOUSE_FILTER_IGNORE
        t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
        t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        t.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
        t.size=Vector2(ICON_SIZE,ICON_SIZE)
        t.pivot_offset=t.size*.5
        t.visible=false
        add_child(t);ghosts.append(t)
    glow=_sprite(GLOW)
    ring=_sprite(RING)
    star=_sprite(FLASH_STAR)
    sparks=CPUParticles2D.new()
    sparks.texture=SPARK
    sparks.material=add_material
    sparks.emitting=false
    sparks.one_shot=true
    sparks.explosiveness=1.0
    sparks.amount=10
    sparks.lifetime=.5
    sparks.lifetime_randomness=.3
    sparks.spread=180.0
    sparks.gravity=Vector2.ZERO
    sparks.initial_velocity_min=120;sparks.initial_velocity_max=210
    sparks.damping_min=260;sparks.damping_max=320
    sparks.angular_velocity_min=-240;sparks.angular_velocity_max=240
    sparks.scale_amount_min=.16;sparks.scale_amount_max=.26
    sparks.scale_amount_curve=_curve([[0,1],[.6,.8],[1,0]])
    sparks.color_ramp=_fade_ramp()
    add_child(sparks)
    icon_double=TextureRect.new()
    icon_double.mouse_filter=Control.MOUSE_FILTER_IGNORE
    icon_double.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    icon_double.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon_double.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    icon_double.size=Vector2(ICON_SIZE,ICON_SIZE)
    icon_double.pivot_offset=icon_double.size*.5
    icon_double.visible=false
    add_child(icon_double)
    level_label=Label.new()
    level_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
    level_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    level_label.add_theme_font_size_override("font_size",30)
    level_label.add_theme_color_override("font_color",Color(.62,1,.58))
    level_label.add_theme_color_override("font_outline_color",Color(.05,.09,.06))
    level_label.add_theme_constant_override("outline_size",8)
    level_label.visible=false
    add_child(level_label)
    for i in range(GLINT_POOL):
        var holder:=Node2D.new()
        holder.visible=false
        var g:=Sprite2D.new();g.texture=GLOW;g.material=add_material;g.name="Glow";holder.add_child(g)
        var r:=Sprite2D.new();r.texture=RING;r.material=add_material;r.name="Ring";holder.add_child(r)
        var s:=Sprite2D.new();s.texture=FLASH_STAR;s.material=add_material;s.name="Star";holder.add_child(s)
        add_child(holder);glints.append(holder)

func _process(_delta: float) -> void:
    # Particles run on game time; counter the game speed so the burst lasts the same on screen.
    sparks.speed_scale=1.0/maxf(Engine.time_scale,.01)

func _sprite(texture: Texture2D) -> Sprite2D:
    var s:=Sprite2D.new()
    s.texture=texture
    s.material=add_material
    s.visible=false
    add_child(s)
    return s

func _curve(points: Array) -> Curve:
    var c:=Curve.new()
    for p in points:c.add_point(Vector2(p[0],p[1]))
    return c

func _fade_ramp() -> Gradient:
    var g:=Gradient.new()
    g.offsets=PackedFloat32Array([0.0,.7,1.0])
    g.colors=PackedColorArray([Color.WHITE,Color(1,1,1,.8),Color(1,1,1,0)])
    return g

func _tween() -> Tween:
    var t:=create_tween().set_ignore_time_scale(true)
    tweens.append(t)
    return t

func _local(point: Vector2) -> Vector2:
    return get_global_transform().affine_inverse()*point

## Ends any running item/button burst at once and hides its nodes (pool glints are separate).
func stop() -> void:
    for t in tweens:
        if t.is_valid():t.kill()
    tweens.clear()
    for n in ghosts+ghost_glows+[glow,ring,star,icon_double,level_label]:n.visible=false
    sparks.emitting=false

func busy() -> bool:
    return glow.visible or icon_double.visible or level_label.visible or ghosts.any(func(g):return g.visible)

## Manual merge of one item: icon_rect is the item card's icon frame (global), tint its tier colour,
## before/after the merge level read from the simulation around the transaction.
func play_item(icon_rect: Rect2,icon: Texture2D,tint: Color,before: int,after: int) -> void:
    stop()
    var c:=_local(icon_rect.get_center())
    var light:=tint.lightened(.45)
    for i in range(2):
        var side:=-1.0 if i==0 else 1.0
        var g:=ghosts[i]
        g.texture=icon
        var start:=c+Vector2(COPY_OFFSET.x*side,COPY_OFFSET.y)
        start.x=clampf(start.x,g.size.x*.5+4,size.x-g.size.x*.5-4)
        g.position=start-g.size*.5
        g.scale=Vector2.ONE*.7
        g.rotation=deg_to_rad(14.0*side)
        g.modulate=Color(1,1,1,0)
        g.visible=true
        var gg:=ghost_glows[i]
        gg.position=g.position+g.size*.5
        gg.scale=Vector2.ONE*(86.0/GLOW.get_width())
        gg.modulate=Color(light,0)
        gg.visible=true
        var t:=_tween().set_parallel(true)
        t.tween_property(g,"modulate:a",.95,.07)
        t.tween_property(gg,"modulate:a",.7,.07)
        t.tween_property(g,"position",c-g.size*.5,CONVERGE).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
        t.tween_property(gg,"position",c,CONVERGE).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
        t.tween_property(g,"rotation",0.0,CONVERGE)
        t.tween_property(g,"scale",Vector2.ONE*.9,CONVERGE)
        t.chain().tween_callback(func()->void:g.visible=false;gg.visible=false)
    var label:="^%d" % after if after-before<=1 else "^%d → ^%d" % [before,after]
    _impact(c,tint,CONVERGE,icon,label,icon_rect.size.y*.5)

## Merge All: a flash on the button that did it (no copies, no icon): the dock glints show which items.
func play_button(rect: Rect2,tint: Color) -> void:
    stop()
    _impact(_local(rect.get_center()),tint,0.0,null,"",0.0)

func _impact(c: Vector2,tint: Color,delay: float,icon: Texture2D,label: String,half_height: float) -> void:
    var light:=tint.lightened(.5)
    var t:=_tween()
    if delay>0:t.tween_interval(delay)
    t.tween_callback(func()->void:
        _pop(glow,c,light,60.0,200.0,.34,.95)
        _pop(ring,c,light,48.0,176.0,.36,.95)
        _pop(star,c,Color(1,1,.92),36.0,200.0,.3,1.0,deg_to_rad(25))
        sparks.position=c
        sparks.color=light
        sparks.restart()
        sparks.emitting=true
        if icon!=null:
            icon_double.texture=icon
            icon_double.position=c-icon_double.size*.5
            icon_double.scale=Vector2.ONE
            icon_double.modulate=Color(2.2,2.2,2.2)
            icon_double.visible=true
            var p:=_tween().set_parallel(true)
            p.tween_property(icon_double,"scale",Vector2.ONE*1.28,.07)
            p.tween_property(icon_double,"modulate",Color.WHITE,.32)
            p.chain().tween_property(icon_double,"scale",Vector2.ONE,.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
            p.chain().tween_property(icon_double,"modulate:a",0.0,.12)
            p.chain().tween_callback(func()->void:icon_double.visible=false)
        if label!="":
            level_label.text=label
            level_label.reset_size()
            # Starts over the icon and settles just above it (it never leaves the card's header area).
            level_label.position=c+Vector2(-level_label.size.x*.5,-level_label.size.y*.5)
            level_label.position.x=clampf(level_label.position.x,4,size.x-level_label.size.x-4)
            level_label.modulate=Color(1,1,1,1)
            level_label.scale=Vector2.ONE*.6
            level_label.pivot_offset=level_label.size*.5
            level_label.visible=true
            var l:=_tween().set_parallel(true)
            l.tween_property(level_label,"scale",Vector2.ONE,.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
            l.tween_property(level_label,"position:y",level_label.position.y-half_height*.55,.95).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
            l.tween_property(level_label,"modulate:a",0.0,.35).set_delay(.6)
            l.chain().tween_callback(func()->void:level_label.visible=false))

## One additive sprite growing from size a to b (base canvas px) while fading out over d seconds.
func _pop(s: Sprite2D,at: Vector2,color: Color,a: float,b: float,d: float,alpha: float,spin:=0.0) -> void:
    var w:=float(s.texture.get_width())
    s.position=at
    s.rotation=0.0
    s.scale=Vector2.ONE*(a/w)
    s.modulate=Color(color,alpha)
    s.visible=true
    var t:=_tween().set_parallel(true)
    t.tween_property(s,"scale",Vector2.ONE*(b/w),d).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    t.tween_property(s,"modulate:a",0.0,d).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    if spin!=0.0:t.tween_property(s,"rotation",spin,d)
    t.chain().tween_callback(func()->void:s.visible=false)

## A short glint over one dock slot (global rect). Returns false (nothing shown) when the pool is busy
## or this slot is already glinting, so repeated automatic merges never stack effects.
func glint(rect: Rect2,tint: Color,strong:=false,delay:=0.0) -> bool:
    var key:="%d:%d" % [int(rect.position.x),int(rect.position.y)]
    if glint_busy.has(key):return false
    var holder: Node2D=null
    for g in glints:
        if not g.visible and not g.has_meta("reserved"):holder=g;break
    if holder==null:return false
    holder.set_meta("reserved",true)
    glint_busy[key]=true
    var c:=_local(rect.get_center())
    var size:=minf(rect.size.x,rect.size.y)
    var light:=tint.lightened(.5)
    var g: Sprite2D=holder.get_node("Glow")
    var r: Sprite2D=holder.get_node("Ring")
    var s: Sprite2D=holder.get_node("Star")
    holder.position=c
    var gw:=float(GLOW.get_width());var rw:=float(RING.get_width());var sw:=float(FLASH_STAR.get_width())
    var scale_glow:=size*(1.5 if strong else 1.1)/gw
    g.scale=Vector2.ONE*scale_glow*.5;g.modulate=Color(light,0)
    r.visible=strong
    r.scale=Vector2.ONE*size*.4/rw;r.modulate=Color(light,.9)
    s.scale=Vector2.ZERO;s.rotation=0.0;s.modulate=Color(1,1,.9,1)
    s.position=Vector2(size*.22,-size*.2) if not strong else Vector2.ZERO
    var star_size:=size*(1.3 if strong else .8)/sw
    var length:=.62 if strong else .46
    var previous: Tween=glint_tweens.get(holder)
    if previous!=null and previous.is_valid():previous.kill()
    var t:=create_tween().set_ignore_time_scale(true)
    glint_tweens[holder]=t
    if delay>0:t.tween_interval(delay)
    t.tween_callback(func()->void:holder.visible=true)
    t.set_parallel(true)
    t.tween_property(g,"modulate:a",.75 if strong else .55,length*.3)
    t.tween_property(g,"scale",Vector2.ONE*scale_glow,length*.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    t.tween_property(s,"scale",Vector2.ONE*star_size,length*.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    t.tween_property(s,"rotation",deg_to_rad(45),length)
    if strong:
        t.tween_property(r,"scale",Vector2.ONE*size*1.5/rw,length).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        t.tween_property(r,"modulate:a",0.0,length)
    t.chain().set_parallel(true)
    t.tween_property(g,"modulate:a",0.0,length*.6)
    t.tween_property(s,"scale",Vector2.ZERO,length*.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    t.chain().tween_callback(func()->void:
        holder.visible=false
        holder.remove_meta("reserved")
        glint_busy.erase(key))
    return true

## Glints currently reserved or showing (probes).
func active_glints() -> int:
    return glints.filter(func(g):return g.visible or g.has_meta("reserved")).size()

## Ends every glint at once (a profile change or Prestige).
func clear_glints() -> void:
    for holder in glints:
        var t: Tween=glint_tweens.get(holder)
        if t!=null and t.is_valid():t.kill()
        holder.visible=false
        if holder.has_meta("reserved"):holder.remove_meta("reserved")
    glint_busy.clear()
