extends Node
## Change 81 rendered desktop evidence (not Android validation): the global Camp reveal radius card and the Auto
## Skill lock, the World note and camp radius line, the Spring II HUD with the Boss Keys chip beside the followed
## objective pills, the Green Alien introduction, the sealed-boss notice, the boss-key pickup (floating and in
## flight), Ready to Challenge, an Obsidian Sword at ^220 with its milestones, and the level-500 panel.
## HUD shots run a bounds audit (the chip inside the map, its text inside the chip, no overlap with the left rail,
## the pills, the minimap or the joystick) and print AUDIT lines; failures print AUDIT_FAIL.
## Run windowed (432x960, 540x960; the monitor clamps taller windows):
##   godot --path . --resolution 432x960 res://tests/change_81_capture.tscn -- --probe --profile=probe-c81cap
##       --no-autosave --first-run-complete --shape=432x960 [--lang=de_DE]
## Output: generated/evidence/change_81/screens/<shape>[_<lang>]_<name>.png (ignored by Git).
var game
var sim
var shape:="540x960"
var lang:=""
var audit_failures:=0

func _ready() -> void:call_deferred("run")
func frames(n:=8) -> void:
    for i in range(n):await get_tree().process_frame

func shot(name_: String) -> void:
    await frames(4)
    var dir:="res://generated/evidence/change_81/screens/"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
    var file:=dir+shape+("_"+lang if lang!="" else "")+"_"+name_+".png"
    get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(file))
    print("SHOT ",file)

func fresh() -> void:
    get_tree().paused=false
    sim.new_profile();sim.set_physics_process(false);sim.suspended=false
    sim.state.tutorial.mode="none"
    sim.campaign.onboarding.reveal_all(true)
    sim.state.tutorial.seen.append("road_ahead")
    game._close();game._cancel_confirm()
    game.banner.queue.clear();game.banner._finish();game.toast_queue.clear();game.get_node("Toast").hide();game.toast_time=0.0
    game.key_fx.clear()

func gi(id: String) -> int:
    for g in range(sim.catalog.groups.size()):
        if sim.catalog.groups[g].id==id:return g
    return -1

func scroll_to(text: String,offset:=-30) -> void:
    var scroll: ScrollContainer=game.get_node("Sheet/Margin/Content/Scroll")
    for l in game.rows.find_children("*","Label",true,false):
        if str(l.text).contains(text):
            scroll.scroll_vertical=int(l.get_global_rect().position.y-scroll.get_global_rect().position.y+scroll.scroll_vertical)+offset
            break
    await frames(4)

func audit_hud(name_: String) -> void:
    var map: Control=game.get_node("Safe/Layout/Map")
    var chip: Control=map.get_node("FinalKeys")
    var problems: Array=[]
    if not chip.visible:problems.append("chip hidden")
    var r: Rect2=chip.get_global_rect()
    if not map.get_global_rect().encloses(r):problems.append("chip outside the map %s" % [r])
    for path in ["Row/Lines/Caption","Row/Lines/Value"]:
        var l: Label=chip.get_node(path)
        if not l.visible:continue
        var w: float=l.get_theme_font("font").get_string_size(l.text,HORIZONTAL_ALIGNMENT_LEFT,-1,l.get_theme_font_size("font_size")).x
        if w>l.get_global_rect().size.x+1 or not r.grow(1).encloses(l.get_global_rect()):problems.append("'%s' clipped (%.0f > %.0f)" % [l.text,w,l.get_global_rect().size.x])
    for other in ["EnemySection","Achievement","EnemyUpgrades","QuickFarm","FollowTracker","MissionTracker","MasteryTracker","MiniMap","Gate","Mastery","Joystick","ZoomButton"]:
        var n: Control=map.get_node_or_null(other)
        if n!=null and n.visible and n.get_global_rect().intersects(r.grow(-1)):problems.append("overlaps "+other)
    var skills: Control=game.get_node("Safe/Layout/Skills")
    if skills.visible and skills.get_global_rect().intersects(r):problems.append("overlaps the skill buttons")
    print("AUDIT %s %s chip=%s %s" % [shape+("_"+lang if lang!="" else ""),name_,r,"ok" if problems.is_empty() else "AUDIT_FAIL "+str(problems)])
    if not problems.is_empty():audit_failures+=1

func spring_two() -> void:
    sim.state.stage=8;sim.state.unlocked_stage=8;sim.campaign.configure_stage();sim._reset_world() # fixture: Spring II reached
    sim.state.camps["8"]=[0];sim.state.spawns=sim.state.camps["8"]

func near_boss(id: String) -> Dictionary:
    for a in sim.state.enemies:
        if int(a.group)==gi(id):
            sim.state.player.x=float(a.x)-70;sim.state.player.y=float(a.y)+40 # fixture: standing near the boss
            game.world.follow_player()
            return a
    return {}

func kill(id: String) -> void:
    var a: Dictionary=sim._actor("cap_%s" % id,sim.state.player.x+70,sim.state.player.y-40,1,gi(id)) # fixture: the boss falls here
    a["variant"]=2
    sim._kill(a)

