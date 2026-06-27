import 'package:believers_songbook/providers/main_page_settings.dart';
import 'package:believers_songbook/providers/songbook_counts.dart';
import 'package:believers_songbook/services/analytics_service.dart';
import 'package:believers_songbook/providers/theme_settings.dart';
import 'package:believers_songbook/widgets/sync_status_icon.dart';
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
  final ScrollController _scrollController = ScrollController();
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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// A song book counts as "new" for ~1 month after the most recent of its
  /// DateAdded / DateUpdated dates, so both newly added and freshly updated
  /// books are highlighted.
  static const int _newForDays = 30;
  bool _isNew(Map songBook) {
    DateTime? newest;
    for (final key in const ['DateAdded', 'DateUpdated']) {
      final raw = songBook[key];
      if (raw is! String || raw.isEmpty) continue;
      final date = DateTime.tryParse(raw);
      if (date != null && (newest == null || date.isAfter(newest))) {
        newest = date;
      }
    }
    if (newest == null) return false;
    final age = DateTime.now().difference(newest).inDays;
    return age >= 0 && age <= _newForDays;
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.songBooksPageTitle),
        actions: const [SyncStatusIcon()],
      ),
      body: SafeArea(
        child: Padding(
          padding: isWideScreen
              ? const EdgeInsets.fromLTRB(80, 0, 80, 0)
              : const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: Consumer3<SongBookSettings, ThemeSettings, SongbookCounts>(
            builder: (context, songBookSettings, themeSettings, counts, child) {
              return RawScrollbar(
                controller: _scrollController,
                minThumbLength: isWideScreen ? 100 : 40,
                thickness: isWideScreen ? 20 : 10.0,
                radius: const Radius.circular(5.0),
                thumbVisibility: true,
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: SongBookAssets.songList.length,
                  itemBuilder: (context, index) {
                    final songBook = SongBookAssets.songList[index];
                    final isSelected =
                        songBookSettings.songBookFile == songBook['FileName'];
                    final isNew = _isNew(songBook as Map);

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
                            AnalyticsService.instance.trackSongbookChanged(
                              songbookName: songBook['Title'],
                            );
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
                                trailing: isNew
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Styles.themeColor,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          AppLocalizations.of(context)!
                                              .songBooksNewBadge,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    16.0, 0, 8.0, 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        (songBook['Languages']
                                                as List<dynamic>)
                                            .join(', '),
                                        style: TextStyle(
                                          color: themeSettings.isDarkMode
                                              ? Styles.songBookLanguagesDark
                                              : Styles.songBookLanguages,
                                        ),
                                        softWrap: true,
                                      ),
                                    ),
                                    Builder(builder: (context) {
                                      final n =
                                          counts.countFor(songBook['FileName']);
                                      if (n == 0) return const SizedBox.shrink();
                                      return Text(
                                        AppLocalizations.of(context)!
                                            .songBooksCountSongs(n),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: themeSettings.isDarkMode
                                              ? Styles.songBookLanguagesDark
                                              : Styles.songBookLanguages,
                                        ),
                                      );
                                    }),
                                  ],
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
