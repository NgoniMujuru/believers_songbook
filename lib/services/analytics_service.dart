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

  Future<void> trackSongOpened({
    required String songId,
    required String songTitle,
    required String source,
  }) {
    return _analytics.logEvent(
      name: 'song_opened',
      parameters: {
        'song_id': songId,
        'song_title': songTitle,
        'source': source,
      },
    );
  }

  Future<void> trackSearchPerformed({
    required String query,
    required int resultsCount,
    String? filter,
  }) {
    return _analytics.logEvent(
      name: 'search_performed',
      parameters: {
        'query_length': query.length,
        'results_count': resultsCount,
        if (filter != null) 'filter': filter,
      },
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
}

