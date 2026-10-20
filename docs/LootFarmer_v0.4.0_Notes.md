# LootFarmer v0.4.0 — world and inspectors

Apply this changed-files ZIP over v0.3.3. Extract directly into the project folder and overwrite. Saves remain schema 1; no reset is required. Let Godot reimport the font (its .import settings enable MSDF).

## Controls and layout

- Tap the player for general upgrades, split into Automation, Inventory and Supplies. The bottom Upgrades button is removed. Stats remain accessible through the existing Stats button.
- Tap an enemy for its group portrait and Overview / Upgrades tabs. Stats and drop identities/chances begin as ???. Reveal Stats and Reveal Drops are separate one-time purchases for each group and survive prestige. Prices are 25/40 coins for Sprouts, 50/80 for Robots, 75/120 for Dinosaurs, and 100/160 for Death. These prices are initial delegated tuning.
- World keeps fallback access to player/group panels when actors are dead or off-screen. Summoned cats have no drops or group upgrade purchases.
- Tap an owned camp to select its respawn point immediately. Tap a locked camp to open its unlock panel; purchasing there unlocks AND selects it. Selection never teleports or heals the player. The selected camp has a gold label, explicit Selected status and an additional marker; locked shrines are dimmed. Camps still reset on prestige.
- Recent-find notifications are top-left, joystick bottom-center. Dragging, pinching, zoom slider and joystick-to-follow remain functional. Tap release selects objects; a nearby loot target takes priority. Drag/pinch never opens an inspector or collects loot.

## Balance

Equipment base probabilities: Sprout 10%, Robot 9%, Dinosaur 8%, Death 30%. A successful roll chooses equally between the group's two items. Gear-chance upgrades still add TWO percentage points per level, with the existing 50% effective ceiling and prestige multiplier. Purchase buttons stop once the effective probability is capped. Gems, coins and supply probabilities are unchanged.

Existing merge/evolution and outfit-role systems are retained; no new crafting currency or mandatory low-tier recipe is introduced. Information unlocks survive prestige, while ordinary per-group farming upgrades reset. Hard reset clears everything normally.

## Map and rendering

The map uses editable TileMapLayers: textured ground, bordered roads, woodland, stone courts and ponds. Clearings align with the existing enemy groups and save coordinates. Fountain-and-bench camp shrines provide recognizable landmarks using supplied Pixel Plains assets. Large scenery stays outside the movement strip; small flowers/rocks are ground decoration, not collision obstacles. Decorated terrain extends far beyond legal camera centers for zoomed-out/tall views. This remains one open map; no boss-gated sections were added.

The deterministic authoring utility is tools/build_map.gd. It bakes world.tscn once, not at runtime. Editing the scene directly is supported; regenerating intentionally overwrites that scene. Original art is unchanged. World labels and actor floating text use linear texture filtering with the shared MSDF font; sprites retain nearest-neighbor filtering.

## Verification

Godot 4.5.1 compatibility runtime: 52 gameplay checks, 24 UI checks, 17 camera gesture checks, 32 inspector/layout/save checks; bootstrap save/reset probe passed. The project still declares its existing Godot 4.7 baseline.

Map_Layout.png is an offline composition of the actual baked map tiles/props for layout inspection, NOT a gameplay screenshot. The virtual display used in earlier turns was unavailable, and its dependencies could not be restored through the current network. Full rendered UI/font verification and Android touch review remain pending. Layout geometry and font settings were checked in Godot; no claim of device or GPU visual acceptance is made.

Signing remains deferred as requested.
