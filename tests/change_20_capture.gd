extends Node
## Rendered desktop evidence at a phone-shaped viewport; not physical Android validation.
var game
var sim
const OUT="res://docs/Change_20_Evidence/ui/"
func _ready() -> void:call_deferred("run")
func frames(n:=8) -> void:
    for i in range(n):await get_tree().process_frame
func shot(name_: String) -> void:
    game.banner.queue.clear();game.banner._finish();game.toast_queue.clear()
    game.get_node("Toast").hide()
    await frames(12)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+name_+".png"))
func run() -> void:
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.set_physics_process(false);sim.new_profile();sim.suspended=false;sim.state.tutorial.mode="none"
    sim.campaign.onboarding.reveal_all(true)
    sim.state.upgrades.gear_slots=20;sim.state.gear.resize(sim.equipment_slot_count());sim.state.gear.fill("")
    sim.state.coins=100000;sim.state.gems=100000
    for id in ["wood_sword","wood_axe","unit-blue-cap_outfit","unit-red-scarf_outfit","skill_fire","skill_heal","skill_frost","skill_lightning"]:sim.add_item(id,5)
    sim.add_item("potion",3);sim.equip("wood_sword")
    game._refresh_slots();game._close()
    for zoom in [2,1,0]:
        SettingsState.set_inventory_zoom(zoom);game._layout_inventory()
        await shot("inventory_%d" % zoom)
    game._open("filters");await shot("zoom_controls")
    game._close();game.selected="wood_sword";game._open("item");await shot("item_auto_merge")
    game._close();sim.state.upgrades.skill_slots=1;sim.state.upgrades.skill_auto_slots=1
    sim.campaign.equip_skill("skill_heal",0);sim.campaign.equip_skill("skill_fire",1);sim.assign_automatic_skills([1])
    game.player_tab=0;game._open("upgrades");await shot("upgrades_and_automation")
    game.get_node("Sheet/Margin/Content/Scroll").scroll_vertical=100000;await shot("automatic_skill_selection")
    game.get_node("Sheet/Margin/Content/Scroll").scroll_vertical=0
    game.player_tab=2;game._refresh_panel(true);await shot("supplies")
    game.player_tab=3;game._refresh_panel(true);await shot("boss_chance")
    game._close();game.selected="skill_lightning";game._open("item");await shot("lightning_description")
    game._close();sim.state.unlocked_stage=2;sim.state.camps["2"]=[0,1]
    game._select_travel_stage(2);await shot("travel_map")
    game._close();game._open("map");await shot("expanded_map")
    game._close();game._open("missions");await shot("missions")
    game._close();sim.state.unlocked_stage=1
    for i in range(sim.state.missions.size()):
        if sim.state.missions[i].kind=="kill":sim.campaign.toggle_follow_mission("daily",i);break
    sim.state.opportunities.expedition_o1={"ready":false,"baseline":{},"step":0,"count":12}
    sim.campaign.toggle_follow("expedition_o1")
    sim.state.bosses_found.append("boss-snowman")
    game._process(.2);await shot("trackers_and_objective")
    print("OBJECTIVE_RECT ",game.get_node("Safe/Layout/Map/Objective").get_rect()," GATE_RECT ",game.get_node("Safe/Layout/Map/Gate").get_rect()," visible ",game.get_node("Safe/Layout/Map/Gate").visible)
    sim.state.tutorial.mode="guided"
    sim.campaign.guided.data().done=sim.campaign.guided.STEPS.slice(0,sim.campaign.guided.STEPS.find("camp")+1)
    game.guide.evaluate();await shot("boss_preparation")
    sim.campaign.guided.data().done=sim.campaign.guided.STEPS.slice(0,sim.campaign.guided.STEPS.find("milestones_intro")+1)
    sim.state.stage=2
    await shot("tutorial_final")
    sim.campaign.guided.shown(5);await shot("tutorial_final_confirm")
    print("CHANGE_20_CAPTURE complete")
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    get_tree().quit()
