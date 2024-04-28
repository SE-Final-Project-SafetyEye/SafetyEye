import '../services/preferences_services.dart';

final Map<PreferencesKeys, dynamic> defaultPreferences = {
  PreferencesKeys.privateKey: 'default_private_key',
  PreferencesKeys.publicKey: 'default_public_key',
  PreferencesKeys.initializeKeys: false,
  PreferencesKeys.chunkDuration: 60,
  PreferencesKeys.autoUpload: false,
  PreferencesKeys.gracePeriodInterval: 20,
  PreferencesKeys.videoResolution: 'high',
};

class Settings {
  late String privateKey;
  late String publicKey;
  late bool initializeKeys;
  late int chunkDuration;
  late bool autoUpload;
  late int gracePeriodInterval;
  late String videoResolution;

  Settings(Map<PreferencesKeys, dynamic> settingsMap) {
    privateKey = settingsMap[PreferencesKeys.privateKey];
    publicKey = settingsMap[PreferencesKeys.publicKey];
    initializeKeys = settingsMap[PreferencesKeys.initializeKeys];
    chunkDuration = settingsMap[PreferencesKeys.chunkDuration];
    autoUpload = settingsMap[PreferencesKeys.autoUpload];
    gracePeriodInterval = settingsMap[PreferencesKeys.gracePeriodInterval];
    videoResolution = settingsMap[PreferencesKeys.videoResolution];
  }

  Settings.defaultSettings() {
    privateKey = defaultPreferences[PreferencesKeys.privateKey];
    publicKey = defaultPreferences[PreferencesKeys.publicKey];
    initializeKeys = defaultPreferences[PreferencesKeys.initializeKeys];
    chunkDuration = defaultPreferences[PreferencesKeys.chunkDuration];
    autoUpload = defaultPreferences[PreferencesKeys.autoUpload];
    gracePeriodInterval =
        defaultPreferences[PreferencesKeys.gracePeriodInterval];
    videoResolution = defaultPreferences[PreferencesKeys.videoResolution];
  }
}
