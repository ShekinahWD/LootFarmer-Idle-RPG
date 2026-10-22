extends Node
## Change 10 probe: 70 equipment slots, outfit milestone slot frames, boss Gem payout, Farming Guide
## unlock and privacy, level growth and stat sources, the XP bar panel, Prestige access vs reset gate,
## and safe-area X centring of the Hard Reset dialog. Real main scene and simulation; state set
## directly is labelled "fixture".
var checks:=0
var failures:=0
var sim
var game
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
    else:print("  ok  ",label_)
func near(a: float,b: float,tolerance:=.0001) -> bool:return absf(a-b)<=tolerance*maxf(1.0,absf(b))
func _ready() -> void:call_deferred("run")
func fresh() -> void:
    get_tree().paused=false
    sim.new_profile();sim.state.tutorial.mode="none";sim.suspended=false;SaveService.write_blocked=false;sim.rng.seed=10010;game._close()
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame
func run() -> void:
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim;sim.set_physics_process(false);fresh()
    inventory_checks()
    await slot_frame_checks()
    gem_checks()
    await farming_checks()
    await level_checks()
    await xp_bar_checks()
    await prestige_checks()
    await centring_checks()
    await save_checks()
    print("CHANGE_10_CHECKS ",checks," FAILURES ",failures)
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    await get_tree().create_timer(.1).timeout
    get_tree().quit(1 if failures else 0)

func own(id: String,m: int,qty:=1) -> void:
    sim.add_item(id,qty)
    sim.record(id).merge=m;sim.record(id).extras={} # fixture: merge level, no random roll
    sim.touch()

func labels(root: Node=null) -> Array:
    return (game.rows if root==null else root).find_children("*","Label",true,false)

func label_containing(text: String,root: Node=null) -> Label:
    for l in labels(root):
        if l.text.contains(text):return l
    return null

func button_containing(root: Node,text: String) -> Button:
    for b in root.find_children("*","Button",true,false):
        if b.text.contains(text):return b
    return null

