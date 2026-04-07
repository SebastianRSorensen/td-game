from __future__ import annotations

from dataclasses import dataclass
from random import Random
from typing import Dict, List, Tuple

from .core import (
    AdaptationDirector,
    Battlefield,
    Faction,
    TerrainState,
    Tower,
    WaveMetrics,
)


@dataclass
class RunResources:
    scrap: int = 100
    essence: int = 0
    core_charge: int = 2
    biome_pressure: float = 0.0


class Game:
    def __init__(self, seed: int = 7):
        self.rng = Random(seed)
        self.field = Battlefield()
        self.adaptation = AdaptationDirector()
        self.integrity = 1.0
        self.wave = 0
        self.towers = self._default_towers()
        self.story_moments: List[str] = []
        self.resources = RunResources()

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
        x = self.rng.randint(1, self.field.width - 2)
        y = self.rng.randint(0, self.field.height - 1)
        affected = [(x, y)]

        if tower.terrain_aura:
            self.field.apply_transformation(affected, tower.terrain_aura)

        if tower.name == "Oil Extractor":
            self.resources.scrap += 14
            self.resources.biome_pressure += 0.02

        return tower.base_damage * self._elemental_combo(tower, affected)

    def run_wave(self) -> Dict[str, object]:
        self.wave += 1
        active = self.rng.sample(self.towers, 5)
        damage = sum(self._apply_tower_effect(tower) for tower in active)

        burn = sum(1 for tower in active if tower.element == "fire") / 5
        control = sum(1 for tower in active if tower.role in {"Control", "Support"}) / 5
        corruption = sum(1 for tower in active if tower.element == "corruption") / 5
        path_extension = self.field.transformed_ratio()

        metrics = WaveMetrics(
            burn_share=min(1.0, burn + self.rng.uniform(0.1, 0.3)),
            slow_dilation=min(1.0, control + self.rng.uniform(0.0, 0.25)),
            path_extension=min(1.0, path_extension + self.rng.uniform(0.0, 0.2)),
            early_kill_share=min(1.0, damage / 140),
            corruption_stacks=corruption * 14,
            corruption_kill_share=min(1.0, corruption + self.rng.uniform(0.05, 0.25)),
        )
        self.adaptation.ingest(metrics)
        forecast = self.adaptation.forecast(self.wave, self.integrity)

        pressure = self.rng.uniform(0.03, 0.09) + self.resources.biome_pressure
        if forecast:
            pressure += 0.04

        self.integrity = max(0.0, self.integrity - pressure)
        self.resources.essence += int(damage / 30)
        self.resources.core_charge = min(4, self.resources.core_charge + 1)

        if damage > 80 and path_extension > 0.30:
            self.story_moments.append(
                f"Wave {self.wave}: reroute combo collapsed a full enemy pack in transformed terrain"
            )

        return {
            "wave": self.wave,
            "damage": round(damage, 1),
            "integrity": round(self.integrity, 2),
            "transformed_tiles": self.field.score_transformation(),
            "resources": self.resources,
            "forecast": forecast,
        }


def run_demo(waves: int = 12) -> None:
    game = Game()
    print("WILDCORE simulation foundation")
    for _ in range(waves):
        report = game.run_wave()
        resources = report["resources"]
        print(
            f"Wave {report['wave']:>2} | damage={report['damage']:>5} | integrity={report['integrity']:.2f} | "
            f"transformed={report['transformed_tiles']} | scrap={resources.scrap} essence={resources.essence}"
        )
        forecast = report["forecast"]
        if forecast:
            print(
                f"  Adaptation forecast: {forecast.family} from {forecast.signal} "
                f"(partial w{forecast.eta_partial}, full w{forecast.eta_full})"
            )
            print(f"  Why: {forecast.explanation[forecast.signal]}")

    print("\nFinal terrain snapshot:")
    for row in game.field.snapshot():
        print("  ", row)
