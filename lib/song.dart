import 'package:believers_songbook/main.dart';
import 'package:believers_songbook/models/collection_song.dart';
import 'package:believers_songbook/providers/collections_data.dart';
import 'package:believers_songbook/providers/main_page_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'models/collection.dart';
import 'styles.dart';
import 'package:provider/provider.dart';
import 'providers/song_settings.dart';
import 'package:believers_songbook/l10n/app_localizations.dart';

class Song extends StatefulWidget {
  final String songTitle;
  final String songText;
  final String songKey;
  final bool isCollectionSong;

  const Song({
    required this.songText,
    required this.songTitle,
    required this.songKey,
    required this.isCollectionSong,
    Key? key,
  }) : super(key: key);

  @override
  State<Song> createState() => _SongState();
}

class _SongState extends State<Song> {
  bool _isSelectingCollection = true;
  bool _isEditingSong = false;
  final _editSongFormKey = GlobalKey<FormState>();
  late String _lyrics = widget.songText;
  late String _key = widget.songKey;

  @override
  Widget build(BuildContext context) {
    final screenSize = Provider.of<ScreenSize>(context);
    return SelectionArea(
      child: Scaffold(
        appBar: AppBar(
            title: Text(widget.songTitle),
            shadowColor: Styles.themeColor,
            scrolledUnderElevation: 4,
            actions: <Widget>[
              IconButton(
                  icon: const Icon(Icons.playlist_add),
                  onPressed: () {
                    collectionsBottomSheet(context, screenSize);
                  }),
              IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    settingsBottomSheet(context,screenSize);
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
                    Consumer<SongSettings>(
                        builder: (context, songSettings, child) {
                      return Padding(
                        padding: screenSize.screenWidth > 600
                            ? const EdgeInsets.fromLTRB(80, 20, 16, 40)
                            : const EdgeInsets.fromLTRB(16, 20, 16, 40),
                        child: _isEditingSong
                            ? editSongForm()
                            : Column(
                                children: [
                                  if (songSettings.displayKey)
                                    Text(_key == '' ? '---' : _key,
                                        style: TextStyle(
                                            fontSize: songSettings.fontSize,
                                            fontWeight: FontWeight.bold))
                                  else
                                    const SizedBox(),
                                  SelectableText(_lyrics,
                                      style: TextStyle(
                                          fontSize: songSettings.fontSize)),
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
        floatingActionButton: _isEditingSong
            ? FloatingActionButton(
                onPressed: () {
                  var collectionsData =
                      Provider.of<CollectionsData>(context, listen: false);

                  if (_editSongFormKey.currentState!.validate()) {
                    //save form
                    _editSongFormKey.currentState!.save();
                    var collectionSongs = collectionsData.collectionSongs;
                    List<int> collectionSongsIds = [];
                    for (int i = 0; i < collectionSongs.length; i++) {
                      CollectionSong collectionSong = collectionSongs[i];
                      if (collectionSong.title == widget.songTitle) {
                        collectionSongsIds.add(collectionSong.id);
                      }
                    }
                    collectionsData.updateCollectionSongs(
                        collectionSongsIds, _lyrics, _key);
                    const Duration duration = Duration(seconds: 2);
                    var snackBar = SnackBar(
                      content: Text(AppLocalizations.of(context)!
                          .songPageSongSuccessfulUpdateSnackbar),
                      duration: duration,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    setState(() {
                      _isEditingSong = false;
                      _lyrics = _lyrics;
                      _key = _key;
                    });
                  }
                },
                child: const Icon(Icons.save),
              )
            : null,
      ),
    );
  }

  Form editSongForm() {
    return Form(
      key: _editSongFormKey,
      child: Column(
        children: [
          TextFormField(
            decoration: InputDecoration(
              border: const UnderlineInputBorder(),
              labelText: AppLocalizations.of(context)!.songPageEditKeyLabel,
            ),
            initialValue: _key,
            // The validator receives the text that the user has entered.
            validator: (value) {
              if (value == null || value.isEmpty) {
                return null;
              }

              // strip value of sql injection characters: minimal
              value = value.replaceAll(RegExp(r'[;\%*]'), '');
              if (value.isEmpty) {
                return AppLocalizations.of(context)!.songPageEditKeyError;
              }

              return null;
            },
            onSaved: (value) => _key = value!,
          ),
          TextFormField(
            decoration: InputDecoration(
              border: const UnderlineInputBorder(),
              labelText: AppLocalizations.of(context)!.songPageEditLyricsLabel,
            ),
            initialValue: _lyrics,
            maxLines: null,
            // The validator receives the text that the user has entered.
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context)!
                    .songPageEditLyricsInstruction;
              }

              // strip value of sql injection characters: minimal
              value = value.replaceAll(RegExp(r'[;\%*]'), '');
              if (value.isEmpty) {
                return AppLocalizations.of(context)!.songPageEditLyricsError;
              }

              return null;
            },
            onSaved: (value) => _lyrics = value!,
          ),
        ],
      ),
    );
  }

  final _collectionsFormKey = GlobalKey<FormState>();

  final List<bool> _songPresentInCollection = [];

  Future<void> collectionsBottomSheet(context, screenSize) {
    var collectionsData = Provider.of<CollectionsData>(context, listen: false);

    initializeSongCollections(collectionsData);

    return showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      constraints: BoxConstraints(
          maxWidth: screenSize.screenWidth < 600
              ? screenSize.screenWidth
              : screenSize.screenWidth * 0.6,
          maxHeight: screenSize.screenHeight * 0.7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15.0),
          topRight: Radius.circular(15.0),
        ),
      ),
      builder: screenSize.screenWidth < 600
          ? (BuildContext context) => Scaffold(
                body: collectionsModalContent(context,screenSize),
              )
          : (BuildContext context) => collectionsModalContent(context, screenSize),
    );
  }

  StatefulBuilder collectionsModalContent(context,screenSize) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setLocalState) {
        return Consumer<MainPageSettings>(
            builder: (context, mainPageSettings, child) =>
                (Localizations.override(
                    context: context,
                    locale: Locale(mainPageSettings.getLocale),
                    child: Consumer<MainPageSettings>(
                        builder: (context, mainPageSettings, child) => (Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(10, 10, 10, 0),
                              child: Consumer<CollectionsData>(
                                builder: (context, collectionsData, child) =>
                                    Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
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
                                                    _isSelectingCollection =
                                                        true;
                                                  });
                                                },
                                                icon: const Icon(
                                                    Icons.arrow_back),
                                              ),
                                        Text(
                                            AppLocalizations.of(context)!
                                                .globalCollections,
                                            style: TextStyle(fontSize: 25)),
                                        TextButton(
                                          onPressed: () {
                                            if (!_isSelectingCollection) {
                                              if (_collectionsFormKey
                                                  .currentState!
                                                  .validate()) {
                                                //save form
                                                _collectionsFormKey
                                                    .currentState!
                                                    .save();

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
                                              Icon(_isSelectingCollection
                                                  ? Icons.add
                                                  : Icons.check),
                                              Text(
                                                  _isSelectingCollection
                                                      ? AppLocalizations.of(
                                                              context)!
                                                          .songPageCreate
                                                      : AppLocalizations.of(
                                                              context)!
                                                          .songPageSave,
                                                  style: const TextStyle(
                                                      fontSize: 15)),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                    const Divider(),
                                    Expanded(
                                      child: _isSelectingCollection
                                          ? listCollections(collectionsData, setLocalState, context,screenSize)
                                          : createNewCollection(context, collectionsData),
                                    ),
                                  ],
                                ),
                              ),
                            ))))));
      },
    );
  }

  RawScrollbar listCollections(CollectionsData collectionsData,
      StateSetter setLocalState, BuildContext context,screenSize) {
    return RawScrollbar(
      minThumbLength: MediaQuery.of(context).size.width > 600 ? 100 : 40,
      thickness: MediaQuery.of(context).size.width > 600 ? 20 : 10.0,
      radius: const Radius.circular(5.0),
      thumbVisibility: true,
      trackVisibility: true,
      thumbColor: Colors.grey.withOpacity(0.5),
      trackColor: Colors.grey.withOpacity(0.1),
       
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
        shrinkWrap: true,
        itemCount: collectionsData.collections.length,
        itemBuilder: (BuildContext context, int index) {
          return Column(
            children: [
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(collectionsData.collections[index].name),
                value: _songPresentInCollection[index],
                onChanged: (bool? value) {
                  String collectionName = collectionsData.collections[index].name;
                  if (value == true) {
                    createCollectionSnackBar(
                        AppLocalizations.of(context)!.songPageAddedToSnackbar,
                        collectionName,screenSize);
                    CollectionSong collectionSong = CollectionSong(
                      id: getAvailableId(collectionsData.collectionSongs),
                      collectionId: collectionsData.collections[index].id,
                      title: widget.songTitle,
                      key: widget.songKey,
                      lyrics: widget.songText,
                      songPosition: collectionsData.collectionSongs.length,
                    );
                    collectionsData.addCollectionSong(
                      collectionSong,
                    );
                  } else {
                    createCollectionSnackBar(
                        AppLocalizations.of(context)!.songPageRemovedFromSnackbar,
                        collectionName,
                        screenSize);
                    // get collectionSongId based on title and collectionId
                    var collectionSongId = collectionsData.collectionSongs
                        .firstWhere((collectionSong) =>
                            collectionSong.collectionId ==
                                collectionsData.collections[index].id &&
                            collectionSong.title == widget.songTitle)
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
      ),
    );
  }

  Form createNewCollection(
      BuildContext context, CollectionsData collectionsData) {
        final FocusNode focusNode = FocusNode();

    // Request focus after the widget tree has been built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });

    return Form(
      key: _collectionsFormKey,
      child: TextFormField(
        focusNode: focusNode,
        decoration: InputDecoration(
            border: const UnderlineInputBorder(), labelText: AppLocalizations.of(context)!.songPageCollectionNameLabel,
            ),
        // The validator receives the text that the user has entered.
        validator: (value) {
          if (value == null || value.isEmpty) {
            return AppLocalizations.of(context)!
                .songPageCollectionNameInstruction;
          }
          // if value exists in collectionsData.collections.name
          // return 'Collection name already exists.';
          if (collectionsData.collections
              .any((collection) => collection.name == value)) {
            return AppLocalizations.of(context)!.songPageCollectionNameError;
          }

          return null;
        },
        onSaved: (value) {
          _songPresentInCollection.add(false);
          int nextId = getAvailableId(collectionsData.collections);

          var collection = Collection(
            id: nextId,
            name: value!,
            dateCreated: DateTime.now().toString(),
          );
          collectionsData.addCollection(collection);
          initializeSongCollections(collectionsData);
        },
      ),
    );
  }

  void createCollectionSnackBar(String action, collectionName,screenSize) {
    const Duration duration = Duration(seconds: 1);
    final snackBar = screenSize.screenWidth > 600
        ? SnackBar(
            content: Text(
                '${AppLocalizations.of(context)!.globalSong} $action $collectionName.'),
            margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height * 0.7),
            behavior: SnackBarBehavior.floating,
            duration: duration)
        : SnackBar(
            content: Text(
                '${AppLocalizations.of(context)!.globalSong} $action $collectionName.'),
            duration: duration,
          );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
          collectionSong.title == widget.songTitle)) {
        _songPresentInCollection.add(true);
      } else {
        _songPresentInCollection.add(false);
      }
    }
  }

  Future<void> settingsBottomSheet(context,screenSize) {
    return showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      constraints: BoxConstraints(
        maxWidth: screenSize.screenWidth < 600
            ? screenSize.screenWidth
            : screenSize.screenWidth * 0.6,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15.0),
          topRight: Radius.circular(15.0),
        ),
      ),
      builder: (BuildContext context) {
        return Consumer<MainPageSettings>(
            builder: (context, mainPageSettings, child) =>
                (Localizations.override(
                    context: context,
                    locale: Locale(mainPageSettings.getLocale),
                    child: Consumer<MainPageSettings>(
                        builder: (context, mainPageSettings, child) => (Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 30, 20, 50),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(AppLocalizations.of(context)!
                                          .songPageFontSize),
                                      Consumer<SongSettings>(
                                        builder:
                                            (context, songSettings, child) =>
                                                Slider(
                                          value: songSettings.fontSize,
                                          min: 14,
                                          max: 38,
                                          divisions: 6,
                                          label: songSettings.fontSize
                                              .round()
                                              .toString(),
                                          onChanged: (double value) {
                                            var songSettings =
                                                context.read<SongSettings>();
                                            songSettings.setFontSize(value);
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(AppLocalizations.of(context)!
                                          .globalDisplaySongKey),
                                      Consumer<SongSettings>(
                                        builder:
                                            (context, songSettings, child) =>
                                                Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            ChoiceChip(
                                              label: Text(
                                                  AppLocalizations.of(context)!
                                                      .globalDisplaySongKeyYes),
                                              selected:
                                                  songSettings.displayKey ==
                                                      true,
                                              onSelected:
                                                  (bool selected) async {
                                                var songSettings = context
                                                    .read<SongSettings>();
                                                songSettings
                                                    .setDisplayKey(true);
                                              },
                                            ),
                                            const SizedBox(width: 20),
                                            ChoiceChip(
                                              label: Text(
                                                  AppLocalizations.of(context)!
                                                      .globalDisplaySongKeyNo),
                                              selected:
                                                  songSettings.displayKey ==
                                                      false,
                                              onSelected:
                                                  (bool selected) async {
                                                var songSettings = context
                                                    .read<SongSettings>();
                                                songSettings
                                                    .setDisplayKey(false);
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(AppLocalizations.of(context)!
                                          .songPageOptions),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          widget.isCollectionSong
                                              ? ElevatedButton(
                                                  style: ButtonStyle(
                                                    foregroundColor:
                                                        MaterialStateColor
                                                            .resolveWith(
                                                                (states) =>
                                                                    Colors
                                                                        .white),
                                                    backgroundColor:
                                                        MaterialStateColor
                                                            .resolveWith(
                                                                (states) => Styles
                                                                    .themeColor),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    setState(() {
                                                      _isEditingSong = true;
                                                    });
                                                  },
                                                  child: Text(
                                                      AppLocalizations.of(
                                                              context)!
                                                          .songPageOptionsEdit),
                                                )
                                              : const SizedBox(),
                                          const SizedBox(width: 20),
                                          ElevatedButton(
                                            style: ButtonStyle(
                                              foregroundColor:
                                                  MaterialStateColor
                                                      .resolveWith((states) =>
                                                          Colors.white),
                                              backgroundColor:
                                                  MaterialStateColor
                                                      .resolveWith((states) =>
                                                          Styles.themeColor),
                                            ),
                                            onPressed: () {
                                              Navigator.pop(context);
                                              var titleWithoutNumber = widget
                                                  .songTitle
                                                  .split('.')
                                                  .last
                                                  .trim();
                                              Clipboard.setData(ClipboardData(
                                                      text:
                                                          '$titleWithoutNumber\n\n${widget.songText}'))
                                                  .then((_) {});
                                            },
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .songPageOptionsCopy),
                                          ),
                                          const SizedBox(width: 20),
                                          ElevatedButton(
                                            style: ButtonStyle(
                                              foregroundColor:
                                                  MaterialStateColor
                                                      .resolveWith((states) =>
                                                          Colors.white),
                                              backgroundColor:
                                                  MaterialStateColor
                                                      .resolveWith((states) =>
                                                          Styles.themeColor),
                                            ),
                                            onPressed: () {
                                              // get text after full stop from song title
                                              var titleWithoutNumber = widget
                                                  .songTitle
                                                  .split('.')
                                                  .last
                                                  .trim();
                                              Share.share(
                                                  '$titleWithoutNumber\n\n${widget.songText}');
                                            },
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .songPageOptionsShare),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ))))));
      },
    );
  }
}