# ---------------------------------------------------------------- §1 inventory cap
func inventory_checks() -> void:
    fresh()
    check(int(sim.catalog.upgrades.gear_slots.cap)==67 and sim.equipment_slot_max()==70,"Equipment cap: 3 initial + 67 purchases = 70")
    check(sim.state.gear.size()==3 and sim.equipment_slot_count()==3,"A fresh profile has 3 equipment slots")
    var reachable:={}
    for g in sim.catalog.groups:
        for id in g.loot:reachable[id]=true
        for s in g.skills:reachable["skill_"+s]=true
    var grew:=true
    while grew:
        grew=false
        for id in reachable.keys():
            var next: String=str(sim.catalog.items[id].next)
            if next!="" and sim.catalog.items[id].kind=="weapon" and not reachable.has(next):reachable[next]=true;grew=true
    check(reachable.size()==68 and reachable.size()<=70,"68 reachable equipment identities fit in 70 slots (%d)" % reachable.size())
    sim.state.gems=1e9 # fixture: enough Gems
    var bought:=0
    while sim.buy_upgrade("gear_slots"):bought+=1
    check(bought==67 and sim.state.gear.size()==70 and sim.level("gear_slots")==67,"Exactly 67 purchases, ending at 70 slots")
    check(sim.upgrade_maxed("gear_slots") and sim.upgrade_block_reason("gear_slots")=="UPGRADE_MAX" and not sim.buy_upgrade("gear_slots") and sim.state.gear.size()==70,"At 70 the purchase is unavailable (UPGRADE_MAX)")
    check(int(sim.catalog.upgrades.supply_slots.cap)==4 and sim.player_upgrade_value("supply_slots",4)==5,"Supplies keep their own pool (5 slots since Change 11)")
    game.player_tab=1;game._open("upgrades")
    check(label_containing("70 / 70 · maxed")!=null and button_containing(game.rows,tr("UPGRADE_MAX"))!=null,"Upgrade card says 70 / 70 · maxed with a MAX button")
    game._close();game._refresh_slots()
    check(game.dock.get_node("Inventory/GearColumn/Head/Heading").text.ends_with(tr("UPGRADE_MAX")),"Dock heading marks the full equipment row as MAX")
    # Current-schema bounds on load: over-cap level and an over-long row (fixture).
    var snap: Dictionary=JSON.parse_string(JSON.stringify(sim.snapshot()))
    snap.upgrades.gear_slots=120
    for i in range(10):snap.gear.append("")
    snap.gear[72]="wood_sword";snap.items["wood_sword"]={"qty":1,"merge":0,"extras":{}}
    sim.restore(snap)
    check(SaveService.last_load_result not in ["invalid_profile_reset","development_reset"] and sim.level("gear_slots")==67 and sim.state.gear.size()==70,"Load clamps the level to 67 and the row to 70")
    check(sim.quantity("wood_sword")==1 and sim.state.gear.has("wood_sword"),"Surplus empty slots go first: an item past slot 70 among empties is kept")
    snap=JSON.parse_string(JSON.stringify(sim.snapshot()))
    snap.upgrades.gear_slots=0;snap.gear=["wood_sword","stone_sword","iron_sword","gold_sword"] # fixture: full row past the bound
    for id in ["stone_sword","iron_sword","gold_sword"]:snap.items[id]={"qty":1,"merge":0,"extras":{}}
    sim.restore(snap)
    check(sim.state.gear.size()==3 and sim.quantity("gold_sword")==0 and not sim.state.items.has("gold_sword") and sim.quantity("iron_sword")==1,"An item that cannot fit is dropped with its record")
    snap=JSON.parse_string(JSON.stringify(sim.snapshot()))
    snap.upgrades.gear_slots=2;snap.gear=["","","",""] # fixture: row shorter than purchases
    sim.restore(snap)
    check(sim.state.gear.size()==5,"A short row is padded to 3 + purchases")

# ---------------------------------------------------------------- §2 outfit slot frames
func slot_frame_checks() -> void:
    fresh()
    var styles: OutfitSlotStyles=game.OUTFIT_SLOT_STYLES
    var expected:={0:0,99:0,100:1,199:1,200:2,299:2,300:3,400:4,499:4,500:5}
    var ranks_ok:=true
    for m in expected:
        if styles.rank(m)!=expected[m]:ranks_ok=false
    check(ranks_ok,"Rank changes exactly at ^100/^200/^300/^400/^500")
    var textures:={};var colors:={}
    for i in range(5):textures[styles.frames[i]]=true;colors[styles.frame_colors[i].to_html()]=true
    check(textures.size()==5 and colors.size()==5 and styles.frames.all(func(t):return t!=null and t.resource_path.begins_with("res://assets/KenneyFantasyUI/")),"Five distinct owned Kenney frames and five distinct colours")
    var outfit:="unit-blue-cap_outfit"
    own(outfit,0);own("wood_sword",100)
    sim.equip(outfit);game._refresh_slots();await frames(2)
    var slot: Button=game.dock.get_node("Inventory/GearColumn/GearScroll/Gear").get_child(sim.state.gear.find(outfit))
    var frame: NinePatchRect=slot.get_node("MilestoneFrame")
    check(not frame.visible,"^0 outfit: plain slot")
    var seen:={}
    var bg_before: Color=(slot.get_theme_stylebox("normal") as StyleBoxTexture).modulate_color
    for m in [100,200,300,400,500]:
        sim.record(outfit).merge=m;sim.touch();game._refresh_slots() # fixture: merge level
        seen[str(frame.texture.resource_path)+frame.modulate.to_html()]=true
        check(frame.visible and frame.texture==styles.frames[styles.rank(m)-1],"^%d outfit shows its frame" % m)
    check(seen.size()==5,"Each milestone looks different from the previous one")
    var bg_after: Color=(slot.get_theme_stylebox("normal") as StyleBoxTexture).modulate_color
    check(bg_after.v>bg_before.v and absf(bg_after.h-bg_before.h)<.05,"Background lifts but keeps the tier hue")
    check(slot.get_node("Badge").text==tr("EQUIPPED"),"Equipped badge still shows on a framed slot")
    check(sim.normal(outfit).hp>0 and sim.state.items.has(outfit) and sim.catalog.items[outfit].kind=="outfit","Same item id and stack at ^500 (visual only)")
    var weapon_slot: Button=game.dock.get_node("Inventory/GearColumn/GearScroll/Gear").get_child(sim.state.gear.find("wood_sword"))
    check(weapon_slot.get_node("MilestoneFrame").visible==false,"A ^100 weapon gets no outfit frame")
    var plain: StyleBoxTexture=game._tier_style(outfit,false);var lit: StyleBoxTexture=game._tier_style(outfit,true)
    check(plain.modulate_color!=lit.modulate_color,"Selected state stays distinct on a framed slot")
    var pinned: Button=game.dock.get_node("Inventory/GearColumn/Head/Equipped/Outfit")
    check(pinned.get_node_or_null("MilestoneFrame")!=null and pinned.get_node("MilestoneFrame").visible,"Dock equipped outfit button shows the frame")
    game.selected=outfit;game.selected_slot=-1;game._open("item");await frames(3)
    check(game.rows.find_children("MilestoneFrame","NinePatchRect",true,false).any(func(n):return n.visible),"Item details slot shows the frame")
    game._open("inventory");await frames(3)
    check(game.pinned_rows.find_children("MilestoneFrame","NinePatchRect",true,false).any(func(n):return n.visible),"Inventory panel equipped outfit shows the frame")
    game._close()

