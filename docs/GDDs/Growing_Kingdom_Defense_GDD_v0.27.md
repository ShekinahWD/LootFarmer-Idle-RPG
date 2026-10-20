# Growing Kingdom: RTS, Game Design Document

**Working title:** Growing Kingdom: RTS  
**Project:** Godot-GrowingKingdom  
**Document version:** 0.27  
**Status:** Current design authority. v0.27 adds the game's localization into the 20 approved languages (§66) and refreshes the store media to the newer readable-card and social-video standards (§67); no gameplay, balance or save change. v0.26's §65 stays in force except where §67 supersedes it; v0.25's §64 stays in force. Earlier versions are retained as history.
**Primary platform:** Android-first  
**Orientation:** Landscape  
**Reference layout:** 1920×1080  
**Current authored content target:** 100 waves/stages  

---

## 1. Game Identity

### 1.1 High concept

A kingdom-management and defense game played on one continuous world: the player builds a small resource economy in the kingdom (the upper, larger part of the map) and defends a Castle from escalating enemy waves on the battlefield below it, moving freely between the two with a pan/zoom camera.

The kingdom is not a separate meta menu. It is the live economy that sustains the battlefield. Villagers gather resources, construct and upgrade buildings, increase population, and support the production of military units. The player spends those resources to train units at military buildings through configurable deployment cards; trained units walk out of their building, through the Castle and onto the battlefield.

As progression advances, the player gradually automates both halves of the game. The long-term fantasy is to evolve from manually managing individual villagers and deployments into managing priorities, deployment rules, production bottlenecks, formations, and high-level strategy.

### 1.2 Player fantasy

> Build a kingdom under pressure, turn its economy into an army, automate the war machine, and see how long the kingdom can survive.

### 1.3 Design pillars

1. **Two systems, one economy.** The kingdom and battlefield are always connected.
2. **Management over direct combat control.** Units fight automatically; the player controls preparation, production, deployment, priorities, upgrades, and automation.
3. **Every run rebuilds.** The kingdom is temporary. Permanent progression makes each rebuild faster, stronger, and strategically broader.
4. **Spatial economy matters.** Resources grow in the kingdom's corners and which corner holds what changes each run, so building placement and travel distance affect efficiency.
5. **Automation is progression.** Manual actions gradually become configurable systems rather than disappearing behind a generic auto-play toggle.
6. **Prestige changes possibilities.** Glory Upgrades improve numbers; Prestige, earned by conquering a rival kingdom (§54), unlocks major systems, automation, and large strategic advantages; Ascension, earned by conquering the final rival with every Prestige (§20.9 as of v0.23), adds a Crown and a Decree and starts the climb again.

---

## 2. Core Loop

```text
Start with Castle + House + Barracks + Villager
→ inspect this run's corner resources (which corners hold Gold)
→ assign Villager task priorities
→ gather Wood / Gold / Food
→ place construction projects
→ builders construct prioritized projects
→ improve gathering and population
→ build military production
→ configure deployment cards in Castle
→ spend kingdom resources to train troops at their buildings
→ troops walk out through the Castle and fight enemy waves by stance
→ upgrade buildings / troops / economy during the run
→ enemy pressure increases through new archetypes and larger compositions
→ Castle eventually reaches 0 HP
→ enemies breach the defense line and destroy the kingdom visually
→ calculate run rewards and salvage
→ spend permanent currency
→ possibly commit a Prestige (a deeper reset)
→ begin a stronger new run
```

**The long loop (v0.18, §54).** Develop the kingdom and survive its waves, prepare an invasion army, plan the assault at any time, launch it once the current wave is cleared, cross from our beach to the rival's, command the assault, destroy the rival Castle: the rival kingdom falls, the waves stop for good, and a Prestige is ready, taken at once or later in peace. The Prestige creates the next, stronger rival. **The longest loop (v0.23, §20.9):** the 33 Prestiges reach Rival 34, the final rival; conquering it offers an Ascension (a Crown and a Decree of the player's choice), which resets the Prestige layer and starts a new ascent at Rival 1, nine times at most.

The kingdom and battlefield continue progressing regardless of which part of the world the camera shows.

---

## 3. Screen Structure

### 3.1 One world, one camera

The gameplay screen shows **one continuous world**: the kingdom above, the Castle and its defensive row at the boundary, the battlefield below. There are no Kingdom / Both / Battle view modes and no split screen.

The player navigates with a real camera:

- one-finger drag pans (mouse drag on desktop);
- pinch zooms around the pinch centre (mouse wheel on desktop);
- a tap selects what is under it; a drag never selects and a tap never pans;
- the camera is clamped so the world always covers the free screen area, with a small margin so objects near the edges are never hidden under the HUD;
- the minimum zoom shows the whole world width (cover fit); the maximum zoom is readable pixel art.

The first view of a run frames the Castle with the kingdom above it and the battlefield front below.

### 3.2 World proportion

At the normal zoomed-out view the world is roughly **65% kingdom and 35% battlefield** by height. The kingdom is wide and uses most of the map; the battlefield is a band below the Castle.

The Castle sits on the kingdom's lower edge. Below it, the cliff opens into a **wide lower Castle entrance** (a ramp at least six tiles wide) so troops leave the Castle comfortably, and the gate area is easy to see and select on a phone.

Water is a thin frame, not a large part of the map.

### 3.3 HUD

A compact top bar always shows:

