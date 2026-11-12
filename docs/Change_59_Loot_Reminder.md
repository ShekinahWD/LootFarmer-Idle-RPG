# LootFarmer — Change 59: Ground Loot Floating and Pointing-Hand Reminder

**Status:** Approved implementation brief. Implement this **before** the next localization batch. If Change 59 is already used in the actual repository, use the next available Change N consistently in the implementation commit and report it. Do not change game version or save schema merely for this visual change.

## Goal

Ground loot can be overlooked after combat. Make each uncollected drop visibly active and periodically indicate that the player can tap to collect it, without changing underlying drop, pickup, or inventory mechanics.

## Confirmed project assets and code (from provided LootFarmer project snapshot)

- Use the **existing** pointer image, do not generate or replace artwork:
  `res://assets/GUIPackCartoon/Demo/Sprites/Icons/Icons Colored/Other/Hand.png`
  (256×256 source, with alpha margins; size against the visible artwork, not the full texture rectangle).
- Ground-drop scene: `scenes/game/pickup.tscn`
- Ground-drop visual script: `scripts/game/pickup_spark.gd`
- Visual styling: `scripts/game/pickup_style.gd` and `resources/game/pickup_style.tres`
- Drop rendering/visibility: `scripts/game/world.gd`, `$Pickups` and the `pickups` dictionary.
- Current appearance: 0.34 s arrival hop, periodic sparkle and tier-colored ring for equipment; preserve them.
- Current normal loot icon sizes: **16 world pixels** for gear and **14** for supplies. The display is separate from authoritative pickup positions.
- Current pickup state contains `uid`, coordinates and `ttl` (initial 300 s); world input locates collection using the **unchanged** logical drop coordinates and a 14-world-pixel selection radius.
- Follow the relevant Reusable Game Development Playbook principles: 125.4 (presentation-only loot feedback), 18.5 (pointer fingertip positioning / no input blocking / hide under modals), 125.6 (effect/tween lifecycle), 44 (validation and local commit).

## A. Continuous idle float (all ground drops)

1. After each drop's **arrival hop finishes**, its rendered loot icon gently floats up and down around the same base position, indefinitely until collection/despawn.
2. Default amplitude: **about 2–3 world pixels** vertically (small, not a large bob or jump); default full cycle around **1.8 seconds**. Make amplitude/speed editable through the existing `PickupStyle` resource and tune against actual on-phone-scale renders.
3. Smooth oscillation, preferably with a per-drop phase derived from UID so a cluster does not move in lockstep. No random calls affecting simulation.
4. Animate **visual child offset only**, never the Pickup `Node2D` world transform or `sim.state.pickups` coordinates. Tap/Auto-Collect detection and the 14-pixel pickup radius remain unchanged.
5. Keep the tier ring anchored to the real ground location. Preserve the existing sparkle, quantity label and arrival hop; avoid transform/tween conflicts. Do not accidentally add a second bob while arrival is still animating.
6. Existing drops loaded from save or shown after a map switch float immediately, without replaying the arrival hop.

## B. Timed pointing-hand reminder

1. **At 10 seconds of uncollected ground time**, display the provided `Hand.png` pointing to the drop for **3 seconds**, then hide it.
2. Repeat at **20–23 s, 30–33 s, 40–43 s**, etc., while the drop still exists. Before 10 seconds there is no reminder hand.
3. Restrict the hand's **visible rendered dimensions** to **no larger than that drop's displayed loot icon** (gear ≤16 world px; supplies ≤14 world px at default style), taking source transparency/cropping into account. The fingertip should point toward the visible loot icon without covering it. Fit on screen/safe region and use an appropriate side/rotation if needed.
4. **Only one pointer may be visible at a time globally**. With multiple eligible uncollected drops, prefer the **oldest visible, reachable candidate**; break ties deterministically (e.g., UID). This prevents a screen filled with hands. If no candidate is eligible, show none.
5. Do not draw reminders for hidden/unrevealed, off-screen, collected, or expired drops; dismiss instantly when the selected drop disappears or becomes invalid. On map change, re-evaluate rather than leaving a stale hand.
6. Reminders must not consume or intercept pointer/touch events. They are visual only and should not impede manual collection, dragging, targeting, or the joystick.
7. No reminder while the game is paused, suspended, or a blocking modal/tutorial overlay is active. Integrate with the **existing** central UI/overlay ownership rather than introducing independent conflicting guidance. Do not claim a modal is hidden if the current UI cannot actually signal that state.
8. Use existing pausable gameplay time / loot TTL to avoid out-of-sync repeated timers or time continuing during pause. Do not count app background time as active on-screen reminder time. No save-schema addition required.
9. Give the pointer a predictable z-order above the targeted loot but avoid hiding gameplay entities or selection markers. Its own bobbing is optional; **do not** add a large bouncing hand that distracts from the loot.

## C. Boundaries and localization

- Preserve loot availability, world coordinates, lifetime (300 s), drop chance, merge/loot quantity, manual tap, collection radius, auto-collection, sparkle, equipment ring, and landing animation.
- Do not create new gameplay rewards, tutorial steps, tips, popups, labels, translated strings, textures, generated images or user settings for this feature.
- This is an **isolated visual UX batch**, not Localization Batch 03; do not alter already approved localization files, Batch 02 catalogs, the Playbook, GDD, or unrelated game systems.
- Respect existing uncommitted developer edits, including any project/export/version or marketing script changes.

## D. Lightweight validation — strict scope and time limit

This is a **small, presentation-only UX change**. Do **not** create any new automated tests, test scripts, test scenes, probes, test fixtures, or long test reports. Do **not** run the full maintained regression/test suite or start a broad project audit for Change 59.

Perform a **basic visual and functional smoke check**, using the existing game/project tools and a representative loot-drop scenario. **Timebox each validation pass to no more than 10 minutes**. Briefly repeat the same targeted check after making adjustments if needed; the 10-minute limit applies **per pass**, not to implementation time.

Check only the essentials:

1. The existing arrival effect still looks correct, and uncollected loot gently floats in place without moving its logical pickup position.
2. A single hand appears at about **10 s**, stays for about **3 s**, hides, and appears again around **20 s** while the drop remains uncollected.
3. The hand is **not larger than the loot icon** and points visibly at it. With multiple drops, **only one hand** appears, preferring the oldest eligible visible drop.
4. Tapping the drop still collects it; the hand disappears immediately. Auto-Collect and ordinary loot collection still behave normally.
5. A quick sanity check confirms the hand is absent during pause/blocking UI and does not remain after the drop disappears.
6. Visually inspect the effect at **432×960** and **540×960**. Reuse existing preview/render tools where available; no screenshot-evidence suite or exhaustive device matrix is required.

If a short check reveals a problem, correct it and repeat the **focused smoke pass**. Do not expand into comprehensive testing unless an actual functional regression warrants investigation; report that separately rather than silently initiating a long suite. Physical Android acceptance remains with the developer.

## Delivery

- Implement only the necessary scene/script/style changes; **do not add or modify test files** for this batch.
- Use existing assets, no image generation. Keep visual values configurable in the `PickupStyle` inspector resource.
- After the short smoke check, review `git status`, diff and staged paths to avoid unrelated/uncommitted changes; create **one local** `feat(change-59): add subtle loot float and pickup reminder` commit (or use the next unallocated number if 59 is already used).
- Do **not** push, publish, or start the next localization batch. Report touched paths, brief smoke-check results, commit hash, version and remaining physical-device checks. Do not claim full regression coverage.
