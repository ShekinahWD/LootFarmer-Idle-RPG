extends "res://tests/change_20_probe.gd"
## Change 26: Android export allowlist and ABIs (audit REL-05/06).
## - Every file in tools/export_manifest.json loads (resources) or reads (raw data) from source.
## - All eight stage scenes are listed and instantiate.
## - Runtime recorder: the art the real game resolves (catalog icons, actor bodies and swing sheets
##   for every enemy group and item, skill effect sheets, UI/guide/Prestige item art cached while
##   every panel opens) is inside the manifest, so a packaged build cannot miss a dynamic path.
## - The Release preset exports exactly the manifest (selected resources), ARM ABIs only, version 26.
## The packaged artifact itself is checked by tools/verify_export.py (needs an export, outside the suite).
const MANIFEST="res://tools/export_manifest.json"
var shipped: Dictionary={}

func run() -> void:
    get_window().size=Vector2i(720,1280)
    SettingsState.mute_all_sfx()
    var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
    check(manifest!=null and manifest.has("files"),"export manifest readable")
    shipped=manifest.files
    source_checks()
    stage_checks()
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    await frames(6)
    await recorder_checks()
    preset_checks()
    print("CHANGE_26_CHECKS %d FAILURES %d" % [checks,failures])
    game.queue_free();await frames();AudioService.stop_all_sfx();get_tree().quit(1 if failures else 0)

func ships(path: String) -> bool:return shipped.has(path)

func source_checks() -> void:
    var loaded:=0;var raw:=0;var bad: Array=[]
    for path in shipped:
        if path.ends_with(".json"):
            if FileAccess.file_exists(path) and JSON.parse_string(FileAccess.get_file_as_string(path))!=null:raw+=1
            else:bad.append(path)
        elif ResourceLoader.exists(path) and load(path)!=null:loaded+=1
        else:bad.append(path)
    check(bad.is_empty(),"every manifest file resolves from source (bad: %s)" % [bad])
    check(loaded+raw==shipped.size() and loaded>200,"manifest resources loaded %d + raw %d" % [loaded,raw])
    for prefix in ["res://tests/","res://tools/","res://docs/","res://addons/","res://Godot-Marketing-Toolkit/"]:
        check(not shipped.keys().any(func(p):return p.begins_with(prefix)),"nothing under %s ships" % prefix)
    for retired in ["res://assets/Zombies Free ver/","res://assets/PP Pumpkins Set Free/","res://assets/LootFarmer-seasonal-animation-sheets/","res://assets/magic-spells-sfx-lite/wav/"]:
        check(not shipped.keys().any(func(p):return p.begins_with(retired)),"excluded group absent: %s" % retired)
    var variants: Array=shipped.keys().filter(func(p):return p.begins_with("res://assets/PixelPlains/Items/") and p.get_base_dir().get_file().begins_with("All") and not p.contains("All v3 (Separated Files, Black Outline)"))
    check(variants.is_empty(),"only the Black Outline item variant ships")
    for path in ["res://scenes/game/main.tscn","res://localization/en.po","res://data/game/catalog.json","res://icon.svg","res://resources/game/theme.tres","res://assets/Fonts/DejaVuSans.ttf","res://resources/game/fog_veil.gdshader","res://assets/sounds/background_music.wav"]:
        check(ships(path),"core file ships: "+path)

func stage_checks() -> void:
    var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/game/catalog.json"))
    check(catalog.stages.size()==8,"catalog has eight stages")
    for stage in catalog.stages:
        var path:="res://scenes/game/stages/stage_%d.tscn" % int(stage.id)
        check(ships(path),"stage %d scene ships" % int(stage.id))
        var scene: Node=load(path).instantiate()
        check(scene!=null and scene.get_child_count()>0,"stage %d scene instantiates" % int(stage.id))
        scene.free()

func recorder_checks() -> void:
    var missing: Array=[]
    var record:=func(texture: Texture2D,what: String) -> void:
        if texture==null:return
        var source: Texture2D=texture.atlas if texture is AtlasTexture else texture
        if source.resource_path=="" or not ships(source.resource_path):missing.append("%s -> %s" % [what,source.resource_path])
    # Catalog icons and the actor looks of every group and every item (outfits, weapons, swings).
    for id in sim.catalog.items:record.call(sim.catalog.icon(id),"icon "+id)
    var looks:=0
    for g in sim.catalog.groups:
        var look: Dictionary=game.world._visual_look(g.body,g.weapon);looks+=1
        record.call(look.body,"body "+g.id);record.call(look.attack,"attack "+g.id)
    for id in sim.catalog.items:
        var look: Dictionary=game.world._visual_look(id,id);looks+=1
        record.call(look.body,"body "+id);record.call(look.attack,"attack "+id)
    for special in ["death","cat"]:
        var look: Dictionary=game.world._visual_look(special,"wood_sword")
        record.call(look.body,"body "+special);record.call(look.attack,"attack "+special)
    check(looks==sim.catalog.groups.size()+sim.catalog.items.size(),"looks resolved for every group and item")
    # Skill effect sheets as the world builds them.
    for key in sim.catalog.skills:
        var sprite: AnimatedSprite2D=game.world._effect(key,Vector2.ZERO,"",Color.WHITE)
        record.call(sprite.sprite_frames.get_frame_texture("default",0),"effect "+key)
        sprite.free()
    # UI item art: open every panel and show every guide picture branch, then read the art cache.
    fresh("basic")
    for which in ["missions","upgrades","prestige","mastery","world","farming","filters","settings","stats","help","level","history","offline","teleport","enemy","camp"]:
        game._open(which);await frames(2)
    game._close()
    for step in ["snowman","overview","basic_gear","basic_growth","basic_world","basic_prestige","focus","skills","camp","prestige","kill","move"]:
        game.guide.step=step;record.call(game.guide._picture(),"guide "+step)
    for path in sim.catalog.campaign.paths:game._path_art(path)
    var art: Array=game.art_cache.keys()
    for index in art:
        var path: String=game.ITEM_ART % int(index)
        if not ships(path):missing.append("ui art %d" % int(index))
    check(art.size()>=15,"UI art recorded %d indices" % art.size())
    check(missing.is_empty(),"every runtime-resolved texture ships (missing: %s)" % [missing.slice(0,8)])

func preset_checks() -> void:
    check(str(ProjectSettings.get_setting("application/config/version"))=="26","Project version is 26 (Change 26)")
    var presets:=FileAccess.get_file_as_string("res://export_presets.cfg")
    var release:=presets.substr(presets.find("name=\"Android Release\""))
    release=release.substr(0,release.find("[preset.1]"))
    check(release.contains("version/code=26") and release.contains("version/name=\"\""),"Android Release version code is 26, name inherited")
    check(release.contains("export_filter=\"resources\""),"Release exports selected resources (the manifest)")
    for abi in ["arm64-v8a","armeabi-v7a"]:check(release.contains("architectures/%s=true" % abi),"Release ABI %s selected" % abi)
    for abi in ["x86","x86_64"]:check(release.contains("architectures/%s=false" % abi),"Release ABI %s not selected" % abi)
    var listed: int=release.substr(release.find("export_files=")).get_slice("\n",0).count("\"res://")
    check(listed==shipped.size(),"preset export_files lists the %d manifest files (%d)" % [shipped.size(),listed])