- Wood, Gold and Food: the stored amount first and largest, the shared storage limit small beside it, a storage-full warning, and under it **how many Villagers are assigned to that resource** (a Villager icon and a count) with the net rate. The count is **workforce allocation, not momentary production**: it is read from each Villager's assigned task (its first priority, what its task button shows; for a Smart Villager its current commitment, §7.6), never from what it is doing this instant. A Villager assigned to Gold counts on the Gold chip while it walks, gathers, carries, waits on full storage or waits for a node. The count changes at once when a Villager is reassigned, recruited, dies or is removed; Villagers assigned to Build count on no chip. Tapping a resource chip opens Villagers;
- population used / maximum and idle-Villager warning; **tapping the population opens a breakdown**: an icon and a count per unit type (Villagers, Warriors, Archers...), with the number still in training;
- current wave and its state (countdown, enemies left);
- Castle HP, in one chip with the wave (its presentation is the one it had before v0.11: the Prestige block never takes room from it);
- Glory. **A ? beside the Glory icon (v0.23):** a small ? on the Glory icon's corner; the icon's column (the chip's left edge up to the amount, at least a finger wide, the chip's full height) is its own touch target, on top of the chip, and shows a short note under the chip for a few seconds: "Glory is earned from battles, missions and offline rewards. Spend it on Glory Upgrades: they survive a defeat but reset when you Prestige." It never opens the shop or buys anything, and a tap on the amount never shows it; it adds only a small gap after the icon (no separate button in the top bar); it is in every onboarding mode (not a hint), and shows with the chip (first-run disclosure). **The Glory chip is a button (v0.22, §18.3):** without Royal Provisioning a tap says "Buy Glory Upgrades between runs. Royal Provisioning unlocks in-run purchases." (no permanent locked label); with it, a tap opens or closes the in-run **Glory Upgrades** panel, and a short line under the amount says where the run's purchases stand, never a timer: **NEXT W10** before the next tenth wave, **1 EARNED** when a purchase is earned but nothing is affordable, **1 READY** (or 2, 3...) when one can be bought now, then the gold **+** badge too, **ALL USED** once the run's ten are spent; with the **Glory of Kings** Decree (v0.23) the shop has no allowance and the line reads **OPEN** (with or without Royal Provisioning). The line has a fixed width (the widest text it shows), reserved also without the card (the line is then empty), so neither its text nor gaining the card ever resizes the chip or moves the Prestige block;
- the **Prestige block** (as of the Android corrections, §45; its bar as of v0.18), its own element between Glory and the Wave / Castle HP chip, so the top bar reads Resources, Population, Glory, Prestige, Wave / Castle HP, controls. A persistent **PRESTIGE** title is centred over a gold bar and, immediately beside the bar, the **Prestige ranks owned out of the 33 the game holds** ("7 / 33"). Inside the bar, centred: the rival to conquer for the next Prestige (**RIVAL 8**; **RIVAL 34**, the final rival, once all 33 ranks are owned), **READY** while an offer waits (the bar full), **ASCEND** while an Ascension waits (v0.23, the bar full; tapping the block opens it), **COMPLETE** once the account is fully Ascended with every rank owned (§54.12). Every part has a fixed size, so no state change resizes or moves anything in the top bar; it is somewhat larger than a resource reading for phone readability, but is plated differently and carries no resource icon, so it never reads as a resource card. On the narrowest screens (a 16:9 phone beside a notch) the block scales down as one piece rather than pushing the controls off screen. A small **ⓘ** sits in its upper right. **Two touch targets (v0.19):** the block's right column (the ⓘ over the rank counter, at least a finger wide, the block's full height) is its own button and always opens the **Prestige Upgrades** panel (§20.8; "Owned Prestiges" before v0.20), or, with no rank owned, says "No Prestige Upgrades yet." just under the block instead of opening an empty panel; the rest of the block is the Prestige action: with Prestige **READY** it opens the waiting Prestige offer (also after "Stay in peace"), otherwise the same information as the ⓘ. The ⓘ pulses gently until the player has used this once (either way counts), then stays still for good; that discovery is saved with the profile;
- a **Pause** button (the player's own pause: everything stops, the music holds where it is (v0.21, §59.5), a "Paused" banner shows, and it holds until the player resumes, even across other modals). The Pause is a **gameplay lock** (§3.5a): while it holds, nothing that changes the game can be done. Game speed and settings.

A tool dock opens side panels (Projects, Villagers, Army, **Attack** (the Assault Planner, v0.18, §54.3), Upgrades, Research, Castle, Missions, Bestiary, Stats) and, as of v0.15, toggles the **Build Shelf** (Build, §5.2, §27.1d). With eleven tools its buttons are 76 px high (the smallest touch target) so the dock still fits a 1080 px screen. Deployment cards sit on a rail at the side: **all six Train places at all times (v0.23, §13.4)**, the Active Train Slots first and the places still locked after them. Panels never pause the game; only true modals do (§3.5).

**First-run disclosure (v0.12).** On a pristine profile's first kingdom the HUD shows only what the first-run progression has revealed (§27.5): in Settlement the resources, population, Pause, speed, Settings and the Build, Projects and Villagers tools, with a compact objective card where the Train rail will be; Defense Preparation adds the Train rail, Army and Castle; once the first invasion's countdown starts, everything above shows, for good.

The count on a resource chip follows a **direct world order** (§7.4d) while one is active: a Villager ordered onto a Tree counts on Wood, one ordered onto a construction counts on no chip, one moving or holding counts on none, whatever its Smart commitment or Manual list says.

Tapping a building or a resource node opens a **context panel** for it with its live state and its actions, each action disabled with a reason when unavailable. **A Villager or a soldier is different (v0.15):** selecting a friendly is command mode, so it opens no panel; a compact **Selection Status** shows instead, and the friendly's context panel (the same card) opens only from that status's **Details** (§12.7). A context panel is **as tall as its content** (one visual family, consistent padding, no large empty paper) and **appears at that size** (§27.1e); only content longer than the screen scrolls. It leads with the one value that matters most, in large type ("14 / 21 Wood", "+5 Population"), and a short supporting line. A Villager's card also offers Recruit.

### 3.4 Battlefield information

**CASTLE UNDER ATTACK (v0.21).** While hostile blows land on our Castle walls, a compact red **⚠ CASTLE UNDER ATTACK** chip shows at the top of the map, in the notification band (under the Paused banner, above the toasts): a state, not a toast, never dismissed, never taking input, clear of the Castle, the selection status, the Build Shelf, the objective card and the Prestige block. It stays through the ordinary gaps between blows (it holds 2.5 simulated seconds after the last hit, longer than the slowest attacker's interval) and goes once the blows stop. The `warning` cue plays once as an attack begins, never per hit; each blow is heard through the Castle Damage pool (§59.4). It is presentation derived from the hits, not saved: after a reload it comes back with the next blow.

The top bar and context panels cover the former battlefield hub: wave, Castle HP, enemies alive, Glory earned, automation status (on the deployment rail) and warnings for Boss, Elite or newly introduced enemies (toasts and introduction cards).

**First-wave warning (every run).** A few seconds before wave 1 of every run begins, a warning shows: **ENEMIES APPROACHING**, "Prepare your defenses", on a red ribbon at the top of the map. At the same time the band at the bottom of the battlefield where the enemies are about to appear pulses red, with chevrons climbing toward the Castle: the **danger zone**. When that band is off screen, a "▼ Enemies" button looks at it in one tap. The ribbon and the button stay briefly into the wave, while the first enemies step out of the marked band, then go away. The ribbon shows exactly once per run (a reload inside its window shows the rest of it; it never recurs later that run), never pauses and takes no input.

**The danger zone lasts three waves (v0.7).** Once raised, the marked band stays for **three waves**: the wave it was raised for counts as the first (the first-wave warning raises it for waves 1, 2 and 3), and it stays through the next two, including the pauses between waves; it never flickers off in between. It goes the moment the last wave of its window is cleared, unless something else requires it. If a legitimate trigger comes again while it is up, the three waves are counted again from that newest trigger; a trigger never shortens what is left. The window belongs to the saved run: a reload keeps exactly what is left of it, neither ending nor restarting it. It is presentation only: no enemy value depends on it.

### 3.5 Continuous simulation rule

Opening menus or panels, or moving the camera away from a part of the world, does not pause any gameplay system unless a true modal/pause state explicitly owns the pause.

### 3.5a Pause is a gameplay lock

The player's Pause stops the simulation **and** every action that would change the game, so pausing can never be used to keep progressing a frozen kingdom. The rule belongs to the game's action layer, not to buttons: any path to an action (a panel, the HUD, a shortcut) is refused the same way, with one short reason: **"Unavailable while paused"**.

- **Allowed while paused:** reading everything (Stats, the Bestiary, Missions and their progress, Villager, Army, building and resource information, context panels), opening and closing informational panels, Settings, game speed, and Unpause.
- **Refused while paused:** recruiting; training (Train cards and building Train buttons) and cancelling training; placing, upgrading, cancelling, reordering or demolishing buildings; run upgrades, research and permanent upgrades; claiming missions; assigning or reassigning Villagers, the default task and Apply to all; stances, squad orders, formations, creating or disbanding squads; editing Train cards, their slots and the automation program; Prestige; ending a victory run; skipping the overrun; any equivalent economic or progression action.
- A paused screen says so once (a "Paused" tag on the open panel, the banner on the map) and its action buttons are off with the reason; the refusal does not depend on those buttons being off.
- The lock covers only a run in progress: the results screen, the Prestige and Ascension choices and the offline reward are decisions of their own modals, and a finished run releases the Pause.

---

## 4. Run Structure

### 4.1 Run start

A fresh run begins with:

- Castle
- 1 House
- **1 completed Barracks** (the baseline Barracks, see below)
- 1 Villager (assigned to Build during the first-run progression, §27.5: with nothing to build yet, it waits)
- this run's corner resource profiles (§5.4)
- default starting resource amounts
- 1 active deployment slot
- 2 saved deployment-card configurations
- only systems currently unlocked by permanent and Prestige progression

**Baseline Barracks.** To reduce early overload, every new run (whatever the tutorial mode, every later run and every post-Prestige run) starts with one Barracks already built beside the Castle. It is an ordinary Barracks in every respect except that it costs nothing and returns no refund or Salvage. No duplicate is ever added. **Every tutorial mode starts the same kingdom (v0.12):** the Guided first run no longer starts without it; the modes differ only in how much help they show (§27.5, §35).

**Random start plots (v0.7).** The starting House and the baseline Barracks no longer stand on fixed spots. The map has a set of authored **start plots** around the Castle (editor-visible markers with stable ids, §5.1), each on open kingdom ground, clear of the reserved zones, the herds, the corner resources and each other. When a new run is created it picks two different plots at random from the run's seed, one for the House and one for the Barracks, and each is checked with the ordinary placement rule (§5.2); both buildings always exist. The choice is part of the saved buildings: reopening the game, reloading or rebuilding the world restores the same places and never picks again; only the next new run picks anew. Everything else about them (selection, demolition rules) is unchanged.

Permanent upgrades may later improve the starting state, including:

- additional starting Villagers
- additional starting resources
- improved starting Castle HP
- prebuilt or partially preserved buildings
- additional deployment capability
- improved salvage

A higher **starting Castle tier** is not a permanent upgrade (v0.8): building tiers are Prestige progression (§11.4), and starting a run with the Castle already at a higher tier belongs to Ascension, the layer above it (the Ancient Foundations Decree, as of v0.23 every new building at Tier 2 once Advanced Construction is owned, §20.9).

### 4.2 Run loss condition

The run ends when **Castle HP reaches 0**.

### 4.3 Defeat presentation

Castle destruction is not an immediate static game-over screen.

After the Castle falls:

1. enemies visibly pass the destroyed Castle;
2. they enter the kingdom section;
3. they attack Villagers;
4. they destroy buildings;
5. the destruction communicates that the current run-state kingdom is being lost;
6. the results/reward flow follows.

The first defeat shows the sequence normally. After the player has seen it once, controls become available to:

- accelerate the destruction sequence;
- skip the sequence.

### 4.4 Run reset

A new run resets:

- buildings and building tiers;
- construction queue/progress;
- Villagers and their run-state assignments;
- military units;
- battlefield state;
- Castle run HP/tier;
- Wood / Gold / Food held during the run, except explicitly salvaged value;
- run research;
- run upgrades;
- current wave progression;
- training queues, squads and unit stances;
- resource-node stock, depletion and respawn timers, and the corner resource profiles (re-rolled).

The permanent/meta layer survives.

### 4.5 Current 100-stage scope (as of v0.18)

The production scope contains **100 authored waves/stages** (v0.4; it was 50 in v0.3).

**Wave 100 is a milestone, not the end (v0.18, §54.11).** Clearing it shows no completion message, offers no Ascension and ends nothing: it cuts the current rival's reinforcement reserves once (§54.11), says so, and the waves go on. Past the authored table the last ten waves repeat (101 is wave 91 again, 110 is 100, 111 is 91), a bounded late-game pressure that never grows further, until the rival falls (§54.6), which stops the waves for good.

The run's end is either a defeat (the Castle at 0 HP, §4.2) or a Prestige taken after a conquest. The former victory lap (v0.7) remains in the code only so an older save resting on it resumes as ordinary play.

**Ascension (Super Prestige)** is redesigned in v0.23 (§20.9): it is earned by conquering the final rival, Rival 34, with all 33 Prestige ranks owned, never by a wave.

Castle destruction remains the established normal run-loss condition.

---

## 5. Kingdom Map and Placement

### 5.1 Map scale and composition

The kingdom map is intentionally compact so the whole economy reads quickly on a phone, but it is the larger part of the world (§3.2). The map is authored in the editor as a scene with stable ids: resource zones, every resource site, the Tower slots, the start plots (§4.1: the House and the baseline Barracks take two of them each run) and the Castle attack positions. Runtime code never invents positions; a saved run refers to sites by id, so reopening the game restores the same nodes.

Zones:

- **four corner resource zones** (north-west, north-east, south-west, south-east);
- **the central kingdom**: buildings, plus the two small **herd areas** where the sheep graze (§5.5); no trees or Gold;
- **the Tower strip** on both sides of the Castle: Towers only;
- **the Castle and its approach lane** (the troop lane to the Castle's back door): nothing may be built there.

### 5.2 Build mode

Buildings are placed freely on the kingdom ground in a **build mode**:

- **the Build Shelf (v0.15).** The Build tool toggles a horizontal shelf of building cards along the bottom of the free map area (§27.1d); the world stays visible and playable above it. **Tapping a card** opens build mode for that building, as choosing it in the old Build panel did. **Dragging a card upward** out of the shelf (steeper than 45°, past a small dead zone) lifts the building into the same build mode: its preview follows the finger over the map with the same validity, and **releasing over valid ground places it through the same action as Place** (charged once, a construction project, Villagers still build it), after which build mode stays for the next one. Released on invalid ground, nothing is placed or spent: build mode stays there and says why. Released back over the HUD or the shelf, nothing is placed. A sideways drag on the shelf scrolls it and never chooses or lifts a building; a drag decided as a scroll never becomes a lift, nor a lift a scroll; a second finger, a modal or closing the shelf cancels a lift without placing. **Buildings already placed are never moved**: dragging only ever lifts a new building from the shelf. Tap, then Place, stays the taught path; the drag is a shortcut into the same mode;
- choosing a building opens build mode with a preview; the mode **stays active after each placement** so several buildings can be placed in a row, and ends only when the player taps **Exit Build Mode**, picks another building or leaves build mode (v0.12: the button no longer says "Done", which players read as confirming the building; **Place** is what places it); when another copy cannot be placed right now (cost, limit, Tower capacity, no free ground), the mode stays open and says why;
- the preview follows a tap or a drag started on it;
- the shelf stays open in build mode, its current building's card marked, so another card switches the building; **Exit Build Mode** ends build mode and leaves the shelf open; tapping Build again closes the shelf (and, in build mode, ends it); opening a panel closes the shelf;
- on entering build mode, every area that cannot hold the chosen building is shown immediately (red), and valid ground is marked; the overlay uses exactly the same validity check as placement. **It is re-evaluated only when a placement blocker changes (v0.21):** a building placed, cancelled, demolished or destroyed, the resource nodes created or loaded; never on unrelated state changes (a death, a delivery). The preview's own answer is kept while it stays on the same spot, so build mode costs about what play costs;
- **four direction arrows** move the preview to the nearest valid spot in that direction (straight line first, then the nearest valid spot in that direction's cone). If there is none, the arrow explains that there is no space that way;
- Place is disabled with a reason while the preview is on invalid ground.

Placement must respect:

- building footprint overlap;
- resource-node overlap (sheep never block, see §5.5);
- each resource's **build clearance** (v0.19): a building (its whole drawn height, plus a little ground below its base) may not cover a tree's **working core**, its trunk, the two stands a Villager chops from and its lower canopy, nor any part of a Gold deposit's rock. A tree's upper canopy may overlap a building: whichever stands lower is drawn in front and takes a tap where both are (a tree in front of a House takes the tap on its canopy, a House in front of a tree its roof). So a House may stand along a tree line, while a deposit keeps the clearance of its whole rock. One rule serves the preview, its overlay, the recommended spots, the start plots and the probes;
- map bounds;
- the reserved zones (Tower strip, Castle and its approach lane).

### 5.3 Reserved defensive row

The row adjacent to the battlefield is structurally reserved. It contains:

- the Castle / Command Center;
- the authored Tower slots (Tower strip).

Ordinary economy and production buildings cannot occupy this strip, and resource nodes never spawn there.

### 5.4 Corner resource zones

Trees and Gold grow **only in the four corner zones**; the middle of the kingdom is kept for buildings.

- Each corner zone has authored site sets (profiles): a **forest** (trees) or a **quarry** (Gold deposits with a fringe of trees).
- Each run, one northern and one southern corner become quarries and the other two are forests. The choice comes from the run seed and is saved with the run, so reopening never rerolls it; a new run rolls again.
- The Castle, its approach lane and the Tower strip are excluded.
- Node positions are authored and editor-visible; only which profile is active varies.

The purpose is still to make efficient building placement differ from run to run: where to put the Mining Camp and the Lumber Camps is a fresh decision.

### 5.5 Sheep and herds

Sheep (Food) live in **authored herds**: two herds of five, each grazing inside its own small area of the kingdom (authored, editor-visible zones with stable ids, like the corner resource zones). They are moving animals, not decoration.

- A herd moves as a group: each sheep's next grazing spot is near the herd's current centre and inside its area, so the animals drift together and never spread over the kingdom.
- Sheep **never block construction**. Placement validity ignores them.
- When a building is placed over a sheep, the sheep walks out to free ground (visibly, never teleporting), preferring ground inside or just around its herd's area; only when that is all taken does it look further. Any Villager working it re-targets. No sheep is ever left inside a building.
- When buildings cover a herd's area, the herd grazes just around it.
- A sheep that has been eaten (depleted) returns near its authored home after its timer.

---

## 6. Resources and Storage

### 6.1 Run resources

The core kingdom resources are:

- **Wood**
- **Gold**
- **Food**

They are run-state resources and normally reset after defeat, except for Salvage.

### 6.2 Resource nodes

Resource nodes (trees, Gold deposits, sheep):

- hold a **finite stock**; each gather removes a load;
- are **claimed** by the Villagers working them; claims never reserve more stock than the node holds, and Villagers spread over nearby nodes (a free node first, the nearest few candidates) instead of crowding one;
- become **unavailable when depleted** (a stump, an empty rock, a missing sheep) and **return after a timer**; the timer and the returned stock are effective values that upgrades can improve (regrowth speed, richer nodes);
- give readable work feedback: Villager chop/mine/harvest contact frames, a small hit reaction on the node and a delivery number showing the credited amount. The feedback follows the simulation and never changes its timing.

Exact stock, yield and respawn values are balance data and not design contracts.

### 6.3 Storage capacity

The run has finite storage capacity.

When storage is full:

- Villagers cannot complete additional deliveries into storage;
- gathering becomes unavailable when no valid delivery can be completed;
- ordinary resource spending can create space again;
- no gathered resource is silently deleted.

If a Villager is already carrying resources when capacity becomes unavailable, the Villager retains the carried load until it can be deposited. A load dropped on the ground by a reassigned Villager (§7.4b) likewise waits there until its resource has room.

### 6.4 General and specialized drop-offs

Travel distance is part of the economy.

**House**

- accepts Wood, Gold, and Food;
- gives no delivery-yield bonus;
- also increases population capacity.

**Lumberjack / Wood drop-off**

- accepts Wood;
- Tier 1 begins with a **+20% Wood delivery bonus**;
- higher-tier values are balance data.

**Gold gathering building**

- accepts Gold;
- Tier 1 begins with a **+20% Gold delivery bonus**;
- higher-tier values are balance data.

**Food gathering building**

- accepts Food;
- Tier 1 begins with a **+20% Food delivery bonus**;
- higher-tier values are balance data.

Villagers prefer an appropriate nearby drop-off according to the runtime targeting rules. Efficient players can build specialized resource districts close to favorable resource clusters.

### 6.5 Delivery bonus ownership

A specialized gathering bonus belongs to the **building instance receiving the delivery**, not to the kingdom globally.

This allows placement and upgrading of individual gathering buildings to remain strategically meaningful.

---

## 7. Villagers

### 7.1 Villager role

Villagers are the worker population responsible for:

- Wood gathering;
- Gold gathering;
- Food gathering;
- construction;
- any later worker tasks explicitly added to the design.

### 7.2 Priority system

Each Villager has an ordered task-priority list.

The Villager performs the first configured task that is executable at that moment.

Example:

```text
1. Build
2. Gather Gold
3. Gather Food
```

If no construction is currently available, the Villager falls through to Gold. If Gold cannot be gathered/delivered, it falls through to Food.

A load in the Villager's hands that its storage cannot take does not stop the fallthrough: the Villager puts it down and goes on to the next task that can run, and keeps it only when no other task can (§7.4c).

### 7.3 Priority progression

Early progression starts with only **one Villager priority slot**.

The permanent upgrade **Villager Task Slots** is the only source of further manual priority slots (v0.11): two levels, so three places at most. Smarter automation is a separate Prestige unlock, **Smart Workforce** (§7.6), which adds no slot.

This turns worker intelligence into progression rather than giving complete automation from the beginning.

### 7.4 Re-evaluation

Villagers re-evaluate priorities at sensible work-cycle boundaries rather than every frame, including after:

- completing a delivery;
- completing a work cycle;
- a construction project changing;
- its target becoming invalid (a node emptied, a storage filling up on the way to it);
- a direct player configuration change, which takes effect **at once** (§7.4b);
- a direct world order starting, completing or losing its target (§7.4d).

### 7.3a Recruiting takes time

Recruiting a Villager is paid in Food when it is ordered and takes a short **creation time** at a House: each House creates one Villager at a time, several Houses in parallel, and the Villager walks out of that House when it is ready. A Villager in creation holds its population place; each one in line costs a little more; a queued recruit can be cancelled for a full refund from the House's panel. Recruiting shows its progress in the Villagers panel and on the House.

### 7.4a Task commands

Tapping a Villager selects it and opens its context panel: its current task, who is in charge of it (§7.4d), its carried load and a one-tap task choice (Build, Wood, Gold, Food) that sets its first priority by the place rule below. Villagers can also be commanded together (§12.7): Villagers form worker squads that share a task.

**A task command edits a place; a work order moves a task to the front (v0.13).** The one-tap task choice, the dropdowns, the Multi-Select task commands, crew commands and the default selector are task commands: they edit one place of the Villager's standing Manual list by the **swap rule** below. Tapping the world with a Villager selected is a different thing, a **direct world order** (§7.4d). A Move or a delivery leaves the list alone; a **work order** (gather a node, build a project) also makes its task the Villager's first priority by a different rule, **move to front** (§7.4e), so the Villager keeps preferring that work once the exact target is done. The two rules are deliberately distinct and are never merged. Neither edits a Smart Villager's list nor its mode.

**Task selection is direct, never cycling.** In the Villagers panel every task place (a Villager's priorities, and the default task that new Villagers get) is a task button showing the task's icon and short name. Tapping it opens a compact dropdown anchored to that button listing every task the game currently allows (read from the game's own list, never hardcoded), each with its icon and short name, the current one marked. One tap on a task assigns it at once and closes the dropdown; a tap outside it, Escape or the Android Back button closes it with nothing changed. A task that cannot run right now stays selectable (an assignment is a standing preference and the Villager falls through, §7.2) and shows a few words saying why ("Storage full", "Nothing to build"). A later priority place can also be set to None.

**Picking a task that is already in the list swaps (v0.7).** A choice is never refused because the task is used in another place. The chosen task always lands in the place the player edited; if it already sat in another place, the two swap (the task that was in the edited place moves to the chosen task's old place), so no task appears twice. Example: Gold → Food → Build, place 1 set to Food, gives Food → Gold → Build; place 2 set to Build gives Gold → Build → Food. Picking the task a place already holds changes nothing. A list has no gaps: emptied places close up, so a task moved into an empty place settles at the end of the list, and the first place always holds a task. One rule serves every surface that edits a list: a Villager's dropdowns, the one-tap task choice on its card (place 1), Multi-Select and worker-squad commands (place 1 of each Villager's own list) and the default selector. A swap is a reassignment like any other: it takes effect at once (§7.4b). A Smart Villager's list is not edited by any of them (§7.6).

**The default for new Villagers is saved when it is chosen (v0.7, user request).** Picking a task in the default selector sets the default at once: it is saved with the profile, the Villagers panel shows it when reopened, and every Villager recruited from then on gets it. Villagers already working keep their own lists; only **Apply to all** gives the default to every one of them. Changing the default is refused while paused, like any assignment (§3.5a).

**One New Villager card (as of the follow-up corrections, §46).** The default selector is the **New Villager** card, the single configuration surface for Villager assignment: what it shows is what a recruit joins with, and **Apply to all** gives the same thing to every existing Villager (with Smart Workforce, its mode too, §7.6). There is no second bulk card. Its priority places sit **side by side on one line**, in priority order from the left, each a dropdown of **one shared width** sized for the longest label any place can show (icon, Build, Wood, Gold, Food or None, the dropdown arrow), never stretched across the card and never shortening a name; **Apply to all** is a compact button on the right of the same line:

```text
New Villager                     [ Manual ] [ Smart ]
[ Build v ] [ Wood v ] [ Gold v ]        [ Apply to all ]
```

With fewer places unlocked the line simply holds fewer dropdowns. The line fits 1, 2 and 3 places at the 1920×1080 reference, a wide phone and the narrowest supported phone layout (16:9 with a notch) at full text size; the dropdowns there use a slightly smaller icon and caret than the Villager rows to make room.

The Villagers panel is one stable screen whose data changes (§27.1e): the population and Recruit (with one status line: the next recruit's countdown, "Recruiting Villager · 8s", or why Recruit is unavailable) and the New Villager card with Apply to all stay pinned at the top at a fixed size; below them the Villager list scrolls on its own, and recruiting adds a row to it without rebuilding anything else.

### 7.4b Reassignment takes effect at once

Changing a Villager's assignment (its task button, a dropdown, Apply to all, a worker squad's task, a Multi-Select command) never waits for the Villager to finish what it is doing:

```text
task changes
-> a carried load the new task does not deliver is dropped on the ground where the Villager stands
-> the old target and claim are released
-> the new task starts now
```

- The dropped load keeps its **exact resource and amount**; nothing is destroyed or duplicated. If the Villager is carrying the resource its new task gathers, it keeps the load and delivers it first, as before.
- A dropped load is an ordinary pickup in the world, drawn with the pack's own resource pickup art and its amount. Any Villager whose task gathers that resource collects it before going to a node (the Villager that dropped it too, once given a compatible task) and delivers it like any load; a pile larger than one trip is collected over several trips. While storage for that resource is full, the pile waits.
- A load dropped beside a pile of the same resource joins it. When several Villagers change task at once, each one's load is dropped exactly once.
- A small cue shows what happened: the pile pops onto the ground with a puff and "Dropped 7 Wood" rises from it.
- Dropped loads are saved with the run and restored exactly (§22.3); a new run starts with none.

### 7.4c A blocked load does not block the list (§47)

A Villager carrying a load whose storage is full (or that no drop-off accepts) does not stand holding it while another of its tasks could run:

```text
carrying A, and A cannot be delivered now
-> another configured task is executable?   (the first one in priority order; A itself is not)
   put A down where the Villager stands as an ordinary dropped load (§7.4b), then start that task at once (Build included)
-> nothing else is executable: keep A and wait for room ("Storage full: holding 7 Wood")
```

- Example: **Wood → Gold**, carrying Wood, Wood storage full, Gold can be gathered: the Wood is dropped and Gold starts. If Gold is blocked too, the Villager keeps its Wood and waits; when either frees, it delivers the Wood or drops it for Gold.
- Example: **Wood → Build**, carrying Wood, Wood storage full, a project to build: the Wood is dropped and Build starts. Build is no exception: one rule for every task.
- The rule is the same for every resource. It is a fallthrough, never littering: a load is put down only when that lets another task run.
- The dropped load is the ordinary pickup of §7.4b: exact resource and amount, collected (by any Villager on that resource) once there is room. Storage + carried + on the ground never changes because of it.
- It is checked at the Villager's normal decision points: after a gather, on arriving at a full drop-off, when the storage fills while it walks there, and every second while it waits holding a load.
- Smart Villagers follow the same rule with their own decision (§7.6).

### 7.4d Direct world orders (v0.12)

RTS-style control on top of the automation, never instead of it. With **a Villager selected** (or several, in any selection of friendlies, §12.7 as of v0.14), a tap on the world orders it:

```text
direct order active?  -> serve the order
else Smart?           -> the Smart allocation (§7.6)
else                  -> the Manual priorities (§7.2)
```

| Tap | Order |
|---|---|
| walkable kingdom ground | **Move**: walk there and **hold** that ground ("Holding Position") until Resume Work or another order |
| a Tree, Gold Deposit or Sheep | **Gather that exact node**: release the old target and claim, walk to it, gather, deliver through the normal drop-offs, and come back to the same node while it has stock |
| a construction or upgrade under way | **Build that project**, even when it is not the queue's first; ordinary Build workers keep the queue's order |
| a completed building that accepts the load carried | **Deliver** the load there, once, through the normal delivery; then the order ends |
| a completed building otherwise, another Villager, a soldier | the usual selection, no order |
| ground off the kingdom (water, the battlefield) | deselects, as before |

- **An override first.** An order never changes the Smart mode, and a Move or a delivery never changes the Manual priorities; a gather or build order also puts its task first in the Manual list (§7.4e, as of v0.13). It ends when it completes (the project is finished, the delivery made), when its target is gone for good (the node emptied, the project cancelled, finished or destroyed, the building gone), when the player taps **Resume Work** on the Villager's card, gives another order, or gives a task command or switches its mode (§7.4a, §7.6); the Villager then returns at once to its own behaviour (for a Manual Villager after a work order, that behaviour now starts with the ordered task, §7.4e). An emptied node ends the order on that node: the order itself never moves silently to another node, though the Villager's priorities may then send it to one.
- **Loads are conserved by the existing rules.** A Move never delivers or drops what is carried: the Villager holds with it. A gather order on the resource it carries delivers that load first and then goes to the node; any other carried load is put down as an ordinary dropped load (§7.4b), exactly as a reassignment does, and a build order does the same. A gather order whose storage is full waits, kept, and resumes when there is room; a blocked load follows §7.4c with the order as the Villager's plan.
- **Same simulation.** Carry capacity, claims (derived from what each Villager works, §6.2), depletion, work timing and contact frames, drop-off choice and its bonus, storage limits, yield modifiers and pickups are the ones every Villager uses; a direct order only chooses the target.
- **Presentation.** The Villager's card says who is in charge in a short line under its status: "Direct: Wood", "Direct: Build Storage", "Direct: Move" (its status says Moving, then Holding Position), otherwise "Smart: Wood" or "Manual: Gold". While the ordered Villager is selected, the same Tiny Swords corners in green mark its order's target (the node or construction, or a small square on the ground of a Move); there are no path lines and no command HUD. The card offers **Resume Work** while an order is active, and a one-line reminder of what a tap on the map does.
- **Input.** Only a tap orders: a drag pans the camera (or, after a long press or with the mouse, draws a selection box, §27.6), a pinch zooms, and none of them ever ends as an order (the camera's tap thresholds, §27). A tap on any UI is UI only. Deselecting: the card's close button, the selection bar's Clear, Android Back or Escape (which close build mode, a selection of several, the selection, then an open panel, before leaving the game), or a tap off the kingdom ground when only Villagers are selected.
- **Gameplay lock.** An order and Resume Work are gameplay actions: refused with the Pause reason while the player's Pause holds (§3.5a).
- **Smart coverage.** See §7.6: an ordered Smart Villager is not reallocated and counts as covering what it works.
- **Several Villagers** (any selection of friendlies, §12.7) take the same orders through the same rules: a tap on a resource node or a construction is a work order for **every selected Villager** (§7.4e, as of v0.13), each ordered onto that target once; a building that takes a carried load is a delivery for the selected Villagers carrying such a load; **as of v0.14** walkable ground is a Move for every selected Villager, each to its own spot around the tapped point (the compact formation of §12.10, each spot on walkable ground), so they do not stack. Soldiers in the selection take their own command from the same tap (§12.10) or are left out of a worker-only order; the selection is kept. The bar's commands (task, stance, crews) stay as they were.
- **Saved as intent.** Only the order's kind, the stable id of its node or building and the ground of a Move are saved with the Villager (§22.3); paths and claims are derived again on load. An order whose target no longer exists is dropped on load and the Villager resumes its own behaviour. The priority list a work order changed is saved like any list.

### 7.4e A work order puts its task first (v0.13)

A direct **work order** (§7.4d: gather a specific Tree, Gold Deposit or Sheep, or build a specific construction or upgrade) is stronger than a one-off destination: the ordered task becomes the Villager's **first configured priority**, by the **move-to-front** rule, which is not the swap rule of §7.4a:

1. remove the ordered task from wherever it is in the Villager's list;
2. put it in place 1;
3. every other task keeps its relative order, one place further back;
4. no task appears twice;
5. the list is cut to the places unlocked now, so the last fallback is the one that falls off.

```text
three places   Food, Gold, Build  + order Wood  ->  Wood, Food, Gold   (Build falls off)
three places   Food, Gold, Wood   + order Wood  ->  Wood, Food, Gold   (moved, not swapped)
three places   Wood, Food, Gold   + order Wood  ->  unchanged
one place      Gold               + order Food  ->  Food
```

- **The exact target stays the immediate target.** The order still works that tree, deposit, sheep or construction now (§7.4d); the new list is what the Villager prefers once that target is finished, emptied, gone or released (Resume Work). An order is never weakened into "some Wood somewhere".
- **The reassignment is immediate**, by the rules of §7.4b and §7.4d: the old target and claim are released, a carried load the ordered work does not deliver is put down once as an ordinary pickup, a load of the ordered resource is delivered first. The same order again on a Villager already working that target with nothing left to change does nothing at all: no re-plan, no second drop, no new claim.
- **Several Villagers** (Multi-Select): each one's own list is transformed once, independently; they need not share a list. Soldiers in a mixed selection are left alone.
- **Smart Villagers** take the order (it overrides the allocation, §7.6) but their hidden Manual list is never edited; switching such a Villager back to Manual restores its own list exactly.
- **Moves and deliveries** never touch the list.
- **One rule, one owner.** The move-to-front rule exists once, in the run state that owns the list (`RunState.priorities_after_direct_command`); the swap rule keeps serving every surface that edits a place (§7.4a). Neither the world nor the UI reproduces either rule.

### 7.5 Worker upgrades

Permanent upgrades may improve:

- Villager movement speed;
- gathering speed;
- carry capacity if used;
- resource-node respawn interaction;
- specialized gathering efficiency;
- number of available task priorities (Villager Task Slots, §7.3);
- starting Villager count.

Exact values and curves are balance data.

### 7.6 Smart Villagers (v0.11)

**Smart Workforce** is a one-time Prestige unlock (§20.6). It is a deliberate automation mode of this game, earned as a strategic reward; it does not replace Manual priorities, which stay the player's configured doctrine.

**Two named states per Villager.** Once Smart Workforce is owned, every Villager is either **Manual** or **Smart**, chosen with two side-by-side buttons on its row in the Villagers panel and on its card (never a button that cycles through hidden choices). Smart is an **assignment mode above the priority system**, never a task: no priority dropdown ever lists it, and a priority place can never hold it ("Priority 1: Smart" does not exist).

**The New Villager card holds the mode (as of the follow-up corrections, §46).** With Smart Workforce owned, the New Villager card (§7.4a) shows **[Manual] [Smart]** in its header, above the priority places, saved with the profile like the default list (and, like it, refused while the player's Pause holds). It is the one configuration surface: there is no separate All Villagers card.

- **Smart** selected: the priority places are hidden (only Apply to all stays, in its place, so the card does not move); recruits join in Smart mode (their hidden Manual list is the default list); **Apply to all** switches every existing Villager to Smart, each keeping its own Manual list in the background.
- **Manual** selected: the unlocked priority places show (as many as Villager Task Slots unlocks, 1 to 3); recruits join Manual with that list; **Apply to all** gives that visible list to every existing Villager and makes every one of them Manual (applied at once by the Manual rule, §7.4b).
- Changing the card alone (its mode or its places) changes **no existing Villager**; only Apply to all makes the bulk change.

**A recruit keeps what it was recruited with.** Recruiting snapshots the card when the recruit is queued: its mode and, for Manual, its priority list cut to the places unlocked then. Later changes to the card never alter a recruit already in line, and the snapshot is saved with the House queue, so a save and reload keep it. Before Smart Workforce, recruiting stays Manual-only, with the default list as before.

Apply to all with Manual intentionally differs from switching **one** Villager back to Manual, which restores that Villager's own saved list.

- **Manual** is the priority system above, unchanged: its task controls, the places Villager Task Slots gives, the first executable task runs, the immediate-reassignment and carried-load rules (§7.4b).
- **Smart** hides that Villager's task controls and shows a clear **SMART** tag in their place; a Smart row is tinted so Smart workers stand out at a glance, and a Smart Villager's card carries the tag in its corner. The row and card keep saying what the Villager is actually doing. The internal commitment timer is not shown.
- A Smart Villager's **Manual list is kept unchanged** in the background. Switching back to Manual restores exactly that list and shows the controls again. A Manual edit of a Smart Villager (its dropdowns, the task choice on its card, a Multi-Select or crew command that includes it) is refused with the reason "switch it to Manual first", never applied to the hidden list; only Apply to all with Manual shown replaces it.

**What a Smart Villager does (coordinated, §47):** Smart Villagers work as **one workforce**. A Smart Villager never walks its hidden Manual list; it takes the **greatest unmet need**, the kingdom's need after counting the Villagers already handling it:

```text
need of a resource = how empty its storage is, counting loads already on their way to it (0 when full)
need of Build      = the same as an empty resource, while a project exists
unmet need         = need / (1 + Villagers already on that task)
```

- **Who counts as handling a task:** every other Villager, Manual or Smart: a Manual Villager by the task it is doing, a Smart one by its commitment (a builder while its project still needs work). So the second Smart Villager sees what the first took, and several Smart Villagers spread over Build and the scarce resources in proportion to need instead of all taking the same one; a resource many Villagers already gather, or one whose storage is nearly full, gets few or none. The split comes from need and coverage, never from a fixed ratio, and it is deterministic (ties in the order Build, Wood, Gold, Food).
- **Only possible tasks:** a task that cannot run now (storage full, no drop-off, nothing to gather, nothing to build) gets nobody. When only one task is possible, every Smart Villager may take it.
- **Example:** six Smart Villagers, Wood empty, Food low, Gold healthy and a House to build: two build, two gather Wood, two gather Food, none Gold.
- **Building:** it commits to one construction project and stays until that project is complete, even if another project is queued or moved ahead of it; then it reassesses at once. If its project disappears or becomes impossible, it reassesses at once. Construction never takes the whole workforce just because it exists: each builder already on it halves what the next one adds.
- **Gathering:** it **commits to its resource for 2 minutes of game time**: it completes normal gather and delivery cycles of that resource and does not change because another resource became slightly scarcer. Game speed shortens the interval in real time because it is simulation time; pause does not advance it. At the end it reassesses, and keeps the task it holds unless another task's unmet need is clearly greater (by a fifth), so Smart Villagers never swap between equal tasks.
- **New construction:** at its next decision point (a gather cycle in progress finishes first, §7.4) a committed gatherer leaves its resource for a project whose unmet need is at least its resource's. An unattended project therefore always calls someone, and each builder that joins makes the next call less likely, so only as many come as the need warrants.
- **Never idle by rule:** the commitment is anti-thrashing, not permission to stand still. It reassesses at once when its task becomes impossible (storage full, no drop-off, nothing left to gather of that resource) and when the player switches it to Smart. A Smart Villager holding a load its storage cannot take follows §7.4c with its own decision: it puts the load down for the task it is allocated to (Build or a resource); with nothing possible it keeps the load and waits.
- Smart mode and its commitment (the chosen task, when the resource commitment ends, the project it is finishing) are saved with the run, so a reload neither resets the commitment nor changes what happens next.
- **Direct orders (v0.12).** A Smart Villager under a direct world order (§7.4d) is not reallocated by the Smart workforce until the order ends; its mode and commitment are left untouched. While the order lasts it counts, for the other Smart Villagers, as covering what it actually works (the ordered resource, or Build; nothing while it moves or holds), never its commitment.

---

## 8. Construction

### 8.1 No passive construction

Buildings do **not** construct themselves.

A requested building becomes a construction project, but progress requires at least one Villager currently executing the **Build** task.

This is an intentional difference from Feed the Dragon.

### 8.2 Construction order

All active building construction and tier-upgrade projects appear in a player-controlled ordered list.

The player can:

- move a project up;
- move a project down;
- cancel a project.

Villagers currently performing Build work on the highest-priority valid construction project.

### 8.3 Building upgrades

Tier upgrades are construction projects and therefore compete for builder time with new buildings.

An existing completed building continues functioning at its current tier while its upgrade is being constructed. The new tier becomes active when construction finishes.

### 8.4 Cancellation and demolition refund

Construction cancellation/demolition uses:

```text
refund_percent = max(20%, 100% - construction_progress_percent)
```

Examples:

- 0% progress → 100% refund
- 20% progress → 80% refund
- 40% progress → 60% refund
- 60% progress → 40% refund
- 80% progress → 20% refund
- 100% / completed building → 20% refund

The refund percentage is applied to the resources invested in the relevant building/project.

This means accidental unstarted placement is fully reversible, while committed construction has an increasing cost, and even completed buildings retain limited salvage value when destroyed manually.

---

## 9. Population

### 9.1 Shared population

Villagers and military units share the kingdom's population capacity.

### 9.2 Houses

Houses:

- increase maximum population;
- act as general-purpose resource drop-offs;
- do not provide specialized gathering bonuses.

### 9.3 Military population

A military unit consumes population from the moment it is queued for training until it dies; queued units (and Villagers in creation) reserve their population so the queue can always complete.

When that unit dies, or a queued unit is cancelled, its population is released immediately.

Training cannot be queued beyond available population capacity.

Exact population costs per unit are balance data.

---

## 10. Building Roster

The current building/system roster is based on the established Tiny Swords / Feed the Dragon building grammar, simplified for this game.

### 10.1 Castle / Command Center

**Availability:** always present; fixed position.  
**Functions:**

- run-loss HP target;
- deployment-card configuration;
- saved card configurations;
- card-to-slot assignment;
- deployment automation configuration;
- command/deployment buffs;
- Castle HP/run upgrades.

Command modifiers currently include:

- spawn with a Shield that lasts until broken (§12.9);
- spawn with movement Speed boost;
- spawn with Attack boost.

The chosen modifier belongs to the deployment configuration and may increase its resource cost.

### 10.2 House

**Availability:** initial building type; one starts prebuilt.  
**Functions:**

- population capacity;
- general Wood / Gold / Food drop-off;
- no specialized resource bonus.

### 10.3 Storage

**Availability:** current roster includes the Feed the Dragon-style storage role.  
**Function:** increases maximum resource storage capacity and can serve as general storage/drop-off infrastructure.

Exact tier behavior is balance/content data.

### 10.4 Lumberjack / Wood building

**Function:** Wood-only specialized drop-off.  
**Tier 1:** +20% Wood delivery yield.  
**Higher tiers:** improve the specialized benefit.

### 10.5 Gold gathering building

**Function:** Gold-only specialized drop-off.  
**Tier 1:** +20% Gold delivery yield.  
**Higher tiers:** improve the specialized benefit.

### 10.6 Food gathering building

**Function:** Food-only specialized drop-off.  
**Tier 1:** +20% Food delivery yield.  
**Higher tiers:** improve the specialized benefit.

This completes the same specialized-drop-off pattern for all three core resources.

### 10.7 Barracks

**Initial military-production building. One is prebuilt at run start (§4.1).**

Trains:

- Warrior
- Lancer (after Lancer Training)

Every military building trains **one unit at a time** from its own **training queue**. Several buildings of the same kind train **in parallel**, so a second Barracks doubles Warrior output. A deployment card sends its units to the trainer with the shortest queue.

- Units are paid when queued; cancelling a queued unit refunds it in full.
- The building's tier at the moment a unit **finishes** training sets that unit's quality (§11.2).
- A trained unit appears at the building's door and walks through the kingdom and the Castle to the battlefield (§12.6).
- Demolishing a building refunds its queue.

The context panel of a training building shows its queue, the current unit's progress and a cancel action.

### 10.8 Archery Range

**Prestige unlock.**

Primary unit:

- Archer

Trains Archers with the same queue rules as the Barracks. Its tier determines the quality/tier of newly trained Archers.

### 10.9 Research / Monastery building

**Prestige unlock.** Up to **two** Monasteries may stand in one run (v0.10; more only if future progression raises the cap). Each costs the same, with the usual placement and construction rules.

Functions:

- run research;
- Mage access **or** Healer access, by its specialty;
- temporary run boosts;
- owns its own research job for the current run.

**Specialty (v0.10).** Every Monastery, once built, chooses one permanent specialty: **Mage** or **Healer**. Its card presents the two options (what each trains and researches); the choice is confirmed, because it can never be changed: there is no respec, toggle, refund or free switch. Until it chooses, a Monastery trains nothing; the world marks it ("Choose: Mage or Healer") and a toast says the choice is waiting. Afterwards:

- a Mage Monastery trains Mages, never Healers; a Healer Monastery trains Healers, never Mages; its Train list shows only its unit;
- the choice belongs to that building: a second Monastery chooses on its own, so a Mage and a Healer Monastery can stand side by side;
- the world shows the specialty on a ribbon over the building ("Mages" on purple, "Healers" on yellow) and its card is titled "Mage Monastery" / "Healer Monastery";
- a Train card for Mages needs a Mage Monastery and says so ("Needs Mage Monastery"), likewise for Healers;
- the specialty is saved with the run.

**Research per Monastery (v0.10).** Research results are the kingdom's; research jobs belong to Monasteries:

- each built Monastery runs **one** research job at a time, at its own tier's research speed; two Monasteries run two different topics at once;
- completed levels are shared by the whole kingdom for the run (a level finished at one Monastery counts at the other);
- one topic runs in one place at a time; a topic at its last level cannot start again;
- specialty topics: **Arcane Focus** only at a Mage Monastery, **Field Medicine** only at a Healer Monastery; every other topic (Forged Blades, Tempered Armor, Battle Hymns, Swift Muster, Sharpened Tools, Masonry) at either;
- level N of a topic needs the Monastery that runs it at Tier N;
- jobs and their progress are saved with the Monastery that owns them;
- demolishing a Monastery ends its job like a cancelled project: refunded by its progress (§8.4), no level granted; the kingdom keeps what was completed.

The Research panel shows every Monastery's job (which topic, how far), lists the topics for the Monastery chosen (each Monastery has its own "Topics" button), and says beside a topic's cost why it cannot start there: the other specialty's topic ("Healer Monastery only"), already running at the other Monastery, or this Monastery busy.

Its exact research tree is balance/content work, but the system contract is that research is temporary run progression and is lost with the kingdom.

### 10.10 Towers

**Prestige unlock (Tower Engineering), with staged capacity.**

- built only on the authored Tower slots of the reserved defensive row;
- attack enemies automatically; their shots meet half of an enemy's armour (§12.8, v0.9);
- can be upgraded during the run;
- serve as kingdom-funded static defense rather than deployment-card units.

**Reach (v0.7, user request).** A Tower's reach is a band of the battlefield, not a circle: horizontally it reaches its tier's range outward and, inward, at least across the **whole Castle front**, so a Tower on the outermost slot still shoots enemies at the Castle; vertically it covers only the **top 40% of the battlefield** below the Castle, so it shoots once enemies come that close. Selecting a Tower, or choosing its slot in build mode, outlines that reach on the battlefield. The share is balance data.

**Capacity.** Unlocking Towers does not allow unlimited Towers. Tower Engineering sets the **maximum number of Towers at once to 1**. Each level of the permanent **Tower Capacity** upgrade (bought with Glory) raises it by one; a higher-layer reward may add more. Because permanent upgrades reset at Prestige (§20.10), Tower Capacity resets there too; the Tower Engineering unlock itself is a Prestige reward and stays.

- The Build panel shows the count against the capacity, for example `Towers 1 / 2`.
- At capacity, Tower placement is unavailable and explains that another permanent Tower Capacity upgrade is needed. Capacity and affordability are checked and explained separately.
- Demolishing or losing a Tower frees its place immediately.

**Damage (v0.11).** Base Tower damage per shot is **30 / 50 / 80** at Tiers 1 / 2 / 3 (2.5 times the first values, an approved first tuning pass). Costs, attack interval, range, Tower Capacity, Tower Damage, Tower Arrows, Warden Towers and the armour matchup are unchanged; a shot still goes once through the Tower multipliers and the armour rule.

Exact tower types/stats are balance/content data.

---

## 11. Building and Unit Tiers

### 11.1 Current tier structure

Current scope uses at least three meaningful tiers.

For military production buildings:

- **Tier 1:** base unit visual/stat profile;
- **Tier 2:** visibly upgraded unit + stronger stats;
- **Tier 3:** further visual/stat improvement + unit special ability enabled.

Authored Tiny Swords palette variants should be preferred for visible tier changes where appropriate.

### 11.2 Spawn-time quality

Building tier affects **newly trained units** (the tier when training finishes).

Units already on the battlefield retain the tier/stat profile they had when spawned.

### 11.3 Non-military tiers

Non-military buildings use tiers according to their role:

- House → population improvement;
- Storage → capacity improvement;
- resource drop-offs → delivery bonus improvement;
- Tower → defensive performance;
- Castle → HP/command/run improvements;
- Research → research capability/effectiveness.

Exact values are tuned during implementation.

### 11.4 Tiers are Prestige progression (v0.8)

Building tiers are an advanced progression feature, opened by normal Prestige:

```text
learn and build a Tier 1 kingdom -> a Prestige unlocks Tier 2 -> a later Prestige unlocks Tier 3
```

- A fresh profile builds everything at **Tier 1**: no building can be upgraded.
- **Advanced Construction** (a Prestige card) lets every building be upgraded to **Tier 2**.
- **Master Construction** (a Prestige card that requires Advanced Construction) lets every building be upgraded to **Tier 3**.
- The rule applies to every upgradeable building, with no exception: the Castle, Houses, Storage, the drop-off camps, the Barracks, the Archery Range, the Monastery and Towers. What follows from it follows naturally: Tier 3 units and their specials (§11.1) need Tier 3 access, and research that needs a Monastery tier (§17.4) waits for the same card.
- The refusal is the game's own (an upgrade without the card is refused, whatever asked for it) and names the card: "Needs Advanced Construction (Prestige)". A building's card and the Castle say, in a line of their own, that the next tier is a Prestige unlock and which card opens it; the reason also sits beside the upgrade's cost (§27.1f).
- An Ascension effect never lifts a building above the tier Prestige has unlocked: a Decree that raises a tier is offered only once that tier is open (§20.9).
- **Saves from before v0.8** keep what their run built: buildings keep their tiers and an upgrade already paid for completes; only new upgrades follow the rule. Prestige ranks are the unlock, so the choice is saved with the profile and kept by Prestige (§20.10).

---

## 12. Player Unit Roster

Exact costs, HP, damage, cooldowns, range, and special numbers are balance data.

### 12.1 Warrior

**Role:** balanced frontline melee unit.  
**Profile:** medium health, medium damage, close combat.  
**Attack (v0.9):** melee blows, which meet an enemy's full armour (§12.8).  
**Tier 3 special:** performs a stronger strike that can hit up to **3 nearby enemies**.

### 12.2 Archer

**Role:** fragile ranged damage dealer.  
**Profile:** low health, long range, high single-target attack.  
**Attack (v0.9):** arrows, which meet half of an enemy's armour (§12.8).  
**Tier 3 special:** fires an attack that can hit up to **5 enemies**.

### 12.3 Mage

**Role:** fragile ranged area damage/control.  
**Profile:** low health, ranged area attacks.  
**Attack (v0.9):** magic, which ignores armour (§12.8): the direct answer to armoured enemies.  
**Tier 3 special:** deals medium damage to enemies in the affected area and pushes them backward.

**Current asset note:** the present Tiny Swords pack does not contain a dedicated Mage unit. Prototype implementation may temporarily reuse an available friendly unit structure/visual treatment with magic VFX until final art is available.

### 12.4 Healer

**Role:** ranged support.  
**Profile:** low health; heals friendly units rather than acting as a primary damage dealer.  
**Tier 3 special:** heals all allies; allies already at full HP receive a small shield instead (a shield lasts until broken, §12.9).

The Tiny Swords Monk is the natural current visual basis for this role.

**Cadence (as of the Android corrections).** A direct heal restores **10 HP** at Tier 1 (the tier scaling gives about **13.5** at Tier 2 and **18** at Tier 3; Field Medicine adds to it as before) **every 6 seconds**. Troop Attack Speed quickens attacks only: it **never shortens the Healer's support cadence**.

**Recently Healed.** An ally healed directly by a Healer is **Recently Healed for 5 seconds of game time** (10 s before the follow-up corrections, §46): no Healer may heal it directly until that ends, so several Healers spread over the wounded instead of stacking on one. A Healer whose target becomes Recently Healed (another Healer reached it first) chooses another wounded ally it may heal; with none, it waits. Game speed shortens the 5 s in real time because it is simulation time; the Pause stops it. Recently Healed blocks only direct Healer heals: Sanctuary's mass heal, the Lancer's Rally and any other recovery ignore it. With one Healer the 6 s cadence is longer than the lockout, so a lone Healer may return to the same ally; the lockout is what spreads several Healers.

**Recently Healed is visible.** While the lockout runs, a small **no-heal mark** (the heal's green cross on a dark disc, struck through in red) floats above the ally's head, over its health bar. It explains why Healers are passing that ally over; it says nothing about other healing, which still reaches it. It goes the moment the ally can be healed again, and with the unit when it dies. It is small so that a large army under heals stays readable; enemies never show it.

**Sanctuary** stays every **4th successful direct heal** (that heal is the Sanctuary, and its ally becomes Recently Healed like any other); waiting, or finding no ally to heal, never counts toward it.

### 12.5 Lancer

**Role:** durable frontline defender.  
**Profile:** high health, medium melee damage.  
**Attack (v0.9):** melee blows, which meet an enemy's full armour (§12.8).  
**Tier 3 special:** temporarily increases defense and restores a portion of its own health.

### 12.6 Combat autonomy and stances

Units fight on their own: they move to their post, acquire targets, attack or heal and use their specials without per-unit micro-management. The player shapes behavior through a **stance** on each unit (and each deployment card, which sets the stance of the units it trains):

- **Defend Castle** (default, as of v0.10): **protect the Castle area, never "find enemies and chase them".** A Defend unit rests at its post close to the Castle and does not roam downfield. It engages an enemy that **attacks it** (or a soldier near its post), an enemy that **attacks the Castle**, or an enemy that **enters the Castle-defense threat area**. Distances are measured from the Castle front the guard holds (the wall line widened to the guard's posts), in the battlefield's own coordinates: the **threat area** reaches 340 px out (every spot an enemy can shoot the walls from, and the guard's posts); an enemy attacking a soldier is answered out to 400 px; the **hard leash** is 460 px (below the gate, 60 px above the enemies' spawn band). A target that moves past the leash is let go and the defender walks back to its post; a defender itself never passes the leash, so a fleeing enemy cannot draw it across the battlefield. "Near the top half" means this outer edge of the Castle's threat area, not half of the battlefield. **Support enemies:** an enemy that heals or wards (shields) an enemy threatening the Castle counts as part of that threat for a few seconds after, so Defend may take it on out to the answer reach, and still never past the leash; this ends the stalemate in which an Elite group sustained by a Hexer just outside the guard held a wave forever. A Defend healer keeps to the same leash. **The Castle comes first, with coverage (v0.11): priority and coverage, never a dogpile.** A **Castle threat** is an enemy going for the Castle inside the threat area or striking the walls, and a support enemy sustaining such a threat within the answer reach; an enemy fighting a soldier is a **local threat**. Each Castle threat needs a number of Defend **responders** by its tier: **1** for a normal enemy, **2** for an elite, **3** for a boss. An uncovered Castle threat takes the nearest suitable Defend unit not already responding to another Castle threat, at once, even off a local fight (a unit in a local fight counts as a little further away, so an idle one goes first; a threat striking the walls is answered before one still on its way). Once a threat has its responders, the rest of the guard leaves it to them and keeps to other legal threats: one Archer shooting the Castle draws one defender of thirty, not thirty, also once it turns on that defender; with three defenders each attacked by a melee enemy and two Archers shooting the Castle, two go for the Archers and the third keeps its fight. More responders than a threat needs are let go (the nearest stay). The requirement is a coverage goal, not a squad: a responder that dies or loses its target is replaced, and a threat that dies or leaves the legal area frees its responders. Responding to the Castle is itself a commitment: a responder keeps its threat while it lives inside the hard leash, even when it turns on that responder, and never switches to another threat, so two attackers can never pull a defender back and forth; every Castle threat lies inside the answer reach, so no responder is sent past the hard leash. The assignment is decided once per simulation tick from the saved unit state, by distance and coverage, ties by id: deterministic, with no oscillation, and the same after a save. A defender **commits** to the enemy it takes on: it keeps that target while the enemy stays inside the hard leash, and lets it go only when the enemy dies, becomes unreachable or passes the leash, when the defender itself passes the leash (not while responding to the Castle), or when an uncovered Castle threat needs it. While committed it may still turn to a clearly nearer enemy (it does not walk past one threat to reach another). Threat area < answer reach < hard leash, so a defender never flips between "attack" and "return" at one distance (no oscillation against ranged enemies standing outside the guarded area). After the engagement it returns to its post.
- **Pursue** (as of v0.10): the stance that commits. It waits and assembles at its post close to the Castle; once it takes on an enemy (the nearest anywhere on the battlefield) it follows that enemy anywhere, with **no chase limit**, and does not switch to a nearer one, until the enemy dies or leaves the battlefield; then it takes the next nearest, and with none left walks back to its post by the Castle.
- **Intercept** (unchanged): advance to a forward line and meet waves where they appear, spreading so each enemy draws few interceptors.
- **Standby** (v0.13, §12.6a): stay in reserve on the kingdom side of the Castle, out of ordinary wave fights; defend the Castle automatically once it falls to 50% HP (30% before v0.22).

**Friendly soldiers are never a wall (v0.21).** Our soldiers keep apart from each other, but that spacing is soft: a soldier on the move (to a post, a target, a commanded spot, through the gate, on the assault) and one standing never push each other, so the moving one walks through a standing formation and the formation keeps its place. Two standing soldiers, or two moving, keep their spacing, so everyone settles apart once arrived. A soldier that makes almost no progress for a second while on the move (two moving soldiers head on, a crowd all on the move) passes through friendlies for two seconds, then settles like everyone else; no soldier is ever placed or teleported. Enemies, rival units, targeting, reach, stances and formation destinations are unchanged, and a Defend line keeps defending from its posts.

**Direct orders override a stance, they are not one (v0.14, §12.10).** The player may take selected soldiers under manual control (move and hold, attack a chosen enemy); while that holds, the stance does not steer them, and the saved stance is unchanged. Resume Stance, or choosing a stance, hands them back.

Stances produce measurably different targeting and movement; they are not labels.

**One icon per stance (v0.8).** Each stance has one icon, and every screen that shows or sets a stance uses it, so the player learns a stance by its picture: **Defend** is the shield, **Intercept** the shield with a green arrow (it guards, but out at a forward line), **Pursue** the sword with the green arrow (it hunts anywhere), **Standby** a shield held behind a shield with the green arrow turned back (a reserve that stays behind the Castle, v0.13). The icons are drawn from the pack's own art as one small grammar: the shield guards, the sword attacks, the arrow leaves the Castle. They appear on a Train card's Command dropdown (§13.2), on the Train cards of the rail, on a soldier's card (and on its stance buttons), in the Army panel (the stance legend, the orders for all soldiers, squads) and on the Multi-Select commands. No screen uses another picture for a stance, or a stance's picture for anything else.

**Stance is card state (v0.10).** Where a unit card *shows* a stance (a rail Train card, a soldier's card), the icon sits on a small dark tag in the card's **top-left corner**, apart from the portrait, which is the unit's identity; it is shown once per card. Controls that *set* a stance (the Command dropdown, stance buttons, Army and Multi-Select orders) carry the same icon on the control itself.

A newly trained unit is not yet in combat: it leaves its building, walks through the kingdom, passes through the Castle gate and enters the battlefield, where it takes its stance.

### 12.6a Standby: the reserve (v0.13)

Standby lets the player build and organise a reserve army (for a later counterattack) without ordinary waves consuming it. It is an ordinary stance, available from the start wherever stances are set, with no unlock.

**In reserve.** A Standby soldier does not seek enemies, does not join ordinary wave combat and uses no Pursue, Intercept or Defend targeting. It stands on the **reserve ground**: the authored troop lane to the Castle's back door (the map's `castle_approach` zone, kingdom side, never built on), in rows filled from the Castle side and centred on the lane, squads together. It stays visible in the world, keeps its population place, stays selectable and commandable (its card, Multi-Select, squads) and keeps its squad. Off the battlefield it is out of every fight: no enemy chooses it as a target and no area strike reaches it.

- **Trained with Standby** (a Train card's Command): it walks from its building to the reserve ground instead of to the gate.
- **Switched to Standby on the field**: it disengages at once and walks back to the gate, in through the Castle and on to its spot. It is never placed there; until it is through the gate it is still on the battlefield and can still be struck.
- **Switched from Standby** (any other stance): it marches out from the reserve through the Castle as a newly trained soldier does, and takes that stance.

**The Castle emergency (50% as of v0.22; 30% before).** Standby is a reserve, not permission to lose while a full army watches. When the Castle is at **50% of its max HP or less** (`hp / max_hp ≤ 0.50`; exactly 50% counts, anything above does not) while a wave is active, **every living Standby soldier fights as Defend Castle**:

- its saved stance stays **Standby** (cards, squads, saves and every stance control still say Standby); Defend is only its **acting** behaviour, a temporary override;
- it leaves the reserve, marches out through the Castle and defends by the ordinary Defend rules (threat area, coverage, commitment, hard leash, §12.6): there is no second emergency AI;
- the emergency is one transition per wave: it starts the first moment both conditions hold and lasts until that wave is over, whatever the Castle's HP does meanwhile, so Standby soldiers never flip between reserve and defense within a wave; a wave's survivors carried past its timeout (§15.1, v0.21) still count as that wave until they are down;
- once the wave is cleared, the survivors walk back to the reserve and are Standby again;
- a later wave that starts with the Castle still at 50% or less starts the emergency again, for that wave;
- between waves, or with no wave active, a low Castle starts nothing.

A manual stance change is always possible (refused only by the gameplay lock, §3.5a) and takes the soldier out of Standby and out of the emergency; giving it Standby again sends it back to the reserve once no emergency holds.

**Direct orders and Standby (v0.14, §12.10).** A direct order takes a Standby soldier out of the reserve by walking (out through the Castle, never placed); while the order holds it is not protected by being Standby, and Resume Stance sends it back to the reserve. The Castle emergency outranks the player: when it starts, every Standby soldier's direct order is cancelled and it defends as above, its saved stance still Standby, and while the emergency holds a direct order to a Standby soldier is refused with the reason ("Castle emergency: Standby soldiers are defending it"). After the wave they return to the reserve as designed.

**Presentation.** A Standby soldier's card says where it is: "Standby · In reserve", "Marching to the reserve", "Withdrawing to the reserve", or "Castle emergency: defending" while the override holds. When the emergency starts with Standby soldiers present a toast says so ("Castle at 50%: 4 Standby soldiers ride out to defend it."), and another when they stand down. The Army panel counts soldiers on the battlefield, in reserve, marching and in training.

**State.** The saved stance is the unit's ordinary stance field; its place (in reserve, walking in, marching out) is its march stage, saved like every march stage; the emergency is one saved run flag, cleared by the end of the wave. Reserve spots and paths are derived again each tick, never saved.

### 12.7 Selection, squads and formations (as of v0.14)

**Selection is a core control; saved squads are the progression.** Selecting one or many friendly units, and commanding them in the world, is available from the start whenever the units exist; only saving a selection as a persistent squad or crew (and how many) is the **Squad Command** permanent upgrade.

- **One unit.** Tapping (clicking) a friendly Villager or soldier selects it: a Tiny Swords corner marker frames it and follows it as it moves. **A unit's marker is light (v0.19):** the same corners, smaller and so with about half the stroke, slightly translucent, framing the same rectangle (the tap target is unchanged), so a large selection shows the army first and its marks second; an enemy marked as an Attack target uses the same light corners in red; buildings and resources keep the full corners. **Selecting a friendly is command mode (v0.15):** no panel opens; the compact **Selection Status** (below) shows, and world commands work at once. Its context card (state, stance or task, commands) opens only from the status's **Details**; while that card is open the selection and its world commands stay; another friendly selected meanwhile takes the open card; **closing the card keeps the friendly selected** and brings the status back.
- **Selection Status (v0.15, its size and order as of v0.16).** One compact one-row block in the lower left of the free map area (above the Build Shelf when it is open), never in the centre, never reserving camera room; only its own rectangle takes input. One Villager: its avatar, "Villager N" and one live line ("Wood · Gathering", "Direct · Holding", "Food · Idle: ..."). One soldier: its portrait, kind and tier, an HP bar and its stance with HP, or its manual command ("Manual · Moving"). Several: the counts ("3 soldiers · 2 Villagers") and how many are under orders, or "Tap the map to command". The add mode alone: "Add selection mode". **Left to right: ^ Expand, the picture, the text, Details, then Cancel.** The **^ expand** control is its own target at the far left and opens the details; the body (picture, text and a **Details** plate right after the text) is the Details target too; **Cancel (✕)** at the far right **clears** (Back is never the only way), with clear dead space between Details and Cancel so a slip never deselects. As of v0.16 it reads at the resource chips' scale and is easier to operate than v0.15's (about 755 × 100 at the 1920 × 1080 reference): a 76 px picture, a title around 30 px and a live line at 26 px, an 84 × 88 ^ and an 88 × 88 ✕ with about 50 px between Details and ✕; it stays under about 45% of the safe width. The expanded selection bar keeps the same separation between Collapse and Clear. It hides while its expanded form (the card, or the selection bar) shows.
- **Several units** (§27.6 for the input): a box (a mouse drag, or on touch a long press then a drag), a double tap (double click) on a friendly for every friendly of that exact type in view (all visible Villagers, or every visible soldier of that unit kind), Shift-click to add or remove one, Shift-box to add a box, and the add mode (**Multi-Select**, the touch fallback to Shift: a toggle on the selection bar, the Army panel and a soldier's card) in which taps add or remove units and a box or double tap adds. The shortcuts Select All Soldiers, All of a unit type and All Villagers stay on the bar. Only friendlies are ever selected: never buildings, resource nodes, enemies or effects.
- **A temporary selection may mix** Villagers and soldiers of every type. Saving one as a squad still follows the compatibility rule below.
- **One selection, one surface.** The context card shows exactly one selected thing (a building, a node, or a single friendly opened from Details); a selection of several shows the compact status, and its Details expands the **selection bar** (never both). A box, a double tap, a shortcut or a squad recall leaves the bar collapsed; once the player expands it, it stays expanded while several stay selected, and its **Collapse** returns to the status, the selection kept. The bar counts the selected soldiers and Villagers (and how many are under direct orders), says in one line what a tap on the map does for them, and offers only commands that make sense for at least one of them: the shortcuts and the add mode, the four stances and **Resume Stance** (soldiers; Resume Stance only while some are under orders), the tasks and **Resume Work** (Villagers; Resume Work only while some are under orders), **Save group** (with Squad Command) and **Clear**. It wraps onto further rows at phone width, never one row running off the screen; while it shows, the map can be pulled up from under it. The dead and removed leave a selection by themselves; a selection that falls to one member stays a selection of one (no card opens by itself).
- **Back / Escape (v0.15):** build mode first; then an open friendly card or an expanded bar collapses, the selection kept; then the selection (and the add mode) clears; then a building's or node's card, a panel, the Build Shelf; then the game. One Back never both collapses and clears.
- **World commands** for whoever is selected: §7.4d (Villagers) and §12.10 (soldiers); each member does what it can with the tap, the others are left out, and the selection is kept.
- **Squads.** A compatible selection can be saved as a squad that stores its members and its stance (combat squads) or task (worker squads, crews) and, for combat squads, a formation. **Selecting a saved squad** (the Army panel's Select, a soldier card's Select squad) makes its living members the selection at once, with no mode to enter; the camera turns to it if none of it is in view. Its world commands are then the selection's; the Army panel's squad stance, task and formation controls stay and act through the same state rules.
- **Compatibility.** Soldiers of any type may share a squad. **Villagers (workers) and soldiers cannot share a squad**; Save group with a mixed selection is refused with that reason, never silently trimmed, and the selection is kept as it was.
- **Formations** (combat squads and assault groups, as of v0.18): **Line** and **Ranks** (a row per role: tanks in front, then melee, then ranged and casters, then support) for everyone; **Block**, **Spread** and **Wedge** (an arrowhead, its tanks at the point) with **Formation Drill**, one Prestige rank since v0.20 (Formation Drill I and II in v0.18 and v0.19). Each is laid out around the squad's anchor, the same layout a direct Move and an assault group's landing use (§12.10, §54.7).
- Squad membership stays valid: dead or removed units leave their squads automatically; an emptied squad disappears.

**Progression gates.** Per-unit stances, selecting several units and every world command are available from the start. Saved squads and crews come from the **Squad Command** Glory upgrade (more of them per level), which resets at Prestige. Extra formations come from **Formation Drill**, a Prestige Upgrade (one rank since v0.20; two ranks in v0.18 and v0.19; a Glory upgrade before), kept for good.

### 12.8 Attack types and armour (v0.9)

Every hit has an **attack type**, and some enemies wear **armour**. Armour is a matchup, not a flat cut: the share of a hit it blocks depends on the attack type.

| Attack type | Sources | Armour it meets |
|---|---|---|
| Melee | Warriors and Lancers (their specials too) | all of it |
| Arrows | Archers (the volley too) | half |
| Towers | Tower shots | half |
| Castle | the armed Castle's shots (§16.4) | half |
| Magic | Mages (the blast too) | none |

Example: a Shieldbearer (armour 35%) takes 35% less from a Warrior's blow, 17.5% less from an arrow, a Tower shot or a Castle shot, and the full damage of a Mage's spell.

- **No unit value changes.** A Warrior's or Lancer's blow on armour is exactly the flat cut it always was; the specialists, Towers and the Castle gained. Armoured enemies become a reason to field Archers, Mages and Towers rather than more Warriors.
- **Damage order:** raw damage × attacker bonus → the target's damage reduction → armour (the share its attack type meets) → shield → HP. A ward's shield still absorbs magic.
- **One table.** The share per attack type is balance data in one place; the combat, the Bestiary's armour strip (§33) and the armour lesson (§15.4) read it. A unit's attack type comes from its role; every hit names its type, so no source can meet armour the wrong way by default.
- A soldier's card names its attack type ("Magic damage 10 every 2s").
- Soldiers wear no armour. Enemy attacks have types too, so the rule would already apply if they ever did.

The armoured enemies are the Shieldbearer (35%), the Juggernaut (25%), the Dread Knight (Elite, 20%) and the Tyrant (Boss, 20%).

### 12.9 Shields (v0.10)

A **shield** is a second durability pool on a unit, not a timed buff:

- it does not expire with time; it stays until damage depletes it;
- damage is applied to the shield first, and what is left of a hit after the shield reaches 0 continues into HP;
- it does not regenerate by itself; a source that grants a shield again tops it up to its own amount, never above, and never stacks;
- its remaining value is saved with an active run.

Sources keep their amounts: Shield Deployment (40% of max HP, raised by Command Drills and Battle Hymns), the Healer's Tier 3 Sanctuary (15% to allies at full HP) and the Hexer's ward on enemies (25% of their HP). None of them has a lifetime any more.

**Readable:** a shielded unit shows its blue ring and, on top of its HP bar, a thin blue bar of the shield left (measured against max HP), never green or red, so it never reads as HP. A soldier's card shows "Shield N · lasts until broken" on its own line, never added to the HP figure.

### 12.10 Direct soldier orders (v0.14; temporary since v0.22)

Selected soldiers can be commanded in the world, AoE-style, on top of their autonomy. A direct order is a **temporary manual override** of the soldier's behaviour, never a fifth stance: the saved stance (Defend, Pursue, Intercept, Standby) is kept unchanged and shown as such.

| Tap (soldiers selected) | Order |
|---|---|
| ground (anywhere) | **Move**: each soldier walks to its own slot of one formation around the tapped point, at the nearest point of the battlefield the player may command; on arrival it **holds** there |
| an active enemy | **Focus Attack**, for each selected soldier that can deal damage (a Healer cannot; it stays selected and can still be moved) |
| a soldier or Villager | the selection (§12.7), never an order |
| a node, a construction, a building | not a soldier order: the Villagers in the selection take theirs (§7.4d); with none, the usual selection |

- **Move and hold.** The soldiers do not fight on the way. Arrived, each **holds** its spot: it attacks (or a Healer heals) only what is already within its normal action range, never leaves the spot to chase and walks back if pushed off it. **The hold is temporary (v0.22):** from the moment a soldier arrives it counts its own **idle time** on the spot, and after **30 seconds of continuous idleness** (`Balance.MANUAL_HOLD_IDLE_SECONDS`) its order ends by itself and its saved stance takes it back (a Defend soldier walks back to its post, a Standby one to the reserve). Idle means nothing to act on: a soldier striking an enemy in reach, or a Healer healing a soldier in reach, is not idle, and its idle time starts again from zero once it has nothing left to do. The time is **game time**: it runs with the simulation, so at 2x it passes in 15 real seconds and at 3x in 10, the Pause freezes it, and time away does not advance it. Each soldier counts from its own arrival, whatever selection the order came in. A new Move starts the wait again; a Focus Attack replaces it; Resume Stance or a stance change ends the order at once. Until then the order lasts as before.
- **Focus Attack.** The soldier follows that enemy anywhere on the battlefield, with **no leash**, and takes no other target while it lives (an explicit player commitment, stronger than any stance's retargeting). **When it dies or is gone (v0.22), the order ends at once** and the soldier's saved stance takes over, choosing its next target by its own rules; no hold, no wait, no Resume Stance needed. The same holds for a Focus Attack on the rival Castle once the battle is over. Each soldier's order ends with its own enemy, never with another soldier's.
- **Resume Stance** (the soldier's card; the selection bar for several) ends the order: the saved stance decides again at once (a Standby soldier walks back to the reserve). **Choosing a stance** for the soldier (its card, the bar, a squad's stance, Army's orders for all soldiers) also ends the order and the new stance takes over at once.
- **Formation.** The slots never stack: the formation is the squad's own (Line, Block or Spread) when the selection is exactly one squad's living members, otherwise one compact default (Block, with no Formation Drill needed to keep units apart), always with the melee in front (toward the enemy), ranged and casters behind them, support behind those, ties by id. The whole shape is shifted to fit the commandable area, so a tap at its edge keeps the shape. It is deterministic: the same order gives the same slots, after a save too.
- **Commandable area.** Where soldiers may be sent is one rule of the battlefield (today exactly the field and the ramp up to the Castle front, where combat units may move); a ground tap anywhere else sends them to the nearest point of it. A later battle can extend this area without changing the commands.
- **Standby and the emergency:** §12.6a.
- **Gameplay lock.** Every order and Resume Stance is a gameplay action, refused with the Pause reason while the player's Pause holds (§3.5a). A tap that commands nobody falls back to the ordinary selection; a refused command says why, never swallowing the tap silently.
- **Presentation.** A soldier under an order says so in place of its stance's state: "Manual · Moving", "Manual · Holding" ("Manual · Holding · 12s" while it stands idle, the game seconds left before its stance takes it back), "Manual · Attacking Raider" ("Manual · Marching out" while it is still walking out to the field); its card keeps the saved stance's tag and stance buttons and adds one line with **Resume Stance** ("Under your orders. Resume Stance hands it back to Defend."). While selected, a soldier's Move or hold spot is marked by a small green square on the ground and its Attack target by red corners (an enemy is never framed like a friendly). The selection bar counts how many are under orders. **An idle held soldier (v0.22)** shows the Villagers' red idle "!" bubble beside its bars (never over its HP, shield or Recently Healed marks); it shows only while the soldier stands on its commanded spot with nothing to act on, never while it marches, fights or heals, never after its order ends, never on an enemy. It reads the soldier's saved order state; the world keeps no timer of its own.
- **Saved as intent.** A soldier's order is saved with it: the kind (move, hold, attack), its spot, the stable id of its enemy and, for a hold, the idle time already waited (a reload resumes the wait where it stood, never a fresh 30 s). On load a spot outside the commandable area is put back inside it, and an Attack whose enemy no longer exists ends: the saved stance decides (v0.22; a hold before).

---

## 13. Deployment Cards

### 13.1 Card contract

A deployment card contains **one unit type only**, but can deploy multiple copies of that unit.

Examples:

- 3 Warriors
- 2 Archers
- 1 Healer

A single card never mixes Warriors + Archers + Healers.

### 13.2 Card configuration

Cards are configured in the Castle / Command Center.

A saved configuration contains at minimum:

- unit type (chosen from a dropdown that lists every unit with its portrait and cost; a unit not unlocked yet is listed but unavailable, saying what unlocks it; v0.7, user request);
- unit quantity;
- its **Command**: the stance the trained units take (§12.6), chosen directly (v0.8): tapping Command opens a dropdown showing every stance at once (Defend, Pursue, Intercept and, as of v0.13, Standby), each with its icon and short name, the current one marked; one tap applies it at once and closes the dropdown; a tap outside, Escape or Back closes it with nothing changed. Nothing cycles. Like every card edit it is refused while paused (§3.5a);
- optional command buff (Shield / Speed / Attack) when available, chosen from a dropdown in the same way (a buff not bought yet is listed but off, naming its permanent upgrade);
- resulting resource cost;
- resulting population requirement.

### 13.3 Saved configurations

**Saved Card Configurations** are how many Train card setups the player can store; **Deployment Slots** (§13.4) are how many of them are in play on the rail. The two are separate capacities and are worded apart.

The player begins with **2 saved card configurations**. The first one, in Slot 1 from the start, trains exactly **1 Warrior** (v0.7), so the first Train tap is cheap and immediate; its size is raised in Castle > Train cards like any card's.

Saved configurations allow quick reassignment without rebuilding the card definition every time.

**Capacity (v0.23).** One getter combines every source and clamps once: base **2**, **+1** per level of the **Saved Card Configurations** Glory Upgrade (**4 levels** again since v0.23; 3 in v0.22), **+2** with the **Twin Banners** Decree; never more than **8** (2 + 4 + 2). **Royal Provisioning no longer adds a saved card** (v0.22's +1 was a mistake; it gives Active Train Slots, §13.4). Every create, edit, save and trim of a card uses it. A Prestige or an Ascension resets the Glory levels and keeps as many saved cards as the capacity after the reset allows; an unassigned slot never deletes a card; no card is created or deleted for any other reason. The two capacities are never mixed in data, text or probes: saved cards are stored setups, Active Train Slots are cards in play.

### 13.4 Deployment slots

The player begins with **1 active deployment slot**.

A slot is assigned one saved card configuration.

Switching which saved card is assigned to a slot is free.

**Assigning (v0.6).** The Castle's Train cards are one list (there is no separate list of slots): each card has an **Assign** button. With one slot, Assign puts the card there at once; with several, it opens a small dropdown of the slots, each showing what it holds ("Empty" or the card it would replace). A card already in a slot shows that slot on its button ("In Slot 2"), which is off. Tapping an **empty** Train card on the rail opens this list, saying which slot waits for a card and suggesting it in the dropdown.

**Active Train Slots (as of v0.23)**, also called Deployment Slots: the Train cards in play on the rail. One getter:

| Source | Active slots | Kept |
|---|---:|---|
| Base | 1 | always |
| **Expanded Command** (Glory Upgrade, 3 levels; authored prices 200, 350, 600 Glory since v0.11) | +1 a level, +3 at most | reset by every Prestige and Ascension |
| **Royal Provisioning** (Prestige Upgrade, 1 rank) | +2 | kept by ordinary Prestiges, reset by an Ascension |
| Any Decree | +0 | (Twin Banners gives saved cards, never slots) |
| **Maximum** | **6** | |

Slots are contiguous from Slot 1 whatever order the sources came in; a reset trims the last ones and keeps the assignments that remain in place (a card the reset's capacity no longer keeps leaves its slot unassigned). A Royal Provisioning owner starts every run of its cycle with 3 slots even with Expanded Command back at 0.

**Six visible places (v0.23).** Once the Train rail is revealed (§27.5), it always shows **all six places**, so no capacity is hidden:

- **Assigned:** the normal card (quantity, cost, Train, automation, block reason), full size while three or fewer slots are open, compact beyond.
- **Not assigned:** "Slot N: Not Assigned", "Tap to configure": opens Castle > Train cards with that slot suggested (the one assignment flow, no other editor).
- **Locked:** a compact place ("Slot N: Locked", "Tap: how to unlock"), dimmed to about 55% yet readable, still a finger tall; a tap shows a short note beside the rail naming only the sources still available ("Expanded Command (Glory): up to +3 slots. Royal Provisioning (Prestige): +2 slots."), never Twin Banners; it opens nothing and pauses nothing.

The rail fits every phone shape inside the safe area (six places plus the automation box). It is general discoverability, the same in every onboarding mode, never a tutorial step.

### 13.5 Card position has no implicit order

Slot position is only an address for manual/automation commands.

There is no built-in meaning such as:

```text
Slot 1 must spawn before Slot 2
```

The player manually taps whichever slot they want, whenever it is usable.

### 13.6 Manual deployment (training)

When the player taps a card slot:

- if resources and population are available and a building that trains the unit exists, the card's units are paid and **queued for training** at the matching building with the shortest queue;
- otherwise the card remains unavailable and clearly communicates the blocking requirement (resources, population, no building that trains the unit).

The card shows how many of its units are still in training.

---

## 14. Deployment Automation

Automation is unlocked progressively.

It operates on **slot numbers/configurations**, not hardcoded unit names. Therefore any future card configuration can participate without rewriting automation logic.

### 14.1 Automation examples

Supported rule concepts include:

- spawn Slot 1 whenever affordable;
- spawn Slot 1, then Slot 3, then Slot 2;
- wait until Slot 1 and Slot 2 can both be paid, then deploy them together;
- deploy Slot 3, then Slot 2, then Slot 1 as each becomes affordable;
- wait until all selected slots are affordable, then deploy all together;
- wait X seconds between Slot 1 and Slot 2;
- apply a delay after every deployment in a sequence;
- repeat a configured sequence.

### 14.2 Wait-not-fail rule

If the next automated action cannot be afforded, automation waits for the required resources rather than consuming/skipping the action. Automation queues training exactly like a manual tap; its status shows what it is waiting for, or which slot it just sent to training ("Training Slot 1").

### 14.3 Progression

Automation starts simple and expands through Prestige choices:

```text
manual deployment
→ basic auto-deploy
→ ordered slot sequences
→ synchronized groups (they need 2 active Deployment Slots, §20.4)
→ delays / richer rules
→ faster game speed and higher-level management
```

---

## 15. Battlefield and Stage Progression

### 15.1 Stage flow

```text
spawn current wave
→ units fight automatically
→ all enemies in wave are defeated (a clear)
   or 45 s after its last scheduled spawn enemies are still alive (pressure)
→ short transition
→ next wave
```

Kingdom production/construction continues during wave transitions.

**Wave pressure (v0.21).** One harmless survivor must not hold the next wave back for free development time. Once the wave's **last scheduled enemy has spawned**, the wave has **45 simulated seconds** to be defeated (game speed scales it, the Pause stops it, and a long authored spawn sequence is never cut short: the clock starts only after it). If every enemy is down first, the wave is **cleared** as always. If enemies are still alive when it runs out, **the next wave's countdown starts anyway**: the survivors are not killed, moved or counted as defeated; they fight on, and the next wave arrives on top of them. That moment is **not a clear**: no Wave Clear sound, no success message, no cleared-wave count, no Wave 100 milestone; a short alert says the wave was not defeated in time and how many enemies fight on. The next clear needs every enemy down, survivors included. Three moments are kept apart: spawning completed, pressure advanced, cleared. While survivors remain, Launch Attack waits ("Defeat the remaining enemies first.", §54.3) and Castle repair waits (it needs no enemy on the field). The first-run progression and an assault still stop the waves altogether, so they outrank the timeout. The timeout's clock is saved with the run.

### 15.2 Difficulty model

Difficulty is driven primarily by **enemy composition**, not by applying a hidden damage multiplier to the same enemy every stage.

Progression uses:

- new stronger enemy archetypes;
- larger quantities of older enemies;
- combinations of enemy roles;
- retirement/reduction of outdated enemies;
- Elites/Bosses.

Each enemy definition owns its intended stats. Stage composition determines pressure.

### 15.3 Enemy introduction cadence (v0.4, 100 waves)

- A new normal enemy about every **5 to 8 waves** early on, then every 7 to 15 waves: the first hours keep showing something new.
- **Every 25 waves an Elite or Boss milestone** (Elite at 25, Bosses at 50, 75 and 100), plus further Elites introduced between them (35, 45, 60).
- Each Elite, once introduced, **returns on a cycle** (every 5 to 7 waves) and more of them appear later.
- Wave pressure follows a **smooth threat budget**: the curve that played well through wave 19 continues without any single enemy type becoming a wall. A newly introduced enemy enters in small numbers and ramps up over five waves; older enemies are retired over several waves.

| Wave | New normal enemy | Role |
|---|---|---|
| 1 | Thrall | fodder |
| 2 | Raider | melee |
| 8 | Skirmisher | ranged |
| 13 | Cutthroat | fast melee |
| 18 | Brute | sturdy tank (not a wall) |
| 24 | Shieldbearer | armoured melee (armour 35%, §12.8) |
| 30 | Shaman | healer |
| 36 | Sapper | ignores soldiers, explodes at the wall |
| 42 | Ravager | siege (triple damage to the Castle) |
| 55 | Reaver | veteran melee (replaces Raiders) |
| 62 | Longbowman | veteran ranged (replaces Skirmishers) |
| 70 | Juggernaut | armoured veteran tank, armour 25% (replaces Brutes) |

| Wave | Elite / Boss | What it does | Reward |
|---|---|---|---|
| 25 | Warlord (Elite) | cleaves several defenders every third blow | Glory per defeat plus a first-defeat bonus |
| 35 | Marksman (Elite) | long range; volley every third shot | as above |
| 45 | Hexer (Elite) | heals and shields nearby enemies | as above |
| 50 | Dread Lord (Boss) | smashes everything around it | large Glory plus a large first-defeat bonus |
| 60 | Dread Knight (Elite) | armoured (20%); smash every fourth strike | Glory plus first-defeat bonus |
| 75 | Tyrant (Boss) | armoured (20%); calls Reavers to its side | larger |
| 90 | Dread Lord returns, with a Dread Knight | | |
| 100 | Dark Prophet (final Boss) | strikes from range; calls packs of Cutthroats | largest |

Rewards: every enemy pays Glory per defeat from its own range (stronger enemies more); every Elite and Boss also pays a **one-time first-defeat bonus** the first time the profile ever defeats that kind. Enemies called by a Boss pay nothing (a Boss cannot be farmed); a Sapper that reaches the wall and explodes pays nothing. Exact values are balance data (data/enemies.json).

The wave table (data/waves.json) is generated from this schedule by a tool and can be edited directly.

### 15.4 Warning cards

The first appearance of every enemy kind shows an introduction card over the map (it never pauses). The card uses the Bestiary layout in a compact size: portrait, name and tier, a one-line description and its special attack first (what to remember), then its numbers as tiles (a small label over a large value: HP, damage and interval, range, speed, damage against the Castle, healing when it has it, Glory). An armoured enemy's card adds the Armor strip of its Bestiary entry (§33).

**The armour lesson (v0.9).** The first time a profile meets an armoured enemy, that enemy's introduction teaches armour. Its ribbon reads **Armored enemy!** and two lines take the description's place:

```text
Melee struggles against Armor.
Arrows and Towers penetrate some Armor. Magic ignores it.
```

- It is the same introduction card: over the map, never pausing, tap to dismiss (it stays a few seconds longer than a plain introduction). No other notification system.
- It appears on the first wave that brings an armoured enemy, normally the Shieldbearer's introduction at wave 24, and never again for that profile. The learned state is saved with the profile, kept by Prestige with the other hints and cleared by Hard Reset.
- A profile that saw the Shieldbearer's introduction before the lesson existed gets it on its next wave with an armoured enemy, on that enemy's card; when the wave also introduces another enemy, the lesson waits for that card instead of cutting it short.
- Afterwards the rule stays available in the Bestiary (§33).

Wave 1 of every run is also announced by the first-wave warning (§3.4).

Presentation variants distinguish:

- Normal enemy introduction
- Elite introduction
- Boss introduction

### 15.5 Placeholder enemy production plan

The final enemy art pack is not currently owned.

Prototype rule:

- use a placeholder enemy built from an existing friendly unit structure/character;
- the same placeholder visual may represent multiple enemy data definitions;
- enemy behavior/stats/composition must be data-driven;
- art, animation, audio, portrait, and presentation references must be replaceable later without rewriting wave progression/combat architecture.

Placeholder variety comes from the owned art: the five Tiny Swords unit sheets in the enemy palette (Red) for normal enemies, their tool and pose variants (knife and hammer Pawns, the Warrior's guard pose), tinted and scaled veterans, and the Black palette, larger, for Elites and Bosses.

---

## 16. Castle / Command Center

The Castle is both the defeat target and the strategic interface for military deployment.

### 16.1 Runtime functions

- Castle HP
- Castle run upgrades
- card creation/editing
- saved card configurations
- slot assignment
- deployment automation rules
- command buffs
- the Castle attack, once armed (§16.4)

### 16.2 Deployment buffs

Current deployment modifier families:

**Shield Deployment**

- units arrive on the battlefield with a shield that lasts until broken (§12.9).

**Rapid Deployment**

- units spawn with a temporary movement-speed boost so frontline units reach combat faster.

**Assault Deployment**

- units spawn with a temporary attack boost.

The modifier is part of the card configuration, not a global battlefield toggle.

Modifiers may change card cost and can themselves have run/meta progression.

### 16.3 Castle attack approach and hit feedback

Enemies must **reach the Castle** before their normal attack can damage it. Authored Castle attack positions line the front wall and gate; a direct attacker claims a free position, walks to it and only then begins its attack loop. When every position is taken, attackers wait in a short queue behind the wall line. Enemies that are ranged by design strike from their range measured from the wall, never from an implausible distance.

Every landed Castle hit produces **one** synchronized feedback event at the moment of damage: the attacker's attack frame, an impact at the wall, a Castle hit flash and punch, the HP bar reaction, a floating damage number, a sound, and a restrained camera shake for heavy hits. Feedback never runs on its own timer (the sound alone is throttled by a short cooldown, §59.4).

### 16.4 Armed Castle (offensive upgrade path)

The Castle is passive until the permanent **Castle Armory** upgrade arms it. From then on it automatically shoots enemies within its range through the normal damage pipeline (with its own projectile and hit feedback; its shots do not trigger unit procs). Its shots meet half of an enemy's armour (§12.8, v0.9).

Its attack improves through:

- the permanent **Castle Weaponry** upgrade (damage);
- run upgrades **Castle Archers** (damage), **Quick Reload** (attack speed) and **Keen Sights** (range), available once the Castle is armed.

Effective Castle attack damage, interval and range come from one set of getters used by combat, the Castle context panel and the upgrade descriptions.

---

## 17. Kingdom Upgrades

**Kingdom Upgrades** ("Run Upgrades" before v0.20) are bought during play with the kingdom's resources (Wood, Gold, Food). They strengthen the current kingdom and disappear when it is destroyed. The Castle's shortcut and the panel use this name. Ordinary actions keep their verb ("Upgrade Castle", "Upgrade to Tier 2"): the name is the progression layer's, not a ban on the word "upgrade".

Current upgrade families include:

### 17.1 Castle

- Castle HP (Castle Walls), repairs between waves (Repair Crews). **The Castle repairs nothing until Repair Crews is bought (v0.21):** level 0 is no repair at all; levels 1, 2, 3 and 4 repair 0.4%, 0.6%, 0.8% and 1.0% of max HP per second while no enemy is on the field (four levels, the same maximum as before). Masonry and Sovereign Walls improve a repair the Castle has, never create one; the upgrade card says "none" at level 0 and that the first level unlocks it, and the Castle's card says it has no repair
- deployment-buff effectiveness/duration (Command Drills)
- Castle attack damage, attack speed and range once the Castle is armed (§16.4)

### 17.2 Economy

- gathering speed (Better Tools) and carry capacity (Bigger Baskets)
- Villager movement speed (Fleet Feet)
- resource regrowth: faster node respawn (Swift Regrowth) and larger node stock (Rich Veins)
- construction speed (Master Builders)
- storage capacity and specialized drop-off performance through building tiers (once Prestige has opened them, §11.4)

### 17.3 Military

- troop damage and HP (Weapon Smith, Armor Smith)
- unit training speed (Drill Sergeants)
- troop movement speed (Forced March)
- production-building tiers and unit-quality tiers (once Prestige has opened them, §11.4)
- Tower damage (Tower Arrows) and attack speed (Tower Crews)

Every run upgrade has a visible effect and reads through the same effective-value getters as the simulation and the UI.

### 17.3a Offline (v0.23)

Two Kingdom Upgrades in their own small **Offline** section of the panel, paid with Wood, Gold and Food and lost with the kingdom like every other (and at every Prestige and Ascension, which start a new kingdom):

- **Supply Routes** (4 levels): the base offline share of storage per hour, 1% → 1.5% → 2% → 2.5% → 3% (Wood, Gold and Food only, never Glory). Its card shows the whole rate.
- **Extended Reserves** (5 levels): +0.3 h of eligible offline time a level (+1.5 h at most), for the whole offline reward, Glory included.

They are not Glory Upgrades: the Glory shop's Offline Glory Rate and Offline Time Cap stay as they are (§22.2).

### 17.4 Research

The Research building provides run-scoped research (each Monastery one job at a time, levels shared by the kingdom, specialty topics at their specialty, §10.9 as of v0.10) that can improve areas such as:

- military performance;
- economy;
- support behavior;
- command/deployment effectiveness.

Exact research nodes are balance/content work and should not duplicate the permanent tree unnecessarily.

---

## 18. Permanent Progression: Glory Upgrades

**The three upgrade layers (v0.20).** The player-facing names, used consistently wherever two layers could be confused:

- **Kingdom Upgrades** (§17): bought with resources; strengthen the current kingdom; lost when it falls.
- **Glory Upgrades** (this section): bought with Glory; survive a defeat and rebuild; reset by Prestige.
- **Prestige Upgrades** (§20): the cards owned, one per conquered rival, kept until the next Ascension (§20.9 as of v0.23). **Prestige** itself stays the name of the conquest and reset event ("PRESTIGE READY", "Prestige now").

The How to play deck's last card teaches the three side by side; other screens name only the layer they show. Internal ids and save keys keep "run", "meta" and "prestige".

### 18.1 Permanent currency

Enemies drop the permanent/meta currency, **Glory**.

The currency is automatically collected.

Each enemy definition owns a reward range; on death, the actual drop is rolled within that range.

Harder/later enemy definitions can have better ranges.

**Glory scarcity.** Every Glory source (enemy drops, mission rewards, offline rewards, first-defeat bonuses) pays **36% of its v0.3 value** through one central multiplier (the approved cut to 30%, then about 20% more after playtesting). Displayed rewards always equal credited rewards; a mission reward is snapshotted when the mission is assigned. Permanent-upgrade costs were deliberately not reduced: Glory is meant to be substantially scarcer.

### 18.2 Permanent-upgrade philosophy

**Glory Upgrades** (the player-facing name since v0.18; "permanent upgrades" before, and "meta" in the save) provide incremental strength and smoother rebuilding without replacing the run economy. They persist through defeats and reset at Prestige (§20.10) and at Ascension (§20.9). No text calls them permanent forever.

Primary families:

**Economy**

- resource-node respawn speed;
- gathering speed;
- Villager movement speed;
- gathering yield/carry improvements;
- storage improvements.

(Drop-off Mastery, the specialized drop-off bonus, was removed in v0.18: it overlapped the camps, their tiers and Kingdom Output. Its levels were refunded.)

**Military**

- troop damage;
- troop HP;
- attack speed (attacks only: a Healer's support cadence is its own, §12.4);
- unit training speed (Drill Yards);
- Castle HP;
- the Castle Armory unlock and Castle Weaponry (§16.4);
- applicable Tower bonuses and Tower Capacity after Tower unlock (§10.10).

**Command**

- Squad Command (saved squads and crews, and how many; selecting several units is a core control, as of v0.14), §12.7 (Formation Drill became a Prestige Upgrade in v0.18: two ranks, one since v0.20);
- Saved Card Configurations (§13.3, 4 levels) and **Expanded Command**, the Active Train Slots (§13.4; v0.10, from Prestige; 3 levels).

**Starting advantages**

- starting resources;
- starting Villagers;
- improved starting Castle HP (buildings completed at Tier 2 are an Ascension Decree, §20.9);
- prebuilt/partially preserved infrastructure where unlocked;
- easier/faster rebuild.

**Salvage**

- improve post-defeat resource recovery above the baseline: **Salvage**, one progression since v0.18 (**+6% per level, 8 levels**: 5% base to 53%). Recovery Doctrine (+20% a level, 3 levels) was merged into it and removed; its levels were refunded.

**A card explains a mechanic its name does not (v0.10).** The Salvage cards say what Salvage is: "Recover part of the Wood, Gold and Food you invested in buildings, upgrades and research when a run ends.", then their effect ("+20% → +40% Salvage") and, since v0.11, the kingdom's whole Salvage now and after the next level ("Salvage: 25% → 45%"). Expanded Command and Saved Card Configurations say which capacity they raise.

**Prices.** A permanent upgrade costs base × growth^level, unless it has an authored price per level (v0.11: Expanded Command). Exact percentages/cost curves are balance data.

### 18.3 Glory Upgrades during a run: Royal Provisioning (v0.22)

Glory Upgrades are bought between runs on the results screen, without limit. The **Royal Provisioning** Prestige Upgrade (§20.6) also lets the player buy them **while a kingdom stands**, behind a wave-earned allowance:

- **One purchase earned per 10 waves cleared this run**, at most **10** a run: available = min(waves cleared ÷ 10, 10) − purchases made this run (integer division). Credits come from clearing waves 10, 20, ... 100 (the run's waves-cleared count, raised only by a real clear), never from a wave starting or from a wave advanced by pressure (§15.1); waves past 100 earn nothing more. Unused credits carry over within the run (at wave 30 with none spent, three in a row), never into the next run.
- **One purchase** spends the ordinary price in the player's own Glory, raises **one** Glory Upgrade by one level and uses **one** credit, as one action; a refusal changes nothing. The allowance is catalogue-wide (one credit, whichever upgrade). The upgrades bought are ordinary Glory Upgrades: kept after a defeat, reset by Prestige. No free Glory, no price change, no extra level.
- **The gate**, one rule for every in-run entry, checked in order: the Pause lock (§3.5a), Royal Provisioning owned, a living kingdom, the upgrade's own state (locked, maxed), a credit ("Clear Wave 20 to earn another purchase", or "All 10 purchases used this run"), then Glory ("Not enough Glory").
- **The Glory Upgrades panel** (a side panel, never pausing, opened from the Glory chip, §3.3) shows the results shop's catalogue with "Glory: N", "Purchases available: X" and "Next purchase after Wave 20" (or "All 10 purchases earned this run"). The list always shows; a row without a purchase says why beside its price. **Starting Advantages** are bought now but shape the next kingdom ("Applies next run"). Effects read through the usual getters apply at once; troop stats apply to soldiers trained afterwards (§11.2); a Castle HP level raises the Castle's current HP with its maximum.
- **The results shop stays unlimited** and never uses a credit.
- **Glory of Kings (v0.23, §20.9).** The Decree opens the same in-run shop **without the wave allowance**, whether or not Royal Provisioning is owned (in a fresh Ascension cycle it works before Royal Provisioning is earned again): no credit is required or used; the Pause lock, the living kingdom, the upgrade's own state (locked, maxed) and the price in Glory still apply, through the same one gate and the same panel. With both, the Decree wins on the restriction. The panel reads "No purchase limit"; the chip OPEN.
- **A note per milestone:** each wave clear that earns a credit shows "+1 Glory Purchase (N available)", Glory or not, once, from the clear itself (never on a redraw or a load).
- **The first-use arrow** (a feature guide, not onboarding, §27.4): the first time the profile earns a purchase (Royal Provisioning owned, wave 10 cleared), the pointer frames the Glory chip with "Glory Upgrade available! Tap here to spend your Glory.", in **every onboarding mode, No Tutorial included**. It never pauses, blocks a tap, slows or forces anything; it waits behind a panel, the task dropdown, build mode, the Build Shelf, the expanded selection bar or a modal and returns when they close; it stays until the player taps the Glory chip, which retires it for good (a profile flag kept by Prestige, cleared by Hard Reset). Showing it retires nothing; a chip already opened after the clear needs no arrow.
- **State:** the purchases made this run are saved with the run (0 at every new run, after a defeat or a Prestige); what is available is derived, never stored.

---

## 19. Salvage Between Runs

### 19.1 Baseline

After the kingdom is destroyed, the next run receives a small portion of the previous run's invested value as starting resources.

Initial target:

- approximately **5% baseline Salvage**.

### 19.2 Progression

Salvage can be improved by long-term progression: the Salvage Glory upgrade (v0.18: +6% a level, Recovery Doctrine merged into it) and the Endless Coffers Decree (+30% since v0.23).

What it recovers is exactly the Wood, Gold and Food invested in buildings, their tiers, run upgrades and research (units are not invested value); it starts the next kingdom, not a post-Prestige run.

### 19.3 Purpose

Salvage makes defeat feel like forward motion and reduces repetitive early rebuilding without preserving the old kingdom itself.

---

## 20. Prestige

### 20.1 Philosophy

Glory Upgrades improve efficiency and strength.

**Prestige permanently changes what the player can do.** The cards a player owns are **Prestige Upgrades** (v0.20); Prestige is the conquest and reset that earns one.

Prestige should feel rarer, more unique, and more build-defining than the standard permanent tree. Prestige Upgrades last until the next Ascension (§20.9 as of v0.23), which starts a new ascent through the rivals.

### 20.2 Prestige offer (as of v0.18)

Each Prestige presents exactly **3 cards**, one per role, in this order:

1. one **Expansion / Unlock** card;
2. one **Command / Automation** card;
3. one **Kingdom Boost** card.

The player chooses **one**. The other offers are not granted. (The roles keep their v0.17 ids; only their names changed.) A role with no eligible card left is replaced by another eligible card, so an offer shows three while any remain.

**First Prestige building guarantee (v0.18, §54.13).** The offer of **Prestige #1 of each cycle, and only that one**, has a building unlock (Archery Range, Research Monastery or Tower Engineering) as its Expansion card. Skipping it forces nothing later: from Prestige #2 on, the Expansion card is drawn from the normal eligible pool. A building already granted another way (the Warden Towers Decree) is never the guaranteed card; **its card still stays in the pool (v0.23)**, so every cycle can reach all 33 ranks, one per rival.

**Fair draw (v0.18).** Within a role, a draw prefers the eligible cards that have appeared in the fewest offers so far (saved with the profile, kept by Prestige): a skipped card is not shown again before every other eligible card of its role has been, yet which one comes next is random among them, never a fixed order.

### 20.3 Offer persistence

Prestige choices are rolled once when the Prestige opportunity is created (a conquest, §54.6) and the exact offers are saved. Closing/reopening the game cannot reroll the three cards.

### 20.4 Eligibility filtering

Cards with unmet dependencies are excluded. Prerequisites (v0.18): Master Construction needs Advanced Construction; Deployment Sequences needs Auto Deployment; Synchronized Deployment needs Deployment Sequences; Third Assault Group and Battle Signals need Second Assault Group; Game Speed's second rank needs its first (the same ranked card).

**Only Prestige prerequisites decide (v0.11).** A layer that Prestige resets never keeps a card out of an offer. **Synchronized Deployment** is offered once Deployment Sequences is owned, whatever the current number of Deployment Slots (Expanded Command is a Glory upgrade and resets at Prestige). Once owned it is kept like every Prestige card, but synchronized groups need **2 active Deployment Slots**: with one, the automation editor says "Requires 2 Deployment Slots" and a step holds one slot; the moment a second slot is active again, groups work, without taking the card again. It never grants slots.

**No rival needs a card (§54.13).** No rival may require any particular Prestige card; every card makes a conquest easier, faster or richer, never possible.

### 20.5 Expansion / Unlock pool (8 ranks)

1. **Archery Range** — unlocks Archer production.
2. **Research / Monastery** — unlocks research plus Mage/Healer access.
3. **Tower Engineering** — unlocks defensive Towers.
4. **Lancer Training** — unlocks the Lancer, trained at the Barracks beside the Warrior (§10.7).
5. **Advanced Construction** (v0.8) — buildings can be upgraded to Tier 2 (§11.4).
6. **Master Construction** (v0.8) — Tier 3; requires Advanced Construction.
7. **Second Assault Group** (v0.18) — a second assault group with its own soldiers, formation and deployment delay (§54.4).
8. **Third Assault Group** (v0.18) — a third; requires Second Assault Group.

### 20.6 Command / Automation pool (10 ranks)

1. **Auto Deployment** — basic automatic use of a selected slot.
2. **Deployment Sequences** — ordered slot rules such as 1 → 3 → 2.
3. **Synchronized Deployment** — wait for multiple cards, then deploy them together (needs 2 active slots to be used, §20.4).
4. **Smart Workforce** (v0.11) — Smart assignment for Villagers (§7.6).
5. **Game Speed** — two ranks (again since v0.20; one rank in v0.18 and v0.19): rank I unlocks 2x, rank II unlocks 3x. Rank 0 plays at 1x only; rank 1 offers 1x and 2x; rank 2 offers 1x, 2x and 3x. Each rank's card says only its own speed ("Unlocks 2x game speed.", then "Unlocks 3x game speed."). The speed controls clamp to the fastest speed unlocked. (The Clockwork Command Decree, which opened 3x, was removed in v0.23.)
6. **Formation Drill** (one rank since v0.20; Formation Drill I and II in v0.18 and v0.19; a Glory upgrade before) — unlocks Block, Spread and Wedge for squads and assault groups.
7. **Rival Intelligence** (v0.18) — reveals the rival's exact defenses, Castle strength and reinforcement reserves before you attack; without it the Assault Planner shows no rival military information (§54.3, v0.20).
8. **Battle Signals** (v0.18) — hold a later assault group at sea and release it yourself (§54.7); requires Second Assault Group.
9. **Royal Provisioning** (v0.22, one rank) — "One in-run Glory Upgrade purchase per 10 waves cleared (up to 10 a run). +2 Active Train Slots." The in-run Glory shop (§18.3) and, as of v0.23, **+2 Active Train Slots** (§13.4) in place of v0.22's mistaken +1 saved card; kept by every ordinary Prestige, reset by an Ascension. Its rank came from Established Kingdom (§20.7), so the pool stays 33 ranks for Rivals 1 to 33.

### 20.7 Kingdom Boost pool (15 ranks)

Four ranks each since v0.18 (five before), each rank a little stronger so the fourth stays meaningful; Established Kingdom three since v0.22 (its fourth rank became Royal Provisioning):

1. **Kingdom Output** — +30% resource delivery yield per rank.
2. **Population Expansion** — +35% population capacity per rank.
3. **Spoils of War** — +50% Glory from enemies per rank. Its card says what Glory is for (v0.20): "+50% Glory from enemies. Glory buys Glory Upgrades that last until your next Prestige." The Prestige Upgrades panel shows the total once ("+100% Glory from enemies. ..." at rank 2).
4. **Established Kingdom** — +175 starting Wood, Gold and Food per rank (3 ranks since v0.22); since v0.23 also, per rank, **+1 point of storage per offline hour** for each resource (added to the hourly rate, never Glory) and **+10% to the whole offline reward** (resources and Glory, a multiplier after the hourly calculation): +30% at rank 3 (§22.2). Its card: "+175 starting Wood, Gold and Food. Offline: +1% of storage per hour and +10% offline rewards."

~~Royal Tribute~~ (v0.11: 2 Glory per game minute) was removed in v0.18 and is not replaced by another passive Glory income.

### 20.8 Prestige trigger (as of v0.18)

**One conquered rival = one Prestige opportunity (§54).** Renown no longer exists: Glory earned fills nothing, no table of requirements remains, and a defeat unlocks nothing (the v0.10 "Prestige starts with the first real defeat" rule is gone; a player may conquer Rival 1 before ever losing a kingdom). There is one rival per Prestige rank: 33 ranks (Expansion 8, Command 10, Kingdom Boost 15), Rivals 1 to 33, and since v0.23 a 34th, the final rival, conquered for an Ascension instead of a Prestige (§20.9, §54.17); a probe checks that the rival count is the rank total plus one.

When the current rival's Castle falls, one offer is created and saved (§20.3). It is **optional and can be deferred**: the conquest message offers **Prestige now** or **Stay in peace**; a waiting offer can be taken later from the Castle panel or the results screen. It cannot be committed during the overrun, while an assault is under way, while an offline reward is unclaimed, or while an Ascension must be resolved first. Prestige is what moves the player to the next rival; a defeat keeps the same one.

Every Prestige surface reads one value (§54.12): the HUD block (RIVAL n, READY, COMPLETE), Stats ("Conquer Rival 8, Stormkeep"), the run receipt and the confirmation.

**Prestige READY (v0.19).** While an offer waits, tapping the HUD's Prestige block opens that offer (the same one, never rerolled), however long ago the player chose "Stay in peace"; the Castle's **Prestige now** and the results screen remain other ways to it. The conquest message says so: "Tap PRESTIGE READY at the top when you want it."

**Prestige Upgrades panel (as of the Android corrections; its own ⓘ target as of v0.19; "Owned Prestiges" before v0.20).** Tapping the HUD Prestige block's ⓘ column (and the block itself when no offer waits) opens a read-only **Prestige Upgrades** panel, never the Prestige offer or its details. It lists **only the Prestige ranks the player owns**, grouped by role: each with its name, its rank when the card has several ("Rank 3 / 4"), and a concise current effect ("+90% resource delivery yield"). It buys, chooses, rerolls and changes nothing. A line under the total says they are earned by conquering rival kingdoms and kept for good. With no rank owned it does not open; a short "No Prestige Upgrades yet." shows under the block instead. It is an ordinary panel: it never pauses and follows the tutorial arbitration (§27.4). There is no Prestige 34: once all 33 are taken the current rival is Rival 34, whose conquest offers an Ascension (§20.9 as of v0.23).

### 20.9 Ascension (Super Prestige; redesigned in v0.23)

**The trigger.** Each Prestige cycle climbs Rivals 1 to 33, one Prestige rank each, which owns all 33 ranks and reaches **Rival 34, the final rival** (authored, stronger than Rival 33, §54.17). Conquering Rival 34 does **not** create a Prestige offer: it creates an **Ascension**, saved at once with the conquest. Wave 100 is never a trigger (§54.11).

**Deferrable and safe.** The conquest message offers **Ascend now** or **Stay in peace**; the HUD's Prestige block then reads **ASCEND** and opens it, as do Castle, the Attack panel and the results screen. It is refused at the same moments as a Prestige (the Pause, the overrun, an assault under way, an unclaimed offline reward) and never blocks a new run. A reload, a new run or a second conquest never loses, duplicates or rerolls it: the record holds no drawn cards, only that an Ascension waits.

**The choice.** The Ascension screen shows **all nine Decrees** (owned ones marked and off; no random three); the player chooses any Decree not owned yet. A strong confirmation (the Prestige confirmation's pattern: what is gained, kept and reset, an acknowledgement, a red button) commits it.

**One atomic transition.** +1 Crown and the chosen Decree; then a **new Prestige cycle**: every Prestige rank, the Prestige count, the waiting Prestige offers and the fair-draw history reset, with every layer below them (Glory, Glory Upgrades, the run, its Salvage, the mission board); a fresh kingdom faces **Rival 1**. Kept: Crowns, owned Decrees, lifetime statistics, the Bestiary, onboarding and tutorial memory, the first-run progression, settings, the default priorities. One save at the end; a force-close lands before or after all of it. The new cycle's first Prestige has its building guarantee again.

**Nine at most.** At **9 / 9** Crowns with every Decree owned the account is **fully Ascended**: conquering Rival 34 again gives no tenth Crown or Decree and forces nothing; the world simply goes on, and every surface says so (COMPLETE on the HUD, "Fully Ascended" in Stats).

**Each Crown** (stacking additively by count): **+50% Glory earned, +30% friendly damage, +20% friendly HP**. Friendly means soldiers, our Towers and the Castle (its attack and its HP), never enemies or rivals. At 9 Crowns: +450% Glory, +270% damage, +180% HP from Crowns alone. Each multiplier is applied once, in the one getter that owns it (troop damage and HP, Tower damage, the Castle's attack and maximum HP, the Glory every source takes); a run starts with the Castle full.

**The nine Decrees** (Clockwork Command was removed in v0.23):

1. **Royal Architects:** construction twice as fast; every run starts with drop-offs already complete, one by each resource area of that run's map, up to 2 Lumber Camps (the two forest corners), 2 Mining Camps (the two quarries) and 2 Farmsteads (the two herds), placed by the placement rule (never overlapping, never duplicated); free every run (no charge, and the player's own camps are not priced up by them). Founding Camps adds nothing on top. More copies may be built as usual.
2. **Ancient Foundations:** once **Advanced Construction** is owned in the current cycle, every newly constructed building (and the starting Castle, House and Barracks) is completed at **Tier 2** for the Tier 1 price and work. Never before Advanced Construction, never Tier 3 (still an upgrade behind Master Construction); a building already standing at Tier 1 is not raised.
3. **Veteran Legions:** unchanged: units spawn one tier above their building, capped by the highest tier unlocked; Tier 3 military buildings add +25% stats.
4. **Endless Coffers:** +100% storage and **+30% Salvage**.
5. **Sovereign Walls:** Castle HP x2, triple Castle repair between waves, and **10% of the damage an enemy deals to the Castle is dealt back to it**, as an ordinary Castle hit (its armour and shields apply; one way, never a loop).
6. **Twin Banners:** **each finished training produces two units** at the price and time of one, from every source (Train cards, a building's Train button, automation). The second is no queue entry (nothing to cancel or refund); it needs a free population place when it comes out, else only one does; **+2 saved Train cards** (never slots).
7. **Golden Age:** **+100% resource delivery yield, +50% Villager speed, +4 h offline time cap, +50% offline rewards** (resources and Glory, §22.2).
8. **Glory of Kings:** **Glory earned x4** (every source) and **unrestricted in-run Glory Upgrade purchases** (§18.3), even before Royal Provisioning in a new cycle.
9. **Warden Towers:** Towers unlocked and **every Tower site open** from the first kingdom of each cycle, without Tower Engineering; **+100% Tower damage**. Rival Towers are untouched.

A Decree that builds on a Prestige unlock (Ancient Foundations, Veteran Legions) can be chosen at any time and waits for that unlock in each cycle; it never opens a tier Prestige has not unlocked.

**Older saves (pre-release, §28.6).** An owned Clockwork Command (or Renowned Dynasty) is dropped and its Crown kept; an Ascension offer drawn by the retired Wave 100 trigger is dropped.

### 20.10 Prestige is a deeper reset

A Prestige grants the chosen card permanently and **resets every layer below Prestige**. Only the Prestige layer itself and the layers above it survive.

| Layer / field | At Prestige |
|---|---|
| Active run (kingdom, buildings, Villagers, army, queues, squads, run resources, run upgrades, research, wave) | Reset: replaced by one fresh run with the baseline Barracks |
| Glory balance | **Reset to 0** |
| Glory Upgrade levels (including Tower Capacity, Squad Command, Castle Armory and Expanded Command) | **Reset to none** |
| Wave 100's cut of the current rival's reserves | Reset (the next rival starts whole) |
| Pending results receipt and Salvage from the last run | Cleared (a Prestige run starts without Salvage) |
| Mission board | Re-rolled (unclaimed rewards are lost; the confirmation says so) |
| Saved card configurations | Kept but trimmed to the base capacity; slots and automation re-sanitized |
| Prestige cards and ranks, Prestige count | **Kept** (the reward) |
| Ascension layer: Crowns, Decrees, pending Ascension, endgame records | Kept (above Prestige; an Ascension itself resets the Prestige layer, §20.9) |
| Statistics: lifetime Glory, runs, best wave, kills, counters | Kept |
| Bestiary discoveries | Kept on purpose (informational collection) |
| Onboarding choice and tutorial progress, seen hints, coach-hint memory and introductions | Kept on purpose (a Prestige never replays first-run onboarding) |
| The first-run progression (its stage and demonstrated goals, §27.5) | Kept on purpose: once complete it is never replayed |
| The fair-draw history (how often each card has been offered) and the conquest count | Kept |
| The current rival | Advances: the Prestige count is the rival number minus one |
| Default Villager priorities (a preference) | Kept |
| Settings (audio, speed, accessibility) | Kept |
| An unclaimed offline reward | Must be claimed before a Prestige can be committed |

### 20.11 Prestige confirmation

Committing a Prestige opens a strong confirmation (the special paper treatment) that states:

- the milestone that was reached;
- the reward the chosen card grants;
- exactly what will be lost, explicitly naming the current Glory and every owned Glory Upgrade;
- which rival the next kingdom faces (stronger);
- what is kept;
- that it cannot be undone.

The confirm action is a red danger button that stays disabled until the player ticks an acknowledgement; Cancel is always available.

### 20.12 Atomic transition

The commit is one saved transition: grant the card, reset the lower layers, create the fresh post-Prestige run, save once. A force-close lands either before the commit (the same offer is still waiting) or after all of it, never in between.

---

## 21. Defeat and Reward Flow

```text
Castle HP reaches 0
→ combat-loss state locks
→ enemies breach Castle
→ enemies attack Villagers / destroy buildings
→ player may speed/skip after first viewing
→ calculate permanent currency already earned from enemy drops
→ calculate Salvage
→ show run results
→ allow Glory Upgrades
→ optionally commit a waiting Prestige (strong confirmation, atomic)
→ start new run
```

Enemy permanent currency is credited automatically during the run, not left as physical pickups requiring collection.

The result screen should act as a receipt and show at minimum:

- wave reached;
- permanent currency earned;
- Salvage value;
- important progression/unlocks available.

---

## 22. Offline and Persistence

### 22.1 Offline rule

Closing the application **freezes the active run**.

While offline:

- no combat advances;
- no waves advance;
- no gathering advances;
- no construction advances;
- no research advances;
- no training/deployment advances.

The player returns to materially the same run state.

### 22.2 Offline reward (as of v0.23)

The game awards a capped reward for time away. Only a player who has started playing earns it: before the onboarding choice is made and some play time exists there is no offline reward to calculate, so a first launch left on the chooser never shows a welcome-back receipt beside the tutorial. The kingdom stays frozen (§22.1): the reward never runs waves, combat, gathering, construction, research or training.

**Eligible time.** `counted = min(time away, cap)`, at least 5 minutes away; **cap = 4 h base + the Offline Time Cap Glory Upgrade (+2 h a level, +8 h) + Extended Reserves (Kingdom Upgrade, +0.3 h a level, +1.5 h) + 4 h with Golden Age**: 17.5 h with everything. The receipt shows the time away and the time counted.

**Resources (v0.23).** For a standing kingdom past its first-run progression (never a finished run awaiting its results), Wood, Gold and Food each earn a share of the kingdom's current storage capacity per counted hour:

1. hourly rate = **1%** + 0.5 point per Supply Routes level (Kingdom Upgrade) + 1 point per Established Kingdom rank (Prestige): 1% to 3% from Supply Routes, 6% with both maxed;
2. raw = capacity × counted hours × rate;
3. × the reward multiplier: **Established Kingdom +10% a rank** (after the hourly calculation, x1.3 at rank 3), then **Golden Age x1.5**; e.g. 1,000 Wood → 1,300 → 1,950; an effective 7.8% an hour at Established Kingdom 3 and Supply Routes 4 before Golden Age;
4. rounded down to whole units, then **limited to the free storage** of each resource when the receipt is made (95 / 100 Wood takes 5; a full store takes 0, "Storage full"); never past the cap, never replacing what is stored.

**Glory.** The offline Glory rate (Offline Glory Rate Glory Upgrade) for the counted minutes, × the Glory every source takes (Crowns, Glory of Kings, once), × the same reward multiplier (Established Kingdom, Golden Age), rounded down to 0.1. No storage limit. Supply Routes never raises it.

**One calculation, one receipt, one claim.** The receipt is saved as pending with the amounts it shows (raw and fitted resources, Glory) and survives any relaunch; a second absence adds to it and is fitted again to the same free storage, so nothing ever adds past the cap. **Claim** credits exactly what it shows, once, and saves at once; it is not a delivery (no gathering counter, no first-run goal moves). A pending receipt from before v0.23 holds Glory only and claims as such.

**The Welcome Back receipt.** A true modal: the time away and counted (with the cap), Wood, Gold and Food each with what Claim credits ("Storage full" where the space cut it), the Glory with one line: "Glory buys Glory Upgrades that survive defeats but reset when you Prestige.", and one short line of the boosts applied; Claim always on screen on a phone.

This reward is separate from active kingdom production and must never make closing the game the optimal way to gather run resources: its rates are a small share of storage per hour and capped in time and space.

### 22.3 Active-run persistence

Save enough authoritative state to resume fairly, including:

- current wave and wave progress, and what is left of the danger zone's window (§3.4);
- Castle HP/state;
- current run resources;
- resource storage/capacity;
- corner resource profiles and every node's stock and respawn timer, by authored site id;
- buildings, positions (the start plots a run drew included), tiers, construction projects, progress, and order;
- Villagers, priorities, carried resources, and relevant work state;
- each Villager's direct world order as intent only: its kind, the stable id of its node or building, the ground of a Move (§7.4d);
- the profile's first-run progression: its stage and the goals already demonstrated (§27.5);
- loads dropped on the ground by reassigned Villagers (resource, exact amount, place);
- active friendly military units and meaningful combat state;
- active enemies and meaningful combat state;
- deployment card configurations and slot assignments;
- training queues (per building) and their progress;
- unit stances, squads and formations; where a Standby soldier is (in reserve, walking in, marching out: its march stage) and whether the Castle emergency holds (§12.6a);
- each soldier's direct order: its kind, its spot and the stable id of its enemy (§12.10); the selection itself is presentation and is not saved;
- mission board and claims; Bestiary discoveries;
- automation rules/timers;
- run research/upgrades;
- permanent currency/progression;
- unresolved Prestige offers, their fair-draw history, the current rival's Wave 100 cut;
- the rival kingdom (v0.18, §54.14): the Assault Planner's plan; an assault under way (the rival Castle's HP, every rival unit, each group's deployment state and timers, each military building's reinforcements and timers, the anti-stall stage and clock, each soldier's assault stage and group); whether this run's rival has fallen;
- Salvage/result state when applicable.

Transient presentation such as particles or in-flight cosmetic visuals can be rebuilt from authoritative state rather than serialized literally.

---

## 23. Enemy Asset Strategy

The final enemy pack is not part of the current project assets.

Therefore enemy implementation must be separated into:

```text
enemy definition/data
+ combat behavior
+ wave composition
+ presentation profile
```

The prototype may use one reused friendly character as the visible enemy placeholder while still defining multiple data archetypes.

Later replacement should require changing presentation/configuration data rather than rebuilding the combat/wave systems.

The correct purchased enemy art will be integrated only after it is available.

---

## 24. Tiny Swords Asset Direction

The current Tiny Swords package already contains the core friendly visual language needed for the prototype, including:

- Castle
- House variants
- Barracks
- Archery
- Monastery
- Tower
- Warrior
- Archer
- Lancer
- Monk
- Pawn/Villager
- Wood resources
- Gold resources
- Meat/Food resources
- multiple authored faction/palette variants

The project should prefer authored palette variants over generic runtime tinting for major tier/progression visuals.

A dedicated Mage is not currently present in the supplied package, so the Mage requires a placeholder/adaptation until final art is chosen.

---

## 25. Balance Authority

The following are **not locked design contracts** and can be chosen during implementation, simulation, and playtesting:

- unit costs;
- building costs;
- construction times;
- unit HP/damage/range/cooldowns;
- Tower values;
- resource stock and respawn values;
- gathering yield;
- storage capacity numbers;
- House population values;
- permanent-upgrade percentages;
- Prestige threshold curve;
- enemy reward ranges;
- wave sizes/compositions;
- offline reward rate/cap;
- exact Tier 2/Tier 3 bonuses;
- the share of armour each attack type meets (§12.8; the v0.9 values are the brief's);
- command-buff cost/effect values;
- Salvage upgrade values beyond the initial target.

Balance should be data-driven so these can be changed without modifying system logic.

### 25.1 Initial pacing target

A fresh player on the first run should normally survive approximately **10 to 20 minutes** before the Castle is destroyed.

This is a pacing target rather than a fixed timer. Player decisions, resource layout, combat performance, permanent upgrades, Prestige, automation, and later progression are expected to change run duration.

Initial balancing should use repeatable simulations/probes where practical and should record the assumptions used when evaluating first-run duration.

---

## 26. Wave Content Framework (100 waves in v0.4)

The game uses a table-driven wave definition rather than hardcoded stage logic. v0.4 authors 100 waves (§15.3 has the schedule); the milestones below are the v0.3 outline it grew from.

Conceptual milestones:

```text
Wave 1      basic placeholder enemy set
Wave 10     introduce normal archetype slot B
Wave 20     introduce normal archetype slot C
Wave 25     Elite/Boss milestone
Wave 30     introduce normal archetype slot D
Wave 40     introduce normal archetype slot E
Wave 50     major Elite/Boss milestone + current endgame completion + Super Prestige offer
```

Older enemy types can:

- disappear from later compositions;
- remain as swarm/filler enemies;
- combine with newer archetypes in larger numbers.

The final wave table is a balancing/content artifact, not a code branch per stage.

---

## 27. UI / UX Contracts

### 27.1 Mobile-first readability

- large touch targets: important buttons at least 76 px high at the 1920×1080 reference (dock and HUD larger), text sized for a phone held at arm's length;
- **less text, larger key values**: every card and chip leads with its primary value or action in large type, then one short supporting line, and detailed text only where genuinely needed. Costs, requirements, consequences, reset warnings and unusual mechanics always stay explicit; obvious button behaviour is not explained. Text density is never solved by shrinking fonts;
- readable text at physical phone size;
- safe-area-aware layout;
- avoid critical controls on unsafe bottom/display edges;
- hubs and panels must remain useful without becoming dense spreadsheets.

### 27.1a Scrolling

Every scrollable list scrolls by dragging **anywhere** on it, including a drag that starts on a button or card. A drag past a small dead zone scrolls and never activates the control it started on; a tap still activates it. Buying a permanent upgrade (or any in-place list action) keeps the list's scroll position.

### 27.1d Build Shelf (as of v0.15)

Build is an action surface, not a management panel: the Build tool toggles a **horizontal shelf** of compact building cards along the bottom of the free map area, centred, as wide as its cards up to that area (then it scrolls sideways), low enough to leave the world visible (one card row). Each card shows the building's picture, its name, its current cost (red where short) and one fixed status line: why it cannot be placed now ("Need more Wood", the Pause, a limit, Tower capacity) or how many stand ("Built 2 / 4", "Towers 1 / 3"); a reason never adds or removes a line (§27.1f), and the card dims while it cannot be placed. The card being placed is marked. The order is the game's building order; buildings the first-run progression has not revealed are absent (§27.5); a Prestige-locked building shows as a locked card ("Prestige unlock"). Benefits and supporting text are no longer repeated on the cards: the building's own context card and How to play explain them.

**Readability (v0.16).** The cards are read at phone distance, at the scale of the top resource chips (their amounts 36 px, their secondary text 24 px): the building's name about 30 px (fitted down to 24 px only for the longest names), the cost about 28 px beside 32 px icons, the status line about 26 px (24 px at the least), a 72 px picture, cards about 312 px wide. Fewer whole cards fit at once (four at the reference); the shelf scrolls for the rest and scrolling brings every card wholly into view. Text is never clipped or shrunk back to fit more cards. Gestures, the fixed status line, the card states, the safe area and the room left to the map are unchanged.

While open, the shelf counts as HUD at the bottom (the map can be pulled up from under it); the build-mode bar (one low row: the building and why it cannot go here, the four arrows, Place, Exit Build Mode) sits just above it, and the compact Selection Status above whichever shows. The shelf, the side panels and an expanded selection never stack: opening one closes the others; the compact status coexists with the shelf.

### 27.1e Stable panels

A panel is one stable screen whose data changes, not a new layout every time the state changes:

- **A panel appears at its final size.** Its content is laid out while it is still invisible; it shows once its size has settled (in practice two or three frames), so the player never sees an oversized first layout shrink into place. This holds for every side panel and context card.
- When the content of an open panel changes size (a line appears, a card is rebuilt), the panel is resized once, straight to the new size; a first, unsettled measurement is never shown.
- Fixed controls stay fixed: header areas that the player acts on (such as Villagers' population, Recruit and the default task) are pinned above a list that scrolls on its own, and keep their place and size while the list grows.
- Short status lines never wrap; a text too long for its place is shortened. No label may collapse into a narrow column of broken words.

### 27.1f A block reason sits beside the cost (v0.8)

A card that sells something (a run upgrade, research, a building's next tier, a building in Build, a unit or a Villager to train) never adds or removes a row for a warning. Its cost and, on the same row, the reason it cannot be bought now share one line of fixed height:

```text
Title
Description
Cost                         Warning
```

```text
Wood 120                    Need more Wood
Gold 250                    Unavailable while paused
Food 80                     Needs Advanced Construction
```

- The card keeps its height and every button its place while affordability, the pause or a requirement changes; a list never jumps.
- The reason is short and decision-relevant (what is missing, or which unlock opens it), in a slightly smaller type than the card's small text, still readable; it is one line and is never cut at a phone's screen shapes. The action layer's full reason stays the source (and the text of any toast).
- Values that change while a card is open (a queue, a countdown) keep a fixed line too, empty or idle rather than hidden.

### 27.1c Stats

A Stats page (dock) consolidates the current effective values, so the player never adds percentages across menus.

**Current Boosts (v0.10)** is its first section: what Glory Upgrades, Prestige Upgrades and Ascension give right now, grouped by the effect the player feels (Combat, Economy, Command and utility), not by which system owns it. Each row shows its total (Unit Damage +54%, Deployment Slots 5, Building Tier II, Game Speed 2x...) and under it where that comes from ("Glory Upgrades +40% · Prestige Upgrades +60% · Ascension ×1.1", the source named by its layer as of v0.20; additive sources as +%, multiplying ones as ×). Only owned effects show; a fresh profile says there are none yet. Every total comes from the same effective getters the game uses; Kingdom Upgrades and research are not part of it. Smart Workforce, Battle Signals and Rival Intelligence as unlocked, Assault Groups and Formations as counts (v0.18), and an owned but dormant Synchronized Deployment says "Requires 2 Deployment Slots".

The page then shows every unlocked unit as it would be trained now (HP, damage or healing, attack interval, range, speed, training time), the Castle and Towers (HP, attack, capacity), the economy (gathering time per resource, carry, Villager speed, construction rate, storage, regrowth, node stock, next recruit, population), rewards (Glory multiplier, Salvage, offline rate, the next Prestige: the rival to conquer), and lifetime statistics (runs, best wave, time played, kills, Glory, Prestiges and Crowns, rivals conquered, units trained, Villagers recruited, buildings, resources gathered, research, Bestiary progress). Every number comes from the same getters the game uses.

**Time played (v0.10)** is two figures: **Real Time Played**, the wall-clock time the kingdom was running, and **Game Time Played**, the simulated time after the game speed (10 real minutes at 3x add about 10 minutes and 30 minutes). Neither counts paused time, time on the results screen or time away (offline time is never active play, §22.1). Both are saved with the profile.

### 27.1b Tiny Swords visual language

- Selected objects are framed by the Tiny Swords corner cursor, scaled to stay readable at every zoom and following moving targets, using the same pick geometry as tapping.
- Panels and cards use the Tiny Swords paper assets by importance: ordinary cards on plain paper, important or special content (Prestige, rewards, highlights) on the special paper, section headers on ribbons, danger actions in red.

### 27.2 Feedback

Automated actions must remain visible and understandable.

Examples:

- Villager gathers/carries/deposits resources visibly;
- construction visibly progresses;
- resource delivery shows the actual credited amount including specialized bonus;
- automated deployment shows which slot triggered;
- a struck resource reacts on the tool's contact: a tree sways, a Gold deposit springs, a sheep hops and **flashes red briefly**, then returns to its own colour (repeated strikes never leave a tint);
- a load dropped by a reassigned Villager pops onto the ground and says what it was (§7.4b);
- waiting automation shows why it is waiting;
- population/storage bottlenecks have clear warnings;
- Tier 3 special attacks have distinct feedback.

### 27.3 Automation status

Where useful, expose authoritative automation state such as:

- `Waiting for Gold`
- `Waiting for Food`
- `Next: Slot 3`
- `Deploying Slots 1 + 2`
- `Delay: 3s`

The UI reads the real automation state; it does not duplicate timing formulas.

### 27.4 Tutorial and panel arbitration (as of the Android corrections)

Tutorial guidance (the Guided pointer and caption, Basic's stage notes and coach hints, §35) **may share the screen with a panel only when the current step belongs to that panel**. Every step names where it belongs: the HUD and the world with no panel open, or one panel (the Villagers list for Recruit, a Villager's card when the player opened it). As of v0.15 the Build Shelf is part of the HUD: a step pointing at a building's card on it belongs to the HUD and shows with no panel open; a selected Villager's next tap (the resource or construction) belongs to the world, or to its card while that is open.

- Opening any other panel (Stats, Prestige Upgrades, a building's card...) or a task dropdown at once hides the caption, the hand and the frame; the step itself stays pending. Nothing of a hidden step takes input (the guidance never does).
- Closing or switching panels re-reads the real state at once: a step already satisfied completes (and the next one follows); otherwise the guidance returns on the live target control. Switching from panel to panel never leaves a pointer behind, and closing the intended panel early never stalls the tutorial (its step simply points at the way back in).
- **Mandatory steps check the resulting state, not a click.** A Villager already Building is not asked to pick Build; a Villager already on a resource is not asked to start again; the tutorial never asks the player to undo a correct state to satisfy it.
- **A lesson completes on the learned result, not when the work starts (v0.16).** Each core Guided lesson completes on its first-run goal (§27.5): the delivered target, three Villagers walked out, the building complete, the first defender trained. Starting the work (a Villager sent to a Sheep, recruits queued, a site placed, a builder assigned, a Warrior queued) keeps the lesson where it is. While the work is under way the lesson shows its progress ("Gathering Food: 7 / 14 delivered.", "Villagers training: 1 / 3 ready.", "Building the Lumber Camp: 40%.") with a soft gold outline on what to watch (the Villager, the construction) and no hand: the player is never sent to repeat what is already happening, and the next concept never appears early. If the work stops (its node ran out, the builder left), the lesson points at the way to start it again. There are no tutorial timers: the work is the pacing.
- Blocking and full-screen modals always outrank the guidance.
- **Guided says what a building does (v0.23).** Before asking for an economy building (its Build Shelf card, or Build first) and throughout its placement, until Place, the Guided caption says what it does and where it belongs, true to the game: "A Lumber Camp is a Wood drop-off: Wood delivered there is worth more. Build it near trees."; the Mining Camp (Gold, near Gold deposits), the Farmstead (Food, near the Sheep), the Storage (raises the Wood, Gold and Food limit and takes all three, where Villagers pass). The first defender's step says the Barracks trains soldiers to defend the Castle. No new step, no timer; the suggested spot and the progress and wait states are unchanged. Guided only: the Glory ? and the locked Train places are for every mode.
- **Feature guides are not tutorials (v0.22).** A one-time pointer at a feature the player has just earned (today only Royal Provisioning's first purchase, §18.3) uses the same pointer and the same arbitration, in **every onboarding mode, No Tutorial included**, below any tutorial step (it never takes the screen from a lesson, a stage note or a coach hint). It belongs to the HUD with no panel open: a panel, the task dropdown, build mode, the Build Shelf or the expanded selection bar defers it, never cancels it. It retires only on the player's own discovery (opening what it points at), never because it was shown.
- The frame and hand follow the target control's **live** rectangle every frame (and a world target's current screen position), so a panel settling at its size, a list scrolling, a relayout, a rotation or a safe-area change, or a rebuilt panel never leaves them on stale coordinates; a panel's controls are pointed at only once the panel shows at its final size.
- A reload restores the logical step from the saved progress, then re-evaluates the state and the open panel before showing anything. As of v0.16 the progress itself (deliveries, Villagers in training, a construction and its builder) comes from the run's own saved state, so a reload mid-lesson resumes the same lesson at the same progress, never replays a finished one and never skips a building because its builder was already at work.

### 27.5 First-run progression (v0.12)

The pristine profile's first kingdom is revealed in stages. This is the game's first-profile pacing, **not** the tutorial: the tutorial mode (§35) only sets how much help is shown, and all three modes play the same kingdom, costs, economy and gates. There are no wait timers: an experienced player clears the goals quickly.

```text
Fresh profile -> SETTLEMENT -> DEFENSE PREPARATION -> first invasion countdown = COMPLETE (permanent)
```

| Stage | Gate | Goals (latched once each, in any order) | Revealed |
|---|---|---|---|
| **Settlement** | no wave advances, no enemy spawns, nothing can be lost; training and military buildings are refused ("Unlocks once your settlement is established") | Food 14, Wood 42 and Gold 14 delivered (v0.16; the starting stock does not count); 3 completed Villagers; a completed Lumber Camp, Mining Camp, Farmstead and Storage | resources, population, Villagers, Build (its shelf lists the economy buildings only), Projects, the world and its context cards, Pause, speed, Settings |
| **Defense Preparation** ("SETTLEMENT ESTABLISHED") | still no wave | the first defender trained (it walks out of its Barracks) | the Train rail, a Barracks' Train section, military buildings on the Build Shelf, Army, Castle |
| **Complete** | the first wave's countdown starts at a generous 60 s (Balance.FIRST_RUN_GRACE) with the usual first-wave warning: no enemy is spawned by the training itself | none | the wave and Castle HP readout, Glory, the Prestige block, Upgrades, Research (with its unlock), Missions, Bestiary, Stats, **Attack** (v0.18): everything |

- **Demonstrated actions, not balances.** A resource counts once its **delivered target** has reached storage in this kingdom (v0.16: **Food 14, Wood 42, Gold 14**, from one table; deliveries only, never the starting stock; spending never lowers the count, which is a demonstrated action, not a wallet requirement); a building once it is complete (a placed site is not); the population once three Villagers have walked out (queued recruits reserve population but do not count). Each goal is latched in the profile when first met, so spending, demolishing or losing something later never un-ticks it. The targets are long enough to watch gather, carry and deliver happen a few times rather than one instant tick, and short enough not to drag.
- **No deadlock.** The House is a drop-off for all three resources from the start; the starting Food pays the two recruits (20 + 23); the four buildings cost 160 Wood and 10 Gold, and the 42 Wood target with the starting 120 makes 162, so the building lessons that follow never stall on a Wood shortage; the Castle's storage (200) holds it.
- **One objective card.** A compact card at the top of the right rail names the stage (SETTLEMENT, then DEFENSE) and lists its goals with their progress ("Population 1 / 3", "Food 7 / 14", "Wood 28 / 42", "Gold 14 / 14" once reached, a building "Done"), never which button to press. As of v0.16 it reads at the resource chips' scale: the title about 36 px, the rows about 28 px, each on one line so the card never changes height as the numbers move; the right rail is 330 px wide (was 300) so "42 / 42" and the longest names fit. It is read-only (taps pass to the map) and disappears for good at completion.
- **Completion is marked when normal enemy progression begins**, not at the first defeat: the moment the first defender is trained, the profile's progression is complete, permanently.
- **The next loop is said once (v0.17).** At that moment, in **every** tutorial mode (Guided, Basic and No Tutorial alike: it is the game's goal, not tutorial guidance), a non-blocking HUD message shows for about 10 seconds: "Your kingdom is established. Keep developing, defend against enemy attacks, and prepare to attack the rival kingdom when you're ready." It never pauses, shows at once even beside other messages and is never dropped from the queue, and it comes from the progression's own completion, never from a tutorial lesson, the Basic cards, a timer or a button. It shows once per profile: it is remembered with the profile's one-time hints, so a save and reload, death, new runs and Prestige never replay it; only Hard Reset (a fresh progression) can show it again. The first invasion's countdown message follows it.
- **Profile scope.** The stage and the latched goals are profile data: they survive save and reload, force-close, death, new runs and Prestige (§20.10); a relaunch cannot bypass a gate. After completion every later run (after a death, after a Prestige) starts as the normal, fully revealed game with normal enemy timing; no stage, objective card, hidden menu or delayed enemy returns. Only Hard Reset (a truly fresh profile) starts the progression again (§28.5).
- **One place decides what shows.** Every surface asks the same reveal table (the HUD, the panel host, the Build Shelf, context cards and the action layer), so a hidden system cannot be opened from another path either.
- **Later systems** need no further gating: after completion the existing one-time introductions (Guided's later lessons, Basic's contextual hints, enemy introductions) present them when they first matter.
- **Guided pacing (v0.16).** Guided walks the goals in its teaching order (Food, Recruit, Wood, Gold, then the economy's buildings, then the first defender) and each lesson completes on its goal (§27.4). The economy's buildings are taught **one at a time, in the order Lumber Camp, Mining Camp, Farmstead, Storage**: its Build Shelf card, its placement, a Villager for its construction, then its construction's progress until it is **complete**; only then the next. A building the player completed early, out of order, is skipped when its turn comes: never asked for again.
- **A suggested placement (v0.16).** When the player chooses the building Guided is teaching, the preview starts once at a **recommended spot** from the real map and the real placement rules: a Lumber Camp by the Trees, a Mining Camp by the Gold Deposits, a Farmstead by the Sheep (each the nearest valid footprint to that resource's node nearest the Castle, the rule that places prebuilt starting camps), the Storage by the Castle and House as a general drop-off. The camera turns to it if it is out of view, the caption says why ("Suggested: place the Lumber Camp near Wood to shorten deliveries."), and a soft gold outline marks the suggested footprint. It is a suggestion, never a rule: the player may drag, tap or use the arrows to place it anywhere legal, and the preview is never snapped back once moved; nothing is placed or spent by the tutorial; the normal Build Shelf tap, lift and Place paths are unchanged. Basic and No Tutorial get no suggestion.

### 27.6 Selecting several units: input (v0.14)

The camera's gesture rules (one finger pans, a quick tap taps, two fingers pinch, a gesture that starts on UI never reaches the world) stay; selection takes two gestures that had no meaning:

| Input | Result |
|---|---|
| tap / click on a friendly | select it (Shift or the add mode: add or remove it) |
| second tap / click on a friendly of the same type within 0.4 s and close by | every friendly of that type whose marker rectangle is in view (Shift or the add mode: added) |
| **desktop**: left-button drag on the map | a selection box; release selects every friendly whose anchor (the centre of its pick rectangle) is inside, replacing the selection (Shift: added, no duplicates); an empty box clears |
| **touch**: hold still for the long-press time (0.45 s, the tap's own limit), then drag | the same selection box (the add mode: added). A ring under the finger and, by it, **"Drag to select multiple units"** (v0.15) show that the hold took |
| touch: press and move before the long press | a pan, for the whole gesture: it never turns into a box later |
| touch: long press released in place | nothing |
| a second finger during a box | the box is cancelled, the gesture is a pinch; a pinch never ends as a selection |
| a modal opening during a box | the box is cancelled; nothing is selected |
| right or middle drag, wheel, trackpad | camera pan and zoom, as before (a left drag pans only in build mode, where no box is drawn) |

- A box is a selection, never an order: releasing it commands nobody and places nothing. Build mode keeps every drag (it moves the preview or pans) and every tap (it moves the preview).
- The box is drawn in the world, with a line the same width on screen at every zoom; the HUD, panels and modals lie above it.
- The gestures are mutually exclusive states (undecided press, pan, preview drag, box, pinch), decided once when the press leaves the dead zone, never a combination.
- **The long-press hint (v0.15)** shows the moment a still touch becomes a long press, never before: above the finger and clear of it on the map (below it, or beside it, where there is no room), inside the safe area, never over the top band; it takes no input and is not a toast. It goes the moment the hold ends: a box begins, the finger lifts, a second finger lands, a modal opens. It is gesture feedback, so every tutorial mode gets it, No Tutorial included; a mouse (which boxes at once), a pan, a gesture from UI and build mode never show it.
- Discoverability: the Army panel's text and the How to play card "Command" describe the controls for the input in use; Guided points at a soldier once a few stand in the field ("Hold, then drag over soldiers to select them all"), Basic shows that caption once as a note, No Tutorial shows nothing unasked (§35).

---

## 28. Save / Reset Contracts

### 28.1 Death / new run

Clears run-state systems and rolls new corner resource profiles. The first-run progression is profile scope: a new run never replays it (§27.5).

### 28.2 Permanent progression

Survives ordinary defeat/new runs.

### 28.3 Prestige

Prestige is a deeper reset: it keeps only the Prestige layer and the layers above it, and resets Glory and Glory Upgrades with the rest of the lower layers; it moves the player to the next rival. The full keep/reset table is §20.10.

### 28.4 Super Prestige

Super Prestige (Ascension) is the transition above ordinary Prestige, earned by conquering the final rival (§20.9 as of v0.23): it keeps Crowns, Decrees, statistics, onboarding and settings, and resets the Prestige layer with everything below it. It must:

- preserve the game's core rebuild loop;
- never allow force-close/reload to duplicate rewards or reroll committed choices;
- persist any unresolved Super Prestige offer until it is legitimately resolved;
- document the final reset/preservation behavior in the implementation decision audit.

### 28.5 Hard Reset

Returns the entire game to a fresh profile, including:

- permanent upgrades;
- Prestige choices;
- saved card configurations;
- tutorials/onboarding state (the game returns to the onboarding choice), including the coach-hint memory;
- the first-run progression (the next kingdom starts in Settlement again, §27.5);
- the rival progression (Rival 1 again), the Prestige offer, its fair-draw history and the Wave 100 cut;
- missions and the Bestiary;
- current run;
- settings that are explicitly part of profile reset according to final settings policy.

Implementation must update save/load/reset paths together whenever persistent state is added.

### 28.6 Save compatibility (pre-release)

The game is pre-release: old development saves carry no compatibility obligation. A substantial schema change may invalidate them and start a fresh profile; migrations for development saves are written only when the developer asks for them. **v0.18 asked for one** (§54.14): a v2 save (through v0.17) is migrated to v3, never dropped. This changes when the developer explicitly declares the game released; from then on player saves are a compatibility obligation (Playbook §61). The field-level migrations already in the game (§11.4, §42) predate this rule.

---

## 29. Production Architecture Requirements

### 29.1 Technical baseline authority

This project uses the **canonical Godot Android starter/bootstrap defined by the current Reusable Game Development Playbook**.

Unless this GDD explicitly overrides a technical setting, the Playbook's current validated production baseline is authoritative for project initialization, Android configuration, persistence/service shells, safe-area handling, export configuration, signing/bootstrap order, and validation workflow.

The expected initial baseline includes:

- Godot 4.7 Mobile-compatible project structure;
- Android-first landscape presentation;
- 1920×1080 reference layout;
- `canvas_items` stretch mode with `expand` aspect behavior;
- mobile / `gl_compatibility` renderer;
- touch emulation and mobile-safe input behavior;
- safe-area-aware layout support;
- Android AAB / arm64 production configuration;
- centralized layout, number-format, settings, audio, and save-service infrastructure;
- dedicated per-game Android identity and upload-signing configuration;
- bootstrap probes and physical Android artifact validation before release claims.

The GDD remains authoritative for **game-specific behavior**. The Playbook remains authoritative for **reusable engineering/bootstrap methodology**. If the two conflict, an explicit game-specific rule in this GDD takes precedence.

Do not duplicate the entire reusable starter specification inside this GDD. The implementation agent should read both documents and apply the Playbook baseline to this game's design.

### 29.2 Game architecture requirements

The design should remain data-driven in the areas most likely to change:

- enemy definitions;
- wave tables;
- unit definitions;
- building definitions;
- tier values;
- upgrade definitions;
- Prestige card definitions;
- permanent-upgrade definitions;
- deployment-card costs/modifiers.

Recommended state ownership:

```text
Profile / Meta State
    permanent upgrades
    Prestige choices
    long-term unlocks
    saved configuration capacity

Run State
    resources
    Castle HP
    buildings / tiers / construction
    Villagers
    resource nodes
    wave state
    active combat snapshots
    run research/upgrades

Building records
    building tier
    construction/upgrade state
    training queue and the research job owned by that building
    (completed research levels belong to the run, §10.9)

Deployment State
    saved card configs
    active slot assignments
    automation rules/status
```

Combat should be simulated from authoritative state and presented by scenes/events so save/resume and later headless balance probes remain possible.

---

## 30. First Playable Acceptance Criteria

The first gameplay implementation does not need the final enemy art or all Prestige content.

A valid first playable should prove (historical list; v0.4 replaced items 1 and 2 with the one-world camera of §3):

1. split-screen Kingdom + Battlefield layout;
2. ability to collapse/focus either half while simulation continues;
3. Castle with HP and defeat condition;
4. one randomized Wood/Gold/Food resource layout;
5. one Villager using the priority system;
6. finite storage and full-storage behavior;
7. House general drop-off;
8. at least one specialized resource drop-off with +20% delivery bonus;
9. free building placement;
10. construction queue with player-controlled priority and no passive progress;
11. Barracks + Warrior;
12. one deployment slot and saved card configuration;
13. manual deployment of multiple Warriors from one card;
14. placeholder enemy wave combat;
15. wave clear → next wave;
16. Castle death → breach/destruction presentation;
17. permanent currency from enemies;
18. run reset with Salvage;
19. save/resume of the active run;
20. debug controls for currency, wave jump, defeat, building completion, and progression testing.

Once this loop is satisfying, additional units, building tiers, automation, Prestige pools, Towers, Research, and the full 50-wave table can layer onto a stable foundation.

---

## 31. Contradiction / Missing-State Audit

### Resolved

- Castle HP reaching 0 is the normal run-loss condition.
- Kingdom is rebuilt every run.
- Permanent/meta progression survives.
- Kingdom and battlefield simulate simultaneously on one continuous world.
- Moving the camera away from a part of the world never stops its simulation.
- Resources are Wood / Gold / Food.
- Storage is finite; full storage blocks further delivery/gathering rather than deleting resources.
- Resource nodes have finite stock, become unavailable when depleted and respawn on a timer; trees and Gold grow only in authored corner zones whose profiles are re-rolled each run; sheep graze in two authored herds and never block construction.
- Prestige starts at the first real defeat (the first Prestige milestone); before it nothing accumulates.
- Every run warns once before wave 1 and marks where the enemies enter; the mark (the danger zone) lasts three waves.
- Defend Castle protects the Castle area: threat area < answer reach < hard leash, measured from the Castle front, with sustaining support enemies counted as part of the threat; Pursue commits with no leash; Intercept meets waves forward (v0.10); Standby holds a reserve behind the Castle that defends it as Defend at 50% Castle HP during a wave (30% before v0.22), its saved stance unchanged (v0.13).
- House is a no-bonus general drop-off and population building.
- Specialized resource buildings give a +20% Tier-1 delivery bonus.
- Construction requires Villagers; there is no passive build progress.
- Construction projects have a player-controlled priority order.
- Cancellation refund floor is 20% with linear loss from 100% at zero progress.
- Villagers and military share population; military deaths free population.
- One deployment card contains one unit type, but may contain multiple copies.
- Card/slot position has no inherent spawn order.
- Automation explicitly defines slot order/grouping/delays.
- Automation waits for resources rather than skipping failed actions.
- Building tier determines newly trained unit quality; Tier 3 unlocks the unit special.
- Units are trained one at a time per building, in parallel across buildings, and walk to the battlefield.
- Prestige is a deeper reset (§20.10); Glory is scarcer (36% of v0.3, §18.1).
- Enemy difficulty comes mainly from authored archetypes/compositions, not silent per-stage damage scaling.
- 100 waves are the current content target (v0.4).
- Clearing the configured current endgame (Wave 100 in v0.4) shows an endgame message, optional Discord/community button, and optional Super Prestige.
- Super Prestige is a progression layer above ordinary Prestige; its detailed rewards/reset rules are implementation-authorized and must be audited.
- Final enemy art is deferred; placeholder visuals are required now.
- Closing the app freezes the run; only capped permanent-currency offline reward is granted.
- Baseline post-defeat Salvage target is approximately 5%.
- Building tiers open through Prestige: Tier 1 on a fresh profile, Tier 2 with Advanced Construction, Tier 3 with Master Construction, for every building (v0.8).
- A higher starting tier is an Ascension Decree (Ancient Foundations: every new building at Tier 2 once Advanced Construction is owned, v0.23), never above the unlocked tier (v0.8).
- Armour is a matchup by attack type: melee meets all of it, arrows and Tower and Castle shots half, magic none; taught once on the first armoured introduction and kept in the Bestiary (v0.9).
- Shields are durability that lasts until broken (v0.10).
- Every Monastery chooses Mage or Healer for good; two may stand; each runs one research job, levels are shared (v0.10).
- Active Train Slots: 1 base, +3 from Expanded Command (Glory), +2 from Royal Provisioning (Prestige): 6 at most, all six places always on the rail (v0.23; Twin Banners gave the +2 before).
- Prestige requirements are an authored table of 33 (v0.10).
- The Lancer is unlocked by the Prestige card Lancer Training (§20.5) and trained at the Barracks (§10.7); resolves open question 3.

### Still open before final GDD approval

1. **Game title.**
2. **Storage building details.** Exact capacity source/tier behavior and whether Castle contributes base storage.
3. ~~Final Lancer unlock path.~~ Resolved: the Prestige card Lancer Training (§20.5), trained at the Barracks (§10.7).
4. **Final Mage visual solution.** Current asset pack has no dedicated Mage.
5. ~~Maximum number of active deployment slots and saved card configurations.~~ Resolved: 6 Active Train Slots (1 + 3 Expanded Command + 2 Royal Provisioning, v0.23, §13.4) and 8 saved configurations (2 + 4 Glory + 2 Twin Banners, §13.3).
6. **Business/monetization model.** Not defined by the current design conversation.

Wave-50 completion behavior is resolved: the configured current endgame displays the completion flow, Discord/community option, and optional Super Prestige. Exact Super Prestige rewards and reset/preservation details are explicitly delegated to implementation and must be audited separately.

---

## 32. Current Design Summary

The game is a run-based management defense game where a temporary kingdom funds a simultaneous battlefield. Each run asks the player to solve a different spatial economy because the corners hold different resources, then convert that economy into an army trained at its buildings through configurable single-unit deployment cards, and command it with stances and squads. Villager priorities, construction order, deployment sequencing, and eventually automation are the core strategic language.

Defeat destroys the visible kingdom, but enemy drops, Glory Upgrades, Salvage, and Prestige make the next rebuild stronger. Glory Upgrades improve efficiency, power and capacities (including Deployment Slots and Salvage). Prestige is earned by conquering the current rival kingdom (§54): an army planned in the Assault Planner crosses to the rival's island and destroys its Castle; the rival falls, the waves stop, and a Prestige (new buildings, units, tiers, automation, assault capabilities, large boosts) is ready, at the price of a deeper reset of Glory and Glory Upgrades and a stronger next rival. Conquering the final rival with every Prestige offers an Ascension: a Crown and a Decree of the player's choice, then a new ascent from Rival 1 (§20.9).

The stages are built with placeholder enemies because enemy data, wave composition, and presentation are intentionally separated. Final enemy art can be integrated later without changing the core design.

Wave 100 is the last authored wave and a milestone: surviving it cuts the current rival's reserves; the last ten waves then repeat until the rival falls (§54.11).

---

## 33. Bestiary

A Bestiary lists every implemented enemy archetype, and only those (no invented entries).

- An entry is discovered the first time that enemy appears; undiscovered entries show a silhouette and no details.
- A discovered entry shows a portrait (one extracted idle frame, never a whole sheet), name, tier (normal, Elite, Boss), role, key stats, its special attack when it has one, and how many the player has defeated.
- **Armor (v0.9).** An armoured enemy's entry shows an Armor strip under its stats: "Armor 35%" with a short explanation ("how much of it each attack meets"), then one tile per attack type in the stat tiles' grammar (a small label over a value): **Melee Full, Arrows Half, Towers Half, Castle Half, Magic Ignores**. The strip is the same on every armoured entry and is read from the table of §12.8, so no entry repeats a paragraph and a change of the table changes every entry. It replaces the single armour number ("Armor -35%"), which implied one cut for every attack. This is where the armour lesson (§15.4) stays available.
- New discoveries show a badge on the Bestiary button until viewed.
- Discoveries are profile data: kept across runs and Prestige (§20.10), cleared by Hard Reset.

---

## 34. Missions

A small board of missions (three at a time) gives short goals built on real systems: defeat enemies or a specific archetype, reach a wave, gather a resource, construct or upgrade buildings, train units, build Towers, complete research.

- Progress is measured from profile counters against a baseline taken when the mission is assigned, and shown on each card.
- A completed mission stays complete (latched) and shows a badge on the Missions button.
- Rewards are **Glory**, scaled to the player's progress and **snapshotted when the mission is assigned**; the displayed reward is exactly what is credited.
- Claiming credits the reward, replaces the mission and saves in one step, so a reload can never pay a mission twice.
- The board is re-rolled at Prestige (unclaimed rewards are lost, and the Prestige confirmation says so) and cleared by Hard Reset.

---

## 35. Onboarding modes

A truly fresh profile opens an onboarding choice before anything in the run advances (the chooser is a modal and pauses). **As of v0.12 the choice sets presentation only**: every mode starts the same kingdom (Castle, House, the baseline Barracks, one Villager on Build) and goes through the same first-run progression (§27.5); no mode reshapes the simulation.

1. **Guided**: learn by doing, step by step through the progression's goals. A pointing hand, a red frame around the target and a short caption, recomputed from the real state, point at named controls and world objects: a Villager, then a Sheep (a direct order, §7.4d), Recruit, a Tree, a Gold Deposit, Build, each economy building's card on the Build Shelf, Place and the arrows, Exit Build Mode, the construction for a Villager to build, the Train card. (A selected Villager opens no card as of v0.15: the next step points straight at the world.) Steps complete on the resulting state, never on a click; as of v0.16 on the **learned result**: Food 14 delivered (not a Villager sent to a Sheep), three Villagers walked out (not queued), Wood 42 and Gold 14 delivered, each economy building complete (not placed, not merely worked), the first defender trained (not queued). While that work runs the caption shows its progress and a soft gold outline what to watch, with no hand. The economy's buildings come one at a time, each with a suggested spot by its resource (§27.5). The pointer never blocks input and hides under any modal. Later systems (stances, through a selected soldier's Details as of v0.15, selecting several soldiers and sending them, as of v0.14, run upgrades, missions, the Bestiary, Squad Command, Towers, the armed Castle) are pointed out the first time they become relevant, never all at once.
2. **Basic** (as of v0.17): choosing it closes the chooser and opens the **How to play cards** at once: the same deck Settings > How to play opens (one source: the same cards, order, art, type, modal and Next / Start; the first-time deck offers Skip where Settings offers Close). Like any modal it waits while it is open; Start or Skip returns to normal play. There is no opening Settlement note (the cards and the objective card already say it). Then a **short note** (the same caption and pointer, a few seconds, never pausing) when a later stage opens: the Train card at Defense Preparation, the wave timer when the first invasion's countdown starts; then the coach hints below and one-time contextual hints for later systems (as of v0.14 one of them says how to select several soldiers, once three are in play). Basic never becomes Guided: no ordered lessons. The How to play cards (seven as of v0.18: the sixth, Conquer, on planning and launching the assault on the rival kingdom; the seventh, Rebuild stronger, on Glory Upgrades) stay in Settings for a later reread. Chooser text: "Read the core controls up front. Tips appear if you get stuck."
3. **No Tutorial** (stored as "skip"): no tutorial cards, pointer, captions, forced steps or instructional modals or toasts. It is **not** "show the whole game at once": the first-run progression still applies, because it is the game's first-profile pacing (§27.5), and its completion message (the next loop, not an instruction) shows here too.

All three modes share the v0.16 delivered targets and every other first-run gate; Guided only decides the order and presentation of teaching (its progress captions and its placement suggestion), never easier or different simulation rules.

**Coach hints (Basic).** Players stop reading cards early. Basic therefore gets a few lightweight hints in its first runs, using the Guided pointer and caption but no lesson order, each shown only while its situation is happening: enemies are near and no soldier is in play or in training (points at the Train card); a construction waits and nobody has the Build task (points at a Villager, then, with it selected, at the construction: a direct order; with its card open, at its Build button); population is full and a House is affordable (points at Build, then the House card on the shelf, then Place, saying what a House gives); one lone Villager for a while and a recruit affordable (points at Villagers, then Recruit). They never pause, never move the camera, show one at a time, rest between showings, stop for good once the player has done the thing (in this run or any earlier one), and stay quiet after a few showings even if ignored. Guided and No Tutorial never show them.

**The pointer is hard to miss (v0.7).** The frame around the target is **red** (a bright red line over a dark edge, with a pulsing red glow), thick enough to read over the map, over paper panels and over red buttons; the pointing hand is **30% larger** than before and still points at the same spot (its fingertip just past the target's corner). The hand stays inside the safe area: beside targets at the right edge it points from the left, beside targets at the bottom (the build bar) it points from above. The pointer remains presentation only: it takes no input, changes nothing and hides under any modal.

The choice and tutorial progress are saved, kept across runs and Prestige, and cleared by Hard Reset (which returns to the chooser). There are no tutorial-only rules: every mode plays the real game, and the gates are the first-run progression's, not the tutorial's.

**Panels and the tutorial (as of the Android corrections).** Guidance shows only with the panel its step belongs to; any other panel suspends it until that panel closes, and steps check the resulting state rather than a click (§27.4).

---

## 36. v0.4 change log

Approved changes from the Full Improvement pass, now reflected above:

- one continuous world with a pan/zoom camera replaces the split screen and the Kingdom / Both / Battle focus modes (§3.1);
- world proportion about 65% kingdom / 35% battlefield, less water, a wide lower Castle entrance (§3.2);
- corner-only resource zones with authored, editor-visible sites and per-run profiles; Tower strip and Castle lane exclusions; roaming sheep that never block construction (§5.1, §5.4, §5.5);
- finite-stock resource nodes with claims, depletion, timed respawn and synchronized work feedback (§6.2);
- continuous build mode with an immediate invalid-area overlay and four-direction arrows (§5.2);
- Tower unlock grants capacity 1; permanent Tower Capacity upgrades raise it (§10.10);
- the baseline Barracks at run start, with the Guided exception (§4.1);
- units trained one at a time per building with queues, in parallel across buildings, walking from the building to the battlefield (§10.7, §12.6, §13.6);
- stances, selection, Multi-Select, squads, formations, the Villager and soldier squad incompatibility, and their progression gates (§12.6, §12.7);
- enemies reach Castle attack positions before direct damage, with one synchronized feedback event per hit; the armed Castle upgrade path (§16.3, §16.4);
- Glory rewards cut to 30% of their v0.3 values (§18.1), later set to 36% after playtesting;
- Prestige as an optional, deferrable, deeper reset with an explicit keep/reset table, a strong confirmation and an atomic commit (§20.8, §20.10 to §20.12);
- more run upgrades with visible effects (§17);
- Bestiary, Missions and the three onboarding modes (§33 to §35);
- larger touch targets, drag-anywhere scrolling and the Tiny Swords selection marker and paper hierarchy (§27).

Playtest feedback round (later in v0.4): a Pause button; Villagers take time to create at a House (§7.3a); a population breakdown per unit type (§3.3); an optional "Prestige now" when a Prestige becomes ready during a run (§20.8); introduction cards redone as compact Bestiary-style cards with stats (§15.4); a Stats page (§27.1c); 100 waves with a larger roster, a schedule of Elites and Bosses, first-defeat bonuses and a smoother difficulty curve (§15.3), with a Brute that is no longer a wall; Glory rewards at 36% of v0.3 (§18.1).

Superseded v0.3 statements: randomized node positions anywhere in the kingdom (§5.4), immediate deployment (§13.6), "Prestige does not erase permanent upgrades" (§20.8, §28.3), split-screen focus modes (§3.1, §3.2).

---

## 37. v0.5 change log

Approved changes of the UX, Onboarding, Prestige, Sheep, Build UI and Defense pass, now reflected above:

- Prestige starts only after the first real defeat, which is the first Prestige milestone (§20.8, §20.10, §28.5);
- a text and UI-density pass: less text, larger key values, primary value first, explicit costs and consequences kept (§27.1);
- five shorter Basic cards in larger type, and coach hints for Basic and Skip (§35);
- the first-wave warning in every run, with the spawn band marked (§3.4, §15.4);
- context panels sized to their content (§3.3);
- two-column Build cards led by an authoritative benefit, with aligned buttons (§27.1d);
- the Villagers working each resource shown on the HUD resource chips (§3.3);
- sheep in two authored herds grazing their own areas (§5.5);
- Defend Castle engagement with acquisition < engagement leash < abandon distance (§12.6);
- (user request during the pass) no offline reward before the onboarding choice and first play (§22.2).

Superseded v0.4 statements: sheep roaming anywhere in the kingdom (§5.5), "Skip: no hints" (§35), a Prestige offer possible during the very first run (§20.8), side panels always as tall as the screen (§3.3), three Build cards per row (Playbook §15 default, now §27.1d).

---

## 38. v0.6 change log

Approved changes of the Interaction Corrections pass (`docs/Claude_GrowingKingdom_Interaction_Corrections_Pass.md`), now reflected above:

- the resource chips count the Villagers **assigned** to each resource (workforce allocation), not those producing it this instant (§3.3);
- the player's Pause is a gameplay lock enforced by the game's action layer, with one reason, "Unavailable while paused"; reading stays open (§3.5a);
- the Villagers panel is one stable screen: population, Recruit and the default task pinned at the top, the Villager list scrolling below, recruiting adds a row in place (§7.4a, §27.1e);
- panels appear at their final size, never an oversized first layout that shrinks (§3.3, §27.1e);
- Villager tasks are chosen from a dropdown (tap, see every task, tap one), for each Villager and for the default task with Apply to all (§7.4a);
- a reassignment takes effect at once; a carried load the new task does not deliver is dropped as a recoverable pickup with its exact amount, saved with the run (§7.4b, §6.3, §22.3);
- a struck sheep flashes red briefly as well as hopping (§27.2).

User requests during the pass:

- **Defend: the Castle comes first.** An enemy striking the walls pulls every Defend unit off what it is doing, at once; the guard shares the attackers out and holds Castle duty as an engagement (§12.6);
- **Train cards and slots in one list.** Each Train card has Assign (asking which slot when there are several; off and naming its slot once assigned); an empty Train card on the rail opens that list (§13.4).

Superseded v0.5 statements: the chips counting "the Villagers actually running that gather task, never their configured priority" (§3.3); a Defend unit committed elsewhere ignoring an attack on the walls unless it was chasing outside the guarded area (§12.6); a Castle "Active slots" list whose "Change" button cycled through the cards (Castle panel, §13.4).

---

## 39. v0.7 change log

Approved changes of the v0.7 implementation brief (`docs/Growing_Kingdom_Claude_Implementation_Brief_v0.7.md`), now reflected above:

- the danger zone (the marked enemy spawn band) lasts three waves, the triggering wave counting as the first; a later trigger extends it, never shortens it; saved with the run (§3.4, §22.3);
- the tutorial pointer's frame is red and stronger, and its hand 30% larger, pointing at the same spot and staying in the safe area (§35);
- the first Train card (Slot 1) trains 1 Warrior (§13.3);
- until the first building is unlocked through Prestige, every Prestige offer holds one random eligible building unlock; skipping it keeps the guarantee, choosing one ends it (§20.2);
- the starting House and baseline Barracks stand on two different random start plots, chosen when the run is created and saved with it (§4.1, §5.1, §22.3);
- picking a task that is already in a Villager's priority list swaps the two places instead of being refused, on every surface that edits a list (§7.4a).

User requests during the pass:

- **Staying never strands the player.** After "Stay in this kingdom", a bar at the top of the map reopens the completion message until the player ends the run and Ascends (§4.5).
- **The default for new Villagers is saved when chosen,** and recruits follow it (§7.4a).
- **Tower reach covers the Castle front** from every slot and the top 40% of the battlefield (§10.10).
- **A Train card's unit is chosen from a dropdown with portraits,** not by cycling (§13.2).

Superseded v0.6 statements: the default selector editing a draft that only Apply to all saved (§7.4a); a Tower's reach as a circle of its range (§10.10); the danger zone going away briefly into wave 1 with the warning ribbon (§3.4); the House and baseline Barracks at fixed authored start positions (§4.1, §5.1); the Villager card's one-tap task choice and Multi-Select commands putting the task first and shifting the others down, the implemented meaning of "sets its first priority" (§7.4a; they now swap like the dropdowns); the Guided pointer's yellow frame (§35).

---

## 40. v0.8 change log

Approved changes of the correction and progression brief (`docs/Claude_GrowingKingdom_Progression_Correction_Pass_v0.8.md`), now reflected above:

- a Train card's Command (the stance of the units it trains) is a direct dropdown: every stance at once with its icon and short name, the current one marked, one tap applies and closes, outside or Back closes with nothing changed; the command buff is chosen the same way (§13.2);
- one icon per combat stance, used on every screen that shows or sets a stance (§12.6);
- a block reason sits on its cost's row, so cards keep their height and buttons their place (§27.1d, §27.1f);
- building tiers are Prestige progression: Tier 1 on a fresh profile, Advanced Construction opens Tier 2 and Master Construction (after it) Tier 3, for every upgradeable building; saves from before keep what their run built (§11.4, §17, §20.5);
- a higher starting Castle tier moved from the permanent upgrades (Castle Foundations, refunded) to Ascension: the Ancient Foundations Decree, offered once Tier 2 is unlocked; Ascension never lifts a building above the unlocked tier (§4.1, §18.2, §20.9).

Superseded v0.7 statements: "improved starting Castle tier" as a permanent upgrade (§4.1, §18.2); a Train card's stance set by a row of toggle buttons and its command buff by a button that cycled (§13.2, as implemented); a block reason on a line of its own under a card's text (§27.1d, as implemented); Veteran Legions reaching Tier 3 from any Tier 2 building (§20.9, as implemented).

---

## 41. v0.9 change log

Approved changes of the armour specialisation brief (`docs/Claude_GrowingKingdom_Armor_Matchup_Pass_v0.9.md`), now reflected above:

- armour is a matchup by attack type: melee blows meet all of an enemy's armour, arrows and Tower and Castle shots half, magic none; no unit value changed (§12.8; §10.10, §12.1 to §12.5, §16.4);
- the first armoured enemy a profile meets teaches armour on its introduction card, once, without pausing (§15.4);
- an armoured enemy's Bestiary entry, and its introduction, show an Armor strip: Melee Full, Arrows Half, Towers Half, Castle Half, Magic Ignores (§33).

Superseded v0.8 statements: armour as a cut of every attack alike ("takes 35% less damage", §15.3 and the enemy descriptions); the single armour tile among an introduction's and an entry's stats (§15.4, §33).

The measured effect on army compositions is in IMPLEMENTATION_DECISIONS.md B9.

---

## 42. v0.10 change log

Approved changes of the shields, stats, progression, Monastery and stance brief (`docs/Claude_GrowingKingdom_Shields_Stats_Progression_Stances_Pass.md`) and its Renown follow-up (`docs/Claude_GrowingKingdom_Renown_Table_Followup.md`), now reflected above:

- shields are a second durability pool that lasts until damage breaks it, absorbs damage before HP, never regenerates by itself and is saved; a blue bar shows what is left (§12.9; §12.4, §16.2);
- the Stats page opens on Current Boosts, grouped by effect with each total's sources, and shows Real and Game Time Played (§27.1c);
- Recovery Doctrine and Expanded Command moved from Prestige to the permanent upgrades; older profiles keep their ranks as levels (§13.4, §18.2, §19.2, §20.5, §20.7, §20.10);
- the Salvage cards explain Salvage on the card (§18.2);
- up to two Monasteries, each with a permanent Mage or Healer specialty and its own research job; levels shared; specialty topics at their specialty (§10.9, §17.4);
- stance tags in a unit card's top-left corner (§12.6);
- Defend protects the Castle area with a threat area, an answer reach and a hard leash, and counts sustaining support enemies; Pursue commits to its target with no leash; Intercept unchanged (§12.6);
- Prestige requirements from an authored table of 33; the Renowned Dynasty Decree (+30% Renown earned) (§20.8, §20.9).

Superseded v0.9 statements: timed shields ("a temporary shield", §12.4, §16.2); one Monastery that trains Mages and Healers and runs one research (§10.9); Expanded Command and Recovery Doctrine in the Prestige pools (§20.5, §20.7); the Renown threshold 150 × 1.6^k (as implemented); a Defend guard area of 470 px around the gate with engagement and abandon leashes out to 1,170 px, which let a defender be drawn across most of the battlefield, and Pursue re-choosing the nearest enemy every moment (§12.6, as implemented); the stance badge on the portrait's corner (§12.6).

The measured effect on combat is in IMPLEMENTATION_DECISIONS.md B10.

---

## 43. Documentation audit (2026-10-01): editorial corrections, no design change

A documentation audit brought wording that had fallen behind the approved v0.10 rules (and the implementation of them) into line. No rule, number or behaviour changed:

- §4.5 and §20.9 name the Super Prestige as the game calls it, **Ascension**, and point to its recorded rules (IMPLEMENTATION_DECISIONS.md S1 to S3); §28.4 likewise.
- §10.1: the Shield command modifier "lasts until broken" (it said "temporary", superseded by §12.9).
- §12.6 and §31: Defend's commitment is described with v0.10's terms (threat area < answer reach < hard leash); the v0.5 names "engagement leash" and "abandon distance" no longer exist in the game.
- §18.1: the permanent currency is named Glory (it said "final name TBD").
- §20.5 and §20.7: the pool sizes no longer say "approximately five".
- §29.2: research levels belong to the run, the job to its Monastery (§10.9).
- §31: Glory is at 36% of v0.3 (§18.1), not 30%.
- §20.5 and §31: the Lancer unlock path is recorded as resolved (Lancer Training, trained at the Barracks), as already stated in §10.7 and implemented; §31 had kept it as open question 3.
- §32: the summary names building tiers as Prestige progression, slots and Salvage as permanent, and Ascension.
- §28.6 (new): the pre-release save-compatibility rule the developer set for every game (Playbook §61).

Earlier GDD files (v0.3 to v0.9) are history; their status lines now say so.

---

## 44. v0.11 change log

Approved changes of the Smart Workforce, Defend, Tower, Prestige HUD and Royal Tribute brief (`docs/Claude_GrowingKingdom_v0.11_Smart_Workforce_Defend_Towers_Prestige_Pass.md`), now reflected above:

- Tower base damage 30 / 50 / 80, nothing else about Towers changed (§10.10);
- Defend covers before it dogpiles: each Castle threat gets the responders its tier needs (1 / 2 / 3), the nearest free defender first, an uncovered Castle threat outranking a local fight; the rest of the guard keeps to other threats (§12.6);
- Synchronized Deployment is offered by its Prestige prerequisites alone; it is dormant ("Requires 2 Deployment Slots") with one active slot and works again as soon as a second is active (§14.3, §20.4, §27.1c);
- Expanded Command priced 200 / 350 / 600 Glory, authored per level (§13.4, §18.2);
- Recovery Doctrine: 3 levels of +20% Salvage at 600 / 850 / 1,200 Glory; Salvage cards show the whole Salvage now and next (§18.2);
- Smart Workforce replaces Advanced Villager Priorities: a one-rank Prestige unlocking Manual or Smart per Villager; Smart builds first (finishing its project), otherwise commits to the most-needed resource for 2 minutes of game time; Villager Task Slots is the only source of manual places (§7.3, §7.5, §7.6, §20.6; the per-Villager Build-first rule replaced by coordinated allocation in §47);
- a Prestige progress bar beside the Castle HP, with locked, progress, ready and complete states at a fixed size (§3.3, §20.8);
- Royal Tribute, the 33rd Prestige rank: 2 Glory per game minute of an active run, credited like active-play Glory (§20.7, §22.2, §27.1c).

Superseded v0.10 statements: every Defend unit answering an attack on the walls, spread by a per-defender penalty and switching to a clearly nearer wall attacker (§12.6); Expanded Command priced 200, 400, 800 (§13.4); Recovery Doctrine +10% per level for 5 levels (§18.2); synchronized automation kept out of offers until several slots exist (§20.4); Advanced Villager Priorities in the Automation / QoL pool and Prestige as a source of task slots (§7.3, §20.6); Tower damage 12 / 20 / 32 (as implemented).

The measured effect is in IMPLEMENTATION_DECISIONS.md section 10 (B11) and IMPLEMENTATION_REPORT.md.

## 45. v0.11 Android playtest corrections

Approved corrections from Android testing (`docs/Claude_GrowingKingdom_Android_Playtest_Corrections.md`), recorded in this v0.11 document as the brief asks, now reflected above:

- Healer: 10 HP every 6 s at Tier 1 (13.5 / 18 at Tiers 2 / 3); **Recently Healed** for 10 s of game time after a direct heal, which no other direct Healer heal may target; Troop Attack Speed no longer shortens the support cadence; Sanctuary every 4th successful direct heal, waiting never counting (§12.4, §18.2);
- tutorial and panel arbitration: guidance only with the panel its step belongs to, suspended (still pending) under any other, re-evaluated from the state on every panel change, live target rectangles, state-driven steps (§27.4, §35);
- the Prestige block: its own HUD element between Glory and the Wave / Castle HP chip (restored as before v0.11), larger, PRESTIGE over the bar and the "X / 33" ranks owned, a ⓘ that pulses until first used (§3.3, §20.8);
- the read-only Owned Prestiges panel, or "No Prestiges so far." with none owned (§20.8);
- Smart Workforce: a New Villager Manual / Smart choice before recruiting, and an All Villagers Manual / Smart bulk control (§7.6; the bulk card superseded by §46).

Superseded statements: the Healer's 16 HP every 2 s, quickened by Troop Attack Speed (as implemented); a Prestige progress bar inside the Wave / Castle HP area of the top bar (§3.3, v0.11 as first written); "a new Villager is Manual; there is no global Smart default" (§7.6, v0.11 as first written); tutorial guidance that stayed on screen over unrelated panels (§35, as implemented).

## 46. v0.11 Villager UI and Healer follow-up corrections

Approved follow-up corrections from Android testing (`docs/Claude_GrowingKingdom_Villager_UI_Healer_Followup.md`), recorded in this v0.11 document, now reflected above:

- one **New Villager** card is the single Villager configuration surface: Manual / Smart in its header (with Smart Workforce), the unlocked priority places side by side at one shared width, and a compact **Apply to all** on the right of the same line (§7.4a, §7.6);
- Apply to all gives what the card shows to every Villager: Smart makes everyone Smart (each keeps its hidden Manual list); Manual makes everyone Manual with the visible list. Changing the card alone changes nobody (§7.6);
- a queued recruit keeps the mode and Manual list it was recruited with, across later card changes and a save (§7.6);
- **Recently Healed** lasts **5 s** of game time instead of 10; every other Healer value and rule is unchanged (§12.4);
- a small no-heal mark above an ally shows Recently Healed while it runs (§12.4).

Superseded statements: the separate All Villagers [Manual] [Smart] card with its own bulk places and its mixed-mode line (§7.6, §45); Recently Healed for 10 s of game time (§12.4, §45); the default places in a wrapping row of numbered dropdowns (§7.4a, as implemented).

## 47. v0.11 Villager fallthrough and Smart coordination corrections

Approved corrections (`docs/Claude_GrowingKingdom_Villager_Fallthrough_Smart_Allocation.md`), recorded in this v0.11 document, now reflected above:

- a Manual Villager whose carried load its storage cannot take puts it down as an ordinary dropped load and goes on to its next executable task, Build included; with nothing else executable it keeps the load and waits (§7.2, §7.4, §7.4c);
- Smart Villagers are one coordinated workforce: each takes the greatest unmet need after counting the Villagers (Manual and Smart) already on each task and the loads already on their way, so they no longer all take the same task; construction calls workers in proportion to need rather than all of them (§7.6);
- the Smart Workforce Prestige text says so: "Smart Villagers share out the work, building and gathering what your kingdom needs most." (§20.6).

Superseded statements: "Is there something to build? Yes → Build, otherwise gather the resource the kingdom needs most" as every Smart Villager's own rule, with need read as the lowest stored amount (§7.6, §44); a Smart Villager with a blocked load and nothing to build dropping it even when nothing else could run (§7.6); a Manual Villager holding a blocked load while a later gather task could run (§7.4b as implemented).

## 48. v0.12 first-run progression and direct Villager orders

Approved brief (`docs/Claude_GrowingKingdom_FirstRun_Progression_Direct_Villager_Orders.md`, with the clarification that the progression is first-profile-only), now reflected above:

- a universal **first-run progression**, independent of the tutorial mode: Settlement (no enemies; Wood, Gold and Food delivered, 3 Villagers, Lumber Camp, Mining Camp, Farmstead and Storage completed, in any order), Defense Preparation (the first defender trained), then the first invasion after a 60 s countdown; one compact objective card; progressive disclosure of the HUD and panels from one reveal table (§3.3, §27.5);
- completion is marked when normal enemy progression begins and is **permanent for the profile**: death, new runs and Prestige never replay it; only Hard Reset restores it (§20.10, §22.3, §27.5, §28);
- the same starting kingdom in every tutorial mode, its first Villager on Build; Guided no longer removes the baseline Barracks or holds wave 1 itself (§4.1, §35);
- tutorial modes control presentation only: Guided walks the progression's goals; Basic shows a short note per stage instead of five cards up front; No Tutorial shows no instructional help at all (§35);
- **direct world orders**: with a Villager selected, tap ground to Move and hold, a resource node to gather that node, a construction to build it, a completed drop-off to deliver the load; a temporary override above Smart and Manual, with Resume Work, green target corners, a "Direct: ..." line on the card, Smart coverage by what it works, the Pause lock, and intent-only saving (§3.3, §7.4a, §7.4d, §7.6, §12.7, §22.3);
- Android Back / Escape close build mode, Multi-Select, the selection and an open panel before leaving the game (§7.4d);
- build mode's **Exit Build Mode** replaces "Done" (§5.2).

Superseded statements: "No Tutorial (Skip): normal play at once" and the whole game shown from the first run (§35); Basic's five cards before play (§35); Guided's pristine-run reshaping (no baseline Barracks, wave 1 held for the first Barracks) and the "Guided exception" to the baseline Barracks (§4.1, §35); coach hints in Skip (§35); a direct command represented as a new priority 1 (§7.4a); a tap on empty ground always deselecting (§12.7, with a Villager selected); "Done" in build mode (§5.2).

## 49. v0.13 pre-enemy-kingdom readiness

Approved brief (`docs/Claude_GrowingKingdom_Pre_Enemy_Kingdom_Readiness_Pass.md`), now reflected above:

- a fourth stance, **Standby**: a reserve on the kingdom side of the Castle (the authored troop lane to its back door), out of ordinary wave fights, visible, selectable, squads kept; trained Standby soldiers walk there from their building, field soldiers switched to it walk back through the gate and the Castle, never placed (§12.6, §12.6a, §13.2);
- Standby's **Castle emergency**: at 30% Castle HP or less during an active wave every Standby soldier fights as Defend Castle, through the ordinary Defend rules, until that wave is cleared, then returns to the reserve; its saved stance stays Standby throughout; one transition per wave, no flip-flop; a later wave below 30% starts it again (§12.6a, §22.3);
- Standby's icon, a shield held behind a shield with the arrow turned back, on every stance surface (§12.6);
- a direct **work order** (gather a node, build a project) also puts its task first in a Manual Villager's priorities by **move to front**, distinct from the place-editing **swap** rule that every task command keeps; Moves and deliveries never touch the list; Smart Villagers' hidden lists are never edited (§7.4a, §7.4d, §7.4e);
- in Multi-Select, a tap on a resource node or a construction orders every selected Villager onto it (each one's list transformed once), soldiers in the selection left alone (§7.4d, §12.7).

Superseded statements: "an order never changes the Manual priorities" for gather and build orders (§7.4d, §48); "world orders are given to one selected Villager at a time" for work orders (§7.4d); three stances (§12.6, §13.2).

Deferred, not current design: the rival kingdom, its recruitment and assault, the end of waves once it falls, and the Prestige requirement that replaces Renown are direction for the next pass, recorded only in the brief's §5; nothing of them is implemented or specified here.

## 50. v0.14 RTS selection and direct army command

Approved brief (`docs/Claude_GrowingKingdom_RTS_Selection_Army_Command_Pass.md`), now reflected above:

- **selection is a core control, saved squads are the progression:** selecting several units (box, double tap on a type, Shift, the add mode) and every world command need no unlock; Squad Command now gives saved squads and crews and their number (§12.7, §18.2);
- a desktop box (left drag) and a touch box (long press, then drag), with the camera's existing pan, tap and pinch rules unchanged; double tap (double click) selects the friendlies of one type in view (§27.6);
- temporary selections may mix Villagers and soldiers; Save group keeps the mix rule and refuses with its reason (§12.7);
- one selection contract: the card for one selected thing, the selection bar for several, never both; a saved squad is recalled straight into the selection (§12.7);
- the selection's world commands, member by member: Villagers work, build, deliver and move as in §7.4d (several moved side by side); soldiers **move and hold** in formation or **focus an enemy**, without a leash; **Resume Stance** hands them back; a stance change ends an order; Manual is a current command, never a stance (§7.4d, §12.6, §12.10);
- Standby and direct orders: an order takes a Standby soldier out of the reserve by walking; the Castle emergency cancels such orders and refuses new ones until the wave is over (§12.6a);
- soldier orders saved as intent, validated on load (§12.10, §22.3).

Superseded statements: "Multi-Select and saved squads come from Squad Command" (§12.7, §18.2); "Multi-Select (touch first, no marquee required)" (§12.7); "Villagers and soldiers cannot be in one Multi-Select selection" (taps refused the mix before v0.14; only a saved squad refuses it now); "Ground taps and Moves stay one Villager at a time" (§7.4d); the Playbook's "long press is free for a future action" for this game (§27.6).

Not in this version: the rival kingdom, its map, buildings, production, invasions and the Prestige redesign remain direction for a later pass; the commandable area is today's battlefield.

## 51. v0.15 RTS UI polish and Build Shelf

Approved brief (`docs/Claude_GrowingKingdom_RTS_UI_Polish_Build_Shelf_Pass.md`, which supersedes the separate selection HUD / gesture feedback brief), now reflected above. The rule: frequent world actions stay close to the world; detailed management is opt-in.

- **friendly selection is command mode:** selecting a Villager or a soldier opens no panel; a compact Selection Status in the lower left shows it; the card (one) or the selection bar (several, the add mode) opens only from its Details; closing or collapsing keeps the selection; Back collapses first, then clears (§3.3, §12.7);
- buildings and resource nodes are inspected as before (their card opens on selection);
- **the long-press hint** "Drag to select multiple units", by the finger, in every tutorial mode, driven by the camera's own hold state (§27.6);
- **the Build Shelf** replaces the Build panel: tap a card for the existing build mode, or drag it up into the world and release to place through the same Place action; sideways drags scroll; existing buildings are never moved (§5.2, §27.1d);
- the build-mode bar is one low row above the shelf; the shelf, panels and an expanded selection never stack (§27.1d);
- tutorial pointers follow: shelf cards, a selected Villager's next tap in the world, a selected soldier's Details (§27.4, §35).

Superseded statements: "tapping a world object opens a context panel" for Villagers and soldiers (§3.3); "its context card shows its state..." on a friendly tap and "a selection of several shows the selection bar" by default (§12.7); "Build shows two cards per row" and the benefit-led Build cards (§27.1d); "Build for a building's card" as a panel step (§27.4); "points at a Villager, then its Build button" (§35).

Not in this version: the rival kingdom, enemy buildings and production, invasions, the Renown / Prestige redesign and any balance change. Nothing in the simulation, its costs, placement rules or saves changed.

## 52. v0.16 Guided onboarding pacing and UI readability

Approved brief (`docs/Claude_GrowingKingdom_Guided_Onboarding_Pacing_UI_Readability_Followup.md`), from device playtesting, now reflected above. The rule: a guided lesson completes on the learned result, not when the work starts; while the work runs, it shows progress instead of the next concept.

- **delivered-resource targets** for Settlement (Food 14, Wood 42, Gold 14, one table, deliveries only), shown on the objective card as progress ("7 / 14"), the same in every tutorial mode (§27.5);
- **Guided lessons complete on their first-run goal:** Food and the other resources on their targets, Recruit on three Villagers walked out, the economy on each building complete, Train on the defender trained; progress captions and a soft "watch this" outline while the work runs, no timers (§27.4, §35);
- **the economy's buildings one at a time** (Lumber Camp, Mining Camp, Farmstead, Storage), each completed before the next; one built early is skipped (§27.5);
- **a suggested placement** by each building's resource (the Storage by the Castle), from the state's own rule, a suggestion the player may leave (§27.5);
- **readability:** larger Build Shelf cards and type (§27.1d); a larger objective card (title 36 px, rows 28 px) on a 330 px rail (§27.5); a larger compact Selection Status in the order ^ Expand, picture, text, Details, then Cancel with a dead gap before it, and the same gap between Collapse and Clear on the expanded bar (§12.7).

Superseded statements: "Wood, Gold and Food each delivered at least once" (§27.5); "A resource counts once a delivery of it has reached storage" (§27.5); "a Villager already on a resource completes the gathering lesson" (§27.4); the objective card's "Wood -" (§27.5); "Its body is Details; a ✕ beside it clears" (§12.7); the 256 px shelf cards with 26 px names (§27.1d, decision UP-6); the compact status "about 565 × 84 px" (decision UP-2).

Not in this version: the rival kingdom, conquest and the Prestige redesign. No cost, placement rule, balance value or save field changed; the Settlement stage takes longer for a first profile by design.

## 53. v0.17 Onboarding completion and Basic cards

Approved brief (`docs/Claude_GrowingKingdom_Onboarding_Completion_Basic_Cards_Followup.md`), a small correction pass, now reflected above.

- **Basic opens the How to play cards** right after the choice: the one deck Settings opens, never a copy (§35); the chooser says "Read the core controls up front. Tips appear if you get stuck.";
- **no opening Settlement note** in Basic ("No enemies yet: build up your settlement..."), not replaced by another; the Defense and countdown notes stay (§35);
- **a transition message when the first-run progression completes**, in every tutorial mode, for about 10 s, non-blocking, once per profile: keep developing, defend against enemy attacks, prepare to attack the rival kingdom (§27.5).

Superseded statements: "Basic: no cards up front" and its Settlement-goals note (§35); "Since v0.12 Basic no longer opens them up front" (the How to play cards).

Not in this version: the rival kingdom, its territory, assault groups, the Attack button, enemy production and the Prestige / Renown redesign; the message only names the goal the next pass builds. No cost, gate, balance value or save field changed (the message is remembered in the existing one-time hints).

## 54. Rival kingdoms and conquest (v0.18)

Approved brief: `docs/Claude_GrowingKingdom_Rival_Kingdom_Conquest_Prestige_Rework.md`. This section is the design; §55 lists what it changed elsewhere.

### 54.1 The loop and the world

```text
develop the kingdom -> survive its waves -> prepare an army
-> plan the assault (any time) -> clear the current wave -> Launch Attack
-> the army sails from our beach and lands on the rival's -> command the assault
-> the rival Castle falls -> the rival kingdom falls, the waves stop for good
-> Prestige ready: take it now or stay in peace -> Prestige creates the next, stronger rival
```

**One world, two islands.** The rival kingdom is an island south of ours across a band of water, and it is **our own world section turned around** (v0.19): a 180° turn of our map, the same width and height, so its beach is on top (facing our shore), then its battlefield, its defensive row with its Castle (our Castle's footprint, entrance and attack positions, turned around) and its kingdom plateau behind (below) the Castle, every proportion ours. The plateau is open in front of the Castle: the battlefield's ground runs flat up to its front (Tiny Swords has no stairs or cliff face facing the other way, so our ramp is not turned around; §57.2). Nothing of it is authored twice: every rival point and rectangle comes from our geometry through one transform, so the two can never drift.

**Its settlement** is our kingdom laid out by our own rules, then turned around: our resource corners (forests, quarries) and herds, each corner's profile drawn from the rival's own seed (so rivals differ from one another, as our runs do); its House and first military building on two of our start plots, its other military buildings and its town where our placement rule allows them (camps by their resources); its Towers on our Tower slots, in their order. Tiny Swords has no back-facing buildings, so its buildings stand upright, mirrored left to right (never flipped vertically). **It looks alive:** a few Villagers (more as the town grows) walk loops between its resources and the buildings that take their loads, gathering, carrying and delivering as ours do. They are scenery: no resource, no affordability, no reward, no target, nothing in the way; they vanish with the conquered kingdom. Its battlefield decorations are ours, turned around. Each group walks down to **our beach** (the band the waves come from) and gathers there, in sight, in its formation on its own third of the beach; once every soldier of the group stands at its place, **the whole group goes into the water together** (a generous timeout brings a straggler that cannot get there to its place, so one soldier never strands the rest, §57.1). It comes out of the water on **the rival's beach** a few seconds later (`ASSAULT_CROSSING`, 4 s). The water hides the crossing: **there is no march corridor** and no separate battle scene. The army therefore attacks "backwards", down the screen, into a kingdom that faces it the way ours faces the waves.

**The camera** reaches the rival island only while an assault needs it (under way, or its survivors still over there); then the whole world is one map: pan between the islands, or use the assault bar's **View Rival / View Home**. When Group 1 lands the camera turns to the rival beach; a failed assault turns it home; when the reach closes with the camera over there, it turns home. The rival island is always drawn; it is simply out of reach otherwise.

**Command territory.** Where soldiers may be sent is one authority (`WorldLayout.command_area()`): our battlefield at home, the rival field for soldiers fighting there. Each soldier takes only the orders of its own island.

### 54.2 Rival identity and progression

**One rival per Prestige rank: 33 rivals, and the final rival (v0.23)** (Rival k is conquered for Prestige k; Rival 34 for an Ascension, §20.9). The first exists before any Prestige; only a Prestige advances to the next; a defeat and a new run keep the same rival. The current rival is Rival (Prestige count + 1).

A rival is **not a simulated AI player**: it is an **authored, deterministic template** (`data/rivals.json`, written by `tools/gen_rivals.py`, read through `RivalData`): its Castle (HP, and from Rival 6 an attack), its frontline, its military buildings with their queues, first spawn, cadence and caps, its search parties, its town and Towers (presentation). It has no economy: no Wood, Gold or Food, no Villagers, no affordability.

**Never scaled from the player.** A rival's strength is fixed: it never reads the player's army, resources, population, Glory upgrades, buildings or power. "I failed against this rival; I can develop further and try again" is always true.

**Its units** are the archetypes of the waves (`data/enemies.json`: the rival is the kingdom that sends them), with their own stats, armour and art, met in this order: Thralls and Raiders (Rival 1), Skirmishers (2), Cutthroats (3), Brutes (4), Shieldbearers (6), Shamans (8), Ravagers and Longbowmen (9), Reavers (10), Juggernauts (12); older ones retire as newer ones arrive. **Elites** (Warlord from Rival 14, Marksman 17, Hexer and Dread Knight 29) stand in the frontline as a few **champions** (1 at Rival 14, a second Warlord at 26, 9 at Rival 33), never in a reserve and never scaled with the rival's size: one Elite outclasses a basic army at any number worth fielding (§54.13). Never summoners, Sappers or Bosses.

**Difficulty is development, not HP.** Later rivals bring more defenders, newer and heavier archetypes (their mix leans toward the heavier ones as rivals develop), ranged and support units, Elite champions, more military buildings (1, then 2 from Rival 4, 3 from Rival 10, 4 from Rival 18), larger caps, faster cadences, a stronger Castle, the Castle's attack from Rival 6 (stronger and faster later), and a larger town. Rival 1 is plain: a simple Castle, a small frontline, one Barracks, a small finite reserve, no Castle attack.

### 54.3 Attack availability and the Assault Planner

The **Attack** tool (the dock) opens the **Assault Planner** once the first-run progression is complete (`FirstRun.REVEAL["attack"]`). **Planning is available at any time**, during a wave too. **Only Launch Attack waits** for the current home wave: its reason is **"Defeat the current wave first."**, and the moment the wave is cleared Launch is open with the plan untouched; survivors of a wave carried past its timeout (§15.1, v0.21) hold it too ("Defeat the remaining enemies first."). Launching never skips or erases a home wave. The Attack tool shows a READY badge when Launch would go now, and an alert badge while an assault is under way.

The planner shows: the rival's name and number ("Attack · Rival 3 of 33", "Conquering it earns Prestige 3"); what is known of it; Group 1, and Groups 2 and 3 locked or open by their Prestige; each group's soldiers, formation and deployment (order, delay, signal); Launch Attack with its reason beside it (§27.1f). During an assault it shows the battle instead: the rival Castle's HP, the soldiers and defenders standing, each group's state, Release for a held group, and the way to the battle.

**What is known (Rival Intelligence, as of v0.20).** Without it the planner gives **no military information**: the rival's name and number, that conquering it earns the next Prestige, **"Military strength: Unknown"** with a line saying Rival Intelligence reveals the rival's defenses before you attack, and, after Wave 100, only "Wave 100 survived: this rival has been weakened." No defender count (not even approximate), composition, military building count, Castle HP or attack, reinforcement types, cadence, caps or reserve totals, and no derived army size; the Wave 100 message names no reserve share either. With **Rival Intelligence** (a Prestige Upgrade): the Castle's exact HP and attack, the exact frontline by archetype, each military building's queue, cadence, first spawn and cap, and the cut by Wave 100 ("up to 7 (was 10)"). This is strategic intelligence before launch: once the assault is under way, what the battlefield shows (the rival Castle's HP, the defenders standing) is visible to everyone; the reserve still in the rival's buildings stays a Rival Intelligence line. Debug surfaces may show the template. Nothing the template does not hold is ever shown. Supersedes v0.18's "about how many defend it (rounded to 5), how many military buildings".

### 54.4 Assault groups

**Group 1** is every player's and holds the whole invasion army: **the game is completable with Group 1 alone**. **Group 2** (Second Assault Group) and **Group 3** (Third Assault Group, requires the second) are Prestige capabilities, each with its own soldiers, formation and delay; they give flexibility and are **never needed** for any rival.

Soldiers join a group from the **current selection** ("Add selected (N)"), from a **saved squad** ("+ Squad 1": its living members) or **every soldier at home** ("Add all soldiers"). A squad is only an input: there is no second squad system. A soldier is in **one group at most** (adding it elsewhere moves it). The plan is kept with the run; soldiers who die drop out of it by themselves.

**Launch snapshots** the planned soldiers: each is committed to its group at once, and the plan keeps only its configuration. Soldiers trained later can never join an assault under way.

### 54.5 Launch, no retreat, failure

After Launch the assault is **committed**: there is **no retreat**, no recall, and no stance moves an assault soldier: while committed it acts as "assault" (`CombatSystem.acting_stance`), and its saved home stance waits untouched for its return. A soldier in reserve or on its way marches out first. The player commands landed soldiers with the ordinary RTS controls (§54.8); orders cannot send them back over the water.

**The home kingdom runs on**: Villagers gather, buildings work, construction and training continue, resources accumulate. **No home wave advances while the assault is under way** (the countdown waits).

**Failure.** The assault fails when no damage-capable soldier is left in it anywhere (landed, at sea, held, or still on its way): a lone Healer cannot carry it. Then the soldiers still in it are lost (as an army is in a defeat); **the rival recovers completely**: its Castle, frontline, buildings, queues, caps, timers and anti-stall state are rebuilt whole at the next Launch, nothing carried over (**no chip damage across attempts**); the home kingdom keeps everything it has; the camera turns home and the home waves resume where they stood. A message says it: the assault failed, the rival has recovered, attacks resume, rebuild and try again.

### 54.6 The rival Castle is the objective

**One Castle destruction = one conquest.** No rival building need be destroyed; there are no stages. When the rival Castle reaches 0 HP the conquest is **resolved in state first** (the run is conquered, the waves stop, a Prestige offer is rolled), **saved**, and only then presented: the Castle falls with fire and smoke, **every rival unit falls with it**, its town lies in ruins for the rest of the run, and the survivors walk to the rival beach and sail home (they then take up their saved stances).

**Aftermath.** Enemy waves stop **for good this run** (the wave chip reads "Peace"); the current rival is conquered; Prestige is ready (§20.8). A message says it: the rival has fallen, the attacks have stopped, Prestige is ready, **Prestige now** or **Stay in peace**. The player may stay as long as they like; the conquered state survives save and load. The last rival's message also ends the campaign: every rival has fallen, thanks for playing, and the community link (the old Wave 100 completion message's role).

### 54.7 Organisation, formations and deployment timing

**Baseline organisation, no Prestige:** an assault group lands in **Ranks**: tanks (Lancers) in front, then the other melee, then ranged and casters, then support. Line is also everyone's; **Formation Drill** (one rank since v0.20) adds Block, Spread and Wedge; the same formations serve saved squads. A formation shapes how the group lands and advances; it never replaces the player's direct control.

**Timing.** Group 1 lands first. A later group follows its **delay** after Group 1's landing (0 to 60 s, steps of 5). **Battle Signals** (Prestige, requires Second Assault Group) lets a later group wait at sea for the player's **Release** instead of its delay (the assault bar and the planner offer it). A held group is never stranded: with nobody of the assault left fighting, it lands by itself. Battle Signals is never needed to win.

### 54.8 The battle

Each landed group forms up on the beach (a few seconds): its formation sets the landing order and each soldier's starting place. Then **Assault Advance** (v0.19): every soldier not under a direct order **marches on the rival Castle by itself**. A fighter takes on any rival unit within reach of its aggro on the way (as Pursue does), and when that fight is over marches on; near the Castle front (or once no rival unit stands) it keeps to the Castle and turns only to a rival unit close at hand. Nothing ties the group to a line: the assault never halts because part of it fights, lags or has fallen, so no healthy soldier stands idle. A Healer heals the most wounded soldier near it and otherwise keeps up with the nearest fighter, a little behind it.

**Striking the rival Castle** obeys the same rule as the waves at our Castle (change 7.3), turned around: a melee soldier must stand on one of **our Castle attack positions, turned around**, before its blow lands; with every position taken, the others wait behind them; a ranged soldier or caster strikes once its real range reaches the **wall line** (never measured to the Castle's footprint, its sides or its back). Every blow, arrow, spell and special is the ordinary combat code; armour, shields and Recently Healed apply as at home.

**Commands** are the existing RTS controls: select (tap, box, double tap), tap ground to move (in formation, on the rival field), tap a rival unit or **the rival Castle** to attack it; a direct order overrides Assault Advance, and Resume Stance hands the soldier back to Assault Advance (never to its home stance, which waits for its return). The selection status names an assault soldier's state ("Assault Group 1 · Attacking", "At sea").

### 54.9 Rival defenders and reinforcements

**The frontline** stands from the Launch in lines before the Castle: melee nearest the beach, ranged behind them, support behind the ranged. Each unit **guards its post**: it takes on an assault soldier near its post, one striking its Castle, or one attacking it, never past a leash from its post, then walks back. Support units heal and ward their own.

**The frontline** holds our own formation lines turned around (melee nearest the beach, then ranged, then support), centred on the Castle entrance.

**Reinforcements.** Each military building (Barracks for melee, Archery Range for ranged; v0.22: their support units come out of a Monastery, below; in its town behind the Castle as ours stand behind ours) sends the next unit of its **authored queue** (cycled) from its **first** time after Group 1's landing, then every **cadence** seconds, up to its **cap** per assault: finite, never an infinite stream. Each unit **walks out of the door of the building whose queue made it**, through the town to the Castle's back, through the Castle and out of its gate, as ours do (§57.3), and takes a post in its line; until it is through the gate it is not on the field (no target). Multiple buildings work independently, each from its own door. No resource is spent. The buildings are not targets; production ends with the Castle.

**Shamans come out of a Monastery (v0.22).** Barracks send melee, the Archery Range ranged units, a **Monastery** support units. A rival's queues are authored and unchanged: a Shaman stays a turn of its Archery Range's queue, on that building's one clock (its order, first time, cadence and cap, the Wave 100 cut), but it **walks out of the Monastery's door** (then through the town, the Castle and its gate like every reinforcement), never out of the Archery Range and never from the Castle. Every rival that sends Shamans has a visible Monastery in its town: Rivals 8 and 9, whose authored towns had none, get one, placed by the same settlement rules (fourth in the town's order, as later rivals have it). With several Monasteries the one nearest the Castle's back door is the origin, always the same. The way is derived from the unit's kind and its building, so a reload resumes a Shaman's walk without a saved field. No Mage joins a rival army; no queue, cap, cadence, frontline or reserve changes.

**The rival Castle** from Rival 6 on shoots the nearest assault soldier in range, its range measured as our Castle's is (from its front), harder and faster on later rivals.

### 54.9a Rival Towers (v0.22)

The rival's Towers (Rival 8 on: 1, then 2 from Rival 14, 3 from 20, 4 from 26; standing on our Tower slots turned around, §54.1) **fire**. During an assault each Tower shoots the nearest **landed** assault soldier within its range of the Tower's base, from the Tower itself (a visible hostile arrow), on its **own** cooldown, through the ordinary damage pipeline as a **Tower** hit (armour 50%, shield first, §12.8, §12.9). Never at sea, on our beach, after the battle or at a rival unit; Towers are not targets and there is no Tower order. Each Tower's cooldown is saved with the battle; its first shot comes 1.5 s after the Launch (each further Tower 0.4 s later), so a reload or a new assault never bursts. Its stats grow modestly by rival stage, well under the rival Castle's own shot:

| Rivals | Damage | Every | Range |
|---|---|---|---|
| 8 to 13 | 12 | 2.0 s | 320 |
| 14 to 19 | 16 | 1.9 s | 340 |
| 20 to 25 | 22 | 1.8 s | 360 |
| 26 to 33 | 30 | 1.7 s | 380 |

No rival was rebalanced for them (queues, caps, Castle HP and attack unchanged); difficulty is the developer's manual playtest.

### 54.10 Anti-stall and anti-farming

**Anti-stall.** An assault cannot be kept alive by hiding a soldier. The trigger is **lack of battle progress** (damage dealt or taken by the assault, a Castle hit), never raw duration:

- **Search Party:** after 45 s without progress, a small party of hunters comes out of the Castle gate;
- **Reinforced Search:** 35 s more without progress, a stronger party;
- **Relentless Hunt:** 30 s more, and from then on a party every 20 s until the battle ends, progress or not.

Progress resets the quiet clock; the stage reached stays. **Hunters** seek the assault's soldiers anywhere (no leash), pay **no Glory and no progress**, are part of no Barracks' queue and use **no cap**. **The hunt is bounded (v0.19):** never more hunters alive at once than two of the rival's strongest search parties; a party that would pass that sends only the hunters that fit, so the pressure goes on but a soldier nobody can reach never makes the hunt an endless unit generator.

**Anti-farming.** Rival units pay **nothing**: no Glory, no first-defeat bonus, no kill counted in the run, the profile, missions or the Bestiary. Meeting an archetype still adds its Bestiary entry (first-time information, never repeatable). Since a failed assault brings the rival back whole, nothing about it can be farmed.

### 54.11 Wave 100 and the waves after it

**Wave 100 never Prestiges, ends nothing and offers no Ascension.** Surviving it, against the current rival, **cuts that rival's reinforcement caps by 30%** (each cap rounded down; `Balance.RIVAL_RESERVE_CUT`, the one value), **once per rival**: the cut is kept through defeats (the same rival) and saved, and the next rival (after a Prestige) starts whole. The HUD says so: "Wave 100 survived! The rival's reinforcement reserves are cut by 30%." A catch-up valve, never a requirement: no rival needs it (§54.13), and attacking early is the faster way to Prestige.

**After Wave 100** the waves go on: the last ten authored waves repeat (101 is 91, ..., 110 is 100, 111 is 91), the late game's pressure, bounded, never scaled further, until the rival falls.

### 54.12 Prestige surfaces

Every Prestige surface reads one value (`ProfileState.prestige_progress()`): the rival to conquer next (its number and name; the final rival is marked), READY while an offer waits, ASCEND while an Ascension waits (v0.23), COMPLETE once the account is fully Ascended with every rank owned. The HUD block reads **RIVAL 8 / READY / COMPLETE** beside "7 / 33"; Stats reads "Conquer Rival 8, Stormkeep" (and the Wave 100 cut); the run receipt "Next Prestige: conquer Rival 8, Stormkeep."; the Prestige confirmation names the rival that fell and which rival the next kingdom faces.

### 54.13 The Prestige pool, offers, and Glory Upgrades

**33 ranks** (one per rival before the final one): Expansion / Unlock 8 (Archery Range, Research Monastery, Tower Engineering, Lancer Training, Advanced and Master Construction, Second and Third Assault Group), Command / Automation 10 (Auto Deployment, Deployment Sequences, Synchronized Deployment, Smart Workforce, Game Speed (two ranks again since v0.20), Formation Drill (one rank since v0.20), Rival Intelligence, Battle Signals, Royal Provisioning (v0.22)), Kingdom Boost 15 (Kingdom Output, Population Expansion, Spoils of War: 4 ranks each; Established Kingdom 3 since v0.22). Removed: Royal Tribute; each Boost's fifth rank; v0.20: Formation Drill II (merged into Formation Drill, which keeps the first rank's id), so Game Speed's second rank returns and the pool still holds exactly 33 ranks (a probe sums every card's maximum rank). Offers, the Prestige #1 building guarantee, the fair draw and prerequisites: §20.2 to §20.4.

**No soft-lock.** No rival may require a specific Prestige card (Second or Third Assault Group, a building, Lancer Training, Formation Drill, Rival Intelligence, Battle Signals, a Boost). A player with basic systems and enough run and Glory development can conquer every rival; the balance audit checks it (§54.17).

**Glory Upgrades** (the renamed permanent upgrades, §18): kept through defeats, reset at Prestige. Removed in v0.18: **Drop-off Mastery**, **Recovery Doctrine** (merged into one **Salvage** progression, +6% a level, 8 levels) and **Formation Drill** (now a Prestige Upgrade); an older profile's levels are refunded at their old prices, once, and old Formation Drill levels open no formation (nothing is applied twice).

### 54.14 Save and migration

**An assault survives save and load**, never disabled: the plan; the rival under attack; its Castle's HP; every rival unit (kind, HP, place, post, hunter); each military building's spawned count and next time; each group's state, sail and landing times, line and anchor; the anti-stall stage, clock and hunter count; every soldier's assault stage, group, place in formation and time at sea; and whether the rival has fallen with its offer. A reload resumes the same battle: the rival is not restored to full, no unit is duplicated, no offer is rerolled, no home wave restarts. **Save integrity (v0.25; supersedes the per-death policy in v0.19):** an assault soldier's death and every other lasting battle change (a rival unit's fall, a hit on the rival Castle, a reinforcement, a group's landing and form-up, the anti-stall stage) mark the save dirty for the existing five-real-second interval. Conquest and other completed progression transitions save immediately; a force-close during combat can roll back at most one dirty-save interval (§64.3).

**Migration (save version 2 to 3).** A v0.17 save is migrated, not dropped: Renown and the first-defeat flag are deleted (old Renown can never become a Prestige); Prestige ranks are kept where the card still exists, capped at the new maximum (a fifth Boost rank to 4; Game Speed's two ranks are kept again since v0.20), and Royal Tribute dropped; the Prestige count becomes the ranks kept, so the current rival follows them and every lost rank is a rival to conquer and a card to choose again; a waiting offer stays (its retired cards redrawn); the retired Glory upgrades are refunded; Renowned Dynasty is dropped; a run on the old victory lap resumes as play, with Wave 100's cut applied. The player is told once. A new profile begins at Rival 1.

### 54.15 Onboarding and How to play

No new tutorial: the first-run completion message (§27.5) already names the goal. When an army of a few soldiers stands after the third wave, a one-time hint (Guided and Basic) says the rival kingdom can be attacked from Attack. The How to play deck (the one source, §35) gains **Conquer** ("Tap Attack to plan your assault on the rival kingdom." Assign soldiers, Launch once the current wave is defeated, no retreat, destroy the rival Castle to conquer it and earn a Prestige) and **Rebuild stronger** speaks of Glory Upgrades.

### 54.16 Ascension

Redesigned in v0.23 (§20.9): conquering Rival 34, the final rival, with all 33 Prestige ranks owned offers an Ascension (one Crown, one freely chosen Decree, a new cycle at Rival 1); nine at most.

### 54.17 The 34 rivals

The authored rivals (`data/rivals.json`, generated by `tools/gen_rivals.py`; the sizing and its measurements are IMPLEMENTATION_DECISIONS.md RK-B1). Each rival is fixed: the same for every player at every attempt. **Rival 34, The Last Crown (v0.23)**, is the final rival, conquered for an Ascension (§20.9): Rival 33's composition and reserves with a stronger Castle (196,200 HP; 151.5 every 1.2 s, range 472) and reinforcements a little sooner (first 5.9 s, every 7.8 s), from the same generator with Rivals 1 to 33 byte-identical; its numbers are a conservative first authoring, to be tuned by playtest.

- **Size** (the frontline plus every reserve, Elite champions apart) grows from 45 units (Rival 1) to 220 (Rival 21 on), the largest battle a phone carries; **composition** develops: newer and heavier archetypes, a mix leaning toward the heavier ones, champions; **buildings** 1, 2 (Rival 4), 3 (10), 4 (18; three Barracks and one Archery Range), each reinforcement coming sooner and faster on later rivals; **the Castle** holds about 30 s of what a typical army of that stage deals (never more than 1.35 times the rival before) and shoots from Rival 6.
- **Balance targets:** a typical army for its stage keeps about half its soldiers against Rivals 2 to 12 (Rival 1 is easier: the first conquest teaches the loop); from Rival 13 the battle size binds first, and a developed army wins with most of its soldiers. **No soft-lock:** the weakest army a player can be forced into (Tier 1 Warriors only to Rival 25, Glory and run upgrades maxed, 100 soldiers, falling back on Wave 100's cut) conquers every rival; the full probe suite checks it at all 33 (`rival_audit --check`).
- **Reading the table:** a building's queue is cycled; "first" is seconds after Group 1 lands, "every" the cadence; reserves in brackets are what remains after Wave 100's 30% cut (each cap rounded down). Search parties (§54.10) are not in the table.

| Rival | Name | Castle HP | Castle attack | Frontline | Military buildings (queue, cap; first s, every s) | Reserves (after Wave 100) |
|---|---|---|---|---|---|---|
| 1 | Thornmere | 4,200 | none | 26: Thrall 13, Raider 13 | Barracks: Thrall/Raider x19 (10, 14) | 19 (13) |
| 2 | Ashford | 5,600 | none | 35: Thrall 12, Raider 13, Skirmisher 10 | Barracks: Raider/Thrall x25 (9.9, 13.8) | 25 (17) |
| 3 | Greywatch | 7,000 | none | 45: Thrall 13, Raider 14, Cutthroat 5, Skirmisher 13 | Barracks: Raider/Thrall/Cutthroat x33 (9.8, 13.6) | 33 (23) |
| 4 | Duskhollow | 9,500 | none | 46: Raider 19, Cutthroat 8, Brute 5, Skirmisher 14 | Barracks: Raider/Cutthroat/Brute x22 (9.6, 13.4); Archery Range: Skirmisher x12 (11.1, 13.4) | 34 (23) |
| 5 | Ironvale | 12,800 | none | 61: Raider 23, Cutthroat 11, Brute 9, Skirmisher 18 | Barracks: Raider/Cutthroat/Brute x29 (9.5, 13.2); Archery Range: Skirmisher x16 (11, 13.2) | 45 (31) |
| 6 | Redmarsh | 17,300 | 20 every 2 s, range 360 | 67: Raider 19, Cutthroat 12, Brute 9, Shieldbearer 7, Skirmisher 20 | Barracks: Raider/Cutthroat/Brute x32 (9.4, 13.1); Archery Range: Skirmisher x17 (10.9, 13.1) | 49 (33) |
| 7 | Stormkeep | 17,900 | 21.5 every 1.97 s, range 364 | 74: Raider 19, Cutthroat 12, Brute 12, Shieldbearer 9, Skirmisher 22 | Barracks: Raider/Brute/Cutthroat x35 (9.2, 12.9); Archery Range: Skirmisher x19 (10.7, 12.9) | 54 (37) |
| 8 | Blackmoor | 21,000 | 23.1 every 1.94 s, range 368 | 74: Raider 16, Cutthroat 10, Brute 10, Shieldbearer 10, Skirmisher 19, Shaman 9 | Barracks: Raider/Shieldbearer/Brute x35 (9.1, 12.7); Archery Range: Skirmisher/Shaman x19 (10.6, 12.7) | 54 (37) |
| 9 | Frostgate | 23,300 | 24.8 every 1.91 s, range 372 | 74: Raider 14, Cutthroat 9, Brute 9, Shieldbearer 11, Ravager 3, Skirmisher 12, Longbowman 7, Shaman 9 | Barracks: Raider/Shieldbearer/Brute x35 (9, 12.5); Archery Range: Skirmisher/Shaman/Longbowman x19 (10.5, 12.5) | 54 (37) |
| 10 | Emberfall | 27,800 | 26.7 every 1.88 s, range 376 | 77: Raider 11, Cutthroat 7, Brute 9, Shieldbearer 10, Ravager 4, Reaver 7, Skirmisher 11, Longbowman 9, Shaman 9 | Barracks: Raider/Shieldbearer/Brute x22 (8.9, 12.3); Archery Range: Shaman/Skirmisher/Longbowman x12 (10.4, 12.3); Barracks: Raider/Shieldbearer/Brute x21 (11.9, 12.3) | 55 (37) |
| 11 | Ravenholt | 29,500 | 28.7 every 1.85 s, range 380 | 79: Raider 11, Cutthroat 7, Brute 8, Shieldbearer 9, Ravager 5, Reaver 9, Skirmisher 10, Longbowman 11, Shaman 9 | Barracks: Raider/Shieldbearer/Reaver x23 (8.8, 12.1); Archery Range: Shaman/Longbowman/Skirmisher x12 (10.3, 12.1); Barracks: Raider/Shieldbearer/Reaver x22 (11.8, 12.1) | 57 (39) |
| 12 | Grimhold | 33,800 | 30.9 every 1.82 s, range 384 | 79: Raider 9, Cutthroat 6, Brute 7, Shieldbearer 8, Ravager 6, Reaver 10, Juggernaut 3, Skirmisher 9, Longbowman 12, Shaman 9 | Barracks: Reaver/Raider/Shieldbearer x23 (8.6, 11.9); Archery Range: Longbowman/Shaman/Skirmisher x12 (10.1, 11.9); Barracks: Reaver/Raider/Shieldbearer x22 (11.6, 11.9) | 57 (39) |
| 13 | Highcliff | 45,600 | 33.2 every 1.79 s, range 388 | 110: Raider 11, Cutthroat 7, Brute 9, Shieldbearer 10, Ravager 8, Reaver 16, Juggernaut 7, Skirmisher 12, Longbowman 17, Shaman 13 | Barracks: Reaver/Raider/Shieldbearer x32 (8.5, 11.8); Archery Range: Longbowman/Shaman/Skirmisher x17 (10, 11.8); Barracks: Reaver/Raider/Shieldbearer x31 (11.5, 11.8) | 80 (54) |
| 14 | Wolfhaven | 51,300 | 35.7 every 1.76 s, range 392 | 115: Raider 11, Cutthroat 7, Brute 10, Shieldbearer 10, Ravager 8, Reaver 16, Juggernaut 9, Skirmisher 12, Longbowman 17, Shaman 14, Warlord 1 | Barracks: Reaver/Raider/Shieldbearer x33 (8.4, 11.6); Archery Range: Longbowman/Shaman/Skirmisher x17 (9.9, 11.6); Barracks: Reaver/Raider/Shieldbearer x33 (11.4, 11.6) | 83 (57) |
| 15 | Saltcrag | 58,100 | 38.3 every 1.73 s, range 396 | 119: Cutthroat 8, Brute 11, Shieldbearer 12, Ravager 10, Reaver 19, Juggernaut 13, Skirmisher 12, Longbowman 19, Shaman 14, Warlord 1 | Barracks: Reaver/Juggernaut/Shieldbearer x34 (8.2, 11.4); Archery Range: Longbowman/Shaman/Skirmisher x18 (9.7, 11.4); Barracks: Reaver/Juggernaut/Shieldbearer x34 (11.2, 11.4) | 86 (58) |
| 16 | Briarwood | 62,600 | 41.2 every 1.7 s, range 400 | 120: Cutthroat 8, Brute 11, Shieldbearer 12, Ravager 10, Reaver 19, Juggernaut 14, Skirmisher 12, Longbowman 19, Shaman 14, Warlord 1 | Barracks: Reaver/Juggernaut/Shieldbearer x34 (8.1, 11.2); Archery Range: Longbowman/Shaman/Skirmisher x19 (9.6, 11.2); Barracks: Reaver/Juggernaut/Shieldbearer x34 (11.1, 11.2) | 87 (59) |
| 17 | Coldspire | 66,500 | 44.3 every 1.67 s, range 404 | 123: Cutthroat 7, Brute 11, Shieldbearer 12, Ravager 11, Reaver 19, Juggernaut 15, Skirmisher 12, Longbowman 19, Shaman 15, Warlord 1, Marksman 1 | Barracks: Reaver/Juggernaut/Shieldbearer x34 (8, 11); Archery Range: Longbowman/Shaman/Skirmisher x19 (9.5, 11); Barracks: Reaver/Juggernaut/Shieldbearer x34 (11, 11) | 87 (59) |
| 18 | Hollowmere | 74,600 | 47.6 every 1.64 s, range 408 | 124: Cutthroat 7, Brute 12, Shieldbearer 12, Ravager 11, Reaver 19, Juggernaut 15, Skirmisher 12, Longbowman 20, Shaman 14, Warlord 1, Marksman 1 | Barracks: Reaver/Juggernaut/Brute x25 (7.9, 10.8); Archery Range: Longbowman/Shaman/Skirmisher x13 (9.4, 10.8); Barracks: Reaver/Juggernaut/Brute x25 (10.9, 10.8); Barracks: Reaver/Juggernaut/Brute x25 (12.4, 10.8) | 88 (60) |
| 19 | Stonehelm | 82,000 | 51.2 every 1.61 s, range 412 | 125: Cutthroat 7, Brute 12, Shieldbearer 11, Ravager 12, Reaver 18, Juggernaut 16, Longbowman 32, Shaman 15, Warlord 1, Marksman 1 | Barracks: Reaver/Juggernaut/Brute x25 (7.8, 10.6); Archery Range: Longbowman/Shaman x14 (9.3, 10.6); Barracks: Reaver/Juggernaut/Brute x25 (10.8, 10.6); Barracks: Reaver/Juggernaut/Brute x25 (12.3, 10.6) | 89 (60) |
| 20 | Cinderreach | 85,900 | 55 every 1.58 s, range 416 | 125: Cutthroat 7, Brute 12, Shieldbearer 11, Ravager 12, Reaver 18, Juggernaut 16, Longbowman 32, Shaman 15, Warlord 1, Marksman 1 | Barracks: Reaver/Juggernaut/Ravager x25 (7.6, 10.4); Archery Range: Longbowman/Shaman x14 (9.1, 10.4); Barracks: Reaver/Juggernaut/Ravager x25 (10.6, 10.4); Barracks: Reaver/Juggernaut/Ravager x25 (12.1, 10.4) | 89 (60) |
| 21 | Mistvale | 93,300 | 59.2 every 1.55 s, range 420 | 126: Brute 13, Shieldbearer 12, Ravager 13, Reaver 20, Juggernaut 19, Longbowman 32, Shaman 15, Warlord 1, Marksman 1 | Barracks: Reaver/Juggernaut/Ravager x25 (7.5, 10.2); Archery Range: Longbowman/Shaman x14 (9, 10.2); Barracks: Reaver/Juggernaut/Ravager x25 (10.5, 10.2); Barracks: Reaver/Juggernaut/Ravager x25 (12, 10.2) | 89 (60) |
| 22 | Dreadmoor | 101,700 | 63.6 every 1.52 s, range 424 | 126: Brute 13, Shieldbearer 12, Ravager 14, Reaver 19, Juggernaut 19, Longbowman 32, Shaman 15, Warlord 1, Marksman 1 | Barracks: Juggernaut/Reaver/Ravager x25 (7.4, 10.1); Archery Range: Longbowman/Shaman x14 (8.9, 10.1); Barracks: Juggernaut/Reaver/Ravager x25 (10.4, 10.1); Barracks: Juggernaut/Reaver/Ravager x25 (11.9, 10.1) | 89 (60) |
| 23 | Ironcrown | 105,800 | 68.4 every 1.49 s, range 428 | 126: Brute 13, Shieldbearer 11, Ravager 14, Reaver 19, Juggernaut 20, Longbowman 32, Shaman 15, Warlord 1, Marksman 1 | Barracks: Juggernaut/Reaver/Ravager x25 (7.2, 9.9); Archery Range: Longbowman/Shaman x14 (8.7, 9.9); Barracks: Juggernaut/Reaver/Ravager x25 (10.2, 9.9); Barracks: Juggernaut/Reaver/Ravager x25 (11.7, 9.9) | 89 (60) |
| 24 | Vexhold | 122,500 | 73.5 every 1.46 s, range 432 | 126: Brute 12, Shieldbearer 11, Ravager 14, Reaver 19, Juggernaut 21, Longbowman 32, Shaman 15, Warlord 1, Marksman 1 | Barracks: Juggernaut/Reaver/Ravager x26 (7.1, 9.7); Archery Range: Longbowman/Shaman x14 (8.6, 9.7); Barracks: Juggernaut/Reaver/Ravager x25 (10.1, 9.7); Barracks: Juggernaut/Reaver/Ravager x25 (11.6, 9.7) | 90 (61) |
| 25 | Bleakwater | 126,200 | 79 every 1.43 s, range 436 | 126: Brute 13, Shieldbearer 11, Ravager 14, Reaver 18, Juggernaut 21, Longbowman 32, Shaman 15, Warlord 1, Marksman 1 | Barracks: Juggernaut/Reaver/Ravager x26 (7, 9.5); Archery Range: Longbowman/Shaman x14 (8.5, 9.5); Barracks: Juggernaut/Reaver/Ravager x25 (10, 9.5); Barracks: Juggernaut/Reaver/Ravager x25 (11.5, 9.5) | 90 (61) |
| 26 | Gloomspire | 136,900 | 85 every 1.4 s, range 440 | 131: Brute 13, Shieldbearer 11, Ravager 15, Reaver 19, Juggernaut 22, Longbowman 33, Shaman 15, Warlord 2, Marksman 1 | Barracks: Juggernaut/Reaver/Ravager x26 (6.9, 9.3); Archery Range: Longbowman/Shaman x14 (8.4, 9.3); Barracks: Juggernaut/Reaver/Ravager x26 (9.9, 9.3); Barracks: Juggernaut/Reaver/Ravager x26 (11.4, 9.3) | 92 (63) |
| 27 | Shadowfen | 142,800 | 91.3 every 1.37 s, range 444 | 131: Shieldbearer 13, Ravager 18, Reaver 22, Juggernaut 27, Longbowman 33, Shaman 15, Warlord 2, Marksman 1 | Barracks: Juggernaut/Reaver/Ravager x26 (6.8, 9.1); Archery Range: Longbowman/Shaman x14 (8.3, 9.1); Barracks: Juggernaut/Reaver/Ravager x26 (9.8, 9.1); Barracks: Juggernaut/Reaver/Ravager x26 (11.3, 9.1) | 92 (63) |
| 28 | Kingsbane | 151,600 | 98.2 every 1.34 s, range 448 | 131: Shieldbearer 12, Ravager 19, Reaver 21, Juggernaut 28, Longbowman 33, Shaman 15, Warlord 2, Marksman 1 | Barracks: Juggernaut/Reaver/Ravager x26 (6.6, 8.9); Archery Range: Longbowman/Shaman x14 (8.1, 8.9); Barracks: Juggernaut/Reaver/Ravager x26 (9.6, 8.9); Barracks: Juggernaut/Reaver/Ravager x26 (11.1, 8.9) | 92 (63) |
| 29 | Drakemoor | 157,500 | 105.5 every 1.31 s, range 452 | 134: Shieldbearer 12, Ravager 19, Reaver 21, Juggernaut 28, Longbowman 33, Shaman 15, Warlord 2, Dread Knight 1, Marksman 2, Hexer 1 | Barracks: Juggernaut/Reaver/Ravager x26 (6.5, 8.8); Archery Range: Longbowman/Shaman x14 (8, 8.8); Barracks: Juggernaut/Reaver/Ravager x26 (9.5, 8.8); Barracks: Juggernaut/Reaver/Ravager x26 (11, 8.8) | 92 (63) |
| 30 | Blightholm | 172,600 | 113.5 every 1.28 s, range 456 | 134: Shieldbearer 12, Ravager 19, Reaver 20, Juggernaut 29, Longbowman 33, Shaman 15, Warlord 2, Dread Knight 1, Marksman 2, Hexer 1 | Barracks: Juggernaut/Reaver/Ravager x26 (6.4, 8.6); Archery Range: Longbowman/Shaman x14 (7.9, 8.6); Barracks: Juggernaut/Reaver/Ravager x26 (9.4, 8.6); Barracks: Juggernaut/Reaver/Ravager x26 (10.9, 8.6) | 92 (63) |
| 31 | Nightcrest | 178,900 | 122 every 1.25 s, range 460 | 136: Shieldbearer 11, Ravager 19, Reaver 20, Juggernaut 30, Longbowman 33, Shaman 15, Warlord 3, Dread Knight 2, Marksman 2, Hexer 1 | Barracks: Juggernaut/Reaver/Ravager x26 (6.2, 8.4); Archery Range: Longbowman/Shaman x14 (7.7, 8.4); Barracks: Juggernaut/Reaver/Ravager x26 (9.2, 8.4); Barracks: Juggernaut/Reaver/Ravager x26 (10.7, 8.4) | 92 (63) |
| 32 | Ebonreach | 185,200 | 131.1 every 1.22 s, range 464 | 136: Shieldbearer 11, Ravager 19, Reaver 20, Juggernaut 30, Longbowman 33, Shaman 15, Warlord 3, Dread Knight 2, Marksman 2, Hexer 1 | Barracks: Juggernaut/Reaver/Ravager x26 (6.1, 8.2); Archery Range: Longbowman/Shaman x14 (7.6, 8.2); Barracks: Juggernaut/Reaver/Ravager x26 (9.1, 8.2); Barracks: Juggernaut/Reaver/Ravager x26 (10.6, 8.2) | 92 (63) |
| 33 | The Black Citadel | 190,500 | 140.9 every 1.2 s, range 468 | 137: Shieldbearer 11, Ravager 19, Reaver 19, Juggernaut 31, Longbowman 33, Shaman 15, Warlord 3, Dread Knight 2, Marksman 2, Hexer 2 | Barracks: Juggernaut/Ravager/Reaver x26 (6, 8); Archery Range: Longbowman/Shaman x14 (7.5, 8); Barracks: Juggernaut/Ravager/Reaver x26 (9, 8); Barracks: Juggernaut/Ravager/Reaver x26 (10.5, 8) | 92 (63) |
| 34 | The Last Crown (final) | 196,200 | 151.5 every 1.2 s, range 472 | 137: Shieldbearer 11, Ravager 19, Reaver 19, Juggernaut 31, Longbowman 33, Shaman 15, Warlord 3, Dread Knight 2, Marksman 2, Hexer 2 | Barracks: Juggernaut/Ravager/Reaver x26 (5.9, 7.8); Archery Range: Longbowman/Shaman x14 (7.4, 7.8); Barracks: Juggernaut/Ravager/Reaver x26 (8.9, 7.8); Barracks: Juggernaut/Ravager/Reaver x26 (10.4, 7.8) | 92 (63) |

## 55. v0.18 change log

Approved brief (`docs/Claude_GrowingKingdom_Rival_Kingdom_Conquest_Prestige_Rework.md`), now reflected above and in §54.

- **Prestige by conquest:** Renown, its table and the first-defeat unlock are gone; one conquered rival = one Prestige opportunity; one rival per Prestige rank (§20.8, §54);
- **the rival kingdom:** an authored island south of ours; Attack and the Assault Planner; Groups 1 to 3; Ranks and the Formation Drill formations; delays and Battle Signals; the beach-to-beach crossing; the assault behaviour; defenders, reinforcements and the Castle's attack; conquest and failure; anti-stall hunters; no rewards from rival units (§54.1 to §54.10);
- **Wave 100** cuts the current rival's reserves and the last ten waves repeat after it; it no longer ends the run or triggers Ascension (§4.5, §54.11);
- **the Prestige pool** (33 ranks): Royal Tribute removed, Game Speed one rank, Boosts four ranks (+30% / +35% / +50% / +175 per rank), six new cards (Second and Third Assault Group, Formation Drill I and II, Rival Intelligence, Battle Signals); roles renamed Expansion / Unlock, Command / Automation, Kingdom Boost; the building guarantee only on Prestige #1; the fair draw (§20.2 to §20.7);
- **Glory Upgrades:** the permanent upgrades renamed; Drop-off Mastery and Recovery Doctrine removed (Salvage: +6% a level, 8 levels); Formation Drill moved to Prestige (§18, §19);
- **saves:** version 3, a deliberate migration from version 2 (§28.6, §54.14);
- **HUD:** the Attack tool (dock buttons 76 px high), the assault bar, the Prestige bar reading RIVAL n (§3.3).

Superseded statements: "Glory earned fills a Renown meter" and the Renown table (§20.8); "Prestige starts with the first real defeat" (§20.8, §28.5); the first-building guarantee "until a building is chosen" (§20.2); Royal Tribute (§20.7, §22.2, §27.1c); "Wave 100 ... completion state ... Super Prestige offer" (§4.5, §26, §32); Formation Drill as a permanent upgrade (§12.7, §18.2); Recovery Doctrine (§18.2, §19.2); Game Speed two ranks and five-rank Boosts (§20.6, §20.7); "LOCKED" and Renown text in the Prestige block (§3.3).

## 56. v0.19 change log

Approved brief: `docs/Claude_GrowingKingdom_Rival_Mirror_Assault_Selection_BuildFootprint_Corrections.md` (from the developer's on-device review), now reflected above.

### 56.1 The rival kingdom is ours turned around (§54.1)

Our world section turned 180°: the same heights and proportions, beach on top, battlefield, ramp apron, defensive row and Castle, then the kingdom plateau. Its settlement, resources, Towers, frontline lines, gate and landing beach all come from our geometry and rules through one transform; Villagers work it as scenery. Supersedes v0.18's island "laid out as ours mirrored" with its own Castle row, military buildings beside the Castle and an authored town grid.

### 56.2 Assault combat (§54.8, §54.9)

- Melee soldiers strike the rival Castle only from our attack positions turned around (queueing when all are taken); ranged soldiers and casters from their range of the wall line. Supersedes "the rival Castle (its footprint): its front and its front corners can all be struck".
- Assault Advance: each soldier marches on the Castle by itself after the form-up; a direct order overrides it, Resume returns to it. Supersedes the line that advanced at its slowest soldier's pace, waited for stragglers, halted while half of it fought and stopped at a siege line.
- Reinforcements come out of the Castle gate; the rival Castle's range is measured from its front.

### 56.3 The search party is bounded (§54.10)

Never more hunters alive than two of the rival's strongest search parties.

### 56.4 Selection, Prestige, saves (§12.7, §20.8, §3.3, §54.14)

Light unit markers (same corners, about half the stroke, slightly translucent, same tap target); the PRESTIGE READY block reopens the waiting offer and the ⓘ column is its own target for Owned Prestiges; assault casualties and other battle progress mark the save dirty, coalesced every five real seconds (v0.25 §64.3).

### 56.5 Build clearance by resource (§5.2)

A tree keeps only its working core clear (trunk, work stands, lower canopy) instead of its whole canopy rectangle; a Gold deposit keeps its whole rock; a sheep nothing. Where a canopy overlaps a building, the one drawn in front takes the tap. Supersedes "the building's pick rectangle clear of every tree's and deposit's pick rectangle".

### 56.6 Current-progress settlement setups (debug builds)

The Debug panel's **Current-progress settlement setups** (Ready to Build, Assault Test: Barracks Only, Mixed Army, Maxed Kingdom) replace only the current run and keep the profile (Prestige ranks and count, the current rival, Crowns, Decrees, the onboarding mode, the Bestiary, statistics); they set the first-run progression to Complete without replaying its notice. The assault fixtures field a fixed army planned into Group 1 (run-only buildings, tiers and soldiers the profile may not own; nothing is written to the profile). For testing each rival in turn: apply, attack, conquer, Prestige, apply again. The deterministic Test Saves still start from a hard reset and are labelled so.

### 56.7 Title

The game's display title is **Growing Kingdom: RTS** (project, Android label, the welcome and campaign-end messages); the package id is unchanged.

### 56.8 Balance

Not retuned in this pass (the developer tests each rival with §56.6). The attack positions limit how many melee soldiers strike the Castle at once, which can lengthen sieges for melee-heavy armies; the no-soft-lock floor check (§54.17) was not re-run.

## 57. v0.19 follow-up: embarkation, the rival Castle entrance, reinforcement spawn

Approved brief: `docs/Claude_GrowingKingdom_Embarkation_RivalEntrance_ReinforcementSpawn_Fix.md` (from the developer's testing), now reflected in §54.1 and §54.9. No new version: a correction of v0.19.

### 57.1 The group sails as one (§54.1)

Each committed soldier walks to its place on our beach (its group's formation on the group's third of the beach, the landing thirds turned around) and waits there, visible. When every living member stands at its place, the whole group goes to sea in one step and its crossing starts once; no soldier ever goes into the water on its own. A group still waiting `ASSAULT_EMBARK_TIMEOUT` (90 s) after the launch brings each straggler that could not get there to its place (unhurt, never killed, failed or copied) and sails. Groups 1, 2 and 3 alike. A save from before this fix holding a group still embarking with some soldiers already at sea is repaired on load: they stand at their beach places again and the group sails as one. Supersedes "each soldier walks into the water on reaching the beach; a group sails once all are aboard", which let one stuck soldier leave the rest of the army unseen at sea forever.

### 57.2 The rival Castle entrance (§54.1)

The rival plateau has no rim across our ramp columns turned around for its first row: the battlefield's flat ground runs up to the Castle's front, the rim stepping round it on both sides, and the raised apron is gone. That open ground is exactly where the rival field lets units reach the Castle front and its attack positions. The mirrored geometry is unchanged.

### 57.3 Reinforcements walk out of their buildings (§54.9)

A reinforcement appears just outside the door of the military building that owns its queue (its upright art faces the town), walks round that building toward the Castle, to the Castle's back, through the Castle and out of its gate onto the field, then to its post and the fight. Each building sends from its own place. Queues, cadence, caps and unit types are unchanged; search parties still come out of the gate. Supersedes v0.19's "units come out of the Castle gate".

### 57.4 Balance

Not retuned. Reinforcements now spend their walk from the town before they reach the field, so they join the fight later than when they appeared at the gate; no audit was run (by the brief).

## 58. v0.20: Rival Intelligence, Game Speed and upgrade naming

Approved brief: `docs/Claude_GrowingKingdom_Prestige_Intelligence_GameSpeed_UpgradeNaming_Followup.md`. A focused progression and UI pass: no rival, army, wave, resource, combat or assault timing change.

### 58.1 Rival Intelligence: unknown, then exact (§54.3, §20.6)

Without Rival Intelligence the Assault Planner shows "Military strength: Unknown" and no rival military number of any kind (no approximation replaces the old "about N defenders · M military buildings"); after Wave 100 only "this rival has been weakened", and the Wave 100 toast says the same. With it, the exact authored template as before. The card reads "Reveals the rival's exact defenses, Castle strength and reinforcement reserves before you attack." Battlefield information during an assault is unchanged.

### 58.2 Game Speed two ranks, Formation Drill one (§20.6, §12.7)

Game Speed: rank I unlocks 2x, rank II 3x (speeds by rank [1x], [1x, 2x], [1x, 2x, 3x]); each rank's card says its own speed; the Prestige Upgrades panel shows what is owned ("Unlocks 2x game speed.", "Unlocks 2x and 3x game speed."). Formation Drill: one rank unlocking Block, Spread and Wedge ("Unlocks Block, Spread and Wedge formations for squads and assault groups."). The pool stays at 33 ranks (Game Speed +1, Formation Drill -1; Command / Automation still 9), one per rival; the draft roles, the fair draw and the building guarantee are unchanged.

### 58.3 Older saves

A save holding Formation Drill II alone keeps its formations as Formation Drill (no rank lost). A save holding both collapses to the one rank; the other rank is counted with the other lost ranks (the one-time message, IMPLEMENTATION_DECISIONS.md RK-M1), the Prestige count follows the ranks kept, and the player conquers that rival again and chooses a card. Formation Drill II is never turned into Game Speed II, and no hidden credit is kept. Its fair-draw count is dropped. A waiting offer holding Formation Drill II (or Formation Drill once the merge made it owned) has that card redrawn from the same role with the profile's saved RNG and is saved, never rerolled again. No save version change (development saves, §28.6).

### 58.4 The three upgrade layers (§17, §18, §20)

Kingdom Upgrades (renamed from Run Upgrades: the panel and the Castle's shortcut), Glory Upgrades (unchanged) and Prestige Upgrades (the owned cards: the panel, its empty note, Stats' source labels, the confirmation's "You keep"). Short lock notes that named "a Prestige unlock" say "a Prestige Upgrade". The How to play deck's last card names the three layers; Spoils of War says what Glory buys ("Glory buys Glory Upgrades that last until your next Prestige.").

Superseded statements: "about how many defend it (rounded to 5), how many military buildings" (§54.3); Game Speed "one rank since v0.18: unlocks 2x and 3x" (§20.6, §54.14); Formation Drill I and II (§12.7, §20.4, §20.6, §54.7); "Run Upgrades" (§17); "Owned Prestiges" and "No Prestiges so far." (§3.3, §20.8).

---

## 59. v0.20 follow-up: authored audio

Approved brief: `docs/Claude_GrowingKingdom_Full_Authored_Audio_Integration.md`. An audio integration pass: no gameplay, balance or timing change. Before it every cue was a synthesized tone (the Tiny Swords pack has no audio) and there was no music.

### 59.1 Principle

Audio stays sparse and semantic: important decisions and state changes are heard, the simulation's repetition is not (no sound for weapon hits, deaths, gathering, deliveries, projectiles, automated deployment, automatic movement or reinforcements). Gameplay and UI ask for a semantic event; the audio service alone knows the files.

### 59.2 The authored set (`assets/sounds/`)

| Event | File | When |
|---|---|---|
| gameplay music | `background_music.wav` | the whole session, looping |
| `ui_click` | `ui_click.wav` | navigation: open, close, select, switch |
| `ui_confirm` | `ui_confirm.wav` | a committed manual action succeeds (buy, claim, launch, place, train, save a group); a direct order to units is acknowledged instead (v0.21) |
| `ui_error` | `ui_error.wav` | a manual action is refused |
| `mission_ready` | `mission_ready.wav` | a mission becomes claimable |
| `wave_clear` | `stage_clear.wav` | a wave is cleared |
| `victory` | `stage_clear.wav` | a rival is conquered (and an Ascension) |
| `defeat` | `defeat.wav` | the Castle falls; an assault fails |
| `reveal` | `reveal_unlock.wav` | an unlock or a reveal: the first-run Defense stage, a Prestige offer, a Prestige committed |
| `move_command_units` | `move_command_units.wav` | any manual order accepted by soldiers (v0.21: Move, Focus Attack, a stance, Resume Stance), a mixed selection included |
| `move_command_villager` | `move_command_villager.wav` | any manual order accepted by Villagers alone (v0.21: Move, Gather, Build, Deliver, a task, Resume Work) |
| `castle_hit` | `Castle_Damage (1).wav` to `(6).wav` | a landed hit on our Castle or the rival's |
| `warning` | synthesized (no authored file) | a new enemy, the first wave, the Defense stage complete, Standby riding out, an assault launched, the Castle coming under attack (once per attack, v0.21) |

### 59.3 One moment, one cue

What a single moment asks for is heard once: every cue requested in one frame is resolved together and only the most important plays (click, then Castle hit, then confirm / error / move, then mission ready / reveal / warning, then clear / victory / defeat). So a button's shared click never sounds under its action's confirm or error; a conquest that also offers a Prestige is heard as the victory; Wave 100 is heard as its wave clear, the rival's weakening adding no second cue; the Castle's last blow is the defeat. A mission plays mission ready once, when it changes from incomplete to claimable (several in one check: one cue), never on a refresh, on opening Missions, on loading a save, or before the first run opens Missions; Claim confirms.

### 59.4 Move acknowledgements and the Castle Damage pool

**Every accepted manual order is acknowledged (v0.21),** once per command, never once per member: a world tap (Move, Focus Attack, Gather, Build, Deliver; §12.10, §7.4d), the selection bar (a stance, Resume Stance, a task, Resume Work), a soldier's or Villager's card (its stance or task buttons, Resume Stance, Resume Work) and the Army panel's stance orders. The soldiers' cue when soldiers took it (a mixed selection included: the soldiers' cue once, never both), the Villagers' cue when only Villagers did. It replaces the generic confirm; a refused order is the error alone. Actions that are not orders (saving a group, buying, placing) still confirm. No automatic movement (stances, Standby, Assault Advance, engagement, formations, reinforcements, work, Smart Workforce, tutorial) ever plays a command cue. (Before v0.21 only a Move was acknowledged; the other orders confirmed.)

`castle_hit` draws from the six Castle Damage files through a shuffle bag (each file once per round, a new round never starting with the file the last one ended on) and plays at most once every 0.30 s of real time, however many attackers land hits; only the sound is throttled. Both Castles use the same pool and cooldown. The blow that destroys our Castle, or the rival's, plays no hit: the defeat or victory is the cue.

### 59.5 Music and Settings

One gameplay track loops for the whole session, started once by the game's lifecycle; panels, Pause, Settings and a reload never restart or stack it. **The Pause holds it (v0.21):** the player's Pause pauses the track where it is and Resume continues it from there (never from the start, never a second stream). While paused, Music Off keeps it off, Music On is not heard until play resumes, and a volume change applies at once; Resume follows the settings as they are then. Opening Settings or a panel does not pause it, and sound effects (the pause menu's own clicks) still play. It is imported compressed (QOA) and looping, not as raw PCM. Settings holds the only controls: Sound effects On/Off, Effects volume, Music On/Off, Music volume (Music was a saved setting with no control before this pass); each applies at once and is saved.

---

## 60. v0.21: wave pressure, Castle healing, command audio, Castle warning, music pause, soldier flow, Build-mode performance

Approved brief: `docs/Claude_GrowingKingdom_WavePressure_CastleHealing_CommandAudio_Warning_Music_SoldierFlow_BuildPerformance.md`. A focused systems and polish pass: no rival, combat formula, targeting or progression change beyond what is listed.

### 60.1 Wave pressure (§15.1, §12.6a, §54.3)

45 simulated seconds after a wave's last scheduled spawn, enemies still alive no longer hold the next wave back: its countdown starts, the survivors fight on into it, and the moment is never a clear (no cue, message, count or milestone). Launch Attack and Castle repair wait for the survivors; Standby's emergency lasts while they remain. The timeout's clock is saved. Supersedes "all enemies in wave are defeated → short transition → next wave" as the only way on.

### 60.2 Castle healing starts at zero (§17.1)

Repair Crews has four levels: none, then 0.4 / 0.6 / 0.8 / 1.0% of max HP per second. A fresh Castle repairs nothing; Masonry and Sovereign Walls only improve a repair it has. Supersedes "a 0.4%/s base repair raised by three Repair Crews levels to 1.0%/s".

### 60.3 Every manual order acknowledged (§59.2, §59.4)

The soldiers' or Villagers' acknowledgement now answers every accepted direct order from every command surface, once per command; the generic confirm stays for actions that are not orders. Supersedes "Focus Attack, Gather, Build and Deliver orders confirm".

### 60.4 CASTLE UNDER ATTACK (§3.4, §59.2)

A persistent, non-blocking warning chip while blows land on the Castle (2.5 s grace between blows), with one warning cue per attack.

### 60.5 The Pause holds the music (§3.3, §59.5)

The player's Pause pauses the music where it is; Resume continues it. Modals other than the Pause (introductions, results, offers) do not pause it.

### 60.6 Friendly soldiers are never a wall (§12.6)

Soft friendly spacing: a soldier on the move and a standing one never push each other; a soldier stuck on the move for a second passes through friendlies for two. Reproduced first: three packed Defend rows across the gate held a soldier ordered past them behind the line indefinitely, and a squad Move and a Focus Attack the same way.

### 60.7 Build mode performance (§5.2)

Measured on a dense deterministic settlement (the Maxed Kingdom setup with 25 more Houses: 51 buildings, 64 soldiers, 65 resource nodes, wave 40): every simulation state change (each death in a fight) marked the build overlay stale, and each rescan ran the placement rule on all 630 anchors over every building and node, about 90 ms a scan, several a second. Validity now follows a placement version that only blocker changes move, the rule reads blockers from coarse spatial buckets kept per version, and the preview reuses its answer while its tile is unchanged. The rule itself is unchanged (checked against the old full scan on every tile). Results are in IMPLEMENTATION_REPORT.md.

## 61. v0.22: rival Towers, Monasteries, Royal Provisioning, Castle Standby, soldier orders

Approved brief: `docs/Claude_GrowingKingdom_Approved_Implementation_v4.md` (v4 supersedes v1 to v3). No rival rebalance: queues, caps, cadence, Wave 100's cut, frontlines, Castle HP and attack, troops and the economy are unchanged.

### 61.1 Rival Towers fire (§54.9a)

Supersedes "towers: decorative towers on the Castle row". Each rival Tower shoots landed assault soldiers on its own saved cooldown, by stage (12 / 16 / 22 / 30 damage).

### 61.2 Shamans come out of a Monastery (§54.9)

Supersedes "Archery Range for ranged and support". The Archery Range's queue stays the clock; a Shaman's door is the Monastery's. Rivals 8 and 9 gain a Monastery.

### 61.3 Royal Provisioning (§18.3, §20.6, §20.7, §13.3, §3.3, §27.4)

A new one-rank Command / Automation Prestige card (Established Kingdom gives up its fourth rank; 33 ranks for 33 rivals): in-run Glory Upgrade purchases, one per 10 waves cleared and at most 10 a run, through the tappable Glory chip and its panel; +1 saved Train card kept by every Prestige (Saved Card Configurations 3 levels, was 4). A one-time arrow points at the Glory chip at the first earned purchase, whatever the onboarding mode. The pacing is wave-earned only: there is no time-based cooldown anywhere.

### 61.4 Standby defends at 50% (§12.6a)

Supersedes the 30% trigger. Nothing else of Standby changes.

### 61.5 Direct orders end by themselves (§12.10)

Supersedes "the order lasts until another order, a stance change or Resume Stance" and "when it dies or is gone, the soldier holds where it stands". A held Move ends after 30 idle game seconds (2x: 15 real seconds, 3x: 10; the Pause freezes it), with an idle "!" over the waiting soldier; a Focus Attack ends the moment its enemy is gone, also after a reload. Villager orders are unchanged.

## 62. v0.23: Ascension, Train slots, offline rewards and Glory clarity

Approved brief: `docs/Claude_GrowingKingdom_Ascension_TrainCards_Offline_Glory_UI.md` (after commit a72c259). No speculative rebalance: Rivals 1 to 33, reinforcement reserves and timing, Wave 100's cut, our Towers' range, v0.22's Tower AI and the trailer are unchanged; the approved numbers below are the only balance changes.

### 62.1 Six Train places (§13.3, §13.4, §20.6)

Supersedes "Twin Banners adds +2 Deployment Slots" and "Royal Provisioning: +1 saved Train card". Active Train Slots: 1 + Expanded Command (Glory, 3) + Royal Provisioning (Prestige, +2) = 6; the rail always shows six places (assigned, not assigned, locked). Saved Card Configurations is 4 levels again: 2 + 4 + Twin Banners 2 = 8 saved cards, a separate capacity.

### 62.2 Rival 34 and Ascension (§20.8, §20.9, §54.16, §54.17)

Supersedes the Wave 100 Ascension and "33 rivals". Rival 34, The Last Crown, is the final rival; its conquest offers an Ascension: all nine Decrees to choose from (Clockwork Command removed; Royal Architects, Ancient Foundations, Endless Coffers, Sovereign Walls, Twin Banners, Golden Age, Glory of Kings and Warden Towers redefined; Veteran Legions unchanged), +1 Crown (+50% Glory, +30% friendly damage, +20% friendly HP each), and a new Prestige cycle at Rival 1. Nine at most. A Decree-granted building no longer leaves its Prestige card out of the pool.

### 62.3 Offline Wood, Gold and Food (§22.2, §17.3a, §20.7)

New: a share of storage per counted hour for each resource, two Offline Kingdom Upgrades (Supply Routes, Extended Reserves), Established Kingdom's offline rate and reward bonus, Golden Age's +4 h and x1.5, fitted to free storage when the receipt is made, claimed once; the receipt says what Glory is for.

### 62.4 Glory clarity (§3.3, §18)

New: the Glory ? beside the Glory icon, its own target, every mode; texts say Glory Upgrades survive defeats and reset at Prestige (and Ascension), never "forever"; Prestige Upgrades last until the next Ascension.

### 62.5 Guided building explanations (§27.4)

New: Guided says what each economy building does and where it belongs before and during its placement, and that the Barracks trains the Castle's defenders.


## 63. v0.24: Glory shop, first defeat, rival pursuit, Train Cards, streamlined Prestige and performance

### 63.1 Full Glory catalogue in an active run

The tappable Glory amount (when Royal Provisioning or Glory of Kings has enabled in-run purchasing) opens the **full Results-style Glory Upgrades catalogue** with all categories, upgrade details, levels, current and next effects, prices and purchase gates, rather than the compact quick-buy side panel. It is a non-pausing overlay: simulation continues at the chosen speed. Buying uses the one `RunState.buy_glory_upgrade` gate and the same Balance catalogue as between-run purchasing; Royal Provisioning still permits a maximum of one purchase per ten completed waves (ten per run, unspent credits accumulate within the run), while Glory of Kings removes only that allowance. The Results shop is unchanged. Closing the overlay returns to gameplay; the overlay closes when the run ends. The first-time Glory chip arrow still retires on chip activation in every tutorial mode.

Glory help text: **“Glory is earned from battles, missions and offline rewards. Spend it on Glory Upgrades after defeat or during a run when unlocked. They last until your next Prestige.”** This text reflects the real reset boundary (Glory also resets on Ascension).

### 63.2 First defeat opens Missions and teaches Glory

A new profile has no Missions button, no mission generation, progress, claim badge or mission-ready audio **until the Castle's first defeat**. The first actual defeat grants a one-time **300 Glory** bonus and permanently unlocks the Missions board across subsequent runs and Prestiges; this also applies to No Tutorial. It is an unconditional onboarding progression change, not a tutorial pointer. On the first defeat the Results screen opens directly to its full Glory Upgrades tab and visibly explains:

- **Your Kingdom Has Fallen!**
- **You've earned 300 Glory to strengthen your next kingdom!**
- **Spend Glory on upgrades that survive defeat and help you progress further. These upgrades reset when you Prestige.**
- **Missions are now unlocked. Earn more Glory by completing objectives.**

The award and its consumed flag are saved in the same final result transaction, cannot be farmed by repeating a defeat, and are not granted retroactively to profiles that already experienced defeat before this update. The reward is a flat 300 Glory, not scaled by Crown multipliers or regular Glory earn modifiers. After their first defeat the mission system's existing rules are unchanged. No “Every defeat is an opportunity to grow stronger” line.

### 63.3 Rival engagement rules

All rival defenders and their reinforcements acquire a landed invading soldier anywhere in the rival kingdom's active battlefield. Once acquired they **pursue the living target with no post leash or return while it remains a valid target**. When it dies or leaves, they acquire another available invader; without targets, a defender may stand/return to its post. Reinforcements continue their authored walk from the producing building through the rival Castle gate before joining combat. Damage, reserves, spawn composition, intervals, reinforcement caps, healing and the player's own stance/leash rules are unchanged. Supersedes the guard leash in §54.9.

### 63.4 Saved Train Card modifiers on Prestige or Ascension

A saved card's previously chosen Glory Command modifier is replaced with **None** if its corresponding Glory Upgrade has become locked on Prestige, Ascension or old-save load. Unit, quantity, stance and slot assignment are preserved wherever their other unlock/capacity rules allow. An unusable “Command locked” card must not be left behind solely because its modifier reset.

### 63.5 Compact Prestige confirmation

The three Prestige offer cards remain. Choosing a card opens **one concise confirmation**: gained upgrade and rank, next opponent, what is kept (Prestige Upgrades/Crowns) and lost (current kingdom and Glory layer), plus an explicit warning **only if unclaimed mission rewards exist**. There are Cancel and Prestige actions. No per-Glory-upgrade loss enumeration, second acknowledgment checkbox, or mandatory extra tap. The reset is still irreversible and atomic; the separate Ascension confirmation retains its established full safety flow. Supersedes §20.11 where it requires the extra acknowledgment for normal Prestige.

### 63.6 High-speed battle efficiency

Preserve 30 simulation ticks per game second, 1×/2×/3× speed, army caps, targeting semantics and save integrity. Use squared-distance comparisons for relevant target/nearest/heal queries, avoid redundant sorting work in coverage assignment and reuse capped arrow sprites instead of allocating a new Sprite2D for every shot. Rebuilds clear the FX pool and counters. These optimizations are candidates, not a claimed Android performance result: verify 40+ attacking soldiers at 3× on device. Immediate saves on assault-soldier death remain in place until a durable alternative can be verified, to prevent force-close exploits.


## 64. v0.25: friendly target sharing, readable progression UI, batched combat saves, compact numbers

This section supersedes the affected rules in §63.5–63.6 and §54.14. Approved after the Android 3× battle playtest (2026-10-11). No rival-enemy AI, combat damage, army size, game speed, resource economy, Glory shop purchase gate or Prestige reset behavior changes.

### 64.1 Friendly defenders share enemy targets (§12.6)

Every *automatic* friendly soldier fighting at home (Defend, Pursue, Intercept, including a Standby soldier activated for Castle defense) prefers enemies with fewer friendly attackers. Normal enemies have a **soft cap of 3 friendly soldiers**, Elites and Bosses and the heavy normal types Brute, Shieldbearer, Ravager and Juggernaut have a **soft cap of 6**. When all reachable targets are at capacity, extra soldiers still take a target and fight; the limits are never a reason to idle. Manual Attack and Move/Hold orders override the automatic choice and do not consume the automatic assignment allowance. Committed soldiers normally retain valid targets; once per game second, over-cap assignments can move to a legal under-cap alternative to spread already-clumped groups without tick-by-tick oscillation. Defend's Castle-duty priority and hard leash, Intercept's far-field preference, Pursue's no-leash commitment, Standby's reserve rules and the enemy's own Castle push are unchanged. Rebuild one home-assignment tally per combat tick and update it on target change; don't repeatedly scan every friendly soldier per candidate.

### 64.2 Glory shop and Prestige text (§18.3, §20.11)

In the full in-run Glory catalogue opened from the Glory HUD chip, only the `Next purchase after Wave N` line and `Glory Upgrades survive defeat, but reset on Prestige or Ascension.` use light/white lettering on the existing dark special-paper panel. The background and all other copy remain unchanged.

Prestige's confirmation uses light/white ordinary descriptions; the single conspicuous red warning is **"Your kingdom restarts"** with the kept/reset explanation. The unclaimed-mission warning is removed entirely: claiming Glory immediately before Prestige wouldn't let the player keep that Glory anyway. Cancel and Prestige buttons, the absence of a second acknowledgement and all actual reset rules remain unchanged.

### 64.3 Safe short-interval autosaves during battle (§54.14, §28)

Casualty deaths (including losses during the rival assault) only **mark dirty**, coalesced into the existing **5 real-second** autosave. Do not immediately serialize and flush the entire save on each death. The existing 60-second periodic fallback and immediate writes for committed progress (Prestige, Ascension, assault completion, conquest, defeat, reward claims and app backgrounding) remain. A force-close during an active fight may roll back up to one dirty-save interval; the developer explicitly accepts this performance/reliability trade-off. No save schema change or new game-time timer.

### 64.4 Number format and mobile results UI (§27, §20.8)

Player-facing large quantities use the shared `NumberFormat` formatter's **1K** threshold, then M/B/T and larger defined suffixes, e.g. `1K`, `1.5K`, `125K`, `1M`. Retain enough precision in displayed resource balances and prices that shorthand does not materially misrepresent their value; never change numerical gameplay calculations. Wave numbers, timers, small unit counts and other semantically exact identifiers remain exact. The top HUD conserves horizontal space via compact values and narrower inter-chip gaps; Prestige remains its own control, with a full-size tap target and the existing Wave/Castle chip unchanged. On the Results Prestige tab the three Choose actions are permanently visible in a row below the scrolling card descriptions, even for long text such as Smart Workforce. The chosen card still opens the same single confirmation.

## 65. v0.26: store marketing media (screenshots, trailer, social video)

Approved by the developer on 2026-10-13 (integration of the reusable Marketing Capture Toolkit, with the original trailer's hard cuts to black corrected). Development tooling only: no rule, balance, UI or save change in the game. The one game-side change is a tag: the five screen-UI layers (HUD, panels, toasts, tutorial, modals) belong to the `store_screenshot_ui` group, so a capture can hide the screen UI and keep world-space bars. How to record: `docs/Trailer_Recording.md`.

### 65.1 One source for every marketing asset

`marketing/manifest.json` is the single editable source: the capture jobs (scenario, size, length, framing options), the composed screenshots, the videos' shot order, durations, transitions and audio, and the approved copy. Scenarios are the live shots of the trailer timeline (`tests/trailer_timeline.gd`: defend, build, command, conquest, prestige), staged and checked as in the trailer brief; every picture is real gameplay recorded from the game, never painted or synthesized. Raw recordings and raw screenshots are kept untouched; text, cards, transitions and music are composed afterwards, so a copy or music change never needs a new recording. The reusable capture and composition code is the Marketing Capture Toolkit at a pinned version (`marketing_capture_toolkit.lock.json`); Growing Kingdom keeps only its adapter (`marketing/game_scenarios.gd`) and manifest.

### 65.2 The 30-second store trailer

1920×1080, 30 fps, exactly 30.0 s, H.264 MP4 (yuv420p, limited range, faststart). Order and copy as the trailer brief: live defense, **BUILD YOUR KINGDOM**, live building, **COMMAND YOUR ARMY**, live command, **CONQUER RIVAL KINGDOMS**, live conquest, **PRESTIGE. / REBUILD. GROW STRONGER.**, live Prestige, end card **GROWING KINGDOM: RTS** with **BUILD • DEFEND • CONQUER** and the game's castle art. It opens on live combat (no lead-in).

**Transitions (supersedes the brief's hard cuts):** every change between gameplay and a black card is an animated 0.4 s fade through black; a card's text appears only once the picture is black and fades in and out (0.2 s), so no text pops and no scene shows through it; the video ends with a 0.6 s fade to black. A hard cut to or from black is a defect. Cuts inside a live shot that the shot authors (the camera's cut from the conquered island to the new kingdom) stay. The live shots keep their authored action frames: a clip starts 0.4 s before its action where a fade covers its opening.

Cards use the game's own typography (Open Sans SemiBold, ivory with a gold rule and tagline) inside a central 75% safe width; each authored line shrinks to fit before it would wrap.

### 65.3 Audio

The game's own music track (`assets/sounds/background_music.wav`) runs under the whole video and fades out with it; the game's sound effects recorded with each clip are mixed beneath it, silent under the cards and crossfaded with the pictures. The mix is limited to −1 dBFS. A developer-supplied track may replace the music without re-recording.

### 65.4 The 9:16 social cut

1080×1920, 30 fps, 12.8 s: live defense with the title over it, **CONQUER RIVAL KINGDOMS**, the live conquest, the end card; same transitions and audio. Its clips are a genuine portrait render of the game (the game lays itself out in a 1080×1920 window with its 1920×1080 reference layout and aspect expand), framed 1.8× closer so units keep their landscape size on screen; never a crop or rotation of landscape footage. The game itself stays landscape-only (Orientation, above); portrait exists only for this marketing render.

### 65.5 Store screenshots

From the same scenarios, held on a chosen frame of live play: Phone 1920×1080 landscape: defense (no headline), defense without the screen UI, building, command, conquest and Prestige (each with its trailer caption as an optional headline on a translucent band); 10-inch tablet 2560×1440: defense. Each screenshot keeps its untouched master. The headline of any screenshot can be turned off.

### 65.6 Localization

Only the English copy above is approved. Marketing text is localized per locale from the approved 20-language set only when approved translations exist; the tooling refuses a missing translation rather than falling back to English. Open Sans covers the Latin and Cyrillic locales (14 of 20); Thai, Hindi, Japanese, Korean and both Chinese locales also need separately licensed fonts, and complex-script shaping (Thai, Devanagari) needs Raqm-enabled Pillow.

### 65.7 Approval

The produced screenshots and videos await the developer's visual and audio approval and a playback check on a phone. Nothing is uploaded or published automatically.

## 66. v0.27: the game in 20 languages

Approved by the developer on 2026-10-15 (implementation brief `docs/Claude_Growing_Kingdom_Localization_Marketing_Production_Brief.md`, Phase B). No rule, balance or save-schema change: language is presentation only.

### 66.1 Languages

The approved 20 (Playbook §132): English (United States, the reference and the fallback), Spanish (Latin America), Spanish (Spain), Portuguese (Brazil), French, German, Italian, Dutch, Polish, Russian, Ukrainian, Turkish, Indonesian, Vietnamese, Thai, Hindi, Japanese, Korean, Chinese (Simplified) and Chinese (Traditional). The app's language id (`es-419`, `zh-TW`...) is kept apart from the Godot catalog locale (`es`, `zh_TW`; Godot folds `es_419` into `es`, so the generic Spanish catalog is Latin America's and `es_ES` is Spain's) and from the Play Console locale (the marketing manifest's `aso_handoff.game_to_play_locale`). Both Spanish and both Chinese variants are separate catalogs.

### 66.2 Choosing the language

Settings › Language: **Automatic** (the default) and the 20 languages, each in its own name and script. Automatic follows the device: the best supported language (Chinese by script or region, Spain's Spanish only for Spain, any Portuguese to Brazil's), else English; its button names the language it resolved to. A choice applies at once, without a restart: every open panel, the HUD, the dock, the Train rail, the tutorial and dialogs redraw in the new language, and the simulation, the selection and the camera are untouched. The choice is a setting, not profile state: it is saved with the settings, kept by Prestige and Ascension, and returned to Automatic by Hard Reset. A save without it (every save before v0.27) loads as Automatic.

### 66.3 What is translated, and what is not

Every player-facing string (HUD, panels, cards, dialogs, toasts, tutorial and onboarding, help, missions, results, Prestige and Ascension, names and descriptions, reasons, status lines, the Bestiary) comes from the language's catalog by a semantic key, with named placeholders a translation may reorder, and plural forms by the language's own rules (Russian, Ukrainian and Polish have three). Text is composed when it is shown, never stored: saves keep ids and codes (a Villager's idle status is a code read into words on display; an older save's stored English status is dropped on load and rewritten by the economy at its next decision).

Not translated, on purpose: the brand **Growing Kingdom: RTS**; rival kingdom names, which are place names kept in Latin letters in every language (the descriptive final rival, "The Black Citadel", is translated); compact numbers, which keep the game's own notation in every language (digits, a point, K/M suffixes: `1.9K`), so no calculation or save ever depends on a language.

### 66.4 Fonts

The game keeps its look: Godot's Open Sans SemiBold is the face of every language. Each language carries only the fallbacks its script needs, bundled with the game (never a system font): Noto Sans for any Latin, Cyrillic or Vietnamese letter Open Sans lacks; a small symbols face for the arrows, the warning sign and the info mark; and Noto Sans Devanagari, Thai, JP, KR, SC or TC for Hindi, Thai, Japanese, Korean and the two Chinese (each Han language its own regional face). All are instanced at weight 600 to match SemiBold and subset to the characters the catalogs use (SIL OFL 1.1, `assets/fonts/ui/OFL.txt`). A fallback's line height counts towards every line, so the symbols, CJK and Thai subsets carry the Latin UI line metrics (as Google's own "UI" Noto variants do): a Japanese, Korean, Chinese, Thai or Russian line is as tall as an English one. Devanagari keeps its own (its marks need the room; the HUD still fits). The language selector alone shows every script at once. Godot's text-server data is exported (Thai line breaking, complex shaping on Android).

### 66.5 Layout: English's room, the readable floor

A translation is often longer than English; the layout never makes it unreadable and never lets it overlap:

- **Fixed HUD lines get the room English needs in the same state** (the Wave chip's title and countdown, the idle Villagers line, the Glory chip's purchase line, the Prestige bar): a longer translation steps its type down, never below the readable floor of 22 px. English is laid out exactly as before.
- **Titles and the objective card's goals** shrink to fit their width, down to the floor; English keeps the v0.16 scale.
- **Buttons with a fixed width** shrink, then take a second line inside the same width (Exit Build Mode).
- **Wrapped panel text and lists** wrap and grow as they always did.
- Past the floor, the translation itself is made shorter: the narrow places (the Train rail's 22 px lines, the top band) use each language's compact forms, in the style English already uses there ("NEXT W10"). The rail has its own short form for a missing specialised Monastery.

Every screen shape of the layout probe is checked in all 20 languages.

### 66.6 Validation

`tools/loc_catalog.py check` (every key in all 20 catalogs, placeholders, plural forms); `tests/localization_probe` (catalogs, plurals, glyph coverage of each language's font chain, line height, locale resolution, Automatic, persistence and Hard Reset, the live switch on the real game with panels open, a pre-localization save); `tests/layout_probe` in every language.

### 66.7 Open before release

The translations were produced with the implementation and have not had a native speaker's review; a review of each language (above all Thai, Hindi, Japanese, Korean and both Chinese) is recommended before release, with an on-device check of German, Russian, Hindi, Thai, Japanese and Simplified Chinese.

## 67. v0.27: store media refresh (Marketing Capture Toolkit 1.0.0)

Approved by the developer on 2026-10-15 (the same brief, Phases C to G). Development tooling and media only. This section supersedes §65.2's card structure, §65.4 and §65.5; the rest of §65 stays in force.

### 67.1 Toolkit

The Marketing Capture Toolkit is pinned at **1.0.0** in `Godot-Marketing-Toolkit-1.0.0/` (`marketing_capture_toolkit.lock.json`); that one path is used by `tools/record_trailer.ps1`, the font builder and the docs. The installed addons are the toolkit's, checked by `status` in the probe suite.

### 67.2 Store screenshots

No added text (Playbook §87.9): authentic gameplay with the game's own HUD exactly as it plays (dock, Train rail and top band included). One English-UI set per device class serves every store locale; the English of the native UI is acknowledged, never hidden. Seven subjects in this order, each a chosen frame of a live trailer shot: 01 the Castle holding a wave, 02 a Barracks placed in build mode, 03 Villagers sent to build it, 04 a soldier group commanded, 05 the assault on a rival kingdom, 06 the rival Castle falling, 07 the Prestige offer. Three classes, each a real render at its own size, all landscape 16:9 (Play's screenshot aspect): Phone 1920×1080, 7-inch tablet 2048×1152, 10-inch tablet 2560×1440. Published screenshots are byte-identical copies of the raw masters. No desktop set (Android only).

### 67.3 The 30-second trailer

Same order and approved English as §65.2, made readable (Playbook §133.2): it opens on live defense with no fade-in; **BUILD YOUR KINGDOM**, **COMMAND YOUR ARMY**, **CONQUER RIVAL KINGDOMS** and **PRESTIGE. / REBUILD. GROW STRONGER.** become headline bands over their own live clips, each fully visible for at least 3 s; one final card, **GROWING KINGDOM: RTS** with **BUILD • DEFEND • CONQUER** and the castle art, holds at least 3 s. Clips meet in 0.4 s dips through black; the card fades in through black; the video ends with a 0.6 s fade. 1920×1080, 30 fps, exactly 30.000 s. The game's music from its start under the whole video, fading out over the last 1.2 s.

### 67.4 Social videos

Ten 15-second 1080×1920 masters cut from the trailer's landscape clips and music (the portrait renders of §65.4 are retired): `social_01`–`05` focused reframes (a window of 0.46 of the source width on the action, a blurred copy of the same frame above and below), `social_06`–`10` the whole landscape frame with black bands, text only in the bands. Each sells a different real mechanic (wave defense, a direct command, building, the assault, Prestige; the settlement growing into a defended kingdom, Villagers at work, the army against rival defenses, conquest into Prestige, the whole loop), opens on action, takes its own music in-point and ends on the brand card with a hard end. Copy is only the approved English above; some cuts carry none. One English set; localized variants only when approved copy exists.

### 67.5 Icon and feature graphic

Candidates for review, never adopted silently: a full-bleed 512×512 icon from the existing icon's own pixels (Google Play masks the corners itself; the current icon has its own rounded frame and transparent corners), and 1024×500 feature graphics from real frames without the screen UI, with the approved title and tagline in the left half (clear of the play button Play draws over the centre).

### 67.6 Store listing handoff

The store title, descriptions and their translations are written and approved outside this project (Playbook §134). `marketing/manifest.json` keeps empty slots for them (`aso_handoff`): the English reference fields, the game-to-Play locale map, the 20-locale import file to validate with the toolkit's `play_store_listing.py`, the trailer card keys and the feature graphic's copy.

### 67.7 Music rights

`assets/sounds/background_music.wav` is the game's own track and the developer's chosen soundtrack; the repository holds no licence or provenance record for it. Its rights for public, commercial and social distribution must be confirmed before any media is published.

### 67.8 Approval

All media are review masters awaiting the developer's visual and audio approval and a playback check on a phone. Nothing is uploaded or published automatically.
