
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/video_recording_provider.dart';

class RecordingPage extends StatelessWidget {
  const RecordingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cameraProvider = Provider.of<VideoRecordingProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Video Recording')),
      body: cameraProvider.isInitialized
          ? Column(
        children: [
          Expanded(
            child: CameraPreview(cameraProvider.cameraController),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(cameraProvider.isRecording ? Icons.stop : Icons.circle),
                onPressed: cameraProvider.isRecording
                    ? cameraProvider.stopRecording
                    : cameraProvider.startRecording,
              ),
            ],
          ),
        ],
      )
          : const CircularProgressIndicator(),
    );
  }
}
