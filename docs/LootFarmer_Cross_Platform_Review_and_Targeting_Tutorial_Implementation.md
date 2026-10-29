# LootFarmer — Cross-Platform Review Invitation and Enemy-Targeting Tutorial

**Implementation brief for Claude Code · 28 October 2026**  
**Scope:** One game implementation change, before importing the 19 non-English runtime translations.  
**Repository:** Work in the developer's **current local Git repository**. The ChatGPT project ZIP is reference material, not a replacement for the working Git tree. Discover the next Change number from actual Git history.

## 1. Objective and non-negotiable decisions

Implement two improvements together:

1. A polished, honest **store-aware** review invitation after at least **60 minutes of accumulated active gameplay**, offered **only at a safe moment**. It must work for **Google Play** and **itch.io** using an explicitly identified distribution channel, with a safe extension path for future stores.
2. An explicit lesson explaining **drag from your hero toward an enemy, then release on that enemy to target it**, in **both Basic (card overview/Help) and Guided tutorials**.

Do this **before** the 19-language runtime import. Update the English text catalog with every new string, but do not import, generate, fill, or enable non-English translations in this change.

**Important approved UX decision:** The review invitation appears **immediately like an ordinary game panel**. There is **no 3-second reveal, delayed button, intro screen, animated entrance, or mandatory viewing timer**. Both buttons are present and actionable from the first visible frame. The panel itself must still look excellent and have a prominent call to action.

Do not redesign or change gameplay balance, marketing assets, app icon, trailer, store screenshots, monetization, equipment rules, or the existing tutorial-mode distinctions.

## 2. Actual project architecture to inspect first

The supplied October 28 project snapshot has these relevant surfaces. **Verify against the current repository before editing; do not treat this list as a substitute for inspecting the code.**

- `scripts/game/simulation.gd`: saved `state.playtime_total`; `step(dt)` advances it only during active simulation (currently capped per step); `select_target(id)` returns success and sets the manual/locked target. Existing game state and save integration must be respected.
- `scripts/game/campaign.gd`: `in_combat()` and player health/state. Evaluate additional boss-specific safety conditions.
- `scripts/game/map_gestures.gd`: starts an aiming gesture **only when the drag begins on the player** (`actor_at_screen(..., true)`), draws the aim line, and calls `sim.select_target(target.id)` after releasing on a valid enemy. This is **not** a joystick move or simply dragging anywhere on the map.
- `scripts/game/world.gd`: screen/actor picking, visibility and player screen coordinates.
- `scripts/game/tutorial_guide.gd`: `BASIC_DECK`, Help, `LESSONS`, Guided presenter and centralized suspension/arbitration. Existing Basic cards are short, up-front and skippable; Guided is staged.
- `scripts/game/guided_progress.gd`: persisted ordered action-based tutorial steps and old-save reconciliation; do not introduce a step that strands saved or already-progressed users.
- `scripts/game/game_ui.gd`: sheet, modal, safe-area layout, Back/Escape behavior, tutorial UI priority, and scene/panel state. Reuse the game UI vocabulary and input handling rather than inventing an independent overlay system.
- `scripts/autoload/save_service.gd`: normal save, committed action and hard-reset mechanisms. Do not bypass them.
- `localization/en.po`: English source text. Preserve semantic keys and placeholder validity.
- `docs/Reusable_Game_Development_Playbook.md` (or the current canonical Playbook): especially §§16.3, 18.2–18.8, 20, 44, 60.1, 61, 125.9, 132.2–132.5, and modal/pause/save guidance. Respect existing guidance first.

## 3. Cross-platform review invitation — triggering and safety

### Eligibility

