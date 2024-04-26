import 'package:flutter/material.dart';
import 'package:magic_ball/src/routes/routes.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/home',
      routes: getAppRoutes(),
    ),
  );
}
