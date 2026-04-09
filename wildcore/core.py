from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, List, Optional, Tuple


class Faction(str, Enum):
    WILD_GROWTH = "Wild Growth"
    IRON_DOMINION = "Iron Dominion"
    VOID_BLOOM = "Void Bloom"


class TerrainState(str, Enum):
    NATURAL = "natural"
    SCORCHED = "scorched"
    FROZEN = "frozen"
    FLOODED = "flooded"
    CORRUPTED = "corrupted"
    OVERGROWN = "overgrown"
    CRATERED = "cratered"
    INDUSTRIAL = "industrialized"
    ELECTRIFIED = "electrified"
    UNSTABLE = "unstable"


@dataclass
class Tile:
    x: int
    y: int
    state: TerrainState = TerrainState.NATURAL
    movement_modifier: float = 1.0
    blocked: bool = False


@dataclass
class Tower:
    name: str
    faction: Faction
    role: str
    element: str
    base_damage: float
    range: int
    terrain_aura: Optional[TerrainState] = None


@dataclass
class Enemy:
    name: str
    hp: float
    speed: float
    traits: List[str] = field(default_factory=list)


@dataclass
class WaveMetrics:
    burn_share: float = 0.0
    slow_dilation: float = 0.0
    path_extension: float = 0.0
    early_kill_share: float = 0.0
    corruption_stacks: float = 0.0
    corruption_kill_share: float = 0.0


@dataclass
class AdaptationForecast:
    signal: str
    family: str
    eta_partial: int
    eta_full: int
    explanation: Dict[str, str]


class Battlefield:
    def __init__(self, width: int = 8, height: int = 5):
        self.width = width
        self.height = height
        self.tiles: Dict[Tuple[int, int], Tile] = {
            (x, y): Tile(x, y) for y in range(height) for x in range(width)
        }

    def apply_transformation(self, positions: List[Tuple[int, int]], state: TerrainState) -> None:
        for pos in positions:
            if pos not in self.tiles:
                continue
            tile = self.tiles[pos]
            tile.state = state
            tile.movement_modifier = self._movement_modifier_for(state)

    def _movement_modifier_for(self, state: TerrainState) -> float:
        if state in {TerrainState.OVERGROWN, TerrainState.CRATERED}:
            return 1.35
        if state in {TerrainState.FLOODED, TerrainState.CORRUPTED, TerrainState.INDUSTRIAL}:
            return 1.15
        if state == TerrainState.FROZEN:
            return 0.90
        if state == TerrainState.ELECTRIFIED:
            return 1.20
        return 1.0

    def score_transformation(self) -> int:
        return sum(1 for tile in self.tiles.values() if tile.state != TerrainState.NATURAL)

    def transformed_ratio(self) -> float:
        return self.score_transformation() / (self.width * self.height)

    def snapshot(self) -> List[str]:
        glyph = {
            TerrainState.NATURAL: ".",
            TerrainState.SCORCHED: "F",
            TerrainState.FROZEN: "I",
            TerrainState.FLOODED: "W",
            TerrainState.CORRUPTED: "C",
            TerrainState.OVERGROWN: "G",
            TerrainState.CRATERED: "R",
            TerrainState.INDUSTRIAL: "M",
            TerrainState.ELECTRIFIED: "E",
            TerrainState.UNSTABLE: "U",
        }
        rows = []
        for y in range(self.height):
            rows.append("".join(glyph[self.tiles[(x, y)].state] for x in range(self.width)))
        return rows


class AdaptationDirector:
    """Counter-system with lead-time and cooldowns for fairness."""

    def __init__(self) -> None:
        self.window: List[WaveMetrics] = []
        self.cooldowns: Dict[str, int] = {}

    def ingest(self, metrics: WaveMetrics) -> None:
        self.window.append(metrics)
        if len(self.window) > 3:
            self.window.pop(0)
        for key in list(self.cooldowns):
            self.cooldowns[key] = max(0, self.cooldowns[key] - 1)

    def forecast(self, wave: int, player_integrity: float) -> Optional[AdaptationForecast]:
        if wave % 3 != 0 or len(self.window) < 3:
            return None
        if player_integrity < 0.35:
            return None

        avg = WaveMetrics(
            burn_share=sum(w.burn_share for w in self.window) / 3,
            slow_dilation=sum(w.slow_dilation for w in self.window) / 3,
            path_extension=sum(w.path_extension for w in self.window) / 3,
            early_kill_share=sum(w.early_kill_share for w in self.window) / 3,
            corruption_stacks=sum(w.corruption_stacks for w in self.window) / 3,
            corruption_kill_share=sum(w.corruption_kill_share for w in self.window) / 3,
        )

        scores = {
            "Burn": min(1.0, avg.burn_share / 0.60),
            "Control": min(1.0, avg.slow_dilation / 0.50),
            "Maze": min(1.0, avg.path_extension / 0.50),
            "Burst": min(1.0, avg.early_kill_share / 0.70),
            "Corruption": min(1.0, ((avg.corruption_stacks / 12.0) + (avg.corruption_kill_share / 0.55)) / 2),
        }
        dominant = max(scores, key=scores.get)
        if scores[dominant] < 0.75 or self.cooldowns.get(dominant, 0) > 0:
            return None

        family = {
            "Burn": "Fireproof",
            "Control": "Unstoppable",
            "Maze": "Pathfinder",
            "Burst": "Bulwark",
            "Corruption": "Purgeblood",
        }[dominant]

        self.cooldowns[dominant] = 3
        return AdaptationForecast(
            signal=dominant,
            family=family,
            eta_partial=wave + 1,
            eta_full=wave + 2,
            explanation={
                "Burn": f"Burn damage share: {avg.burn_share:.0%} (trigger 45%)",
                "Control": f"Slow dilation: {avg.slow_dilation:.0%} (trigger 35%)",
                "Maze": f"Path extension: {avg.path_extension:.0%} (trigger 30%)",
                "Burst": f"Early kill share: {avg.early_kill_share:.0%} (trigger 55%)",
                "Corruption": (
                    f"Corruption pressure: {avg.corruption_stacks:.1f} stacks / "
                    f"{avg.corruption_kill_share:.0%} kill-share"
                ),
            },
        )


class HybridizationEngine:
    def __init__(self, primary: Faction, picks: List[Faction]):
        self.primary = primary
        self.picks = picks

    def evaluate(self) -> Dict[str, float]:
        off = [pick for pick in self.picks if pick != self.primary]
        n = len(off)
        tax = 0
        if n > 3:
            tax += min(3, n - 3) * 1
        if n > 6:
            tax += (n - 6) * 2

        integration_slots = 3 if n >= 10 else 2
        volatility = max(0, n - 3)

        adaptation_acceleration = 1.0
        if 4 <= volatility <= 6:
            adaptation_acceleration = 1.2
        elif 7 <= volatility <= 9:
            adaptation_acceleration = 1.35
        elif volatility >= 10:
            adaptation_acceleration = 1.5

        return {
            "off_faction_picks": n,
            "resource_tax": tax,
            "integration_slots": integration_slots,
            "volatility": volatility,
            "adaptation_acceleration": adaptation_acceleration,
        }
