extends Node
## Change 10 UI capture (rendered, not headless): outfit milestone slots ^0-^500, Player Level &
## Growth, Stats breakdown, Farming Guide list and map, Prestige before the Snowman, Hard Reset
## dialog and the post-reset chooser. Writes PNGs to docs/Change_10_Evidence/ui/.
var sim
var game
const OUT="res://docs/Change_10_Evidence/ui/"
func _ready() -> void:call_deferred("run")
func frames(n:=6) -> void:
    for i in range(n):await get_tree().process_frame
func shot(name: String) -> void:
    await frames(8)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+name+".png"))
func own(id: String,m: int) -> void:
    sim.add_item(id,2);sim.record(id).merge=m
func run() -> void:
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.new_profile();sim.state.tutorial.mode="none";sim.suspended=false
    sim.state.gems=1e6
    for i in range(6):sim.buy_upgrade("gear_slots")
    sim.state.gems=40
    var outfits:=["unit-blue-cap_outfit","unit-red-scarf_outfit","unit-chef-hat_outfit","boss-snowman_outfit","unit-wolf-hood_outfit","unit-santa-hat_outfit"]
    for i in range(6):own(outfits[i],[0,100,200,300,400,500][i])
    own("wood_sword",100)
    sim.equip("boss-snowman_outfit");sim.equip("wood_sword")
    sim.state.player_level=11;sim.state.xp=120
    for i in range(30):sim.step(.1)
    sim.touch()
    await shot("01_milestone_slots")
    game.top.get_node("Meters/XP/Open").pressed.emit()
    await shot("02_level_panel")
    $"/root".get_child(-1)
    game._open("stats")
    await shot("03_stats_breakdown")
    game.selected="boss-snowman_outfit";game.selected_slot=-1;game._open("item")
    await shot("04_item_slot_frame")
    game._nav("prestige")
    await shot("05_prestige_before_snowman")
    game.guide_stage=0;game._open("farming")
    await shot("06_farming_locked")
    for g in sim.campaign.stage().groups:
        sim.state.upgrades["reveal_stats:%d" % g]=1;sim.state.upgrades["reveal_drops:%d" % g]=1
    sim.state.upgrades["map_detail:1"]=3
    var groups: Array=sim.campaign.stage().groups
    sim.campaign.discover_spot(groups[0],2);sim.campaign.discover_spot(groups[0],0);sim.campaign.discover_spot(groups[1],1)
    sim.touch()
    game._refresh_panel(true)
    await shot("07_farming_list")
    game.guide_stage=1;game._refresh_panel(true)
    await shot("08_farming_map")
    game._open("settings")
    game._confirm(tr("RESET_CONFIRM"),func()->void:pass)
    await shot("09_hard_reset_confirm")
    game._cancel_confirm()
    SaveService.hard_reset();game._close()
    await shot("10_after_reset_chooser")
    get_tree().quit(0)
