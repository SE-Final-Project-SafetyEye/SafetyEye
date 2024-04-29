import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

import '../../../providers/permissions_provider.dart';
import '../../../providers/video_recording_provider.dart';

class RecordingPage extends StatefulWidget {
  const RecordingPage({super.key});

  @override
  State<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage> {
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    KeepScreenOn.turnOn();
  }

  @override
  void dispose() {
    super.dispose();
    KeepScreenOn.turnOff();
  }

  @override
  Widget build(BuildContext context) {
    final cameraProvider =
        Provider.of<VideoRecordingProvider>(context, listen: false);

    return FutureBuilder(
        future: cameraProvider.initializeCamera(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (cameraProvider.isInitialized) {
              return Column(
                children: [
                  Expanded(
                    child: Center(
                      child: cameraProvider.isInitialized
                          ? CameraPreview(cameraProvider.cameraController)
                          : const Text('Could not Access Camera'),
                    ),
                  ),
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
                          label: Text(
                            cameraProvider.isRecording ? 'Stop' : 'Record',
                          ),
                          onPressed: () async {
                            if (cameraProvider.isRecording) {
                              _logger.i("Stopping recording...");
                              await cameraProvider.stopRecording();
                              _logger.i("Recording stopped.");
                            } else {
                              _logger.i("Starting recording...");
                              await cameraProvider.startRecording();
                              _logger.i("Recording started.");
                            }
                            //setState(() {});
                          },
                          icon: Icon(
                            cameraProvider.isRecording
                                ? Icons.stop
                                : Icons.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              return const Column(children: [
                CircularProgressIndicator(),
                Text("Camera not initialized")
              ]);
            }
          } else {
            return const Column(children: [
              CircularProgressIndicator(),
              Text("CameraProvider not initialized")
            ]);
          }
        });
  }
}
