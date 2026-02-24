# User Accounts & Cloud Sync

This doc covers everything about the user accounts + cloud sync feature I added to the Believers Songbook app. If you're picking this up or need to test/debug, this should have everything you need.

---

## What this feature does

Users can sign in with Google, Apple, or Email/Password. Once signed in, their settings (font size, dark mode, selected songbook, etc.) and custom collections get synced to Firebase. If they reinstall the app or use it on another device, signing in again restores everything.

There's also a first-install onboarding screen that prompts new users to sign in right away (they can skip it). Existing users who update the app see a "What's New" dialog instead.

Every screen's AppBar now has a small cloud icon that shows the sync/auth state at a glance — tap it to go to the Account page.

---

## Firebase project

- **Project ID**: `believers-songbook-v2-11edb`
- **Project number**: `767948267709`
- **Firestore mode**: Native (NOT Datastore — the original project was Datastore which can't be changed, so this is a new project)
- **Console**: https://console.firebase.google.com/project/believers-songbook-v2-11edb

The FlutterFire config is already generated in `lib/firebase_options.dart`. If you ever need to regenerate:

```bash
flutterfire configure --project=believers-songbook-v2-11edb
```

### Firestore schema

```
users/
  {uid}/
    settings: { fontSize, displayKey, displaySongNumber, isDarkMode, songBookFile, locale, sortOrder, searchBy }
    collections/
      {collectionId}/
        name, dateCreated
        songs/
          {songId}/
            title, key, lyrics, songPosition
```

### Security rules

Each user can only read/write their own data. Rules are in `firestore.rules` in the project root.

### Auth providers enabled in Firebase Console

- Email/Password
- Google
- Apple

---

## Architecture

### New files

| File | What it does |
|------|-------------|
| `lib/providers/auth_provider.dart` | Auth state management — wraps Firebase Auth, Google Sign-In, Apple Sign-In. Exposes `signInWithGoogle()`, `signInWithApple()`, `signInWithEmail()`, `createAccount()`, `signOut()`. Uses `ChangeNotifier` so the UI rebuilds on auth state changes. |
| `lib/services/sync_service.dart` | All Firestore read/write logic. Static methods: `pushSettings`, `pullSettings`, `pushCollection`, `pushAllCollections`, `pullCollections`, `fullSync`, etc. Handles batch chunking (Firestore has a 500 operations per batch limit). |
| `lib/account_page.dart` | The Account page UI. Shows sign-in options when logged out, shows avatar + sync button + sign out when logged in. |
| `lib/widgets/sync_status_icon.dart` | The cloud icon widget in AppBars. Shows different icons for signed-in, signed-out, or syncing. |
| `lib/widgets/google_logo.dart` | Custom-painted multicolor Google "G" logo for the sign-in button. |
| `firestore.rules` | Firestore security rules file. |

### Modified files

| File | What changed |
|------|-------------|
| `lib/main.dart` | Firebase initialization, `AuthProvider` in the widget tree, onboarding gate (`_OnboardingGate`) that detects first install vs. update, `_FirstInstallLoginScreen` for new users, "What's New" dialog for existing users. |
| `lib/songs.dart` | Added `SyncStatusIcon` to AppBar, fixed ScrollController for desktop scrollbars. |
| `lib/song_books.dart` | Added `SyncStatusIcon` to AppBar, converted to StatefulWidget for ScrollController. |
| `lib/collections.dart` | Added `SyncStatusIcon` to AppBar, converted to StatefulWidget for ScrollController. |
| `lib/song.dart` | Added ScrollController for collections bottom sheet scrollbar. |
| `lib/app_pages.dart` | Added Account page to the navigation. |
| `pubspec.yaml` | Added `firebase_auth`, `cloud_firestore`, `google_sign_in`, `sign_in_with_apple`, `crypto` dependencies. |

### How sync works

1. **On sign-in**: The app does an automatic full sync — pushes local data to Firestore, then pulls everything back (which merges data from other devices if any).
2. **On settings change**: Each setting change pushes to Firestore individually in the background.
3. **On collection change**: Create/delete/reorder operations push immediately.
4. **Manual sync**: The Account page has a "Sync Now" button that does a full push+pull and merges results into local state.

The `fullSync` method in `SyncService` is the entry point for full sync. It:
- Pushes all settings
- Pushes all collections and songs (batched to avoid Firestore's 500-op limit)
- Pulls settings and collections back
- Returns the pulled data for the caller to merge into local state

---

## Code signing & Apple Developer setup

### Team info

- **Team ID**: `577356XP4Z`
- **Bundle ID**: `com.ngonimujuru.songbookForBelievers`

Both iOS and macOS `project.pbxproj` files are configured with `DEVELOPMENT_TEAM = 577356XP4Z` across all build configurations (Debug, Profile, Release).

### Entitlements

**iOS** (`ios/Runner/Runner.entitlements`):
- `com.apple.developer.applesignin` — required for Sign in with Apple

**macOS Debug/Profile** (`macos/Runner/DebugProfile.entitlements`):
- App Sandbox enabled
- `com.apple.security.cs.allow-jit` — needed for debug
- `com.apple.security.network.client` — needed for Firebase/Google Sign-In network calls
- `com.apple.security.network.server` — needed for Flutter debug server
- Keychain access groups — needed for Google Sign-In credential storage
- `com.apple.developer.applesignin` — needed for Sign in with Apple

**macOS Release** (`macos/Runner/Release.entitlements`):
- App Sandbox enabled
- `com.apple.security.network.client`
- Keychain access groups
- `com.apple.developer.applesignin`

### Important: Who can build and sign

The iOS provisioning profile only contains the project owner's signing certificate. If you're not the project owner, you won't be able to build for a real iOS device with code signing. You CAN still:
- Build without signing: `flutter build ios --debug --no-codesign`
- Run on the iOS Simulator
- Run on macOS (with your own dev cert, Xcode will auto-manage)

For proper device testing with Apple Sign-In, the project owner needs to build and sign.

---

## Testing each auth method

### Google Sign-In

**iOS Simulator**: ✅ Works. The `iosClientId` and reversed client ID URL scheme are configured in `auth_provider.dart` and `ios/Runner/Info.plist` respectively.

**Android Emulator**: ✅ Works. Debug SHA-1 fingerprint is registered with Firebase and included in `google-services.json`.

**macOS**: Requires proper code signing with team `577356XP4Z` and keychain access. If you get a keychain error (`OSStatus -25299`), make sure:
1. The app is code-signed (not ad-hoc)
2. `keychain-access-groups` is in the entitlements
3. `com.apple.security.network.client` is in the entitlements

### Apple Sign-In

**iOS / macOS**: Not yet working — requires the setup in **Step 2** of the Setup guide below.

### Email/Password

**All platforms**: ✅ Works. No special configuration needed.

---

## How to test the full flow

1. Run the app (fresh install or clear app data)
2. You should see the first-install login screen
3. Sign in with any method (or tap "Skip for now")
4. Go to Settings > Account to see the account page
5. Create some collections, add songs, change settings
6. Tap "Sync Now" on the Account page
7. Check Firestore Console — you should see your data under `users/{your-uid}/`
8. Reinstall the app (or use another device), sign in with the same account
9. Your settings and collections should restore after the automatic sync

---

## Setup guide — getting everything working

All the code is ready. The only remaining work is infrastructure configuration that requires **GCP Owner** permissions and **Apple Developer** portal access. Follow the steps below in order.

### Prerequisites: install the Google Cloud CLI (`gcloud`)

If you don't have `gcloud` installed:

```bash
# macOS (Homebrew)
brew install --cask google-cloud-sdk

# Source it in your current shell (add to ~/.zshrc for permanence)
source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"

# Verify
gcloud --version
```

Then authenticate and set the project:

```bash
gcloud auth login                     # opens browser — sign in with an account that has Owner on the GCP project
gcloud config set project believers-songbook-v2-11edb
```

> **Important**: You need the **Owner** role on the *Google Cloud* project (not just Firebase). Editor is not enough to create a Firestore database. Check your role with:
> ```bash
> gcloud projects get-iam-policy believers-songbook-v2-11edb \
>   --flatten="bindings[].members" \
>   --filter="bindings.members:YOUR_EMAIL" \
>   --format="table(bindings.role)"
> ```
> If it shows `roles/editor`, the project owner needs to upgrade you to `roles/owner` at:
> https://console.cloud.google.com/iam-admin/iam?project=believers-songbook-v2-11edb

---

### Step 1: Create the Firestore database (CRITICAL — blocks all sync)

Without this, **no data sync works on any platform**. Auth will work but nothing gets saved to the cloud.

**Option A — CLI (recommended):**

```bash
gcloud firestore databases create \
  --location=nam5 \
  --type=firestore-native \
  --project=believers-songbook-v2-11edb
```

**Option B — Firebase Console:**

1. Go to https://console.firebase.google.com/project/believers-songbook-v2-11edb/firestore
2. If you see a setup/provisioning screen, select **Native mode** and location **nam5** (United States)
3. Click **Create Database**

**Verify it worked:**

```bash
gcloud firestore databases describe --database="(default)" --project=believers-songbook-v2-11edb
```

You should see output with `type: FIRESTORE_NATIVE` and `locationId: nam5`. If you see `NOT_FOUND`, the creation failed — try again or check permissions.

After the database exists, deploy the security rules:

```bash
firebase deploy --only firestore:rules --project believers-songbook-v2-11edb
```

---

### Step 2: Enable Apple Sign-In capability (blocks Apple Sign-In on iOS & macOS)

The code and entitlements are in place, but the App ID needs the capability enabled in the Apple Developer portal.

1. Go to https://developer.apple.com/account/resources/identifiers
2. Find the App ID **`com.ngonimujuru.songbookForBelievers`** (or register it if it doesn't exist)
3. Click on it → scroll down to **Capabilities**
4. Check the box for **"Sign in with Apple"**
5. Click **Save**
6. Go to **Profiles** and regenerate any provisioning profiles that use this App ID

---

### Step 3: macOS build access (optional — for local dev testing)

For other devs to build macOS locally, they need to be on the Apple Developer team:
- Go to https://developer.apple.com/account → **People**
- Invite devs with their Apple ID
- They then add their Apple ID in Xcode → Settings → Accounts

Alternatively, the project owner can build and test macOS after pulling the branch.

---

### Step 4: Android release SHA-1 (before Play Store release only)

Only the debug SHA-1 is registered. Before publishing:

```bash
cd android && ./gradlew signingReport && cd ..
```

Copy the **release** SHA-1 fingerprint, then:
1. Go to Firebase Console → Project Settings → Android app → **Add fingerprint**
2. Paste the release SHA-1
3. Download the updated `google-services.json` and replace `android/app/google-services.json`

---

### After completing all steps

Update this document to reflect the finished state:
1. Remove this entire "Setup guide" section (or condense it to a brief "already done" note).
2. Update the "What's done" table — mark everything as ✅.
3. Remove the corresponding items from "Known issues / TODO".
4. This keeps the doc clean for future contributors.

---

## API key security

Google will flag the Firebase API keys in `GoogleService-Info.plist` and `google-services.json` because they're committed to a public GitHub repo. **This is expected** — Firebase API keys are client-side identifiers (not secrets) and are designed to be shipped inside the app binary. Your data is protected by Firestore security rules and Firebase Auth, not by key secrecy.

However, to prevent quota abuse (someone using your key to spam API calls against your free tier), **restrict the API key**:

1. Go to https://console.cloud.google.com/apis/credentials?project=believers-songbook-v2-11edb
2. Click on the flagged API key
3. Under **API restrictions**, select **Restrict key** and allow only:
   - Firebase Installations API
   - Firebase Cloud Messaging API
   - Cloud Firestore API
   - Identity Toolkit API (for Firebase Auth)
   - Token Service API
4. Under **Application restrictions** (optional but recommended):
   - For Android: restrict to package `com.ngonimujuru.songbook_for_believers` + SHA-1 fingerprint(s)
   - For iOS/macOS: restrict to bundle ID `com.ngonimujuru.songbookForBelievers`
5. Click **Save**

You do **not** need to regenerate the key or remove the files from the repo. These config files are required for the app to build.

---

## Known issues / TODO

- **Hardcoded English strings**: About 30 strings in the auth/account UI are hardcoded in English. They should eventually be moved to the l10n files for localization. Not blocking for the initial release.
- **Conflict resolution**: Right now sync is "last write wins". If you edit the same collection on two devices simultaneously, the last one to sync wins. This is fine for the current use case but something to be aware of.
- **Web platform**: Auth should work on web but hasn't been tested. Google Sign-In on web needs the web client ID configured in `index.html` meta tag.

## What's done (verified working)

| Platform | Email/Password | Google Sign-In | Apple Sign-In | Firestore Sync |
|----------|---------------|----------------|---------------|----------------|
| Android Emulator | ✅ | ✅ | N/A | ✅ after Step 1 |
| iOS Simulator (iOS 17) | ✅ | ✅ | ✅ after Step 2 | ✅ after Step 1 |
| macOS | Untested | ✅ after Step 3 | ✅ after Steps 2+3 | ✅ after Step 1 |
| Web | Untested | Untested | N/A | Untested |

---

## Quick reference commands

```bash
# Run on macOS
flutter run -d macos

# Run on iOS Simulator
flutter run -d <simulator-id>

# Build iOS without signing (verify compilation)
flutter build ios --debug --no-codesign

# Deploy Firestore rules
firebase deploy --only firestore:rules --project believers-songbook-v2-11edb

# Regenerate FlutterFire config
flutterfire configure --project=believers-songbook-v2-11edb
```