import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'semi_app/VideoPlayer.dart';

enum MediaType {
  photo,
  video,
}

class CameraDefaultAppAndGalleryAccessHomeScreen extends StatefulWidget {
  const CameraDefaultAppAndGalleryAccessHomeScreen({super.key});

  @override
  State<CameraDefaultAppAndGalleryAccessHomeScreen> createState() => _CameraHomeScreenState();
}

class _CameraHomeScreenState extends State<CameraDefaultAppAndGalleryAccessHomeScreen> {
  late MediaType mediaType;
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
                title: const Text('Video Library'),
                onTap: () async {
                  mediaType = MediaType.video;
                  //final directory = await getApplicationDocumentsDirectory();
                  _captureMedia(ImageSource.gallery, MediaType.video);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a photo'),
                onTap: () {
                  mediaType = MediaType.photo;
                  _captureMedia(ImageSource.camera, MediaType.photo);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Record a video'),
                onTap: () {
                  mediaType = MediaType.video;
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
