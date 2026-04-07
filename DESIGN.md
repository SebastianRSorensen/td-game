# TD Game Design

## Core Fun Gate (Mandatory)

Before any **new tower, biome, commander, or game mode** can move into implementation, it must pass the **Core Fun Gate** in a playtest-ready prototype.

### Scope
This gate is required for:
- Tower additions
- Biome additions
- Commander additions
- Mode additions

No feature in these categories may be scheduled for production work until this gate is marked **PASS**.

### Explicit Pass Criteria
A prototype passes only if **all** criteria below are met:

1. **Terrain transformation changes decisions every wave.**
   - In every wave, battlefield changes (elevation, cover, hazards, routes, elemental surfaces, etc.) alter optimal placement, targeting, pathing, or resource spend.
   - Testers can name the wave-to-wave decision change and why it happened.

2. **Enemy adaptation is understandable and feels fair.**
   - Enemy adaptation signals are visible (animation, icon, tooltip, log line, or telegraph).
   - Players can explain what enemies adapted to and what counterplay exists.
   - Failure states are attributable to player decisions, not hidden rule shifts.

3. **At least 3 elemental interactions are both readable and strategically meaningful.**
   - Minimum of 3 distinct interactions (example pattern: trigger + effect + counter).
   - Each interaction has clear audiovisual readability in combat.
   - Each interaction changes build order, tower choice, timing, or positioning in successful runs.

4. **A single 20–30 minute run produces a visibly transformed battlefield and one “story moment.”**
   - By end-of-run, terrain/lanes/zones are visibly different from start.
   - At least one memorable emergent event (“story moment”) is observed and captured in test notes.
   - Session length must remain within the 20–30 minute target while preserving clarity.

### Pass/Fail Rule
- **PASS**: All 4 criteria validated by internal playtest notes.
- **FAIL**: Any single criterion missing, unclear, or inconsistent.

---

## Kill-List Rule (Mandatory)

If a proposed feature does **not** measurably improve one or more Core Fun Gate criteria above, it is moved to the **Kill-List** and **deferred**.

### Deferred-by-default examples
- Cosmetic complexity without new decisions
- Content volume that does not improve readability/fairness
- Systems that increase run length without improving transformation or story moments

Kill-List items are revisited only after Core Gate targets are stable across repeated runs.

---

## Planned Features Tagging

All planned features must be labeled either **Core Gate** or **Post-Gate**.

| Feature | Tag | Why |
|---|---|---|
| Dynamic terrain mutation system | Core Gate | Directly required for wave-to-wave decision shifts and visible battlefield transformation. |
| Enemy adaptation telegraph + counterplay UI | Core Gate | Required for understandable, fair adaptation. |
| Elemental interaction triad (3+ interactions) | Core Gate | Required for readable, meaningful strategic interactions. |
| Run narrative capture (“story moment” recorder in test notes) | Core Gate | Required to validate memorable 20–30 minute run outcomes. |
| New elemental tower variants | Post-Gate | Deferred until baseline interaction readability/meaning is proven. |
| Additional biomes beyond baseline test biome | Post-Gate | Deferred until transformation/fairness criteria pass in one biome. |
| Extra commanders | Post-Gate | Deferred until core adaptation and interaction loop is stable. |
| Alternate game modes (endless/challenge/daily) | Post-Gate | Deferred until core 20–30 minute run consistently passes gate. |
| Meta-progression expansion | Post-Gate | Deferred unless it improves gate criteria directly. |
| Cosmetic battlefield themes | Post-Gate | No direct gate impact; deferred by kill-list rule if criteria-neutral. |

---

## Governance

- Every design proposal must include: (a) targeted Core Fun Gate criterion, (b) expected measurable impact, (c) test plan.
- Planning boards and milestone docs must include the **Core Gate/Post-Gate** tag on each item.
- Any untagged planned feature is blocked from scheduling.
