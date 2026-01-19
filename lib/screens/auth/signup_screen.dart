import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/auth/auth_header.dart';
import '../../widgets/auth/role_selector.dart';
import '../../widgets/auth/password_strength_indicator.dart';
import '../../utils/validators.dart';
import '../../providers/providers.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _authService = AuthService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  UserRole _selectedRole = UserRole.customer;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;
  String _passwordValue = '';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _passwordController.addListener(_onPasswordChanged);
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  void _onPasswordChanged() {
    setState(() {
      _passwordValue = _passwordController.text;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _passwordController.removeListener(_onPasswordChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
        role: _selectedRole,
        phoneNumber: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
      );

      if (user != null && mounted) {
        if (user.role == UserRole.vendor) {
          Navigator.pushReplacementNamed(context, '/vendor-home');
        } else {
          Navigator.pushReplacementNamed(context, '/customer-home');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = _formatError(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatError(String error) {
    if (error.contains('email-already-in-use')) {
      return 'An account with this email already exists';
    }
    if (error.contains('weak-password')) {
      return 'Password is too weak';
    }
    if (error.contains('invalid-email')) {
      return 'Invalid email address';
    }
    return error.replaceAll('Exception: ', '');
  }

  Future<void> _signUpWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.signInWithGoogle(defaultRole: _selectedRole);

      if (user != null && mounted) {
        if (user.role == UserRole.vendor) {
          Navigator.pushReplacementNamed(context, '/vendor-home');
        } else {
          Navigator.pushReplacementNamed(context, '/customer-home');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = _formatError(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Gradient Header with back button and theme toggle
            Stack(
              children: [
                AuthHeaderCompact(
                  title: 'Create Account',
                  subtitle: 'Join Food Finder today',
                  height: 180,
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 8,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        ref.read(themeProvider.notifier).themeModeIcon,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        ref.read(themeProvider.notifier).toggleTheme();
                      },
                      tooltip: 'Theme: ${ref.read(themeProvider.notifier).themeModeLabel}',
                    ),
                  ),
                ),
              ],
            ),

            // Form Section
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: child,
                  ),
                );
              },
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppShadows.medium,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Role Selection
                        Text(
                          'I am a:',
                          style: AppTextStyles.labelLarge,
                        ),
                        const SizedBox(height: 12),
                        RoleSelector(
                          selectedRole: _selectedRole,
                          onChanged: (role) {
                            setState(() {
                              _selectedRole = role;
                            });
                          },
                        ),

                        const SizedBox(height: 24),

                        // Name Field
                        AppTextField(
                          controller: _nameController,
                          label: _selectedRole == UserRole.vendor
                              ? 'Business Name'
                              : 'Full Name',
                          hint: _selectedRole == UserRole.vendor
                              ? 'Enter your business name'
                              : 'Enter your full name',
                          prefixIcon: _selectedRole == UserRole.vendor
                              ? Icons.storefront_outlined
                              : Icons.person_outline,
                          textInputAction: TextInputAction.next,
                          validator: Validators.name,
                        ),

                        const SizedBox(height: 16),

                        // Email Field
                        AppTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'Enter your email',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: Validators.email,
                        ),

                        const SizedBox(height: 16),

                        // Phone Field (required for vendors, optional for customers)
                        AppTextField(
                          controller: _phoneController,
                          label: _selectedRole == UserRole.vendor
                              ? 'Phone Number'
                              : 'Phone Number (optional)',
                          hint: 'Enter your phone number',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          validator: _selectedRole == UserRole.vendor
                              ? Validators.phoneRequired
                              : Validators.phoneOptional,
                        ),

                        const SizedBox(height: 16),

                        // Password Field
                        AppTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Create a password',
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _signup(),
                          validator: Validators.password,
                        ),

                        // Password Strength Indicator
                        PasswordStrengthIndicator(password: _passwordValue),

                        // Error Message
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _errorMessage != null
                              ? Container(
                                  key: ValueKey(_errorMessage),
                                  margin: const EdgeInsets.only(top: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.error.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: AppColors.error,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            color: AppColors.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),

                        const SizedBox(height: 24),

                        // Signup Button
                        PrimaryButton(
                          text: _selectedRole == UserRole.vendor
                              ? 'Create Vendor Account'
                              : 'Create Account',
                          onPressed: _isLoading ? null : _signup,
                          isLoading: _isLoading,
                          icon: Icons.person_add_outlined,
                        ),

                        const SizedBox(height: 16),

                        // Divider
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'or',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textHint,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Google Sign-Up Button
                        _GoogleSignUpButton(
                          onPressed: _isGoogleLoading ? null : _signUpWithGoogle,
                          isLoading: _isGoogleLoading,
                          roleLabel: _selectedRole == UserRole.vendor ? 'Vendor' : 'Customer',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Login Link
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: child,
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: AppTextStyles.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Login',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom padding for safe area
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
}

/// Google Sign-Up Button Widget
class _GoogleSignUpButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String roleLabel;

  const _GoogleSignUpButton({
    required this.onPressed,
    this.isLoading = false,
    required this.roleLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          side: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    'https://www.google.com/favicon.ico',
                    width: 20,
                    height: 20,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.g_mobiledata,
                        size: 24,
                        color: Colors.red,
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Sign up with Google as $roleLabel',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
