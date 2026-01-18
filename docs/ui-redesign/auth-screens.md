# Auth Screen Redesign

## Overview

The login and signup screens were redesigned with modern UI/UX patterns including gradient headers, entrance animations, password visibility toggles, and password strength indicators.

## Files

### New Components

| File | Location | Purpose |
|------|----------|---------|
| `app_text_field.dart` | `lib/widgets/common/` | Styled text input with password toggle |
| `auth_header.dart` | `lib/widgets/auth/` | Gradient header with curved bottom |
| `role_selector.dart` | `lib/widgets/auth/` | Animated role selection chips |
| `password_strength_indicator.dart` | `lib/widgets/auth/` | Visual password strength bar |
| `validators.dart` | `lib/utils/` | Form validation utilities |

### Modified Screens

| File | Location | Changes |
|------|----------|---------|
| `login_screen.dart` | `lib/screens/auth/` | Complete redesign |
| `signup_screen.dart` | `lib/screens/auth/` | Complete redesign |

## Login Screen

### Layout Structure

```
┌─────────────────────────────┐
│     Gradient Header         │
│   ┌─────────────────────┐   │
│   │    App Logo         │   │
│   └─────────────────────┘   │
│      "Welcome Back"         │
│    "Sign in to continue"    │
└─────────────────────────────┘
        Curved edge
┌─────────────────────────────┐
│   White Form Card           │
│  ┌─────────────────────┐    │
│  │ 📧 Email            │    │
│  └─────────────────────┘    │
│  ┌─────────────────────┐    │
│  │ 🔒 Password     👁  │    │
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │      Login          │    │
│  └─────────────────────┘    │
│         ── or ──            │
│  ┌─────────────────────┐    │
│  │  Continue as Guest  │    │
│  └─────────────────────┘    │
└─────────────────────────────┘
   Don't have account? Sign up
```

### Features

- Gradient header with app logo
- Curved bottom edge using `ClipPath`
- Form card with shadow
- Email field with icon prefix
- Password field with visibility toggle
- Animated error messages
- Primary gradient button for login
- Secondary outlined button for guest

### Entrance Animations

1. Header appears first
2. Form card slides up with fade (300-800ms)
3. Bottom link fades in

## Signup Screen

### Layout Structure

```
┌─────────────────────────────┐
│  ← Gradient Header          │
│      "Create Account"       │
│   "Join Food Finder today"  │
└─────────────────────────────┘
┌─────────────────────────────┐
│   "I am a:"                 │
│  ┌──────────┬──────────┐    │
│  │ Customer │  Vendor  │    │
│  │    ✓     │          │    │
│  └──────────┴──────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │ 👤 Full Name        │    │
│  └─────────────────────┘    │
│  ┌─────────────────────┐    │
│  │ 📧 Email            │    │
│  └─────────────────────┘    │
│  ┌─────────────────────┐    │
│  │ 📱 Phone (optional) │    │
│  └─────────────────────┘    │
│  ┌─────────────────────┐    │
│  │ 🔒 Password     👁  │    │
│  └─────────────────────┘    │
│  [■■■■░░░░░░] Medium        │
│                             │
│  ┌─────────────────────┐    │
│  │   Create Account    │    │
│  └─────────────────────┘    │
└─────────────────────────────┘
   Already have account? Login
```

### Features

- Compact gradient header with back button
- Role selector with animated chips
- Dynamic form labels (Full Name vs Business Name)
- Password strength indicator
- All fields have icon prefixes

## Components

### AppTextField

Reusable text field with consistent styling:

```dart
AppTextField(
  controller: _emailController,
  label: 'Email',
  hint: 'Enter your email',
  prefixIcon: Icons.email_outlined,
  keyboardType: TextInputType.emailAddress,
  validator: Validators.email,
)
```

**Password Mode:**
```dart
AppTextField(
  controller: _passwordController,
  label: 'Password',
  isPassword: true,  // Enables visibility toggle
  validator: Validators.password,
)
```

### AuthHeader

Gradient header with curved bottom:

```dart
AuthHeader(
  title: 'Welcome Back',
  subtitle: 'Sign in to continue',
  logo: Container(...),  // Optional logo widget
  height: 280,           // Default height
)
```

**Compact Variant:**
```dart
AuthHeaderCompact(
  title: 'Create Account',
  subtitle: 'Join Food Finder today',
  height: 180,
)
```

### RoleSelector

Animated role selection:

```dart
RoleSelector(
  selectedRole: _selectedRole,
  onChanged: (role) {
    setState(() => _selectedRole = role);
  },
)
```

### PasswordStrengthIndicator

Visual strength feedback:

```dart
PasswordStrengthIndicator(password: _passwordValue)
```

**Strength Levels:**
- Weak (red): Score ≤ 2
- Medium (orange): Score 3-4
- Strong (green): Score ≥ 5

**Score Calculation:**
- +1 for length ≥ 6
- +1 for length ≥ 8
- +1 for length ≥ 12
- +1 for lowercase letters
- +1 for uppercase letters
- +1 for numbers
- +1 for special characters

## Validators

Centralized validation functions:

```dart
// Email validation
Validators.email(value)  // Regex-based

// Password validation
Validators.password(value)       // Min 6 chars
Validators.passwordStrong(value) // Min 8 + number

// Name validation
Validators.name(value)  // Min 2 chars

// Phone validation
Validators.phoneOptional(value)  // Optional
Validators.phoneRequired(value)  // Required

// Generic validators
Validators.required(value, 'Field name')
Validators.minLength(value, 8, 'Password')
Validators.confirmPassword(originalPassword)(value)
```

## Error Handling

Errors are displayed with animated transitions:

```dart
AnimatedSwitcher(
  duration: Duration(milliseconds: 200),
  child: _errorMessage != null
    ? Container(
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error),
            Text(_errorMessage!),
          ],
        ),
      )
    : SizedBox.shrink(),
)
```

Firebase error messages are cleaned up:

```dart
String _formatError(String error) {
  if (error.contains('user-not-found')) {
    return 'No account found with this email';
  }
  if (error.contains('wrong-password')) {
    return 'Incorrect password';
  }
  // ... other mappings
}
```
