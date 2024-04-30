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
  bool isRecording = false;

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
    final cameraProvider = Provider.of<VideoRecordingProvider>(context, listen: false);

    if (cameraProvider.isInitialized) {
      return buildCamaraPreviewContent(cameraProvider);
    } else {
      return FutureBuilder(
          future: cameraProvider.initializeCamera(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.connectionState == ConnectionState.done) {
              return buildCamaraPreviewContent(cameraProvider);
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          });
    }
  }

  Column buildCamaraPreviewContent(VideoRecordingProvider cameraProvider) {
    return Column(children: [
      Expanded(
        child: Center(child: CameraPreview(cameraProvider.cameraController!)),
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
                isRecording ? 'Stop' : 'Record',
              ),
              onPressed: () async {
                _logger.i(
                    "Recording button pressed. is recording: ${cameraProvider.isRecording}, isRecordingState: $isRecording");
                if (cameraProvider.isRecording) {
                  _logger.i("Stopping recording...");
                  await cameraProvider.stopRecording();
                  setIsRecording(false);
                  _logger.i("Recording stopped.");
                } else {
                  _logger.i("Starting recording...");
                  await cameraProvider.startRecording();
                  _logger.i("Recording started.");
                  setIsRecording(true);
                }
                _logger.i(
                    "Recording button pressed. is recording: ${cameraProvider.isRecording}, isRecordingState: $isRecording");
              },
              icon: Icon(
                isRecording ? Icons.stop : Icons.circle,
              ),
            ),
          ],
        ),
      )
    ]);
  }

  void setIsRecording(bool isRecording) {
    setState(() {
      this.isRecording = isRecording;
    });
  }
}
