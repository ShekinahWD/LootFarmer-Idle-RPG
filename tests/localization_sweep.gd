extends Node
## Localization Batches 01 and 02: renders the game's player-visible surfaces in one or more languages and
## checks what is actually on screen (Playbook 132.4, 132.6).
## - pseudo: every catalog string is wrapped in ⟦ ⟧; any visible text outside the markers did not come
##   from the catalog (hardcoded English, a key built from data, a name derived from an id).
## - a real language: no raw keys, no English sentence that the language translates differently,
##   no clipped single-line text, nothing pushed off screen horizontally, buttons stay tappable.
## Headless: -- --probe --profile=probe-l10n --no-autosave --first-run-complete [--langs=pseudo,de_DE]
##   [--sizes=432x960,540x960,768x1024] [--report=res://docs/.../sweep.json]
## The canvas stretches to 720 units wide (canvas_items, expand), so shapes, not pixel counts, change layout:
## 432x960 is a 20:9 phone, 540x960 16:9, 768x1024 a 4:3 tablet.
## Windowed screenshots: --resolution 540x960 ... --langs=de_DE --shots=res://docs/.../screens/ --shape=540
var game
var sim
## Defaults (the maintained-suite run): pseudo-locale, English, Batch 01 and Batch 02 at the three portrait shapes.
var langs: Array=["pseudo","en","es_419","es_ES","pt_BR","fr_FR","de_DE","it_IT","nl_NL","pl_PL","ru_RU","uk_UA"]
var sizes: Array=[]
var shots:=""
var shape:=""
var report_path:=""
## Windowed evidence: only these screens are saved as screenshots (all screens are still checked).
var shot_screens: Array=[]
var current_lang:=""
var current_size:=""
var findings: Array=[]
var screens_seen:=0
var english: Dictionary={}
var english_values: Dictionary={}
var translations: Dictionary={}
const OPEN:="⟦"
const CLOSE:="⟧"

func _ready() -> void:call_deferred("run")
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame

## Minimal PO reader (the catalogs use single-line msgid/msgstr, the project convention).
static func read_po(path: String) -> Dictionary:
    var out: Dictionary={}
    var text:=FileAccess.get_file_as_string(path)
    var key:=""
    for line in text.split("\n"):
        if line.begins_with("msgid \""):key=line.substr(7,line.length()-8).c_unescape()
        elif line.begins_with("msgstr \"") and key!="":out[key]=line.substr(8,line.length()-9).c_unescape();key=""
    return out

func pseudo_translation() -> Translation:
    var t:=Translation.new()
    t.locale="eo"
    for key in english:t.add_message(key,OPEN+str(english[key])+CLOSE)
    return t

func run() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--langs="):langs=Array(arg.trim_prefix("--langs=").split(","))
        elif arg.begins_with("--sizes="):sizes=Array(arg.trim_prefix("--sizes=").split(","))
        elif arg.begins_with("--shots="):shots=arg.trim_prefix("--shots=")
        elif arg.begins_with("--shape="):shape=arg.trim_prefix("--shape=")
        elif arg.begins_with("--report="):report_path=arg.trim_prefix("--report=")
        elif arg.begins_with("--shot-screens="):shot_screens=Array(arg.trim_prefix("--shot-screens=").split(","))
    english=read_po("res://localization/en.po")
    for key in english:
        var value: String=english[key]
        if value.split(" ").size()>=3 and not "%" in value:english_values[value]=key
    LocalizationService.enable_test_batch("batch01")
    LocalizationService.enable_test_batch("batch02")
    TranslationServer.add_translation(pseudo_translation())
    for lang in langs:
        if lang!="pseudo":translations[lang]=read_po("res://localization/%s.po" % lang)
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.campaign.review.opener=func(_url: String)->int:return ERR_CANT_OPEN
    await frames(10)
    if sizes.is_empty():sizes=["%dx%d" % [get_window().size.x,get_window().size.y]] if shots!="" else ["432x960","540x960","768x1024"]
    for size_text in sizes:
        var parts: PackedStringArray=size_text.split("x")
        if shots=="":get_window().size=Vector2i(int(parts[0]),int(parts[1]))
        await settle()
        current_size=size_text
        for lang in langs:
            current_lang=lang
            LocalizationService.set_test_locale("eo" if lang=="pseudo" else "")
            if lang!="pseudo":check_select(lang)
            await frames(3)
            await sweep()
    var summary:={"langs":langs,"sizes":sizes,"screens":screens_seen,"findings":findings}
    if report_path!="":
        DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(report_path.get_base_dir()))
        var f:=FileAccess.open(report_path,FileAccess.WRITE);f.store_string(JSON.stringify(summary,"  "));f.close()
    for item in findings:print("FINDING ",JSON.stringify(item))
    print("LOCALIZATION_SWEEP checks=%d findings=%d" % [screens_seen,findings.size()])
    LocalizationService.set_test_locale("")
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    get_tree().quit(1 if not findings.is_empty() else 0)

