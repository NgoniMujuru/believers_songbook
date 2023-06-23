import 'package:believers_songbook/providers/theme_settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'styles.dart';

class Collections extends StatelessWidget {
  const Collections({super.key});

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Collections'),
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
                        'Create your own song collections. Open a song, tap the menu button and select "Add to Collection".',
                        style: themeSettings.isDarkMode
                            ? Styles.aboutHeaderDark
                            : Styles.aboutHeader,
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
}
