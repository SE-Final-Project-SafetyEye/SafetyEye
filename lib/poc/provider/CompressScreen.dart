import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'CompressProvider.dart';

class CompressScreen extends StatelessWidget {
  const CompressScreen({Key? key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CompressProvider(),
      child: Consumer<CompressProvider>(
        builder: (context, compressProvider, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Video Compressor'),
            ),
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  compressProvider.pickVideo();
                  compressProvider.compressAndSaveVideo();
                },
                child: Text('Select Video and Compress'),
              ),
            ),
          );
        },
      ),
    );
  }
}
