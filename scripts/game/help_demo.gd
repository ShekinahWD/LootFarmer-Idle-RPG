extends Control
## Change 65: the looping demonstration of one tutorial card (help_cards.gd), shared by the Basic opening
## and Settings → Help & Tutorials. Everything is drawn: the game's own art (the hero sheet, enemy and
## item icons, Coin/Gem, the joystick plates, the guide's pointer) and the theme's button styles on a
## fixed 400 x 240 stage scaled into the control. It reads catalog data for honest numbers (evolution
## thresholds, prices) but never calls a simulation action and never writes state: a demo hit, purchase
## or claim changes nothing in the game.
## The loop restarts when the card changes, plays only while visible and while the app is in front
## (sim.suspended), and draws one static key frame instead when reduced_motion is set.
const HelpCards=preload("res://scripts/game/help_cards.gd")
const W:=400.0
const H:=240.0
const HERO_SHEET:="res://assets/PixelPlains/Characters 24x24/Basic character v2.png"
const POINTER:=preload("res://assets/PixelPlains/Items/All v3 (Separated Files, Black Outline)/Item-273.png")
const STICK_BASE:=preload("res://assets/KenneyFantasyUI/PNG/Default/Transparent center/panel-transparent-center-014.png")
const STICK_KNOB:=preload("res://assets/KenneyFantasyUI/PNG/Default/Panel/panel-014.png")
const COIN:=preload("res://resources/game/coin.tres")
const GEM:=preload("res://resources/game/gem.tres")
const AIM:=Color(1,.75,.2)
const GOOD:=Color(.55,1,.7)
const WORLD_BG:=Color(.16,.23,.19)
const UI_BG:=Color(.1,.12,.16)
## Map Mastery's five category icons (explore, hunt, research, collect, forge), as game_ui.MASTERY_ART.
const MASTERY_ICONS:=[249,1,60,147,211]
## Seconds into the loop drawn as the single frame when motion is reduced (the card's key moment).
const KEY_TIMES:={"movement_combat":3.4,"manual_target":1.8,"collect_equip":5.4,"merge_gear":3.6,"player_upgrades":5.0,
    "enemy_automation":1.4,"missions":5.4,"explore_camps":5.2,"skills_supplies":4.8,"offline_rewards":6.4,
    "weapon_evolution":5.4,"prestige":5.6,"map_details_mastery":6.8,"advanced_farming":4.6}
var ui
var sim
var card_id:=""
var time:=0.0
var playing:=true
var reduced_motion:=false
var _hero: Texture2D
var _pointer: Texture2D
var _enemy_a: Texture2D
var _enemy_b: Texture2D
var _enemy_name:=""
var _weapon: Texture2D
var _outfit: Texture2D
var _evo_from: Texture2D
var _evo_to: Texture2D
var _skill: Texture2D
var _potion: Texture2D
var _snowman: Texture2D

func setup(owner_ui) -> void:
    ui=owner_ui;sim=ui.sim
    texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    clip_contents=true
    var sheet:=AtlasTexture.new();sheet.atlas=load(HERO_SHEET);sheet.region=Rect2(0,0,24,24);_hero=sheet
    _pointer=ui.cropped(POINTER)
    # The first enemies every player meets (Winter I), so a card never reveals an undiscovered type.
    var groups: Array=[]
    for g in sim.catalog.stages[0].groups:
        if not sim.catalog.groups[int(g)].boss:groups.append(int(g))
    var a: Dictionary=sim.catalog.groups[groups[0]]
    var b: Dictionary=sim.catalog.groups[groups[mini(1,groups.size()-1)]]
    _enemy_a=ui._portrait_texture(str(a.body));_enemy_b=ui._portrait_texture(str(b.body))
    _enemy_name=tr(str(a.name))
    _weapon=ui.icon_cache.get(str(a.weapon))
    _outfit=ui.icon_cache.get(str(a.body))
    var evo:=_evolvable(str(a.weapon))
    _evo_from=ui.icon_cache.get(evo);_evo_to=ui.icon_cache.get(str(sim.catalog.items[evo].next)) if evo!="" else null
    _skill=ui.icon_cache.get("skill_lightning",ui.icon_cache.get("skill_fire"))
    _potion=ui.icon_cache.get("potion")
    _snowman=ui.icon_cache.get("boss-snowman_outfit")

## The first-met enemy's weapon when it can evolve, else the first evolvable weapon of the catalog.
func _evolvable(preferred: String) -> String:
    if sim.catalog.items.has(preferred) and str(sim.catalog.items[preferred].get("next",""))!="":return preferred
    for id in sim.catalog.items:
        var d: Dictionary=sim.catalog.items[id]
        if d.kind=="weapon" and str(d.get("next",""))!="" and not bool(d.get("legacy",false)):return id
    return ""

func show_card(id: String) -> void:
    if id!=card_id:card_id=id
    restart()

func restart() -> void:
    time=0.0
    _apply_fade()
    queue_redraw()

func loop_length() -> float:
    return HelpCards.loop_seconds(card_id)

## True while the loop advances (the viewer's Auto-Advance uses the same rule).
func running() -> bool:
    return card_id!="" and playing and not reduced_motion and is_visible_in_tree() and not sim.suspended

func _process(dt: float) -> void:
    if not running():return
    time=fmod(time+dt,loop_length())
    _apply_fade()
    queue_redraw()

