extends RefCounted
## Change 35: one automatic, honest review invitation per saved profile, the same on every storefront.
## - Persistent state (state.review, kept by Prestige, cleared by Hard Reset):
##   "none" (not offered) -> "pending" (eligible after ReviewRules.eligible_seconds of saved active
##   play) -> "dismissed" (Maybe Later or Back) or "opened" (the store page opened). Dismissed and
##   opened are final: no automatic prompt again, whatever storefront or device the save moves to.
## - The storefront (label and URL) comes from distribution_channels.gd only. A build without a
##   configured channel never offers the panel and leaves "pending" untouched, so a correctly
##   configured build later still can. A failed store launch keeps "pending" and the panel open.
## - Where it may appear is decided in two layers: world_block_reason() (this file: simulation and
##   tutorial state) and game_ui._offer_review (open panels, banners, guide cards, input), which also
##   requires ReviewRules.safe_seconds of continuous safety. While the panel is visible the
##   simulation is held (sim.held), so no combat, clocks or playtime run behind it.
const NONE:="none"
const PENDING:="pending"
const DISMISSED:="dismissed"
const OPENED:="opened"
const STATUSES:=[NONE,PENDING,DISMISSED,OPENED]
var sim
var rules=preload("res://resources/game/review_rules.tres")
var channels=preload("res://resources/game/distribution_channels.tres")
## Opens a URL and returns an Error (OS.shell_open; probes replace it to test failures and routing).
var opener: Callable=func(url: String)->int:return OS.shell_open(url)
## The last URL handed to the opener (probes and the change report read it).
var last_url:=""

func _init(owner) -> void:sim=owner

func initial() -> Dictionary:
    return {"status":NONE,"eligible_at":-1.0,"answered_at":-1.0,"channel":"","open_failures":0}

func data() -> Dictionary:return sim.state.review
func status() -> String:return str(data().status)
func resolved() -> bool:return status() in [DISMISSED,OPENED]
func channel() -> String:return channels.current()

## none -> pending once enough saved active play exists. Never moves a resolved invitation.
func update() -> void:
    if status()==NONE and float(sim.state.playtime_total)>=rules.eligible_seconds:
        data().status=PENDING;data().eligible_at=float(sim.state.playtime_total);SaveService.mark_dirty()

## Pending, eligible and the build knows its storefront: the UI may now look for a quiet moment.
func wanted() -> bool:
    update()
    return status()==PENDING and channel()!=""

## Why the world is not a quiet moment ("" = it is). Only simulation and tutorial state; the UI adds
## its own surfaces (game_ui._review_ui_block).
func world_block_reason() -> String:
    var p: Dictionary=sim.state.player
    if sim.state.tutorial.mode=="pending":return "chooser"
    if tutorial_busy():return "tutorial"
    if sim.held or sim.suspended or sim.get_tree().paused:return "paused"
    if not sim.state.prestige_batch.is_empty():return "prestige"
    if not sim.state.offline_pending.is_empty():return "offline"
    if p.hp<=0 or float(p.get("respawn",0))>0:return "dead"
    if float(p.hp)<float(sim.stats().hp)*rules.min_health_fraction:return "health"
    var at: Vector2=sim.position_of(p)
    for e in sim.state.enemies:
        if e.hp>0 and sim.catalog.groups[int(e.group)].boss and (e.aggro or sim.position_of(e).distance_to(at)<=rules.boss_clearance):return "boss"
    if sim.campaign.in_combat():return "combat"
    if sim.movement.length()>.1:return "moving"
    return ""

## Guided until its final step, Basic until its overview and The Road Ahead are done, None until its
## Road Ahead is read: the opening never shares the screen with a store request.
func tutorial_busy() -> bool:
    var t: Dictionary=sim.state.tutorial
    if t.mode=="guided":return sim.campaign.guided.active()
    return not t.seen.has("road_ahead")

## Maybe Later (or Back): final; the player can still review from Settings.
func dismiss() -> void:
    if resolved():return
    data().status=DISMISSED;data().answered_at=float(sim.state.playtime_total);data().channel=channel()
    sim.touch();SaveService.mark_committed()

## Opens the configured store page. Success records "opened" (the page opened, nothing more is
## claimed); a failure counts it and changes nothing else, so the same button can be tried again.
## Settings uses this too; a manual review also settles the automatic invitation.
func open_store() -> bool:
    var id:=channel()
    if id=="":return false
    last_url=channels.url(id)
    if int(opener.call(last_url))!=OK:
        data().open_failures=int(data().open_failures)+1;SaveService.mark_dirty()
        return false
    if status()!=OPENED:
        data().status=OPENED;data().answered_at=float(sim.state.playtime_total)
    data().channel=id
    sim.touch();SaveService.mark_committed()
    return true

## Saved profiles before Change 35 (same schema 8) have no record: they start at "none" and turn
## pending on the first update() if they already played the eligible time. Malformed fields reset.
func normalize(out: Dictionary) -> void:
    var r=out.get("review")
    var clean:=initial()
    if r is Dictionary and str(r.get("status","")) in STATUSES:
        clean.status=str(r.status)
        for key in ["eligible_at","answered_at"]:
            if sim.campaign.number(r.get(key)):clean[key]=float(r[key])
        if r.get("channel") is String:clean.channel=r.channel
        if sim.campaign.number(r.get("open_failures")):clean.open_failures=maxi(0,int(r.open_failures))
    out["review"]=clean
