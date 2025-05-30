import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:magic_ball/src/models/app_state.dart';
import 'package:magic_ball/src/utils/data_configurations.dart';
import 'package:provider/provider.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  SettingsState createState() => SettingsState();
}

class SettingsState extends State<Settings> {
  late String titleAppBar;
  late String dropDownLangOption;

  late Map dataLanguage;
  final ValueNotifier<Map?> dataConfigurationsNotifier = ValueNotifier<Map?>(null);

  DataConfigurations? dataConfigurations;
  List<String>? magicList;

  int? previousValue;

  int getOption() {
    return dataConfigurations?.langStrings[dataConfigurations?.langStrings.keys.elementAt(0)]['appbarTitle']['settings'] == 'Ajustes' ? 2 : 1;
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      dataConfigurations = appState.dataConfigurations;
      magicList = dataConfigurations?.listMagicOptionsStrings;
      dataLanguage = dataConfigurations?.langStrings[dataConfigurations?.langStrings.keys.elementAt(0)];
      dataConfigurationsNotifier.value = dataLanguage;
    } catch (e) {
      log('Error : $e');
    }
  }

  void swapLanguageStrings() {
    var temp = dataConfigurations?.langStrings[dataConfigurations?.langStrings.keys.first];
    dataConfigurations?.langStrings[dataConfigurations?.langStrings.keys.first] = dataConfigurations?.langStrings[dataConfigurations?.langStrings.keys.elementAt(1)];
    dataConfigurations?.langStrings[dataConfigurations?.langStrings.keys.elementAt(1)] = temp;
    dataConfigurationsNotifier.value = dataConfigurations?.langStrings[dataConfigurations?.langStrings.keys.first];
  }

  @override
  void dispose() {
    dataConfigurationsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final dataConfigurations = appState.dataConfigurations;
    final width = MediaQuery.of(context).size.width;
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
              child: LayoutBuilder(builder: (context, constraints) {
                final containerWidth = constraints.maxWidth;
                final containerHeight = constraints.maxHeight;
                return Container(
                  width: containerWidth * 0.8,
                  height: containerWidth * 0.8,
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
                                  fontSize:  containerWidth * 0.05,
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
                                fontSize:  containerWidth * 0.05,
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 1,
                                  child: ValueListenableBuilder<Map?>(
                                    valueListenable: dataConfigurationsNotifier,
                                    builder: (context, dataLanguage, _) {
                                      return Text(
                                        dataLanguage?['dropDownOptionEnglish'] ?? '',
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
                                        dataLanguage?['dropDownOptionSpanish'] ?? '',
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
                              iconSize:  containerWidth * 0.05,
                              iconEnabledColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Magic List',
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontStyle: FontStyle.normal,
                              fontWeight: FontWeight.bold,
                              fontSize:  containerWidth * 0.05,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/magic_list_settings');
                            },
                            icon: Icon(Icons.edit, color: Colors.white, size:  containerWidth * 0.08),
                          ),
                        ],
                      ),
                      //Switch Shake to get answer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Shake to get answer',
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontStyle: FontStyle.normal,
                              fontWeight: FontWeight.bold,
                              fontSize:  containerWidth * 0.05,
                            ),
                          ),SizedBox(
                            width: containerWidth * 0.09,
                            child: FittedBox(
                              fit: BoxFit.fill,
                              child: Switch(
                                value: true,
                                onChanged: (bool value) {},
                                activeColor: Colors.white,
                              ),
                            ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  void returnDataLanguage(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.dataConfigurations = dataConfigurations;
    Navigator.pop(context, {'dataConfigurations': appState.dataConfigurations, 'magicList': appState.magicList});
  }
}