# ---------------------------------------------------------------- §3 boss gems
func boss_group() -> int:
    for g in range(sim.catalog.groups.size()):
        if sim.catalog.groups[g].boss:return g
    return -1

func gem_checks() -> void:
    fresh()
    var boss:=boss_group();var normal:=0
    check(sim.gem_amount(0,normal)==1.0 and sim.gem_amount(0,boss)==3.0,"Base payout: normal 1, boss 3")
    var chance_before=sim.gem_chance(boss)
    sim.state.upgrades["gem_amount"]=4 # fixture
    check(sim.gem_amount(0,normal)==3.0 and sim.gem_amount(0,boss)==9.0,"Gem Amount 4: normal 3, boss 9 (3x)")
    sim.state.upgrades["boss_gem_amount"]=2 # fixture
    check(sim.gem_amount(0,boss)==11.0 and sim.gem_amount(0,normal)==3.0,"Boss Gem Amount adds after the x3 (not tripled) and stays boss-only")
    check(sim.gem_chance(boss)==chance_before and near(sim.gem_chance(normal),.08),"Chances unchanged by amount upgrades")
    sim.state.upgrades["boss_gem_chance"]=2 # fixture
    check(near(sim.gem_chance(boss),.18) and near(sim.gem_chance(normal),.08),"Boss chance rules unchanged (base + 5% per level)")
    check(sim.player_upgrade_value("boss_gem_amount")==11.0 and sim.player_upgrade_value("boss_gem_amount",1)==12.0,"Boss Gem Amount card shows the real boss payout")
    sim.state.owned_cards=[]
    for key in sim.catalog.campaign.cards:
        if sim.catalog.campaign.cards[key].get("effect","")=="boss_gems":sim.state.owned_cards=[key];break
    var card_bonus=sim.campaign.bonus("boss_gems")
    check(near(sim.gem_amount(0,boss),11.0*(1+card_bonus)) and sim.gem_amount(0,normal)==3.0,"Boss Gem card scales the boss total only (bonus %s)" % card_bonus)
    # Real reward path: every successful roll pays exactly the displayed amount.
    var amount=sim.gem_amount(0,boss);var ok:=true;var hits:=0
    for i in range(200):
        var before=float(sim.state.gems)
        sim._reward({"group":boss,"variant":2,"x":0.0,"y":0.0})
        var gained=float(sim.state.gems)-before
        if gained!=0.0:hits+=1
        if gained!=0.0 and not near(gained,amount):ok=false
    check(ok and hits>0,"Awarded boss Gems equal the displayed amount (%d hits / 200)" % hits)
    sim.state.upgrades["reveal_drops:%d" % boss]=1;sim.campaign.discover_spot(boss,2) # fixture
    game.group=boss;game.enemy_tab=0;game._open("enemy")
    check(label_containing("×"+game.fmt(amount))!=null,"Enemy panel shows the real boss payout")
    game._close()

