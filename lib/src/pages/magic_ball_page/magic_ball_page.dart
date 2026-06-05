import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:magic_ball/src/models/app_state.dart';
import 'package:magic_ball/src/pages/magic_ball_page/components/ball_figure.dart';
import 'package:magic_ball/src/pages/magic_ball_page/components/ball_shadow.dart';
import 'package:magic_ball/src/pages/magic_ball_page/components/bubble_loop_effect_container.dart';
import 'package:magic_ball/src/pages/magic_ball_page/components/bubbles_shacking_effect_container.dart';
import 'package:magic_ball/src/pages/magic_ball_page/components/liquid_tetrahedron_container.dart';
import 'package:magic_ball/src/pages/magic_ball_page/custom_widgets/animations.dart';
import 'package:magic_ball/src/services/initialization_local_data_service.dart';
import 'package:magic_ball/src/services/sensor_service.dart';
import 'package:magic_ball/src/utils/audio.dart';
import 'package:magic_ball/src/core/localizations/i18n/app_localizations.dart';
import 'package:provider/provider.dart';

const Duration _bubbleEffectDelay = Duration(milliseconds: 3500);
const Duration _answerShowDuration = Duration(seconds: 3);
const Color _primaryGradientColor = Color(0xff28237d);
const Color _secondaryGradientColor = Color(0xff10024f);
const Color _loadingIndicatorColor = Color(0xff10024f);
const double _gradientRadius = 0.8;
const double _gradientStop1 = 0.65;

class MagicBallPage extends StatefulWidget {
  const MagicBallPage({super.key});

  @override
  MagicBallPageState createState() => MagicBallPageState();
}

