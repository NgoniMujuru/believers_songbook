import 'package:believers_songbook/styles.dart';
// import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/song_book_settings.dart';

class SongBooks extends StatelessWidget {
  SongBooks({super.key});

  final List songList = [
    {
      'Title': 'Bible Tabernacle',
      'Location': 'Cape Town, South Africa',
      'Songs': '3416',
      'FileName': 'BibleTabernacle_CapeTown_SA',
      'Last Updated': '2023-01-15',
      'Languages': ['Afrikaans', 'English']
    },
    {
      'Title': 'Emmanuel Gospel Centre',
      'Location': 'Johannesburg, South Africa',
      'Songs': '20',
      'FileName': 'EmmanuelGospelCentre_Joburg_SA',
      'Last Updated': '2022-09-01',
      'Languages': ['English'],
    },
    {
      'Title': 'Harare Christian Fellowship',
      'Location': 'Harare, Zimbabwe',
      'Songs': '2136',
      'FileName': 'HarareChristianFellowship_Harare_Zimbabwe',
      'Last Updated': '2022-08-01',
      'Languages': ['English', 'Ndebele', 'Shona'],
    },
    {
      'Title': 'Kenya Local Believers',
      'Location': 'Nairobi, Kenya',
      'Songs': '',
      'FileName': 'KenyaLocalBelievers_Nairobi_Kenya',
      'Last Updated': '2022-08-01',
      'Languages': ['English', 'Swahili'],
    },
    {
      'Title': 'Nyimbo za Injili',
      'Location': 'Nairobi, Kenya',
      'Songs': '',
      'FileName': 'NyimboZaInjili_Nairobi_Kenya',
      'Last Updated': '2022-08-01',
      'Languages': ['Swahili'],
    },
    {
      'Title': 'Shekinah Tabernacle',
      'Location': 'Kinshasa, Congo',
      'Songs': '807',
      'FileName': 'ShekinahTabernacle_Kinshasa_DRC',
      'Last Updated': '2022-08-01',
      'Languages': ['French', 'Lingala'],
    },
    {
      'Title': 'Third Exodus Assembly',
      'Location': 'Longdenville, Trinidad and Tobago',
      'Songs': '',
      'FileName': 'ThirdExodusAssembly_Trinidad',
      'Last Updated': '2022-08-01',
      'Languages': ['English'],
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
          padding: MediaQuery.of(context).size.width > 600
              ? const EdgeInsets.fromLTRB(80, 0, 80, 0)
              : const EdgeInsets.fromLTRB(10, 0, 10, 0),
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
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
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
