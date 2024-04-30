import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/chunks_provider.dart';

class ChunksPage extends StatelessWidget {
  final String path;

  const ChunksPage({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    final chunks = Provider.of<ChunksProvider>(context, listen: false);
    String videoName = path.split('/').last.split('.').first;
    return FutureBuilder(
        future: chunks.initChunks(path),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (chunks.chunksPaths.isNotEmpty) {
              return ListView(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          videoName,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
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
                                    child: chunks
                                            .generateThumbnailIsNotEmpty(index)
                                        ? Image.file(
                                            chunks.getThumbnail(index),
                                            width: 100,
                                            height: 56.25,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 100,
                                            height: 56.25,
                                            color: Colors
                                                .grey, // Placeholder color
                                          ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          chunks.getName(index),
                                          style:
                                              const TextStyle(fontSize: 16.0),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.highlight),
                                            onPressed: () => chunks
                                                .handleHighlightsButtonPress(
                                                    index),
                                            tooltip: 'Add Highlights',
                                          ),
                                          const SizedBox(width: 8.0),
                                          IconButton(
                                            icon:
                                                const Icon(Icons.cloud_upload),
                                            onPressed: () => chunks
                                                .handleCloudUploadButtonPress(
                                                    index),
                                            tooltip: 'Upload to Cloud',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () =>
                                        chunks.handlePlayButtonPress(index),
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
            } else {
              return const CircularProgressIndicator();
            }
          } else {
            return const CircularProgressIndicator();
          }
        });
  }
}
