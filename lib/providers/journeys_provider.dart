import 'dart:io';

import 'package:flutter/cupertino.dart';


import '../poc/uploadVideo/BackendService.dart';
import '../repositories/file_system_repo.dart';
import 'auth_provider.dart';

class JourneysProvider extends ChangeNotifier {
  List<FileSystemEntity> localVideoFolders = [];
  late AuthenticationProvider authenticationProvider;
  late FileSystemRepository fileSystemRepository;
  late BackendService backendService;
  List<String> backendVideoFolders = [];

  JourneysProvider({required this.authenticationProvider});

  Future<void> initializeJourneys() async {
    fileSystemRepository = FileSystemRepository(authProvider: authenticationProvider);
    backendService = BackendService(authenticationProvider.currentUser);
    localVideoFolders = await fileSystemRepository.getVideoList();
    backendVideoFolders = (await backendService.getJourneys()) as List<String>; //TODO: check if connection is good
  }
}
