import 'package:flutter/material.dart';

// class Songs extends StatelessWidget {
//   const Songs({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Songs'),
//         backgroundColor: Colors.green[800],
//       ),
//       body: const Center(
//         child: Text('This songbook is a work in progress.'),
//       ),
//     );
//   }
// }

import 'search_bar.dart'; // NEW
import 'styles.dart';

class Songs extends StatefulWidget {
  const Songs({Key? key}) : super(key: key);

  @override
  _SongsState createState() {
    return _SongsState();
  }
}

class _SongsState extends State<Songs> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String _terms = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()..addListener(_onTextChanged);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _terms = _controller.text;
    });
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: SearchBar(
        controller: _controller,
        focusNode: _focusNode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = List<String>.generate(20, (i) => "Item $i");

    return Scaffold(
      appBar: AppBar(
        title: const Text('Songs'),
        backgroundColor: Colors.green[800],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          color: Styles.scaffoldBackground,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildSearchBox(),
              Expanded(
                child: ListView.builder(
                  itemBuilder: (context, index) => ListTile(
                    title: Text(results[index]),
                  ),
                  itemCount: results.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// flutter code to read csv file and display in a listview
//  readFromCSV() {
//     String csvFile = "assets/words.csv";

//  }
