import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsProvider extends ChangeNotifier {
  late List<CameraDescription> _cameras;
  final Logger _logger = Logger();

  List<CameraDescription> get cameras => _cameras;

  Future<PermissionsProvider> init() async {
    try {
      _cameras = await availableCameras();
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _logger.w('User denied location permission.');
        }else{
          _logger.i('Location permission granted');
        }
      }
      var status = await Permission.microphone.request();
      if (status.isGranted) {
        _logger.i('microphone permission granted');
      } else {
        _logger.w('User denied microphone permission.');
      }
    } catch (error,stackTrace) {
      _logger.e(error.toString(), stackTrace: stackTrace);
    }
    return this;
  }
}