import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/review.dart';
import '../common/star_rating.dart';

/// A form widget for submitting or editing a review
class ReviewForm extends StatefulWidget {
  final Review? existingReview;
  final String vendorId;
  final String customerId;
  final String customerName;
  final Function(Review review) onSubmit;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;

  const ReviewForm({
    super.key,
    this.existingReview,
    required this.vendorId,
    required this.customerId,
    required this.customerName,
    required this.onSubmit,
    this.onCancel,
    this.onDelete,
  });

  @override
  State<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  late int _rating;
  late TextEditingController _commentController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.existingReview?.rating ?? 0;
    _commentController = TextEditingController(
      text: widget.existingReview?.comment ?? '',
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.existingReview != null;

  void _handleSubmit() {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final review = Review(
      reviewId: widget.existingReview?.reviewId ?? '',
      vendorId: widget.vendorId,
      customerId: widget.customerId,
      customerName: widget.customerName,
      rating: _rating,
      comment: _commentController.text.trim().isNotEmpty
          ? _commentController.text.trim()
          : null,
      createdAt: widget.existingReview?.createdAt ?? DateTime.now(),
    );

    widget.onSubmit(review);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isEditing ? 'Edit Your Review' : 'Write a Review',
                style: AppTextStyles.h4,
              ),
              if (widget.onCancel != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onCancel,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Rating selection
          Text(
            'Your Rating',
            style: AppTextStyles.labelLarge,
          ),
          const SizedBox(height: 8),
          Center(
            child: StarRating(
              rating: _rating.toDouble(),
              size: 40,
              onRatingChanged: (rating) {
                setState(() => _rating = rating);
              },
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _getRatingText(_rating),
              style: AppTextStyles.bodyMedium.copyWith(
                color: _rating > 0 ? AppColors.warning : AppColors.textHint,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Comment field
          Text(
            'Your Review (Optional)',
            style: AppTextStyles.labelLarge,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Share your experience...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              if (_isEditing && widget.onDelete != null) ...[
                TextButton.icon(
                  onPressed: _isSubmitting ? null : widget.onDelete,
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  label: Text(
                    'Delete',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
                const Spacer(),
              ] else ...[
                const Spacer(),
              ],
              if (widget.onCancel != null)
                TextButton(
                  onPressed: _isSubmitting ? null : widget.onCancel,
                  child: const Text('Cancel'),
                ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isEditing ? 'Update Review' : 'Submit Review'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Tap to rate';
    }
  }
}
