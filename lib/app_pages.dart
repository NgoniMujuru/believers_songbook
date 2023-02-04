import 'package:believers_songbook/providers/main_page_settings.dart';
import 'package:believers_songbook/songs.dart';
import 'package:believers_songbook/styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'about.dart';
import 'song_books.dart';

class AppPages extends StatelessWidget {
  const AppPages({super.key});

  static final List<Widget> _widgetOptions = <Widget>[
    const Songs(),
    SongBooks(),
    const AboutPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<MainPageSettings>(builder: (context, settings, child) {
      return Scaffold(
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
                destinations: const <NavigationRailDestination>[
                  NavigationRailDestination(
                      icon: Icon(Icons.lyrics),
                      label: Text('Songs'),
                      padding: EdgeInsets.all(10)),
                  NavigationRailDestination(
                      icon: Icon(Icons.book),
                      label: Text('Songbooks'),
                      padding: EdgeInsets.all(10)),
                  NavigationRailDestination(
                      icon: Icon(Icons.account_circle),
                      label: Text('About'),
                      padding: EdgeInsets.all(10)),
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
                  destinations: const <Widget>[
                    NavigationDestination(
                      icon: Icon(Icons.lyrics),
                      label: 'Songs',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.book),
                      label: 'Songbooks',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.info),
                      label: 'About',
                    ),
                  ],
                ));
    });
  }
}
