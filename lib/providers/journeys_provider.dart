import 'dart:io';

import 'package:flutter/cupertino.dart';


import '../services/BackendService.dart';
import '../repositories/file_system_repo.dart';
import 'auth_provider.dart';

class JourneysProvider extends ChangeNotifier {
  List<FileSystemEntity> localVideoFolders = [];
  final AuthenticationProvider authenticationProvider;
  final FileSystemRepository fileSystemRepository;
  final BackendService backendService;
  List<String> backendVideoFolders = [];

  JourneysProvider({required this.authenticationProvider,required this.backendService,required this.fileSystemRepository});

  Future<void> initializeJourneys() async {
    localVideoFolders = await fileSystemRepository.getVideoList();
    final videoList = await backendService.getJourneys();
    backendVideoFolders = videoList.journeys;
  }

  Future<void> getLocalJourneys() async {
    localVideoFolders = await fileSystemRepository.getVideoList();
    notifyListeners();
  }

  Future<void> getBackendJourneys() async {
    backendVideoFolders = await backendService.getJourneys().then((response) => response.journeys);
    notifyListeners();
  }
}
