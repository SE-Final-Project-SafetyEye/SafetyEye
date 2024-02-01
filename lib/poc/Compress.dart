import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
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
    if (pickedFile != null) {
      setState(() {
        videoPath = pickedFile.path ?? '';
      });
      await compressAndShowDialog();
    } else {
      // Handle case where the user canceled video selection
      print('No video selected.');
    }
  }


  Future<void> compressAndShowDialog() async {
    try {
      MediaInfo? mediaInfoOriginal = await compressVideo(videoPath);
      MediaInfo? mediaInfoCompress = await compressVideo(videoPath, quality: VideoQuality.LowQuality);

      File? compressedFile = mediaInfoCompress?.file;

      String originalSize = formatFileSize(mediaInfoOriginal?.filesize ?? 0);
      String? originalPath = mediaInfoOriginal?.path;
      String compressedSize = formatFileSize(mediaInfoCompress?.filesize ?? 0);
      String? compressedPath = compressedFile?.path;

      // Update state in a single call
      setState(() {
        originalSize = originalSize;
        originalPath = originalPath;
        compressedSize = compressedSize;
        compressedPath = compressedPath;
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
    } catch (e) {
      print('Error compressing or saving video: $e');
    }
  }


  Future<MediaInfo?> compressVideo(String videoPath, {VideoQuality quality = VideoQuality.DefaultQuality}) {
    return VideoCompress.compressVideo(
      videoPath,
      quality: quality,
      deleteOrigin: false,
    );
  }

  Future<void> saveCompressedVideo(File? compressedFile) async {
    if (compressedFile != null) {
      try {
        // Save the compressed video to the gallery
        await GallerySaver.saveVideo(compressedFile.path);
      } catch (e) {
        print('Error saving compressed video: $e');
        // Handle errors or show a message if necessary
      }
    }
  }




  String formatFileSize(int fileSize) {
    const int KB = 1024;
    const int MB = KB * KB;
    const int GB = MB * KB;

    if (fileSize >= GB) {
      return '${(fileSize / GB).toStringAsFixed(2)} GB';
    } else if (fileSize >= MB) {
      return '${(fileSize / MB).toStringAsFixed(2)} MB';
    } else if (fileSize >= KB) {
      return '${(fileSize / KB).toStringAsFixed(2)} KB';
    } else {
      return '$fileSize bytes';
    }
  }
}

void main() {
  runApp(MaterialApp(
    home: VideoCompressorWidget(),
  ));
}
