import 'package:flutter/material.dart';
import 'package:magic_ball/src/constants/constants.dart';
import 'package:magic_ball/src/utils/data_configurations.dart';
import 'package:magic_ball/src/utils/shared_preferences.dart';

class InitializationService {
  late final SharedPreferencesUtils sharedPreferencesUtils;

  InitializationService(this.sharedPreferencesUtils)  {
    _initializeAll();
  }

  Future<void> _initializeAll() async {
    await initializeDataConfigurations();
    await initializeMagicList();
  }

  /// Initializes the data configurations. If not present, it saves the default configurations.
  Future<DataConfigurations> initializeDataConfigurations() async {
    //await sharedPreferencesUtils.initializeSharedPreferences();
    try{
      DataConfigurations? dataConfigurations = await sharedPreferencesUtils.getDataConfigurationsFromSharedPreferences();
      if (dataConfigurations == null) {
        debugPrint('Error saving data configurations to shared preferences $dataConfigurations');
        try{
          dataConfigurations = _getDefaultDataConfigurations();
          await sharedPreferencesUtils.saveDataConfigurationsFromSharedPreferences(dataConfigurations);
        }catch(e){
          return _getDefaultDataConfigurations();
        }
      }
      debugPrint('Error INIT: $dataConfigurations');
      return dataConfigurations;
    } catch(e){
      debugPrint('Error initializing data configurations: $e');
      return _getDefaultDataConfigurations();
    }

  }

  /// Initializes the magic list. If not present, it saves an empty list.
  Future<List<String>?> initializeMagicList() async {
    try{
      List<String>? magicList = await sharedPreferencesUtils.getMagicListFromSharedPreferences();
      if (magicList == null) {
         sharedPreferencesUtils.saveMagicListToSharedPreferences(english); //TODO : refactor logic resposibilities with shared preferences
         magicList = await sharedPreferencesUtils.getMagicListFromSharedPreferences();
      }
      return magicList;
    } catch(e){
      debugPrint('Error initializing magic list: $e');
      return null;
    }
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
        },
        'portuguese': {
          'appbarTitle': {
            'home': 'Pergunte o que quiser',
            'settings': 'Configurações',
          },
          'dropDownOptionTitle': 'Idioma',
          'dropDownOptionEnglish': 'Inglês',
          'dropDownOptionSpanish': 'Espanhol',
          'translate': {
            'list': [
              'SIM',
              'NÃO',
              '\t\t\PREGUNTA\n\t\t\t\t\tMAIS\n\t\t\t\tTARDE',
              'A RESPOSTA É\n' + '\t\t\t\t\t\t\t\t\t\t\t\t' + 'SIM',
              'NÃO FAÇO IDEIA',
            ],
          }
        }
      },
    );
  }
}