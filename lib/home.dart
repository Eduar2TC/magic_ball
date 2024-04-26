import 'package:flutter/material.dart';
import 'package:magic_ball/src/pages/magic_ball/magic_ball_page.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MagicBall(); //removed return MaterialApp
  }
}
