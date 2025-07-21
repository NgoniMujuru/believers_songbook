import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:believers_songbook/providers/main_page_settings.dart';
import 'package:believers_songbook/providers/theme_settings.dart';
import 'package:believers_songbook/providers/song_settings.dart';
import 'package:believers_songbook/providers/song_book_settings.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '/models/song_sort_order.dart';

class BottomSheetSettings extends StatefulWidget {
  final List<List<dynamic>>? csvData;
  final SortOrder? sortBy;
  final SearchBy? searchBy;
  final Function(List<List<dynamic>>?)? onCsvDataChanged;
  final Function(SortOrder)? onSortByChanged;
  final Function(SearchBy)? onSearchByChanged;
  final int Function(String, String) customComparator;

  const BottomSheetSettings({
    Key? key,
    this.csvData,
    this.sortBy,
    this.searchBy,
    this.onCsvDataChanged,
    this.onSortByChanged,
    this.onSearchByChanged,
    required this.customComparator,
  }) : super(key: key);

  static Future<void> show(BuildContext context,
      {List<List<dynamic>>? csvData,
      SortOrder? sortBy,
      SearchBy? searchBy,
      Function(List<List<dynamic>>?)? onCsvDataChanged,
      Function(SortOrder)? onSortByChanged,
      Function(SearchBy)? onSearchByChanged,
      required int Function(String, String) customComparator}) {
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
        return BottomSheetSettings(
          csvData: csvData,
          sortBy: sortBy,
          searchBy: searchBy,
          onCsvDataChanged: onCsvDataChanged,
          onSortByChanged: onSortByChanged,
          onSearchByChanged: onSearchByChanged,
          customComparator: customComparator,
        );
      },
    );
  }

  @override
  State<BottomSheetSettings> createState() => _BottomSheetSettingsState();
}

class _BottomSheetSettingsState extends State<BottomSheetSettings> {
  List<List<dynamic>>? get _csvData => widget.csvData;
  late SortOrder? _localSortBy;
  late SearchBy? _localSearchBy;
  int Function(String, String) get customComparator => widget.customComparator;

  @override
  void initState() {
    super.initState();
    _localSortBy = widget.sortBy;
    _localSearchBy = widget.searchBy;
  }

