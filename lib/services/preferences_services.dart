import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/Settings.dart';

enum PreferencesKeys {
  initializeKeys('initialize_keys'),
  publicKey('public_key'),
  privateKey('private_key'),
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
    return preference ?? defaultPreferences[key] as T;
  }

  Future<Map<PreferencesKeys, dynamic>> createSettingsMap() async {
    return {
      PreferencesKeys.privateKey:
          await getPrefOrDefault<String>(PreferencesKeys.privateKey),
      PreferencesKeys.publicKey:
          await getPrefOrDefault<String>(PreferencesKeys.publicKey),
      PreferencesKeys.initializeKeys:
          await getPrefOrDefault<bool>(PreferencesKeys.initializeKeys),
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
