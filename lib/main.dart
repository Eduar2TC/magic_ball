import 'package:flutter/material.dart';
import 'package:magic_ball/src/services/initialization_local_data_service.dart';
import 'package:magic_ball/src/models/app_state.dart';
import 'package:magic_ball/src/utils/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:magic_ball/src/routes/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferencesUtils = SharedPreferencesUtils();
  InitializationService(sharedPreferencesUtils);
  await InitializationService(sharedPreferencesUtils).initializeDataConfigurations();
  await InitializationService(sharedPreferencesUtils).initializeMagicList();

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/home',
      routes: getAppRoutes(),
      theme: ThemeData(
        primaryColor: context.watch<AppState>().dataConfigurations?.appBarColor,
        brightness: context.watch<AppState>().dataConfigurations?.brightness,
      ),
    );
  }
}