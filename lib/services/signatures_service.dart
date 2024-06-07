import 'dart:convert';
import 'package:cryptography/cryptography.dart';
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
  late BackendService backendService;
  final Ed25519 _signingAlgorithm = Ed25519();

  SimpleKeyPair? _keyPair;
  bool areKeysGenerated = false;

  SignaturesService({required this.backendService});

  Future<void> init() async {
    if (await areKeysStored()) {
      _logger.i('Found keys on device');
      _keyPair = await _loadKeys();
      if (_keyPair!= null) {
        areKeysGenerated = true;
      } else {
        _logger.e('KeyPair is null. Initialization failed.');
      }
    } else {
      await _generateKeys();
    }

    if (_keyPair != null) {
      final keyBytes = (await _keyPair!.extractPublicKey()).bytes;
      backendService.exchangeKey(base64Encode(keyBytes)).then((exchangeKey) {
        _logger.d("Received key from backend: $exchangeKey");
        _preferencesService.setPref(PreferencesKeys.exchangeKey, exchangeKey);
        _preferencesService.setPref(PreferencesKeys.areKeysInitialize, true);
      });
    } else {
      _logger.e('KeyPair is null. Initialization failed.');
    }
  }

  void dispose() async {
    if (_keyPair != null) {
      await _storeKeys();
      _keyPair!.destroy();
    }
  }

  Future<void> _generateKeys() async {
    await _signingAlgorithm.newKeyPair().then((value) {
      _keyPair = value;
      areKeysGenerated = true;
      _storeKeys();
    });
  }

  Future<void> _storeKeys() async {
    _logger.i('Storing keys...');
    var pubKey = await _keyPair!.extractPublicKey();
    final pubKeyBytes = pubKey.bytes;
    final privKeyBytes = await _keyPair!.extractPrivateKeyBytes();
    final publicKey = base64Encode(pubKeyBytes);
    final privateKey = base64Encode(privKeyBytes);
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

    final publicKey = await _preferencesService
        .getPrefOrDefault<String>(PreferencesKeys.publicKey);
    final privateKey = await _preferencesService
        .getPrefOrDefault<String>(PreferencesKeys.privateKey);
    final keyPair = SimpleKeyPairData(base64Decode(privateKey),
        publicKey: SimplePublicKey(base64Decode(publicKey), type: _keyPairType),
        type: _keyPairType);
    _keyPair = keyPair;
    return keyPair;
  }

  Future<SimpleKeyPair> getKeys() async {
    if (!(await areKeysStored())) {
      await _generateKeys();
    }
    if(_keyPair == null) {
      await init();
    }
    return _keyPair!;
  }


  Future<Signature> signMessage(String id, String message) async {
    if (!areKeysGenerated) {
      await _generateKeys();
    }
    final signature =
    await _signingAlgorithm.sign(base64Decode(message), keyPair: _keyPair!);
    String encodedSignature = base64.encode(signature.bytes);
    _logger.i('generated Signature for message with id $id: $encodedSignature');
    await _signaturesRepository.saveSignature(id, encodedSignature,
        base64Encode((await _keyPair!.extractPublicKey()).bytes));
    return signature;
  }

  Future<bool> verifySignature(List<int> message, Signature signature) async {
    return _signingAlgorithm.verify(message,
        signature: signature);
  }

  Future<String> getSignature(String id) async {
    final (signature, _) = await _signaturesRepository.getSignature(id);
    if (signature != null) {
      return signature;
    } else {
      throw Exception("Signature not found");
    }
  }
}