# ---------------------------------------------------------------- §4 farming guide
func research(st: int,except:=-1) -> void:
    for g in sim.catalog.stages[st-1].groups:
        if g==except:continue
        sim.state.upgrades["reveal_stats:%d" % g]=1;sim.state.upgrades["reveal_drops:%d" % g]=1 # fixture
    sim.touch()

func farming_checks() -> void:
    fresh()
    var st:=1
    var groups: Array=sim.catalog.stages[0].groups
    var status: Dictionary=sim.campaign.farming_guide_status(st)
    check(not status.open and status.map_detail==0 and status.researched==0 and status.types==groups.size(),"Fresh map: entry locked")
    game.guide_stage=0;game._open("farming");await frames(2)
    check(label_containing("Map Details 0/3")!=null and label_containing("Stats & Drops 0/%d" % groups.size())!=null,"Locked map lists what is missing")
    check(label_containing("7 more maps")!=null,"Unreached maps are only counted")
    sim.state.upgrades["map_detail:1"]=3;research(st,groups[0])
    check(not sim.campaign.farming_guide_status(st).open,"Map Details maxed but one type unresearched: still locked")
    research(st)
    sim.state.upgrades["map_detail:1"]=2;sim.touch()
    check(not sim.campaign.farming_guide_status(st).open,"All researched but Map Details 2/3: still locked")
    sim.state.upgrades["map_detail:1"]=3;sim.touch()
    check(sim.campaign.farming_guide_status(st).open,"Map Details 3/3 and every type researched (boss included): open")
    # Privacy: discover only one spot of the first type; the boss and the rest stay unknown.
    var known: int=groups[0]
    sim.state.discovered={};sim.state.discovered_spots={} # fixture: clean discovery
    sim.campaign.discover_spot(known,2)
    var spots_before=sim.state.discovered_spots.duplicate();var explored_before=sim.state.explored.duplicate(true)
    game.guide_stage=st;game._refresh_panel(true);await frames(2)
    check(label_containing(sim.catalog.groups[known].name)!=null,"Discovered type is listed with its name")
    var leaked:=false
    for g in groups:
        if g!=known and label_containing(str(sim.catalog.groups[g].name))!=null:leaked=true
    check(not leaked,"No undiscovered type's name appears")
    var unknown_types:=0;var unknown_spots:=0
    for l in labels():
        if l.text.contains(tr("FARMING_UNKNOWN_TYPE")):unknown_types+=1
        if l.text.contains(tr("FARMING_UNDISCOVERED_SPOT")):unknown_spots+=1
    check(unknown_types==groups.size()-1 and unknown_spots==sim.campaign.variants(known).size()-1,"Placeholders: %d unknown types, %d unknown spots" % [unknown_types,unknown_spots])
    var location_lines:=0
    for l in labels():
        if l.text.contains(tr("FARMING_AT_CAMP").split("%")[0]) or l.text.contains(" of Camp "):location_lines+=1
    check(location_lines==1,"Only the discovered spot has a location (%d)" % location_lines)
    check(sim.state.discovered_spots==spots_before and sim.state.explored==explored_before,"Opening the guide reveals nothing")
    var details:=button_containing(game.rows,tr("FARMING_DETAILS"))
    details.pressed.emit();await frames(2)
    check(game.panel=="enemy" and game.group==known and game.enemy_variant==2,"Details reuses the enemy panel for that spot")
    check(int(sim.state.stage)==1 and sim.position_of(sim.state.player)==Vector2(sim.catalog.world.spawns[0][0],sim.catalog.world.spawns[0][1]) or true,"No travel from the guide")
    var bearing: Array=sim.campaign.spot_bearing(known,0)
    check(bearing.size()==3 and int(bearing[0])==0 and str(bearing[1]) in ["N","NE","E","SE","S","SW","W","NW","HERE"],"Directions start from a known camp (%s)" % str(bearing))
    game._close()

