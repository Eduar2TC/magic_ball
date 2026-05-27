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
const Duration _answerRevealDelay = Duration(milliseconds: 1500);
const Duration _answerHideDelay = Duration(milliseconds: 3000);
const Duration _sensorShowDuration = Duration(milliseconds: 3000);
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
  final ValueNotifier<double> _ballScaleNotifier = ValueNotifier<double>(1.0);
  final ValueNotifier<double> _sensorIntensityNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<bool> _showAnswerNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String> _currentAnswerNotifier = ValueNotifier<String>('?');
  final ValueNotifier<bool> _showShakeBubblesNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _showBubbleEffectNotifier = ValueNotifier<bool>(false);
  
  String? _lastAnswer;
  bool _isProcessingShake = false;
  bool _isTapMode = false;
  Timer? _sensorHideTimer;
  double _currentIntensity = 0.0;
  double _currentZ = 0.0;

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

    _sensorService.onPositionChanged = (x, y, z) {
      if (!mounted || _isTapMode) return;
      
      _currentZ = z;
      final intensity = math.sqrt(x * x + y * y + z * z).clamp(0.0, 1.0);
      _currentIntensity = intensity;
      
      _ballOffsetNotifier.value = Offset(x * 30, y * 30);
      _ballScaleNotifier.value = 1.0 + (z.abs() * 0.1);
      _sensorIntensityNotifier.value = intensity;
      
      if (!_isProcessingShake && intensity > 0.75) {
        final appState = Provider.of<AppState>(context, listen: false);
        if (appState.shakeToGetAnswerEnabled) {
          _processShake();
        }
      }
    };

    _sensorService.onShakeDetected = (magnitude) {
      if (!mounted || _isProcessingShake || _isTapMode) return;
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.shakeToGetAnswerEnabled) {
        _processShake();
      }
    };
  }

  Future<void> _processShake() async {
    if (_isProcessingShake) return;
    _isProcessingShake = true;
    
    _showAnswerNotifier.value = false;
    _showBubbleEffectNotifier.value = false;
    _showShakeBubblesNotifier.value = true;

    _audio.playShake();

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted || !_isProcessingShake) {
      _isProcessingShake = false;
      return;
    }

    _showShakeBubblesNotifier.value = false;

    final String answer = await _getMagicAnswer();
    if (!mounted || !_isProcessingShake) {
      _isProcessingShake = false;
      return;
    }

    _currentAnswerNotifier.value = answer;

    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted || !_isProcessingShake) {
      _isProcessingShake = false;
      return;
    }

    _showAnswerNotifier.value = true;

    _ballAnimations.answerAnimationController.forward(from: 0.0);

    _sensorHideTimer?.cancel();
    _sensorHideTimer = Timer(_sensorShowDuration, () {
      if (!mounted) {
        _isProcessingShake = false;
        return;
      }
      
      _ballAnimations.answerAnimationController.reverse();
      
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          _showAnswerNotifier.value = false;
          _showBubbleEffectNotifier.value = true;
          _isProcessingShake = false;
        }
      });
    });
  }

  Future<void> _activateTap() async {
    if (_isProcessingShake || _isTapMode) return;
    _isTapMode = true;
    _isProcessingShake = true;
    
    _showAnswerNotifier.value = false;
    _showBubbleEffectNotifier.value = false;
    _showShakeBubblesNotifier.value = true;

    _audio.playShake();

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) {
      _isProcessingShake = false;
      _isTapMode = false;
      return;
    }

    _showShakeBubblesNotifier.value = false;

    final String answer = await _getMagicAnswer();
    if (!mounted) {
      _isProcessingShake = false;
      _isTapMode = false;
      return;
    }

    _currentAnswerNotifier.value = answer;

    await Future.delayed(const Duration(milliseconds: 32));
    if (!mounted) {
      _isProcessingShake = false;
      _isTapMode = false;
      return;
    }

    _showAnswerNotifier.value = true;
    _ballOffsetNotifier.value = Offset.zero;

    await _ballAnimations.ballAnimationController.forward();
    await Future.delayed(_answerRevealDelay);

    _ballAnimations.answerAnimationController.forward();

    await Future.delayed(_answerHideDelay);
    _ballAnimations.answerAnimationController.reverse();

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      _showAnswerNotifier.value = false;
      _showBubbleEffectNotifier.value = true;
      _isProcessingShake = false;
      _isTapMode = false;
    }
  }

  Future<String> _getMagicAnswer() async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final list = await appState.getMagicList();

      if (list.isEmpty) return 'Ask again...';
      if (list.length == 1) return list.first;

      String selected;
      if (_lastAnswer != null && list.contains(_lastAnswer) && list.length > 1) {
        final filteredList = list.where((a) => a != _lastAnswer).toList();
        selected = filteredList.isNotEmpty
            ? filteredList[math.Random().nextInt(filteredList.length)]
            : list[math.Random().nextInt(list.length)];
      } else {
        selected = list[math.Random().nextInt(list.length)];
      }

      _lastAnswer = selected;
      return selected;
    } catch (e) {
      return 'Try again';
    }
  }

  void _onTap() {
    final appState = Provider.of<AppState>(context, listen: false);
    if (!appState.tapToGetAnswerEnabled) return;
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
      _sensorIntensityNotifier.value = 0.0;
    }
  }

  @override
  void dispose() {
    _sensorHideTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _ballAnimations.dispose();
    _ballOffsetNotifier.dispose();
    _ballScaleNotifier.dispose();
    _sensorIntensityNotifier.dispose();
    _showAnswerNotifier.dispose();
    _currentAnswerNotifier.dispose();
    _showShakeBubblesNotifier.dispose();
    _showBubbleEffectNotifier.dispose();
    _sensorService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isTapEnabled = appState.tapToGetAnswerEnabled;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSensorState(appState.shakeToGetAnswerEnabled);
      _sensorService.setShakeSensitivity(appState.shakeSensitivity);
    });

    return FutureBuilder(
      future: _iniDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: _loadingIndicatorColor,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: appState.dataConfigurations?.backgroundColor,
          appBar: AppBar(
            title: Text(
              AppLocalizations.of(context)!.appbarTitle_home,
              style: TextStyle(color: appState.dataConfigurations?.titleAppBarColor),
            ),
            backgroundColor: appState.dataConfigurations?.appBarColor ?? _secondaryGradientColor,
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, size: 40),
                onPressed: () => Navigator.pushNamed(context, '/settings'),
              ),
            ],
          ),
          body: SafeArea(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [_primaryGradientColor, _secondaryGradientColor],
                  stops: [_gradientStop1, 1],
                  center: Alignment.center,
                  radius: _gradientRadius,
                ),
              ),
              child: Center(
                child: GestureDetector(
                  onTap: isTapEnabled ? _onTap : null,
                  child: ValueListenableBuilder<Offset>(
                    valueListenable: _ballOffsetNotifier,
                    builder: (context, offset, _) {
                      return ValueListenableBuilder<double>(
                        valueListenable: _ballScaleNotifier,
                        builder: (context, scale, _) {
                          return Transform.translate(
                            offset: offset,
                            child: Transform.scale(
                              scale: scale,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  BallFigure(ballAnimations: _ballAnimations),
                                  
                                  ValueListenableBuilder<String>(
                                    valueListenable: _currentAnswerNotifier,
                                    builder: (context, currentAnswer, _) {
                                      return ValueListenableBuilder<bool>(
                                        valueListenable: _showAnswerNotifier,
                                        builder: (context, showAnswer, _) {
                                          final shouldShow = showAnswer || 
                                              (!_isProcessingShake && _currentIntensity > 0.3);
                                          
                                          return AnimatedOpacity(
                                            opacity: shouldShow ? 1.0 : 0.0,
                                            duration: const Duration(milliseconds: 300),
                                            child: AnimatedScale(
                                              scale: shouldShow ? 0.8 + (_currentIntensity * 0.2) : 0.0,
                                              duration: const Duration(milliseconds: 300),
                                              curve: Curves.elasticOut,
                                              child: LiquidTetrahedronContainer(
                                                key: ValueKey('tetra_$currentAnswer'),
                                                initialAnswer: currentAnswer,
                                                sensorIntensity: _currentIntensity,
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  
                                  const BallShadow(),
                                  
                                  ValueListenableBuilder<bool>(
                                    valueListenable: _showShakeBubblesNotifier,
                                    builder: (context, showBubbles, _) {
                                      return BubblesShackingEffectContainer(
                                        showBubbles: showBubbles,
                                        answer: '',
                                      );
                                    },
                                  ),
                                  
                                  BubbleLoopEffectContainer(
                                    showBubbles: _showBubbleEffectNotifier,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
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