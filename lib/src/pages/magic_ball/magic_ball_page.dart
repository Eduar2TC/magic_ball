import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:magic_ball/src/pages/magic_ball/custom_widgets/animations.dart';
import 'package:magic_ball/src/utils/audio.dart';
import 'package:magic_ball/src/utils/data.dart';
import 'package:magic_ball/src/utils/shared_preferences.dart';

class MagicBall extends StatefulWidget {
  const MagicBall({super.key});

  @override
  MagicBallState createState() => MagicBallState();
}

class MagicBallState extends State<MagicBall> with TickerProviderStateMixin {
  late final Audio audio;
  String? magicAnswer;
  List<String>? magicList;
  bool isOnPressed = false;
  DataConfigurations? dataConfigurations;
  late BallAnimations? ballAnimations;
  SharedPreferencesUtils? sharedPreferencesUtils;
  late Map? langStrings;

  @override
  void initState() {
    super.initState();
    initializeDefaults();
    initializeAnimations();
    initializeSharedPreferences();
  }

  void initializeDefaults() {
    magicAnswer = '';
    magicList = [
      'YES',
      'NO',
      '\t\tASK\nAGAIN\nLATER',
      'THE ANSWER IS\n' + '\t\t\t\t\t\t\t\t\t\t' + 'YES',
      'I HAVE NO IDEA',
    ];
    langStrings = {
      'english': {
        'appbarTitle': {'home': 'Ask anything', 'settings': 'Settings'},
        'dropDownOptionTitle': 'Language',
        'dropDownOptionEnglish': 'English',
        'dropDownOptionSpanish': 'Spanish',
        'translate': {
          'list': [
            'YES',
            'NO',
            '\t\tASK\nAGAIN\nLATER',
            'THE ANSWER IS\n' + '\t\t\t\t\t\t\t\t\t\t' + 'YES',
            'I HAVE NO IDEA',
          ],
        }
      },
      'spanish': {
        'appbarTitle': {'home': 'Pregunta lo que sea', 'settings': 'Ajustes'},
        'dropDownOptionTitle': 'Idioma',
        'dropDownOptionEnglish': 'Inglés',
        'dropDownOptionSpanish': 'Español',
        'translate': {
          'list': [
            'SI',
            'NO',
            '\t\t\PREGUNTA\n\t\t\t\t\tMAS\n\t\t\t\tTARDE',
            'LA RESPUESTA ES\n' + '\t\t\t\t\t\t\t\t\t\t\t\t' + 'SI',
            'NO TENGO IDEA',
          ],
        }
      }
    };
    dataConfigurations = DataConfigurations(
      backgroundColor: Colors.blue[300]!,
      appBarColor: const Color(0xff10024f),
      brightness: Brightness.dark,
      titleAppBarColor: Colors.white,
      listMagicOptionsStrings: magicList!,
      langStrings: langStrings!,
    );
    audio = Audio();
  }

  void initializeAnimations() {
    ballAnimations = BallAnimations()..initializeAnimations(this);
  }

  void initializeSharedPreferences() {
    sharedPreferencesUtils = SharedPreferencesUtils(
      dataConfigurations: dataConfigurations,
      magicList: magicList,
    )..getMagicListFromSharedPreferences();

    if (sharedPreferencesUtils!.magicList == null) {
      magicList = sharedPreferencesUtils!.magicList;
    } else {
      sharedPreferencesUtils!
          .saveDataToSharedPreferences(dataConfigurations!, magicList!);
    }
  }

  int randomNumber() => math.Random().nextInt(5);

