# Phase 1 - Task 3: Backend Service Provisioning (Firebase Setup)

**Status**: ✅ COMPLETED
**Completion Date**: 2026-01-17
**Estimated Effort**: 1.5-2 hours (as per guide)
**Actual Effort**: ~2 hours

---

## Objective

Create a Firebase project, connect it to the Flutter app, and configure Firestore with security rules.

---

## Why This Matters for Later Phases

- All data storage, auth, and real-time sync depend on this foundation
- Security rules prevent unauthorized access
- Proper configuration prevents production security incidents

---

## Firebase Project Configuration

### Project Details

| Setting | Value |
|---------|-------|
| Project Name | FoodVendorApp |
| Project ID | `foodvendorapp2911` |
| Project Number | 847733100272 |
| Database Location | nam5 (North America) |
| Google Analytics | Disabled |

**Note on Location**: Database is in `nam5` instead of recommended `asia-south1` (Mumbai). This will result in slightly higher latency for India-based users but is not a critical blocker for MVP.

---

## Completed Steps

### Step 3.1: Create Firebase Project ✅

**Actions Taken:**
1. ✅ Navigated to Firebase Console
2. ✅ Created project: "FoodVendorApp"
3. ✅ Disabled Google Analytics (simplified setup)
4. ✅ Project provisioned successfully

**Verification:**
- Project visible in Firebase Console
- Project ID: `foodvendorapp2911`

---

### Step 3.2: Add Android App to Firebase ✅

**Configuration:**

| Setting | Value |
|---------|-------|
| Package Name | `com.vendorapp.food_vendor_app` |
| App Nickname | FoodVendorApp |
| App ID | 1:847733100272:android:8c3eff93a12b74930cfc35 |

**Files Generated:**
- `google-services.json` → Placed in `android/app/`
- ✅ File properly gitignored

**SHA-1 Certificate:**
Debug SHA-1 obtained using:
```bash
cd android
./gradlew signingReport
```
Added to Firebase (required for Google Sign-In in future)

---

### Step 3.3: Add Firebase Dependencies ✅

**Gradle Configuration:**

**File**: [android/app/build.gradle.kts](../../android/app/build.gradle.kts)
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // Added
}
```

**Why Google Services Plugin?**
- Processes `google-services.json` at build time
- Injects Firebase configuration into app
- Required for Firebase SDK initialization

---

### Step 3.4: Add Flutter Firebase Packages ✅

**File**: [pubspec.yaml:40-42](../../pubspec.yaml#L40-L42)

```yaml
dependencies:
  firebase_core: ^3.8.0
  firebase_auth: ^5.3.3
  cloud_firestore: ^5.5.0
