import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:safety_eye_app/providers/ioc_provider.dart';
import 'package:safety_eye_app/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:safety_eye_app/views/components/journeys/journeys_content.dart';
import 'package:safety_eye_app/views/components/recording/recording_content.dart';
import 'package:speech_to_text/speech_recognition_event.dart';
import 'package:speech_to_text/speech_to_text_provider.dart';
import 'package:background_fetch/background_fetch.dart';

import '../../providers/video_recording_provider.dart';
import '../components/settings/settings_content.dart';

class HomeScreen extends StatefulWidget {
  final SettingsProvider settingsProvider;
  final SpeechToTextProvider speechProvider;

  const HomeScreen(this.settingsProvider, this.speechProvider, {super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _pageTitles = const ['Journeys', 'Recording', 'Settings'];
  final Logger _logger = Logger();
  bool _isListening = false;
  late int _currentIndex;
  late List<Widget> _pages;

  void _startBackgroundFetch() {
    BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: 1,
        // Minimum interval in minutes for background fetch events
        stopOnTerminate: false,
        // Set to true if you want to stop background execution when the app is terminated
        enableHeadless: true,
        // Set to true to enable headless execution
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiresDeviceIdle: false,
      ),
      (String taskId) async {
        await _startListening();
        BackgroundFetch.finish(taskId); // Finish the background fetch task
      },
    ).then((int status) {
      _logger.i('[BackgroundFetch] configure success: $status');
    }).catchError((e) {
      _logger.e('[BackgroundFetch] configure ERROR: $e');
    });
  }

  Future<void> _startListening() async {
    if (!_isListening) {
      bool available = await widget.speechProvider.initialize();
      if (available) {
        StreamSubscription<SpeechRecognitionEvent> _subscription;
        _subscription = widget.speechProvider.stream.listen((recognitionEvent) {
          if (recognitionEvent.eventType ==
              SpeechRecognitionEventType.finalRecognitionEvent) {
            _logger.i(
                "I heard: ${recognitionEvent.recognitionResult?.recognizedWords}");
          }
        });
        widget.speechProvider.listen();
        setState(() => _isListening = true);
      }
    }
  }

  // void initSpeechProvider(SpeechToTextProvider speechProvider) async {
  //   if (!_speechEnabled) {
  //     bool available = await speechProvider.initialize();
  //     if (available) {
  //       _speechEnabled = true;
  //       StreamSubscription<SpeechRecognitionEvent> _subscription;
  //       _subscription = speechProvider.stream.listen((recognitionEvent) {
  //         if (recognitionEvent.eventType ==
  //             SpeechRecognitionEventType.finalRecognitionEvent) {
  //           _logger.i(
  //               "I heard: ${recognitionEvent.recognitionResult?.recognizedWords}");
  //         }
  //         // currently disabled as it got INTO INFINITE LOOP
  //         // if (recognitionEvent.eventType ==
  //         //     SpeechRecognitionEventType.errorEvent) {
  //         //   // DO NOTHING and trigger again
  //         //   speechProvider.listen();
  //         // }
  //         // if (recognitionEvent.eventType ==
  //         //     SpeechRecognitionEventType.doneEvent) {
  //         //   _logger.i("Listening done, triggering again");
  //         //   speechProvider.listen();
  //         // }
  //       });
  //       speechProvider.listen();
  //     }
  //   }
  // }

  @override
  void initState() {
    super.initState();
    _currentIndex = 0;
    _pages = [
      const RecordingPage(),
      const JourneysPage(),
      SettingsPage(widget.settingsProvider)
    ];
    _startBackgroundFetch();
  }

  @override
  Widget build(BuildContext context) {
    final iocProvider =
        Provider.of<IocContainerProvider>(context, listen: false);
    // final speechProvider =
    //     Provider.of<SpeechToTextProvider>(context, listen: false);
    // initSpeechProvider(speechProvider);

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
