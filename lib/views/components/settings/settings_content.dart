import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:safety_eye_app/providers/settings_provider.dart';

import '../../../services/preferences_services.dart';

const double fontSize = 12;

class SettingsPage extends StatefulWidget {
  final SettingsProvider settingsProvider;

  const SettingsPage(this.settingsProvider, {super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late int chunkDuration;
  late int gracePeriodInterval;
  late bool autoUpload;

  final List<bool> _videoResolution = [false, false, false, false];
  List<Widget> videoResolution = const [
    Text('Low', style: TextStyle(fontSize: fontSize)),
    Text('Medium', style: TextStyle(fontSize: fontSize)),
    Text('High', style: TextStyle(fontSize: fontSize)),
    Text('Max', style: TextStyle(fontSize: fontSize))
  ];
  late int selectedResolution;

  void buildVideoResolutionSelection() {
    for (int i = 0; i < _videoResolution.length; i++) {
      _videoResolution[i] = i == selectedResolution;
    }
  }
  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(children: [
        Row(
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
              },
              axis: Axis.horizontal,
            )
          ],
        ),
        Row(
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
              },
              axis: Axis.horizontal,
            )
          ],
        ),
        Row(
          children: [
            Text('Auto upload'),
            Spacer(),
            Switch(
              value: autoUpload,
              onChanged: (value) {
                setState(() {
                  autoUpload = value;
                });
              },
            )
          ],
        ),
        Row(
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
        ),
      ]),
    );
  }
}
