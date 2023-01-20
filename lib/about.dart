import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const Text(
                'Psalm 98:4',
                style: Styles.productRowItemName,
              ),
              const Text(
                'Make a joyful noise unto the Lord, all the earth: make a loud noise, and rejoice, and sing praise.',
                style: Styles.productRowItemName,
              ),
              const Divider(),
              RichText(
                  text: TextSpan(children: <TextSpan>[
                const TextSpan(
                  text:
                      "This app was made with ❤️ by Ngoni Mujuru with the invaluable support of family and friends. Together, lets continue to spread the love and share this app with anyone who will find it helpful. Your support doesn't stop there, a positive review on the app store will help others discover it too. We're always looking for ways to improve, so if you have any suggestions for features or would like to see your songbook added, don't hesitate to ",
                  style: Styles.appInfo,
                ),
                TextSpan(
                  text: 'reach out',
                  style: Styles.link,
``                  recognizer: TapGestureRecognizer()
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
                const TextSpan(
                  text:
                      ' and let us know. For more resources, visit the Voice of God Recordings ',
                  style: Styles.appInfo,
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
                const TextSpan(
                  text: '.',
                  style: Styles.appInfo,
                ),
                const TextSpan(
                  text:
                      'This app does not collect any personal information. Details about how data is handled can be found in the ',
                  style: Styles.appInfo,
                ),
                TextSpan(
                    text: 'privacy policy',
                    style: Styles.link,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        String url = "https://branham.org/en/apps";
                        if (await canLaunchUrlString(url)) {
                          await launchUrlString(url);
                        } else {
                          createDialog(
                              context,
                              'Policy Could Not Be Launched Automatically',
                              'Visit website by copying the following url into your browser app: https://ngonimujuru.com/songbookforbelievers/privacy_policy.html');
                        }
                      }),
                const TextSpan(
                  text: '.',
                  style: Styles.appInfo,
                ),
              ])),
              const Text(
                'May God richly bless you!',
                style: Styles.appInfo,
              ),
              const Card(
                  child: Icon(Icons.handshake, color: Styles.themeColor, size: 50.0)),
              const Text(
                'Version 1.0.0',
              )
            ],
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
