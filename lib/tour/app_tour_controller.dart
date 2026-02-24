import 'package:flutter/material.dart';
import 'package:flutter_welcome_kit/core/enums.dart';
import 'package:flutter_welcome_kit/core/tour_controller.dart';
import 'package:flutter_welcome_kit/core/tour_step.dart';
import 'package:flutter_welcome_kit/widgets/progress_indicator.dart';
import 'package:provider/provider.dart';

import '../providers/main_page_settings.dart';
import 'tour_ids.dart';

class AppTourController extends ChangeNotifier {
  static const Color _defaultTourCardColor = Colors.green;
  final Map<String, GlobalKey> _targets = {};
  final Map<String, BuildContext> _screenContexts = {};
  final Map<String, Future<void> Function()> _actions = {};

  final Duration _stepDelay = const Duration(milliseconds: 350);
  final Duration _retryDelay = const Duration(milliseconds: 400);
  final int _maxWaitAttempts = 20;
  final Duration _pageSwitchDelay = const Duration(milliseconds: 500);

  final List<_TourStepSpec> _steps = <_TourStepSpec>[
    const _TourStepSpec(
      screenId: TourIds.songsScreen,
      targetId: TourIds.songsSettingsMenu,
      title: 'Songs Options',
      description: 'Open the song screen settings.',
      allowTargetTap: true,
      isLast: false,
      buttonLabel: 'Continue',
    ),
    const _TourStepSpec(
      screenId: TourIds.songsSettingsSheetScreen,
      targetId: TourIds.songsSettingsSortChip,
      title: 'Sort & Search',
      description:
          'Use these options to customize how the song screen looks and behaves.',
      beforeShowActionId: TourIds.songsSettingsSheetAction,
      isLast: false,
      buttonLabel: 'Continue',
    ),
    const _TourStepSpec(
      screenId: TourIds.songBooksScreen,
      targetId: TourIds.songBooksFirstCard,
      title: 'Songbooks',
      description: 'Choose any songbook from churches around the world',
      isLast: false,
      buttonLabel: 'Continue',
    ),
    const _TourStepSpec(
      screenId: TourIds.collectionsScreen,
      targetId: TourIds.collectionsAddFab,
      title: 'Collections',
      description: 'Create your own collection of songs.',
      isLast: false,
      buttonLabel: 'Continue',
    ),
    const _TourStepSpec(
      screenId: TourIds.aboutScreen,
      targetId: TourIds.aboutSettingsCog,
      title: 'About Settings',
      description: 'Adjust app settings here.',
      allowTargetTap: true,
      isLast: false,
      buttonLabel: 'Continue',
    ),
    const _TourStepSpec(
      screenId: TourIds.aboutScreen,
      targetId: TourIds.aboutSettingsSheet,
      title: 'Language and Theme',
      description: 'Change app language and theme here.',
      beforeShowActionId: TourIds.aboutSettingsSheetAction,
      isLast: true,
      buttonLabel: 'Done',
    ),
  ];

  TourController? _activeController;
  BuildContext? _rootContext;
  BuildContext? _navigationContext;
  int _currentIndex = 0;
  bool _isRunning = false;
  bool _isAdvancing = false;

  void registerTarget(String id, GlobalKey key) {
    _targets[id] = key;
    debugPrint('Tour register target: $id');
  }

  void registerScreenContext(String screenId, BuildContext context) {
    _screenContexts[screenId] = context;
    debugPrint('Tour register screen context: $screenId');
    if (_isPrimaryScreen(screenId)) {
      _navigationContext = context;
      debugPrint('Tour navigation context set from $screenId.');
    }
  }

  void registerAction(String id, Future<void> Function() action) {
    _actions[id] = action;
  }

  Future<void> start(BuildContext context) async {
    if (_isRunning) {
      _stop();
    }
    _rootContext = context;
    _currentIndex = 0;
    _isRunning = true;
    await _showCurrentStep();
  }

  void _stop() {
    _closeOpenSheets();
    _activeController?.end();
    _activeController = null;
    _isRunning = false;
    _isAdvancing = false;
  }

