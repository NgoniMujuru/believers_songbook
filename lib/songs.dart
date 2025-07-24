import 'dart:io';
import 'package:believers_songbook/providers/song_book_settings.dart';
import 'package:believers_songbook/providers/song_settings.dart';
import 'package:believers_songbook/providers/theme_settings.dart';
import 'package:believers_songbook/providers/main_page_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:alphabet_scroll_view/alphabet_scroll_view.dart';
import 'package:provider/provider.dart';

import 'custom_search_bar.dart';
import 'styles.dart';
import 'song.dart';
import '/models/song_search_result.dart';
import '/models/song_sort_order.dart';
import 'constants/song_book_assets.dart';
import 'dart:async';

class Songs extends StatefulWidget {
  const Songs({Key? key}) : super(key: key);

  @override
  SongsState createState() {
    return SongsState();
  }
}

class SongsState extends State<Songs> {
  late final TextEditingController _controller;
  Timer? _debounce;
  late final FocusNode _focusNode;
  String _fileName = '';
  String _terms = '';
  SortOrder? _sortBy;
  SearchBy? _searchBy;
  Expanded _songList = const Expanded(
    child: Center(
      child: Text('...'),
    ),
  );
  List<List<dynamic>>? _csvData = [];
  bool _loadingSongs = true;
  final int _shortDebounceTime = 200;
  final int _longDebounceTime = 600;
  late int _debounceTime;

