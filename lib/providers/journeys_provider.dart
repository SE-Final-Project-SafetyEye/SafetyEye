import 'dart:io';

import 'package:flutter/cupertino.dart';


import '../repositories/file_system_repo.dart';
import 'auth_provider.dart';

class JourneysProvider extends ChangeNotifier {
  List<FileSystemEntity> videoFolders = [];
  late AuthenticationProvider authenticationProvider;
  late FileSystemRepository fileSystemRepository;

  JourneysProvider({required this.authenticationProvider});

  Future<void> initializeJourneys() async {
    fileSystemRepository = FileSystemRepository(authProvider: authenticationProvider);
    videoFolders = await fileSystemRepository.getVideoList();
  }
}
