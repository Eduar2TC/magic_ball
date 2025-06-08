import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'i18n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt')
  ];

  /// Title for the home screen app bar
  ///
  /// In en, this message translates to:
  /// **'Ask anything'**
  String get appbarTitle_home;

  /// Title for the settings screen app bar
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get appbarTitle_settings;

  /// Dropdown title for selecting language
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get dropDownOptionTitle;

  /// Option for English language
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get dropDownOptionEnglish;

  /// Option for Spanish language
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get dropDownOptionSpanish;

  /// Message displayed when the magic list is empty
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get magicList_empty;

  /// Button text for adding a magic word
  ///
  /// In en, this message translates to:
  /// **'Add Magic Word'**
  String get addMagicWord;

  /// Button text for editing a magic word
  ///
  /// In en, this message translates to:
  /// **'Edit Magic Word'**
  String get editMagicWord;

  /// Placeholder text for entering a magic word
  ///
  /// In en, this message translates to:
  /// **'Enter a magic word'**
  String get enterMagicWord;

  /// Button text for canceling an action
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Button text for saving changes
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Instruction to shake the device to get an answer
  ///
  /// In en, this message translates to:
  /// **'Shake to get answer'**
  String get shakeToGetAnswer;

  /// Title for the magic list screen
  ///
  /// In en, this message translates to:
  /// **'Magic List'**
  String get magicList;

  /// Button text for undoing an action
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// Message displayed when a magic word is added
  ///
  /// In en, this message translates to:
  /// **'Magic word added'**
  String get magicWordAdded;

  /// Message displayed when a magic word is updated
  ///
  /// In en, this message translates to:
  /// **'Magic word updated'**
  String get magicWordUpdated;

  /// Message displayed when a magic word is removed
  ///
  /// In en, this message translates to:
  /// **'Magic word removed'**
  String get magicWordRemoved;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'pt': return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
