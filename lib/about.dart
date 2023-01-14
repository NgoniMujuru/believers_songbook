import 'package:flutter/material.dart';
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
            children: const [
              Text(
                'Psalm 98:4.',
                style: Styles.productRowItemName,
              ),
              Text(
                'Make a joyful noise unto the Lord, all the earth: make a loud noise, and rejoice, and sing praise.',
                style: Styles.productRowItemName,
              ),
              Divider(),
              Text(
                'This songbook is a work in progress. Currently being built by Mr N. Mujuru with support from the distinguished gentlemen, Mr F. Mwashita and Mr D. Mabanga ',
                style: Styles.productRowItemName,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
