import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class FileSystemRepository {
  Directory? _saveDir;
  String userEmail;
  final Logger _logger = Logger();

  FileSystemRepository({required this.userEmail});

  Future<void> startRecording() async {
    _saveDirUpdate();
  }

  Future<void> saveDataToFile(String directory, String jsonData) async {
    String filePath = '${directory}_data.json';
    File file = File(filePath);
    await file.writeAsString(jsonData);
    _logger.i('save metaDate into json.');
  }

  Future<void> processVideoChunk(XFile videoChunk, String outputDir) async {
    FlutterFFmpeg flutterFFmpeg = FlutterFFmpeg();

    int intervalInSeconds = 5;

    int rc = await flutterFFmpeg.execute(
        '-i $outputDir -vf fps=1/$intervalInSeconds ${outputDir}frame-%03d.jpg');

    if (rc == 0) {
      _logger.i('Frames extracted successfully');
    } else {
      _logger.e('Error extracting frames: $rc');
    }
  }

  Future<void> _saveDirUpdate() async {
    final dir = await getApplicationDocumentsDirectory();
    final videosDirectory = Directory('${dir.path}/videos/$userEmail');
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
      final videosDirectory = Directory('${dir.path}/videos/$userEmail');
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
