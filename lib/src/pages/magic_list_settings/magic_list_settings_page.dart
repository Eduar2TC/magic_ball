import 'package:flutter/material.dart';
import 'package:magic_ball/src/models/app_state.dart';
import 'package:provider/provider.dart';
//load data from shared preferences or use a default list
//create a list view with the magic words
//add a button to add a new magic word
//add a button to remove a magic word
//add a button to reset the magic words to the default list
//add a button to save the magic words
//add a button to cancel the changes

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
              onPressed: () {
                final appState = Provider.of<AppState>(context, listen: false);
                final sharedPreferencesUtils = appState.sharedPreferencesUtils;
                final magicWord = textEditingController.text;
                if( magicWord.isNotEmpty ){
                  appState.magicList?.add(magicWord);
                  appState.saveData();
                  _showSnackBar(context, magicWord, 'Magic word added');
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
  //Snackbar to show a message when the magic word is removed or added
  void _showSnackBar(BuildContext context, String magicWord, String message) {
    if( magicWord.isNotEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
            },
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
                delegate: SliverChildBuilderDelegate( (context, index) {
                    return ListTile(
                      title: Text(magicList?[index] ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {},
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
      floatingActionButton:
      FloatingActionButton(
          onPressed: _showAddMagicWordDialog,
          child: const Icon(Icons.add)),
    );
  }
}