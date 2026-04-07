# Enemy Adaptation System Spec

## Purpose
Define a deterministic and player-readable adaptation system that keeps runs challenging without hard-countering player builds.

## 1) Dominant Strategy Signals and Trigger Thresholds
Adaptation signals are evaluated on a rolling **3-wave window** and normalized to each run's current pacing.

### Signal Definitions
- **Burn (Fire-heavy) Signal**
  - Metric: `% enemy HP lost to Burn-type DoT` in the rolling window.
  - Trigger threshold: **>= 45%** for 2 consecutive evaluations.
  - Escalated threshold (for stronger adaptation tier): **>= 60%** for 2 consecutive evaluations.

- **Slow/Control Signal**
  - Metric: `% effective path time increase` caused by slow, stun, root, knockback, or freeze.
  - Trigger threshold: **>= 35%** average time dilation for 2 consecutive evaluations.
  - Escalated threshold: **>= 50%** for 2 consecutive evaluations.

- **Maze/Path Exploitation Signal**
  - Metric: `extra path length vs baseline shortest route` and `% enemies rerouted through repeat choke loops`.
  - Trigger threshold: **>= 30%** added path length **or** >= 40% looped reroutes.
  - Escalated threshold: **>= 50%** added path length.

- **Burst/Alpha Signal**
  - Metric: `% enemies killed within first 20% of path` and peak damage in 2-second windows.
  - Trigger threshold: **>= 55%** early kills for 2 consecutive evaluations.
  - Escalated threshold: **>= 70%** early kills.

- **Corruption/Stacking Debuff Signal**
  - Metric: average corruption stacks per elite and `% elite deaths primarily from corruption effects`.
  - Trigger threshold: **>= 8 stacks average** and >= 40% corruption-primary kills.
  - Escalated threshold: **>= 12 stacks average** and >= 55% corruption-primary kills.

### Trigger Arbitration Rules
- At each evaluation, score all signals from 0.0-1.0 based on proximity to escalated threshold.
- Select only the top **1 dominant signal** (or top 2 if tied within 0.05 score).
- Cooldown: the same signal cannot trigger a new adaptation more than once every **3 waves**.
- Fairness limiter: if player HP/core integrity dropped below 35% in the last wave, delay adaptation by 1 wave.

## 2) Forecast Cadence and Adaptation Timing
- **Forecast cadence:** every **3 waves** (Wave 3, 6, 9, ...).
- On forecast wave, game announces likely adaptation trait family for the next adaptation cycle.
- Adaptation unit injection begins **1 wave after forecast**.
- Full-strength counter units cannot appear until **2 waves after forecast**.
- If multiple signals are tied, forecast may show dual-family warning with weighted probabilities.

## 3) Counterplay Guarantee Rules
Before full counter units appear, the game must present at least one meaningful mitigation path:

1. **Timing guarantee:** At least **1 full wave** of lead time between forecast and first partial counters; **2 full waves** before full counters.
2. **Choice guarantee:** Provide at least **one actionable mitigation option** in post-wave reward/event choices immediately after each forecast.
3. **Accessibility guarantee:** Mitigation cannot require a rare-only shop/event; at least one option must be common-tier or universally available.
4. **Cost fairness:** If mitigation is paid, offer at least one low-cost option (<= 60% of median current wave income).
5. **Build integrity:** Mitigation options should adjust build expression, not invalidate it (e.g., convert burn to mixed burn+direct, add anti-resist shred, add slow immunity bypass windows).

## 4) UX Requirements
The adaptation UI must prioritize legibility, causality, and agency.

### A. Show Which Behaviors Triggered Adaptation
- Forecast panel lists top contributing behaviors with values, e.g.:
  - "Burn damage share: 52% (Trigger: 45%)"
  - "Average slow dilation: 41% (Trigger: 35%)"
- Include a compact "Why this forecast" breakdown with at most 3 metrics.
- Use green/yellow/red status chips for below/near/over threshold.

### B. Show Likely Enemy Trait Family Before Arrival
- Forecast panel must name trait family (examples: **Fireproof**, **Unstoppable**, **Pathfinder**, **Purgeblood**).
- Display confidence band (High/Medium/Low) if arbitration had ties.
- Include ETA text: "Partial adaptation next wave; full adaptation in 2 waves."

### C. Guarantee Actionable Mitigation Choice After Forecast
- Immediately after each forecast, reward/event screen includes at least one tagged option: **"Mitigation"**.
- Mitigation option tooltip explicitly states what it helps against.
- If player skips mitigation, confirm dialog clarifies increased adaptation risk.

## 5) Design Test Scenario Set (Challenging but Fair)
Each scenario is run across 20 seeded simulations + 5 human validation runs.

### Scenario A: Fire-Heavy Build
- Build profile: high burn uptime, low burst, minimal control.
- Expected adaptation: Fire-resist/cleanse family forecast by Wave 6-9.
- Fairness pass criteria:
  - Forecast appears before full counters with required cadence.
  - At least one mitigation option offered after each forecast.
  - Win rate reduction after adaptation is noticeable but bounded (**target: -8% to -18%**, not catastrophic).

### Scenario B: Control-Heavy Build
- Build profile: heavy slows/stuns and maze extension.
- Expected adaptation: Unstoppable/Pathfinder family forecast by Wave 6-9.
- Fairness pass criteria:
  - Player can pivot via at least one mitigation choice to preserve partial control fantasy.
  - Full hard-immune enemies do not appear without prior partial warning stage.
  - Time-to-failure does not drop by >25% immediately after first full counter wave.

### Scenario C: Corruption-Heavy Build
- Build profile: stack-based corruption and debuff amplification.
- Expected adaptation: Purge/stack-cap family forecast by Wave 9-12.
- Fairness pass criteria:
  - Forecast explains corruption stack trigger clearly.
  - Mitigation enables alternate scaling path (hybrid direct damage, shred, or detonation).
  - Post-adaptation average wave clear remains within 0.75x-1.15x of pre-adaptation baseline.

### Cross-Scenario "Challenging but Fair" Acceptance
A run passes design validation when all of the following hold:
- Causality clarity: >= 80% of playtesters can correctly identify why adaptation triggered.
- Agency clarity: >= 80% of playtesters can name at least one mitigation they could have taken.
- Difficulty integrity: adaptation increases decision pressure without forcing a no-win state.
- No sudden hard-counter spikes: failure rates increase gradually across at least 2 waves post-forecast.

## 6) Telemetry Requirements
Capture the following for balancing:
- Signal values each evaluation point.
- Forecast shown trait family, confidence, and ETA.
- Mitigation options offered/picked/skipped.
- Outcome deltas: survival waves, DPS composition shifts, failure cause tags.

This telemetry is mandatory for tuning thresholds and validating fairness criteria over time.
