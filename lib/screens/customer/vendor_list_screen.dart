import 'package:flutter/material.dart';
import '../../models/vendor_profile.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_refresh_indicator.dart';
import '../../widgets/common/animated_list_item.dart';
import '../../core/navigation/app_page_route.dart';
import '../../core/navigation/app_transitions.dart';
import 'vendor_menu_screen.dart';

class VendorListScreen extends StatefulWidget {
  const VendorListScreen({super.key});

  @override
  State<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<VendorListScreen> {
  final DatabaseService _databaseService = DatabaseService();
  late Stream<List<VendorProfile>> _vendorStream;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _vendorStream = _databaseService.getActiveVendorsWithFreshnessCheck();
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _refreshKey++;
      _vendorStream = _databaseService.getActiveVendorsWithFreshnessCheck();
    });
    // Minimum refresh time for visual feedback
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VendorProfile>>(
      key: ValueKey(_refreshKey),
      stream: _vendorStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.error.withValues(alpha: 0.6)),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: AppTextStyles.h4,
                ),
                const SizedBox(height: 8),
                Text(
                  'Pull down to refresh',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          );
        }

        final vendors = snapshot.data ?? [];

        if (vendors.isEmpty) {
          return AppRefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: _buildEmptyState(),
                ),
              ],
            ),
          );
        }

        return AppRefreshIndicator(
          onRefresh: _handleRefresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: vendors.length,
            itemBuilder: (context, index) {
              final vendor = vendors[index];
              return AnimatedListItem(
                index: index,
                child: _buildVendorCard(context, vendor),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.storefront_outlined,
              size: 50,
              color: AppColors.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No vendors online',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for available\nfood vendors in your area',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Pull down to refresh',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorCard(BuildContext context, VendorProfile vendor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            AppPageRoute(
              page: VendorMenuScreen(vendor: vendor),
              transitionType: AppTransitionType.slideRight,
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Vendor avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                  image: vendor.profileImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(vendor.profileImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: vendor.profileImageUrl == null
                    ? Icon(
                        Icons.store,
                        color: AppColors.primary,
                        size: 28,
                      )
                    : null,
              ),
              const SizedBox(width: 16),

              // Vendor details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vendor.businessName,
                            style: AppTextStyles.h4,
                          ),
                        ),
                        // Online indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.success,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.success.withValues(alpha: 0.4),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Open',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (vendor.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        vendor.description,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (vendor.cuisineTags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: vendor.cuisineTags.take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.primaryDark,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Arrow
              Icon(
                Icons.chevron_right,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
