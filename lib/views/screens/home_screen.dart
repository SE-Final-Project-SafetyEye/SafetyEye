import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:safety_eye_app/providers/chunks_provider.dart';
import 'package:safety_eye_app/providers/journeys_provider.dart';
import 'package:safety_eye_app/providers/permissions_provider.dart';
import 'package:safety_eye_app/providers/sensors_provider.dart';
import 'package:safety_eye_app/views/components/journeys/journeys_content.dart';
import 'package:safety_eye_app/views/components/recording/recording_content.dart';

import '../../providers/auth_provider.dart';
import '../../providers/video_recording_provider.dart';
import '../components/settings/settings_content.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    RecordingPage(),
    const JourneysPage(),
    const SettingsPage()
  ];
  final List<String> _pageTitles = const ['Recording', 'Journeys', 'Settings'];
  final Logger _logger = Logger();


  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthenticationProvider>(context,listen: false);
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => SensorsProvider()),
          ChangeNotifierProvider(create: (context)=>JourneysProvider(authenticationProvider: auth)),
          ChangeNotifierProxyProvider3(create: (context) => VideoRecordingProvider(permissions: Provider.of<PermissionsProvider>(context,listen: false),
              sensorsProvider: Provider.of<SensorsProvider>(context,listen: false),
              authenticationProvider: auth),
              update: (BuildContext context, PermissionsProvider permissions ,SensorsProvider sensors,AuthenticationProvider auth,
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
