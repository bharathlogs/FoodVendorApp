import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../models/vendor_profile.dart';
import '../../utils/distance_formatter.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/app_button.dart';

class VendorBottomSheet extends StatelessWidget {
  final VendorProfile vendor;
  final double? distanceKm;
  final VoidCallback onViewMenu;

  const VendorBottomSheet({
    super.key,
    required this.vendor,
    this.distanceKm,
    required this.onViewMenu,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vendor icon with gradient
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.storefront,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Name and status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vendor.businessName,
                            style: AppTextStyles.h3.copyWith(
                              color: isDark ? Colors.white : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          StatusBadge(
                            status: vendor.isActive
                                ? StatusType.open
                                : StatusType.closed,
                            large: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Distance & Time card
                if (distanceKm != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.info.withValues(alpha: 0.1),
                          AppColors.info.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Distance
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.location_on,
                                  color: AppColors.info,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DistanceFormatter.format(distanceKm),
                                    style: AppTextStyles.h4.copyWith(
                                      color: AppColors.info,
                                    ),
                                  ),
                                  Text(
                                    'away',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: isDark ? Colors.grey.shade400 : null,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Divider
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.info.withValues(alpha: 0.2),
                        ),

                        // Walking time
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.directions_walk,
                                  color: AppColors.info,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getWalkingTime(),
                                    style: AppTextStyles.h4.copyWith(
                                      color: AppColors.info,
                                    ),
                                  ),
                                  Text(
                                    'walk',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: isDark ? Colors.grey.shade400 : null,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Cuisine tags
                if (vendor.cuisineTags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: vendor.cuisineTags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
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
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? Colors.grey.shade300 : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 24),

                // Action Buttons Row
                Row(
                  children: [
                    // Call Button (only show if phone number available)
                    if (vendor.phoneNumber != null &&
                        vendor.phoneNumber!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _CallButton(
                          phoneNumber: vendor.phoneNumber!,
                        ),
                      ),

                    // View Menu Button
                    Expanded(
                      child: PrimaryButton(
                        text: 'View Menu',
                        icon: Icons.restaurant_menu,
                        onPressed: onViewMenu,
                      ),
                    ),
                  ],
                ),

                // Safe area
                SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getWalkingTime() {
    if (distanceKm == null) return '-';
    final minutes = (distanceKm! / 5 * 60).round();
    if (minutes < 1) return '<1 min';
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    return '${hours}h ${minutes % 60}m';
  }
}

/// Call button widget that launches the phone dialer
class _CallButton extends StatelessWidget {
  final String phoneNumber;

  const _CallButton({required this.phoneNumber});

  Future<void> _makePhoneCall(BuildContext context) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch phone dialer'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _makePhoneCall(context),
          borderRadius: BorderRadius.circular(16),
          child: const Icon(
            Icons.phone,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