class MagicBallPageState extends State<MagicBallPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final Audio _audio;
  late BallAnimations _ballAnimations;
  late Future<void> _iniDataFuture;
  late final SensorService _sensorService;

  final ValueNotifier<Offset> _ballOffsetNotifier = ValueNotifier<Offset>(Offset.zero);
  final ValueNotifier<String> _currentAnswerNotifier = ValueNotifier<String>('?');
  final ValueNotifier<bool> _showBubbleEffectNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isTetraVisibleNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _showShakeBubblesNotifier = ValueNotifier<bool>(false);

  double _maxPixelOffset = 60.0;
  String? _lastAnswer;
  bool _isTapMode = false;
  Timer? _answerTimer;
  String _currentAnswer = '?';
  bool _shakeSequenceActive = false;

  VoidCallback? _shakingActiveListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audio = Audio();
    _ballAnimations = BallAnimations(ValueNotifier<void>(null));
    _ballAnimations.initializeAnimations(this, _audio.playPop);
    _initSensor();
    _iniDataFuture = _initDataService();

    Future.delayed(_bubbleEffectDelay, () {
      if (mounted) _showBubbleEffectNotifier.value = true;
    });
  }

  void _initSensor() {
    _sensorService = SensorService();

    _sensorService.onPositionChanged = (x, y) {
      if (!mounted || _isTapMode) return;
      _ballOffsetNotifier.value = Offset(x * _maxPixelOffset, y * _maxPixelOffset);
    };

    _shakingActiveListener = () {
      if (!mounted || _isTapMode) return;
      final appState = Provider.of<AppState>(context, listen: false);
      if (!appState.shakeToGetAnswerEnabled) return;

      final isActive = _sensorService.isShakingActive.value;

      if (isActive && !_shakeSequenceActive) {
        _beginShakeSequence();
      } else if (!isActive && _shakeSequenceActive) {
        _endShakeSequence();
      }
    };
    _sensorService.isShakingActive.addListener(_shakingActiveListener!);
  }

  void _updateMaxPixelOffset(Size screenSize) {
    final ballRadius = screenSize.width * 0.55 / 2;
    final availableX = screenSize.width / 2 - ballRadius - 8;
    final availableY = screenSize.height / 2 - ballRadius - 8;
    _maxPixelOffset = math.min(availableX, availableY).clamp(0.0, 80.0);
  }

  void _beginShakeSequence() {
    _shakeSequenceActive = true;
    _answerTimer?.cancel();
    _answerTimer = null;

    if (_isTetraVisibleNotifier.value) _isTetraVisibleNotifier.value = false;
    _showBubbleEffectNotifier.value = false;
    
    // Iniciar sonido en bucle continuo y mostrar animación continua
    _audio.startShakeLoop();
    _showShakeBubblesNotifier.value = true;
  }

  Future<void> _endShakeSequence() async {
    _shakeSequenceActive = false;
    
    // Detener el bucle de sonido y ocultar burbujas
    _audio.stopShakeLoop();
    if (mounted) _showShakeBubblesNotifier.value = false;

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final answer = await _getMagicAnswer();
    if (!mounted) return;

    _currentAnswer = answer;
    _currentAnswerNotifier.value = answer;
    _isTetraVisibleNotifier.value = true;
    _audio.playPop();

    _answerTimer = Timer(_answerShowDuration, () {
      if (!mounted) return;
      _isTetraVisibleNotifier.value = false;

      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        _showBubbleEffectNotifier.value = true;
        final appState = Provider.of<AppState>(context, listen: false);
        if (appState.shakeToGetAnswerEnabled && !_sensorService.isListening) {
          _sensorService.startListening();
        }
      });
    });
  }

  Future<void> _activateTap() async {
    if (_isTapMode) return;
    _isTapMode = true;
    _sensorService.stopListening();
    _answerTimer?.cancel();
    _answerTimer = null;

    if (_isTetraVisibleNotifier.value) _isTetraVisibleNotifier.value = false;
    _showBubbleEffectNotifier.value = false;
    _showShakeBubblesNotifier.value = true;

    // Para el tap, usamos el sonido de un solo disparo
    _audio.playShakeOneShot();
    
    await _ballAnimations.ballAnimationController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) { _isTapMode = false; return; }

    _showShakeBubblesNotifier.value = false;
    final answer = await _getMagicAnswer();
    if (!mounted) { _isTapMode = false; return; }

    _currentAnswer = answer;
    _currentAnswerNotifier.value = answer;
    _isTetraVisibleNotifier.value = true;
    _audio.playPop();

    _answerTimer = Timer(_answerShowDuration, () {
      if (!mounted) return;
      _isTetraVisibleNotifier.value = false;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        _showBubbleEffectNotifier.value = true;
        _isTapMode = false;
        _answerTimer = null;
        final appState = Provider.of<AppState>(context, listen: false);
        if (appState.shakeToGetAnswerEnabled) _sensorService.startListening();
      });
    });
  }

  Future<String> _getMagicAnswer() async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final list = await appState.getMagicList();
      if (list.isEmpty) return 'Ask again...';
      if (list.length == 1) return list.first;

      String selected;
      if (_lastAnswer != null && list.contains(_lastAnswer) && list.length > 1) {
        final filtered = list.where((a) => a != _lastAnswer).toList();
        selected = filtered.isNotEmpty
            ? filtered[math.Random().nextInt(filtered.length)]
            : list[math.Random().nextInt(list.length)];
      } else {
        selected = list[math.Random().nextInt(list.length)];
      }
      _lastAnswer = selected;
      return selected;
    } catch (_) {
      return 'Try again';
    }
  }

  void _onTap() {
    final appState = Provider.of<AppState>(context, listen: false);
    if (!appState.tapToGetAnswerEnabled || _isTapMode) return;
    _activateTap();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final appState = Provider.of<AppState>(context, listen: false);
    if (state == AppLifecycleState.resumed && appState.shakeToGetAnswerEnabled) {
      _sensorService.startListening();
    } else if (state == AppLifecycleState.paused) {
      _sensorService.stopListening();
    }
  }

  void _updateSensorState(bool enabled) {
    if (enabled && !_sensorService.isListening) {
      _sensorService.startListening();
    } else if (!enabled && _sensorService.isListening) {
      _sensorService.stopListening();
      _ballOffsetNotifier.value = Offset.zero;
    }
  }

  @override
  void dispose() {
    _answerTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (_shakingActiveListener != null) {
      _sensorService.isShakingActive.removeListener(_shakingActiveListener!);
    }
    _ballAnimations.dispose();
    _ballOffsetNotifier.dispose();
    _currentAnswerNotifier.dispose();
    _showBubbleEffectNotifier.dispose();
    _isTetraVisibleNotifier.dispose();
    _showShakeBubblesNotifier.dispose();
    _sensorService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isTapEnabled = appState.tapToGetAnswerEnabled;
    final screenSize = MediaQuery.of(context).size;

    _updateMaxPixelOffset(screenSize);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSensorState(appState.shakeToGetAnswerEnabled);
      _sensorService.setShakeSensitivity(appState.shakeSensitivity);
    });

    return FutureBuilder(
      future: _iniDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(backgroundColor: _loadingIndicatorColor, body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          backgroundColor: appState.dataConfigurations?.backgroundColor,
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.appbarTitle_home, style: TextStyle(color: appState.dataConfigurations?.titleAppBarColor)),
            backgroundColor: appState.dataConfigurations?.appBarColor ?? _secondaryGradientColor,
            centerTitle: true,
            actions: [IconButton(icon: const Icon(Icons.settings, size: 40), onPressed: () => Navigator.pushNamed(context, '/settings'))],
          ),
          body: SafeArea(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(colors: [_primaryGradientColor, _secondaryGradientColor], stops: [_gradientStop1, 1], center: Alignment.center, radius: _gradientRadius),
              ),
              child: Center(
                child: GestureDetector(
                  onTap: isTapEnabled ? _onTap : null,
                  child: ValueListenableBuilder<Offset>(
                    valueListenable: _ballOffsetNotifier,
                    builder: (context, offset, child) {
                      final safeOffset = Offset(offset.dx.clamp(-_maxPixelOffset, _maxPixelOffset), offset.dy.clamp(-_maxPixelOffset, _maxPixelOffset));
                      return Transform.translate(offset: safeOffset, child: child);
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        BallFigure(ballAnimations: _ballAnimations),
                        ValueListenableBuilder<bool>(
                          valueListenable: _isTetraVisibleNotifier,
                          builder: (context, isVisible, _) {
                            if (!isVisible) return const SizedBox.shrink();
                            return IgnorePointer(
                              child: LiquidTetrahedronContainer(
                                key: ValueKey('tetra_$_currentAnswer'),
                                initialAnswer: _currentAnswer,
                                sensorIntensity: 0.0,
                              ),
                            );
                          },
                        ),
                        // Animación continua de burbujas (sin shakeBurst)
                        ValueListenableBuilder<bool>(
                          valueListenable: _showShakeBubblesNotifier,
                          builder: (context, showBubbles, _) {
                            if (!showBubbles) return const SizedBox.shrink();
                            return const IgnorePointer(
                              child: BubblesShackingEffectContainer(
                                showBubbles: true,
                                answer: '',
                              ),
                            );
                          },
                        ),
                        IgnorePointer(
                          child: BubbleLoopEffectContainer(showBubbles: ValueNotifier<bool>(false)), // Nota: BubbleLoopEffectContainer ya maneja su propio notifier internamente si lo diseñaste así, o usa _showBubbleEffectNotifier
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _initDataService() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final initService = InitializationService(appState.sharedPreferencesUtils);
    await initService.initializeAll(appState.currentLanguage);
  }
}