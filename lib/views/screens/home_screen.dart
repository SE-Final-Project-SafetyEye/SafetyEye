import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:logger/logger.dart';
import 'package:safety_eye_app/providers/ioc_provider.dart';
import 'package:safety_eye_app/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:safety_eye_app/views/components/journeys/journeys_content.dart';
import 'package:safety_eye_app/views/components/recording/recording_content.dart';
import 'package:speech_to_text/speech_recognition_event.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_to_text_provider.dart';

import '../../providers/video_recording_provider.dart';
import '../components/settings/settings_content.dart';

class HomeScreen extends StatefulWidget {
  final SettingsProvider settingsProvider;

  const HomeScreen(this.settingsProvider, {super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _pageTitles = const ['Journeys', 'Recording', 'Settings'];
  final Logger _logger = Logger();
  late int _currentIndex;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentIndex = 0;
    _pages = [
      const RecordingPage(),
      const JourneysPage(),
      SettingsPage(widget.settingsProvider)
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSpeechRecognition(context);
    });
  }

  Future<void> _initializeSpeechRecognition(BuildContext context) async {
    var speechProvider =
        Provider.of<SpeechToTextProvider>(context, listen: false);
    bool available = await speechProvider.initialize();
    if (available) {
      _startListening(speechProvider);
    } else {
      _logger.w("The user has denied the use of speech recognition.");
    }
  }

  void _startListening(SpeechToTextProvider speechProvider) async {
    await FlutterVolumeController.updateShowSystemUI(
        false); // Hide system volume UI
    await FlutterVolumeController.setMute(true,
        stream: AudioStream.alarm); // Set volume to 0 to silence feedback

    speechProvider.listen(
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 10),
      partialResults: false,
      onDevice: false,
      listenMode: ListenMode.confirmation,
    );

    speechProvider.stream.listen((event) async {
      if (event.eventType == SpeechRecognitionEventType.finalRecognitionEvent) {
        _logger.i("Final result: ${event.recognitionResult?.recognizedWords}");
        _startListening(speechProvider); // Restart listening
      } else if (event.eventType == SpeechRecognitionEventType.errorEvent) {
        _logger.e("Error: ${event.error?.errorMsg}");
        _startListening(speechProvider); // Restart listening on error
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final iocProvider =
        Provider.of<IocContainerProvider>(context, listen: false);

    return MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (context) =>
                  iocProvider.container.get<VideoRecordingProvider>())
        ],
        child: Scaffold(
          appBar: AppBar(
            title: Text(_pageTitles[_currentIndex]),
          ),
          body: _pages[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (int index) {
              _logger
                  .i('onTap: moving to page with index ${_pageTitles[index]}');
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.emergency_recording_outlined),
                label: 'Drive',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.drive_eta_sharp),
                label: 'Journeys',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bookmark_add_outlined),
                label: 'Settings',
              ),
            ],
          ),
        ));
  }
}
