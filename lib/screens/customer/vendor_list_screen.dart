import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/vendor_profile.dart';
import '../../services/database_service.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_refresh_indicator.dart';
import '../../widgets/common/animated_list_item.dart';
import '../../core/navigation/app_page_route.dart';
import '../../core/navigation/app_transitions.dart';
import 'vendor_menu_screen.dart';

class VendorListScreen extends ConsumerStatefulWidget {
  const VendorListScreen({super.key});

  @override
  ConsumerState<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends ConsumerState<VendorListScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<VendorProfile> _vendors = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String _searchQuery = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadVendors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreVendors();
    }
  }

  Future<void> _loadVendors() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = _searchQuery.isEmpty
          ? await _databaseService.getActiveVendorsPaginated()
          : await _databaseService.searchVendorsPaginated(query: _searchQuery);

      if (mounted) {
        setState(() {
          _vendors = result.items;
          _lastDocument = result.lastDocument;
          _hasMore = result.hasMore;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreVendors() async {
    if (_isLoadingMore || !_hasMore || _lastDocument == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final result = _searchQuery.isEmpty
          ? await _databaseService.getActiveVendorsPaginated(
              startAfter: _lastDocument,
            )
          : await _databaseService.searchVendorsPaginated(
              query: _searchQuery,
              startAfter: _lastDocument,
            );

      if (mounted) {
        setState(() {
          _vendors.addAll(result.items);
          _lastDocument = result.lastDocument;
          _hasMore = result.hasMore;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    _lastDocument = null;
    _hasMore = true;
    await _loadVendors();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _lastDocument = null;
      _hasMore = true;
    });
    _loadVendors();
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading && _vendors.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _vendors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: AppColors.error.withValues(alpha: 0.6)),
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

    if (_vendors.isEmpty) {
      return AppRefreshIndicator(
        onRefresh: _handleRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: _buildEmptyState(),
            ),
          ],
        ),
      );
    }

    return AppRefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _vendors.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _vendors.length) {
            return _buildLoadingIndicator();
          }

          final vendor = _vendors[index];
          return AnimatedListItem(
            index: index,
            child: _buildVendorCard(context, vendor),
          );
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _isLoadingMore
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton(
                onPressed: _loadMoreVendors,
                child: Text(
                  'Load more',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search vendors or cuisines...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textHint,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.textHint,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppColors.textHint),
                  onPressed: _clearSearch,
                )
              : null,
          filled: true,
          fillColor: AppColors.primaryLight.withValues(alpha: 0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
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
            _searchQuery.isEmpty ? 'No vendors online' : 'No vendors found',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Check back later for available\nfood vendors in your area'
                : 'Try a different search term',
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
              // Vendor avatar with cached image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: vendor.profileImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: vendor.profileImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.primaryLight,
                          child: Icon(
                            Icons.store,
                            color: AppColors.primary.withValues(alpha: 0.5),
                            size: 28,
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.store,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      )
                    : Icon(
                        Icons.store,
                        color: AppColors.primary,
                        size: 28,
                      ),
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
                                      color:
                                          AppColors.success.withValues(alpha: 0.4),
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
                              color:
                                  AppColors.primaryLight.withValues(alpha: 0.6),
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

              // Favorite button and Arrow
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _FavoriteButton(vendorId: vendor.vendorId),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textHint,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  final String vendorId;

  const _FavoriteButton({required this.vendorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorited = ref.watch(isVendorFavoritedProvider(vendorId));
    final authState = ref.watch(authStateProvider);
    final isLoggedIn = authState.valueOrNull != null;

    return IconButton(
      onPressed: () {
        if (!isLoggedIn) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to save favorites'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        ref.read(favoritesNotifierProvider.notifier).toggleFavorite(vendorId);
      },
      icon: Icon(
        isFavorited ? Icons.favorite : Icons.favorite_border,
        color: isFavorited ? Colors.red : AppColors.textHint,
      ),
      tooltip: isFavorited ? 'Remove from favorites' : 'Add to favorites',
      visualDensity: VisualDensity.compact,
    );
  }
}