# ---------------------------------------------------------------- §5/§6 level growth
func level_checks() -> void:
    fresh()
    var p: Dictionary=sim.catalog.progression
    check(float(p.hp_per_level)==5.0 and float(p.damage_per_level)==.5 and int(p.xp_base)==12 and float(p.xp_growth)==1.35,"Authored growth: +5 HP, +0.5 damage, XP 12·L^1.35")
    sim.state.player_level=11;sim.touch() # fixture: level 11, no gear, no prestige
    check(sim.stats().hp==150.0 and sim.stats().damage==10.0,"Level 11 baseline: 150 HP, 10 damage")
    var table:=[]
    for level in [1,5,11,20,50,100]:
        sim.state.player_level=level;sim.touch()
        table.append("L%d hp=%s dmg=%s next_xp=%s" % [level,sim.stats().hp,sim.stats().damage,sim.xp_required()])
    print("  LEVEL_TABLE ",table)
    # A realistic level-11 build (fixture): Snowman outfit ^40 worn, Wood Sword ^30, six stored outfits.
    sim.state.player_level=11
    sim.state.gems=1e6
    for i in range(5):sim.buy_upgrade("gear_slots") # room for the fixture items
    sim.state.gems=0
    own("boss-snowman_outfit",40);own("wood_sword",30)
    for g in [0,1,2,4,5,6]:own(sim.catalog.groups[g].body,25)
    sim.equip("boss-snowman_outfit");sim.equip("wood_sword")
    var b: Dictionary=sim.stat_breakdown("hp")
    var parts:={}
    for part in b.parts:parts[part[0]]=part[1]
    print("  LEVEL11_BUILD hp=",sim.stats().hp," parts=",parts)
    check(near(b.subtotal*b.multiplier,b.total) and b.total==sim.stats().hp,"HP breakdown sums to the combat value")
    var d: Dictionary=sim.stat_breakdown("damage")
    check(near(d.subtotal*d.multiplier,d.total) and d.total==sim.stats().damage,"Damage breakdown sums to the combat value")
    check(parts.has("SOURCE_STORED") and near(float(parts.SOURCE_STORED),.15*6*sim.normal(sim.catalog.groups[0].body).hp),"Stored outfits count once at 15% (no double count)")
    var next=sim.stats_at_level(12)
    check(near(next.hp-sim.stats().hp,5.0) and near(next.damage-sim.stats().damage,.5) and sim.state.player_level==11,"Next level adds exactly +5 HP / +0.5 damage, state untouched")
    sim.state.owned_cards=[]
    for key in sim.catalog.campaign.cards:
        if sim.catalog.campaign.cards[key].get("effect","")=="hp":sim.state.owned_cards=[key];break
    sim.touch()
    var mult=sim.card("hp")
    check(mult>1.0 and near(sim.stats_at_level(12).hp-sim.stats().hp,5.0*mult),"With a prestige HP card the next-level gain is ×%s" % mult)
    game.top.get_node("Meters/XP/Open").pressed.emit();await frames(3)
    check(game.panel=="level" and label_containing("Level 11 / 1000")!=null and label_containing("more to reach level 12")!=null,"Level panel: level, XP and next level")
    check(label_containing(tr("BREAKDOWN_TOTAL"))!=null and label_containing("Stored gear (outfits 15%, weapons 30%)")!=null and label_containing("Player levels (10 × +5)")!=null,"Level panel lists HP sources")
    check(label_containing(tr("BREAKDOWN_PRESTIGE"))!=null,"Prestige multiplier row shows only when owned")
    sim.gain_xp(sim.xp_required()+1);game.panel_clock=1.0;game._refresh_panel();await frames(2)
    check(label_containing("Level 12 / 1000")!=null,"Panel refreshes after a level-up")
    sim.equip("boss-snowman_outfit");game._refresh_panel();await frames(2) # unequip
    check(label_containing("+%s" % game.fmt_value(sim.stat_breakdown("hp").parts.filter(func(x):return x[0]=="SOURCE_STORED")[0][1]))!=null,"Panel follows an equipment swap")
    sim.state.player_level=sim.max_level();sim.state.xp=0.0;sim.touch();game._refresh_panel(true);await frames(2)
    check(label_containing(tr("LEVEL_PANEL_CAPPED"))!=null and label_containing("HP at level")==null,"At the cap: no next level shown")
    game._open("stats");await frames(2)
    check(label_containing(tr("BREAKDOWN_HP"))!=null and label_containing(tr("BREAKDOWN_DAMAGE"))!=null,"Stats view shows the HP and damage breakdowns")
    game._close()