func step_fx(seconds: float) -> void:
    var t:=0.0
    while t<seconds:
        game.key_fx._process(.05);t+=.05

func run() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--shape="):shape=arg.trim_prefix("--shape=")
        elif arg.begins_with("--lang="):lang=arg.trim_prefix("--lang=")
    SettingsState.mute_all_sfx()
    LocalizationService.set_test_device_locale("en_US")
    LocalizationService.select_language("automatic" if lang=="" else lang)
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    await frames(10)
    # 1. Upgrades > Player: the global Camp reveal radius (level 1) and Auto Skill slot 2 locked.
    fresh()
    sim.state.skills_seen=["heal"];sim.state.gems=500 # fixture
    sim.buy_upgrade("camp_radius");sim.buy_upgrade("skill_auto_slots")
    game.player_tab=0;game._open("upgrades");await frames(20)
    await scroll_to(tr("UP_CAMP_RADIUS"),-120)
    await shot("01_upgrades_camp_radius_auto_skill")
    # 2. World: the shared radius note in Map upgrades; 3. the camp panel's radius line.
    game._close()
    game._open("world");await frames(20)
    await scroll_to(tr("CAMP_RADIUS_GLOBAL_NOTE").get_slice(":",0),-260)
    await shot("02_world_camp_radius_note")
    game._close()
    game.selected_camp=0;game._open("camp");await frames(20)
    await shot("03_camp_panel_radius")
    game._close()
    # 4. Spring II HUD: Boss Keys 4/13 under Next Stage, three followed pills on the left.
    fresh()
    spring_two()
    sim.state.final_discovered=true;sim.state.tutorial.seen.append("final_intro")
    sim.state.keys=["boss-snowman","boss-cyan-robot","boss-gray-cat","boss-elephant"] # fixture: 4 keys
    sim.state.follow_mastery="8:explore" # fixture: followed objectives
    sim.state.follow="hunter_o1";sim.state.opportunities["hunter_o1"]={"ready":false,"baseline":{},"step":0,"count":0}
    sim.state.follow_mission=sim.campaign.mission_follow_key("main",0)
    sim.touch()
    game.elapsed=1.0;await frames(20)
    audit_hud("04_hud")
    await shot("04_hud_boss_keys_pills")
    # 5. The introduction (first discovery).
    sim.state.tutorial.seen.erase("final_intro")
    game._final_intro_check();await frames(20)
    await shot("05_intro_not_worthy")
    game.banner.queue.clear();game.banner._finish()
    # 6. A tap on the sealed Green Alien.
    for a in sim.state.enemies:
        if bool(sim.catalog.groups[int(a.group)].final):
            sim.state.player.x=float(a.x)-50;sim.state.player.y=float(a.y)+20;game.world.follow_player() # fixture: next to it
            sim.campaign.reveal()
            print("SEALED_TAP refused=%s" % str(not sim.select_target(str(a.id))))
    for i in range(4):game._update_toast(.1)
    game.elapsed=1.0;await frames(20)
    await shot("06_sealed_notice")
    # 7. A new key: floating over the fallen boss, then in flight to the chip.
    fresh()
    spring_two()
    sim.state.final_discovered=true;sim.state.tutorial.seen.append("final_intro")
    sim.state.keys=["boss-snowman","boss-cyan-robot","boss-gray-cat","boss-elephant"]
    near_boss("boss-red-panda")
    game.elapsed=1.0;await frames(20)
    kill("boss-red-panda")
    step_fx(.9);await frames(2)
    game.elapsed=1.0;await frames(2)
    audit_hud("07_key_float")
    await shot("07_key_floating")
    step_fx(1.95);await frames(1)
    await shot("08_key_flying")
    step_fx(1.0);await frames(6)
    await shot("09_key_landed_5_of_13")
    # 8. The 13th key: Ready to Challenge.
    var all: Array=[]
    for d in sim.catalog.groups:
        if d.boss and not d.final and str(d.id)!="boss-sunflower":all.append(str(d.id))
    sim.state.keys=all # fixture: 12 keys
    near_boss("boss-sunflower")
    kill("boss-sunflower")
    step_fx(4.0)
    for i in range(4):game._update_toast(.1)
    game.elapsed=1.0;await frames(20)
    audit_hud("10_ready")
    await shot("10_ready_to_challenge")
    # 9. An Obsidian Sword at ^220 (milestones), 10. the level-500 panel.
    fresh()
    sim.add_item("obsidian_sword",3);sim.record("obsidian_sword").merge=220;sim.record("obsidian_sword").extras={} # fixture
    sim.equip("obsidian_sword")
    game.selected="obsidian_sword";game.selected_slot=-1;game._open("item");await frames(20)
    await shot("11_obsidian_sword_220")
    game._close()
    sim.state.player_level=500;sim.state.xp=0.0;sim.touch() # fixture: at the cap
    game._open("level");await frames(20)
    game.elapsed=1.0;await frames(4)
    await shot("12_level_500")
    print("CHANGE_81_CAPTURE complete shape=%s audit_failures=%d" % [shape,audit_failures])
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    get_tree().quit(1 if audit_failures>0 else 0)
