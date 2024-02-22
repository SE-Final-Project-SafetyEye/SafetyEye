import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'dart:io';

class CompressProvider extends ChangeNotifier {
  late String videoPath;
  String originalSize = '';
  String? originalPath;
  String compressedSize = '';
  String? compressedPath;

  Future<void> pickVideo() async {
    final pickedFile = await ImagePicker().getVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      videoPath = pickedFile.path ?? '';
      notifyListeners();
    } else {
      print('No video selected.');
    }
  }

  Future<void> compressAndSaveVideo() async {
    try {
      MediaInfo? mediaInfoOriginal = await compressVideo(videoPath);
      MediaInfo? mediaInfoCompress = await compressVideo(videoPath, quality: VideoQuality.LowQuality);

      File? compressedFile = mediaInfoCompress?.file;

      originalSize = formatFileSize(mediaInfoOriginal?.filesize ?? 0);
      originalPath = mediaInfoOriginal?.path;
      compressedSize = formatFileSize(mediaInfoCompress?.filesize ?? 0);
      compressedPath = compressedFile?.path;

      saveCompressedVideo(compressedFile);

      notifyListeners();
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
