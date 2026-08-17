import 'dart:math';
import 'data/models/arrow_model.dart';
import 'data/models/level_model.dart';
import 'domain/engine/arrow_solver.dart';

void main() {
  final rng = Random(12345);
  print('Testing 100% Strict Layered Peeling Gap-Free Generator...');

  final sw = Stopwatch()..start();
  for (int lvl = 1; lvl <= 100; lvl += 15) {
    int gW = (7 + (lvl ~/ 5) * 0.70).floor().clamp(7, 20);
    int gH = (9 + (lvl ~/ 5) * 0.85).floor().clamp(9, 25);

    final level = generateStrictLayeredLevel(lvl, gW, gH, rng);
    final totalCells = level.arrows.fold(0, (s, a) => s + a.cells.length);
    final coverage = (totalCells / (gW * gH) * 100).toStringAsFixed(1);
    final avgLen = totalCells / level.arrows.length;
    final solvable = ArrowSolver.isSolvable(level);

    print('Level $lvl [${gW}x${gH}]: ${level.arrows.length} arrows (avg ${avgLen.toStringAsFixed(1)} cells), $coverage% fill (Solvable: $solvable)');
  }
  sw.stop();
  print('Completed in ${sw.elapsedMilliseconds} ms');
}

Level generateStrictLayeredLevel(int id, int gW, int gH, Random r) {
  final cellLayer = List.generate(gH, (_) => List.filled(gW, -1));
  final arrows = <Arrow>[];
  int arrowId = 1;

  final totalCells = gW * gH;

  for (int layer = 0; layer < 20; layer++) {
    int minLen = layer <= 2 ? 4 : (layer <= 6 ? 3 : 2);
    int maxLen = layer <= 2 ? 7 : (layer <= 6 ? 5 : 4);

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

        final path = _windLayerPath(pt, dir, minLen, maxLen, cellLayer, gW, gH, r);
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
    if (filled / totalCells >= 0.94) break;
  }

  _growStrictTails(cellLayer, arrows, gW, gH);

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
    // If ray hits an empty cell (-1) or a cell from current/higher layer, it's NOT allowed.
    // Ray MUST travel through cells already placed in LOWER layers (< currentLayer) that clear first!
    if (layer == -1 || layer >= currentLayer) return false;
    cx += dx;
    cy += dy;
  }
  return true;
}

List<Point<int>>? _windLayerPath(
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

  int consecutiveStraight = 1;

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

    neighbors.sort((a, b) {
      final openA = _countEmpty(a, cellLayer, gW, gH);
      final openB = _countEmpty(b, cellLayer, gW, gH);
      return openB.compareTo(openA);
    });

    Point<int> pick;
    if (path.length >= 2) {
      final prev = path[path.length - 2];
      final straightDir = Point(cur.x - prev.x, cur.y - prev.y);
      final straightCandidate = Point(cur.x + straightDir.x, cur.y + straightDir.y);

      final turnCandidates = neighbors.where((n) => n != straightCandidate).toList();

      if (consecutiveStraight >= 2 && turnCandidates.isNotEmpty) {
        pick = turnCandidates.first;
        consecutiveStraight = 1;
      } else if (turnCandidates.isNotEmpty && r.nextDouble() < 0.70) {
        pick = turnCandidates.first;
        consecutiveStraight = 1;
      } else {
        pick = neighbors.first;
        if (pick == straightCandidate) {
          consecutiveStraight++;
        } else {
          consecutiveStraight = 1;
        }
      }
    } else {
      pick = neighbors.first;
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

void _growStrictTails(List<List<int>> cellLayer, List<Arrow> arrows, int gW, int gH) {
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
  while (grew && pass < 6) {
    grew = false;
    pass++;
    for (int y = 0; y < gH; y++) {
      for (int x = 0; x < gW; x++) {
        if (cellLayer[y][x] == -1) {
          if (exitRays.contains((x, y))) continue;

          for (final arrow in arrows) {
            if (arrow.cells.length >= 10) continue;
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
