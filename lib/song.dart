import 'package:flutter/material.dart';
import 'styles.dart';
import 'package:provider/provider.dart';
import 'providers/song_settings.dart';

class Song extends StatelessWidget {
  final String songTitle;
  final String songText;

  const Song({
    required this.songText,
    required this.songTitle,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(Object context) {
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
          width: double.infinity,
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
                      child: Text(songText,
                          style: TextStyle(fontSize: songSettings.fontSize)),
                    );
                  })
                ],
              ),
            ),
          ),
        ),
      ),
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
                  const Text('Font Size:'),
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
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
