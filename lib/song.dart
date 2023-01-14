import 'package:flutter/material.dart';
import 'styles.dart';

class Song extends StatefulWidget {
  final String songTitle;
  final String songText;

  const Song({
    required this.songText,
    required this.songTitle,
    Key? key,
  }) : super(key: key);

  @override
  State<Song> createState() => _SongState();
}

class _SongState extends State<Song> {
  double _fontSize = 22;

  @override
  Widget build(Object context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.songTitle),
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
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          child: DecoratedBox(
            decoration: const BoxDecoration(
                // color: Styles.scaffoldBackground,
                ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.songText, style: TextStyle(fontSize: _fontSize)),
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
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setLocalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 50),
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      const Text('Font Size:'),
                      Slider(
                        value: _fontSize,
                        min: 14,
                        max: 30,
                        divisions: 4,
                        label: _fontSize.round().toString(),
                        onChanged: (double value) {
                          setLocalState(() {
                            _fontSize = value;
                          });
                          setState(() {
                            _fontSize = value;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
