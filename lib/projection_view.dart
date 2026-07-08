import 'package:believers_songbook/models/collection_song.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProjectionView extends StatefulWidget {
  final List<CollectionSong> songs;
  final int initialIndex;

  const ProjectionView({
    required this.songs,
    this.initialIndex = 0,
    super.key,
  });

  @override
  State<ProjectionView> createState() => _ProjectionViewState();
}

class _ProjectionViewState extends State<ProjectionView> {
  late int _currentIndex;
  double _fontSize = 28.0;
  final ScrollController _scrollController = ScrollController();
  AnimationStatusListener? _routeAnimationListener;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeAnimationListener != null) return;
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null) {
      _applySystemUI();
      return;
    }
    if (animation.isCompleted) {
      _applySystemUI();
    } else {
      _routeAnimationListener = (status) {
        if (status == AnimationStatus.completed) {
          _applySystemUI();
          animation.removeStatusListener(_routeAnimationListener!);
        }
      };
      animation.addStatusListener(_routeAnimationListener!);
    }
  }

  void _applySystemUI() {
    if (!mounted) return;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _goToPrevious() {
    setState(() {
      _currentIndex--;
      _scrollController.jumpTo(0);
    });
  }

  void _goToNext() {
    setState(() {
      _currentIndex++;
      _scrollController.jumpTo(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.songs[_currentIndex];
    final canGoPrev = _currentIndex > 0;
    final canGoNext = _currentIndex < widget.songs.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _NavButton(
                icon: Icons.chevron_left,
                enabled: canGoPrev,
                onTap: _goToPrevious,
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 40, horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          song.title,
                          style: TextStyle(
                            fontSize: _fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          song.lyrics,
                          style: TextStyle(fontSize: _fontSize),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _NavButton(
                icon: Icons.chevron_right,
                enabled: canGoNext,
                onTap: _goToNext,
              ),
            ],
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                _OverlayButton(
                  icon: Icons.remove,
                  onTap: () => setState(
                    () => _fontSize = (_fontSize - 2).clamp(12.0, 80.0),
                  ),
                ),
                const SizedBox(width: 4),
                _OverlayButton(
                  icon: Icons.add,
                  onTap: () => setState(
                    () => _fontSize = (_fontSize + 2).clamp(12.0, 80.0),
                  ),
                ),
                const SizedBox(width: 4),
                _OverlayButton(
                  icon: Icons.close,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Center(
            child: Icon(
              icon,
              size: 40,
              color: enabled
                  ? Theme.of(context).iconTheme.color
                  : Colors.grey.withOpacity(0.2),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _OverlayButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black26,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}
