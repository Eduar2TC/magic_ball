import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:magic_ball/src/utils/data_configurations.dart';
import 'package:magic_ball/src/utils/shared_preferences.dart';

class AppState extends ChangeNotifier {
  DataConfigurations? dataConfigurations;
  List<String>? magicList;
  final SharedPreferencesUtils sharedPreferencesUtils = SharedPreferencesUtils();

  AppState() {
    loadData();
  }

  Future<void> loadData() async {
    try {
      dataConfigurations = await sharedPreferencesUtils.getDataConfigurationsFromSharedPreferences();
      magicList = await sharedPreferencesUtils.getMagicListFromSharedPreferences();
      if (dataConfigurations == null || magicList == null) {
        log('Error: dataConfigurations or magicList is null');
      }
      notifyListeners();
    } catch (e) {
      log('Error loading data: $e');
    }
  }

  void updateDataConfigurations(DataConfigurations newDataConfigurations) {
    dataConfigurations = newDataConfigurations;
    notifyListeners();
  }

  void updateMagicList(List<String> newMagicList) {
    magicList = newMagicList;
    notifyListeners();
  }

  Future<void> saveData() async {
    if (dataConfigurations != null && magicList != null) {
      sharedPreferencesUtils.saveDataToSharedPreferences(dataConfigurations!, magicList!);
    }
    if (magicList != null) {
      await sharedPreferencesUtils.saveMagicListToSharedPreferences(magicList!);
    }
    notifyListeners();
  }
}
