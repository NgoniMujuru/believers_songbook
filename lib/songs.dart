import 'package:believers_songbook/providers/song_book_settings.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';

import 'search_bar.dart';
import 'styles.dart';
import 'song.dart';
import '/models/song_search_result.dart';
import 'package:alphabet_scroll_view/alphabet_scroll_view.dart';
import '/models/song_sort_order.dart';
import 'package:provider/provider.dart';

class Songs extends StatefulWidget {
  const Songs({Key? key}) : super(key: key);

  @override
  _SongsState createState() {
    return _SongsState();
  }
}

class _SongsState extends State<Songs> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String _terms = '';
  SortOrder? _sortBy = SortOrder.alphabetic;
  Expanded _songList = const Expanded(
    child: Center(
      child: Text('Loading...'),
    ),
  );
  List<List<dynamic>>? _csvData;
  final int _searchThreshold = 75;
  final int _minSearchResults = 5;

  @override
  void initState() {
    print('initState Songs');
    super.initState();
    _controller = TextEditingController()..addListener(_onTextChanged);
    _focusNode = FocusNode();
    processCsv();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _terms = _controller.text;
    });
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: SearchBar(
        controller: _controller,
        focusNode: _focusNode,
      ),
    );
  }

  void processCsv() async {
    var result = await DefaultAssetBundle.of(context).loadString(
      context.read<SongBookSettings>().songBookPath,
    );
    var results = const CsvToListConverter().convert(result, fieldDelimiter: ';');
    if (_sortBy == SortOrder.alphabetic) {
      results.sort(
          (a, b) => a.elementAt(1).toLowerCase().compareTo(b.elementAt(1).toLowerCase()));
    }
    setState(() {
      _csvData = results;
    });
  }

  List? filterSongs() {
    if (_terms.isEmpty) {
      return _csvData;
    }

    var songSearchResults = [];
    double searchScore;

    String processedSearchTerm = _terms.toLowerCase();
    String processedSongTitle;

    _csvData?.forEach((element) {
      processedSongTitle = _sortBy == SortOrder.alphabetic
          ? element.elementAt(1).toLowerCase()
          : '${element.elementAt(0)} ${element.elementAt(1).toLowerCase()}';
      // search on song titles 1st
      searchScore = partialRatio(processedSongTitle, processedSearchTerm).toDouble();
      if (searchScore > _searchThreshold) {
        songSearchResults.add(SongSearchResult(element, searchScore));
      }
    });

    // search on song text if not enough results
    if (songSearchResults.length < _minSearchResults) {
      _csvData?.forEach((element) {
        searchScore =
            tokenSetPartialRatio(element.elementAt(3).toLowerCase(), processedSearchTerm)
                .toDouble();
        if (searchScore > _searchThreshold) {
          // divide by 10 to make the score less powerful than the title search
          songSearchResults.add(SongSearchResult(element, searchScore / 10));
        }
      });
    }

    songSearchResults.sort((a, b) => b.score.compareTo(a.score));
    var results = [];
    for (var songSearchResult in songSearchResults) {
      results.add(songSearchResult.song);
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    // rebuilt widget when song book settings change
    context.watch<SongBookSettings>();
    var results = filterSongs();
    _songList = _sortBy == SortOrder.alphabetic
        ? _buildAlphabeticList(results ?? [])
        : _buildNumericList(results ?? []);

    return Scaffold(
      appBar: AppBar(
          title: const Text('Songs'),
          shadowColor: Styles.themeColor,
          scrolledUnderElevation: 4,
          actions: <Widget>[
            IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  buildBottomSheet();
                }),
          ]),
      body: DecoratedBox(
        decoration: const BoxDecoration(
            // color: Styles.scaffoldBackground,
            ),
        child: SafeArea(
          child: Column(
            children: [_buildSearchBox(), _songList],
          ),
        ),
      ),
    );
  }

  buildBottomSheet() {
    return showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setLocalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 50),
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sort Order:'),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ChoiceChip(
                              label: const Text('Alphabetical'),
                              selected: _sortBy == SortOrder.alphabetic,
                              onSelected: (bool selected) {
                                _csvData?.sort((a, b) => a
                                    .elementAt(1)
                                    .toLowerCase()
                                    .compareTo(b.elementAt(1).toLowerCase()));
                                setState(() {
                                  _sortBy = SortOrder.alphabetic;
                                });
                                setLocalState(() {
                                  _sortBy = SortOrder.alphabetic;
                                });
                              }),
                          const SizedBox(width: 20),
                          ChoiceChip(
                            label: const Text('Numerical'),
                            selected: _sortBy == SortOrder.numerical,
                            onSelected: (bool selected) {
                              _csvData?.sort(
                                  (a, b) => a.elementAt(0).compareTo(b.elementAt(0)));
                              setState(() {
                                _sortBy = SortOrder.numerical;
                              });
                              setLocalState(() {
                                _sortBy = SortOrder.numerical;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Expanded _buildAlphabeticList(results) {
    return Expanded(
      child: AlphabetScrollView(
        list: results.map<AlphaModel>((e) => AlphaModel(e.elementAt(1))).toList(),
        alignment: LetterAlignment.right,
        itemExtent: 60,
        unselectedTextStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black),
        selectedTextStyle: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w800, color: Styles.themeColor),
        overlayWidget: (value) => Container(
          height: 100,
          width: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Styles.themeColor.withOpacity(0.6),
          ),
          alignment: Alignment.center,
          child: Text(
            value.toUpperCase(),
            style: const TextStyle(
                fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        itemBuilder: (context, index, id) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 40, 0),
            child: Column(
              children: [
                Flexible(
                  child: GestureDetector(
                    onTap: () {
                      _focusNode.unfocus();
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Song(
                                  songText: results!.elementAt(index).elementAt(3),
                                  songTitle:
                                      '${results!.elementAt(index).elementAt(1)}')));
                    },
                    child: ListTile(
                      title: Text(
                        results == null
                            ? 'Loading'
                            : '${results!.elementAt(index).elementAt(1)}',
                      ),
                    ),
                  ),
                ),
                const Divider(
                  height: 5,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Expanded _buildNumericList(results) {
    return Expanded(
      child: Scrollbar(
        thickness: 10.0,
        child: ListView.builder(
          itemBuilder: (context, index) => Column(
            children: [
              GestureDetector(
                onTap: () {
                  _focusNode.unfocus();
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Song(
                              songText: results!.elementAt(index).elementAt(3),
                              songTitle:
                                  '${results!.elementAt(index).elementAt(0)}. ${results!.elementAt(index).elementAt(1)}')));
                },
                child: ListTile(
                  title: Text(results == null
                      ? 'Loading'
                      : '${results!.elementAt(index).elementAt(0)}. ${results!.elementAt(index).elementAt(1)}'),
                ),
              ),
              const Divider(
                height: 0.5,
              ),
            ],
          ),
          itemCount: results == null ? 0 : results!.length,
        ),
      ),
    );
  }
}