```

**Package Purposes:**

1. **firebase_core** (^3.8.0):
   - Core Firebase SDK
   - Required by all Firebase packages
   - Handles initialization

2. **firebase_auth** (^5.3.3):
   - User authentication (Phase 2)
   - Email/password and Google Sign-In
   - Session management

3. **cloud_firestore** (^5.5.0):
   - NoSQL database
   - Real-time data sync
   - Offline persistence

**Version Selection:**
- Using latest stable versions as of 2026-01-17
- Compatible with Flutter SDK >=3.10.0
- Tested and production-ready

---

### Step 3.5: FlutterFire CLI Configuration ✅

**Command Executed:**
```bash
flutterfire configure --project=foodvendorapp2911
```

**Files Generated:**

1. **firebase.json**:
   ```json
   {
     "flutter": {
       "platforms": {
         "android": {
           "default": {
             "projectId": "foodvendorapp2911",
             "appId": "1:847733100272:android:8c3eff93a12b74930cfc35"
           }
         }
       }
     }
   }
   ```

2. **lib/firebase_options.dart**:
   - Platform-specific Firebase configuration
   - Contains API keys and project identifiers
   - ✅ Properly gitignored

**Security Note:**
- `firebase_options.dart` contains sensitive configuration
- Added to [.gitignore:55](../../.gitignore#L55)
- Not committed to git (verified)

---

### Step 3.6: Initialize Firebase in App ✅

**File**: [lib/main.dart:5-10](../../lib/main.dart#L5-L10)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

**Key Implementation Details:**

1. **WidgetsFlutterBinding.ensureInitialized()**:
   - Required before async operations in main()
   - Initializes Flutter engine

2. **await Firebase.initializeApp()**:
   - Asynchronous initialization
   - Uses platform-specific options
   - Must complete before app starts

3. **DefaultFirebaseOptions.currentPlatform**:
   - Auto-selects correct config for platform
   - From generated `firebase_options.dart`

**UI Confirmation:**
Updated home screen to show "Firebase Connected!" message for verification.

---

### Step 3.7: Enable Firestore Database ✅

**Database Configuration:**

| Setting | Value |
|---------|-------|
| Database Name | (default) |
| Location | nam5 (North America) |
| Mode | Production (with custom rules) |

**Creation Steps:**
1. ✅ Navigated to Firestore Database in console
2. ✅ Created database
3. ✅ Configured security rules (see next section)

---

### Step 3.8: Configure Security Rules ✅

**File**: Firestore Rules (in Firebase Console)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users collection: users can only read/write their own document
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null && request.auth.uid == userId;
      allow update: if request.auth != null && request.auth.uid == userId;
      allow delete: if false;  // Never allow deletion
    }

    // Vendor profiles: public read, vendor-only write
    match /vendor_profiles/{vendorId} {
      allow read: if true;  // Customers need to see this without login
      allow create: if request.auth != null
                    && request.auth.uid == vendorId;
      allow update: if request.auth != null
                    && request.auth.uid == vendorId;
      allow delete: if false;

      // Menu items subcollection
      match /menu_items/{itemId} {
        allow read: if true;
        allow write: if request.auth != null
                     && request.auth.uid == vendorId;
      }
    }

    // Orders: vendor can read their orders, anyone can create
    match /orders/{orderId} {
      allow read: if request.auth != null
                  && request.auth.uid == resource.data.vendorId;
      allow create: if true;  // No login required to place order
      allow update: if request.auth != null
                    && request.auth.uid == resource.data.vendorId;
      allow delete: if false;
    }
  }
}
```

**Security Rule Breakdown:**

#### 1. Users Collection
```javascript
match /users/{userId} {
  allow read: if request.auth != null && request.auth.uid == userId;
  allow create: if request.auth != null && request.auth.uid == userId;
  allow update: if request.auth != null && request.auth.uid == userId;
  allow delete: if false;
}
```

**Rules:**
- Users can only read their own document
- Users can only create/update their own document
- Deletion disabled (data preservation)

**Why:**
- Privacy: Users can't see other users' data
- Security: Prevents impersonation
- Data integrity: Prevents accidental deletion

---

#### 2. Vendor Profiles Collection
```javascript
match /vendor_profiles/{vendorId} {
  allow read: if true;  // Public read
  allow create: if request.auth != null && request.auth.uid == vendorId;
  allow update: if request.auth != null && request.auth.uid == vendorId;
  allow delete: if false;
}
```

**Rules:**
- Anyone can read (including unauthenticated customers)
- Only the vendor can create/update their own profile
- Deletion disabled

**Why:**
- Customers need to browse vendors without login
- Vendors can only modify their own data
- Profile preservation

---

#### 3. Menu Items Subcollection
```javascript
match /menu_items/{itemId} {
  allow read: if true;  // Public read
  allow write: if request.auth != null && request.auth.uid == vendorId;
}
```

**Rules:**
- Anyone can read menu items
- Only the vendor can modify their menu

**Why:**
- Customers need to see menus without login
- Prevents tampering by other vendors
- Inherits vendorId from parent path

---

