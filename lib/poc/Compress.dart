import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';
import 'dart:io';

class VideoCompressorWidget extends StatefulWidget {

  const VideoCompressorWidget({super.key});
  @override
  State<VideoCompressorWidget> createState() => _VideoCompressorWidgetState();
}

class _VideoCompressorWidgetState extends State<VideoCompressorWidget> {
  late String videoPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Compressor'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await pickVideo();
            await compressAndShowDialog();
          },
          child: Text('Select Video and Compress'),
        ),
      ),
    );
  }

  Future<void> pickVideo() async {
    final pickedFile = await ImagePicker().getVideo(source: ImageSource.gallery);
    setState(() {
      videoPath = pickedFile?.path ?? '';
    });
  }

  Future<void> compressAndShowDialog() async {
    late String originalSize;
    late String compressedSize;
    late String? originalPath;
    late String? compressedPath;

    MediaInfo? mediaInfoOriginal = await VideoCompress.compressVideo(
      videoPath,
      // quality: VideoQuality.LowQuality,
      deleteOrigin: false,
    );
    MediaInfo? mediaInfoCompress = await VideoCompress.compressVideo(
      videoPath,
      quality: VideoQuality.LowQuality,
      deleteOrigin: false,
    );

    File? c = mediaInfoCompress?.file;
    Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();
    final compressDirectory = Directory('${appDocumentsDirectory.path}/compress_videos');

    if (!compressDirectory.existsSync()) {
      compressDirectory.createSync();
    }
    String compressName = videoPath.split('/').last;
    compressName = compressName.split('.').first;
    await c?.copy('${compressDirectory.path}/$compressName.mp4');

    setState(() {
      originalSize = formatFileSize(mediaInfoOriginal?.filesize ?? 0);
      originalPath = mediaInfoOriginal?.path;
      compressedSize = formatFileSize(mediaInfoCompress?.filesize ?? 0);
      compressedPath = mediaInfoCompress?.path;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('File Sizes'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Original Size: $originalSize'),
              Text('Original Path: $originalPath'),
              Text('Compressed Size: $compressedSize'),
              Text('Compressed Path: $compressedPath'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String formatFileSize(int fileSize) {
    // Implement your logic for formatting file size (e.g., converting bytes to KB, MB, etc.).
    // For simplicity, this example returns the file size in bytes.
    return '$fileSize bytes';
  }
}

void main() {
  runApp(MaterialApp(
    home: VideoCompressorWidget(),
  ));
}
