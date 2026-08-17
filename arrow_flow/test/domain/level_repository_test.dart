import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_flow/core/config/app_config.dart';
import 'package:arrow_flow/data/repositories/level_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LevelRepository', () {
    const config = LevelsConfig(
      bundledCount: 100,
      bundledPackFile: 'assets/levels/levels_pack_001.json',
      generatedTargetCount: 1000,
      difficultyCurveSeed: 20260809,
      cacheGeneratedLevelsLocally: true,
    );

    final repo = LevelRepository(config: config);

    test('procedurally generates level when outside bundled range', () async {
      final level101 = await repo.getLevel(101);
      expect(level101.id, 101);
      expect(level101.arrows.isNotEmpty, isTrue);
    });
  });
}
