import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/location_manager.dart';
import '../../models/vendor_profile.dart';
import '../../providers/providers.dart';
import 'menu_management_screen.dart';
import 'cuisine_selection_screen.dart';

class VendorHome extends ConsumerStatefulWidget {
  const VendorHome({super.key});

  @override
  ConsumerState<VendorHome> createState() => _VendorHomeState();
}

class _VendorHomeState extends ConsumerState<VendorHome> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  final LocationManager _locationManager = LocationManager();

  VendorProfile? _vendorProfile;
  bool _isLoading = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeVendor();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeVendor() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    await _locationManager.initialize(uid);
    final profile = await _databaseService.getVendorProfile(uid);

    setState(() {
      _vendorProfile = profile;
      _isLoading = false;
    });

    _locationManager.addListener(_onLocationManagerUpdate);
  }

  void _onLocationManagerUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _toggleStatus() async {
    if (_locationManager.state == LocationManagerState.starting ||
        _locationManager.state == LocationManagerState.stopping) {
      return;
    }

    if (_locationManager.isActive) {
      await _locationManager.stopBroadcasting();
    } else {
      await _locationManager.startBroadcasting(context);
    }
  }

  @override
  void dispose() {
    _locationManager.removeListener(_onLocationManagerUpdate);
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.storefront,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          _buildAppBar(),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card with Toggle
                  _buildStatusCard(),

                  const SizedBox(height: 24),

                  // Quick Stats
                  if (_locationManager.isActive) _buildLocationStats(),

                  const SizedBox(height: 24),

                  // Section Title
                  Text(
                    'Manage Your Business',
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: 12),

                  // Menu Card
                  _buildMenuCard(),

                  // Cuisine Card
                  _buildCuisineCard(),

                  // Phone Number Card
                  _buildPhoneCard(),

                  const SizedBox(height: 24),

                  // Error Message
                  if (_locationManager.errorMessage != null)
                    _buildErrorMessage(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.surface,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back!',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              _vendorProfile?.businessName ?? 'Vendor',
              style: AppTextStyles.h4.copyWith(fontSize: 18),
            ),
          ],
        ),
      ),
      actions: [
        IconActionButton(
          icon: Icons.notifications_outlined,
          onPressed: () {
            // TODO: Notifications
          },
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          icon: const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (context) {
            final themeNotifier = ref.read(themeProvider.notifier);
            final biometricState = ref.watch(biometricProvider);
            return [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _authService.currentUser?.email ?? 'Vendor',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Vendor',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(
                      themeNotifier.themeModeIcon,
                      color: Theme.of(context).iconTheme.color,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Theme: ${themeNotifier.themeModeLabel}',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'biometric',
                child: Row(
                  children: [
                    Icon(
                      biometricState.isEnabled
                          ? Icons.fingerprint
                          : Icons.fingerprint_outlined,
                      color: biometricState.isEnabled
                          ? AppColors.primary
                          : Theme.of(context).iconTheme.color,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Biometric: ${biometricState.isEnabled ? 'On' : 'Off'}',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ];
          },
          onSelected: (value) async {
            if (value == 'theme') {
              await ref.read(themeProvider.notifier).toggleTheme();
            } else if (value == 'biometric') {
              final biometricService = ref.read(biometricServiceProvider);
              final isAvailable = await biometricService.isBiometricAvailable();

              if (!isAvailable) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Biometric authentication is not available on this device'),
                    ),
                  );
                }
                return;
              }

              final biometricNotifier = ref.read(biometricProvider.notifier);
              final currentState = ref.read(biometricProvider);

              if (currentState.isEnabled) {
                await biometricNotifier.setBiometricEnabled(false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Biometric authentication disabled')),
                  );
                }
              } else {
                final authenticated = await biometricService.authenticate(
                  reason: 'Authenticate to enable biometric login',
                );
                if (authenticated) {
                  await biometricNotifier.setBiometricEnabled(true);
                  await biometricNotifier.storeCredential();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Biometric authentication enabled')),
                    );
                  }
                }
              }
            } else if (value == 'logout') {
              if (_locationManager.isActive) {
                await _locationManager.stopBroadcasting();
              }
              await ref.read(biometricProvider.notifier).clearCredential();
              await _authService.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            }
          },
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildStatusCard() {
    final isActive = _locationManager.isActive;
    final isTransitioning =
        _locationManager.state == LocationManagerState.starting ||
            _locationManager.state == LocationManagerState.stopping;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isActive ? _pulseAnimation.value : 1.0,
          child: GradientCard(
            gradient: isActive
                ? AppColors.successGradient
                : const LinearGradient(
                    colors: [Color(0xFF6B7280), Color(0xFF4B5563)],
                  ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    // Status Icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isActive ? Icons.storefront : Icons.store_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Status Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isTransitioning
                                ? 'Updating...'
                                : (isActive ? 'You\'re Online!' : 'You\'re Offline'),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isActive
                                ? 'Customers can find you now'
                                : 'Go online to start serving',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Toggle Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isTransitioning ? null : _toggleStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: isActive ? AppColors.error : AppColors.success,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isTransitioning
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: isActive ? AppColors.error : AppColors.success,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isActive ? Icons.power_settings_new : Icons.power_settings_new,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isActive ? 'Go Offline' : 'Go Online',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationStats() {
    final lat = _locationManager.lastLatitude;
    final lng = _locationManager.lastLongitude;
    final time = _locationManager.lastUpdateTime;

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.location_on,
              color: AppColors.info,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Location',
                  style: AppTextStyles.labelLarge,
                ),
                const SizedBox(height: 4),
                if (lat != null && lng != null)
                  Text(
                    '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontFamily: 'monospace',
                    ),
                  )
                else
                  Text(
                    'Fetching location...',
                    style: AppTextStyles.bodySmall,
                  ),
              ],
            ),
          ),
          if (time != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Updated',
                  style: AppTextStyles.bodySmall,
                ),
                Text(
                  _formatTime(time),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMenuCard() {
    return AppCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MenuManagementScreen(),
          ),
        );
      },
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.restaurant_menu,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage Menu',
                  style: AppTextStyles.h4.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add, edit, or remove items',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.textHint,
          ),
        ],
      ),
    );
  }

  Widget _buildCuisineCard() {
    final cuisines = _vendorProfile?.cuisineTags ?? [];

    return AppCard(
      onTap: () async {
        final result = await Navigator.push<List<String>>(
          context,
          MaterialPageRoute(
            builder: (context) => CuisineSelectionScreen(
              initialSelection: cuisines,
            ),
          ),
        );

        if (result != null) {
          final profile = await _databaseService.getVendorProfile(
            _authService.currentUser!.uid,
          );
          if (mounted) {
            setState(() {
              _vendorProfile = profile;
            });
          }
        }
      },
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.category,
              color: Colors.purple.shade400,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cuisine Types',
                  style: AppTextStyles.h4.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  cuisines.isEmpty
                      ? 'Select your cuisine types'
                      : cuisines.take(3).join(', ') +
                          (cuisines.length > 3 ? ' +${cuisines.length - 3}' : ''),
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.textHint,
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneCard() {
    final phoneNumber = _vendorProfile?.phoneNumber;

    return AppCard(
      onTap: () => _showPhoneEditDialog(),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.phone,
              color: Colors.green.shade600,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phone Number',
                  style: AppTextStyles.h4.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  phoneNumber?.isNotEmpty == true
                      ? phoneNumber!
                      : 'Add your contact number',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: phoneNumber?.isNotEmpty == true
                        ? null
                        : AppColors.warning,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.edit,
            size: 16,
            color: AppColors.textHint,
          ),
        ],
      ),
    );
  }

  Future<void> _showPhoneEditDialog() async {
    final controller = TextEditingController(
      text: _vendorProfile?.phoneNumber ?? '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Phone Number'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            hintText: '+1234567890',
            prefixIcon: Icon(Icons.phone),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      // Validate phone number
      final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
      if (result.isEmpty || !phoneRegex.hasMatch(result)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid phone number (10-15 digits)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        await _databaseService.updateVendorProfile(
          _authService.currentUser!.uid,
          {'phoneNumber': result},
        );

        // Refresh profile
        final profile = await _databaseService.getVendorProfile(
          _authService.currentUser!.uid,
        );
        if (mounted) {
          setState(() {
            _vendorProfile = profile;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone number updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating phone number: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _locationManager.errorMessage!,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
