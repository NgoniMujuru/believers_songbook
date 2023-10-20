import 'package:believers_songbook/collections.dart';
import 'package:believers_songbook/providers/main_page_settings.dart';
import 'package:believers_songbook/songs.dart';
import 'package:believers_songbook/styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'about.dart';
import 'song_books.dart';

class AppPages extends StatelessWidget {
  AppPages({super.key});

  static final List<Widget> _widgetOptions = <Widget>[
    const Songs(),
    const SongBooks(),
    const Collections(),
    AboutPage(),
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