func _apply_fade() -> void:
    var s:=_now()
    var l:=loop_length()
    self_modulate.a=1.0 if reduced_motion else clampf(minf(s/.25,(l-s)/.35),0.0,1.0)

func _now() -> float:
    return float(KEY_TIMES.get(card_id,1.0)) if reduced_motion else time

func _draw() -> void:
    if card_id=="" or ui==null:return
    var k:=minf(size.x/W,size.y/H)
    draw_set_transform((size-Vector2(W,H)*k)*.5,0,Vector2(k,k))
    if has_method("_demo_"+card_id):call("_demo_"+card_id,_now())
    draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

# ---------------------------------------------------------------- drawing helpers (stage units)

static func _p(s: float,a: float,b: float) -> float:
    return clampf((s-a)/maxf(.001,b-a),0.0,1.0)

static func _e(x: float) -> float:
    return x*x*(3.0-2.0*x)

func _bg(world:=true) -> void:
    draw_rect(Rect2(0,0,W,H),WORLD_BG if world else UI_BG)
    if world:
        for i in range(14):
            var x:=fmod(37.0*i+11.0,W);var y:=fmod(53.0*i+29.0,H)
            draw_line(Vector2(x,y),Vector2(x+3,y-5),Color(.3,.42,.3,.7),2)
            draw_line(Vector2(x+5,y),Vector2(x+6,y-6),Color(.3,.42,.3,.7),2)

func _tex(t: Texture2D,center: Vector2,h: float,color:=Color.WHITE) -> void:
    if t==null:return
    var sz:=t.get_size()
    var w:=h*sz.x/maxf(1.0,sz.y)
    draw_texture_rect(t,Rect2(center-Vector2(w,h)*.5,Vector2(w,h)),false,color)

func _shadow(at: Vector2,w:=24.0) -> void:
    draw_rect(Rect2(at+Vector2(-w*.5,15),Vector2(w,5)),Color(0,0,0,.28))

func _hero_at(at: Vector2,lunge:=0.0,toward:=Vector2.RIGHT) -> void:
    var pos:=at+toward.normalized()*8.0*sin(lunge*PI)
    _shadow(at)
    _tex(_hero,pos,40)

func _enemy_at(at: Vector2,tex: Texture2D,hurt:=0.0,alpha:=1.0) -> void:
    if alpha<=0:return
    _shadow(at)
    _tex(tex,at,36,Color(1,1-.6*hurt,1-.6*hurt,alpha))

func _slash(at: Vector2,t: float) -> void:
    if t<=0 or t>=1:return
    draw_arc(at,16,-1.2+t*1.6,-.2+t*1.6,12,Color(1,1,1,1-t),3,true)

func _float_text(text: String,at: Vector2,t: float,color:=Color(1,.9,.5)) -> void:
    if t<=0 or t>=1:return
    _label(text,Rect2(at-Vector2(40,10+18*t),Vector2(80,18)),14,Color(color,1-t))

func _touch(at: Vector2,pressed:=false,alpha:=1.0) -> void:
    if alpha<=0:return
    draw_circle(at,12.0 if pressed else 15.0,Color(1,1,1,.28*alpha))
    draw_arc(at,12.0 if pressed else 15.0,0,TAU,24,Color(1,1,1,.9*alpha),2,true)
    draw_texture_rect(_pointer,Rect2(at+Vector2(2,2),Vector2(26,26)),false,Color(1,1,1,alpha))

func _ripple(at: Vector2,t: float) -> void:
    if t<=0 or t>=1:return
    draw_arc(at,8+18*t,0,TAU,24,Color(AIM,1-t),3,true)

func _ring(at: Vector2,r: float,color: Color,width:=3.0) -> void:
    draw_arc(at,r,0,TAU,32,color,width,true)

func _dashed(a: Vector2,b: Vector2,color: Color,dash:=8.0,gap:=6.0) -> void:
    var length:=a.distance_to(b)
    if length<1:return
    var d:=(b-a)/length
    var x:=0.0
    while x<length:
        draw_line(a+d*x,a+d*minf(length,x+dash),color,2,true)
        x+=dash+gap

func _label(text: String,rect: Rect2,font_size:=14,color:=Color.WHITE,align:=HORIZONTAL_ALIGNMENT_CENTER) -> void:
    var font: Font=get_theme_default_font()
    var s:=font_size
    while s>7 and font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,s).x>rect.size.x:s-=1
    var y:=rect.position.y+(rect.size.y+font.get_ascent(s)-font.get_descent(s))*.5
    draw_string_outline(font,Vector2(rect.position.x,y),text,align,rect.size.x,s,3,Color(0,0,0,.8*color.a))
    draw_string(font,Vector2(rect.position.x,y),text,align,rect.size.x,s,color)

func _panel(rect: Rect2,border:=Color(.45,.52,.62)) -> void:
    draw_rect(rect,Color(.15,.18,.24,.97))
    draw_rect(rect,border,false,2)