  Widget _buildSortOrderChips(BuildContext context) {
    final sortOptions = [
      {
        'label': AppLocalizations.of(context)!.songsPageSortOrderNumerical,
        'value': SortOrder.numerical,
        'onSelected': (bool selected) async {
          _csvData?.sort((a, b) => a.elementAt(0).compareTo(b.elementAt(0)));
          if (widget.onCsvDataChanged != null) {
            widget.onCsvDataChanged!(_csvData);
          }
          if (widget.onSortByChanged != null) {
            widget.onSortByChanged!(SortOrder.numerical);
          }
          setState(() {
            _localSortBy = SortOrder.numerical;
          });
          final prefs = await SharedPreferences.getInstance();
          prefs.setString('sortOrder', SortOrder.numerical.name);
        },
      },
      {
        'label': AppLocalizations.of(context)!.songsPageSortOrderAlphabetic,
        'value': SortOrder.alphabetic,
        'onSelected': (bool selected) async {
          _csvData?.sort((a, b) => customComparator(a.elementAt(1), b.elementAt(1)));
          if (widget.onCsvDataChanged != null) {
            widget.onCsvDataChanged!(_csvData);
          }
          if (widget.onSortByChanged != null) {
            widget.onSortByChanged!(SortOrder.alphabetic);
          }
          setState(() {
            _localSortBy = SortOrder.alphabetic;
          });
          final prefs = await SharedPreferences.getInstance();
          prefs.setString('sortOrder', SortOrder.alphabetic.name);
        },
      },
      {
        'label': AppLocalizations.of(context)!.songsPageSortOrderKey,
        'value': SortOrder.key,
        'onSelected': (bool selected) async {
          _csvData?.sort((a, b) {
            int primary = customComparator(a.elementAt(2), b.elementAt(2));
            if (primary != 0) return primary;
            return a.elementAt(1).compareTo(b.elementAt(1));
          });
          if (widget.onCsvDataChanged != null) {
            widget.onCsvDataChanged!(_csvData);
          }
          if (widget.onSortByChanged != null) {
            widget.onSortByChanged!(SortOrder.key);
          }
          setState(() {
            _localSortBy = SortOrder.key;
          });
          final prefs = await SharedPreferences.getInstance();
          prefs.setString('sortOrder', SortOrder.key.name);
        },
      },
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: sortOptions.map<Widget>((option) {
        return Row(
          children: [
            ChoiceChip(
              label: Text(option['label'] as String),
              selected: _localSortBy == option['value'],
              onSelected: option['onSelected'] as void Function(bool),
            ),
            if (option != sortOptions.last) const SizedBox(width: 20),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSearchByChips(BuildContext context) {
    final searchOptions = [
      {
        'label': AppLocalizations.of(context)!.songsPageSearchSongsByKey,
        'value': SearchBy.key,
      },
      {
        'label': AppLocalizations.of(context)!.songsPageSearchSongsByTitleAndLyrics,
        'value': SearchBy.titleAndLyrics,
      },
      {
        'label': AppLocalizations.of(context)!.songsPageSearchSongsByTitle,
        'value': SearchBy.title,
      },
      {
        'label': AppLocalizations.of(context)!.songsPageSearchSongsByLyrics,
        'value': SearchBy.lyrics,
      },
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: searchOptions.map<Widget>((option) {
          return Row(
            children: [
              ChoiceChip(
                label: Text(option['label'] as String),
                selected: _localSearchBy == option['value'],
                onSelected: (bool selected) async {
                  if (widget.onSearchByChanged != null) {
                    widget.onSearchByChanged!(option['value'] as SearchBy);
                  }
                  setState(() {
                    _localSearchBy = option['value'] as SearchBy;
                  });
                  final prefs = await SharedPreferences.getInstance();
                  prefs.setString('searchBy', (option['value'] as SearchBy).name);
                },
              ),
              if (option != searchOptions.last) const SizedBox(width: 20),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 50),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.globalThemeSetting),
              Consumer<ThemeSettings>(
                  builder: (context, themeSettings, child) =>
                      (Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ChoiceChip(
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              label: Text(AppLocalizations.of(context)!.globalThemeSettingLight),
                              selected: !themeSettings.isDarkMode,
                              onSelected: (bool selected) async {
                                var themeSettings = context.read<ThemeSettings>();
                                themeSettings.setIsDarkMode(false);
                              }),
                          const SizedBox(width: 20),
                          ChoiceChip(
                              label: Text(AppLocalizations.of(context)!.globalThemeSettingDark),
                              selected: themeSettings.isDarkMode,
                              onSelected: (bool selected) async {
                                var themeSettings = context.read<ThemeSettings>();
                                themeSettings.setIsDarkMode(true);
                              }),
                        ],
                      ))),
              const SizedBox(height: 10),
              Text(AppLocalizations.of(context)!.songsPageSortOrder),
              _buildSortOrderChips(context),
              const SizedBox(height: 10),
              Text(AppLocalizations.of(context)!.globalDisplaySongKey),
              Consumer<SongSettings>(
                builder: (context, songSettings, child) =>
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ChoiceChip(
                          label: Text(AppLocalizations.of(context)!.globalDisplaySongKeyYes),
                          selected: songSettings.displayKey == true,
                          onSelected: (bool selected) async {
                            var songSettings = context.read<SongSettings>();
                            songSettings.setDisplayKey(true);
                          },
                        ),
                        const SizedBox(width: 20),
                        ChoiceChip(
                          label: Text(AppLocalizations.of(context)!.globalDisplaySongKeyNo),
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
              Text(AppLocalizations.of(context)!.globalPageDisplaySongNumber),
              Consumer<SongSettings>(
                builder: (context, songSettings, child) =>
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ChoiceChip(
                          label: Text(AppLocalizations.of(context)!.globalDisplaySongKeyYes),
                          selected: songSettings.displaySongNumber == true,
                          onSelected: (bool selected) async {
                            var songSettings = context.read<SongSettings>();
                            songSettings.setDisplaySongNumber(true);
                          },
                        ),
                        const SizedBox(width: 20),
                        ChoiceChip(
                          label: Text(AppLocalizations.of(context)!.globalDisplaySongKeyNo),
                          selected: songSettings.displaySongNumber == false,
                          onSelected: (bool selected) async {
                            var songSettings = context.read<SongSettings>();
                            songSettings.setDisplaySongNumber(false);
                          },
                        ),
                      ],
                    ),
              ),
              const SizedBox(height: 10),
              Text(AppLocalizations.of(context)!.songsPageSearchSongsBy),
              _buildSearchByChips(context),
            ],
          ),
        ],
      ),
    );
  }
}