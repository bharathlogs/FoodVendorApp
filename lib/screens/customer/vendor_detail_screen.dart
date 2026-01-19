import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/common/star_rating.dart';
import '../../widgets/customer/review_form.dart';
import '../../widgets/customer/review_list.dart';
import '../../models/vendor_profile.dart';
import '../../models/menu_item.dart';
import '../../models/review.dart';
import '../../services/database_service.dart';
import '../../utils/distance_formatter.dart';
import '../../providers/providers.dart';
import '../../services/deep_link_service.dart';

class VendorDetailScreen extends ConsumerStatefulWidget {
  final VendorProfile vendor;
  final double? distanceKm;

  const VendorDetailScreen({
    super.key,
    required this.vendor,
    this.distanceKm,
  });

  @override
  ConsumerState<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends ConsumerState<VendorDetailScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _showReviewForm = false;
  Review? _editingReview;

  @override
  Widget build(BuildContext context) {
    final vendor = widget.vendor;
    final distanceKm = widget.distanceKm;

    // Watch reviews
    final reviewsAsync = ref.watch(vendorReviewsProvider(vendor.vendorId));
    final userReviewAsync = ref.watch(userReviewProvider(vendor.vendorId));
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: Stack(
                  children: [
                    // Pattern overlay
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _PatternPainter(),
                      ),
                    ),

                    // Content
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 20,
                      child: Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: vendor.profileImageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: vendor.profileImageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Icon(
                                      Icons.storefront,
                                      size: 40,
                                      color: AppColors.primary.withValues(alpha: 0.5),
                                    ),
                                    errorWidget: (context, url, error) => Icon(
                                      Icons.storefront,
                                      size: 40,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : Icon(
                                    Icons.storefront,
                                    size: 40,
                                    color: AppColors.primary,
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vendor.businessName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    StatusBadge(
                                      status: vendor.isActive
                                          ? StatusType.open
                                          : StatusType.closed,
                                    ),
                                    if (vendor.totalRatings > 0) ...[
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.star_rounded,
                                              size: 16,
                                              color: AppColors.warning,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              vendor.averageRating.toStringAsFixed(1),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '(${vendor.totalRatings})',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white.withValues(alpha: 0.8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Share button
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.share, color: Colors.white),
                ),
                onPressed: () => _shareVendor(),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Cards Row
                  Row(
                    children: [
                      // Distance Card
                      if (distanceKm != null)
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.location_on,
                            iconColor: AppColors.info,
                            title: DistanceFormatter.format(distanceKm),
                            subtitle: 'Distance',
                          ),
                        ),
                      if (distanceKm != null) const SizedBox(width: 12),

                      // Walking Time Card
                      if (distanceKm != null)
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.directions_walk,
                            iconColor: AppColors.success,
                            title: DistanceFormatter.walkingTime(distanceKm),
                            subtitle: 'Walking',
                          ),
                        ),
                    ],
                  ),

                  // Cuisine Tags
                  if (vendor.cuisineTags.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: vendor.cuisineTags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // Description
                  if (vendor.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      vendor.description,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Menu Section
                  Row(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Menu',
                        style: AppTextStyles.h3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Menu Items
          StreamBuilder<List<MenuItem>>(
            stream: _databaseService.getMenuItemsStream(vendor.vendorId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const ShimmerMenuItem(),
                      childCount: 4,
                    ),
                  ),
                );
              }

              final items = snapshot.data ?? [];
              final availableItems =
                  items.where((item) => item.isAvailable).toList();

              if (availableItems.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyMenu(),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = availableItems[index];
                      return _MenuItemCard(item: item);
                    },
                    childCount: availableItems.length,
                  ),
                ),
              );
            },
          ),

          // Reviews Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.rate_review,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Reviews',
                            style: AppTextStyles.h3,
                          ),
                          if (vendor.totalRatings > 0) ...[
                            const SizedBox(width: 8),
                            RatingBadge(
                              rating: vendor.averageRating,
                              totalRatings: vendor.totalRatings,
                            ),
                          ],
                        ],
                      ),
                      // Add review button
                      if (currentUser != null && !_showReviewForm)
                        userReviewAsync.when(
                          data: (existingReview) {
                            if (existingReview != null) {
                              return const SizedBox.shrink();
                            }
                            return TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _showReviewForm = true;
                                  _editingReview = null;
                                });
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Write Review'),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Review Form
                  if (_showReviewForm && currentUser != null)
                    ReviewForm(
                      existingReview: _editingReview,
                      vendorId: vendor.vendorId,
                      customerId: currentUser.uid,
                      customerName: currentUser.displayName,
                      onSubmit: (review) => _handleReviewSubmit(review),
                      onCancel: () {
                        setState(() {
                          _showReviewForm = false;
                          _editingReview = null;
                        });
                      },
                      onDelete: _editingReview != null
                          ? () => _handleReviewDelete(_editingReview!)
                          : null,
                    ),

                  if (_showReviewForm) const SizedBox(height: 16),

                  // Reviews List
                  reviewsAsync.when(
                    data: (reviews) => ReviewList(
                      reviews: reviews,
                      currentUserId: currentUser?.uid,
                      onEditReview: (review) {
                        setState(() {
                          _showReviewForm = true;
                          _editingReview = review;
                        });
                      },
                    ),
                    loading: () => const ReviewList(
                      reviews: [],
                      isLoading: true,
                    ),
                    error: (e, _) => Text(
                      'Error loading reviews',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Padding
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),

      // Bottom Bar
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ready to order?',
                    style: AppTextStyles.bodySmall,
                  ),
                  Text(
                    'Visit the stall directly',
                    style: AppTextStyles.labelLarge,
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.directions_walk, color: Colors.white),
                            SizedBox(width: 12),
                            Text('Head to the stall to place your order!'),
                          ],
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.directions_walk, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Visit Stall',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareVendor() {
    final vendor = widget.vendor;
    DeepLinkService.shareVendorWithLocation(
      vendorId: vendor.vendorId,
      vendorName: vendor.businessName,
      description: vendor.description.isNotEmpty ? vendor.description : null,
      distanceKm: widget.distanceKm,
    );
  }

  Future<void> _handleReviewSubmit(Review review) async {
    final vendor = widget.vendor;
    final reviewNotifier = ref.read(reviewNotifierProvider.notifier);
    final isEditing = _editingReview != null;

    bool success;
    if (isEditing) {
      success = await reviewNotifier.updateReview(
        vendorId: vendor.vendorId,
        reviewId: _editingReview!.reviewId,
        review: review,
      );
    } else {
      success = await reviewNotifier.submitReview(
        vendorId: vendor.vendorId,
        review: review,
      );
    }

    if (success && mounted) {
      setState(() {
        _showReviewForm = false;
        _editingReview = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing
              ? 'Review updated successfully'
              : 'Review submitted successfully'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _handleReviewDelete(Review review) async {
    final vendor = widget.vendor;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete your review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final reviewNotifier = ref.read(reviewNotifierProvider.notifier);
      final success = await reviewNotifier.deleteReview(
        vendorId: vendor.vendorId,
        reviewId: review.reviewId,
      );

      if (success && mounted) {
        setState(() {
          _showReviewForm = false;
          _editingReview = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Review deleted'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Widget _buildEmptyMenu() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant_menu,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Menu not available',
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later or visit the stall',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.labelLarge),
              Text(subtitle, style: AppTextStyles.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;

  const _MenuItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food Image or Icon
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: item.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: item.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Icon(
                      Icons.fastfood,
                      color: AppColors.primary,
                      size: 32,
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.fastfood,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  )
                : Icon(
                    Icons.fastfood,
                    color: AppColors.primary,
                    size: 32,
                  ),
          ),
          const SizedBox(width: 16),

          // Item Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTextStyles.labelLarge,
                ),
                if (item.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description!,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '₹${item.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 10; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.3),
        50.0 + i * 20,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
