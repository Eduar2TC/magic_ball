import 'package:flutter/material.dart';
import 'package:magic_ball/src/services/initialization_local_data_service.dart';
import 'package:magic_ball/src/models/app_state.dart';
import 'package:magic_ball/src/utils/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:magic_ball/src/routes/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/home',
      routes: getAppRoutes(),
      theme: ThemeData(
        primaryColor: appState.dataConfigurations?.appBarColor,
        brightness: appState.dataConfigurations?.brightness,
      ),
    );
  }
}
