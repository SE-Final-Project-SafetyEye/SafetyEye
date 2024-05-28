import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safety_eye_app/providers/journeys_provider.dart';
import '../../../providers/ioc_provider.dart';
import '../chunks/chunks_content.dart';

class JourneysPage extends StatefulWidget {
  JourneysProvider journeysProvider;

  JourneysPage(this.journeysProvider,{super.key});

  @override
  State<JourneysPage> createState() => _JourneysPageState();
}

class _JourneysPageState extends State<JourneysPage> {
  late List<String> selectedBackendJourneys;
  bool isSelectItem = false;
  late Future<void> localJourneysFuture = widget.journeysProvider.getLocalJourneys();
  late Future<void> backendJourneysFuture = widget.journeysProvider.getBackendJourneys();

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
    return Scaffold(
      body: ListView(
        children: [
          _buildLocalVideoList(context,localJourneysFuture),
          _buildBackEndVideoList(context, backendJourneysFuture),
        ],
      ),
    );
  }
}

Widget _buildLocalVideoList(BuildContext context,Future<void> localJourneysFuture) {
  final journeys = Provider.of<JourneysProvider>(context, listen: false);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text("Local Journeys"),
      FutureBuilder(
          future: localJourneysFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: journeys.localVideoFolders.length,
                itemBuilder: (context, index) {
                  return LocalVideoCard(fileSystemEntity: journeys.localVideoFolders[index]);
                },
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          })
    ],
  );
}

Widget _buildBackEndVideoList(BuildContext context, Future<void> backendJourneysFuture) {
  final journeys = Provider.of<JourneysProvider>(context, listen: false);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text("BackEnd Journeys"),
      FutureBuilder(
          future: backendJourneysFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (journeys.backendVideoFolders.isEmpty) {
                return const Center(child: Text("No Cloud Journeys found"));
              } else {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: journeys.backendVideoFolders.length,
                  itemBuilder: (context, index) {
                    return BackEndVideoCard(journeyName: journeys.backendVideoFolders[index]);
                  },
                );
              }
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          })
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
              builder: (context) => ChunksPage(
                path: fileSystemEntity.path,
                local: true,
              ),
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
              builder: (context) => ChunksPage(path: journeyName, local: false),
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
