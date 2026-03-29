import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._(this._analytics);

  static final AnalyticsService instance =
      AnalyticsService._(FirebaseAnalytics.instance);

  final FirebaseAnalytics _analytics;

  Future<void> setTheme(String theme) {
    return _analytics.setUserProperty(name: 'theme', value: theme);
  }

  Future<void> setPreferredLanguage(String languageCode) {
    return _analytics.setUserProperty(
      name: 'preferred_language',
      value: languageCode,
    );
  }

  Future<void> trackSongShared({
    required String songTitle,
    required String channel,
  }) {
    return _analytics.logEvent(
      name: 'share_song',
      parameters: {
        'song_title': songTitle,
        'channel': channel,
      },
    );
  }

  Future<void> trackTabChanged({required String tabName}) {
    return _analytics.logEvent(
      name: 'tab_changed',
      parameters: {
        'tab_name': tabName,
      },
    );
  }

  Future<void> trackSettingsChanged({
    required String settingType,
    required String value,
  }) {
    return _analytics.logEvent(
      name: 'settings_changed',
      parameters: {
        'setting_type': settingType,
        'value': value,
      },
    );
  }

  Future<void> trackCollectionCreated() {
    return _analytics.logEvent(name: 'collection_created');
  }

  Future<void> trackSongAddedToCollection({required String songTitle}) {
    return _analytics.logEvent(
      name: 'song_added_to_collection',
      parameters: {
        'song_title': songTitle,
      },
    );
  }

  Future<void> trackSongbookChanged({required String songbookName}) {
    return _analytics.logEvent(
      name: 'songbook_changed',
      parameters: {
        'songbook_name': songbookName,
      },
    );
  }

  Future<void> trackAppShared() {
    return _analytics.logEvent(name: 'app_shared');
  }

  // --- Authentication ---

  Future<void> trackLogin({required String method}) {
    return _analytics.logEvent(
      name: 'login',
      parameters: {'method': method},
    );
  }

  Future<void> trackSignUp({required String method}) {
    return _analytics.logEvent(
      name: 'sign_up',
      parameters: {'method': method},
    );
  }

  Future<void> trackSignOut() {
    return _analytics.logEvent(name: 'sign_out');
  }

  Future<void> trackPasswordResetRequested() {
    return _analytics.logEvent(name: 'password_reset_requested');
  }

  Future<void> trackSignInSkipped() {
    return _analytics.logEvent(name: 'sign_in_skipped');
  }

  Future<void> trackManualSync() {
    return _analytics.logEvent(name: 'manual_sync');
  }

  // --- Core Engagement ---

  Future<void> trackSongOpened({
    required String songTitle,
    required String source,
  }) {
    return _analytics.logEvent(
      name: 'song_opened',
      parameters: {
        'song_title': songTitle,
        'source': source,
      },
    );
  }

  Future<void> trackSearch({required String searchTerm}) {
    return _analytics.logEvent(
      name: 'search',
      parameters: {'search_term': searchTerm},
    );
  }

  Future<void> trackSortOrderChanged({required String sortOrder}) {
    return _analytics.logEvent(
      name: 'sort_order_changed',
      parameters: {'sort_order': sortOrder},
    );
  }

  Future<void> trackSearchByChanged({required String searchBy}) {
    return _analytics.logEvent(
      name: 'search_by_changed',
      parameters: {'search_by': searchBy},
    );
  }

  // --- Collection Management ---

  Future<void> trackCollectionOpened({required String collectionName}) {
    return _analytics.logEvent(
      name: 'collection_opened',
      parameters: {'collection_name': collectionName},
    );
  }

  Future<void> trackCollectionDeleted() {
    return _analytics.logEvent(name: 'collection_deleted');
  }

  Future<void> trackSongRemovedFromCollection({required String songTitle}) {
    return _analytics.logEvent(
      name: 'song_removed_from_collection',
      parameters: {'song_title': songTitle},
    );
  }

  // --- Onboarding ---

  Future<void> trackTourCompleted() {
    return _analytics.logEvent(name: 'tour_completed');
  }

  Future<void> trackTourSkipped({required int atStep}) {
    return _analytics.logEvent(
      name: 'tour_skipped',
      parameters: {'at_step': atStep},
    );
  }

  Future<void> trackSyncExplainerShown() {
    return _analytics.logEvent(name: 'sync_explainer_shown');
  }

  Future<void> trackSyncExplainerSignInClicked() {
    return _analytics.logEvent(name: 'sync_explainer_sign_in_clicked');
  }

  // --- About Page ---

  Future<void> trackRateAppClicked() {
    return _analytics.logEvent(name: 'rate_app_clicked');
  }

  Future<void> trackContactUsClicked() {
    return _analytics.logEvent(name: 'contact_us_clicked');
  }

  Future<void> trackPrivacyPolicyClicked() {
    return _analytics.logEvent(name: 'privacy_policy_clicked');
  }
}

