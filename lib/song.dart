import 'dart:ffi';

import 'package:believers_songbook/models/collection.dart';
import 'package:believers_songbook/models/collection_song.dart';
import 'package:believers_songbook/providers/collections_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'styles.dart';
import 'package:provider/provider.dart';
import 'providers/song_settings.dart';

class Song extends StatelessWidget {
  final String songTitle;
  final String songText;
  final String songKey;

  Song({
    required this.songText,
    required this.songTitle,
    required this.songKey,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(Object context) {
    return SelectionArea(
      child: Scaffold(
        appBar: AppBar(
            title: Text(songTitle),
            shadowColor: Styles.themeColor,
            scrolledUnderElevation: 4,
            actions: <Widget>[
              IconButton(
                  icon: const Icon(Icons.playlist_add),
                  onPressed: () {
                    collectionsBottomSheet(context);
                  }),
              IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    settingsBottomSheet(context);
                  }),
            ]),
        // backgroundColor: Styles.scaffoldBackground,
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                  // color: Styles.scaffoldBackground,
                  ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer<SongSettings>(builder: (context, songSettings, child) {
                      return Padding(
                        padding: MediaQuery.of(context).size.width > 600
                            ? const EdgeInsets.fromLTRB(80, 20, 16, 40)
                            : const EdgeInsets.fromLTRB(16, 20, 16, 40),
                        child: Column(
                          children: [
                            if (songSettings.displayKey)
                              Text(songKey == '' ? '---' : songKey,
                                  style: TextStyle(
                                      fontSize: songSettings.fontSize,
                                      fontWeight: FontWeight.bold))
                            else
                              const SizedBox(),
                            SelectableText(songText,
                                style: TextStyle(fontSize: songSettings.fontSize)),
                          ],
                        ),
                      );
                    })
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isSelectingCollection = true;
  final _formKey = GlobalKey<FormState>();
  final List<bool> _songPresentInCollection = [];

  Future<void> collectionsBottomSheet(context) {
    var collectionsData = Provider.of<CollectionsData>(context, listen: false);

    initializeSongCollections(collectionsData);

    return showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width < 600
            ? MediaQuery.of(context).size.width
            : MediaQuery.of(context).size.width * 0.6,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15.0),
          topRight: Radius.circular(15.0),
        ),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setLocalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 50),
              child: Consumer<CollectionsData>(
                builder: (context, collectionsData, child) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _isSelectingCollection
                            ? IconButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.close),
                              )
                            : IconButton(
                                onPressed: () {
                                  setLocalState(() {
                                    _isSelectingCollection = true;
                                  });
                                },
                                icon: const Icon(Icons.arrow_back),
                              ),
                        const Text('Collections', style: TextStyle(fontSize: 25)),
                        TextButton(
                          onPressed: () {
                            if (!_isSelectingCollection) {
                              if (_formKey.currentState!.validate()) {
                                //save form
                                _formKey.currentState!.save();

                                setLocalState(() {
                                  _isSelectingCollection = true;
                                });
                              }
                            } else {
                              setLocalState(() {
                                _isSelectingCollection = false;
                              });
                            }
                          },
                          child: Row(
                            children: [
                              Icon(_isSelectingCollection ? Icons.add : Icons.check),
                              Text(_isSelectingCollection ? 'Create' : ' Save',
                                  style: const TextStyle(fontSize: 15)),
                            ],
                          ),
                        )
                      ],
                    ),
                    const Divider(),
                    SizedBox(
                      height: 300,
                      child: _isSelectingCollection
                          ? ListView.builder(
                              shrinkWrap: true,
                              itemCount: collectionsData.collections.length,
                              itemBuilder: (BuildContext context, int index) {
                                return Column(
                                  children: [
                                    CheckboxListTile(
                                      title:
                                          Text(collectionsData.collections[index].name),
                                      value: _songPresentInCollection[index],
                                      onChanged: (bool? value) {
                                        if (value == true) {
                                          CollectionSong collectionSong = CollectionSong(
                                            id: getAvailableId(
                                                collectionsData.collectionSongs),
                                            collectionId:
                                                collectionsData.collections[index].id,
                                            title: songTitle,
                                            key: songKey,
                                            lyrics: songText,
                                          );
                                          collectionsData.addCollectionSong(
                                            collectionSong,
                                          );
                                        } else {
                                          // get collectionSongId based on title and collectionId
                                          var collectionSongId = collectionsData
                                              .collectionSongs
                                              .firstWhere((collectionSong) =>
                                                  collectionSong.collectionId ==
                                                      collectionsData
                                                          .collections[index].id &&
                                                  collectionSong.title == songTitle)
                                              .id;

                                          collectionsData.deleteCollectionSong(
                                            collectionSongId,
                                          );
                                        }
                                        setLocalState(() {
                                          _songPresentInCollection[index] = value!;
                                        });
                                      },
                                    ),
                                    const Divider(),
                                  ],
                                );
                              },
                            )
                          : Form(
                              key: _formKey,
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  border: UnderlineInputBorder(),
                                  labelText: 'Collection name',
                                ),
                                // The validator receives the text that the user has entered.
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter the collection name.';
                                  }
                                  // if value exists in collectionsData.collections.name
                                  // return 'Collection name already exists.';
                                  if (collectionsData.collections
                                      .any((collection) => collection.name == value)) {
                                    return 'Collection name already exists.';
                                  }

                                  return null;
                                },
                                onSaved: (value) {
                                  _songPresentInCollection.add(false);
                                  int nextId =
                                      getAvailableId(collectionsData.collections);

                                  var collection = Collection(
                                    id: nextId,
                                    name: value!,
                                    dateCreated: DateTime.now().toString(),
                                  );
                                  collectionsData.addCollection(collection);
                                  initializeSongCollections(collectionsData);
                                },
                              ),
                            ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  int getAvailableId(list) {
    int nextId = 0;
    if (list.isEmpty) {
      nextId = 1;
    } else {
      // iterate through list ids and find the smallest available number
      var ids = list.map((item) => item.id).toList();
      ids.sort();
      for (var i = 0; i < ids.length; i++) {
        if (ids[i] != i + 1) {
          nextId = i + 1;
          break;
        }
        nextId = i + 2;
      }
    }
    return nextId;
  }

  void initializeSongCollections(collectionsData) {
    _songPresentInCollection.clear();
    var collectionSongs = collectionsData.collectionSongs;
    // for each collection, check if any collectionSong has the songTitle and add true or false to _songPresentInCollection
    for (var collection in collectionsData.collections) {
      if (collectionSongs.any((collectionSong) =>
          collectionSong.collectionId == collection.id &&
          collectionSong.title == songTitle)) {
        _songPresentInCollection.add(true);
      } else {
        _songPresentInCollection.add(false);
      }
    }
  }

  Future<void> settingsBottomSheet(context) {
    return showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width < 600
            ? MediaQuery.of(context).size.width
            : MediaQuery.of(context).size.width * 0.6,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15.0),
          topRight: Radius.circular(15.0),
        ),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 50),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Font Size:'),
                  Consumer<SongSettings>(
                    builder: (context, songSettings, child) => Slider(
                      value: songSettings.fontSize,
                      min: 14,
                      max: 38,
                      divisions: 6,
                      label: songSettings.fontSize.round().toString(),
                      onChanged: (double value) {
                        var songSettings = context.read<SongSettings>();
                        songSettings.setFontSize(value);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Display Song Key:'),
                  Consumer<SongSettings>(
                    builder: (context, songSettings, child) => Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ChoiceChip(
                          label: const Text('     Yes     '),
                          selected: songSettings.displayKey == true,
                          onSelected: (bool selected) async {
                            var songSettings = context.read<SongSettings>();
                            songSettings.setDisplayKey(true);
                          },
                        ),
                        const SizedBox(width: 20),
                        ChoiceChip(
                          label: const Text('     No     '),
                          selected: songSettings.displayKey == false,
                          onSelected: (bool selected) async {
                            var songSettings = context.read<SongSettings>();
                            songSettings.setDisplayKey(false);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Options:'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        style: ButtonStyle(
                          foregroundColor:
                              MaterialStateColor.resolveWith((states) => Colors.white),
                          backgroundColor: MaterialStateColor.resolveWith(
                              (states) => Styles.themeColor),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          var titleWithoutNumber = songTitle.split('.').last.trim();
                          Clipboard.setData(
                                  ClipboardData(text: '$titleWithoutNumber\n\n$songText'))
                              .then((_) {});
                        },
                        child: const Text('Copy Song'),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        style: ButtonStyle(
                          foregroundColor:
                              MaterialStateColor.resolveWith((states) => Colors.white),
                          backgroundColor: MaterialStateColor.resolveWith(
                              (states) => Styles.themeColor),
                        ),
                        onPressed: () {
                          // get text after full stop from song title
                          var titleWithoutNumber = songTitle.split('.').last.trim();
                          Share.share('$titleWithoutNumber\n\n$songText');
                        },
                        child: const Text('Share Song'),
                      ),
                    ],
                  )
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
