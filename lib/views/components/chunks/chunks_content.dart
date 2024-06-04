import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import '../../../providers/chunks_provider.dart';
import '../videoPlayer/video_player.dart';

class ChunksPage extends StatefulWidget {
  final String path;
  final bool local;
  final ChunksProvider chunksProvider;

  ChunksPage({super.key, required this.path, required this.local, required this.chunksProvider});

  @override
  State<ChunksPage> createState() => _ChunksPageState();
}

class _ChunksPageState extends State<ChunksPage> {
  final Logger _logger = Logger();
  late final ChunksProvider chunksProvider;

  late Future<void> future;
  @override
  void initState() {
    chunksProvider = widget.chunksProvider;
    if (widget.local) {
      future = chunksProvider.initChunks(widget.path);
    }
    else {
      future = chunksProvider.getChunks(widget.path);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final chunks = Provider.of<ChunksProvider>(context);
    String videoName = widget.path.split('/').last.split('.').first;
    if (widget.local) {

      return Scaffold(
        body: FutureBuilder(
          future: future,
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
          future: future,
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
                            _playVideo(videoPath);
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

  void _playVideo(String videoPath) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ChewieVideoPlayer(
                  srcs: [videoPath],
                )));
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
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 8.0),
                      IconButton(
                        icon: const Icon(Icons.cloud_download),
                        onPressed: () =>
                            chunks.download(widget.path, index),
                        tooltip: 'Download from Cloud',
                      ),
                      Text(chunks.chunksPaths[index].split("_").first),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  void onCloudIconPressed(BuildContext context, String journeyId, int chunkIndex) async {
    final chunks = Provider.of<ChunksProvider>(context);
      try {
        final file = await chunks.download(journeyId, chunkIndex);
        _logger.i("Finished downloading chunk");
        _playVideo(file.path);
      } catch (e) {
        _logger.e(e);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
        ));
      }
  }
}
