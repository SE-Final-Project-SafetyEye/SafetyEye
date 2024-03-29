import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_compress/video_compress.dart';

import 'VideoPlayer.dart';


class InAppVideoListScreen extends StatefulWidget {
  final String path;
  const InAppVideoListScreen({super.key, required this.path});

  @override
  _InAppVideoListScreenState createState() => _InAppVideoListScreenState();
}

class _InAppVideoListScreenState extends State<InAppVideoListScreen> {
  List<String> videoPaths = [];
  List<String> videoCompressPaths = [];

  @override
  void initState() {
    super.initState();
    getVideoList();
    getVideoCompressList();
  }

  Future<void> getVideoList() async {
    try {
      //Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();
      final videosDirectory = Directory(widget.path);
      videoPaths = videosDirectory
          .listSync()
          .where((entity) => entity.path.endsWith(".mp4"))
          .map((file) => file.path)
          .toList();
      setState(() {});
    } catch (e) {
      print("Error getting original video list: $e");
    }
  }

  Future<void> getVideoCompressList() async {
    try {
      Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();
      final videosDirectory = Directory('${appDocumentsDirectory.path}/compress_videos');
      videoCompressPaths = videosDirectory
          .listSync()
          .where((entity) => entity.path.endsWith(".mp4"))
          .map((file) => file.path)
          .toList();
      setState(() {});
    } catch (e) {
      print("Error getting compressed video list: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Videos List'),
      ),
      body: (videoPaths.isEmpty && videoCompressPaths.isEmpty)
          ? const Center(child: Text('No videos available'))
          : ListView(
        children: [
          if (videoPaths.isNotEmpty)
            _buildVideoList(videoPaths, 'Original Videos'),
          if (videoCompressPaths.isNotEmpty)
            _buildVideoList(videoCompressPaths, 'Compressed Videos'),
        ],
      ),
    );
  }

  Widget _buildVideoList(List<String> paths, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: paths.length,
          itemBuilder: (context, index) {
            return VideoCard(videoPath: paths[index]);
          },
        ),
      ],
    );
  }
}

class VideoCard extends StatefulWidget {
  final String videoPath;
  const VideoCard({Key? key, required this.videoPath}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  late String _thumbnailPath = '';

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    try {
      String? thumbnail = await VideoThumbnail.thumbnailFile(
        video: widget.videoPath,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 100,
        quality: 25,
      );
      setState(() {
        _thumbnailPath = thumbnail!;
      });
    } catch (e) {
      print('Error generating thumbnail: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String videoName = widget.videoPath.split('/').last.split('.').first;

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
          builder: (context) => VideoPlayerScreen(videoUrl: widget.videoPath),
        ),
      );
    }


    return GestureDetector(
      onTap: () {
      },
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: _thumbnailPath.isNotEmpty
                  ? Image.file(
                File(_thumbnailPath),
                width: 100,
                height: 56.25,
                fit: BoxFit.cover,
              )
                  : Container(
                width: 100,
                height: 56.25,
                color: Colors.grey, // Placeholder color
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
