# LootFarmer — Change 12: Gameplay Feedback, Audio, Merge All & Gem Chance

**Implementation brief for Claude**  
**Baseline:** Current committed repository after completed Change 11 (gameplay build `7081d18`, followed by tests/docs commit `2684e85`, plus any later committed work). **The live working tree is authoritative.** Do not revert newer commits or copy older ZIP source over it.

## Working principles

Read and follow the **current in-repository Reusable Game Development Playbook** and the latest GDD, catalogs, state contracts, and Change 11 notes **before changes**. In particular, follow the Playbook's **sparse semantic audio (§85)**, combat/VFX authority, fog exploration correctness (§117.9), inspector-editable asset configuration, Android safe-area rules, and **pre-release save policy (§61.1)**.

Implement the **nine requested items** below, with focused investigation only where needed to identify the root cause. Preserve working Change 10–11 systems and existing gameplay balance outside this scope. **Use only existing approved visual/audio assets; do not fabricate new artwork or download substitutes.** Expose asset assignments, tuneable values, and presentation offsets in editor-visible resources/scenes where practical.

No old development-save migration is required. **Current-schema** save/load, prestige, and Hard Reset behavior must remain correct. Preserve developer-owned export/signing/version changes in `export_presets.cfg`, `project.godot`, and unrelated local files; do not run broad destructive clean/restore operations.

## 1. Cyan Robot Heal: verify actual healing, not just VFX

On Android, the Cyan Robot begins its Heal animation/effect, but the player cannot tell that it heals. Check the actual combat event from skill eligibility through target selection, cooldown, authoritative HP change, and VFX.

- Verify whether the skill **actually restores HP** to the intended recipient, and whether it respects maximum HP, cast timing, death/interruption, and cooldown rules.
- Fix any actual simulation/targeting defect. Do not change heal strength merely because a full-HP target cannot gain HP.
- Display a **clear, readable positive healing number** when a nonzero amount is restored, using existing combat text conventions. Align the heal effect with the correct sprite/feet (player or enemy) without detaching it during movement.
- Make visual/audio feedback correspond to an actual successful heal, not a falsely completed skill event. If cast at full HP is allowed by design, avoid implying health increased when it did not.

**Acceptance:** a wounded Cyan Robot visibly gains exactly the expected HP (clamped to max), with correctly placed feedback; heal doesn't become free, duplicated, or trigger while invalid.

## 2. Current-map exploration percentage on gameplay HUD

Show a **compact map completion percentage in the lower-right corner**, e.g. `Map explored: 42%`, within Android safe areas and away from joystick, minimap, enemy HUD, and screen edges.

- Use the **same authoritative permanent exploration cells and authored discoverable-area denominator** as map/exploration progression. Do not count temporary vision, camera panning, raw world bounds, or undiscovered enemy IDs as exploration.
- Handle map switching, resets, complete exploration, and tiny/empty edge cases (no divide-by-zero). Keep the display cheap: update from exploration state changes rather than recomputing the whole map unnecessarily each frame.
- Do not allow the percentage UI to disclose enemy positions or bypass fog/discovery rules.

**Acceptance:** percentage increases as **new cells become permanently explored**, does not increase when only panning or temporarily seeing farther, and matches the World exploration logic.

## 3. Settings text cleanup

Remove player-facing **Settings text that mentions fonts or calls the product a “premium game.”** Keep genuine functioning accessibility, language, and graphics controls; this is a copy/UI cleanup, not authorization to remove useful settings.

**Acceptance:** no unwanted font/premium marketing copy appears in Settings or its help text.

## 4. Working audio controls: Music, Gameplay Sounds, Special Sounds

Audit the **existing audio service, settings persistence, music and supplied sound assets** first. Ensure there is audible, appropriate in-game sound where assets exist; do not just add sliders connected to nothing. Apply Playbook §85: **quiet automation and sparse semantic cues**, not a sound for every repeated hit/kill.

**Settings controls:**

- **Music volume** slider, 0–100% (0 is silent).
- **Sound effects volume** slider, 0–100% (0 mutes both SFX categories).
- Independent **Mute Gameplay Sounds** option: controls normal action/UI/combat/pickup sounds that could repeat during farming.
- Independent **Mute Special Sounds** option: controls important milestones and notifications.
- Gameplay mute **must not suppress** Special Sounds; Special mute **must not suppress** normal gameplay sounds. Both use the SFX volume slider.
- Persist both volumes/mutes through save/load and app restart. Hard Reset follows the existing settings-reset policy; avoid accidental resetting when prestiging.

