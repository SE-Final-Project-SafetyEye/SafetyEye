import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/cupertino.dart';
import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

const sigDbName = 'your_database.db';
const sigTableName = 'signatures';
// const messageColName = 'message';
const signatureColName = 'signature';
const publicKeyColName = 'publicKey';
const fileNameId = 'fileNameId';

class SignaturesRepository {
  static Database? _database;
  static String? _databasePath;
  final Logger _logger = Logger();

  @visibleForTesting
  static Future<void> deleteDatabase() async {
    await _database!.close();
    await File(_databasePath!).delete();
  }

  SignaturesRepository() {
    init();
  }

  Future<SignaturesRepository> init() async {
    _database = await database;
    return this;
  }

  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _databasePath = path.join(await getDatabasesPath(), sigDbName);
    // Open the database (create if it doesn't exist)
    _database = await openDatabase(
      _databasePath!,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE $sigTableName(id INTEGER PRIMARY KEY, $signatureColName TEXT, $publicKeyColName TEXT, $fileNameId TEXT)',
        );
      },
      version: 1,
    );
    return _database!;
  }

  Future<Hash> getHashedMessage(String message) async {
    return await Sha256().hash(utf8.encode(message));
  }
  // Save signature into the database
  Future<void> saveSignature(
      String id, String signature, String publicKey) async {
    final db = await database;
    try {
      _logger.d("try to save sig in db");
      // _logger.d(
      //     'Try to save signature message: $message, signature: $signature, publicKey: $publicKey');
      var res = await db.insert(
        sigTableName,
        {
          signatureColName: signature,
          publicKeyColName: publicKey,
          fileNameId: id,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (res > 0) {
        _logger.i("successfully saved sig");
        // _logger.i(
        //     'Signature message: $message, signature: $signature, publicKey: $publicKey saved successfully');
      } else {
        _logger.w(
            'Failed to save signature, errorCode: $res, id: $id, signature: $signature, publicKey: $publicKey');
      }
    } catch (error, stackTrace) {
      _logger.e(error.toString(), stackTrace: stackTrace);
    }
  }

  // Retrieve signature from the database
  Future<(String?, String?)> getSignature(String id) async {
    final db = await database;
    _logger.d('Try to get signature message: $id');
    final List<Map<String, dynamic>> maps = await db.query(
      sigTableName,
      where: '$fileNameId = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      var signature = maps.first[signatureColName] as String;
      var publicKey = maps.first[publicKeyColName] as String;
      _logger.i(
          'Signature found');
      return (signature, publicKey);
    }
    _logger.w('Signature message: $id not found');
    return (null, null);
  }
}
