extends Node
## Change 78 focused checks (real main scene and simulation; state set directly is labelled "fixture"):
## 1. Enemy skill priority: an enemy comes back from death with a fresh skill turn (no leftover cooldown,
##    telegraph or rotation position: the root cause); its first eligible skill acts before any normal attack,
##    after every respawn; conditions (Heal threshold, Focus in combat), reach and cooldowns are respected;
##    a boss starts no normal attack while its skill is telegraphed.
## 2. Merge preview: sim.merge_preview equals the real change of each core stat after one merge (weapons and
##    outfits, the stock bonus at the cap, one copy); empty at the cap; the item panel shows the gain in green
##    beside each stat and no separate "Next merge" line for gear (skills keep theirs).
## 3. Text filtering: labels draw their MSDF text with linear filtering; theme pixel frames stay nearest
##    (CanvasTexture); the world's supply name and boss timer labels use the game theme's MSDF font.
## 4. Boss gear: boss outfit drops are enhanced like weapons (two attributes, first copy only, reroll, merge,
##    disk save/reload); the one-time migration enhances owned boss outfits and marks boss outfits on the ground.
## 5. Boss automation prices: Auto-Collect and Auto-Merge cost at least 70% less on every boss type; normal types
##    and the other automation upgrades keep their prices; bought levels stay through a save/reload.
## Run: Godot --headless --path . res://tests/change_78_probe.tscn -- --probe --profile=probe-c78 --no-autosave --first-run-complete
var checks:=0
var failures:=0
var game
var sim
var log_: Array=[]

func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
    else:print("  ok  ",label_)
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame
func _ready() -> void:call_deferred("run")

func run() -> void:
    SettingsState.mute_all_sfx()
    TranslationServer.set_locale("en")
    get_window().size=Vector2i(720,1280)
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.spell_cast.connect(func(actor: String,key: String,_p: Vector2)->void:log_.append("cast:%s:%s" % [actor,key]))
    sim.skill_warning.connect(func(actor: String,key: String,_p: Vector2)->void:log_.append("warn:%s:%s" % [actor,key]))
    await frames(6)
    skill_priority_checks()
    merge_preview_checks()
    await merge_preview_ui_checks()
    await text_filter_checks()
    boss_gear_checks()
    await boss_gear_persistence_checks()
    await migration_checks()
    await price_checks()
    print("CHANGE_78_CHECKS %d FAILURES %d" % [checks,failures])
    game.queue_free();await frames(2);AudioService.stop_all_sfx()
    get_tree().quit(1 if failures>0 else 0)

func fresh() -> void:
    get_tree().paused=false
    sim.held=false
    sim.new_profile();sim.set_physics_process(false);sim.suspended=false;SaveService.write_blocked=false
    sim.state.tutorial.mode="none"
    sim.campaign.onboarding.reveal_all(true)
    sim.state.tutorial.seen.append("road_ahead")
    game._close();game.banner.queue.clear();game.banner._finish();game.toast_queue.clear();game.toast_important.clear();game.get_node("Toast").hide();game.toast_time=0.0
    log_.clear()

func gi(id: String) -> int:return sim.campaign.group_id(id)

# ---------------------------------------------------------------- 1. Enemy skill priority
## A lone enemy of `type` (variant), `dist` px east of the player, everything else removed (fixture).
func lone(type: String,variant: int,dist: float) -> Dictionary:
    var g:=gi(type)
    var p: Dictionary=sim.state.player
    p.x=600.0;p.y=600.0;p.hp=1e9 # fixture: an unkillable hero standing still
    var d: Dictionary=sim.enemy_definition(g,variant)
    var e: Dictionary=sim._actor("probe-"+type,p.x+dist,p.y,float(d.hp),g)
    e.variant=variant
    sim.state.enemies=[e] # fixture: only this enemy on the map
    sim.state.boss_respawns={}
    return e

## Steps the world; the hero never swings (fixture), so the enemy's own actions are all that happen.
## Returns the ordered actions of `e`: "attack" (a normal attack started), "warn:<skill>", "cast:<skill>".
func run_for(e: Dictionary,seconds: float,hold:=true) -> Array:
    var out: Array=[]
    log_.clear()
    var t:=0.0
    while t<seconds:
        if hold:sim.state.player.cooldown=99.0;e.quiet=0.0 # fixture: in a fight (no out-of-combat regeneration)
        sim.state.player.hp=1e9
        var age: float=float(e.get("attack_age",9.0))
        sim.step(.05)
        t+=.05
        for entry in log_:
            var part: PackedStringArray=str(entry).split(":")
            if part[1]==str(e.id):out.append(part[0]+":"+part[2])
        log_.clear()
        if float(e.get("attack_age",9.0))<age:out.append("attack")
    return out

