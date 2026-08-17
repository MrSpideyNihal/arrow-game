# Arrow Flow — Build Prompt Bundle

This folder is a complete, ready-to-hand-off prompt set for an AI coding agent (Claude Code, etc.) to build, test, and publish a Flutter arrow-removal puzzle game from scratch, based on the reference video spec in `reference/`.

## Read in this order

1. `01_MASTER_AGENT_PROMPT.md` — the actual prompt. Paste this whole file to your coding agent as the task brief. It references the other files below by name, so keep them in the same `docs/` folder inside the repo.
2. `02_FOLDER_STRUCTURE.md` — exact Flutter project layout the agent should create.
3. `03_LEVEL_AND_SOLVER_SPEC.md` — the puzzle algorithm, level JSON schema, and the procedural-generation approach that keeps 1000 levels under ~500KB.
4. `config/game_config.json` — drop this in as `config/game_config.json` in the new repo. It's the single file that controls ad IDs, version, colors, gameplay tuning, and feature flags for the entire app. Google's official AdMob **test IDs** are pre-filled so the app runs safely in test mode out of the box — swap in real IDs when ready to publish.
5. `reference/Arrow_Puzzle_Gameplay_Feature_Specification.pdf` — the original gameplay spec this build is based on. Keep it in the repo under `docs/reference/` for provenance.

## How to use this with an agent, step by step

1. Create a new empty GitHub repo (e.g. `arrow-flow`).
2. Copy this entire `docs/` folder into the repo root.
3. Open the repo in your coding agent and give it `01_MASTER_AGENT_PROMPT.md` as the task, telling it explicitly: "follow the phases in order, commit after each phase, do not skip the acceptance criteria at the end."
4. Let it work through Phase 0 → Phase 10. Review after each phase rather than only at the end — it's much cheaper to correct course early (e.g. wrong folder structure, wrong config shape) than after 10 phases of code are built on top of it.
5. Once Phase 10 finishes, verify the acceptance criteria checklist in `01_MASTER_AGENT_PROMPT.md` §8 yourself before submitting to the Play Store.

## What you'll end up with

- A signed, installable Flutter app (APK + AAB).
- 100 hand-QA'd (solver-validated) levels shipped, with a built-in generator that can extend to 1000+ without growing app size.
- One JSON file that reskins/retunes the entire game.
- Banner + rewarded ads only — no interstitials anywhere.
- A momentum-combo + star-rating + soft-currency layer that gives the game a genuine "one more try" hook beyond the base mechanic.
- A clean GitHub history and a README a stranger could build from.
