import 'package:flutter/material.dart';
import 'package:magic_ball/src/constants/constants.dart';
import 'package:magic_ball/src/utils/data_configurations.dart';
import 'package:magic_ball/src/utils/shared_preferences.dart';

class InitializationService {
  late final SharedPreferencesUtils sharedPreferencesUtils;

  InitializationService(this.sharedPreferencesUtils);

  /// Inicializa todas las configuraciones y listas mágicas para el idioma dado.
  Future<void> initializeAll(String languageCode) async {
    await initializeDataConfigurations();
    await initializeMagicList(languageCode);
  }

  /// Inicializa la configuración de datos. Si no existe, guarda la configuración por defecto.
  Future<DataConfigurations> initializeDataConfigurations() async {
    try {
      DataConfigurations? dataConfigurations = await sharedPreferencesUtils.getDataConfigurationsFromSharedPreferences();
      if (dataConfigurations == null) {
        dataConfigurations = _getDefaultDataConfigurations();
        await sharedPreferencesUtils.saveDataConfigurationsFromSharedPreferences(dataConfigurations);
      }
      return dataConfigurations;
    } catch (e) {
      debugPrint('Error initializing data configurations: $e');
      return _getDefaultDataConfigurations();
    }
  }

  /// Inicializa la Magic List para el idioma dado. Si no existe, usa la lista por defecto y la guarda.
  Future<List<String>?> initializeMagicList(String languageCode) async {
    try {
      List<String>? magicList = await sharedPreferencesUtils.getMagicListFromSharedPreferences(languageCode);
      if (magicList == null) {
        List<String> defaultList;
        switch (languageCode) {
          case 'es':
            defaultList = spanish;
            break;
          case 'pt':
            defaultList = portuguese;
            break;
          case 'en':
          default:
            defaultList = english;
        }
        await sharedPreferencesUtils.saveMagicListToSharedPreferences(defaultList, languageCode);
        magicList = defaultList;
      }
      return magicList;
    } catch (e) {
      debugPrint('Error initializing magic list for $languageCode: $e');
      return null;
    }
  }

  /// Devuelve la configuración de datos por defecto.
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
          'magicListTitle': 'Magic List',
          'shakeOptionTitle': 'Shake to get answer',
          'dropDownOptionTitle': 'Language',
          'dropDownOptionEnglish': 'English',
          'dropDownOptionSpanish': 'Spanish',
          'dropDownOptionPortuguese': 'Portuguese',
          'translate': {
            'list': english,
          }
        },
        'spanish': {
          'appbarTitle': {
            'home': 'Pregunta lo que sea',
            'settings': 'Ajustes',
          },
          'magicListTitle': 'Lista Mágica',
          'shakeOptionTitle': 'Sacudir para funcionar',
          'dropDownOptionTitle': 'Idioma',
          'dropDownOptionEnglish': 'Inglés',
          'dropDownOptionSpanish': 'Español',
          'dropDownOptionPortuguese': 'Portugués',
          'translate': {
            'list': spanish,
          }
        },
        'portuguese': {
          'appbarTitle': {
            'home': 'Pergunte o que quiser',
            'settings': 'Configurações',
          },
          'magicListTitle': 'Lista de Magia',
          'shakeOptionTitle': 'Agite para obter a resposta',
          'dropDownOptionTitle': 'Idioma',
          'dropDownOptionEnglish': 'Inglês',
          'dropDownOptionSpanish': 'Espanhol',
          'dropDownOptionPortuguese': 'Português',
          'translate': {
            'list': portuguese,
          }
        }
      },
    );
  }
}
