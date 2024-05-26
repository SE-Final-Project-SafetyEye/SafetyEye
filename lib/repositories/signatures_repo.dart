import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:path/path.dart' as path;

const sigDbName = 'your_database.db';
const sigTableName = 'signatures';
const messageColName = 'message';
const signatureColName = 'signature';
const publicKeyColName = 'publicKey';

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
          'CREATE TABLE $sigTableName(id INTEGER PRIMARY KEY, $messageColName TEXT, $signatureColName TEXT, $publicKeyColName TEXT)',
        );
      },
      version: 1,
    );
    return _database!;
  }

  // Save signature into the database
  Future<void> saveSignature(
      String message, String signature, String publicKey) async {
    final db = await database;
    try {
      _logger.d("try to save sig in db");
      // _logger.d(
      //     'Try to save signature message: $message, signature: $signature, publicKey: $publicKey');
      var res = await db.insert(
        sigTableName,
        {
          messageColName: message,
          signatureColName: signature,
          publicKeyColName: publicKey,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (res > 0) {
        _logger.i("successfully saved sig");
        // _logger.i(
        //     'Signature message: $message, signature: $signature, publicKey: $publicKey saved successfully');
      } else {
        _logger.w(
            'Failed to save signature, errorCode: $res, message: $message, signature: $signature, publicKey: $publicKey');
      }
    } catch (error, stackTrace) {
      _logger.e(error.toString(), stackTrace: stackTrace);
    }
  }

  // Retrieve signature from the database
  Future<(String?, String?)> getSignature(String message) async {
    final db = await database;
    _logger.d('Try to get signature message: ');
    final List<Map<String, dynamic>> maps = await db.query(
      sigTableName,
      where: '$messageColName = ?',
      whereArgs: [message],
    );
    if (maps.isNotEmpty) {
      var signature = maps.first[signatureColName] as String;
      var publicKey = maps.first[publicKeyColName] as String;
      _logger.i(
          'Signature message: $message found, signature: $signature, publicKey: $publicKey');
      return (signature, publicKey);
    }
    _logger.w('Signature message: $message not found');
    return (null, null);
  }
}
