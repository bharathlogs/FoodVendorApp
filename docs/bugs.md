# Bug Tracking

## Critical (Must Fix Before Launch)
| ID | Description | Status | Fix Notes |
|----|-------------|--------|-----------|
| C1 | Map tiles wrong userAgentPackageName | FIXED | Changed from placeholder to com.vendorapp.food_vendor_app |
| C2 | Vendor list shows "Something went wrong" | FIXED | Missing Firestore composite index for `isActive` + `locationUpdatedAt` query. Added index to `firestore.indexes.json` and deployed. |

## High Priority
| ID | Description | Status | Fix Notes |
|----|-------------|--------|-----------|
| H1 | setState after dispose in MapScreen | FIXED | Added mounted checks in _initCustomerLocation async callback |
| H2 | Login error message not user-friendly | FIXED | Added handling for `invalid-credential`, `INVALID_LOGIN_CREDENTIALS`, and `credential is incorrect` errors in `_formatError()` |
| H3 | App icon showing default Flutter icon | FIXED | Added `flutter_launcher_icons` configuration to `pubspec.yaml` and regenerated icons |
| H4 | Favorites tab shows "can't fetch favorites" | FIXED | Missing Firestore security rules for `favorites` collection. Added read/create/delete rules for authenticated users. |
| H5 | Splash screen icon zoomed out with transparent borders | FIXED | Applied `Transform.scale(1.25)` with `ClipRRect` to crop transparent edges and fill the container properly |

## Medium Priority
| ID | Description | Status | Fix Notes |
|----|-------------|--------|-----------|
| M1 | No centralized error handling | FIXED | Created ErrorHandler utility with user-friendly messages |
| M2 | No profile menu, logout button exposed directly | FIXED | Added profile popup menu with user email, role badge (Customer/Vendor), and logout option inside menu |
| M3 | Adaptive icon inset causing small app icon | FIXED | Removed 16% inset from `ic_launcher.xml` adaptive icon configuration |

## Low Priority (Nice to Have)
| ID | Description | Status | Fix Notes |
|----|-------------|--------|-----------|
| L1 | | | |

## Won't Fix (Known Limitations)
| ID | Description | Reason |
|----|-------------|--------|
| W1 | Background location may stop on some OEMs | Android OEM-specific battery optimization beyond app control |
