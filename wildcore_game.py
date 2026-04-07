from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
import random
from typing import Dict, List, Tuple, Optional


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


class Biome(str, Enum):
    VERDANT_BASIN = "Verdant Basin"
    IRON_SCAR = "Iron Scar"
    HOLLOW_VEIL = "Hollow Veil"


@dataclass
class Tile:
    x: int
    y: int
    state: TerrainState = TerrainState.NATURAL
    slow: float = 1.0
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


@dataclass
class Commander:
    name: str
    faction: Faction
    passive: str
    core_ability: str


class Battlefield:
    def __init__(self, width: int = 8, height: int = 5, biome: Biome = Biome.VERDANT_BASIN):
        self.width = width
        self.height = height
        self.biome = biome
        self.tiles: Dict[Tuple[int, int], Tile] = {
            (x, y): Tile(x, y) for y in range(height) for x in range(width)
        }
        self._seed_biome_features()

    def _seed_biome_features(self) -> None:
        if self.biome == Biome.VERDANT_BASIN:
            river_y = self.height // 2
            self.apply_transformation([(x, river_y) for x in range(self.width)], TerrainState.FLOODED)
        elif self.biome == Biome.IRON_SCAR:
            self.apply_transformation([(x, 0) for x in range(self.width)], TerrainState.INDUSTRIAL)
            self.apply_transformation([(x, self.height - 1) for x in range(self.width)], TerrainState.CRATERED)
        elif self.biome == Biome.HOLLOW_VEIL:
            center = [(self.width // 2, self.height // 2), (self.width // 2 - 1, self.height // 2)]
            self.apply_transformation(center, TerrainState.CORRUPTED)

    def apply_transformation(self, positions: List[Tuple[int, int]], state: TerrainState) -> None:
        for pos in positions:
            if pos not in self.tiles:
                continue
            t = self.tiles[pos]
            t.state = state
            if state in {TerrainState.OVERGROWN, TerrainState.CRATERED}:
                t.slow = 1.35
            elif state in {TerrainState.FLOODED, TerrainState.CORRUPTED}:
                t.slow = 1.15
            elif state == TerrainState.FROZEN:
                t.slow = 0.9
            else:
                t.slow = 1.0

    def score_transformation(self) -> int:
        return sum(1 for tile in self.tiles.values() if tile.state != TerrainState.NATURAL)

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
                "Corruption": f"Corruption stacks: {avg.corruption_stacks:.1f} (trigger 8)",
            },
        )


class HybridizationEngine:
    def __init__(self, primary: Faction, picks: List[Faction]):
        self.primary = primary
        self.picks = picks

    def evaluate(self) -> Dict[str, float]:
        off = [p for p in self.picks if p != self.primary]
        n = len(off)
        tax = 0
        if n > 3:
            tax += min(3, n - 3) * 1
        if n > 6:
            tax += (n - 6) * 2

        integration_slots = 3 if n >= 10 else 2
        volatility = max(0, n - 3)
        aam = 1.0
        if 4 <= volatility <= 6:
            aam = 1.2
        elif 7 <= volatility <= 9:
            aam = 1.35
        elif volatility >= 10:
            aam = 1.5

        return {
            "off_faction_picks": n,
            "resource_tax": tax,
            "integration_slots": integration_slots,
            "volatility": volatility,
            "adaptation_acceleration": aam,
        }


