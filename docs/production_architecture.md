# WILDCORE Production Architecture

## Current state in this repository

The codebase now provides a **feature-complete headless simulation core** for launch scope validation.

### Implemented systems

- Deterministic run orchestration via seeded RNG.
- Terrain transformation with persistent tile-state mutation.
- Elemental combo interactions that alter terrain and damage output.
- Adaptive enemy evolution forecasting with lead-time + cooldown fairness.
- Counter-trait injection to represent enemy adaptation response.
- Hybridization pressure model with tax + adaptation acceleration.
- Commander identities and active core abilities.
- Node-based campaign structure across 3 biomes.
- Elite and boss pressure spikes tied to strategic over-reliance.
- Run economy and risk model (`scrap`, `essence`, `core_charge`, `biome_pressure`).
- Run summary for analytics/share surfaces.

## Recommended shipping stack

- **Client/Renderer**: Godot 4.x
- **Gameplay simulation**: module parity with this core (C# or Rust GDExtension)
- **Content**: data-driven schemas for towers/enemies/relics/biomes
- **Testing/CI**: pytest + golden seeds + run summary assertions

## Next integration tasks (engine side)

1. Hook simulation events into visual/audio timeline channels.
2. Implement path preview UX and evolution warning UI widgets.
3. Add content loaders for towers/enemies/relics from authored data files.
4. Serialize complete run replay packets for debugging and daily challenge seeds.
5. Integrate profile progression storage around unlocked options (not mandatory power).
