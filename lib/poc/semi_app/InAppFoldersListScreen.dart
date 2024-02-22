import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_compress/video_compress.dart';

import '../InAppVideoListScreen.dart';
import '../VideoListScreen.dart';
import '../VideoPlayer.dart';


class InAppFolderListScreen extends StatefulWidget {
  const InAppFolderListScreen();

  @override
  _InAppVideoListScreenState createState() => _InAppVideoListScreenState();
}

class _InAppVideoListScreenState extends State<InAppFolderListScreen> {
  List<FileSystemEntity> videoFolders = [];
  List<String> videoCompressPaths = [];

  @override
  void initState() {
    super.initState();
    getVideoList();
  }

  Future<void> getVideoList() async {
    try {
      Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();
      final videosDirectory = Directory('${appDocumentsDirectory.path}/videos');
      List<FileSystemEntity> files = videosDirectory.listSync();
      for(FileSystemEntity file in files){
        FileSystemEntity fileSystemEntity = file.absolute;
        FileStat fileStat = file.statSync();
        if(fileStat.type == FileSystemEntityType.directory){
          print(fileStat.toString());
          videoFolders.add(fileSystemEntity);
        }
      }
      setState(() {});
    } catch (e) {
      print("Error getting original video list: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Videos List'),
      ),
      body: (videoFolders.isEmpty)
          ? const Center(child: Text('No videos available'))
          : ListView(
        children: [
          if (videoFolders.isNotEmpty)
            _buildVideoList(videoFolders, 'Video Folders'),
        ],
      ),
    );
  }

  Widget _buildVideoList(List<FileSystemEntity> paths, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: paths.length,
          itemBuilder: (context, index) {
            return VideoCard( fileSystemEntity: paths[index]);
          },
        ),
      ],
    );
  }
}

class VideoCard extends StatefulWidget {
  final FileSystemEntity fileSystemEntity;
  const VideoCard({Key? key, required this.fileSystemEntity}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String videoFolderName = widget.fileSystemEntity.path.split('/').last;
    return GestureDetector(onTap: () =>{
    Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => VideoListScreen(path: widget.fileSystemEntity.path)),
    )},child: Card(
        child: Column(children: [
          ListTile(title: Text(videoFolderName))
        ])),);

  }

  @override
  void dispose() {
    super.dispose();
  }
}
