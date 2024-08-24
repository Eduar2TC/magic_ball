import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:magic_ball/src/utils/data.dart';
import 'package:magic_ball/src/utils/shared_preferences.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  SettingsState createState() => SettingsState();
}

class SettingsState extends State<Settings> {
  late String titleAppBar;
  late String dropDownLangOption;
  static String horizontal = 'horizontal';
  static String vertical = 'vertical';

  late Map dataLanguage;
  late double horizontalValue = 0;
  late double verticalValue = 0;

  final SharedPreferencesUtils sharedPreferencesUtils =
      SharedPreferencesUtils();
  DataConfigurations? dataConfigurations;
  List<String>? magicList;
  int? previusValue;

  int getOption() {
    //log('Data Language: ${dataConfigurations?.langStrings[dataConfigurations?.langStrings.keys.first]}');
    return dataConfigurations?.langStrings[dataConfigurations?.langStrings.keys
                .elementAt(0)]['appbarTitle']['settings'] ==
            'Ajustes'
        ? 2
        : 1;
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    try {
      dataConfigurations = await sharedPreferencesUtils
          .getDataConfigurationsFromSharedPreferences();
      magicList = dataConfigurations?.listMagicOptionsStrings;
      dataLanguage = dataConfigurations
          ?.langStrings[dataConfigurations?.langStrings.keys.elementAt(0)];
    } catch (e) {
      log('Error : $e');
    } finally {
      setState(() {});
    }
  }

  void swapLanguageStrings() {
    setState(() {
      var temp = dataConfigurations
          ?.langStrings[dataConfigurations?.langStrings.keys.first];
      dataConfigurations
              ?.langStrings[dataConfigurations?.langStrings.keys.first] =
          dataConfigurations
              ?.langStrings[dataConfigurations?.langStrings.keys.elementAt(1)];
      dataConfigurations
              ?.langStrings[dataConfigurations?.langStrings.keys.elementAt(1)] =
          temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        returnDataLanguage(context);
        return true;
      },
      child: Scaffold(
        backgroundColor: dataConfigurations?.backgroundColor,
        appBar: AppBar(
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarBrightness: Brightness.dark,
            statusBarColor: Colors.transparent,
          ),
          title: Text(
            dataConfigurations
                    ?.langStrings[dataConfigurations?.langStrings.keys.first]
                ['appbarTitle']['settings'],
            style: TextStyle(color: dataConfigurations!.titleAppBarColor),
          ),
          backgroundColor: dataConfigurations?.appBarColor,
          centerTitle: true,
        ),
        body: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [Color(0xff28237d), Color(0xff10024f)],
                stops: [0.65, 1],
                center: Alignment.center,
                radius: 0.8,
              ),
            ),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(5),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 50, horizontal: 10),
                child: FittedBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Text(
                            dataConfigurations?.langStrings[dataConfigurations
                                ?.langStrings
                                .keys
                                .first]['dropDownOptionTitle'],
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontStyle: FontStyle.normal,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          DropdownButtonHideUnderline(
                            child: DropdownButton(
                              value: getOption(),
                              dropdownColor: const Color(0xff28237d),
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontStyle: FontStyle.normal,
                                fontWeight: FontWeight.bold,
                                fontSize: 30,
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 1,
                                  child: Text(
                                    dataConfigurations?.langStrings[
                                        dataConfigurations?.langStrings.keys
                                            .first]['dropDownOptionEnglish'],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 2,
                                  child: Text(
                                    dataConfigurations?.langStrings[
                                        dataConfigurations?.langStrings.keys
                                            .first]['dropDownOptionSpanish'],
                                  ),
                                )
                              ],
                              onChanged: (int? value) {
                                if (value != previusValue) {
                                  swapLanguageStrings();
                                }
                                previusValue = value;
                              },
                              iconSize: 50,
                              iconEnabledColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            horizontal,
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontStyle: FontStyle.normal,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          Slider(
                              activeColor: Colors.white70,
                              value: horizontalValue,
                              min: 0,
                              max: 1,
                              divisions: 5,
                              label: horizontalValue.toString(),
                              onChanged: (double newRating) {
                                setState(() {
                                  horizontalValue = newRating;
                                });
                              })
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            vertical,
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontStyle: FontStyle.normal,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          Slider(
                              activeColor: Colors.white70,
                              value: verticalValue,
                              min: 0,
                              max: 1,
                              divisions: 5,
                              label: verticalValue.toString(),
                              onChanged: (double newRating) {
                                setState(() {
                                  verticalValue = newRating;
                                });
                              })
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void returnDataLanguage(BuildContext context) {
    List<String> tmp = (dataConfigurations
                ?.langStrings[dataConfigurations?.langStrings.keys.elementAt(0)]
            ['translate']['list'] as List<dynamic>)
        .cast<String>();
    sharedPreferencesUtils.saveDataToSharedPreferences(
        dataConfigurations!, tmp);
    sharedPreferencesUtils.saveMagicListToSharedPreferences(tmp);
    Navigator.pop(context, {
      'dataConfigurations': dataConfigurations,
      'magicList': tmp
    }); // Pass updated data back
  }
}
