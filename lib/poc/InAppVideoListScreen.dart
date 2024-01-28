import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class InAppVideoListScreen extends StatefulWidget {
  @override
  _InAppVideoListScreenState createState() => _InAppVideoListScreenState();
}

class _InAppVideoListScreenState extends State<InAppVideoListScreen> {
  List<String> videoPaths = [];

  @override
  void initState() {
    super.initState();
    getVideoList();
  }

  Future<void> getVideoList() async {
    try {
      // Get the application documents directory
      Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();

      videoPaths = appDocumentsDirectory
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
      body: ListView.builder(
        itemCount: videoPaths.length,
        itemBuilder: (context, index) {
          return VideoCard(videoPath: videoPaths[index]);
        },
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
    _thumbnailPath = (await VideoThumbnail.thumbnailFile(
      video: widget.videoPath,
      thumbnailPath: (await getTemporaryDirectory()).path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 100,
      quality: 25,
    ))!;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    String videoName = widget.videoPath.split('/').last;
    videoName = videoName.split('.').first;
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
          // Handle video card tap
          // You can navigate to a detail screen or play the video, for example.
        },
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
                      onPressed: () {
                        // Handle Highlights button press
                      },
                    ),
                    const SizedBox(width: 8.0),
                    IconButton(
                      icon: const Icon(Icons.cloud_upload),
                      onPressed: () {
                        // Handle Upload to Cloud button press
                      },
                    ),
                  ],
                ),
              ],
            ),
            // Right side - Play button
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () {

              },
            ),
          ],
        ),
      ),
    );
  }
  @override
  void dispose() {
    super.dispose();
  }
  
}

