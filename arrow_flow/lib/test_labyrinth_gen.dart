import 'dart:math';
import 'data/models/arrow_model.dart';
import 'data/models/level_model.dart';
import 'domain/engine/arrow_solver.dart';

/// LABYRINTH SPIRAL GENERATOR
/// Generates long serpentine winding arrows that wrap around each other
/// with 0 gaps, matching the exact puzzle aesthetic in the user reference image!

void main() {
  final rng = Random(42);
  print('Testing Long Serpentine Labyrinth Generator...');

  final sw = Stopwatch()..start();
  for (int lvl = 1; lvl <= 100; lvl += 20) {
    int gW = (7 + (lvl ~/ 5) * 0.70).floor().clamp(7, 20);
    int gH = (9 + (lvl ~/ 5) * 0.85).floor().clamp(9, 26);

    final level = generateLabyrinthLevel(lvl, gW, gH, rng);
    final totalCells = level.arrows.fold(0, (s, a) => s + a.cells.length);
    final coverage = (totalCells / (gW * gH) * 100).toStringAsFixed(1);
    final avgLen = level.arrows.isEmpty ? 0.0 : totalCells / level.arrows.length;
    final solvable = ArrowSolver.isSolvable(level);

    print('Level $lvl [${gW}x${gH}]: ${level.arrows.length} arrows (avg ${avgLen.toStringAsFixed(1)} cells), $coverage% fill (Solvable: $solvable)');
  }
  sw.stop();
  print('Completed in ${sw.elapsedMilliseconds} ms');
}

Level generateLabyrinthLevel(int id, int gW, int gH, Random r) {
  final cellLayer = List.generate(gH, (_) => List.filled(gW, -1));
  final arrows = <Arrow>[];
  int arrowId = 1;

  final totalCells = gW * gH;

  // We peel layer by layer, prioritizing long straight corridors and serpentine wraps
  for (int layer = 0; layer < 30; layer++) {
    // Target very long arrows (6 to 14 cells long!)
    int minLen = layer <= 2 ? 6 : (layer <= 6 ? 5 : (layer <= 12 ? 4 : 2));
    int maxLen = layer <= 2 ? 14 : (layer <= 6 ? 10 : (layer <= 12 ? 7 : 4));
    if (gW < 9) {
      minLen = minLen.clamp(2, 6);
      maxLen = maxLen.clamp(minLen, 8);
    }

    final emptyCells = <Point<int>>[];
    for (int y = 0; y < gH; y++) {
      for (int x = 0; x < gW; x++) {
        if (cellLayer[y][x] == -1) emptyCells.add(Point(x, y));
      }
    }
    if (emptyCells.isEmpty) break;
    emptyCells.shuffle(r);

    for (final pt in emptyCells) {
      if (cellLayer[pt.y][pt.x] != -1) continue;

      final dirs = List.of(Direction.values)..shuffle(r);
      for (final dir in dirs) {
        if (!_canRayExitStrictly(pt, dir, cellLayer, layer, gW, gH)) continue;

        final path = _windLabyrinthPath(pt, dir, minLen, maxLen, cellLayer, gW, gH, r);
        if (path != null && path.length >= minLen) {
          final cells = path.reversed.map((p) => (p.x, p.y)).toList();
          arrows.add(Arrow(id: arrowId++, cells: cells, direction: dir));

          for (final p in path) {
            cellLayer[p.y][p.x] = layer;
          }
          break;
        }
      }
    }

    int filled = arrows.fold(0, (sum, a) => sum + a.cells.length);
    if (filled / totalCells >= 0.96) break;
  }

  // Extend tails along walls to fill any 1-cell gaps completely
  _growLabyrinthTails(cellLayer, arrows, gW, gH);

  return Level(
    id: id,
    difficulty: id <= 15 ? 'Normal' : (id <= 40 ? 'Hard' : (id <= 75 ? 'Expert' : 'Master')),
    gridWidth: gW,
    gridHeight: gH,
    arrows: arrows,
  );
}

bool _canRayExitStrictly(Point<int> head, Direction dir, List<List<int>> cellLayer, int currentLayer, int gW, int gH) {
  final (dx, dy) = dir.delta;
  int cx = head.x + dx;
  int cy = head.y + dy;
  while (cx >= 0 && cx < gW && cy >= 0 && cy < gH) {
    final layer = cellLayer[cy][cx];
    if (layer == -1 || layer >= currentLayer) return false;
    cx += dx;
    cy += dy;
  }
  return true;
}