class Game:
    def __init__(
        self,
        seed: int = 7,
        biome: Biome = Biome.VERDANT_BASIN,
        commander: Optional[Commander] = None,
    ):
        random.seed(seed)
        self.field = Battlefield(biome=biome)
        self.adaptation = AdaptationDirector()
        self.integrity = 1.0
        self.wave = 0
        self.towers = self._default_towers()
        self.story_moments: List[str] = []
        self.commander = commander or self._default_commander()
        self.evolutions_faced: List[str] = []
        self.element_usage: Dict[str, int] = {}

    def _default_commander(self) -> Commander:
        commanders = [
            Commander("The Warden", Faction.WILD_GROWTH, "Roots slow enemies longer", "Overgrow a target lane tile"),
            Commander("The Foreman", Faction.IRON_DOMINION, "Gain extra scrap from kills", "Ignite all oil terrain"),
            Commander("The Seer", Faction.VOID_BLOOM, "Corruption stacks decay slower", "Pulse corruption in an area"),
        ]
        return random.choice(commanders)

    @staticmethod
    def _default_towers() -> List[Tower]:
        return [
            Tower("Thorn Nest", Faction.WILD_GROWTH, "DPS", "growth", 11, 2, TerrainState.OVERGROWN),
            Tower("Root Spire", Faction.WILD_GROWTH, "Control", "growth", 8, 2, TerrainState.OVERGROWN),
            Tower("Bloom Shrine", Faction.WILD_GROWTH, "Support", "growth", 0, 2, TerrainState.OVERGROWN),
            Tower("Spore Pod", Faction.WILD_GROWTH, "AoE", "poison", 10, 2, TerrainState.CORRUPTED),
            Tower("Greatbark Sentinel", Faction.WILD_GROWTH, "Anchor", "growth", 20, 2, TerrainState.OVERGROWN),
            Tower("Rivet Gun", Faction.IRON_DOMINION, "DPS", "kinetic", 12, 3, TerrainState.INDUSTRIAL),
            Tower("Mortar Foundry", Faction.IRON_DOMINION, "AoE", "explosive", 18, 4, TerrainState.CRATERED),
            Tower("Oil Extractor", Faction.IRON_DOMINION, "Economy", "oil", 0, 1, TerrainState.FLOODED),
            Tower("Arc Furnace", Faction.IRON_DOMINION, "Aura", "fire", 14, 2, TerrainState.SCORCHED),
            Tower("Rail Cannon", Faction.IRON_DOMINION, "Finisher", "kinetic", 25, 5, TerrainState.INDUSTRIAL),
            Tower("Hex Obelisk", Faction.VOID_BLOOM, "Support", "corruption", 9, 3, TerrainState.CORRUPTED),
            Tower("Rift Lantern", Faction.VOID_BLOOM, "Chain", "lightning", 13, 3, TerrainState.UNSTABLE),
            Tower("Plague Vessel", Faction.VOID_BLOOM, "AoE", "poison", 12, 2, TerrainState.CORRUPTED),
            Tower("Entropy Coil", Faction.VOID_BLOOM, "Volatile", "arcane", 16, 3, TerrainState.UNSTABLE),
            Tower("Abyss Seed", Faction.VOID_BLOOM, "Late", "corruption", 30, 2, TerrainState.CORRUPTED),
        ]

    def _elemental_combo(self, tower: Tower, affected: List[Tuple[int, int]]) -> float:
        bonus = 1.0
        for pos in affected:
            state = self.field.tiles[pos].state
            if tower.element == "lightning" and state == TerrainState.FLOODED:
                bonus += 0.5
                self.field.apply_transformation([pos], TerrainState.ELECTRIFIED)
            if tower.element == "fire" and state == TerrainState.FLOODED:
                bonus += 0.4
                self.field.apply_transformation([pos], TerrainState.SCORCHED)
            if tower.element == "explosive" and state == TerrainState.FROZEN:
                bonus += 0.6
                self.field.apply_transformation([pos], TerrainState.CRATERED)
            if tower.element == "poison" and state == TerrainState.CORRUPTED:
                bonus += 0.35
        return bonus

    def _apply_tower_effect(self, tower: Tower) -> float:
        x = random.randint(1, self.field.width - 2)
        y = random.randint(0, self.field.height - 1)
        affected = [(x, y)]
        if tower.terrain_aura:
            self.field.apply_transformation(affected, tower.terrain_aura)
        self.element_usage[tower.element] = self.element_usage.get(tower.element, 0) + 1
        return tower.base_damage * self._elemental_combo(tower, affected)

    def _mitigation_choice(self, forecast: AdaptationForecast) -> str:
        options = {
            "Burn": "Install heat shred rounds: reduce enemy fire resistance by 15%.",
            "Control": "Take momentum breaker: next slows ignore first immunity layer.",
            "Maze": "Deploy seismic anchors: +20% damage on path-skipping enemies.",
            "Burst": "Convert alpha package: +12% sustained damage over route length.",
            "Corruption": "Add detonation catalyst: corruption stacks can burst for direct damage.",
        }
        return options[forecast.signal]

    def run_wave(self) -> Dict[str, object]:
        self.wave += 1
        active = random.sample(self.towers, 5)
        damage = sum(self._apply_tower_effect(t) for t in active)

        burn = sum(1 for t in active if t.element == "fire") / 5
        control = sum(1 for t in active if t.role in {"Control", "Support"}) / 5
        corruption = sum(1 for t in active if t.element == "corruption") / 5
        path_extension = self.field.score_transformation() / (self.field.width * self.field.height)

        metrics = WaveMetrics(
            burn_share=min(1.0, burn + random.uniform(0.1, 0.3)),
            slow_dilation=min(1.0, control + random.uniform(0.0, 0.25)),
            path_extension=min(1.0, path_extension + random.uniform(0.0, 0.2)),
            early_kill_share=min(1.0, damage / 140),
            corruption_stacks=corruption * 14,
            corruption_kill_share=min(1.0, corruption + random.uniform(0.05, 0.25)),
        )
        self.adaptation.ingest(metrics)
        forecast = self.adaptation.forecast(self.wave, self.integrity)
        mitigation = None

        pressure = random.uniform(0.03, 0.09)
        if forecast:
            mitigation = self._mitigation_choice(forecast)
            self.evolutions_faced.append(forecast.family)
            pressure += 0.04
        self.integrity = max(0.0, self.integrity - pressure)

        if damage > 80 and path_extension > 0.30:
            self.story_moments.append(
                f"Wave {self.wave}: reroute combo collapsed a full enemy pack in transformed terrain"
            )

        return {
            "wave": self.wave,
            "damage": round(damage, 1),
            "integrity": round(self.integrity, 2),
            "transformed_tiles": self.field.score_transformation(),
            "forecast": forecast,
            "mitigation": mitigation,
        }

    def run_summary(self) -> Dict[str, object]:
        dominant_element = "none"
        if self.element_usage:
            dominant_element = max(self.element_usage, key=self.element_usage.get)
        return {
            "commander": self.commander.name,
            "biome": self.field.biome.value,
            "dominant_element": dominant_element,
            "evolutions_faced": list(dict.fromkeys(self.evolutions_faced)),
            "story_moments": self.story_moments[:3],
            "final_integrity": round(self.integrity, 2),
            "final_transformed_tiles": self.field.score_transformation(),
        }


