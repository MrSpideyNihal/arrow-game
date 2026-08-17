import 'dart:math';
import '../../data/models/arrow_model.dart';
import '../../data/models/level_model.dart';
import 'arrow_solver.dart';

/// Progressive procedural level generator with Super Ultra Hard Boss levels every 5 levels.
class LevelGenerator {
  static Level generate(int levelId, int seed) {
    final rng = Random(seed + levelId * 99991);
    
    final (String diff, int gW, int gH) = _getGridParamsForLevel(levelId);

    Level level;
    while (true) {
      level = _generateLabyrinthLevel(levelId, diff, gW, gH, rng);
      if (ArrowSolver.isSolvable(level)) {
        return level;
      }
    }
  }

  static (String, int, int) _getGridParamsForLevel(int id) {
    final isBoss = id % 5 == 0;

    if (isBoss) {
      // Super Ultra Hard Boss Level every 5 levels!
      final bossIndex = id ~/ 5;
      int bW, bH;
      if (bossIndex == 1) { // Level 5
        bW = 12; bH = 15;
      } else if (bossIndex == 2) { // Level 10
        bW = 14; bH = 18;
      } else if (bossIndex == 3) { // Level 15
        bW = 16; bH = 20;
      } else if (bossIndex == 4) { // Level 20
        bW = 18; bH = 22;
      } else if (bossIndex <= 10) { // Level 25-50
        bW = 20; bH = 25;
      } else { // Level 55+
        bW = 22; bH = 28;
      }
      return ('BOSS', bW, bH);
    }

    String diff;
    int gW, gH;
    if (id <= 5) {
      diff = 'Normal';
      gW = 7; gH = 9;
    } else if (id <= 15) {
      diff = 'Normal';
      gW = 8; gH = 10;
    } else if (id <= 35) {
      diff = 'Hard';
      gW = 10; gH = 12;
    } else if (id <= 75) {
      diff = 'Expert';
      gW = 13; gH = 17;
    } else if (id <= 150) {
      diff = 'Master';
      gW = 21; gH = 27;
    } else {
      diff = 'Grandmaster';
      gW = 22; gH = 28;
    }

    return (diff, gW, gH);
  }

  static List<Level> generateBatch(int startIndex, int count, int curveSeed) {
    return List.generate(count, (i) => generate(startIndex + i, curveSeed));
  }
}

Level _generateLabyrinthLevel(int id, String diff, int gW, int gH, Random r) {
  final cellLayer = List.generate(gH, (_) => List.filled(gW, -1));
  final arrows = <Arrow>[];
  int arrowId = 1;

  final totalCells = gW * gH;

  for (int layer = 0; layer < 35; layer++) {
    int minLen = layer <= 2 ? 5 : (layer <= 8 ? 4 : (layer <= 16 ? 3 : 2));
    int maxLen = layer <= 2 ? 10 : (layer <= 8 ? 8 : (layer <= 16 ? 5 : 3));
    if (gW < 9) {
      minLen = minLen.clamp(2, 5);
      maxLen = maxLen.clamp(minLen, 7);
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
      dirs.sort((a, b) {
        int matchA = arrows.where((ar) => (ar.head.$1 - pt.x).abs() <= 1 && (ar.head.$2 - pt.y).abs() <= 1 && ar.direction == a).length;
        int matchB = arrows.where((ar) => (ar.head.$1 - pt.x).abs() <= 1 && (ar.head.$2 - pt.y).abs() <= 1 && ar.direction == b).length;
        return matchA.compareTo(matchB);
      });

      for (final dir in dirs) {
        if (layer < 10 && _isTooCloseParallel(pt, dir, arrows, gW, gH)) continue;
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
    if (filled / totalCells >= 0.98) break;
  }

  _growLabyrinthTails(cellLayer, arrows, gW, gH);

  return Level(
    id: id,
    difficulty: diff,
    gridWidth: gW,
    gridHeight: gH,
    arrows: arrows,
  );
}

bool _isTooCloseParallel(Point<int> pt, Direction dir, List<Arrow> arrows, int gW, int gH) {
  for (final ar in arrows) {
    if (ar.direction != dir) continue;

    // On outer border: spacing between same-direction heads must be at least 3
    if ((dir == Direction.right && pt.x == gW - 1 && ar.head.$1 == gW - 1) ||
        (dir == Direction.left && pt.x == 0 && ar.head.$1 == 0)) {
      if ((ar.head.$2 - pt.y).abs() < 3) return true;
    }
    if ((dir == Direction.down && pt.y == gH - 1 && ar.head.$2 == gH - 1) ||
        (dir == Direction.up && pt.y == 0 && ar.head.$2 == 0)) {
      if ((ar.head.$1 - pt.x).abs() < 3) return true;
    }

    // Adjacent parallel heads in the grid
    if (dir == Direction.left || dir == Direction.right) {
      if (ar.head.$1 == pt.x && (ar.head.$2 - pt.y).abs() <= 1) return true;
    } else {
      if (ar.head.$2 == pt.y && (ar.head.$1 - pt.x).abs() <= 1) return true;
    }
  }
  return false;
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
  int desiredStraight = 2 + r.nextInt(3);

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
      pick = straightCandidate;
      straightSteps++;
    } else {
      final turnCandidates = neighbors.where((n) => n != straightCandidate).toList();
      if (turnCandidates.isNotEmpty) {
        turnCandidates.sort((a, b) {
          final openA = _countEmpty(a, cellLayer, gW, gH);
          final openB = _countEmpty(b, cellLayer, gW, gH);
          return openB.compareTo(openA);
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
  while (grew && pass < 30) {
    grew = false;
    pass++;
    for (int y = 0; y < gH; y++) {
      for (int x = 0; x < gW; x++) {
        if (cellLayer[y][x] == -1) {
          if (exitRays.contains((x, y))) continue;

          for (final arrow in arrows) {
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
