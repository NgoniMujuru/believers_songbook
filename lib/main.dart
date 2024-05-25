import 'package:believers_songbook/models/local_database.dart';
import 'package:believers_songbook/providers/collections_data.dart';
import 'package:believers_songbook/providers/main_page_settings.dart';
import 'package:believers_songbook/providers/theme_settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_pages.dart';
import 'styles.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/song_settings.dart';
import 'providers/song_book_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock/wakelock.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (context) => SongSettings()),
    ChangeNotifierProvider(create: (context) => MainPageSettings()),
    ChangeNotifierProvider(create: (context) => ThemeSettings()),
    ChangeNotifierProvider(create: (context) => CollectionsData()),
    ListenableProvider(create: (context) => SongBookSettings())
  ], child: MyApp()));
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  static const String _title = 'Believers Songbook';
  final Future<FirebaseApp> _fbApp = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    SharedPreferences.getInstance().then((prefs) {
      final songSettings = context.read<SongSettings>();
      songSettings.setFontSize(prefs.getDouble('fontSize') ?? 30);
      final themeSettings = context.read<ThemeSettings>();
      themeSettings.setIsDarkMode(prefs.getBool('isDarkMode') ?? false);
    });
    initCollections(context);
    Wakelock.enable();
    return Consumer<ThemeSettings>(
      builder: (context, themeSettings, child) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          // Locale('af'), // Afrikaans
          Locale('en'), // English
          Locale('fr'), // French
          // Locale('de'), // German
          // Locale('es'), // Spanish
          Locale('sw'), // Swahili
          // Locale('zu'), // Zulu
        ],
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Styles.themeColor,
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Styles.themeColor,
          brightness: Brightness.dark,
        ),
        themeMode: themeSettings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        debugShowCheckedModeBanner: false,
        title: _title,
        home: FutureBuilder(
          future: _fbApp,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text(
                  'Loading songbooks failed, please try again later');
            } else if (snapshot.hasData) {
              return AppPages();
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      ),
    );
  }
}

void initCollections(BuildContext context) async {
  final collectionsData = context.read<CollectionsData>();
  await LocalDatabase.initDatabase();
  final collections = await LocalDatabase.getCollections();
  collectionsData.setCollections(collections);
  final collectionSongs = await LocalDatabase.getCollectionSongs();
  collectionsData.setCollectionSongs(collectionSongs);
}
