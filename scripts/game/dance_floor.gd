extends Node2D
## Change 83: the Green Alien celebration floor, in the clearing where it fell (its home; the arena clearing is
## free of solid scenery). Presentation only: world.gd shows it while campaign.floor_visible() (from the defeat
## until the boss respawns, on its map) and frees it otherwise, so it never accumulates across victories, deaths,
## Prestige, map changes or reloads.
##
##   floor     a round disco floor of coloured tiles (normal blending, translucent) that steps through colours with
##             the beat, a ring of rim lights, under the actors
##   dancers   every obtainable outfit the profile owns (campaign.owned_floor_outfits(), one per outfit), each the
##             outfit's own Pixel Plains sheet (idle row, a walk-row shuffle on the beat), popping in one after
##             another within SPAWN_SECONDS, then hopping, swaying and turning in rings around the floor. New outfits
##             join while it shows.
##   effects   falling confetti (the moments Confetti_Sheet), fireworks (a rising spark, then a coloured burst of
##             glows, one of three pooled emitters), turning coloured light beams (Light_Ray_007); more fireworks
##             during the first 10 s celebration (intro)
##   caption   below the floor: "Collect every outfit to complete this celebration floor!" and
##             "Outfits dancing: X / Y" (X owned of Y obtainable), updated when ownership changes
## Cheap on Android: one Sprite2D per dancer (region frames, no actor views), one confetti emitter (40), three
## firework emitters (24 each), four beams; all game time (pauses with the world).

const CONFETTI:=preload("res://assets/vfx/moments/Confetti_Sheet.png")
const GLOW:=preload("res://assets/vfx/buff/Glow_001.png")
const BEAM:=preload("res://assets/vfx/buff/Light_Ray_007.png")
const STAR:=preload("res://assets/vfx/celebration/Star_004.png")
const THEME:=preload("res://resources/game/theme.tres")
const SPAWN_SECONDS:=5.0
const FLOOR_RADIUS:=74.0
const CAPTION_WIDTH:=170.0
const TILE:=11.0
const RINGS:=[[30.0,8],[52.0,14],[74.0,20],[96.0,26]]
const PALETTE:=[Color(1,.35,.45),Color(1,.75,.25),Color(.4,.95,.55),Color(.35,.7,1),Color(.8,.45,1),Color(1,.95,.4)]

var sim
var intro:=false
var time:=0.0
var beat_time:=0.0
var dancers: Array=[]
var queue: Array=[]
var spawn_clock:=0.0
var firework_clock:=0.0
var fireworks: Array=[]
var firework_next:=0
var confetti: CPUParticles2D
var beams: Array=[]
var caption: Label
var count_label: Label
var add_material:=CanvasItemMaterial.new()
var shown_ids: Array=[]
var textures: Dictionary={}
var total:=0
## The floor tiles, rim lights and shadows sit on the ground under every actor (the world is y-sorted: a single
## node at the floor's y would draw over the hero standing north of it); rocket sparks draw above the fog.
var ground: Node2D
var sky: Node2D

func _ready() -> void:
    add_material.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD
    texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    process_mode=Node.PROCESS_MODE_PAUSABLE
    # Dancers join the world's y-sort with the actors.
    y_sort_enabled=true
    ground=Node2D.new();ground.z_index=-1;ground.draw.connect(_draw_ground);add_child(ground)
    sky=Node2D.new();sky.z_index=53;sky.draw.connect(_draw_sky);add_child(sky)
    for i in range(4):
        var b:=Sprite2D.new();b.texture=BEAM;b.material=add_material;b.centered=true
        b.offset=Vector2(0,-BEAM.get_height()*.5);b.z_index=52;b.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
        add_child(b);beams.append(b)
    confetti=CPUParticles2D.new()
    var mat:=CanvasItemMaterial.new()
    mat.particles_animation=true;mat.particles_anim_h_frames=1;mat.particles_anim_v_frames=3;mat.particles_anim_loop=false
    confetti.material=mat;confetti.texture=CONFETTI;confetti.z_index=52
    confetti.amount=40;confetti.lifetime=3.2;confetti.preprocess=0.0
    confetti.emission_shape=CPUParticles2D.EMISSION_SHAPE_RECTANGLE;confetti.emission_rect_extents=Vector2(FLOOR_RADIUS+30,4)
    confetti.position=Vector2(0,-FLOOR_RADIUS-40)
    confetti.direction=Vector2(0,1);confetti.spread=25;confetti.initial_velocity_min=20;confetti.initial_velocity_max=45
    confetti.gravity=Vector2(0,28);confetti.angular_velocity_min=-300;confetti.angular_velocity_max=300
    confetti.scale_amount_min=.06;confetti.scale_amount_max=.09;confetti.anim_offset_max=1
    confetti.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
    var colors:=Gradient.new()
    colors.offsets=PackedFloat32Array([0,.2,.4,.6,.8,1])
    colors.colors=PackedColorArray(PALETTE)
    colors.interpolation_mode=Gradient.GRADIENT_INTERPOLATE_CONSTANT
    confetti.color_initial_ramp=colors
    var fade:=Gradient.new();fade.offsets=PackedFloat32Array([0,.85,1]);fade.colors=PackedColorArray([Color.WHITE,Color.WHITE,Color(1,1,1,0)])
    confetti.color_ramp=fade
    add_child(confetti)
    for i in range(3):
        var f:=CPUParticles2D.new()
        f.texture=GLOW;f.material=add_material;f.z_index=53;f.one_shot=true;f.emitting=false
        f.amount=24;f.lifetime=1.1;f.explosiveness=.95;f.spread=180
        f.initial_velocity_min=45;f.initial_velocity_max=80;f.damping_min=40;f.damping_max=60;f.gravity=Vector2(0,30)
        f.scale_amount_min=.04;f.scale_amount_max=.07;f.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
        var r:=Gradient.new();r.offsets=PackedFloat32Array([0,.1,.7,1]);r.colors=PackedColorArray([Color(1,1,1,0),Color.WHITE,Color(1,1,1,.7),Color(1,1,1,0)])
        f.color_ramp=r
        add_child(f)
        fireworks.append({"node":f,"rocket":-1.0,"from":Vector2.ZERO,"to":Vector2.ZERO,"color":Color.WHITE})
    caption=_label(20,Color(1,.9,.55))
    count_label=_label(26,Color.WHITE)
    visible=false

