import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/chunks_provider.dart';
import '../../../providers/ioc_provider.dart';
import '../videoPlayer/video_player.dart';

class ChunksPage extends StatefulWidget {
  final String path;
  final bool local;

  const ChunksPage({super.key, required this.path, required this.local});

  @override
  State<ChunksPage> createState() => _ChunksPageState();
}

class _ChunksPageState extends State<ChunksPage> {
  @override
  Widget build(BuildContext context) {
    final chunks = Provider.of<IocContainerProvider>(context, listen: false)
        .container
        .get<ChunksProvider>();

    if (widget.local) {
      String videoName = widget.path.split('/').last.split('.').first;
      return Scaffold(
        body: FutureBuilder(
          future: chunks.initChunks(widget.path),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.connectionState == ConnectionState.done) {
              return _buildLocalChunksListView(videoName, chunks);
            } else {
              return const Center(child: Text('Error loading chunks'));
            }
          },
        ),
      );
    } else {
      return Scaffold(
        body: FutureBuilder(
          future: chunks.getChunk(widget.path),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text('Error loading chunks'));
            } else {
              if (chunks.chunksPaths.isNotEmpty) {
                return _buildBackendChunksListView(chunks);
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            }
          },
        ),
      );
    }
  }

  Widget _buildLocalChunksListView(String videoName, ChunksProvider chunks) {
    return ListView(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                videoName,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: chunks.chunksPaths.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {},
                  child: Card(
                    margin: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: chunks.generateThumbnailIsNotEmpty(index)
                              ? Image.file(
                                  chunks.getThumbnail(index),
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
                                (index + 1).toString(),
                                style: const TextStyle(fontSize: 16.0),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.highlight),
                                  onPressed: () =>
                                      chunks.handleHighlightsButtonPress(index),
                                  tooltip: 'Add Highlights',
                                ),
                                const SizedBox(width: 8.0),
                                IconButton(
                                  icon: const Icon(Icons.cloud_upload),
                                  onPressed: () => chunks
                                      .handleCloudUploadButtonPress(index),
                                  tooltip: 'Upload to Cloud',
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            String videoPath =
                                chunks.handlePlayButtonPress(context, index);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ChewieVideoPlayer(
                                          srcs: [videoPath],
                                        )));
                          },
                          icon: const Icon(Icons.play_arrow),
                          tooltip: 'Play video',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBackendChunksListView(ChunksProvider chunks) {
    return ListView(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                widget.path,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: chunks.chunksPaths.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {},
                  child: Card(
                    margin: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const SizedBox(width: 8.0),
                                IconButton(
                                  icon: const Icon(Icons.cloud_download),
                                  onPressed: () =>
                                      chunks.download(widget.path, index),
                                  tooltip: 'Download from Cloud',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
