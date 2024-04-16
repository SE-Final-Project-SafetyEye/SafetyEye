

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:path_provider/path_provider.dart';

class FileSystemRepository{
  Directory? _saveDir;
  String userEmail;

  FileSystemRepository({ required this.userEmail});

  Future<void> startRecording() async {
    _saveDirUpdate();
  }

  Future<void> saveDataToFile(String directory,String jsonData) async {
    String filePath = '${directory}_data.json';
    File file = File(filePath);
    await file.writeAsString(jsonData);
  }

  Future<void> processVideoChunk(XFile videoChunk,String outputDir) async {
    FlutterFFmpeg flutterFFmpeg = FlutterFFmpeg();

    int intervalInSeconds = 5;

    int rc = await flutterFFmpeg.execute(
        '-i $outputDir -vf fps=1/$intervalInSeconds ${outputDir}frame-%03d.jpg');

    if (rc == 0) {
      //printColoredMessage('Frames extracted successfully',color: "red");
    } else {
      print('Error extracting frames: $rc');
    }
  }

  Future<void> _saveDirUpdate() async {
    final dir = await getApplicationDocumentsDirectory();
    final videosDirectory = Directory('${dir.path}/$userEmail');
    if (!videosDirectory.existsSync()) {
      videosDirectory.createSync(recursive: true);
    }

    final subdirectory = Directory('${videosDirectory.path}/${DateTime.now().millisecondsSinceEpoch}');
    if (!subdirectory.existsSync()) {
      subdirectory.createSync();
    }
    _saveDir = subdirectory;
  }

  Future<void> stopRecording(XFile videoChunk,int chunkNumber) async{
    String lastFilePath = _latestFilePath(chunkNumber: chunkNumber);
    final videosDirectory = Directory(lastFilePath);
    videoChunk.saveTo(videosDirectory.path).then((_) {
      processVideoChunk(videoChunk,videosDirectory.path);
      File(videoChunk.path).delete();});
  }

  String _latestFilePath({required chunkNumber}) {
    final String latestFilePath = '${_saveDir?.path ?? ''}/$chunkNumber';
    final _latestFilePath = Directory(latestFilePath);
    if (!_latestFilePath.existsSync()) {
      _latestFilePath.createSync();
    }
    return '$latestFilePath/CVR-chunkNumber_$chunkNumber.mp4';
  }
}