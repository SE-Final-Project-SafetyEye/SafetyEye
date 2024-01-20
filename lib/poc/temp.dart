import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error in fetching the cameras: $e');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Camera Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: CameraScreen(),
    );
  }
}

List<CameraDescription> cameras = [];

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? controller;
  bool _isCameraInitialized = false;
  final resolutionPresets = ResolutionPreset.values;
  ResolutionPreset currentResolutionPreset = ResolutionPreset.high;
  bool _isVideoCameraSelected = false;
  bool _isRecordingInProgress = false;
  VideoPlayerController? videoController;
  File? _videoFile;
  File? _imageFile;

  @override
  void initState() {
    // Hide the status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

    WidgetsBinding.instance.addObserver(this);
    onNewCameraSelected(cameras.isNotEmpty ? cameras[0] : null);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    videoController?.dispose();
    super.dispose();
  }

  void onNewCameraSelected(CameraDescription? cameraDescription) async {
    if (controller != null) {
      await controller!.dispose();
    }

    controller = CameraController(
      cameraDescription!,
      currentResolutionPreset,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // Add a listener for camera updates
    controller!.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    try {
      await controller!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = controller!.value.isInitialized;
        });
      }
    } on CameraException catch (e) {
      print('Error initializing camera: $e');
    }
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (controller == null || !controller!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Free up memory when camera is not active
      controller!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Reinitialize the camera with the same properties
      onNewCameraSelected(controller!.description);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera Screen'),
        actions: [
          // Dropdown for resolution presets
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<ResolutionPreset>(
              dropdownColor: Colors.white, // Set background color
              underline: Container(),
              value: currentResolutionPreset,
              items: [
                for (ResolutionPreset preset in resolutionPresets)
                  DropdownMenuItem(
                    value: preset,
                    child: Text(
                      preset.toString().split('.')[1].toUpperCase(),
                      style: const TextStyle(color: Colors.black),
                    ),
                  )
              ],
              onChanged: (value) {
                setState(() {
                  currentResolutionPreset = value!;
                  _isCameraInitialized = false;
                });
                onNewCameraSelected(controller!.description);
              },
              hint: Text(
                "Select Resolution",
                style: TextStyle(color: Colors.black), // Set text color
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildCameraPreview(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 8.0,
                      right: 4.0,
                    ),
                    child: TextButton(
                      onPressed: _isRecordingInProgress
                          ? null
                          : () {
                        if (_isVideoCameraSelected) {
                          setState(() {
                            _isVideoCameraSelected = false;
                          });
                        }
                      },
                      style: TextButton.styleFrom(
                        primary: _isVideoCameraSelected
                            ? Colors.black54
                            : Colors.black,
                        backgroundColor: _isVideoCameraSelected
                            ? Colors.white30
                            : Colors.white,
                      ),
                      child: Text('IMAGE'),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4.0, right: 8.0),
                    child: TextButton(
                      onPressed: () {
                        if (!_isVideoCameraSelected) {
                          setState(() {
                            _isVideoCameraSelected = true;
                          });
                        }
                      },
                      style: TextButton.styleFrom(
                        primary: _isVideoCameraSelected
                            ? Colors.black
                            : Colors.black54,
                        backgroundColor: _isVideoCameraSelected
                            ? Colors.white
                            : Colors.white30,
                      ),
                      child: Text('VIDEO'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startVideoPlayer() async {
    if (_videoFile != null) {
      videoController = VideoPlayerController.file(_videoFile!);
      await videoController!.initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized,
        // even before the play button has been pressed.
        setState(() {});
      });
      await videoController!.setLooping(true);
      await videoController!.play();
    }
  }


  Future<void> startVideoRecording() async {
    final CameraController? cameraController = controller;
    if (controller!.value.isRecordingVideo) {
      // A recording has already started, do nothing.
      return;
    }
    try {
      await cameraController!.startVideoRecording();
      setState(() {
        _isRecordingInProgress = true;
        print(_isRecordingInProgress);
      });
    } on CameraException catch (e) {
      print('Error starting to record video: $e');
    }
  }

  Future<XFile?> stopVideoRecording() async {
    if (!controller!.value.isRecordingVideo) {
      // Recording is already is stopped state
      return null;
    }
    try {
      XFile file = await controller!.stopVideoRecording();
      setState(() {
        _isRecordingInProgress = false;
        print(_isRecordingInProgress);
      });
      return file;
    } on CameraException catch (e) {
      print('Error stopping video recording: $e');
      return null;
    }
  }

  Future<void> pauseVideoRecording() async {
    if (!controller!.value.isRecordingVideo) {
      // Video recording is not in progress
      return;
    }
    try {
      await controller!.pauseVideoRecording();
    } on CameraException catch (e) {
      print('Error pausing video recording: $e');
    }
  }

  Future<void> resumeVideoRecording() async {
    if (!controller!.value.isRecordingVideo) {
      // No video recording was in progress
      return;
    }
    try {
      await controller!.resumeVideoRecording();
    } on CameraException catch (e) {
      print('Error resuming video recording: $e');
    }
  }

  Future<XFile?> takePicture() async {
    final CameraController? cameraController = controller;
    if (cameraController!.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }
    try {
      XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      print('Error occured while taking picture: $e');
      return null;
    }
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || !controller!.value.isInitialized) {
      return Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: 1 / controller!.value.aspectRatio,
            child: controller!.buildPreview(),
          ),
          Positioned(
            bottom: 16.0, // Adjust the value as needed
            child: _buildCaptureButton(),
          ),
          Positioned(
              bottom: 16.0,
              right: 10.0,
              child: _lastCapturedPreview()),
        ],
      );
    }
  }
  Widget _lastCapturedPreview(){
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.white, width: 2),
        image: _imageFile != null
            ? DecorationImage(
          image: FileImage(_imageFile!),
          fit: BoxFit.cover,
        )
            : null,
      ),
      child: videoController != null && videoController!.value.isInitialized
          ? ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: AspectRatio(
          aspectRatio: videoController!.value.aspectRatio,
          child: VideoPlayer(videoController!),
        ),
      )
          : Container(),
    );
  }

  Widget _buildCaptureButton() {
    return  InkWell(
      onTap: _isVideoCameraSelected
          ? () async {
        if (_isRecordingInProgress) {
          XFile? rawVideo = await stopVideoRecording();
          File videoFile = File(rawVideo!.path);

          int currentUnix = DateTime.now().millisecondsSinceEpoch;

          final directory = await getApplicationDocumentsDirectory();
          String fileFormat = videoFile.path.split('.').last;

          _videoFile = await videoFile.copy(
            '${directory.path}/$currentUnix.$fileFormat',
          );

          _startVideoPlayer();
        } else {
          await startVideoRecording();
        }
      }
          : () async {
        // code to handle image clicking
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.circle,
            color: _isVideoCameraSelected
                ? Colors.white
                : Colors.white38,
            size: 80,
          ),
          Icon(
            Icons.circle,
            color: _isVideoCameraSelected
                ? Colors.red
                : Colors.white,
            size: 65,
          ),
          _isVideoCameraSelected &&
              _isRecordingInProgress
              ? const Icon(
            Icons.stop_rounded,
            color: Colors.white,
            size: 32,
          )
              : Container(),
        ],
      ),
    );
  }


}
