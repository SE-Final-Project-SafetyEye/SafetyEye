import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'InAppFoldersListScreen.dart';
import 'Settings.dart';
import 'Records_chanks.dart';

class NavigateAppPage extends StatefulWidget {
  List<CameraDescription> cameras;
  NavigateAppPage({super.key,required this.cameras});
  @override
  State<NavigateAppPage> createState() => _NavigateAppPageState();
}

class _NavigateAppPageState extends State<NavigateAppPage> {
  int _currentIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    _pages = [
      CameraScreen(title: "SafetyEye",cameras: widget.cameras,),
      const InAppFolderListScreen(),
      const Settings(),
    ];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) {
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