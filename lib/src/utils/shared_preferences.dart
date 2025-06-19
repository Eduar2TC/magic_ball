import 'dart:developer';
import 'package:magic_ball/src/constants/constants.dart';
import 'package:magic_ball/src/utils/data_configurations.dart';
import 'package:shared_preferences/shared_preferences.dart';
//Get data if it exist in shared preferences device , if not return predefined constant data
class SharedPreferencesUtils {
  late SharedPreferences sharedPreferences;

  SharedPreferencesUtils() {
    initializeSharedPreferences();
  }

  Future<void> initializeSharedPreferences() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  Future<DataConfigurations?> getDataConfigurationsFromSharedPreferences() async {
    await initializeSharedPreferences();
    try{
      final dataConfigurations = sharedPreferences.getString('dataConfigurations');
      if (dataConfigurations != null) {
        return DataConfigurations.fromJson(dataConfigurations);
      }
      return null;
    } catch(e){
      log('Error getting data configurations from shared preferences: $e');
      return null;
    }
  }
  // Nuevo: Guardar idioma actual
  Future<void> saveCurrentLanguage(String languageCode) async {
    await initializeSharedPreferences();
    await sharedPreferences.setString('currentLanguage', languageCode);
  }
  // Nuevo: Obtener idioma actual
  Future<String?> getCurrentLanguage() async {
    await initializeSharedPreferences();
    return sharedPreferences.getString('currentLanguage');
  }
  // Magic List por idioma
  Future<List<String>?> getMagicListFromSharedPreferences(String languageCode) async {
    await initializeSharedPreferences();
    try {
      return sharedPreferences.getStringList('magicList_$languageCode');
    } catch (e) {
      log('Error getting magic list for $languageCode: $e');
      return null;
    }
  }
  Future<void> saveMagicListToSharedPreferences(List<String> magicList, String languageCode) async {
    await initializeSharedPreferences();
    try {
      await sharedPreferences.setStringList('magicList_$languageCode', magicList);
    } catch (e) {
      log('Error saving magic list for $languageCode: $e');
    }
    log('magicList_$languageCode: ${sharedPreferences.getStringList('magicList_$languageCode')}');
  }

  Future<void> saveDataConfigurationsFromSharedPreferences( DataConfigurations dataConfigurations ) async {
    await initializeSharedPreferences();
    try{
      await sharedPreferences.setString(
        'dataConfigurations',
        dataConfigurations.toJson(),
      );
    } catch(e){
      log('Error saving data configurations to shared preferences: $e');
    }
  }

  Future<void> saveAllDataToSharedPreferences( DataConfigurations dataConfigurations, List<String> magicList) async {
    await initializeSharedPreferences();
    await sharedPreferences.setString(
      'dataConfigurations',
      dataConfigurations.toJson(),
    );
    await sharedPreferences.setStringList(
      'magicList',
      magicList,
    );
  }
}
