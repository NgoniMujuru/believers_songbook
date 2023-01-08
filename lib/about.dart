import 'package:flutter/material.dart';
import 'styles.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: Styles.themeColor,
      ),
      body: const Center(
        child: Text('This songbook is a work in progress.'),
      ),
    );
  }
}
