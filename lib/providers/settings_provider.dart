import 'package:flutter/cupertino.dart';
import 'package:logger/logger.dart';
import 'package:safety_eye_app/services/preferences_services.dart';

import '../models/Settings.dart';

class SettingsProvider extends ChangeNotifier {
  final PreferencesService _preferencesService;
  final Logger _logger = Logger();
  late Settings _settingsState;

  Settings get settingsState => _settingsState;

  SettingsProvider(this._preferencesService) {
    init();
  }

  Future<SettingsProvider> init() async {
    _settingsState = await _preferencesService.getSettings();
    notifyListeners();
    return this;
  }

  Future<void> changeSettings(
      Map<PreferencesKeys, dynamic> settingsToUpdate) async {
    try {
      await Future.wait(settingsToUpdate.entries.map((entry) async {
        await _preferencesService.setPref(entry.key, entry.value);
      }));
      _settingsState = await _preferencesService.getSettings();
      notifyListeners();
    } catch (error, stackTrace) {
      _logger.e(error.toString(), stackTrace: stackTrace);
    }
  }
}