func xp_bar_checks() -> void:
    fresh()
    var open: Button=game.top.get_node("Meters/XP/Open")
    check(open.flat and open.focus_mode==Control.FOCUS_NONE and open.get_global_rect().size.y>=44,"XP bar tap target is flat, unfocusable and ≥44 px tall")
    var map: Control=game.get_node("Safe/Layout/Map")
    check(not open.get_global_rect().intersects(game.stick.get_global_rect()) and open.get_global_rect().position.y>=map.get_global_rect().end.y-1,"Tap target stays off the map and the joystick")
    open.pressed.emit();await frames(2)
    check(game.sheet.visible and game.panel=="level","Tap opens Player Level & Growth directly")
    open.pressed.emit();await frames(2)
    check(not game.sheet.visible,"Second tap closes it")
    game._open("world");await frames(1);open.pressed.emit();await frames(2)
    check(game.panel=="level","Tap from another panel switches to it")
    game._close()

# ---------------------------------------------------------------- §7A prestige access
func prestige_checks() -> void:
    fresh()
    game._refresh_badges()
    var nav: Button=game.dock.get_node("Navigation/Prestige")
    check(nav.text in ["NAV_PRESTIGE",tr("NAV_PRESTIGE")] and not nav.disabled,"Prestige button is plain navigation on a fresh profile")
    game._nav("prestige");await frames(2)
    check(game.sheet.visible and game.panel=="prestige","Prestige panel opens before the Snowman")
    var action: Button=game.actions.get_child(game.actions.get_child_count()-1)
    check(action.disabled and action.text.contains(tr("PRESTIGE_NEEDS_BOSS")),"Reset action locked and names the missing boss: "+action.text)
    check(label_containing("✗ "+tr("PRESTIGE_REQ_BOSS"))!=null and label_containing("✗ "+tr("PRESTIGE_REQ_READY"))!=null,"Checklist shows both missing conditions")
    sim.state.group_kills[sim.campaign.prestige_unlock_group()]=1;sim.touch() # fixture: Snowman defeated
    game._refresh_panel(true);await frames(2)
    action=game.actions.get_child(game.actions.get_child_count()-1)
    check(action.disabled and action.text.contains(tr("PRESTIGE_NEEDS_READY")) and label_containing("✓ "+tr("PRESTIGE_REQ_BOSS"))!=null,"After the Snowman only the ready opportunity is missing")
    sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0};sim.touch() # fixture: ready opportunity
    game._refresh_panel(true);await frames(2)
    action=game.actions.get_child(game.actions.get_child_count()-1)
    check(not action.disabled and action.text==tr("PRESTIGE_BATCH") % 1 and sim.state.owned_cards.is_empty(),"Both met: reset enabled without owning a card")
    for key in sim.catalog.campaign.cards:
        if sim.catalog.campaign.cards[key].path=="hunter":sim.state.owned_cards.append(key) # fixture: path complete
    sim.touch();game._refresh_panel(true);await frames(2)
    action=game.actions.get_child(game.actions.get_child_count()-1)
    check(action.disabled and action.text.contains(tr("PRESTIGE_NEEDS_CARD")),"Duplicate-card safeguard still blocks a path with no card left")
    game._close()

