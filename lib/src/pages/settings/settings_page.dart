import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:magic_ball/src/models/app_state.dart';
import 'package:magic_ball/src/utils/data_configurations.dart';
import 'package:magic_ball/src/utils/shared_preferences.dart';
import 'package:provider/provider.dart';

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
  final ValueNotifier<double> horizontalValueNotifier = ValueNotifier<double>(0);
  final ValueNotifier<double> verticalValueNotifier = ValueNotifier<double>(0);
  final ValueNotifier<Map?> dataConfigurationsNotifier = ValueNotifier<Map?>(null);

  final SharedPreferencesUtils sharedPreferencesUtils = SharedPreferencesUtils();
  DataConfigurations? dataConfigurations;
  List<String>? magicList;
  int? previousValue;

  int getOption() {
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
      dataConfigurationsNotifier.value = dataLanguage;
    } catch (e) {
      log('Error : $e');
    }
  }

  void swapLanguageStrings() {
    var temp = dataConfigurations
        ?.langStrings[dataConfigurations?.langStrings.keys.first];
    dataConfigurations
            ?.langStrings[dataConfigurations?.langStrings.keys.first] =
        dataConfigurations
            ?.langStrings[dataConfigurations?.langStrings.keys.elementAt(1)];
    dataConfigurations
        ?.langStrings[dataConfigurations?.langStrings.keys.elementAt(1)] = temp;
    dataConfigurationsNotifier.value = dataConfigurations
        ?.langStrings[dataConfigurations?.langStrings.keys.first];
  }

  @override
  void dispose() {
    horizontalValueNotifier.dispose();
    verticalValueNotifier.dispose();
    dataConfigurationsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final dataConfigurations = appState.dataConfigurations;
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (boolean, result) async {
        returnDataLanguage(context);
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
          title: ValueListenableBuilder<Map?>(
            valueListenable: dataConfigurationsNotifier,
            builder: (context, dataLanguage, child) {
              return Text(
                dataLanguage?['appbarTitle']['settings'] ?? '',
                style: TextStyle(color: dataConfigurations!.titleAppBarColor),
              );
            },
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
                width: width * 0.8,
                height: width * 0.8,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ValueListenableBuilder<Map?>(
                          valueListenable: dataConfigurationsNotifier,
                          builder: (context, dataLanguage, child) {
                            return Text(
                              dataLanguage?['dropDownOptionTitle'] ?? '',
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontStyle: FontStyle.normal,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            );
                          },
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
                                child: ValueListenableBuilder<Map?>(
                                  valueListenable: dataConfigurationsNotifier,
                                  builder: (context, dataLanguage, _) {
                                    return Text(
                                      dataLanguage?[
                                              'dropDownOptionEnglish'] ??
                                          '',
                                    );
                                  },
                                ),
                              ),
                              DropdownMenuItem(
                                value: 2,
                                child: ValueListenableBuilder<Map?>(
                                  valueListenable: dataConfigurationsNotifier,
                                  builder: (context, dataLanguage, _) {
                                    return Text(
                                      dataLanguage?[
                                              'dropDownOptionSpanish'] ??
                                          '',
                                    );
                                  },
                                ),
                              )
                            ],
                            onChanged: (int? value) {
                              if (value != previousValue) {
                                swapLanguageStrings();
                              }
                              previousValue = value;
                            },
                            iconSize: 50,
                            iconEnabledColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        ValueListenableBuilder<double>(
                          valueListenable: horizontalValueNotifier,
                          builder: (context, horizontalValue, child) {
                            return Slider(
                              activeColor: Colors.white70,
                              value: horizontalValue,
                              min: 0,
                              max: 1,
                              divisions: 5,
                              label: horizontalValue.toString(),
                              onChanged: (double newRating) {
                                horizontalValueNotifier.value = newRating;
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        ValueListenableBuilder<double>(
                          valueListenable: verticalValueNotifier,
                          builder: (context, verticalValue, child) {
                            return Slider(
                              activeColor: Colors.white70,
                              value: verticalValue,
                              min: 0,
                              max: 1,
                              divisions: 5,
                              label: verticalValue.toString(),
                              onChanged: (double newRating) {
                                verticalValueNotifier.value = newRating;
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    //option add more words to the magic list app
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Magic List',
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontStyle: FontStyle.normal,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      IconButton(
                          onPressed: (){
                            Navigator.pushNamed(context, '/magic_list_settings');
                          },
                          icon: Icon(
                              Icons.edit,
                              color: Colors.white,
                              size:  width*0.08
                          ),
                      ),
                    ],
                  ),
                  ],
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
    Provider.of<AppState>(context, listen: false)
        .updateDataConfigurations(dataConfigurations!);
    Provider.of<AppState>(context, listen: false).updateMagicList(tmp);
    Provider.of<AppState>(context, listen: false).saveData();
    Navigator.pop(
        context, {'dataConfigurations': dataConfigurations, 'magicList': tmp});
  }
}
