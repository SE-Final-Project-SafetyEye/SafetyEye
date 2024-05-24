import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safety_eye_app/providers/journeys_provider.dart';
import '../../../providers/ioc_provider.dart';
import '../chunks/chunks_content.dart';

class JourneysPage extends StatefulWidget {
  const JourneysPage({super.key});

  @override
  State<JourneysPage> createState() => _JourneysPageState();
}

class _JourneysPageState extends State<JourneysPage> {
  late List<String> selectedBackendJourneys;
  bool isSelectItem = false;

  @override
  void initState() {
    selectedBackendJourneys = [];
    super.initState();
  }

  @override
  void dispose() {
    selectedBackendJourneys = [];
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final journeys = Provider.of<IocContainerProvider>(context, listen: false)
        .container
        .get<JourneysProvider>();

    return FutureBuilder(
        future: journeys.initializeJourneys(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Scaffold(
              body: ListView(
                children: [
                  _buildLocalVideoList(journeys.localVideoFolders),
                  if (journeys.backendVideoFolders.isNotEmpty)
                    _buildBackEndVideoList(journeys.backendVideoFolders),
                ],
              ),
            );
          } else {
            return const CircularProgressIndicator();
          }
        });
  }
}

Widget _buildLocalVideoList(List<FileSystemEntity> paths) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text("Local Journeys"),
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: paths.length,
        itemBuilder: (context, index) {
          return LocalVideoCard(fileSystemEntity: paths[index]);
        },
      ),
    ],
  );
}

Widget _buildBackEndVideoList(List<String> journeys) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text("BackEnd Journeys"),
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: journeys.length,
        itemBuilder: (context, index) {
          return BackEndVideoCard(journeyName: journeys[index]);
        },
      ),
    ],
  );
}

class LocalVideoCard extends StatelessWidget {
  final FileSystemEntity fileSystemEntity;

  const LocalVideoCard({super.key, required this.fileSystemEntity});

  @override
  Widget build(BuildContext context) {
    String videoFolderName = fileSystemEntity.path.split('/').last;
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChunksPage(path: fileSystemEntity.path,local: true,),
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

class BackEndVideoCard extends StatelessWidget {
  final String journeyName;

   const BackEndVideoCard({super.key, required this.journeyName});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChunksPage(path: journeyName,local:false),
            ));
      },
      child: Card(
        child: Column(
          children: [
            ListTile(title: Text(journeyName)),
          ],
        ),
      ),
    );
  }
}
