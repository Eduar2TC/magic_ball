import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:magic_ball/src/models/app_state.dart';
import 'package:magic_ball/src/core/localizations/i18n/app_localizations.dart';
import 'package:provider/provider.dart';

class MagicListSettings extends StatefulWidget {
  const MagicListSettings({super.key});

  @override
  State<MagicListSettings> createState() => _MagicListSettingsState();
}

class _MagicListSettingsState extends State<MagicListSettings> {
  final GlobalKey<SliverAnimatedListState> _listKey =
      GlobalKey<SliverAnimatedListState>();

  void _showAddMagicWordDialog() {
    final textEditingController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = Theme.of(context).primaryColor;
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xff181461),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white12, width: 1.5),
        ),
        title: Text(
          l10n.addMagicWord,
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: TextField(
          controller: textEditingController,
          autofocus: true,
          style: GoogleFonts.roboto(color: Colors.white),
          decoration: InputDecoration(
            hintText: l10n.enterMagicWord,
            hintStyle: GoogleFonts.roboto(color: Colors.white54),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white30),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.roboto(
                color: Colors.white60,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xff10024f),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final magicWord = textEditingController.text.trim();
              if (magicWord.isEmpty) return;
              final appState = Provider.of<AppState>(context, listen: false);
              final insertIndex = appState.magicList?.length ?? 0;

              appState.addMagicWord(magicWord);
              _listKey.currentState?.insertItem(insertIndex);

              _showSnackBar(context, magicWord, l10n.magicWordAdded, () {
                if (insertIndex < (appState.magicList?.length ?? 0)) {
                  final removed = appState.magicList!.removeAt(insertIndex);
                  _listKey.currentState?.removeItem(
                    insertIndex,
                    (context, animation) =>
                        _buildAnimatedItem(removed, animation),
                  );
                  appState.saveAllData();
                }
              });

              appState.saveAllData();
              if (context.mounted) Navigator.of(context).pop();
            },
            child: Text(
              l10n.add,
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditMagicWordDialog(String currentMagicWord, int index) {
    final textEditingController = TextEditingController(text: currentMagicWord);
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xff181461),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white12, width: 1.5),
        ),
        title: Text(
          l10n.editMagicWord,
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: TextField(
          controller: textEditingController,
          autofocus: true,
          style: GoogleFonts.roboto(color: Colors.white),
          decoration: InputDecoration(
            hintText: l10n.enterMagicWord,
            hintStyle: GoogleFonts.roboto(color: Colors.white54),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white30),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.roboto(
                color: Colors.white60,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xff10024f),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final newWord = textEditingController.text.trim();
              if (newWord.isEmpty) return;
              final appState = Provider.of<AppState>(context, listen: false);
              final oldWord = appState.magicList![index];

              appState.editMagicWord(index, newWord);

              _showSnackBar(context, newWord, l10n.magicWordUpdated, () {
                appState.editMagicWord(index, oldWord);
                appState.saveAllData();
              });

              await appState.saveAllData();
              if (context.mounted) Navigator.of(context).pop();
            },
            child: Text(
              l10n.save,
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String word, String message,
      VoidCallback undoCallback) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.roboto(color: Colors.white),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xff28237d),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: l10n.undo,
          textColor: Colors.amberAccent,
          onPressed: undoCallback,
        ),
      ),
    );
  }

  Widget _buildAnimatedItem(String word, Animation<double> animation,
      [int? index]) {
    final l10n = AppLocalizations.of(context)!;
    return SizeTransition(
      sizeFactor: animation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.0),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            title: Text(
              word,
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white70),
                  onPressed: () {
                    if (index != null) _showEditMagicWordDialog(word, index);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () {
                    final appState = Provider.of<AppState>(context, listen: false);
                    if (index != null && index < appState.magicList!.length) {
                      final removed = appState.magicList!.removeAt(index);
                      _listKey.currentState?.removeItem(
                        index,
                        (context, animation) =>
                            _buildAnimatedItem(removed, animation),
                      );

                      _showSnackBar(context, removed, l10n.magicWordRemoved, () {
                        appState.magicList!.insert(index, removed);
                        _listKey.currentState?.insertItem(index);
                        appState.saveAllData();
                      });

                      appState.saveAllData();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final magicList = appState.magicList ?? [];
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          l10n.magicList,
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
          child: magicList.isEmpty
              ? Center(
                  child: Text(
                    'No hay respuestas mágicas',
                    style: GoogleFonts.roboto(color: Colors.white70, fontSize: 16),
                  ),
                )
              : CustomScrollView(
                  key: ValueKey('scroll_${appState.currentLanguage}'),
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    const SliverPadding(padding: EdgeInsets.only(top: 10)),
                    SliverAnimatedList(
                      key: _listKey,
                      initialItemCount: magicList.length,
                      itemBuilder: (context, index, animation) =>
                          _buildAnimatedItem(magicList[index], animation, index),
                    ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMagicWordDialog,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff10024f),
        icon: const Icon(Icons.add, size: 24),
        label: Text(
          l10n.add,
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }
}
