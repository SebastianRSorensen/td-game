from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
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


class Biome(str, Enum):
    VERDANT_BASIN = "Verdant Basin"
    IRON_SCAR = "Iron Scar"
    HOLLOW_VEIL = "Hollow Veil"


class Commander(str, Enum):
    WARDEN = "The Warden"
    FOREMAN = "The Foreman"
    SEER = "The Seer"


class NodeType(str, Enum):
    BATTLE = "battle"
    ELITE = "elite"
    RESOURCE_CACHE = "resource_cache"
    ANOMALY = "anomaly"
    SHRINE = "shrine"
    MERCHANT = "merchant"
    BOSS = "boss"


@dataclass
class RunResources:
    scrap: int = 120
    essence: int = 0
    core_charge: int = 2
    biome_pressure: float = 0.0


@dataclass
class RunNode:
    wave: int
    biome: Biome
    node_type: NodeType
    threat_multiplier: float = 1.0


@dataclass
class BossProfile:
    name: str
    adaptation_focus: str
    pressure_bonus: float


@dataclass
class RunReport:
    wave: int
    node_type: NodeType
    biome: Biome
    damage: float
    integrity: float
    transformed_tiles: int
    forecast_family: str | None


class Game:
    def __init__(self, seed: int = 7, commander: Commander = Commander.WARDEN):
        self.rng = Random(seed)
        self.seed = seed
        self.commander = commander
        self.field = Battlefield()
        self.adaptation = AdaptationDirector()
        self.integrity = 1.0
        self.wave = 0
        self.towers = self._default_towers()
        self.story_moments: List[str] = []
        self.resources = RunResources()
        self.enemy_traits: List[str] = []
        self.node_plan = self._build_node_plan()
        self.bosses = self._boss_profiles()
        self.completed_nodes: List[RunNode] = []
        self._apply_commander_start_bonus()

    def _apply_commander_start_bonus(self) -> None:
        if self.commander == Commander.WARDEN:
            self.integrity = 1.1
        elif self.commander == Commander.FOREMAN:
            self.resources.scrap += 40
            self.resources.biome_pressure += 0.03
        elif self.commander == Commander.SEER:
            self.resources.essence += 10
            self.resources.biome_pressure += 0.02

    def _build_node_plan(self) -> List[RunNode]:
        biomes = [Biome.VERDANT_BASIN, Biome.IRON_SCAR, Biome.HOLLOW_VEIL]
        nodes: List[RunNode] = []
        for wave in range(1, 13):
            biome = biomes[(wave - 1) // 4]
            if wave in {6, 12}:
                node_type = NodeType.BOSS
                mult = 1.6
            elif wave in {4, 8, 11}:
                node_type = NodeType.ELITE
                mult = 1.25
            elif wave in {3, 7, 10}:
                node_type = self.rng.choice([NodeType.ANOMALY, NodeType.RESOURCE_CACHE, NodeType.SHRINE])
                mult = 1.0
            else:
                node_type = NodeType.BATTLE
                mult = 1.0
            nodes.append(RunNode(wave=wave, biome=biome, node_type=node_type, threat_multiplier=mult))
        return nodes

    @staticmethod
    def _boss_profiles() -> Dict[Biome, BossProfile]:
        return {
            Biome.VERDANT_BASIN: BossProfile("Bloom Rot Matriarch", "Control", 0.04),
            Biome.IRON_SCAR: BossProfile("Ember Titan", "Burn", 0.06),
            Biome.HOLLOW_VEIL: BossProfile("Glass Saint", "Burst", 0.07),
        }

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

    def cast_core_ability(self) -> str | None:
        if self.resources.core_charge <= 0:
            return None
        self.resources.core_charge -= 1

        x = self.rng.randint(1, self.field.width - 2)
        y = self.rng.randint(0, self.field.height - 1)

        if self.commander == Commander.WARDEN:
            self.field.apply_transformation([(x, y)], TerrainState.OVERGROWN)
            self.story_moments.append(f"Wave {self.wave}: Warden overgrowth save stabilized a lane")
            return "Overgrowth Surge"
        if self.commander == Commander.FOREMAN:
            self.field.apply_transformation([(x, y)], TerrainState.SCORCHED)
            self.resources.biome_pressure += 0.03
            self.story_moments.append(f"Wave {self.wave}: Foreman ignition burned a collapse lane")
            return "Ignition Sweep"

        self.field.apply_transformation([(x, y)], TerrainState.UNSTABLE)
        self.resources.essence += 4
        self.story_moments.append(f"Wave {self.wave}: Seer void pulse rewired the battlefield")
        return "Void Pulse"

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
            if tower.element == "growth" and state == TerrainState.CRATERED:
                bonus += 0.2
                self.field.apply_transformation([pos], TerrainState.OVERGROWN)
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

    def _apply_node_rewards(self, node: RunNode, damage: float) -> None:
        if node.node_type == NodeType.RESOURCE_CACHE:
            self.resources.scrap += 45
            self.resources.essence += 8
        elif node.node_type == NodeType.SHRINE:
            self.integrity = min(1.2, self.integrity + 0.12)
            self.resources.biome_pressure = max(0.0, self.resources.biome_pressure - 0.03)
        elif node.node_type == NodeType.ANOMALY:
            self.resources.essence += 12
            self.resources.biome_pressure += 0.05
        elif node.node_type == NodeType.ELITE:
            self.resources.scrap += 28
            self.resources.essence += 10
        elif node.node_type == NodeType.BOSS:
            self.resources.scrap += 60
            self.resources.essence += 20

        self.resources.essence += int(damage / 30)
        self.resources.core_charge = min(4, self.resources.core_charge + 1)

    def _apply_adaptation_counter_trait(self, signal: str) -> None:
        mapping = {
            "Burn": "heat-fed",
            "Control": "momentum-burst",
            "Maze": "burrower",
            "Burst": "bulwark-shield",
            "Corruption": "purgeblood",
        }
        trait = mapping[signal]
        if trait not in self.enemy_traits:
            self.enemy_traits.append(trait)

    def _boss_pressure(self, node: RunNode, active_towers: List[Tower]) -> float:
        if node.node_type != NodeType.BOSS:
            return 0.0
        boss = self.bosses[node.biome]
        if boss.adaptation_focus == "Burn":
            fire_count = sum(1 for tower in active_towers if tower.element == "fire")
            return boss.pressure_bonus + (fire_count * 0.015)
        if boss.adaptation_focus == "Control":
            control_count = sum(1 for tower in active_towers if tower.role in {"Control", "Support"})
            return boss.pressure_bonus + (control_count * 0.01)
        return boss.pressure_bonus

    def run_wave(self) -> Dict[str, object]:
        if self.wave >= len(self.node_plan):
            raise RuntimeError("Run already completed")

        node = self.node_plan[self.wave]
        self.wave += 1
        self.completed_nodes.append(node)

        if self.resources.core_charge > 0 and self.rng.random() < 0.4:
            self.cast_core_ability()

        active = self.rng.sample(self.towers, 5)
        damage = sum(self._apply_tower_effect(tower) for tower in active) * node.threat_multiplier

        burn = sum(1 for tower in active if tower.element == "fire") / 5
        control = sum(1 for tower in active if tower.role in {"Control", "Support"}) / 5
        corruption = sum(1 for tower in active if tower.element == "corruption") / 5
        path_extension = self.field.transformed_ratio()

        metrics = WaveMetrics(
            burn_share=min(1.0, burn + self.rng.uniform(0.1, 0.3)),
            slow_dilation=min(1.0, control + self.rng.uniform(0.0, 0.25)),
            path_extension=min(1.0, path_extension + self.rng.uniform(0.0, 0.2)),
            early_kill_share=min(1.0, damage / 170),
            corruption_stacks=corruption * 14,
            corruption_kill_share=min(1.0, corruption + self.rng.uniform(0.05, 0.25)),
        )
        self.adaptation.ingest(metrics)
        forecast = self.adaptation.forecast(self.wave, self.integrity)

        if forecast:
            self._apply_adaptation_counter_trait(forecast.signal)
            self.story_moments.append(
                f"Wave {self.wave}: enemy evolution forecasted {forecast.family} counter-line"
            )

        pressure = self.rng.uniform(0.03, 0.09) + self.resources.biome_pressure
        pressure += self._boss_pressure(node, active)
        if node.node_type == NodeType.ELITE:
            pressure += 0.03

        self.integrity = max(0.0, self.integrity - pressure)
        self._apply_node_rewards(node, damage)

        if damage > 95 and path_extension > 0.30:
            self.story_moments.append(
                f"Wave {self.wave}: reroute combo collapsed a full enemy pack in transformed terrain"
            )

        return {
            "wave": self.wave,
            "node": node,
            "damage": round(damage, 1),
            "integrity": round(self.integrity, 2),
            "transformed_tiles": self.field.score_transformation(),
            "resources": self.resources,
            "enemy_traits": list(self.enemy_traits),
            "forecast": forecast,
        }

    def run_campaign(self) -> List[RunReport]:
        reports: List[RunReport] = []
        while self.wave < len(self.node_plan) and self.integrity > 0:
            result = self.run_wave()
            forecast = result["forecast"]
            node: RunNode = result["node"]
            reports.append(
                RunReport(
                    wave=result["wave"],
                    node_type=node.node_type,
                    biome=node.biome,
                    damage=result["damage"],
                    integrity=result["integrity"],
                    transformed_tiles=result["transformed_tiles"],
                    forecast_family=forecast.family if forecast else None,
                )
            )
        return reports

    def run_summary(self) -> Dict[str, object]:
        dominant_faction = max(
            (Faction.WILD_GROWTH, Faction.IRON_DOMINION, Faction.VOID_BLOOM),
            key=lambda faction: sum(1 for tower in self.towers if tower.faction == faction),
        )
        return {
            "seed": self.seed,
            "commander": self.commander.value,
            "waves_cleared": self.wave,
            "integrity": round(self.integrity, 2),
            "final_map": self.field.snapshot(),
            "transformed_ratio": round(self.field.transformed_ratio(), 2),
            "enemy_traits_faced": list(self.enemy_traits),
            "story_moments": self.story_moments[-5:],
            "dominant_faction": dominant_faction.value,
            "resources": {
                "scrap": self.resources.scrap,
                "essence": self.resources.essence,
                "core_charge": self.resources.core_charge,
                "biome_pressure": round(self.resources.biome_pressure, 2),
            },
        }


def run_demo(waves: int = 12) -> None:
    game = Game()
    print("WILDCORE production-grade campaign simulation")
    for _ in range(min(waves, len(game.node_plan))):
        if game.integrity <= 0:
            break
        report = game.run_wave()
        resources = report["resources"]
        node = report["node"]
        print(
            f"Wave {report['wave']:>2} [{node.node_type.value}] {node.biome.value} | "
            f"damage={report['damage']:>5} | integrity={report['integrity']:.2f} | "
            f"transformed={report['transformed_tiles']} | scrap={resources.scrap} essence={resources.essence}"
        )
        forecast = report["forecast"]
        if forecast:
            print(
                f"  Adaptation forecast: {forecast.family} from {forecast.signal} "
                f"(partial w{forecast.eta_partial}, full w{forecast.eta_full})"
            )

    summary = game.run_summary()
    print("\nRun summary")
    print(f"  Commander: {summary['commander']}")
    print(f"  Waves cleared: {summary['waves_cleared']} | Integrity: {summary['integrity']}")
    print(f"  Enemy traits faced: {', '.join(summary['enemy_traits_faced']) or 'none'}")
    if summary["story_moments"]:
        print("  Story moments:")
        for moment in summary["story_moments"]:
            print("   -", moment)
