import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_sw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('sw')
  ];

  /// No description provided for @globalThemeSetting.
  ///
  /// In en, this message translates to:
  /// **'Theme:'**
  String get globalThemeSetting;

  /// No description provided for @globalThemeSettingDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get globalThemeSettingDark;

  /// No description provided for @globalThemeSettingLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get globalThemeSettingLight;

  /// No description provided for @globalSong.
  ///
  /// In en, this message translates to:
  /// **'Song'**
  String get globalSong;

  /// No description provided for @globalDisplaySongKey.
  ///
  /// In en, this message translates to:
  /// **'Display Song Key:'**
  String get globalDisplaySongKey;

  /// No description provided for @globalPageDisplaySongNumber.
  ///
  /// In en, this message translates to:
  /// **'Display Song Number'**
  String get globalPageDisplaySongNumber;

  /// No description provided for @globalDisplaySongKeyYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get globalDisplaySongKeyYes;

  /// No description provided for @globalDisplaySongKeyNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get globalDisplaySongKeyNo;

  /// No description provided for @globalCollections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get globalCollections;

  /// No description provided for @aboutPageTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutPageTitle;

  /// No description provided for @aboutBibleBook.
  ///
  /// In en, this message translates to:
  /// **'Psalm'**
  String get aboutBibleBook;

  /// No description provided for @aboutBibleVerse.
  ///
  /// In en, this message translates to:
  /// **'Make a joyful noise unto the Lord, all the earth: make a loud noise, and rejoice, and sing praise.'**
  String get aboutBibleVerse;

  /// No description provided for @aboutDescriptionA.
  ///
  /// In en, this message translates to:
  /// **'This app was made for you. A special thanks goes to the wonderful saints who provided the songbooks and helped with testing. A special thank you also goes out to all the composers of the songs included in this app, whose beautiful and inspiring music has touched the hearts of so many. Please share this app with anyone who will find it helpful. A positive review on the app store will help others discover it too!'**
  String get aboutDescriptionA;

  /// No description provided for @aboutDescriptionB.
  ///
  /// In en, this message translates to:
  /// **'\n\nIf you have any feedback or would like to see your congregation\'s songbook added, don\'t hesitate to '**
  String get aboutDescriptionB;

  /// No description provided for @aboutDescriptionC.
  ///
  /// In en, this message translates to:
  /// **'contact us'**
  String get aboutDescriptionC;

  /// No description provided for @aboutDescriptionD.
  ///
  /// In en, this message translates to:
  /// **' and let us know. For more resources, visit the Voice of God Recordings'**
  String get aboutDescriptionD;

  /// No description provided for @aboutDescriptionE.
  ///
  /// In en, this message translates to:
  /// **' website'**
  String get aboutDescriptionE;

  /// No description provided for @aboutDescriptionF.
  ///
  /// In en, this message translates to:
  /// **'. This app does not collect any personal information, as specified in the '**
  String get aboutDescriptionF;

  /// No description provided for @aboutDescriptionG.
  ///
  /// In en, this message translates to:
  /// **'privacy policy'**
  String get aboutDescriptionG;

  /// No description provided for @aboutDialogErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Website Could Not Be Launched Automatically'**
  String get aboutDialogErrorTitle;

  /// No description provided for @aboutDialogBtnOk.
  ///
  /// In en, this message translates to:
  /// **'Ok'**
  String get aboutDialogBtnOk;

  /// No description provided for @aboutDialogErrorDescription.
  ///
  /// In en, this message translates to:
  /// **'Visit website by copying the following url into your browser app:'**
  String get aboutDialogErrorDescription;

  /// No description provided for @aboutContactUsBtn.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get aboutContactUsBtn;

  /// No description provided for @aboutRateAppBtn.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get aboutRateAppBtn;

  /// No description provided for @aboutShareAppBtn.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get aboutShareAppBtn;

  /// No description provided for @aboutMayGodBless.
  ///
  /// In en, this message translates to:
  /// **'May God richly bless you!'**
  String get aboutMayGodBless;

  /// No description provided for @aboutShareText.
  ///
  /// In en, this message translates to:
  /// **'Check out the Songbook for Believers app, available for Android and iOs devices:'**
  String get aboutShareText;

  /// No description provided for @aboutDialogEmailErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Email App Could Not Be Opened Automatically'**
  String get aboutDialogEmailErrorTitle;

  /// No description provided for @aboutDialogEmailErrorDescription.
  ///
  /// In en, this message translates to:
  /// **'You can use the following email address:'**
  String get aboutDialogEmailErrorDescription;

  /// No description provided for @aboutDialogReviewErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'App Store Could Not Be Launched Automatically'**
  String get aboutDialogReviewErrorTitle;

  /// No description provided for @aboutLanguageSetting.
  ///
  /// In en, this message translates to:
  /// **'Language:'**
  String get aboutLanguageSetting;

  /// No description provided for @aboutLanguageSettingFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get aboutLanguageSettingFrench;

  /// No description provided for @aboutLanguageSettingEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get aboutLanguageSettingEnglish;

  /// No description provided for @aboutLanguageSettingSwahili.
  ///
  /// In en, this message translates to:
  /// **'Swahili'**
  String get aboutLanguageSettingSwahili;

  /// No description provided for @collectionsEmptyStateText.
  ///
  /// In en, this message translates to:
  /// **'Create your own song collections. Open a song and select the collections menu icon on the top right corner.'**
  String get collectionsEmptyStateText;

  /// No description provided for @collectionsSongs.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get collectionsSongs;

  /// No description provided for @collectionsCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get collectionsCreated;

  /// No description provided for @collectionSongsDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get collectionSongsDialogTitle;

  /// No description provided for @collectionSongsDialogText.
  ///
  /// In en, this message translates to:
  /// **'This will delete this collection. This action cannot be undone.'**
  String get collectionSongsDialogText;

  /// No description provided for @collectionSongsDialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get collectionSongsDialogCancel;

  /// No description provided for @collectionSongsDialogDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get collectionSongsDialogDelete;

  /// No description provided for @collectionSongsEmptyStateText.
  ///
  /// In en, this message translates to:
  /// **'This collection has no songs. Add songs to this collection by opening a song and selecting the collections menu icon on the top right corner.'**
  String get collectionSongsEmptyStateText;

  /// No description provided for @songBooksPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Songbooks'**
  String get songBooksPageTitle;

  /// No description provided for @songBooksChangeSnackBarText.
  ///
  /// In en, this message translates to:
  /// **'Songbook changed to'**
  String get songBooksChangeSnackBarText;

  /// No description provided for @songsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get songsPageTitle;

  /// No description provided for @songsPageLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get songsPageLoading;

  /// No description provided for @songsPageSortOrder.
  ///
  /// In en, this message translates to:
  /// **'Sort Order:'**
  String get songsPageSortOrder;

  /// No description provided for @songsPageSortOrderNumerical.
  ///
  /// In en, this message translates to:
  /// **'Numerical'**
  String get songsPageSortOrderNumerical;

  /// No description provided for @songsPageSortOrderAlphabetic.
  ///
  /// In en, this message translates to:
  /// **'Alphabetical'**
  String get songsPageSortOrderAlphabetic;

  /// No description provided for @songsPageSortOrderKey.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get songsPageSortOrderKey;

  /// No description provided for @songsPageSearchSongsBy.
  ///
  /// In en, this message translates to:
  /// **'Search Songs By:'**
  String get songsPageSearchSongsBy;

  /// No description provided for @songsPageSearchSongsByTitleAndLyrics.
  ///
  /// In en, this message translates to:
  /// **'Title&Lyrics'**
  String get songsPageSearchSongsByTitleAndLyrics;

  /// No description provided for @songsPageSearchSongsByTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get songsPageSearchSongsByTitle;

  /// No description provided for @songsPageSearchSongsByLyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get songsPageSearchSongsByLyrics;

  /// No description provided for @songsPageSearchSongsByKey.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get songsPageSearchSongsByKey;

  /// No description provided for @songsPageLoadingSongbooksText.
  ///
  /// In en, this message translates to:
  /// **'Loading songs. Please be patient, this can take a bit of time.'**
  String get songsPageLoadingSongbooksText;

  /// No description provided for @songsPageNoSongsFoundWord.
  ///
  /// In en, this message translates to:
  /// **'Songbook: no songs found with words'**
  String get songsPageNoSongsFoundWord;

  /// No description provided for @songsPageNoSongsFoundKey.
  ///
  /// In en, this message translates to:
  /// **'Songbook: no songs found with key'**
  String get songsPageNoSongsFoundKey;

  /// No description provided for @songPageSongSuccessfulUpdateSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Song updated successfully.'**
  String get songPageSongSuccessfulUpdateSnackbar;

  /// No description provided for @songPageEditKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get songPageEditKeyLabel;

  /// No description provided for @songPageEditKeyError.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid key.'**
  String get songPageEditKeyError;

  /// No description provided for @songPageEditLyricsLabel.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get songPageEditLyricsLabel;

  /// No description provided for @songPageEditLyricsInstruction.
  ///
  /// In en, this message translates to:
  /// **'Please enter the lyrics.'**
  String get songPageEditLyricsInstruction;

  /// No description provided for @songPageEditLyricsError.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid lyrics.'**
  String get songPageEditLyricsError;

  /// No description provided for @songPageCollections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get songPageCollections;

  /// No description provided for @songPageCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get songPageCreate;

  /// No description provided for @songPageSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get songPageSave;

  /// No description provided for @songPageAddedToSnackbar.
  ///
  /// In en, this message translates to:
  /// **'added to'**
  String get songPageAddedToSnackbar;

  /// No description provided for @songPageRemovedFromSnackbar.
  ///
  /// In en, this message translates to:
  /// **'removed from'**
  String get songPageRemovedFromSnackbar;

  /// No description provided for @songPageCollectionNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Collection name'**
  String get songPageCollectionNameLabel;

  /// No description provided for @songPageCollectionNameInstruction.
  ///
  /// In en, this message translates to:
  /// **'Please enter the collection name.'**
  String get songPageCollectionNameInstruction;

  /// No description provided for @songPageCollectionNameError.
  ///
  /// In en, this message translates to:
  /// **'Collection name already exists.'**
  String get songPageCollectionNameError;

  /// No description provided for @songPageFontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size:'**
  String get songPageFontSize;

  /// No description provided for @songPageOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get songPageOptions;

  /// No description provided for @songPageOptionsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get songPageOptionsEdit;

  /// No description provided for @songPageOptionsCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get songPageOptionsCopy;

  /// No description provided for @songPageOptionsShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get songPageOptionsShare;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr', 'sw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'sw':
      return AppLocalizationsSw();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
