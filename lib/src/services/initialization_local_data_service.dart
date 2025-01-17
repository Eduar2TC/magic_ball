import 'package:flutter/material.dart';
import 'package:magic_ball/src/constants/constants.dart';
import 'package:magic_ball/src/utils/data_configurations.dart';
import 'package:magic_ball/src/utils/shared_preferences.dart';

class InitializationService {
  final SharedPreferencesUtils sharedPreferencesUtils;

  InitializationService(this.sharedPreferencesUtils);


  /// Initializes the data configurations. If not present, it saves the default configurations.
  Future<DataConfigurations> initializeDataConfigurations() async {
    var dataConfigurations = await sharedPreferencesUtils.getDataConfigurationsFromSharedPreferences();
    if (dataConfigurations == null) {
      dataConfigurations = _getDefaultDataConfigurations();
      await sharedPreferencesUtils.saveDataToSharedPreferences(dataConfigurations, english); //english is a predefined constant
    }
    return dataConfigurations;
  }

  /// Initializes the magic list. If not present, it saves an empty list.
  Future<List<String>> initializeMagicList() async {
    var magicList = await sharedPreferencesUtils.getMagicListFromSharedPreferences();
    if (magicList == null) {
      magicList = [];
      await sharedPreferencesUtils.saveMagicListToSharedPreferences(magicList);
    }
    return magicList;
  }

  /// Returns the default data configurations.
  DataConfigurations _getDefaultDataConfigurations() {
    return DataConfigurations(
      backgroundColor: Colors.blue[300]!,
      appBarColor: const Color(0xff10024f),
      brightness: Brightness.dark,
      titleAppBarColor: Colors.white,
      listMagicOptionsStrings: [],
      langStrings: {
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
      },
    );
  }
}