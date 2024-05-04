import 'dart:io';

import 'package:flutter/cupertino.dart';


import '../repositories/file_system_repo.dart';
import 'auth_provider.dart';

class JourneysProvider extends ChangeNotifier {
  List<FileSystemEntity> videoFolders = [];
  late AuthenticationProvider authenticationProvider;
  late FileSystemRepository _fileSystemRepository;

  JourneysProvider({required this.authenticationProvider});

  Future<void> initializeJourneys() async {
    _fileSystemRepository = FileSystemRepository(
        userEmail: authenticationProvider.currentUser?.uid ?? "nitayv");
    videoFolders = await _fileSystemRepository.getVideoList();
  }
}
