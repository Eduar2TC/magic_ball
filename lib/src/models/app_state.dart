import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:magic_ball/src/utils/data_configurations.dart';
import 'package:magic_ball/src/utils/shared_preferences.dart';

class AppState extends ChangeNotifier {
  late DataConfigurations? dataConfigurations;
  late List<String>? magicList;
  late final SharedPreferencesUtils sharedPreferencesUtils;

  AppState() {
    _initializeSharedPreferencesUtils();
  }
  Future<void> _initializeSharedPreferencesUtils() async {
    try{
      dataConfigurations = null;
      magicList = null;
      sharedPreferencesUtils = SharedPreferencesUtils();
      await sharedPreferencesUtils.initializeSharedPreferences();  //load before data
      await _loadData();
    }catch(e){
      log('Error initializing shared preferences utils: $e');
    }
  }
  Future<void> _loadData() async {
    await sharedPreferencesUtils.getMagicListFromSharedPreferences();
    try{
      dataConfigurations = await sharedPreferencesUtils.getDataConfigurationsFromSharedPreferences();
    } catch(e){
      log('Error loading data configurations: $e');
    }
    try{
      magicList = await sharedPreferencesUtils.getMagicListFromSharedPreferences();
    } catch(e){
      log('Error loading magic list: $e');
    }
    notifyListeners();
  }

  Future<void> getMagicList() async {
    try{
      magicList = await sharedPreferencesUtils.getMagicListFromSharedPreferences();
    } catch(e){
      log('Error loading magic list: $e');
    }
    notifyListeners();
  }

  void updateDataConfigurations(DataConfigurations dataConfigurations) {
   try{
     this.dataConfigurations = dataConfigurations;
     sharedPreferencesUtils.saveDataConfigurationsFromSharedPreferences(dataConfigurations);
   }catch(e){
      log('Error updating data configurations: $e');
   }
    notifyListeners();
  }

  void updateMagicList(List<String> magicList) {
    try{
      this.magicList = magicList;
      sharedPreferencesUtils.saveMagicListToSharedPreferences(magicList);
    }catch(e){
      log('Error updating magic list: $e');
    }
    notifyListeners();
  }

  Future<void> saveAllData() async {
    if (dataConfigurations != null && magicList != null) {
      sharedPreferencesUtils.saveAllDataToSharedPreferences(dataConfigurations!, magicList!);
    }
    if (magicList != null) {
      await sharedPreferencesUtils.saveMagicListToSharedPreferences(magicList!);
    }
    notifyListeners();
  }

}
