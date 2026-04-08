import 'package:flutter/material.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/score_category.dart';

class ScoreCategoryRow extends StatelessWidget {
  const ScoreCategoryRow({
    super.key,
    required this.category,
    required this.assignedScore,
    required this.previewScore,
    required this.onTap,
    required this.enabled,
  });

  final ScoreCategory category;
  final int? assignedScore;
  final int previewScore;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isAssigned = assignedScore != null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled || isAssigned ? 1 : 0.6,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: isAssigned ? AppColors.mintCream : AppColors.sky,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.localizedLabel(l10n),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAssigned ? l10n.lockedIn : l10n.tapToScoreThisRound,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${assignedScore ?? previewScore}',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: AppColors.ink),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAssigned ? l10n.scored : l10n.preview,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.mutedInk,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
