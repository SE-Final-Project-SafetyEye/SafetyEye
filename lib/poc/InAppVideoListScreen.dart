import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_compress/video_compress.dart';

import 'VideoPlayer.dart';


class InAppVideoListScreen extends StatefulWidget {
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
      Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();
      final videosDirectory = Directory('${appDocumentsDirectory.path}/videos');
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

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(galleryFile: widget.videoPath),
          ),
        );
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
                      onPressed: () {
                        // Handle Highlights button press
                      },
                      tooltip: 'Add Highlights',
                    ),
                    const SizedBox(width: 8.0),
                    IconButton(
                      icon: const Icon(Icons.cloud_upload),
                      onPressed: () {
                        // Handle Cloud Upload button press
                      },
                      tooltip: 'Upload to Cloud',
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              onPressed: () {
                // Handle Play button press
              },
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Play video',
            ),
          ],
        ),
      ),
    );
  }
}
