import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:safrt_eye_app/printColoredMessage.dart';


Directory? saveDir;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  List<CameraDescription> _cameras = await availableCameras();
  saveDir = await getApplicationDocumentsDirectory();
  runApp(MyApp(cameras: _cameras));
}

class MyApp extends StatelessWidget {
  List<CameraDescription> cameras;
  MyApp({super.key,required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Circular Video Recorder',
      theme: ThemeData(
          useMaterial3: true,
          colorScheme: const ColorScheme.light(
              primary: Colors.red, secondary: Colors.amber)),
      darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: const ColorScheme.dark(
              primary: Colors.redAccent, secondary: Colors.amberAccent)),
      home: CameraScreen(title: 'Circular Video Recorder',cameras: cameras,),
    );
  }
}

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
  ResolutionPreset resolutionPreset = ResolutionPreset.max;
  DateTime currentClipStart = DateTime.now();
  String? ip;
  bool saving = false;
  bool moving = false;
  Directory? exportDir;

  @override
  void initState() {
    super.initState();
    KeepScreenOn.turnOn();
    initCam();
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
                      recordRecursively();
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
      await Future.delayed(
          Duration(milliseconds: (recordMins * 60 * 1000).toInt()));
      if (cameraController.value.isRecordingVideo) {
        await stopRecording(true);
        recordRecursively();
      }
    }
  }

  String latestFilePath() {
    return '${saveDir?.path ?? ''}/CVR-${currentClipStart.millisecondsSinceEpoch.toString()}.mp4';
  }

  Future<void> stopRecording(bool cleanup) async {
    if (cameraController.value.isRecordingVideo) {
      XFile tempFile = await cameraController.stopVideoRecording();
      setState(() {});
      String lastFilePath = latestFilePath();
      final videosDirectory = Directory(lastFilePath);
      String dir = videosDirectory.path;
      printColoredMessage("dir: $dir");

      //String dir = videosDirectory.path;
      //printColoredMessage('videosDirectory: $dir',color: 'red');
      // Once clip is saved, deleting cached copy and cleaning up old clips can be done asynchronously
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
  @override
  void dispose() {
    cameraController.dispose();
    KeepScreenOn.turnOff();
    super.dispose();
  }

  Future<void> saveDirUpdate() async {
    final dir = await getApplicationDocumentsDirectory();
    final videosDirectory = Directory('${dir.path}/videos/${DateTime.now().microsecondsSinceEpoch}');
    if (!videosDirectory.existsSync()) {
      videosDirectory.createSync();
    }
    saveDir = videosDirectory;
  }
}