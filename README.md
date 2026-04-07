# WILDCORE (Production Campaign Simulation Core)

This repository now contains a feature-complete **headless production simulation core** for WILDCORE's launch scope:

- persistent terrain transformation across a 12-wave campaign
- elemental combo interactions and terrain feedback loops
- adaptive enemy evolution forecasting + counter-trait injection
- node-based run structure (battle, elite, resource, shrine, anomaly, boss)
- three biomes with boss exams tied to playstyle pressure
- commander identity + active core abilities
- run resources (`scrap`, `essence`, `core_charge`, `biome_pressure`) with tradeoffs
- post-run summary payload for shareability and analytics

## Run demo

```bash
python wildcore_game.py
```

## Run tests

```bash
python -m pytest -q
```

## Production architecture notes

See `docs/production_architecture.md`.
