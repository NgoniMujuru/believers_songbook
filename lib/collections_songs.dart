import 'package:believers_songbook/providers/collections_data.dart';
import 'package:believers_songbook/providers/theme_settings.dart';
import 'package:believers_songbook/song.dart';
import 'package:believers_songbook/styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Are you sure?'),
                              content: const Text(
                                  'This will delete this collection. This action cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () async {
                                    final navigator = Navigator.of(context);
                                    await collectionsData.deleteCollection(collectionId);
                                    navigator.pop();
                                    navigator.pop();
                                  },
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Cancel'),
                                )
                              ],
                            );
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
                                    "This collection has no songs. Add songs to this collection by opening a song and selecting the collections menu icon on the top right corner.",
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
                          context, collectionsData.songsByCollection[collectionId]),
                ),
              ),
            )));
  }

  Widget _buildCollectionList(context, songs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
      child: RawScrollbar(
        minThumbLength: MediaQuery.of(context).size.width > 600 ? 100 : 40,
        thickness: MediaQuery.of(context).size.width > 600 ? 20 : 10.0,
        radius: const Radius.circular(5.0),
        thumbVisibility: true,
        child: ListView.builder(
          itemBuilder: (context, index) => Padding(
            padding: MediaQuery.of(context).size.width > 600
                ? const EdgeInsets.fromLTRB(0, 0, 25, 0)
                : const EdgeInsets.fromLTRB(0, 0, 15, 0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    String lyrics = songs.elementAt(index).lyrics;
                    String title = songs.elementAt(index).title;
                    String key = songs.elementAt(index).key;

                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                Song(songText: lyrics, songKey: key, songTitle: title)));
                  },
                  child: ListTile(
                    title: Text(songs.elementAt(index).title),
                  ),
                ),
                const Divider(
                  height: 0.5,
                ),
              ],
            ),
          ),
          itemCount: songs.length,
        ),
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
