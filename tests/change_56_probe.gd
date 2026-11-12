extends "res://tests/change_20_probe.gd"
## Change 56 (approved progression brief §6): "cheap first five" (Change 71: first three, then a taper to level 8). Levels 1-5 of each enemy type's Coin Amount,
## Enemy XP and Loot Chance cost x0.25 of the existing curve; level 6 onward and every other upgrade are unchanged;
## bought levels are kept by Prestige (Change 50), so a repeat run starts with them; missions keep pricing from
## the current run's map access. Runs with --first-run-complete.
func run() -> void:
    get_window().size=Vector2i(720,1280)
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    await frames(6)
    cost_checks()
    prestige_checks()
    print("CHANGE_56_CHECKS %d FAILURES %d" % [checks,failures])
    game.queue_free();await frames();AudioService.stop_all_sfx();get_tree().quit(1 if failures else 0)

## The pre-Change-56 price (the same formula without the discount).
func plain(id: String,g: int,n: int) -> int:
    var d: Dictionary=sim.catalog.upgrades[id]
    var st: int=int(sim.catalog.groups[g].stage)
    return maxi(1,ceili(float(d.base)*pow(float(d.growth),n)*sim.campaign.map_cost_factor(st)))

func cost_checks() -> void:
    fresh()
    for g in [0,4,11,30,39]:
        sim.state.discovered[str(g)]=true
        for id in ["coin_amount","group_xp","loot"]:
            # Change 71: x0.25 for the first three levels, then a geometric fade to the full price at level 8
            # (the one-step x5.4 jump after level 5 is gone). Computed here independently of campaign.gd.
            for n in range(10):
                sim.state.upgrades["%s:%d" % [id,g]]=n
                var f: float=.25 if n<3 else (1.0 if n>=8 else pow(.25,1.0-float(n-2)/6.0))
                var want: int=maxi(1,ceili(float(sim.catalog.upgrades[id].base)*pow(float(sim.catalog.upgrades[id].growth),n)*f*sim.campaign.map_cost_factor(int(sim.catalog.groups[g].stage))))
                check(sim.upgrade_cost(id,g)==want,"%s level %d on %s: %d (want %d)" % [id,n+1,sim.catalog.groups[g].id,sim.upgrade_cost(id,g),want])
            sim.state.upgrades.erase("%s:0" % id)
    for id in ["supply_drop","skill_drop","spawn_amount"]:
        if sim.catalog.upgrades.has(id) and sim.catalog.upgrades[id].currency=="coins":
            check(sim.upgrade_cost(id,4)==plain(id,4,sim.level(id,4)),"%s keeps its price" % id)

func prestige_checks() -> void:
    fresh()
    sim.state.coins=100000.0;sim.state.discovered["0"]=true
    var spent:=0.0
    for i in range(5):
        var c: int=sim.upgrade_cost("coin_amount",0);spent+=c
        check(sim.buy_upgrade("coin_amount",0),"Buy Coin Amount level %d" % (i+1))
    check(sim.level("coin_amount",0)==5,"Five cheap levels bought for %d coins" % int(spent))
    for run in range(2):
        if not sim.state.bosses_found.has("boss-snowman"):sim.state.bosses_found.append("boss-snowman")
        sim.state.group_kills[sim.campaign.prestige_unlock_group()]=1 # fixture: defeated once (needed since Change 61; added in Change 71)
        sim.state.unlocked_stage=4
        sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0}
        sim.state.consumed.erase("hunter_o1");sim.state.owned_cards=sim.state.owned_cards.filter(func(c):return not str(c).begins_with("hunter"))
        var coins: float=float(sim.state.coins)
        check(sim.campaign.begin_prestige() and sim.campaign.choose_card(str(sim.campaign.offered_cards()[0])),"Prestige %d" % (run+1))
        check(float(sim.state.coins)>=coins and sim.level("coin_amount",0)==5,"Prestige %d keeps the Coins and the five levels" % (run+1))
        check(sim.campaign.reward_stage()==1,"Run %d missions priced from Winter I" % (run+2))