  Future<void> _advance() async {
    if (_isAdvancing) return;
    _isAdvancing = true;
    debugPrint(
        'Tour advancing from step ${_currentIndex + 1}/${_steps.length}.');
    final previousSpec = _steps[_currentIndex];
    _maybeCloseBottomSheet(previousSpec);
    _currentIndex++;
    if (_currentIndex >= _steps.length) {
      debugPrint('Tour finished all steps.');
      _stop();
      return;
    }
    debugPrint(
      'Tour moving to step ${_currentIndex + 1}/${_steps.length}: '
      '${_steps[_currentIndex].screenId}/${_steps[_currentIndex].targetId}',
    );
    await _showCurrentStep();
    _isAdvancing = false;
  }

  void _skip() {
    _stop();
  }

  Future<void> _showCurrentStep() async {
    if (!_isRunning || _rootContext == null) return;
    final spec = _steps[_currentIndex];
    debugPrint(
      'Tour show step ${_currentIndex + 1}/${_steps.length}: '
      '${spec.screenId}/${spec.targetId}',
    );

    final didNavigate = await _navigateToScreen(spec.screenId);
    if (didNavigate) {
      debugPrint('Tour navigating to screen ${spec.screenId}.');
      await Future.delayed(_pageSwitchDelay);
      await WidgetsBinding.instance.endOfFrame;
    }
    if (spec.beforeShowActionId != null) {
      final action = _actions[spec.beforeShowActionId!];
      if (action != null) {
        await action();
      }
    }
    await Future.delayed(_stepDelay);

    final targetKey = await _waitForTarget(spec.targetId);
    final screenContext = await _waitForScreenContext(spec.screenId);

    if (targetKey == null || screenContext == null) {
      debugPrint(
        'Tour step skipped: missing target or context for ${spec.screenId}/${spec.targetId}',
      );
      debugPrint(
        'Tour debug: targetKey=${targetKey != null}, '
        'screenContext=${screenContext != null}',
      );
      _stop();
      return;
    }

    _activeController = TourController(
      context: screenContext,
      steps: [
        TourStep(
          key: targetKey,
          title: spec.title,
          description: spec.description,
          backgroundColor: spec.backgroundColor,
          animation: StepAnimation.fadeSlideUp,
          showPulse: true,
          allowTargetTap: spec.allowTargetTap,
          isLast: spec.isLast,
          buttonLabel: spec.buttonLabel,
          showProgress: false,
          customContent: _TourStepContent(
            description: spec.description,
            backgroundColor: spec.backgroundColor,
            currentStep: _currentIndex,
            totalSteps: _steps.length,
            showProgress: spec.showProgress,
          ),
        ),
      ],
      onComplete: () {
        debugPrint(
          'Tour complete step ${_currentIndex + 1}/${_steps.length}: '
          '${spec.screenId}/${spec.targetId}',
        );
        _advance();
      },
      onSkip: () {
        debugPrint(
          'Tour skipped at step ${_currentIndex + 1}/${_steps.length}: '
          '${spec.screenId}/${spec.targetId}',
        );
        _skip();
      },
    );

    await _activeController!.start();
  }

  BuildContext? _bestNavigationContext() {
    if (_navigationContext != null) return _navigationContext;
    if (_rootContext != null) return _rootContext;
    if (_screenContexts.isNotEmpty) {
      return _screenContexts.values.first;
    }
    return null;
  }

  Future<bool> _navigateToScreen(String screenId) async {
    final context = _bestNavigationContext();
    if (context == null) {
      debugPrint('Tour navigation failed: no navigation context available.');
      return false;
    }
    final settings = context.read<MainPageSettings>();

    final targetIndex = _screenIndex(screenId);
    if (targetIndex == null) {
      debugPrint('Tour navigation failed: unknown screenId $screenId.');
      return false;
    }

    if (settings.openPageIndex != targetIndex) {
      debugPrint(
        'Tour switching page index ${settings.openPageIndex} -> $targetIndex '
        'for $screenId',
      );
      settings.setOpenPageIndex(targetIndex);
      return true;
    }
    debugPrint(
      'Tour already on page index ${settings.openPageIndex} for $screenId',
    );
    return false;
  }

