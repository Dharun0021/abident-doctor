# Firebase Setup for Doctor App - FCM Configuration

## Problem: FCM Token is NULL

**Root Cause**: `google-services.json` is missing from doctor app

---

## Solution: Setup Firebase for Doctor App

### Step 1: Get google-services.json

**Option A - Use Same Firebase Project (RECOMMENDED):**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your existing project: **"abidant"**
3. Click **⚙️ Project Settings**
4. Navigate to **"Your apps"** tab
5. Look for **Android apps**:
   - If doctor app NOT listed: Click **Add app** → Android
   - If doctor app listed: Download its google-services.json

6. **Register Android App** (if not already done):
   - Android package name: `com.example.flutter_doctor`
   - Android SHA-1: (Get from: `flutter clean && flutter run` then check logs OR run `keytool -list -v -keystore ~/.android/debug.keystore`)
   - App nickname: "Flutter Doctor"

7. Download `google-services.json`

8. Copy to: **`android/app/google-services.json`**

### Step 2: Verify Android Configuration

**build.gradle.kts** (android/app/):
```kotlin
plugins {
    id("com.android.application")
    id("com.google.gms.google-services")  // Make sure this line exists
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}
```

**build.gradle.kts** (android/):
```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.0" apply false
}
```

### Step 3: Verify Permissions in AndroidManifest.xml

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### Step 4: Rebuild App

```bash
flutter clean
flutter pub get
flutter run
```

---

## Checklist

- [ ] google-services.json placed in `android/app/`
- [ ] Android package name matches in Firebase Console
- [ ] FCM permissions in AndroidManifest.xml
- [ ] google-services plugin in build.gradle.kts
- [ ] App rebuilt with `flutter clean && flutter run`

---

## Testing

After rebuild, login and check console for:
```
FCM Token: <token_here> (NOT null)
FCM Token is null: false
```

If still null → Share Firebase Console screenshots for debugging

---

## Firebase Project Structure

```
Firebase Project: "abidant"
├── Android Apps:
│   ├── com.abidant.app (User App) ✅
│   └── com.example.flutter_doctor (Doctor App) ❌ MISSING - ADD THIS
├── Web Apps
├── iOS Apps
└── Settings
```

---

## Next Steps

1. Download/create google-services.json
2. Place in android/app/
3. Rebuild Flutter app
4. Login and check console logs
5. If FCM Token still null → Share Firebase configuration