func check_select(lang: String) -> void:
    if lang=="en":lang="en_US"
    if not LocalizationService.select_language(lang):
        findings.append({"lang":lang,"size":current_size,"screen":"settings","kind":"select_refused","text":lang})

# ---------------------------------------------------------------- fixtures
func fresh(mode:="none") -> void:
    get_tree().paused=false
    if game.get_node("ReviewInvitation").visible:game.get_node("ReviewInvitation").close()
    if game.get_node("PrestigeConfirm").visible:game.get_node("PrestigeConfirm").close()
    sim.new_profile();sim.set_physics_process(false);sim.suspended=false
    sim.state.tutorial.mode=mode;sim.campaign.onboarding.reveal_all(true)
    sim.state.tutorial.seen.append("road_ahead")
    game._close();game._cancel_confirm()
    game.toast_queue.clear();game.get_node("Toast").hide()

## A mid-game profile: several stages, gear of every kind, supplies, skills, coins and gems.
func rich() -> void:
    fresh("none")
    sim.state.unlocked_stage=5;sim.state.player_level=60
    sim.state.coins=123456789.0;sim.state.gems=4321.0
    var kinds: Dictionary={}
    for id in sim.catalog.items:
        var item: Dictionary=sim.catalog.items[id]
        var kind: String=str(item.kind)
        if int(item.get("tier",1))!=1 or int(kinds.get(kind,0))>=4:continue
        if sim.add_item(id,3,true,false):kinds[kind]=int(kinds.get(kind,0))+1
    for id in sim.state.items:
        if sim.catalog.items[id].kind in ["weapon","outfit"]:sim.equip(id)
    for g in range(sim.catalog.groups.size()):
        if int(sim.catalog.groups[g].stage)<=3:sim.campaign.discover_spot(g,2)
    sim.campaign.reveal();sim.touch()
    sim.state.player.hp=sim.stats().hp*.6
    game.world.follow_player()

# ---------------------------------------------------------------- collection
func texts_of(c: Control) -> Array:
    var out: Array=[]
    if c is Label or c is Button or c is RichTextLabel or c is LineEdit:
        var t: String=displayed(c)
        if t.strip_edges()!="":out.append(t)
    return out

## What the player sees: scene text that is a key is auto-translated for display (Playbook 145.4).
func displayed(c: Control) -> String:
    if c is RichTextLabel:return c.get_parsed_text()
    return c.atr(str(c.text)) if c.can_auto_translate() else str(c.text)

## Containers relayout over a couple of hundred frames after a window resize (headless starts at 64x64).
func settle() -> void:
    # Stable for 0.6 s of real time: the HUD relayouts on its 0.15 s tick, so frame counts can mislead.
    var top: Control=game.get_node("Safe/Layout/Top")
    var last:=Rect2();var since:=Time.get_ticks_msec()
    for i in range(3000):
        await get_tree().process_frame
        var r:=top.get_global_rect()
        if r!=last:last=r;since=Time.get_ticks_msec()
        elif Time.get_ticks_msec()-since>=600:return

func visible_controls(root: Node) -> Array:
    var out: Array=[]
    for c in root.find_children("*","Control",true,false):
        if c.is_visible_in_tree() and c.modulate.a>0.05:out.append(c)
    return out

func strip_marked(t: String) -> String:
    var re:=RegEx.create_from_string("⟦[^⟦⟧]*⟧")
    var prev:=""
    while prev!=t:
        prev=t;t=re.sub(t,"",true)
    return t

func add(screen: String,kind: String,text: String,node: Node=null) -> void:
    var entry:={"lang":current_lang,"size":current_size,"screen":screen,"kind":kind,"text":text}
    if node!=null:entry["node"]=str(game.get_path_to(node)) if game.is_ancestor_of(node) else str(node.get_path())
    for f in findings:
        if f.lang==entry.lang and f.size==entry.size and f.kind==entry.kind and f.text==entry.text:return
    findings.append(entry)

