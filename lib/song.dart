import 'package:flutter/material.dart';
import 'song_player.dart';
import 'styles.dart';
import 'package:provider/provider.dart';
import 'providers/song_settings.dart';

class Song extends StatelessWidget {
  final String songTitle;
  final String songText;
  final String songKey;

  const Song({
    required this.songText,
    required this.songTitle,
    required this.songKey,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(songTitle),
          shadowColor: Styles.themeColor,
          scrolledUnderElevation: 4,
          actions: <Widget>[
            IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  buildBottomSheet(context);
                }),
          ]),
      // backgroundColor: Styles.scaffoldBackground,
      body: Stack(children: [
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Stack(
            children: [
              ConstrainedBox(
                // width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 60,
                  minWidth: double.infinity,
                ),

                child: DecoratedBox(
                  decoration: const BoxDecoration(
                      // color: Styles.scaffoldBackground,
                      ),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Consumer<SongSettings>(builder: (context, songSettings, child) {
                          return Padding(
                            padding: MediaQuery.of(context).size.width > 600
                                ? const EdgeInsets.fromLTRB(80, 20, 16, 40)
                                : const EdgeInsets.fromLTRB(16, 20, 16, 40),
                            child: Column(
                              children: [
                                if (songSettings.displayKey)
                                  Text(songKey == '' ? '---' : songKey,
                                      style: TextStyle(
                                          fontSize: songSettings.fontSize,
                                          fontWeight: FontWeight.bold))
                                else
                                  const SizedBox(),
                                Text(songText,
                                    style: TextStyle(fontSize: songSettings.fontSize)),
                              ],
                            ),
                          );
                        })
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Styles.themeColor.withOpacity(0.0),
                  Styles.themeColor.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(5.0),
            ),
            // width: ,
            // full width of screen
            width: MediaQuery.of(context).size.width,
            height: 50,
            child: const SongPlayer(
                audioLink:
                    'https://firebasestorage.googleapis.com/v0/b/songbook-for-believers.appspot.com/o/SongAudioFiles%2FBroDonnyReagan-LetMeWalkWithYou%2CJesus-InTheGarden.mp3?alt=media&token=39c22b2c-1518-4060-9619-109011e7afb9'),
          ),
        ),
      ]),
    );
  }

  buildBottomSheet(context) {
    return showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 50),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Text('Display Song Key:'),
                  Consumer<SongSettings>(
                    builder: (context, songSettings, child) => Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ChoiceChip(
                          label: const Text('Yes'),
                          selected: songSettings.displayKey == true,
                          onSelected: (bool selected) async {
                            var songSettings = context.read<SongSettings>();
                            songSettings.setDisplayKey(true);
                          },
                        ),
                        const SizedBox(width: 20),
                        ChoiceChip(
                          label: const Text('No'),
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
                  const Text('Font Size:'),
                  Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                    const Text(
                      'Aa',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    Consumer<SongSettings>(
                      builder: (context, songSettings, child) => Slider(
                        value: songSettings.fontSize,
                        min: 14,
                        max: 38,
                        divisions: 6,
                        label: songSettings.fontSize.round().toString(),
                        onChanged: (double value) {
                          var songSettings = context.read<SongSettings>();
                          songSettings.setFontSize(value);
                        },
                      ),
                    ),
                    const Text(
                      'Aa',
                      style: TextStyle(
                        fontSize: 38,
                      ),
                    ),
                  ]),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
