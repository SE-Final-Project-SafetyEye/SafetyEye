import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'InAppFoldersListProvider.dart';
import 'VideoListScreen.dart';

class InAppFolderListScreen extends StatelessWidget {
  const InAppFolderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Consumer to listen to changes in VideoFolderProvider
    return Consumer<VideoFolderProvider>(
      builder: (context, provider, _) {
        if (provider.videoFolders.isEmpty) {
          // Call getVideoList when videoFolders is empty
          provider.getVideoList();
          return const Center(child: Text('Loading videos...'));
        } else {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Videos List'),
            ),
            body: ListView.builder(
              itemCount: provider.videoFolders.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => VideoListScreen(path: provider.videoFolders[index].path)),
                    );
                  },
                  child: Card(
                    child: ListTile(
                      title: Text(provider.videoFolders[index].name),
                      subtitle: Text(provider.videoFolders[index].path),
                    ),
                  ),
                );
              },
            ),
          );
        }
      },
    );
  }
}