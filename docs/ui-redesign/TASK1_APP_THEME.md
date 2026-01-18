# Task 1: App Theme & Design System

## Objective
Create a consistent design system with colors, typography, and component styles inspired by Swiggy and Zomato.

## Status: ✅ COMPLETED

## Files Created

### `lib/theme/app_theme.dart`

## Implementation Details

### 1. AppColors Class
Primary color palette inspired by food delivery apps:

| Color Category | Color Name | Hex Value | Usage |
|----------------|------------|-----------|-------|
| **Primary** | primary | `#FC8019` | Main brand color (Swiggy orange) |
| | primaryDark | `#E67312` | Pressed/active states |
| | primaryLight | `#FFE0B2` | Backgrounds, highlights |
| **Secondary** | secondary | `#60B246` | Success, open status |
| | secondaryDark | `#4A9036` | Darker green variant |
| **Status** | success | `#60B246` | Success messages |
| | error | `#E23744` | Errors (Zomato red) |
| | warning | `#FFC107` | Warnings |
| | info | `#2196F3` | Information |
| **Neutral** | background | `#F5F5F5` | App background |
| | surface | `#FFFFFF` | Card/sheet surfaces |
| | cardBackground | `#FFFFFF` | Card backgrounds |
| **Text** | textPrimary | `#1C1C1C` | Main text |
| | textSecondary | `#686B78` | Secondary text |
| | textHint | `#93959F` | Hints, placeholders |
| | textOnPrimary | `#FFFFFF` | Text on primary color |
| **Border** | border | `#E8E8E8` | Input borders |
| | divider | `#F0F0F0` | Divider lines |

### Gradients
```dart
primaryGradient: [#FC8019 → #FF6B35]  // Orange gradient for buttons
successGradient: [#60B246 → #7BC95E]  // Green gradient for success states
```

### 2. AppTextStyles Class
Typography hierarchy:

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| h1 | 28px | Bold | Main headlines |
| h2 | 24px | Bold | Section headers |
| h3 | 20px | SemiBold | Sub-headers |
| h4 | 18px | SemiBold | Card titles |
| bodyLarge | 16px | Normal | Main body text |
| bodyMedium | 14px | Normal | Secondary text |
| bodySmall | 12px | Normal | Captions, hints |
| labelLarge | 14px | SemiBold | Button labels |
| labelMedium | 12px | Medium | Chip labels |
| price | 16px | Bold | Price display |
| priceSmall | 14px | SemiBold | Small prices |

### 3. AppShadows Class
Elevation system:

| Shadow | Blur | Offset | Opacity | Usage |
|--------|------|--------|---------|-------|
| small | 8px | (0, 2) | 4% | Cards, chips |
| medium | 16px | (0, 4) | 8% | Elevated cards, modals |
| large | 24px | (0, 8) | 12% | Floating elements |

### 4. AppTheme.lightTheme
Complete Material 3 theme configuration:

- **ColorScheme**: Light theme with primary/secondary colors
- **AppBarTheme**: Clean white appbar, no elevation
- **CardTheme**: 16px radius, no elevation (uses shadow instead)
- **ElevatedButtonTheme**: Primary gradient, 12px radius
- **TextButtonTheme**: Primary color text
- **OutlinedButtonTheme**: Primary border, 12px radius
- **InputDecorationTheme**: Filled inputs, 12px radius, focus states
- **ChipTheme**: 20px radius pills with border
- **BottomSheetTheme**: 20px top radius
- **FloatingActionButtonTheme**: Circle shape, primary color
- **DividerTheme**: Subtle dividers
- **SnackBarTheme**: Floating style, 12px radius

## Integration

### Updated `lib/main.dart`
```dart
import 'theme/app_theme.dart';

MaterialApp(
  title: 'Food Finder',
  debugShowCheckedModeBanner: false,
  theme: AppTheme.lightTheme,
  // ...
)
```

## Commit
```
git commit -m "Add app theme and design system"
```

## Design Inspiration

| Element | Swiggy/Zomato Approach | Our Implementation |
|---------|------------------------|-------------------|
| Colors | Vibrant primary (orange/red) | Orange primary with gradients |
| Cards | Elevated with shadows | 16px radius, subtle shadows |
| Typography | Bold headlines, clear hierarchy | Custom text theme system |
| Inputs | Rounded, clean borders | 12px radius, focus states |
| Buttons | Gradient fills, rounded | Primary gradient, 12px radius |
