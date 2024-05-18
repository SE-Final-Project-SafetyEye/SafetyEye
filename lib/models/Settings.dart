import 'dart:convert';

import '../services/preferences_services.dart';

final Map<PreferencesKeys, dynamic> defaultPreferences = {
  PreferencesKeys.privateKey: base64Encode('default_private_key'.codeUnits),
  PreferencesKeys.publicKey: base64Encode('default_public_key'.codeUnits),
  PreferencesKeys.exchangeKey: base64Encode('default_exchange_key'.codeUnits),
  PreferencesKeys.areKeysInitialize: false,
  PreferencesKeys.chunkDuration: 60,
  PreferencesKeys.autoUpload: false,
  PreferencesKeys.gracePeriodInterval: 20,
  PreferencesKeys.videoResolution: 'high',
};

class Settings {
  late int chunkDuration;
  late bool autoUpload;
  late int gracePeriodInterval;
  late String videoResolution;

  Settings(Map<PreferencesKeys, dynamic> settingsMap) {
    chunkDuration = settingsMap[PreferencesKeys.chunkDuration];
    autoUpload = settingsMap[PreferencesKeys.autoUpload];
    gracePeriodInterval = settingsMap[PreferencesKeys.gracePeriodInterval];
    videoResolution = settingsMap[PreferencesKeys.videoResolution];
  }
}
