import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'VideoListProvider.dart';
import 'VideoPlayer.dart';


class VideoListScreen extends StatelessWidget {
  final String path;

  const VideoListScreen({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Videos List'),
      ),
      body: Consumer<VideoListProvider>(
        builder: (context, provider, _) {
          if (provider.videoList.isEmpty) {
            provider.getVideoList(path);
            return const Center(child: CircularProgressIndicator());
          } else {
            return ListView.builder(
              itemCount: provider.videoList.length,
              itemBuilder: (context, index) {
                final videoData = provider.videoList[index];
                return VideoCard(videoData: videoData);
              },
            );
          }
        },
      ),
    );
  }
}

class VideoCard extends StatelessWidget {
  final VideoData videoData;

  const VideoCard({super.key, required this.videoData});

  @override
  Widget build(BuildContext context) {
    final videoListProvider = Provider.of<VideoListProvider>(context);
    return GestureDetector(
      onTap: () {
        // Handle video card tap
      },
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.file(
                  File(videoData.thumbnailPath),
                  width: 100,
                  height: 56.25,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      videoData.videoName,
                      style: const TextStyle(fontSize: 16.0),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.highlight),
                        onPressed: () {
                          Provider.of<VideoListProvider>(context, listen: false)
                              .addHighlight(videoData);
                        },
                        tooltip: 'Add Highlights',
                      ),
                      const SizedBox(width: 8.0),
                      IconButton(
                        icon: const Icon(Icons.cloud_upload),
                        onPressed: () async {
                          var videoProvider = Provider.of<VideoListProvider>(
                              context, listen: false);
                          try {
                            await videoProvider.compressVideo(videoData.videoPath);
                          } catch (e) {
                            if (kDebugMode) {
                              print('Error compressing video: $e');
                            }
                          }
                        },
                        tooltip: 'Upload to Cloud',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        VideoPlayerScreen(videoUrl: videoData.videoPath),
                  ),
                );
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
