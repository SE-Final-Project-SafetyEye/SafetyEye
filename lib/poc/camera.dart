import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

enum MediaType {
  photo,
  video,
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primaryColor: Colors.green),
      home: const CameraHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CameraHomeScreen extends StatefulWidget {
  const CameraHomeScreen({super.key});

  @override
  State<CameraHomeScreen> createState() => _CameraHomeScreenState();
}

class _CameraHomeScreenState extends State<CameraHomeScreen> {
  File? galleryFile;
  final picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    //display image selected from gallery

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery and Camera Access'),
        backgroundColor: Colors.green,
        actions: const [],
      ),
      body: Builder(
        builder: (BuildContext context) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.green)),
                  child: const Text('Select Media from Gallery and Camera'),
                  onPressed: () {
                    _showPicker(context: context);
                  },
                ),
                const SizedBox(
                  height: 20,
                ),
                SizedBox(
                  height: 200.0,
                  width: 300.0,
                  child: galleryFile == null
                      ? const Center(child: Text('Sorry nothing selected!!'))
                      : Center(child: Image.file(galleryFile!)),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18.0),
                  child: Text(
                    "GFG",
                    textScaleFactor: 3,
                    style: TextStyle(color: Colors.green),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _captureMedia(ImageSource source, MediaType mediaType) async {
    final picker = ImagePicker();
    final pickedFile = mediaType == MediaType.video
        ? await picker.pickVideo(
      source: source,
      preferredCameraDevice: CameraDevice.front,
      maxDuration: const Duration(minutes: 10),
    )
        : await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        galleryFile = File(pickedFile.path);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing is selected')),
      );
    }
  }
  void _showPicker({
    required BuildContext context,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  _captureMedia(ImageSource.gallery, MediaType.photo);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  _captureMedia(ImageSource.camera, MediaType.photo);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Video'),
                onTap: () {
                  _captureMedia(ImageSource.camera, MediaType.video);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

}
