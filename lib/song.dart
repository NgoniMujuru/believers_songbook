import 'package:flutter/material.dart';
import 'styles.dart';

class Song extends StatelessWidget {
  final songTitle;
  final songText;
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
        backgroundColor: Styles.themeColor,
      ),
      backgroundColor: Styles.scaffoldBackground,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Styles.scaffoldBackground,
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(songText, style: Styles.productRowItemName),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
