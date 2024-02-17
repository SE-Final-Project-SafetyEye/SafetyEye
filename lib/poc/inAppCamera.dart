import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:safrt_eye_app/poc/InAppVideoListScreen.dart';
import 'package:video_player/video_player.dart';
import '../printColoredMessage.dart';

class InAppCameraScreen extends StatefulWidget {
  List<CameraDescription> cameras;
  InAppCameraScreen({super.key,required this.cameras});

  @override
  State<InAppCameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<InAppCameraScreen> with WidgetsBindingObserver {
  CameraController? controller;
  bool _isCameraInitialized = false;
  final resolutionPresets = ResolutionPreset.values;
  ResolutionPreset currentResolutionPreset = ResolutionPreset.high;
  bool _isVideoCameraSelected = false;
  bool _isRecordingInProgress = false;
  VideoPlayerController? videoController;
  File? _videoFile;
  File? _imageFile;
  List<File> allFileList = [];

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    //getPermissionStatus();
    WidgetsBinding.instance.addObserver(this);
    refreshAlreadyCapturedImages();
    //cameras = await availableCameras();
    onNewCameraSelected(widget.cameras.isNotEmpty ? widget.cameras[0] : null);
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
        title: const Text('Camera Screen'),
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
              hint: const Text(
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

  refreshAlreadyCapturedImages() async {
    // Get the directory
    final directory = await getApplicationDocumentsDirectory();
    final videosDirectory = Directory('${directory.path}/videos/ABC');
    List<FileSystemEntity> fileList = await videosDirectory.list().toList();
    allFileList.clear();

    List<Map<int, dynamic>> fileNames = [];

    // Searching for all the image and video files using
    // their default format, and storing them
    fileList.forEach((file) {
      if (file.path.contains('.jpg') || file.path.contains('.mp4')) {
        allFileList.add(File(file.path));

        String name = file.path.split('/').last.split('.').first;
        fileNames.add({0: int.parse(name), 1: file.path.split('/').last});
      }
    });

    // Retrieving the recent file
    if (fileNames.isNotEmpty) {
      final recentFile =
      fileNames.reduce((curr, next) => curr[0] > next[0] ? curr : next);
      String recentFileName = recentFile[1];
      // Checking whether it is an image or a video file
      if (recentFileName.contains('.mp4')) {
        _videoFile = File('${directory.path}/$recentFileName');
        _startVideoPlayer();
      } else {
        _imageFile = File('${directory.path}/$recentFileName');
      }

      setState(() {});
    }
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || !controller!.value.isInitialized) {
      return const Center(
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
    return InkWell(
      child: Container(
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
      ),
    onTap: (){ Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const InAppVideoListScreen(path:'',)), //TODO: pay Attention to this update
    );},);
  }

  Future<String> getPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final videosDirectory = Directory('${directory.path}/videos');
    return videosDirectory.path;
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
          final videosDirectory = Directory('${directory.path}/videos');
          if (!videosDirectory.existsSync()) {
            videosDirectory.createSync();
          }
          String videosDirectory_Path = videosDirectory.path;
          printColoredMessage('videosDirectory: $videosDirectory_Path', color: 'red');
          String fileFormat = videoFile.path.split('.').last;

          _videoFile = await videoFile.copy(
            '${videosDirectory.path}/$currentUnix.$fileFormat',
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

