import 'package:flutter/material.dart';
import 'package:magic_ball/src/pages/magic_ball/magic_ball_page.dart';

class Home extends StatelessWidget {
  const Home({super.key});
  @override
  Widget build(BuildContext context) {
    return const MagicBall(); //removed return MaterialApp
  }
}
