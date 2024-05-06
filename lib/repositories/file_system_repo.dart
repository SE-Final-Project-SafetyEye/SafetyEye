import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:safety_eye_app/providers/auth_provider.dart';
import 'package:safety_eye_app/services/auth_service.dart';

class FileSystemRepository {
  Directory? _saveDir;
  AuthenticationProvider authProvider;
  final Logger _logger = Logger();
  late String userId;

  FileSystemRepository({ required this.authProvider}) {
    userId = authProvider.currentUser?.uid ?? '';
  }

  Future<void> startRecording() async {
    _saveDirUpdate();
  }

  Future<void> saveDataToFile(String jsonData) async {
    String filePath = '${_saveDir?.path}/JourneyMetadata.json';
    _logger.i('save metaDate into json... path: $filePath');
    File file = File(filePath);
    await file.writeAsString(jsonData);
  }

  Future<void> processVideoChunk(XFile videoChunk, String outputDir) async {
    FlutterFFmpeg ffmpeg = FlutterFFmpeg();

    int intervalInSeconds = 5;

    int rc = await ffmpeg.execute(
        '-i $outputDir -vf fps=1/$intervalInSeconds ${outputDir}frame-%03d.jpg');

    if (rc == 0) {
      _logger.i('Frames extracted successfully');
    } else {
      _logger.e('Error extracting frames: $rc');
    }
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

  Future<void> stopRecording(XFile videoChunk, int chunkNumber) async {
    String lastFilePath = _latestFilePath(chunkNumber: chunkNumber);
    _logger.i(lastFilePath);
    final videosDirectory = Directory(lastFilePath);
    videoChunk.saveTo(videosDirectory.path).then((_) {
      processVideoChunk(videoChunk, videosDirectory.path);
      File(videoChunk.path).delete();
    });
  }

  String _latestFilePath({required chunkNumber}) {
    final String latestFilePath = '${_saveDir?.path ?? ''}/$chunkNumber';
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
}
