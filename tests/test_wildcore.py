from wildcore_game import (
    AdaptationDirector,
    Commander,
    Faction,
    Game,
    HybridizationEngine,
    NodeType,
    WaveMetrics,
)


def test_adaptation_forecast_after_three_waves():
    director = AdaptationDirector()
    for _ in range(3):
        director.ingest(
            WaveMetrics(
                burn_share=0.7,
                slow_dilation=0.1,
                path_extension=0.1,
                early_kill_share=0.2,
                corruption_stacks=0.0,
                corruption_kill_share=0.0,
            )
        )
    forecast = director.forecast(3, 1.0)
    assert forecast is not None
    assert forecast.signal == "Burn"
    assert forecast.family == "Fireproof"


def test_hybridization_costs_scale():
    picks = [Faction.WILD_GROWTH] * 2 + [Faction.IRON_DOMINION] * 8
    result = HybridizationEngine(Faction.WILD_GROWTH, picks).evaluate()
    assert result["off_faction_picks"] == 8
    assert result["resource_tax"] == 7
    assert result["integration_slots"] == 2
    assert result["adaptation_acceleration"] == 1.2


def test_run_transforms_battlefield():
    game = Game(seed=11)
    before = game.field.score_transformation()
    for _ in range(6):
        game.run_wave()
    after = game.field.score_transformation()
    assert after > before


def test_campaign_includes_boss_nodes():
    game = Game(seed=5)
    boss_count = sum(1 for node in game.node_plan if node.node_type == NodeType.BOSS)
    assert boss_count == 2


def test_campaign_generates_summary_and_enemy_traits():
    game = Game(seed=9, commander=Commander.FOREMAN)
    reports = game.run_campaign()
    summary = game.run_summary()

    assert len(reports) > 0
    assert summary["waves_cleared"] == len(reports)
    assert isinstance(summary["enemy_traits_faced"], list)
    assert "resources" in summary
