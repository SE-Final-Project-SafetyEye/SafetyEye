import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:safety_eye_app/providers/auth_provider.dart';

class FileSystemRepository {
  Directory? _saveDir;
  AuthenticationProvider authProvider;
  final Logger _logger = Logger();
  late String userId;
  String latestFilePath = '';

  FileSystemRepository({required this.authProvider}) {
    userId = authProvider.currentUser!.uid;
  }

  Future<void> startRecording() async {
    _saveDirUpdate();
  }

  Future<void> saveDataToFile(String jsonData) async {
    String filePath = '$latestFilePath/chunkMetadata.json';
    _logger.i('save metaDate into json... path: $filePath');
    File file = File(filePath);
    await file.writeAsString(jsonData);
  }

  Future<void> _saveDirUpdate() async {
    final dir = await getApplicationDocumentsDirectory();

    final videosDirectory = Directory('${dir.path}/videos/$userId');

    if (!videosDirectory.existsSync()) {
      videosDirectory.createSync(recursive: true);
    }

    final subdirectory = Directory(
        '${videosDirectory.path}/${DateTime.now().millisecondsSinceEpoch}');
    if (!subdirectory.existsSync()) {
      subdirectory.createSync();
    }
    _saveDir = subdirectory;
  }

  Future<Directory> stopRecording(XFile videoChunk, int chunkNumber) async {
    String lastFilePath = _latestFilePath(chunkNumber: chunkNumber);
    _logger.i(lastFilePath);
    final videosDirectory = Directory(lastFilePath);
    videoChunk.saveTo(videosDirectory.path).then((_) {
      File(videoChunk.path).delete();
    });
    return videosDirectory;
  }

  String _latestFilePath({required chunkNumber}) {
    latestFilePath = '${_saveDir?.path ?? ''}/$chunkNumber';
    _logger.i(latestFilePath);
    final latestFilePath0 = Directory(latestFilePath);
    if (!latestFilePath0.existsSync()) {
      latestFilePath0.createSync();
    }
    return '$latestFilePath/CVR-chunkNumber_$chunkNumber.mp4';
  }

  FutureOr<List<FileSystemEntity>> getVideoList() async {
    List<FileSystemEntity> videoFolders = [];
    try {
      final dir = await getApplicationDocumentsDirectory();
      final videosDirectory = Directory('${dir.path}/videos/$userId');
      _logger.i(videosDirectory.path);
      List<FileSystemEntity> files = videosDirectory.listSync();
      for (FileSystemEntity file in files) {
        FileSystemEntity fileSystemEntity = file.absolute;
        FileStat fileStat = file.statSync();
        if (fileStat.type == FileSystemEntityType.directory) {
          videoFolders.add(fileSystemEntity);
        }
      }
    } catch (e) {
      _logger.e("Error getting original video list: $e");
    }
    return videoFolders;
  }

  Future<List<String>> getChunksList(String path) async {
    List<String> videoDirectories = [];
    try {
      final videosDirectory = Directory(path);

      await for (FileSystemEntity entity
          in videosDirectory.list(recursive: true)) {
        if (entity is File && entity.path.endsWith(".mp4")) {
          String videoDirectory = entity.path;
          if (!videoDirectories.contains(videoDirectory)) {
            videoDirectories.add(videoDirectory);
          }
        }
      }
    } catch (e) {
      _logger.e("Error getting original video list: $e");
    }
    return videoDirectories;
  }

  getThumbnailFile(String thumbnail) {
    return File(thumbnail);
  }

  Future<File> downLoadChunk(
      List<int> chunkBytes, String journeyId, String chunkId) async {
    final dir = await getApplicationDocumentsDirectory();
    final videosDirectory = Directory('${dir.path}/videos/$userId');
    File chunkFile = File('${videosDirectory.path}/$journeyId/$chunkId');
    return await chunkFile.writeAsBytes(chunkBytes);
  }

  File getChunkVideo(String chunksPath) {
    return File(chunksPath);
  }

  List<File> getChunkPics(String chunksPath) {
    File file = File(chunksPath);
    String directoryPath = file.parent.path;
    Directory picsDir = Directory(directoryPath);
    List<File> pics = [];
    List<FileSystemEntity> files = picsDir.listSync();
    for (FileSystemEntity entity in files) {
      if (entity is File && entity.path.endsWith('.jpg')) {
        pics.add(entity);
      }
    }
    return pics;
  }

  File getChunkMetadata(String chunksPath) {
    File file = File(chunksPath);
    String directoryPath = file.parent.path;
    Directory metaDataDir = Directory(directoryPath);
    List<FileSystemEntity> files = metaDataDir.listSync();
    for (FileSystemEntity entity in files) {
      if (entity is File && entity.path.endsWith('.json')) {
        return entity;
      }
    }
    return File('');
  }
}
