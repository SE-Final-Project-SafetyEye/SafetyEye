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

  late SimpleKeyPair? _keyPair;
  bool areKeysGenerated = false;

  SignaturesService({required this.backendService});

  Future<void> init() async {
    if (await areKeysStored()) {
      _logger.i('Found keys on device');
      _keyPair = await _loadKeys();
      areKeysGenerated = true;
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
    _preferencesService.setPref(PreferencesKeys.areKeysInitialize, areKeysGenerated);
  }

  Future<bool> areKeysStored() async {
    areKeysGenerated = await _preferencesService.getPrefOrDefault<bool>(PreferencesKeys.areKeysInitialize);
    return areKeysGenerated;
  }

  Future<SimpleKeyPair?> _loadKeys() async {
    if (!areKeysGenerated) {
      return null;
    }

    final publicKey = await _preferencesService.getPrefOrDefault<String>(PreferencesKeys.publicKey);
    final privateKey = await _preferencesService.getPrefOrDefault<String>(PreferencesKeys.privateKey);
    final keyPair = SimpleKeyPairData(base64Decode(privateKey),
        publicKey: SimplePublicKey(base64Decode(publicKey), type: _keyPairType), type: _keyPairType);

    return keyPair;
  }

  Future<(String, String)> getKeys() async {
    if (!(await areKeysStored())) {
      await _generateKeys();
    }
    final privateKeyBytes = await _keyPair!.extractPrivateKeyBytes();
    final publicKeyBytes = await _keyPair!.extractPublicKey().then((value) => value.bytes);
    _logger.i("Generated keypair type: ${(await _keyPair!.extract()).type}");

    final constructedKeyPair = SimpleKeyPairData(privateKeyBytes,
        publicKey: SimplePublicKey(publicKeyBytes, type: _keyPairType), type: _keyPairType);
    _logger.i("Keypair and constructed key pair are equal: ${constructedKeyPair == _keyPair}");

    return (base64Encode(publicKeyBytes), base64Encode(privateKeyBytes));
  }

  Future<Signature> signMessage(String id, String message) async {
    if(!areKeysGenerated){await _generateKeys();}
    final signature = await _signingAlgorithm.sign(utf8.encode(message), keyPair: _keyPair!);
    _logger.i('Signature: ${base64.encode(signature.bytes)}');
    await _signaturesRepository.saveSignature(
        message, signature.toString(), base64Encode((await _keyPair!.extractPublicKey()).bytes));
    //var (String? sigVerify, String? publicKeyVerifiy) = await _signaturesRepository.getSignature(message);
    // TODO: Verify signature
    return signature;
  }

  Future<bool> verifySignature(String message, Signature signature) async {
    return await _signingAlgorithm.verify(utf8.encode(message), signature: signature);
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
