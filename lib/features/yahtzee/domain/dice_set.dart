class DiceSet {
  const DiceSet({required this.values, required this.held})
    : assert(values.length == 5, 'Yahtzee requires exactly 5 dice values.'),
      assert(held.length == 5, 'Yahtzee requires exactly 5 hold flags.');

  final List<int> values;
  final List<bool> held;

  DiceSet copyWith({List<int>? values, List<bool>? held}) {
    return DiceSet(values: values ?? this.values, held: held ?? this.held);
  }
}