func first_index(actions: Array,prefix: String) -> int:
    for i in range(actions.size()):
        if str(actions[i]).begins_with(prefix):return i
    return 999

func skill_priority_checks() -> void:
    print("-- 1. Enemy skill priority")
    fresh()
    # Root cause: a skill-variant enemy dies with most of its 20 s cooldown left and comes back with it.
    var e:=lone("unit-yellow-cap",3,20.0)
    e.aggro=true
    e.skill_timer=15.0;e.skill_index=1;e.telegraph=true;e.pending="lightning" # fixture: state from its previous life
    e.hp=0.0;e.respawn=0.0;e.dead_age=5.0 # fixture: dead, respawn due now
    sim.step(.05)
    check(float(e.hp)>0 and float(e.skill_timer)==0.0 and int(e.skill_index)==0 and not bool(e.telegraph) and str(e.pending)=="","A respawned enemy starts with a fresh skill turn (no leftover cooldown, telegraph or rotation)")
    # First eligible skill before any normal attack, from the first hit on a passive enemy.
    e.aggro=true
    var actions:=run_for(e,3.0)
    check(first_index(actions,"cast:lightning")<first_index(actions,"attack"),"After respawn its skill (Lightning) comes before its first normal attack %s" % str(actions.slice(0,4)))
    check(first_index(actions,"attack")<999,"…and normal attacks follow")
    # Cooldown respected: no second cast within the catalog's 20 s.
    var later:=run_for(e,15.0)
    check(later.count("cast:lightning")==0 and later.count("attack")>=5,"No second cast before its 20 s cooldown; normal attacks fill the gap")
    var much:=run_for(e,6.0)
    check(much.count("cast:lightning")==1,"The skill returns once its cooldown is over")
    # Every respawn: kill it twice more, each life opens with its skill.
    var ok:=true
    for i in range(2):
        e.hp=0.0;e.respawn=0.0;e.dead_age=5.0 # fixture: killed mid-cooldown
        sim.step(.05);e.aggro=true
        var life:=run_for(e,2.5)
        ok=ok and first_index(life,"cast:")<first_index(life,"attack")
    check(ok,"Consistent after every respawn")
    # Reach: an attack skill out of reach waits without spending its turn; no normal attack meanwhile.
    fresh()
    e=lone("unit-yellow-cap",3,200.0)
    e.home_x=e.x;e.home_y=e.y
    e.aggro=true
    var far:=run_for(e,.2)
    check(far.is_empty() and float(e.skill_timer)==0.0,"Out of reach (200 px > Lightning's 120): no cast and the skill turn is not spent")
    var closing:=run_for(e,4.0)
    check(first_index(closing,"cast:lightning")<first_index(closing,"attack"),"Walking into reach, it casts before its first normal attack %s" % str(closing.slice(0,3)))
    # Conditions: a boss with Heal and Focus at full HP passes over Heal and uses Focus in combat.
    fresh()
    e=lone("boss-squirrel",2,20.0)
    e.aggro=true
    var boss:=run_for(e,3.0)
    check(first_index(boss,"cast:focus")<first_index(boss,"attack") and boss.count("cast:heal")==0,"Squirrel at full HP: Heal is passed over, Focus comes first %s" % str(boss.slice(0,3)))
    check(int(e.skill_index)%2==0,"…and the rotation moves on to Heal for its next turn")
    e.hp=float(sim.enemy_definition(gi("boss-squirrel"),2).hp)*.5 # fixture: wounded
    var heal:=run_for(e,11.0)
    check(heal.has("cast:heal"),"Wounded, its next turn after the 10 s boss cooldown is Heal")
    # Telegraph: a boss announces an attack skill and starts no normal attack until it resolves.
    fresh()
    e=lone("boss-gray-cat",2,20.0)
    e.aggro=true
    var tele:=run_for(e,2.0)
    var warn:=first_index(tele,"warn:lightning")
    var cast:=first_index(tele,"cast:lightning")
    var attack:=first_index(tele,"attack")
    check(warn<attack and cast<attack and cast<999,"Gray Cat: warning, then Lightning, then its first normal attack %s" % str(tele.slice(0,4)))
    var cycle:=run_for(e,21.0)
    check(cycle.count("cast:lightning")==2,"Boss skill every 10 s (two in 21 s: %d)" % cycle.count("cast:lightning"))
    # A boss's leftover cooldown is cleared by its respawn too.
    e.skill_timer=8.0;e.hp=0.0;e.respawn=0.0;e.dead_age=5.0 # fixture: defeated mid-cooldown
    sim.step(.05)
    check(float(e.skill_timer)==0.0,"A boss respawns with its skill ready")

