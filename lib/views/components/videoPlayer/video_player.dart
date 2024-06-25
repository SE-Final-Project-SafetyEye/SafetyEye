import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as path;

class ChewieVideoPlayer extends StatefulWidget {
  final List<String> srcs;
  final String title;

  const ChewieVideoPlayer({super.key, required this.srcs, this.title = ''});

  @override
  State<ChewieVideoPlayer> createState() => _ChewieVideoPlayerState();
}

class _ChewieVideoPlayerState extends State<ChewieVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  int currPlayIndex = 0;
  int? bufferDelay;

  @override
  void initState() {
    super.initState();
    if (widget.srcs.length == 1) {
      _loadAdditionalVideos();
    } else {
      initializePlayer();
    }
  }

  Future<void> _loadAdditionalVideos() async {
    final videoPath = widget.srcs.first;
    final directoryPath = path.dirname(videoPath);
    final directory = Directory(directoryPath);
    final videoFiles = directory.listSync().where((file) {
      final extension = path.extension(file.path).toLowerCase();
      return extension == '.mp4' || extension == '.mov' || extension == '.mkv';
    }).map((file) => file.path).toList();

    setState(() {
      widget.srcs.clear();
      widget.srcs.addAll(videoFiles);
    });

    initializePlayer();
  }

  Future<void> initializePlayer() async {
    _videoPlayerController = VideoPlayerController.network(widget.srcs[currPlayIndex]);
    await _videoPlayerController.initialize();
    _createChewieController();

    _videoPlayerController.addListener(_videoListener);

    setState(() {});
  }

  void _createChewieController() {
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false, // Set looping to false to play next video
      progressIndicatorDelay: bufferDelay != null ? Duration(milliseconds: bufferDelay!) : null,
      additionalOptions: (context) {
        return <OptionItem>[
          OptionItem(
            onTap: toggleVideo,
            iconData: Icons.live_tv_sharp,
            title: 'Toggle Video Src',
          ),
        ];
      },
      hideControlsTimer: const Duration(seconds: 1),
    );
  }

  void _videoListener() {
    if (_videoPlayerController.value.position == _videoPlayerController.value.duration) {
      toggleVideo();
    }
  }

  Future<void> toggleVideo() async {
    _videoPlayerController.removeListener(_videoListener); // Remove the listener from the old controller
    await _videoPlayerController.pause();
    _videoPlayerController.dispose();
    currPlayIndex = (currPlayIndex + 1) % widget.srcs.length;
    await initializePlayer();
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Center(
              child: _chewieController != null &&
                  _chewieController!.videoPlayerController.value.isInitialized
                  ? Chewie(controller: _chewieController!)
                  : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Loading'),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              _chewieController?.enterFullScreen();
            },
            child: const Text('Fullscreen'),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _videoPlayerController.seekTo(Duration.zero);
                      _videoPlayerController.play();
                    });
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text("Restart Video"),
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: toggleVideo,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text("Toggle Video Src"),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
