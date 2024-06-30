import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import '../../../providers/chunks_provider.dart';
import '../videoPlayer/video_player.dart';

class ChunksPage extends StatefulWidget {
  final String path;
  final bool local;
  final ChunksProvider chunksProvider;

  const ChunksPage({
    super.key,
    required this.path,
    required this.local,
    required this.chunksProvider,
  });

  @override
  State<ChunksPage> createState() => _ChunksPageState();
}

class _ChunksPageState extends State<ChunksPage> {
  late final ChunksProvider chunksProvider;
  late Future<void> future;
  Set<int> selectedChunks = {};

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
        appBar: AppBar(
          title: const Text('Chunks'),
          actions: [
            if (selectedChunks.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: _playSelectedChunks,
              ),
          ],
        ),
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
        appBar: AppBar(
          title: const Text('Chunks List'),
          actions: [
            if (selectedChunks.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: _playSelectedChunks,
              ),
          ],
        ),
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
    return ListView.builder(
      itemCount: chunks.chunksPaths.length,
      itemBuilder: (context, index) {
        return LocalChunkCard(
          videoId: videoName,
          chunks: chunks,
          chunkIndex: index,
          isSelected: selectedChunks.contains(index),
          onSelected: (bool isSelected) {
            setState(() {
              if (isSelected) {
                selectedChunks.add(index);
              } else {
                selectedChunks.remove(index);
              }
            });
          },
        );
      },
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

  void _playSelectedChunks() {
    final chunks = Provider.of<ChunksProvider>(context, listen: false);
    final selectedPaths =
        selectedChunks.map((index) => chunks.chunksPaths[index]).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChewieVideoPlayer(srcs: selectedPaths),
      ),
    );
  }
}

class LocalChunkCard extends StatefulWidget {
  final String videoId;
  final int chunkIndex;
  final ChunksProvider chunks;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const LocalChunkCard({
    super.key,
    required this.chunks,
    required this.chunkIndex,
    required this.videoId,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  State<LocalChunkCard> createState() => _LocalChunkCardState();
}

class _LocalChunkCardState extends State<LocalChunkCard> {
  bool isUpload = false;
  bool isHighLight = false;
  late String videoId;
  late int chunkIndex;
  late ChunksProvider chunks;
  late bool isSelected;
  late ValueChanged<bool> onSelected;

  @override
  void initState() {
    videoId = widget.videoId;
    chunkIndex = widget.chunkIndex;
    chunks = widget.chunks;
    isSelected = widget.isSelected;
    onSelected = widget.onSelected;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      color: isSelected ? Colors.blue.withOpacity(0.3) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: chunks.generateThumbnailIsNotEmpty(chunkIndex)
                ? Image.file(
                    chunks.getThumbnail(chunkIndex),
                    width: 100,
                    height: 56.25,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 100,
                    height: 56.25,
                    color: Colors.grey,
                  ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  (chunkIndex + 1).toString(),
                  style: const TextStyle(fontSize: 16.0),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: isHighLight
                        ? const Icon(Icons.brightness_high_sharp)
                        : const Icon(Icons.highlight),
                    onPressed: () async {
                      bool result =
                          await chunks.handleHighlightsButtonPress(chunkIndex);
                      setState(() {
                        isHighLight = result;
                      });
                    },
                    tooltip: 'Add Highlights',
                  ),
                  const SizedBox(width: 8.0),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.cloud_upload),
                        onPressed: isUpload
                            ? null
                            : () async {
                                setState(() {
                                  isUpload = true;
                                });
                                try {
                                  await chunks
                                      .handleCloudUploadButtonPress(chunkIndex);
                                  setState(() {
                                    isUpload = false;
                                  });
                                }
                                catch(e){
                                  setState(() {
                                    isUpload = false;
                                  });
                                  return showDialog<void>(
                                    context: context,
                                    barrierDismissible: false, // user must tap button!
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Chunk Already in the Cloud.'),
                                        content: const SingleChildScrollView(),
                                        actions: <Widget>[TextButton(
                                          child: const Text('Close'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        )],
                                      );
                                    },
                                  );
                                }
                              },
                        tooltip: 'Upload to Cloud',
                      ),
                      if (isUpload)
                        const CircularProgressIndicator(
                          strokeWidth: 2.0,
                        ),
                    ],
                  ),
                  const SizedBox(width: 8.0),
                  IconButton(
                    onPressed: () {
                      chunks.deleteChunk(chunkIndex);
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              onSelected(!isSelected);
            },
            icon: isSelected
                ? const Icon(Icons.check_box)
                : const Icon(Icons.check_box_outline_blank),
            tooltip: 'Select chunk',
          ),
          IconButton(
            onPressed: () {
              String videoPath =
                  chunks.handlePlayButtonPress(context, chunkIndex);
              _playVideo(context, videoPath);
            },
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Play video',
          ),
        ],
      ),
    );
  }

  void _playVideo(BuildContext context, String videoPath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChewieVideoPlayer(srcs: [videoPath]),
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
  late final ChunksProvider chunks;
  late final String videoId;
  late final int chunkIndex;

  @override
  void initState() {
    super.initState();
    chunks = widget.chunks;
    videoId = widget.videoId;
    chunkIndex = widget.chunkIndex;
  }

  @override
  Widget build(BuildContext context) {
    _logger.i("videoId: $videoId, chunkList: ${chunks.chunksPaths.toString()}");
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8.0),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: isDownLoad
                    ? const Icon(Icons.downloading)
                    : const Icon(Icons.cloud_download),
                onPressed: () async {
                  setState(() {
                    isDownLoad = true;
                  });
                  await onCloudIconPressed(context, videoId, chunkIndex);
                  setState(() {
                    isDownLoad = false;
                  });
                },
                tooltip: 'Download from Cloud',
              ),
              if (isDownLoad)
                const CircularProgressIndicator(
                  strokeWidth: 2.0,
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(chunks.chunksPaths[chunkIndex].split('_').first),
          ),
        ],
      ),
    );
  }

  Future<void> onCloudIconPressed(
      BuildContext context, String videoId, int chunkIndex) async {
    try {
      final file = await chunks.download(videoId, chunkIndex);
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
}

void _playVideo(BuildContext context, String videoPath) {
  Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ChewieVideoPlayer(
                srcs: [videoPath],
              )));
}
