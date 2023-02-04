import 'package:believers_songbook/providers/song_book_settings.dart';
import 'package:believers_songbook/providers/theme_settings.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String _fileName = '';
  String _terms = '';
  SortOrder? _sortBy;
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
    super.initState();
    _controller = TextEditingController()..addListener(_onTextChanged);
    _focusNode = FocusNode();
    SharedPreferences.getInstance().then((prefs) {
      final songBookSettings = context.read<SongBookSettings>();
      songBookSettings.setSongBookFile(
          prefs.getString('songBookFile') ?? 'HarareChristianFellowship_Harare_Zimbabwe');

      if (prefs.getString('sortOrder') == 'alphabetic') {
        _sortBy = SortOrder.alphabetic;
      } else {
        _sortBy = SortOrder.numerical;
      }

      processCsv();
    });
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
    _fileName = context.read<SongBookSettings>().songBookFile;
    var result = await DefaultAssetBundle.of(context).loadString(
      'assets/$_fileName.csv',
    );

    // if more examples exist, map for each file
    String eol = _fileName == 'ThirdExodusAssembly_Trinidad' ||
            _fileName == 'KenyaLocalBelievers_Nairobi_Kenya' ||
            _fileName == 'BibleTabernacle_CapeTown_SA'
        ? '\r\n'
        : '\n';
    var results =
        const CsvToListConverter().convert(result, fieldDelimiter: ';', eol: eol);
    if (_sortBy == SortOrder.alphabetic) {
      results.sort(
          (a, b) => a.elementAt(1).toLowerCase().compareTo(b.elementAt(1).toLowerCase()));
    } else {
      results.sort((a, b) => a.elementAt(0).compareTo(b.elementAt(0)));
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
        if (songDoesNotExist(element, songSearchResults)) {
          searchScore = tokenSetPartialRatio(
                  element.elementAt(3).toLowerCase(), processedSearchTerm)
              .toDouble();
          if (searchScore > _searchThreshold) {
            // divide by 10 to make the score less powerful than the title search
            songSearchResults.add(SongSearchResult(element, searchScore / 10));
          }
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

  bool songDoesNotExist(element, results) {
    for (var songSearchResult in results) {
      if (songSearchResult.song.elementAt(0) == element.elementAt(0)) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // rebuilt widget when song book settings change
    context.watch<SongBookSettings>();
    var results = filterSongs();
    _songList = results?.length == 0
        ? noSearchSongsFound()
        : _sortBy == SortOrder.alphabetic
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
          child: Padding(
            padding: MediaQuery.of(context).size.width > 600
                ? const EdgeInsets.fromLTRB(20, 0, 20, 0)
                : const EdgeInsets.all(0),
            child: Column(
              children: [_buildSearchBox(), _songList],
            ),
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
                      const Text('Theme:'),
                      Consumer<ThemeSettings>(
                          builder: (context, themeSettings, child) => (Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  ChoiceChip(
                                      label: const Text('Light'),
                                      selected: !themeSettings.isDarkMode,
                                      onSelected: (bool selected) async {
                                        var themeSettings = context.read<ThemeSettings>();
                                        themeSettings.setIsDarkMode(false);
                                      }),
                                  const SizedBox(width: 20),
                                  ChoiceChip(
                                      label: const Text('Dark'),
                                      selected: themeSettings.isDarkMode,
                                      onSelected: (bool selected) async {
                                        var themeSettings = context.read<ThemeSettings>();
                                        themeSettings.setIsDarkMode(true);
                                      }),
                                ],
                              ))),
                      const SizedBox(height: 10),
                      const Text('Sort Order:'),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ChoiceChip(
                            label: const Text('Numerical'),
                            selected: _sortBy == SortOrder.numerical,
                            onSelected: (bool selected) async {
                              _csvData?.sort(
                                  (a, b) => a.elementAt(0).compareTo(b.elementAt(0)));
                              setState(() {
                                _sortBy = SortOrder.numerical;
                              });
                              setLocalState(() {
                                _sortBy = SortOrder.numerical;
                              });
                              final Future<SharedPreferences> prefsRef =
                                  SharedPreferences.getInstance();
                              final SharedPreferences prefs = await prefsRef;
                              prefs.setString('sortOrder', SortOrder.numerical.name);
                            },
                          ),
                          const SizedBox(width: 20),
                          ChoiceChip(
                              label: const Text('Alphabetical'),
                              selected: _sortBy == SortOrder.alphabetic,
                              onSelected: (bool selected) async {
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
                                final Future<SharedPreferences> prefsRef =
                                    SharedPreferences.getInstance();
                                final SharedPreferences prefs = await prefsRef;
                                prefs.setString('sortOrder', SortOrder.alphabetic.name);
                              }),
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
                                  songKey: results!.elementAt(index).elementAt(2),
                                  songTitle:
                                      '${capitalizeFirstLetters(results!.elementAt(index).elementAt(1))}')));
                    },
                    child: ListTile(
                      title: Text(
                        results == null
                            ? 'Loading'
                            : '${capitalizeFirstLetters(results!.elementAt(index).elementAt(1))}',
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
                      _focusNode.unfocus();
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Song(
                                  songText: results!.elementAt(index).elementAt(3),
                                  songKey: results!.elementAt(index).elementAt(2),
                                  songTitle:
                                      '${results!.elementAt(index).elementAt(0)}. ${capitalizeFirstLetters(results!.elementAt(index).elementAt(1))}')));
                    },
                    child: ListTile(
                      title: Text(results == null
                          ? 'Loading'
                          : '${results!.elementAt(index).elementAt(0)}. ${capitalizeFirstLetters(results!.elementAt(index).elementAt(1))}'),
                    ),
                  ),
                  const Divider(
                    height: 0.5,
                  ),
                ],
              ),
            ),
            itemCount: results == null ? 0 : results!.length,
          ),
        ),
      ),
    );
  }

  capitalizeFirstLetters(String s) {
    return s
        .split(' ')
        .map((str) =>
            str.isEmpty ? str : str[0].toUpperCase() + str.substring(1).toLowerCase())
        .join(' ');
  }

  Expanded noSearchSongsFound() {
    String songbook = _fileName.split('_').first;
    songbook = songbook.replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'), (Match m) => '${m[1]} ${m[2]}');

    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 100,
              color: Colors.grey,
            ),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(40.0, 0, 40.0, 0),
              child: Text(
                'No songs found with words "$_terms" in $songbook Songbook.',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w500, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
