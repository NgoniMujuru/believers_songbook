import 'package:believers_songbook/models/collection.dart';
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

  Future<void> collectionsBottomSheet(context) {
    return showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
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
                    _isSelectingCollection
                        ? ListView.builder(
                            shrinkWrap: true,
                            itemCount: collectionsData.collections.length,
                            itemBuilder: (BuildContext context, int index) {
                              return Column(
                                children: [
                                  CheckboxListTile(
                                    title: Text(collectionsData.collections[index].name),
                                    value: true,
                                    onChanged: (bool? value) {
                                      setLocalState(() {
                                        value = true;
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
                                int nextId;
                                if (collectionsData.collections.isEmpty) {
                                  nextId = 1;
                                } else {
                                  nextId = collectionsData.collections
                                          .map((collection) => collection.id)
                                          .reduce((value, element) =>
                                              value > element ? value : element) +
                                      1;
                                }

                                var collection = Collection(
                                  id: nextId,
                                  name: value!,
                                  dateCreated: DateTime.now().toString(),
                                );
                                collectionsData.addCollection(collection);
                              },
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

  Future<void> settingsBottomSheet(context) {
    return showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
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
