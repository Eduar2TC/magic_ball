import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:magic_ball/src/models/app_state.dart';
import 'package:magic_ball/src/core/localizations/i18n/app_localizations.dart';
import 'package:provider/provider.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final dataConfigurations = appState.dataConfigurations;
    final currentLang = appState.currentLanguage;
    final l10n = AppLocalizations.of(context)!;
    final appBarTitle = l10n.appbarTitle_settings;
    final dropDownOptionTitle = l10n.dropDownOptionTitle;
    final dropDownOptionEnglish = l10n.dropDownOptionEnglish;
    final dropDownOptionSpanish = l10n.dropDownOptionSpanish;
    final dropDownOptionPortuguese = l10n.dropDownOptionPortuguese;
    final magicListTitle = l10n.magicList;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarColor: Colors.transparent,
        ),
        title: Text(
          appBarTitle,
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xff28237d), Color(0xff10024f)],
            stops: [0.65, 1],
            center: Alignment.center,
            radius: 0.8,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final containerWidth = constraints.maxWidth;
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      
                      // CATEGORY: GENERAL
                      _buildCategoryHeader(context, 'General', Icons.tune),
                      const SizedBox(height: 10),
                      
                      _buildGlassCard(
                        child: Column(
                          children: [
                            // Idioma Setting
                            _buildSettingRow(
                              icon: Icons.language,
                              title: dropDownOptionTitle,
                              trailing: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: currentLang,
                                  dropdownColor: const Color(0xff181461),
                                  alignment: Alignment.centerRight,
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
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
                                  iconSize: 24,
                                  iconEnabledColor: Colors.white,
                                ),
                              ),
                            ),
                            
                            const Divider(color: Colors.white12, height: 1),
                            
                            // Magic List Setting
                            _buildSettingRow(
                              icon: Icons.list_alt,
                              title: magicListTitle,
                              trailing: IconButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/magic_list_settings');
                                },
                                icon: const Icon(
                                  Icons.chevron_right,
                                  color: Colors.white70,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 25),
                      
                      // CATEGORY: INTERACTION
                      _buildCategoryHeader(context, 'Interacción', Icons.touch_app),
                      const SizedBox(height: 10),
                      
                      _buildGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tap to get answer
                            _buildSwitchTile(
                              icon: Icons.fingerprint,
                              title: 'Toque en la bola',
                              subtitle: 'Toca la bola mágica para obtener respuestas',
                              value: appState.tapToGetAnswerEnabled,
                              onChanged: (value) {
                                appState.tapToGetAnswerEnabled = value;
                              },
                            ),
                            
                            const Divider(color: Colors.white12, height: 1),
                            
                            // Shake to get answer
                            _buildSwitchTile(
                              icon: Icons.vibration,
                              title: 'Agitación del dispositivo',
                              subtitle: 'Agita tu teléfono para activar la respuesta',
                              value: appState.shakeToGetAnswerEnabled,
                              onChanged: (value) {
                                appState.shakeToGetAnswerEnabled = value;
                              },
                            ),
                            
                            // Shake sensitivity - embedded when shake is enabled
                            if (appState.shakeToGetAnswerEnabled) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: Divider(color: Colors.white12, height: 1),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Sensibilidad de agitación',
                                          style: GoogleFonts.roboto(
                                            color: Colors.white70,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          appState.shakeSensitivity.toStringAsFixed(1),
                                          style: GoogleFonts.roboto(
                                            color: Colors.tealAccent,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Icon(Icons.fitness_center, color: Colors.white38, size: 18),
                                        Expanded(
                                          child: SliderTheme(
                                            data: SliderTheme.of(context).copyWith(
                                              activeTrackColor: Colors.tealAccent,
                                              inactiveTrackColor: Colors.white12,
                                              thumbColor: Colors.white,
                                              overlayColor: Colors.tealAccent.withOpacity(0.15),
                                              valueIndicatorColor: const Color(0xff28237d),
                                              valueIndicatorTextStyle: const TextStyle(color: Colors.white),
                                            ),
                                            child: Slider(
                                              value: appState.shakeSensitivity,
                                              min: 2.0,
                                              max: 10.0,
                                              divisions: 8,
                                              onChanged: (value) {
                                                appState.shakeSensitivity = value;
                                              },
                                            ),
                                          ),
                                        ),
                                        const Icon(Icons.flash_on, color: Colors.tealAccent, size: 18),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.04),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.info_outline,
                                            color: Colors.tealAccent,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              appState.shakeSensitivity <= 3.5
                                                  ? '⚡ Muy sensible - se activa con movimientos suaves'
                                                  : appState.shakeSensitivity <= 6.0
                                                      ? '👍 Normal - requiere agitación moderada'
                                                      : '💪 Resistente - necesita agitación fuerte',
                                              style: GoogleFonts.roboto(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 25),
                      
                      // ERROR DIALOG BANNER IF BOTH DISABLED
                      if (!appState.tapToGetAnswerEnabled && !appState.shakeToGetAnswerEnabled)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.25), width: 1.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Ambos métodos están desactivados. Activa al menos uno para usar la bola mágica.',
                                  style: GoogleFonts.roboto(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 18),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.roboto(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.roboto(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.tealAccent,
            activeTrackColor: Colors.tealAccent.withOpacity(0.3),
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: Colors.white12,
          ),
        ],
      ),
    );
  }
}