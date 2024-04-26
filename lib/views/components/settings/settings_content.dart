import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:numberpicker/numberpicker.dart';

const double fontSize = 12;
const List<Widget> videoResolution = <Widget>[
  Text('Low', style: TextStyle(fontSize: fontSize)),
  Text('Medium', style: TextStyle(fontSize: fontSize)),
  Text('High', style: TextStyle(fontSize: fontSize)),
  Text('Max', style: TextStyle(fontSize: fontSize))
];

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int chunkDuration = 60;
  int gracePeriodInterval = 60;
  bool autoUpload = true;
  List<bool> _videoResolution = <bool>[false, false, true, false];

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
                    for (int i = 0; i < _videoResolution.length; i++) {
                      _videoResolution[i] = i == index;
                    }
                  });
                }),
          ],
        ),
      ]),
    );
  }
}
