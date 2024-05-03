import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:safety_eye_app/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:safety_eye_app/providers/permissions_provider.dart';
import 'package:safety_eye_app/providers/sensors_provider.dart';
import 'package:safety_eye_app/views/components/journeys/journeys_content.dart';
import 'package:safety_eye_app/views/components/recording/recording_content.dart';

import '../../providers/auth_provider.dart';
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
    _pages = [const RecordingPage(), const JourneysPage(), SettingsPage(widget.settingsProvider)];

  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthenticationProvider>(context, listen: false);
    final sensors = Provider.of<SensorsProvider>(context, listen: false);
    final permissions = Provider.of<PermissionsProvider>(context, listen: false);
    return MultiProvider(
        providers: [
          ChangeNotifierProxyProvider2(create: (context) => VideoRecordingProvider(permissions: permissions,
              sensorsProvider: sensors,
              authenticationProvider: auth),
              update: (BuildContext context ,SensorsProvider sensors,AuthenticationProvider auth,
                  VideoRecordingProvider? vProvider) =>
                 vProvider ?? VideoRecordingProvider(permissions: permissions, sensorsProvider: sensors,authenticationProvider: auth)),
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
