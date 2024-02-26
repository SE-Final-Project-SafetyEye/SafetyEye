import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:safety_eye_app/poc/payloads/request/requests.dart';

import '../AuthProvider.dart';
import 'BackendService.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? pickedVideo;
  List<XFile>? pickedImages;
  File? toUploadVideoFile;
  List<File> toUploadImagesFiles = [];
  late AuthProvider authProvider;
  bool isUploading = false;
  double progress = 0.0;

  @override
  Widget build(BuildContext context) {
    authProvider = Provider.of<AuthProvider>(context);
    String userId = authProvider.user?.uid ?? 'noUser';

    return Scaffold(
        appBar: AppBar(
          title: const Text('Upload'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (pickedVideo != null)
                Text("selected video: ${pickedVideo!.name}")
              else
                const Text("No Video Selected"),
              ElevatedButton(
                onPressed: () async {
                  final applicationDocumentsDirectory = await getApplicationDocumentsDirectory();
                  final selectedVideo = await _picker.pickVideo(source: ImageSource.gallery);
                  if (selectedVideo != null) {
                    setState(() {
                      pickedVideo = selectedVideo;
                    });
                    File selectedVideoFile = File(selectedVideo.path);
                    File newFile =
                        File("${applicationDocumentsDirectory.path}/${userId}_testJourney42_testChunk_video.mp4");
                    toUploadVideoFile = await selectedVideoFile.copy(newFile.path);
                  }
                },
                child: const Text('Pick Video'),
              ),
              if (pickedImages != null)
                Text("selected images: ${pickedImages!.length}")
              else
                const Text("No Images Selected"),
              ElevatedButton(
                  onPressed: () async {
                    final applicationDocumentsDirectory = await getApplicationDocumentsDirectory();
                    final multiPicker = await _picker.pickMultiImage();

                    if (multiPicker.isNotEmpty) {
                      setState(() {
                        pickedImages = multiPicker;
                      });
                      List<File> newFiles = [];
                      for (int i = 0; i < multiPicker.length; i++) {
                        File selectedImageFile = File(multiPicker[i].path);
                        File newFile =
                            File("${applicationDocumentsDirectory.path}/${userId}_testJourney42_testChunk_image$i.jpg");
                        newFiles.add(await selectedImageFile.copy(newFile.path));
                      }
                      toUploadImagesFiles = newFiles;
                    }
                  },
                  child: const Text('Pick Images')),
              ElevatedButton(
                onPressed: toUploadVideoFile != null && toUploadImagesFiles.isNotEmpty ? onUploadPressed : null,
                child: const Text("upload files"),
              ),
              if (isUploading) LinearProgressIndicator(value: progress),
            ],
          ),
        ));
  }

  void onUploadPressed() async {
    final backendService = BackendService(authProvider.currentUser);
    String appDir = (await getApplicationDocumentsDirectory()).path;
    File metadata = File('$appDir/${authProvider.user?.uid ?? "userTest"}_JourneyTest42_testChunk_metadata.json');
    Map<String, dynamic> metadataMap = {"video": "video meta data", "images": "images mata data"};
    await metadata.writeAsString(json.encoder.convert(metadataMap));

    List<String> picturesSignatures = [];
    for (int i = 0; i < toUploadImagesFiles.length; i++) {
      picturesSignatures.add("picture signature $i");
    }

    UploadChunkSignaturesRequest signaturesRequest = UploadChunkSignaturesRequest(
        videoSig: "sigtest1", picturesSig: picturesSignatures, metadataSig: "sigtest4", key: "dummykey");

    try {
      setState(() {
        isUploading = true;
      });
      await backendService.uploadChunk(toUploadVideoFile!, toUploadImagesFiles, metadata, signaturesRequest, updateUploadProgress );
      setState(() {
        isUploading = false;
        progress = 0.0;
        toUploadVideoFile = null;
        toUploadImagesFiles = [];
        print("uploaded");
      });
    } catch (e) {
      print(e);
    }
  }

  updateUploadProgress(int progress, int total) {
    setState(() {
      this.progress = progress / total;
      print(this.progress);
    });

  }
}
