import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/providers.dart';
import '../../services/database_service.dart';
import '../../models/vendor_profile.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;

    if (user == null) {
      return const _LoginPrompt();
    }

    return _FavoritesContent(customerId: user.uid);
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Save Your Favorite Vendors',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Login to save and view your favorite food vendors',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            icon: const Icon(Icons.login),
            label: const Text('Login'),
          ),
        ],
      ),
    );
  }
}

class _FavoritesContent extends StatelessWidget {
  final String customerId;

  const _FavoritesContent({required this.customerId});

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();

    return StreamBuilder<List<VendorProfile>>(
      stream: dbService.getFavoriteVendorsStream(customerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading favorites: ${snapshot.error}'),
              ],
            ),
          );
        }

        final vendors = snapshot.data ?? [];

        if (vendors.isEmpty) {
          return const _EmptyFavorites();
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Stream will auto-refresh, but we can trigger a rebuild
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vendors.length,
            itemBuilder: (context, index) {
              return _FavoriteVendorCard(vendor: vendors[index]);
            },
          ),
        );
      },
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Favorites Yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Start exploring vendors and tap the heart icon to save your favorites',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteVendorCard extends ConsumerWidget {
  final VendorProfile vendor;

  const _FavoriteVendorCard({required this.vendor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Navigate to vendor detail (can be implemented later)
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Vendor image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: vendor.profileImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: vendor.profileImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              _buildPlaceholder(theme),
                        )
                      : _buildPlaceholder(theme),
                ),
              ),
              const SizedBox(width: 16),
              // Vendor info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.businessName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (vendor.description.isNotEmpty)
                      Text(
                        vendor.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    // Cuisine tags
                    if (vendor.cuisineTags.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: vendor.cuisineTags.take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tag,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 4),
                    // Active status
                    Row(
                      children: [
                        Icon(
                          vendor.isActive ? Icons.circle : Icons.circle_outlined,
                          size: 10,
                          color: vendor.isActive ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          vendor.isActive ? 'Currently Active' : 'Not Active',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: vendor.isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Favorite button
              IconButton(
                onPressed: () {
                  ref
                      .read(favoritesNotifierProvider.notifier)
                      .removeFavorite(vendor.vendorId);
                },
                icon: const Icon(Icons.favorite, color: Colors.red),
                tooltip: 'Remove from favorites',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.store,
        size: 32,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
