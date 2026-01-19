import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// A reusable star rating widget that can display ratings or allow selection
class StarRating extends StatelessWidget {
  final double rating;
  final int maxRating;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final ValueChanged<int>? onRatingChanged;
  final bool showValue;
  final MainAxisAlignment alignment;

  const StarRating({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 20,
    this.activeColor,
    this.inactiveColor,
    this.onRatingChanged,
    this.showValue = false,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final active = activeColor ?? AppColors.warning;
    final inactive = inactiveColor ?? AppColors.textHint;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: [
        ...List.generate(maxRating, (index) {
          final starValue = index + 1;
          final isFilled = starValue <= rating;
          final isHalfFilled = starValue > rating && starValue - 0.5 <= rating;

          IconData icon;
          Color color;

          if (isFilled) {
            icon = Icons.star_rounded;
            color = active;
          } else if (isHalfFilled) {
            icon = Icons.star_half_rounded;
            color = active;
          } else {
            icon = Icons.star_outline_rounded;
            color = inactive;
          }

          final star = Icon(
            icon,
            size: size,
            color: color,
          );

          if (onRatingChanged != null) {
            return GestureDetector(
              onTap: () => onRatingChanged!(starValue),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: star,
              ),
            );
          }

          return star;
        }),
        if (showValue && rating > 0) ...[
          const SizedBox(width: 6),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.7,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}

/// A compact rating display with star icon and value
class RatingBadge extends StatelessWidget {
  final double rating;
  final int totalRatings;
  final double iconSize;
  final bool showCount;

  const RatingBadge({
    super.key,
    required this.rating,
    this.totalRatings = 0,
    this.iconSize = 16,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    if (rating == 0 && totalRatings == 0) {
      return Text(
        'No ratings yet',
        style: AppTextStyles.bodySmall,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_rounded,
          size: iconSize,
          color: AppColors.warning,
        ),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: iconSize * 0.85,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (showCount && totalRatings > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($totalRatings)',
            style: TextStyle(
              fontSize: iconSize * 0.75,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