# ---------------------------------------------------------------- 2. Merge preview
func preview_matches(id: String) -> bool:
    var preview: Dictionary=sim.merge_preview(id)
    var before: Dictionary=sim.normal(id)
    if preview.is_empty() or not sim.merge(id):return false
    var after: Dictionary=sim.normal(id)
    for stat in before:
        if absf((float(after[stat])-float(before[stat]))-float(preview.get(stat,0.0)))>1e-6:return false
    return true

func merge_preview_checks() -> void:
    print("-- 2. Merge preview (simulation)")
    fresh()
    sim.add_item("wood_sword",4)
    check(sim.merge_preview("wood_sword").has("damage") and float(sim.merge_preview("wood_sword").damage)>0,"A weapon previews its Damage gain")
    check(preview_matches("wood_sword"),"Weapon: the preview equals the real change after one merge")
    sim.add_item("unit-blue-cap_outfit",4)
    check(preview_matches("unit-blue-cap_outfit"),"Outfit: the preview equals the real change after one merge")
    # The merge that reaches the cap adds the stock bonus of the copies left.
    var cap: int=sim.merge_cap("wood_sword")
    sim.state.items.wood_sword.merge=cap-1;sim.state.items.wood_sword.qty=6 # fixture: one merge from the cap
    check(preview_matches("wood_sword"),"At cap − 1 the preview includes the stock bonus of the copies left")
    check(sim.merge_preview("wood_sword").is_empty(),"At the merge cap there is no preview")
    var ocap: int=sim.merge_cap("unit-blue-cap_outfit")
    sim.state.items["unit-blue-cap_outfit"].merge=ocap-1;sim.state.items["unit-blue-cap_outfit"].qty=3 # fixture
    check(preview_matches("unit-blue-cap_outfit") and sim.merge_preview("unit-blue-cap_outfit").is_empty(),"Outfit at cap − 1 matches, and has none at its cap")
    # One copy: the gain of the merge the next copy allows.
    sim.add_item("stone_sword",1)
    var single: Dictionary=sim.merge_preview("stone_sword")
    sim.add_item("stone_sword",1)
    var before: Dictionary=sim.normal("stone_sword")
    sim.merge("stone_sword")
    check(absf(float(sim.normal("stone_sword").damage)-float(before.damage)-float(single.damage))<1e-6,"With one copy it previews the merge the next copy allows")
    check(sim.merge_preview("skill_heal").is_empty() and sim.merge_preview("potion").is_empty(),"Skills and supplies have no gear preview")

func gains_in_panel() -> Array:
    var out: Array=[]
    for n in game.rows.find_children("MergeGain","RichTextLabel",true,false):out.append(str(n.text))
    return out

func next_merge_lines() -> int:
    var n:=0
    for l in game.rows.find_children("*","Label",true,false):
        if str(l.text).begins_with(tr("NEXT_MERGE_GAIN")):n+=1
    return n

