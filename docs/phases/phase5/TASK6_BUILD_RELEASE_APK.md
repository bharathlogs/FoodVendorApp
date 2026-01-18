# Task 6: Build Release APK

**Status**: Complete
**Date**: 2026-01-18

---

## Objective

Build a release APK for distribution with proper signing and code optimization.

---

## Steps Completed

### 1. Keystore Created

**Location**: `~/food-vendor-key.jks`

**Command Used**:
```bash
keytool -genkey -v -keystore ~/food-vendor-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias food-vendor
```

**Keystore Details**:
| Property | Value |
|----------|-------|
| Algorithm | RSA |
| Key Size | 2048 bits |
| Validity | 10,000 days (~27 years) |
| Alias | food-vendor |
| DN | CN=Food Finder, OU=Mobile Development, O=VendorApp |

**IMPORTANT**: Backup this keystore file! You need it for all future app updates.

---

### 2. Signing Configuration Created

**File**: `android/key.properties`

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=food-vendor
storeFile=/Users/equipp/food-vendor-key.jks
```

**Security**: This file is added to `.gitignore` and should NEVER be committed.

---

### 3. build.gradle.kts Updated

**File**: `android/app/build.gradle.kts`

**Changes**:
- Added imports for Properties and FileInputStream
- Added keystoreProperties loading
- Added release signingConfig
- Enabled minifyEnabled and shrinkResources for release builds
- Configured ProGuard

**Key Code**:
```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

---

### 4. ProGuard Rules Created

**File**: `android/app/proguard-rules.pro`

**Rules Include**:
- Flutter and Flutter plugins
- Play Core suppression (deferred components)
- Firebase
- Geolocator
- Flutter Foreground Task
- Serializable and Parcelable classes

---

### 5. .gitignore Updated

**Added**:
```
android/key.properties
```

**Already Present**:
```
*.jks
*.keystore
```

---

### 6. Release APK Built

**Command**:
```bash
flutter build apk --release
```

**Output**:
```
build/app/outputs/flutter-apk/app-release.apk (54.8MB)
```

**Build Optimizations**:
- Material Icons tree-shaken (99.7% reduction)
- Code minification enabled
- Resource shrinking enabled

---

## Files Created

| File | Purpose |
|------|---------|
| `~/food-vendor-key.jks` | Release signing keystore |
| `android/key.properties` | Signing configuration (not in git) |
| `android/app/proguard-rules.pro` | Code optimization rules |

## Files Modified

| File | Changes |
|------|---------|
| `android/app/build.gradle.kts` | Added signing config, ProGuard |
| `.gitignore` | Added key.properties |

---

## Build Output

| File | Location | Size |
|------|----------|------|
| Release APK | `build/app/outputs/flutter-apk/app-release.apk` | 54.8 MB |

---

## Success Criteria

- [x] Keystore created and stored securely
- [x] key.properties configured
- [x] build.gradle.kts updated for release signing
- [x] ProGuard rules created
- [x] key.properties NOT in git
- [x] Release APK builds successfully

---

## Next Steps

To install and test the release APK:

```bash
# Install on connected device
flutter install --release

# Or manually via adb
adb install build/app/outputs/flutter-apk/app-release.apk
```

To build App Bundle for Play Store:

```bash
flutter build appbundle --release
```

---

## Important Reminders

1. **Backup Keystore**: Copy `~/food-vendor-key.jks` to a secure backup location
2. **Remember Password**: Store the keystore password securely
3. **Never Commit Secrets**: Ensure `key.properties` and `*.jks` stay out of git
4. **Test Release Build**: Release builds may behave differently than debug