def run_demo(waves: int = 12) -> None:
    game = Game()
    print(f"WILDCORE prototype run | biome={game.field.biome.value} | commander={game.commander.name}")
    for _ in range(waves):
        report = game.run_wave()
        print(
            f"Wave {report['wave']:>2} | damage={report['damage']:>5} | integrity={report['integrity']:.2f} | "
            f"transformed={report['transformed_tiles']}"
        )
        forecast = report["forecast"]
        if forecast:
            print(
                f"  Adaptation forecast: {forecast.family} from {forecast.signal} "
                f"(partial w{forecast.eta_partial}, full w{forecast.eta_full})"
            )
            print(f"  Why: {forecast.explanation[forecast.signal]}")
            print(f"  Mitigation option: {report['mitigation']}")

    print("\nFinal terrain snapshot:")
    for row in game.field.snapshot():
        print("  ", row)

    if game.story_moments:
        print("\nStory moments:")
        for s in game.story_moments[:3]:
            print(" -", s)

    summary = game.run_summary()
    print("\nRun summary:")
    print(
        f"  dominant_element={summary['dominant_element']} | final_integrity={summary['final_integrity']} | "
        f"final_transformed_tiles={summary['final_transformed_tiles']}"
    )
    if summary["evolutions_faced"]:
        print(f"  evolutions={', '.join(summary['evolutions_faced'])}")


if __name__ == "__main__":
    run_demo()
