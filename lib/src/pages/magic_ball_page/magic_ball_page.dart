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
          return  Scaffold(
            body: Center(
              child: Text('Error loading data $snapshot.error '),
            ),
          );
        }
        return Scaffold(
          backgroundColor: dataConfigurations?.backgroundColor,
          appBar: AppBar(
            title: Text(
              dataConfigurations != null &&
                  dataConfigurations.langStrings.isNotEmpty &&
                  dataConfigurations.langStrings.keys.isNotEmpty
                  ? dataConfigurations.langStrings[dataConfigurations
                  .langStrings.keys.first]['appbarTitle']['home'] ??
                  ''
                  : '',
              style: TextStyle(color: dataConfigurations?.titleAppBarColor),
            ),
            backgroundColor: dataConfigurations?.appBarColor ??
                const Color(0xff10024f),
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

      ballAnimations.animationController0.forward().then((_) {
        getMagicWord(context).then((value) {
          magicAnswerNotifier.value = value;
        });
        Future.delayed(const Duration(milliseconds: 1500), () {
          ballAnimations.animationController1.forward();
          isOnPressedNotifier.value = false;
          //show bubbles
          ballAnimations.animation0.isAnimating
              ? showShakeBubblesNotifier.value = true
              : showShakeBubblesNotifier.value = false;
          ballAnimations.animation0.isAnimating
              ? showBubbleEffectNotifier.value = false
              : showBubbleEffectNotifier.value = true;
        });
        //hide magic response
        Future.delayed(const Duration(milliseconds: 3000), () {
          ballAnimations.animationController1.reverse();
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
              animation: ballAnimations.animation0,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    bounce(ballAnimations.animation0.value),
                    math.sin(ballAnimations.animation0.value * 500) * 25,
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

  Widget buildMagicAnswer() {
    return ValueListenableBuilder<String?>(
      valueListenable: magicAnswerNotifier,
      builder: (context, magicAnswer, child) {
        return AnimatedBuilder(
          animation: ballAnimations.animation1,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 10 * ballAnimations.animation1.value),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 0),
                opacity: ballAnimations.animation1.value,
                child: Text(
                  magicAnswer ?? '',
                  style: TextStyle(
                    color: Colors.white30,
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.bold,
                    fontSize: magicAnswer == 'NO' ||
                        magicAnswer == 'YES' ||
                        magicAnswer == 'SI'
                        ? 40
                        : 20,
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
              ),
            );
          },
        );
      },
    );
  }

  Widget buildShakingBubbleEffect() {
    final bubblesContainerWith = MediaQuery.of(context).size.width * 0.40;
    return ValueListenableBuilder<bool>(
      valueListenable: showShakeBubblesNotifier,
      builder: (context, showBubbles, child) {
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
                  color: Colors.black.withOpacity(0.5),
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
      builder: (context, showBubbleEffect, child) {
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