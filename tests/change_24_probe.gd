extends "res://tests/change_20_probe.gd"
## Change 24 performance batch: the faster representations and schedules give the same answers as
## before. Fog sight, explored masks and their save encoding, the save path (size/digest check,
## backup, coalesced tiers), the SceneState obstacle reader, the stage scene cache, off-screen actor
## views and the view pool, the inventory layout key, the retained panel, and the build version.
## Timings are not asserted here (see tools/run_benchmark.py, non-gating).
const STAGE_SCENES=preload("res://scripts/game/stage_scenes.gd")

func run() -> void:
    get_window().size=Vector2i(720,1280)
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    fresh("none");sim.state.tutorial.seen.append("road_ahead");await frames(6)
    sight_checks()
    mask_checks()
    save_checks()
    obstacle_checks()
    await world_checks()
    await inventory_checks()
    await panel_checks()
    version_checks()
    print("CHANGE_24_CHECKS %d FAILURES %d" % [checks,failures])
    game.queue_free();await frames();AudioService.stop_all_sfx();get_tree().quit(1 if failures else 0)

func go(st: int) -> void:
    sim.state.unlocked_stage=maxi(int(sim.state.unlocked_stage),st);sim.state.stage=st;sim.state.spawn=0
    sim._reset_world();sim.campaign.reveal()

# ---------------------------------------------------------------- fog sight (P06/P07)
func sight_checks() -> void:
    for st in [1,8]:
        fresh("none");sim.state.tutorial.seen.append("road_ahead");go(st)
        sim.campaign.reveal_circle(Vector2(600,500),180.0)
        sim.campaign.reveal_circle(Vector2(240,900),90.0)
        var size:=Vector2(sim.campaign.stage().size[0],sim.campaign.stage().size[1])
        for alive in [true,false]:
            sim.state.player.hp=sim.stats().hp if alive else 0.0
            var view=sim.campaign.sight()
            var same:=0;var total:=0
            for y in range(-30,int(size.y)+30,13):
                for x in range(-30,int(size.x)+30,17):
                    var p:=Vector2(x,y)+Vector2(.37,.61)
                    total+=1
                    if view.sees(p)==sim.campaign.can_see(p):same+=1
            check(same==total,"Stage %d, player %s: Sight agrees with can_see at all %d points (%d)" % [st,"alive" if alive else "dead",total,same])
        sim.state.player.hp=sim.stats().hp
    # Targeting with and without a sight context.
    var e: Dictionary=sim.state.enemies[0]
    check(sim.campaign.target_allowed(e)==sim.campaign.target_allowed(e,sim.campaign.sight()),"target_allowed is the same with a shared Sight")

# ---------------------------------------------------------------- explored masks (P02)
func mask_checks() -> void:
    fresh("none");sim.state.tutorial.seen.append("road_ahead");go(8)
    var n: int=sim.campaign.fog_cell_count(8)
    check(sim.state.explored["8"] is PackedByteArray and sim.state.explored["8"].size()==n,"Spring II explored cells are one byte per fog cell (%d)" % n)
    var before: int=sim.campaign.explored_count(8)
    check(sim.campaign.reveal_circle(Vector2(1500,1500),120.0) and sim.campaign.explored_count(8)>before,"A reveal sets mask bytes and raises the count")
    sim.campaign.explore_cells(8,[],true)
    var encoded: Dictionary=sim.campaign.encode_explored(sim.state.explored)
    check(encoded["8"] is String and encoded["8"].length()<400,"A fully explored map saves as %d Base64 characters (was one JSON key per cell)" % encoded["8"].length())
    check(sim.campaign.decode_explored(8,encoded["8"])==sim.state.explored["8"],"Encoding round-trips exactly")
    var winter:=PackedByteArray();winter.resize(sim.campaign.fog_cell_count(1))
    check(sim.campaign.decode_explored(8,"not base64").is_empty() and sim.campaign.decode_explored(8,winter).is_empty(),"Malformed or wrong-map masks decode to nothing")
    check(sim.campaign.explored_fraction(8)==1.0 and sim.campaign.explored_percent(8)==100,"Fully explored Spring II reads 100%")
    var kept: PackedByteArray=sim.state.explored["8"]
    check(sim.campaign.cell_explored(8,0,0) and sim.campaign.cell_known(Vector2(5,5)),"Cell lookups read the mask")
    # Prestige keeps explored cells (Change 16 rule unchanged).
    sim.state.bosses_found.append("boss-snowman");sim.state.opportunities.hunter_o1={"ready":true,"baseline":{},"step":0,"count":0}
    if sim.campaign.begin_prestige():
        var guard:=0
        while not sim.state.prestige_batch.is_empty() and guard<40:
            guard+=1;sim.campaign.choose_card(str(sim.campaign.offered_cards()[0]))
    check(int(sim.state.prestiges)==1 and sim.state.explored.get("8")==kept,"Prestige keeps the explored mask")

