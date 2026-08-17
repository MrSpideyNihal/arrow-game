import 'dart:convert';
import 'dart:io';
import 'data/models/arrow_model.dart';
import 'data/models/level_model.dart';
import 'domain/engine/arrow_solver.dart';

void main() {
  final j = jsonDecode(File('assets/levels/levels_pack_001.json').readAsStringSync()) as List;
  
  int deadlockCount = 0;
  int sparseCount = 0;
  
  for (int i = 0; i < j.length; i++) {
    final levelJson = j[i];
    final level = Level.fromJson(levelJson as Map<String, dynamic>);
    final sel = ArrowSolver.findAllSelectable(level.arrows, level.gridWidth, level.gridHeight);
    final totalCells = level.arrows.fold(0, (s, a) => s + a.cells.length);
    final coverage = totalCells / (level.gridWidth * level.gridHeight);
    
    bool solvable = false;
    if (sel.isNotEmpty) {
      solvable = ArrowSolver.isSolvable(level);
    }
    
    if (sel.isEmpty || !solvable) {
      deadlockCount++;
      print('DEADLOCK L${i+1}: ${level.arrows.length} arrows, ${sel.length} selectable, ${(coverage*100).toStringAsFixed(1)}% fill, solvable=$solvable');
    }
    
    if (coverage < 0.85) {
      sparseCount++;
      if (sel.isNotEmpty && solvable) {
        print('SPARSE L${i+1}: ${level.arrows.length} arrows, ${sel.length} selectable, ${(coverage*100).toStringAsFixed(1)}% fill');
      }
    }
    
    if ((i+1) % 100 == 0) print('Checked ${i+1}/500...');
  }
  
  print('');
  print('Total deadlock levels: $deadlockCount / 500');
  print('Total sparse levels (< 85% fill): $sparseCount / 500');
}