func _button(rect: Rect2,text: String,primary:=false,pressed:=false,icon: Texture2D=null) -> void:
    var box: StyleBox=get_theme_stylebox("pressed" if pressed else "normal","Primary" if primary else "Button")
    if box!=null:draw_style_box(box,rect)
    else:draw_rect(rect,Color(.3,.36,.45))
    var text_rect:=rect.grow_individual(-6,0,-6,0)
    if icon!=null:
        _tex(icon,Vector2(rect.position.x+14,rect.get_center().y),14)
        text_rect=rect.grow_individual(-24,0,-6,0)
    _label(text,text_rect,13)
    if pressed:draw_rect(rect,Color(0,0,0,.18))

func _glow(rect: Rect2,s: float) -> void:
    draw_rect(rect.grow(3),Color(AIM,.55+.45*sin(s*7)),false,2)

func _slot(rect: Rect2,icon: Texture2D,badge:="",tint:=Color.WHITE) -> void:
    draw_rect(rect,Color(.08,.1,.14,.95))
    draw_rect(rect,Color(.5,.56,.66),false,2)
    _tex(icon,rect.get_center(),rect.size.y*.72,tint)
    if badge!="":_label(badge,Rect2(rect.position+Vector2(0,rect.size.y-14),Vector2(rect.size.x-3,14)),11,Color(1,.95,.7),HORIZONTAL_ALIGNMENT_RIGHT)

func _bar(rect: Rect2,frac: float,color: Color) -> void:
    draw_rect(rect,Color(0,0,0,.55))
    draw_rect(Rect2(rect.position,Vector2(rect.size.x*clampf(frac,0,1),rect.size.y)),color)
    draw_rect(rect,Color(1,1,1,.35),false,1)

func _sparkle(at: Vector2,t: float,color:=Color(1,.92,.5)) -> void:
    if t<=0 or t>=1:return
    for i in range(6):
        var d:=Vector2.RIGHT.rotated(TAU*i/6.0+.4)
        draw_circle(at+d*(6+22*t),2.5*(1-t)+.5,Color(color,1-t))

func _stick(center: Vector2,push: Vector2,alpha:=1.0) -> void:
    draw_texture_rect(STICK_BASE,Rect2(center-Vector2(34,34),Vector2(68,68)),false,Color(.9,.94,1,.8*alpha))
    draw_texture_rect(STICK_KNOB,Rect2(center+push-Vector2(14,14),Vector2(28,28)),false,Color(.6,.67,.76,.92*alpha))

# ---------------------------------------------------------------- the 14 demonstrations

## Thumb on the real joystick plates pushes right; the hero walks to a foe, stops, then attacks on its own.
func _demo_movement_combat(s: float) -> void:
    _bg()
    var push:=_e(_p(s,.6,1.0))*(1.0-_p(s,2.6,2.8))
    var hero:=Vector2(130,110).lerp(Vector2(262,110),_e(_p(s,.8,2.6)))
    var enemy:=Vector2(300,110)
    var swing:=fmod(maxf(0,s-3.0),.8)/.8 if s>=3.0 and s<5.4 else 0.0
    _enemy_at(enemy,_enemy_a,.8 if swing>.45 and swing<.7 else 0.0)
    _hero_at(hero,swing)
    if s>=3.0 and s<5.4:
        _slash(enemy+Vector2(-10,-4),_p(swing,.35,.75))
        _float_text("−12",enemy+Vector2(0,-22),_p(swing,.45,1.0))
    var stick:=Vector2(70,190)
    _stick(stick,Vector2(26,0)*push)
    _touch(stick+Vector2(26,0)*push,push>0,1.0-_p(s,2.6,2.9))
    if s>=3.0:_ring(enemy,22,Color(AIM,.6),2)

## The drag starts on the hero (ring), travels to an enemy, releases (selection ring) and the attack follows.
func _demo_manual_target(s: float) -> void:
    _bg()
    var hero_home:=Vector2(110,140)
    var a:=Vector2(290,80)
    var b:=Vector2(300,190)
    var drag:=_e(_p(s,.8,2.2))
    var approach:=_e(_p(s,2.8,4.0))
    var hero:=hero_home.lerp(a+Vector2(-36,8),approach)
    var swing:=fmod(maxf(0,s-4.1),.7)/.7 if s>=4.1 and s<5.9 else 0.0
    _enemy_at(b,_enemy_b)
    _enemy_at(a,_enemy_a,.8 if swing>.45 and swing<.7 else 0.0)
    _hero_at(hero,swing,a-hero)
    _stick(Vector2(50,200),Vector2.ZERO,.35)
    if s<2.4:
        _ring(hero_home,24,Color(1,1,1,.6+.4*sin(s*8)),3)
        if s>.8:
            _dashed(hero_home,a,Color(AIM,.45))
            draw_line(hero_home,hero_home.lerp(a,drag),Color(0,0,0,.6),5,true)
            draw_line(hero_home,hero_home.lerp(a,drag),AIM,3,true)
        _touch(hero_home.lerp(a,drag),s>.6,_p(s,.2,.6))
    _ripple(a,_p(s,2.2,2.8))
    if s>=2.2:_ring(a,22+2*sin(s*6),AIM,3)
    if swing>0:_slash(a+Vector2(-10,-4),_p(swing,.35,.75))

