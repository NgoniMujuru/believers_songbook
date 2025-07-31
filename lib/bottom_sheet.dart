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
  static const double _chipSpacing = 20.0;
  static const double _sectionSpacing = 10.0;
  
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

  Future<void> _handleSortOrderChange(SortOrder sortOrder) async {
    // Sort the data based on the selected order
    switch (sortOrder) {
      case SortOrder.numerical:
        _csvData?.sort((a, b) => a.elementAt(0).compareTo(b.elementAt(0)));
        // Automatically set display song number to true when numerical sort is selected
        var songSettings = context.read<SongSettings>();
        songSettings.setDisplaySongNumber(true);
        break;
      case SortOrder.alphabetic:
        _csvData?.sort((a, b) => customComparator(a.elementAt(1), b.elementAt(1)));
        break;
      case SortOrder.key:
        _csvData?.sort((a, b) {
          int primary = customComparator(a.elementAt(2), b.elementAt(2));
          if (primary != 0) return primary;
          return a.elementAt(1).compareTo(b.elementAt(1));
        });
        // Automatically set display key to true when key sort is selected
        var songSettings = context.read<SongSettings>();
        songSettings.setDisplayKey(true);
        break;
    }

    // Update callbacks
    if (widget.onCsvDataChanged != null) {
      widget.onCsvDataChanged!(_csvData);
    }
    if (widget.onSortByChanged != null) {
      widget.onSortByChanged!(sortOrder);
    }

    // Update local state
    setState(() {
      _localSortBy = sortOrder;
    });

    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('sortOrder', sortOrder.name);
  }

  Future<void> _handleSearchByChange(SearchBy searchBy) async {
    if (widget.onSearchByChanged != null) {
      widget.onSearchByChanged!(searchBy);
    }
    setState(() {
      _localSearchBy = searchBy;
    });
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('searchBy', searchBy.name);
  }

  Widget _buildSortOrderChips(BuildContext context) {
    final sortOptions = [
      {
        'label': AppLocalizations.of(context)!.songsPageSortOrderNumerical,
        'value': SortOrder.numerical,
      },
      {
        'label': AppLocalizations.of(context)!.songsPageSortOrderAlphabetic,
        'value': SortOrder.alphabetic,
      },
      {
        'label': AppLocalizations.of(context)!.songsPageSortOrderKey,
        'value': SortOrder.key,
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
              onSelected: (bool selected) => _handleSortOrderChange(option['value'] as SortOrder),
            ),
            if (option != sortOptions.last) const SizedBox(width: _chipSpacing),
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
                onSelected: (bool selected) => _handleSearchByChange(option['value'] as SearchBy),
              ),
              if (option != searchOptions.last) const SizedBox(width: _chipSpacing),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildThemeSettings() {
    return Consumer<ThemeSettings>(
      builder: (context, themeSettings, child) => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ChoiceChip(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            label: Text(AppLocalizations.of(context)!.globalThemeSettingLight),
            selected: !themeSettings.isDarkMode,
            onSelected: (bool selected) {
              var themeSettings = context.read<ThemeSettings>();
              themeSettings.setIsDarkMode(false);
            },
          ),
          const SizedBox(width: _chipSpacing),
          ChoiceChip(
            label: Text(AppLocalizations.of(context)!.globalThemeSettingDark),
            selected: themeSettings.isDarkMode,
            onSelected: (bool selected) {
              var themeSettings = context.read<ThemeSettings>();
              themeSettings.setIsDarkMode(true);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayKeySettings() {
    return Consumer<SongSettings>(
      builder: (context, songSettings, child) => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ChoiceChip(
            label: Text(AppLocalizations.of(context)!.globalDisplaySongKeyYes),
            selected: songSettings.displayKey == true,
            onSelected: (bool selected) {
              var songSettings = context.read<SongSettings>();
              songSettings.setDisplayKey(true);
            },
          ),
          const SizedBox(width: _chipSpacing),
          ChoiceChip(
            label: Text(AppLocalizations.of(context)!.globalDisplaySongKeyNo),
            selected: songSettings.displayKey == false,
            onSelected: (bool selected) {
              var songSettings = context.read<SongSettings>();
              songSettings.setDisplayKey(false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDisplaySongNumberSettings() {
    return Consumer<SongSettings>(
      builder: (context, songSettings, child) => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ChoiceChip(
            label: Text(AppLocalizations.of(context)!.globalDisplaySongKeyYes),
            selected: songSettings.displaySongNumber == true,
            onSelected: (bool selected) {
              var songSettings = context.read<SongSettings>();
              songSettings.setDisplaySongNumber(true);
            },
          ),
          const SizedBox(width: _chipSpacing),
          ChoiceChip(
            label: Text(AppLocalizations.of(context)!.globalDisplaySongKeyNo),
            selected: songSettings.displaySongNumber == false,
            onSelected: (bool selected) {
              var songSettings = context.read<SongSettings>();
              songSettings.setDisplaySongNumber(false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        content,
        const SizedBox(height: _sectionSpacing),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 50),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _buildSettingSection(
            AppLocalizations.of(context)!.globalThemeSetting,
            _buildThemeSettings(),
          ),
          _buildSettingSection(
            AppLocalizations.of(context)!.songsPageSortOrder,
            _buildSortOrderChips(context),
          ),
          _buildSettingSection(
            AppLocalizations.of(context)!.globalDisplaySongKey,
            _buildDisplayKeySettings(),
          ),
          _buildSettingSection(
            AppLocalizations.of(context)!.globalPageDisplaySongNumber,
            _buildDisplaySongNumberSettings(),
          ),
          _buildSettingSection(
            AppLocalizations.of(context)!.songsPageSearchSongsBy,
            _buildSearchByChips(context),
          ),
        ],
      ),
    );
  }
}