"""Backwards-compatible facade for the WILDCORE simulation package."""

from wildcore import (
    AdaptationDirector,
    AdaptationForecast,
    Battlefield,
    Biome,
    Commander,
    Enemy,
    Faction,
    Game,
    HybridizationEngine,
    NodeType,
    RunNode,
    RunReport,
    RunResources,
    TerrainState,
    Tile,
    Tower,
    WaveMetrics,
    run_demo,
)

__all__ = [
    "AdaptationDirector",
    "AdaptationForecast",
    "Battlefield",
    "Biome",
    "Commander",
    "Enemy",
    "Faction",
    "Game",
    "HybridizationEngine",
    "NodeType",
    "RunNode",
    "RunReport",
    "RunResources",
    "TerrainState",
    "Tile",
    "Tower",
    "WaveMetrics",
    "run_demo",
]


if __name__ == "__main__":
    run_demo()
