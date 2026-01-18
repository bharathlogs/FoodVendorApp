# Testing Documentation

## Overview

This folder contains testing documentation and results for the Food Finder app.

---

## Test Sessions

| Session | Date | Status | Documentation |
|---------|------|--------|---------------|
| Phase 1 Live Testing | Jan 18, 2026 | PASS | [PHASE1_LIVE_TESTING.md](PHASE1_LIVE_TESTING.md) |
| Emulator Location Testing | Jan 18, 2026 | PASS | [EMULATOR_LOCATION_TESTING_EXECUTION.md](EMULATOR_LOCATION_TESTING_EXECUTION.md) |

---

## Test Environment

| Property | Value |
|----------|-------|
| Primary Device | Android Emulator (API 36) |
| Flutter Version | 3.38.7 |
| Firebase Project | asia-south1 |

---

## Quick Commands

### Run App on Emulator
```bash
flutter run -d emulator-5554
```

### Set Emulator Location
```bash
~/Library/Android/sdk/platform-tools/adb emu geo fix <longitude> <latitude>

# Example (Bangalore):
~/Library/Android/sdk/platform-tools/adb emu geo fix 77.5946 12.9716
```

### Run Unit Tests
```bash
flutter test
```

---

## Issues Tracker

| ID | Issue | Status | Fixed In |
|----|-------|--------|----------|
| T1 | BootReceiver crash on Android 16 | FIXED | PHASE1_LIVE_TESTING |
| T2 | Emulator location inaccurate | DOCUMENTED | PHASE1_LIVE_TESTING |

---

## Test Scripts

For comprehensive test scenarios, see:
- [End-to-End Test Script](../../docs/end-to-end-test-script.md)
- [Test Results Template](../../docs/test-results.md)
