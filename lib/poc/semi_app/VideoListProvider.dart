import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoData {
  final String videoName;
  late final String videoPath;
  String thumbnailPath;

  VideoData({required this.videoName, required this.videoPath, required this.thumbnailPath});
}

class VideoListProvider extends ChangeNotifier {
  List<VideoData> videoList = [];

  Future<void> getVideoList(String path) async {
    try {
      final videosDirectory = Directory(path);
      List<String> videoDirectories = [];

      await for (FileSystemEntity entity in videosDirectory.list(recursive: true)) {
        if (entity is File && entity.path.endsWith(".mp4")) {
          String videoDirectory = entity.path;
          if (!videoDirectories.contains(videoDirectory)) {
            videoDirectories.add(videoDirectory);
          }
        }
      }

      List<VideoData> videos = videoDirectories.map((path) {
        return VideoData(
          videoName: path.split('/').last.split('.').first,
          videoPath: path,
          thumbnailPath: '',
        );
      }).toList();

      videoList = videos;
      for (var element in videoList) {generateThumbnail(element); }
      notifyListeners();
    } catch (e) {
      print("Error getting original video list: $e");
    }
  }

  Future<void> generateThumbnail(VideoData videoData) async {
    try {
      String? thumbnail = await VideoThumbnail.thumbnailFile(
        video: videoData.videoPath,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 100,
        quality: 25,
      );
        videoData.thumbnailPath = thumbnail ?? '';
        notifyListeners();
    } catch (e) {
      print('Error generating thumbnail: $e');
    }
  }

  Future<void> compressVideo(String videoPath) async {
    try {
      MediaInfo? mediaInfoOriginal = await VideoCompress.compressVideo(
        videoPath,
        deleteOrigin: false,
      );
      MediaInfo? mediaInfoCompress = await VideoCompress.compressVideo(
        videoPath,
        quality: VideoQuality.LowQuality,
        deleteOrigin: false,
      );
      var originalSize = _formatFileSize(mediaInfoOriginal?.filesize ?? 0);
      var originalPath = mediaInfoOriginal?.path;
      var compressedSize = _formatFileSize(mediaInfoCompress?.filesize ?? 0);
      var compressedPath = mediaInfoCompress?.path;

      // return showDialog(
      //   //context: context,
      //   builder: (BuildContext context) {
      //     return AlertDialog(
      //       title: Text('File Sizes'),
      //       content: Column(
      //         crossAxisAlignment: CrossAxisAlignment.start,
      //         mainAxisSize: MainAxisSize.min,
      //         children: [
      //           Text('Original Size: $originalSize'),
      //           Text('Original Path: $originalPath'),
      //           Text('Compressed Size: $compressedSize'),
      //           Text('Compressed Path: $compressedPath'),
      //         ],
      //       ),
      //       actions: [
      //         ElevatedButton(
      //           onPressed: () {
      //             Navigator.of(context).pop();
      //           },
      //           child: Text('OK'),
      //         ),
      //       ],
      //     );
      //   },
      // );

      notifyListeners();
    } catch (e) {
      print('Error compressing video: $e');
    }
  }

  String _formatFileSize(int fileSize) {
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
  Future<void> addHighlight(VideoData videoData) async {
    try {
      String data = videoData.videoPath.replaceAll('.mp4', '_data.json');
      var file = File(data);

      if (!file.existsSync()) {
        file.createSync(recursive: true);
        file.writeAsStringSync('{}');
      }

      var jsonData = json.decode(await file.readAsString()) as Map<String, dynamic>;

      if (jsonData.containsKey('Highlight') && !jsonData['Highlight']) {
        jsonData['Highlight'] = true;
        await file.writeAsString(json.encode(jsonData));
        print('Highlight added successfully for ${videoData.videoName}');
      } else {
        print('Video ${videoData.videoName} is already highlighted or JSON structure is incorrect');
      }
    } catch (e) {
      print('Error adding highlight for ${videoData.videoName}: $e');
    }
  }

}