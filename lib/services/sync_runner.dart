import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:believers_songbook/providers/auth_provider.dart';
import 'package:believers_songbook/providers/collections_data.dart';
import 'package:believers_songbook/providers/main_page_settings.dart';
import 'package:believers_songbook/providers/song_settings.dart';
import 'package:believers_songbook/providers/theme_settings.dart';
import 'package:believers_songbook/services/analytics_service.dart';
import 'package:believers_songbook/services/sync_service.dart';

class SyncRunner {
  static Future<bool> run(BuildContext context) async {
    final songSettings = context.read<SongSettings>();
    final themeSettings = context.read<ThemeSettings>();
    final mainPageSettings = context.read<MainPageSettings>();
    final collectionsData = context.read<CollectionsData>();
    final auth = context.read<AuthProvider>();
    if (!auth.isSignedIn) return false;

    final prefs = await SharedPreferences.getInstance();
    final songBookFile = prefs.getString('songBookFile') ??
        'CityTabernacleBulawayo_Bulawayo_Zimbabwe';

    AnalyticsService.instance.trackManualSync();
    final result = await SyncService.fullSync(
      fontSize: songSettings.fontSize,
      displayKey: songSettings.displayKey,
      displaySongNumber: songSettings.displaySongNumber,
      isDarkMode: themeSettings.isDarkMode,
      songBookFile: songBookFile,
      locale: mainPageSettings.getLocale,
      sortOrder: prefs.getString('sortOrder'),
      searchBy: prefs.getString('searchBy'),
      collections: collectionsData.collections,
      collectionSongs: collectionsData.collectionSongs,
    );
    if (result == null) return false;

    final settings = result['settings'] as Map<String, dynamic>?;
    if (settings != null) {
      if (settings['fontSize'] != null) {
        songSettings.setFontSize((settings['fontSize'] as num).toDouble());
      }
      if (settings['displayKey'] != null) {
        songSettings.setDisplayKey(settings['displayKey'] as bool);
      }
      if (settings['displaySongNumber'] != null) {
        songSettings.setDisplaySongNumber(settings['displaySongNumber'] as bool);
      }
      if (settings['isDarkMode'] != null) {
        themeSettings.setIsDarkMode(settings['isDarkMode'] as bool);
      }
      if (settings['locale'] != null) {
        mainPageSettings.setLocale(settings['locale'] as String);
      }
      if (settings['songBookFile'] != null) {
        prefs.setString('songBookFile', settings['songBookFile'] as String);
      }
    }

    final pulledCollections = result['collections'];
    final pulledSongs = result['collectionSongs'];
    if (pulledCollections != null) {
      for (var collection in pulledCollections) {
        if (!collectionsData.collections.any((c) => c.id == collection.id)) {
          await collectionsData.addCollection(collection);
        }
      }
    }
    if (pulledSongs != null) {
      for (var song in pulledSongs) {
        if (!collectionsData.collectionSongs.any((s) => s.id == song.id)) {
          await collectionsData.addCollectionSong(song);
        }
      }
    }

    await auth.markSynced();
    return true;
  }
}
