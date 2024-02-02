import 'package:cryptography/cryptography.dart';
import 'package:cryptography_flutter/cryptography_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class DigitalSignatureScreen extends StatelessWidget {
  final KeysGenerationService _keysGenerationService = KeysGenerationService();

  DigitalSignatureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white70,
      body: FutureBuilder(
      future: _keysGenerationService.getKeys(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              'Public Key: ${snapshot.data?.$1}',
            ),
            Text('Private Key: ${snapshot.data?.$2}'),
          ]);
        } else {
          return const CircularProgressIndicator();
        }
      }),
    );
  }
}

interface class KeysGenerationService {
  final FlutterEd25519 _generationAlgorithm = FlutterEd25519(Ed25519());
  late SimpleKeyPair _keyPair;
  bool _keysGenerated = false;

  Future<void> generateKeys() {
    return _generationAlgorithm.newKeyPair().then((value) {
      _keyPair = value;
      _keysGenerated = true;
    });
  }

  Future<(String, String)> getKeys() async {
    if (!_keysGenerated) {
      await generateKeys();
    }
    final privateKeyBytes = await _keyPair.extractPrivateKeyBytes();
    final publicKeyBytes = await _keyPair.extractPublicKey().then((value) => value.bytes);
    return (publicKeyBytes.toString(), privateKeyBytes.toString());
  }
}
