# Custom Splash Screen

## Overview

An animated splash screen provides a branded app launch experience with sequenced animations for logo, text, and loading indicator.

## Files

| File | Location | Purpose |
|------|----------|---------|
| `splash_screen.dart` | `lib/screens/splash/` | Animated splash implementation |
| `main.dart` | `lib/` | SplashWrapper integration |

## Visual Design

```
┌─────────────────────────────┐
│                             │
│     Gradient Background     │
│     (#FC8019 → #FF6B35)     │
│                             │
│      ┌─────────────┐        │
│      │             │        │
│      │   App Icon  │        │  ← Scale + Fade + Pulse
│      │             │        │
│      └─────────────┘        │
│                             │
│       Food Finder           │  ← Slide Up + Fade
│                             │
│   Discover nearby food      │  ← Fade
│        vendors              │
│                             │
│          ● ● ●              │  ← Pulsing dots
│                             │
└─────────────────────────────┘
```

## Animation Sequence

| Time | Element | Animation |
|------|---------|-----------|
| 0-200ms | Background | Appears instantly |
| 200-800ms | Logo | Scale (0.5→1) + Fade + Elastic curve |
| 600-1100ms | App Name | Slide up (30%) + Fade |
| 900-1300ms | Tagline | Fade in |
| Continuous | Pulsing dots | Scale + opacity loop |
| ~2000ms | Transition | Navigate to AuthWrapper |

## Implementation

### SplashScreen Widget

```dart
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({required this.onComplete});
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // Animation controllers
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _taglineController;
  late AnimationController _pulseController;

  // Animations
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _textSlide;
  // ... etc
}
```

### Logo Animation

Scale with elastic bounce + fade:

```dart
_logoController = AnimationController(
  duration: Duration(milliseconds: 600),
  vsync: this,
);

_logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
  CurvedAnimation(
    parent: _logoController,
    curve: Curves.elasticOut,  // Bouncy effect
  ),
);

_logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
  CurvedAnimation(
    parent: _logoController,
    curve: Interval(0.0, 0.5, curve: Curves.easeOut),
  ),
);
```

### Text Slide Animation

Slide up from offset with fade:

```dart
_textController = AnimationController(
  duration: Duration(milliseconds: 500),
  vsync: this,
);

_textSlide = Tween<Offset>(
  begin: Offset(0, 0.3),  // Start 30% below
  end: Offset.zero,
).animate(CurvedAnimation(
  parent: _textController,
  curve: Curves.easeOutCubic,
));
```

### Pulse Animation (Logo Background)

Continuous subtle scale:

```dart
_pulseController = AnimationController(
  duration: Duration(milliseconds: 1500),
  vsync: this,
)..repeat(reverse: true);

_pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
  CurvedAnimation(
    parent: _pulseController,
    curve: Curves.easeInOut,
  ),
);
```

### Animation Sequence

```dart
void _startAnimationSequence() async {
  await Future.delayed(Duration(milliseconds: 200));
  if (!mounted) return;
  _logoController.forward();

  await Future.delayed(Duration(milliseconds: 400));
  if (!mounted) return;
  _textController.forward();

  await Future.delayed(Duration(milliseconds: 300));
  if (!mounted) return;
  _taglineController.forward();

  await Future.delayed(Duration(milliseconds: 1100));
  if (!mounted) return;
  widget.onComplete();  // Notify parent to transition
}
```

## Pulsing Dots Loading Indicator

Custom loading indicator with staggered dot animations:

```dart
class _PulsingDots extends StatefulWidget { ... }

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            // Calculate staggered animation value
            final delay = index * 0.2;
            // ... animation logic
            return Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
```

## SplashWrapper Integration

In `main.dart`, `SplashWrapper` manages the splash → auth transition:

```dart
class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  bool _showSplash = true;

  void _onSplashComplete() {
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(onComplete: _onSplashComplete);
    }
    return const AuthWrapper();
  }
}
```

### MaterialApp Configuration

```dart
MaterialApp(
  home: WithForegroundTask(
    child: SplashWrapper(),  // Shows splash first
  ),
  onGenerateRoute: _onGenerateRoute,
)
```

## Visual Elements

### Logo Container

```dart
Container(
  width: 120,
  height: 120,
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(30),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 30,
        offset: Offset(0, 10),
      ),
    ],
  ),
  child: Image.asset(
    'assets/icon/app_icon.png',
    errorBuilder: (context, error, stackTrace) {
      return Icon(Icons.restaurant, size: 60, color: AppColors.primary);
    },
  ),
)
```

### App Name Text

```dart
Text(
  'Food Finder',
  style: TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 1.2,
  ),
)
```

### Tagline Text

```dart
Text(
  'Discover nearby food vendors',
  style: TextStyle(
    fontSize: 16,
    color: Colors.white.withOpacity(0.9),
    fontWeight: FontWeight.w400,
  ),
)
```

## Timing Summary

| Phase | Duration | Total Time |
|-------|----------|------------|
| Initial delay | 200ms | 200ms |
| Logo animation | 600ms | 800ms |
| Text delay | 400ms | 600ms |
| Text animation | 500ms | 1100ms |
| Tagline delay | 300ms | 900ms |
| Tagline animation | 400ms | 1300ms |
| Final wait | 1100ms | ~2000ms |

Total splash duration: ~2 seconds
