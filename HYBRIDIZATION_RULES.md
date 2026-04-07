# Hybridization Rules (Hard Costs + Excitement)

## Design Intent
Hybrid builds should be **high ceiling, high risk**:
- They can produce stronger peak turns than mono-faction builds.
- They should pay meaningful upfront and ongoing costs.
- They should lose consistency and effective durability when piloted poorly.
- They should never become strictly better than mono-faction options at equal skill.

---

## 1) Hard Cost Pillars

### 1.1 Cross-Faction Draft Tax (Required)
When a deck includes cards/units/upgrades from a secondary faction, apply all of the following:

1. **Resource Tax**
   - First 3 off-faction picks: `+0` additional cost.
   - Picks 4-6 off-faction: each costs **+1 resource** when played.
   - Picks 7+ off-faction: each costs **+2 resources** when played.

2. **Slot Tax**
   - Reserve **2 roster slots** as `Integration Slots` (cannot hold normal units).
   - If running 10+ off-faction picks, reserve **3 Integration Slots**.

3. **Tempo Tax**
   - First time each combat you play an off-faction card/ability, it enters with `Assimilation Delay`:
     - `-25%` immediate effect this turn, full effect from next turn onward.

> Tuning goal: Hybrid openers are weaker/slower than mono-faction openers, but hybrids can outscale by mid-to-late combat.

---

### 1.2 Stability Pressure for Incompatible Terrain Effects
Hybridizing terrain paradigms increases system strain.

- Define terrain incompatibility pairs (examples):
  - `Fortified Grid` vs `Shifting Wilds`
  - `Static Leyline` vs `Corrosive Mire`
  - `Heat Zone` vs `Cryo Zone`

For each active incompatible pair in a build:
- **+12 Stability Pressure baseline**.
- **+4 additional Stability Pressure** per turn where both effects are active.
- If total Stability Pressure exceeds threshold:
  - Threshold 1 (`40`): random non-core effect is muted for 1 turn.
  - Threshold 2 (`65`): one off-faction unit is `Disrupted` (cannot use active ability next turn).
  - Threshold 3 (`85`): `Cascade Event` (lose 10% current shield/HP team-wide).

> Tuning goal: Hybrids are punished for over-stacking conflicting environment packages.

---

### 1.3 Adaptation Acceleration for Volatility
High-volatility hybrids adapt quickly but become easier to counter if predictable.

- Compute `Volatility Score` from deck composition and effects:
  - +1 per off-faction card beyond first 3.
  - +1 per incompatible terrain pair.
  - +1 per self-sacrifice or random outcome mechanic (cap +4).

Apply Adaptation Acceleration Multiplier (AAM) to both sides:
- At `Volatility 0-3`: `AAM 1.00x` (no change).
- At `Volatility 4-6`: `AAM 1.20x`.
- At `Volatility 7-9`: `AAM 1.35x`.
- At `Volatility 10+`: `AAM 1.50x`.

Interpretation:
- Your hybrid unlock mechanics that rely on adaptation triggers sooner.
- Opponent counter-adaptation and anti-pattern responses also accelerate by the same multiplier.

> Tuning goal: Reward daring pivots while enforcing real counterplay windows.

---

## 2) Positive Compensation (Why Hybrid Is Exciting)

### 2.1 Unique Cross-Faction Combo Unlocks
A build with at least 6 off-faction picks may equip one `Hybrid Signature Combo`.

**Examples**
1. **Bastion Bloom** (Aegis + Verdant)
   - Shielded unit roots nearby enemies briefly when shield breaks.
2. **Ash Circuit** (Infernal + Aegis)
   - Overheat damage converts partly into temporary armor.
3. **Spore Surge** (Verdant + Infernal)
   - Burned enemies spread a weaker poison-on-death cloud.

Rules:
- Signature Combos are mutually exclusive (one equipped at a time).
- They require meeting faction ratio and volatility floor (e.g., Volatility ≥ 4).

### 2.2 Distinct Hybrid Capstones (Visible Identity)
At high investment, hybrids unlock faction-pair capstones with strong visual/readability cues.

- Capstones unlock at:
  - 10+ off-faction picks.
  - 2+ mastered cross-faction synergies.
  - Stability Pressure average below 60 over last 3 rounds.

Each capstone should include:
- **Gameplay identity**: one major mechanic shift.
- **Visual identity**: clear VFX color blend, unit silhouette modifier, HUD badge.
- **Counterplay identity**: one explicit weakness.

**Examples**
- **Iron Canopy Protocol** (Aegis + Verdant)
  - Gain periodic bark-armor refreshes; weakness: vulnerable to armor shred windows.
- **Ember Bastion Lattice** (Aegis + Infernal)
  - Reflective heat shielding spikes; weakness: high self-heat risk if overcycled.
- **Wildfire Bloom Core** (Verdant + Infernal)
  - Rapid spread effects with explosive growth; weakness: unstable under cleanse/control.

---

## 3) Benchmark Build Targets
Use these six benchmarks to tune for fairness. Metrics below assume equal player skill and standard map pools.

### 3.1 Mono-Faction Baselines (3)

| Build | Primary Plan | Power Target (P50 / P90) | Survivability Target | Risk Profile |
|---|---|---:|---:|---|
| **Aegis Bastion** | Frontline control + shields | 100 / 118 | 125 | Low variance, stable |
| **Verdant Swarm** | Tempo expansion + sustain | 102 / 122 | 112 | Medium variance |
| **Infernal Burst** | Spike damage + pressure | 106 / 130 | 95 | High variance but linear |

### 3.2 Hybrid Benchmarks (3)

| Build | Hybrid Pair | Cost Pressure | Power Target (P50 / P90) | Survivability Target | Risk Profile |
|---|---|---|---:|---:|---|
| **Bastion Bloom** | Aegis + Verdant | Medium (slot + stability) | 98 / 136 | 108 | High ceiling, setup-sensitive |
| **Ember Lattice** | Aegis + Infernal | High (resource + tempo) | 96 / 140 | 100 | Very high ceiling, punishing misplay |
| **Wildfire Canopy** | Verdant + Infernal | Very High (stability + volatility) | 94 / 145 | 90 | Extreme spikes, fragile floor |

### 3.3 Comparison Rules (Must Hold)
To enforce “high ceiling, high risk”:

1. **Floor Rule (Consistency Check)**
   - Hybrid P50 power must be **2-8% lower** than nearest mono baseline.

2. **Ceiling Rule (Excitement Check)**
   - Hybrid P90 power can be **8-15% higher** than nearest mono baseline.

3. **Durability Rule (Risk Check)**
   - Hybrid survivability must be **8-20% lower** than defensive mono analog.

4. **Failure Rate Rule**
   - In internal tests, hybrid catastrophic failure states (stability collapse / dead draw / tempo lock) should occur **1.4x-2.0x** as often as mono-faction control builds.

5. **Counterplay Rule**
   - Every hybrid capstone must have at least one counter strategy with a measurable win-rate swing of **+6% or greater** when executed correctly.

---

## 4) Quick Tuning Checklist
Before shipping a patch, verify:
- Draft tax is felt by round 2-3 in 80%+ of hybrid test games.
- Hybrid openers do not outperform mono openers in uncontested conditions.
- Hybrid midgame spikes are visible and satisfying.
- Capstone visuals clearly telegraph faction identity blend.
- Counterplay options remain available in every matchup cluster.

If all checks pass, hybrids should remain aspirational and expressive without eclipsing mono-faction reliability.