## A foe falls, its drop is tapped and flies into the inventory, the slot is tapped, Equip, stats rise.
func _demo_collect_equip(s: float) -> void:
    _bg()
    var enemy:=Vector2(250,80)
    var hero:=Vector2(150,86)
    var fall:=_p(s,.6,1.2)
    _enemy_at(enemy,_enemy_a,.8 if s<.8 else 0.0,1.0-fall)
    _hero_at(hero,_p(s,.2,.6))
    var drop:=enemy+Vector2(0,26)
    var fly:=_e(_p(s,2.6,3.3))
    var slot:=Rect2(150,178,44,44)
    if s>=1.2 and s<3.3:
        var bounce:=absf(sin(_p(s,1.2,1.8)*PI))*10
        _tex(_weapon,drop.lerp(slot.get_center(),fly)-Vector2(0,bounce*(1.0-fly)),26)
    _ripple(drop,_p(s,2.3,2.8))
    for i in range(4):
        var r:=Rect2(102+i*48,178,44,44)
        _slot(r,_weapon if i==1 and s>=3.3 else null,"×1" if i==1 and s>=3.3 else "")
    var equip_btn:=Rect2(214,132,96,32)
    if s>=4.1 and s<5.1:_button(equip_btn,tr("EQUIP"),true,s>=4.7)
    var equipped:=Rect2(26,20,44,44)
    _slot(equipped,_weapon if s>=5.0 else null,"",Color(1,1,1,_p(s,5.0,5.3)))
    draw_rect(equipped.grow(2),Color(1,.86,.5,.8),false,2)
    _float_text(tr("STAT_DAMAGE")+" ▲",equipped.get_center()+Vector2(70,0),_p(s,5.1,6.6),GOOD)
    var finger:=Vector2.INF
    if s>=1.9 and s<2.8:finger=drop
    elif s>=3.4 and s<4.0:finger=slot.get_center()
    elif s>=4.2 and s<5.0:finger=equip_btn.get_center()
    if finger!=Vector2.INF:_touch(finger,(s>=2.3 and s<2.8) or (s>=3.6 and s<4.0) or s>=4.7)
    _ripple(slot.get_center(),_p(s,3.6,4.1))

## Two copies of the same item, one Merge, one item with a higher merge rank.
func _demo_merge_gear(s: float) -> void:
    _bg(false)
    var left:=Rect2(110,70,56,56)
    var right:=Rect2(234,70,56,56)
    var join:=_e(_p(s,2.2,3.0))
    var merged:=s>=3.0
    if not merged:
        _slot(left.grow(0),null);_slot(right,null)
        _tex(_weapon,left.get_center().lerp(Vector2(200,98),join),40)
        _tex(_weapon,right.get_center().lerp(Vector2(200,98),join),40)
        _label("^0",Rect2(left.position+Vector2(0,60),Vector2(56,16)),13,Color(1,.95,.7))
        _label("^0",Rect2(right.position+Vector2(0,60),Vector2(56,16)),13,Color(1,.95,.7))
    else:
        var mid:=Rect2(172,70,56,56)
        _slot(mid,_weapon)
        _label("^0  →  ^1",Rect2(130,130,140,22),17,GOOD)
        _sparkle(mid.get_center(),_p(s,3.0,3.9))
    var button:=Rect2(120,176,160,36)
    if s>=.9 and s<3.0:_button(button,tr("MERGE_ONE"),true,s>=1.8)
    if s<1.0:_touch(left.get_center(),s>=.6,_p(s,.2,.5))
    elif s<2.2:_touch(button.get_center(),s>=1.8)
    _ripple(left.get_center(),_p(s,.6,1.1))

## Player Upgrades: the global Focused Farming row (25 Gems) is bought, reads MAX, and Farm is usable.
func _demo_player_upgrades(s: float) -> void:
    _bg(false)
    var price:=int(sim.upgrade_cost("focus")) if sim.catalog.upgrades.has("focus") else 25
    var bought:=s>=2.2
    var view:=_p(s,3.6,4.0)
    if view<1.0:
        var alpha:=1.0-view
        _label(tr("PANEL_UPGRADES"),Rect2(20,8,360,22),15,Color(1,.86,.5,alpha))
        var gems:=40-(price if bought else 0)
        _tex(GEM,Vector2(330,46),14);_label(str(gems),Rect2(340,36,50,20),14,Color(1,1,1,alpha),HORIZONTAL_ALIGNMENT_LEFT)
        var row1:=Rect2(20,64,360,56)
        _panel(row1)
        _label(tr("UP_RESPAWN"),Rect2(70,70,180,20),13,Color(.8,.84,.9),HORIZONTAL_ALIGNMENT_LEFT)
        _button(Rect2(280,74,88,36),"30",false,false,COIN)
        var row2:=Rect2(20,130,360,64)
        _panel(row2,Color(1,.86,.5) if not bought else Color(.45,.52,.62))
        _tex(ui._art(147),Vector2(44,162),30)
        _label(tr("UP_FOCUS"),Rect2(70,136,200,20),14,Color.WHITE,HORIZONTAL_ALIGNMENT_LEFT)
        _label(tr("FOCUS_GLOBAL_OWNED") if bought else tr("FOCUS_GLOBAL_BENEFIT"),Rect2(70,156,200,30),11,GOOD,HORIZONTAL_ALIGNMENT_LEFT)
        var buy:=Rect2(280,144,88,38)
        _button(buy,tr("UPGRADE_MAX") if bought else str(price),not bought,s>=1.8 and s<2.2,null if bought else GEM)
        if not bought:_glow(buy,s)
        else:_sparkle(buy.get_center(),_p(s,2.2,3.0))
        if s<2.3:_touch(buy.get_center(),s>=1.8,_p(s,.6,1.0))
    if view>0:
        var card:=Rect2(40,40,320,150)
        _panel(card)
        _tex(_enemy_a,Vector2(80,84),40,Color(1,1,1,view))
        _label(_enemy_name,Rect2(110,66,230,22),15,Color(1,1,1,view),HORIZONTAL_ALIGNMENT_LEFT)
        var farm:=Rect2(80,130,240,40)
        var on:=s>=5.4
        _button(farm,tr("FOCUS_GROUP") % [_enemy_name,tr("ON" if on else "OFF")],true,s>=5.0 and s<5.4)
        if s>=4.4 and s<5.5:_touch(farm.get_center(),s>=5.0)
        if on:_ring(Vector2(80,84),26,Color(GOOD,.7))

