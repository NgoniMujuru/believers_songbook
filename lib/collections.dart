import 'package:believers_songbook/models/collection_song.dart';
import 'package:believers_songbook/providers/collections_data.dart';
import 'package:believers_songbook/providers/theme_settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'collections_songs.dart';
import 'styles.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Collections extends StatelessWidget {
  const Collections({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CollectionsData>(
      builder: (context, collectionsData, child) => (SelectionArea(
        child: Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.globalCollections),
            scrolledUnderElevation: 4,
          ),
          body: SafeArea(
            child: collectionsData.collections.isNotEmpty
                ? _buildCollectionList(collectionsData, context)
                : Center(
                    child: Padding(
                      padding: MediaQuery.of(context).size.width > 600
                          ? const EdgeInsets.fromLTRB(80, 20, 80, 40)
                          : const EdgeInsets.all(20.0),
                      child: Consumer<ThemeSettings>(
                        builder: (context, themeSettings, child) => (Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.collectionsEmptyStateText,
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
      )),
    );
  }

  Widget _buildCollectionList(collectionsData, context) {
    Map<int, List<CollectionSong>> songsByCollection = collectionsData.songsByCollection;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
      child: RawScrollbar(
        minThumbLength: MediaQuery.of(context).size.width > 600 ? 100 : 40,
        thickness: MediaQuery.of(context).size.width > 600 ? 20 : 10.0,
        radius: const Radius.circular(5.0),
        thumbVisibility: true,
        trackVisibility: true,
        thumbColor: Colors.grey.withOpacity(0.5),
        trackColor: Colors.grey.withOpacity(0.1),
        child: ListView.builder(
          itemCount: collectionsData.collections.length,
          itemBuilder: (context, index) {
            int? numSongs =
                songsByCollection[collectionsData.collections[index].id]?.length;
            String numSongsString = numSongs == 1
                ? AppLocalizations.of(context)!.globalSong
                : AppLocalizations.of(context)!.collectionsSongs;
            DateTime dateTime =
                DateTime.parse(collectionsData.collections[index].dateCreated);
            String formattedDate = DateFormat('dd MMMM yyyy').format(dateTime);

            return Padding(
              padding: MediaQuery.of(context).size.width > 600
                  ? const EdgeInsets.fromLTRB(0, 0, 25, 0)
                  : const EdgeInsets.fromLTRB(0, 0, 15, 0),
              child: Column(
                children: [
                  ListTile(
                      title: Text(collectionsData.collections[index].name),
                      trailing: Text('$numSongs $numSongsString'),
                      subtitle: Text(
                          '${AppLocalizations.of(context)!.collectionsCreated}: $formattedDate'),
                      onTap: () {
                        int collectionId = collectionsData.collections[index].id;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CollectionSongs(
                              collectionId: collectionId,
                            ),
                          ),
                        );
                      }),
                  const Divider(
                    height: 0.5,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
