import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(localizations != null, 'AppLocalizations is not available in context.');
    return localizations!;
  }

  bool get isChinese => locale.languageCode == 'zh';

  String get appTitle => isChinese ? '掌上游乐屋' : 'Pocket Playroom';
  String get languageLabel => isChinese ? '语言' : 'Language';
  String get englishLabel => 'English';
  String get chineseLabel => '中文';
  String get homeTagline => isChinese
      ? '一个柔和又轻快的小型游戏厅，适合随时来一局，刷新分数。'
      : 'A soft little arcade for quick wins, lucky streaks, and replay-worthy scores.';
  String get androidFirst => isChinese ? '安卓优先' : 'Android First';
  String get singlePlayer => isChinese ? '单人游玩' : 'Single-Player';
  String get clayUi => isChinese ? '黏土风界面' : 'Clay UI';
  String get gameShelf => isChinese ? '游戏列表' : 'Game Shelf';
  String get noRecordYet => isChinese ? '暂无记录' : 'No record yet';
  String get recordUnavailable => isChinese ? '记录不可用' : 'Record unavailable';
  String get loading => isChinese ? '加载中...' : 'Loading...';
  String get bestScore => isChinese ? '最高分' : 'Best Score';
  String get bestTime => isChinese ? '最佳时间' : 'Best Time';
  String get playYahtzee => isChinese ? '开始 Yahtzee' : 'Play Yahtzee';
  String get play2048 => isChinese ? '开始 2048' : 'Play 2048';
  String get playSudoku => isChinese ? '开始数独' : 'Play Sudoku';
  String get yahtzeeDescription => isChinese
      ? '掷出五枚骰子，锁住想保留的点数，挑战完整的 13 轮计分表。'
      : 'Roll five dice, lock your picks, and chase the perfect 13-round sheet.';
  String get game2048Description => isChinese
      ? '滑动棋盘、连续合并数字，把更高的发光方块一路推上去。'
      : 'Swipe the grid, chain merges, and push one glowing tile after another.';
  String get sudokuDescription => isChinese
      ? '选择难度、填满九宫格，挑战更快更稳的通关时间。'
      : 'Pick a difficulty, fill the grid, and chase your cleanest completion time.';
  String get shortEasy => isChinese ? '简' : 'E';
  String get shortMedium => isChinese ? '中' : 'M';
  String get shortHard => isChinese ? '难' : 'H';

  String get back => isChinese ? '返回' : 'Back';
  String get newRun => isChinese ? '重新开始' : 'New Run';
  String get diceTray => isChinese ? '骰盘' : 'Dice Tray';
  String get diceTrayHint => isChinese
      ? '点击骰子可保留该点数。保留的骰子在重掷时不会变化。'
      : 'Tap a die to hold it. Held dice stay put during rerolls.';
  String rerollsUsed(int used, int max) => isChinese
      ? '已重掷：$used / $max'
      : 'Rerolls used: $used / $max';
  String get noRerollsLeft => isChinese ? '本轮无重掷次数' : 'No rerolls left';
  String get rerollDice => isChinese ? '重掷骰子' : 'Reroll Dice';
  String get scoreSheet => isChinese ? '计分表' : 'Score Sheet';
  String get scoreSheetHint => isChinese
      ? '每一轮必须锁定一个计分类别。'
      : 'Every round, you must lock in exactly one category.';
  String get yahtzeeRun => isChinese ? 'Yahtzee 对局' : 'Yahtzee Run';
  String roundLabel(int current, int total) =>
      isChinese ? '第 $current / $total 轮' : 'Round $current / $total';
  String get total => isChinese ? '总分' : 'Total';
  String get upperBonus => isChinese ? '上区奖励' : 'Upper Bonus';
  String get extraYahtzeeShort => isChinese ? '额外 YZ' : 'Extra YZ';
  String get scoreSnapshot => isChinese ? '得分概览' : 'Score Snapshot';
  String get upperSectionSubtotal =>
      isChinese ? '上区小计' : 'Upper section subtotal';
  String get upperSectionBonus =>
      isChinese ? '上区奖励' : 'Upper section bonus';
  String get extraYahtzeeBonus =>
      isChinese ? '额外 Yahtzee 奖励' : 'Extra Yahtzee bonus';
  String get runningTotal => isChinese ? '当前总分' : 'Running total';
  String get lockedIn => isChinese ? '已锁定' : 'Locked in';
  String get tapToScoreThisRound =>
      isChinese ? '点击在本轮记入该项' : 'Tap to score this round';
  String get scored => isChinese ? '已记分' : 'Scored';
  String get preview => isChinese ? '预览' : 'Preview';

  String get yahtzeeFreshHighScore =>
      isChinese ? '刷新最高分！' : 'Fresh High Score!';
  String get runComplete => isChinese ? '本局结束' : 'Run Complete';
  String finalScoreLabel(int score) =>
      isChinese ? '最终得分：$score' : 'Final score: $score';
  String upperBonusChip(int score) =>
      isChinese ? '上区奖励 $score' : 'Upper bonus $score';
  String extraYahtzeeChip(int score) =>
      isChinese ? '额外 Yahtzee $score' : 'Extra Yahtzee $score';
  String bestChip(int score) => isChinese ? '最佳 $score' : 'Best $score';
  String get playAgain => isChinese ? '再来一局' : 'Play Again';
  String get backHome => isChinese ? '返回首页' : 'Back Home';
  String yahtzeeResultMessage({
    required bool isNewRecord,
    required int? previousBest,
  }) {
    if (isNewRecord) {
      return isChinese
          ? '你刷新了自己的最高分，首页排行榜也已经同步更新。'
          : 'You beat your previous best and the home screen leaderboard has been updated.';
    }
    if (previousBest == null) {
      return isChinese
          ? '这是你第一次保存 Yahtzee 成绩。'
          : 'This is your first stored Yahtzee result.';
    }
    return isChinese
        ? '当前最高分仍然是 $previousBest，再来一局试试看。'
        : 'Your best score is still $previousBest. Try another run to beat it.';
  }

  String get game2048Title => isChinese ? '2048 光格' : '2048 Glow Grid';
  String get game2048Hint => isChinese
      ? '滑动棋盘，合并相同数字，尽可能冲击更高分。'
      : 'Swipe the board, combine matching tiles, and bank the best score you can.';
  String get score => isChinese ? '分数' : 'Score';
  String get best => isChinese ? '最佳' : 'Best';
  String get noRecord => isChinese ? '暂无记录' : 'No record';
  String get unavailable => isChinese ? '不可用' : 'Unavailable';
  String get newGame => isChinese ? '新游戏' : 'New Game';
  String get finishRun => isChinese ? '结束本局' : 'Finish Run';
  String get hit2048 => isChinese ? '达到 2048' : 'You hit 2048';
  String get noMovesLeft => isChinese ? '没有可移动的格子' : 'No moves left';
  String get hit2048Hint => isChinese
      ? '你可以继续冲分，也可以现在保存成绩。'
      : 'Keep the run alive or save it right now.';
  String get noMovesLeftHint => isChinese
      ? '保存这次成绩，或者直接开一盘新棋局。'
      : 'Save the score or jump into a fresh board.';
  String get keepGoing => isChinese ? '继续冲分' : 'Keep Going';
  String get saveResult => isChinese ? '保存成绩' : 'Save Result';
  String get newBoard => isChinese ? '新棋盘' : 'New Board';
  String get reached2048 => isChinese ? '成功到达 2048！' : '2048 Reached!';
  String get boardLocked => isChinese ? '棋盘已锁定' : 'Board Locked';
  String maxTileChip(int tile) => isChinese ? '最大方块 $tile' : 'Max tile $tile';
  String get newRecord => isChinese ? '新纪录' : 'New record';
  String get keepClimbing => isChinese ? '继续攀升' : 'Keep climbing';
  String game2048ResultMessage({
    required bool isNewRecord,
    required int? previousBest,
  }) {
    if (isNewRecord) {
      return isChinese
          ? '这局已经登上你的 2048 排行榜顶部。'
          : 'This run is now at the top of your 2048 shelf.';
    }
    if (previousBest == null) {
      return isChinese
          ? '你的第一条 2048 成绩已经保存。'
          : 'Your first 2048 score has been saved.';
    }
    return isChinese
        ? '当前 2048 最高分仍然是 $previousBest。'
        : 'Your best 2048 score is still $previousBest.';
  }

  String get sudokuTitle => isChinese ? '数独工坊' : 'Sudoku Studio';
  String get sudokuHint => isChinese
      ? '选择难度，填满棋盘，挑战更干净的通关时间。'
      : 'Pick a lane, fill the grid, and chase the cleanest completion time.';
  String get time => isChinese ? '时间' : 'Time';
  String get mistakes => isChinese ? '错误' : 'Mistakes';
  String get newPuzzle => isChinese ? '新谜题' : 'New Puzzle';
  String get erase => isChinese ? '擦除' : 'Erase';
  String get cleanSweep => isChinese ? '完美通关！' : 'Clean Sweep!';
  String get puzzleSolved => isChinese ? '谜题已解开' : 'Puzzle Solved';
  String difficultySolvedIn(String difficulty, String duration) => isChinese
      ? '$difficulty，用时 $duration'
      : '$difficulty in $duration';
  String mistakesChip(int count) => isChinese ? '错误 $count' : 'Mistakes $count';
  String bestTimeChip(String duration) =>
      isChinese ? '最佳 $duration' : 'Best $duration';
  String get newBest => isChinese ? '新最佳' : 'New best';
  String get keepSharpening => isChinese ? '继续精进' : 'Keep sharpening';
  String sudokuResultMessage({
    required bool isNewRecord,
    required String difficulty,
    required String? previousBestDuration,
  }) {
    if (isNewRecord) {
      return isChinese
          ? '这是你目前最快的$difficulty成绩。'
          : 'That is your fastest ${difficulty.toLowerCase()} Sudoku so far.';
    }
    if (previousBestDuration == null) {
      return isChinese
          ? '你的第一条数独成绩已经保存。'
          : 'Your first Sudoku result has been stored.';
    }
    return isChinese
        ? '当前$difficulty最佳时间仍然是 $previousBestDuration。'
        : 'Your best ${difficulty.toLowerCase()} time is still $previousBestDuration.';
  }

  String get easy => isChinese ? '简单' : 'Easy';
  String get medium => isChinese ? '中等' : 'Medium';
  String get hard => isChinese ? '困难' : 'Hard';

  String categoryLabel(String englishLabel) {
    if (!isChinese) {
      return englishLabel;
    }

    return switch (englishLabel) {
      'Aces' => '一点',
      'Twos' => '二点',
      'Threes' => '三点',
      'Fours' => '四点',
      'Fives' => '五点',
      'Sixes' => '六点',
      'Three of a Kind' => '三条',
      'Four of a Kind' => '四条',
      'Full House' => '葫芦',
      'Small Straight' => '小顺',
      'Large Straight' => '大顺',
      'Yahtzee' => 'Yahtzee',
      'Chance' => '机会',
      _ => englishLabel,
    };
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any(
        (supportedLocale) => supportedLocale.languageCode == locale.languageCode,
      );

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(Locale(locale.languageCode));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsBuildContextX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