  @override
  void initState() {
    super.initState();
    adjustDebounceTime();
    _controller = TextEditingController()..addListener(_onTextChanged);
    _focusNode = FocusNode();
    SharedPreferences.getInstance().then((prefs) {
      final songBookSettings = context.read<SongBookSettings>();
      songBookSettings.setSongBookFile(prefs.getString('songBookFile') ??
          'CityTabernacleBulawayo_Bulawayo_Zimbabwe');

      if (prefs.getString('sortOrder') == 'alphabetic') {
        _sortBy = SortOrder.alphabetic;
      } else {
        _sortBy = SortOrder.numerical;
      }

      if (prefs.getString('searchBy') == 'title') {
        _searchBy = SearchBy.title;
      } else if (prefs.getString('searchBy') == 'lyrics') {
        _searchBy = SearchBy.lyrics;
      } else if (prefs.getString('searchBy') == 'key') {
        _searchBy = SearchBy.key;
      } else {
        _searchBy = SearchBy.titleAndLyrics;
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
    _controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void adjustDebounceTime() async {
    bool isHighEnd = await isDeviceHighEnd();
    _debounceTime = isHighEnd
        ? _shortDebounceTime
        : _longDebounceTime; // Shorter for high-end, longer for low-end
  }

  void _onTextChanged() {
    // TODO:
    // 1. backspace slowdowns on lower end devices: investigate why. Consider not updating text if backspace.
    // 2. Implement a more efficient search algorithm!!!

    if (_debounce?.isActive ?? false) {
      _debounce?.cancel();
      if (_debounceTime == _longDebounceTime) {
        setState(() {
          _loadingSongs = true;
        });
      }
    }
    _debounce = Timer(Duration(milliseconds: _debounceTime), () {
      setState(() {
        _terms = _controller.text;
        _loadingSongs = false;
      });
    });
  }

  Future<bool> isDeviceHighEnd() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      int? sdkInt = androidInfo.version.sdkInt;
      // Assume newer Android devices are faster.
      // You could refine this by checking specific models in a predefined list.
      return sdkInt >= 31; // Android 12 or higher
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      String? model = iosInfo.utsname.machine;
      // Check if the model is relatively new or considered high-end.
      return model != null &&
          (model.contains("iPhone11,") || model.compareTo("iPhone11,") > 0);
    }
    return false;
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: CustomSearchBar(
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
      songList.sort((a, b) => customComparator(a.elementAt(1), b.elementAt(1)));
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

    if (kDebugMode) {
      if (_csvData == null) {
        print('CSV Data is null');
      } else {
        print('All songs before duplicate removal: ${_csvData!.length}');
      }
    }

    _csvData?.sort((a, b) => customComparator(a.elementAt(1), b.elementAt(1)));

    double searchScore = 0;
    double maxSimilarityScore = 90;

    for (int i = 0; i + 1 < (_csvData?.length ?? 0); i++) {
      var currentSong = _csvData?.elementAt(i);
      var nextSong = _csvData?.elementAt(i + 1);

      String processedSongTitle =
          currentSong!.elementAt(1).toString().toLowerCase();
      processedSongTitle =
          processedSongTitle.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      String processedNextSongTitle =
          nextSong!.elementAt(1).toString().toLowerCase();
      processedNextSongTitle =
          processedNextSongTitle.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      searchScore =
          ratio(processedSongTitle, processedNextSongTitle).toDouble();
      if (searchScore > maxSimilarityScore) {
        _csvData?.removeAt(i);
        i--;
      }
    }

    if (kDebugMode) {
      if (_csvData == null) {
        print('CSV Data is null');
      } else {
        print('All songs after duplicate removal: ${_csvData!.length}');
      }
    }

    // for each element in _csvData, add a number to it
    for (int i = 0; i < (_csvData?.length ?? 0); i++) {
      _csvData?[i][0] = i + 1;
    }

    String csv = const ListToCsvConverter(fieldDelimiter: ';', eol: '\n')
        .convert(_csvData!);
    // Adds csv data to clipboard: copy and paste it over the contents of 'All.csv'
    Clipboard.setData(ClipboardData(text: csv)).then((_) {});

    setState(() {
      _csvData;
      _loadingSongs = false;
    });
  }

  // Custom comparator that sorts strings by putting alphabets and numbers first, then special characters.
  int customComparator(String a, String b) {
    // Regular expression to match only alphabets and numbers
    RegExp alphaNum = RegExp(r'^[a-zA-Z0-9]');

    // Check if the first characters of a and b are alphanumeric
    bool isFirstAlphaNum = alphaNum.hasMatch(a);
    bool isSecondAlphaNum = alphaNum.hasMatch(b);

    // Prioritize strings starting with alphabetic or numeric characters
    if (isFirstAlphaNum && !isSecondAlphaNum) {
      return -1; // a comes before b
    } else if (!isFirstAlphaNum && isSecondAlphaNum) {
      return 1; // b comes before a
    }

    // If both are same type, compare normally
    return a.toLowerCase().compareTo(b.toLowerCase());
  }

  List<List> createSongList(String fileName, String fileData) {
    // if more examples exist, map for each file
    String eol = fileName == 'ThirdExodusAssembly_Trinidad' ||
            fileName == 'KenyaLocalBelievers_Nairobi_Kenya' ||
            fileName == 'BibleTabernacle_CapeTown_SA' ||
            fileName == 'HebronTabernacle_Lusaka_Zambia' ||
            fileName == "TokenTabernacle_Soweto_SA" ||
            fileName == 'RevealedWordTabernacle_Bulawayo_Zimbabwe' ||
            fileName == 'CityTabernacleBulawayo_Bulawayo_Zimbabwe' ||
            fileName == 'ChesilyotWordOfLifeTabernacle_BometCounty_Kenya'
        ? '\r\n'
        : '\n';
    return const CsvToListConverter()
        .convert(fileData, fieldDelimiter: ';', eol: eol);
  }

  final int _songSearchThreshold = 70;
  final int _maxSearchResults = 20;

  List? filterSongs() {
    if (_terms.isEmpty) {
      return _csvData;
    }

    List<dynamic> results = [];

    if (_searchBy == SearchBy.key) {
      for (var song in _csvData!) {
        if (song.elementAt(2).toString().toLowerCase().contains(_terms)) {
          results.add(song);
        }
      }
      return results;
    }

    List<SongSearchResult> songSearchResults = searchSongs(_searchBy);
    if (_searchBy == SearchBy.titleAndLyrics) {
      List<SongSearchResult> potentialLyricsSearchResults =
          searchSongs(SearchBy.lyrics);
      if (potentialLyricsSearchResults.isNotEmpty) {
        for (var element in potentialLyricsSearchResults) {
          if (songDoesNotExist(element, songSearchResults)) {
            songSearchResults.add(element);
          }
        }
      }
    }
    songSearchResults.sort((a, b) => b.score.compareTo(a.score));

    for (var i = 0;
        i < songSearchResults.length && i < _maxSearchResults;
        i++) {
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
      _songList = results!.isEmpty
          ? noSearchSongsFound()
          : _sortBy == SortOrder.alphabetic
              ? _buildAlphabeticList(results)
              : _buildNumericList(results);
    }

    return SelectionArea(
      child: Scaffold(
        appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.songsPageTitle),
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
            return Consumer<MainPageSettings>(
                builder: (context, mainPageSettings, child) =>
                    (Localizations.override(
                        context: context,
                        locale: Locale(mainPageSettings.getLocale),
                        child: Consumer<MainPageSettings>(
                          builder: (context, mainPageSettings, child) =>
                              (Padding(
                            padding: const EdgeInsets.fromLTRB(20, 30, 20, 50),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(AppLocalizations.of(context)!
                                        .globalThemeSetting),
                                    Consumer<ThemeSettings>(
                                        builder: (context, themeSettings,
                                                child) =>
                                            (Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                ChoiceChip(
                                                    materialTapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                    label: Text(AppLocalizations
                                                            .of(context)!
                                                        .globalThemeSettingLight),
                                                    selected: !themeSettings
                                                        .isDarkMode,
                                                    onSelected:
                                                        (bool selected) async {
                                                      var themeSettings =
                                                          context.read<
                                                              ThemeSettings>();
                                                      themeSettings
                                                          .setIsDarkMode(false);
                                                    }),
                                                const SizedBox(width: 20),
                                                ChoiceChip(
                                                    label: Text(AppLocalizations
                                                            .of(context)!
                                                        .globalThemeSettingDark),
                                                    selected: themeSettings
                                                        .isDarkMode,
                                                    onSelected:
                                                        (bool selected) async {
                                                      var themeSettings =
                                                          context.read<
                                                              ThemeSettings>();
                                                      themeSettings
                                                          .setIsDarkMode(true);
                                                    }),
                                              ],
                                            ))),
                                    const SizedBox(height: 10),
                                    Text(AppLocalizations.of(context)!
                                        .songsPageSortOrder),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ChoiceChip(
                                          label: Text(
                                              AppLocalizations.of(context)!
                                                  .songsPageSortOrderNumerical),
                                          selected:
                                              _sortBy == SortOrder.numerical,
                                          onSelected: (bool selected) async {
                                            _csvData?.sort((a, b) => a
                                                .elementAt(0)
                                                .compareTo(b.elementAt(0)));
                                            setState(() {
                                              _sortBy = SortOrder.numerical;
                                            });
                                            setLocalState(() {
                                              _sortBy = SortOrder.numerical;
                                            });
                                            final Future<SharedPreferences>
                                                prefsRef =
                                                SharedPreferences.getInstance();
                                            final SharedPreferences prefs =
                                                await prefsRef;
                                            prefs.setString('sortOrder',
                                                SortOrder.numerical.name);
                                          },
                                        ),
                                        const SizedBox(width: 20),
                                        ChoiceChip(
                                            label: Text(AppLocalizations.of(
                                                    context)!
                                                .songsPageSortOrderAlphabetic),
                                            selected:
                                                _sortBy == SortOrder.alphabetic,
                                            onSelected: (bool selected) async {
                                              _csvData?.sort((a, b) =>
                                                  customComparator(
                                                      a.elementAt(1),
                                                      b.elementAt(1)));
                                              setState(() {
                                                _sortBy = SortOrder.alphabetic;
                                              });
                                              setLocalState(() {
                                                _sortBy = SortOrder.alphabetic;
                                              });
                                              final Future<SharedPreferences>
                                                  prefsRef = SharedPreferences
                                                      .getInstance();
                                              final SharedPreferences prefs =
                                                  await prefsRef;
                                              prefs.setString('sortOrder',
                                                  SortOrder.alphabetic.name);
                                            }),
                                        const SizedBox(width: 20),
                                        ChoiceChip(
                                            label: Text(
                                                AppLocalizations.of(context)!
                                                    .songsPageSortOrderKey),
                                            selected: _sortBy == SortOrder.key,
                                            onSelected: (bool selected) async {
                                              _csvData?.sort((a, b) {
                                                int primary = customComparator(
                                                    a.elementAt(2),
                                                    b.elementAt(2));
                                                if (primary != 0)
                                                  return primary;
                                                return a
                                                    .elementAt(1)
                                                    .compareTo(b.elementAt(1));
                                              });
                                              setState(() {
                                                _sortBy = SortOrder.key;
                                              });
                                              setLocalState(() {
                                                _sortBy = SortOrder.key;
                                              });
                                              final Future<SharedPreferences>
                                                  prefsRef = SharedPreferences
                                                      .getInstance();
                                              final SharedPreferences prefs =
                                                  await prefsRef;
                                              prefs.setString('sortOrder',
                                                  SortOrder.key.name);
                                            }),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(AppLocalizations.of(context)!
                                        .globalDisplaySongKey),
                                    Consumer<SongSettings>(
                                      builder: (context, songSettings, child) =>
                                          Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          ChoiceChip(
                                            label: Text(
                                                AppLocalizations.of(context)!
                                                    .globalDisplaySongKeyYes),
                                            selected:
                                                songSettings.displayKey == true,
                                            onSelected: (bool selected) async {
                                              var songSettings =
                                                  context.read<SongSettings>();
                                              songSettings.setDisplayKey(true);
                                            },
                                          ),
                                          const SizedBox(width: 20),
                                          ChoiceChip(
                                            label: Text(
                                                AppLocalizations.of(context)!
                                                    .globalDisplaySongKeyNo),
                                            selected: songSettings.displayKey ==
                                                false,
                                            onSelected: (bool selected) async {
                                              var songSettings =
                                                  context.read<SongSettings>();
                                              songSettings.setDisplayKey(false);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(AppLocalizations.of(context)!
                                        .globalPageDisplaySongNumber),
                                    Consumer<SongSettings>(
                                      builder: (context, songSettings, child) =>
                                          Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          ChoiceChip(
                                            label: Text(
                                                AppLocalizations.of(context)!
                                                    .globalDisplaySongKeyYes),
                                            selected: songSettings
                                                    .displaySongNumber ==
                                                true,
                                            onSelected: (bool selected) async {
                                              var songSettings =
                                                  context.read<SongSettings>();
                                              songSettings
                                                  .setDisplaySongNumber(true);
                                            },
                                          ),
                                          const SizedBox(width: 20),
                                          ChoiceChip(
                                            label: Text(
                                                AppLocalizations.of(context)!
                                                    .globalDisplaySongKeyNo),
                                            selected: songSettings
                                                    .displaySongNumber ==
                                                false,
                                            onSelected: (bool selected) async {
                                              var songSettings =
                                                  context.read<SongSettings>();
                                              songSettings
                                                  .setDisplaySongNumber(false);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(AppLocalizations.of(context)!
                                        .songsPageSearchSongsBy),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          ChoiceChip(
                                              label: Text(AppLocalizations.of(
                                                      context)!
                                                  .songsPageSearchSongsByKey),
                                              selected:
                                                  _searchBy == SearchBy.key,
                                              onSelected:
                                                  (bool selected) async {
                                                setState(() {
                                                  _searchBy = SearchBy.key;
                                                });
                                                setLocalState(() {
                                                  _searchBy = SearchBy.key;
                                                });
                                                final Future<SharedPreferences>
                                                    prefsRef = SharedPreferences
                                                        .getInstance();
                                                final SharedPreferences prefs =
                                                    await prefsRef;
                                                prefs.setString('searchBy',
                                                    SearchBy.key.name);
                                              }),
                                          const SizedBox(width: 20),
                                          ChoiceChip(
                                              label: Text(AppLocalizations.of(
                                                      context)!
                                                  .songsPageSearchSongsByTitleAndLyrics),
                                              selected: _searchBy ==
                                                  SearchBy.titleAndLyrics,
                                              onSelected:
                                                  (bool selected) async {
                                                setState(() {
                                                  _searchBy =
                                                      SearchBy.titleAndLyrics;
                                                });
                                                setLocalState(() {
                                                  _searchBy =
                                                      SearchBy.titleAndLyrics;
                                                });
                                                final Future<SharedPreferences>
                                                    prefsRef = SharedPreferences
                                                        .getInstance();
                                                final SharedPreferences prefs =
                                                    await prefsRef;
                                                prefs.setString(
                                                    'searchBy',
                                                    SearchBy
                                                        .titleAndLyrics.name);
                                              }),
                                          const SizedBox(width: 20),
                                          ChoiceChip(
                                            label: Text(AppLocalizations.of(
                                                    context)!
                                                .songsPageSearchSongsByTitle),
                                            selected:
                                                _searchBy == SearchBy.title,
                                            onSelected: (bool selected) async {
                                              setState(() {
                                                _searchBy = SearchBy.title;
                                              });
                                              setLocalState(() {
                                                _searchBy = SearchBy.title;
                                              });
                                              final Future<SharedPreferences>
                                                  prefsRef = SharedPreferences
                                                      .getInstance();
                                              final SharedPreferences prefs =
                                                  await prefsRef;
                                              prefs.setString('searchBy',
                                                  SearchBy.title.name);
                                            },
                                          ),
                                          const SizedBox(width: 20),
                                          ChoiceChip(
                                              label: Text(AppLocalizations.of(
                                                      context)!
                                                  .songsPageSearchSongsByLyrics),
                                              selected:
                                                  _searchBy == SearchBy.lyrics,
                                              onSelected:
                                                  (bool selected) async {
                                                setState(() {
                                                  _searchBy = SearchBy.lyrics;
                                                });
                                                setLocalState(() {
                                                  _searchBy = SearchBy.lyrics;
                                                });
                                                final Future<SharedPreferences>
                                                    prefsRef = SharedPreferences
                                                        .getInstance();
                                                final SharedPreferences prefs =
                                                    await prefsRef;
                                                prefs.setString('searchBy',
                                                    SearchBy.lyrics.name);
                                              }),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )),
                        ))));
          },
        );
      },
    );
  }

  Expanded _buildAlphabeticList(results) {
    return Expanded(
      child: Consumer<ThemeSettings>(
          builder: (context, themeSettings, child) => ((AlphabetScrollView(
                list: results
                    .map<AlphaModel>((e) => AlphaModel(e.elementAt(1)))
                    .toList(),
                alignment: LetterAlignment.right,
                itemExtent: 60,
                unselectedTextStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color:
                        themeSettings.isDarkMode ? Colors.white : Colors.black),
                selectedTextStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Styles.themeColor),
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
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
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
                                          isCollectionSong: false,
                                          songText: results!
                                              .elementAt(index)
                                              .elementAt(3),
                                          songKey: results!
                                              .elementAt(index)
                                              .elementAt(2),
                                          songTitle: capitalizeFirstLetters(
                                              results!
                                                  .elementAt(index)
                                                  .elementAt(1)))));
                            },
                            child: Consumer<SongSettings>(
                                builder: (context, songSettings, child) {
                              return ListTile(
                                title: Text(results == null
                                    ? AppLocalizations.of(context)!
                                        .songsPageLoading
                                    : songNumAndTitle(
                                        results!.elementAt(index))),
                                trailing: songSettings.displayKey
                                    ? Text(
                                        results!.elementAt(index).elementAt(2))
                                    : null,
                              );
                            }),
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
                                  isCollectionSong: false,
                                  songText:
                                      results!.elementAt(index).elementAt(3),
                                  songKey:
                                      results!.elementAt(index).elementAt(2),
                                  songTitle: songNumAndTitle(
                                    results!.elementAt(index),
                                  ))));
                    },
                    child: Consumer<SongSettings>(
                        builder: (context, songSettings, child) {
                      return ListTile(
                        title: Text(results == null
                            ? AppLocalizations.of(context)!.songsPageLoading
                            : songNumAndTitle(results!.elementAt(index))),
                        trailing: songSettings.displayKey
                            ? Text(results!.elementAt(index).elementAt(2))
                            : null,
                      );
                    }),
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

