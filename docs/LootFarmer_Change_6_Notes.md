# Change 6 — full-game review and implementation

Baseline: the existing working tree, in which the separately delivered Change 5 corrections were already applied (all 67 files byte-identical to LootFarmer-5-corrections-changed-files.zip). The older lootFarmer(7).zip was not applied.

## What changed for the player

- **Opening and layout:** on every stage the weakest enemy type is nearest the arrival camp and bosses are farthest, each in its existing landmark arena (moved with its court). Spots are spaced so idle farming never pulls a neighbouring spot or type; camps sit outside every spot's reach.
- **First boss:** the Snowman is now a far, signposted encounter needing roughly level 10–14 and merged gear (bot: 15–29 min) instead of falling at level 2 in one minute.
- **Prestige:** a reset requires clearing Winter in the current run (bot: fastest completed first-run route 76.3 min, ordinary 92–113; before, about 15 minutes or a day away after one minute of play). Cards are worth 10–30% in their own outcome instead of 1–5%, every path has distinct effects, and choices are real visual cards with a keep/reset summary. Discovery, completion, each card and the reset get a short celebration and a persistent Prestige badge.
- **Guidance:** the guided tutorial points with an owned arrow at the next real control across the HUD and panels (World → Unlock for the camp lesson), asks for an attainable step when coins or discovery are missing, never points at hidden places and hides itself whenever another menu, confirmation, pause or celebration is up.
- **Panels:** sized to their content and anchored above the HUD with actions pinned in one place; item details compare against the equipped item and browse with ◀ ▶; navigation is World, Missions, Prestige, Stats and Settings with badges; upgrades opened from the character.
- **Readability:** toasts, recent finds, tutorial cards and the banner sit on a dark backing; floating numbers and labels are outlined and carry meaning by sign and glyph.
- **Recovery:** slow recovery anywhere out of combat and fast resting beside your camps; Heal 10 HP; potions have a 5 s cooldown.
- **Performance:** the Upgrades panel no longer rebuilds its controls on every kill (about 77–82 ms per refresh before); enemy definitions are cached instead of deep-copied every physics tick.

## Fixed defects found during the review

Regional mastery accepted ~22.5% exploration as 90%; new profiles hard-coded fog layout revision 1; the prestige batch lock disabled the Keep button; five upgrade labels stated the wrong effect; two cards shared one effect; opportunity texts showed raw ids.
