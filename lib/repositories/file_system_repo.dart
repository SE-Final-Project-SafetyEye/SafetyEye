import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:safety_eye_app/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';

class FileSystemRepository {
  Directory? _saveDir;
  AuthenticationProvider authProvider;
  final Logger _logger = Logger();
  String userId = "";
  String latestFilePath = '';
  var uuid = const Uuid();

  FileSystemRepository({required this.authProvider}) {
    authProvider.currentUserStream.listen((user) {
      if (user != null) {
        userId = user.uid;
      } else {
        userId = '';
      }
    });
  }

  Future<void> startRecording() async {
    _saveDirUpdate();
  }

  Future<File> saveDataToFile(String jsonData, int chunkNumber) async {
    var uuidG = uuid.v4();
    Directory dir = Directory(latestFilePath);
    String journeyId = XFile(dir.parent.path).name;
    String filePath =
        '$latestFilePath/${journeyId}_chunknumber-${chunkNumber}_${uuidG}_metadata.json';
    _logger.i('save metaDate into json... path: $filePath');
    File file = File(filePath);
    await file.writeAsString(jsonData);
    return file;
  }

  Future<void> _saveDirUpdate() async {
    final dir = await getApplicationDocumentsDirectory();

    if (userId.isEmpty) {
      return Future.error(Exception());
    }

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

    try {
      await videoChunk.saveTo(videosDirectory.path);
      await File(videoChunk.path).delete();
    } catch (e) {
      _logger.e('Error saving or deleting file: $e');
    }

    return videosDirectory;
  }

  String _latestFilePath({required chunkNumber}) {
    latestFilePath = '${_saveDir?.path ?? ''}/$chunkNumber';
    final latestFilePath0 = Directory(latestFilePath);
    if (!latestFilePath0.existsSync()) {
      latestFilePath0.createSync();
    }
    String journeyId = XFile(latestFilePath0.parent.path).name;
    var uuidG = uuid.v4();
    return '$latestFilePath/${journeyId}_chunknumber-${chunkNumber}_$uuidG.mp4';
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
          Directory directory = Directory(fileSystemEntity.path);
          if (directory.listSync().isNotEmpty) {
            videoFolders.add(fileSystemEntity);
          } else {
            directory.delete(recursive: true);
          }
        }
      }
    } catch (e,st) {
      _logger.e("Error getting original video list: $e,\n $st");
    }
    return videoFolders;
  }

  Future<List<String>> getChunksList(String path) async {
    List<String> videoDirectories = [];
    try {
      final videosDirectory = Directory(path);

      await for (FileSystemEntity entity in videosDirectory.list(recursive: true)) {
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

  Future<File> downLoadChunk(List<int> chunkBytes, String journeyId, String chunkId) async {
    final dir = await getApplicationDocumentsDirectory();
    // spit name of chunk Id by _
    String chunkNumber_number = chunkId.split('_').first;
    //find the chunk file number
    String chunkNumber = chunkNumber_number.split('-').last;
    final chunkFolder = Directory('${dir.path}/videos/$userId/$journeyId/$chunkNumber');

    //ensure directory exists
    if (!await chunkFolder.exists()) {
      await chunkFolder.create(recursive: true);
    }

    //save the chunk file to the chunk folder
    final chunkFile = File('${chunkFolder.path}/$chunkId');
    _logger.i("saving chunk to ${chunkFile.path}");
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

  Future<void> deleteDirectoryFiles(String filePath) async {
    final file = File(filePath);
    final directory = file.parent;

    // Check if the directory exists
    if (await directory.exists()) {
      try {
        await directory.delete(recursive: true);
        _logger.i('Directory deleted successfully');
      } catch (e) {
        _logger.e('Error deleting directory: $e');
      }
    } else {
      _logger.e('Directory not found');
    }
  }

  String getName(String path) {
    return XFile(path).name;
  }

  Future<Uint8List> getUint8List(String path) async {
    XFile videoCo = XFile(path);
    Uint8List videoCoBytes = await videoCo.readAsBytes();
    return videoCoBytes;
  }

  Future<void> deleteDirectoryOfFile(String filePath) async {
    final file = File(filePath);
    final directory = file.parent;

    // Check if the directory exists
    if (await directory.exists()) {
      try {
        await directory.delete(recursive: true);
        _logger.i('Directory deleted successfully');
      } catch (e) {
        _logger.e('Error deleting directory: $e');
      }
    } else {
      _logger.e('Directory not found');
    }
  }
}
