# Level & Solver Specification

## 1. Board representation

Use a fixed-unit grid (e.g. 12x16 units) rather than free-floating pixel coordinates — this keeps the JSON tiny and makes ray-casting exact-integer math instead of floating point.

Each arrow is a **polyline** ending in a direction: `start (gx, gy)` cells → path cells → `exitDirection` (`up`/`down`/`left`/`right`). Most arrows are simple straight or single-bend paths; complexity comes from overlap/occlusion between many arrows sharing board space, not from exotic geometry.

## 2. Compact JSON schema (per level)

```json
{
  "id": 42,
  "difficulty": "normal",
  "gridW": 12,
  "gridH": 16,
  "arrows": [
    { "cells": [[3,2],[3,3],[3,4]], "dir": "d" },
    { "cells": [[3,4],[4,4],[5,4]], "dir": "r" }
  ]
}
```

- `cells`: ordered list of `[x,y]` grid coordinates the arrow occupies, from tail to arrowhead.
- `dir`: single-letter exit direction (`u`,`d`,`l`,`r`) — the direction the arrowhead points and the direction it exits the board edge on removal.
- No color/style/animation data stored per level — all visual styling comes from the active theme in `game_config.json`, keeping level files tiny (a few hundred bytes each).

100 levels bundled as one array in `levels_pack_001.json` (not 100 separate files) — fewer filesystem reads, better gzip compression across similar structures, smaller APK.

## 3. Blocked / selectable algorithm

An arrow is **selectable** if and only if every cell strictly between its arrowhead and the board edge, along its exit direction ray, contains no cell belonging to another still-active arrow.

```
function isSelectable(arrow, activeArrows):
    head = arrow.cells.last
    ray = cellsFrom(head, arrow.dir, toEdge = true)   // excludes head itself
    for cell in ray:
        if any other active arrow occupies cell:
            return false
    return true
```

Recompute selectability for all remaining arrows after every removal (cheap at these board sizes — O(arrows × ray length), fine even at 60fps if called on tap rather than every frame).

On tap:
- If `isSelectable(tapped)` → play exit animation → remove from active set → recompute → feed combo engine a "hit" event.
- Else → feed combo engine a "miss" event (resets multiplier, does not remove a life by itself) → if the tapped arrow is *also* fully covered by another arrow's own body (a genuinely invalid/occluded tap vs. a legal-but-not-yet-clear tap) apply the heart-loss rule from `game_config.json.gameplay.mistakePenalty` — implement this as a single configurable enum (`"loseHeart"`, `"comboResetOnly"`, `"none"`) so designers can tune punishment without code changes.

## 4. Procedural generation (how 1000 levels stay under ~500KB)

Do **not** hand-author or store 1000 independent boards. Instead:

1. `level_generator.dart` takes a `(levelIndex, difficultyCurveSeed)` and derives a deterministic seed (`hash(levelIndex, difficultyCurveSeed)`).
2. Uses that seed to procedurally place N arrows (N grows with `levelIndex` per a config-defined difficulty curve — e.g. arrows = `clamp(3 + floor(levelIndex/4), 3, 14)`), with increasing overlap/occlusion density at higher indices.
3. Immediately runs `arrow_solver.dart`'s solvability check (a full simulated clear using a greedy/backtracking solve) on the generated board.
4. If unsolvable, or solvable in a trivial single fixed order that makes it "too easy for its slot," regenerate with a perturbed seed and retry (cap retries, e.g. 20, then fall back to a slightly smaller arrow count).
5. Only the **seed + arrow count + difficulty tag** need to be stored to reproduce a level deterministically — OR, for guaranteed stability/QA (recommended for the first 100 shipped levels), generate once at build time and bake the resulting compact JSON into `assets/levels/`. For levels beyond the first 100 (the "1000 levels" ambition), generate-on-first-play and cache the compact JSON result locally instead of shipping it — this is what keeps app size flat regardless of how many levels exist.

This satisfies three requirements at once: **storage stays tiny**, **adding levels is trivial** (bump a count in config/manifest, no authoring), and **every level is guaranteed solvable** (QA is automatic, not manual).

## 5. Difficulty curve (default, tune via config)

| Level range | Arrow count | Overlap density | Notes |
|---|---|---|---|
| 1–10 | 3–4 | low | tutorial band, mostly straight arrows |
| 11–30 | 4–6 | low-medium | introduce single-bend arrows |
| 31–60 | 6–9 | medium | introduce "locked" arrows (see below) |
| 61–100 | 9–14 | medium-high | dense nested clusters |
| 100+ (generated) | scale per formula above, cap 18 | high | for the 1000-level long tail |

Optional depth mechanic for levels 30+: a small subset of arrows can be **color-locked** — removable only while the Momentum combo tier is at x2 or higher — reusing the combo system as a puzzle constraint, not just a score multiplier. This is optional polish; ship the core mechanic first, add this after Phase 7 if time allows.
