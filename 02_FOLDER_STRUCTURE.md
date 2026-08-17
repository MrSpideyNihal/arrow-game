# Folder Structure — Arrow Flow (Flutter)

Clean-architecture-lite: `core` (infra/shared) → `data` (models + persistence) → `domain` (pure game logic, no Flutter imports) → `presentation` (UI). This split is what makes the solver/generator independently unit-testable and keeps UI changes from ever touching game rules.

```
arrow_flow/
├── android/                         # standard Flutter android project (signing config wired to key.properties)
│                                     # (Android-only target — no ios/ folder needed)
├── config/
│   └── game_config.json             # SINGLE SOURCE OF TRUTH — see 04_CONFIG_SCHEMA.md
├── assets/
│   ├── audio/
│   │   ├── sfx_tap.wav
│   │   ├── sfx_remove.wav
│   │   ├── sfx_combo_tier.wav
│   │   ├── sfx_level_complete.wav
│   │   └── music_loop.mp3           # optional, toggle-able
│   ├── anim/
│   │   ├── celebration.riv          # or .json if using Lottie
│   │   └── arrow_glow.riv
│   ├── icons/                       # custom icon set (svg)
│   ├── fonts/
│   └── levels/
│       ├── levels_pack_001.json     # bundled, solver-validated (levels 1-100)
│       └── levels_manifest.json     # {count, difficultyCurveSeed, packFile}
├── lib/
│   ├── main.dart                    # loads config, boots app
│   ├── app.dart                     # MaterialApp/CupertinoApp shell, theming, routing
│   │
│   ├── core/
│   │   ├── config/
│   │   │   └── app_config.dart      # typed model + loader for game_config.json
│   │   ├── theme/
│   │   │   ├── app_theme.dart       # neumorphism theme built FROM config colors
│   │   │   └── app_typography.dart
│   │   ├── services/
│   │   │   ├── ads_service.dart     # banner + rewarded only, config-driven IDs
│   │   │   ├── audio_service.dart
│   │   │   ├── haptics_service.dart
│   │   │   ├── storage_service.dart # hive/sqflite wrapper
│   │   │   └── iap_service.dart     # stub interface for Remove Ads purchase
│   │   ├── routing/
│   │   │   └── app_router.dart
│   │   └── utils/
│   │       └── result.dart          # small Result<T> / error handling helper
│   │
│   ├── data/
│   │   ├── models/
│   │   │   ├── arrow_model.dart
│   │   │   ├── level_model.dart
│   │   │   ├── player_progress_model.dart
│   │   │   └── economy_model.dart   # Sparks balance, cosmetic unlocks
│   │   └── repositories/
│   │       ├── level_repository.dart      # reads bundled packs + manifest
│   │       ├── progress_repository.dart   # persisted via storage_service
│   │       └── economy_repository.dart
│   │
│   ├── domain/                       # PURE DART — no Flutter/material imports, fully unit-testable
│   │   ├── engine/
│   │   │   ├── arrow_solver.dart     # ray-cast / blocked-detection algorithm
│   │   │   ├── level_generator.dart  # procedural generation + reject-unsolvable loop
│   │   │   └── level_validator.dart
│   │   └── systems/
│   │       ├── combo_engine.dart     # momentum bar / flow-state state machine
│   │       ├── star_rating.dart
│   │       └── economy_engine.dart   # sparks earn/spend rules
│   │
│   ├── presentation/
│   │   ├── screens/
│   │   │   ├── splash/
│   │   │   ├── main_menu/
│   │   │   ├── level_select/
│   │   │   ├── gameplay/
│   │   │   │   ├── gameplay_screen.dart
│   │   │   │   ├── widgets/
│   │   │   │   │   ├── board_view.dart
│   │   │   │   │   ├── arrow_widget.dart
│   │   │   │   │   ├── hud_bar.dart
│   │   │   │   │   ├── momentum_bar.dart
│   │   │   │   │   └── hint_button.dart
│   │   │   ├── level_complete/
│   │   │   ├── daily_challenge/
│   │   │   ├── profile_me/          # Awards, Achievements, Settings, Help, About, Privacy, Remove Ads
│   │   │   └── settings/
│   │   ├── widgets/                 # shared components (custom dialog, custom button, banner slot)
│   │   └── state/                   # riverpod providers/notifiers, one file per feature
│   │
│   └── l10n/                        # copy strings (keep all UI text out of widgets for easy edits)
│
├── tool/
│   ├── generate_levels.dart         # CLI script: generate N solver-validated levels into assets/levels
│   └── apply_branding.dart          # CLI script: syncs app.name/app.packageId from config into
│                                     # AndroidManifest.xml before every release build
│
├── test/
│   ├── domain/
│   │   ├── arrow_solver_test.dart
│   │   ├── level_generator_test.dart
│   │   └── combo_engine_test.dart
│   └── widget/
│       └── gameplay_flow_test.dart
│
├── docs/
│   ├── reference/
│   │   └── Arrow_Puzzle_Gameplay_Feature_Specification.pdf   # original source spec, kept for provenance
│   ├── GAME_DESIGN.md
│   ├── HOW_TO_ADD_LEVELS.md
│   ├── HOW_TO_RESKIN.md
│   ├── STORE_LISTING_CHECKLIST.md
│   └── QA_CHECKLIST.md
│
├── key.properties.example           # template only — real one is gitignored
├── pubspec.yaml
├── analysis_options.yaml
├── .gitignore
└── README.md
```

## Key structural rules

- `domain/` never imports `package:flutter/*`. This is what lets the puzzle solver/generator be tested in pure Dart in milliseconds and reused (e.g. server-side level QA) later.
- Every screen's copy strings live in `l10n/`, not inline in widgets — makes re-skinning/translation trivial.
- `core/services/ads_service.dart` is the *only* file allowed to import the AdMob package. If interstitials ever get added by mistake, this isolation makes it a one-file grep-and-check.
- `tool/generate_levels.dart` is the only place level *count* is decided (via CLI arg or config) — this is how you go from 100 to 1000 levels without touching game code.
- `tool/apply_branding.dart` is the only place the app name/package ID cross from config into native project files — run it before every build so `config/game_config.json -> app.name` is the true single source of truth, including for the installed app label, not just in-app text.
