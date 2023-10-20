import 'package:believers_songbook/providers/main_page_settings.dart';
import 'package:believers_songbook/providers/theme_settings.dart';
import 'package:believers_songbook/styles.dart';
// import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/song_book_settings.dart';
import 'constants/song_book_assets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SongBooks extends StatelessWidget {
  const SongBooks({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.songBooksPageTitle),
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
                      itemCount: SongBookAssets.songList.length,
                      itemBuilder: (itemBuilder, index) {
                        return Consumer<ThemeSettings>(
                          builder: (context, themeSettings, child) => Card(
                            clipBehavior: Clip.hardEdge,
                            color: songBookSettings.songBookFile ==
                                    SongBookAssets.songList[index]['FileName']
                                ? (themeSettings.isDarkMode
                                    ? Styles.selectedSongBookBackgroundDark
                                    : Styles.selectedSongBookBackground)
                                : (themeSettings.isDarkMode
                                    ? Styles.songBookBackgroundDark
                                    : Styles.songBookBackground),
                            child: InkWell(
                              splashColor: Styles.themeColor.withAlpha(30),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${AppLocalizations.of(context)!.songBooksChangeSnackBarText} ${SongBookAssets.songList[index]['Title']}',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: themeSettings.isDarkMode
                                        ? Styles.searchBackgroundDark
                                        : Styles.themeColor,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                                Provider.of<MainPageSettings>(context, listen: false)
                                    .setOpenPageIndex(0);
                                songBookSettings.setSongBookFile(
                                    SongBookAssets.songList[index]['FileName']);
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    title: Text(SongBookAssets.songList[index]['Title']),
                                    textColor: themeSettings.isDarkMode
                                        ? Styles.songBookTextDark
                                        : Styles.songBookText,
                                    subtitle:
                                        Text(SongBookAssets.songList[index]['Location']),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16.0, 0, 8.0, 8.0),
                                    child: Text(
                                      SongBookAssets.songList[index]['Languages']
                                          .join(', '),
                                      style: TextStyle(
                                          color: themeSettings.isDarkMode
                                              ? Styles.songBookLanguagesDark
                                              : Styles.songBookLanguages),
                                      softWrap: true,
                                    ),
                                  )
                                ],
                              ),
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
      //           // song_book_assets.add(child.value);
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
