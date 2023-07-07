import 'package:believers_songbook/providers/song_book_settings.dart';
import 'package:believers_songbook/providers/theme_settings.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'search_bar.dart';
import 'styles.dart';
import 'song.dart';
import '/models/song_search_result.dart';
import 'package:alphabet_scroll_view/alphabet_scroll_view.dart';
import '/models/song_sort_order.dart';
import 'package:provider/provider.dart';
import 'constants/song_book_assets.dart';

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
  SearchBy? _searchBy;
  Expanded _songList = const Expanded(
    child: Center(
      child: Text('Loading...'),
    ),
  );
  List<List<dynamic>>? _csvData = [];
  bool _loadingSongs = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()..addListener(_onTextChanged);
    _focusNode = FocusNode();
    SharedPreferences.getInstance().then((prefs) {
      final songBookSettings = context.read<SongBookSettings>();
      songBookSettings.setSongBookFile(prefs.getString('songBookFile') ?? 'All');

      if (prefs.getString('sortOrder') == 'alphabetic') {
        _sortBy = SortOrder.alphabetic;
      } else {
        _sortBy = SortOrder.numerical;
      }

      if (prefs.getString('searchBy') == 'title') {
        _searchBy = SearchBy.title;
      } else if (prefs.getString('searchBy') == 'lyrics') {
        _searchBy = SearchBy.lyrics;
      } else {
        _searchBy = SearchBy.both;
      }

      _fileName = context.read<SongBookSettings>().songBookFile;
      setState(() {
        _loadingSongs = false;
      });
      processSongBook();

      // Use the following code anytime a new songbook is added.
      // if (_fileName == 'All') {
      //   processAllSongBooks();
      // } else {
      //   setState(() {
      //     _loadingSongs = false;
      //   });
      //   processSongBook();
      // }
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

  void processSongBook() async {
    _fileName = context.read<SongBookSettings>().songBookFile;
    var fileData = await DefaultAssetBundle.of(context).loadString(
      'assets/$_fileName.csv',
    );

    var songList = createSongList(_fileName, fileData);
    if (_sortBy == SortOrder.alphabetic) {
      songList.sort(
          (a, b) => a.elementAt(1).toLowerCase().compareTo(b.elementAt(1).toLowerCase()));
    } else {
      songList.sort((a, b) => a.elementAt(0) - b.elementAt(0));
    }
    setState(() {
      _csvData = songList;
    });
  }

  void processAllSongBooks() async {
    for (var songBook in SongBookAssets.songList) {
      if (songBook['FileName'] == 'All') {
        continue;
      }
      _fileName = songBook['FileName'];
      String fileData = await DefaultAssetBundle.of(context).loadString(
        'assets/$_fileName.csv',
      );
      var songList = createSongList(_fileName, fileData);
      _csvData?.addAll(songList);
    }

    print(_csvData?.length ?? 0);

    _csvData?.sort(
        (a, b) => a.elementAt(1).toLowerCase().compareTo(b.elementAt(1).toLowerCase()));

    double searchScore = 0;
    double maxSimilarityScore = 90;

    for (int i = 0; i + 1 < (_csvData?.length ?? 0); i++) {
      var currentSong = _csvData?.elementAt(i);
      var nextSong = _csvData?.elementAt(i + 1);

      String processedSongTitle = currentSong!.elementAt(1).toString().toLowerCase();
      processedSongTitle = processedSongTitle.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      String processedNextSongTitle = nextSong!.elementAt(1).toString().toLowerCase();
      processedNextSongTitle =
          processedNextSongTitle.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      searchScore = ratio(processedSongTitle, processedNextSongTitle).toDouble();
      if (searchScore > maxSimilarityScore) {
        _csvData?.removeAt(i);
        i--;
      }
    }

    print(_csvData?.length ?? 0);

    if (_sortBy == SortOrder.numerical) {
      _csvData?.sort((a, b) => a.elementAt(0).compareTo(b.elementAt(0)));
    }
    String csv =
        const ListToCsvConverter(fieldDelimiter: ';', eol: '\n').convert(_csvData!);
    // Adds csv data to clipboard: copy and paste it over the contents of 'All.csv'
    Clipboard.setData(ClipboardData(text: csv)).then((_) {});

    setState(() {
      _csvData;
      _loadingSongs = false;
    });
  }

  List<List> createSongList(String fileName, String fileData) {
    // if more examples exist, map for each file
    String eol = fileName == 'ThirdExodusAssembly_Trinidad' ||
            fileName == 'KenyaLocalBelievers_Nairobi_Kenya' ||
            fileName == 'BibleTabernacle_CapeTown_SA' ||
            fileName == 'RevealedWordTabernacle_Bulawayo_Zimbabwe'
        ? '\r\n'
        : '\n';
    return const CsvToListConverter().convert(fileData, fieldDelimiter: ';', eol: eol);
  }

  final int _songSearchThreshold = 70;
  final int _maxSearchResults = 20;

  List? filterSongs() {
    if (_terms.isEmpty) {
      return _csvData;
    }

    List<SongSearchResult> songSearchResults = searchSongs(_searchBy);
    if (_searchBy == SearchBy.both) {
      List<SongSearchResult> potentialLyricsSearchResults = searchSongs(SearchBy.lyrics);
      if (potentialLyricsSearchResults.isNotEmpty) {
        for (var element in potentialLyricsSearchResults) {
          if (songDoesNotExist(element, songSearchResults)) {
            songSearchResults.add(element);
          }
        }
      }
    }
    songSearchResults.sort((a, b) => b.score.compareTo(a.score));

    List<dynamic> results = [];
    for (var i = 0; i < songSearchResults.length && i < _maxSearchResults; i++) {
      results.add(songSearchResults[i].song);
    }
    return results;
  }

  bool songDoesNotExist(element, results) {
    for (var songSearchResult in results) {
      if (songSearchResult.song.elementAt(0) == element.song.elementAt(0)) {
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
    if (_loadingSongs) {
      _songList = loadingSongbooks();
    } else {
      _songList = results?.length == 0
          ? noSearchSongsFound()
          : _sortBy == SortOrder.alphabetic
              ? _buildAlphabeticList(results ?? [])
              : _buildNumericList(results ?? []);
    }

    return SelectionArea(
      child: Scaffold(
        appBar: AppBar(
            title: const Text('Songs'),
            // shadowColor: Styles.themeColor,
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
      ),
    );
  }

  buildBottomSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
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
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ChoiceChip(
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      label: const Text('    Light    '),
                                      selected: !themeSettings.isDarkMode,
                                      onSelected: (bool selected) async {
                                        var themeSettings = context.read<ThemeSettings>();
                                        themeSettings.setIsDarkMode(false);
                                      }),
                                  const SizedBox(width: 20),
                                  ChoiceChip(
                                      label: const Text('      Dark      '),
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
                        mainAxisAlignment: MainAxisAlignment.end,
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
                      const SizedBox(height: 10),
                      const Text('Search Songs By:'),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ChoiceChip(
                              label: const Text('Both'),
                              selected: _searchBy == SearchBy.both,
                              onSelected: (bool selected) async {
                                setState(() {
                                  _searchBy = SearchBy.both;
                                });
                                setLocalState(() {
                                  _searchBy = SearchBy.both;
                                });
                                final Future<SharedPreferences> prefsRef =
                                    SharedPreferences.getInstance();
                                final SharedPreferences prefs = await prefsRef;
                                prefs.setString('searchBy', SearchBy.both.name);
                              }),
                          const SizedBox(width: 20),
                          ChoiceChip(
                            label: const Text('Title'),
                            selected: _searchBy == SearchBy.title,
                            onSelected: (bool selected) async {
                              setState(() {
                                _searchBy = SearchBy.title;
                              });
                              setLocalState(() {
                                _searchBy = SearchBy.title;
                              });
                              final Future<SharedPreferences> prefsRef =
                                  SharedPreferences.getInstance();
                              final SharedPreferences prefs = await prefsRef;
                              prefs.setString('searchBy', SearchBy.title.name);
                            },
                          ),
                          const SizedBox(width: 20),
                          ChoiceChip(
                              label: const Text('Lyrics'),
                              selected: _searchBy == SearchBy.lyrics,
                              onSelected: (bool selected) async {
                                setState(() {
                                  _searchBy = SearchBy.lyrics;
                                });
                                setLocalState(() {
                                  _searchBy = SearchBy.lyrics;
                                });
                                final Future<SharedPreferences> prefsRef =
                                    SharedPreferences.getInstance();
                                final SharedPreferences prefs = await prefsRef;
                                prefs.setString('searchBy', SearchBy.lyrics.name);
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
      child: Consumer<ThemeSettings>(
          builder: (context, themeSettings, child) => ((AlphabetScrollView(
                list: results.map<AlphaModel>((e) => AlphaModel(e.elementAt(1))).toList(),
                alignment: LetterAlignment.right,
                itemExtent: 60,
                unselectedTextStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: themeSettings.isDarkMode ? Colors.white : Colors.black),
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
                                          songText:
                                              results!.elementAt(index).elementAt(3),
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
              )))),
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

  Expanded loadingSongbooks() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            //loading icon
            Icon(
              Icons.hourglass_bottom,
              size: 200,
              color: Colors.grey,
            ),

            SizedBox(
              height: 20,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(40.0, 0, 40.0, 0),
              child: Text(
                'Loading songs. Please be patient, this can take a bit of time.',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w500, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<SongSearchResult> searchSongs(SearchBy? criteria) {
    int elementPos;
    if (criteria == SearchBy.lyrics) {
      elementPos = 3;
    } else {
      elementPos = 1;
    }

    List<SongSearchResult> songSearchResults = [];
    double searchScore;

    String processedSearchTerm = _terms.toLowerCase();
    String processedSongTitle;

    _csvData?.forEach((element) {
      processedSongTitle = _sortBy == SortOrder.alphabetic
          ? element.elementAt(elementPos).toLowerCase()
          : '${element.elementAt(0)} ${element.elementAt(elementPos).toLowerCase()}';
      searchScore = partialRatio(processedSongTitle, processedSearchTerm).toDouble();
      if (searchScore > _songSearchThreshold) {
        songSearchResults.add(SongSearchResult(element, searchScore));
      }
    });
    return songSearchResults;
  }
}
