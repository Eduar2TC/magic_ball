import 'package:magic_ball/src/constants/constants.dart';
import 'package:magic_ball/src/utils/data_configurations.dart';
import 'package:shared_preferences/shared_preferences.dart';
//get data if it exist in shared preferences device , if not return predefined constant data
class SharedPreferencesUtils {

  Future<void> saveDataToSharedPreferences( DataConfigurations dataConfigurations, List<String> magicList) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString(
      'dataConfigurations',
      dataConfigurations.toJson(),
    );
    await sharedPreferences.setStringList(
      'magicList',
      magicList,
    );
  }

  Future<DataConfigurations?> getDataConfigurationsFromSharedPreferences() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? jsonString = sharedPreferences.getString('dataConfigurations');
    return jsonString != null ? DataConfigurations.fromJson(jsonString) : null;
  }

  Future<List<String>?> getMagicListFromSharedPreferences() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    List<String>? magicList = sharedPreferences.getStringList('magicList');
    return magicList ?? [];
  }

  Future<void> saveMagicListToSharedPreferences(List<String> magicList) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setStringList(
      'magicList',
      magicList,
    );
  }
}
