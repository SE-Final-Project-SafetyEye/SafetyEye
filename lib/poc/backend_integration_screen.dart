import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'package:safety_eye_app/poc/BackendService.dart';
import 'package:safety_eye_app/poc/payloads/request/requests.dart';

import 'AuthProvider.dart';

class BackendIntegrationScreen extends StatefulWidget {
  const BackendIntegrationScreen({super.key});

  @override
  State<BackendIntegrationScreen> createState() => _BackendIntegrationScreenState();
}

class _BackendIntegrationScreenState extends State<BackendIntegrationScreen> {
  late BackendService _backendService;
  String responseText = '';
  String journeyId = '';
  List<String> chunksNames = [];

  void updateResponseText(String text) {
    setState(() {
      responseText = text;
    });
  }

  void uploadChunk() async {
    String appDir = (await getApplicationDocumentsDirectory()).path;
    File video = File('$appDir/userId_JourneyTest_1_video.mp4');

    video.writeAsBytes(utf8.encode("123456789"));
    File pic1 = File('$appDir/userId_JourneyTest_1_picture1.jpg');
    pic1.writeAsBytes(utf8.encode("123456789"));
    File pic2 = File('$appDir/userId_JourneyTest_1_picture2.jpg');
    pic2.writeAsBytes(utf8.encode("123456789"));
    File pic3 = File('$appDir/userId_JourneyTest_1_picture3.jpg');
    pic3.writeAsBytes(utf8.encode("123456789"));

    File metadata = File('$appDir/userId_JourneyTest_1_metadata.json');
    Map<String, dynamic> metadataMap = {
      "video": "userId_JourneyTest_1_video.mp4",
      "picture1": "userId_JourneyTest_1_picture1.jpg",
      "picture2": "userId_JourneyTest_1_picture2.jpg",
      "picture3": "userId_JourneyTest_1_picture3.jpg",
      "metadata": "userId_JourneyTest_1_metadata.json"
    };
    metadata.writeAsString(json.encode(metadataMap));


    UploadChunkSignaturesRequest req = UploadChunkSignaturesRequest(
        videoSig: "123456789", picturesSig: ["12345", "12345", "12345"], metadataSig: "123456789", key: "123456789");
    try {
      await _backendService.uploadChunk(video, [pic1, pic2, pic3], metadata, req);
      updateResponseText('Uploaded');
    } catch (e) {
      updateResponseText('failed to upload files');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    _backendService = BackendService(authProvider.currentUser);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Integration'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () {
                  _backendService.getJourneys().then((response) {
                    journeyId = response.journeys[0];
                    updateResponseText(response.journeys.toString());
                  });
                },
                child: const Text('Get Journeys')),
            ElevatedButton(
                onPressed: () {
                  _backendService.getJourneyChunks(journeyId).then((response) {
                    chunksNames = response;
                    updateResponseText(response.toString());
                  }).catchError((error) {
                    updateResponseText(error.toString());
                  });
                },
                child: const Text("Journey's chunks")),
            ElevatedButton(
                onPressed: () {
                  _backendService.downloadChunk(journeyId, chunksNames[0]).then((response) {
                    updateResponseText("chunk was saved under ${response.path}");
                  });
                },
                child: const Text('Download Chunk')),
            ElevatedButton(onPressed: uploadChunk, child: const Text('Upload Chunk')),
            BackendResponseWidget(responseText: responseText),
          ],
        ),
      ),
    );
  }
}

class BackendResponseWidget extends StatelessWidget {
  const BackendResponseWidget({
    super.key,
    required this.responseText,
  });

  final String responseText;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text("Response:"),
        Text(responseText, maxLines: 10, softWrap: true),
      ],
    );
  }
}
