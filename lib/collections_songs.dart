import 'dart:developer';

import 'package:believers_songbook/models/collection_song.dart';
import 'package:believers_songbook/providers/collections_data.dart';
import 'package:believers_songbook/providers/song_settings.dart';
import 'package:believers_songbook/providers/theme_settings.dart';
import 'package:believers_songbook/providers/main_page_settings.dart';
import 'package:believers_songbook/song.dart';
import 'package:believers_songbook/styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CollectionSongs extends StatelessWidget {
  final int collectionId;

  const CollectionSongs({
    required this.collectionId,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CollectionsData>(
      builder: (context, collectionsData, child) => (SelectionArea(
        child: Scaffold(
          appBar: AppBar(
            title: Text(getCollectionName(collectionsData, collectionId)),
            scrolledUnderElevation: 4,
            actions: [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return Consumer<MainPageSettings>(
                          builder: (context, mainPageSettings, child) =>
                              (Localizations.override(
                                  context: context,
                                  locale: Locale(mainPageSettings.getLocale),
                                  child: Consumer<MainPageSettings>(
                                      builder: (context, mainPageSettings,
                                              child) =>
                                          (AlertDialog(
                                            title: Text(AppLocalizations.of(
                                                    context)!
                                                .collectionSongsDialogTitle),
                                            content: Text(
                                                AppLocalizations.of(context)!
                                                    .collectionSongsDialogText),
                                            actions: [
                                              TextButton(
                                                onPressed: () async {
                                                  final navigator =
                                                      Navigator.of(context);
                                                  await collectionsData
                                                      .deleteCollection(
                                                          collectionId);
                                                  navigator.pop();
                                                  navigator.pop();
                                                },
                                                child: Text(
                                                  AppLocalizations.of(context)!
                                                      .collectionSongsDialogDelete,
                                                  style: const TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: Text(AppLocalizations.of(
                                                        context)!
                                                    .collectionSongsDialogCancel),
                                              )
                                            ],
                                          ))))));
                    },
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: collectionsData.songsByCollection[collectionId] == null ||
                    collectionsData.songsByCollection[collectionId]!.isEmpty
                ? Center(
                    child: Padding(
                      padding: MediaQuery.of(context).size.width > 600
                          ? const EdgeInsets.fromLTRB(80, 20, 80, 40)
                          : const EdgeInsets.all(20.0),
                      child: Consumer<ThemeSettings>(
                        builder: (context, themeSettings, child) => (Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text(
                              AppLocalizations.of(context)!
                                  .collectionSongsEmptyStateText,
                              style: themeSettings.isDarkMode
                                  ? Styles.aboutHeaderDark
                                  : Styles.aboutHeader,
                            ),
                          ],
                        )),
                      ),
                    ),
                  )
                : _buildCollectionList(
                    context, collectionsData.songsByCollection[collectionId]?..sort((a, b) => a.songPosition.compareTo(b.songPosition)),
                    ),
          ),
        ),
      )),
    );
  }

  

  Widget _buildCollectionList(context, songs) {
     final scrollController = ScrollController();

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
      child: RawScrollbar(
        minThumbLength: MediaQuery.of(context).size.width > 600 ? 100 : 40,
        thickness: MediaQuery.of(context).size.width > 600 ? 20 : 10.0,
        radius: const Radius.circular(5.0),
        thumbVisibility: true,
        controller: scrollController,
        child: ReorderableSongList(songs, scrollController: scrollController),
      ),
    );
  }

  String getCollectionName(collectionsData, collectionId) {
    String name = '';
    collectionsData.collections.forEach((collection) {
      if (collection.id == collectionId) {
        name = collection.name;
      }
    });
    return name;
  }
}

class ReorderableSongList extends StatefulWidget {
  final List<CollectionSong> songs;
  final ScrollController scrollController;
  const ReorderableSongList(this.songs, {required this.scrollController, super.key});

  @override
  State<ReorderableSongList> createState() => _ReorderableSongListState();
}

class _ReorderableSongListState extends State<ReorderableSongList> {
  late List<CollectionSong> _songs;

  @override
  void initState() {
    super.initState();
    _songs = List.from(widget.songs); // Initialize _songs with the provided list
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      buildDefaultDragHandles: false, // Custom drag handles
      children: List.generate(_songs.length, (index) {
        return Container(
          key: ValueKey(_songs[index].id), 
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  String lyrics = _songs[index].lyrics;
                  String title = _songs[index].title;
                  String key = _songs[index].key;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Song(
                        songText: lyrics,
                        songKey: key,
                        songTitle: title,
                        isCollectionSong: true,
                      ),
                    ),
                  );
                }, 
                child: Consumer<SongSettings>(
                  builder: (context, songSettings, child) {
                    return ListTile(
                      title: Text(_songs[index].title),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (songSettings.displayKey) Text(_songs[index].key),
                          const Padding(padding: EdgeInsets.fromLTRB(0, 0, 10, 0)),
                          // Custom drag handle for reordering
                          ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.menu),
                          ),
                        ],
                      ), // trailing Row
                    );
                  }, // builder
                ), // Consumer
              ), // GestureDetector
              const Divider(height: 0.5),
            ], // Column children
          ), // Column
        );
      }),
      onReorder: (int oldIndex, int newIndex) {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final CollectionSong song = _songs.removeAt(oldIndex);
          _songs.insert(newIndex, song);

          // Update song positions after reordering
          for (int i = 0; i < _songs.length; i++) {
            _songs[i].songPosition = i;
          }
        });
      },
    );
  }
}
