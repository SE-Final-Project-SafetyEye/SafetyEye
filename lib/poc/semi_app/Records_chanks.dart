import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:sensors_plus/sensors_plus.dart';
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
  late List<Position> _currentPosition;
  late List<AccelerometerEvent> accelerometerEvents;
  late List<UserAccelerometerEvent> userAccelerometerEvents;
  late List<MagnetometerEvent> magnetometerEvents;
  late List<GyroscopeEvent> gyroscopeEvents;
  late List<File> _photos;

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
    _photos = [];
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

  // Future<List<FileSystemEntity>> getExistingClips() async {
  //   List<FileSystemEntity>? existingFiles = await saveDir?.list().toList();
  //   existingFiles?.removeWhere(
  //           (element) => element.uri.pathSegments.last == 'index.html');
  //   return existingFiles ?? [];
  // }

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
                      _photos = [];
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
          //printColoredMessage("_getCurrentLocation",color: "red");
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
    final String latestFilePath = '${saveDir?.path ?? ''}/$chunkNumber';
    final _latestFilePath = Directory(latestFilePath);
    if (!_latestFilePath.existsSync()) {
      _latestFilePath.createSync();
    }
    return '$latestFilePath/CVR-chunkNumber_$chunkNumber.mp4';
  }

  Future<void> stopRecording(bool cleanup) async {
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
        File(tempFile.path).delete();
        setState(() {
          saving = false;
        });
      });
        FlutterFFmpeg flutterFFmpeg = FlutterFFmpeg();

        // Specify the output directory where the frames will be saved
        String outputDir = videosDirectory.path;

        // Specify the time intervals at which frames will be extracted
        int intervalInSeconds = 5;

        // Run FFmpeg command to extract frames
        int rc = await flutterFFmpeg.execute(
            '-i ${videosDirectory.path} -vf fps=1/$intervalInSeconds ${outputDir}frame-%03d.jpg');

        if (rc == 0) {
          print('Frames extracted successfully');
        } else {
          print('Error extracting frames: $rc');
        }
    }
  }

  Future<void> saveDataToFile(String directory) async {
    // Save photos first
    try {
      for (int i = 0; i < _photos.length; i++) {
        final String filePath = '${directory}photo_$i.jpg';
        await _photos[i].copy(filePath);
      }

      // Clear the list after saving the photos.
      _photos.clear();
    } catch (e) {
      print('Error saving photos: $e');
    }

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
      accelerometerEvents.forEach((event) {
        dataMap['Accelerometer'].add({
          'x': event.x.toStringAsFixed(1),
          'y': event.y.toStringAsFixed(1),
          'z': event.z.toStringAsFixed(1),
        });
      });

      // Add user accelerometer events
      userAccelerometerEvents.forEach((event) {
        dataMap['UserAccelerometer'].add({
          'x': event.x.toStringAsFixed(1),
          'y': event.y.toStringAsFixed(1),
          'z': event.z.toStringAsFixed(1),
        });
      });

      // Add magnetometer events
      magnetometerEvents.forEach((event) {
        dataMap['Magnetometer'].add({
          'x': event.x.toStringAsFixed(1),
          'y': event.y.toStringAsFixed(1),
          'z': event.z.toStringAsFixed(1),
        });
      });

      // Add gyroscope events
      gyroscopeEvents.forEach((event) {
        dataMap['Gyroscope'].add({
          'x': event.x.toStringAsFixed(1),
          'y': event.y.toStringAsFixed(1),
          'z': event.z.toStringAsFixed(1),
        });
      });

      // Add GPS data
      _currentPosition.forEach((position) {
        dataMap['GPS'].add({
          'latitude': position.latitude,
          'longitude': position.longitude,
        });
      });

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