  String songNumAndTitle(List song) {
    if (context.read<SongSettings>().displaySongNumber) {
      return '${song.elementAt(0)}. ${capitalizeFirstLetters(song.elementAt(1))}';
    }
    return capitalizeFirstLetters(song.elementAt(1));
  }

  String capitalizeFirstLetters(String s) {
    return s
        .split(' ')
        .map((str) => str.isEmpty
            ? str
            : str[0].toUpperCase() + str.substring(1).toLowerCase())
        .join(' ');
  }

  Expanded noSearchSongsFound() {
    String songbook = _fileName.split('_').first;
    songbook = songbook.replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'), (Match m) => '${m[1]} ${m[2]}');

    String termNotFound = _searchBy == SearchBy.key
        ? AppLocalizations.of(context)!.songsPageNoSongsFoundKey
        : AppLocalizations.of(context)!.songsPageNoSongsFoundWord;

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
                '$songbook $termNotFound "$_terms"',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey),
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
          children: [
            //loading icon
            const Icon(
              Icons.hourglass_bottom,
              size: 200,
              color: Colors.grey,
            ),

            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(40.0, 0, 40.0, 0),
              child: Text(
                AppLocalizations.of(context)!.songsPageLoadingSongbooksText,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey),
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
      searchScore =
          partialRatio(processedSongTitle, processedSearchTerm).toDouble();
      if (searchScore > _songSearchThreshold) {
        songSearchResults.add(SongSearchResult(element, searchScore));
      }
    });
    return songSearchResults;
  }
}