func scroll_ancestor(c: Control) -> Control:
    var p:=c.get_parent()
    while p!=null and p is Control:
        if p is ScrollContainer:return p
        p=p.get_parent()
    return null

func inspect(screen: String) -> void:
    screens_seen+=1
    var view: Rect2=get_viewport().get_visible_rect()
    var raw:=RegEx.create_from_string("^[A-Z][A-Z0-9]*(_[A-Z0-9]+)+$")
    var latin:=RegEx.create_from_string("[A-Za-z]{2,}")
    for c in visible_controls(game):
        for t in texts_of(c):
            for line in t.split("\n"):
                if raw.search(line.strip_edges())!=null:add(screen,"raw_key",line,c)
            if current_lang=="pseudo":
                var rest: String=strip_marked(t)
                if latin.search(rest)!=null:add(screen,"not_from_catalog",t,c)
            elif current_lang!="en" and translations.has(current_lang):
                for line in t.split("\n"):
                    var s: String=line.strip_edges()
                    if english_values.has(s) and translations[current_lang].get(english_values[s],s)!=s:add(screen,"english_leak",s,c)
        # Geometry: horizontally inside the screen (or its scroll area); single-line text not clipped.
        var r: Rect2=c.get_global_rect()
        if r.size.x<=0 or r.size.y<=0:continue
        var bounds:=view
        var scroll:=scroll_ancestor(c)
        if scroll!=null:bounds=scroll.get_global_rect()
        if (c is Label or c is Button) and (r.position.x<bounds.position.x-2 or r.end.x>bounds.end.x+2):
            add(screen,"off_screen_x","%s %s in %s" % [displayed(c).left(60),str(r),str(bounds)],c)
        if c is Label and c.autowrap_mode==TextServer.AUTOWRAP_OFF and (c.clip_text or c.text_overrun_behavior!=TextServer.OVERRUN_NO_TRIMMING):
            var font: Font=c.get_theme_font("font");var fs: int=c.get_theme_font_size("font_size")
            for line in displayed(c).split("\n"):
                if font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x>r.size.x+2:add(screen,"clipped",line,c)
        if c is Button and c.autowrap_mode==TextServer.AUTOWRAP_OFF and (c.clip_text or c.text_overrun_behavior!=TextServer.OVERRUN_NO_TRIMMING) and displayed(c)!="":
            var font: Font=c.get_theme_font("font");var fs: int=c.get_theme_font_size("font_size")
            var icon_w: float=0.0
            if c.icon!=null:icon_w=(float(c.get_theme_constant("icon_max_width")) if c.expand_icon and c.get_theme_constant("icon_max_width")>0 else float(c.icon.get_width()))+c.get_theme_constant("h_separation")
            var room: float=r.size.x-c.get_theme_stylebox("normal").get_minimum_size().x-icon_w
            for line in displayed(c).split("\n"):
                if font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x>room+2:add(screen,"clipped",line,c)
        if c is Button and not c.disabled and r.size.y<44 and displayed(c)!="" and scroll==null and not c.get_parent() is TabBar:
            add(screen,"small_button","%s h=%d" % [displayed(c).left(40),int(r.size.y)],c)
    if shots!="" and (shot_screens.is_empty() or screen in shot_screens):
        await frames(2)
        var dir:=shots+current_lang+"/"
        DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
        get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(dir+"%s_%s.png" % [screen,shape if shape!="" else current_size]))

func quiet_shot() -> void:
    game.banner.queue.clear();game.banner._finish()
    game.toast_queue.clear();game.get_node("Toast").hide()
    await frames(8)

func panel(name_: String,screen: String) -> void:
    game._open(name_);await quiet_shot()
    await inspect(screen)
    # The bottom of a long panel too (scrolled content must be reachable and fit).
    var scroll: ScrollContainer=game.get_node("Sheet/Margin/Content/Scroll")
    var bar:=scroll.get_v_scroll_bar()
    if bar.max_value>scroll.size.y+4:
        if not bar.visible:add(screen,"scrollbar_hidden","content %d > view %d" % [int(bar.max_value),int(scroll.size.y)],scroll)
        scroll.scroll_vertical=int(bar.max_value);await frames(3)
        await inspect(screen+"_end")
        scroll.scroll_vertical=0

