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
  MagicBallState createState() {
    return MagicBallState();
  }
}

class MagicBallState extends State<MagicBall> with TickerProviderStateMixin {
  //Uses a Ticker Mixin for Animations
  late final Audio audio;
  String? magicAnswer;
  //Initialize default data
  List<String>? magicList;
  bool isOnPressed = false; //press by turns
  //Init object data
  DataConfigurations? dataConfigurations;
  //Init animation
  late BallAnimations? ballAnimations;
  //Init SharedPreferences
  SharedPreferencesUtils? sharedPreferencesUtils;
  late Map? langStrings;

  @override
  void initState() {
    super.initState();
    magicAnswer = '';
    //default magic list
    magicList = [
      'YES',
      'NO',
      '\t\tASK\nAGAIN\nLATER',
      'THE ANSWER IS\n' + '\t\t\t\t\t\t\t\t\t\t' + 'YES',
      'I HAVE NO IDEA',
    ];
    langStrings = {
      'english': {
        'appbarTitle': {
          'home': 'Ask anything',
          'settings': 'Settings',
        },
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
        'appbarTitle': {
          'home': 'Pregunta lo que sea',
          'settings': 'Ajustes',
        },
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
    //default app data configurations
    dataConfigurations = DataConfigurations(
      backgroundColor: Colors.blue[300]!,
      appBarColor: const Color(0xff10024f),
      brightness: Brightness.dark,
      titleAppBarColor: Colors.white,
      listMagicOptionsStrings: magicList!,
      langStrings: langStrings!, //TODO:FIX
    );
    audio = Audio();
    //Initialize animations
    ballAnimations = BallAnimations()..initializeAnimations(this);
    //initializeData
    sharedPreferencesUtils = SharedPreferencesUtils(
      dataConfigurations: dataConfigurations,
      magicList: magicList,
    )..getMagicListFromSharedPreferences();

    if (sharedPreferencesUtils!.magicList == null) {
      //save data to SharedPreferences if not exists
      magicList = sharedPreferencesUtils!.magicList;
    } else {
      sharedPreferencesUtils!
          .saveDataToSharedPreferences(dataConfigurations!, magicList!);
    }
  }

  int randomNumber() {
    return math.Random().nextInt(5);
  }

  String getMagicWord() {
    return magicList![randomNumber()];
  }

  /*Future<List<String>?> getDataFromSharedPreferences() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getStringList('data') ??
        magicList; //if left element is null, return default data
  }

  //Initialize data from SharedPreferences
  void gedDataSharePreferences() async {
    magicList = await getDataFromSharedPreferences();
    setState(() {
      dataConfigurations!.langOptSelected = int.parse(
          magicList!.elementAt(5).toString()); //Initialize option language
    });
  }*/

  late AnimationController control;
  late Animation<double> rot;
  late Animation<double> trasl;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dataConfigurations!.backgroundColor,
      appBar: CustomAppBar(
        dataConfigurations: dataConfigurations,
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
          child: Stack(
            alignment: Alignment.center,
            children: [
              TextButton(
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                ).copyWith(
                  overlayColor: MaterialStateProperty.all(
                    Colors.transparent,
                  ), //remove foreground color
                ),
                onPressed: () {
                  if (!isOnPressed) {
                    isOnPressed = true; //catch button press
                    audio.playShake();

                    ballAnimations?.animationController0
                        .forward()
                        .then((value) {
                      //_animationControllerOne.forward();
                    }).then((value) {
                      magicAnswer = getMagicWord();
                      ballAnimations!.animationController1.reset();
                      //Delay audio
                      Future.delayed(const Duration(milliseconds: 1500), () {
                        audio.playPop();
                        isOnPressed = false;
                      });
                    });
                  } else {
                    return;
                  }
                },
                child: AnimatedBuilder(
                  animation: ballAnimations!.animation0,
                  builder: (BuildContext context, Widget? child) {
                    return Transform.translate(
                      offset: Offset(
                          //Horizontal animation
                          shake(ballAnimations!.animation0.value),
                          //Vertical animation
                          math.sin(ballAnimations!.animation0.value * 500) *
                              25),
                      child: child,
                    );
                  },
                  child: Stack(
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
                            child: Image.asset(
                              'assets/images/ball1.png',
                            ),
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: ballAnimations!.animation1,
                        builder: (BuildContext context, Widget? child) {
                          return Transform.translate(
                            //Position text on ball
                            offset: Offset(
                                0, 10 * ballAnimations!.animation1.value),
                            child: child,
                          );
                        },
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 0),
                          opacity: ballAnimations!.animation1!.value,
                          curve: Curves.bounceInOut,
                          child: Text(
                            magicAnswer!,
                            style: magicAnswer == 'NO' ||
                                    magicAnswer == 'YES' ||
                                    magicAnswer == 'SI'
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
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              //Animate shadow
              TweenAnimationBuilder(
                duration: const Duration(seconds: 3),
                tween: Tween<double>(begin: 0, end: 1),
                curve: Curves.easeIn,
                builder: (context, value, _) {
                  //Draw shadow and rotate from x
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
                            //offset: const Offset(50, 0),
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              settings(),
            ],
          ),
        ),
      ),
    );
  }

  Widget settings() {
    return Align(
      alignment: Alignment.topRight,
      child: IconButton(
        onPressed: () {
          awaitData(context);
        },
        icon: const FaIcon(
          FontAwesomeIcons.gear,
          color: Colors.white,
        ),
        iconSize: 50,
      ),
    );
  }

  void awaitData(BuildContext context) async {
    //get magic list from shared preferences
    magicList =
        await sharedPreferencesUtils!.getMagicListFromSharedPreferences();
    dynamic result = await Navigator.pushNamed(
      context,
      '/settings',
      arguments: null,
    );
    // magicList = dataConfigurations?.listMagicOptionsStrings;
    log('Magic List: $magicList');
    setState(() {});
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
  const CustomAppBar({
    super.key,
    required this.dataConfigurations,
  });
  final DataConfigurations? dataConfigurations;

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
                ['appbarTitle'][
            'home'], // dataConfigurations?.langStrings.keys.first == 'english' key
        style: TextStyle(
          color: dataConfigurations!.titleAppBarColor,
        ),
      ),
      backgroundColor: dataConfigurations!.appBarColor,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(AppBar().preferredSize.height);
}