## One enemy's upgrades: Auto-Collect, Auto-Merge and Auto Evolution light up in turn, each with its own effect.
func _demo_enemy_automation(s: float) -> void:
    _bg(false)
    _tex(_enemy_a,Vector2(40,28),34)
    _label(_enemy_name,Rect2(66,14,320,26),15,Color.WHITE,HORIZONTAL_ALIGNMENT_LEFT)
    var keys:=["UP_COLLECT","UP_MERGE_GEAR","UP_AUTO_EVOLVE"]
    var active:=int(s/2.5)%3
    var local:=fmod(s,2.5)/2.5
    for i in range(3):
        var row:=Rect2(16,52+i*60,220,52)
        _panel(row,Color(1,.86,.5) if i==active else Color(.45,.52,.62))
        _label(tr(keys[i]),Rect2(row.position+Vector2(10,0),Vector2(row.size.x-20,row.size.y)),13,Color.WHITE if i==active else Color(.7,.75,.82),HORIZONTAL_ALIGNMENT_LEFT)
        if i==active:_glow(row,s)
    var box:=Rect2(250,52,136,172)
    _panel(box)
    var c:=box.get_center()
    match active:
        0:
            # Loot flies to the bag by itself (no tap).
            var bag:=Rect2(c.x-22,box.end.y-56,44,44)
            _slot(bag,_weapon if local>.6 else null)
            _tex(_weapon,Vector2(c.x,box.position.y+34).lerp(bag.get_center(),_e(_p(local,.2,.6))),24,Color(1,1,1,1.0-_p(local,.6,.62)))
        1:
            var j:=_e(_p(local,.25,.6))
            if local<.6:
                _tex(_weapon,Vector2(c.x-34,c.y).lerp(c,j),30);_tex(_weapon,Vector2(c.x+34,c.y).lerp(c,j),30)
            else:
                _tex(_weapon,c,34);_label("^+1",Rect2(c.x-40,c.y+22,80,18),14,GOOD);_sparkle(c,_p(local,.6,.95))
        2:
            _tex(_evo_from,c+Vector2(0,-30),30,Color(1,1,1,1.0-_p(local,.45,.6)))
            _label("▼",Rect2(c.x-20,c.y-10,40,20),16,AIM)
            _tex(_evo_to,c+Vector2(0,34),34,Color(1,1,1,_p(local,.45,.6)))
            _sparkle(c+Vector2(0,34),_p(local,.6,.95))

## Follow a mission, progress fills, the ready card is claimed by a tap and pays its reward.
func _demo_missions(s: float) -> void:
    _bg(false)
    var card:=Rect2(30,30,340,120)
    var ready:=s>=4.0
    _panel(card,Color(1,.86,.5) if ready else Color(.45,.52,.62))
    _tex(_enemy_a,Vector2(62,66),30)
    _label(tr("ENEMY_KILLS") % ("%d / 10" % int(10*_p(s,1.6,4.0))),Rect2(86,44,270,22),14,Color.WHITE,HORIZONTAL_ALIGNMENT_LEFT)
    _bar(Rect2(86,74,270,12),_p(s,1.6,4.0),GOOD if ready else AIM)
    var button:=Rect2(240,100,116,36)
    if not ready:
        var following:=s>=1.2
        _button(button,tr("FOLLOW")+(" ✓" if following else ""),not following,s>=.9 and s<1.2)
        if s<1.3:_touch(button.get_center(),s>=.9,_p(s,.3,.6))
    elif s<5.1:
        _button(button,tr("CLAIM"),true,s>=4.8);_glow(button,s)
        _touch(button.get_center(),s>=4.8,_p(s,4.2,4.5))
    else:
        _label("✓",Rect2(button.position,button.size),18,GOOD)
    # The followed mission's tracker on the map below.
    var tracker:=Rect2(30,170,200,40)
    if s>=1.2 and s<5.1:
        _panel(tracker);_bar(Rect2(40,186,180,10),_p(s,1.6,4.0),AIM)
    var r:=_p(s,5.1,6.6)
    if r>0 and r<1:
        _tex(COIN,Vector2(298,170).lerp(Vector2(298,120),_e(r)),20,Color(1,1,1,1-r*.6))
        _tex(GEM,Vector2(326,170).lerp(Vector2(326,120),_e(r)),20,Color(1,1,1,1-r*.6))
        _float_text("+25",Vector2(312,150),r,GOOD)

