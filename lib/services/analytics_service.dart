import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

// firebase_analytics has no Windows implementation, so calls are routed
// through _log/_setUserProperty, which no-op there instead of throwing.
class AnalyticsService {
  AnalyticsService._(this._analytics);

  static final AnalyticsService instance =
      AnalyticsService._(FirebaseAnalytics.instance);

  static bool get _supported =>
      kIsWeb || defaultTargetPlatform != TargetPlatform.windows;

  final FirebaseAnalytics _analytics;

  Future<void> _log(String name, [Map<String, Object>? parameters]) {
    if (!_supported) return Future.value();
    return _analytics.logEvent(name: name, parameters: parameters);
  }

  Future<void> _setUserProperty({required String name, String? value}) {
    if (!_supported) return Future.value();
    return _analytics.setUserProperty(name: name, value: value);
  }

  Future<void> setTheme(String theme) {
    return _setUserProperty(name: 'theme', value: theme);
  }

  Future<void> setPreferredLanguage(String languageCode) {
    return _setUserProperty(
      name: 'preferred_language',
      value: languageCode,
    );
  }

  Future<void> trackSongShared({
    required String songTitle,
    required String channel,
  }) {
    return _log('share_song', {
      'song_title': songTitle,
      'channel': channel,
    });
  }

  Future<void> trackTabChanged({required String tabName}) {
    return _log('tab_changed', {
      'tab_name': tabName,
    });
  }

  Future<void> trackSettingsChanged({
    required String settingType,
    required String value,
  }) {
    return _log('settings_changed', {
      'setting_type': settingType,
      'value': value,
    });
  }

  Future<void> trackCollectionCreated() {
    return _log('collection_created');
  }

  Future<void> trackSongAddedToCollection({required String songTitle}) {
    return _log('song_added_to_collection', {
      'song_title': songTitle,
    });
  }

  Future<void> trackSongbookChanged({required String songbookName}) {
    return _log('songbook_changed', {
      'songbook_name': songbookName,
    });
  }

  Future<void> trackAppShared() {
    return _log('app_shared');
  }

  // --- Authentication ---

  Future<void> trackLogin({required String method}) {
    return _log('login', {'method': method});
  }

  Future<void> trackSignUp({required String method}) {
    return _log('sign_up', {'method': method});
  }

  Future<void> trackSignOut() {
    return _log('sign_out');
  }

  Future<void> trackPasswordResetRequested() {
    return _log('password_reset_requested');
  }

  Future<void> trackSignInSkipped() {
    return _log('sign_in_skipped');
  }

  Future<void> trackManualSync() {
    return _log('manual_sync');
  }

  // --- Core Engagement ---

  Future<void> trackSongOpened({
    required String songTitle,
    required String source,
  }) {
    return _log('song_opened', {
      'song_title': songTitle,
      'source': source,
    });
  }

  Future<void> trackSearch({required String searchTerm}) {
    return _log('search', {'search_term': searchTerm});
  }

  Future<void> trackSortOrderChanged({required String sortOrder}) {
    return _log('sort_order_changed', {'sort_order': sortOrder});
  }

  Future<void> trackSearchByChanged({required String searchBy}) {
    return _log('search_by_changed', {'search_by': searchBy});
  }

  // --- Collection Management ---

  Future<void> trackCollectionOpened({required String collectionName}) {
    return _log('collection_opened', {'collection_name': collectionName});
  }

  Future<void> trackCollectionDeleted() {
    return _log('collection_deleted');
  }

  Future<void> trackSongRemovedFromCollection({required String songTitle}) {
    return _log('song_removed_from_collection', {'song_title': songTitle});
  }

  // --- Onboarding ---

  Future<void> trackTourCompleted() {
    return _log('tour_completed');
  }

  Future<void> trackTourSkipped({required int atStep}) {
    return _log('tour_skipped', {'at_step': atStep});
  }

  Future<void> trackSyncExplainerShown() {
    return _log('sync_explainer_shown');
  }

  Future<void> trackSyncExplainerSignInClicked() {
    return _log('sync_explainer_sign_in_clicked');
  }

  // --- About Page ---

  Future<void> trackRateAppClicked() {
    return _log('rate_app_clicked');
  }

  Future<void> trackContactUsClicked() {
    return _log('contact_us_clicked');
  }

  Future<void> trackPrivacyPolicyClicked() {
    return _log('privacy_policy_clicked');
  }
}