**Audio service:** route semantic events through one central service, not individual callers choosing assets/volumes; use sensible category priority, throttling/debouncing, and avoid multiple stacked sounds for one state transition. Prefer existing approved assets and editor-assigned sound resources. If the project genuinely lacks a usable music track or SFX for a requested cue, identify that in the report rather than falsely asserting it was implemented or sourcing new art/audio without permission.

## 5. Special sounds for meaningful progress

Create distinct-enough **Special Sound** notifications for:

- Discovery of a new Prestige opportunity.
- **Completing the current step/objective of the Prestige being followed** (e.g. while farming, the required count crosses its threshold). Trigger **once per completed step**, not per kill or every refresh. A completion may advance to the next step immediately; ensure the cue fires at the actual state transition.
- A manually completed mission becoming ready to claim; **do not spam completion sounds** when mission auto-claim is purchased/active and automatically processing repeated missions.
- Other already-authoritative, genuinely important discoveries/unlocks where existing sound conventions warrant it (avoid inventing extra alerts).

This is an **audio** requirement; preserve existing concise visual banners/follower panel and their positioning. Suppress special cues when `Mute Special Sounds` is active; allow them to remain audible when `Mute Gameplay Sounds` alone is active. Use service-level priority/deduplication when several events happen together.

**Acceptance:** followed-Prestige objective emits one noticeable cue at completion even if combat audio is muted; no repeated alert for already-completed objectives, load/reopen, or continuous farming.

## 6. Permanent **Merge All** unlock — 5,000 Gems

Add an explicitly named, **one-time 5,000-Gem `Merge All`** upgrade/unlock in an appropriate existing upgrade surface, with clear description and locked/unlocked state. After purchase, expose a manual **Merge All** button in the relevant inventory UI.

- The button performs all currently eligible merges in a **single deliberate action**, using the same authoritative validity and merge rules as ordinary manual merges. It must not sell items (selling was removed), reroll stats, bypass per-item limits, or duplicate/delete items incorrectly.
- Weapons retain their existing evolution rules; **do not silently trigger unintended evolution to another weapon identity** if evolution is a separate explicit action. Outfits and skills retain their permanent no-evolution duplicate progression. Supplies already have automatic permanent mastery from gained drops, so don't consume their charges or double-count mastery just because Merge All runs.
- Make a no-work state clear (`Nothing to merge`, disabled when appropriate). Avoid huge UI stalls; aggregate output instead of spamming one toast/audio cue per copy.
- Buying this upgrade with Gems makes it **permanent across Prestige**, per Change 11's universal Gem-funded persistence rule. **Hard Reset** removes it; level state saves/reloads correctly. Do not deduct 5,000 Gems again on subsequent uses.
- Check the relationship to existing timed Auto-Merge: this is **manual instant convenience**, not the same purchase or automatic repeating behavior.

**Acceptance:** after unlocking, Merge All processes eligible duplicates correctly and predictably in one tap, has zero Gem charge for use, persists across Prestige, and resets on Hard Reset.

## 7. Metallic axe attack-animation mismatch

The weapon dropped/used by the **Winter I Snowman** has a metallic-looking equipped icon, but the player's attack swing looks like a **black/dark axe**. The user called the weapon “Iron Axe”; do **not assume the tier ID**—verify the actual live drop, shared-weapon identity, artwork, and sprite/animation mapping first.

- Match item icon, equipped weapon sprite, swing/contact animation, and tier/family assets using the **existing approved asset sheets**.
- Fix the player view, inspect the Snowman boss/enemy version, and spot-check the remaining axe tiers for the same mapping/crop/color issue.
- Preserve combat timings, hit range, collision, and the authoritative damage contact; fix **presentation** unless a genuine mapping bug also affects gameplay.
- Use inspector-editable sprite offsets/animation resources where appropriate. No new artwork.

**Acceptance:** the Snowman's metallic axe animates with a visually consistent metallic axe in player hands, and the boss and related tiers don't exhibit an obvious mismatch.

## 8. Recenter camera after Prestige reset

After **performing a Prestige** (not merely opening the Prestige panel), **center/focus on the newly spawned player**, restore player-follow mode, and clear any stale camera drag/pan target or inertia. Preserve the current zoom level.

- This must work even if the camera was previously moved far from the character.
- Apply the reset at the right moment relative to scene/map/player respawn so an old camera state doesn't override it one frame later.
- Do not change the existing joystick-follow and revival-recenter behavior.

**Acceptance:** Prestige finishes with player centered and followed without manual joystick movement; zoom remains as selected.

## 9. Gem drop probability redesign (NOT Gem amount)

Apply the following approved chance rules in the **current live combat/catalog implementation**:

