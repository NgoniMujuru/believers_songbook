import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';

import 'search_bar.dart';
import 'styles.dart';
import 'song.dart';
import '/models/song_search_result.dart';

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
  List<List<dynamic>>? csvData;
  final int _searchThreshold = 75;
  final int _minSearchResults = 5;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()..addListener(_onTextChanged);
    _focusNode = FocusNode();
    processCsv();
    print('Testing fuzzy search');
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
    setState(() {
      csvData = const CsvToListConverter().convert(result, fieldDelimiter: ';');
    });
  }

  List? filterSongs() {
    if (_terms.isEmpty) {
      return csvData;
    }

    var songSearchResults = [];
    double searchScore;

    csvData?.forEach((element) {
      // search on song titles 1st
      searchScore = partialRatio(element.elementAt(1).toLowerCase(), _terms.toLowerCase())
          .toDouble();
      if (searchScore > _searchThreshold) {
        songSearchResults.add(SongSearchResult(element, searchScore));
      }
    });

    // search on song text if not enough results
    if (songSearchResults.length < _minSearchResults) {
      csvData?.forEach((element) {
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
              Expanded(
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
            ],
          ),
        ),
      ),
    );
  }
}
