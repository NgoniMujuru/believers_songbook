// ignore_for_file: use_build_context_synchronously

import 'package:believers_songbook/providers/main_page_settings.dart';
import 'package:believers_songbook/providers/theme_settings.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'styles.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:io' show Platform;

class AboutPage extends StatelessWidget {
  AboutPage({super.key});
  final InAppReview _inAppReview = InAppReview.instance;

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Scaffold(
        appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.aboutPageTitle),
            scrolledUnderElevation: 4,
            actions: <Widget>[
              IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    buildSettingsBottomSheet(context);
                  }),
            ]),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: MediaQuery.of(context).size.width > 600
                    ? const EdgeInsets.fromLTRB(80, 20, 80, 40)
                    : const EdgeInsets.all(20.0),
                child: Consumer<ThemeSettings>(
                  builder: (context, themeSettings, child) => (Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        '${AppLocalizations.of(context)!.aboutBibleBook} 98:4',
                        style: themeSettings.isDarkMode
                            ? Styles.aboutHeaderDark
                            : Styles.aboutHeader,
                      ),
                      Text(
                        AppLocalizations.of(context)!.aboutBibleVerse,
                        style: themeSettings.isDarkMode
                            ? Styles.aboutHeaderDark
                            : Styles.aboutHeader,
                      ),
                      const Divider(),
                      RichText(
                          text: TextSpan(children: <TextSpan>[
                        TextSpan(
                          text: AppLocalizations.of(context)!.aboutDescriptionA,
                          style: themeSettings.isDarkMode
                              ? Styles.appInfoDark
                              : Styles.appInfo,
                        ),
                        TextSpan(
                          text: AppLocalizations.of(context)!.aboutDescriptionB,
                          style: themeSettings.isDarkMode
                              ? Styles.appInfoDark
                              : Styles.appInfo,
                        ),
                        TextSpan(
                          text: AppLocalizations.of(context)!.aboutDescriptionC,
                          style: themeSettings.isDarkMode
                              ? Styles.linkDark
                              : Styles.link,
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              contactUs(context);
                            },
                        ),
                        TextSpan(
                          text: AppLocalizations.of(context)!.aboutDescriptionD,
                          style: themeSettings.isDarkMode
                              ? Styles.appInfoDark
                              : Styles.appInfo,
                        ),
                        TextSpan(
                          text: AppLocalizations.of(context)!.aboutDescriptionE,
                          style: themeSettings.isDarkMode
                              ? Styles.linkDark
                              : Styles.link,
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              String url = "https://branham.org/en/apps";
                              if (await canLaunchUrlString(url)) {
                                await launchUrlString(url);
                              } else {
                                createDialog(
                                    context,
                                    AppLocalizations.of(context)!
                                        .aboutDialogErrorTitle,
                                    '${AppLocalizations.of(context)!.aboutDialogErrorTitle} $url');
                              }
                            },
                        ),
                        TextSpan(
                          text: AppLocalizations.of(context)!.aboutDescriptionF,
                          style: themeSettings.isDarkMode
                              ? Styles.appInfoDark
                              : Styles.appInfo,
                        ),
                        TextSpan(
                            text:
                                AppLocalizations.of(context)!.aboutDescriptionG,
                            style: themeSettings.isDarkMode
                                ? Styles.linkDark
                                : Styles.link,
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                String url =
                                    "https://ngonimujuru.com/songbook_for_believers/privacy_policy.html";
                                if (await canLaunchUrlString(url)) {
                                  await launchUrlString(url);
                                } else {
                                  createDialog(
                                      context,
                                      AppLocalizations.of(context)!
                                          .aboutDialogErrorTitle,
                                      '${AppLocalizations.of(context)!.aboutDialogErrorTitle} $url');
                                }
                              }),
                        TextSpan(
                          text: '.',
                          style: themeSettings.isDarkMode
                              ? Styles.appInfoDark
                              : Styles.appInfo,
                        ),
                      ])),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton(
                            style: ButtonStyle(
                              foregroundColor: MaterialStateColor.resolveWith(
                                  (states) => Colors.white),
                              backgroundColor: MaterialStateColor.resolveWith(
                                  (states) => Styles.themeColor),
                            ),
                            onPressed: () {
                              contactUs(context);
                            },
                            child: Text(AppLocalizations.of(context)!
                                .aboutContactUsBtn),
                          ),
                          ElevatedButton(
                            style: ButtonStyle(
                              foregroundColor: MaterialStateColor.resolveWith(
                                  (states) => Colors.white),
                              backgroundColor: MaterialStateColor.resolveWith(
                                  (states) => Styles.themeColor),
                            ),
                            onPressed: () async {
                              if (Platform.isAndroid) {
                                //android does not support in app review from button press
                                manualReview(context);
                              } else {
                                try {
                                  if (await _inAppReview.isAvailable()) {
                                    _inAppReview.requestReview();
                                  } else {
                                    manualReview(context);
                                  }
                                } catch (e) {
                                  manualReview(context);
                                }
                              }
                            },
                            child: Text(
                                AppLocalizations.of(context)!.aboutRateAppBtn),
                          ),
                          ElevatedButton(
                            style: ButtonStyle(
                              foregroundColor: MaterialStateColor.resolveWith(
                                  (states) => Colors.white),
                              backgroundColor: MaterialStateColor.resolveWith(
                                  (states) => Styles.themeColor),
                            ),
                            onPressed: () {
                              Share.share(
                                  '${AppLocalizations.of(context)!.aboutShareText} https://onelink.to/songbook');
                            },
                            child: Text(
                                AppLocalizations.of(context)!.aboutShareAppBtn),
                          ),
                        ],
                      ),
                      Text(
                        AppLocalizations.of(context)!.aboutMayGodBless,
                        style: themeSettings.isDarkMode
                            ? Styles.appInfoDark
                            : Styles.appInfo,
                      ),
                      const Card(
                          child: Icon(Icons.handshake,
                              color: Styles.themeColor, size: 50.0)),
                      const Text(
                        'v1.7.2 - 04/24',
                      ),
                    ],
                  )),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  createDialog(BuildContext context, String heading, String content) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(heading),
            content: Text(content),
            actions: [
              TextButton(
                child: Text(AppLocalizations.of(context)!.aboutDialogBtnOk),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  void contactUs(context) async {
    String emailUrl = "mailto:songbookforbelievers@gmail.com";
    if (await canLaunchUrlString(emailUrl)) {
      await launchUrlString(emailUrl);
    } else {
      createDialog(
          context,
          AppLocalizations.of(context)!.aboutDialogEmailErrorTitle,
          '${AppLocalizations.of(context)!.aboutDialogEmailErrorDescription} songbookforbelievers@gmail.com');
    }
  }

  void manualReview(context) async {
    String url = Platform.isIOS
        ? "https://apps.apple.com/app/songbook-for-believers/id1667531237"
        : "https://play.google.com/store/apps/details?id=com.ngonimujuru.songbook_for_believers";
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      createDialog(
          context,
          AppLocalizations.of(context)!.aboutDialogReviewErrorTitle,
          '${AppLocalizations.of(context)!.aboutDialogErrorDescription} $url');
    }
  }

  buildSettingsBottomSheet(context) {
    // Language settings on labels were not updating without closing and opening widget. Had to add more consumers to refresh the widget
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
                        builder: (context, mainPageSettings, child) => (Padding(
                          padding: const EdgeInsets.fromLTRB(20, 30, 20, 50),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(AppLocalizations.of(context)!
                                      .aboutLanguageSetting),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ChoiceChip(
                                          label: Text(
                                              AppLocalizations.of(context)!
                                                  .aboutLanguageSettingSwahili),
                                          selected:
                                              mainPageSettings.getLocale ==
                                                  'sw',
                                          onSelected: (bool selected) async {
                                            var settings = context
                                                .read<MainPageSettings>();
                                            settings.setLocale('sw');
                                          }),
                                      const SizedBox(width: 20),
                                      ChoiceChip(
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          label: Text(
                                              AppLocalizations.of(context)!
                                                  .aboutLanguageSettingFrench),
                                          selected:
                                              mainPageSettings.getLocale ==
                                                  'fr',
                                          onSelected: (bool selected) async {
                                            var settings = context
                                                .read<MainPageSettings>();
                                            settings.setLocale('fr');
                                          }),
                                      const SizedBox(width: 20),
                                      ChoiceChip(
                                          label: Text(
                                              AppLocalizations.of(context)!
                                                  .aboutLanguageSettingEnglish),
                                          selected:
                                              mainPageSettings.getLocale ==
                                                  'en',
                                          onSelected: (bool selected) async {
                                            var settings = context
                                                .read<MainPageSettings>();
                                            settings.setLocale('en');
                                          }),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
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
                                                  label: Text(
                                                      '    ${AppLocalizations.of(context)!.globalThemeSettingLight}    '),
                                                  selected:
                                                      !themeSettings.isDarkMode,
                                                  onSelected:
                                                      (bool selected) async {
                                                    var themeSettings = context
                                                        .read<ThemeSettings>();
                                                    themeSettings
                                                        .setIsDarkMode(false);
                                                  }),
                                              const SizedBox(width: 20),
                                              ChoiceChip(
                                                  label: Text(
                                                      '      ${AppLocalizations.of(context)!.globalThemeSettingDark}      '),
                                                  selected:
                                                      themeSettings.isDarkMode,
                                                  onSelected:
                                                      (bool selected) async {
                                                    var themeSettings = context
                                                        .read<ThemeSettings>();
                                                    themeSettings
                                                        .setIsDarkMode(true);
                                                  }),
                                            ],
                                          ))),
                                ],
                              ),
                            ],
                          ),
                        )),
                      ),
                    )));
          },
        );
      },
    );
  }
}
