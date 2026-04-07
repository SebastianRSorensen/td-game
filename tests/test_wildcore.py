from wildcore_game import (
    AdaptationDirector,
    Biome,
    Faction,
    Game,
    HybridizationEngine,
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


def test_biome_seeds_distinct_terrain():
    verdant = Game(seed=3, biome=Biome.VERDANT_BASIN)
    iron = Game(seed=3, biome=Biome.IRON_SCAR)
    assert verdant.field.score_transformation() != iron.field.score_transformation()


def test_forecast_includes_mitigation_and_summary_tracks_evolutions():
    game = Game(seed=5)
    got_forecast = False
    for _ in range(9):
        report = game.run_wave()
        if report["forecast"] is not None:
            got_forecast = True
            assert report["mitigation"] is not None

    summary = game.run_summary()
    assert got_forecast
    assert isinstance(summary["evolutions_faced"], list)
