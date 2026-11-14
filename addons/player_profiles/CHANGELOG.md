# Changelog

## 1.0.0 (2026-11-14)

First release. Extracted from the first integration's Phase 1/2 playtest harness and generalized:

- Seven universal, data-driven profiles (`core/profiles.json`, schema `player-profiles.profiles/1`): active, casual,
  idle, beginner, collector, speedrunner, completionist; 16 normalized traits; per-run overrides; profile hash.
- One universal decision engine (`core/decision_engine.gd`): scoring from player-observable option signals, refusal
  classes, savings goals, commitments with hysteresis and a switch limit, cooldowns and caution after failures, bounded
  mistakes that fade with experience, familiarity learning, satiation (no single plan starves the rest), urgent
  interrupts by attention, deterministic ties and its own seeded stream.
- Capability/intent contract `player-profiles.contract/1` (`core/adapter_base.gd`, `core/contract_check.gd`) with
  11 generic intents and explicit unsupported declarations.
- Driver, recorder and session schedule extracted unchanged in behaviour (active/offline/calendar clocks, sessions,
  stops, stalls, budgets, digests). Summary schema `player-profiles.summary/1`.
- Generic runner scene, `tools/player_profiles.py` (manifest, verify, install, status, isolation, blank-project
  self-test, sequential run, generic report with diagnosis).
- Cross-game acceptance test: Farmstead, a non-combat production/building fixture in two capability models.
