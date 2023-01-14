import 'package:flutter/material.dart';
import 'about.dart';
import 'songs.dart';
import 'styles.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
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
            print('You have an error! ${snapshot.error.toString()}');
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
  int _selectedIndex = 0;
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static final List<Widget> _widgetOptions = <Widget>[
    const Songs(),
    const Center(
      child: Text(
        'Index 1: Songbooks',
        style: optionStyle,
      ),
    ),
    const AboutPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedIndex: _selectedIndex,
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
  }
}
