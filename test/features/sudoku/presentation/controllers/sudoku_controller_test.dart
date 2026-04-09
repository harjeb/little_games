import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_demo/features/sudoku/presentation/controllers/sudoku_controller.dart';

void main() {
  test(
    'toggleNoteMode and placeDigit in note mode records a candidate note',
    () {
      final container = ProviderContainer(
        overrides: [sudokuRandomProvider.overrideWithValue(Random(0))],
      );
      addTearDown(container.dispose);

      final notifier = container.read(sudokuControllerProvider.notifier);
      final initial = container.read(sudokuControllerProvider);
      final selectedIndex = initial.selectedIndex!;

      notifier.toggleNoteMode();
      notifier.placeDigit(1);

      final state = container.read(sudokuControllerProvider);
      expect(state.isNoteMode, isTrue);
      expect(state.cells[selectedIndex].notes, contains(1));
      expect(state.cells[selectedIndex].value, isNull);
    },
  );

  test('useHint fills the selected editable cell with its solution', () {
    final container = ProviderContainer(
      overrides: [sudokuRandomProvider.overrideWithValue(Random(0))],
    );
    addTearDown(container.dispose);

    final notifier = container.read(sudokuControllerProvider.notifier);
    final initial = container.read(sudokuControllerProvider);
    final selectedIndex = initial.selectedIndex!;
    final expectedValue = initial.cells[selectedIndex].solutionValue;

    notifier.useHint();

    final state = container.read(sudokuControllerProvider);
    expect(state.cells[selectedIndex].value, expectedValue);
    expect(state.cells[selectedIndex].notes, isEmpty);
    expect(state.isNoteMode, isFalse);
  });
}
