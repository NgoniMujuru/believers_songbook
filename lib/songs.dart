import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';

import 'search_bar.dart';
import 'styles.dart';
import 'song.dart';
import '/models/song_search_result.dart';
import 'package:alphabet_scroll_view/alphabet_scroll_view.dart';

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
  List<List<dynamic>>? _csvData;
  final int _searchThreshold = 75;
  final int _minSearchResults = 5;

  @override
  void initState() {
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
      "assets/Songs.csv",
    );
    var results = const CsvToListConverter().convert(result, fieldDelimiter: ';');
    results.sort(
        (a, b) => a.elementAt(1).toLowerCase().compareTo(b.elementAt(1).toLowerCase()));
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

    _csvData?.forEach((element) {
      // search on song titles 1st
      searchScore = partialRatio(element.elementAt(1).toLowerCase(), _terms.toLowerCase())
          .toDouble();
      if (searchScore > _searchThreshold) {
        songSearchResults.add(SongSearchResult(element, searchScore));
      }
    });

    // search on song text if not enough results
    if (songSearchResults.length < _minSearchResults) {
      _csvData?.forEach((element) {
        searchScore =
            tokenSetPartialRatio(element.elementAt(3).toLowerCase(), _terms.toLowerCase())
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
    var results = filterSongs();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Songs'),
        backgroundColor: Styles.themeColor,
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          color: Styles.scaffoldBackground,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildSearchBox(),
              _buildSongList(results ?? []),
            ],
          ),
        ),
      ),
    );
  }

  Expanded _buildSongList(List<dynamic> results) {
    return Expanded(
      child: AlphabetScrollView(
        list: results.map((e) => AlphaModel(e.elementAt(1))).toList(),
        alignment: LetterAlignment.right,
        itemExtent: 60,
        unselectedTextStyle: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
        selectedTextStyle: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w800, color: Styles.themeColor),
        overlayWidget: (value) => Container(
          height: 100,
          width: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.5),
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
                                      // '${results!.elementAt(index).elementAt(0)}. ${results!.elementAt(index).elementAt(1)}')));
                                      '${results!.elementAt(index).elementAt(1)}')));
                    },
                    child: ListTile(
                      title: Text(
                          results == null
                              ? 'Loading'
                              // : '${results!.elementAt(index).elementAt(0)}. ${results!.elementAt(index).elementAt(1)}'),
                              : '${results!.elementAt(index).elementAt(1)}',
                          style: const TextStyle(fontSize: 18)),
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
}
