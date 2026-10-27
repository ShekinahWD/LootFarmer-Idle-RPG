# LootFarmer Change 21 — phone-test corrections

## Baseline and installation

This patch starts from the exact last delivered `LootFarmer_Change_20_Complete_Changed_Files.zip`: every file in that ZIP matched the working project before edits. It does not use the older 04:26 source archive. No commits were made.

Extract the patch directly into the existing Change 20 project folder, overwriting the matching project-relative paths. Open/import the project in Godot 4.7.2, then rebuild and install the Android app. This is a source patch, not an APK. Application and Android version code are now 21; save schema remains 8. Existing player progress is retained.

## Complete requested batch

| Request | Delivered behavior |
|---|---|
| Missions take too long after merging | Delay reduced to **60 active gameplay seconds**, persisted through reloads. Paused/offline time does not count. The subsequent upgrade delay stays 60 seconds. |
| Auto-merge toggle before purchase | Hidden until an applicable enemy's Auto-Merge is owned. Turning an item off does not hide the re-enable control. |
| Claim grows with mission card | Claim has a compact 64-reference-pixel minimum height and vertical center alignment; card text no longer stretches it. |
| Gear and Supplies alignment | Heading centers and first slot rows align for every zoom setting. |
| Supply slots waste horizontal space | Independent supply sizing: Small = 3 columns, Medium = 2, Large = 1. Empty slots follow the same grid. |
| Six total supply slots | One initial slot plus five purchases. The sixth costs 20 Gems under the existing +4-Gem progression. Existing saves with four purchases still have five slots and can buy the final slot. |
| Visible supply capacity by size | Small shows six slots in two rows, Medium four in two rows, Large one; overflow remains scrollable and panel height stays fixed across zoom. There are still five supply identities; this change adds capacity, not a sixth supply type. |
| Farming instruction wording | “Build strength and gather Coins before moving on.” |
| Close arrow after expansion | A saved `close_inventory` step points at the actual Close control after buying expansion. Potion teaching waits for closure. Saves already past the potion purchase skip the inserted step. |
| Visible scrollbars | Missions, Mastery, Filters, Prestige and Upgrades use a contrasting visible thumb whenever content overflows. Swipe scrolling remains available. Existing theme assets are reused. |
| Boss-farming message readability | Larger text, warm high-contrast color, padding, wrapped height and separation from Next Stage. |
| Pixelated Respawn text | Countdown shows only seconds (e.g. `55s`), rendered from a larger font with linear filtering at half scale. |
| Follow panels block view | Mission and Prestige trackers stack upward just above the joystick, with a gap and no joystick overlap. |
| Prestige sections | Relevant unlocked stage headings show discovered/total opportunities. Undiscovered opportunity details remain hidden. Multi-stage objectives appear under every relevant unlocked stage. |
| General Prestige objectives | The user-selected **General** section contains offline, mission, merging, arsenal and offering objectives. Owned Cards and Card Sets follow. Counters count opportunities, not owned reward cards. |
| Travel from opened map | Owned camps show regardless of Map Details rank; tap-release travels through the existing shared travel action. Dragging does not travel; combat/death/action locks remain enforced. Camp-list Travel buttons remain. |
| Larger camp icons | Expanded-map camp icons double to 24 reference pixels and use cropped art; 64-pixel-diameter selection area. The separate destination picker also doubles its icons and enlarges hit areas. |

## Validation

See `Change_21_Evidence/suite_summary.txt` and `final_targeted_summary.txt`. The full maintained suite ran once. Four tests initially exposed outdated placement/capacity assumptions and an inventory fixture tapping before layout settled; the affected tests were corrected and rerun. The final combined result is recorded in the test-suite document.

The dedicated Change 21 probe covers real upgrade purchases, capacity limits, save/restore, auto-merge visibility and re-enabling, supply column/row geometry and fixed panel height, compact Claim layout, all five scrollable panels, Prestige grouping, expanded-map touch/drag/combat behavior, and the actual tutorial Close-arrow target.

Rendered captures in `Change_21_Evidence/ui/` use a 540×960 desktop viewport. They cover all supply sizes, scrollbars, mission Claim, Prestige grouping, map travel, followers, objective and countdown. These are desktop renders, **not physical Android validation**. The renderer reports unsupported V-Sync and shutdown resource warnings; they are retained in `render.log`.

## Phone acceptance

Check the three slot sizes, swipe all five panels, buy the sixth supply slot, complete the expansion Close lesson, tap a map camp outside combat, and verify countdown legibility at your preferred camera zoom. Confirm both followers remain just above the joystick. No balance benchmark or Play Store submission is included in this correction batch.
