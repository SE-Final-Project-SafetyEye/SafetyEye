import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:real_volume/real_volume.dart';

class PermissionsProvider extends ChangeNotifier {
  late List<CameraDescription> _cameras;
  final Logger _logger = Logger();

  List<CameraDescription> get cameras => _cameras;

  Future<void> init() async {
    try {
      _cameras = await availableCameras();

      // every permission is listed in ./android/app/src/main/AndroidManifest.xml file
      await checkAndRequestGeolocationPermissions();
      await checkAndRequestCameraPermissions();
      await checkAndRequestVoicePermissions();

      // await checkAndRequestDoNotDisturbPermissions(); // may be required for real_volume plugin functionality


    } catch (error, stackTrace) {
      _logger.e(error.toString(), stackTrace: stackTrace);
    }
  }


  Future<bool> checkAndRequestDoNotDisturbPermissions() async {
    bool? isPermissionGranted = await RealVolume.isPermissionGranted();
    if (!isPermissionGranted!) {
      // Opens Do Not Disturb Access settings to grant the access
      await RealVolume.openDoNotDisturbSettings();
    }
    return true;
  }


  Future<bool> checkAndRequestGeolocationPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _logger.w('User denied location permission.');
        return false;
      } else {
        _logger.i('Location permission granted');
      }
    }
    return true;
  }

  Future<bool> checkAndRequestCameraPermissions() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      return true;
    } else {
      // You can request permission if it hasn't been permanently denied (restricted)
      final result = await Permission.camera.request();
      return result.isGranted;
    }
  }

  Future<bool> checkAndRequestVoicePermissions() async{
    var status = await Permission.microphone.request();
    if (status.isGranted) {
      _logger.i('microphone permission granted');
    } else {
      _logger.w('User denied microphone permission.');
    }
    return status.isGranted;
  }
}