func merge_preview_ui_checks() -> void:
    print("-- 2. Merge preview (item panel)")
    fresh()
    sim.add_item("wood_sword",3);sim.equip("wood_sword")
    game.selected="wood_sword";game._open("item");await frames(3)
    var gains:=gains_in_panel()
    var expected: String="+"+game.fmt(float(sim.merge_preview("wood_sword").damage))
    check(gains.size()==1 and gains[0].contains(tr("STAT_DAMAGE")) and gains[0].contains(expected),"Weapon: the Damage row carries its gain %s %s" % [expected,str(gains)])
    check(gains.size()==1 and gains[0].contains("[color=#"+game.MERGE_GAIN_COLOR.to_html(false)+"]"+expected),"…in green")
    check(next_merge_lines()==0,"No separate Next merge line for a weapon")
    sim.add_item("unit-blue-cap_outfit",3)
    game.selected="unit-blue-cap_outfit";game._open("item");await frames(3)
    gains=gains_in_panel()
    check(gains.size()==1 and gains[0].contains(tr("STAT_HP")) and next_merge_lines()==0,"Outfit: Maximum health row carries its gain, no Next merge line %s" % str(gains))
    sim.state.items.wood_sword.merge=sim.merge_cap("wood_sword") # fixture: at the cap
    game.selected="wood_sword";game._open("item");await frames(3)
    check(gains_in_panel().is_empty() and next_merge_lines()==0,"At the merge cap no gain is shown")
    sim.add_item("skill_heal",2)
    game.selected="skill_heal";game._open("item");await frames(3)
    check(next_merge_lines()==1,"A skill (no stat rows) keeps its one-line next-merge summary")
    # Not equipped (comparison card): both the merge gain and the comparison arrow fit at phone width.
    sim.state.gems=1000.0 # fixture
    check(sim.buy_upgrade("gear_slots"),"Buy a fourth gear slot")
    check(sim.add_item("stone_sword",2),"A stored Stone Sword (fixture)")
    game.selected="stone_sword";game._open("item");await frames(3)
    var sheet: Control=game.get_node("Sheet")
    var found: Array=game.rows.find_children("MergeGain","RichTextLabel",true,false)
    check(found.size()==1 and found[0].get_global_rect().end.x<=sheet.get_global_rect().end.x+.5,"Comparison card: the gain row is shown and stays inside the sheet")
    game._close()

# ---------------------------------------------------------------- 3. Text filtering
func text_filter_checks() -> void:
    print("-- 3. Text filtering")
    fresh()
    sim.add_item("potion",3)
    game.selected="potion";game._open("item");await frames(3)
    var labels: Array=game.find_children("*","Label",true,false)
    var linear:=labels.filter(func(l):return l.texture_filter==CanvasItem.TEXTURE_FILTER_LINEAR)
    check(labels.size()>50 and linear.size()==labels.size(),"Every label draws linear (%d of %d)" % [linear.size(),labels.size()])
    var title: Label=game.get_node("Sheet/Margin/Content/Header/Title")
    check(title.text==sim.catalog.display_name("potion") and title.texture_filter==CanvasItem.TEXTURE_FILTER_LINEAR,"The supply name title draws linear")
    var base: Font=title.get_theme_font("font")
    while base is FontVariation:base=(base as FontVariation).base_font
    check(base is FontFile and (base as FontFile).multichannel_signed_distance_field,"…with the MSDF theme font")
    var buttons: Array=game.find_children("*","Button",true,false)
    check(buttons.all(func(b):return b.texture_filter!=CanvasItem.TEXTURE_FILTER_LINEAR),"Buttons keep nearest (their item icons are atlas regions)")
    var wrapped:=0;var frames_:=0
    for type in game.theme.get_stylebox_type_list():
        for name in game.theme.get_stylebox_list(type):
            var box:=game.theme.get_stylebox(name,type) as StyleBoxTexture
            if box==null or box.texture is AtlasTexture:continue
            frames_+=1
            if box.texture is CanvasTexture and (box.texture as CanvasTexture).texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST:wrapped+=1
    check(frames_>10 and wrapped==frames_,"Theme pixel frames keep nearest filtering (%d of %d)" % [wrapped,frames_])
    var chip:=game.theme.get_stylebox("normal","HudChipLabel") as StyleBoxTexture
    check(chip!=null and chip.texture is CanvasTexture,"The HUD chip label's frame stays pixel-sharp")
    var fx: Label=game.world.supply_fx.label
    var fx_font: Font=fx.get_theme_font("font")
    while fx_font is FontVariation:fx_font=(fx_font as FontVariation).base_font
    check(fx_font is FontFile and (fx_font as FontFile).multichannel_signed_distance_field and fx.texture_filter==CanvasItem.TEXTURE_FILTER_LINEAR,"The world's supply name uses the MSDF theme font (was the engine's raster fallback)")
    game._close()

# ---------------------------------------------------------------- 4. Boss gear
func boss_drop(item: String,boss: String) -> int:
    sim._drop(item,{"group":gi(boss),"x":200.0,"y":200.0})
    return int(sim.state.pickups.back().uid)

