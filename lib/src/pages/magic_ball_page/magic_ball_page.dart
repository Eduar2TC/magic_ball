import 'dart:async';
import 'dart:math' as math;
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:magic_ball/src/models/app_state.dart';
import 'package:magic_ball/src/pages/magic_ball_page/components/ball_figure.dart';
import 'package:magic_ball/src/pages/magic_ball_page/components/ball_shadow.dart';
import 'package:magic_ball/src/pages/magic_ball_page/components/bubble_loop_effect_container.dart';
import 'package:magic_ball/src/pages/magic_ball_page/components/bubbles_shacking_effect_container.dart';
import 'package:magic_ball/src/pages/magic_ball_page/components/liquid_tetrahedron_container.dart';
import 'package:magic_ball/src/pages/magic_ball_page/custom_widgets/animations.dart';
import 'package:magic_ball/src/services/initialization_local_data_service.dart';
import 'package:magic_ball/src/utils/audio.dart';
import 'package:magic_ball/src/utils/data_configurations.dart';
import 'package:magic_ball/src/core/localizations/i18n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'custom_widgets/triangle.dart';

class MagicBallPage extends StatefulWidget {
  const MagicBallPage({super.key});

  @override
  MagicBallPageState createState() => MagicBallPageState();
}

class MagicBallPageState extends State<MagicBallPage>
    with TickerProviderStateMixin {
  late final Audio audio;
  String? magicAnswer;
  bool isOnPressed = false;
  late BallAnimations ballAnimations;
  final ValueNotifier<void> notifier = ValueNotifier<void>(null);
  final ValueNotifier<bool> isOnPressedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> magicAnswerNotifier =
      ValueNotifier<String?>(null);
  final ValueNotifier<bool> showShakeBubblesNotifier =
      ValueNotifier<bool>(false);
  final ValueNotifier<bool> showBubbleEffectNotifier =
      ValueNotifier<bool>(false); //TODO: fix this functionallity
  final ValueNotifier<bool> showLiquidTetrahedronNotifier =
      ValueNotifier<bool>(false);
  late Future<void> _iniDataFuture;

  @override
  void initState() {
    super.initState();
    audio = Audio();
    ballAnimations = BallAnimations(notifier);
    ballAnimations.initializeAnimations(this, audio.playPop);
    //showBubbleEffect with delayed
    Future.delayed(const Duration(milliseconds: 3500), () {
      showBubbleEffectNotifier.value = true;
      showLiquidTetrahedronNotifier.value = true;
    });
    _iniDataFuture = _initDataService();
  }

  @override
  void dispose() {
    ballAnimations.dispose();
    notifier.dispose();
    isOnPressedNotifier.dispose();
    magicAnswerNotifier.dispose();
    showShakeBubblesNotifier.dispose();
    showBubbleEffectNotifier.dispose();
    showLiquidTetrahedronNotifier.dispose();
    super.dispose();
  }

  Future<String?> getMagicWord(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.getMagicList();
    if (appState.magicList == null || appState.magicList!.isEmpty) {
      return 'Empty';
    }
    return appState
        .magicList?[math.Random().nextInt(appState.magicList!.length)];
  }

  @override
  Widget build(BuildContext context) {
    final AppState appState = Provider.of<AppState>(context);
    final DataConfigurations? dataConfigurations = appState.dataConfigurations;
    final String appBarTitle = AppLocalizations.of(context)!.appbarTitle_home;

    return FutureBuilder(
      future: _iniDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xff10024f),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xff10024f)),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error loading data $snapshot.error '),
            ),
          );
        }
        return Scaffold(
          backgroundColor: dataConfigurations?.backgroundColor,
          appBar: AppBar(
            title: Text(
              appBarTitle,
              style: TextStyle(color: dataConfigurations?.titleAppBarColor),
            ),
            backgroundColor:
                dataConfigurations?.appBarColor ?? const Color(0xff10024f),
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
                  colors: [Color(0xff28237d), Color(0xff10024f)],
                  stops: [0.65, 1],
                  center: Alignment.center,
                  radius: 0.8,
                ),
              ),
              child: Center(
                child: GestureDetector(
                  onTap: handleMagicBallPress,
                  child: buildMagicBallContent(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void handleMagicBallPress() {
    if (!isOnPressedNotifier.value) {
      isOnPressedNotifier.value = true;
      showShakeBubblesNotifier.value = true;
      showBubbleEffectNotifier.value = false;
      showLiquidTetrahedronNotifier.value = false;
      audio.playShake();

      ballAnimations.ballAnimationController.forward().then((_) {
        //TODO: REFACTORIZE THIS
        getMagicWord(context).then((value) {
          magicAnswerNotifier.value = value;
        });
        Future.delayed(const Duration(milliseconds: 1500), () {
          ballAnimations.answerAnimationController.forward();
          isOnPressedNotifier.value = false;
          //show bubbles
          ballAnimations.ballAnimation.isAnimating
              ? showShakeBubblesNotifier.value = true
              : showShakeBubblesNotifier.value = false;
          ballAnimations.ballAnimation.isAnimating
              ? showBubbleEffectNotifier.value = false
              : showBubbleEffectNotifier.value = true;
          showLiquidTetrahedronNotifier.value = true;
        }).then((_) {
          //hide magic response
          Future.delayed(const Duration(milliseconds: 3000), () {
            ballAnimations.answerAnimationController.reverse();
          });
        });
      });
    }
  }

  Widget buildMagicBallContent() {
    return Stack(
      alignment: Alignment.center,
      children: [
        BallFigure(
          ballAnimations: ballAnimations,
        ),
        LiquidTetrahedronContainer(
          showLiquid: showLiquidTetrahedronNotifier,
          magicAnswerNotifier: magicAnswerNotifier,
        ),
        //buildMagicAnswer(),
        const BallShadow(),
        BubblesShackingEffectContainer(
          showBubbles: showShakeBubblesNotifier,
          anwer: '', //TODO: fix or remmove this parameter
        ),
        BubbleLoopEffectContainer(
          showBoobles: showBubbleEffectNotifier,
        ),
      ],
    );
  }

  double magicAnswerCounter(String? magicAnswer) {
    if (magicAnswer != null) {
      if (magicAnswer.length <= 3) {
        return 60;
      }
    }
    return 20;
  }

  FractionalOffset calculateFractionalOffset(double angle) {
    final x = 0.5 + 0.5 * math.cos(angle);
    final y = 0.5 + 0.5 * math.sin(angle);
    return FractionalOffset(x, y);
  }

  Widget buildMagicAnswer() {
    return ValueListenableBuilder<String?>(
      valueListenable: magicAnswerNotifier,
      builder: (context, magicAnswer, _) {
        final randomZAngle = (math.Random().nextDouble() * (math.pi / 4)) +
            (-math.pi / 4); // random z between 45 to 90 degrees
        final alternateRotationDirection = math.Random().nextBool();
        return ClipOval(
          clipBehavior: Clip.antiAlias,
          child: AnimatedBuilder(
            animation: ballAnimations.answerAnimation,
            builder: (context, _) {
              return Transform.translate(
                offset: Offset(0, ballAnimations.answerAnimation.value),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 0),
                  opacity: ballAnimations.answerAnimation.value,
                  child: Transform(
                    alignment: FractionalOffset.lerp(
                      FractionalOffset.topLeft,
                      FractionalOffset.bottomRight,
                      0.5,
                    ), //rotation from top center
                    // 3D rotation effect
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..translate(
                        0.0,
                        -100.0 * (1 - ballAnimations.answerAnimation.value),
                        0.0,
                      )
                      ..setRotationZ(
                        alternateRotationDirection
                            ? randomZAngle *
                                ballAnimations.answerAnimation.value
                            : -randomZAngle *
                                ballAnimations.answerAnimation.value,
                      )
                      ..scale(1.5 -
                          math.cos(ballAnimations.answerAnimation.value *
                                  math.pi *
                                  0.3) *
                              1.0),
                    child: MagicBallTriangle(
                      magicAnswer: magicAnswer ?? '',
                      size: MediaQuery.of(context).size.width * 0.4,
                    ),
                  ),
                ),
              );
            },
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

class RealisticBubbleEffect extends StatefulWidget {
  final double size;
  final int maxBubbles;
  const RealisticBubbleEffect({
    super.key,
    this.size = 300,
    this.maxBubbles = 12,
  });

  @override
  State<RealisticBubbleEffect> createState() => _RealisticBubbleEffectState();
}

class _RealisticBubbleEffectState extends State<RealisticBubbleEffect>
    with TickerProviderStateMixin {
  final List<_BubbleModel> _bubbles = [];
  bool _running = true;

  @override
  void initState() {
    super.initState();
    _scheduleNextBubble();
  }

  void _scheduleNextBubble() {
    if (!_running) return;
    final delay = Duration(milliseconds: 300 + Random().nextInt(700));
    Future.delayed(delay, () {
      if (!_running) return;
      if (_bubbles.length < widget.maxBubbles) {
        setState(() {
          _bubbles.add(_BubbleModel.random(widget.size, this, onRemove: () {
            setState(() {});
          }));
        });
      }
      _scheduleNextBubble();
    });
  }

  @override
  void dispose() {
    _running = false;
    for (final b in _bubbles) {
      b.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          children:
              _bubbles.where((b) => !b.removed).map((b) => b.build()).toList(),
        ),
      ),
    );
  }
}

class _BubbleModel {
  final AnimationController controller;
  final Animation<double> appearAnim;
  final double startX, startY, endX, endY, size;
  final double opacity;
  bool removed = false;
  final VoidCallback onRemove;

  _BubbleModel._(
    this.controller,
    this.appearAnim,
    this.startX,
    this.startY,
    this.endX,
    this.endY,
    this.size,
    this.opacity,
    this.onRemove,
  );

  factory _BubbleModel.random(double size, TickerProvider vsync,
      {required VoidCallback onRemove}) {
    final random = Random();
    final radius = size / 2;
    final centerX = size / 2;
    final centerY = size / 2;

    final bubbleSize = random.nextDouble() * 18 + 8;
    final angle = random.nextDouble() * 2 * pi;
    final distance = random.nextDouble() * (radius - bubbleSize);

    final startX = centerX + distance * cos(angle);
    final startY = centerY + distance * sin(angle);

    final endY = startY - (radius * 0.8);
    final endX = startX + (random.nextDouble() - 0.5) * radius * 0.3;

    final duration = Duration(milliseconds: 1200 + random.nextInt(1800));
    final opacity = random.nextDouble() * 0.4 + 0.4;

    final controller = AnimationController(
      vsync: vsync,
      duration: duration,
    )..forward();

    final appearAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: controller,
          curve: const Interval(0.0, 0.2, curve: Curves.easeOut)),
    );

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        onRemove();
      }
    });

    return _BubbleModel._(
      controller,
      appearAnim,
      startX,
      startY,
      endX,
      endY,
      bubbleSize,
      opacity,
      onRemove,
    );
  }

  void dispose() => controller.dispose();

  Widget build() {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(controller.value);
        final x = lerpDouble(startX, endX, t)!;
        final y = lerpDouble(startY, endY, t)!;
        final scale = appearAnim.value * (0.8 + 0.4 * (1 - t));
        final bubbleOpacity = opacity * (1 - t) * appearAnim.value;
        if (controller.isCompleted) removed = true;
        return Positioned(
          left: x,
          top: y,
          child: Opacity(
            opacity: bubbleOpacity,
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
