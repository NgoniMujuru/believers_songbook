import 'package:believers_songbook/styles.dart';
// import 'package:firebase_database/firebase_database.dart';
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
      'FileName': 'HarareChristianFellowship_Harare_Zimbabwe.csv',
      'Last Updated': '2022-08-01',
      'Languages': ['English', 'Shona', 'Ndebele'],
    },
    {
      'Title': 'Bible Tabernacle',
      'Location': 'CapeTown, South Africa',
      'Songs': '3416',
      'FileName': '2.csv',
      'Last Updated': '2023-01-15',
      'Languages': ['English']
    },
    {
      'Title': 'Cloverdale Bibleway',
      'Location': 'Surrey, Canada',
      'Songs': '508',
      'FileName': 'Bibleway.csv',
      'Last Updated': '2022-09-01',
      'Languages': ['English'],
    },
    {
      'Title': 'Believers Christian Fellowship',
      'Location': 'Ohio, USA',
      'Songs': '1006',
      'FileName': 'BCF.csv',
      'Last Updated': '2023-01-15',
      'Languages': ['English']
    },
    {
      'Title': 'Elandsfontein Tabernacle',
      'Location': 'Johannesburg, South Africa',
      'Songs': '2136',
      'FileName': 'SampleSongs_20.csv',
      'Last Updated': '2022-09-01',
      'Languages': ['English', 'Afrikaans', 'Zulu'],
    },
    {
      'Title': 'Willows Tabernacle',
      'Location': 'Pretoria, South Africa',
      'Songs': '1356',
      'FileName': '3.csv',
      'Last Updated': '2023-01-10',
      'Languages': ['English', 'Xhosa'],
    },
    {
      'Title': 'Shalom Tabernacle',
      'Location': 'Masvingo, Zimbabwe',
      'Songs': '1223',
      'FileName': '4.csv',
      'Last Updated': '2022-12-10',
      'Languages': ['English', 'Shona'],
    },
    {
      'Title': 'Polokwane Tabernacle',
      'Location': 'Polokwane, South Africa',
      'Songs': '2136',
      'FileName': '5.csv',
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
                          color:
                              songBookSettings.songBookFile == songList[index]['FileName']
                                  ? Styles.searchBackground
                                  : Colors.white,
                          child: InkWell(
                            splashColor: Styles.themeColor.withAlpha(30),
                            onTap: () {
                              songBookSettings
                                  .setSongBookFile(songList[index]['FileName']);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Songbook changed to ${songList[index]['Title']}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Styles.themeColor,
                                  duration: const Duration(seconds: 3),
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