# ---------------------------------------------------------------- surfaces
func sweep() -> void:
    rich();await settle();await quiet_shot()
    await inspect("hud")
    # Inventory items of each kind (weapon, outfit, skill, supply).
    var seen_kinds: Dictionary={}
    for i in range(sim.state.gear.size()):
        var id: String=sim.state.gear[i]
        if id=="" or seen_kinds.has(sim.catalog.items[id].kind):continue
        seen_kinds[sim.catalog.items[id].kind]=true
        game._select_slot(0,i);await quiet_shot();await inspect("item_"+str(sim.catalog.items[id].kind))
    if sim.state.supplies.size()>0 and sim.state.supplies[0]!="":
        game._select_slot(1,0);await quiet_shot();await inspect("item_supply")
    game._close()
    for tab in range(5):
        game.player_tab=tab;await panel("upgrades","upgrades_tab%d" % tab)
    game.player_tab=0
    for g in [0,1]:
        game.group=g
        for tab in range(3):
            game.enemy_tab=tab;await panel("enemy","enemy_g%d_tab%d" % [g,tab])
    game.enemy_tab=0
    for p in ["world","missions","prestige","stats","history","settings","help","level","farming","mastery","offline","filters","teleport"]:
        await panel(p,p)
    game.selected_camp=0;await panel("camp","camp")
    game.travel_stage=1;await panel("travel_map","travel_map")
    game._close()
    # Confirmations and dialogs.
    game._confirm(tr("RESET_CONFIRM"),func()->void:pass,tr("HARD_RESET"),true);await quiet_shot();await inspect("confirm_reset")
    game._cancel_confirm()
    var dropped:=""
    for id in sim.state.items:
        if not sim.equipped(id):dropped=id;break
    if dropped!="":game._confirm_drop(dropped);await quiet_shot();await inspect("confirm_drop");game._cancel_confirm()
    game._close();await frames(2);game.back();await quiet_shot();await inspect("confirm_exit");game._cancel_confirm()
    for channel in ["google_play","itch_io"]:
        BootContext.store_channel_override=channel
        game.open_review();await quiet_shot();await inspect("review_"+channel)
        if channel=="google_play":
            game.get_node("ReviewInvitation").review_button.pressed.emit();await quiet_shot();await inspect("review_open_failed")
        game._review_later()
    BootContext.store_channel_override=""
    # Banners (a milestone and a stage) and a toast.
    game._milestone("stage","2");await frames(20);await inspect("banner_stage")
    game.banner.queue.clear();game.banner._finish()
    game._say(tr("NOT_ENOUGH_COINS"));await frames(30);await inspect("toast")
    # Onboarding: the chooser, every Basic card, the Road Ahead.
    fresh("pending");sim.state.tutorial.seen=[];await frames(6);await inspect("chooser")
    game.guide.choose("basic");await frames(4)
    for i in range(game.guide.BASIC_DECK.size()):
        await frames(4);await inspect("basic_%d_%s" % [i+1,game.guide.BASIC_DECK[i]])
        if game.guide.intro_button.visible:game.guide.intro_button.pressed.emit()
        else:sim.state.tutorial.seen.append(game.guide.BASIC_DECK[i])
    await frames(4)
    sim.state.tutorial["road_ahead_seconds"]=999.0;await frames(4);await inspect("road_ahead")
    await guide_cards()

## Every GUIDE_* card text in the real card (title + detail), placed as the guide places it: the card
## must stay on the map and inside the screen whatever the language.
func guide_cards() -> void:
    fresh("basic");sim.state.tutorial.seen=[];await frames(4)
    var g=game.guide
    g.process_mode=Node.PROCESS_MODE_DISABLED
    g.card.show();g.intro_button.show()
    var map: Rect2=game.get_node("Safe/Layout/Map").get_global_rect()
    for key in english:
        if not key.begins_with("GUIDE_") or key.ends_with("_DETAIL") or not english.has(key+"_DETAIL") or key.begins_with("GUIDE_MODE_"):continue
        g.title.text=tr(key);g.support.text=tr(key+"_DETAIL")
        if "%s" in g.support.text:g.support.text=g.support.text % NumberFormat.currency(12345,true)
        await frames(1);g._place_card();await frames(1);g._place_card()
        var r: Rect2=g.card.get_global_rect()
        if not get_viewport().get_visible_rect().grow(1).encloses(r) or r.size.y>map.size.y*.75:add("guide_card","guide_card_fit","%s %s map=%s" % [key,str(r),str(map)],g.card)
        if current_lang=="pseudo":
            for t in [g.title.text,g.support.text]:
                if RegEx.create_from_string("[A-Za-z]{2,}").search(strip_marked(t))!=null:add("guide_card","not_from_catalog",t,g.card)
    g.process_mode=Node.PROCESS_MODE_INHERIT
    screens_seen+=1
