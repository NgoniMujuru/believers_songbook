import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class SongBooks extends StatefulWidget {
  const SongBooks({super.key});

  @override
  _songBooksState createState() => _songBooksState();
}

class _songBooksState extends State<SongBooks> {
  List songList = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Songbooks'),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              Text(
                'Index 1: Songbook page',
              ),
              Expanded(
                child: ListView.builder(
                    itemCount: songList.length,
                    itemBuilder: (itemBuilder, index) {
                      return ListTile(
                        title: Text(songList.isEmpty
                            ? 'Loading'
                            : songList.elementAt(index)['Title'].toString()),
                      );
                    }),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            DatabaseReference _testRef =
                FirebaseDatabase.instance.ref().child('SongBooks');
            _testRef.get().then((DataSnapshot snapshot) {
              print('Connected to second database and read ${snapshot.value}');

              Iterable<DataSnapshot> values = snapshot.children;
              values.forEach((DataSnapshot child) {
                print(child.key);
                print(child.value);
                songList.add(child.value);
              });

              setState(() {
                songList = songList;
              });
            });
          },
          label: const Text('Check for updates')),
    );
  }
}
