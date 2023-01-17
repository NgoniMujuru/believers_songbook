import 'package:believers_songbook/styles.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/song_book_settings.dart';

class SongBooks extends StatelessWidget {
  SongBooks({super.key});

  final List songList = [
    {
      'Title': 'Harare Christian Fellowship',
      'Location': 'Harare, Zimbabwe',
      'Songs': '2136',
      'Path': 'assets/Songs.csv',
      'Last Updated': '2022-08-01',
      'Languages': ['English', 'Shona', 'Ndebele'],
    },
    {
      'Title': 'Bible Tabernacle',
      'Location': 'CapeTown, South Africa',
      'Songs': '3416',
      'Path': 'assets/2.csv',
      'Last Updated': '2023-01-15',
      'Languages': ['English']
    },
    {
      'Title': 'Cloverdale Bibleway',
      'Location': 'Surrey, Canada',
      'Songs': '508',
      'Path': 'assets/Bibleway.csv',
      'Last Updated': '2022-09-01',
      'Languages': ['English'],
    },
    {
      'Title': 'Believers Christian Fellowship',
      'Location': 'Ohio, USA',
      'Songs': '1006',
      'Path': 'assets/BCF.csv',
      'Last Updated': '2023-01-15',
      'Languages': ['English']
    },
    {
      'Title': 'Elandsfontein Tabernacle',
      'Location': 'Johannesburg, South Africa',
      'Songs': '2136',
      'Path': 'assets/SampleSongs_20.csv',
      'Last Updated': '2022-09-01',
      'Languages': ['English', 'Afrikaans', 'Zulu'],
    },
    {
      'Title': 'Willows Tabernacle',
      'Location': 'Pretoria, South Africa',
      'Songs': '1356',
      'Path': 'assets/3.csv',
      'Last Updated': '2023-01-10',
      'Languages': ['English', 'Xhosa'],
    },
    {
      'Title': 'Shalom Tabernacle',
      'Location': 'Masvingo, Zimbabwe',
      'Songs': '1223',
      'Path': 'assets/4.csv',
      'Last Updated': '2022-12-10',
      'Languages': ['English', 'Shona'],
    },
    {
      'Title': 'Polokwane Tabernacle',
      'Location': 'Polokwane, South Africa',
      'Songs': '2136',
      'Path': 'assets/5.csv',
      'Last Updated': '2022-09-01',
      'Languages': ['English', 'Pedi', 'Zulu'],
    },
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Songbooks'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: Column(
            children: [
              Expanded(
                child: Consumer<SongBookSettings>(
                    builder: (context, songBookSettings, child) {
                  return ListView.builder(
                      itemCount: songList.length,
                      itemBuilder: (itemBuilder, index) {
                        return Card(
                          clipBehavior: Clip.hardEdge,
                          color: songBookSettings.songBookPath == songList[index]['Path']
                              ? Styles.searchBackground
                              : Colors.white,
                          child: InkWell(
                            splashColor: Styles.themeColor.withAlpha(30),
                            onTap: () {
                              songBookSettings.setSongBookPath(songList[index]['Path']);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Songbook changed to ' + songList[index]['Title'],
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Styles.themeColor,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                ListTile(
                                  // enabled: false,
                                  title: Text(songList[index]['Title']),
                                  textColor: Colors.black,
                                  subtitle: Text(songList[index]['Location']),
                                  // trailing: Text(songList[index]['Songs'] + ' songs'),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16.0, 0, 8.0, 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        songList[index]['Songs'] + ' songs',
                                        style: TextStyle(color: Colors.grey[800]),
                                      ),
                                      Text(
                                        // comma separated languages from array
                                        songList[index]['Languages'].join(', '),
                                        style: TextStyle(color: Colors.grey[800]),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      });
                }),
              ),
            ],
          ),
        ),
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //     onPressed: () {
      //       DatabaseReference _testRef =
      //           FirebaseDatabase.instance.ref().child('SongBooks');
      //       _testRef.get().then((DataSnapshot snapshot) {
      //         Iterable<DataSnapshot> values = snapshot.children;
      //         values.forEach((DataSnapshot child) {
      //           // print(child.key);
      //           // print(child.value);
      //           // songList.add(child.value);
      //         });
      //         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      //             content: Text(
      //               'Songbooks updated successfully',
      //               style: TextStyle(color: Colors.white),
      //             ),
      //             backgroundColor: Styles.themeColor,
      //             duration: Duration(seconds: 2)));
      //       });
      //     },
      //     label: const Text('Check for updates')),
    );
  }
}
