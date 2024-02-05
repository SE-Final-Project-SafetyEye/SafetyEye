import 'dart:convert' show base64Decode, base64Encode;
import 'package:cryptography/cryptography.dart';
import 'package:cryptography_flutter/cryptography_flutter.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DigitalSignatureScreen extends StatefulWidget {
  const DigitalSignatureScreen({super.key});

  @override
  State<DigitalSignatureScreen> createState() => _DigitalSignatureScreenState();
}

class _DigitalSignatureScreenState extends State<DigitalSignatureScreen> {
  final KeysService _keysGenerationService = KeysService();

  @override
  initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _keysGenerationService.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final future = _keysGenerationService.init().then((_) => _keysGenerationService.getKeys());
    return Scaffold(
      backgroundColor: Colors.white70,
      body: FutureBuilder(
          future: future,
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

interface class KeysService {
  final logger = Logger(printer: PrettyPrinter(colors: true));
  final _keyPairType = KeyPairType.x25519;

  final FlutterEd25519 _generationAlgorithm = FlutterEd25519(Ed25519());
  late SimpleKeyPair _keyPair;
  bool _keysGenerated = false;

  Future<void> init() async {
    if ((await areKeysStored())) {
      logger.i('found keys on device');
      _keyPair = (await _loadKeys())!;
      _keysGenerated = true;
    } else {
      _generateKeys();
    }
  }

  dispose() async {
    await _storeKeys();
    _keyPair.destroy();
  }

  Future<void> _generateKeys() {
    return _generationAlgorithm.newKeyPair().then((value) {
      _keyPair = value;
      _keysGenerated = true;

      _storeKeys();
    });
  }

  Future<void> _storeKeys() async {
    logger.i('Storing keys...');
    final pubKeyBytes = (await _keyPair.extractPublicKey()).bytes;
    final privKeyBytes = await _keyPair.extractPrivateKeyBytes();
    final sharedPreferences = await SharedPreferences.getInstance();
    final String publicKey = base64Encode(pubKeyBytes);
    final String privateKey = base64Encode(privKeyBytes);

    sharedPreferences.setString('publicKey', publicKey);
    sharedPreferences.setString('privateKey', privateKey);
    sharedPreferences.setBool("initialize", _keysGenerated);
  }

  Future<bool> areKeysStored() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    _keysGenerated = sharedPreferences.getBool("initialize") ?? false;
    return _keysGenerated;
  }

  Future<SimpleKeyPair?> _loadKeys() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final String? publicKey = sharedPreferences.getString('publicKey');
    final String? privateKey = sharedPreferences.getString('privateKey');
    if (publicKey == null || privateKey == null) {
      return null;
    }
    _keysGenerated = sharedPreferences.getBool("initialize") ?? false;
    final keyPair = SimpleKeyPairData(base64Decode(privateKey),
        publicKey: SimplePublicKey(base64Decode(publicKey), type: _keyPairType), type: _keyPairType);
    return keyPair;
  }

  Future<(String, String)> getKeys() async {
    if (!(await areKeysStored())) {
      await _generateKeys();
    }
    final privateKeyBytes = await _keyPair.extractPrivateKeyBytes();
    final publicKeyBytes = await _keyPair.extractPublicKey().then((value) => value.bytes);
    logger.e("generated keypair type: ${(await _keyPair.extract()).type}");

    final constructedKeyPair = SimpleKeyPairData(privateKeyBytes,
        publicKey: SimplePublicKey(publicKeyBytes, type: _keyPairType), type: _keyPairType);
    logger.i("key pair and constructed key pair are equal: ${constructedKeyPair == _keyPair}");

    return (base64Encode(publicKeyBytes), base64Encode(privateKeyBytes));
  }
}
