extends "res://tests/playtest/policies/profile_policy.gd"
## Player-profile playtesting (Phase 2): the CASUAL player (`casual-1`).
## "Enjoys progressing but plays intermittently." Default schedule (tests/playtest/profiles.json): about
## 20 active minutes a session, two or three sessions a day; collects offline earnings on every return.
##
## How it differs from Active (active-1), in decisions only:
##  - Attention: reviews gear, missions and the shop once a minute (Active: every 0.5 s); taps loot every
##    1.5 s; casts ready skills every 3 s outside boss fights.
##  - Spending: no savings plan. It works down a natural list and buys what it can afford now: Focused
##    Farming, Gem Chance, one Offline Time level, Auto-Collect for its farm, a little Critical; with Coins
##    the farm type's Enemy XP / Loot / Coin Amount to modest levels, Movement, Map Details, two Offline
##    Coins levels and nearer camps; Coins left over raise the same farm upgrades toward their caps,
##    Movement, Offline Coins and Respawn. Boss potions keep their reserve, as for Active.
##  - Objectives: farms an open daily "defeat" mission's type when it can, claims missions at its passes.
##  - Bosses: wants a wider margin (+0.25), at most two attempts a session, and after a loss waits for the
##    next session. Rests below 30% HP to 80% (between fights, as Active). Two deaths on one type within
##    15 minutes make it farm something else until it gains 3 levels.
##  - Prestige: reads the Prestige panel only at the start of a session, at most once every 20 calendar hours.
##  - Exploration: 90 s bursts every 4 minutes.
## Unchanged from Active: movement, the boss-attempt commitment and retreat rule, the estimates, the gear
## comparison (the game's own stats_with), the next-map rule and the camp choice.

func _init() -> void:
    P={"version":"casual-1","manage_every":60.0,"loot_every":1.5,"cast_every":3.0,"use_coin_boost":true,
        "rest_below":.30,"rest_until":.80,"boss_rest_until":.85,"potion_boss_below":.6,"potion_farm_below":.2,
        "boss_extra_margin":.25,"boss_attempts_per_session":2,"boss_retry_same_session":false,
        "explore_burst":90.0,"explore_every":240.0,"follow_missions":true,
        "prestige_at":"session_start","prestige_gap_h":20.0,
        "cards":["damage","hp","coins","boss_damage","xp","normal_xp","normal_coins","gear_chance","boss_guard"],
        "spend_save":false,"max_buys":3,"manage_on_leave":false,"death_avoid":2}

func gem_wishes() -> Array:
    var out: Array=[{"id":"focus","to":1},{"id":"gem_chance","to":1},{"id":"offline_cap","to":1}]
    if farm_group>=0 and now-farm_since>=600.0:out.append({"id":"collect","group":farm_group,"to":1})
    out.append_array([{"id":"critical_chance","to":2},{"id":"offline_gems","to":1},{"id":"critical_damage","to":2}])
    return out

func coin_wishes() -> Array:
    var out: Array=[]
    if farm_group>=0:
        out.append_array([{"id":"group_xp","group":farm_group,"to":5},{"id":"loot","group":farm_group,"to":4},{"id":"coin_amount","group":farm_group,"to":3}])
    out.append_array([{"id":"movement","to":2},{"id":"map_detail","group":a.stage(),"to":1},{"id":"offline_coins","to":2}])
    out.append_array(_camp_wishes())
    # Surplus: a player with Coins left over keeps raising what it already uses.
    if farm_group>=0:
        out.append_array([{"id":"group_xp","group":farm_group,"to":20},{"id":"loot","group":farm_group,"to":15},{"id":"coin_amount","group":farm_group,"to":20}])
    out.append_array([{"id":"movement","to":6},{"id":"offline_coins","to":8},{"id":"respawn","to":3}])
    return out
