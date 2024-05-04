import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorsProvider extends ChangeNotifier {
  late List<_PositionData> _currentPosition;
  late List<_AccelerometerData> _accelerometerEvents;
  late List<_UserAccelerometerData> _userAccelerometerEvents;
  late List<_MagnetometerData> _magnetometerEvents;
  late List<_GyroscopeData> _gyroscopeEvents;

  bool _run = false;
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  Duration sensorInterval = SensorInterval.normalInterval;

  Future<void> startCollectMetadata() async {
    _restart();
    _run = true;
    _initState();
  }

  Future<String> stopCollectMetadata() async {
    _run = false;
    _dispose();
    return _exportToJson();
  }

  void _initState() {
    _streamSubscriptions.add(
      userAccelerometerEventStream(samplingPeriod: sensorInterval).listen(
            (UserAccelerometerEvent event) {
          final now = DateTime.now();
          _UserAccelerometerData userAccelerometerData =
          _UserAccelerometerData(event, now);
          _userAccelerometerEvents.add(userAccelerometerData);
        },
        onError: (e) {
          print('Error receiving UserAccelerometerEvent: $e');
        },
        cancelOnError: true,
      ),
    );

    _streamSubscriptions.add(
      accelerometerEventStream(samplingPeriod: sensorInterval).listen(
            (AccelerometerEvent event) {
          final now = DateTime.now();
          _AccelerometerData accelerometerData = _AccelerometerData(event, now);
          _accelerometerEvents.add(accelerometerData);
        },
        onError: (e) {
          print('Error receiving AccelerometerEvent: $e');
        },
        cancelOnError: true,
      ),
    );

    _streamSubscriptions.add(
      gyroscopeEventStream(samplingPeriod: sensorInterval).listen(
            (GyroscopeEvent event) {
          final now = DateTime.now();
          _GyroscopeData gyroscopeData = _GyroscopeData(event, now);
          _gyroscopeEvents.add(gyroscopeData);
        },
        onError: (e) {
          print('Error receiving GyroscopeEvent: $e');
        },
        cancelOnError: true,
      ),
    );

    _streamSubscriptions.add(
      magnetometerEventStream(samplingPeriod: sensorInterval).listen(
            (MagnetometerEvent event) {
          final now = DateTime.now();
          _MagnetometerData magnetometerData = _MagnetometerData(event, now);
          _magnetometerEvents.add(magnetometerData);
        },
        onError: (e) {
          print('Error receiving MagnetometerEvent: $e');
        },
        cancelOnError: true,
      ),
    );

    _startGPSListener();
  }


  void _dispose() {
    for (var subscription in _streamSubscriptions) {
      subscription.cancel();
    }
  }

  void _startGPSListener() {
    Timer.periodic(const Duration(seconds: 1), (Timer timer) async {
      if (_run) {
        await _getCurrentLocation();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _PositionData positionData = _PositionData(position, DateTime.now());
      _currentPosition.add(positionData);
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  Future<String> _exportToJson() async {
    Map<String, dynamic> dataMap = {
      'TimeStamp': DateTime.now().millisecondsSinceEpoch,
      'Accelerometer': [],
      'UserAccelerometer': [],
      'Magnetometer': [],
      'Gyroscope': [],
      'GPS': [],
    };

    for (var data in _accelerometerEvents) {
      dataMap['Accelerometer'].add({
        'timestamp': data.timestamp.toIso8601String(),
        'event': {
          'x': data.accelerometerEvent.x.toStringAsFixed(1),
          'y': data.accelerometerEvent.y.toStringAsFixed(1),
          'z': data.accelerometerEvent.z.toStringAsFixed(1),
        },
      });
    }

    // Similar code for other sensor events

    String jsonData = jsonEncode(dataMap);
    return jsonData;
  }

  Future<void> _writeToFile(String data) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/sensor_data.json');
    await file.writeAsString(data);
  }

  void _restart() {
    _currentPosition = [];
    _accelerometerEvents = [];
    _userAccelerometerEvents = [];
    _magnetometerEvents = [];
    _gyroscopeEvents = [];
  }
}

class _UserAccelerometerData {
  final UserAccelerometerEvent userAccelerometerEvent;
  final DateTime timeStamp;

  _UserAccelerometerData(this.userAccelerometerEvent, this.timeStamp);
}

class _AccelerometerData {
  final AccelerometerEvent accelerometerEvent;
  final DateTime timestamp;

  _AccelerometerData(this.accelerometerEvent, this.timestamp);
}

class _GyroscopeData {
  final GyroscopeEvent gyroscopeEvent;
  final DateTime timestamp;

  _GyroscopeData(this.gyroscopeEvent, this.timestamp);
}

class _MagnetometerData {
  final MagnetometerEvent magnetometerEvent;
  final DateTime timestamp;

  _MagnetometerData(this.magnetometerEvent, this.timestamp);
}

class _PositionData {
  final Position position;
  final DateTime timestamp;

  _PositionData(this.position, this.timestamp);
}
