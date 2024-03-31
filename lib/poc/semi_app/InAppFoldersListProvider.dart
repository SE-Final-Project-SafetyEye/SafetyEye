import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

// Define a model class to hold your data
class VideoFolder {
  final String name;
  final String path;

  VideoFolder({required this.name, required this.path});
}

// Create a provider class that extends ChangeNotifier
class VideoFolderProvider extends ChangeNotifier {
  List<VideoFolder> videoFolders = [];

  void getVideoList() async {
    try {
      Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();
      final videosDirectory = Directory('${appDocumentsDirectory.path}/videos');
      List<FileSystemEntity> files = videosDirectory.listSync();
      for (FileSystemEntity file in files) {
        FileSystemEntity fileSystemEntity = file.absolute;
        FileStat fileStat = file.statSync();
        if (fileStat.type == FileSystemEntityType.directory) {
          videoFolders.add(VideoFolder(name: fileSystemEntity.path.split('/').last, path: fileSystemEntity.path));
        }
      }
      notifyListeners(); // Notify listeners after updating data
    } catch (e) {
      print("Error getting original video list: $e");
    }
  }
}
