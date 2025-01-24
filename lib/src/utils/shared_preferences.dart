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

  Future<List<String>?> getMagicListFromSharedPreferences() async {
    await initializeSharedPreferences();
    try{
      return sharedPreferences.getStringList('magicList');
    }
    catch(e){
      log('Error getting magic list from shared preferences: $e');
      return null;
    }
  }

  Future<void> saveMagicListToSharedPreferences(List<String> magicList) async {
    await initializeSharedPreferences();
    try{
      await sharedPreferences.setStringList(
        'magicList',
        magicList,
      );
    }
    catch(e){
      log('Error saving magic list to shared preferences: $e');
    }
    log('magicList: ${sharedPreferences.getStringList('magicList')}');
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
