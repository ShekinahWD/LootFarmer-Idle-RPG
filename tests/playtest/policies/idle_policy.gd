extends "res://tests/playtest/policies/profile_policy.gd"
## Player-profile playtesting (Phase 2): the IDLE player (`idle-1`).
## "Prefers automation and minimal interaction." Default schedule (tests/playtest/profiles.json): 5 to 10
## active minutes a session, once or twice a day; relies on offline earnings.
##
## The game does not simulate combat or farming while closed: offline time only pays the Offline tab's
## hourly Coins and Gems and copies of owned items, up to the purchased cap. So this profile progresses
## through what those rules pay plus its short sessions; nothing else is credited.
##
## How it differs from Active (active-1), in decisions only:
##  - Attention: one management pass at the start of a session, every 2 minutes, and one more right before
##    leaving (to spend before the absence); taps loot every 3 s; never casts by hand outside a boss fight
##    (automatic casting once bought).
##  - Spending: a strict savings plan, automation and offline first. Gems: Focused Farming, Offline Time to
##    level 2, Auto-Collect for its farm, Offline Gems, Offline Weapons and Outfits, Auto-Merge for its farm,
##    Offline Time to 4, mission Auto-Claim, Auto Use, Auto Buy, Offline Supplies and Skills, automatic
##    skills, then Gem Chance and the remaining Offline Time and Gems. Coins: Offline Coins to 3, the
##    offline item rates, then the farm's Enemy XP and Loot, more Offline Coins and rates, Coin Amount,
##    Movement; Coins left over (bought when affordable, never saved for) raise the farm upgrades toward
##    their caps, Offline Coins to 20, Movement and Respawn. Owned automation is switched on (Auto-Claim, Auto Use and Auto Buy for potions, automatic
##    skills).
##  - Play: Auto Farm (Focused Farming) on the best farm as soon as it is owned. It only looks at its HP at
##    a management pass (every 2 minutes): below 35% it walks to a camp and rests to 80%, then farms again.
##    Two deaths on one type within 15 minutes make it farm something else until it gains 3 levels.
##    Short exploration bursts (60 s every 5 min).
##  - Bosses: only when well prepared (+0.35 margin), one attempt a session.
##  - Prestige: at the start of a session, at most once every 20 calendar hours.

func _init() -> void:
    P={"version":"idle-1","manage_every":120.0,"loot_every":3.0,"cast_every":-1.0,"use_coin_boost":false,
        "rest_below":.35,"rest_check":"glance","rest_until":.80,"boss_rest_until":.9,"potion_boss_below":.5,"potion_farm_below":.15,
        "boss_extra_margin":.35,"boss_attempts_per_session":1,"boss_retry_same_session":false,
        "explore_burst":60.0,"explore_every":300.0,"follow_missions":false,
        "prestige_at":"session_start","prestige_gap_h":20.0,
        "cards":["coins","normal_coins","damage","hp","xp","normal_xp","boss_damage","gear_chance","boss_guard"],
        "spend_save":true,"max_buys":4,"manage_on_leave":true,"death_avoid":2}

func gem_wishes() -> Array:
    var out: Array=[{"id":"focus","to":1},{"id":"offline_cap","to":2}]
    if farm_group>=0:out.append({"id":"collect","group":farm_group,"to":1})
    out.append_array([{"id":"offline_gems","to":1},{"id":"offline_weapon","to":1},{"id":"offline_outfit","to":1}])
    if farm_group>=0:out.append({"id":"merge_gear","group":farm_group,"to":1})
    out.append_array([{"id":"offline_cap","to":4},{"id":"mission_claim","to":1},{"id":"auto_use","to":1},{"id":"auto_buy_slots","to":1},
        {"id":"offline_consumable","to":1}])
    if a.skills_seen():out.append_array([{"id":"offline_skill","to":1},{"id":"skill_auto_slots","to":1}])
    out.append_array([{"id":"gem_chance","to":1},{"id":"offline_cap","to":6},{"id":"offline_gems","to":5}])
    return out

func coin_wishes() -> Array:
    var out: Array=[{"id":"offline_coins","to":3},{"id":"offline_weapon_rate","to":2},{"id":"offline_outfit_rate","to":2}]
    if farm_group>=0:out.append_array([{"id":"group_xp","group":farm_group,"to":5},{"id":"loot","group":farm_group,"to":3}])
    out.append_array([{"id":"offline_coins","to":6},{"id":"offline_consumable_rate","to":2},{"id":"offline_skill_rate","to":2}])
    if farm_group>=0:out.append({"id":"coin_amount","group":farm_group,"to":3})
    out.append({"id":"movement","to":1})
    # Surplus (never saved for): Coins left over go to the farm, then more offline Coins and Movement.
    if farm_group>=0:
        out.append_array([{"id":"group_xp","group":farm_group,"to":20,"save":false},{"id":"loot","group":farm_group,"to":15,"save":false},
            {"id":"coin_amount","group":farm_group,"to":20,"save":false}])
    out.append_array([{"id":"offline_coins","to":20,"save":false},{"id":"movement","to":6,"save":false},{"id":"respawn","to":3,"save":false}])
    return out
