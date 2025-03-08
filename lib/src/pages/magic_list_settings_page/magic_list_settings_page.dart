import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:magic_ball/src/models/app_state.dart';
import 'package:provider/provider.dart';

class MagicListSettings extends StatefulWidget {
  const MagicListSettings({super.key});

  @override
  State<MagicListSettings> createState() => _MagicListSettingsState();
}

class _MagicListSettingsState extends State<MagicListSettings> {
  @override
  void dispose() {
    super.dispose();
  }

  void _showAddMagicWordDialog() {
    TextEditingController textEditingController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).primaryColor,
          title: const Text('Add Magic Word'),
          content: TextField(
            controller: textEditingController,
            decoration: const InputDecoration(
              hintText: 'Enter a magic word',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final appState = Provider.of<AppState>(context, listen: false);
                final magicWord = textEditingController.text;
                if (magicWord.isNotEmpty && appState.magicList != null) {
                  appState.updateMagicList(magicWord);
                  log('list from magic settings page ${appState.magicList}');
                  if (!context.mounted) return;
                  _showSnackBar(context, magicWord, 'Magic word added', () {

                    appState.saveAllData();
                    appState.removeMagicWord(magicWord);
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditMagicWordDialog(String currentMagicWord, int index) {
    TextEditingController textEditingController = TextEditingController(text: currentMagicWord);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).primaryColor,
          title: const Text('Edit Magic Word'),
          content: TextField(
            controller: textEditingController,
            decoration: const InputDecoration(
              hintText: 'Enter a magic word',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final appState = Provider.of<AppState>(context, listen: false);
                final newMagicWord = textEditingController.text;
                final oldMagicWord = appState.magicList![index];
                if (newMagicWord.isNotEmpty && appState.magicList != null) {
                  appState.magicList![index] = newMagicWord;
                  appState.saveAllData();
                  log('list from magic settings page ${appState.magicList}');
                  if (!context.mounted) return;
                  _showSnackBar(context, newMagicWord, 'Magic word updated', () {
                    appState.magicList![index] = oldMagicWord;
                    appState.saveAllData();
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  //Snack bar to show a message when the magic word is removed or added
  void _showSnackBar(BuildContext context, String magicWord, String message, VoidCallback undoCallback) {
    if (magicWord.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: undoCallback, //undo changes
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    //get data from shared preferences from app state
    final appState = Provider.of<AppState>(context);
    final dataConfigurations = appState.dataConfigurations;
    final magicList = appState.magicList;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Magic Words'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
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
          child: CustomScrollView(
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    return ListTile(
                      title: Text(magicList?[index] ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              final magicWord = magicList?[index];
                              if (magicWord != null) {
                                _showEditMagicWordDialog(magicWord, index);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              final magicWord = magicList?[index];
                              if (magicWord != null) {
                                final originalIndex = index;
                                if (!context.mounted) return;
                                _showSnackBar(context, magicWord, 'Magic word removed', () {
                                  appState.magicList!.insert(originalIndex, magicWord);
                                  appState.saveAllData();
                                });
                                appState.removeMagicWord(magicWord);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: magicList?.length ?? 0,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: _showAddMagicWordDialog, child: const Icon(Icons.add)),
    );
  }
}