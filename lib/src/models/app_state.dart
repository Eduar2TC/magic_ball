import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:magic_ball/src/utils/data_configurations.dart';
import 'package:magic_ball/src/utils/shared_preferences.dart';
import 'package:magic_ball/src/constants/constants.dart'; // <-- Asegúrate de importar esto para acceder a las listas por defecto

class AppState extends ChangeNotifier {
  late DataConfigurations? _dataConfigurations;
  late List<String>? _magicList;
  late final SharedPreferencesUtils _sharedPreferencesUtils;
  String _currentLanguage = 'en'; // Default

  AppState() {
    _initializeSharedPreferencesUtils();
  }
  Future<void> _initializeSharedPreferencesUtils() async {
    try {
      _dataConfigurations = null;
      _magicList = null;
      _sharedPreferencesUtils = SharedPreferencesUtils();
      await _sharedPreferencesUtils.initializeSharedPreferences(); // Load before the data
      _currentLanguage = await _sharedPreferencesUtils.getCurrentLanguage() ?? 'en';
      await _initializeMagicListIfNeeded(_currentLanguage); // <-- Inicializa si es necesario
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

  String get currentLanguage => _currentLanguage;
  set currentLanguage(String lang) {
    _currentLanguage = lang;
    _sharedPreferencesUtils.saveCurrentLanguage(lang);
    _initializeMagicListIfNeeded(lang); // <-- Llama aquí
    _loadData();
    notifyListeners();
  }

  set magicList(List<String>? magicList) {
    _magicList = magicList;
    notifyListeners();
  }

  Future<void> _loadData() async {
    try {
      _magicList = await _sharedPreferencesUtils.getMagicListFromSharedPreferences(_currentLanguage);
      _dataConfigurations = await _sharedPreferencesUtils.getDataConfigurationsFromSharedPreferences();
    } catch (e) {
      log('Error loading data: $e');
    }
    notifyListeners();
  }

  /// Nuevo método para inicializar la lista mágica por defecto si no existe
  Future<void> _initializeMagicListIfNeeded(String lang) async {
    final list = await _sharedPreferencesUtils.getMagicListFromSharedPreferences(lang);
    if (list == null || list.isEmpty) {
      List<String> defaultList;
      switch (lang) {
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
      await _sharedPreferencesUtils.saveMagicListToSharedPreferences(defaultList, lang);
    }
  }

  Future<void> getMagicList() async {
    try {
      _magicList = await _sharedPreferencesUtils.getMagicListFromSharedPreferences(_currentLanguage);
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
      _sharedPreferencesUtils.saveMagicListToSharedPreferences(_magicList!, _currentLanguage);
    } catch (e) {
      log('Error adding magic word: $e');
    }
    notifyListeners();
  }

  void editMagicWord(int index, String newWord) {
    try {
      if (_magicList != null && index >= 0 && index < _magicList!.length) {
        _magicList![index] = newWord.toUpperCase();
        _sharedPreferencesUtils.saveMagicListToSharedPreferences(_magicList!, _currentLanguage);
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
      await _sharedPreferencesUtils.saveMagicListToSharedPreferences(_magicList!, _currentLanguage);
    }
    notifyListeners();
  }

  void removeMagicWord(String magicWord) {
    try {
      final index = _searchWordAndReturnIndexInMagicList(magicWord.toUpperCase());
      if (index != -1) {
        _magicList?.removeAt(index);
        _sharedPreferencesUtils.saveMagicListToSharedPreferences(_magicList!, _currentLanguage);
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
