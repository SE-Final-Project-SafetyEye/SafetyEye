import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safety_eye_app/providers/journeys_provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/chunks_provider.dart';
import '../../../providers/ioc_provider.dart';
import '../chunks/chunks_content.dart';

class JourneysPage extends StatelessWidget {
  const JourneysPage({super.key});

  @override
  Widget build(BuildContext context) {
    final journeys = Provider.of<IocContainerProvider>(context, listen: false).container.get<JourneysProvider>();

    return FutureBuilder(
        future: journeys.initializeJourneys(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Scaffold(body: ListView(
              children: [
                _buildVideoList(journeys.videoFolders, 'Video Folders'),
              ],
            ),);
          } else {
            return const CircularProgressIndicator();
          }
        });
  }
}

Widget _buildVideoList(List<FileSystemEntity> paths, String title) {
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
          return VideoCard(fileSystemEntity: paths[index]);
        },
      ),
    ],
  );
}

class VideoCard extends StatelessWidget {
  final FileSystemEntity fileSystemEntity;

  const VideoCard({super.key, required this.fileSystemEntity});

  @override
  Widget build(BuildContext context) {
    String videoFolderName = fileSystemEntity.path.split('/').last;
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ChunksPage(path: fileSystemEntity.path),
                    ));
      },
      child: Card(
        child: Column(
          children: [
            ListTile(title: Text(videoFolderName)),
          ],
        ),
      ),
    );
  }
}
