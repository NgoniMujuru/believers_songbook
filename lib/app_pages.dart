import 'package:believers_songbook/account_page.dart';
import 'package:believers_songbook/collections.dart';
import 'package:believers_songbook/providers/auth_provider.dart';
import 'package:believers_songbook/providers/main_page_settings.dart';
import 'package:believers_songbook/songs.dart';
import 'package:believers_songbook/styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'about.dart';
import 'song_books.dart';

class AppPages extends StatefulWidget {
  const AppPages({super.key});

  @override
  State<AppPages> createState() => _AppPagesState();
}

class _AppPagesState extends State<AppPages> {
  static final List<Widget> _widgetOptions = <Widget>[
    const Songs(),
    const SongBooks(),
    const Collections(),
    const AboutPage(),
  ];

// manual language translations as flutter_localizations was not working for nav elements
  final Map<String, Map<String, String>> titleMap = {
    'en': {
      'aboutPageTitle': 'About',
      'collectionPageTitle': 'Collections',
      'songBooksPageTitle': 'Songbooks',
      'songsPageTitle': 'Songs',
    },
    'fr': {
      'aboutPageTitle': 'À propos',
      'collectionPageTitle': 'Collections',
      'songBooksPageTitle': 'Congrégations',
      'songsPageTitle': 'Chansons',
    },
    'sw': {
      'aboutPageTitle': 'Kuhusu',
      'collectionPageTitle': 'Makusanyo',
      'songBooksPageTitle': 'Makutano',
      'songsPageTitle': 'Nyimbo',
    },
  };

  @override
  void initState() {
    super.initState();
    _showSyncExplainerIfNeeded();
  }

  Future<void> _showSyncExplainerIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenExplainer = prefs.getBool('hasSeenSyncExplainer') ?? false;
    if (hasSeenExplainer) return;
    await prefs.setBool('hasSeenSyncExplainer', true);

    if (!mounted) return;
    // Delay slightly so the page is fully built first
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    if (auth.isSignedIn) return; // Already signed in, no need for explainer

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.cloud_sync, size: 48, color: Styles.themeColor),
        title: const Text("What's new"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You can now sign in to back up your collections and settings '
              'to the cloud.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'If you reinstall the app or switch to a new device, just sign '
              'in again and everything will be restored automatically.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'You can use Google, Apple, or email to create an account.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Maybe later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AccountPage()),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Styles.themeColor,
            ),
            child: const Text('Sign in now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MainPageSettings>(builder: (context, settings, child) {
      String locale = settings.locale;
      Map<String, String>? titles = titleMap[locale] ?? titleMap['en'];

      String? aboutPageTitle = titles?['aboutPageTitle'];
      String? collectionPageTitle = titles?['collectionPageTitle'];
      String? songBooksPageTitle = titles?['songBooksPageTitle'];
      String? songsPageTitle = titles?['songsPageTitle'];

      return Localizations.override(
        context: context,
        locale: Locale(settings.locale),
        child: Scaffold(
            // navigation rail with same content as bottom navigation bar
            body: Row(children: [
              if (MediaQuery.of(context).size.width > 600)
                NavigationRail(
                  onDestinationSelected: (int index) {
                    settings.setOpenPageIndex(index);
                  },
                  groupAlignment: 0.0,
                  selectedIndex: settings.openPageIndex,
                  backgroundColor: Styles.themeColor.withAlpha(30),
                  indicatorColor: Styles.themeColor.withAlpha(50),
                  minWidth: 100,
                  elevation: 1,
                  labelType: NavigationRailLabelType.all,
                  destinations: <NavigationRailDestination>[
                    NavigationRailDestination(
                        icon: const Icon(Icons.lyrics),
                        label: Text(songsPageTitle!),
                        padding: const EdgeInsets.all(10)),
                    NavigationRailDestination(
                        icon: const Icon(Icons.book),
                        label: Text(songBooksPageTitle!),
                        padding: const EdgeInsets.all(10)),
                    NavigationRailDestination(
                        icon: const Icon(Icons.library_music),
                        label: Text(collectionPageTitle!),
                        padding: const EdgeInsets.all(10)),
                    NavigationRailDestination(
                        icon: const Icon(Icons.info),
                        label: Text(aboutPageTitle!),
                        padding: const EdgeInsets.all(10)),
                  ],
                ),
              // This is the main content.
              Expanded(
                child: _widgetOptions.elementAt(settings.openPageIndex),
              )
            ]),
            bottomNavigationBar: MediaQuery.of(context).size.width > 600
                ? null
                : NavigationBar(
                    onDestinationSelected: (int index) {
                      settings.setOpenPageIndex(index);
                    },
                    selectedIndex: settings.openPageIndex,
                    destinations: <Widget>[
                      NavigationDestination(
                        icon: const Icon(Icons.lyrics),
                        label: songsPageTitle!,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.book),
                        label: songBooksPageTitle!,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.library_music),
                        label: collectionPageTitle!,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.info),
                        label: aboutPageTitle!,
                      ),
                    ],
                  )),
      );
    });
  }
}
