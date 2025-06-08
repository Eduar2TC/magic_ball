import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:magic_ball/src/utils/data_configurations.dart';
import 'package:magic_ball/src/utils/shared_preferences.dart';
class AppState extends ChangeNotifier {
  late DataConfigurations? _dataConfigurations;
  late List<String>? _magicList;
  late final SharedPreferencesUtils _sharedPreferencesUtils;

  AppState() {
    _initializeSharedPreferencesUtils();
  }
  Future<void> _initializeSharedPreferencesUtils() async {
    try {
      _dataConfigurations = null;
      _magicList = null;
      _sharedPreferencesUtils = SharedPreferencesUtils();
      await _sharedPreferencesUtils.initializeSharedPreferences(); // Load before the data
      await _loadData();
    } catch (e) {
      log('Error initializing shared preferences utils: $e');
    }
  }

  // getters and setters
  DataConfigurations? get dataConfigurations => _dataConfigurations;
  List<String>? get magicList => _magicList;
  SharedPreferencesUtils get sharedPreferencesUtils => _sharedPreferencesUtils;
  set dataConfigurations(DataConfigurations? dataConfigurations) {
    _dataConfigurations = dataConfigurations;
    notifyListeners();
  }

  set magicList(List<String>? magicList) {
    _magicList = magicList;
    notifyListeners();
  }

  Future<void> _loadData() async {
    await _sharedPreferencesUtils.getMagicListFromSharedPreferences();
    try {
      _dataConfigurations = await _sharedPreferencesUtils.getDataConfigurationsFromSharedPreferences();
    } catch (e) {
      log('Error loading data configurations: $e');
    }
    try {
      _magicList = await _sharedPreferencesUtils.getMagicListFromSharedPreferences();
    } catch (e) {
      log('Error loading magic list: $e');
    }
    notifyListeners();
  }

  Future<void> getMagicList() async {
    try {
      _magicList = await _sharedPreferencesUtils.getMagicListFromSharedPreferences();
    } catch (e) {
      log('Error loading magic list: $e');
    }
    notifyListeners();
  }

  void updateDataConfigurations(DataConfigurations dataConfigurations) {
    try {
      _dataConfigurations = dataConfigurations;
      _sharedPreferencesUtils.saveDataConfigurationsFromSharedPreferences(dataConfigurations);
    } catch (e) {
      log('Error updating data configurations: $e');
    }
    notifyListeners();
  }

  void addMagicWord(String magicWord) {
    try {
      final updatedList = List<String>.from(_magicList ?? []);
      updatedList.add(magicWord.toUpperCase());
      _magicList = updatedList;
      _sharedPreferencesUtils.saveMagicListToSharedPreferences(_magicList!);
    } catch (e) {
      log('Error adding magic word: $e');
    }
    notifyListeners();
  }

  void editMagicWord(int index, String newWord) {
    try {
      if (_magicList != null && index >= 0 && index < _magicList!.length) {
        _magicList![index] = newWord.toUpperCase();
        _sharedPreferencesUtils.saveMagicListToSharedPreferences(_magicList!);
      } else {
        log('Error: Invalid index or magic list is null while editing.');
      }
    } catch (e) {
      log('Error editing magic word: $e');
    }
    notifyListeners();
  }

  Future<void> saveAllData() async {
    if (_dataConfigurations != null && _magicList != null) {
      _sharedPreferencesUtils.saveAllDataToSharedPreferences(_dataConfigurations!, _magicList!);
    }
    if (_magicList != null) {
      await _sharedPreferencesUtils.saveMagicListToSharedPreferences(_magicList!);
    }
    notifyListeners();
  }

  void removeMagicWord(String magicWord) {
    try {
      final index = _searchWordAndReturnIndexInMagicList(magicWord.toUpperCase());
      if (index != -1) {
        _magicList?.removeAt(index);
        _sharedPreferencesUtils.saveMagicListToSharedPreferences(_magicList!);
      } else {
        log('Magic word not found: $magicWord');
      }
    } catch (e) {
      log('Error removing magic word: $e');
    }
    notifyListeners();
  }

  int _searchWordAndReturnIndexInMagicList(String magicWord) {
    return _magicList!.indexWhere((element) => element == magicWord);
  }
}