# ---------------------------------------------------------------- save path (P01/P03)
func save_checks() -> void:
    fresh("none");sim.state.tutorial.seen.append("road_ahead")
    for st in range(1,9):sim.campaign.explore_cells(st,[],true)
    sim.add_item("wood_sword",3)
    check(SaveService.save_now(),"Late-game style profile saves")
    var path: String=ProjectSettings.globalize_path(SaveService.save_path())
    var text:=FileAccess.get_file_as_string(path)
    var data=JSON.parse_string(text)
    check(data is Dictionary and int(data.version)==SaveService.SAVE_VERSION and SaveService.SAVE_VERSION==3,"The file is valid JSON at save version 3")
    check(data is Dictionary and data.sections.lootfarmer.explored["8"] is String,"Explored masks are stored compactly")
    check(text.length()<120000,"Fully explored profile is %d bytes (the audit measured 465,980)" % text.length())
    var expected: Dictionary=sim.snapshot()
    sim.state.explored={};sim.state.items={}
    SaveService.load_and_apply()
    check(SaveService.last_load_result=="primary" and sim.campaign.explored_count(8)==sim.campaign.fog_cell_count(8) and sim.quantity("wood_sword")==3,"Disk reload restores every explored cell and the inventory")
    check(sim.snapshot().explored==expected.explored,"…byte for byte")
    # Backup: a valid primary becomes the backup; a primary changed on disk never does.
    check(SaveService.save_now() and JSON.parse_string(FileAccess.get_file_as_string(path+".bak")) is Dictionary,"The previous primary becomes a valid backup")
    var good_backup:=FileAccess.get_file_as_string(path+".bak")
    var f:=FileAccess.open(path,FileAccess.READ_WRITE);f.seek_end();f.store_string("garbage");f.close()
    check(SaveService.save_now() and FileAccess.get_file_as_string(path+".bak")==good_backup,"A primary changed on disk does not replace the backup")
    check(JSON.parse_string(FileAccess.get_file_as_string(path)) is Dictionary,"…and the new primary is valid")
    # Development reset policy: an older save version starts fresh (Playbook 61.1, no migration).
    var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path));old.version=2
    var w:=FileAccess.open(path,FileAccess.WRITE);w.store_string(JSON.stringify(old));w.close()
    var b:=FileAccess.open(path+".bak",FileAccess.WRITE);b.store_string(JSON.stringify(old));b.close()
    SaveService.load_and_apply()
    check(SaveService.last_load_result=="development_reset" and SaveService._loaded_sections.is_empty(),"A version-2 development profile resets (nothing is restored from it)")
    check(SaveService.save_now() and int(JSON.parse_string(FileAccess.get_file_as_string(path)).version)==3,"…and the fresh profile is writable")
    # Two coalescing tiers.
    var was: bool=BootContext.autosave_enabled
    BootContext.autosave_enabled=true
    var saves:=[0]
    var counter:=func()->void:saves[0]+=1
    SaveService.saved.connect(counter)
    SaveService.mark_dirty();SaveService._process(0.0)
    check(saves[0]==0,"Ordinary progress is not written at once")
    var since: float=SaveService._dirty_since
    SaveService.mark_dirty()
    check(SaveService._dirty_since==since,"Repeated marks do not postpone the ordinary save")
    SaveService._dirty_since-=SaveService.ORDINARY_SAVE_DELAY;SaveService._process(0.0)
    check(saves[0]==1 and SaveService.ORDINARY_SAVE_DELAY==30.0,"…it is written %d s after the first unsaved change" % int(SaveService.ORDINARY_SAVE_DELAY))
    sim.state.coins=1000000.0
    check(sim.buy_upgrade("respawn") and SaveService._commit_at>=0.0,"A purchase schedules a committed save")
    SaveService._process(0.0)
    check(saves[0]==1,"…coalesced for %.0f s" % SaveService.COMMITTED_SAVE_DELAY)
    SaveService._commit_at-=SaveService.COMMITTED_SAVE_DELAY+.01;SaveService._process(0.0)
    check(saves[0]==2 and not SaveService._dirty,"…then written")
    SaveService.saved.disconnect(counter)
    BootContext.autosave_enabled=was