## Walk through fog to a camp, then the visual Teleport map: tap another owned camp, Confirm. The respawn
## flag stays where it was (teleporting never changes it).
func _demo_explore_camps(s: float) -> void:
    _bg()
    if s<3.6:
        var hero:=Vector2(60,160).lerp(Vector2(270,110),_e(_p(s,.2,2.4)))
        var camp:=Vector2(300,96)
        _tex(ui._art(249),camp,34,Color(1,1,1,_p(s,1.6,2.2)))
        _hero_at(hero)
        # Fog: dark everywhere except the walked path around the hero.
        for x in range(0,int(W),20):
            for y in range(0,int(H),20):
                var cell:=Vector2(x+10,y+10)
                var clear:=false
                for k in range(8):
                    var past:=Vector2(60,160).lerp(Vector2(270,110),_e(_p(s,.2,2.4))*k/7.0)
                    if cell.distance_to(past)<62:clear=true;break
                if not clear:draw_rect(Rect2(x,y,20,20),Color(.03,.04,.06,.82))
        if s>=2.2:_ring(camp,24+3*sin(s*7),Color(GOOD,.9),3);_float_text("✓",camp+Vector2(0,-20),_p(s,2.2,3.2),GOOD)
        return
    var map:=Rect2(40,16,320,170)
    _panel(map)
    draw_rect(map.grow(-6),Color(.2,.29,.23))
    var here:=Vector2(100,130)
    var goal:=Vector2(290,60)
    var other:=Vector2(200,150)
    var arrived:=s>=6.0
    for pair in [[here,Color(.45,.7,1) if not arrived else Color(.4,.9,.5)],[goal,Color(.4,.9,.5) if not arrived else Color(.45,.7,1)],[other,Color(.4,.9,.5)]]:
        draw_circle(pair[0],10,pair[1]);_ring(pair[0],10,Color(0,0,0,.6),2)
    # The respawn flag stays at the first camp (travel never changes it).
    _tex(ui._art(249),here+Vector2(0,-22),20)
    if s>=6.4:_ring(here,18+2*sin(s*6),Color(1,.86,.5),2)
    _tex(_hero,here.lerp(goal,_e(_p(s,5.9,6.2)))+Vector2(0,-4),22)
    if s>=4.6:_ring(goal,16,AIM,3)
    var confirm:=Rect2(120,194,160,36)
    if s>=4.6 and s<6.0:_button(confirm,tr("TELEPORT_CONFIRM"),true,s>=5.5)
    if s<4.7:_touch(goal,s>=4.3,_p(s,3.7,4.1))
    elif s<6.0:_touch(confirm.get_center(),s>=5.5)
    _ripple(goal,_p(s,4.3,4.8))
    if s>=6.4:_label(tr("CAMP_SELECT"),Rect2(40,196,140,30),12,Color(1,.86,.5))

## A skill drops into its slot and fires at a foe; later a Health Potion in the supply slot heals.
func _demo_skills_supplies(s: float) -> void:
    _bg()
    var hero:=Vector2(120,100)
    var enemy:=Vector2(290,100)
    var hp:=1.0-.55*_p(s,2.6,3.4)+.55*_p(s,4.4,5.4)
    _enemy_at(enemy,_enemy_a,.8 if s>=1.8 and s<2.2 else 0.0)
    _hero_at(hero)
    _bar(Rect2(hero.x-24,hero.y-34,48,7),hp,Color(.4,.9,.45) if hp>.5 else Color(1,.5,.35))
    var skills:=[Rect2(30,184,44,44),Rect2(80,184,44,44),Rect2(130,184,44,44)]
    for r in skills:_slot(r,null)
    var drop:=_e(_p(s,.4,1.2))
    _tex(_skill,Vector2(52,150).lerp(skills[0].get_center(),drop),30)
    if s>=1.6 and s<2.2:
        var t:=_p(s,1.6,2.2)
        var a:=hero+Vector2(10,-6)
        var pts:=PackedVector2Array()
        for i in range(7):
            pts.append(a.lerp(enemy,i/6.0)+Vector2(0,(-8 if i%2==0 else 8) if i>0 and i<6 else 0))
        draw_polyline(pts,Color(.7,.85,1,1-t),3,true)
        _sparkle(enemy,t,Color(.7,.85,1))
    var supply:=Rect2(320,184,44,44)
    _slot(supply,_potion,"×1" if s<4.4 else "")
    draw_rect(supply.grow(2),Color(.6,1,.75,.6),false,2)
    if s>=3.6 and s<4.6:_touch(supply.get_center(),s>=4.2,_p(s,3.6,3.9))
    _ripple(supply.get_center(),_p(s,4.2,4.7))
    if s>=4.4 and s<5.6:_float_text("+",hero+Vector2(0,-30),_p(s,4.4,5.6),GOOD);_sparkle(hero,_p(s,4.4,5.2),GOOD)

