# Readability Spec

This document defines minimum readability standards for combat, VFX, and gameplay UI signaling.

## 1) Color ownership

### 1.1 Faction ownership
- **Player-owned effects:** cool-spectrum palette (blues/cyans/teals) and clean edge treatment.
- **Enemy-owned effects:** warm/aggressive palette (reds/oranges/magentas) with harsher edge treatment.
- **Neutral/world effects:** desaturated or earth-spectrum palette (grays/browns/greens) unless elevated by a mechanic.
- **Boss-exclusive effects:** unique accent hue not used by standard enemies in the same encounter.

### 1.2 Terrain-state ownership
- **Stable/default terrain:** low-saturation base colors with minimal emissive highlights.
- **Buffed/helpful terrain:** positive-state highlights (green/cyan) with soft pulse.
- **Debuffed/dangerous terrain:** warning-state highlights (amber/red) with stronger pulse and contrast.
- **Transitioning terrain:** striped/interleaved gradients between current and incoming state color until state swap resolves.

### 1.3 Color conflict rules
- Never assign identical primary hue + intensity bands to two simultaneous hostile telegraphs in the same local area.
- When overlap is unavoidable, differentiate by **shape first**, then luminance contrast, then animation pattern.
- Colorblind-safe differentiation must be maintained via shape and motion even when hue discrimination fails.

## 2) Max simultaneous high-intensity VFX per screen region

Define each screen into three gameplay regions: **Left lane region**, **Center lane region**, **Right lane region** (or equivalent spatial thirds for non-lane maps).

### 2.1 Hard limits
- Max **2** simultaneous high-intensity effects per region.
- Max **5** simultaneous high-intensity effects globally on screen.
- Any additional effect request above budget must degrade to low-intensity mode (reduced bloom, alpha, and particle count) or queue.

### 2.2 High-intensity classification
An effect is high-intensity if it meets any of the following:
- Peak luminance/brightness spike intended to grab immediate attention.
- Full-saturation emissive fill occupying significant local area.
- Dense particle burst or high-frequency motion capable of obscuring unit silhouettes.

## 3) Priority layering order

When visual conflicts occur, render and readability priority must follow this order (highest to lowest):

1. **Critical combo telegraphs** (imminent, high-punishment chained mechanics)
2. **Boss mechanics telegraphs**
3. **Terrain hazards** (active damaging zones, collapse warnings)
4. **Enemy units/projectiles**
5. **Paths/navigation readability**
6. **Tower ranges/placement previews**
7. **Ambient/non-critical VFX dressing**

### 3.1 Layering enforcement
- Lower-priority layers must not fully occlude higher-priority telegraphs.
- Tower range rings must auto-dim when overlapping active hazard or combo telegraphs.
- Path readability must remain visible at all times through contrast outlines or top-line overlays.

## 4) Distinct telegraph shapes by warning class

Each warning class must be shape-distinct so players can classify mechanics without relying on color.

- **Adaptation warnings:** segmented **chevrons/arrows** pointing toward required behavior change.
- **Boss mechanics:** bold **radial rings/concentric circles** with timing sweep.
- **Terrain hazards:** **polygonal/area-fill footprints** (rectangles, cones, irregular ground masks) anchored to map geometry.

### 4.1 Shape consistency rules
- Do not reuse the primary silhouette family of one class for another class in the same encounter.
- Animation cadence should reinforce class identity (e.g., adaptation = directional ticks, boss = countdown sweep, terrain = grounded pulse).

## 5) New-effect readability checklist (required)

Every new combat/VFX/UI effect must pass this checklist:

1. **Can player identify source in <1 second?**
2. **Can player identify consequence in <2 seconds?**
3. **Can player act on it before punishment?**

If any answer is "No", the effect is blocked from merge until revised.

## 6) Feature review gate (mandatory)

The checklist in Section 5 is **required in feature review** for all:
- Combat additions
- VFX additions
- UI additions that communicate gameplay state or danger

Review templates and sign-off notes must include explicit pass/fail for all three checklist items before approval.
