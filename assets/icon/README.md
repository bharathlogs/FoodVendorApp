# App Icon Assets

Place your app icon files here:

## Required Files

### 1. `app_icon.png`
- **Size**: 1024x1024 pixels
- **Format**: PNG with transparency
- **Purpose**: Main app icon (used as fallback on older devices)

### 2. `app_icon_foreground.png`
- **Size**: 432x432 pixels (centered in 108dp safe zone)
- **Format**: PNG with transparent background
- **Purpose**: Adaptive icon foreground (Android 8.0+)
- **Note**: Keep important content within the center 66% to avoid clipping

## How to Generate Icons

### Option A: Online Generator (Recommended for MVP)
1. Go to [AppIcon.co](https://appicon.co) or [MakeAppIcon](https://makeappicon.com)
2. Upload your 1024x1024 PNG image
3. Download Android icons
4. Replace files in `android/app/src/main/res/mipmap-*`

### Option B: Use flutter_launcher_icons
After placing your icon files here, run:
```bash
flutter pub run flutter_launcher_icons
```

## Current Configuration

The app uses an orange theme (`#FF9800`) as the adaptive icon background.
See `flutter_launcher_icons.yaml` in the project root for full configuration.
