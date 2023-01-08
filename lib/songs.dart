import 'package:flutter/material.dart';
import 'package:csv/csv.dart';

import 'search_bar.dart'; // NEW
import 'styles.dart';
import 'song.dart';

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
  List<List<dynamic>>? csvData;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()..addListener(_onTextChanged);
    _focusNode = FocusNode();
    processCsv();
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

  void processCsv() async {
    var result = await DefaultAssetBundle.of(context).loadString(
      "assets/Songs.csv",
    );
    setState(() {
      csvData = const CsvToListConverter().convert(result, fieldDelimiter: ';');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Songs'),
        backgroundColor: Styles.themeColor,
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
                  itemBuilder: (context, index) => GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Song(
                                  songText: csvData!.elementAt(index).elementAt(3),
                                  songTitle:
                                      '${csvData!.elementAt(index).elementAt(0)} - ${csvData!.elementAt(index).elementAt(1)}')));
                    },
                    child: ListTile(
                      title: Text(csvData == null
                          ? 'Loading'
                          : '${csvData!.elementAt(index).elementAt(0)} - ${csvData!.elementAt(index).elementAt(1)}'),
                    ),
                  ),
                  itemCount: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