- Become eligible when the player's saved **cumulative active gameplay** reaches **3,600 seconds**. Use the existing playtime accounting/save contract; do not count offline rewards, app background time, loading, a paused game, or time spent inside the review dialog. Inspect how simulation time is measured; avoid counting idle real-world time outside the running game or changing unrelated playtime/stat logic.
- **Eligibility is not permission to pop immediately.** Keep a pending eligible state and offer the panel at the **first suitable quiet moment**. Remaining eligible over sessions must work; saving and reloading must not lose the opportunity or repeat a resolved prompt.
- It must **never appear** during active combat, during any boss fight, while a boss is actively engaging the player, or while the player's current HP is **below 50% of max HP**. Death, respawn, transitions, teleport, stage changes, a pending fight/attack, or an unsafe world state also block it. Prefer a short continuous safe-state confirmation, e.g. roughly two seconds, to avoid a one-frame gap between attacks triggering the panel.
- It must not interrupt the onboarding chooser, Guided lessons/cards, the Basic card deck, other dialogs, Prestige selection/confirmation, offline reward claims, menus/panels, important announcements, or a user-initiated interaction. Use the current centralized UI arbitration; do not bolt unrelated checks on every panel.
- Once actually opened, protect the player from danger: hold/pause gameplay simulation correctly while the decision modal is visible, without causing soft locks, accidental movement, combat damage, save corruption, unwanted clock accumulation or lost audio settings. The modal and buttons must remain responsive.
- Do not interfere with controls or visibility while waiting for a safe moment.

### Presentation

Use an attractive dedicated dialog **consistent with existing game UI**, not an ordinary toast. Use existing approved artwork/Kenney UI resources and the game's typography and palette; strong hierarchy, restrained celebratory accents, excellent contrast and mobile tap targets. Do **not** generate AI artwork or fake a Google rating. Respect safe areas, portrait devices and text expansion.

Suggested English copy (you may polish for layout without changing the meaning):

**Title:** `Enjoying LootFarmer?`  
**Short lead:** `Your adventure is just getting started!`  
**Body:** `Found some great loot? We'd love to hear what you think. An honest review helps us improve LootFarmer and helps other players discover the game.`

**Primary button:** `Review on Google Play` **or** `Review on itch.io` depending on the configured distribution channel (visually prominent).  
**Secondary button:** `Maybe Later` (always available, immediately)

- Invite an **honest** review. Never request **only positive** reviews, offer gems/rewards for reviewing, gate gameplay, preselect a rating, claim that a review was submitted, or pressure users to leave five stars.
- No animated introduction, time-gated buttons, forced timer, fake review-count/rating or repeated nagging.
- System Back/Escape/Android Back must dismiss safely (equivalent to **Maybe Later**, or another predictable documented behavior). Do not strand the player in a blocking overlay.
- Use localization keys for **all** visible text; no embedded English-only messages.

### Distribution-channel routing (required)

The same **review invitation UI, safety/eligibility gate, and persistent response state** must support distinct storefronts. **The operating system is NOT the storefront.** An Android APK can come from either Google Play or itch.io; a desktop build may come from itch.io. Do **not** use an `OS.has_feature("Android")` check, device platform, build type, or package name as a surrogate for store identity.

Use one clear, centralized and testable **distribution-channel configuration** (prefer Godot export feature tags or an equivalent explicit per-export build setting already compatible with the project; do not invent a production web service). Implement the simplest robust option fitting the real repository/export workflow. Every release artifact must explicitly identify its store; preserve normal export/release processes and do not commit secret signing settings.

Approved store destinations, exact URLs:

| Distribution channel | Review button | URL |
|---|---|---|
| `google_play` | `Review on Google Play` | `https://play.google.com/store/apps/details?id=com.shekinahwelefuldesigns.lootfarmeridlerpg` |
| `itch_io` | `Review on itch.io` | `https://shekinawd.itch.io/lootfarmer-idlerpg` |
| unconfigured/unknown/editor/debug | **No automatic review prompt** | No inferred or fallback link |

- Give each release channel an explicit, **verifiable export configuration**, including Google Play Android and itch.io exports on Android and/or desktop where applicable. The same OS may have multiple channel variants; do not accidentally replace the official Google Play bundle configuration with itch.io settings. Do not silently activate the prompt in arbitrary editor runs, test exports, desktop ports, or sideloaded builds without a declared storefront. Provide an intentional test harness/override available only in controlled testing, never as an accidental production fallback.
- Resolve the configured channel **before** showing the invitation. If no valid channel or URL exists, suppress it rather than offering a dead or wrong button. Do not mark the offer consumed simply because the configuration is missing; a later correctly configured build should still be eligible.
- Keep store-specific label and link selection separate from the generic review/persistence system. Future storefronts should require only adding a well-defined channel mapping and export configuration, not duplicating the modal and timer.
- Use the exact above URL for each review action. For itch.io, the action links to the **game page** where players can rate the game; do not claim it opens a dedicated review form or that a review is automatically submitted. For Google Play, link to the official listing; do not assume that opening the listing guarantees a rating/review.
- Use a supported external browser or Android-safe intent / `OS.shell_open` mechanism on each supported platform. Test URL selection and attempt handling. If a launch fails, keep a retry path and provide a concise, localized error; do not falsely record a completed review.
- Make the **CTA store-specific** while keeping the title, honest-review request, panel art, dismiss behavior and all eligibility logic consistent across channels.

