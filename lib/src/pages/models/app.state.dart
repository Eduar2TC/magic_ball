import 'package:flutter/material.dart';
import 'package:magic_ball/src/utils/data.dart';
import 'package:magic_ball/src/utils/shared_preferences.dart';

class AppState extends ChangeNotifier {
  DataConfigurations? dataConfigurations;
  List<String>? magicList;
  final SharedPreferencesUtils sharedPreferencesUtils = SharedPreferencesUtils();

  AppStateProvider() {
    loadData();
  }

  Future<void> loadData() async {
    dataConfigurations = await sharedPreferencesUtils.getDataConfigurationsFromSharedPreferences();
    magicList = await sharedPreferencesUtils.getMagicListFromSharedPreferences();
    notifyListeners();
  }

  void updateDataConfigurations(DataConfigurations newDataConfigurations) {
    dataConfigurations = newDataConfigurations;
    notifyListeners();
  }

  void updateMagicList(List<String> newMagicList) {
    magicList = newMagicList;
    notifyListeners();
  }

  void saveData() {
    if (dataConfigurations != null && magicList != null) {
      sharedPreferencesUtils.saveDataToSharedPreferences(dataConfigurations!, magicList!);
    }
  }
}
