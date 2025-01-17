import 'package:flutter/material.dart';
import 'package:magic_ball/src/pages/magic_ball/magic_ball_page.dart';
import 'package:magic_ball/src/pages/magic_list_settings/magic_list_settings_page.dart';
import 'package:magic_ball/src/pages/settings/settings_page.dart';

Map<String, WidgetBuilder> getAppRoutes() {
  return <String, WidgetBuilder>{
    '/home': (BuildContext context) {
      return const MagicBall();
    },
    '/settings': (BuildContext context) {
      return const Settings();
    },
    '/magic_list_settings': (BuildContext context) {
      return const MagicListSettings();
    }
  };
}