### Persistent state and frequency

Persist a small, clear state machine: **not offered / pending eligible / dismissed / opened store** (or an equivalent representation). This is **one automatic invitation per saved player profile, not one per store**. If a profile migrates to another storefront or changes platforms, an already-dismissed/opened invitation must not reappear simply because the channel changed. The offer should appear once, including after `Maybe Later`; **do not automatically nag again**.

If an external-link launch fails, keep the action retryable and communicate the failure instead of claiming success. Preserve state through reloads and Prestige. Follow existing Hard Reset semantics so a genuinely new profile can earn the prompt again after a new hour; don't reset the decision merely because of a normal load or export-channel change. If exposing an optional permanent manual review action in Settings fits existing patterns, keep it unobtrusive, correctly route it to the active channel, and do not confuse it with an automatic reprompt.

The system must not incentivize, gate, demand a positive review, claim a review was completed, or request an app rating before a player can continue. Review invitation copy should be genuinely neutral and localized. The external link action is just **opening the destination**, not proof of a submitted review.

## 4. Enemy-targeting tutorial — authentic gesture

### Exact mechanic to teach

**Touch and hold your HERO, drag toward the ENEMY you want to attack, then release on that enemy.** This follows the existing targeting gesture in `map_gestures.gd`. Do not tell players to drag the joystick, tap an enemy, or drag an enemy; those are different interactions. The target should become selected through the game's actual `select_target` path, not a scripted fake.

Recommended localized English lesson copy:

**Title:** `Target an enemy`  
**Instruction:** `Drag from your hero to an enemy, then release to target it.`  
**Helpful short detail (when space permits):** `You'll focus your attacks on the selected enemy.`

Match existing voice/wording conventions and use semantic English localization keys in `localization/en.po`.

### Basic tutorial (cards)

- Add a **dedicated, short targeting card** near the beginning of `BASIC_DECK` (ideally after the overview, before the gear card). It must also appear within **Help**, which uses that same deck.
- Respect existing Got it / Skip / automatic card expiration semantics. Do not introduce late tips, pointers or gated interaction into Basic mode. Update deck indexing/count and copy naturally.
- Keep `None` tutorial mode unchanged: it does not show tutorial lessons.

### Guided tutorial

- Add a targeting lesson **early in the first combat sequence**—preferably after movement and before the first kill, subject to the actual beginner encounter flow.
- Explain and visually indicate the **start at the player** and **release over an enemy**. Use the existing guidance/pointer system with its current input-pass-through behavior. If an illustration is useful, reuse existing arrows/highlights; never let a guide overlay steal the drag itself.
- Complete the step on a **successful manual target selection through the actual input path**, **not** a timer or an unrelated automatic enemy acquisition. Where necessary, add a tightly scoped successful-target signal/counter that distinguishes manual targeting from ordinary auto-attacks. Do not advance based only on a button tap or a selection attempt that failed.
- Make the step safe and solvable on first-run Winter I: target must be visible, alive and selectable, and remain reachable during the instruction. If enemies die, change target, or the player reloads, the guide must recover; no forced battle/loot changes or soft-lock. Provide a reasonable documented non-blocking escape/recovery path if the interaction is genuinely unavailable due to an edge case.
- Preserve Guided's saved progress on old profiles. Reconcile new step IDs, skips and already-completed first-run tutorials so no existing player is unexpectedly sent back to early lessons. Existing Basic/None players must not be assigned a Guided-only action.
- Tutorial pointer/card remains suppressed behind other panels, modals, Prestige decisions and pause as required by Playbook §18.8.

## 5. Localization sequencing

