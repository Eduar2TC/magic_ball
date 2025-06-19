import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:magic_ball/src/models/app_state.dart';
import 'package:magic_ball/src/utils/lang_helper.dart';
import 'package:provider/provider.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final dataConfigurations = appState.dataConfigurations;
    final currentLang = appState.currentLanguage;
    final langStrings = dataConfigurations?.langStrings;
    final width = MediaQuery.of(context).size.width;
    final appBarTitle = getLang(langStrings, currentLang, ['appbarTitle', 'settings']) ?? 'Settings';
    final dropDownOptionTitle = getLang(langStrings, currentLang, ['dropDownOptionTitle', 'settings']) ?? 'Languaje';
    final dropDownOptionEnglish = getLang(langStrings, currentLang, ['dropDownOptionEnglish', 'settings']) ?? 'English';
    final dropDownOptionSpanish = getLang(langStrings, currentLang, ['dropDownOptionSpanish', 'settings']) ?? 'Español';
    final dropDownOptionPortuguese = getLang(langStrings, currentLang, ['dropDownOptionPortuguese', 'settings']) ?? 'Português';
    final magicListTitle = getLang(langStrings, currentLang, ['magicListTitle']) ?? 'Magic List';
    final shakeOptionTitle = getLang(langStrings, currentLang, ['shakeOptionTitle']) ?? 'Shake to get answer';

    return Scaffold(
      backgroundColor: dataConfigurations?.backgroundColor,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarColor: Colors.transparent,
        ),
        title: Text(
          appBarTitle,
          style: TextStyle(color: dataConfigurations?.titleAppBarColor),
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
                    // Idioma
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dropDownOptionTitle,
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.bold,
                            fontSize: containerWidth * 0.05,
                          ),
                        ),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: currentLang,
                            dropdownColor: const Color(0xff28237d),
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontStyle: FontStyle.normal,
                              fontWeight: FontWeight.bold,
                              fontSize: containerWidth * 0.05,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'en',
                                child: Text(dropDownOptionEnglish),
                              ),
                              DropdownMenuItem(
                                value: 'es',
                                child: Text(dropDownOptionSpanish),
                              ),
                              DropdownMenuItem(
                                value: 'pt',
                                child: Text(dropDownOptionPortuguese),
                              ),
                            ],
                            onChanged: (String? value) {
                              if (value != null && value != currentLang) {
                                appState.currentLanguage = value;
                              }
                            },
                            iconSize: containerWidth * 0.05,
                            iconEnabledColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    // Magic List
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          magicListTitle,
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.bold,
                            fontSize: containerWidth * 0.05,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/magic_list_settings');
                          },
                          icon: Icon(Icons.edit, color: Colors.white, size: containerWidth * 0.08),
                        ),
                      ],
                    ),
                    // Shake to get answer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          shakeOptionTitle,
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.bold,
                            fontSize: containerWidth * 0.045,
                          ),
                        ),
                        SizedBox(
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
    );
  }
}
