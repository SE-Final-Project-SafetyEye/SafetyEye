import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:safrt_eye_app/printColoredMessage.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_compress/video_compress.dart';

import 'VideoPlayer.dart';

class InAppVideoListScreen extends StatefulWidget {
  @override
  _InAppVideoListScreenState createState() => _InAppVideoListScreenState();
}

class _InAppVideoListScreenState extends State<InAppVideoListScreen> {
  List<String> videoPaths = [];
  List<String> videoCompressPaths = []; //video_compress

  @override
  void initState() {
    super.initState();
    getVideoList();
    getVideoCompressList();
  }

  Future<void> getVideoList() async {
    try {
      // Get the application documents directory
      Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();

      final videosDirectory = Directory('${appDocumentsDirectory.path}/videos');
      String videosDirectory_Path = videosDirectory.path;
      printColoredMessage('videosDirectory: $videosDirectory_Path', color: 'red');
      videoPaths = videosDirectory
          .listSync()
          .where((entity) => entity.path.endsWith(".mp4"))
          .map((file) => file.path)
          .toList();
      setState(() {});
    } catch (e) {
      print("Error getting video list: $e");
    }
  }
  Future<void> getVideoCompressList() async {
    try {
      // Get the application documents directory
      Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();

      final videosDirectory = Directory('${appDocumentsDirectory.path}/compress_videos');
      String videosDirectory_Path = videosDirectory.path;
      printColoredMessage('videosDirectory: $videosDirectory_Path', color: 'red');
      videoCompressPaths = videosDirectory
          .listSync()
          .where((entity) => entity.path.endsWith(".mp4"))
          .map((file) => file.path)
          .toList();
      setState(() {});
    } catch (e) {
      print("Error getting video list: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Videos List'),
      ),
      body: videoPaths.isEmpty && videoCompressPaths.isEmpty
          ? const Center(child: Text('No videos available'))
          : Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (videoPaths.isNotEmpty)
            Container(
              padding: EdgeInsets.all(8.0),
              child: const Text(
                'Original Videos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          if (videoPaths.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: videoPaths.length,
                itemBuilder: (context, index) {
                  return VideoCard(videoPath: videoPaths[index]);
                },
              ),
            ),
          if (videoCompressPaths.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8.0),
              child: const Text(
                'Compressed Videos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          if (videoCompressPaths.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: videoCompressPaths.length,
                itemBuilder: (context, index) {
                  return VideoCard(videoPath: videoCompressPaths[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

}

class VideoCard extends StatefulWidget {
  final String videoPath;
  const VideoCard({super.key, required this.videoPath});
  @override
  State<StatefulWidget> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  late String _thumbnailPath;
  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    try {
      _thumbnailPath = (await VideoThumbnail.thumbnailFile(
        video: widget.videoPath,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 100,
        quality: 25,
      ))!;
      setState(() {});
    } catch (e) {
      print('Error generating thumbnail: $e');
      // Handle the error, or set a default value for _thumbnailPath
      _thumbnailPath = 'default_thumbnail_path';
    }
  }


  @override
  Widget build(BuildContext context) {
    String videoName = widget.videoPath.split('/').last;
    videoName = videoName.split('.').first;

    void handleVideoCardTap() {
      // Handle video card tap
      // You can navigate to a detail screen or play the video, for example.
    }

    void handleHighlightsButtonPress() {
      // Handle Highlights button press
    }

    void handleCloudUploadButtonPress() {
      showCompressionDialog(context);
    }

    void handlePlayButtonPress() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(galleryFile: widget.videoPath),
        ),
      );
    }

    return GestureDetector(
      onTap: handleVideoCardTap,
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side - Video and Name
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.file(
                File(_thumbnailPath),
                width: 100,
                height: 56.25, // 16:9 aspect ratio
                fit: BoxFit.cover,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    videoName,
                    style: const TextStyle(fontSize: 16.0),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.highlight),
                      onPressed: handleHighlightsButtonPress,
                      tooltip: 'Add Highlights',
                    ),
                    const SizedBox(width: 8.0),
                    IconButton(
                      icon: const Icon(Icons.cloud_upload),
                      onPressed: handleCloudUploadButtonPress,
                      tooltip: 'Upload to Cloud',
                    ),
                  ],
                ),
              ],
            ),
            // Right side - Play button
            const Spacer(),
            IconButton(
              onPressed: handlePlayButtonPress,
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Play video',
            ),
          ],
        ),
      ),
    );
  }
  Future<void> showCompressionDialog(BuildContext context) async {
    late String originalSize;
    late String compressedSize;
    late String? originalPath;
    late String? compressedPath;

    MediaInfo? mediaInfoOriginal = await VideoCompress.compressVideo(
      widget.videoPath,
      //quality: VideoQuality.LowQuality,
      deleteOrigin: false,
    );
    MediaInfo? mediaInfoCompress = await VideoCompress.compressVideo(
      widget.videoPath,
      quality: VideoQuality.LowQuality,
      deleteOrigin: false,
    );

    File? c = mediaInfoCompress?.file;
    Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();
    final compressDirectory = Directory('${appDocumentsDirectory.path}/compress_videos');

    if (!compressDirectory.existsSync()) {
      compressDirectory.createSync();
    }
    String compressName = widget.videoPath.split('/').last;
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


  @override
  void dispose() {
    super.dispose();
  }

}
