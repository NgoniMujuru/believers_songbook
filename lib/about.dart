import 'package:believers_songbook/providers/theme_settings.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'styles.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        shadowColor: Styles.themeColor,
        scrolledUnderElevation: 4,
      ),
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
                      'Psalm 98:4',
                      style: themeSettings.isDarkMode
                          ? Styles.aboutHeaderDark
                          : Styles.aboutHeader,
                    ),
                    Text(
                      'Make a joyful noise unto the Lord, all the earth: make a loud noise, and rejoice, and sing praise.',
                      style: themeSettings.isDarkMode
                          ? Styles.aboutHeaderDark
                          : Styles.aboutHeader,
                    ),
                    const Divider(),
                    RichText(
                        text: TextSpan(children: <TextSpan>[
                      TextSpan(
                        text: "This app was made by a ",
                        style: themeSettings.isDarkMode
                            ? Styles.appInfoDark
                            : Styles.appInfo,
                      ),
                      TextSpan(
                        text: 'solo developer',
                        style: Styles.link,
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            String url = "https://ngonimujuru.com";
                            if (await canLaunchUrlString(url)) {
                              await launchUrlString(url);
                            } else {
                              createDialog(
                                  context,
                                  'Website Could Not Be Launched Automatically',
                                  'Visit website by copying the following url into your browser app: $url');
                            }
                          },
                      ),
                      TextSpan(
                        text:
                            " with the invaluable support of family and friends. A special thanks goes to the wonderful saints who provided the songbooks and helped with testing. Please share this app with anyone who will find it helpful. A positive review on the app store will also help others discover it too!",
                        style: themeSettings.isDarkMode
                            ? Styles.appInfoDark
                            : Styles.appInfo,
                      ),
                      TextSpan(
                        text:
                            "\n\nIf you have any feedback or would like to see your congregation's songbook added, don't hesitate to ",
                        style: themeSettings.isDarkMode
                            ? Styles.appInfoDark
                            : Styles.appInfo,
                      ),
                      TextSpan(
                        text: 'reach out',
                        style: Styles.link,
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            String emailUrl = "mailto:songbookforbelievers@gmail.com";
                            if (await canLaunchUrlString(emailUrl)) {
                              await launchUrlString(emailUrl);
                            } else {
                              createDialog(
                                  context,
                                  'Email App Could Not Be Opened Automatically',
                                  'You can use the following email address: songbookforbelievers@gmail.com');
                            }
                          },
                      ),
                      TextSpan(
                        text:
                            ' and let us know. For more resources, visit the Voice of God Recordings ',
                        style: themeSettings.isDarkMode
                            ? Styles.appInfoDark
                            : Styles.appInfo,
                      ),
                      TextSpan(
                        text: 'website',
                        style: Styles.link,
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            String url = "https://branham.org/en/apps";
                            if (await canLaunchUrlString(url)) {
                              await launchUrlString(url);
                            } else {
                              createDialog(
                                  context,
                                  'Website Could Not Be Launched Automatically',
                                  'Visit website by copying the following url into your browser app: $url');
                            }
                          },
                      ),
                      TextSpan(
                        text:
                            '. This app does not collect any personal information, as specified in the ',
                        style: themeSettings.isDarkMode
                            ? Styles.appInfoDark
                            : Styles.appInfo,
                      ),
                      TextSpan(
                          text: 'privacy policy',
                          style: Styles.link,
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              String url =
                                  "https://ngonimujuru.com/songbook_for_believers/privacy_policy.html";
                              if (await canLaunchUrlString(url)) {
                                await launchUrlString(url);
                              } else {
                                createDialog(
                                    context,
                                    'Policy Could Not Be Launched Automatically',
                                    'Visit website by copying the following url into your browser app: $url');
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
                    Text(
                      'May God richly bless you!',
                      style:
                          themeSettings.isDarkMode ? Styles.appInfoDark : Styles.appInfo,
                    ),
                    const Card(
                        child:
                            Icon(Icons.handshake, color: Styles.themeColor, size: 50.0)),
                    const Text(
                      'Version 1.1.0',
                    )
                  ],
                )),
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
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }
}
