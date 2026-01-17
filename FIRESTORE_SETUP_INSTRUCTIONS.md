# Firestore Database Setup Instructions

**Project ID**: foodvendorapp2911

## Step 1: Create Firestore Database

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **foodvendorapp2911**
3. Navigate to **Build → Firestore Database** (left sidebar)
4. If database doesn't exist, click **"Create database"**
5. **Location**: Select **asia-south1 (Mumbai)** for India-based users
6. **Security rules**: Start in **test mode** (we'll update rules in Step 2)
7. Click **"Enable"** and wait for provisioning

## Step 2: Configure Security Rules

1. In Firestore Database, go to the **Rules** tab
2. Replace the default rules with the following:

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

3. Click **"Publish"** to save the rules

## Step 3: Verify Setup

Run this command in your terminal to test the connection:

```bash
cd /Users/equipp/Documents/VendorApp/FoodVendorApp
# Note: Flutter command may not be available in your PATH
# If flutter command is not found, run the app from Android Studio instead
```

If you see "Firebase Connected!" in the app, the setup is successful.

## Step 4: Test Firestore Access (Optional)

You can test by creating a test document in the Firebase Console:

1. Go to Firestore Database → Data tab
2. Click **"Start collection"**
3. Collection ID: `vendor_profiles`
4. Document ID: `test_vendor`
5. Add fields:
   - `businessName` (string): "Test Vendor"
   - `description` (string): "Test Description"
   - `cuisineTags` (array): ["Test"]
   - `isActive` (boolean): true
6. Click **"Save"**

## Security Checklist

- [ ] Database created in asia-south1 region
- [ ] Security rules published (not in test mode)
- [ ] Test mode expiration removed
- [ ] No public write access (read-only for non-authenticated users on vendor_profiles only)

## Common Issues

**Issue**: "Insufficient permissions" error
**Solution**: Make sure security rules are published correctly

**Issue**: Can't see database in console
**Solution**: Refresh the page, or check if you're in the correct Firebase project

**Issue**: Rules show as expired
**Solution**: Replace test mode rules with the production rules above

---

**After completing these steps, delete this file or move it to a docs folder.**
