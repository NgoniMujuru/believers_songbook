import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'styles.dart';

class SongPlayer extends StatefulWidget {
  final String audioLink;

  const SongPlayer({
    required this.audioLink,
    Key? key,
  }) : super(key: key);

  @override
  _SongPlayerState createState() => _SongPlayerState();
}

class _SongPlayerState extends State<SongPlayer> {
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _player.setUrl(widget.audioLink!);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Playing state.
        Row(
          children: [
            IconButton(
              icon: Icon(_player.playing ? Icons.pause : Icons.play_arrow),
              iconSize: 64.0,
              onPressed: _player.playing ? _player.pause : _player.play,
            ),
          ],
        ),
      ],
    );
  }
}
