import 'dart:async';
import 'dart:math' as math;
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:magic_ball/src/models/app_state.dart';
import 'package:magic_ball/src/pages/magic_ball_page/custom_widgets/animations.dart';
import 'package:magic_ball/src/pages/magic_ball_page/custom_widgets/liquid_tetrahedron.dart';
import 'package:magic_ball/src/services/initialization_local_data_service.dart';
import 'package:magic_ball/src/utils/lang_helper.dart';
import 'package:provider/provider.dart';
import 'package:magic_ball/src/utils/audio.dart';

import 'custom_widgets/bubble_effect.dart';
import 'custom_widgets/sphere_figure.dart';
import 'custom_widgets/shaking_bubble_effect.dart';
import 'custom_widgets/triangle.dart';

import 'package:vector_math/vector_math_64.dart' as vmath;

class MagicBallPage extends StatefulWidget {
  const MagicBallPage({super.key});

  @override
  MagicBallPageState createState() => MagicBallPageState();
}

class MagicBallPageState extends State<MagicBallPage> with TickerProviderStateMixin {
  late final Audio audio;
  String? magicAnswer;
  bool isOnPressed = false;
  late BallAnimations ballAnimations;
  final ValueNotifier<void> notifier = ValueNotifier<void>(null);
  final ValueNotifier<bool> isOnPressedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> magicAnswerNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<bool> showShakeBubblesNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> showBubbleEffectNotifier = ValueNotifier<bool>(false); //TODO: fix this functionallity
  final ValueNotifier<bool> showLiquidTetrahedronNotifier = ValueNotifier<bool>(false);
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
    return appState.magicList?[math.Random().nextInt(appState.magicList!.length)];
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final dataConfigurations = appState.dataConfigurations;
    final currentLang = appState.currentLanguage;
    final langStrings = dataConfigurations?.langStrings;
    final appBarTitle = getLang(langStrings, currentLang, ['appbarTitle', 'home']) ?? 'Ask anything';

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
            backgroundColor: dataConfigurations?.appBarColor ?? const Color(0xff10024f),
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
          ballAnimations.ballAnimation.isAnimating ? showShakeBubblesNotifier.value = true : showShakeBubblesNotifier.value = false;
          ballAnimations.ballAnimation.isAnimating ? showBubbleEffectNotifier.value = false : showBubbleEffectNotifier.value = true;
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
        buildBallFigure(),
        buildLiquidTetrahedron(),
        //buildMagicAnswer(),
        buildShadowAnimation(),
        buildShakingBubbleEffect(),
        buildBubbleEffect(),

      ],
    );
  }

  Widget buildBallFigure() {
    final sphereWidth = MediaQuery.of(context).size.width * 0.9;
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 3000),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.fastEaseInToSlowEaseOut,
      builder: (context, value, _) {
        return Transform.scale(
          scale: value,
          child: Transform.rotate(
            angle: (2 * math.pi) * value,
            child: AnimatedBuilder(
              animation: ballAnimations.ballAnimation,
              builder: (context, _) {
                return Transform.translate(
                  offset: Offset(
                    bounce(ballAnimations.ballAnimation.value),
                    math.sin(ballAnimations.ballAnimation.value * 500) * 25,
                  ),
                  child: SphereFigure(size: sphereWidth), //figure of the magic ball
                );
              },
            ),
          ),
        );
      },
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
        final randomZAngle = (math.Random().nextDouble() * (math.pi / 4)) + (-math.pi / 4); // random z between 45 to 90 degrees
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
                        alternateRotationDirection ? randomZAngle * ballAnimations.answerAnimation.value : -randomZAngle * ballAnimations.answerAnimation.value,
                      )
                      ..scale(1.5 - math.cos(ballAnimations.answerAnimation.value * math.pi * 0.3) * 1.0)
                    ,
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

  Widget buildShakingBubbleEffect() {
    final bubblesContainerWith = MediaQuery.of(context).size.width * 0.40;
    return ValueListenableBuilder<bool>(
      valueListenable: showShakeBubblesNotifier,
      builder: (context, showBubbles, _) {
        return showBubbles
            ? ShakingBubbleEffect(
                size: bubblesContainerWith,
                magicAnswer: magicAnswer ?? '',
              )
            : Container();
      },
    );
  }

  Widget buildShadowAnimation() {
    final width = MediaQuery.of(context).size.width * 0.9;
    return TweenAnimationBuilder(
      duration: const Duration(seconds: 3),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeIn,
      builder: (context, value, _) {
        return Transform(
          transform: Matrix4.identity()
            ..scale(1.3, 1.3)
            ..rotateX(math.pi / 2.1),
          origin: Offset(width - width * 0.65, width),
          child: Container(
            width: value * width * 0.5,
            height: 240,
            alignment: Alignment.bottomCenter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  blurStyle: BlurStyle.inner,
                  blurRadius: 100,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildBubbleEffect() {
    //generate random bubbles between 3 to 5
    int randomBubbles = math.Random().nextInt(3) + 2;
    return ValueListenableBuilder(
      valueListenable: showBubbleEffectNotifier,
      builder: (context, showBubbleEffect, _) {
        return showBubbleEffect
            ? ClipOval(
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                height: MediaQuery.of(context).size.width * 0.4,
                child: BubbleEffect(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: MediaQuery.of(context).size.width * 0.4,
                  numberOfBubbles: randomBubbles,
                ),
              ),
            )
            : Container();
      },
    );
  }

  Widget buildLiquidTetrahedron() {
    return ValueListenableBuilder(
      valueListenable: showLiquidTetrahedronNotifier,
      builder: (context, isShowing, _) {
        return isShowing
            ? ClipOval(
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                height: MediaQuery.of(context).size.width * 0.4,
                child: LiquidTetrahedron(
                    size: MediaQuery.of(context).size.width * 0.5,
                    answer: magicAnswerNotifier.value ?? 'Tap to find out your fortune',
                  ),
              ),
            )
            : Container();
      },
    );
  }

  double bounce(double animation) {
    const double amplitude = 20.0;
    const double frequency = 4.0;
    return amplitude * math.sin(frequency * 2 * math.pi * animation);
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

class _RealisticBubbleEffectState extends State<RealisticBubbleEffect> with TickerProviderStateMixin {
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
      child: Container(
        width: widget.size,
        height: widget.size,
        child: Stack(
          children: _bubbles.where((b) => !b.removed).map((b) => b.build()).toList(),
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

  factory _BubbleModel.random(double size, TickerProvider vsync, {required VoidCallback onRemove}) {
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
      CurvedAnimation(parent: controller, curve: const Interval(0.0, 0.2, curve: Curves.easeOut)),
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
                  color: Colors.white.withOpacity(0.7),
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
class GlowingRingWidget extends StatefulWidget {
  final double size;
  final Duration duration;
  final double inner;
  final double outer;
  final Color color1;
  final Color color2;
  final Color innerColor;
  final double edge;

  const GlowingRingWidget({
    super.key,
    required this.size,
    this.duration = const Duration(seconds: 10),
    this.inner = 0.48,
    this.outer = 0.5,
    this.color1 = const Color(0xFF4DE0FF),
    this.color2 = const Color(0xFFFFFFFF),
    this.innerColor = Colors.black,
    this.edge = 0.0,
  });

  @override
  State<GlowingRingWidget> createState() => _GlowingRingWidgetState();
}

class _GlowingRingWidgetState extends State<GlowingRingWidget>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  FragmentProgram? _program;
  Offset? widgetGlobalOffset;
  final GlobalKey _paintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(_updateOffset)
      ..repeat();
    _loadShader();
  }

  @override
  void didChangeMetrics() {
    _updateOffset();
  }

  Future<void> _loadShader() async {
    final program = await FragmentProgram.fromAsset('shaders/glow_ring.frag');
    setState(() {
      _program = program;
    });
  }

  void _updateOffset() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? box = _paintKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        final offset = box.localToGlobal(Offset.zero);
        final pixelRatio = window.devicePixelRatio;
        setState(() {
          widgetGlobalOffset = offset * pixelRatio;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_updateOffset);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_program == null || widgetGlobalOffset == null) {
      return SizedBox(key: _paintKey, width: widget.size, height: widget.size);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          key: _paintKey,
          size: Size.square(widget.size),
          painter: GlowingRingPainter(
            program: _program!,
            time: _controller.value * 2 * 3.1416,
            uOffset: widgetGlobalOffset!,
            widgetSize: widget.size,
            inner: widget.inner,
            outer: widget.outer,
            color1: widget.color1,
            color2: widget.color2,
            innerColor: widget.innerColor,
            edge: widget.edge,
          ),
        );
      },
    );
  }
}

class GlowingRingPainter extends CustomPainter {
  final FragmentProgram program;
  final double time;
  final Offset uOffset;
  final double widgetSize;
  final double inner;
  final double outer;
  final Color color1;
  final Color color2;
  final Color innerColor;
  final double edge;

  GlowingRingPainter({
    required this.program,
    required this.time,
    required this.uOffset,
    required this.widgetSize,
    required this.inner,
    required this.outer,
    required this.color1,
    required this.color2,
    required this.innerColor,
    required this.edge,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pixelRatio = window.devicePixelRatio;
    final shader = program.fragmentShader();
    shader.setFloat(0, time); // u_time
    shader.setFloat(1, widgetSize * pixelRatio); // u_resolution.x
    shader.setFloat(2, widgetSize * pixelRatio); // u_resolution.y
    shader.setFloat(3, uOffset.dx); // u_offset.x
    shader.setFloat(4, uOffset.dy); // u_offset.y
    shader.setFloat(5, inner); // u_inner
    shader.setFloat(6, outer); // u_outer

    // color1
    shader.setFloat(7, color1.red / 255.0);
    shader.setFloat(8, color1.green / 255.0);
    shader.setFloat(9, color1.blue / 255.0);
    shader.setFloat(10, color1.opacity); // u_color1Alpha

    // color2
    shader.setFloat(11, color2.red / 255.0);
    shader.setFloat(12, color2.green / 255.0);
    shader.setFloat(13, color2.blue / 255.0);
    shader.setFloat(14, color2.opacity); // u_color2Alpha

    // innerColor
    shader.setFloat(15, innerColor.red / 255.0);
    shader.setFloat(16, innerColor.green / 255.0);
    shader.setFloat(17, innerColor.blue / 255.0);
    shader.setFloat(18, innerColor.opacity); // u_innerAlpha

    shader.setFloat(19, edge); // u_edge

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant GlowingRingPainter oldDelegate) =>
      oldDelegate.time != time ||
      oldDelegate.uOffset != uOffset ||
      oldDelegate.inner != inner ||
      oldDelegate.outer != outer ||
      oldDelegate.color1 != color1 ||
      oldDelegate.color2 != color2 ||
      oldDelegate.innerColor != innerColor ||
      oldDelegate.edge != edge;
}