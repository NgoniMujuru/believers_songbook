import 'package:believers_songbook/providers/main_page_settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'about.dart';
import 'songs.dart';
import 'styles.dart';
import 'package:firebase_core/firebase_core.dart';
import 'song_books.dart';
import 'providers/song_settings.dart';
import 'providers/song_book_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (context) => SongSettings()),
    ChangeNotifierProvider(create: (context) => MainPageSettings()),
    ListenableProvider(create: (context) => SongBookSettings())
  ], child: MyApp()));
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  static const String _title = 'Believers Songbook';
  final Future<FirebaseApp> _fbApp = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Styles.themeColor,
      ),
      debugShowCheckedModeBanner: false,
      title: _title,
      home: FutureBuilder(
        future: _fbApp,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Loading songbooks failed, please try again later');
          } else if (snapshot.hasData) {
            return const MyStatefulWidget();
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({super.key});

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  static final List<Widget> _widgetOptions = <Widget>[
    const Songs(),
    SongBooks(),
    const AboutPage(),
  ];

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      final songSettings = context.read<SongSettings>();
      songSettings.setFontSize(prefs.getDouble('fontSize') ?? 30);
    });
  }

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
