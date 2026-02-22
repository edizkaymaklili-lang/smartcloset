# Firebase Setup Guide - Stil Asist

## 📋 Required Services
- ✅ Firebase Authentication
- ✅ Cloud Firestore (Database)
- ✅ Firebase Storage (Photos)
- ✅ Cloud Functions (AI recommendations)
- ✅ Google Maps API

---

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add project"
3. Project name: **Stil Asist** (or your preferred name)
4. Enable Google Analytics: **Yes** (recommended)
5. Choose Analytics account or create new
6. Click "Create project" ⏳ (takes ~1 minute)

---

## Step 2: Add Android App

1. In project overview, click Android icon
2. Android package name: `com.example.stil_asist`
   - Find in: `android/app/build.gradle` → `applicationId`
3. App nickname: **Stil Asist Android**
4. Debug signing certificate (optional for now)
5. Click "Register app"
6. **Download `google-services.json`**
7. **IMPORTANT**: Place file in `android/app/` directory
   ```
   android/
     app/
       google-services.json  ← HERE
       build.gradle
   ```

---

## Step 3: Enable Firestore Database

1. In Firebase Console → **Build** → **Firestore Database**
2. Click "Create database"
3. Choose location: **europe-west1** (or closest to users)
4. Start in **Production mode** (we'll set rules)
5. Click "Enable"

### Security Rules (Update Rules Tab):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Style posts - anyone can read, authenticated can write
    match /style_posts/{postId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null
                              && request.auth.uid == resource.data.userId;
    }

    // User data - only owner can access
    match /users/{userId} {
      allow read, write: if request.auth != null
                           && request.auth.uid == userId;

      // Saved posts subcollection
      match /saved_posts/{postId} {
        allow read, write: if request.auth != null
                             && request.auth.uid == userId;
      }
    }

    // Contest entries (legacy - can be removed later)
    match /contest_entries/{entryId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow delete: if request.auth != null
                     && request.auth.uid == resource.data.userId;
    }
  }
}
```

---

## Step 4: Enable Firebase Storage

1. In Firebase Console → **Build** → **Storage**
2. Click "Get started"
3. Start in **Production mode**
4. Choose location: **europe-west1** (same as Firestore)
5. Click "Done"

### Storage Rules (Update Rules Tab):
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    // Style post photos
    match /style_posts/{userId}/{postId}.jpg {
      allow read: if true;
      allow write: if request.auth != null
                    && request.auth.uid == userId
                    && request.resource.size < 5 * 1024 * 1024; // Max 5MB
    }

    // Wardrobe item photos
    match /wardrobe/{userId}/{itemId}.jpg {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null
                    && request.auth.uid == userId
                    && request.resource.size < 5 * 1024 * 1024;
    }

    // User avatars
    match /avatars/{userId}.jpg {
      allow read: if true;
      allow write: if request.auth != null
                    && request.auth.uid == userId
                    && request.resource.size < 2 * 1024 * 1024; // Max 2MB
    }
  }
}
```

---

## Step 5: Enable Authentication

1. In Firebase Console → **Build** → **Authentication**
2. Click "Get started"
3. Enable providers:
   - ✅ **Email/Password** (click, toggle on, save)
   - ✅ **Google** (click, toggle on, add support email, save)

### Test Users (Create for development):
1. Go to **Users** tab
2. Click "Add user"
3. Email: `test@stilasist.com`
4. Password: `test123456`
5. Click "Add user"

---

## Step 6: Upgrade to Blaze Plan (for Cloud Functions)

⚠️ **Required for AI recommendations & Cloud Functions**

1. In Firebase Console → ⚙️ (bottom left) → **Usage and billing**
2. Click "Modify plan"
3. Select "Blaze (Pay as you go)"
4. Add billing account (credit card required)
5. **Don't worry**: Free tier is generous
   - Firestore: 50K reads/20K writes per day FREE
   - Storage: 5GB storage, 1GB download per day FREE
   - Functions: 2M invocations per month FREE

---

## Step 7: Setup Cloud Functions (AI Recommendations)

### Install Firebase CLI:
```bash
npm install -g firebase-tools
```

### Login to Firebase:
```bash
firebase login
```

### Initialize Functions:
```bash
cd "C:\Users\DeboMac\Documents\GitHub\Stil Asist"
firebase init functions
```