  String getMagicWord() => magicList![randomNumber()];

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dataConfigurations!.backgroundColor,
      appBar: CustomAppBar(dataConfigurations: dataConfigurations),
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
          child: Stack(
            alignment: Alignment.center,
            children: [
              buildMagicBallButton(),
              buildShadowAnimation(),
              buildSettingsButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildMagicBallButton() {
    return TextButton(
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
      ).copyWith(
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),
      onPressed: handleMagicBallPress,
      child: AnimatedBuilder(
        animation: ballAnimations!.animation0,
        builder: (BuildContext context, Widget? child) {
          return Transform.translate(
            offset: Offset(
              shake(ballAnimations!.animation0.value),
              math.sin(ballAnimations!.animation0.value * 500) * 25,
            ),
            child: child,
          );
        },
        child: buildMagicBallContent(),
      ),
    );
  }

  void handleMagicBallPress() {
    if (!isOnPressed) {
      isOnPressed = true;
      audio.playShake();

      ballAnimations?.animationController0.forward().then((value) {
        magicAnswer = getMagicWord();
        ballAnimations!.animationController1.reset();
        Future.delayed(const Duration(milliseconds: 1500), () {
          audio.playPop();
          isOnPressed = false;
        });
      });
    }
  }

  Widget buildMagicBallContent() {
    return Stack(
      alignment: Alignment.center,
      children: [
        TweenAnimationBuilder(
          duration: const Duration(milliseconds: 1700),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.fastEaseInToSlowEaseOut,
          builder: (context, value, _) => Transform.scale(
            scale: value,
            child: Transform.rotate(
              angle: (2 * math.pi) * value,
              child: Image.asset('assets/images/ball1.png'),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: ballAnimations!.animation1,
          builder: (BuildContext context, Widget? child) {
            return Transform.translate(
              offset: Offset(0, 10 * ballAnimations!.animation1.value),
              child: child,
            );
          },
          child: buildMagicAnswerText(),
        ),
      ],
    );
  }

  Widget buildMagicAnswerText() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 0),
      opacity: ballAnimations!.animation1!.value,
      curve: Curves.bounceInOut,
      child: Text(
        magicAnswer!,
        style:
            magicAnswer == 'NO' || magicAnswer == 'YES' || magicAnswer == 'SI'
                ? GoogleFonts.roboto(
                    color: Colors.white30,
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.bold,
                    fontSize: 40,
                    shadows: <Shadow>[
                      const Shadow(
                        offset: Offset(3, 3),
                        blurRadius: 3.0,
                        color: Color.fromARGB(40, 35, 125, 0),
                      ),
                      const Shadow(
                        offset: Offset(5.0, 5.0),
                        blurRadius: 8.0,
                        color: Color.fromARGB(40, 35, 125, 255),
                      ),
                    ],
                  )
                : GoogleFonts.roboto(
                    color: Colors.white30,
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    shadows: <Shadow>[
                      const Shadow(
                        offset: Offset(3, 3),
                        blurRadius: 3.0,
                        color: Color.fromARGB(40, 35, 125, 0),
                      ),
                      const Shadow(
                        offset: Offset(5.0, 5.0),
                        blurRadius: 8.0,
                        color: Color.fromARGB(40, 35, 125, 255),
                      ),
                    ],
                  ),
      ),
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

  Widget buildSettingsButton() {
    return Align(
      alignment: Alignment.topRight,
      child: IconButton(
        onPressed: () => navigateToSettings(context),
        icon: const FaIcon(FontAwesomeIcons.gear, color: Colors.white),
        iconSize: 50,
      ),
    );
  }

  void navigateToSettings(BuildContext context) async {
    magicList =
        await sharedPreferencesUtils!.getMagicListFromSharedPreferences();
    dynamic result =
        await Navigator.pushNamed(context, '/settings', arguments: null);

    setState(() {
      if (result != null) {
        dataConfigurations =
            result['dataConfigurations'] as DataConfigurations?;
        magicList = result['magicList'] as List<String>?;
        sharedPreferencesUtils!
            .saveDataToSharedPreferences(dataConfigurations!, magicList!);
      }
    });
  }

  double shake(double animation) {
    Curve curve = Curves.elasticIn;
    const double positionRight = 0.5;
    const double positionLeft = 0.5;
    return 2.5 *
        (positionRight - (positionLeft - curve.transform(animation)).abs());
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final DataConfigurations? dataConfigurations;

  const CustomAppBar({super.key, required this.dataConfigurations});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
      ),
      centerTitle: true,
      title: Text(
        dataConfigurations
                ?.langStrings[dataConfigurations?.langStrings.keys.first]
            ['appbarTitle']['home'],
        style: TextStyle(color: dataConfigurations!.titleAppBarColor),
      ),
      backgroundColor: dataConfigurations!.appBarColor,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(AppBar().preferredSize.height);
}