func _label(font_size: int,color: Color) -> Label:
    var l:=Label.new()
    l.theme=THEME
    l.mouse_filter=Control.MOUSE_FILTER_IGNORE
    l.add_theme_font_size_override("font_size",font_size)
    l.add_theme_color_override("font_color",color)
    l.add_theme_color_override("font_outline_color",Color.BLACK)
    l.add_theme_constant_override("outline_size",8)
    l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    # Wrapped to the floor's width (CAPTION_WIDTH world units at scale 0.5), so long languages wrap, never run off.
    l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    l.custom_minimum_size=Vector2(CAPTION_WIDTH*2.0,0)
    l.scale=Vector2.ONE*.5
    l.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
    l.z_index=53
    add_child(l)
    return l

## Starts the floor at a point (the boss's home). intro: the first victory's 10 s celebration (more fireworks).
func open(at: Vector2,is_intro: bool) -> void:
    position=at;intro=is_intro;time=0.0;spawn_clock=0.0;firework_clock=0.6
    visible=true
    confetti.emitting=true
    refresh_outfits()

func set_intro(value: bool) -> void:intro=value

## Adds dancers for outfits owned now (new ones join the queue); refreshes the caption.
func refresh_outfits() -> void:
    var owned: Array=sim.campaign.owned_floor_outfits()
    total=sim.campaign.floor_outfits().size()
    for id in owned:
        if not shown_ids.has(id):shown_ids.append(id);queue.append(id)
    caption.text=tr("FLOOR_COLLECT_HINT")
    count_label.text=tr("FLOOR_OUTFITS_COUNT") % [owned.size(),total]
    _place_labels()

func _place_labels() -> void:
    var y:=FLOOR_RADIUS*.55+18.0
    for l in [count_label,caption]:
        l.size=Vector2(CAPTION_WIDTH*2.0,0)
        l.reset_size()
        l.position=Vector2(-CAPTION_WIDTH*.5,y)
        y+=l.get_combined_minimum_size().y*l.scale.y-2.0

func _texture(id: String) -> Texture2D:
    if not textures.has(id):textures[id]=load(str(sim.catalog.items[id].texture))
    return textures[id]

## Ring slot i of n dancers: [position, ring index].
func _slot(i: int) -> Vector2:
    var start:=0
    for ring in RINGS:
        if i<start+int(ring[1]):
            var k:=i-start
            var ang:=-PI*.5+TAU*k/float(ring[1])+(.3 if int(ring[1])%2==0 else 0.0)
            return Vector2(cos(ang)*float(ring[0]),sin(ang)*float(ring[0])*.55)
        start+=int(ring[1])
    var j:=i-start
    return Vector2(cos(j*.7)*110.0,sin(j*.7)*60.0)

func _spawn(id: String) -> void:
    var s:=Sprite2D.new()
    s.texture=_texture(id)
    s.region_enabled=true;s.region_rect=Rect2(0,0,24,24)
    s.centered=true;s.offset=Vector2(0,-12)
    var i:=dancers.size()
    var home:=_slot(i)
    s.position=home
    s.scale=Vector2.ZERO
    add_child(s)
    dancers.append({"node":s,"home":home,"age":0.0,"phase":randf()*TAU,"style":i%3,"id":id})
    # A little pop of stars where it appears.
    var f: Dictionary=fireworks[firework_next%fireworks.size()]
    if f.rocket<0:
        var node: CPUParticles2D=f.node
        node.texture=STAR;node.position=home+Vector2(0,-10);node.amount=24
        node.color=PALETTE[i%PALETTE.size()];node.restart();node.emitting=true

