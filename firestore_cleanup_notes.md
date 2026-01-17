# Server-Side Timeout Cleanup (Future Enhancement)

If you need automatic server-side cleanup, you can add a Cloud Function:

```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.cleanupStaleVendors = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async (context) => {
    const db = admin.firestore();
    const cutoffTime = new Date(Date.now() - 10 * 60 * 1000); // 10 min ago

    const staleVendors = await db
      .collection('vendor_profiles')
      .where('isActive', '==', true)
      .where('locationUpdatedAt', '<', cutoffTime)
      .get();

    const batch = db.batch();
    staleVendors.docs.forEach((doc) => {
      batch.update(doc.ref, { isActive: false });
    });

    await batch.commit();
    console.log(`Cleaned up ${staleVendors.size} stale vendors`);
  });
```

**Note:** This requires Firebase Blaze plan for Cloud Functions.
For MVP with 10 vendors, client-side filtering is sufficient.
