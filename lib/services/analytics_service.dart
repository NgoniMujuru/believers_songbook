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
}

