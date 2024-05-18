import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/Settings.dart';

enum PreferencesKeys {
  areKeysInitialize('are_keys_initialize'),
  publicKey('public_key'),
  privateKey('private_key'),
  exchangeKey('exchange_key'),
  chunkDuration('chunk_duration'),
  autoUpload('auto_upload'),
  gracePeriodInterval('grace_period_interval'),
  videoResolution('video_resolution');

  const PreferencesKeys(String value) : _value = value;
  final String _value;

  @visibleForTesting
  String get value => _value;
}

class PreferencesService {
  SharedPreferences? _prefs;

  Future<void> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> setPref<T>(PreferencesKeys key, T value) async {
    await _getPrefs();
    String keyString = key._value;
    switch (value.runtimeType) {
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
        throw Exception('Type not supported - setPref');
    }
  }

  Future<T> getPrefOrDefault<T>(PreferencesKeys key) async {
    await _getPrefs();
    String keyString = key._value;

    T? preference;

    if (T == String) {
      preference = _prefs!.getString(keyString) as T?;
    } else if (T == int) {
      preference = _prefs!.getInt(keyString) as T?;
    } else if (T == double) {
      preference = _prefs!.getDouble(keyString) as T?;
    } else if (T == bool) {
      preference = _prefs!.getBool(keyString) as T?;
    } else {
      throw Exception('Type not supported - getPrefOrDefault');
    }

    return preference ?? defaultPreferences[key] as T;
  }

  Future<Map<PreferencesKeys, dynamic>> createSettingsMap() async {
    return {
      PreferencesKeys.chunkDuration:
          await getPrefOrDefault<int>(PreferencesKeys.chunkDuration),
      PreferencesKeys.autoUpload:
          await getPrefOrDefault<bool>(PreferencesKeys.autoUpload),
      PreferencesKeys.gracePeriodInterval:
          await getPrefOrDefault<int>(PreferencesKeys.gracePeriodInterval),
      PreferencesKeys.videoResolution:
          await getPrefOrDefault<String>(PreferencesKeys.videoResolution),
    };
  }

  Future<Settings> getSettings() async {
    return Settings(await createSettingsMap());
  }

}
