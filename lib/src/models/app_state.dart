import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:magic_ball/src/utils/data_configurations.dart';
import 'package:magic_ball/src/utils/shared_preferences.dart';
import 'package:magic_ball/src/constants/constants.dart';

class AppState extends ChangeNotifier {
  late DataConfigurations? _dataConfigurations;
  late List<String>? _magicList;
  late final SharedPreferencesUtils _sharedPreferencesUtils;
  String _currentLanguage = 'en';
  bool _shakeToGetAnswerEnabled = true;
  bool _tapToGetAnswerEnabled = true;
  double _shakeSensitivity = 3.0;
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  Future<void>? _initFuture;

  AppState() {
    initialize();
  }

  Future<void> initialize() {
    _initFuture ??= _initializeSharedPreferencesUtils();
    return _initFuture!;
  }
  
  Future<void> _initializeSharedPreferencesUtils() async {
    try {
      _dataConfigurations = null;
      _magicList = null;
      _sharedPreferencesUtils = SharedPreferencesUtils();
      await _sharedPreferencesUtils.initializeSharedPreferences();
      _currentLanguage = await _sharedPreferencesUtils.getCurrentLanguage() ?? 'en';
      _shakeToGetAnswerEnabled = await _sharedPreferencesUtils.getShakeToGetAnswerEnabled() ?? true;
      _tapToGetAnswerEnabled = await _sharedPreferencesUtils.getTapToGetAnswerEnabled() ?? true;
      _shakeSensitivity = await _sharedPreferencesUtils.getShakeSensitivity() ?? 3.0;
      await _loadData();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      log('Error initializing shared preferences utils: $e');
      _loadDefaultData();
      _isInitialized = true;
      notifyListeners();
    }
  }

  void _loadDefaultData() {
    _magicList = english;
    _dataConfigurations = null;
    log('Loaded default magic list due to initialization error');
  }

  DataConfigurations? get dataConfigurations => _dataConfigurations;
  List<String>? get magicList => _magicList;
  SharedPreferencesUtils get sharedPreferencesUtils => _sharedPreferencesUtils;
  bool get shakeToGetAnswerEnabled => _shakeToGetAnswerEnabled;
  bool get tapToGetAnswerEnabled => _tapToGetAnswerEnabled;
  double get shakeSensitivity => _shakeSensitivity;
  
  set dataConfigurations(DataConfigurations? dataConfigurations) {
    _dataConfigurations = dataConfigurations;
    notifyListeners();
  }

  String get currentLanguage => _currentLanguage;
  set currentLanguage(String lang) {
    _currentLanguage = lang;
    _sharedPreferencesUtils.saveCurrentLanguage(lang);
    _initializeMagicListIfNeeded(lang);
    _loadData();
    notifyListeners();
  }

  set magicList(List<String>? magicList) {
    _magicList = magicList;
    notifyListeners();
  }

  set shakeToGetAnswerEnabled(bool enabled) {
    _shakeToGetAnswerEnabled = enabled;
    _sharedPreferencesUtils.saveShakeToGetAnswerEnabled(enabled);
    notifyListeners();
  }
  
  set tapToGetAnswerEnabled(bool enabled) {
    _tapToGetAnswerEnabled = enabled;
    _sharedPreferencesUtils.saveTapToGetAnswerEnabled(enabled);
    notifyListeners();
  }
  
  set shakeSensitivity(double sensitivity) {
    _shakeSensitivity = sensitivity.clamp(2.0, 10.0);
    _sharedPreferencesUtils.saveShakeSensitivity(_shakeSensitivity);
    notifyListeners();
  }

  Future<void> _loadData() async {
    try {
      _magicList = await _sharedPreferencesUtils.getMagicListFromSharedPreferences(_currentLanguage);
      if (_magicList == null || _magicList!.isEmpty) {
        await _initializeMagicListIfNeeded(_currentLanguage);
        _magicList = await _sharedPreferencesUtils.getMagicListFromSharedPreferences(_currentLanguage);
      }
      _dataConfigurations = await _sharedPreferencesUtils.getDataConfigurationsFromSharedPreferences();
      log('Magic list loaded: $_magicList');
    } catch (e) {
      log('Error loading data: $e');
      _loadDefaultData();
    }
    notifyListeners();
  }

  Future<void> _initializeMagicListIfNeeded(String lang) async {
    try {
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
        log('Initializing magic list for $lang with ${defaultList.length} words');
        await _sharedPreferencesUtils.saveMagicListToSharedPreferences(defaultList, lang);
      }
    } catch (e) {
      log('Error initializing magic list: $e');
    }
  }

Future<List<String>> getMagicList() async {
    try {
      if (!_isInitialized) {
        log('Waiting for initialization to complete...');
        await _initializeSharedPreferencesUtils();
      }
      
      _magicList = await _sharedPreferencesUtils.getMagicListFromSharedPreferences(_currentLanguage);
      
      if (_magicList == null || _magicList!.isEmpty) {
        log('Magic list empty, loading defaults...');
        await _initializeMagicListIfNeeded(_currentLanguage);
        _magicList = await _sharedPreferencesUtils.getMagicListFromSharedPreferences(_currentLanguage);
      }
      
      if (_magicList == null || _magicList!.isEmpty) {
        log('Using hardcoded default magic list');
        _magicList = ['Yes', 'No', 'Maybe', 'Ask again later', 'Definitely', 'Not sure'];
      }
      
      log('Returning magic list with ${_magicList!.length} words');
    } catch (e) {
      log('Error getting magic list: $e');
      _magicList = ['Yes', 'No', 'Maybe', 'Ask again later'];
    }
    // ← ELIMINADO notifyListeners() — causaba rebuild durante flujo async
    return _magicList!;
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
    return _magicList?.indexWhere((element) => element == magicWord) ?? -1;
  }
}