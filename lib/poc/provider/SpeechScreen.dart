import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:highlight_text/highlight_text.dart';
import 'SpeechProvider.dart';

class SpeechScreen extends StatelessWidget {
  const SpeechScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SpeechProvider(),
      child: Consumer<SpeechProvider>(
        builder: (context, speechState, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Confidence: ${(speechState.confidence * 100.0).toStringAsFixed(1)}%'),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            floatingActionButton: AvatarGlow(
              animate: speechState.isListening,
              glowColor: Theme.of(context).primaryColor,
              duration: const Duration(milliseconds: 2000),
              repeat: true,
              child: FloatingActionButton(
                onPressed: () {
                  speechState.listen();
                },
                child: Icon(speechState.isListening ? Icons.mic : Icons.mic_none),
              ),
            ),
            body: SingleChildScrollView(
              reverse: true,
              child: Container(
                padding: const EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 150.0),
                child: TextHighlight(
                  text: speechState.text,
                  words: speechState.highlights,
                  textStyle: const TextStyle(
                    fontSize: 32.0,
                    color: Colors.black,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
