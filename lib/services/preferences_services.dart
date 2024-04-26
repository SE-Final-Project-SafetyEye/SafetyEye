import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PreferencesKeys {
  initializeKeys('initialize_keys'),
  publicKey('public_key'),
  privateKey('private_key');

  const PreferencesKeys(String value) : _value = value;
  final String _value;

  @visibleForTesting
  String get value => _value;
}

final Map<String, dynamic> defaultPreferences = {
  PreferencesKeys.privateKey._value: 'default_private_key',
  PreferencesKeys.publicKey._value: 'default_public_key',
  PreferencesKeys.initializeKeys._value: false,
};

class PreferencesService {
  SharedPreferences? _prefs;

  Future<void> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> setPref<T>(PreferencesKeys key, T value) async {
    await _getPrefs();
    String keyString = key._value;
    switch (T) {
      case String:
        _prefs!.setString(keyString, value as String);
        break;
      case int:
        _prefs!.setInt(keyString, value as int);
        break;
      case double:
        _prefs!.setDouble(keyString, value as double);
        break;
      case bool:
        _prefs!.setBool(keyString, value as bool);
        break;
      default:
        throw Exception('Type not supported');
    }
  }

  Future<T> getPrefOrDefault<T>(PreferencesKeys key) async {
    await _getPrefs();
    String keyString = key._value;
    T? preference = switch (T) {
      String => _prefs!.getString(keyString) as T?,
      int => _prefs!.getInt(keyString) as T?,
      double => _prefs!.getDouble(keyString) as T?,
      bool => _prefs!.getBool(keyString) as T?,
      _ => throw Exception('Type not supported'),
    };
    return preference ?? defaultPreferences[keyString] as T;
  }
}