# ---------------------------------------------------------------- obstacles and stage cache (P04/P09)
func old_obstacles(id: int) -> Array:
    var list: Array=[]
    var scene: Node=load(STAGE_SCENES.path(id)).instantiate()
    for node in scene.find_children("*","CollisionShape2D",true,false):
        var shape: CollisionShape2D=node
        var pos:=Vector2.ZERO;var n: Node=shape
        while n!=null and n!=scene:
            if n is Node2D:pos+=(n as Node2D).position
            n=n.get_parent()
        if shape.shape is CircleShape2D:list.append({"c":pos,"r":(shape.shape as CircleShape2D).radius})
        elif shape.shape is RectangleShape2D:
            var size: Vector2=(shape.shape as RectangleShape2D).size
            list.append({"rect":Rect2(pos-size*.5,size)})
    scene.free()
    return list
func obstacle_checks() -> void:
    var same:=0
    for id in range(1,9):
        if sim.campaign._read_obstacles(id).list==old_obstacles(id):same+=1
    check(same==8,"The SceneState obstacle reader returns the same solids as instantiating each stage (%d/8)" % same)
    STAGE_SCENES.request(5)
    check(STAGE_SCENES.scene(5) is PackedScene,"A requested stage scene is returned from the background load")
    for id in range(1,9):STAGE_SCENES.scene(id)
    check(STAGE_SCENES._scenes.size()<=STAGE_SCENES.CAPACITY,"The stage scene cache stays bounded (%d of %d)" % [STAGE_SCENES._scenes.size(),STAGE_SCENES.CAPACITY])