  void _maybeCloseBottomSheet(_TourStepSpec spec) {
    if (spec.screenId != TourIds.songsSettingsSheetScreen) {
      return;
    }
    final sheetContext = _screenContexts[TourIds.songsSettingsSheetScreen];
    if (sheetContext == null) return;
    final navigator = Navigator.of(sheetContext);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  void _closeOpenSheets() {
    _closeSongsSettingsSheet();
    _closeAboutSettingsSheet();
  }

  void _closeSongsSettingsSheet() {
    final sheetContext = _screenContexts[TourIds.songsSettingsSheetScreen];
    if (sheetContext == null) return;
    if (sheetContext is Element && !sheetContext.mounted) return;
    final navigator = Navigator.maybeOf(sheetContext);
    if (navigator?.canPop() ?? false) {
      navigator!.pop();
    }
  }

  void _closeAboutSettingsSheet() {
    final sheetKey = _targets[TourIds.aboutSettingsSheet];
    final sheetContext = sheetKey?.currentContext;
    if (sheetContext == null) return;
    if (sheetContext is Element && !sheetContext.mounted) return;
    final navigator = Navigator.maybeOf(sheetContext);
    if (navigator?.canPop() ?? false) {
      navigator!.pop();
    }
  }

  int? _screenIndex(String screenId) {
    switch (screenId) {
      case TourIds.songsScreen:
        return 0;
      case TourIds.songBooksScreen:
        return 1;
      case TourIds.collectionsScreen:
        return 2;
      case TourIds.aboutScreen:
        return 3;
      default:
        return null;
    }
  }

  bool _isPrimaryScreen(String screenId) {
    return screenId == TourIds.songsScreen ||
        screenId == TourIds.songBooksScreen ||
        screenId == TourIds.collectionsScreen ||
        screenId == TourIds.aboutScreen;
  }

  Future<GlobalKey?> _waitForTarget(String targetId) async {
    for (int attempt = 0; attempt < _maxWaitAttempts; attempt++) {
      final key = _targets[targetId];
      if (key != null && key.currentContext != null) {
        return key;
      }
      await Future.delayed(_retryDelay);
    }
    return null;
  }

  Future<BuildContext?> _waitForScreenContext(String screenId) async {
    for (int attempt = 0; attempt < _maxWaitAttempts; attempt++) {
      final context = _screenContexts[screenId];
      if (context != null) {
        return context;
      }
      await Future.delayed(_retryDelay);
    }
    return null;
  }
}

class _TourStepSpec {
  final String screenId;
  final String targetId;
  final String title;
  final String description;
  final bool allowTargetTap;
  final bool isLast;
  final String? buttonLabel;
  final String? beforeShowActionId;
  final Color backgroundColor;
  final bool showProgress;

  const _TourStepSpec({
    required this.screenId,
    required this.targetId,
    required this.title,
    required this.description,
    this.allowTargetTap = false,
    this.isLast = false,
    this.buttonLabel,
    this.beforeShowActionId,
    this.backgroundColor = AppTourController._defaultTourCardColor,
    this.showProgress = true,
  });
}

class _TourStepContent extends StatelessWidget {
  final String description;
  final Color backgroundColor;
  final int currentStep;
  final int totalSteps;
  final bool showProgress;

  const _TourStepContent({
    required this.description,
    required this.backgroundColor,
    required this.currentStep,
    required this.totalSteps,
    required this.showProgress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = backgroundColor != Colors.white
        ? backgroundColor
        : (isDark ? Colors.grey[850]! : Colors.white);
    final textColor = _getContrastingTextColor(cardColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textColor.withValues(alpha: 0.8),
              ),
        ),
        if (showProgress) ...[
          const SizedBox(height: 12),
          Center(
            child: TourProgressIndicator(
              currentStep: currentStep,
              totalSteps: totalSteps,
              style: ProgressIndicatorStyle.dots,
              activeColor: textColor,
              inactiveColor: textColor.withValues(alpha: 0.3),
            ),
          ),
        ],
      ],
    );
  }

  Color _getContrastingTextColor(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}
