import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:servline/core/theme/app_theme.dart';

/// Icon-based rating widget for feedback
class RatingWidget extends StatelessWidget {
  final int selectedRating;
  final void Function(int) onRatingChanged;
  final bool showLabels;

  const RatingWidget({
    super.key,
    required this.selectedRating,
    required this.onRatingChanged,
    this.showLabels = true,
  });

  static const _ratings = [
    {
      'icon': Icons.sentiment_very_dissatisfied,
      'label': 'Poor',
      'color': AppColors.ratingPoor,
    },
    {
      'icon': Icons.sentiment_dissatisfied,
      'label': 'Fair',
      'color': AppColors.ratingBad,
    },
    {
      'icon': Icons.sentiment_neutral,
      'label': 'Okay',
      'color': AppColors.ratingNeutral,
    },
    {
      'icon': Icons.sentiment_satisfied,
      'label': 'Good',
      'color': AppColors.ratingGood,
    },
    {
      'icon': Icons.sentiment_very_satisfied,
      'label': 'Excellent',
      'color': AppColors.ratingExcellent,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (index) {
            final rating = index + 1;
            final isSelected = selectedRating == rating;
            final ratingData = _ratings[index];
            final color = ratingData['color'] as Color;

            return GestureDetector(
              onTap: () => onRatingChanged(rating),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 56 : 48,
                height: isSelected ? 56 : 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.2)
                      : AppColors.surfaceLight,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: color, width: 2)
                      : null,
                ),
                child: Center(
                  child: Icon(
                    ratingData['icon'] as IconData,
                    size: isSelected ? 32 : 28,
                    color: isSelected ? color : AppColors.textTertiary,
                  ),
                ),
              ),
            );
          }),
        ),
        if (showLabels) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'POOR',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.5,
                ),
              ),
              if (selectedRating > 0)
                Text(
                  (_ratings[selectedRating - 1]['label'] as String)
                      .toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _ratings[selectedRating - 1]['color'] as Color,
                    letterSpacing: 0.5,
                  ),
                )
              else
                const SizedBox(),
              Text(
                'EXCELLENT',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ratingExcellent,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Selectable tag chip
class TagChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const TagChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