# ---------------------------------------------------------------- world views (P04/P06)
func world_checks() -> void:
    fresh("none");sim.state.tutorial.seen.append("road_ahead");sim.set_physics_process(false)
    go(8);await frames(4)
    var w=game.world
    check(w.views.size()==sim.state.enemies.size()+1,"One view per actor on Spring II (%d)" % w.views.size())
    var player: Vector2=sim.position_of(sim.state.player)
    var far: Dictionary={}
    for e in sim.state.enemies:
        if far.is_empty() or sim.position_of(e).distance_to(player)>sim.position_of(far).distance_to(player):far=e
    var v: LootActorView=w.views[far.id]
    check(not v.is_processing() and not v.visible,"An off-screen actor's view is hidden and skips its animation")
    check(v.actor==far and v.position==sim.position_of(far) and v.max_hp==float(sim.enemy_definition(int(far.group),int(far.get("variant",2))).hp),"…while its data stays current")
    far.x=player.x+30;far.y=player.y;sim.campaign.reveal_circle(player,200.0)
    await frames(2)
    check(v.is_processing() and v.visible,"Brought on screen, it animates and shows again")
    var nodes_before: float=Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
    go(1);await frames(30)
    check(w.views.size()==sim.state.enemies.size()+1 and w._view_pool.size()>0,"Leaving Spring II pools the spare views (%d pooled)" % w._view_pool.size())
    check(w._retired.is_empty() and w.scenery.get_parent()==w,"The previous stage scenery is freed over the following frames")
    go(8);await frames(30)
    check(w.views.size()==sim.state.enemies.size()+1,"Returning to Spring II reuses pooled views")
    var nodes_after: float=Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
    check(absf(nodes_after-nodes_before)<=40,"Node count stays flat across stage switches (%d → %d)" % [nodes_before,nodes_after])
    var fog=w.fog
    var rules=sim.campaign.fog_rules
    check(fog.material is ShaderMaterial and fog.material.get_shader_parameter("cells")==Vector2(sim.campaign.fog_columns(8),sim.campaign.fog_rows(8)),"The fog veil is one shader draw over the stage's fog grid")
    check(fog.material.get_shader_parameter("cover_color")==rules.cover_color and fog.material.get_shader_parameter("vision_color")==rules.vision_color,"…with the fog_rules colours")
    check(is_equal_approx(float(fog.material.get_shader_parameter("radius")),sim.campaign.vision_radius()),"…and the live vision radius")
    sim.set_physics_process(true)

# ---------------------------------------------------------------- inventory (P05)
func inventory_checks() -> void:
    fresh("none");sim.state.tutorial.seen.append("road_ahead");sim.state.upgrades.gear_slots=67
    sim.state.gear.resize(sim.equipment_slot_count());sim.state.gear.fill("")
    sim.add_item("wood_sword",2)
    game._refresh_slots();await frames(4);game._layout_inventory()
    var grid: GridContainer=game.dock.get_node("Inventory/GearColumn/GearScroll/Gear")
    check(grid.get_child_count()==70 and game.inventory_layout_key!="","70 equipment slots laid out")
    var slot: Control=grid.get_child(5)
    var count: Label=slot.get_node("Count")
    count.add_theme_font_size_override("font_size",99) # sentinel: only a real relayout rewrites it
    sim.touch();game._refresh_slots();game._layout_inventory()
    check(count.get_theme_font_size("font_size")==99,"An unchanged inventory refresh does not re-apply slot layout")
    var zoom: int=SettingsState.inventory_zoom
    SettingsState.set_inventory_zoom((zoom+1)%3);game._layout_inventory()
    check(count.get_theme_font_size("font_size")!=99,"A zoom change lays the slots out again")
    SettingsState.set_inventory_zoom(zoom);game._layout_inventory();await frames(2)

# ---------------------------------------------------------------- panels (P08)
func panel_checks() -> void:
    fresh("none");sim.state.tutorial.seen.append("road_ahead")
    game._open("upgrades");await frames(4)
    var first: Node=game.rows.get_child(0)
    game._close();await frames(2)
    check(is_instance_valid(first) and game.rows.process_mode==Node.PROCESS_MODE_DISABLED and not game.sheet.visible,"A closed panel's controls are retained with processing paused")
    game._open("upgrades");await frames(4)
    check(game.rows.get_child(0)==first and game.rows.process_mode==Node.PROCESS_MODE_INHERIT,"Reopening the same panel reconciles the retained controls")
    check(game.sheet.modulate.a==1.0,"…and the sheet settles visible")
    game._close();game._open("missions");await frames(4)
    check(not is_instance_valid(first),"Opening another panel replaces them")
    game._close()

func version_checks() -> void:
    # Later changes raise the version (change_25_probe checks the current one).
    check(int(str(ProjectSettings.get_setting("application/config/version")))>=24,"Project version is at least 24 (Change 24)")
    var presets:=FileAccess.get_file_as_string("res://export_presets.cfg")
    var code:=presets.substr(presets.find("version/code=")+13,4).to_int()
    check(presets.contains("name=\"Android Release\"") and code>=24,"Android Release version code is at least 24")
