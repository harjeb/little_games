import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/clay_button.dart';
import '../../../../core/widgets/clay_panel.dart';

class GameCard extends StatelessWidget {
  const GameCard({
    super.key,
    required this.title,
    required this.description,
    required this.bestScoreLabel,
    required this.onPlay,
    required this.accentColor,
    this.playLabel = 'Play',
    this.scoreLabel = 'Best Score',
    this.icon = Icons.casino_rounded,
  });

  final String title;
  final String description;
  final String bestScoreLabel;
  final VoidCallback onPlay;
  final Color accentColor;
  final String playLabel;
  final String scoreLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ClayPanel(
      backgroundColor: AppColors.white.withValues(alpha: 0.92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: AppColors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.sky,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scoreLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: AppColors.mutedInk),
                ),
                const SizedBox(height: 6),
                Text(
                  bestScoreLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.displaySmall?.copyWith(color: AppColors.ink),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ClayButton(
            label: playLabel,
            icon: Icons.play_arrow_rounded,
            onPressed: onPlay,
            backgroundColor: accentColor,
            foregroundColor: AppColors.white,
          ),
        ],
      ),
    );
  }
}