func boss_gear_checks() -> void:
    print("-- 4. Boss gear attributes")
    fresh()
    var uid:=boss_drop("boss-snowman_outfit","boss-snowman")
    check(bool(sim.state.pickups.back().get("enhanced",false)),"A boss's outfit drop is marked enhanced")
    check(sim.collect(uid) and sim.boss_extras("boss-snowman_outfit").size()==2,"Collected: the outfit has two boss attributes")
    var stats: Array=sim.state.items["boss-snowman_outfit"].extras.keys()
    for e in sim.boss_extras("boss-snowman_outfit"):stats.append(str(e.stat))
    check(stats.size()==3 and stats.all(func(s):return stats.count(s)==1),"No stat repeats across its base and boss slots %s" % str(stats))
    var ok:=true
    for e in sim.boss_extras("boss-snowman_outfit"):
        var span: Array=sim.catalog.items["boss-snowman_outfit"].extras[str(e.stat)]
        ok=ok and float(e.value)>=float(span[0]) and float(e.value)<=float(span[1])
    check(ok,"Values within the outfit's ranges")
    var before:=JSON.stringify(sim.boss_extras("boss-snowman_outfit"))
    check(sim.collect(boss_drop("boss-snowman_outfit","boss-snowman")) and JSON.stringify(sim.boss_extras("boss-snowman_outfit"))==before and sim.quantity("boss-snowman_outfit")==2,"A second boss copy is an ordinary copy")
    check(sim.merge("boss-snowman_outfit") and JSON.stringify(sim.boss_extras("boss-snowman_outfit"))==before,"Merging keeps the attributes")
    sim.equip("boss-snowman_outfit")
    var total: Dictionary=sim.bonus_attributes("boss-snowman_outfit")
    var src: Dictionary=sim.stat_sources()["SOURCE_EQUIPPED"]
    var counted:=true
    for k in total:counted=counted and float(src.get(k,0))>=float(total[k])-1e-6
    check(counted,"Equipped, the boss attributes count in the stats")
    sim.state.gems=100000
    var slots: Array=sim.reroll_slots("boss-snowman_outfit")
    var boss_slot: int=slots.find(["boss",0])
    check(boss_slot>=0 and sim.reroll("boss-snowman_outfit",boss_slot) and sim.boss_extras("boss-snowman_outfit").size()==2,"A boss slot rerolls on its own")
    # Weapons unchanged; a normal enemy's outfit drop is not enhanced; a direct grant never is.
    boss_drop("wood_axe","boss-snowman")
    check(bool(sim.state.pickups.back().get("enhanced",false)),"Boss weapons are still enhanced")
    sim._drop("unit-blue-cap_outfit",{"group":gi("unit-blue-cap"),"x":0.0,"y":0.0})
    check(not sim.state.pickups.back().has("enhanced"),"A normal enemy's outfit is not")
    sim.add_item("boss-cyan-robot_outfit",1)
    check(sim.boss_extras("boss-cyan-robot_outfit").is_empty(),"A copy added directly (offline grant) is not enhanced")
    check(sim.campaign.valid_snapshot(sim.save_snapshot()),"The snapshot with an enhanced outfit validates")

func boss_gear_persistence_checks() -> void:
    print("-- 4. Boss gear: save and reload")
    fresh()
    sim.collect(boss_drop("boss-gray-cat_outfit_t2","boss-gray-cat"))
    var kept:=JSON.stringify(sim.boss_extras("boss-gray-cat_outfit_t2"))
    var uid:=boss_drop("boss-gray-cat_outfit_t2","boss-gray-cat")
    boss_drop("boss-elephant_outfit_t2","boss-elephant")
    check(SaveService.save_now(),"Disk save")
    sim.state.items={} # fixture: in-memory change the reload must undo
    SaveService.load_and_apply();await frames(2)
    check(JSON.stringify(sim.boss_extras("boss-gray-cat_outfit_t2"))==kept,"Reload keeps the outfit's boss attributes")
    check(bool(sim.state.pickups.back().get("enhanced",false)),"A boss outfit on the ground keeps its origin")
    check(sim.collect(int(sim.state.pickups.back().uid)) and sim.boss_extras("boss-elephant_outfit_t2").size()==2,"…and enhances when collected after the reload")
    check(sim.collect(uid) and JSON.stringify(sim.boss_extras("boss-gray-cat_outfit_t2"))==kept,"A later copy of an enhanced outfit adds nothing")