List<Point<int>>? _windLabyrinthPath(
    Point<int> head, Direction dir, int minLen, int maxLen,
    List<List<int>> cellLayer, int gW, int gH, Random r) {
  final path = <Point<int>>[head];
  final (dx, dy) = dir.delta;

  final backX = head.x - dx;
  final backY = head.y - dy;
  if (backX < 0 || backX >= gW || backY < 0 || backY >= gH || cellLayer[backY][backX] != -1) {
    return null;
  }
  path.add(Point(backX, backY));

  int targetLen = minLen == maxLen ? minLen : minLen + r.nextInt(maxLen - minLen + 1);
  Point<int> cur = Point(backX, backY);
  final localVisited = <String>{'${head.x},${head.y}', '$backX,$backY'};

  Point<int> currentDir = Point(-dx, -dy);
  int straightSteps = 1;
  int desiredStraight = 3 + r.nextInt(4); // Run 3 to 6 straight cells before turning (like reference image!)

  while (path.length < targetLen) {
    final neighbors = <Point<int>>[];
    for (final d in [const Point(0,-1), const Point(0,1), const Point(-1,0), const Point(1,0)]) {
      final nx = cur.x + d.x;
      final ny = cur.y + d.y;
      if (nx >= 0 && nx < gW && ny >= 0 && ny < gH &&
          cellLayer[ny][nx] == -1 && !localVisited.contains('$nx,$ny')) {
        neighbors.add(Point(nx, ny));
      }
    }
    if (neighbors.isEmpty) break;

    Point<int> pick;
    final straightCandidate = Point(cur.x + currentDir.x, cur.y + currentDir.y);
    final canGoStraight = neighbors.contains(straightCandidate);

    if (canGoStraight && straightSteps < desiredStraight) {
      // Continue along the long straight corridor!
      pick = straightCandidate;
      straightSteps++;
    } else {
      // Time to make a 90-degree turn!
      final turnCandidates = neighbors.where((n) => n != straightCandidate).toList();
      if (turnCandidates.isNotEmpty) {
        // Pick turn candidate that hugs existing walls for tight nesting
        turnCandidates.sort((a, b) {
          final openA = _countEmpty(a, cellLayer, gW, gH);
          final openB = _countEmpty(b, cellLayer, gW, gH);
          return openA.compareTo(openB);
        });
        pick = turnCandidates.first;
        currentDir = Point(pick.x - cur.x, pick.y - cur.y);
        straightSteps = 1;
        desiredStraight = 2 + r.nextInt(4);
      } else if (canGoStraight) {
        pick = straightCandidate;
        straightSteps++;
      } else {
        pick = neighbors.first;
        currentDir = Point(pick.x - cur.x, pick.y - cur.y);
        straightSteps = 1;
      }
    }

    localVisited.add('${pick.x},${pick.y}');
    path.add(pick);
    cur = pick;
  }

  return path.length >= minLen ? path : null;
}

int _countEmpty(Point<int> p, List<List<int>> cellLayer, int gW, int gH) {
  int count = 0;
  for (final d in [const Point(0,-1), const Point(0,1), const Point(-1,0), const Point(1,0)]) {
    final nx = p.x + d.x;
    final ny = p.y + d.y;
    if (nx >= 0 && nx < gW && ny >= 0 && ny < gH && cellLayer[ny][nx] == -1) {
      count++;
    }
  }
  return count;
}

void _growLabyrinthTails(List<List<int>> cellLayer, List<Arrow> arrows, int gW, int gH) {
  final exitRays = <(int, int)>{};
  for (final arrow in arrows) {
    final (dx, dy) = arrow.direction.delta;
    var cx = arrow.head.$1 + dx;
    var cy = arrow.head.$2 + dy;
    while (cx >= 0 && cx < gW && cy >= 0 && cy < gH) {
      exitRays.add((cx, cy));
      cx += dx;
      cy += dy;
    }
  }

  bool grew = true;
  int pass = 0;
  while (grew && pass < 8) {
    grew = false;
    pass++;
    for (int y = 0; y < gH; y++) {
      for (int x = 0; x < gW; x++) {
        if (cellLayer[y][x] == -1) {
          if (exitRays.contains((x, y))) continue;

          for (final arrow in arrows) {
            if (arrow.cells.length >= 18) continue;
            final (tx, ty) = arrow.cells.first; // TAIL is cells.first
            if ((tx - x).abs() + (ty - y).abs() == 1) {
              arrow.cells.insert(0, (x, y));
              cellLayer[y][x] = 99;
              grew = true;
              break;
            }
          }
        }
      }
    }
  }
}
