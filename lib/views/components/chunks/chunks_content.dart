import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import '../../../providers/chunks_provider.dart';
import '../videoPlayer/video_player.dart';

class ChunksPage extends StatefulWidget {
  final String path;
  final bool local;
  final ChunksProvider chunksProvider;

  const ChunksPage(
      {super.key,
      required this.path,
      required this.local,
      required this.chunksProvider});

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
    } else {
      future = chunksProvider.getChunks(widget.path);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final chunks = Provider.of<ChunksProvider>(context);
    if (widget.local) {
      String videoName = widget.path.split('/').last.split('.').first;
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
      String videoName = widget.path;
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
                return _buildBackendChunksListView(videoName, chunks);
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
                return LocalChunkCard(
                  videoId: videoName,
                  chunks: chunks,
                  chunkIndex: index,
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBackendChunksListView(String videoId, ChunksProvider chunks) {
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
                return BackEndChunkCard(
                  videoId: videoId,
                  chunkIndex: index,
                  chunks: chunks,
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class LocalChunkCard extends StatefulWidget {
  final String videoId;
  final int chunkIndex;
  final ChunksProvider chunks;

  const LocalChunkCard(
      {super.key,
      required this.chunks,
      required this.chunkIndex,
      required this.videoId});

  @override
  State<LocalChunkCard> createState() => _LocalChunkCardState();
}

class _LocalChunkCardState extends State<LocalChunkCard> {
  bool isUpLoad = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: widget.chunks.generateThumbnailIsNotEmpty(widget.chunkIndex)
                ? Image.file(
                    widget.chunks.getThumbnail(widget.chunkIndex),
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
                  (widget.chunkIndex + 1).toString(),
                  style: const TextStyle(fontSize: 16.0),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.highlight),
                    onPressed: () => widget.chunks
                        .handleHighlightsButtonPress(widget.chunkIndex),
                    tooltip: 'Add Highlights',
                  ),
                  const SizedBox(width: 8.0),
                  IconButton(
                    icon: isUpLoad
                        ? const Icon(Icons.cloud_upload_outlined)
                        : const Icon(Icons.cloud_upload),
                    onPressed: () async {
                      setState(() {
                        isUpLoad = true;
                      });
                      await widget.chunks
                          .handleCloudUploadButtonPress(widget.chunkIndex);
                      setState(() {
                        isUpLoad = false;
                      });
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
              String videoPath = widget.chunks
                  .handlePlayButtonPress(context, widget.chunkIndex);
              _playVideo(context, videoPath);
            },
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Play video',
          ),
        ],
      ),
    );
  }
}

class BackEndChunkCard extends StatefulWidget {
  final String videoId;
  final int chunkIndex;
  final ChunksProvider chunks;

  const BackEndChunkCard(
      {super.key,
      required this.videoId,
      required this.chunkIndex,
      required this.chunks});

  @override
  State<BackEndChunkCard> createState() => _BackEndChunkCardState();
}

class _BackEndChunkCardState extends State<BackEndChunkCard> {
  bool isDownLoad = false;
  final Logger _logger = Logger();

  @override
  Widget build(BuildContext context) {
    _logger.i(
        "videoId: ${widget.videoId}, chunkList: ${widget.chunks.chunksPaths.toString()}");
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8.0),
          IconButton(
            icon: isDownLoad
                ? const Icon(Icons.downloading)
                : const Icon(Icons.cloud_download),
            onPressed: () async {
              setState(() {
                isDownLoad = true;
              });

              // Ensure this part is asynchronous if onCloudIconPressed is a Future
              onCloudIconPressed(context, widget.videoId, widget.chunkIndex);

              setState(() {
                isDownLoad = false;
              });
            },
            tooltip: 'Download from Cloud',
          ),
          Text(widget.chunks.chunksPaths[widget.chunkIndex]),
        ],
      ),
    );
  }

  void onCloudIconPressed(
      BuildContext context, String journeyId, int chunkIndex) async {
    try {
      final file = await widget.chunks.download(journeyId, chunkIndex);
      _logger.i("Finished downloading chunk");
      if (context.mounted) {
        _playVideo(context, file.path);
      } else {
        _logger.i("Context not mounted");
      }
    } catch (e) {
      _logger.e(e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
        ));
      }
    }
  }

  void _progressCallback(int count, int total) {

    _logger.i("Progress is: $count/$total -- ${100 * (count / total)}%");
    if (context.mounted && count == total) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("$count/$total"),
        duration: const Duration(seconds: 1),
      ));
    }
  }
  }

void _playVideo(BuildContext context, String videoPath) {
  Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ChewieVideoPlayer(
                srcs: [videoPath],
              )));
}