func _process(delta: float) -> void:
    if not visible:return
    time+=delta
    # Dancers join one after another, all within SPAWN_SECONDS of the floor opening (or of joining later).
    if not queue.is_empty():
        var step:=minf(.35,SPAWN_SECONDS/float(maxi(1,queue.size()+dancers.size())))
        spawn_clock+=delta
        while spawn_clock>=step and not queue.is_empty():
            spawn_clock-=step
            _spawn(queue.pop_front())
    var beat:=time*2.2
    for d in dancers:
        d.age+=delta
        var s: Sprite2D=d.node
        var grow:=clampf(d.age/.3,0,1)
        var pop:=1.0+.35*sin(grow*PI)
        s.scale=Vector2.ONE*grow*pop
        var b: float=beat+float(d.phase)
        var hop:=absf(sin(b*PI))*(5.0 if d.style==0 else 3.0)
        var sway:=sin(b*PI*.5)*(4.0 if d.style==1 else 2.0)
        s.position=Vector2(d.home)+Vector2(sway,-hop)
        s.flip_h=int(floor(b))%2==1
        s.rotation=sin(b*PI)*(.12 if d.style==2 else .05)
        # Idle row with a walk-row shuffle every other beat (the outfits' own animation rows).
        var row:=1 if int(floor(b*.5))%2==1 and d.style!=1 else 0
        var frames:=4 if row==1 else 8
        s.region_rect=Rect2(int(time*(10.0 if row==1 else 6.0)+float(d.phase)*3.0)%frames*24,row*24,24,24)
    # Beams turn over the floor.
    for i in range(beams.size()):
        var b: Sprite2D=beams[i]
        b.position=Vector2(cos(i*PI*.5)*FLOOR_RADIUS*.55,sin(i*PI*.5)*FLOOR_RADIUS*.3)
        b.rotation=sin(time*.8+i*1.7)*.6
        b.scale=Vector2(.35,1.1)*(110.0/BEAM.get_height())
        b.modulate=Color(PALETTE[(i+int(time*1.5))%PALETTE.size()],.22+.08*sin(time*3.0+i))
    # Fireworks: a spark rises, then bursts.
    firework_clock-=delta
    if firework_clock<=0:
        firework_clock=(.7 if intro else 2.4)+randf()*.5
        _launch()
    for f in fireworks:
        if f.rocket<0:continue
        f.rocket+=delta
        if f.rocket>=.55:
            var node: CPUParticles2D=f.node
            node.texture=GLOW;node.position=f.to;node.color=f.color;node.restart();node.emitting=true
            f.rocket=-1.0
    ground.queue_redraw()
    sky.queue_redraw()

func _launch() -> void:
    for k in range(fireworks.size()):
        var f: Dictionary=fireworks[(firework_next+k)%fireworks.size()]
        if f.rocket>=0 or f.node.emitting:continue
        firework_next=(firework_next+k+1)%fireworks.size()
        f.from=Vector2(randf_range(-FLOOR_RADIUS,FLOOR_RADIUS),0)
        f.to=Vector2(f.from.x*.8+randf_range(-20,20),-FLOOR_RADIUS-randf_range(25,70))
        f.color=PALETTE[randi()%PALETTE.size()]
        f.rocket=0.0
        AudioService.play("floor_firework")
        return

func _draw_ground() -> void:
    # The disco floor: tiles inside an ellipse, each stepping through the palette with the beat.
    var step:=int(time*2.2)
    var rx:=FLOOR_RADIUS+16.0
    var ry:=(FLOOR_RADIUS+16.0)*.55
    var n:=int(ceil(rx/TILE))
    for gy in range(-n,n+1):
        for gx in range(-n,n+1):
            var c:=Vector2(gx*TILE,gy*TILE*.55)
            if (c.x*c.x)/(rx*rx)+(c.y*c.y)/(ry*ry)>1.0:continue
            var col: Color=PALETTE[absi(gx*3+gy*5+step)%PALETTE.size()]
            ground.draw_rect(Rect2(c-Vector2(TILE,TILE*.55)*.5+Vector2(.5,.3),Vector2(TILE-1,TILE*.55-.6)),Color(col,.38))
    # Rim lights.
    for i in range(28):
        var ang:=TAU*i/28.0
        var p:=Vector2(cos(ang)*rx,sin(ang)*ry)
        var on:=(i+step)%2==0
        ground.draw_circle(p,1.8,Color(1,.95,.6,.95) if on else Color(1,.6,.3,.5))
    # Dancer shadows.
    for d in dancers:
        var s: Sprite2D=d.node
        ground.draw_set_transform(Vector2(d.home),0,Vector2(1,.4))
        ground.draw_circle(Vector2.ZERO,6.5*s.scale.x,Color(0,0,0,.28))
        ground.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

func _draw_sky() -> void:
    # Rising firework sparks.
    for f in fireworks:
        if f.rocket<0:continue
        var u:float=f.rocket/.55
        var p:Vector2=f.from.lerp(f.to,1.0-pow(1.0-u,2.0))
        sky.draw_line(p,p+Vector2(0,8),Color(f.color,.6),1.5)
        sky.draw_circle(p,1.8,Color(1,1,.85))