**Choices:**
- Use existing project: **Stil Asist**
- Language: **JavaScript**
- ESLint: **No** (or Yes, your choice)
- Install dependencies: **Yes**

### Get Gemini API Key:
1. Go to [Google AI Studio](https://aistudio.google.com)
2. Click "Get API key"
3. Create new project or select existing
4. Copy API key

### Set Secret:
```bash
firebase functions:secrets:set GEMINI_API_KEY
# Paste your Gemini API key when prompted
```

### Copy Cloud Function Code:
The function code is already in `functions/index.js` (we'll create this next).

---

## Step 8: Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select your Firebase project (or create new)
3. **Enable APIs**:
   - Maps SDK for Android
   - Maps SDK for iOS (if planning iOS)
4. **Create credentials**:
   - Credentials → Create Credentials → API Key
   - Copy the API key
5. **Restrict API Key** (recommended):
   - Click on API key → Application restrictions
   - Select "Android apps"
   - Add package name: `com.example.stil_asist`
   - Add SHA-1 certificate fingerprint (get from Android Studio or `keytool`)

### Add to AndroidManifest.xml:
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<!-- Find line 47 and replace YOUR_GOOGLE_MAPS_API_KEY_HERE -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXX"/>
```

---

## Step 9: Test Firebase Connection

### Run flutter commands:
```bash
cd "C:\Users\DeboMac\Documents\GitHub\Stil Asist"
flutter clean
flutter pub get
flutter run
```

### Test checklist:
- [ ] App launches without errors
- [ ] Can navigate to Style Feed tab
- [ ] Can tap "Share Your Style" button
- [ ] Can select photo from gallery
- [ ] Photo preview appears
- [ ] Can add tags and description
- [ ] Location detected (if permissions granted)
- [ ] "Share" button works
- [ ] Post appears in feed (after refresh)
- [ ] Can like posts
- [ ] Map view shows posts with markers

---

## Step 10: Create Initial Test Data

### Option A: Use App UI
1. Open app → Navigate to Style Feed
2. Tap "Share Your Style"
3. Upload 5-10 different outfit photos
4. Add various tags: #casual, #formal, #summer, #winter, etc.
5. Set different location privacy settings

### Option B: Use Firebase Console
1. Go to Firestore → `style_posts` collection
2. Add document manually (click "Add document")
3. Copy structure from app's first post

---

## 🎯 Verification

### Firestore Check:
1. Firebase Console → Firestore Database
2. Should see `style_posts` collection
3. Each document has fields: userId, photoUrl, tags, likes, etc.

### Storage Check:
1. Firebase Console → Storage
2. Should see `style_posts/userId/postId.jpg` files
3. Images should be viewable

### Map Check:
1. Open app → Style Feed → Tap map icon
2. Should see Google Maps
3. Markers appear for posts with location
4. Tap marker → preview sheet opens

---

## 🐛 Troubleshooting

### "Default FirebaseApp is not initialized"
- ✅ Check `google-services.json` is in `android/app/`
- ✅ Run `flutter clean && flutter pub get`
- ✅ Rebuild app

### "Maps API key not found"
- ✅ Check AndroidManifest.xml has API key
- ✅ API key is not restricted to wrong app
- ✅ Maps SDK for Android is enabled in Cloud Console

### "Permission denied" errors
- ✅ Check Firestore security rules
- ✅ User must be authenticated for writes
- ✅ Check Storage rules allow uploads

### Posts not appearing
- ✅ Check Firestore rules allow reads
- ✅ Pull to refresh the feed
- ✅ Check Firebase Console → Firestore for documents

---

## 📊 Cost Estimation (Monthly)

**Typical usage for testing/development:**
- Firestore: FREE (under free tier limits)
- Storage: FREE (under 5GB)
- Functions: FREE (under 2M invocations)
- Maps: FREE (under $200 monthly credit for Maps usage)

**Important**: Set budget alerts in Google Cloud Console!

---

## 🔐 Security Best Practices

1. ✅ Never commit `google-services.json` to public repo
2. ✅ Add to `.gitignore`: `android/app/google-services.json`
3. ✅ Use Firestore rules to protect data
4. ✅ Restrict Maps API key to your app package
5. ✅ Monitor Firebase usage dashboard regularly

---

## 📞 Support

- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Firebase](https://firebase.flutter.dev)
- [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)

---

**Next**: After setup, test all features and proceed to Phase 3! 🚀