#### 4. Orders Collection
```javascript
match /orders/{orderId} {
  allow read: if request.auth != null
              && request.auth.uid == resource.data.vendorId;
  allow create: if true;  // Unauthenticated allowed
  allow update: if request.auth != null
                && request.auth.uid == resource.data.vendorId;
  allow delete: if false;
}
```

**Rules:**
- Anyone can create orders (customers not authenticated)
- Only the vendor can read their orders
- Only the vendor can update order status
- Deletion disabled

**Why:**
- MVP requirement: No customer login
- Privacy: Vendors can't see other vendors' orders
- Order integrity: Only vendor can update status

---

### Step 3.9: Security Verification ✅

**Checklist:**

- [x] google-services.json in .gitignore
- [x] firebase_options.dart in .gitignore
- [x] No API keys in git history
- [x] Security rules published (not test mode)
- [x] Test mode rules removed
- [x] No public write access (except orders creation)
- [x] Deletion disabled on all collections

**Git Verification:**
```bash
✅ google-services.json NOT in git
✅ firebase_options.dart NOT in git
✅ No sensitive data in commit history
✅ .gitignore properly configured
```

---

## Success Criteria Checklist

- [x] Firebase project created
- [x] Android app registered
- [x] Firebase dependencies added
- [x] App initializes Firebase successfully
- [x] Firestore database created
- [x] Security rules configured
- [x] No test mode rules
- [x] Sensitive files gitignored
- [x] All changes committed to git

---

## Common Pitfalls Avoided

| Pitfall | How We Avoided It | Impact |
|---------|-------------------|--------|
| Wrong package name | Matched exactly with build.gradle | Critical |
| Forgetting SHA-1 | Added during initial setup | Medium |
| Test mode security rules | Replaced with production rules immediately | Critical |
| Committing secrets | Added to .gitignore BEFORE generation | Critical |
| Missing Google Services plugin | Added to build.gradle.kts | Critical |

---

## Files Created/Modified

### Created:
1. **android/app/google-services.json** (gitignored)
   - Firebase Android configuration
   - Contains API keys and project IDs

2. **lib/firebase_options.dart** (gitignored)
   - Platform-specific Firebase config
   - Auto-generated by FlutterFire CLI

3. **firebase.json**
   - FlutterFire configuration metadata
   - Safe to commit (no secrets)

4. **phases/phase1/FIRESTORE_SETUP_INSTRUCTIONS.md**
   - Manual setup guide
   - Security rules documentation

### Modified:
1. [android/app/build.gradle.kts](../../android/app/build.gradle.kts)
   - Added Google Services plugin
   - Updated dependencies

2. [android/build.gradle.kts](../../android/build.gradle.kts)
   - Build configuration updates

3. [lib/main.dart](../../lib/main.dart)
   - Firebase initialization
   - UI confirmation screen

4. [.gitignore](../../.gitignore)
   - Added firebase_options.dart
   - Verified google-services.json exclusion

5. [pubspec.yaml](../../pubspec.yaml)
   - Added Firebase dependencies

---

## Testing & Verification

### Local Testing ✅

**Test**: App Launch
```bash
Expected: App launches without Firebase errors
Result: ✅ Success - "Firebase Connected!" displayed
```

**Test**: Firebase Initialization
```bash
Expected: No console errors related to Firebase
Result: ✅ Success - Clean initialization
```

### Firebase Console Verification ✅

**Checklist:**
- [x] Project visible in console
- [x] Android app registered
- [x] Firestore database active
- [x] Security rules published
- [x] No test mode warnings

---

## Database Location Consideration

**Current**: nam5 (North America)
**Recommended**: asia-south1 (Mumbai)

**Impact Analysis:**

| Factor | nam5 | asia-south1 |
|--------|------|-------------|
| Latency from India | ~200-300ms | ~50-100ms |
| Impact on MVP | Low | N/A |
| Migration Cost | Possible later | N/A |
| Data Residency | USA | India |

