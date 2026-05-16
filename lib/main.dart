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
import 'package:believers_songbook/tour/app_tour_controller.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (context) => SongSettings()),
    ChangeNotifierProvider(create: (context) => MainPageSettings()),
    ChangeNotifierProvider(create: (context) => ThemeSettings()),
    ChangeNotifierProvider(create: (context) => CollectionsData()),
    ListenableProvider(create: (context) => SongBookSettings()),
    ChangeNotifierProvider(create: (context) => AuthProvider()),
    ChangeNotifierProvider(create: (context) => AppTourController()),
  ], child: ScreenSizeProvider(child: MyApp())));
}

class ScreenSizeProvider extends StatefulWidget {
  final Widget child;

  const ScreenSizeProvider({super.key, required this.child});

  @override
  State<ScreenSizeProvider> createState() => _ScreenSizeProviderState();
}

class _ScreenSizeProviderState extends State<ScreenSizeProvider> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Provider<ScreenSize>(
      create: (_) => ScreenSize(screenWidth, screenHeight),
      child: widget.child,
    );
  }
}

class MyApp extends StatefulWidget {
  MyApp({super.key});

  static const String _title = 'Songbook for Believers';

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    debugPrint('[PREFS] _loadPrefs START');
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final songSettings = context.read<SongSettings>();
    songSettings.setFontSize(prefs.getDouble('fontSize') ?? 30);
    songSettings.setDisplayKey(prefs.getBool('displayKey') ?? true);
    songSettings
        .setDisplaySongNumber(prefs.getBool('displaySongNumber') ?? false);
    final themeSettings = context.read<ThemeSettings>();
    final darkMode = prefs.getBool('isDarkMode') ?? false;
    debugPrint('[PREFS] Read isDarkMode=$darkMode from SharedPreferences');
    themeSettings.setIsDarkMode(darkMode);
    final mainPageSettings = context.read<MainPageSettings>();
    final locale = prefs.getString('locale') ?? 'en';
    debugPrint('[PREFS] Read locale=$locale from SharedPreferences');
    mainPageSettings.setLocale(locale);
    debugPrint('[PREFS] _loadPrefs DONE');
    if (mounted) setState(() => _prefsLoaded = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_prefsLoaded) {
      initCollections(context);
      WakelockPlus.enable();
    }
    return Consumer<ThemeSettings>(
      builder: (context, themeSettings, child) => MaterialApp(
        navigatorObservers: [
          FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
        ],
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
        title: MyApp._title,
        home: const _OnboardingGate(),
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
  bool _isLoading = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final auth = context.read<AuthProvider>();
    if (auth.isSignedIn) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    // If the user has completed onboarding before, skip
    if (prefs.getBool('hasCompletedOnboarding') == true) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    // Detect existing user: if they already have stored preferences
    // that are only set after the app has fully loaded (past onboarding),
    // they are an update, not a fresh install. We check songBookFile
    // because it's set by Songs.initState (after AppPages loads) and NOT
    // by _loadPrefs (which writes defaults for isDarkMode/fontSize/etc.
    // on every launch, creating false positives).
    final hasExistingData = prefs.containsKey('songBookFile') ||
        prefs.containsKey('hasSeenSyncExplainer');
    if (hasExistingData) {
      // Existing user updating — mark onboarding done, let What's New fire.
      await prefs.setBool('hasCompletedOnboarding', true);
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    // Truly fresh install — show onboarding login
    if (mounted) {
      setState(() {
        _isLoading = false;
        _showOnboarding = true;
      });
    }
  }

  void _finishOnboarding() {
    debugPrint('[ONBOARD] _finishOnboarding called — transitioning to AppPages');
    // Update UI immediately — no await before setState
    setState(() => _showOnboarding = false);
    // Persist in background
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('hasCompletedOnboarding', true);
      prefs.setBool('hasSeenSyncExplainer', true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_showOnboarding) {
      return _FirstInstallLoginScreen(onComplete: _finishOnboarding);
    }
    return const AppPages();
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
        // While the sign-in handler is finishing sync in the background,
        // show a loading spinner. Do NOT call onComplete here —
        // it fires before sync finishes, causing a race condition.
        if (auth.isSignedIn) {
          debugPrint('[FIRSTINSTALL] Consumer detected auth.isSignedIn — showing spinner');
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
                      MyApp._title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.onboardingDescription,
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
                          debugPrint('[FIRSTINSTALL] Sign-in button pressed, pushing AccountPage');
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AccountPage(),
                            ),
                          );
                          debugPrint('[FIRSTINSTALL] AccountPage popped, checking auth...');
                          // AccountPage popped — sync already finished
                          // (handler awaits sync before popping).
                          // If user signed in, transition to home.
                          if (context.read<AuthProvider>().isSignedIn) {
                            debugPrint('[FIRSTINSTALL] Auth is signed in, calling onComplete');
                            final themeSettings = context.read<ThemeSettings>();
                            debugPrint('[FIRSTINSTALL] isDarkMode=${themeSettings.isDarkMode} before onComplete');
                            onComplete();
                          } else {
                            debugPrint('[FIRSTINSTALL] Auth NOT signed in after AccountPage pop');
                          }
                        },
                        icon: const Icon(Icons.cloud_sync),
                        label: Text(AppLocalizations.of(context)!.onboardingSignInButton),
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
                      child: Text(AppLocalizations.of(context)!.accountSkipForNow),
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
