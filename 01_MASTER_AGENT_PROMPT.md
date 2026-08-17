# MASTER BUILD PROMPT — "Arrow Flow" (Arrow-Removal Puzzle, Flutter)

> Paste this entire file as the system/task prompt to a coding agent (Claude Code, Cursor, etc).
> Reference doc: `Arrow_Puzzle_Gameplay_Feature_Specification.pdf` (place it in `docs/reference/` in the repo — it is the source spec this game is based on).
> Build order: work through the phases **one by one**, in sequence. Do not skip ahead. After each phase, run `flutter analyze` and `flutter test`, fix all errors, then commit to git with a clear message before moving to the next phase.

---

## 0. NON-NEGOTIABLE GLOBAL RULES

1. **Single source of truth config.** Every tunable value (ad unit IDs, version, colors, starting lives, combo timing, feature flags, URLs) lives in `config/game_config.json`. Nothing tunable is hardcoded anywhere else. Changing that one file must be able to re-skin/re-tune the whole game without touching Dart code.
2. **No interstitial / popup ads. Ever.** Only: (a) one persistent banner, and (b) rewarded video ads triggered explicitly by the player (extra hint, extra life/continue, double stars). No auto-popups, no ads on level start, no ads on level complete.
3. **No AI-slop visual language.** No default Material purple/indigo gradients, no generic rounded-sparkle icons, no stock emoji used as UI icons, no "✨🚀🎉" in copy or code comments. Use a custom, restrained **soft-neumorphism** design system (see §5). Confetti/celebration effects are a custom Lottie/Rive animation, not emoji bursts.
4. **Storage discipline.** 1000 levels must add negligible app size (target: under 500KB total for all level data). Achieved via **procedural level generation + solver validation**, not 1000 hand-authored files. See §7.
5. **Everything must be addable/editable easily**: new levels, new ad units, new theme, new copy text — each has one obvious file to touch, documented in `docs/HOW_TO_ADD_LEVELS.md` and `docs/HOW_TO_RESKIN.md` (agent must generate these).
6. **Production-ready output.** End state = a signed, installable release APK/AAB, a working GitHub repo with clean history, and a store-ready listing checklist.
7. Use clear, human-readable code comments. No filler comments, no emoji in code.

---

## 1. GAME IDENTITY

- Codename used in this doc: **Arrow Flow** — this name is already taken by an existing app/mark, so it must **not** be used for the real store listing. Treat every mention of "Arrow Flow" below as a placeholder for whatever final name is set in `config/game_config.json -> app.name`.
- Genre: One-tap logic/removal puzzle. Session length: 30–90 seconds per level, built for "just one more level" replay loops.
- Tone: Calm, minimal, confident — think a premium habit-tracker app crossed with a puzzle toy. Not cartoonish, not childish, not corporate-flat.
- Candidate names to check for availability before locking one in (verify on Google Play + trademark search — do not assume any of these are free): **Flowline**, **Ray & Arrow**, **Vectra**, **Untangle**, **Clearway**, **Arrowbound**. Whichever is chosen goes into `app.name` and nowhere else, per the rule below.

### 1.1 Name propagation — config is the ONLY place the name is typed

`app.name` in `config/game_config.json` must drive **every** surface the name appears on, not just in-app UI copy:

