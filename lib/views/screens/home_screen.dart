import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:safety_eye_app/providers/settings_provider.dart';
import 'package:safety_eye_app/views/components/journeys/journeys_content.dart';
import 'package:safety_eye_app/views/components/recording/recording_content.dart';

import '../components/settings/settings_content.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late SettingsProvider settingsProvider;
  late List<Widget> _pages;
  final List<String> _pageTitles = const ['Recording', 'Journeys', 'Settings'];
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    settingsProvider = Provider.of<SettingsProvider>(context);
    _pages = [RecordingPage(), JourneysPage(), SettingsPage(settingsProvider)];

    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_currentIndex]),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) {
          _logger.i('onTap: moving to page with index ${_pageTitles[index]}');
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
    );
  }
}
