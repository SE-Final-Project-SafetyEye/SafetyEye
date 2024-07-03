import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safety_eye_app/providers/journeys_provider.dart';
import '../../../providers/chunks_provider.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../chunks/chunks_content.dart';

String formatJourneyName(String name) {
  int miles = int.parse(name);
  DateTime date = DateTime.fromMillisecondsSinceEpoch(miles);
  DateFormat formatter = DateFormat('dd-MM-yy HH:mm');
  String formattedDate = formatter.format(date);
  return formattedDate;
}

class Journey {
  final String name;
  final String path;
  final bool isLocal;

  Journey({required this.name, required this.path, required this.isLocal});
}

class JourneysPage extends StatefulWidget {
  final JourneysProvider journeysProvider;

  const JourneysPage(this.journeysProvider, {super.key});

  @override
  State<JourneysPage> createState() => _JourneysPageState();
}

class _JourneysPageState extends State<JourneysPage> {
  late Future<List<Journey>> journeysFuture;

  @override
  void initState() {
    super.initState();
    journeysFuture = _fetchJourneys();
  }

  Future<List<Journey>> _fetchJourneys() async {
    await widget.journeysProvider.getLocalJourneys();
    await widget.journeysProvider.getBackendJourneys();

    List<Journey> localJourneys = widget.journeysProvider.localVideoFolders
        .map((file) => Journey(name: file.path.split('/').last, path: file.path, isLocal: true))
        .toList();

    List<Journey> backendJourneys = widget.journeysProvider.backendVideoFolders
        .map((name) => Journey(name: name, path: "", isLocal: false))
        .toList();

    // Remove backend journeys that are already in local journeys
    Set<String> localJourneyNames = localJourneys.map((journey) => journey.name).toSet();
    backendJourneys = backendJourneys.where((journey) => !localJourneyNames.contains(journey.name)).toList();

    List<Journey> allJourneys = [...localJourneys, ...backendJourneys];

    allJourneys.sort((a, b) => int.parse(a.name).compareTo(int.parse(b.name)));

    return allJourneys;
  }

  Future<void> _refreshJourneys() async {
    setState(() {
      journeysFuture = _fetchJourneys();
    });
    await journeysFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshJourneys,
        child: FutureBuilder<List<Journey>>(
          future: journeysFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    return JourneyCard(journey: snapshot.data![index]);
                  },
                );
              } else {
                return const Center(child: Text("No Journeys found"));
              }
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}

class JourneyCard extends StatelessWidget {
  final Journey journey;

  const JourneyCard({super.key, required this.journey});

  @override
  Widget build(BuildContext context) {
    final chunksProvider = Provider.of<ChunksProvider>(context, listen: false);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChunksPage(
              path: journey.isLocal ? journey.path : journey.name,
              local: journey.isLocal,
              chunksProvider: chunksProvider,
            ),
          ),
        );
      },
      child: Card(
        child: Column(
          children: [
            ListTile(
              title: Text(formatJourneyName(journey.name)),
              trailing: journey.isLocal
                  ? null
                  : const Icon(Icons.cloud_done, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}
