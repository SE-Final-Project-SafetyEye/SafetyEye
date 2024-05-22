import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:cryptography_flutter/cryptography_flutter.dart';
import 'package:logger/logger.dart';
import 'package:safety_eye_app/repositories/repositories.dart';
import 'package:safety_eye_app/repositories/signatures_repo.dart';
import 'package:safety_eye_app/services/BackendService.dart';
import 'package:safety_eye_app/services/preferences_services.dart';

class SignaturesService {
  final Logger _logger = Logger();
  final _keyPairType = KeyPairType.x25519;
  final SignaturesRepository _signaturesRepository = SignaturesRepository();
  final PreferencesService _preferencesService = PreferencesService();
  final FlutterEd25519 _signingAlgorithm = FlutterEd25519(Ed25519());
  late BackendService backendService;

  late SimpleKeyPair _keyPair;
  bool areKeysGenerated = false;

  SignaturesService({required this.backendService});

  Future<void> init() async {
    if ((await areKeysStored())) {
      _logger.i('found keys on device');
      _keyPair = (await _loadKeys())!;
      areKeysGenerated = true;
    } else {
      await _generateKeys();
    }

    final keyBytes = (await _keyPair.extractPublicKey()).bytes;
    // This function throw if exchange key is not set
    backendService.exchangeKey(base64Encode(keyBytes))
        .then((exchangeKey) {
      _logger.d("received key from backend:");
      _preferencesService.setPref(PreferencesKeys.exchangeKey, exchangeKey);
    });
  }

  dispose() async {
    await _storeKeys();
    _keyPair.destroy();
  }

  Future<void> _generateKeys() {
    return _signingAlgorithm.newKeyPair().then((value) {
      _keyPair = value;
      areKeysGenerated = true;
      _storeKeys();
    });
  }

  Future<void> _storeKeys() async {
    _logger.i('Storing keys...');
    var pubKey = await _keyPair.extractPublicKey();
    final pubKeyBytes = pubKey.bytes;
    final privKeyBytes = await _keyPair.extractPrivateKeyBytes();
    final String publicKey = base64Encode(pubKeyBytes);
    final String privateKey = base64Encode(privKeyBytes);
    _preferencesService.setPref(PreferencesKeys.publicKey, publicKey);
    _logger.i('Stored public key: $publicKey');
    _preferencesService.setPref(PreferencesKeys.privateKey, privateKey);
    _preferencesService.setPref(
        PreferencesKeys.areKeysInitialize, areKeysGenerated);
  }

  Future<bool> areKeysStored() async {
    areKeysGenerated = await _preferencesService
        .getPrefOrDefault<bool>(PreferencesKeys.areKeysInitialize);
    return areKeysGenerated;
  }

  Future<SimpleKeyPair?> _loadKeys() async {
    if (!areKeysGenerated) {
      return null;
    }

    final String publicKey = await _preferencesService
        .getPrefOrDefault<String>(PreferencesKeys.publicKey);
    final String privateKey = await _preferencesService
        .getPrefOrDefault<String>(PreferencesKeys.privateKey);
    final keyPair = SimpleKeyPairData(base64Decode(privateKey),
        publicKey: SimplePublicKey(base64Decode(publicKey), type: _keyPairType),
        type: _keyPairType);

    return keyPair;
  }

  Future<(String, String)> getKeys() async {
    if (!(await areKeysStored())) {
      await _generateKeys();
    }
    final privateKeyBytes = await _keyPair.extractPrivateKeyBytes();
    final publicKeyBytes =
        await _keyPair.extractPublicKey().then((value) => value.bytes);
    _logger.i("generated keypair type: ${(await _keyPair.extract()).type}");

    final constructedKeyPair = SimpleKeyPairData(privateKeyBytes,
        publicKey: SimplePublicKey(publicKeyBytes, type: _keyPairType),
        type: _keyPairType);
    _logger.i(
        "key pair and constructed key pair are equal: ${constructedKeyPair == _keyPair}");

    return (base64Encode(publicKeyBytes), base64Encode(privateKeyBytes));
  }

  Future<Signature> signMessage(String message) async {
    _logger.i("signMessage");
    final signature =
        await _signingAlgorithm.sign(utf8.encode(message), keyPair: _keyPair);
    _logger.i('signature: ${base64.encode(signature.bytes)}');
    await _signaturesRepository.saveSignature(message, signature.toString(),
        base64Encode((await _keyPair.extractPublicKey()).bytes));
    //var (String? sigVerify, String? publicKeyVerifiy) = await _signaturesRepository.getSignature(message);
    // TODO verify
    return signature;
  }

  Future<bool> verifySignature(String message, Signature signature) async {
    return await _signingAlgorithm.verify(utf8.encode(message),
        signature: signature);
  }
}
