# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

WILDCORE is a tower-defense game with a headless Python simulation core. The codebase is a feature-complete campaign simulation — no rendering, no external dependencies, pure game logic designed for eventual Godot 4.x client integration.

## Commands

```bash
# Run demo simulation
python wildcore_game.py

# Run all tests
python -m pytest -q

# Run a single test
python -m pytest tests/test_wildcore.py::test_adaptation_forecast_after_three_waves -q
```

No external dependencies beyond Python 3 stdlib and pytest.

## Architecture

Two-module core with a facade entry point:

- **`wildcore/core.py`** — Fundamental game systems: battlefield grid (8x5 tiles), towers, enemies, terrain state machine, elemental combos, adaptation director (enemy counter-system), and hybridization engine (cross-faction build penalties).
- **`wildcore/simulation.py`** — Campaign orchestrator: 12-wave runs across 3 biomes (4 waves each), node-based progression, commander abilities, resource economy (scrap/essence/core_charge/biome_pressure), boss encounters, run summary generation.
- **`wildcore/__init__.py`** — Re-exports all public classes.
- **`wildcore_game.py`** — Backwards-compatible CLI facade; re-exports package contents and runs demo on `__main__`.

### Key Design Patterns

- **Deterministic simulation**: All randomness flows through `Random(seed)` on the `Game` instance (`game.rng`). Runs are fully reproducible for testing and daily challenge seeds.
- **Terrain feedback loop**: Towers emit terrain auras that persist across waves, affecting future tower placement and combo triggers.
- **Adaptation fairness**: The `AdaptationDirector` uses a 3-wave rolling window with cooldowns, lead-time telegraphs, and integrity floors to keep enemy counters fair and transparent.
- **Story moment capture**: Emergent events (combos, adaptations, ability activations) are logged to `story_moments` for post-run summaries.

## Design Constraints

All new towers, biomes, commanders, or game modes must pass the **Core Fun Gate** (see `DESIGN.md`) before implementation. Key criteria: terrain transforms decisions every wave, adaptation feels fair, 3+ readable elemental interactions, and runs produce a story moment within 20-30 minutes.

Hybrid builds follow balance rules in `HYBRIDIZATION_RULES.md`: resource tax, slot tax, tempo tax, and adaptation acceleration for cross-faction volatility.

VFX/UI must follow `READABILITY_SPEC.md`: color ownership rules, max simultaneous effects, priority layering order.
