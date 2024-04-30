import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:safety_eye_app/providers/settings_provider.dart';

import '../../../services/preferences_services.dart';

class SettingsPage extends StatefulWidget {
  final SettingsProvider settingsProvider;

  const SettingsPage(this.settingsProvider, {super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final List<bool> _videoResolution = [false, false, false, false];
  final Logger _logger = Logger();

  late int chunkDuration;
  late int gracePeriodInterval;
  late bool autoUpload;
  late int selectedResolution;

  void buildVideoResolutionSelection() {
    for (int i = 0; i < _videoResolution.length; i++) {
      var isSelectedResolution = i == selectedResolution;
      _videoResolution[i] = isSelectedResolution;
    }
  }

  @override
  void initState() {
    chunkDuration = widget.settingsProvider.settingsState.chunkDuration;
    gracePeriodInterval =
        widget.settingsProvider.settingsState.gracePeriodInterval;
    autoUpload = widget.settingsProvider.settingsState.autoUpload;
    selectedResolution = switch (
        widget.settingsProvider.settingsState.videoResolution) {
      "low" => 0,
      'medium' => 1,
      'high' => 2,
      'max' => 3,
      _ => 0
    };
    buildVideoResolutionSelection();
    _logger.i('Settings page initialized');
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    widget.settingsProvider.changeSettings({
      PreferencesKeys.chunkDuration: chunkDuration,
      PreferencesKeys.gracePeriodInterval: gracePeriodInterval,
      PreferencesKeys.autoUpload: autoUpload,
      PreferencesKeys.videoResolution: switch (selectedResolution) {
        0 => "low",
        1 => 'medium',
        2 => 'high',
        3 => 'max',
        _ => "low"
      }
    });
    _logger.i('Settings page disposed');
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.bodySmall!.fontSize!;
    final List<Widget> videoResolution = [
      Text('Low', style: TextStyle(fontSize: fontSize)),
      Text('Medium', style: TextStyle(fontSize: fontSize)),
      Text('High', style: TextStyle(fontSize: fontSize)),
      Text('Max', style: TextStyle(fontSize: fontSize))
    ];
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(children: [
        _buildChunkDurationSection(fontSize),
        _buildGracePeriodInterval(fontSize),
        _buildAutoUpload(),
        _buildVideoResolution(videoResolution),
      ]),
    );
  }

  Row _buildVideoResolution(List<Widget> videoResolution) {
    return Row(
      children: [
        Text('Video resolution'),
        Spacer(),
        ToggleButtons(
            children: videoResolution,
            isSelected: _videoResolution,
            borderRadius: BorderRadius.circular(25),
            onPressed: (index) {
              setState(() {
                selectedResolution = index;
                buildVideoResolutionSelection();
              });
            }),
      ],
    );
  }

  Row _buildAutoUpload() {
    return Row(
      children: [
        Text('Auto upload'),
        Spacer(),
        Switch(
          value: autoUpload,
          onChanged: (value) {
            setState(() {
              autoUpload = value;
            });
            _logger.i('Auto upload changed to $value');
          },
        )
      ],
    );
  }

  Row _buildGracePeriodInterval(double fontSize) {
    return Row(
      children: [
        Text('Grace period interval (seconds)'),
        Spacer(),
        NumberPicker(
          value: gracePeriodInterval,
          minValue: 10,
          maxValue: 30,
          itemHeight: 50,
          itemWidth: 50,
          step: 5,
          textStyle: TextStyle(fontSize: fontSize),
          selectedTextStyle:
              TextStyle(fontSize: fontSize * 2, color: Colors.blue),
          onChanged: (value) {
            setState(() {
              gracePeriodInterval = value;
            });
            _logger.i('Grace period interval changed to $value');
          },
          axis: Axis.horizontal,
        )
      ],
    );
  }

  Row _buildChunkDurationSection(double fontSize) {
    return Row(
      children: [
        Text('Chunk duration (seconds)'),
        Spacer(),
        NumberPicker(
          value: chunkDuration,
          minValue: 40,
          maxValue: 80,
          itemHeight: 50,
          itemWidth: 50,
          step: 5,
          textStyle: TextStyle(fontSize: fontSize),
          selectedTextStyle:
              TextStyle(fontSize: fontSize * 2, color: Colors.blue),
          onChanged: (value) {
            setState(() {
              chunkDuration = value;
            });
            _logger.i('Chunk duration changed to $value');
          },
          axis: Axis.horizontal,
        )
      ],
    );
  }
}