## Return receipt (Coins, Gems, gear and supplies locked) is claimed; an Offline unlock is bought; a later
## receipt shows that one category, the others still locked. The first receipt is never edited.
func _demo_offline_rewards(s: float) -> void:
    _bg(false)
    var rows:=[["OFFLINE_CAT_COINS",COIN],["OFFLINE_CAT_GEMS",GEM],["WEAPONS",_weapon],["OUTFITS",_outfit],["CONSUMABLES",_potion]]
    if s<3.0 or s>=5.0:
        var later:=s>=5.0
        var card:=Rect2(60,8,280,176)
        _panel(card,Color(1,.86,.5) if later else Color(.45,.52,.62))
        for i in range(rows.size()):
            var y:=18+i*32
            _tex(rows[i][1],Vector2(86,y+12),20)
            _label(tr(rows[i][0]),Rect2(104,y,120,24),13,Color.WHITE,HORIZONTAL_ALIGNMENT_LEFT)
            var value:="+120" if i==0 else ("+2" if i==1 else tr("OFFLINE_CAT_LOCKED"))
            if later and i==2:value="×1"
            _label(value,Rect2(230,y,100,24),13,(GOOD if i<2 or (later and i==2) else Color(1,.72,.45)),HORIZONTAL_ALIGNMENT_RIGHT)
        if later and s<6.4:_glow(Rect2(70,82,260,30),s)
        var claim:=Rect2(140,196,120,36)
        _button(claim,tr("CLAIM"),true,(s>=2.4 and s<3.0) or s>=7.4)
        if s<3.0:_touch(claim.get_center(),s>=2.4,_p(s,1.6,2.0))
        return
    var row:=Rect2(30,70,340,70)
    _panel(row,Color(1,.86,.5))
    _tex(ui._art(171),Vector2(58,105),30)
    _label(tr("UP_OFFLINE_WEAPON"),Rect2(80,76,180,58),12,Color.WHITE,HORIZONTAL_ALIGNMENT_LEFT)
    var bought:=s>=4.1
    var buy:=Rect2(270,86,90,38)
    _button(buy,tr("UPGRADE_MAX") if bought else "50",not bought,s>=3.8 and s<4.1,null if bought else GEM)
    if not bought:_touch(buy.get_center(),s>=3.8,_p(s,3.1,3.4))
    else:_sparkle(buy.get_center(),_p(s,4.1,4.8))

## Merge rank and spare copies meet the current evolution rule, Evolve, the next-tier weapon.
func _demo_weapon_evolution(s: float) -> void:
    _bg(false)
    var need:=int(sim.catalog.progression.evolution.required_merge)
    var spare: int=sim.evolution_spare_cost()
    var rank:=int(round(need*_p(s,.4,2.2)))
    var copies:=int(round(spare*_p(s,2.2,3.6)))
    var evolved:=s>=4.6
    var slot:=Rect2(40,40,72,72)
    _slot(slot,_evo_to if evolved else _evo_from,"^%d" % (0 if evolved else rank))
    _label("^%d / %d" % [rank,need],Rect2(130,40,120,20),14,GOOD if rank>=need else Color.WHITE,HORIZONTAL_ALIGNMENT_LEFT)
    _bar(Rect2(130,64,230,10),float(rank)/need,GOOD if rank>=need else AIM)
    _label("+%d / %d" % [copies,spare],Rect2(130,84,120,20),14,GOOD if copies>=spare else Color.WHITE,HORIZONTAL_ALIGNMENT_LEFT)
    for i in range(copies):
        _tex(_evo_from,Vector2(140+i*(220.0/maxf(1,spare)),118),16)
    var button:=Rect2(100,172,200,40)
    if not evolved:
        var ready: bool=rank>=need and copies>=spare
        _button(button,tr("EVOLVE") % (tr(sim.catalog.display_name(str(sim.catalog.items[_evolvable_id()].next))) if _evolvable_id()!="" else ""),ready,s>=4.2)
        if ready:_glow(button,s);_touch(button.get_center(),s>=4.2,_p(s,3.7,4.0))
    else:
        _sparkle(slot.get_center(),_p(s,4.6,5.6))
        _label("▲",Rect2(slot.end.x-24,slot.position.y-24,24,22),18,GOOD)

func _evolvable_id() -> String:
    return _evolvable(str(sim.catalog.groups[int(sim.catalog.stages[0].groups[0])].weapon))

## The Snowman is defeated (the reset unlocks), an opportunity is ready, Prestige is confirmed, the permanent
## card joins the collection and a new run starts.
func _demo_prestige(s: float) -> void:
    _bg(s<2.4 or s>=6.6)
    if s<2.4:
        var boss:=Vector2(260,100)
        _enemy_at(boss,_snowman,.6 if fmod(s,.5)<.15 and s<1.8 else 0.0,1.0-_p(s,1.8,2.2))
        _bar(Rect2(220,52,80,8),1.0-_p(s,0,1.8),Color(1,.45,.35))
        var swing:=fmod(s,.5)/.5 if s<1.8 else 0.0
        _hero_at(Vector2(200,106),swing)
        _sparkle(boss,_p(s,1.8,2.4))
        if s>=2.0:_label("✓",Rect2(230,20,60,30),22,GOOD)
        return
    if s<6.6:
        var card:=Rect2(60,20,160,130)
        var fly:=_e(_p(s,4.8,5.8))
        var to:=Rect2(286,150,56,70)
        var r:=Rect2(card.position.lerp(to.position,fly),card.size.lerp(to.size,fly))
        for i in range(3):_slot(Rect2(230+i*58,150,52,66),null)
        _panel(r,Color(1,.86,.5))
        _tex(_snowman,r.get_center()+Vector2(0,-r.size.y*.12),r.size.y*.42)
        if fly<.5:_label("✓",Rect2(r.position+Vector2(0,r.size.y-30),Vector2(r.size.x,24)),18,GOOD)
        if s<4.8:
            _glow(card,s)
            var go:=Rect2(240,60,130,40)
            _button(go,tr("NAV_PRESTIGE"),true,s>=4.2)
            _touch(go.get_center(),s>=4.2,_p(s,3.2,3.6))
        else:_sparkle(to.get_center(),_p(s,5.8,6.6))
        return
    _tex(ui._art(249),Vector2(120,90),34)
    _hero_at(Vector2(170,110).lerp(Vector2(240,110),_e(_p(s,6.8,7.8))))
    _label(tr("ENEMY_LEVEL") % 1,Rect2(150,60,120,20),13,Color(.85,.9,1))
    _slot(Rect2(330,170,52,52),_snowman,"",Color(1,1,1,.9))

