import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'styles.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

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
  bool _audioNotLoaded = false;
  Stream<DurationState>? durationState;

  @override
  initState() {
    super.initState();
    initPlayer();
  }

  initPlayer() async {
    durationState = Rx.combineLatest2<Duration, PlaybackEvent, DurationState>(
        _player.positionStream,
        _player.playbackEventStream,
        (position, playbackEvent) => DurationState(
              progress: position,
              buffered: playbackEvent.bufferedPosition,
              total: playbackEvent.duration ?? Duration.zero,
            ));
    try {
      await _player.setUrl(widget.audioLink);
    } catch (e) {
      print("Error loading audio source: $e");
      setState(() {
        _audioNotLoaded = false;
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.audioLink == '' || _audioNotLoaded
        ? generateEmptyWidget()
        : generatePlayer(context);
  }

  Container generateEmptyWidget() {
    return Container();
  }

  StreamBuilder<DurationState> _progressBar() {
    return StreamBuilder<DurationState>(
      stream: durationState,
      builder: (context, snapshot) {
        final durationState = snapshot.data;
        final progress = durationState?.progress ?? Duration.zero;
        final buffered = durationState?.buffered ?? Duration.zero;
        final total = durationState?.total ?? Duration.zero;
        return ProgressBar(
          progress: progress,
          buffered: buffered,
          total: total,
          onSeek: (duration) {
            setState(() {
              _player.seek(duration);
            });
          },
          onDragUpdate: (details) {
            debugPrint('${details.timeStamp}, ${details.localPosition}');
          },
          // barHeight: _barHeight,
          // baseBarColor: _baseBarColor,
          // progressBarColor: _progressBarColor,
          // bufferedBarColor: _bufferedBarColor,
          // thumbColor: _thumbColor,
          // thumbGlowColor: _thumbGlowColor,
          // barCapShape: _barCapShape,
          // thumbRadius: _thumbRadius,
          // thumbCanPaintOutsideBar: _thumbCanPaintOutsideBar,
          // timeLabelLocation: _labelLocation,
          // timeLabelType: _labelType,
          // timeLabelTextStyle: _labelStyle,
          // timeLabelPadding: _labelPadding,
        );
      },
    );
  }

  Row generatePlayer(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        //progress bar
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: _progressBar(),
        ),

        IconButton(
          icon: Icon(_player.playing ? Icons.pause : Icons.play_arrow),
          iconSize: 32.0,
          onPressed: () => setState(() {
            _player.playing ? _player.pause() : _player.play();
          }),
        ),
      ],
    );
  }

  Text generateAudioLoadingFailed() {
    return const Text(
      'Audio loading failed due to network error.',
      style: TextStyle(color: Styles.themeColor),
    );
  }
}

class DurationState {
  const DurationState(
      {required this.progress, required this.buffered, required this.total});
  final Duration progress;
  final Duration buffered;
  final Duration total;
}
