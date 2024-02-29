import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

class AccelerometerScreen extends StatefulWidget {
  const AccelerometerScreen({Key? key}) : super(key: key);

  @override
  _AccelerometerScreenState createState() => _AccelerometerScreenState();
}

class _AccelerometerScreenState extends State<AccelerometerScreen> {
  static const Duration _ignoreDuration = Duration(milliseconds: 20);

  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS Example'),
        elevation: 4,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_currentPosition != null)
              Text(
                'Latitude: ${_currentPosition!.latitude}, Longitude: ${_currentPosition!.longitude}',
                style: TextStyle(fontSize: 18),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startLocationUpdates,
              child: Text('Start GPS Updates'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _stopLocationUpdates,
              child: Text('Stop GPS Updates'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _positionStreamSubscription?.cancel();
  }

  void _startLocationUpdates() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Handle the scenario where the user denies permission
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Permission Denied'),
              content: Text('Please enable location services to use this feature.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
          );
          return;
        }
      }

      _positionStreamSubscription = Geolocator.getPositionStream(
      ).listen((Position position) {
        setState(() {
          _currentPosition = position;
        });
      });
    } on PlatformException catch (e) {
      print('Platform Exception: $e');
      // Handle platform exceptions
    }
  }

  void _stopLocationUpdates() {
    _positionStreamSubscription?.cancel();
  }
}
