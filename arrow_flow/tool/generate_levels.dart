// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:arrow_flow/data/models/level_model.dart';
import 'package:arrow_flow/domain/engine/level_generator.dart';
import 'package:arrow_flow/domain/engine/level_validator.dart';
import 'package:arrow_flow/domain/engine/arrow_solver.dart';

/// CLI Tool: Generates N solver-validated levels and bakes them into JSON asset packs.
///
/// Usage:
///   dart tool/generate_levels.dart [count] [seed]
/// Example:
///   dart tool/generate_levels.dart 100 20260809
void main(List<String> args) async {
  final count = args.isNotEmpty ? int.parse(args[0]) : 100;
  final seed = args.length > 1 ? int.parse(args[1]) : 20260809;

  print('Generating $count solver-validated levels with seed $seed...');

  final levels = <Level>[];
  final startTime = DateTime.now();

  for (int i = 1; i <= count; i++) {
    final level = LevelGenerator.generate(i, seed);

    // Double check solvability and validity
    final errors = LevelValidator.validate(level);
    if (errors.isNotEmpty) {
      print('ERROR on level $i: $errors');
      exit(1);
    }
    if (!ArrowSolver.isSolvable(level)) {
      print('ERROR: Generated unsolvable level $i');
      exit(1);
    }

    levels.add(level);
    if (i % 25 == 0 || i == count) {
      print('  Generated $i / $count levels...');
    }
  }

  final elapsed = DateTime.now().difference(startTime).inMilliseconds;
  print('All $count levels generated and validated in ${elapsed}ms.');

  // Output compact JSON
  final packJson = jsonEncode(levels.map((l) => l.toJson()).toList());
  final packPath = 'assets/levels/levels_pack_001.json';
  final packFile = File(packPath);
  await packFile.parent.create(recursive: true);
  await packFile.writeAsString(packJson);

  final sizeInKb = (packFile.lengthSync() / 1024).toStringAsFixed(1);
  print('Saved $packPath ($sizeInKb KB).');

  // Output manifest JSON
  final manifestJson = jsonEncode({
    'packVersion': 1,
    'totalLevels': count,
    'difficultyCurveSeed': seed,
    'packs': [
      {
        'file': 'levels_pack_001.json',
        'count': count,
        'levelRange': [1, count],
        'difficultyCurveSeed': seed,
      }
    ]
  });

  final manifestPath = 'assets/levels/levels_manifest.json';
  final manifestFile = File(manifestPath);
  await manifestFile.writeAsString(manifestJson);
  print('Saved $manifestPath.');
}
