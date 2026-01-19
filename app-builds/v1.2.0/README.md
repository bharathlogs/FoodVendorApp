# Version 1.2.0 Release Notes

**Release Date:** January 19, 2026

## New Features

### Vendor Phone Number & Call Functionality
- Vendors must now provide a phone number during registration (required field)
- Customers can now call vendors directly from the map view
- Green call button appears in vendor bottom sheet when phone number is available
- Tapping the call button opens the device dialer

### Real-time Vendor Movement Animations
- Vendor markers now animate smoothly when positions update
- 800ms animation duration with easeInOutCubic curve
- 60fps smooth transitions using Flutter Ticker
- Battery efficient: animations only run when position changes

### Vendor Profile Phone Number Management
- Existing vendors can now add/update their phone number
- New "Phone Number" card in vendor home screen
- Phone number validation (10-15 digits)
- Real-time Firestore update

### Dark Mode Improvements
- Fixed text visibility in vendor bottom sheet for dark mode
- Handle bar color adapts to theme
- Description and labels now properly visible in dark mode

## Dependencies Added
- `url_launcher: ^6.2.6` - For phone dialer integration

## Files Modified
- `lib/models/vendor_profile.dart` - Added phoneNumber field
- `lib/screens/auth/signup_screen.dart` - Phone required for vendors
- `lib/services/auth_service.dart` - Store phone in profile
- `lib/widgets/customer/vendor_bottom_sheet.dart` - Call button & dark mode
- `lib/widgets/customer/animated_vendor_marker.dart` - New animation system
- `lib/screens/customer/map_screen.dart` - Animation integration
- `lib/screens/vendor/vendor_home.dart` - Phone number card

## Testing
- All 209 tests passing
- Tested on Android emulator (API 36)
