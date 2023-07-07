import 'package:believers_songbook/models/collection_song.dart';
import 'package:believers_songbook/song.dart';
import 'package:flutter/material.dart';

class CollectionSongs extends StatelessWidget {
  final String collectionName;
  final List<CollectionSong> songs;

  const CollectionSongs({
    required this.collectionName,
    required this.songs,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(collectionName),
          scrolledUnderElevation: 4,
        ),
        body: SafeArea(
          child: _buildCollectionList(context),
        ),
      ),
    );
  }

  Widget _buildCollectionList(context) {
    return Expanded(
      child: Padding(
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
                              builder: (context) => Song(
                                  songText: lyrics, songKey: key, songTitle: title)));
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
      ),
    );
  }
}
