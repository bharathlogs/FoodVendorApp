# End-to-End Test Script

## Overview
This document contains comprehensive end-to-end test scenarios for the FoodVendorApp. Execute these tests to verify complete user flows work correctly from start to finish.

---

## Test 1: New Vendor Onboarding
**Prerequisites:** Fresh install or logged out state

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1.1 | Open app | Login screen appears |
| 1.2 | Tap "Sign up" | Signup screen appears |
| 1.3 | Select "Vendor" role | Vendor role selected |
| 1.4 | Enter: Business name, email, phone, password | Form filled |
| 1.5 | Tap "Create Vendor Account" | Account creation initiated |
| 1.6 | Verify navigation | Should land on Vendor Dashboard |
| 1.7 | Check Firestore | `users/{uid}` created with `role="vendor"` |
| 1.8 | Check Firestore | `vendor_profiles/{uid}` created |

---

## Test 2: Vendor Profile Setup
**Prerequisites:** Logged in as vendor

| Step | Action | Expected Result |
|------|--------|-----------------|
| 2.1 | Tap "Cuisine Types" card | Cuisine selection screen opens |
| 2.2 | Select 3 cuisines (e.g., South Indian, Beverages, Breakfast) | Cuisines highlighted |
| 2.3 | Tap "Save Cuisines" | Save initiated |
| 2.4 | Verify navigation | Returns to dashboard with cuisines displayed |
| 2.5 | Check Firestore | `vendor_profiles/{uid}/cuisineTags` updated |

---

## Test 3: Menu Setup
**Prerequisites:** Logged in as vendor

| Step | Action | Expected Result |
|------|--------|-----------------|
| 3.1 | Tap "Manage Menu" card | Menu management screen opens |
| 3.2 | Tap "Add First Item" or FAB | Add item form appears |
| 3.3 | Enter: Item name, price, description | Form filled |
| 3.4 | Tap "Add Item" | Item saved |
| 3.5 | Verify list | Item appears in list |
| 3.6 | Add 2 more items | Items added successfully |
| 3.7 | Verify count | Shows "3 / 50 items" |
| 3.8 | Toggle one item's availability switch | Switch toggled |
| 3.9 | Verify visual feedback | Item shows strikethrough and grey |
| 3.10 | Tap an item to edit | Edit form appears |
| 3.11 | Change price, tap "Update Item" | Changes saved |
| 3.12 | Tap item, tap "Delete Item", confirm | Item removed from list |

---

## Test 4: Vendor Goes Online
**Prerequisites:** Logged in as vendor with menu set up

| Step | Action | Expected Result |
|------|--------|-----------------|
| 4.1 | On dashboard, tap "GO ONLINE" | Online process initiated |
| 4.2 | Handle permissions (if first time) | Permission dialogs appear |
| 4.3 | Grant location permissions | Permissions granted |
| 4.4 | Verify button | Button changes to "GO OFFLINE" |
| 4.5 | Verify status card | Shows "You are OPEN" |
| 4.6 | Verify notification | Notification appears in status bar |
| 4.7 | Verify coordinates | Location coordinates displayed |
| 4.8 | Check Firestore | `vendor_profiles/{uid}/isActive` = true |
| 4.9 | Check Firestore | `vendor_profiles/{uid}/location` has GeoPoint |
| 4.10 | Check Firestore | `vendor_profiles/{uid}/locationUpdatedAt` recent |

---

## Test 5: Background Location
**Prerequisites:** Vendor is online

| Step | Action | Expected Result |
|------|--------|-----------------|
| 5.1 | Press home button (minimize app) | App minimized |
| 5.2 | Verify notification | Notification still visible |
| 5.3 | Wait 2 minutes | Time elapsed |
| 5.4 | Check Firestore | `locationUpdatedAt` updated |
| 5.5 | Lock screen | Screen locked |
| 5.6 | Wait 2 minutes | Time elapsed |
| 5.7 | Check Firestore | `locationUpdatedAt` still updating |
| 5.8 | Open app again | App resumed |
| 5.9 | Verify status | Still shows "You are OPEN" |

---

