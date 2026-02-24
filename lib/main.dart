import 'package:believers_songbook/models/local_database.dart';
import 'package:believers_songbook/providers/auth_provider.dart';
import 'package:believers_songbook/providers/collections_data.dart';
import 'package:believers_songbook/providers/main_page_settings.dart';
import 'package:believers_songbook/providers/theme_settings.dart';
import 'package:believers_songbook/account_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'app_pages.dart';
import 'styles.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/song_settings.dart';
import 'providers/song_book_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:believers_songbook/l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (context) => SongSettings()),
    ChangeNotifierProvider(create: (context) => MainPageSettings()),
    ChangeNotifierProvider(create: (context) => ThemeSettings()),
    ChangeNotifierProvider(create: (context) => CollectionsData()),
    ListenableProvider(create: (context) => SongBookSettings()),
    ChangeNotifierProvider(create: (context) => AuthProvider()),
  ], child: ScreenSizeProvider(child: MyApp())));
}

class ScreenSizeProvider extends StatelessWidget {
  final Widget child;

  const ScreenSizeProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Provider<ScreenSize>(
      create: (_) => ScreenSize(screenWidth, screenHeight),
      child: child,
    );
  }
}
class MyApp extends StatelessWidget {
  MyApp({super.key});

  static const String _title = 'Believers Songbook';
  final Future<FirebaseApp> _fbApp = Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  @override
  Widget build(BuildContext context) {
    SharedPreferences.getInstance().then((prefs) {
      final songSettings = context.read<SongSettings>();
      songSettings.setFontSize(prefs.getDouble('fontSize') ?? 30);
      songSettings.setDisplayKey(prefs.getBool('displayKey') ?? true);
      songSettings.setDisplaySongNumber(prefs.getBool('displaySongNumber') ?? false);
      final themeSettings = context.read<ThemeSettings>();
      themeSettings.setIsDarkMode(prefs.getBool('isDarkMode') ?? false);
      final mainPageSettings = context.read<MainPageSettings>();
      mainPageSettings.setLocale(prefs.getString('locale') ?? 'en');
    });
    initCollections(context);
    WakelockPlus.enable();
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

            double screenWidth = MediaQuery.of(context).size.width;
            double screenHeight = MediaQuery.of(context).size.height;

            if (snapshot.hasError) {
              return const Scaffold(
                body: Center(
                  child: Text(
                      'Loading songbooks failed, please try again later'),
                ),
              );
            } else if (snapshot.hasData) {
              return Provider<ScreenSize>(
                create: (_) => ScreenSize(screenWidth, screenHeight),
                child: const _OnboardingGate(),
              );
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

/// Decides whether to show the first-install login screen or go straight
/// to the main app.
///
/// - Fresh install (no prior SharedPreferences data) AND not signed in
///   → show full-screen login/onboarding.
/// - Existing user who updated (has prefs data) → AppPages (which shows
///   the "What's New" dialog via hasSeenSyncExplainer).
/// - Already signed in → AppPages.
class _OnboardingGate extends StatefulWidget {
  const _OnboardingGate();
  @override
  State<_OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<_OnboardingGate> {
  late Future<bool> _shouldOnboard;

  @override
  void initState() {
    super.initState();
    _shouldOnboard = _checkOnboarding();
  }

  Future<bool> _checkOnboarding() async {
    final auth = context.read<AuthProvider>();
    if (auth.isSignedIn) return false; // already signed in

    final prefs = await SharedPreferences.getInstance();
    // If the user has completed onboarding before, skip
    if (prefs.getBool('hasCompletedOnboarding') == true) return false;
    // Detect existing user: if they already have stored preferences
    // (like fontSize, isDarkMode, locale) they are an update, not fresh.
    final hasExistingData = prefs.containsKey('fontSize') ||
        prefs.containsKey('isDarkMode') ||
        prefs.containsKey('songBookFile');
    if (hasExistingData) {
      // Existing user updating — mark onboarding done, let What's New fire.
      await prefs.setBool('hasCompletedOnboarding', true);
      return false;
    }
    // Truly fresh install — show onboarding login
    return true;
  }

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedOnboarding', true);
    await prefs.setBool('hasSeenSyncExplainer', true);
    if (mounted) setState(() => _shouldOnboard = Future.value(false));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _shouldOnboard,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == true) {
          return _FirstInstallLoginScreen(onComplete: _finishOnboarding);
        }
        return const AppPages();
      },
    );
  }
}

/// Full-screen login prompt shown only on truly fresh installs.
class _FirstInstallLoginScreen extends StatelessWidget {
  final VoidCallback onComplete;
  const _FirstInstallLoginScreen({required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // If the user just signed in, finish onboarding automatically
        if (auth.isSignedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onComplete());
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: MediaQuery.of(context).size.width > 600
                    ? const EdgeInsets.fromLTRB(80, 40, 80, 40)
                    : const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.music_note_rounded,
                      size: 72,
                      color: Styles.themeColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Believers Songbook',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sign in to back up your collections and settings '
                      'to the cloud so they stay with you across devices.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),
                    // Sign in button → navigates to full AccountPage
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AccountPage(),
                            ),
                          );
                          // If they signed in on that page, auth state changed
                          // and the Consumer above will call onComplete.
                        },
                        icon: const Icon(Icons.cloud_sync),
                        label: const Text('Sign in or create account'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Styles.themeColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: onComplete,
                      child: const Text('Skip for now'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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

class ScreenSize {
  final double screenWidth;
  final double screenHeight;

  ScreenSize(this.screenWidth, this.screenHeight);
}