- **Update only the English source** `localization/en.po` for both features; keep keys meaningful and consistent.
- Ensure the source inventory/catalog generator or existing completeness checks include the new messages and preserve every current identifier, placeholder and escaped symbol.
- **Do not import the earlier 19-language draft ZIP**, enable untranslated languages, or run the 5+5+5+4 import yet. That handoff should happen **after this change is visually approved and the English text is frozen**.
- Keep the game behavior in other disabled locales consistent with existing English fallback.

## 6. Validation and evidence — required

Create a targeted probe/check for **every** relevant case, ideally using the game's real main scene/save mechanics rather than only isolated helper mocks:

**Review prompt:**
1. Under 3,600 active seconds => never shown; exactly eligible => pending; crossed eligibility in combat => stays pending until safe.
2. Active boss fight, HP below 50%, ongoing combat/attack, death/respawn, tutorial, menu/modal, Prestige, offline claim, pause/background => never interrupts.
3. A safe, healthy, idle world state eventually shows the panel once; no accidental combat damage or clock advancement while visible.
4. First frame has complete message and both functional buttons; Back dismisses; clean mobile safe-area layout at phone and tablet sizes.
5. `Maybe Later` persists across save/reload/Prestige **and storefront change** with **no repeated automatic prompt**; Review button opens the **correct channel-specific URL**, without assuming a review was written; link errors are recoverable; Hard Reset has consistent semantics.
6. 60-minute counter excludes background/offline/pause and does not drift or cause regressions in existing guided waits/offline progression.
6a. **Cross-platform matrix:** Google Play Android selects Play URL/CTA; itch.io Android and itch.io desktop select itch.io URL/CTA; unknown/normal editor/debug channel never auto-prompts; two release channels on the **same Android OS** remain distinguishable; missing/invalid config does not consume pending eligibility; moving an already-prompted save between channels does not prompt again; `OS.shell_open` failure is retryable. Check the actual export configurations, not just a mock helper. Include correct mobile and desktop Back/Escape/links as applicable.

**Targeting teaching:**
7. Basic shows the targeting card, Help includes it, Skip/Got it/timer behavior still works, None stays silent.
8. Guided teaches the **actual drag-from-player/release-on-enemy** gesture; a real successful selection advances exactly once; invalid drags, joystick movement and auto-targeting do not falsely complete it.
9. First-run target unavailable/defeated, pause, another panel, reload, old save, completed onboarding and multiple screen sizes do not cause a pointer/input soft-lock.
10. English catalog completeness and placeholder checks pass; layout is legible at small phone sizes, including with longer pseudolocalized strings.

Capture clear visual evidence of the **review panel for both storefront CTAs** and **both tutorial variants** on portrait layouts. Inspect the actual rendered captures, not just a test result. Confirm the review CTA is prominent, the secondary action is legible, and the instructional pointer matches the real gesture.

Run targeted tests during implementation. Run the **entire maintained regression suite once at the end**, after implementation settles, and report any external device limitations honestly. Do not invent passing results.

## 7. Documentation, Playbook and Git

- Update the game-specific GDD/tutorial documentation, English key inventory, test-suite documentation and Change report as warranted.
- **Only after the implementation and checks validate the approach**, add **compact game-independent reusable lessons** to the **canonical Reusable Game Development Playbook**, merged into relevant existing sections (onboarding, modal safety, time eligibility, **distribution-channel-specific store destinations**, honest review requests, localization), not a new project-specific appendix. Document verified rules, no fabricated device/policy confirmations.
- Confirm no unrelated assets or content changed. Do not alter the 19 translation drafts, store assets or current marketing materials.
- Auto-commit **one cohesive next chronological Change** based on actual Git history. Do not push. If the current working tree has unrelated or user-owned untracked files (e.g. the earlier extracted ASO package), leave them alone and don't include them in the commit.

### Final handoff

Report the actual Change number/hash; main files and English keys changed; screenshot/evidence paths; tests (targeted and full); how eligible time and safe state are enforced; how dismiss/store-open persistence works; the **per-export channel configuration** and verified Google Play/itch.io routing for Android and desktop; how a real successful target drag is detected; Playbook sections updated; and anything that still needs physical Android/desktop verification.