## Test 6: Vendor Goes Offline
**Prerequisites:** Vendor is online

| Step | Action | Expected Result |
|------|--------|-----------------|
| 6.1 | Tap "GO OFFLINE" | Offline process initiated |
| 6.2 | Verify button | Button changes to "GO ONLINE" |
| 6.3 | Verify status card | Shows "You are CLOSED" |
| 6.4 | Verify notification | Notification disappears |
| 6.5 | Check Firestore | `vendor_profiles/{uid}/isActive` = false |

---

## Test 7: Customer Discovery (Guest)
**Prerequisites:** Vendor is online, separate device/emulator or logged out

| Step | Action | Expected Result |
|------|--------|-----------------|
| 7.1 | Open app | App launched |
| 7.2 | Tap "Continue as Guest" | Guest mode activated |
| 7.3 | Verify screen | Map screen appears |
| 7.4 | Handle permissions | Location permission requested |
| 7.5 | Grant permission | Permission granted |
| 7.6 | Verify user marker | Blue marker shows your location |
| 7.7 | Verify vendor marker | Orange marker shows vendor (if nearby) |
| 7.8 | Debug (if needed) | If no vendors visible, check Firestore and emulator locations |

---

## Test 8: Customer Views Vendor
**Prerequisites:** Customer on map, vendor marker visible

| Step | Action | Expected Result |
|------|--------|-----------------|
| 8.1 | Tap vendor marker | Bottom sheet appears |
| 8.2 | Verify vendor info | Shows vendor name, Open status |
| 8.3 | Verify distance | Shows distance and walking time |
| 8.4 | Verify cuisines | Shows cuisine tags |
| 8.5 | Tap "View Menu" | VendorDetailScreen opens |
| 8.6 | Verify vendor card | Shows vendor info card |
| 8.7 | Verify menu | Shows menu items with prices |
| 8.8 | Verify availability | Unavailable items NOT shown |

---

## Test 9: Cuisine Filtering
**Prerequisites:** Customer on map

| Step | Action | Expected Result |
|------|--------|-----------------|
| 9.1 | Tap a cuisine filter chip (e.g., "South Indian") | Filter activated |
| 9.2 | Verify chip state | Chip becomes selected (orange) |
| 9.3 | Verify badge | "1 filter active" badge appears |
| 9.4 | Verify vendors | Only vendors with that cuisine visible |
| 9.5 | Tap another cuisine chip | Second filter added |
| 9.6 | Verify badge | "2 filters active" shown |
| 9.7 | Verify vendors | Vendors matching EITHER cuisine visible |
| 9.8 | Tap "Clear All" | Clear action triggered |
| 9.9 | Verify filters | All filters removed |
| 9.10 | Verify vendors | All vendors visible again |

---

## Test 10: Logout Flow
**Prerequisites:** Logged in as vendor, online

| Step | Action | Expected Result |
|------|--------|-----------------|
| 10.1 | While online, tap logout icon | Logout initiated |
| 10.2 | Verify broadcasting | Should stop broadcasting first |
| 10.3 | Check Firestore | `isActive` = false |
| 10.4 | Verify navigation | Returns to login screen |
| 10.5 | Log back in | Login successful |
| 10.6 | Verify navigation | Returns to vendor dashboard |
| 10.7 | Verify status | Shows "You are CLOSED" (not auto-online) |

---

## Testing Tips

### Setting Up Test Environment
1. Use Android Emulator or physical device
2. Ensure Firebase project is connected
3. Have Firestore Console open to verify data changes
4. For multi-device tests, use two emulators or emulator + physical device

### Mock Location for Testing
For emulator testing, set mock locations via:
- Extended Controls > Location in Android Emulator
- Set different locations for vendor and customer tests

### Firestore Verification
Monitor these collections during testing:
- `users/{uid}` - User authentication data
- `vendor_profiles/{uid}` - Vendor profile and location
- `menu_items/{vendorId}/items/{itemId}` - Menu items

### Common Issues
- **No vendors on map**: Check vendor's `isActive` field and location coordinates
- **Location not updating**: Verify battery optimization is disabled for app
- **Permission denied**: Clear app data and re-test permission flow
