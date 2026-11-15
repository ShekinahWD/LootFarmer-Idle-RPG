extends Node
## Change 80 rendered desktop evidence (not Android validation): the World panel's stage selector in four states,
## the camp panel's Camp Supplies cooldown line, the Camp Supplies toast and the Regional Prestige choice. Each
## stage-selector shot also runs a bounds audit (every label inside its card, cards in order without overlap,
## tap height >= 56, the list inside the sheet's width) and prints AUDIT lines; failures print AUDIT_FAIL.
## Run windowed (432x960, 540x960; the monitor clamps taller windows):
##   godot --path . --resolution 540x960 res://tests/change_80_capture.tscn -- --probe --profile=probe-c80cap
##       --no-autosave --first-run-complete --shape=540x960 [--lang=de_DE]
## Output: tests/tmp/change_80_capture/<shape>[_<lang>]_<name>.png (ignored by Git).
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
    var dir:="res://tests/tmp/change_80_capture/"
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

func stage_cards() -> Array:
    return game.rows.find_children("*","PanelContainer",true,false).filter(func(n):return n.has_meta("stage_row"))

## Scrolls the sheet so the stage list's summary sits near the top (as a player scrolling down would see it).
func scroll_to_list(offset:=0) -> void:
    var scroll: ScrollContainer=game.get_node("Sheet/Margin/Content/Scroll")
    var anchor: Control=null
    for l in game.rows.find_children("*","Label",true,false):
        if l.has_meta("stage_summary"):anchor=l
    if anchor==null:return
    scroll.scroll_vertical=int(anchor.get_global_rect().position.y-scroll.get_global_rect().position.y+scroll.scroll_vertical)-40+offset
    await frames(4)

func audit(name_: String) -> void:
    var cards:=stage_cards()
    var problems: Array=[]
    if cards.size()!=8:problems.append("cards=%d" % cards.size())
    var list_width: float=game.rows.get_global_rect().size.x
    var last_bottom:=-INF
    for c in cards:
        var r: Rect2=c.get_global_rect()
        if r.size.y<56:problems.append("stage %d height %.0f" % [c.get_meta("stage_row"),r.size.y])
        if r.size.x>list_width+1:problems.append("stage %d wider than the list" % c.get_meta("stage_row"))
        if r.position.y<last_bottom-0.5:problems.append("stage %d overlaps the previous card" % c.get_meta("stage_row"))
        last_bottom=r.end.y
        for l in c.find_children("*","Label",true,false):
            var lr: Rect2=l.get_global_rect()
            if lr.position.x<r.position.x-1 or lr.end.x>r.end.x+1 or lr.position.y<r.position.y-1 or lr.end.y>r.end.y+1:
                problems.append("stage %d label '%s' outside its card" % [c.get_meta("stage_row"),l.text])
            var font: Font=l.get_theme_font("font");var fs: int=l.get_theme_font_size("font_size")
            if l.autowrap_mode==TextServer.AUTOWRAP_OFF and font.get_string_size(l.text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x>lr.size.x+1:
                problems.append("stage %d label '%s' clipped" % [c.get_meta("stage_row"),l.text])
    print("AUDIT %s %s cards=%d %s" % [shape+("_"+lang if lang!="" else ""),name_,cards.size(),"ok" if problems.is_empty() else "AUDIT_FAIL "+str(problems)])
    if not problems.is_empty():audit_failures+=1

func run() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--shape="):shape=arg.trim_prefix("--shape=")
        elif arg.begins_with("--lang="):lang=arg.trim_prefix("--lang=")
    SettingsState.mute_all_sfx()
    LocalizationService.set_test_device_locale("en_US")
    LocalizationService.select_language("automatic" if lang=="" else lang)
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    await frames(10)
    # 1. Fresh save at Winter I: Winter II is NEXT and locked.
    fresh()
    game._open("world");await frames(20)
    await scroll_to_list()
    audit("01_fresh")
    await shot("01_stages_fresh")
    # 2. Autumn I reached this run, standing in Winter I: NEXT is Autumn II.
    fresh()
    sim.state.unlocked_stage=5 # fixture: Autumn I reached this run
    sim.state.follow_mastery="2:explore";sim.touch() # fixture: a followed objective's icon on Winter II
    game._open("world");await frames(20)
    await scroll_to_list()
    audit("02_unlocked5_at1")
    await shot("02_stages_unlocked5_at_winter1")
    await scroll_to_list(420)
    await shot("03_stages_unlocked5_scrolled")
    # 3. All eight unlocked, standing in Spring I.
    fresh()
    sim.state.unlocked_stage=8;sim.state.stage=7;sim.campaign.configure_stage();sim._reset_world() # fixture: all stages reached
    game._open("world");await frames(20)
    await scroll_to_list(260)
    audit("04_all")
    await shot("04_stages_all_unlocked")
    # 4. Camp panel with the Camp Supplies cooldown line, then the toast.
    fresh()
    sim.state.owned_cards=["regional_c3"] # fixture: card owned
    sim.state.camps["1"].append(1) # fixture: camp 1 owned
    var a: Array=sim.campaign.stage().spawns[0];sim.state.player.x=a[0];sim.state.player.y=a[1]
    sim.campaign.camp_supply_step()
    sim.state.playtime_total=float(sim.state.playtime_total)+133.0 # fixture: 2m13s of play since
    for i in range(10):game._update_toast(.1)
    await frames(6)
    await shot("05_camp_supplies_toast")
    game._open("camp");await frames(20)
    await shot("06_camp_panel_cooldown")
    # 5. The Regional Prestige choice with Camp Supplies offered.
    fresh()
    sim.state.owned_cards=["regional_c1","regional_c2"] # fixture: earlier Regional cards owned
    var g: int=sim.campaign.prestige_unlock_group()
    sim.state.bosses_found.append("boss-snowman");sim.state.group_kills[g]=1 # fixture: Prestige unlocked
    sim.state.opportunities["regional_o1"]={"ready":true,"baseline":{},"step":0,"count":0} # fixture: ready
    sim.campaign.begin_prestige()
    game._open("prestige");await frames(20)
    await shot("07_prestige_choice_camp_supplies")
    print("CHANGE_80_CAPTURE complete shape=%s audit_failures=%d" % [shape,audit_failures])
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    get_tree().quit(1 if audit_failures>0 else 0)