1. **In-app text** (splash, menus, about screen, share text) — pulled at runtime from `AppConfig.app.name`. This part is already covered by the config-loading approach.
2. **Android app label** (`AndroidManifest.xml android:label`) — this is a native, build-time value and Flutter does **not** read `config/game_config.json` for it automatically. The agent must add a small pre-build step (`tool/apply_branding.dart`, run via a `flutter pub run` step or a Makefile/CI step before every build) that reads `app.name` (and `app.packageId`) out of the config file and writes them into `AndroidManifest.xml` before compiling. Document this step clearly in the README so a human running a manual build knows to run it too.
3. **Store listing title** — not automatable (it's typed into Play Console by a human), but `docs/STORE_LISTING_CHECKLIST.md` must pull its "app title" field directly from `app.name` so there's no drift between what's in the app and what's in the listing.
4. **Package ID** (`app.packageId`, e.g. `com.yourstudio.arrowflow`) is also config-driven for documentation purposes, but changing it *after* the app has been published is a much bigger, mostly-manual native-project operation (Android `applicationId`, Play Console listing is tied to the ID permanently) — call this out explicitly to the human before build, don't silently rename it late in the project.

Net effect: change `app.name` once in the config file, run the branding step, rebuild — the name updates in the running app, the installed app label, and the listing checklist, with no Dart/native code edits required.

## 2. THE NEW HOOK (what makes this different from the reference spec)

The reference spec is a plain arrow-removal puzzle. Add these three systems on top — they are the differentiators and must be implemented, not optional:

### 2.1 Momentum Combo System
- Every arrow removed **within the combo window** (config: `gameplay.comboWindowMs`, default 1400ms) of the previous removal extends a visible **Momentum Bar** at the top of the board.
- Combo tiers: x1 → x2 (3 in a row) → x3 (6 in a row) → "FLOW STATE" (10 in a row) — each tier has a distinct subtle glow/sound, no numbers-popping-everywhere spam.
- A broken combo does **not** cost a heart — it only resets the multiplier. Hearts are only lost on an actually invalid tap (tapping a blocked arrow). This keeps punishment and skill-expression as separate axes, which is the core retention hook: players chase flow, not survival.
- Reaching FLOW STATE on a level grants a bonus star and a small burst of the reward-ad currency (see 2.3).

### 2.2 Perfect Clear Rating
- 1–3 stars per level: 1 star = cleared, 2 stars = cleared with ≤1 mistake, 3 stars = cleared with 0 mistakes AND at least one FLOW STATE combo reached.
- Star totals unlock cosmetic arrow-skins and board themes (not power-ups — cosmetics only, so this never feels pay-to-win).

### 2.3 Soft Currency: "Sparks"
- Earned from stars, daily challenges, and FLOW STATE, or from watching a rewarded ad.
- Spend Sparks on: extra hint, cosmetic skins, or a one-time "second wind" (revive after losing all hearts, same level only, max once per level).
- No hard currency / no gacha. This is the config-driven economy — all values in `game_config.json -> economy`.

Document this system in `docs/GAME_DESIGN.md` with the exact numbers used.

## 3. TECH STACK

- Flutter (latest stable channel), null-safe, Dart 3.x.
- State management: **Riverpod** (or Bloc if the agent strongly prefers — pick one and be consistent; do not mix).
- Ads: `google_mobile_ads` (AdMob) — banner + rewarded only.
- Local persistence: `shared_preferences` for small flags, `hive` (or `sqflite`) for progress/level-completion records.
- Animation: `flutter_animate` or `rive`/`lottie` for celebration + arrow-exit effects.
- Audio: `audioplayers` or `just_audio`, short SFX only (tap, remove, combo tier-up, level complete). Music optional and toggle-able.
- Testing: `flutter_test` for solver/logic unit tests (this is the most important test surface — see §6).

## 4. PHASED BUILD PLAN (execute in this order)

**Phase 0 — Scaffolding**
- `flutter create` with correct package id (from config), set up folder structure (see file `02_FOLDER_STRUCTURE.md`), add dependencies, wire up `config/game_config.json` loading via a typed `AppConfig` class at boot in `main.dart`.

**Phase 1 — Core Puzzle Engine (pure Dart, no UI)**
- Implement the `Arrow` model, board grid, and the **blocked/selectable ray-cast algorithm** (see `03_LEVEL_AND_SOLVER_SPEC.md`).
- Implement the procedural level generator + a solver that verifies a generated level is 100% solvable before it's accepted (reject-and-regenerate loop).
- Write unit tests: solver correctness, generator always produces a solvable board, no false-positive "selectable" states.

**Phase 2 — Gameplay Screen UI**
- Board rendering, tap handling, exit animation, HUD (lives, difficulty pill, remaining-arrow counter, hint button, combo bar).
- Wire the engine from Phase 1 to the UI via Riverpod providers.

**Phase 3 — Meta Screens**
- Splash → Main Menu → Level Select (grid, 100 levels visible, scrollable, lazy) → Level Complete (custom celebration animation, star rating, next/main buttons) → Daily Challenge → Me/Profile (Awards, Achievements, Settings, Help, About, Privacy Rights, Privacy Preferences, Remove Ads) → Settings (audio, haptics, reset progress).

**Phase 4 — Combo / Sparks / Cosmetics**
- Momentum bar, Flow State, star rating logic, Sparks wallet, cosmetic skin picker (arrow color/board theme), unlock gating by star totals.

**Phase 5 — Ads Integration**
- Banner: persistent, bottom-safe-area, on Main Menu and Level Select only (not covering gameplay board).
- Rewarded: triggered from hint button (extra hint), from "second wind" revive, and from a Daily Challenge double-reward button.
- All ad unit IDs sourced from `game_config.json.ads`, with a `testMode` flag that swaps in Google's official test IDs automatically. Remove-Ads IAP flag (`monetization.removeAdsProductId`) hides the banner and disables the ad-gated (but not the Sparks-gated) content when purchased — stub the IAP call behind an interface so a real store SDK can be dropped in later.

**Phase 6 — Audio, Animation Polish, Haptics**
- Add all SFX hooks, celebration animation, subtle micro-haptics on tap/remove/combo-tier via `HapticFeedback`.

**Phase 7 — 100 Levels + Level Authoring Tooling**
- Ship with 100 generated + solver-validated levels bundled at build time (pre-baked JSON, not generated at runtime, so difficulty curve is controlled and QA'd). Provide a Dart script `tool/generate_levels.dart` that can regenerate/extend to any N (including 1000+) on demand — this is how "add levels easily" is satisfied without shipping 1000 files: the generator + a `levels_manifest.json` with `{count, difficultyCurveSeed}` is the only thing that changes.

**Phase 8 — QA Pass**
- Full run-through of acceptance criteria in §8 below. Fix everything before Phase 9.

**Phase 9 — Store-Readiness**
- App icons (adaptive icon for Android), splash screen, versioning wired to `app.version`/`app.buildNumber` in config, `tool/apply_branding.dart` run to sync `app.name`/`app.packageId` into `AndroidManifest.xml` (see §1.1), ProGuard/R8 config, signing config via `key.properties` (never commit the actual keystore or passwords), build `flutter build appbundle --release`, produce a debug/test `flutter build apk --release` too.
- Generate `docs/STORE_LISTING_CHECKLIST.md`: privacy policy URL requirement (ads + IAP require one), screenshots list, short/long description draft, content rating questionnaire notes, target API level compliance.

**Phase 10 — GitHub**
- Init repo, proper `.gitignore` for Flutter (exclude `/build`, `.dart_tool`, keystore, local.properties), meaningful commit history per phase (not one giant commit), a real `README.md` (setup, run, build, config guide, screenshots placeholder), and a `docs/` folder containing this whole prompt set plus the original reference PDF for provenance. Push to `main`.

## 5. UI / VISUAL DESIGN SYSTEM ("Quiet Depth")

- Base: soft neumorphism — light warm-gray background (`#EDEEF2` light mode / deep charcoal `#14151A` dark mode), elements raised via dual soft shadows (light top-left, dark bottom-right), never harsh drop shadows, never flat Material default surfaces.
- Arrows: solid dark navy (`#1B2340`) on light mode board, soft glow accent (single accent color from config, default electric teal `#00C2A8`) only on selectable/hinted arrows — this glow is the sole "loud" visual element, everything else stays quiet so it reads instantly.
- Typography: one clean geometric sans (e.g. Inter or Manrope via `google_fonts`), max two weights per screen.
- Motion: short (150–250ms) eased transitions everywhere; the arrow-exit animation should feel physical (slight ease-out acceleration off-board), not a generic fade.
- Celebration screen: custom radial-gradient burst + a restrained particle system (not confetti-emoji), built with Rive/Lottie or a lightweight custom `CustomPainter` — must be config-swappable per theme.
- No default Flutter `AlertDialog`/`SnackBar` chrome — build a matching custom bottom-sheet/dialog component once and reuse everywhere.
- Icons: one custom/consistent icon set (e.g. `phosphor_flutter` or hand-picked SVGs) — never mix icon families, never use raw emoji as UI icons.

## 6. TESTING REQUIREMENTS

- Unit tests for: ray-cast/blocked-detection algorithm, solver, level generator (must never emit unsolvable boards, must respect target arrow count/difficulty), combo timing state machine, star-rating calculation.
- Widget tests for: gameplay tap flow (tap selectable arrow removes it; tap blocked arrow loses a life, does not remove it), level-complete star display.
- Manual QA checklist (agent produces this in `docs/QA_CHECKLIST.md`) covering: no ad ever interrupts gameplay uninvited; banner never overlaps tappable board area; config changes (swap an ad ID, swap a color) actually propagate without code changes; app works with airplane mode on (ads fail gracefully, no crash).

## 7. LEVEL DATA — SEE `03_LEVEL_AND_SOLVER_SPEC.md`

Read that file for the exact JSON schema and the procedural-generation approach that keeps 1000 levels under ~500KB.

## 8. ACCEPTANCE CRITERIA (must all pass before calling this "done")

- [ ] `config/game_config.json` is the only place ad IDs, version, colors, gameplay tuning, and feature flags live; changing it changes app behavior with zero Dart edits.
- [ ] Only banner + rewarded ads exist anywhere in the codebase. Grep for interstitial/app-open ad code must return nothing.
- [ ] 100 levels ship, solver-validated, difficulty curve visibly increasing (arrow count/overlap grows).
- [ ] `tool/generate_levels.dart` can produce 1000 solvable levels on demand with total asset size under ~500KB.
- [ ] Momentum combo, Flow State, star rating, and Sparks economy all function end-to-end.
- [ ] No emoji anywhere in UI copy, icons, or code comments. No default Material purple theme.
- [ ] `flutter analyze` clean, all unit/widget tests pass.
- [ ] Signed release AAB + APK build successfully.
- [ ] GitHub repo pushed with phased commit history, README, and this docs/ folder including the original reference PDF.
- [ ] `docs/STORE_LISTING_CHECKLIST.md` and `docs/HOW_TO_ADD_LEVELS.md` and `docs/HOW_TO_RESKIN.md` exist and are accurate.

## 9. WHAT TO ASK THE HUMAN FOR (do not guess these)

- Final app name + package ID (`com.yourstudio.arrowflow` style).
- Real AdMob app ID + ad unit IDs (ship with Google test IDs until provided, `ads.testMode: true` by default).
- Keystore details for signing (never generate/commit a real production keystore for them silently).
- Privacy policy URL / support email for store listing.
- Accent color / brand direction if they want something other than the default teal-on-navy above.
