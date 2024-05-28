// import 'dart:convert';
// import 'package:cryptography/cryptography.dart';
// import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
// import 'package:flutter/material.dart';
// import 'package:logger/logger.dart';
// import 'package:safety_eye_app/Deprecated/printColoredMessage.dart';
// import 'package:provider/provider.dart';
// import 'package:safety_eye_app/poc/uploadVideo/BackendService.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart' as path;
//
// import 'AuthProvider.dart';
//
// class DigitalSignatureScreen extends StatefulWidget {
//   const DigitalSignatureScreen({super.key});
//
//   @override
//   State<DigitalSignatureScreen> createState() => _DigitalSignatureScreenState();
// }
//
// class _DigitalSignatureScreenState extends State<DigitalSignatureScreen> {
//   final KeysService _keysGenerationService = KeysService();
//   final TextEditingController controller = TextEditingController();
//   Signature? generatedSignature;
//   bool isValidSignature = false;
//   bool verifiedCalled = false;
//
//   @override
//   initState() {
//     generatedSignature = null;
//     super.initState();
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     _keysGenerationService.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final currentUser = Provider.of<AuthProvider>(context).currentUser;
//     final future = _keysGenerationService.init(currentUser!);
//     return Scaffold(
//       appBar: AppBar(title: const Text("Digital signature")),
//       backgroundColor: Colors.white70,
//       body: FutureBuilder(
//           future: future,
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.done) {
//               return Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     const Text("keys ready for signing"),
//                     TextField(controller: controller),
//                     ElevatedButton(
//                         onPressed: () async {
//                           var sig = await _keysGenerationService.signMessage(controller.text);
//                           setState(() {
//                             generatedSignature = sig;
//                             verifiedCalled = false;
//                           });
//                         },
//                         child: const Text("Generate Signature")),
//                     if (generatedSignature != null) ...[
//                       Text(base64Encode(generatedSignature!.bytes)),
//                       ElevatedButton(
//                           onPressed: () async {
//                             String textValue = controller.text;
//                             bool isValid = await _keysGenerationService.verifySignature(textValue, generatedSignature!);
//                             setState(() {
//                               verifiedCalled = true;
//                               isValidSignature = isValid;
//                             });
//                           },
//                           child: const Text("Verify Signature")),
//                       if (verifiedCalled)
//                         if (isValidSignature) const Text("data is valid") else const Text("data is not valid"),
//                     ] else
//                       const Text("No signature generated"),
//                   ]);
//             } else {
//               return const Column(
//                 children: [CircularProgressIndicator(), Text("initializing keys")],
//               );
//             }
//           }),
//     );
//   }
// }
//
// interface class KeysService {
//   final logger = Logger(printer: PrettyPrinter(colors: true));
//   final _keyPairType = KeyPairType.x25519;
//
//   final FlutterEd25519 _generationAlgorithm = FlutterEd25519(Ed25519());
//   late SimpleKeyPair _keyPair;
//   bool _keysGenerated = false;
//
//   Future<void> init(User current) async {
//     if ((await areKeysStored())) {
//       logger.i('found keys on device');
//       _keyPair = (await _loadKeys())!;
//       _keysGenerated = true;
//     } else {
//       _generateKeys();
//     }
//     final keyBytes =(await _keyPair.extractPublicKey()).bytes;
//     BackendService(current).exchangeKey(base64Encode(keyBytes)).then((value) {
//       logger.d("received key from backend: ");
//     }).catchError((error) {
//       logger.e("failed to receive key from backend: $error");
//     });
//   }
//
//   dispose() async {
//     await _storeKeys();
//     _keyPair.destroy();
//   }
//
//   Future<void> _generateKeys() {
//     return _generationAlgorithm.newKeyPair().then((value) {
//       _keyPair = value;
//       _keysGenerated = true;
//
//       _storeKeys();
//     });
//   }
//
//   Future<void> _storeKeys() async {
//     logger.i('Storing keys...');
//     final pubKeyBytes = (await _keyPair.extractPublicKey()).bytes;
//     final privKeyBytes = await _keyPair.extractPrivateKeyBytes();
//     final sharedPreferences = await SharedPreferences.getInstance();
//     final String publicKey = base64Encode(pubKeyBytes);
//     final String privateKey = base64Encode(privKeyBytes);
//
//     sharedPreferences.setString('publicKey', publicKey);
//     logger.i('Stored public key: $publicKey');
//     sharedPreferences.setString('privateKey', privateKey);
//     sharedPreferences.setBool("initialize", _keysGenerated);
//   }
//
//   Future<bool> areKeysStored() async {
//     final sharedPreferences = await SharedPreferences.getInstance();
//     _keysGenerated = sharedPreferences.getBool("initialize") ?? false;
//     return _keysGenerated;
//   }
//
//   Future<SimpleKeyPair?> _loadKeys() async {
//     final sharedPreferences = await SharedPreferences.getInstance();
//     final String? publicKey = sharedPreferences.getString('publicKey');
//     final String? privateKey = sharedPreferences.getString('privateKey');
//     if (publicKey == null || privateKey == null) {
//       return null;
//     }
//     _keysGenerated = sharedPreferences.getBool("initialize") ?? false;
//     final keyPair = SimpleKeyPairData(base64Decode(privateKey),
//         publicKey: SimplePublicKey(base64Decode(publicKey), type: _keyPairType), type: _keyPairType);
//     return keyPair;
//   }
//
//   Future<(String, String)> getKeys() async {
//     if (!(await areKeysStored())) {
//       await _generateKeys();
//     }
//     final privateKeyBytes = await _keyPair.extractPrivateKeyBytes();
//     final publicKeyBytes = await _keyPair.extractPublicKey().then((value) => value.bytes);
//     logger.e("generated keypair type: ${(await _keyPair.extract()).type}");
//
//     final constructedKeyPair = SimpleKeyPairData(privateKeyBytes,
//         publicKey: SimplePublicKey(publicKeyBytes, type: _keyPairType), type: _keyPairType);
//     logger.i("key pair and constructed key pair are equal: ${constructedKeyPair == _keyPair}");
//
//     return (base64Encode(publicKeyBytes), base64Encode(privateKeyBytes));
//   }
//
//   Future<Signature> signMessage(String message) async {
//     final signature = await _generationAlgorithm.sign(utf8.encode(message), keyPair: _keyPair);
//     logger.i('signature: ${base64.encode(signature.bytes)}');
//     await DBHelper.saveSignature(message, signature.toString());
//     String? verify = await DBHelper.getSignature(message);
//     //printColoredMessage('verify: $verify',color: "red");
//     return signature;
//   }
//
//   Future<bool> verifySignature(String message, Signature signature) async {
//     return await _generationAlgorithm.verify(utf8.encode(message), signature: signature);
//   }
// }
//
// class DBHelper {
//   static Database? _database;
//
//   static Future<Database> get database async {
//     if (_database != null) {
//       return _database!;
//     }
//
//     // Open the database (create if it doesn't exist)
//     _database = await openDatabase(
//       path.join(await getDatabasesPath(), 'your_database.db'),
//       onCreate: (db, version) {
//         return db.execute(
//           'CREATE TABLE signatures(id INTEGER PRIMARY KEY, message TEXT, signature TEXT)',
//         );
//       },
//       version: 1,
//     );
//     return _database!;
//   }
//
//   // Save signature into the database
//   static Future<void> saveSignature(String message, String signature) async {
//     final db = await database;
//     await db.insert(
//       'signatures',
//       {
//         'message': message,
//         'signature': signature,
//       },
//       conflictAlgorithm: ConflictAlgorithm.replace,
//     );
//   }
//
//   // Retrieve signature from the database
//   static Future<String?> getSignature(String message) async {
//     final db = await database;
//     final List<Map<String, dynamic>> maps = await db.query(
//       'signatures',
//       where: 'message = ?',
//       whereArgs: [message],
//     );
//     if (maps.isNotEmpty) {
//       return maps.first['signature'] as String;
//     }
//     return null;
//   }
// }