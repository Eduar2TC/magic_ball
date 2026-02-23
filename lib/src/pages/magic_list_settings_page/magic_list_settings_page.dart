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
  final GlobalKey<SliverAnimatedListState> _listKey = GlobalKey<SliverAnimatedListState>();

  void _showAddMagicWordDialog() {
    final textEditingController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text('Add Magic Word'),
        content: TextField(
          controller: textEditingController,
          decoration: const InputDecoration(hintText: 'Enter a magic word'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final magicWord = textEditingController.text.trim();
              if (magicWord.isEmpty) return;
              final appState = Provider.of<AppState>(context, listen: false);
              final insertIndex = appState.magicList?.length ?? 0;

              appState.addMagicWord(magicWord);
              _listKey.currentState?.insertItem(insertIndex);

              _showSnackBar(context, magicWord, 'Magic word added', () {
                if (insertIndex < (appState.magicList?.length ?? 0)) {
                      final removed = appState.magicList!.removeAt(insertIndex);
                      _listKey.currentState?.removeItem(
                        insertIndex,
                        (context, animation) => _buildAnimatedItem(removed, animation),
                      );
                  appState.saveAllData();
                }
              });

              appState.saveAllData();
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditMagicWordDialog(String currentMagicWord, int index) {
    final textEditingController = TextEditingController(text: currentMagicWord);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text('Edit Magic Word'),
        content: TextField(
          controller: textEditingController,
          decoration: const InputDecoration(hintText: 'Enter a magic word'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final newWord = textEditingController.text.trim();
              if (newWord.isEmpty) return;
              final appState = Provider.of<AppState>(context, listen: false);
              final oldWord = appState.magicList![index];

              // Usar el nuevo método editMagicWord
              appState.editMagicWord(index, newWord);

              _showSnackBar(context, newWord, 'Magic word updated', () {
                appState.editMagicWord(index, oldWord); // Deshacer con la palabra antigua
                appState.saveAllData();
              });

              await appState.saveAllData();
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String word, String message, VoidCallback undoCallback) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        action: SnackBarAction(label: 'Undo', onPressed: undoCallback),
      ),
    );
  }

  Widget _buildAnimatedItem(String word, Animation<double> animation, [int? index]) {
    return SizeTransition(
      sizeFactor: animation,
      child: ListTile(
        title: Text(word),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                if (index != null) _showEditMagicWordDialog(word, index);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                final appState = Provider.of<AppState>(context, listen: false);
                if (index != null && index < appState.magicList!.length) {
                  final removed = appState.magicList!.removeAt(index);
                  _listKey.currentState?.removeItem(
                    index,
                    (context, animation) => _buildAnimatedItem(removed, animation),
                  );

                  _showSnackBar(context, removed, 'Magic word removed', () {
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final magicList = appState.magicList ?? [];

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
              SliverAnimatedList(
                key: _listKey,
                initialItemCount: magicList.length,
                itemBuilder: (context, index, animation) => _buildAnimatedItem(magicList[index], animation, index),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMagicWordDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}