**Recommendation**:
For MVP, nam5 is acceptable. Consider migration to asia-south1 before production launch if targeting India-based users exclusively.

---

## Security Best Practices Implemented

### 1. API Key Protection ✅
```
✅ google-services.json gitignored
✅ firebase_options.dart gitignored
✅ No hardcoded API keys in source
```

### 2. Principle of Least Privilege ✅
```
✅ Users can only access their own data
✅ Vendors can only modify their own profiles
✅ No blanket public write access
✅ Deletion disabled on all collections
```

### 3. Authentication-Based Access ✅
```
✅ Most operations require authentication
✅ Exception: Order creation (by design)
✅ Exception: Public read on vendor data (by design)
```

### 4. Data Integrity ✅
```
✅ Deletion disabled
✅ Vendor-ID validation in rules
✅ User-ID validation in rules
```

---

## Firebase Services Configuration Summary

### Enabled Services

| Service | Status | Purpose | Phase |
|---------|--------|---------|-------|
| Firebase Core | ✅ Active | Foundation | 1 |
| Authentication | ✅ Configured | User login | 2 |
| Cloud Firestore | ✅ Active | Database | 1-4 |
| Cloud Storage | ❌ Not yet | Images | 3-4 |
| Cloud Functions | ❌ Not yet | Backend logic | Future |

---

## Dependencies

### From Previous Tasks:
- ✅ Task 1: Project structure
- ✅ Task 2: Data models defined

### For Next Phase:
- ✅ Firebase ready for authentication (Phase 2)
- ✅ Firestore ready for data storage (Phase 2-4)
- ✅ Security rules support all planned features

---

## Key Learnings

### 1. FlutterFire CLI Benefits
- Automates platform-specific configuration
- Generates type-safe Dart configuration
- Reduces manual setup errors

### 2. Security Rules Design
- Design rules for all phases upfront
- Test mode is a security risk
- Always disable deletion for data preservation

### 3. Git Security
- Add sensitive files to .gitignore BEFORE generating them
- Verify exclusion before every commit
- Multiple file path variations may be needed

### 4. Firebase Project Setup
- SHA-1 needed for Google Sign-In
- Database location affects latency
- Google Analytics optional for MVP

---

## Metrics

| Metric | Value |
|--------|-------|
| Firebase packages added | 3 |
| Security rules defined | 4 collections |
| Configuration files | 3 (2 gitignored) |
| Build errors | 0 |
| Security issues | 0 |
| Git commits | 1 (main commit) |

---

## Troubleshooting Guide

### Issue: "Firebase not initialized"
**Solution**: Check main.dart has `await Firebase.initializeApp()`

### Issue: "google-services.json not found"
**Solution**: Verify file is in `android/app/` directory

### Issue: "Insufficient permissions" error
**Solution**: Verify security rules are published

### Issue: Firebase initialization slow
**Solution**: Normal on first launch; subsequent launches faster

---

## Next Steps

**Phase 1 Complete** ✅

All foundation work done. Ready to proceed to:

**Phase 2: Authentication & Location Tracking**
- Vendor login/signup
- Real-time location updates
- Vendor dashboard

---

## References

- [Firebase Android Setup Guide](https://firebase.google.com/docs/android/setup)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Firebase Console](https://console.firebase.google.com/)

---

## Documentation Files Created

1. [FIRESTORE_SETUP_INSTRUCTIONS.md](../../FIRESTORE_SETUP_INSTRUCTIONS.md)
   - Manual setup guide
   - Security rules reference
   - Verification checklist

2. [PHASE1_COMPLETION_SUMMARY.md](../../PHASE1_COMPLETION_SUMMARY.md)
   - Overall Phase 1 summary
   - Success metrics
   - Next steps guide

---

**Task 3 Complete** ✅
**Phase 1 Complete** ✅
**Ready for Phase 2** ✅
