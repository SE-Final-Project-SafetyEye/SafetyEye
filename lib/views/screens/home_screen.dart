import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:safety_eye_app/providers/journeys_provider.dart';
import 'package:safety_eye_app/providers/providers.dart';

import 'package:safety_eye_app/providers/settings_provider.dart';
import 'package:safety_eye_app/views/components/journeys/journeys_content.dart';
import 'package:safety_eye_app/views/components/recording/recording_content.dart';
import '../components/settings/settings_content.dart';

class HomeScreen extends StatefulWidget {
  final SettingsProvider settingsProvider;
  final JourneysProvider journeysProvider;
  final VideoRecordingProvider videoRecordingProvider;

  const HomeScreen({ required this.settingsProvider, required this.journeysProvider, required this.videoRecordingProvider, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _pageTitles = const ['Recording', 'Journeys', 'Settings'];
  final Logger _logger = Logger();
  final PageController _pageController = PageController();

  late final List<Widget> _pages = [
    RecordingPage(widget.videoRecordingProvider),
    JourneysPage(widget.journeysProvider),
    SettingsPage(widget.settingsProvider)
  ];

  @override
  void initState() {
    super.initState();
  }

  int _currentIndex = 0;

  void onItemTap(int index) {
    _logger.i('onTap: moving to page with index ${_pageTitles[index]}');
    _pageController.jumpToPage(index);
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_currentIndex]),
      ),
      body: PageView(
        onPageChanged: _onPageChanged,
        physics: const NeverScrollableScrollPhysics(),
        controller: _pageController,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: onItemTap,
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
    );
  }
}
