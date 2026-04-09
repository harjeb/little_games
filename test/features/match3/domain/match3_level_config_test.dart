import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_demo/features/match3/domain/match3_level_config.dart';

void main() {
  test('match3 ships with 10 documented level configs', () {
    expect(Match3LevelConfig.defaults, hasLength(10));
    expect(Match3LevelConfig.defaults.first.id, 1);
    expect(Match3LevelConfig.defaults.last.id, 10);
  });
}
