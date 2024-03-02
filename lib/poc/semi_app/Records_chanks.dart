import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../printColoredMessage.dart';
import 'package:geolocator/geolocator.dart';



Directory? saveDir;
var initMins = 1;

class CameraScreen extends StatefulWidget {
  late List<CameraDescription> cameras;
  CameraScreen({super.key, required this.title,required this.cameras});


  final String title;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController cameraController;
  int recordMins = initMins;
  int chunkNumber = 0;
  ResolutionPreset resolutionPreset = ResolutionPreset.max;
  DateTime currentClipStart = DateTime.now();
  String? ip;
  bool saving = false;
  bool moving = false;
  Directory? exportDir;
  late List<Position> _currentPosition;
  late List<AccelerometerEvent> accelerometerEvents;
  late List<UserAccelerometerEvent> userAccelerometerEvents;
  late List<MagnetometerEvent> magnetometerEvents;
  late List<GyroscopeEvent> gyroscopeEvents;

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
    _currentPosition = [];
    accelerometerEvents = [];
    userAccelerometerEvents = [];
    magnetometerEvents = [];
    gyroscopeEvents = [];
    _streamSubscriptions.add(
      userAccelerometerEventStream(samplingPeriod: sensorInterval).listen(
            (UserAccelerometerEvent event) {
          final now = DateTime.now();
          setState(() {
            _userAccelerometerEvent = event;
            userAccelerometerEvents.add(event); // Add event to the list
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
            _accelerometerEvent = event;
            accelerometerEvents.add(event); // Add event to the list
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
            _gyroscopeEvent = event;
            gyroscopeEvents.add(event); // Add event to the list
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
            _magnetometerEvent = event;
            magnetometerEvents.add(event); // Add event to the list
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

  void _getPermission() async {
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
        _currentPosition.add(position);
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

  Future<List<FileSystemEntity>> getExistingClips() async {
    List<FileSystemEntity>? existingFiles = await saveDir?.list().toList();
    existingFiles?.removeWhere(
            (element) => element.uri.pathSegments.last == 'index.html');
    return existingFiles ?? [];
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
                      _currentPosition = [];
                      accelerometerEvents = [];
                      userAccelerometerEvents = [];
                      magnetometerEvents = [];
                      gyroscopeEvents = [];
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
          printColoredMessage("_getCurrentLocation",color: "red");
          _getCurrentLocation();
        }
      });
      await Future.delayed(
          Duration(milliseconds: (recordMins * 60 * 1000).toInt()));
      if (cameraController.value.isRecordingVideo) {
        await stopRecording(true);
        recordRecursively();
      }
    }
  }

  String latestFilePath() {
    return '${saveDir?.path ?? ''}/CVR-chunkNumber_$chunkNumber.mp4';
  }

  Future<void> stopRecording(bool cleanup) async {
    if (cameraController.value.isRecordingVideo) {
      XFile tempFile = await cameraController.stopVideoRecording();
      setState(() {});
      String lastFilePath = latestFilePath();
      chunkNumber++;
      String GPSFile = lastFilePath.split('/').last;
      GPSFile = GPSFile.substring(0,GPSFile.length-4);
      final videosDirectory = Directory(lastFilePath);
      saveDataToFile(GPSFile);
      setState(() {
        saving = true;
      });
      tempFile.saveTo(videosDirectory.path).then((_) {
        File(tempFile.path).delete();
        setState(() {
          saving = false;
        });
      });
    }
  }

  Future<void> saveDataToFile(String directory) async {
    String filePath = '${saveDir?.path}/${directory}_data.txt';
    File file = File(filePath);

    // Write timestamp at the top
    await file.writeAsString(
      'TimeStamp: ${DateTime.now().millisecondsSinceEpoch}\n\n',
    );

    // Create copies of the lists to avoid concurrent modification
    List<AccelerometerEvent> accelerometerEventsCopy = List.from(accelerometerEvents);
    List<UserAccelerometerEvent> userAccelerometerEventsCopy = List.from(userAccelerometerEvents);
    List<MagnetometerEvent> magnetometerEventsCopy = List.from(magnetometerEvents);
    List<GyroscopeEvent> gyroscopeEventsCopy = List.from(gyroscopeEvents);

    // Write accelerometer events
    for (var event in accelerometerEventsCopy) {
      await file.writeAsString(
        'Accelerometer: ${event.x.toStringAsFixed(1)}, ${event.y.toStringAsFixed(1)}, ${event.z.toStringAsFixed(1)}\n',
        mode: FileMode.append,
      );
    }

    // Write user accelerometer events
    for (var event in userAccelerometerEventsCopy) {
      await file.writeAsString(
        'User Accelerometer: ${event.x.toStringAsFixed(1)}, ${event.y.toStringAsFixed(1)}, ${event.z.toStringAsFixed(1)}\n',
        mode: FileMode.append,
      );
    }

    // Write magnetometer events
    for (var event in magnetometerEventsCopy) {
      await file.writeAsString(
        'Magnetometer: ${event.x.toStringAsFixed(1)}, ${event.y.toStringAsFixed(1)}, ${event.z.toStringAsFixed(1)}\n',
        mode: FileMode.append,
      );
    }

    // Write gyroscope events
    for (var event in gyroscopeEventsCopy) {
      await file.writeAsString(
        'Gyroscope: ${event.x.toStringAsFixed(1)}, ${event.y.toStringAsFixed(1)}, ${event.z.toStringAsFixed(1)}\n',
        mode: FileMode.append,
      );
    }

    // Write GPS data
    for (var position in _currentPosition) {
      await file.writeAsString(
        'GPS- Latitude: ${position.latitude}, Longitude: ${position.longitude}\n',
        mode: FileMode.append,
      );
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