import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../services/preferences_services.dart';

final Map<PreferencesKeys, dynamic> defaultPreferences = {
  PreferencesKeys.privateKey: base64Encode('default_private_key'.codeUnits),
  PreferencesKeys.publicKey: base64Encode('default_public_key'.codeUnits),
  PreferencesKeys.areKeysInitialize: false,
  PreferencesKeys.chunkDuration: 60,
  PreferencesKeys.autoUpload: false,
  PreferencesKeys.gracePeriodInterval: 20,
  PreferencesKeys.videoResolution: 'high',
};

class Settings {
  final _keyPairType = KeyPairType.x25519;

  late SimpleKeyPair keyPair;
  late bool initializeKeys;
  late int chunkDuration;
  late bool autoUpload;
  late int gracePeriodInterval;
  late String videoResolution;

  Settings(Map<PreferencesKeys, dynamic> settingsMap) {
    keyPair = SimpleKeyPairData(
        base64Decode(settingsMap[PreferencesKeys.privateKey]),
        publicKey: SimplePublicKey(
            base64Decode(settingsMap[PreferencesKeys.publicKey]),
            type: _keyPairType),
        type: _keyPairType);
    initializeKeys = settingsMap[PreferencesKeys.areKeysInitialize];
    chunkDuration = settingsMap[PreferencesKeys.chunkDuration];
    autoUpload = settingsMap[PreferencesKeys.autoUpload];
    gracePeriodInterval = settingsMap[PreferencesKeys.gracePeriodInterval];
    videoResolution = settingsMap[PreferencesKeys.videoResolution];
  }
}