## Exploring raises the explored share; Map Details ranks add markers, names and loadouts; Map Mastery's
## categories fill to a completion reward.
func _demo_map_details_mastery(s: float) -> void:
    _bg(false)
    if s<4.8:
        var map:=Rect2(30,30,220,150)
        draw_rect(map,Color(.2,.29,.23));draw_rect(map,Color(.5,.56,.66),false,2)
        var explored:=_p(s,0,2.4)
        draw_rect(Rect2(map.position+Vector2(map.size.x*explored,0),Vector2(map.size.x*(1-explored),map.size.y)),Color(.03,.04,.06,.85))
        _tex(_hero,map.position+Vector2(map.size.x*explored-8,map.size.y*.6),18)
        _label(tr("MAP_EXPLORED") % int(20+40*explored),Rect2(30,186,220,22),13,Color(.85,.9,1))
        var rank:=int(_p(s,2.4,4.6)*3.0+.0001)
        _label(tr("UP_MAP_DETAIL"),Rect2(264,30,120,20),13,Color(1,.86,.5),HORIZONTAL_ALIGNMENT_LEFT)
        for i in range(3):
            draw_circle(Vector2(276+i*24,64),8,GOOD if i<rank else Color(.3,.33,.4))
        var dots:=[Vector2(70,70),Vector2(120,120),Vector2(170,80)]
        for i in range(dots.size()):
            var d:Vector2=map.position+dots[i]-Vector2(30,30)
            if rank>=1:draw_circle(d,6,Color(1,.4,.35));_ring(d,6,Color(0,0,0,.6),2)
            if rank>=2:draw_rect(Rect2(d+Vector2(-18,-20),Vector2(36,8)),Color(1,1,1,.75))
            if rank>=3:_tex(_weapon,d+Vector2(14,4),14)
        if s>=2.4 and s<3.1:_touch(Vector2(300,64),s>=2.7,1.0)
        return
    _label(tr("PANEL_MASTERY"),Rect2(20,8,360,24),16,Color(1,.86,.5))
    for i in range(MASTERY_ICONS.size()):
        var y:=42+i*32
        _tex(ui._art(MASTERY_ICONS[i]),Vector2(46,y+12),22)
        _bar(Rect2(70,y+6,240,12),_p(s,4.9+i*.35,5.9+i*.35),GOOD)
    var done:=_p(s,6.8,7.6)
    if done>0:
        _tex(GEM,Vector2(350,120),30*(.6+.4*done))
        _sparkle(Vector2(350,120),done)

## Tap a found spot on the map, Farm, the hero walks there and fights by itself; a joystick push stops it.
## The global unlock stays owned (MAX).
func _demo_advanced_farming(s: float) -> void:
    _bg()
    var spot:=Vector2(300,80)
    var start:=Vector2(90,170)
    var farm_on:=s>=1.9 and s<5.8
    var hero:=start
    if s>=2.0:hero=start.lerp(spot+Vector2(-34,8),_e(_p(s,2.0,3.6)))
    if s>=5.8:hero=(spot+Vector2(-34,8)).lerp(Vector2(160,190),_e(_p(s,5.9,7.2)))
    var swing:=fmod(maxf(0,s-3.7),.7)/.7 if s>=3.7 and s<5.6 else 0.0
    _ring(spot,30,Color(GOOD,.35+.25*sin(s*5)),3)
    _enemy_at(spot,_enemy_a,.8 if swing>.45 and swing<.7 else 0.0)
    _hero_at(hero,swing,spot-hero)
    if swing>0:_slash(spot+Vector2(-10,-4),_p(swing,.35,.75))
    var farm:=Rect2(20,16,200,34)
    _button(farm,tr("FOCUS_GROUP") % [_enemy_name,tr("ON" if farm_on else "OFF")],not farm_on,s>=1.5 and s<1.9)
    if farm_on:draw_rect(farm.grow(2),Color(GOOD,.8),false,2)
    _label(tr("UPGRADE_MAX"),Rect2(226,16,60,34),12,Color(.75,.8,.87))
    if s<.9:_ripple(spot,_p(s,.4,.9));_touch(spot,s>=.4,_p(s,0,.3))
    elif s<2.0:_touch(farm.get_center(),s>=1.5)
    var stick:=Vector2(330,196)
    var push:=_e(_p(s,5.6,5.9))*(1.0-_p(s,7.2,7.5))
    _stick(stick,Vector2(-24,6)*push,.9)
    if s>=5.4 and s<7.4:_touch(stick+Vector2(-24,6)*push,push>0)
