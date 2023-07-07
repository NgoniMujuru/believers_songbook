import 'package:believers_songbook/models/collection_song.dart';
import 'package:believers_songbook/providers/collections_data.dart';
import 'package:believers_songbook/providers/theme_settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'styles.dart';

class Collections extends StatelessWidget {
  const Collections({super.key});

  @override
  Widget build(BuildContext context) {
    var collectionsData = context.read<CollectionsData>();

    return SelectionArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Collections'),
          scrolledUnderElevation: 4,
        ),
        body: SafeArea(
          child: collectionsData.collections.isNotEmpty
              ? _buildCollectionList(collectionsData, context)
              : SingleChildScrollView(
                  child: Center(
                    child: Padding(
                      padding: MediaQuery.of(context).size.width > 600
                          ? const EdgeInsets.fromLTRB(80, 20, 80, 40)
                          : const EdgeInsets.all(20.0),
                      child: Consumer<ThemeSettings>(
                        builder: (context, themeSettings, child) => (Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text(
                              'Create your own song collections. Open a song and select the collections menu icon on the top right corner.',
                              style: themeSettings.isDarkMode
                                  ? Styles.aboutHeaderDark
                                  : Styles.aboutHeader,
                            ),
                          ],
                        )),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCollectionList(collectionsData, context) {
    Map<int, List<CollectionSong>> songsByCollection =
        createSongsByCollection(collectionsData);
    List sortedCollections = collectionsData.collections.toList();
    sortedCollections.sort((a, b) => a.name.compareTo(b.name));

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
      child: RawScrollbar(
        minThumbLength: MediaQuery.of(context).size.width > 600 ? 100 : 40,
        thickness: MediaQuery.of(context).size.width > 600 ? 20 : 10.0,
        radius: const Radius.circular(5.0),
        thumbVisibility: true,
        child: ListView.builder(
          itemCount: sortedCollections.length,
          itemBuilder: (context, index) {
            int? numSongs = songsByCollection[sortedCollections[index].id]?.length;
            String numSongsString = numSongs == 1 ? 'song' : 'songs';
            DateTime dateTime = DateTime.parse(sortedCollections[index].dateCreated);
            String formattedDate = DateFormat('dd MMMM yyyy').format(dateTime);

            return Padding(
              padding: MediaQuery.of(context).size.width > 600
                  ? const EdgeInsets.fromLTRB(0, 0, 25, 0)
                  : const EdgeInsets.fromLTRB(0, 0, 15, 0),
              child: Column(
                children: [
                  ListTile(
                    title: Text(sortedCollections[index].name),
                    trailing: Text('$numSongs $numSongsString'),
                    subtitle: Text('Created: $formattedDate'),
                    onTap: () {
                      Navigator.pushNamed(context, '/collection',
                          arguments: sortedCollections[index]);
                    },
                  ),
                  const Divider(
                    height: 0,
                    thickness: 1,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Map<int, List<CollectionSong>> createSongsByCollection(collectionsData) {
    Map<int, List<CollectionSong>> songsByCollection = <int, List<CollectionSong>>{};

    for (var collection in collectionsData.collections) {
      if (!songsByCollection.containsKey(collection.id)) {
        songsByCollection[collection.id] = [];
      }
      for (var collectionSong in collectionsData.collectionSongs) {
        if (collectionSong.collectionId == collection.id) {
          songsByCollection[collection.id]?.add(collectionSong);
        }
      }
    }
    return songsByCollection;
  }
}
