import 'dart:convert';

import 'package:flutter/material.dart';

class DataConfigurations {
  late Color backgroundColor;
  late Color appBarColor;
  late Brightness brightness;
  late Color titleAppBarColor;
  late List<String> listMagicOptionsStrings;
  late Map langStrings;

  DataConfigurations({
    required this.backgroundColor,
    required this.appBarColor,
    required this.brightness,
    required this.titleAppBarColor,
    required this.listMagicOptionsStrings,
    required this.langStrings,
  });

  //String to JSON
  String toJson() => json.encode({
        'backgroundColor': backgroundColor.value,
        'appBarColor': appBarColor.value,
        'brightnessMode': brightness.index,
        'titleColor': titleAppBarColor.value,
        'listMagicOptionsStrings': listMagicOptionsStrings,
        'listLangStrings': langStrings,
      });

  // DataConfigurations object from a JSON string.
  static DataConfigurations fromJson(String jsonString) {
    final Map<String, dynamic> data = json.decode(jsonString);
    return DataConfigurations(
      backgroundColor: Color(data['backgroundColor']),
      appBarColor: Color(data['appBarColor']),
      brightness: Brightness.values[data['brightnessMode']],
      titleAppBarColor: Color(data['titleColor']),
      listMagicOptionsStrings: List<String>.from(
          data['listMagicOptionsStrings'].map((item) => item.toString())),
      langStrings: Map<String, dynamic>.from(data['listLangStrings']),
    );
  }
}