| Source | Required rule |
|---|---|
| Base Gem drop chance | **5%** for normal and boss calculations before bonuses (was 8%) |
| Global **Gem Drop Chance** upgrade | **20 levels maximum**, **+0.5 percentage points per level** (10 points total) |
| Global Gem Chance upgrade **prices** | **DO NOT DISCOUNT**. Preserve the existing cost of levels 1–12 exactly, and extend the existing escalating price pattern sensibly for levels 13–20. Report the eight new prices. |
| **Gem Wisdom** prestige reward | **+5 percentage points** (was +3) |
| Per-enemy kill achievement Gem chance | Keep its existing effect and thresholds (currently understood as up to **+4 percentage points**). Verify against current implementation. |
| **Boss Gem Chance** upgrade | Preserve existing max levels, cost/effect progression (currently understood as **+5 points per level ×8 = +40 points**). |
| Hard game-specific probability cap | Remove the obsolete **20% normal / 60% boss** cap(s) and any hidden earlier truncation that would make upgrades/cards useless. Only universal mathematical `[0%, 100%]` probability clamping is acceptable. |

Expected *fully stacked* maximum if no other contributors exist: **24% normal**, **64% boss** (= 5 base + 10 global + 5 Gem Wisdom + 4 achievements, plus 40 boss bonus). **Audit the real current code** for other modifiers, stacking/rounding/precedence, UI-reported odds and prestige effects; report any actual differences rather than hard-coding these totals as caps.

**Do not change:** Gem drop **amount**, 3× boss Gem **quantity**, boss amount upgrades, Gem-funded upgrade permanence, enemy gear/supply drop chances, coin economy, or unrelated loot rules. Ensure cost previews, maximum-level UI, details and Gem Wisdom descriptions show the new accurate values and **no outdated “normal enemies up to 20%”** language.

**Acceptance:** Gem Wisdom still adds actual probability when the global upgrade is maxed; level 20 gives +10 points; no game-specific 20%/60% ceiling discards earned bonuses; prices for levels 1–12 are unchanged; costs 13–20 are monotone and documented; boss amount stays 3× normal before its own extra amount bonuses.

---

## Delivery workflow (mandatory)

### Phase A — Implementation and early build notification

1. Implement all nine sections. Run only the **minimum compiler/smoke checks needed to avoid a knowingly broken build**; do not start long balance simulations or full regression campaigns yet.
2. Commit gameplay, UI, assets/resource links, catalog and settings changes to Git with a descriptive message. **Commit relevant files only**, respecting developer-owned Android export/version edits and generated Godot files.
3. **Immediately post this notice in chat**, with the actual commit hash:

   **✅ YOU CAN BUILD AND TEST THE GAME NOW.**  
   **Commit: `<actual hash>`**  
   **🧪 GENERATING AND RUNNING THE REMAINING FOCUSED TESTS NOW.**

   Do not wait for the deferred tests before telling the developer they can build; do not stop working after the notice.

### Phase B — Necessary focused regression tests

4. Add/update concise tests for each new behavior: heal actual HP change and effect timing; map percent source/rounding; independent audio categories/settings persistence and exactly-once milestone; Merge All purchase/action/save/Prestige/Hard Reset; correct weapon animation mapping; camera after Prestige; Gem chance and level-1–12 price preservation plus extended costs.
5. Run relevant existing maintained probes **once on the stable result** and a basic desktop/headless smoke check. No excessive pacing bots, repeated mega-campaigns, or speculative optimization. Android visuals/audio must be verified by the developer on device; do not claim a desktop screenshot proves phone-safe layouts or audible cue quality.
6. If deferred tests reveal a gameplay or UI bug, fix it, **commit** the correction, and immediately post a **new build-ready commit hash**; state that earlier APKs are superseded. Tests/docs-only commits do not require a new APK.

### Phase C — Documentation and report

7. Update the GDD, Upgrade Catalog, Prestige Catalog/Gem Wisdom wording, state contracts, localization/source strings, Change 12 notes, and relevant tests. Update the Reusable Playbook **only if a new broadly applicable lesson was learned**; do not turn game-specific balance numbers into generic Playbook rules. Commit final docs/tests.
8. Report concisely: issues fixed, what actual Cyan Robot Heal bug was (if any), how audio categories work and which assets were assigned, Merge All semantics, Gem chance formula/prices 13–20, commits, focused checks, and remaining Android checks. Explicitly state what was **not tested on a phone** and whether any unrelated developer edits are still uncommitted.

**Avoid expanding scope:** do not redesign boss difficulty, outfit curves, supply catalog, map artwork, music composition, or gameplay economy beyond the requirements above.
