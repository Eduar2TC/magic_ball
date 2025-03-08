import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:magic_ball/src/models/app_state.dart';
import 'package:magic_ball/src/pages/magic_ball_page/custom_widgets/animations.dart';
import 'package:magic_ball/src/services/initialization_local_data_service.dart';
import 'package:provider/provider.dart';
import 'package:magic_ball/src/utils/audio.dart';

import 'custom_widgets/bubble_effect.dart';
import 'custom_widgets/sphere_figure.dart';
import 'custom_widgets/shaking_bubble_effect.dart';
import 'package:vector_math/vector_math_64.dart' show Quaternion, Vector3, Vector4;

import 'custom_widgets/triangle.dart';

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
    final dataConfigurations = Provider.of<AppState>(context).dataConfigurations;
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
              dataConfigurations != null && dataConfigurations.langStrings.isNotEmpty &&
                      dataConfigurations.langStrings.keys.isNotEmpty
                  ? dataConfigurations.langStrings[dataConfigurations
                          .langStrings.keys.first]['appbarTitle']['home'] ?? ''
                  : '',
              style: TextStyle(color: dataConfigurations?.titleAppBarColor),
            ),
            backgroundColor:dataConfigurations?.appBarColor ?? const Color(0xff10024f),
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
        }).then((_) {
          //Hide magic response
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
        buildMagicAnswer(),
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
                  child: SphereFigure(size: sphereWidth),
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
              double h = math.sqrt(3) / 2 * MediaQuery.of(context).size.width * 0.4;
              double xOffset = (h / 3) * math.sin(randomZAngle);
              double yOffset = (h / 3) * (1 - math.cos(randomZAngle));
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
                      ..translate(0.0,-100.0 * (1 - ballAnimations.answerAnimation.value),0.0,)
                      ..setRotationZ( alternateRotationDirection ? randomZAngle * ballAnimations.answerAnimation.value
                            : -randomZAngle * ballAnimations.answerAnimation.value,
                      )
                      ..scale( 1.5 - math.cos(ballAnimations.answerAnimation.value *math.pi *0.3) * 1.0) //animation 1
                    //..scale(math.cos( 0.3 * ballAnimations.answerAnimation.value)) //animation 2
                    //..rotateX(randomZAngle * ballAnimations.answerAnimation.value) //animation 3
                    ,
                    child: MagicBallTriangle(
                      magicAnswer: magicAnswer ?? '',
                      size: MediaQuery.of(context).size.width * 0.4,
                    ),
                    /*
                    Text(
                    magicAnswer ?? '',
                    style: TextStyle(
                      color: Colors.white30,
                      fontStyle: FontStyle.normal,
                      fontWeight: FontWeight.bold,
                      fontSize: magicAnswerCounter(magicAnswer),
                      shadows: const [
                        Shadow(
                          offset: Offset(3, 3),
                          blurRadius: 3.0,
                          color: Color.fromARGB(40, 35, 125, 0),
                        ),
                        Shadow(
                          offset: Offset(5.0, 5.0),
                          blurRadius: 8.0,
                          color: Color.fromARGB(40, 35, 125, 255),
                        ),
                      ],
                    ),
                  ),
                     */
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
            ? BubbleEffect(
                width: MediaQuery.of(context).size.width * 0.4,
                height: MediaQuery.of(context).size.width * 0.4,
                numberOfBubbles: randomBubbles,
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
    InitializationService(appState.sharedPreferencesUtils);
  }
}