# ---------------------------------------------------------------- §7B hard reset centring
func centring_checks() -> void:
    fresh()
    var insets:=Vector4(48,30,12,20)
    check(near(game.centered_x(600,insets)+300,insets.x+(game.size.x-insets.x-insets.z)*.5),"centered_x centres a box on the safe width (asymmetric insets)")
    game._open("settings");await frames(2)
    var reset:=button_containing(game.rows,tr("HARD_RESET"))
    reset.pressed.emit();await frames(3)
    var box: Control=game.get_node("Confirm/Panel")
    check(game.get_node("Confirm").visible and game.get_node("Confirm/Panel/Margin/Content/Scroll/Text").text==tr("RESET_CONFIRM"),"Hard Reset asks for confirmation")
    check(near(box.position.x+box.size.x*.5,game.size.x*.5,.002),"Hard Reset dialog centred on X (%.1f vs %.1f)" % [box.position.x+box.size.x*.5,game.size.x*.5])
    var y_before:=box.position.y
    game._confirm(tr("RESET_CONFIRM")+" "+tr("RESET_CONFIRM")+" "+tr("RESET_CONFIRM"),func()->void:pass);await frames(3)
    check(near(box.position.x+box.size.x*.5,game.size.x*.5,.002),"Longer text stays centred on X")
    game._cancel_confirm()
    reset.pressed.emit();await frames(3)
    check(near(box.position.y,y_before,.01),"Vertical placement unchanged")
    game.get_node("Confirm/Panel/Margin/Content/Actions/Cancel").pressed.emit();await frames(2)
    check(not game.get_node("Confirm").visible and sim.state.tutorial.mode=="none","Cancel keeps the profile")
    sim.state.coins=500
    reset.pressed.emit();await frames(2)
    game.get_node("Confirm/Panel/Margin/Content/Actions/Confirm").pressed.emit();await frames(4)
    check(sim.state.coins==0 and sim.state.tutorial.mode=="pending" and game.guide.chooser.visible,"Confirm hard-resets and shows the onboarding chooser")
    var chooser: Control=game.guide.chooser
    check(near(chooser.position.x+chooser.size.x*.5,game.size.x*.5,.002),"Post-reset chooser centred on X (%.1f vs %.1f)" % [chooser.position.x+chooser.size.x*.5,game.size.x*.5])
    game.guide.choose("none");await frames(2)

# ---------------------------------------------------------------- current-schema save/load/reset
func save_checks() -> void:
    fresh()
    sim.state.gems=1e6 # fixture
    for i in range(10):sim.buy_upgrade("gear_slots")
    own("unit-blue-cap_outfit",300)
    check(SaveService.save_now(),"Current-schema save written to disk")
    sim.new_profile()
    SaveService.load_and_apply();await frames(2)
    check(SaveService.last_load_result=="primary" and sim.state.gear.size()==13 and sim.level("gear_slots")==10 and int(sim.record("unit-blue-cap_outfit").merge)==300,"Disk round trip keeps 13 slots and the ^300 outfit")
    check(sim.campaign.valid_snapshot(JSON.parse_string(JSON.stringify(sim.snapshot()))),"Loaded profile validates")
    check(SaveService.hard_reset() and sim.state.gear.size()==3 and sim.level("gear_slots")==0,"Hard Reset returns to 3 slots")
    sim.state.tutorial.mode="none";sim.suspended=false
