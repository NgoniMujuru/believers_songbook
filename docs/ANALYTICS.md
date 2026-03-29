# Firebase Analytics

The app uses Firebase Analytics to track feature engagement via custom events and user properties. All analytics logic lives in `lib/services/analytics_service.dart` — a singleton wrapper around `FirebaseAnalytics`.

## Local testing with DebugView

Firebase batches events and sends them roughly every hour in production. To see events in real time during development, enable **DebugView** mode.

### Start debug mode

#### Android (emulator or device)

```bash
# If adb is not on your PATH, use the full path:
# $HOME/Library/Android/sdk/platform-tools/adb

adb shell setprop debug.firebase.analytics.app com.ngonimujuru.songbook_for_believers
```

#### iOS (simulator or device)

Add the `-FIRDebugEnabled` launch argument in Xcode:
1. Product → Scheme → Edit Scheme → Run → Arguments
2. Add `-FIRDebugEnabled`

Or pass it via the command line:
```bash
flutter run --dart-define=FIRDebugEnabled=true
```

### View events

1. Open [Firebase Console](https://console.firebase.google.com) → project **believers-songbook-v2**
2. Left sidebar → **Analytics** (click the `>` arrow to expand)
3. Click **DebugView**
4. Your device should appear within a few seconds of running the app

### Stop debug mode

When you're done testing, disable DebugView so events batch normally again:

#### Android
```bash
adb shell setprop debug.firebase.analytics.app .none.
```

#### iOS
Remove the `-FIRDebugEnabled` argument from the scheme, or add `-FIRDebugDisabled` instead.

---

## Tracked events

### Authentication

| Event | When | Parameters |
|-------|------|------------|
| `login` | User signs in successfully | `method`: `google`, `apple`, or `email` |
| `sign_up` | User creates email account | `method`: `email` |
| `sign_out` | User taps Sign out | — |
| `password_reset_requested` | Password reset email sent | — |
| `sign_in_skipped` | User taps "Skip for now" on onboarding | — |
| `manual_sync` | User taps "Sync now" | — |

> `login` and `sign_up` are [Firebase recommended events](https://support.google.com/analytics/answer/9267735) — they automatically populate conversion funnels.

### Core engagement

| Event | When | Parameters |
|-------|------|------------|
| `song_opened` | User taps a song to view it | `song_title`, `source`: `songs_list` or `collection` |
| `search` | User types a search query (after debounce) | `search_term` |
| `sort_order_changed` | User changes sort order | `sort_order`: `numerical`, `alphabetic`, or `key` |
| `search_by_changed` | User changes search filter | `search_by`: `title`, `lyrics`, `key`, or `titleAndLyrics` |
| `tab_changed` | User switches bottom nav tab | `tab_name`: `songs`, `songbooks`, `collections`, or `about` |

> `search` is a [Firebase recommended event](https://support.google.com/analytics/answer/9267735).

### Collections

| Event | When | Parameters |
|-------|------|------------|
| `collection_created` | User creates a new collection | — |
| `collection_opened` | User taps a collection to view songs | `collection_name` |
| `collection_deleted` | User deletes a collection | — |
| `song_added_to_collection` | User adds a song to a collection | `song_title` |
| `song_removed_from_collection` | User removes a song from a collection | `song_title` |

### Songbooks

| Event | When | Parameters |
|-------|------|------------|
| `songbook_changed` | User switches active songbook | `songbook_name` |

### Settings

| Event | When | Parameters |
|-------|------|------------|
| `settings_changed` | User changes theme or language | `setting_type`: `theme` or `language`, `value` |

### Sharing

| Event | When | Parameters |
|-------|------|------------|
| `share_song` | User copies or shares song lyrics | `song_title`, `channel`: `copy` or `share` |
| `app_shared` | User taps "Share App" button | — |

### Onboarding

| Event | When | Parameters |
|-------|------|------------|
| `tour_completed` | User finishes all tour steps | — |
| `tour_skipped` | User dismisses the tour early | `at_step` |
| `sync_explainer_shown` | "What's new" sync dialog appears | — |
| `sync_explainer_sign_in_clicked` | User taps "Sign in now" from sync dialog | — |

### About page

| Event | When | Parameters |
|-------|------|------------|
| `rate_app_clicked` | User taps "Rate App" | — |
| `contact_us_clicked` | User taps "Contact Us" | — |
| `privacy_policy_clicked` | User taps privacy policy link | — |

---

## User properties

| Property | Set when | Values |
|----------|----------|--------|
| `theme` | User changes theme | `light`, `dark` |
| `preferred_language` | User changes language | `en`, `sw`, `fr` |

These are set alongside their `settings_changed` events and enable audience segmentation in the Firebase Analytics dashboard.

---

## Adding a new event

1. Add a method to `AnalyticsService` in `lib/services/analytics_service.dart`
2. Call it at the appropriate location (fire-and-forget — no `await` needed)
3. Update this doc
4. Test with DebugView before merging
