import 'package:flutter/material.dart';
import 'package:magic_ball/src/pages/models/app.state.dart';
import 'package:magic_ball/src/utils/data.dart';
import 'package:provider/provider.dart';
import 'package:magic_ball/src/routes/routes.dart';
import 'package:magic_ball/src/utils/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferencesUtils = SharedPreferencesUtils();
  final dataConfigurations = await sharedPreferencesUtils.getDataConfigurationsFromSharedPreferences();
  final magicList = await sharedPreferencesUtils.getMagicListFromSharedPreferences();

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState()
        ..updateDataConfigurations(dataConfigurations ??
            DataConfigurations(
              backgroundColor: Colors.blue[300]!,
              appBarColor: const Color(0xff10024f),
              brightness: Brightness.dark,
              titleAppBarColor: Colors.white,
              listMagicOptionsStrings: magicList ?? [],
              langStrings: {},
            ))
        ..updateMagicList(magicList ?? []),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
