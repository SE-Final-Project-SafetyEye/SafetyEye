import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../printColoredMessage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';



Directory? saveDir;
var initMins = 0.25;

class CameraScreen extends StatefulWidget {
  late List<CameraDescription> cameras;
  CameraScreen({super.key, required this.title,required this.cameras});


  final String title;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController cameraController;
  double recordMins = initMins;
  int chunkNumber = 0;
  ResolutionPreset resolutionPreset = ResolutionPreset.max;
  DateTime currentClipStart = DateTime.now();
  String? ip;
  bool saving = false;
  bool moving = false;
  Directory? exportDir;
  late List<_PositionData> _currentPosition;
  late List<_AccelerometerData> accelerometerEvents;
  late List<_UserAccelerometerData> userAccelerometerEvents;
  late List<_MagnetometerData> magnetometerEvents;
  late List<_GyroscopeData> gyroscopeEvents;

  static const Duration _ignoreDuration = Duration(milliseconds: 20);

  UserAccelerometerEvent? _userAccelerometerEvent;
  AccelerometerEvent? _accelerometerEvent;
  GyroscopeEvent? _gyroscopeEvent;
  MagnetometerEvent? _magnetometerEvent;

  DateTime? _userAccelerometerUpdateTime;
  DateTime? _accelerometerUpdateTime;
  DateTime? _gyroscopeUpdateTime;
  DateTime? _magnetometerUpdateTime;

