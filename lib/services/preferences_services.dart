import 'package:shared_preferences/shared_preferences.dart';

enum PreferencesKeys {
  initializeKeys('initialize_keys'),
  publicKey('public_key'),
  privateKey('private_key');

  const PreferencesKeys(String value) : _value = value;
  final String _value;
}

abstract class PreferencesService {
  SharedPreferences? prefs;
  final Map<String, dynamic> defaultPreferences = {
    PreferencesKeys.privateKey._value: 'default_private_key',
    PreferencesKeys.publicKey._value: 'default_public_key',
    PreferencesKeys.initializeKeys._value: false,
  };

  Future<void> _prefs() async {
    prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> setPref<T>(PreferencesKeys key, T value) async {
    await _prefs();
    String keyString = key._value;
    switch (T) {
      case String:
        prefs!.setString(keyString, value as String);
        break;
      case int:
        prefs!.setInt(keyString, value as int);
        break;
      case double:
        prefs!.setDouble(keyString, value as double);
        break;
      case bool:
        prefs!.setBool(keyString, value as bool);
        break;
      default:
        throw Exception('Type not supported');
    }
  }

  Future<T> getPrefOrDefault<T>(PreferencesKeys key) async {
    await _prefs();
    String keyString = key._value;
    T? preference = switch (T) {
      String => prefs!.getString(keyString) as T?,
      int => prefs!.getInt(keyString) as T?,
      double => prefs!.getDouble(keyString) as T?,
      bool => prefs!.getBool(keyString) as T?,
      _ => throw Exception('Type not supported'),
    };
    return preference ?? defaultPreferences[keyString] as T;
  }
}
