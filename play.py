"""Interactive WILDCORE CLI game."""

from wildcore import (
    Battlefield,
    Commander,
    Game,
)


def clear_screen():
    print("\033[2J\033[H", end="")


def print_header(game: Game):
    node = game.node_plan[game.wave]
    print(f"\n{'='*50}")
    print(f"  WAVE {game.wave + 1}/{len(game.node_plan)}  [{node.node_type.value.upper()}]  {node.biome.value}")
    print(f"{'='*50}")
    print(
        f"  Integrity: {game.integrity:.0%}  |  "
        f"Scrap: {game.resources.scrap}  |  "
        f"Essence: {game.resources.essence}  |  "
        f"Core Charges: {game.resources.core_charge}"
    )
    if game.enemy_traits:
        print(f"  Enemy traits: {', '.join(game.enemy_traits)}")


def print_battlefield(field: Battlefield):
    print(f"\n  Battlefield:")
    for row in field.snapshot():
        print(f"    {' '.join(row)}")
    transformed = field.score_transformation()
    total = field.width * field.height
    print(f"    ({transformed}/{total} tiles transformed)")


def print_towers(game: Game):
    print(f"\n  Available towers:")
    for i, tower in enumerate(game.towers):
        faction_short = tower.faction.value[:5]
        print(
            f"    {i + 1:>2}. {tower.name:<22} [{faction_short}]  "
            f"{tower.role:<8}  dmg={tower.base_damage:<4}  rng={tower.range}"
        )


def choose_commander() -> Commander:
    print("\n" + "=" * 50)
    print("          W I L D C O R E")
    print("=" * 50)
    print("\n  Choose your Commander:\n")
    print("    1. The Warden   - +10% integrity, Overgrowth Surge")
    print("    2. The Foreman  - +40 scrap, Ignition Sweep")
    print("    3. The Seer     - +10 essence, Void Pulse")

    commanders = [Commander.WARDEN, Commander.FOREMAN, Commander.SEER]
    while True:
        try:
            choice = input("\n  > ")
            idx = int(choice) - 1
            if 0 <= idx < 3:
                print(f"\n  Selected: {commanders[idx].value}")
                return commanders[idx]
        except (ValueError, EOFError):
            pass
        print("  Enter 1, 2, or 3.")


def choose_towers(game: Game) -> list[int]:
    print_towers(game)
    count = min(5, len(game.towers))
    print(f"\n  Pick {count} towers (e.g. 1 3 5 7 9):")

    while True:
        try:
            raw = input("  > ")
            indices = [int(x) - 1 for x in raw.split()]
            if len(indices) != count:
                print(f"  Pick exactly {count} towers.")
                continue
            if any(i < 0 or i >= len(game.towers) for i in indices):
                print(f"  Tower numbers must be 1-{len(game.towers)}.")
                continue
            if len(set(indices)) != len(indices):
                print("  No duplicates allowed.")
                continue
            return indices
        except (ValueError, EOFError):
            print(f"  Enter {count} numbers separated by spaces.")


def choose_ability(game: Game) -> bool:
    if game.resources.core_charge <= 0:
        return False

    ability_name = {
        Commander.WARDEN: "Overgrowth Surge",
        Commander.FOREMAN: "Ignition Sweep",
        Commander.SEER: "Void Pulse",
    }[game.commander]

    print(f"\n  Use {ability_name}? ({game.resources.core_charge} charges left) [y/n]")
    while True:
        try:
            choice = input("  > ").strip().lower()
            if choice in ("y", "yes"):
                return True
            if choice in ("n", "no", ""):
                return False
        except EOFError:
            return False
        print("  Enter y or n.")


def print_wave_result(result: dict):
    node = result["node"]
    resources = result["resources"]
    print(f"\n  {'- ' * 25}")
    print(f"  Damage dealt: {result['damage']}")
    print(f"  Integrity: {result['integrity']:.0%}")
    print(f"  Transformed tiles: {result['transformed_tiles']}")
    print(f"  Scrap: {resources.scrap}  |  Essence: {resources.essence}")

    forecast = result["forecast"]
    if forecast:
        print(
            f"\n  ! ADAPTATION FORECAST: {forecast.family} from {forecast.signal}"
            f" (partial w{forecast.eta_partial}, full w{forecast.eta_full})"
        )


def print_game_over(game: Game):
    summary = game.run_summary()
    print(f"\n{'='*50}")
    if game.integrity <= 0:
        print("  DEFEAT - Your defenses crumbled!")
    else:
        print("  VICTORY - Campaign complete!")
    print(f"{'='*50}")
    print(f"  Commander: {summary['commander']}")
    print(f"  Waves cleared: {summary['waves_cleared']}/{len(game.node_plan)}")
    print(f"  Final integrity: {summary['integrity']:.0%}")
    print(f"  Dominant faction: {summary['dominant_faction']}")
    print(f"  Enemy traits faced: {', '.join(summary['enemy_traits_faced']) or 'none'}")
    print(f"\n  Final battlefield:")
    for row in summary["final_map"]:
        print(f"    {' '.join(row)}")
    if summary["story_moments"]:
        print(f"\n  Key moments:")
        for moment in summary["story_moments"]:
            print(f"    - {moment}")
    print()


def main():
    commander = choose_commander()
    game = Game(seed=None, commander=commander)

    while game.wave < len(game.node_plan) and game.integrity > 0:
        print_header(game)
        print_battlefield(game.field)

        tower_indices = choose_towers(game)
        use_ability = choose_ability(game)

        result = game.run_wave(tower_indices=tower_indices, use_ability=use_ability)
        print_wave_result(result)

        if game.integrity > 0 and game.wave < len(game.node_plan):
            input("\n  Press Enter for next wave...")

    print_game_over(game)


if __name__ == "__main__":
    main()