  int? _userAccelerometerLastInterval;
  int? _accelerometerLastInterval;
  int? _gyroscopeLastInterval;
  int? _magnetometerLastInterval;
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];

  Duration sensorInterval = SensorInterval.normalInterval;

  @override
  void initState() {
    super.initState();
    KeepScreenOn.turnOn();
    initCam();
    _getPermission();
    restart();
    _streamSubscriptions.add(
      userAccelerometerEventStream(samplingPeriod: sensorInterval).listen(
            (UserAccelerometerEvent event) {
          final now = DateTime.now();
          setState(() {
            //_userAccelerometerEvent = event;
            _UserAccelerometerData userAccelerometerData = _UserAccelerometerData(event, now);
            userAccelerometerEvents.add(userAccelerometerData); // Add event to the list
            if (_userAccelerometerUpdateTime != null) {
              final interval = now.difference(_userAccelerometerUpdateTime!);
              if (interval > _ignoreDuration) {
                _userAccelerometerLastInterval = interval.inMilliseconds;
              }
            }
          });
          _userAccelerometerUpdateTime = now;
        },
        onError: (e) {
          showDialog(
            context: context,
            builder: (context) {
              return const AlertDialog(
                title: Text("Sensor Not Found"),
                content: Text(
                    "It seems that your device doesn't support User Accelerometer Sensor"),
              );
            },
          );
        },
        cancelOnError: true,
      ),
    );
    _streamSubscriptions.add(
      accelerometerEventStream(samplingPeriod: sensorInterval).listen(
            (AccelerometerEvent event) {
          final now = DateTime.now();
          setState(() {
            //_accelerometerEvent = event;
            _AccelerometerData accelerometerData = _AccelerometerData(event, now);
            accelerometerEvents.add(accelerometerData); // Add event to the list
            if (_accelerometerUpdateTime != null) {
              final interval = now.difference(_accelerometerUpdateTime!);
              if (interval > _ignoreDuration) {
                _accelerometerLastInterval = interval.inMilliseconds;
              }
            }
          });
          _accelerometerUpdateTime = now;
        },
        onError: (e) {
          showDialog(
            context: context,
            builder: (context) {
              return const AlertDialog(
                title: Text("Sensor Not Found"),
                content: Text(
                    "It seems that your device doesn't support Accelerometer Sensor"),
              );
            },
          );
        },
        cancelOnError: true,
      ),
    );
    _streamSubscriptions.add(
      gyroscopeEventStream(samplingPeriod: sensorInterval).listen(
            (GyroscopeEvent event) {
          final now = DateTime.now();
          setState(() {
            //_gyroscopeEvent = event;
            _GyroscopeData gyroscopeData = _GyroscopeData(event, now);
            gyroscopeEvents.add(gyroscopeData); // Add event to the list
            if (_gyroscopeUpdateTime != null) {
              final interval = now.difference(_gyroscopeUpdateTime!);
              if (interval > _ignoreDuration) {
                _gyroscopeLastInterval = interval.inMilliseconds;
              }
            }
          });
          _gyroscopeUpdateTime = now;
        },
        onError: (e) {
          showDialog(
            context: context,
            builder: (context) {
              return const AlertDialog(
                title: Text("Sensor Not Found"),
                content: Text(
                    "It seems that your device doesn't support Gyroscope Sensor"),
              );
            },
          );
        },
        cancelOnError: true,
      ),
    );
    _streamSubscriptions.add(
      magnetometerEventStream(samplingPeriod: sensorInterval).listen(
            (MagnetometerEvent event) {
          final now = DateTime.now();
          setState(() {
            //_magnetometerEvent = event;
            _MagnetometerData magnetometerData  = _MagnetometerData(event, now);
            magnetometerEvents.add(magnetometerData); // Add event to the list
            if (_magnetometerUpdateTime != null) {
              final interval = now.difference(_magnetometerUpdateTime!);
              if (interval > _ignoreDuration) {
                _magnetometerLastInterval = interval.inMilliseconds;
              }
            }
          });
          _magnetometerUpdateTime = now;
        },
        onError: (e) {
          showDialog(
            context: context,
            builder: (context) {
              return const AlertDialog(
                title: Text("Sensor Not Found"),
                content: Text(
                    "It seems that your device doesn't support Magnetometer Sensor"),
              );
            },
          );
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

  Future<void> _getPermission() async {
    try {
      printColoredMessage("_getPermission",color: "red");
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('User denied location permission.');
        }
      }
    } catch (e) {
      print("Error: $e");
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

  Future<void> initCam() async {
    cameraController = CameraController(widget.cameras[0], resolutionPreset);
    try {
      saveDir = await getApplicationDocumentsDirectory();
      await cameraController.initialize();
      if (!mounted) {
        return;
      }
      setState(() {});
    } catch (e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            showInSnackBar('User denied camera access');
            break;
          default:
            showInSnackBar('Unknown error');
            break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(children: [
        Expanded(
          child: Center(
            child: cameraController.value.isInitialized
                ? CameraPreview(cameraController)
                : const Text('Could not Access Camera'),
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            child: cameraController.value.isRecordingVideo
                ? Text(
                'Current clip started at ${currentClipStart.hour <= 9 ? '0${currentClipStart.hour}' : currentClipStart.hour}:${currentClipStart.minute <= 9 ? '0${currentClipStart.minute}' : currentClipStart.minute}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ))
                : null,
          ),
        ]),
        const Padding(
          padding: EdgeInsets.fromLTRB(15, 15, 15, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(width: 15),
              SizedBox(width: 15),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(
                width: 15,
              ),
              ElevatedButton.icon(
                  label: Text(cameraController.value.isRecordingVideo
                      ? 'Stop'
                      : 'Record'),
                  onPressed: cameraController.value.isRecordingVideo
                      ? () => stopRecording(false)
                      : recordMins > 0
                      ? () {
                    if (saveDir == null) {
                      showDialog(
                          context: context,
                          builder: (BuildContext ctx) {
                            return const AlertDialog(
                                title: Text('Storage Error'),
                                content: Text(
                                    'Could not configure storage directory. This error is unrecoverable.'));
                          });
                    } else {
                      saveDirUpdate();
                      restart();
                      //_photos = [];
                      recordRecursively();
                      chunkNumber = 1;
                    }
                  }
                      : null,
                  icon: Icon(cameraController.value.isRecordingVideo
                      ? Icons.stop
                      : Icons.circle)),
            ],
          ),
        ),
        if (saving || moving)
          Container(
              decoration:
              BoxDecoration(color: Theme.of(context).colorScheme.primary),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                child: Row(children: [
                  Text(
                      '${saving && moving ? 'Saving & moving clips' : saving ? 'Saving last clip' : 'Moving clips'} - do not exit...',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white))
                ]),
              )),
        if (saving || moving) const LinearProgressIndicator(),
      ]),
    );
  }

  void restart() {
    _currentPosition = [];
    accelerometerEvents = [];
    userAccelerometerEvents = [];
    magnetometerEvents = [];
    gyroscopeEvents = [];
  }

  void showInSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String? getStatusText() {
    if (recordMins <= 0) {
      return null;
    }
    String status1 = cameraController.value.isRecordingVideo
        ? 'Now recording'
        : 'Set to record';
    return '$status1';
  }

  void recordRecursively() async {
    if (recordMins > 0) {
      await cameraController.startVideoRecording();
      setState(() {
        currentClipStart = DateTime.now();
      });

      Timer.periodic(const Duration(seconds: 1), (Timer timer) async {
        if (!cameraController.value.isRecordingVideo) {
          timer.cancel();
        } else {
          //printColoredMessage("_getCurrentLocation",color: "red");
          _getCurrentLocation();
        }
      });

      await Future.delayed(
          Duration(milliseconds: (recordMins * 60 * 1000).toInt()));
      if (cameraController.value.isRecordingVideo) {
        stopRecording(true);
      }
    }
  }

  String latestFilePath() {
    final String latestFilePath = '${saveDir?.path ?? ''}/$chunkNumber';
    final _latestFilePath = Directory(latestFilePath);
    if (!_latestFilePath.existsSync()) {
      _latestFilePath.createSync();
    }
    return '$latestFilePath/CVR-chunkNumber_$chunkNumber.mp4';
  }

  Future<void> stopRecording(bool recursive) async {
    if (cameraController.value.isRecordingVideo) {
      XFile tempFile = await cameraController.stopVideoRecording();
      setState(() {});
      String lastFilePath = latestFilePath();
      final videosDirectory = Directory(lastFilePath);
      chunkNumber++;
      String GPSFile = lastFilePath.substring(0,lastFilePath.length-4);
      saveDataToFile(GPSFile);
      setState(() {
        saving = true;
      });
      tempFile.saveTo(videosDirectory.path).then((_) {
        processVideoChunk(tempFile,videosDirectory.path);
        File(tempFile.path).delete();
        setState(() {
          saving = false;
        });
      });
      if(recursive){
        recordRecursively();
      }
    }
  }

  Future<void> processVideoChunk(XFile videoChunk,String outputDir) async {
    FlutterFFmpeg flutterFFmpeg = FlutterFFmpeg();

    int intervalInSeconds = 5;

    int rc = await flutterFFmpeg.execute(
        '-i $outputDir -vf fps=1/$intervalInSeconds ${outputDir}frame-%03d.jpg');

    if (rc == 0) {
      printColoredMessage('Frames extracted successfully',color: "red");
    } else {
      print('Error extracting frames: $rc');
    }
  }

  Future<void> saveDataToFile(String directory) async {
    // Continue with saving other data to the file
    try {
      String filePath = '${directory}_data.json';
      File file = File(filePath);

      // Create a map to hold all the data
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
      for (var data in accelerometerEvents) {
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
      for (var data in userAccelerometerEvents) {
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
      for (var data in magnetometerEvents) {
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
      for (var data in gyroscopeEvents) {
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


      // Convert the map to JSON string
      String jsonData = jsonEncode(dataMap);

      // Write the JSON string to the file
      await file.writeAsString(jsonData);
    } catch (e) {
      print('Error saving data: $e');
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    KeepScreenOn.turnOff();
    for (var subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  Future<void> saveDirUpdate() async {
    final dir = await getApplicationDocumentsDirectory();
    final videosDirectory = Directory('${dir.path}/videos');
    if (!videosDirectory.existsSync()) {
      videosDirectory.createSync(recursive: true);
    }

    final subdirectory = Directory('${videosDirectory.path}/${DateTime.now().millisecondsSinceEpoch}');
    if (!subdirectory.existsSync()) {
      subdirectory.createSync();
    }
    saveDir = subdirectory;
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