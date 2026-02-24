import 'package:believers_songbook/providers/main_page_settings.dart';
import 'package:believers_songbook/providers/theme_settings.dart';
import 'package:believers_songbook/styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/song_book_settings.dart';
import 'constants/song_book_assets.dart';
import 'package:believers_songbook/l10n/app_localizations.dart';
import 'package:believers_songbook/tour/app_tour_controller.dart';
import 'package:believers_songbook/tour/tour_ids.dart';

class SongBooks extends StatefulWidget {
  const SongBooks({super.key});

  @override
  State<SongBooks> createState() => _SongBooksState();
}

class _SongBooksState extends State<SongBooks> {
  final GlobalKey _firstCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final tour = context.read<AppTourController>();
    tour.registerTarget(TourIds.songBooksFirstCard, _firstCardKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      tour.registerScreenContext(TourIds.songBooksScreen, context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.songBooksPageTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: isWideScreen
              ? const EdgeInsets.fromLTRB(80, 0, 80, 0)
              : const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: Consumer2<SongBookSettings, ThemeSettings>(
            builder: (context, songBookSettings, themeSettings, child) {
              return RawScrollbar(
                minThumbLength: isWideScreen ? 100 : 40,
                thickness: isWideScreen ? 20 : 10.0,
                radius: const Radius.circular(5.0),
                thumbVisibility: true,
                child: ListView.builder(
                  itemCount: SongBookAssets.songList.length,
                  itemBuilder: (context, index) {
                    final songBook = SongBookAssets.songList[index];
                    final isSelected =
                        songBookSettings.songBookFile == songBook['FileName'];

                    final cardColor = isSelected
                        ? (themeSettings.isDarkMode
                            ? Styles.selectedSongBookBackgroundDark
                            : Styles.selectedSongBookBackground)
                        : (themeSettings.isDarkMode
                            ? Styles.songBookBackgroundDark
                            : Styles.songBookBackground);

                    return Padding(
                      padding: isWideScreen
                          ? const EdgeInsets.fromLTRB(0, 0, 25, 0)
                          : const EdgeInsets.fromLTRB(0, 0, 15, 0),
                      child: Card(
                        key: index == 1 ? _firstCardKey : null,
                        clipBehavior: Clip.hardEdge,
                        color: cardColor,
                        child: InkWell(
                          splashColor: Styles.themeColor.withAlpha(30),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${AppLocalizations.of(context)!.songBooksChangeSnackBarText} ${songBook['Title']}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: themeSettings.isDarkMode
                                    ? Styles.searchBackgroundDark
                                    : Styles.themeColor,
                                duration: const Duration(seconds: 3),
                              ),
                            );

                            Provider.of<MainPageSettings>(context,
                                    listen: false)
                                .setOpenPageIndex(0);

                            songBookSettings
                                .setSongBookFile(songBook['FileName']);
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                title: Text(songBook['Title']),
                                textColor: themeSettings.isDarkMode
                                    ? Styles.songBookTextDark
                                    : Styles.songBookText,
                                subtitle: Text(songBook['Location']),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    16.0, 0, 8.0, 8.0),
                                child: Text(
                                  (songBook['Languages'] as List<dynamic>)
                                      .join(', '),
                                  style: TextStyle(
                                    color: themeSettings.isDarkMode
                                        ? Styles.songBookLanguagesDark
                                        : Styles.songBookLanguages,
                                  ),
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
