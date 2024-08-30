import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:magic_ball/src/pages/models/app.state.dart';
import 'package:provider/provider.dart';
import 'package:magic_ball/src/pages/magic_ball/custom_widgets/animations.dart';
import 'package:magic_ball/src/utils/audio.dart';

class MagicBall extends StatefulWidget {
  const MagicBall({super.key});

  @override
  MagicBallState createState() => MagicBallState();
}

class MagicBallState extends State<MagicBall> with TickerProviderStateMixin {
  late final Audio audio;
  String? magicAnswer;
  bool isOnPressed = false;
  late BallAnimations ballAnimations;
  final ValueNotifier<void> notifier = ValueNotifier<void>(null);

  @override
  void initState() {
    super.initState();
    audio = Audio();
    ballAnimations = BallAnimations(notifier);
    ballAnimations.initializeAnimations(this, audio.playPop);
  }

  @override
  void dispose() {
    ballAnimations.dispose();
    notifier.dispose();
    super.dispose();
  }

  String getMagicWord(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final magicList = appState.magicList;
    if (magicList == null || magicList.isEmpty) {
      return '';
    }
    return magicList[math.Random().nextInt(magicList.length)];
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final dataConfigurations = appState.dataConfigurations;

    return Scaffold(
      backgroundColor: dataConfigurations?.backgroundColor,
      appBar: AppBar(
        title: Text(
          dataConfigurations
                      ?.langStrings[dataConfigurations.langStrings.keys.first]
                  ['appbarTitle']['home'] ??
              '',
          style: TextStyle(color: dataConfigurations?.titleAppBarColor),
        ),
        backgroundColor: dataConfigurations?.appBarColor,
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
  }

  void handleMagicBallPress() {
    if (!isOnPressed) {
      setState(() {
        isOnPressed = true;
      });
      audio.playShake();

      ballAnimations.animationController0.forward().then((_) {
        setState(() {
          magicAnswer = getMagicWord(context);
        });
        ballAnimations.animationController1.reset();
        Future.delayed(const Duration(milliseconds: 1500), () {
          setState(() {
            isOnPressed = false;
          });
        });
      });
    }
  }

  Widget buildMagicBallContent() {
    return Stack(
      alignment: Alignment.center,
      children: [
        buildBallImage(),
        buildMagicAnswer(),
        buildShadowAnimation(),
      ],
    );
  }

  Widget buildBallImage() {
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
                    shake(ballAnimations.animation0.value),
                    math.sin(ballAnimations.animation0.value * 500) * 25,
                  ),
                  child: Image.asset('assets/images/ball1.png'),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget buildMagicAnswer() {
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
  }

  Widget buildShadowAnimation() {
    return TweenAnimationBuilder(
      duration: const Duration(seconds: 3),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeIn,
      builder: (context, value, _) {
        return Transform(
          transform: Matrix4.identity()
            ..scale(1.3, 1.3)
            ..rotateX(math.pi / 2.1),
          origin: const Offset(240 / 2, 340),
          child: Container(
            width: value * 200,
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

  double shake(double animation) {
    const double positionRight = 0.5;
    const double positionLeft = 0.5;
    return 2.5 *
        (positionRight -
            (positionLeft - Curves.elasticIn.transform(animation)).abs());
  }
}
