# WILDCORE Production Architecture (Foundation)

This repository still runs a **headless simulation** in Python, but the architecture is now aligned with a production migration path.

## Recommended shipping stack

- **Engine**: Godot 4.x (renderer, tooling, cross-platform export, mod-friendly data pipeline)
- **Gameplay core**: deterministic simulation module (initially Python prototype; migrate to C# or Rust GDExtension for ship)
- **Content**: data-driven JSON/YAML/CSV definitions for towers, enemies, biome rules, and combos
- **Build/CI**: GitHub Actions, pytest for simulation correctness, golden-seed run verification
- **Telemetry**: run summaries and adaptation trigger analytics to validate fairness/readability

## Architecture rules

1. Deterministic simulation separated from rendering/UI.
2. Adaptation system must provide lead-time forecasts before full counters are active.
3. Terrain state is a first-class system, not a passive visual effect.
4. Economy must encode tradeoffs (power now vs. adaptation pressure later).
5. Every new system requires tests for readability/fairness hooks.

## Current implementation in this repo

- `wildcore/core.py`: domain models + battlefield + adaptation + hybridization.
- `wildcore/simulation.py`: run loop, resource model, elemental combo resolution.
- `wildcore_game.py`: compatibility facade and CLI entrypoint.
- `tests/test_wildcore.py`: baseline behavior and balance guardrails.

## Next production steps

1. Replace random tile targeting with explicit lane/path model.
2. Implement enemy roster traits and boss exam mechanics.
3. Move tower/enemy definitions to content files and validate schemas.
4. Add deterministic replay serialization (`seed`, player actions, wave outputs).
5. Integrate frontend client (Godot) consuming simulation events.
