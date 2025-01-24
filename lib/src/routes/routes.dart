import 'package:flutter/material.dart';
import 'package:magic_ball/src/pages/magic_ball_page/magic_ball_page.dart';
import 'package:magic_ball/src/pages/magic_list_settings_page/magic_list_settings_page.dart';
import 'package:magic_ball/src/pages/settings_page/settings_page.dart';

Map<String, WidgetBuilder> getAppRoutes() {
  return <String, WidgetBuilder>{
    '/home': (BuildContext context) {
      return const MagicBallPage();
    },
    '/settings': (BuildContext context) {
      return const Settings();
    },
    '/magic_list_settings': (BuildContext context) {
      return const MagicListSettings();
    }
  };
}
