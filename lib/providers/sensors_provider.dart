
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorsProvider extends ChangeNotifier{
  late List<_PositionData> _currentPosition;
  late List<_AccelerometerData> _accelerometerEvents;
  late List<_UserAccelerometerData> _userAccelerometerEvents;
  late List<_MagnetometerData> _magnetometerEvents;
  late List<_GyroscopeData> _gyroscopeEvents;

  static const Duration _ignoreDuration = Duration(milliseconds: 20);
  
  bool _run = false;

  DateTime? _userAccelerometerUpdateTime;
  DateTime? _accelerometerUpdateTime;
  DateTime? _gyroscopeUpdateTime;
  DateTime? _magnetometerUpdateTime;
  DateTime? _currentPositionUpdateTime;

  int? _userAccelerometerLastInterval;
  int? _accelerometerLastInterval;
  int? _gyroscopeLastInterval;
  int? _magnetometerLastInterval;
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];

  Duration sensorInterval = SensorInterval.normalInterval;
  void _initState() {
    _streamSubscriptions.add(
      userAccelerometerEventStream(samplingPeriod: sensorInterval).listen(
            (UserAccelerometerEvent event) {
          final now = DateTime.now();
          _UserAccelerometerData userAccelerometerData = _UserAccelerometerData(event, now);
          _userAccelerometerEvents.add(userAccelerometerData); // Add event to the list
          if (_userAccelerometerUpdateTime != null) {
            final interval = now.difference(_userAccelerometerUpdateTime!);
            if (interval > _ignoreDuration) {
              _userAccelerometerLastInterval = interval.inMilliseconds;
            }
          }
          _userAccelerometerUpdateTime = now;
          //notifyListeners(); // Notify listeners of state change
        },
        onError: (e) {
        },
        cancelOnError: true,
      ),
    );
    _streamSubscriptions.add(
      accelerometerEventStream(samplingPeriod: sensorInterval).listen(
            (AccelerometerEvent event) {
          final now = DateTime.now();
            //_accelerometerEvent = event;
            _AccelerometerData accelerometerData = _AccelerometerData(event, now);
            _accelerometerEvents.add(accelerometerData); // Add event to the list
            if (_accelerometerUpdateTime != null) {
              final interval = now.difference(_accelerometerUpdateTime!);
              if (interval > _ignoreDuration) {
                _accelerometerLastInterval = interval.inMilliseconds;
              }
            }
          _accelerometerUpdateTime = now;
          //notifyListeners();
        },
        onError: (e) {
        },
        cancelOnError: true,
      ),
    );
    _streamSubscriptions.add(
      gyroscopeEventStream(samplingPeriod: sensorInterval).listen(
            (GyroscopeEvent event) {
          final now = DateTime.now();
            //_gyroscopeEvent = event;
            _GyroscopeData gyroscopeData = _GyroscopeData(event, now);
            _gyroscopeEvents.add(gyroscopeData); // Add event to the list
            if (_gyroscopeUpdateTime != null) {
              final interval = now.difference(_gyroscopeUpdateTime!);
              if (interval > _ignoreDuration) {
                _gyroscopeLastInterval = interval.inMilliseconds;
              }
            }
          _gyroscopeUpdateTime = now;
        },
        onError: (e) {
        },
        cancelOnError: true,
      ),
    );
    _streamSubscriptions.add(
      magnetometerEventStream(samplingPeriod: sensorInterval).listen(
            (MagnetometerEvent event) {
          final now = DateTime.now();
            //_magnetometerEvent = event;
            _MagnetometerData magnetometerData  = _MagnetometerData(event, now);
            _magnetometerEvents.add(magnetometerData); // Add event to the list
            if (_magnetometerUpdateTime != null) {
              final interval = now.difference(_magnetometerUpdateTime!);
              if (interval > _ignoreDuration) {
                _magnetometerLastInterval = interval.inMilliseconds;
              }
            }
          _magnetometerUpdateTime = now;
        },
        onError: (e) {
        },
        cancelOnError: true,
      ),
    );
    userAccelerometerEventStream(
        samplingPeriod: sensorInterval);
    accelerometerEventStream(samplingPeriod: sensorInterval);
    gyroscopeEventStream(samplingPeriod: sensorInterval);
    magnetometerEventStream(samplingPeriod: sensorInterval);
  }
  
  void _dispose() {
    for (var subscription in _streamSubscriptions) {
      subscription.cancel();
    }
  }
  
  void _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _PositionData positionData = _PositionData(position, DateTime.now());
      _currentPosition.add(positionData);
    } catch (e) {
      print("Error: $e");
    }
  }
  
  Future<void> startCollectMetadata() async {
    _restart();
    _initState();
    _run =true;
    Timer.periodic(const Duration(seconds: 1), (Timer timer) async {
      if(_run) {
        _getCurrentLocation();
      }
      else{timer.cancel();}
    });
  }
  
  Future<void> stopCollectMetadata() async{
    Map<String, dynamic> dataMap = {
      'TimeStamp': DateTime.now().millisecondsSinceEpoch,
      'Highlight': false,
      'Accelerometer': [],
      'UserAccelerometer': [],
      'Magnetometer': [],
      'Gyroscope': [],
      'GPS': [],
    };

    // Add accelerometer events
    for (var data in _accelerometerEvents) {
      dataMap['Accelerometer'].add({
        'timestamp': data.timestamp.toIso8601String(), // Actual timestamp
        'event': {
          'x': data.accelerometerEvent.x.toStringAsFixed(1),
          'y': data.accelerometerEvent.y.toStringAsFixed(1),
          'z': data.accelerometerEvent.z.toStringAsFixed(1),
        },
      });
    }


    // Add user accelerometer events
    for (var data in _userAccelerometerEvents) {
      dataMap['UserAccelerometer'].add({
        'timestamp': data.timeStamp.toIso8601String(), // Actual timestamp
        'event': {
          'x': data.userAccelerometerEvent.x.toStringAsFixed(1),
          'y': data.userAccelerometerEvent.y.toStringAsFixed(1),
          'z': data.userAccelerometerEvent.z.toStringAsFixed(1),
        },
      });
    }


    // Add magnetometer events
    for (var data in _magnetometerEvents) {
      dataMap['Magnetometer'].add({
        'timestamp': data.timestamp.toIso8601String(), // Actual timestamp
        'event': {
          'x': data.magnetometerEvent.x.toStringAsFixed(1),
          'y': data.magnetometerEvent.y.toStringAsFixed(1),
          'z': data.magnetometerEvent.z.toStringAsFixed(1),
        },
      });
    }

    // Add gyroscope events
    for (var data in _gyroscopeEvents) {
      dataMap['Gyroscope'].add({
        'timestamp': data.timestamp.toIso8601String(), // Actual timestamp
        'event': {
          'x': data.gyroscopeEvent.x.toStringAsFixed(1),
          'y': data.gyroscopeEvent.y.toStringAsFixed(1),
          'z': data.gyroscopeEvent.z.toStringAsFixed(1),
        },
      });
    }


    // Add GPS data
    for (var data in _currentPosition) {
      dataMap['GPS'].add({
        'timestamp': data.timestamp.toIso8601String(), // Actual timestamp
        'latitude': data.position.latitude,
        'longitude': data.position.longitude,
      });
    }
    _run = false;
    String jsonData = jsonEncode(dataMap);
    _dispose();
    _restart();
  }

  void _restart() {
    _currentPosition = [];
    _accelerometerEvents = [];
    _userAccelerometerEvents = [];
    _magnetometerEvents = [];
    _gyroscopeEvents = [];
  }
}


class _UserAccelerometerData{
  final UserAccelerometerEvent userAccelerometerEvent;
  final DateTime timeStamp;

  _UserAccelerometerData(this.userAccelerometerEvent,this.timeStamp);
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