func migration_checks() -> void:
    print("-- 4. Migration of existing boss outfits")
    fresh()
    check(sim.state.migrations.has("boss_outfit_extras"),"A new profile records the migration as done")
    sim.add_item("boss-snowman_outfit",3);sim.state.items["boss-snowman_outfit"].merge=4 # fixture: owned before this change
    sim.add_item("unit-blue-cap_outfit",2) # fixture: an ordinary outfit
    sim.add_item("wood_axe",1) # fixture: a weapon of unknown origin
    sim._drop("boss-cyan-robot_outfit",{"group":gi("boss-cyan-robot"),"x":0.0,"y":0.0});sim.state.pickups.back().erase("enhanced") # fixture: dropped by an older build
    sim.state.migrations.erase("boss_outfit_extras") # fixture: a save from before Change 78
    check(SaveService.save_now(),"Disk save of the older profile")
    SaveService.load_and_apply();await frames(2)
    check(sim.boss_extras("boss-snowman_outfit").size()==2,"The owned boss outfit receives its two attributes")
    check(int(sim.state.items["boss-snowman_outfit"].merge)==4 and sim.quantity("boss-snowman_outfit")==3 and sim.state.items["boss-snowman_outfit"].extras.size()==1,"Its merge level, copies and base attribute are unchanged")
    check(sim.boss_extras("unit-blue-cap_outfit").is_empty() and sim.boss_extras("wood_axe").is_empty(),"Ordinary outfits and weapons are not touched")
    check(bool(sim.state.pickups.back().get("enhanced",false)),"A boss outfit on the ground is marked")
    check(sim.state.migrations.has("boss_outfit_extras"),"The migration is recorded")
    var once:=JSON.stringify(sim.boss_extras("boss-snowman_outfit"))
    SaveService.load_and_apply();await frames(2)
    check(JSON.stringify(sim.boss_extras("boss-snowman_outfit"))==once,"Loading again changes nothing")

# ---------------------------------------------------------------- 5. Boss automation prices
func price_checks() -> void:
    print("-- 5. Boss automation prices")
    fresh()
    var ok:=true
    var lines: Array=[]
    for g in range(sim.catalog.groups.size()):
        var d: Dictionary=sim.catalog.groups[g]
        var factor:=1.0+.25*(int(d.stage)-1)
        var old_collect:=ceili(20*factor);var old_merge:=ceili(30*factor)
        var c: int=sim.upgrade_cost("collect",g);var m: int=sim.upgrade_cost("merge_gear",g)
        if d.boss:
            ok=ok and c<=old_collect*.3 and m<=old_merge*.3
            lines.append("%s %d->%d %d->%d" % [d.id,old_collect,c,old_merge,m])
        else:
            ok=ok and c==old_collect and m==old_merge
    check(ok,"Every boss: both unlocks at least 70% cheaper; every normal type unchanged")
    print("     ",", ".join(lines.slice(0,3)))
    var b:=gi("boss-red-panda")
    var others:=true
    for id in ["collect_range","collect_batch","collect_speed","gear_merge_speed","auto_evolve","boss_item_rolls","boss_spawn_cooldown"]:
        var u: Dictionary=sim.catalog.upgrades[id]
        others=others and not u.has("boss_price_factor")
    check(others and sim.upgrade_cost("collect_batch",b)==ceili(50*(1+.25*7)),"Other automation upgrades keep their prices")
    sim.state.upgrades["collect:%d" % b]=1;sim.state.upgrades["merge_gear:%d" % b]=1 # fixture: bought at the old price
    check(SaveService.save_now(),"Disk save")
    SaveService.load_and_apply();await frames(2)
    check(sim.level("collect",b)==1 and sim.level("merge_gear",b)==1 and sim.upgrade_maxed("collect",b) and sim.upgrade_maxed("merge_gear",b),"Levels bought earlier stay bought (and maxed)")
    sim.state.gems=100.0
    var a:=gi("boss-snowman")
    sim.campaign.discover_spot(a,2) # fixture: the Snowman has been found
    check(sim.buy_upgrade("collect",a) and is_equal_approx(float(sim.state.gems),95.0),"Snowman Auto-Collect now costs 5 Gems")
    check(sim.buy_upgrade("merge_gear",a) and is_equal_approx(float(sim.state.gems),87.0),"Snowman Auto-Merge now costs 8 Gems")
